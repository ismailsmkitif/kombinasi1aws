# ☁️ Proyek Cloud Computing AWS Learner Lab: CloudRetail Portal

Selamat datang di repositori proyek **CloudRetail Portal**, sebuah proyek infrastruktur & aplikasi cloud interaktif berbasis layanan AWS yang dirancang khusus untuk lingkungan **AWS Academy Learner Lab**.

Proyek ini dapat digunakan sebagai **Bahan Pembelajaran**, **Tugas Akhir Modul**, maupun **Ujian / Seleksi Kompetensi (LKS Cloud Computing / Uji Kompetensi Keahlian)**.

---

## 📌 Ringkasan Proyek
Proyek ini membangun arsitektur web aplikasi *High Availability* (Tinggi Ketersediaan) dan *Multi-Tier* yang sepenuhnya dikonfigurasi melalui **AWS Management Console** (tanpa perlu AWS CLI lokal).

### Layanan AWS yang Terlibat:
| Layanan AWS | Peran dalam Arsitektur | Keterangan Khusus Learner Lab |
| :--- | :--- | :--- |
| **VPC** | Jaringan privat terisolasi (Custom VPC) | Multi-AZ (2 Availability Zones), 2 Public Subnet, 2 Private Subnet, IGW, Route Tables. |
| **EC2** | Web/App Server (*Compute*) | 2 Instance `t2.micro` / `t3.micro` di 2 AZ berbeda, dipasangi IAM Role `LabRole`. |
| **Target Group** | Target tujuan distribusi lalu lintas | Mendaftarkan kedua instance EC2 pada port HTTP (80). |
| **Application Load Balancer (ALB)** | Penyeimbang beban akses publik (*Load Balancer*) | Internet-facing di 2 Public Subnet, mendistribusikan traffic ke Target Group. |
| **RDS** | Relational Database (SQL) | MySQL 8.0 `db.t3.micro` / `db.t2.micro` (Single-AZ) di Private Subnet untuk data produk & transaksi. |
| **DynamoDB** | NoSQL Database | Tabel `CloudRetail-Logs` untuk audit log & riwayat aktivitas pengunjung secara real-time. |
| **S3** | Object Storage | Bucket privat untuk penyimpanan gambar/aset produk yang diunggah pengguna. |

---

## 🏛️ Arsitektur Sistem

```
                                  [ Internet / Browser User ]
                                               │
                                               ▼
                              [ Application Load Balancer (ALB) ]
                                (Tersebar di Public Subnet AZ-A & AZ-B)
                                               │
                       ┌───────────────────────┴───────────────────────┐
                       ▼                                               ▼
         [ EC2 Web Server 1 ]                            [ EC2 Web Server 2 ]
       (Public/Private Subnet AZ-A)                    (Public/Private Subnet AZ-B)
       Attached: IAM LabRole                           Attached: IAM LabRole
         │             │                                 │             │
         │             └─────────────────┬───────────────┘             │
         ▼                               ▼                             ▼
  [ Amazon S3 Bucket ]          [ Amazon RDS MySQL ]        [ Amazon DynamoDB ]
 (Penyimpanan Gambar Produk)   (Private Subnet AZ-A & B)     (Audit Log Kunjungan)
                               (Katalog & Data Pesanan)
```

---

## 📁 Struktur Dokumen & Panduan

Proyek ini telah disusun dengan struktur direktori yang rapi dan siap pakai:

- **[`01_DOKUMEN_SOAL/`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/01_DOKUMEN_SOAL/)**
  - [`SOAL_PRAKTIK_SELEKSI.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/01_DOKUMEN_SOAL/SOAL_PRAKTIK_SELEKSI.md) : Naskah soal ujian/seleksi resmi untuk peserta.
  - [`RUBRIK_PENILAIAN.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/01_DOKUMEN_SOAL/RUBRIK_PENILAIAN.md) : Lembar penilaian, poin bobot, dan kriteria kelulusan bagi penguji/evaluator.

- **[`02_PANDUAN_LANGKAH_DEMI_LANGKAH/`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/)**
  - [`00_ARSITEKTUR_DAN_PERSIAPAN.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/00_ARSITEKTUR_DAN_PERSIAPAN.md) : Alamat IP, topologi, dan batasan khusus AWS Learner Lab.
  - [`01_KONFIGURASI_VPC_NETWORKING.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/01_KONFIGURASI_VPC_NETWORKING.md) : Panduan klik Console untuk VPC, Subnet, IGW, Route Table, dan Security Groups.
  - [`02_SETUP_S3_DAN_DYNAMODB.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/02_SETUP_S3_DAN_DYNAMODB.md) : Panduan klik Console untuk S3 Bucket & DynamoDB Table.
  - [`03_SETUP_RDS_DATABASE.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/03_SETUP_RDS_DATABASE.md) : Panduan klik Console untuk DB Subnet Group & RDS MySQL Instance.
  - [`04_DEPLOY_EC2_WEB_SERVER.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/04_DEPLOY_EC2_WEB_SERVER.md) : Panduan klik Console Launch EC2, attach `LabRole`, dan input *User Data*.
  - [`05_SETUP_TARGET_GROUP_DAN_ALB.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/05_SETUP_TARGET_GROUP_DAN_ALB.md) : Panduan klik Console Target Group & Application Load Balancer.
  - [`06_PENGUJIAN_DAN_VERIFIKASI.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/06_PENGUJIAN_DAN_VERIFIKASI.md) : Cara pengujian High Availability (refresh round-robin), CRUD RDS, Upload S3, dan DynamoDB logging.
  - [`07_PEMBERSIHAN_RESOURCE.md`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/02_PANDUAN_LANGKAH_DEMI_LANGKAH/07_PEMBERSIHAN_RESOURCE.md) : Prosedur penghapusan resource agar saldo Learner Lab tidak terkuras.

- **[`app/`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/app/)**
  - [`app.py`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/app/app.py) : Source code aplikasi web Flask (Python) yang menghubungkan RDS, S3, dan DynamoDB.
  - [`requirements.txt`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/app/requirements.txt) : Daftar pustaka Python yang dibutuhkan.
  - [`templates/index.html`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/app/templates/index.html) : Tampilan antarmuka (UI) web dashboard modern responsif.
  - [`user_data.sh`](file:///e:/2026/Materi/cloud%20computing/soal_seleksi/app/user_data.sh) : Script User Data otomatis untuk EC2 saat booting pertama kali.

---

## ⚡ Karakteristik Khusus AWS Learner Lab
1. **IAM Role**: Peserta tidak diizinkan membuat IAM Role baru. Gunakan role bawaan bernama **`LabRole`** saat mengonfigurasi EC2 Instance Profile.
2. **Kredensial Otomatis**: Dengan menggunakan `LabRole`, instance EC2 memiliki akses resmi ke S3 dan DynamoDB secara aman tanpa perlu memasukkan `aws_access_key_id` atau `aws_secret_access_key`.
3. **Region**: Default region AWS Learner Lab umumnya adalah **`us-east-1` (N. Virginia)**. Pastikan selalu berada di region ini saat membuat seluruh resource.
4. **Ukuran Instance**: Gunakan `t2.micro` atau `t3.micro` untuk EC2 dan `db.t3.micro` / `db.t2.micro` untuk RDS agar hemat saldo dan tidak terkena limit kuota lab.
# kombinasi1aws
