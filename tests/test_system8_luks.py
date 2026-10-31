"""Static, isolated assembly checks; no actual Plymouth daemon required."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXT = ROOT / "files/system/usr/share/blue9/plymouth/System8-LUKS.append.script"
BUILDER = ROOT / "files/scripts/12-system8-luks.sh"


class ThemeOverlayTests(unittest.TestCase):
    def test_expected_callbacks_present(self):
        ext = EXT.read_text(encoding="utf-8")
        for name in ["SetDisplayPasswordFunction", "SetDisplayQuestionFunction", "SetDisplayNormalFunction", "SetMessageFunction"]:
            self.assertIn("Plymouth." + name + "(", ext)
        self.assertIn("bullet_count", ext)
        self.assertNotIn("Plymouth.SetKeyboardInputFunction", ext)
        self.assertNotIn('"Input: [ " + text_entered', ext)
        self.assertIn('Input: [ hidden ]', ext)
        self.assertIn("dialog_setup()", ext)
        self.assertIn("display_normal_callback()", ext)

    def test_builder_works_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            themes = root / "themes"
            src = themes / "System8"
            src.mkdir(parents=True)
            (src / "System8.script").write_text("# Upstream System8 attribution preserved\nfun dialog_setup(){}\n")
            for png in ("checker.png", "picasso.png", "shutdown.png", "message.png", "os8_boot.png", "os8_swatch.png"):
                (src / png).write_bytes(b"test-asset")
            (src / "icons").mkdir()
            (src / "icons/8help.png").write_bytes(b"test-icon")
            (src / "System8.plymouth").write_text("old descriptor")
            env = os.environ.copy()
            env.update(PLYMOUTH_THEMES_DIR=str(themes), SYSTEM8_LUKS_EXTENSION=str(EXT), SYSTEM8_LUKS_SKIP_ACTIVATE="1", SYSTEM8_LUKS_SKIP_BRANDING="1")
            for _ in range(2):
                subprocess.run(["bash", str(BUILDER)], env=env, check=True, capture_output=True)
            new = themes / "System8-LUKS"
            text = (new / "System8.script").read_text()
            self.assertEqual(text.count("System8 LUKS / question-prompt extension"), 1)
            self.assertIn("Upstream System8 attribution preserved", text)
            self.assertIn("SetDisplayPasswordFunction", text)
            self.assertTrue((new / "icons/8help.png").exists())
            self.assertFalse((new / "System8.plymouth").exists())
            self.assertIn("ImageDir=/usr/share/plymouth/themes/System8-LUKS", (new / "System8-LUKS.plymouth").read_text())
            self.assertEqual((src / "System8.script").read_text(), "# Upstream System8 attribution preserved\nfun dialog_setup(){}\n")

    def test_branding_overlays_and_upstream_preservation(self):
        try:
            from PIL import Image
        except ImportError:
            self.skipTest('Pillow unavailable')
        if not (shutil.which('magick') or (shutil.which('convert') and shutil.which('identify'))):
            self.skipTest('ImageMagick unavailable')

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src = root / 'themes/System8'
            src.mkdir(parents=True)
            (src / 'System8.script').write_text('# Attribution preserved\nfun dialog_setup(){}\n')
            sizes = {'os8_boot.png': (422, 322), 'picasso.png': (448, 126),
                     'shutdown.png': (448, 126)}
            for name, size in sizes.items():
                Image.new('RGB', size, '#00ff00').save(src / name)
            for name in ('checker.png', 'message.png', 'os8_swatch.png'):
                Image.new('RGB', (16,16), '#00ff00').save(src / name)
            (src / 'icons').mkdir()
            (src / 'icons/8help.png').write_bytes(b'placeholder')

            env = os.environ.copy()
            env.update(PLYMOUTH_THEMES_DIR=str(root / 'themes'),
                       SYSTEM8_LUKS_EXTENSION=str(EXT),
                       SYSTEM8_LUKS_BRANDING_DIR=str(ROOT / 'files/system/usr/share/blue9/plymouth/branding'),
                       SYSTEM8_LUKS_SKIP_ACTIVATE='1')
            for _ in range(2):
                subprocess.run(['bash', str(BUILDER)], env=env, check=True, capture_output=True)
            dst = root / 'themes/System8-LUKS'
            checks = [('os8_boot.png', (100,166)), ('picasso.png',(147,28)),
                      ('shutdown.png', (78,16))]
            for name, opaque_patch_xy in checks:
                upstream = Image.open(src / name).convert('RGB')
                modified = Image.open(dst / name).convert('RGB')
                self.assertEqual(upstream.getpixel(opaque_patch_xy), (0,255,0))
                self.assertEqual(modified.getpixel(opaque_patch_xy), (255,255,255))
                self.assertEqual(modified.getpixel((5,5)), (0,255,0))
                self.assertEqual(upstream.size, modified.size)
            self.assertIn('Name=Blue 9 (System8-LUKS)', (dst / 'System8-LUKS.plymouth').read_text())



if __name__ == "__main__":
    unittest.main()
