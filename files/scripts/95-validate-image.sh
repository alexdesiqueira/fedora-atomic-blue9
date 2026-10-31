#!/usr/bin/env bash

set -euo pipefail

readonly THEME_DIR=/usr/share/plymouth/themes/System8-LUKS

test "$(systemctl get-default)" = graphical.target
systemctl is-enabled --quiet lightdm.service
systemctl is-enabled --quiet NetworkManager.service
test "$(plymouth-set-default-theme)" = System8-LUKS
test -s "$THEME_DIR/System8-LUKS.plymouth"
test -s "$THEME_DIR/System8.script"
grep -Fq 'Plymouth.SetDisplayPasswordFunction' "$THEME_DIR/System8.script"

shopt -s nullglob
initramfs_images=(/usr/lib/modules/*/initramfs.img)
if (( ${#initramfs_images[@]} == 0 )); then
  echo 'ERROR: no generated initramfs image found under /usr/lib/modules' >&2
  exit 1
fi

for initramfs in "${initramfs_images[@]}"; do
  listing="$(lsinitrd "$initramfs")"
  grep -Fq 'System8-LUKS.plymouth' <<< "$listing"
  grep -Fq 'System8-LUKS/System8.script' <<< "$listing"
done

echo 'Image validation passed: graphical services and System8-LUKS initramfs are present.'
