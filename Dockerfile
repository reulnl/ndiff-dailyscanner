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
    tzdata \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Python package for calculating cron execution times
RUN pip install croniter

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

# Create a script to update cron dynamically based on CRON_SCHEDULE
RUN echo '#!/bin/sh\n\
echo "=============== ndiff-dailyscanner ==============="\n\
env\n\
echo "=================================================="\n\
echo "Setting up cron job with schedule: $CRON_SCHEDULE"\n\
echo "$CRON_SCHEDULE /root/scans/scan-ndiff.sh >> /proc/1/fd/1 2>> /proc/1/fd/2" > /etc/crontab\n\
chmod 0644 /etc/crontab\n\
crontab /etc/crontab\n\
\n\
# Get next execution time using Python (croniter)\n\
NEXT_RUN=$(python3 -c "from croniter import croniter; from datetime import datetime; import os;\n\
tz = os.getenv(\'TZ\', \'UTC\')\n\
current_time = datetime.now()\n\
cron_schedule = os.getenv(\'CRON_SCHEDULE\', \'0 2 * * *\')\n\
next_time = croniter(cron_schedule, current_time).get_next(datetime)\n\
print(next_time.strftime(\'%Y-%m-%d %H:%M:%S\'))")\n\
\n\
# Convert to human-readable format\n\
NEXT_RUN_TIMESTAMP=$(date -d "$NEXT_RUN" +"%Y-%m-%d %H:%M:%S %Z")\n\
\n\
# Calculate time left\n\
CURRENT_TIME=$(date +"%s")\n\
NEXT_RUN_TIME=$(date -d "$NEXT_RUN" +"%s")\n\
SECONDS_LEFT=$((NEXT_RUN_TIME - CURRENT_TIME))\n\
HOURS_LEFT=$((SECONDS_LEFT / 3600))\n\
MINUTES_LEFT=$(((SECONDS_LEFT % 3600) / 60))\n\
\n\
echo "Cron job successfully added! Next run time: $NEXT_RUN_TIMESTAMP"\n\
echo "Time left until next execution: ${HOURS_LEFT}h ${MINUTES_LEFT}m"\n\
\n\
cron -f' > /root/start-cron.sh && chmod +x /root/start-cron.sh

# Start cron using the dynamic schedule
CMD ["/root/start-cron.sh"]
