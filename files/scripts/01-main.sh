#!/bin/bash

set -exuo pipefail

readonly APPMENU_COMMIT="637cfdb7b317e4f6b98d02324cd4a447856109bd"
readonly APPMENU_SHA256="cc51636d553a1753cf622fe0490dbce4a9a4f05d2b4f398811dfc4e60c4e686f"
readonly APPMENU_ARCHIVE="/tmp/vala-panel-appmenu.tar.gz"
readonly APPMENU_SOURCE="/tmp/vala-panel-appmenu"

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
  wayland-protocols-devel \
  git

# Download a reviewed source revision and verify it before building.
curl --fail --location --retry 3 \
  --output "$APPMENU_ARCHIVE" \
  "https://github.com/rilian-la-te/vala-panel-appmenu/archive/${APPMENU_COMMIT}.tar.gz"
echo "${APPMENU_SHA256}  ${APPMENU_ARCHIVE}" | sha256sum --check --strict
install -d /usr/share/blue9/build
printf 'vala-panel-appmenu %s sha256:%s\n' "$APPMENU_COMMIT" "$APPMENU_SHA256" \
  >> /usr/share/blue9/build/source-revisions.txt
rm -rf -- "$APPMENU_SOURCE"
mkdir -p -- "$APPMENU_SOURCE"
tar --extract --gzip --file "$APPMENU_ARCHIVE" \
  --directory "$APPMENU_SOURCE" --strip-components=1
cd "$APPMENU_SOURCE"

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
rm -rf -- "$APPMENU_SOURCE" "$APPMENU_ARCHIVE"

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
  wayland-protocols-devel
