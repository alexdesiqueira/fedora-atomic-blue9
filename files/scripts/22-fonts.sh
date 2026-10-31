#!/usr/bin/env bash

set -oeux pipefail

readonly CASCADIA_VERSION="3.5.0"
readonly CASCADIA_SHA256="b31fafd248c001ffa4c7149ced737bf5e3aea0e381ee44755ad32919429a5af2"
readonly CASCADIA_ARCHIVE="/tmp/CascadiaMono.zip"
readonly CASCADIA_SOURCE="/tmp/CascadiaMono"

curl --fail --location --retry 3 \
  --output "$CASCADIA_ARCHIVE" \
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v${CASCADIA_VERSION}/CascadiaMono.zip"
echo "${CASCADIA_SHA256}  ${CASCADIA_ARCHIVE}" | sha256sum --check --strict
install -d /usr/share/blue9/build
printf 'CascadiaMono v%s sha256:%s\n' "$CASCADIA_VERSION" "$CASCADIA_SHA256" \
  >> /usr/share/blue9/build/source-revisions.txt
rm -rf -- "$CASCADIA_SOURCE"
mkdir -p -- "$CASCADIA_SOURCE"
unzip -q "$CASCADIA_ARCHIVE" -d "$CASCADIA_SOURCE"
install -Dm0644 "$CASCADIA_SOURCE/CaskaydiaMonoNerdFont-Regular.ttf" \
  /usr/share/fonts/CaskaydiaMonoNerdFont-Regular.ttf
rm -rf -- "$CASCADIA_SOURCE" "$CASCADIA_ARCHIVE"

fc-cache -fv
