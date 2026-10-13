# 💻 Modul 04: Deploy EC2 Web Server Multi-AZ (Konsol AWS)

Pada modul ini, kita akan meluncurkan dua instance virtual machine **Amazon EC2** di dua Availability Zone yang berbeda (`us-east-1a` dan `us-east-1b`). Kedua instance akan dipasangi IAM Role **`LabRole`** dan dikonfigurasi secara otomatis menggunakan **User Data Bootstrap Script**.

---

## Persiapan Script User Data

Sebelum meluncurkan instance, pastikan Anda telah menyiapkan teks User Data dari file [`app/user_data.sh`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/app/user_data.sh).

Cari bagian berikut di dalam script `user_data.sh`:
```bash
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
```

Ganti nilai:
- `REPLACE_WITH_YOUR_RDS_ENDPOINT` dengan endpoint database RDS Anda (misal: `cloudretail-mysql.c7abcde12345.us-east-1.rds.amazonaws.com`).
- `REPLACE_WITH_YOUR_S3_BUCKET_NAME` dengan nama S3 bucket Anda (misal: `cloudretail-bucket-ismail2026`).

---

## Langkah 1: Meluncurkan EC2 Server 1 (`EC2-Web-Server-A`)

1. Pada bilah pencarian AWS Console, ketik **`EC2`** lalu klik layanan **EC2**.
2. Di menu kiri klik **Instances**, lalu klik tombol oranye **Launch instances**.
3. **Name and tags**:
   - Beri nama: **`EC2-Web-Server-A`**
4. **Application and OS Images (Amazon Machine Image)**:
   - Pilih **Amazon Linux**.
   - Pada dropdown *AMI*, pilih **Amazon Linux 2023 AMI** (*Free tier eligible*).
5. **Instance type**:
   - Pilih **`t2.micro`** atau **`t3.micro`**.
6. **Key pair (login)**:
   - Pilih key pair yang tersedia (contoh: `vockey`), atau pilih **Proceed without a key pair (Not recommended)** karena seluruh instalasi berjalan otomatis via script.
7. **Network settings** (Klik tombol **Edit** di kanan atas kotak ini):
   - **VPC**: Pilih **`CloudRetail-VPC`**
   - **Subnet**: Pilih **`Public-Subnet-A`** (`us-east-1a`)
   - **Auto-assign public IP**: Pilih **Enable**
   - **Firewall (security groups)**: Pilih **Select existing security group**, lalu centang **`ec2-sg`**.
8. **Configure storage**:
   - Biarkan default: **8 GiB gp3**.
9. **Advanced details** (Klik panah untuk memperluas bagian ini):
   - **IAM instance profile**: ⚠️ **PENTING: Pilih `LabRole`**  
     *(Jika tidak dipilih, EC2 tidak akan bisa mengakses S3 dan DynamoDB!)*
   - Gulir terus ke paling bawah hingga menemukan kolom **User data**.
   - Salin dan tempelkan (*Paste*) seluruh teks script dari [`app/user_data.sh`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/app/user_data.sh) yang sudah Anda lengkapi dengan nilai `RDS_HOST` dan `S3_BUCKET`.
10. Klik tombol oranye **Launch instance** di panel sebelah kanan.

---

## Langkah 2: Meluncurkan EC2 Server 2 (`EC2-Web-Server-B`)

Lakukan langkah yang sama untuk meluncurkan server kedua pada Availability Zone B:

1. Di menu EC2 Instances, klik kembali tombol **Launch instances**.
2. **Name and tags**: Beri nama **`EC2-Web-Server-B`**
3. **AMI**: Pilih **Amazon Linux 2023 AMI**
4. **Instance type**: `t2.micro` atau `t3.micro`
5. **Key pair**: Sama seperti server pertama
6. **Network settings** (Klik **Edit**):
   - **VPC**: Pilih **`CloudRetail-VPC`**
   - **Subnet**: Pilih **`Public-Subnet-B`** (`us-east-1b`) ⚠️ *(Harus di Subnet B!)*
   - **Auto-assign public IP**: **Enable**
   - **Security groups**: Pilih **`ec2-sg`**
7. **Advanced details**:
   - **IAM instance profile**: Pilih **`LabRole`**
   - **User data**: Paste script yang sama persis dengan yang digunakan pada Server A.
8. Klik **Launch instance**.

---

## Langkah 3: Verifikasi Pengujian Mandiri

1. Tunggu 2–3 menit agar script User Data selesai mengunduh pustaka Python dan menyalakan aplikasi web.
2. Pada tabel daftar instance EC2:
   - Klik instance **`EC2-Web-Server-A`**, salin **Public IPv4 address**-nya.
   - Buka tab baru di browser: `http://<PUBLIC_IP_SERVER_A>`.
   - Pastikan halaman portal **CloudRetail** terbuka dan menampilkan kartu informasi:
     - Instance ID: `i-xxxxxxxxxxxx`
     - AZ: `us-east-1a`
     - Status RDS: *Connected*
     - Status S3: *Ready*
     - Status DynamoDB: *Ready*
3. Lakukan pengecekan pada **`EC2-Web-Server-B`**:
   - Buka tab browser: `http://<PUBLIC_IP_SERVER_B>`.
   - Pastikan AZ yang ditampilkan adalah **`us-east-1b`**.

---

✅ **Hasil Akhir Modul 04**: Kedua EC2 Web Server telah berjalan aktif di dua Availability Zone terpisah, masing-masing terhubung secara mandiri ke RDS, S3, dan DynamoDB!
