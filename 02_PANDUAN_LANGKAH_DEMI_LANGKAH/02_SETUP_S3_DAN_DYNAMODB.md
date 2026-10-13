# 🪣 Modul 02: Setup Amazon S3 & Amazon DynamoDB (Konsol AWS)

Pada modul ini, kita akan membuat dua media penyimpanan data non-relasional:
1. **Amazon S3**: Sebagai *Object Storage* penyimpan file gambar produk yang diunggah.
2. **Amazon DynamoDB**: Sebagai *NoSQL Key-Value Database* untuk mencatat log aktivitas pengunjung secara instan dan tanpa server (*serverless*).

---

## Bagian A: Membuat Amazon S3 Bucket

> [!TIP]
> Nama bucket S3 bersifat **unik global** di seluruh dunia (tidak boleh ada nama bucket yang sama persis di seluruh pengguna AWS). Oleh karena itu, tambahkan akhiran identitas/NIM/nama Anda pada nama bucket.

1. Pada bilah pencarian AWS Console, ketik **`S3`** lalu pilih **S3**.
2. Klik tombol oranye **Create bucket**.
3. Pada bagian **General configuration**:
   - **Bucket type**: Pilih **General purpose**
   - **Bucket name**: Masukkan format `cloudretail-bucket-<nama/id-anda>` (Contoh: `cloudretail-bucket-ismail2026`).
     *(Gunakan huruf kecil, angka, dan tanda minus; jangan gunakan spasi atau simbol lain)*.
   - **AWS Region**: Pastikan terpilih **`US East (N. Virginia) us-east-1`**.
4. Pada bagian **Object Ownership**:
   - Biarkan opsi default: **ACLs disabled (recommended)**.
5. Pada bagian **Block Public Access settings for this bucket**:
   - Biarkan opsi **Block *all* public access** tetap **TERCENTANG (Checked)**.
   > [!NOTE]
   > Aplikasi CloudRetail menggunakan metode **AWS Presigned URLs** via Boto3. Metode ini memungkinkan browser menampilkan gambar dari bucket privat secara aman dengan masa berlaku token khusus tanpa perlu membuka akses bucket ke publik!
6. Pada bagian **Bucket Versioning**: Biarkan **Disable**.
7. Pada bagian **Default encryption**: Biarkan **Server-side encryption with Amazon S3 managed keys (SSE-S3)**.
8. Gulir ke bawah lalu klik **Create bucket**.
9. **Catat nama bucket Anda** yang baru dibuat, karena nama ini akan dimasukkan ke dalam konfigurasi EC2.

---

## Bagian B: Membuat Tabel Amazon DynamoDB

1. Pada bilah pencarian AWS Console, ketik **`DynamoDB`** lalu pilih **DynamoDB**.
2. Pada panel dashboard DynamoDB, klik tombol oranye **Create table**.
3. Isi konfigurasi tabel:
   - **Table name**: Masukkan persis: **`CloudRetail-Logs`** *(Case-sensitive)*.
   - **Partition key**: Ketik **`log_id`** dan pilih tipe data **`String`**.
   - **Sort key**: Biarkan kosong.
4. Pada bagian **Table settings**:
   - Pilih opsi **Customize settings**.
   - Pada **Read/write capacity settings**, pilih **On-demand** (Mode ini sangat hemat saldo di Learner Lab karena biaya hanya dihitung per transaksi, tanpa biaya standby kapasitas).
5. Gulir ke bagian paling bawah lalu klik **Create table**.
6. Tunggu sekitar 10–30 detik hingga status tabel berubah menjadi **Active**.

---

## Bagian C: Verifikasi Integrasi IAM di AWS Learner Lab

Karena kita berada di AWS Learner Lab:
- EC2 instance akan menggunakan profil IAM bawaan bernama **`LabRole`**.
- Role `LabRole` ini secara otomatis sudah memiliki policy bawaan (*pre-configured policies*) yang memberikan izin penuh (*Full Access*) untuk layanan **Amazon S3** (`s3:*`) dan **Amazon DynamoDB** (`dynamodb:*`).
- Peserta **tidak perlu** membuat IAM Role atau policy baru secara manual.

---

✅ **Hasil Akhir Modul 02**: Bucket S3 dan Tabel DynamoDB telah aktif dan siap digunakan untuk menyimpan file gambar dan log audit aplikasi!
