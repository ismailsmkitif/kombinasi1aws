# 🧪 Modul 06: Skenario Pengujian Terpadu & Verifikasi Solusi

Modul ini menyajikan 5 skenario pengujian komprehensif untuk membuktikan bahwa seluruh layanan AWS (**VPC, EC2, ALB, Target Group, RDS, S3, DynamoDB**) terintegrasi sempurna dan memenuhi standar *High Availability* serta *Fault Tolerance*.

---

## Skenario 1: Akses Publik via Application Load Balancer

1. Salin **DNS Name** dari Application Load Balancer yang telah dibuat pada Modul 05 (contoh: `alb-cloudretail-123456789.us-east-1.elb.amazonaws.com`).
2. Buka web browser (Chrome / Edge / Firefox), masukkan alamat:
   ```
   http://<ALB-DNS-NAME>
   ```
3. **Kriteria Keberhasilan**:
   - Web portal **CloudRetail** terbuka dengan sempurna.
   - Keempat badge layanan di bagian atas menyala hijau:
     - ⚖️ **ALB & Target Group**: *Active*
     - 🗄️ **Amazon RDS**: *Connected* (Engine MySQL 8.0)
     - 🪣 **Amazon S3**: *Ready*
     - ⚡ **Amazon DynamoDB**: *Ready*

---

## Skenario 2: Uji High Availability & Load Balancing (Round-Robin)

Skenario ini membuktikan bahwa Application Load Balancer mendistribusikan beban secara merata ke dua Availability Zone yang berbeda.

1. Buka kembali halaman web `http://<ALB-DNS-NAME>`.
2. Perhatikan kartu di sudut kanan atas:
   - **SERVED BY EC2**: Menampilkan `Instance ID` dan `AZ` (misal: `i-01a2b3c4d5e6f7` di `us-east-1a`).
3. Tekan tombol **Refresh (F5)** atau klik tombol *🔄 Refresh Test ALB* beberapa kali.
4. **Kriteria Keberhasilan**:
   - Identitas server berganti secara bergantian antara Server A (`us-east-1a`) dan Server B (`us-east-1b`).
   - Sesi pengguna tetap lancar tanpa terputus.

---

## Skenario 3: Uji Simpan Data Terpadu (RDS MySQL & Amazon S3)

Skenario ini menguji kemampuan aplikasi menyimpan data relasional ke database SQL dan file biner media ke Object Storage secara simultan.

1. Pada bagian formulir **📦 Tambah Produk Baru**:
   - **Nama Produk**: Ketik `Laptop Cloud Pro 14`
   - **Harga (Rp)**: Ketik `14500000`
   - **Foto Produk**: Pilih file gambar sembarang dari komputer Anda (.jpg / .png).
2. Klik tombol **💾 Simpan Data & Upload Media**.
3. **Kriteria Keberhasilan**:
   - Muncul notifikasi hijau: `✅ Produk berhasil ditambahkan ke RDS MySQL & S3!`.
   - Produk muncul pada tabel katalog **📋 Data Produk di RDS MySQL** lengkap dengan thumbnail gambar.
   - Klik gambar tersebut untuk memastikan file dapat dibuka melalui URL S3 yang aman.
4. **Verifikasi via AWS Console**:
   - Buka AWS Console -> Layanan **S3** -> Buka bucket Anda -> Masuk ke folder `products/`.
   - Pastikan file foto yang baru saja diunggah tercantum di dalam bucket S3.

---

## Skenario 4: Uji NoSQL Realtime Audit Logging (Amazon DynamoDB)

Skenario ini membuktikan pencatatan aktivitas pengguna (*Event Logging*) ke database NoSQL berkecepatan tinggi.

1. Gulir ke bagian paling bawah portal web pada tabel **📊 Live Activity Logs (Amazon DynamoDB)**.
2. Perhatikan baris-baris log:
   - Terdapat record bertipe `PAGE_VISIT` saat halaman diakses/direfresh.
   - Terdapat record bertipe `PRODUCT_ADDED` yang mencatat nama produk dan harga yang baru saja ditambahkan.
   - Kolom *Instance ID* dan *AZ* menunjukkan server EC2 mana yang memproses request tersebut.
3. **Verifikasi via AWS Console**:
   - Buka AWS Console -> Layanan **DynamoDB**.
   - Pada panel kiri klik **Tables** -> Pilih tabel **`CloudRetail-Logs`**.
   - Klik tombol **Explore table items** di kanan atas.
   - Pastikan record log tersimpan dengan kunci `log_id`, atribut `timestamp`, `action`, `client_ip`, dll.

---

## Skenario 5: Simulasi Kegagalan Server (*Fault Tolerance Demo*)

Skenario ini membuktikan keandalan sistem ketika salah satu data center atau server mengalami crash/down (*Failover Simulation*).

1. Buka AWS Console -> Layanan **EC2** -> Menu **Instances**.
2. Pilih server pertama: **`EC2-Web-Server-A`**.
3. Klik menu **Instance state** di kanan atas -> Pilih **Stop instance**.
4. Buka kembali halaman web `http://<ALB-DNS-NAME>` di browser Anda lalu lakukan refresh berkali-kali.
5. **Kriteria Keberhasilan**:
   - Portal web **TIDAK PERNAH DOWN (Zero Downtime)**!
   - Seluruh request kini 100% dialihkan dan dilayani oleh **`EC2-Web-Server-B`** di zona `us-east-1b`.
6. Buka menu **Target Groups** di EC2 Console:
   - Pada target group `tg-cloudretail`, amati tab **Targets**.
   - Target Server A akan ditandai *Unused* / *Unhealthy*, sedangkan Server B berstatus *Healthy*.
7. (*Opsional*) Nyalakan kembali Server A (**Start instance**). Amati bahwa dalam 1–2 menit, Target Group mendeteksi server telah sehat kembali dan otomatis membagi beban (*Auto-Recovery*).

---

✅ **Hasil Akhir Modul 06**: Seluruh skenario pengujian berhasil 100%! Infrastruktur membuktikan standar ketersediaan tinggi, skalabilitas, dan integrasi multi-layanan AWS yang solid.
