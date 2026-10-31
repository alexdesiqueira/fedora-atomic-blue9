# Blue 9 Plymouth — classic System8 boot graphics with LUKS support and Blue 9 branding

This is an **overlay for the System8 Plymouth theme used by `winblues/blue9`**, not a replacement bootloader, disk encryption manager, or an independently bundled copy of the theme's graphics.

**Verified upstream path**: Blue9 `files/scripts/10-platinum9.sh` downloads `timnetworks/Platinum9`, unpacks `boot/System8-master.zip`, installs its `System8` directory, and chooses `System8` via `plymouth-set-default-theme`. The theme originated at `vladkorotnev/System8`, where handling for password/question prompts is listed as unfinished.

This overlay creates a **separate `System8-LUKS`** theme by copying the existing `System8` assets and appending new Plymouth script callbacks. **Original `System8` remains untouched and can be selected again.**

## Branding: Mac OS → Blue 9

The original System8 artwork has wording baked into three PNGs. This package
adds *transparent overlay graphics* that alter **only the derived System8-LUKS
copy** when `12-system8-luks.sh` runs:

- `os8_boot.png`: classic **Blue 9** logo instead of “Mac OS”. The original
  blue-and-black serif aesthetic is approximated, not an exact copy of Apple's typography.
- `picasso.png`: **Welcome to Blue 9.** instead of “Welcome to Macintosh.”
- `shutdown.png`: **It is now safe to switch off your Blue 9.** instead of the Macintosh text.

Original checkerboard, boot icon, extension icons, progress bar, and message
window are preserved. A change in upstream PNG dimensions fails with an explicit
message rather than silently drawing in the wrong location. No font files are
redistributed; text is rasterized into the three tiny overlay PNGs.

For an unbranded System8-LUKS build, set `SYSTEM8_LUKS_SKIP_BRANDING=1` in the
script environment. Otherwise, the script requires ImageMagick (`magick` or
`convert` + `identify`), as already used by the upstream Blue9 build.

## What changes

- Maintains original checkerboard, classic Mac startup progress and extension icons.
- Uses original `message.png` for both disk-passphrase and ordinary question dialogs.
- Handles Plymouth `SetDisplayPasswordFunction(prompt, bullet_count)` with asterisks only; never displays/logs plaintext disk passwords.
- Updates the masked count as keys are typed or erased (Backspace).
- Handles `SetDisplayQuestionFunction(prompt, entered_text)` for questions, but deliberately **hides question answers** as a privacy/safety fallback.
- Handles normal-display transitions and restores animation/icons when the prompt ends.
- Routes error/status messages to the dialog hint line while a prompt is active.
- Caps the on-screen mask length, and falls back to short prompts when provided text is too wide.

## Apply to your Blue9 / BlueBuild fork

1. Extract this package, then merge its `files/` directory with the `files/` directory of your Blue9 fork. This adds the builder script, LUKS extension and three branding overlays; it does not change `10-platinum9.sh`.
2. Edit your existing `recipes/recipe.yml` (or your fork's corresponding BlueBuild recipe): in its `type: script` module, insert `12-system8-luks.sh` **after** `10-platinum9.sh`.
3. Keep `plymouth-plugin-script` installed and keep the existing `type: initramfs` module **after** the script module; both are already present upstream. See `docs/recipe-addition.yml` for a reference snippet (do not replace the entire recipe with the snippet).
4. Build your image in BlueBuild as you normally do. The script copies `System8` to `System8-LUKS`, appends the extension, composites the Blue 9 lettering into copied PNGs, sets the new default and lets the subsequent initramfs module embed it.
5. Check the resulting image/ISO with a *throwaway LUKS-encrypted virtual machine* before installing on your actual workstation. Test correct password, wrong password then retry, Backspace, empty password, and a power-cycle/recovery boot.

**Important:** Theme code alone does **not** enable or alter full-disk encryption. Your installed operating system must already have a working systemd/dracut/cryptsetup LUKS prompt through Plymouth. For Fedora's graphical early boot, ensure the effective kernel command line has `rhgb quiet` (and does not disable Plymouth) and your initramfs contains `plymouth-plugin-script`, the theme, and required keyboard/crypt modules. If theme boot fails, use Escape to show textual boot feedback, or an alternate boot entry. Do not remove the stock fallback/recovery entry.

### Example BlueBuild recipe edit

From:

```yaml
  - type: script
    scripts:
      - 10-platinum9.sh
      - 11-b00merang.sh
      # ...
```

To:

```yaml
  - type: script
    scripts:
      - 10-platinum9.sh
      - 11-b00merang.sh
      - 12-system8-luks.sh
      # ...
```

The upstream script module has other scripts; retain them all. The overlay must appear after the upstream System8 installation, before `type: initramfs`.

## Apply on a conventional Fedora installation (not Atomic)

If the original `System8` theme is already in `/usr/share/plymouth/themes/System8`, from the extracted package directory:

```bash
sudo install -Dm644 files/system/usr/share/blue9/plymouth/System8-LUKS.append.script \
  /usr/share/blue9/plymouth/System8-LUKS.append.script
sudo install -d /usr/share/blue9/plymouth/branding
sudo install -m644 files/system/usr/share/blue9/plymouth/branding/*.png \
  /usr/share/blue9/plymouth/branding/
sudo bash files/scripts/12-system8-luks.sh
sudo dracut --force
```

This intentionally does **not** modify the host OSTree deployment for Fedora Atomic systems. Use the **BlueBuild route** for those systems.

### Roll back to System8

In a build recipe: remove the `12-system8-luks.sh` entry and rebuild/deploy your previous image. On conventional Fedora:

```bash
sudo plymouth-set-default-theme System8
sudo dracut --force
```

## Constraints / test status

- All three overlays and the theme assembly have been tested with **synthetic**
  PNGs matching the upstream dimensions; the images have not yet been compared
  pixel-by-pixel against the downloaded Platinum9 archive. In particular, the
  startup/shutdown word replacements are approximations of the original font.

- The extension is static-tested for its callback registration and integration into the existing Blue9 build structure. **It has not been tested with a real Plymouth daemon or with an encrypted boot** in this environment. Do not treat it as production-validated until the test VM passes.
- The new Blue 9 text is pre-rendered into PNG overlays, but the theme retains existing early-boot font availability and keyboard mapping; the theme cannot fix a missing `rd.luks.*` mapping, unavailable early-boot display driver, or incorrect initramfs keymap.
- Existing System8 base graphics are not bundled: they are copied from the theme downloaded by the original Blue9 script. Only the three transparent branding overlays are included.
- The original assets are derived from classic Mac OS graphics and are credited by the System8 author to Apple. The **original script and this adaptation** are licensed under **CC BY-SA 4.0**. Retain the original script's header/credits. Original project: https://github.com/vladkorotnev/System8 ; packaging used by Blue9: https://github.com/winblues/blue9 .

## What is in this package

```text
files/
  system/usr/share/blue9/plymouth/System8-LUKS.append.script
  system/usr/share/blue9/plymouth/branding/
    blue9-boot-overlay.png
    blue9-welcome-overlay.png
    blue9-shutdown-overlay.png
  scripts/12-system8-luks.sh
docs/recipe-addition.yml
tests/test_system8_luks.py
README.md
```

For a fork that still has the original upstream recipe ordering, `docs/blue9-recipe.patch` can add the script line with `git apply docs/blue9-recipe.patch` from the repository root. **Do not apply that patch unless your recipe matches**; otherwise merge the single line manually.
