#!/bin/sh
# Zip producer-mode/ into dist/producer-mode-<version>.zip
set -e
cd "$(dirname "$0")/.."
VER=$(grep '^version=' producer-mode/module.prop | cut -d= -f2)
mkdir -p dist; OUT="$PWD/dist/producer-mode-$VER.zip"; rm -f "$OUT"
(cd producer-mode && zip -r -X -q "$OUT" .)
echo "$OUT"
