#!/bin/sh
TARGETS="<targets>"
OPTIONS="-v -T4 -F -sV"
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
date=`date +%F`
cd /root/scans

# Run nmap scan
nmap $OPTIONS $TARGETS -oA scan-$date > /dev/null

# Display results in terminal
echo "*** NMAP RESULTS ***"
cat scan-$date.nmap

# Check for previous scan results
if [ -e scan-prev.xml ]; then
    ndiff scan-prev.xml scan-$date.xml > diff-$date.txt  # Save with .txt extension

    # Check if ndiff output is empty
    if [ -s diff-$date.txt ]; then
        echo "*** NDIFF RESULTS ***"
        cat diff-$date.txt

        # Check if the output is too long (> 4096 characters)
        diff_size=$(wc -c < diff-$date.txt)
        if [ "$diff_size" -gt 4000 ]; then
            # Send message about large file
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                 -d "chat_id=$TELEGRAM_CHAT_ID" \
                 -d "text=*** NDIFF RESULTS ***%0AToo many differences - see attached file."

            # Send as a file with .txt extension
            curl -F "chat_id=$TELEGRAM_CHAT_ID" \
                 -F "document=@diff-$date.txt" \
                 "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument"
        else
            # Send as a message
            diff_result=$(cat diff-$date.txt)
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                 -d "chat_id=$TELEGRAM_CHAT_ID" \
                 -d "text=*** NDIFF RESULTS ***%0A$diff_result"
        fi
    else
        echo "No differences found."
        
        # Send "No differences found" message to Telegram
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
             -d "chat_id=$TELEGRAM_CHAT_ID" \
             -d "text=*** NDIFF RESULTS ***%0ANo differences found."
    fi
fi

# Update symlink for previous scan
ln -sf scan-$date.xml scan-prev.xml
