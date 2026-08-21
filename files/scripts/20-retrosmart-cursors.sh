#!/usr/bin/env bash

set -xeuo pipefail

cd /tmp

# Install build dependencies
dnf5 -y install ImageMagick xcursorgen

# Clone and build retrosmart cursors
git clone --depth 1 https://github.com/mdomlop/retrosmart-x11-cursors.git
cd retrosmart-x11-cursors

# Build and install cursors system-wide
make
make install PREFIX=/usr

# Clean up
cd /tmp
rm -rf retrosmart-x11-cursors
