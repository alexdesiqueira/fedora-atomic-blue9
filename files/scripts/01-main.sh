#!/bin/bash

set -exuo pipefail

# Install build dependencies for vala-panel-appmenu
dnf5 -y install \
  meson \
  vala \
  gcc-c++ \
  gtk3-devel \
  libwnck3-devel \
  xfce4-panel-devel \
  libxfce4ui-devel \
  libxfce4util-devel \
  xfconf-devel \
  gobject-introspection-devel \
  libpeas-devel \
  libdbusmenu-gtk3-devel \
  git

# Clone and build vala-panel-appmenu
cd /tmp
git clone --depth 1 https://github.com/rilian-la-te/vala-panel-appmenu.git
cd vala-panel-appmenu

meson setup builddir \
  --prefix=/usr \
  -Dxfce=enabled \
  -Dmate=disabled \
  -Dvalapanel=disabled \
  -Dbudgie=disabled \
  -Djayatana=disabled \
  -Dappmenu-gtk-module=enabled

ninja -C builddir
ninja -C builddir install

# Clean up
cd /tmp
rm -rf vala-panel-appmenu

# Remove build dependencies
dnf5 -y remove \
  meson \
  vala \
  gcc-c++ \
  gtk3-devel \
  libwnck3-devel \
  xfce4-panel-devel \
  libxfce4ui-devel \
  libxfce4util-devel \
  xfconf-devel \
  gobject-introspection-devel \
  libpeas-devel \
  libdbusmenu-gtk3-devel \
  git
