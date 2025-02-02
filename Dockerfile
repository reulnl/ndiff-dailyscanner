# Use a lightweight Linux distribution
FROM debian:latest AS base

# Set the working directory inside the container
WORKDIR /root/scans

# Install dependencies
RUN apt update && apt install -y \
    nmap \
    ndiff \
    curl \
    cron \
    tzdata \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Set up a Python virtual environment and install croniter
RUN python3 -m venv /root/venv && \
    /root/venv/bin/pip install --upgrade pip && \
    /root/venv/bin/pip install croniter

# Copy the script into the container
COPY scan-ndiff.sh /root/scans/scan-ndiff.sh

# Ensure the script is executable
RUN chmod +x /root/scans/scan-ndiff.sh

# Expose environment variables
ENV TARGETS="<default_targets>"
ENV OPTIONS="-v -T4 -F -sV"
ENV TELEGRAM_BOT_TOKEN="your_bot_token"
ENV TELEGRAM_CHAT_ID="your_chat_id"
ENV CRON_SCHEDULE="0 2 * * *"
ENV TZ="UTC"

# Copy start script
COPY start-cron.sh /root/start-cron.sh
RUN chmod +x /root/start-cron.sh

# Start cron using the dynamic schedule
CMD ["/root/start-cron.sh"]
