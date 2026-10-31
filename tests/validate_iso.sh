#!/usr/bin/env bash

set -euo pipefail

if (( $# != 1 )); then
  echo "Usage: $0 PATH-TO-ISO" >&2
  exit 2
fi

readonly iso="$1"
test -s "$iso"
command -v xorriso >/dev/null || {
  echo 'ERROR: xorriso is required to validate the ISO.' >&2
  exit 1
}

listing="$(xorriso -indev "$iso" -find / -type f -exec echo 2>/dev/null)"
for required in \
  /LiveOS/squashfs.img \
  /images/pxeboot/vmlinuz \
  /images/pxeboot/initrd.img; do
  grep -Fxq "$required" <<< "$listing" || {
    echo "ERROR: ISO is missing $required" >&2
    exit 1
  }
done

xorriso -indev "$iso" -report_el_torito plain 2>&1 \
  | grep -Eq 'El Torito|UEFI|BIOS'

echo "ISO structure validation passed: $iso"
