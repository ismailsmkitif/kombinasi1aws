# 📑 LEMBAR SOAL UJIAN PRAKTIK SELEKSI
## BIDANG LOMBA / KOMPETENSI: CLOUD COMPUTING
### Topik: Rancang Bangun Arsitektur Web Multi-Tier & High-Availability Berbasis AWS Services

---

| Informasi Ujian | Keterangan |
| :--- | :--- |
| **Waktu Pengerjaan** | 120 – 180 Menit |
| **Metode Pelaksanaan**| Praktik Mandiri via **AWS Management Console** |
| **Platform Target**   | **AWS Academy Learner Lab** |
| **Region Wajib**      | `us-east-1` (US East - N. Virginia) |
| **Sifat Ujian**       | Praktik Terbuka (*Open-Reference Documentation*) |

---

## I. DESKRIPSI STUDI KASUS

Perusahaan ritel online **CloudRetail Indonesia** sedang mengalami lonjakan pengunjung yang signifikan pada platform web mereka. Untuk meningkatkan keandalan sistem dan menghindari gangguan operasional (*downtime*), manajemen memutuskan untuk memigrasikan arsitektur aplikasi mereka ke AWS Cloud dengan standar industri modern:

1. **Jaringan Terisolasi & Bertingkat (*Network Tiering*)**: Aplikasi harus berjalan di dalam VPC privat khusus dengan pembagian zona publik dan privat di minimal 2 Availability Zone.
2. **Ketersediaan Tinggi (*High Availability*)**: Beban akses pelanggan dari internet harus didistribusikan secara otomatis melalui Load Balancer ke dua web server yang berada di zona fisik berbeda.
3. **Pemisahan Penyimpanan Data (*Polyglot Persistence*)**:
   - Master katalog produk dan data transaksi disimpan pada database relasional (**RDS MySQL**) di zona privat.
   - File gambar produk yang diunggah pengguna disimpan pada object storage (**Amazon S3**).
   - Log audit dan riwayat aktivitas kunjungan pengunjung disimpan secara instan pada database NoSQL tanpa server (**Amazon DynamoDB**).
4. **Keamanan Tanpa Hardcoded Key**: Seluruh interaksi EC2 ke S3 dan DynamoDB harus menggunakan peran IAM berbasis role (`LabRole`) tanpa menyimpan kredensial sensitif di dalam kode.

Sebagai seorang **Cloud Solutions Architect / Cloud Engineer**, Anda ditugaskan untuk mengimplementasikan dan menguji seluruh rancangan arsitektur ini melalui **AWS Management Console**.

---

## II. DAFTAR TUGAS PESERTA (TASKS)

### Tugas 1: Konfigurasi Jaringan & Keamanan (VPC, Subnet, Route Table, Security Group)
1. Buat sebuah Custom VPC dengan nama **`CloudRetail-VPC`** dan IPv4 CIDR **`10.0.0.0/16`**.
2. Buat **4 Subnet** yang terdistribusi di dua Availability Zone (`us-east-1a` dan `us-east-1b`):
   - `Public-Subnet-A`: CIDR `10.0.1.0/24` (AZ `us-east-1a`)
   - `Public-Subnet-B`: CIDR `10.0.2.0/24` (AZ `us-east-1b`)
   - `Private-Subnet-A`: CIDR `10.0.11.0/24` (AZ `us-east-1a`)
   - `Private-Subnet-B`: CIDR `10.0.12.0/24` (AZ `us-east-1b`)
3. Aktifkan fitur *Auto-assign public IPv4 address* pada kedua Public Subnet.
4. Buat Internet Gateway **`CloudRetail-IGW`** dan tautkan (*Attach*) ke `CloudRetail-VPC`.
5. Buat **Public-Route-Table** dengan rute default `0.0.0.0/0` menuju Internet Gateway, dan asosiasikan ke `Public-Subnet-A` serta `Public-Subnet-B`.
6. Buat **Private-Route-Table** dan asosiasikan ke `Private-Subnet-A` serta `Private-Subnet-B` (tanpa rute ke IGW).
7. Buat 3 Security Groups berjenjang:
   - **`alb-sg`**: Port 80 (HTTP) dari `0.0.0.0/0`.
   - **`ec2-sg`**: Port 80 (HTTP) dari `alb-sg` (atau `0.0.0.0/0`).
   - **`rds-sg`**: Port 3306 (MySQL) hanya dari sumber `ec2-sg`.

---

### Tugas 2: Penyimpanan Object Storage & NoSQL (Amazon S3 & DynamoDB)
1. Buat sebuah S3 Bucket bernama **`cloudretail-bucket-<nama/id-anda>`** di region `us-east-1`.
   - Aktifkan perlindungan bawaan dan simpan data secara aman.
2. Buat sebuah tabel Amazon DynamoDB:
   - Nama Tabel: **`CloudRetail-Logs`** *(Case-sensitive)*.
   - Partition Key: **`log_id`** (Tipe data: `String`).
   - Kapasitas: On-Demand.

---

### Tugas 3: Database Relasional Privat (Amazon RDS MySQL)
1. Buat **DB Subnet Group** bernama **`cloudretail-db-subnet-group`** di dalam `CloudRetail-VPC` yang mencakup `Private-Subnet-A` dan `Private-Subnet-B`.
2. Buat database instance **Amazon RDS MySQL**:
   - Engine: MySQL 8.0
   - Template: **Free tier** (Single-AZ, `db.t3.micro` atau `db.t2.micro`)
   - DB instance identifier: `cloudretail-mysql`
   - Master username: `admin` | Password: `Admin123456!`
   - VPC: `CloudRetail-VPC` | Subnet Group: `cloudretail-db-subnet-group`
   - Public access: **No**
   - Security Group: **`rds-sg`**
   - Initial database name: **`cloudretail`**
3. Catat **RDS Endpoint** setelah instance berstatus *Available*.

---

### Tugas 4: Peluncuran Compute Tier (EC2 Instances dengan User Data)
1. Luncurkan **`EC2-Web-Server-A`**:
   - AMI: Amazon Linux 2023 AMI | Tipe: `t2.micro` / `t3.micro`
   - Subnet: `Public-Subnet-A` | Public IP: Enabled | SG: `ec2-sg`
   - IAM Role: **`LabRole`**
   - User Data: Pasang script bootstrap aplikasi dengan endpoint RDS dan nama S3 yang telah dibuat.
2. Luncurkan **`EC2-Web-Server-B`**:
   - AMI: Amazon Linux 2023 AMI | Tipe: `t2.micro` / `t3.micro`
   - Subnet: `Public-Subnet-B` (AZ B) | Public IP: Enabled | SG: `ec2-sg`
   - IAM Role: **`LabRole`**
   - User Data: Pasang script yang sama.

---

### Tugas 5: Penyeimbang Beban & Ketersediaan Tinggi (Target Group & ALB)
1. Buat Target Group bernama **`tg-cloudretail`**:
   - Target type: Instances | Protokol: HTTP Port 80 | VPC: `CloudRetail-VPC`
   - Health check path: `/health`
   - Daftarkan target: `EC2-Web-Server-A` dan `EC2-Web-Server-B`.
2. Buat Application Load Balancer bernama **`alb-cloudretail`**:
   - Scheme: Internet-facing | IPv4
   - VPC: `CloudRetail-VPC`
   - Subnet Mapping: Centang `Public-Subnet-A` dan `Public-Subnet-B`.
   - Security Group: `alb-sg`
   - Listener: HTTP Port 80 -> Forward ke `tg-cloudretail`.
3. Verifikasi status target hingga berstatus **Healthy**.

---

### Tugas 6: Pengujian Terpadu & Demonstrasi Hasil
Peserta wajib mendemonstrasikan hasil akhir kepada penguji/evaluator:
1. Akses web aplikasi melalui **DNS Name ALB**.
2. Buktikan distribusi beban (*Round-Robin*) berjalan saat halaman direfresh.
3. Tambahkan 1 produk baru dengan mengunggah gambar. Tunjukkan bahwa data tersimpan di RDS MySQL dan gambar tersimpan di Amazon S3.
4. Tunjukkan tabel live audit log mencatat transaksi di DynamoDB.
5. Lakukan simulasi failover: Matikan salah satu EC2 dan buktikan web portal tetap dapat melayani pengunjung (*Zero Downtime*).

---

## III. FORMAT PENGUMPULAN & DOKUMENTASI
Peserta mengumpulkan laporan singkat berformat PDF/Markdown yang memuat:
1. DNS URL Application Load Balancer.
2. Screenshot arsitektur VPC & Subnet di AWS Console.
3. Screenshot Target Group berstatus *2 Healthy*.
4. Screenshot Portal Web CloudRetail yang menampilkan integrasi RDS, S3, dan DynamoDB.
5. Screenshot item pada S3 Bucket dan tabel DynamoDB di AWS Console.
