# Security notes / نکات امنیتی

## Never commit these files

- `~/.cloudflared/cert.pem`
- `~/.cloudflared/*.json` (tunnel credentials)
- Tailscale state / auth keys
- Any password, token, or API key
- `.env` files

هرگز این فایل‌ها رو commit نکن:

- `~/.cloudflared/cert.pem`
- `~/.cloudflared/*.json` (credentials تونل)
- کلیدها و state تیل‌اسکیل
- هر پسورد، توکن یا API key
- فایل‌های `.env`

See the root `.gitignore` for a starting point.

## SSH: Tailscale only, not the public tunnel

SSH is intentionally left out of `configs/cloudflared/config.yml.example`. Exposing the same service over two separate paths (public tunnel + private VPN) doubles the attack surface without adding real capability. If you have a specific reason to expose SSH publicly, set its DNS record to **DNS only** (not proxied), since Cloudflare only proxies HTTP/HTTPS.

For SSH itself, run `scripts/harden-ssh.sh` **after** confirming key-based login already works — it disables root login and password authentication. Test a new connection before closing your existing session, same as with the firewall script.

SSH فقط از طریق Tailscale expose شده، نه از طریق تونل عمومی. برای خود SSH، بعد از اینکه مطمئن شدی ورود با کلید کار می‌کنه، `scripts/harden-ssh.sh` رو اجرا کن — ورود root و ورود با پسورد رو غیرفعال می‌کنه.

## CasaOS: a tunnel doesn't make the dashboard secure

Pointing a Cloudflare Tunnel hostname at CasaOS's port (80) makes the **admin dashboard** reachable from the entire internet, protected only by whatever password is set inside CasaOS itself. A tunnel solves reachability, not authentication.

Before exposing CasaOS (or any admin panel) publicly, put **Cloudflare Access** in front of it: Cloudflare dashboard → Zero Trust → Access → Applications → add the hostname → require login via email one-time code or an identity provider. This is free for personal use and needs no code changes. Without it, treat the hostname as reachable by anyone who finds it — Cloudflare Tunnel provides no authentication by itself.

وصل‌کردن هاست‌نیم تونل به پورت CasaOS یعنی **پنل مدیریتی** از کل اینترنت در دسترسه، فقط با پسورد خود CasaOS. راه‌حل: قبل از انتشار عمومی، **Cloudflare Access** رو جلوش بذار (رایگان برای استفاده‌ی شخصی) تا یه لایه‌ی احراز هویت مجزا اضافه بشه.

## The `docker` group is root-equivalent

Adding a user to the `docker` group (as `scripts/install-docker.sh` does) is effectively giving that user root access to the whole machine — a container can mount the host filesystem. Only add trusted users to this group, and don't run unfamiliar/untrusted container images with it.

عضویت در گروه `docker` عملاً معادل دسترسی root به کل سیستمه (یه کانتینر می‌تونه فایل‌سیستم host رو mount کنه). فقط کاربران مورد‌اعتماد رو به این گروه اضافه کن.

## Samba: single-user model

`configs/samba/smb.conf.example` assumes one trusted user owns the share. If multiple people need write access to the same files, you need a shared group instead — see the comments in that file.

فایل نمونه‌ی Samba یه مدل تک‌کاربره رو فرض می‌کنه. اگه چند نفر باید به فایل‌های مشترک دسترسی نوشتن داشته باشن، به یه گروه مشترک نیاز داری — کامنت‌های همون فایل رو ببین.

## Hardening scripts

- `setup-auto-updates.sh` — enables `unattended-upgrades` for automatic Debian security patches.
- `setup-fail2ban.sh` — bans an IP for 1 hour after 5 failed SSH login attempts within 10 minutes.
- `setup-firewall.sh` — enables UFW with a default-deny policy, SSH allowed only on the Tailscale interface, and Samba/CasaOS ports open only to the local subnet. **Run this with an existing SSH session kept open**, and verify a new connection works before closing it.
- `harden-ssh.sh` — disables root login and password auth. Run only after confirming key-based login works.

## Backups and health checks (basic)

`scripts/backup.sh` does a simple `rsync` copy of `/srv/shared` and `/srv/DATA` to a destination you configure (external drive, NAS, or remote host). It is intentionally basic — periodically test that you can actually restore a file from the backup destination, not just that the script runs without errors.

`scripts/check-health.sh` reports disk space, SMART disk health, and the status of every service this project sets up. Safe to run anytime; it changes nothing.

Neither script covers RAID/disk redundancy — that requires additional hardware and is a deliberate choice left to you.

اسکریپت `backup.sh` یه کپی ساده با `rsync` انجام می‌ده — عمداً ابتدایی نگه داشته شده؛ به‌صورت دوره‌ای تست کن که واقعاً می‌شه از مقصد بک‌آپ فایل بازیابی کرد. `check-health.sh` هم وضعیت دیسک و سرویس‌ها رو گزارش می‌ده، بدون تغییر چیزی.
