#!/usr/bin/env bash
set -e

### =========================
### sing-box core build script
### Build from main branch
### =========================

# --------- Config ----------
SINGBOX_TAGS="with_v2ray_api with_quic with_gvisor with_dhcp with_wireguard with_utls with_acme with_clash_api with_tailscale"

HIDDIFY_DIR="/opt/hiddify-manager/singbox"
HIDDIFY_BIN="$HIDDIFY_DIR/sing-box"

# --------- Dependencies ----------
echo "▶ Installing build dependencies..."
apt update -y
apt install -y \
  git curl wget build-essential \
  pkg-config clang lld \
  golang ca-certificates

# --------- Workdir ----------
WORKDIR="/tmp/singbox-build"
CRONET_DIR="$WORKDIR/cronet-go"
SINGBOX_DIR="$WORKDIR/sing-box"

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# --------- cronet-go ----------
echo "▶ Cloning cronet-go..."
git clone --recursive --depth=1 https://github.com/sagernet/cronet-go.git
cd "$CRONET_DIR"

echo "▶ Downloading Chromium toolchain..."
go run ./cmd/build-naive --target=linux/amd64 download-toolchain

echo "▶ Exporting build environment..."
eval "$(go run ./cmd/build-naive --target=linux/amd64 env)"

# --------- sing-box ----------
echo
echo "▶ Cloning sing-box (main branch)..."
cd "$WORKDIR"
git clone --depth=1 https://github.com/SagerNet/sing-box.git
cd "$SINGBOX_DIR"

# --------- Detect Version ----------
echo "▶ Detecting sing-box version from git metadata..."
SINGBOX_VERSION="$(git describe --tags --dirty --always 2>/dev/null || true)"

if [[ -z "$SINGBOX_VERSION" ]]; then
  SINGBOX_VERSION="main-$(git rev-parse --short HEAD)"
fi

echo "▶ Detected version: $SINGBOX_VERSION"

# --------- Build ----------
echo "▶ Building sing-box core..."
go build \
  -tags "$SINGBOX_TAGS" \
  -ldflags "-X github.com/sagernet/sing-box/constant.Version=$SINGBOX_VERSION" \
  -o sing-box \
  ./cmd/sing-box

# --------- Result ----------
echo
echo "✅ Build completed successfully"
echo "📦 Output binary:"
ls -lh "$SINGBOX_DIR/sing-box"
echo

# --------- Replace Prompt ----------
read -rp "❓ Do you want to replace the current Hiddify sing-box core with this build? (y/N): " ANSWER

if [[ "$ANSWER" != "y" && "$ANSWER" != "Y" ]]; then
  echo "ℹ️ Replacement canceled by user."
  exit 0
fi

# --------- Hiddify Check ----------
if [[ ! -d "$HIDDIFY_DIR" ]]; then
  echo "❌ Directory $HIDDIFY_DIR does not exist."
  echo "❌ Hiddify panel does not seem to be installed. Cannot replace binary."
  exit 1
fi

if [[ ! -f "$HIDDIFY_BIN" ]]; then
  echo "❌ Existing sing-box binary not found."
  echo "❌ Expected path: $HIDDIFY_BIN"
  exit 1
fi

# --------- Backup ----------
BACKUP_FILE="$HIDDIFY_BIN.bak.$SINGBOX_VERSION.$(date +%Y%m%d-%H%M%S)"
echo "▶ Backing up existing sing-box binary..."
cp "$HIDDIFY_BIN" "$BACKUP_FILE"

# --------- Replace ----------
echo "▶ Replacing sing-box binary..."
cp "$SINGBOX_DIR/sing-box" "$HIDDIFY_BIN"
chmod +x "$HIDDIFY_BIN"

# --------- Restart ----------
echo "▶ Restarting hiddify-singbox service..."
systemctl daemon-reload
systemctl restart hiddify-singbox

echo
echo "✅ sing-box core successfully replaced"
echo "📦 Backup saved at:"
echo "$BACKUP_FILE"
