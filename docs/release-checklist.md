# Blue9 release validation checklist

Automated tests validate the pinned source archives, theme assembly, image
services, generated initramfs, image signature, and ISO structure. A graphical
encrypted installation still needs a disposable VM because keyboard interaction
with Plymouth and the installer is not reliably represented by static checks.

For each release candidate:

1. Download the ISO and matching `-CHECKSUM` file from the same immutable
   `releases/<digest-prefix>/` directory.
2. Run `sha256sum --check <name>.iso-CHECKSUM`.
3. Create a throwaway UEFI VM with at least 4 GiB RAM, a 40 GiB disk, and 3D
   acceleration disabled for the first test.
4. Boot the live ISO and confirm the graphical desktop, LightDM, networking,
   keyboard, mouse, and installer start normally.
5. Install with LUKS encryption enabled and a temporary test passphrase.
6. Remove the ISO and reboot. Confirm the System8-LUKS prompt appears.
7. Test an incorrect passphrase followed by a correct retry, Backspace editing,
   and an empty submission. Confirm entered characters are never displayed.
8. Confirm LightDM starts after unlock and NetworkManager reaches an operational
   state.
9. Power-cycle the VM and repeat one successful unlock.
10. Record the ISO digest prefix, VM firmware, result, and any screenshots in
    the release notes. Do not promote `latest` if any check fails.

Use Escape during Plymouth startup to obtain textual diagnostics. Keep the
previous known-good image and ISO available for rollback.
