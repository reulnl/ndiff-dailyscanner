# Nmap Auto Scanner with Telegram Alerts

This script automates **Nmap** scanning and sends scan differences (using `ndiff`) to **Telegram**. If no differences are found, it notifies you accordingly.

## Features
- Runs **Nmap** scans on specified targets.
- Uses `ndiff` to compare with previous scans.
- Sends scan differences to **Telegram**.
- If differences exceed Telegram's message limit, they are sent as a **file attachment**.
- Can be scheduled using **crontab** for automated scans.

## How to install?
You can either run the script within a **docker container**.

### Run the Docker Image

```bash
docker run -d --name ndiff-dailyscanner \
  -e TARGETS="your_targets" \
  -e OPTIONS="-v -T4 -F -sV" \
  -e TELEGRAM_BOT_TOKEN="your_telegram_bot_token" \
  -e TELEGRAM_CHAT_ID="your_chat_id" \
  -e CRON_SCHEDULE="0 2 * * *" \
  -e TZ="UTC" \
  -v /usr/local/ndiff-dailyscanner:/root/scans/results \
  ghcr.io/reulnl/ndiff-dailyscanner:latest
```

- Different targets can be separated with a space (e.g. 192.168.0.0/24 8.8.8.8/32)
- For help with generation your CRON_SCHEDULE use e.g. https://crontab.guru/

You can always manually start a scan with the following docker command, without waiting for the CRON job to start:
```bash
docker exec -it ndiff-dailyscanner /root/scans/scan-ndiff.sh
```

## License
MIT License. Feel free to use and modify!

