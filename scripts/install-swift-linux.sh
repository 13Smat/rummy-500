#!/bin/sh
set -eu

version=6.4.2
prefix=/opt/swift

if [ -x "$prefix/usr/bin/swift" ] && "$prefix/usr/bin/swift" --version | grep -q "Swift version $version "; then
  echo "Swift $version is already installed"
else
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-13-dev \
    libpython3-dev \
    libsqlite3-0 \
    libstdc++-13-dev \
    libxml2-dev \
    libncurses-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev
  tarball="swift-${version}-RELEASE-ubuntu24.04.tar.gz"
  url="https://download.swift.org/swift-${version}-release/ubuntu2404/swift-${version}-RELEASE/${tarball}"
  curl -fL --retry 3 -o "/tmp/${tarball}" "$url"
  sudo mkdir -p "$prefix"
  sudo tar -xzf "/tmp/${tarball}" -C "$prefix" --strip-components=1
fi

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$prefix/usr/bin" >> "$GITHUB_PATH"
fi

"$prefix/usr/bin/swift" --version
