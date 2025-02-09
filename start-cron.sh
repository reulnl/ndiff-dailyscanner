#!/bin/sh

echo "=============== ndiff-dailyscanner ==============="
env
echo "=================================================="
echo "Setting up cron job with schedule: $CRON_SCHEDULE"

# Write cron schedule to crontab
echo "$CRON_SCHEDULE /root/scans/scan-ndiff.sh >> /proc/1/fd/1 2>> /proc/1/fd/2" > /etc/crontab
chmod 0644 /etc/crontab
crontab /etc/crontab

# Get next execution time using Python (croniter)
NEXT_RUN=$(/root/venv/bin/python3 -c "
from croniter import croniter
from datetime import datetime
import os

tz = os.getenv('TZ', 'UTC')
current_time = datetime.now()
cron_schedule = os.getenv('CRON_SCHEDULE', '0 2 * * *')

# Get next execution time
next_time = croniter(cron_schedule, current_time).get_next(datetime)

# Print in a format that `date -d` can parse
print(next_time.strftime('%Y-%m-%d %H:%M:%S'))
")

# Validate NEXT_RUN format
if [ -z "$NEXT_RUN" ]; then
    echo "ERROR: Failed to calculate the next run time."
    exit 1
fi

# Convert to human-readable format
if [ -n "$NEXT_RUN" ]; then
NEXT_RUN_TIMESTAMP=$(date -d "$NEXT_RUN" +"%Y-%m-%d %H:%M:%S %Z" 2>/dev/null)

if [ -z "$NEXT_RUN_TIMESTAMP" ]; then
    echo "ERROR: Invalid cron execution time format."
    exit 1
fi

# Calculate time left
CURRENT_TIME=$(date +"%s")
NEXT_RUN_TIME=$(date -d "$NEXT_RUN" +"%s" 2>/dev/null)
else
    echo "Error: NEXT_RUN is empty or invalid"
    exit 1
fi

if [ -z "$NEXT_RUN_TIME" ]; then
    echo "ERROR: Failed to calculate the next run timestamp."
    exit 1
fi

SECONDS_LEFT=$((NEXT_RUN_TIME - CURRENT_TIME))
HOURS_LEFT=$((SECONDS_LEFT / 3600))
MINUTES_LEFT=$(((SECONDS_LEFT % 3600) / 60))

echo "Cron job successfully added! Next run time: $NEXT_RUN_TIMESTAMP"
echo "Time left until next execution: ${HOURS_LEFT}h ${MINUTES_LEFT}m"

# Export all env variables and start cron
printenv | grep -v >> /etc/environment
cron -f
