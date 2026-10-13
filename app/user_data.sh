#!/bin/bash
# ========================================================
# AWS Learner Lab: User Data Bootstrap Script - CloudRetail
# OS Target: Amazon Linux 2023
# ========================================================

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "=== Memulai Inisialisasi CloudRetail Web Server ==="

# 1. Update paket sistem & install Python 3 serta pip
dnf update -y
dnf install -y python3 python3-pip

# 2. Buat direktori aplikasi
mkdir -p /opt/cloudretail/templates
cd /opt/cloudretail

# 3. Buat file requirements.txt
cat << 'EOF' > /opt/cloudretail/requirements.txt
flask==3.0.3
boto3==1.34.140
pymysql==1.1.1
cryptography==42.0.8
urllib3==2.2.2
EOF

# 4. Install dependencies Python
pip3 install -r /opt/cloudretail/requirements.txt

# 5. Salin kode aplikasi app.py
cat << 'EOF' > /opt/cloudretail/app.py
import os
import uuid
import datetime
import urllib.request
from flask import Flask, render_template, request, redirect, url_for, flash
import pymysql
import boto3

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", "aws-learner-lab-secret-key-2026")

AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
S3_BUCKET = os.environ.get("S3_BUCKET", "cloudretail-bucket-learnerlab")
DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "CloudRetail-Logs")

RDS_HOST = os.environ.get("RDS_HOST", "")
RDS_USER = os.environ.get("RDS_USER", "admin")
RDS_PASSWORD = os.environ.get("RDS_PASSWORD", "Admin123456!")
RDS_DATABASE = os.environ.get("RDS_DATABASE", "cloudretail")
RDS_PORT = int(os.environ.get("RDS_PORT", 3306))

def get_instance_metadata():
    instance_id = "ec2-unknown"
    az = "az-unknown"
    try:
        token_req = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "60"},
            method="PUT"
        )
        with urllib.request.urlopen(token_req, timeout=1) as response:
            token = response.read().decode("utf-8")

        id_req = urllib.request.Request(
            "http://169.254.169.254/latest/meta-data/instance-id",
            headers={"X-aws-ec2-metadata-token": token}
        )
        with urllib.request.urlopen(id_req, timeout=1) as response:
            instance_id = response.read().decode("utf-8")

        az_req = urllib.request.Request(
            "http://169.254.169.254/latest/meta-data/placement/availability-zone",
            headers={"X-aws-ec2-metadata-token": token}
        )
        with urllib.request.urlopen(az_req, timeout=1) as response:
            az = response.read().decode("utf-8")
    except Exception:
        pass
    return instance_id, az

def get_db_connection():
    if not RDS_HOST:
        return None
    try:
        conn = pymysql.connect(
            host=RDS_HOST,
            user=RDS_USER,
            password=RDS_PASSWORD,
            port=RDS_PORT,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
            connect_timeout=3
        )
        with conn.cursor() as cursor:
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{RDS_DATABASE}`")
            cursor.execute(f"USE `{RDS_DATABASE}`")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS products (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    name VARCHAR(120) NOT NULL,
                    price DECIMAL(12, 2) NOT NULL,
                    image_url VARCHAR(500),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.commit()
        return conn
    except Exception as e:
        print(f"[RDS Error]: {e}")
        return None

def get_s3_client():
    return boto3.client("s3", region_name=AWS_REGION)

def get_dynamodb_resource():
    return boto3.resource("dynamodb", region_name=AWS_REGION)

def log_activity(action, detail, client_ip):
    instance_id, az = get_instance_metadata()
    try:
        dynamodb = get_dynamodb_resource()
        table = dynamodb.Table(DYNAMODB_TABLE)
        now_iso = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        item = {
            "log_id": str(uuid.uuid4()),
            "timestamp": now_iso,
            "action": action,
            "detail": detail,
            "instance_id": instance_id,
            "az": az,
            "client_ip": client_ip
        }
        table.put_item(Item=item)
    except Exception as e:
        print(f"[DynamoDB Error]: {e}")

@app.route("/health", methods=["GET"])
def health_check():
    return "OK", 200

@app.route("/", methods=["GET"])
def index():
    instance_id, az = get_instance_metadata()
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)

    log_activity("PAGE_VISIT", f"Akses dashboard via IP {client_ip}", client_ip)

    rds_conn = get_db_connection()
    rds_status = rds_conn is not None
    products = []
    if rds_status:
        try:
            with rds_conn.cursor() as cursor:
                cursor.execute(f"USE `{RDS_DATABASE}`")
                cursor.execute("SELECT * FROM products ORDER BY id DESC")
                products = cursor.fetchall()
            rds_conn.close()
        except Exception:
            rds_status = False

    dynamodb_status = False
    logs = []
    try:
        dynamodb = get_dynamodb_resource()
        table = dynamodb.Table(DYNAMODB_TABLE)
        response = table.scan(Limit=30)
        logs = response.get("Items", [])
        logs.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        logs = logs[:10]
        dynamodb_status = True
    except Exception:
        dynamodb_status = False

    s3_status = False
    try:
        s3 = get_s3_client()
        s3.head_bucket(Bucket=S3_BUCKET)
        s3_status = True
    except Exception:
        s3_status = False

    return render_template(
        "index.html",
        instance_id=instance_id,
        az=az,
        rds_status=rds_status,
        rds_host_display=RDS_HOST if RDS_HOST else "Belum Dikonfigurasi",
        s3_status=s3_status,
        s3_bucket_name=S3_BUCKET,
        dynamodb_status=dynamodb_status,
        dynamodb_table_name=DYNAMODB_TABLE,
        products=products,
        logs=logs
    )

@app.route("/add-product", methods=["POST"])
def add_product():
    name = request.form.get("name")
    price = request.form.get("price")
    image_file = request.files.get("image")
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)
    image_url = ""

    if image_file and image_file.filename != "":
        file_ext = os.path.splitext(image_file.filename)[1]
        unique_filename = f"products/{uuid.uuid4()}{file_ext}"
        try:
            s3 = get_s3_client()
            s3.upload_fileobj(
                image_file,
                S3_BUCKET,
                unique_filename,
                ExtraArgs={"ContentType": image_file.content_type}
            )
            image_url = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": S3_BUCKET, "Key": unique_filename},
                ExpiresIn=604800
            )
        except Exception as e:
            flash(f"Gagal upload foto ke S3: {e}", "danger")

    rds_conn = get_db_connection()
    if rds_conn:
        try:
            with rds_conn.cursor() as cursor:
                cursor.execute(f"USE `{RDS_DATABASE}`")
                cursor.execute(
                    "INSERT INTO products (name, price, image_url) VALUES (%s, %s, %s)",
                    (name, price, image_url)
                )
                rds_conn.commit()
            rds_conn.close()
            flash("✅ Produk berhasil ditambahkan ke RDS MySQL & S3!", "success")
            log_activity("PRODUCT_ADDED", f"Tambah produk: {name} (Rp {price})", client_ip)
        except Exception as e:
            flash(f"Gagal simpan ke RDS: {e}", "danger")
    else:
        flash("⚠️ Database RDS tidak terhubung.", "danger")

    return redirect(url_for("index"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80, debug=False)
EOF

# 6. Salin template index.html
cat << 'EOF' > /opt/cloudretail/templates/index.html
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CloudRetail Portal | AWS Learner Lab Showcase</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700&family=Plus+Jakarta+Sans:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0d1117;
      --card: rgba(22, 27, 34, 0.9);
      --border: #30363d;
      --text: #f0f6fc;
      --muted: #8b949e;
      --aws: #ff9900;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: radial-gradient(circle at 10% 10%, #161b22 0%, #090d16 100%);
      color: var(--text);
      font-family: 'Plus Jakarta Sans', sans-serif;
      min-height: 100vh;
      padding: 24px;
    }
    .container { max-width: 1200px; margin: 0 auto; }
    header {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 24px 30px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
      margin-bottom: 24px;
    }
    header h1 {
      font-family: 'Outfit', sans-serif;
      font-size: 26px;
      background: linear-gradient(135deg, #ff9900, #ffc837);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .host-pill {
      background: rgba(56, 139, 253, 0.1);
      border: 1px solid rgba(56, 139, 253, 0.4);
      padding: 10px 18px;
      border-radius: 12px;
      text-align: right;
    }
    .host-pill .val { font-family: monospace; font-weight: 700; color: #79c0ff; font-size: 15px; }
    .az-badge { background: #238636; color: #fff; font-size: 11px; padding: 2px 8px; border-radius: 6px; font-weight: 600; display: inline-block; margin-top: 4px; }
    .services-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }
    .service-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 16px;
    }
    .service-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
    .badge { font-size: 11px; font-weight: 600; padding: 3px 8px; border-radius: 12px; }
    .badge-ok { background: rgba(35, 134, 54, 0.2); color: #3fb950; border: 1px solid #238636; }
    .badge-err { background: rgba(218, 54, 51, 0.2); color: #f85149; border: 1px solid #da3633; }
    .badge-warn { background: rgba(210, 153, 34, 0.2); color: #d29922; border: 1px solid #d29922; }
    .service-detail { font-size: 12px; color: var(--muted); word-break: break-all; }
    .dashboard-layout { display: grid; grid-template-columns: 1fr 2fr; gap: 24px; margin-bottom: 24px; }
    @media (max-width: 860px) { .dashboard-layout { grid-template-columns: 1fr; } }
    .card { background: var(--card); border: 1px solid var(--border); border-radius: 16px; padding: 24px; }
    .card h2 { font-family: 'Outfit', sans-serif; font-size: 18px; margin-bottom: 14px; }
    .form-group { margin-bottom: 12px; }
    label { display: block; font-size: 12px; color: var(--muted); margin-bottom: 4px; }
    input[type="text"], input[type="number"], input[type="file"] {
      width: 100%; padding: 10px; background: #0d1117; border: 1px solid #30363d; border-radius: 8px; color: #fff; font-size: 13px;
    }
    button.btn {
      width: 100%; background: linear-gradient(135deg, #ff9900, #e07f00); border: none; padding: 12px; border-radius: 8px; font-weight: 700; cursor: pointer; color: #000; margin-top: 8px;
    }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    th { text-align: left; padding: 10px; border-bottom: 1px solid #30363d; color: var(--muted); font-size: 11px; }
    td { padding: 10px; border-bottom: 1px solid #21262d; vertical-align: middle; }
    .product-img { width: 44px; height: 44px; border-radius: 6px; object-fit: cover; }
    .alert { padding: 10px 14px; border-radius: 8px; margin-bottom: 16px; font-size: 13px; }
    .alert-success { background: rgba(35, 134, 54, 0.2); border: 1px solid #238636; color: #3fb950; }
    .alert-danger { background: rgba(218, 54, 51, 0.2); border: 1px solid #da3633; color: #f85149; }
    .log-badge { background: rgba(163, 113, 247, 0.2); color: #d2a8ff; border: 1px solid rgba(163, 113, 247, 0.4); padding: 2px 6px; border-radius: 4px; font-size: 11px; font-family: monospace; }
  </style>
</head>
<body>
<div class="container">
  <header>
    <div>
      <h1>🚀 CloudRetail Portal</h1>
      <p style="font-size: 13px; color: var(--muted);">AWS Learner Lab Multi-Tier Showcase</p>
    </div>
    <div class="host-pill">
      <div style="font-size: 11px; color: var(--muted);">SERVED BY EC2</div>
      <div class="val">{{ instance_id }}</div>
      <div class="az-badge">AZ: {{ az }}</div><br>
      <a href="/" onclick="window.location.reload();" style="font-size: 11px; color: #58a6ff; text-decoration: none;">🔄 Refresh Test ALB</a>
    </div>
  </header>

  {% with messages = get_flashed_messages(with_categories=true) %}
    {% if messages %}
      {% for category, message in messages %}
        <div class="alert alert-{{ category }}">{{ message }}</div>
      {% endfor %}
    {% endif %}
  {% endwith %}

  <div class="services-grid">
    <div class="service-card">
      <div class="service-head"><span>⚖️ ALB & Target Group</span><span class="badge badge-ok">Active</span></div>
      <div class="service-detail">EC2: <strong>{{ instance_id }}</strong><br>Zone: <strong>{{ az }}</strong></div>
    </div>
    <div class="service-card">
      <div class="service-head"><span>🗄️ Amazon RDS</span>{% if rds_status %}<span class="badge badge-ok">Connected</span>{% else %}<span class="badge badge-err">Disconnected</span>{% endif %}</div>
      <div class="service-detail">Engine: MySQL 8.0<br>Host: {{ rds_host_display }}</div>
    </div>
    <div class="service-card">
      <div class="service-head"><span>🪣 Amazon S3</span>{% if s3_status %}<span class="badge badge-ok">Ready</span>{% else %}<span class="badge badge-warn">Not Found</span>{% endif %}</div>
      <div class="service-detail">Bucket: <strong>{{ s3_bucket_name }}</strong></div>
    </div>
    <div class="service-card">
      <div class="service-head"><span>⚡ Amazon DynamoDB</span>{% if dynamodb_status %}<span class="badge badge-ok">Ready</span>{% else %}<span class="badge badge-warn">Unavailable</span>{% endif %}</div>
      <div class="service-detail">Table: <strong>{{ dynamodb_table_name }}</strong></div>
    </div>
  </div>

  <div class="dashboard-layout">
    <div class="card">
      <h2>📦 Tambah Produk Baru</h2>
      <form action="/add-product" method="POST" enctype="multipart/form-data">
        <div class="form-group">
          <label>Nama Produk</label>
          <input type="text" name="name" placeholder="Misal: Monitor Gaming" required>
        </div>
        <div class="form-group">
          <label>Harga (Rp)</label>
          <input type="number" name="price" placeholder="2500000" required>
        </div>
        <div class="form-group">
          <label>Foto Produk (Upload S3)</label>
          <input type="file" name="image" accept="image/*">
        </div>
        <button type="submit" class="btn">💾 Simpan Data & Upload Media</button>
      </form>
    </div>

    <div class="card">
      <h2>📋 Data Produk di RDS MySQL</h2>
      <div style="overflow-x: auto;">
        <table>
          <thead>
            <tr><th>ID</th><th>Foto (S3)</th><th>Nama</th><th>Harga</th><th>Waktu</th></tr>
          </thead>
          <tbody>
            {% if products %}
              {% for p in products %}
                <tr>
                  <td>#{{ p.id }}</td>
                  <td>
                    {% if p.image_url %}
                      <a href="{{ p.image_url }}" target="_blank"><img src="{{ p.image_url }}" class="product-img"></a>
                    {% else %}-{% endif %}
                  </td>
                  <td><strong>{{ p.name }}</strong></td>
                  <td>Rp {{ "{:,.0f}".format(p.price) }}</td>
                  <td style="font-size: 11px; color: var(--muted);">{{ p.created_at }}</td>
                </tr>
              {% endfor %}
            {% else %}
              <tr><td colspan="5" style="text-align: center; color: var(--muted); padding: 20px;">Belum ada data di RDS MySQL.</td></tr>
            {% endif %}
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <div class="card">
    <h2>📊 Live Activity Logs (Amazon DynamoDB)</h2>
    <div style="overflow-x: auto;">
      <table>
        <thead>
          <tr><th>Waktu</th><th>Aksi</th><th>Instance ID</th><th>AZ</th><th>IP</th><th>Detail</th></tr>
        </thead>
        <tbody>
          {% if logs %}
            {% for log in logs %}
              <tr>
                <td style="font-size: 11px; font-family: monospace; color: var(--muted);">{{ log.timestamp }}</td>
                <td><span class="log-badge">{{ log.action }}</span></td>
                <td style="font-family: monospace; color: #79c0ff;">{{ log.instance_id }}</td>
                <td style="color: #3fb950; font-weight: 600;">{{ log.az }}</td>
                <td style="font-family: monospace; font-size: 11px;">{{ log.client_ip }}</td>
                <td>{{ log.detail }}</td>
              </tr>
            {% endfor %}
          {% else %}
            <tr><td colspan="6" style="text-align: center; color: var(--muted); padding: 20px;">Belum ada log di DynamoDB.</td></tr>
          {% endif %}
        </tbody>
      </table>
    </div>
  </div>
</div>
</body>
</html>
EOF

# 7. Buat file Environment Variables (EDIT SESUAI RESOURCE ANDA DI BAWAH INI)
# Catatan untuk Peserta: Ganti nilai RDS_HOST dan S3_BUCKET sesuai yang telah dibuat di AWS Console
cat << 'EOF' > /opt/cloudretail/cloudretail.env
AWS_REGION=us-east-1
RDS_HOST=REPLACE_WITH_YOUR_RDS_ENDPOINT
RDS_USER=admin
RDS_PASSWORD=Admin123456!
RDS_DATABASE=cloudretail
RDS_PORT=3306
S3_BUCKET=REPLACE_WITH_YOUR_S3_BUCKET_NAME
DYNAMODB_TABLE=CloudRetail-Logs
EOF

# 8. Buat Systemd Service agar Flask berjalan otomatis di port 80 sebagai daemon
cat << 'EOF' > /etc/systemd/system/cloudretail.service
[Unit]
Description=CloudRetail Flask Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/cloudretail
EnvironmentFile=/opt/cloudretail/cloudretail.env
ExecStart=/usr/bin/python3 /opt/cloudretail/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 9. Reload dan jalankan service
systemctl daemon-reload
systemctl enable cloudretail.service
systemctl start cloudretail.service

echo "=== Inisialisasi CloudRetail Selesai ==="
