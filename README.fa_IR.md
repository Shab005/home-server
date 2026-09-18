[English](https://github.com/Shab005/home-server/blob/main/README.md) | [فارسی](https://github.com/Shab005/home-server/blob/main/README.fa_IR.md)

# 🏠 سرور خانگی — Debian + CasaOS + دسترسی از راه دور

یه سرور خانگی self-hosted روی یه کامپیوتر قدیمی: اشتراک فایل تو شبکه‌ی محلی، یه داشبورد مدیریتی مبتنی بر Docker (CasaOS)، و دسترسی از راه دور از هر جای دنیا بدون باز کردن حتی یک پورت روی روتر.

از عمد دو مسیر دسترسی جدا از هم استفاده شده:

- **Cloudflare Tunnel** — دسترسی عمومی به سرویس‌های مشخص از طریق یه دامنه‌ی واقعی، بدون پورت‌فورواردینگ.
- **Tailscale** — یه VPN خصوصی بین دستگاه‌های خودت، برای دسترسی مستقیم (از جمله SSH).

## قابلیت‌ها

- IP ثابت داخلی
- دسترسی SSH برای مدیریت از راه دور
- اشتراک فایل با Samba
- Docker + CasaOS برای مدیریت اپلیکیشن‌ها
- دسترسی عمومی از طریق Cloudflare Tunnel
- دسترسی خصوصی از طریق Tailscale
- سخت‌سازی: فایروال (UFW)، fail2ban، آپدیت خودکار امنیتی، ورود SSH فقط با کلید
- اسکریپت‌های پایه‌ای بک‌آپ و health-check
- نگه‌داری داده روی یه پارتیشن جدا

## ساختار ریپو

```
home-server/
├── README.md
├── README.fa_IR.md
├── .gitignore
├── configs/
│   ├── cloudflared/config.yml.example
│   ├── samba/smb.conf.example
│   └── network/20-static-enp2s0.network
├── scripts/
│   ├── install-docker.sh
│   ├── install-casaos.sh
│   ├── install-cloudflared.sh
│   ├── install-tailscale.sh
│   ├── setup-firewall.sh
│   ├── setup-fail2ban.sh
│   ├── setup-auto-updates.sh
│   ├── harden-ssh.sh
│   ├── backup.sh
│   └── check-health.sh
└── docs/
    ├── troubleshooting.md
    └── security.md
```

فایل‌های زیر `configs/` همه `.example` هستن — کپی کن، مقادیر خودتو بذار. اسکریپت‌های نصب امن هستن برای اجرای مجدد (مراحل انجام‌شده رو رد می‌کنن).

## راه‌اندازی

### ۱. به‌روزرسانی سیستم

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git nano net-tools screen unzip samba openssh-server
```

### ۲. تنظیم IP ثابت

**قبل از هر تغییری**، ببین کدوم مدیر شبکه الان فعاله — غیرفعال کردن اشتباه یا اسم کارت شبکه‌ی غلط می‌تونه اتصالت رو قطع کنه:

```bash
systemctl is-active NetworkManager networking dhcpcd 2>/dev/null
ip link show
```

کانفیگ رو ویرایش کن (نمونه‌ش تو [`configs/network/20-static-enp2s0.network`](configs/network/20-static-enp2s0.network) — هم اسم فایل هم خط `Name=` رو با **کارت شبکه‌ی واقعی خودت** جایگزین کن):

```bash
sudo nano /etc/systemd/network/20-static-<اسم-کارت-شبکه‌ی-خودت>.network
```

```bash
sudo systemctl disable networking NetworkManager dhcpcd 2>/dev/null
sudo systemctl stop networking NetworkManager dhcpcd 2>/dev/null
sudo systemctl enable systemd-networkd --now
sudo systemctl restart systemd-networkd
sudo reboot
```

اگه اتصال قطع شد، با دسترسی فیزیکی/کنسول بوت کن و همون سرویسی که `systemctl is-active` نشونت داده بود رو دوباره فعال کن (مثلاً `sudo systemctl enable --now NetworkManager`). یه جایگزین که اصلاً به شبکه‌ی سیستم‌عامل دست نمی‌زنه: رو خود روتر برای MAC address این دستگاه یه **DHCP Reservation** بذار.

### ۳. فعال‌سازی SSH

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

### ۴. اشتراک فایل با Samba

این نمونه یه کاربر تک و مورداعتماد رو فرض می‌کنه — اگه چند نفر باید دسترسی نوشتن داشته باشن، کامنت‌های [`configs/samba/smb.conf.example`](configs/samba/smb.conf.example) رو ببین.

```bash
sudo apt install samba -y
sudo mkdir -p /srv/shared
sudo chown <USER>:<USER> /srv/shared
sudo smbpasswd -a <USER>
```

محتوای فایل نمونه رو به `/etc/samba/smb.conf` اضافه کن، بعد:

```bash
sudo systemctl restart smbd
sudo systemctl enable smbd
```

دسترسی از ویندوز: `\\<ip-سرور>\Shared`. از لینوکس/KDE یا مک: `smb://<ip-سرور>/Shared`. تست از خود سرور: `sudo apt install -y smbclient && smbclient -L localhost -U <USER>`.

### ۵. نصب Docker

⚠️ این کار کاربرت رو به گروه `docker` اضافه می‌کنه که عملاً معادل دسترسی root هست (یه کانتینر می‌تونه فایل‌سیستم host رو mount کنه). فقط برای کاربران مورداعتماد انجامش بده.

```bash
bash scripts/install-docker.sh
```

### ۶. نصب CasaOS

نصب‌کننده‌ی خود CasaOS خودش Docker رو از مخزن رسمی نصب می‌کنه، پس اگه فقط CasaOS می‌خوای، مرحله‌ی ۵ رو رد کن.

```bash
bash scripts/install-casaos.sh
```

داشبورد: `http://<local-ip-سرور>`

### ۷. راه‌اندازی Cloudflare Tunnel

```bash
bash scripts/install-cloudflared.sh
```

> اگه "Unable to locate package" داد، بعد از ساخته‌شدن فایل مخزن دوباره `sudo apt update` بزن.

```bash
cloudflared tunnel login
cloudflared tunnel create <TUNNEL_NAME>
```

فایل [`configs/cloudflared/config.yml.example`](configs/cloudflared/config.yml.example) رو کپی و مقادیرشو پر کن، بعد:

```bash
sudo mkdir -p /etc/cloudflared
sudo cp ~/.cloudflared/config.yml /etc/cloudflared/
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
cloudflared tunnel route dns <TUNNEL_NAME> app.example.com
```

> ⚠️ **تونل فقط قابل‌دسترس بودن رو حل می‌کنه، نه امنیت رو.** اگه داری یه پنل مدیریتی مثل CasaOS رو این‌طوری منتشر می‌کنی، **Cloudflare Access** رو جلوش بذار (Zero Trust → Access → Applications، رایگان برای شخصی) تا قبل از رسیدن هرکسی، یه لاگین لازم باشه. [`docs/security.md`](docs/security.md) رو ببین.
>
> SSH از عمد اصلاً از این تونل رد نمی‌شه.

### ۸. نصب Tailscale

```bash
bash scripts/install-tailscale.sh
```

### ۹. سخت‌سازی سرور

```bash
bash scripts/setup-auto-updates.sh
bash scripts/setup-fail2ban.sh
```

`scripts/harden-ssh.sh` ورود root و پسورد رو غیرفعال می‌کنه — **فقط بعد از اطمینان از کارکردن ورود با کلید** (`ssh-copy-id` اول) اجراش کن.

اسکریپت فایروال ممکنه قفلت کنه:
- یه session SSH باز نگه دار
- از ترمینال دوم اجرا کن
- قبل از بستن اولی، یه اتصال جدید تست کن
- اگه fail شد: `sudo ufw disable`

```bash
bash scripts/setup-firewall.sh
```

### ۱۰. بک‌آپ و health-check

```bash
bash scripts/check-health.sh
bash scripts/backup.sh
```

این‌ها عمداً ابتدایی‌ان — به‌صورت دوره‌ای تست کن که واقعاً می‌شه فایل رو از مقصد بک‌آپ بازیابی کرد.

### ۱۱. انتقال داده به پارتیشن بزرگ‌تر (اختیاری)

```bash
sudo systemctl stop docker
sudo mv /var/lib/docker /srv/docker
sudo ln -s /srv/docker /var/lib/docker

sudo systemctl stop casaos
sudo mv /DATA /srv/DATA
sudo ln -s /srv/DATA /DATA

sudo systemctl start docker
sudo systemctl start casaos
```

اول سرویس‌ها رو متوقف کن — جابه‌جایی داده زیر پای یه سرویس درحال‌اجرا می‌تونه خرابش کنه. مطمئن شو مقصد واقعاً mount شده، وگرنه symlink بی‌صدا به یه فضای خالی رو دیسک اصلی اشاره می‌کنه.

## امنیت

فایل کامل: [`docs/security.md`](docs/security.md). خلاصه: SSH فقط از Tailscale، هیچ‌وقت credentials رو commit نکن، گروه `docker` معادل root‌ه، و پنل مدیریتی پشت تونل نیاز به Cloudflare Access داره.

## محدودیت‌های شناخته‌شده

- بدون RAID — یه تصمیم سخت‌افزاریه که خودت باید بگیری.
- `backup.sh` یه کپی ساده‌ی rsync‌ه، نه یه سیستم بک‌آپ کامل (بدون versioning).
- نمونه‌ی Samba یه مدل تک‌کاربره‌ست.
- ترمینال‌های ناشناس (مثل `xterm-ghostty`) هشدار بی‌ضرر می‌دن.

## عیب‌یابی

[`docs/troubleshooting.md`](docs/troubleshooting.md)

## لایسنس

مستندات شخصی. سرویس‌های ثالث تابع شرایط خودشونن.
