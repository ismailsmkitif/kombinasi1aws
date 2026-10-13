# 🌐 Modul 01: Konfigurasi Custom VPC & Networking (Konsol AWS)

Panduan ini menjelaskan tahap demi tahap pembuatan topologi jaringan **Virtual Private Cloud (VPC)**, Subnet di 2 Availability Zone, Internet Gateway, Route Table, dan Security Groups melalui **AWS Management Console**.

---

## Langkah 1: Membuat Custom VPC
1. Pada bilah pencarian paling atas AWS Management Console, ketik **`VPC`** lalu pilih layanan **VPC**.
2. Pastikan region aktif di kanan atas adalah **N. Virginia (`us-east-1`)**.
3. Di menu sebelah kiri, klik **Your VPCs**, kemudian klik tombol oranye **Create VPC**.
4. Pada opsi *Resources to create*, pilih **VPC only**.
5. Isi konfigurasi berikut:
   - **Name tag**: `CloudRetail-VPC`
   - **IPv4 CIDR block**: Masukkan `10.0.0.0/16`
   - **IPv6 CIDR block**: Biarkan *No IPv6 CIDR block*
   - **Tenancy**: Pilih *Default*
6. Gulir ke bawah lalu klik **Create VPC**.

---

## Langkah 2: Membuat 4 Subnet (Multi-AZ)
Kita akan membuat 2 Public Subnet dan 2 Private Subnet terdistribusi di `us-east-1a` dan `us-east-1b`.

1. Di menu navigasi sebelah kiri, klik **Subnets**.
2. Klik tombol **Create subnet**.
3. Pada **VPC ID**, pilih **`CloudRetail-VPC`**.
4. Masukkan konfigurasi untuk subnet pertama:
   - **Subnet name**: `Public-Subnet-A`
   - **Availability Zone**: Pilih **`us-east-1a`**
   - **IPv4 subnet CIDR block**: Masukkan `10.0.1.0/24`
5. Klik tombol **Add new subnet** di bagian bawah, lalu isi subnet kedua:
   - **Subnet name**: `Public-Subnet-B`
   - **Availability Zone**: Pilih **`us-east-1b`**
   - **IPv4 subnet CIDR block**: Masukkan `10.0.2.0/24`
6. Klik lagi **Add new subnet**, lalu isi subnet ketiga:
   - **Subnet name**: `Private-Subnet-A`
   - **Availability Zone**: Pilih **`us-east-1a`**
   - **IPv4 subnet CIDR block**: Masukkan `10.0.11.0/24`
7. Klik lagi **Add new subnet**, lalu isi subnet keempat:
   - **Subnet name**: `Private-Subnet-B`
   - **Availability Zone**: Pilih **`us-east-1b`**
   - **IPv4 subnet CIDR block**: Masukkan `10.0.12.0/24`
8. Klik tombol **Create subnet**.

---

## Langkah 3: Mengaktifkan Auto-assign Public IP pada Public Subnet
1. Pada daftar **Subnets**, centang subnet **`Public-Subnet-A`**.
2. Klik menu **Actions** di kanan atas -> pilih **Edit subnet settings**.
3. Centang opsi **Enable auto-assign public IPv4 address**.
4. Klik **Save**.
5. Ulangi langkah di atas untuk **`Public-Subnet-B`**.

---

## Langkah 4: Membuat & Menghubungkan Internet Gateway (IGW)
1. Di menu navigasi kiri, klik **Internet gateways**.
2. Klik **Create internet gateway**.
3. Beri nama:
   - **Name tag**: `CloudRetail-IGW`
4. Klik **Create internet gateway**.
5. Setelah berhasil dibuat, klik tombol **Actions** -> pilih **Attach to VPC**.
6. Pada dropdown *Available VPCs*, pilih **`CloudRetail-VPC`**.
7. Klik **Attach internet gateway**.

---

## Langkah 5: Mengatur Route Table
### A. Route Table untuk Public Subnet
1. Di menu sebelah kiri, klik **Route tables**, lalu klik **Create route table**.
2. Isi formulir:
   - **Name**: `Public-Route-Table`
   - **VPC**: Pilih **`CloudRetail-VPC`**
3. Klik **Create route table**.
4. Pada tab **Routes** (di bagian tengah bawah), klik **Edit routes**.
5. Klik tombol **Add route**:
   - **Destination**: Ketik `0.0.0.0/0`
   - **Target**: Pilih **Internet Gateway**, lalu pilih **`CloudRetail-IGW`**
6. Klik **Save changes**.
7. Beralih ke tab **Subnet associations**, lalu klik **Edit subnet associations**.
8. Centang dua subnet publik:
   - ☑ `Public-Subnet-A`
   - ☑ `Public-Subnet-B`
9. Klik **Save associations**.

### B. Route Table untuk Private Subnet
1. Klik kembali menu **Route tables** -> klik **Create route table**.
2. Beri nama:
   - **Name**: `Private-Route-Table`
   - **VPC**: Pilih **`CloudRetail-VPC`**
3. Klik **Create route table**.
4. Beralih ke tab **Subnet associations** -> klik **Edit subnet associations**.
5. Centang dua subnet privat:
   - ☑ `Private-Subnet-A`
   - ☑ `Private-Subnet-B`
6. Klik **Save associations** (Subnet privat tidak boleh memiliki rute ke `0.0.0.0/0` melalui IGW).

---

## Langkah 6: Membuat Security Groups
Di menu navigasi kiri, klik **Security groups**, lalu buat 3 grup keamanan berikut:

### 1. Security Group untuk Application Load Balancer (`alb-sg`)
1. Klik **Create security group**.
2. Konfigurasi:
   - **Security group name**: `alb-sg`
   - **Description**: `Security Group untuk ALB Publik`
   - **VPC**: Pilih **`CloudRetail-VPC`** *(pastikan tidak memilih default VPC)*
3. Pada **Inbound rules**, klik **Add rule**:
   - **Type**: `HTTP` (Port 80)
   - **Source**: `Anywhere-IPv4` (`0.0.0.0/0`)
4. Klik **Create security group**.

### 2. Security Group untuk EC2 Web Server (`ec2-sg`)
1. Klik **Create security group**.
2. Konfigurasi:
   - **Security group name**: `ec2-sg`
   - **Description**: `Security Group untuk EC2 Instance`
   - **VPC**: Pilih **`CloudRetail-VPC`**
3. Pada **Inbound rules**, klik **Add rule**:
   - **Type**: `HTTP` (Port 80)
   - **Source**: Pilih **Custom**, lalu ketik dan pilih `alb-sg` (atau `0.0.0.0/0` agar mempermudah pengujian langsung)
4. Klik **Create security group**.

### 3. Security Group untuk RDS MySQL (`rds-sg`)
1. Klik **Create security group**.
2. Konfigurasi:
   - **Security group name**: `rds-sg`
   - **Description**: `Security Group untuk Database RDS MySQL`
   - **VPC**: Pilih **`CloudRetail-VPC`**
3. Pada **Inbound rules**, klik **Add rule**:
   - **Type**: `MYSQL/Aurora` (Port 3306)
   - **Source**: Pilih **Custom**, lalu cari dan pilih ID security group **`ec2-sg`**
4. Klik **Create security group**.

---

✅ **Hasil Akhir Modul 01**: Jaringan Custom VPC telah selesai dibuat lengkap dengan 4 Subnet Multi-AZ, Internet Gateway aktif, Public & Private Route Table, serta 3 Security Group berjenjang!
