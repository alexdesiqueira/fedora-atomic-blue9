#!/usr/bin/env bash

set -ouex pipefail

# Apply the image's user-service presets after installing the desktop.
systemctl --global preset-all

# Make the installed desktop and display manager the default boot target.
systemctl set-default graphical.target

# Fail the image build instead of publishing another console-only image.
test "$(systemctl get-default)" = "graphical.target"
systemctl is-enabled --quiet lightdm.service
systemctl is-enabled --quiet NetworkManager.service

# Titanoboa reads EFI binaries from /boot/efi, while bootc stores the RPM
# payloads under /usr/lib/efi. Assemble the vendor and fallback directories.
shopt -s nullglob
efi_payloads=(/usr/lib/efi/shim/*/EFI /usr/lib/efi/grub2/*/EFI)
if (( ${#efi_payloads[@]} != 2 )); then
  echo 'ERROR: expected one shim and one GRUB EFI payload' >&2
  exit 1
fi
install -d /boot/efi/EFI
for payload in "${efi_payloads[@]}"; do
  cp -a "$payload"/. /boot/efi/EFI/
done

# Preserve enough build information to audit a published image without
# freezing Fedora package updates.
install -d -m 0755 /usr/share/blue9/build
sort -u -o /usr/share/blue9/build/source-revisions.txt \
  /usr/share/blue9/build/source-revisions.txt
rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' \
  | sort > /usr/share/blue9/build/rpm-packages.txt
chmod 0644 /usr/share/blue9/build/source-revisions.txt \
  /usr/share/blue9/build/rpm-packages.txt
