#!/bin/bash

# Name of the report file
REPORT="network_report.txt"

# Start the report file
echo "==================================" > "$REPORT"
echo " NETWORK HEALTH CHECK REPORT" >> "$REPORT"
echo "==================================" >> "$REPORT"

# 1. Server Information
echo "" >> "$REPORT"
echo "1. SERVER INFORMATION" >> "$REPORT"
echo "Hostname: $(hostname)" >> "$REPORT"
echo "Current User: $(whoami)" >> "$REPORT"
echo "Date & Time: $(date)" >> "$REPORT"

# 2. Network Information
echo "" >> "$REPORT"
echo "2. NETWORK INFORMATION" >> "$REPORT"

# This gets the main IP address on macOS.
IP_ADDRESS=$(ipconfig getifaddr en0 2>/dev/null)

# If en0 is empty, try en1.
if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(ipconfig getifaddr en1 2>/dev/null)
fi

echo "IP Address: $IP_ADDRESS" >> "$REPORT"

# This gets the default gateway on macOS.
DEFAULT_GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway/ {print $2}')
echo "Default Gateway: $DEFAULT_GATEWAY" >> "$REPORT"

# This gets the first DNS server.
DNS_SERVER=$(scutil --dns 2>/dev/null | awk '/nameserver\[[0-9]+\]/ {print $3; exit}')
echo "DNS Server: $DNS_SERVER" >> "$REPORT"

# 3. Internet Connectivity Check
echo "" >> "$REPORT"
echo "3. INTERNET CONNECTIVITY" >> "$REPORT"

if ping -c 2 8.8.8.8 > /dev/null 2>&1
then
    echo "Internet Connectivity: UP" >> "$REPORT"
else
    echo "Internet Connectivity: DOWN" >> "$REPORT"
fi

# 4. DNS Resolution Check
echo "" >> "$REPORT"
echo "4. DNS RESOLUTION" >> "$REPORT"

if nslookup google.com > /dev/null 2>&1
then
    echo "DNS Resolution: WORKING" >> "$REPORT"
else
    echo "DNS Resolution: FAILED" >> "$REPORT"
fi

# 5. Website Availability Check
echo "" >> "$REPORT"
echo "5. WEBSITE AVAILABILITY" >> "$REPORT"

for site in google.com github.com amazon.com
do
    if curl -Is --max-time 5 "https://$site" > /dev/null 2>&1
    then
        echo "$site : UP" >> "$REPORT"
    else
        echo "$site : DOWN" >> "$REPORT"
    fi
done

echo "" >> "$REPORT"
echo "Report generated successfully." >> "$REPORT"

# Show the report on the screen
cat "$REPORT"
