#!/bin/bash

set -e

echo "✅ Starting file replacement process..."

BASE_PATH="/opt/hiddify-manager/singbox/configs"

FILE1="03_routing.json.j2"
FILE2="05_inbounds_4100_hysteria.json.j2"

URL1="https://raw.githubusercontent.com/aliakbarnajmi/hiddify-moderator/main/03_routing.json.j2"
URL2="https://raw.githubusercontent.com/aliakbarnajmi/hiddify-moderator/main/05_inbounds_4100_hysteria.json.j2"

# Create backups
echo "📦 Creating backups of existing files..."
cp "$BASE_PATH/$FILE1" "$BASE_PATH/$FILE1.bak"
cp "$BASE_PATH/$FILE2" "$BASE_PATH/$FILE2.bak"

# Download and replace files
echo "⬇️ Downloading new 03_routing.json.j2 ..."
curl -fsSL "$URL1" -o "$BASE_PATH/$FILE1"

echo "⬇️ Downloading new 05_inbounds_4100_hysteria.json.j2 ..."
curl -fsSL "$URL2" -o "$BASE_PATH/$FILE2"

# Set permissions
chmod 644 "$BASE_PATH/$FILE1"
chmod 644 "$BASE_PATH/$FILE2"

# Apply configs
echo "🚀 Applying new configurations..."
/opt/hiddify-manager/apply_configs.sh

echo "🚀 Restart Sing-Box Core..."
systemctl restart hiddify-singbox

echo "✅ Operation completed successfully."
