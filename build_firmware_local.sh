#!/bin/bash
# Alshka-WISP Local Linux / VPS Firmware Build Script
set -e

VERSION="24.10.0"
DEVICE="${1:-xiaomi_ax3000t}"

echo "=================================================="
echo "    Alshka-WISP Firmware Builder (OpenWrt $VERSION)"
echo "    Target: $DEVICE"
echo "=================================================="

# Check and install tools
sudo apt-get update -y
sudo apt-get install -y build-essential libncurses5-dev libncursesw5-dev \
    zlib1g-dev gawk git gettext libssl-dev xsltproc rsync wget unzip python3 zstd file

if [ "$DEVICE" = "xiaomi_ax3000t" ]; then
    IB_URL="https://downloads.openwrt.org/releases/${VERSION}/targets/mediatek/filogic/openwrt-imagebuilder-${VERSION}-mediatek-filogic.Linux-x86_64.tar.zst"
    PROFILE="xiaomi_mi-router-ax3000t"
    EXTRA_KMODS="kmod-nft-offload"
elif [ "$DEVICE" = "x86_64" ]; then
    IB_URL="https://downloads.openwrt.org/releases/${VERSION}/targets/x86/64/openwrt-imagebuilder-${VERSION}-x86-64.Linux-x86_64.tar.zst"
    PROFILE="generic"
    EXTRA_KMODS=""
else
    echo "Unknown device: $DEVICE. Use xiaomi_ax3000t or x86_64"
    exit 1
fi

echo "--> Downloading ImageBuilder..."
wget -q --show-progress "$IB_URL" -O ib.tar.zst
tar --zstd -xf ib.tar.zst
IB_DIR=$(ls -d openwrt-imagebuilder-*)
cd "$IB_DIR"

mkdir -p packages
cp -f ../packages/*.ipk packages/

mkdir -p files/etc/uci-defaults
cp -rf ../files/* files/

PKGS="luci luci-ssl luci-compat rp-pppoe-server tc-tiny kmod-sched-core kmod-sched-act-police kmod-sched-cake $EXTRA_KMODS htop nano curl wget-ssl ca-certificates ip-full v2raya xray-core alshka-wisp"

echo "--> Compiling Firmware..."
make image PROFILE="$PROFILE" PACKAGES="$PKGS" FILES=files/

mkdir -p ../output
cp -f bin/targets/*/*/*.bin ../output/ 2>/dev/null || cp -f bin/targets/*/*/*.img.gz ../output/ 2>/dev/null || true

echo "=================================================="
echo "    SUCCESS! Firmware built in ./output/"
echo "=================================================="
ls -lh ../output/
