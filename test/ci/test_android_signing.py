import base64
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tool/ci/prepare_android_signing.py"
spec = importlib.util.spec_from_file_location("android_signing", SCRIPT)
signing = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signing)


class AndroidSigningTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "android").mkdir()
        self.env = {
            "ANDROID_KEYSTORE_BASE64": base64.b64encode(b"fake-keystore").decode(),
            "ANDROID_STORE_PASSWORD": "fake-store-password",
            "ANDROID_KEY_ALIAS": "fake-alias",
            "ANDROID_KEY_PASSWORD": "fake-key-password",
            "RUNNER_TEMP": str(self.root),
        }

    def test_prepares_private_files_and_correct_gradle_settings(self):
        signing.prepare(self.env, self.root)
        key = self.root / "xiaoyu-release.jks"
        properties = self.root / "android/key.properties"
        self.assertEqual(key.read_bytes(), b"fake-keystore")
        self.assertEqual(key.stat().st_mode & 0o777, 0o600)
        self.assertEqual(properties.stat().st_mode & 0o777, 0o600)
        self.assertIn("storeFile=" + str(key), properties.read_text())
        self.assertIn("keyAlias=fake-alias", properties.read_text())

    def test_missing_and_invalid_secrets_do_not_create_files(self):
        for changes in ({"ANDROID_STORE_PASSWORD": ""}, {"ANDROID_KEYSTORE_BASE64": "%%%"}, {"ANDROID_KEY_PASSWORD": "fake\ninvalid"}):
            with self.subTest(changes=changes):
                with self.assertRaises(ValueError):
                    signing.prepare({**self.env, **changes}, self.root)
                self.assertFalse((self.root / "xiaoyu-release.jks").exists())
                self.assertFalse((self.root / "android/key.properties").exists())

    def test_existing_signing_files_are_preserved(self):
        existing = self.root / "android/key.properties"
        existing.write_text("keep-existing-settings")
        with self.assertRaises(ValueError):
            signing.prepare(self.env, self.root)
        self.assertEqual(existing.read_text(), "keep-existing-settings")
        self.assertFalse((self.root / "xiaoyu-release.jks").exists())

    def test_failed_properties_write_removes_the_new_key(self):
        original_open = Path.open
        def fail_properties(path, *args, **kwargs):
            if path.name == "key.properties":
                raise OSError("fake file failure")
            return original_open(path, *args, **kwargs)
        with mock.patch.object(Path, "open", fail_properties):
            with self.assertRaises(OSError):
                signing.prepare(self.env, self.root)
        self.assertFalse((self.root / "xiaoyu-release.jks").exists())

    def test_cli_validation_never_prints_secret_values(self):
        env = {**os.environ, **self.env, "ANDROID_KEYSTORE_BASE64": "fake-invalid-sensitive-value"}
        result = subprocess.run([sys.executable, str(SCRIPT)], cwd=self.root, env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        output = result.stdout + result.stderr
        for name, value in env.items():
            if name.startswith("ANDROID_"):
                self.assertNotIn(value, output)
        self.assertNotIn("Traceback", output)


if __name__ == "__main__":
    unittest.main()
