#!/usr/bin/env bash
# Run *after* Blue9's 10-platinum9.sh and *before* the BlueBuild initramfs module.
set -euo pipefail

THEMES_DIR="${PLYMOUTH_THEMES_DIR:-/usr/share/plymouth/themes}"
SOURCE="${SYSTEM8_SOURCE_THEME:-${THEMES_DIR}/System8}"
DEST="${SYSTEM8_LUKS_DEST:-${THEMES_DIR}/System8-LUKS}"
EXTENSION="${SYSTEM8_LUKS_EXTENSION:-/usr/share/blue9/plymouth/System8-LUKS.append.script}"
BRANDING_DIR="${SYSTEM8_LUKS_BRANDING_DIR:-/usr/share/blue9/plymouth/branding}"

if [[ ! -f "$SOURCE/System8.script" ]]; then
  echo "ERROR: Original System8 theme missing: $SOURCE" >&2
  echo "Blue9's 10-platinum9.sh must run first (or install vladkorotnev/System8)." >&2
  exit 1
fi
if [[ ! -f "$EXTENSION" ]]; then
  echo "ERROR: Missing System8 LUKS extension: $EXTENSION" >&2
  exit 1
fi
if [[ "$SOURCE" == "$DEST" || "${DEST##*/}" != "System8-LUKS" ]]; then
  echo "ERROR: Refusing to overwrite original theme or non-System8-LUKS target." >&2
  exit 1
fi

# Keep original assets, including graphics (not redistributed in this patch).
for file in checker.png picasso.png shutdown.png message.png os8_boot.png os8_swatch.png; do
  if [[ ! -f "$SOURCE/$file" ]]; then
    echo "ERROR: Required original System8 asset is missing: $SOURCE/$file" >&2
    exit 1
  fi
done
if [[ ! -d "$SOURCE/icons" ]]; then
  echo "ERROR: Original System8 icons directory is missing." >&2
  exit 1
fi

# Idempotent: rebuild the derived theme from the pristine original each time.
rm -rf -- "$DEST"
mkdir -p -- "$DEST"
cp -a -- "$SOURCE/." "$DEST/"
cat -- "$EXTENSION" >> "$DEST/System8.script"

# The original Mac OS wording lives in PNGs, not in System8.script.  Apply
# small opaque-on-transparent patches ONLY to the copied theme, leaving the
# upstream System8 directory untouched. Blue9 already uses ImageMagick.
if [[ "${SYSTEM8_LUKS_SKIP_BRANDING:-0}" != "1" ]]; then
  if command -v magick >/dev/null 2>&1; then
    image_compose() { magick "$@"; }
    image_dimensions() { magick identify -format '%wx%h' "$1"; }
  elif command -v convert >/dev/null 2>&1 && command -v identify >/dev/null 2>&1; then
    image_compose() { convert "$@"; }
    image_dimensions() { identify -format '%wx%h' "$1"; }
  else
    echo 'ERROR: ImageMagick (magick, or convert + identify) is required to brand the System8 PNGs.' >&2
    exit 1
  fi

  brand_png() {
    local basename="$1" overlay="$2" expected="$3" actual temp
    if [[ ! -f "$overlay" ]]; then
      echo "ERROR: Missing branding overlay: $overlay" >&2
      exit 1
    fi
    actual="$(image_dimensions "$DEST/$basename")"
    if [[ "$actual" != "$expected" ]]; then
      echo "ERROR: $basename is $actual, expected $expected; refusing to draw on an unfamiliar layout." >&2
      exit 1
    fi
    temp="$DEST/${basename%.png}.blue9.tmp.png"
    image_compose "$DEST/$basename" "$overlay" -compose over -composite "$temp"
    mv -f -- "$temp" "$DEST/$basename"
  }

  brand_png 'os8_boot.png' "$BRANDING_DIR/blue9-boot-overlay.png" '422x322'
  brand_png 'picasso.png' "$BRANDING_DIR/blue9-welcome-overlay.png" '448x126'
  brand_png 'shutdown.png' "$BRANDING_DIR/blue9-shutdown-overlay.png" '448x126'
fi

cat > "$DEST/System8-LUKS.plymouth" <<'EOF'
[Plymouth Theme]
Name=Blue 9 (System8-LUKS)
Description=Classic Mac-style Blue 9 startup with Plymouth LUKS password and question prompts
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/System8-LUKS
ScriptFile=/usr/share/plymouth/themes/System8-LUKS/System8.script
EOF

# Do not keep an old .plymouth descriptor pointing to /System8 in this copy.
rm -f -- "$DEST/System8.plymouth"
chmod 0644 "$DEST/System8.script" "$DEST/System8-LUKS.plymouth"

if [[ "${SYSTEM8_LUKS_SKIP_ACTIVATE:-0}" != "1" ]]; then
  command -v plymouth-set-default-theme >/dev/null || {
    echo 'ERROR: plymouth-set-default-theme is unavailable (install plymouth).' >&2
    exit 1
  }
  plymouth-set-default-theme System8-LUKS
fi

echo 'System8-LUKS theme assembled (selected unless SYSTEM8_LUKS_SKIP_ACTIVATE=1).'
echo 'For BlueBuild: keep its initramfs module AFTER this script to embed the theme.'
