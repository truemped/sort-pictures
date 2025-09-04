#!/bin/bash

# Setup script for Bats testing framework
# This script installs Bats and its helper libraries

set -euo pipefail

BATS_VERSION="1.11.0"
BATS_SUPPORT_VERSION="0.3.0"
BATS_ASSERT_VERSION="2.1.0"
BATS_FILE_VERSION="0.4.0"

# Create bats directory
mkdir -p tests/bats

# Download and install Bats core
echo "Installing Bats ${BATS_VERSION}..."
curl -sSL "https://github.com/bats-core/bats-core/archive/v${BATS_VERSION}.tar.gz" | \
    tar -xz -C tests/bats --strip-components=1

# Download and install bats-support
echo "Installing bats-support ${BATS_SUPPORT_VERSION}..."
mkdir -p tests/bats/test_helper/bats-support
curl -sSL "https://github.com/bats-core/bats-support/archive/v${BATS_SUPPORT_VERSION}.tar.gz" | \
    tar -xz -C tests/bats/test_helper/bats-support --strip-components=1

# Download and install bats-assert
echo "Installing bats-assert ${BATS_ASSERT_VERSION}..."
mkdir -p tests/bats/test_helper/bats-assert
curl -sSL "https://github.com/bats-core/bats-assert/archive/v${BATS_ASSERT_VERSION}.tar.gz" | \
    tar -xz -C tests/bats/test_helper/bats-assert --strip-components=1

# Download and install bats-file
echo "Installing bats-file ${BATS_FILE_VERSION}..."
mkdir -p tests/bats/test_helper/bats-file
curl -sSL "https://github.com/bats-core/bats-file/archive/v${BATS_FILE_VERSION}.tar.gz" | \
    tar -xz -C tests/bats/test_helper/bats-file --strip-components=1

echo "Bats installation completed!"
echo "Run tests with: ./tests/bats/bin/bats tests/*.bats"
