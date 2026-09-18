# Troubleshooting / عیب‌یابی

| Issue | Fix |
|---|---|
| SSH won't connect | `sudo systemctl status ssh` and check your firewall |
| Domain not loading | `sudo systemctl status cloudflared` and check the DNS record |
| Disk full | `df -h` and `du -sh /*` to find the heavy folder |
| CasaOS won't start | `sudo systemctl restart casaos` |

| مشکل | راه‌حل |
|---|---|
| SSH وصل نمی‌شود | `sudo systemctl status ssh` و بررسی فایروال |
| دامنه باز نمی‌شود | `sudo systemctl status cloudflared` و بررسی رکورد DNS |
| حافظه پر شده | `df -h` و `du -sh /*` |
| CasaOS بالا نمی‌آید | `sudo systemctl restart casaos` |
