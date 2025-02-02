# Nmap Auto Scanner with Telegram Alerts

This script automates **Nmap** scanning and sends scan differences (using `ndiff`) to **Telegram**. If no differences are found, it notifies you accordingly.

## Features
- Runs **Nmap** scans on specified targets.
- Uses `ndiff` to compare with previous scans.
- Sends scan differences to **Telegram**.
- If differences exceed Telegram's message limit, they are sent as a **file attachment**.
- Can be scheduled using **crontab** for automated scans.

## How to install?
You can either run the script within a **docker container** or install it manually on **any Linux Distribution**.

### Run the Docker Image

```bash
docker run -d --name ndiff-dailyscanner \
  -e TARGETS="your_targets" \
  -e OPTIONS="-v -T4 -F -sV" \
  -e TELEGRAM_BOT_TOKEN="your_telegram_bot_token" \
  -e TELEGRAM_CHAT_ID="your_chat_id" \
  -e CRON_SCHEDULE="* 2 * * *" \
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

### Manual installation


#### Requirements
- **Linux** (Tested on Ubuntu/Debian)
- **Nmap** installed (`sudo apt install nmap`)
- **ndiff** installed (`sudo apt install ndiff`)
- **cURL** installed (`sudo apt install curl`)
- A **Telegram bot** (see setup below)

#### Setup

##### 1️⃣ Create a Telegram Bot
1. Open Telegram and search for `@BotFather`.
2. Start a chat and send `/newbot`.
3. Follow instructions and get your **Bot Token**.
4. Send a message to your bot from your Telegram account.
5. Get your **Chat ID** by running:
   ```sh
   curl "https://api.telegram.org/botYOUR_BOT_TOKEN/getUpdates"
   ```
   Look for `"chat":{"id":YOUR_CHAT_ID}` in the response.

##### 2️⃣ Configure the Script
Edit the script and replace:
- `<targets>` → Your target hosts/IPs for scanning.
- `your_bot_token` → Your Telegram bot token.
- `your_chat_id` → Your Telegram chat ID.

Save the script as `scan-ndiff.sh` and make it executable:
```sh
chmod +x scan-ndiff.sh
```

##### 3️⃣ Run the Script
Execute manually:
```sh
./scan-ndiff.sh
```

##### 4️⃣ Automate with Crontab
To run the script daily at **2 AM**, add it to `crontab`:
```sh
crontab -e
```
Add the following line:
```sh
0 2 * * * /path/to/scan-ndiff.sh >> /path/to/nmap_cron.log 2>&1
```
Check if it's scheduled:
```sh
crontab -l
```

##### Output & Logs
- Nmap results are **only printed to the terminal**.
- If differences are found, they are **sent to Telegram**.
- If no differences are found, a message **"No differences found."** is sent to Telegram.
- If the `ndiff` output is too large, it is **sent as a file attachment**.

To check logs:
```sh
cat /path/to/nmap_cron.log
```

## License
MIT License. Feel free to use and modify!

