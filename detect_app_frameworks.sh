#!/bin/bash

# ================================
# 📱 Mobile App Framework Detector
# ================================
# Detects the framework (Flutter, React Native, WebView, Native)
# used in APK, XAPK, ZIP bundles, or IPA files.
#
# Author: Cyb3r_Slay3r
# GitHub: https://github.com/MuhammedShebin
# ================================

# Enable colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Spinner animation
spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\\b\\b\\b\\b\\b\\b"
  done
  printf "    \\b\\b\\b\\b"
}

# Entry check
APP_FILE="$1"
if [[ -z "$APP_FILE" || ! -f "$APP_FILE" ]]; then
  echo -e "${RED}[✘] Usage: $0 <apk|xapk|ipa|zip>${NC}"
  exit 1
fi

EXT="${APP_FILE##*.}"
TMP_DIR=$(mktemp -d)
APK_TMP=$(mktemp -d)

echo -e "${BLUE}[*] Processing:${NC} $APP_FILE"
echo -e "${BLUE}[*] Extracting to:${NC} $TMP_DIR"

unzip -q "$APP_FILE" -d "$TMP_DIR" &
spinner

# APK / ZIP / XAPK bundle detection
if [[ "$EXT" == "apk" ]]; then
  echo -e "${GREEN}[✓] Detected:${NC} APK"
  APK_LIST="$APP_FILE"
elif [[ "$EXT" == "xapk" || "$EXT" == "zip" ]]; then
  APK_LIST=$(find "$TMP_DIR" -name "*.apk")
  echo -e "${GREEN}[✓] Detected:${NC} Bundle with $(echo \"$APK_LIST\" | wc -l) APK(s)"
elif [[ "$EXT" == "ipa" ]]; then
  echo -e "${GREEN}[✓] Detected:${NC} IPA file (iOS App)"
  PAYLOAD_DIR=$(find "$TMP_DIR" -name "Payload" -type d | head -n 1)
  APP_DIR=$(find "$PAYLOAD_DIR" -name "*.app" -type d | head -n 1)

  if [[ ! -d "$APP_DIR" ]]; then
    echo -e "${RED}[✘] .app directory not found in IPA${NC}"
    rm -rf "$TMP_DIR" "$APK_TMP"
    exit 1
  fi

  echo -e "${CYAN}[>] Analyzing:${NC} $(basename "$APP_DIR")"

  if find "$APP_DIR" -iname "flutter_assets" | grep -q . || find "$APP_DIR" -iname "*libFlutter.dylib" | grep -q .; then
    echo -e "${YELLOW}[+] Framework:${NC} Flutter (iOS)"
  elif find "$APP_DIR" -iname "*libReact*.dylib" | grep -q . || find "$APP_DIR" -type f -exec strings {} \; 2>/dev/null | grep -q 'RCTBridge'; then
    echo -e "${YELLOW}[+] Framework:${NC} React Native (iOS)"
  elif grep -q 'UIWebView\|WKWebView' < <(find "$APP_DIR" -type f -exec strings {} \; 2>/dev/null); then
    if find "$APP_DIR" -iname "*.html" -o -iname "*.js" -o -iname "*.css" | grep -q .; then
      echo -e "${YELLOW}[+] Framework:${NC} WebView-based Hybrid App (iOS)"
    else
      echo -e "${YELLOW}[+] Framework:${NC} Uses WebView, unclear if hybrid"
    fi
  else
    echo -e "${YELLOW}[+] Framework:${NC} Likely Native (Swift/Obj-C)"
  fi

  rm -rf "$TMP_DIR" "$APK_TMP"
  exit 0
fi

# Function to analyze each APK
analyze_apk() {
  local APK_PATH="$1"
  local APK_NAME=$(basename "$APK_PATH")

  echo -e "${CYAN}[>] Analyzing APK:${NC} $APK_NAME"
  unzip -q "$APK_PATH" -d "$APK_TMP/$APK_NAME"

  if [[ -f "$APK_TMP/$APK_NAME/lib/arm64-v8a/libapp.so" || -f "$APK_TMP/$APK_NAME/assets/flutter_assets/isolate_snapshot_data" ]]; then
    echo -e "${YELLOW}[+] Framework:${NC} Flutter"
  elif unzip -p "$APK_PATH" classes*.dex 2>/dev/null | strings | grep -q 'ReactNative'; then
    echo -e "${YELLOW}[+] Framework:${NC} React Native"
  elif find "$APK_TMP/$APK_NAME/assets" "$APK_TMP/$APK_NAME/res" 2>/dev/null | grep -E '\\.(html|js|css)$' | grep -q . && unzip -p "$APK_PATH" classes*.dex | strings | grep -q 'WebView'; then
    echo -e "${YELLOW}[+] Framework:${NC} WebView-based Hybrid App"
  else
    echo -e "${YELLOW}[+] Framework:${NC} Likely Native (Java/Kotlin)"
  fi

  ABI_LIST=$(find "$APK_TMP/$APK_NAME/lib" -type d -name "armeabi*" -o -name "arm64-v8a" -o -name "x86*" 2>/dev/null | sed 's|.*/||')
  if [[ -n "$ABI_LIST" ]]; then
    echo -e "${BLUE}[•] Architectures:${NC} $ABI_LIST"
  fi

  echo ""
}

# Loop through APKs if found
if [[ -n "$APK_LIST" ]]; then
  for APK in $APK_LIST; do
    analyze_apk "$APK"
  done
fi

# Cleanup
rm -rf "$TMP_DIR" "$APK_TMP"
