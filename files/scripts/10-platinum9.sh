#!/bin/bash

set -xeuo pipefail

readonly PLATINUM9_COMMIT="f0b7214e00a72ca8c0b71a949f1268db90dc216a"
readonly PLATINUM9_SHA256="cb1f4647d00e81c429600404193fc2c7f2d58a8c963ecbbcff63f43848f31303"
readonly PLATINUM9_ARCHIVE="/tmp/Platinum9.tar.gz"
readonly PLATINUM9_SOURCE="/tmp/Platinum9"

curl --fail --location --retry 3 \
  --output "$PLATINUM9_ARCHIVE" \
  "https://github.com/timnetworks/Platinum9/archive/${PLATINUM9_COMMIT}.tar.gz"
echo "${PLATINUM9_SHA256}  ${PLATINUM9_ARCHIVE}" | sha256sum --check --strict
install -d /usr/share/blue9/build
printf 'Platinum9 %s sha256:%s\n' "$PLATINUM9_COMMIT" "$PLATINUM9_SHA256" \
  >> /usr/share/blue9/build/source-revisions.txt
rm -rf -- "$PLATINUM9_SOURCE"
mkdir -p -- "$PLATINUM9_SOURCE"
tar --extract --gzip --file "$PLATINUM9_ARCHIVE" \
  --directory "$PLATINUM9_SOURCE" --strip-components=1
cd "$PLATINUM9_SOURCE"

mv NineIcons /usr/share/icons
mv Charcoal.ttf MONACO.TTF /usr/share/fonts

mv OS9-wallpaper /usr/share/backgrounds/Platinum9

# Greeter background
montage /usr/share/backgrounds/Platinum9/Finder/OS9_Default.png -tile 10x10 -geometry +0+0 /usr/share/backgrounds/Platinum9/greeter.png

# Install the original System8 assets used by the LUKS-capable Blue9 theme.
cd boot
unzip System8-master.zip
mv System8-master/System8 /usr/share/plymouth/themes

update-mime-database /usr/share/mime
gdk-pixbuf-query-loaders-64 --update-cache
#gtk-update-icon-cache --force --ignore-theme-index /usr/share/icons/NineIcons

# Panel config
cd /usr/share/winblues/chezmoi/dot_local/share/xfce-panel-profile
tar cjf /usr/share/xfce4-panel-profiles/layouts/blue9.tar.bz2 config.txt

rm -rf -- "$PLATINUM9_SOURCE" "$PLATINUM9_ARCHIVE"
