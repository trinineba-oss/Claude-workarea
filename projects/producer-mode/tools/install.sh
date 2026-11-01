#!/bin/sh
# Build, push and install. Usage: tools/install.sh [zip]
set -e
cd "$(dirname "$0")/.."
ZIP=${1:-$(tools/build.sh)}
NAME=$(basename "$ZIP")
adb push "$ZIP" "/data/local/tmp/$NAME"
adb shell su -c "magisk --install-module /data/local/tmp/$NAME"
echo "Installed. Reboot to activate: adb reboot"
