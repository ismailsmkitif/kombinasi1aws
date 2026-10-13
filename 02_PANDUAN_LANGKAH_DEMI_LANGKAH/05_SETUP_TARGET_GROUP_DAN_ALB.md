# ⚖️ Modul 05: Setup Target Group & Application Load Balancer (Konsol AWS)

Pada modul ini, kita akan membuat **Target Group** yang mendaftarkan kedua instance EC2 web server, kemudian membangun **Application Load Balancer (ALB)** yang berfungsi mendistribusikan lalu lintas HTTP secara merata (*Round-Robin*) ke kedua Availability Zone.

---

## Bagian A: Membuat Target Group

1. Pada bilah pencarian AWS Console, buka layanan **EC2**.
2. Pada panel navigasi sebelah kiri, gulir ke bagian **Load Balancing**, lalu klik **Target Groups**.
3. Klik tombol oranye **Create target group**.
4. **Basic configuration**:
   - **Choose a target type**: Pilih **Instances**.
   - **Target group name**: Ketik **`tg-cloudretail`**
   - **Protocol**: `HTTP`
   - **Port**: `80`
   - **IP address type**: `IPv4`
   - **VPC**: Pilih **`CloudRetail-VPC`**
   - **Protocol version**: Biarkan **HTTP1**.
5. **Health checks**:
   - **Health check protocol**: `HTTP`
   - **Health check path**: Ketik **`/health`**
6. Klik tombol **Next** di bagian bawah.
7. **Register targets**:
   - Pada tabel *Available instances*, centang kedua server:
     - ☑ `EC2-Web-Server-A`
     - ☑ `EC2-Web-Server-B`
   - Pastikan *Ports for the inspected instances* terisi `80`.
   - Klik tombol **Include as pending below**.
   - Pastikan kedua instance telah berpindah ke tabel *Review targets*.
8. Klik tombol oranye **Create target group**.

---

## Bagian B: Membuat Application Load Balancer (ALB)

1. Pada menu sebelah kiri di bawah **Load Balancing**, klik **Load Balancers**.
2. Klik tombol oranye **Create load balancer**.
3. Pada kartu **Application Load Balancer**, klik tombol **Create**.
4. **Basic configuration**:
   - **Load balancer name**: Ketik **`alb-cloudretail`**
   - **Scheme**: Pilih **Internet-facing** *(Dapat diakses langsung oleh browser pengguna di internet)*.
   - **IP address type**: Pilih **IPv4**.
5. **Network mapping**:
   - **VPC**: Pilih **`CloudRetail-VPC`**
   - **Mappings** (Pilih dua Availability Zone publik):
     - Centang ☑ **`us-east-1a`** -> Pada dropdown Subnet, pilih **`Public-Subnet-A`** (`10.0.1.0/24`).
     - Centang ☑ **`us-east-1b`** -> Pada dropdown Subnet, pilih **`Public-Subnet-B`** (`10.0.2.0/24`).
     *(Pastikan tidak memilih subnet private!)*
6. **Security groups**:
   - Hapus *default* security group jika ada.
   - Pilih dan pasang security group **`alb-sg`**.
7. **Listeners and routing**:
   - **Protocol**: `HTTP`
   - **Port**: `80`
   - **Default action**: Pilih **Forward to** -> Pilih Target Group **`tg-cloudretail`**.
8. Gulir ke bawah hingga bagian **Summary**, periksa kembali pengaturan Anda, lalu klik **Create load balancer**.
9. Klik tombol **View load balancers**.

---

## Bagian C: Menunggu Status ALB & Verifikasi Health Check

1. Pada tabel Load Balancers, perhatikan kolom **State** untuk `alb-cloudretail`.
   - Status awal akan menampilkan **Provisioning**.
   - Tunggu sekitar 2–3 menit hingga status berubah menjadi **Active**.
2. Klik nama load balancer **`alb-cloudretail`**:
   - Pada tab **Description**, cari bagian **DNS name**.
   - Salin alamat DNS tersebut (contoh: `alb-cloudretail-123456789.us-east-1.elb.amazonaws.com`).
3. Cek Status Kesehatan Target (*Health Checks*):
   - Di menu kiri, klik kembali **Target Groups**.
   - Klik `tg-cloudretail`, lalu buka tab **Targets**.
   - Periksa kolom **Health status** kedua instance:
     - Status harus menunjukkan **Healthy** (2 targets healthy).
   > [!TIP]
   > Jika status masih *Initial*, tunggu 30–60 detik. Jika menunjukkan *Unhealthy*, periksa apakah service di EC2 sudah aktif dan security group `ec2-sg` mengizinkan akses port 80 dari `alb-sg`.

---

✅ **Hasil Akhir Modul 05**: Application Load Balancer telah aktif dan berhasil memantau kesehatan kedua instance EC2 di target group!
