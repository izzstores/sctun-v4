

```markdown
<div align="center">

# ⚡ IZZ TUNNELING (sctun-v4)
High-Performance & Fully Automated VPN/Tunneling Setup for Linux

[![Telegram](https://img.shields.io/badge/Telegram-@izzcoyy-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/izzcoyy)
[![WhatsApp](https://img.shields.io/badge/WhatsApp-Chat%20Admin-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://wa.me/6282213283021)
[![Architecture](https://img.shields.io/badge/Arch-x86__64-informational?style=for-the-badge&logo=linux&logoColor=white)](#-spesifikasi--arsitektur)
[![OS Support](https://img.shields.io/badge/OS-Debian%20%7C%20Ubuntu-orange?style=for-the-badge&logo=debian&logoColor=white)](#-sistem-operasi-didukung)

---

</div>

## 🌟 Fitur Utama

- ⚡ Otomatisasi Total: Setup dinamis, cepat, dan otomatis menerapkan tuning kernel terbaik.
- 🛡️ Keamanan Maksimal: Proteksi brute-force dengan Fail2ban & filter DNS iklan Indonesia.
- 🚀 Core Xray Khusus: Engine Xray kustom yang dioptimalkan oleh `@izzcoyy`.
- 🧹 Auto Maintenance:
  - Auto swap 1 GB (mencegah Out-Of-Memory pada RAM kecil).
  - Pembersihan log sistem otomatis tiap 3 menit.
  - Hapus user kedaluwarsa secara otomatis.
- 📊 Manajemen Lengkap: Manajemen akun, pemantauan status, dan servis yang terpusat.

---

## 🚀 Panduan Instalasi

### 1. Persiapan Jaringan & DNS

Jalankan perintah berikut untuk mengoptimalkan DNS dan menonaktifkan IPv6:

```bash
rm -f /etc/resolv.conf
touch /etc/sysctl.conf
sed -i '/disable_ipv6/d' /etc/sysctl.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

2. Update Dependensi Sistem

```bash
apt update -y && apt upgrade -y --fix-missing && apt install --reinstall wget curl screen -y
```

3. Eksekusi Script

Jalankan instalasi di dalam sesi `screen` agar proses tetap aman jika koneksi terputus:

```bash
screen -S setup-session bash -c "wget -q https://raw.githubusercontent.com/izzstores/sctun-v4/main/install.sh && chmod +x install.sh && ./install.sh"
```

> [!TIP]
> Koneksi terputus saat instalasi?  
> Buka kembali sesi instalasi yang sedang berjalan dengan:
> ```bash
> screen -r -d setup-session
> ```

---

## 🔄 Pembaruan (Update Script)

Untuk mengupdate script ke versi terbaru:

```bash
wget https://raw.githubusercontent.com/izzstores/sctun-v4/main/update.sh && chmod +x update.sh && ./update.sh
```

---

📡 Port Layanan

| Protokol | Transport | Port | Keterangan |
| :--- | :--- | :---: | :--- |
| Trojan | WS / gRPC | `443` | TLS Encrypted |
| Shadowsocks | WS / gRPC | `443` | TLS Encrypted |
| VLESS | WS / gRPC | `443` | TLS Encrypted |
| VLESS | Non-TLS | `80` | Direct HTTP |
| VMess | WS / gRPC | `443` | TLS Encrypted |
| VMess | Non-TLS | `80` | Direct HTTP |
| SSH | WS / TLS | `443` | WebSocket TLS |
| SSH | Non-TLS | `8880` | CDN / Direct Non-TLS |
| OpenVPN | SSL / TCP | `1194` | OVPN Tunnel |
| SlowDNS | UDP | `5300` | DNS Tunneling |

---

☁️ Konfigurasi Cloudflare

Atur parameter domain di dashboard Cloudflare sebagai berikut:

| Opsi | Status / Nilai | Catatan |
| :--- | :---: | :--- |
| SSL/TLS Mode | `FULL` | Hindari mode Flexible |
| SSL/TLS Recommender | `OFF` | Mencegah redirect berulang |
| gRPC | `ON` | Wajib untuk endpoint gRPC |
| WebSocket | `ON` | Wajib untuk endpoint WS |
| Always Use HTTPS | `OFF` | Agar port Non-TLS (80, 8880) aktif |
| Under Attack Mode | `OFF` | Mencegah pemblokiran handshake |

---

🖥️ Sistem Operasi Didukung

Distribusi Linux
| OS | Versi | Status |
| :--- | :--- | :---: |
| *Ubuntu* | 20.04 LTS, 22.04 LTS, 24.04 LTS | 🟢 Sangat Direkomendasikan |
| *Ubuntu* | 18.04, 23.10 | 🟡 Legacy / Testing |
| *Debian* | 10 (Buster), 11 (Bullseye), 12 (Bookworm) | 🟢 Stabil |
| *Debian* | 9 (Stretch) | 🟡 Kurang Stabil |
| *Debian* | 13 (Trixie), 14 (Forky) | ⏳ Segera Hadir |
| *Kali Linux* | Kali Rolling | 🟢 Stabil |

*Virtualisasi*
KVM • VMware • Xen • XenServer • Proxmox • LXC • OpenVZ 7 • Virtuozzo • ZFS

---

*⚙️ Spesifikasi & Arsitektur*

| Komponen | Kebutuhan Minimum | Rekomendasi |
| :--- | :--- | :--- |
| *CPU* | 1 vCPU | 1 vCPU atau lebih |
| *RAM* | 512 MB _(Auto-Swap aktif)_ | 1 GB+ |
| *Storage* | 10 GB SSD | 15 GB+ SSD NVMe |
| *OS* | Debian 10+ / Ubuntu 20.04+ | Ubuntu 22.04 / 24.04 LTS |

> [!IMPORTANT]
> *Arsitektur CPU:*
> - ✅ *x86_64 (64-bit)* didukung penuh.
> - ❌ *ARM / i386 (32-bit)* tidak didukung.

---

*📬 Kontak & Pengembang*

<div align="center">

Dibuat & dikelola oleh *[@izzcoyy](https://t.me/izzcoyy)*

[![Telegram](https://img.shields.io/badge/Telegram-Chat%20Pengembang-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/izzcoyy)
&nbsp;
[![WhatsApp](https://img.shields.io/badge/WhatsApp-WhatsApp%20Fast%20Response-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://wa.me/6282213283021)

</div>
```
