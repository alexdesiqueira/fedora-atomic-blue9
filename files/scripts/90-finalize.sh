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

# Preserve enough build information to audit a published image without
# freezing Fedora package updates.
install -d -m 0755 /usr/share/blue9/build
sort -u -o /usr/share/blue9/build/source-revisions.txt \
  /usr/share/blue9/build/source-revisions.txt
rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' \
  | sort > /usr/share/blue9/build/rpm-packages.txt
chmod 0644 /usr/share/blue9/build/source-revisions.txt \
  /usr/share/blue9/build/rpm-packages.txt
