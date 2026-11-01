#!/bin/sh
# Pull the module log to ./logs/
set -e
cd "$(dirname "$0")/.."; mkdir -p logs
adb shell su -c 'cat /data/adb/producer-mode/log.old /data/adb/producer-mode/log.txt 2>/dev/null' > logs/log.txt
echo "logs/log.txt ($(wc -l < logs/log.txt) lines)"
