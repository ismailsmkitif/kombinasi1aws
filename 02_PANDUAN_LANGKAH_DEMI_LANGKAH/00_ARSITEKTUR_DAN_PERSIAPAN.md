# 📐 Modul 00: Arsitektur Sistem & Ketentuan AWS Learner Lab

Dokumen ini memuat rancangan topologi jaringan, skema pengalamatan IP, serta aturan penting yang berlaku di lingkungan **AWS Academy Learner Lab**.

---

## 1. Topologi Jaringan & Skema CIDR

Untuk memastikan prinsip *High Availability* (Ketersediaan Tinggi) dan pemisahan lapisan (*Multi-Tier Segregation*), infrastruktur dibangun di atas **2 Availability Zones** (`us-east-1a` dan `us-east-1b`).

```
+-----------------------------------------------------------------------------------+
| Custom VPC: CloudRetail-VPC (10.0.0.0/16)                                         |
|                                                                                   |
|  +-------------------------------------+   +-------------------------------------+|
|  | Availability Zone: us-east-1a       |   | Availability Zone: us-east-1b       | |
|  |                                     |   |                                     | |
|  |  [ Public Subnet A ] (10.0.1.0/24)  |   |  [ Public Subnet B ] (10.0.2.0/24)  | |
|  |   - ALB Listener Node               |   |   - ALB Listener Node               | |
|  |   - EC2 Web Server 1                |   |   - EC2 Web Server 2                | |
|  +-------------------------------------+   +-------------------------------------+|
|                                                                                   |
|  +-------------------------------------+   +-------------------------------------+|
|  |  [ Private Subnet A ] (10.0.11.0/24)|   |  [ Private Subnet B ] (10.0.12.0/24)| |
|  |   - RDS MySQL Subnet Member         |   |   - RDS MySQL Primary/Subnet Member | |
|  +-------------------------------------+   +-------------------------------------+|
|                                                                                   |
|  Internet Gateway: CloudRetail-IGW (Terhubung ke Public Route Table)              |
+-----------------------------------------------------------------------------------+
```

### Tabel Rincian Subnet
| Nama Subnet | Availability Zone | CIDR Block | Tipe Akses | Fungsi Utama |
| :--- | :--- | :--- | :--- | :--- |
| `Public-Subnet-A` | `us-east-1a` | `10.0.1.0/24` | Public (Route ke IGW) | ALB Node & EC2 Instance 1 |
| `Public-Subnet-B` | `us-east-1b` | `10.0.2.0/24` | Public (Route ke IGW) | ALB Node & EC2 Instance 2 |
| `Private-Subnet-A`| `us-east-1a` | `10.0.11.0/24` | Private (No IGW) | RDS DB Subnet Group |
| `Private-Subnet-B`| `us-east-1b` | `10.0.12.0/24` | Private (No IGW) | RDS DB Subnet Group |

---

## 2. Matriks Keamanan (Security Groups)

Prinsip *Least Privilege* diterapkan dengan cara membatasi akses port hanya dari grup keamanan yang membutuhkan:

| Nama Security Group | Deskripsi | Inbound Rules | Outbound Rules |
| :--- | :--- | :--- | :--- |
| `alb-sg` | Security Group untuk ALB | **HTTP (80)** dari `0.0.0.0/0` | All Traffic (`0.0.0.0/0`) |
| `ec2-sg` | Security Group untuk Web Server EC2 | **HTTP (80)** dari sumber `alb-sg` (atau `0.0.0.0/0` untuk fleksibilitas lab) | All Traffic (`0.0.0.0/0`) |
| `rds-sg` | Security Group untuk Database RDS MySQL | **MySQL/Aurora (3306)** dari sumber `ec2-sg` | All Traffic (`0.0.0.0/0`) |

---

## 3. Ketentuan Khusus AWS Academy Learner Lab

Saat mengerjakan proyek ini di AWS Learner Lab, perhatikan poin-poin penting berikut:

> [!IMPORTANT]
> **1. IAM Role Pre-Created (`LabRole`)**
> Akun peserta Learner Lab **TIDAK memiliki izin** membuat IAM Role atau Policy baru. Namun, AWS Academy telah menyediakan sebuah IAM Role bernama **`LabRole`** (dan Instance Profile `LabInstanceProfile`).
> Saat meluncurkan EC2, Anda **WAJIB** memilih IAM role **`LabRole`** agar aplikasi web otomatis memiliki izin membaca/menulis ke **Amazon S3** dan **Amazon DynamoDB** tanpa perlu konfigurasi Access Key!

> [!WARNING]
> **2. Batasan Region & Saldo Lab ($100)**
> - Pastikan selalu memilih region **`us-east-1` (N. Virginia)** di pojok kanan atas AWS Console.
> - Hindari memilih tipe instance besar! Gunakan:
>   - EC2: `t2.micro` atau `t3.micro`
>   - RDS: `db.t3.micro` atau `db.t2.micro` (Single-AZ, Non-Multi-AZ untuk menghemat biaya)
> - Setiap selesai sesi belajar, ikuti panduan pembersihan resource agar saldo kredit lab tidak habis otomatis karena RDS atau Load Balancer yang berjalan terus-menerus.

> [!NOTE]
> **3. Session Timer & Auto Stop**
> Lingkungan Learner Lab memiliki batas waktu aktif per sesi (biasanya 4 jam). Jika sesi habis, status lab menjadi *Inactive*.
> Anda cukup mengklik **Start Lab** kembali, lalu login ke AWS Console. Resource Anda (VPC, S3, RDS, EC2) tetap ada dan dapat dinyalakan kembali (*Start Instance*).
