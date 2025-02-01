# Use a lightweight Linux distribution
FROM debian:latest

# Set the working directory inside the container
WORKDIR /root/scans

# Install dependencies
RUN apt update && apt install -y \
    nmap \
    ndiff \
    curl \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Copy the script into the container
COPY scan-ndiff.sh /root/scans/scan-ndiff.sh

# Ensure the script is executable
RUN chmod +x /root/scans/scan-ndiff.sh

# Expose environment variables
ENV TARGETS="<default_targets>"
ENV OPTIONS="-v -T4 -F -sV"
ENV TELEGRAM_BOT_TOKEN="your_bot_token"
ENV TELEGRAM_CHAT_ID="your_chat_id"
ENV CRON_SCHEDULE="0 2 * * *"  # Default: Runs every day at 2 AM

# Create a script to update cron dynamically based on CRON_SCHEDULE
RUN echo '#!/bin/sh\n\
echo "$CRON_SCHEDULE /root/scans/scan-ndiff.sh" > /etc/crontab\n\
chmod 0644 /etc/crontab\n\
crontab /etc/crontab\n\
cron -f' > /root/start-cron.sh && chmod +x /root/start-cron.sh

# Start cron using the dynamic schedule
CMD ["/root/start-cron.sh"]
