#!/bin/bash
# Builds a debug APK of the game: build/chad-gyro-demo.apk
#
# Needs Godot 4.7 with its Android export templates, a JDK (17 or newer) and the Android SDK
# (platform-tools, build-tools;35.0.0, platforms;android-35). Godot looks for the SDK and a
# debug keystore where its Editor Settings say (Export > Android); by default
# ~/Android/Sdk and ~/.local/share/godot/keystores/debug.keystore. To make a keystore:
#   keytool -genkeypair -keystore debug.keystore -storepass android -alias androiddebugkey \
#     -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
godot --headless --path . --import >/dev/null 2>&1 || true
godot --headless --path . --export-debug Android build/chad-gyro-demo.apk
ls -la build/chad-gyro-demo.apk
