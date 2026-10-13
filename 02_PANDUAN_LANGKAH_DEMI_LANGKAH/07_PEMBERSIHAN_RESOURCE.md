# 🧹 Modul 07: Prosedur Pembersihan Sumber Daya (*Resource Cleanup*)

Di lingkungan **AWS Academy Learner Lab**, saldo kredit lab bersifat terbatas ($100). Komponen seperti **Application Load Balancer** dan **Amazon RDS** mengenakan biaya per jam berjalan (*hourly charge*).

Ikuti urutan penghapusan di bawah ini secara disiplin untuk mencegah terkurasnya saldo lab dan menghindari pesan error *Dependency Violation* di AWS Console.

---

## ⚠️ Urutan Penghapusan Wajib (Dependency Order)

```
1. Application Load Balancer  ──►  2. Target Groups  ──►  3. EC2 Instances (Terminate)
             │
             ▼
4. RDS Database  ──►  5. DB Subnet Group  ──►  6. S3 Bucket (Empty & Delete)
             │
             ▼
7. DynamoDB Table  ──►  8. Security Groups  ──►  9. Internet Gateway & VPC
```

---

## Langkah 1: Menghapus Application Load Balancer & Target Group
1. Buka layanan **EC2** -> Di menu kiri klik **Load Balancers**.
2. Pilih `alb-cloudretail` -> Klik menu **Actions** -> **Delete load balancer** -> Ketik `confirm` jika diminta -> Klik **Delete**.
3. Di menu kiri klik **Target Groups**.
4. Pilih `tg-cloudretail` -> Klik **Actions** -> **Delete** -> Klik **Yes, delete**.

---

## Langkah 2: Menghapus (Terminate) Instance EC2
1. Pada menu EC2, klik **Instances**.
2. Centang kedua instance:
   - ☑ `EC2-Web-Server-A`
   - ☑ `EC2-Web-Server-B`
3. Klik **Instance state** -> Pilih **Terminate instance** -> Klik **Terminate**.
4. Tunggu status instance berubah menjadi *Terminated*.

---

## Langkah 3: Menghapus Database Amazon RDS
1. Buka layanan **RDS** -> Klik menu **Databases**.
2. Pilih database **`cloudretail-mysql`**.
3. Klik tombol **Actions** di kanan atas -> Pilih **Delete**.
4. Pada kotak konfirmasi:
   - ⚠️ **Hapus centang (Uncheck)** pada opsi *Create final snapshot?*
   - ⚠️ **Centang (Check)** pada kotak *I acknowledge that upon instance deletion, automated backups...*.
   - Ketikkan kata: **`delete me`** pada kolom konfirmasi.
5. Klik **Delete**.
6. Setelah database berstatus *Deleting*, buka menu **Subnet groups** di panel kiri:
   - Pilih `cloudretail-db-subnet-group` -> Klik **Delete** -> Konfirmasi penghapusan (lakukan setelah status DB benar-benar hilang).

---

## Langkah 4: Mengosongkan & Menghapus Amazon S3 Bucket
1. Buka layanan **S3**.
2. Centang bucket Anda (contoh: `cloudretail-bucket-ismail2026`).
3. Klik tombol **Empty** terlebih dahulu:
   - Ketik `permanently delete` pada kolom input -> Klik **Empty**.
4. Kembali ke daftar bucket, klik kembali nama bucket Anda lalu klik tombol **Delete**.
5. Ketikkan nama bucket Anda untuk mengonfirmasi -> Klik **Delete bucket**.

---

## Langkah 5: Menghapus Tabel Amazon DynamoDB
1. Buka layanan **DynamoDB** -> Klik **Tables**.
2. Pilih tabel **`CloudRetail-Logs`**.
3. Klik tombol **Delete** di kanan atas.
4. Ketik **`confirm`** pada kolom konfirmasi -> Klik **Delete table**.

---

## Langkah 6: Menghapus Security Groups, IGW, dan Custom VPC
Setelah seluruh resource di dalam VPC dihapus, jaringan VPC dapat dibersihkan dengan aman:

1. Buka layanan **VPC**.
2. Klik **Internet gateways**:
   - Pilih `CloudRetail-IGW` -> Klik **Actions** -> **Detach from VPC** -> Klik **Detach**.
   - Klik kembali **Actions** -> **Delete internet gateway** -> Konfirmasi hapus.
3. Klik **Security groups**:
   - Hapus secara bertahap:
     - Hapus `rds-sg`
     - Hapus `ec2-sg`
     - Hapus `alb-sg`
4. Klik **Your VPCs**:
   - Pilih **`CloudRetail-VPC`**.
   - Klik menu **Actions** -> Pilih **Delete VPC**.
   - AWS Console akan secara otomatis menghapus seluruh Subnet dan Route Table terkait di dalam VPC tersebut.
   - Ketik **`delete`** -> Klik **Delete**.

---

## Langkah 7: Mengakhiri Sesi Learner Lab
1. Kembali ke tab browser portal **AWS Academy Learner Lab**.
2. Klik tombol merah **End Lab** atau biarkan sesi lab non-aktif.
3. Saldo lab Anda akan tetap aman dan siap digunakan untuk latihan berikutnya! 🎉
