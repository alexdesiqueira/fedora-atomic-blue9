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
