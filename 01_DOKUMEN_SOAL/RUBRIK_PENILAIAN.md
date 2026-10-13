# 📊 RUBRIK PENILAIAN & CHECKLIST EVALUATOR
## Ujian Praktik / Seleksi Cloud Computing AWS Learner Lab
### Proyek: CloudRetail Multi-Tier & High-Availability Architecture

---

| Informasi Penilaian | Rincian |
| :--- | :--- |
| **Total Skor Maksimal** | **100 Poin** |
| **Standar Kelulusan (Passing Grade)** | **75 Poin** |
| **Nama Peserta** | ____________________________________ |
| **Nomor Induk / NIM / No. Ujian** | ____________________________________ |
| **Nama Evaluator / Penguji** | ____________________________________ |
| **Tanggal Penilaian** | ____________________________________ |

---

## I. TABEL DISTRIBUSI BOBOT NILAI

| No | Komponen Penilaian | Bobot Maksimal | Nilai Diperoleh |
| :---: | :--- | :---: | :---: |
| 1 | Konfigurasi Networking & Security (VPC, Subnet, SG, IGW) | **20 Poin** | ______ |
| 2 | Konfigurasi Database & Storage (S3, DynamoDB, RDS MySQL) | **25 Poin** | ______ |
| 3 | Konfigurasi Compute Tier & IAM Role (EC2 Multi-AZ) | **20 Poin** | ______ |
| 4 | Load Balancing & High Availability (ALB & Target Group) | **20 Poin** | ______ |
| 5 | Pengujian Integrasi Terpadu & Skenario Failover | **15 Poin** | ______ |
| **TOTAL** | **KUMULATIF NILAI AKHIR** | **100 Poin** | ______ |

---

## II. CHECKLIST DETAIL & INDIKATOR PENILAIAN

### 1. Networking & Security Tier (Maks. 20 Poin)
- [ ] **Custom VPC (3 Poin)**: `CloudRetail-VPC` dibuat dengan CIDR `10.0.0.0/16` tanpa menggunakan Default VPC.
- [ ] **Subnet Multi-AZ (5 Poin)**: Tersedia 4 subnet terpisah di 2 Availability Zone (`us-east-1a` dan `us-east-1b`):
  - 2 Public Subnet (`10.0.1.0/24` & `10.0.2.0/24`) dengan auto-assign public IPv4 aktif.
  - 2 Private Subnet (`10.0.11.0/24` & `10.0.12.0/24`).
- [ ] **Routing & IGW (6 Poin)**:
  - Internet Gateway terpasang ke VPC.
  - Public Route Table mengarahkan rute `0.0.0.0/0` ke Internet Gateway.
  - Private Route Table terisolasi tanpa akses langsung ke internet publik.
- [ ] **Security Group Tiering (6 Poin)**:
  - `alb-sg`: Mengizinkan Inbound HTTP (80) dari publik (`0.0.0.0/0`).
  - `ec2-sg`: Mengizinkan Inbound HTTP (80) dari `alb-sg`.
  - `rds-sg`: Mengizinkan Inbound MySQL (3306) eksklusif hanya dari `ec2-sg`.

---

### 2. Database & Storage Tier (Maks. 25 Poin)
- [ ] **Amazon S3 (5 Poin)**: Bucket S3 berhasil dibuat di region `us-east-1` dengan penamaan unik global.
- [ ] **Amazon DynamoDB (5 Poin)**: Tabel `CloudRetail-Logs` aktif dengan Partition Key `log_id` (String) dan mode On-Demand.
- [ ] **DB Subnet Group (5 Poin)**: Grup subnet mencakup minimal 2 private subnet di 2 AZ yang berbeda.
- [ ] **Amazon RDS MySQL (10 Poin)**:
  - Instance MySQL 8.0 berhasil dibuat dengan kelas Free Tier (`db.t3.micro` / `db.t2.micro`).
  - Ditempatkan di dalam VPC dan Subnet Group privat dengan public access dinonaktifkan (*No*).
  - Database awal `cloudretail` terbuat dan endpoint dapat diakses oleh EC2.

---

### 3. Compute Tier & IAM Role (Maks. 20 Poin)
- [ ] **Distribusi Multi-AZ (5 Poin)**: Server A berada di `Public-Subnet-A` (AZ 1a) dan Server B berada di `Public-Subnet-B` (AZ 1b).
- [ ] **IAM Role `LabRole` (5 Poin)**: Kedua instance EC2 terpasang IAM Instance Profile `LabRole` sehingga memiliki akses SDK ke S3 dan DynamoDB tanpa hardcoded access key.
- [ ] **Eksekusi User Data & Web Service (10 Poin)**: Script bootstrap berhasil mengeksekusi instalasi dependency, membuat systemd service, dan aplikasi Flask berjalan pada port 80.

---

### 4. Load Balancing & High Availability (Maks. 20 Poin)
- [ ] **Target Group (5 Poin)**: `tg-cloudretail` mendaftarkan kedua instance EC2 pada port 80 dengan health check path `/health`.
- [ ] **Application Load Balancer (5 Poin)**: ALB bersifat *Internet-facing*, memetakan 2 public subnet, dan menggunakan security group `alb-sg`.
- [ ] **Health Status (5 Poin)**: Kedua target pada Target Group berstatus **Healthy (2/2)**.
- [ ] **Round-Robin Balancing (5 Poin)**: Saat URL DNS ALB dibuka dan direfresh, request dilayani secara bergantian oleh instance AZ-A dan AZ-B.

---

### 5. Pengujian Terpadu & Failover (Maks. 15 Poin)
- [ ] **Integrasi RDS (5 Poin)**: Data produk yang diinput melalui formulir web berhasil tersimpan dan tampil di tabel katalog database.
- [ ] **Integrasi S3 Upload (4 Poin)**: Gambar produk berhasil diupload ke S3 dan ditampilkan pada portal web menggunakan Presigned URL.
- [ ] **Integrasi DynamoDB Logs (3 Poin)**: Log aktivitas pengunjung tercatat secara realtime di tabel DynamoDB dan tampil pada web portal.
- [ ] **Simulasi Failover / Fault Tolerance (3 Poin)**: Saat salah satu EC2 dimatikan (*stopped*), portal web tetap aktif melayani pengguna melalui server kedua tanpa downtime.

---

## III. KRITERIA KELULUSAN & PREDIKAT

| Rentang Nilai | Predikat | Keterangan |
| :---: | :---: | :--- |
| **88 – 100** | **Sangat Kompeten (Excellent)** | Arsitektur sempurna, seluruh service terintegrasi, failover berhasil mulus. |
| **75 – 87** | **Kompeten (Good)** | Memenuhi persyaratan inti, beberapa konfigurasi minor perlu perapian. |
| **60 – 74** | **Cukup (Fair)** | Sebagian besar service berjalan namun terdapat kendala pada HA atau integrasi data. |
| **< 60** | **Belum Kompeten (Needs Improvement)** | Infrastruktur inti tidak dapat beroperasi atau gagal memenuhi standar minimal. |

---

### Catatan & Rekomendasi Evaluator:
__________________________________________________________________________________________
__________________________________________________________________________________________
__________________________________________________________________________________________

Tanda Tangan Penguji / Evaluator:  
*( ____________________________________ )*
