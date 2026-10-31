#!/bin/bash

set -xeuo pipefail

readonly MACOS9_COMMIT="ca8a5d2a3fb1976cf904133574a3d0022ac2cf71"
readonly MACOS9_SHA256="ea8b5f6c171a70ad87cb6df8adb3ed891dd662c453d9925ac0ddc2d355a48aab"
readonly MACOS9_ARCHIVE="/tmp/Mac-OS-9.tar.gz"
readonly MACOS9_SOURCE="/tmp/Mac-OS-9"

curl --fail --location --retry 3 \
  --output "$MACOS9_ARCHIVE" \
  "https://github.com/B00merang-Project/Mac-OS-9/archive/${MACOS9_COMMIT}.tar.gz"
echo "${MACOS9_SHA256}  ${MACOS9_ARCHIVE}" | sha256sum --check --strict
install -d /usr/share/blue9/build
printf 'Mac-OS-9 %s sha256:%s\n' "$MACOS9_COMMIT" "$MACOS9_SHA256" \
  >> /usr/share/blue9/build/source-revisions.txt
rm -rf -- "$MACOS9_SOURCE"
mkdir -p -- "$MACOS9_SOURCE"
tar --extract --gzip --file "$MACOS9_ARCHIVE" \
  --directory "$MACOS9_SOURCE" --strip-components=1
rm -rf /usr/share/themes/Mac-OS-9
mv "$MACOS9_SOURCE" /usr/share/themes/Mac-OS-9
rm -f -- "$MACOS9_ARCHIVE"
