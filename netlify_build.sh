#!/usr/bin/env bash
set -euo pipefail

SDK_DIR=".flutter-sdk"
VER="${FLUTTER_VERSION:-3.24.3-stable}"
TARBALL="flutter_linux_${VER}.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${TARBALL}"

if [ ! -d "${SDK_DIR}/flutter" ]; then
  mkdir -p "${SDK_DIR}"
  echo "Downloading Flutter ${VER} ..."
  curl -L "${URL}" -o flutter.tar.xz
  tar -xJf flutter.tar.xz -C "${SDK_DIR}"
  rm -f flutter.tar.xz
fi

export PATH="${PWD}/${SDK_DIR}/flutter/bin:${PATH}"
export PUB_CACHE="${HOME}/.pub-cache"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release
