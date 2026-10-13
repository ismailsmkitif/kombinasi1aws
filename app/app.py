import os
import uuid
import datetime
import urllib.request
from flask import Flask, render_template, request, redirect, url_for, flash
import pymysql
import boto3
from botocore.exceptions import ClientError, BotoCoreError

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", "aws-learner-lab-secret-key-2026")

# Konfigurasi AWS & Database dari Environment Variable
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
S3_BUCKET = os.environ.get("S3_BUCKET", "cloudretail-bucket-learnerlab")
DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "CloudRetail-Logs")

RDS_HOST = os.environ.get("RDS_HOST", "")
RDS_USER = os.environ.get("RDS_USER", "admin")
RDS_PASSWORD = os.environ.get("RDS_PASSWORD", "Admin123456!")
RDS_DATABASE = os.environ.get("RDS_DATABASE", "cloudretail")
RDS_PORT = int(os.environ.get("RDS_PORT", 3306))

# Helper untuk mendapatkan Metadata EC2 (IMDSv2)
def get_instance_metadata():
    instance_id = "local-instance"
    az = "local-az"
    try:
        # Request token IMDSv2
        token_req = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "60"},
            method="PUT"
        )
        with urllib.request.urlopen(token_req, timeout=1) as response:
            token = response.read().decode("utf-8")

        # Request Instance ID
        id_req = urllib.request.Request(
            "http://169.254.169.254/latest/meta-data/instance-id",
            headers={"X-aws-ec2-metadata-token": token}
        )
        with urllib.request.urlopen(id_req, timeout=1) as response:
            instance_id = response.read().decode("utf-8")

        # Request Availability Zone
        az_req = urllib.request.Request(
            "http://169.254.169.254/latest/meta-data/placement/availability-zone",
            headers={"X-aws-ec2-metadata-token": token}
        )
        with urllib.request.urlopen(az_req, timeout=1) as response:
            az = response.read().decode("utf-8")
    except Exception:
        # Berjalan di lingkungan non-EC2 atau metadata dinonaktifkan
        pass
    return instance_id, az

# Inisialisasi Koneksi RDS & Auto-create Table
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
        print(f"[RDS Error] Failed to connect: {e}")
        return None

# AWS SDK Clients
def get_s3_client():
    return boto3.client("s3", region_name=AWS_REGION)

def get_dynamodb_resource():
    return boto3.resource("dynamodb", region_name=AWS_REGION)

# Fungsi Logging ke DynamoDB
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
        print(f"[DynamoDB Error] Gagal menulis log: {e}")

# Health Check Route untuk ALB Target Group
@app.route("/health", methods=["GET"])
def health_check():
    return "OK", 200

# Route Utama Dashboard
@app.route("/", methods=["GET"])
def index():
    instance_id, az = get_instance_metadata()
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)

    # Catat log kunjungan ke DynamoDB
    log_activity("PAGE_VISIT", f"User mengakses halaman utama dari IP: {client_ip}", client_ip)

    # Cek Status RDS & Ambil Data Produk
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
        except Exception as e:
            print(f"[RDS Query Error]: {e}")
            rds_status = False

    # Cek Status & Ambil Log dari DynamoDB
    dynamodb_status = False
    logs = []
    try:
        dynamodb = get_dynamodb_resource()
        table = dynamodb.Table(DYNAMODB_TABLE)
        # Ambil sampel log terkini
        response = table.scan(Limit=30)
        logs = response.get("Items", [])
        logs.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        logs = logs[:10]
        dynamodb_status = True
    except Exception as e:
        print(f"[DynamoDB Query Error]: {e}")
        dynamodb_status = False

    # Cek Status S3
    s3_status = False
    try:
        s3 = get_s3_client()
        s3.head_bucket(Bucket=S3_BUCKET)
        s3_status = True
    except Exception as e:
        print(f"[S3 Check Error]: {e}")
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

# Route Tambah Produk
@app.route("/add-product", methods=["POST"])
def add_product():
    name = request.form.get("name")
    price = request.form.get("price")
    image_file = request.files.get("image")
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)

    image_url = ""

    # 1. Upload Gambar ke S3 jika ada
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
            # Buat Presigned URL agar dapat ditampilkan dengan aman
            image_url = s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": S3_BUCKET, "Key": unique_filename},
                ExpiresIn=604800  # 7 hari
            )
        except Exception as e:
            flash(f"Gagal mengunggah foto ke S3: {e}", "danger")
            log_activity("UPLOAD_S3_FAILED", f"Error upload {image_file.filename}: {e}", client_ip)

    # 2. Simpan Data ke RDS MySQL
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
            flash("✅ Produk berhasil disimpan ke RDS MySQL dan foto diunggah ke S3!", "success")
            log_activity("PRODUCT_ADDED", f"Produk baru ditambahkan: '{name}' (Rp {price})", client_ip)
        except Exception as e:
            flash(f"Gagal menyimpan data ke RDS MySQL: {e}", "danger")
            log_activity("RDS_INSERT_FAILED", f"Gagal simpan produk: {e}", client_ip)
    else:
        flash("⚠️ Database RDS belum terhubung. Pastikan RDS_HOST sudah benar dan security group mengizinkan koneksi port 3306.", "danger")

    return redirect(url_for("index"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80, debug=False)
