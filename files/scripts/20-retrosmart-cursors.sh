#!/usr/bin/env bash

set -xeuo pipefail

readonly RETROSMART_COMMIT="768e207ce072945a7eba9caddc71f235b2036281"
readonly RETROSMART_SHA256="c16fbeb70498928f3a3671d3e10595b47f94918f301c033e58895a5b78a7685c"
readonly RETROSMART_ARCHIVE="/tmp/retrosmart-x11-cursors.tar.gz"
readonly RETROSMART_SOURCE="/tmp/retrosmart-x11-cursors"

# Install build dependencies
dnf5 -y install ImageMagick xcursorgen

# Download a reviewed source revision and verify it before building.
curl --fail --location --retry 3 \
  --output "$RETROSMART_ARCHIVE" \
  "https://github.com/mdomlop/retrosmart-x11-cursors/archive/${RETROSMART_COMMIT}.tar.gz"
echo "${RETROSMART_SHA256}  ${RETROSMART_ARCHIVE}" | sha256sum --check --strict
install -d /usr/share/blue9/build
printf 'retrosmart-x11-cursors %s sha256:%s\n' "$RETROSMART_COMMIT" "$RETROSMART_SHA256" \
  >> /usr/share/blue9/build/source-revisions.txt
rm -rf -- "$RETROSMART_SOURCE"
mkdir -p -- "$RETROSMART_SOURCE"
tar --extract --gzip --file "$RETROSMART_ARCHIVE" \
  --directory "$RETROSMART_SOURCE" --strip-components=1
cd "$RETROSMART_SOURCE"

# Build the themes without upstream's optional OCS archive packaging.
make xpmtheme svgtheme
make install PREFIX=/usr

# Clean up
cd /tmp
rm -rf -- "$RETROSMART_SOURCE" "$RETROSMART_ARCHIVE"
