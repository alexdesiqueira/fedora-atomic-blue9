import os
from pathlib import Path
import subprocess
import tempfile
import unittest


VALIDATOR = Path(__file__).with_name("validate_iso.sh")


class IsoValidationTests(unittest.TestCase):
    def validate(self, listing):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            iso = root / "test.iso"
            iso.write_text("not empty")
            xorriso = root / "xorriso"
            xorriso.write_text(
                '#!/usr/bin/env bash\n'
                'if [[ "$*" == *-report_el_torito* ]]; then\n'
                '  echo "El Torito boot image"\n'
                'else\n'
                '  printf "%s\\n" "$ISO_LISTING"\n'
                'fi\n'
            )
            xorriso.chmod(0o755)
            env = os.environ | {"PATH": f"{root}:{os.environ['PATH']}",
                                "ISO_LISTING": listing}
            return subprocess.run(["bash", str(VALIDATOR), str(iso)],
                                  env=env, capture_output=True, text=True)

    def test_accepts_xorriso_quoted_paths(self):
        result = self.validate("\n".join([
            "'/LiveOS/squashfs.img'",
            "'/images/pxeboot/vmlinuz'",
            "'/images/pxeboot/initrd.img'",
        ]))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_missing_file(self):
        result = self.validate("'/LiveOS/squashfs.img'")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ISO is missing /images/pxeboot/vmlinuz", result.stderr)


if __name__ == "__main__":
    unittest.main()
