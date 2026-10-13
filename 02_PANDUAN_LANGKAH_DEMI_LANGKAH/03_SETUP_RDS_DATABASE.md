# 🗄️ Modul 03: Setup Relational Database Amazon RDS MySQL (Konsol AWS)

Pada modul ini, kita akan membuat database relasional **Amazon RDS MySQL** yang ditempatkan secara aman di dalam **Private Subnet** dan hanya dapat diakses oleh instance EC2 melalui security group `rds-sg`.

---

## Langkah 1: Membuat DB Subnet Group

RDS memerlukan minimal 2 subnet di Availability Zone yang berbeda untuk membentuk sebuah grup subnet (*DB Subnet Group*).

1. Pada bilah pencarian AWS Console, ketik **`RDS`** lalu klik layanan **RDS**.
2. Pada panel navigasi di sebelah kiri, klik **Subnet groups**.
3. Klik tombol oranye **Create DB subnet group**.
4. Lengkapi formulir konfigurasi:
   - **Name**: `cloudretail-db-subnet-group`
   - **Description**: `Subnet group di Private Subnet untuk CloudRetail`
   - **VPC**: Pilih **`CloudRetail-VPC`**
5. Pada bagian **Add subnets**:
   - **Availability Zones**: Centang dua zona:
     - ☑ `us-east-1a`
     - ☑ `us-east-1b`
   - **Subnets**: Pilih dua subnet privat yang telah dibuat sebelumnya:
     - ☑ Subnet dengan CIDR `10.0.11.0/24` (*Private-Subnet-A*)
     - ☑ Subnet dengan CIDR `10.0.12.0/24` (*Private-Subnet-B*)
6. Klik tombol **Create** di bagian paling bawah.

---

## Langkah 2: Membuat RDS MySQL Instance

> [!IMPORTANT]
> Pilih template **Free Tier** untuk membatasi ukuran instance ke kelas micro (`db.t3.micro` / `db.t2.micro`) dan memastikan konfigurasi Single-AZ agar hemat saldo kredit lab Anda!

1. Pada menu sebelah kiri RDS Console, klik **Databases**.
2. Klik tombol oranye **Create database**.
3. **Choose a database creation method**: Pilih **Standard create**.
4. **Engine options**:
   - Engine type: **MySQL**
   - Engine Version: Biarkan versi default (contoh: MySQL 8.0.x).
5. **Templates**: Pilih **Free tier**.
6. **Settings**:
   - **DB instance identifier**: Ketik **`cloudretail-mysql`**
   - **Master username**: Ketik **`admin`**
   - **Master password**: Ketik **`Admin123456!`**
   - **Confirm master password**: Ketik **`Admin123456!`**
7. **Instance configuration**:
   - DB instance class: Pastikan memilih **Burstable classes (includes t classes)** -> **`db.t3.micro`** (atau `db.t2.micro`).
8. **Storage**:
   - Storage type: **General Purpose SSD (gp2 atau gp3)**
   - Allocated storage: **20** GiB
   - **Storage autoscaling**: **Hapus centang (Uncheck)** pada *Enable storage autoscaling*.
9. **Connectivity**:
   - **Compute resource**: Pilih *Don’t connect to an EC2 compute resource*.
   - **Network type**: *IPv4*.
   - **Virtual private cloud (VPC)**: Pilih **`CloudRetail-VPC`**.
   - **DB Subnet group**: Pilih **`cloudretail-db-subnet-group`**.
   - **Public access**: Pilih **No** *(Database privat terlindung dari akses publik)*.
   - **VPC security group (firewall)**:
     - Pilih opsi **Choose existing**.
     - Hapus *default* jika terpasang, lalu centang dan pilih **`rds-sg`**.
   - **Availability Zone**: Pilih *No preference*.
   - **Database port**: Biarkan default `3306`.
10. **Database authentication**: Pilih **Password authentication**.
11. **Additional configuration** (Klik panah untuk membuka):
    - **Initial database name**: Ketik **`cloudretail`** *(Penting: nama database default aplikasi)*.
    - **Backup**: Hilangkan centang *Enable automated backups* jika ingin mempercepat proses provision.
    - **Deletion protection**: Pastikan **tidak tercentang** (agar mudah dihapus saat pembersihan lab).
12. Gulir ke bawah lalu klik **Create database**.

---

## Langkah 3: Menunggu & Mencatat RDS Endpoint

1. Status instance akan menampilkan **Creating**. Proses ini biasanya memakan waktu **5 hingga 10 menit**.
2. Anda dapat melanjutkan ke Modul 04 terlebih dahulu sambil menunggu status database berubah menjadi **Available**.
3. Setelah status menjadi **Available**:
   - Klik nama database **`cloudretail-mysql`**.
   - Pada tab **Connectivity & security**, perhatikan bagian **Endpoint**.
   - Format endpoint akan tampak seperti:  
     `cloudretail-mysql.c7abcde12345.us-east-1.rds.amazonaws.com`
   - **Salin (Copy) Endpoint ini**, Anda akan memerlukannya pada langkah konfigurasi EC2 Web Server!

---

✅ **Hasil Akhir Modul 03**: Database MySQL telah berhasil dibuat di lingkungan private subnet terisolasi dan siap menerima query dari EC2 Web Server!
