#!/bin/sh

# Read environment variables
TARGETS="${TARGETS:-<default_targets>}"
OPTIONS="${OPTIONS:-"-v -T4 -F -sV"}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-your_bot_token}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-your_chat_id}"

date=$(date +%F)

# Ensure /root/scans/results directory exists
mkdir -p /root/scans/results
cd /root/scans/results || exit 1

# Housekeeping: Remove logfiles older than 1 month
find /root/scans/results -type f \( -name "*.xml" -o -name "*.gnmap" -o -name "*.nmap" -o -name "diff-*.txt" \) -mtime +30 -exec rm {} \;

# Separate IPv4 and IPv6 addresses
IPV4_TARGETS=""
IPV6_TARGETS=""

for target in $TARGETS; do
    if echo "$target" | grep -q ":"; then
        IPV6_TARGETS="$IPV6_TARGETS $target"
    else
        IPV4_TARGETS="$IPV4_TARGETS $target"
    fi
done

# Run IPv4 scan if there are IPv4 targets
if [ -n "$IPV4_TARGETS" ]; then
    nmap $OPTIONS $IPV4_TARGETS -oA scan-ipv4-$date > /dev/null
fi

# Run IPv6 scan if there are IPv6 targets
if [ -n "$IPV6_TARGETS" ]; then
    nmap -6 $OPTIONS $IPV6_TARGETS -oA scan-ipv6-$date > /dev/null
fi

# Combine ndiff results
MESSAGE="*** NDIFF RESULTS ***"

if [ -e scan-prev-ipv4.xml ] && [ -e scan-ipv4-$date.xml ]; then
    ndiff scan-prev-ipv4.xml scan-ipv4-$date.xml | grep -v "^ Nmap" > diff-ipv4-$date.txt
    if [ -s diff-ipv4-$date.txt ]; then
        MESSAGE="$MESSAGE%0A%0A*** IPv4 Changes ***%0A$(cat diff-ipv4-$date.txt)"
    else
        MESSAGE="$MESSAGE%0A%0A*** IPv4 Changes ***%0ANo differences found."
    fi
fi

if [ -e scan-prev-ipv6.xml ] && [ -e scan-ipv6-$date.xml ]; then
    ndiff scan-prev-ipv6.xml scan-ipv6-$date.xml | grep -v "^ Nmap" > diff-ipv6-$date.txt
    if [ -s diff-ipv6-$date.txt ]; then
        MESSAGE="$MESSAGE%0A%0A*** IPv6 Changes ***%0A$(cat diff-ipv6-$date.txt)"
    else
        MESSAGE="$MESSAGE%0A%0A*** IPv6 Changes ***%0ANo differences found."
    fi
fi

# Check total message size
MESSAGE_SIZE=${#MESSAGE}
if [ "$MESSAGE_SIZE" -gt 4000 ]; then
    echo "$MESSAGE" > combined-diff-$date.txt
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=Too many differences - see attached file."
    curl -F "chat_id=$TELEGRAM_CHAT_ID" \
        -F "document=@combined-diff-$date.txt" \
        "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument"
else
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$MESSAGE"
fi

# Update previous scan references
[ -e scan-ipv4-$date.xml ] && ln -sf scan-ipv4-$date.xml scan-prev-ipv4.xml
[ -e scan-ipv6-$date.xml ] && ln -sf scan-ipv6-$date.xml scan-prev-ipv6.xml
