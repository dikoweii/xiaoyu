import importlib.util
import plistlib
import stat
import tempfile
import unittest
import zipfile
from pathlib import Path


spec = importlib.util.spec_from_file_location(
    "unsigned_ipa", Path(__file__).resolve().parents[2] / "tool/ci/package_unsigned_ipa.py"
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class UnsignedIpaTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / "Runner.app"
        self.app.mkdir()
        self.write_info("iPhoneOS")
        binary = self.app / "Runner"
        binary.write_bytes(b"offline fake executable")
        binary.chmod(0o755)
        self.output = self.root / "unsigned.ipa"

    def write_info(self, platform):
        (self.app / "Info.plist").write_bytes(plistlib.dumps({
            "CFBundleSupportedPlatforms": [platform],
            "CFBundleExecutable": "Runner",
        }))

    def test_payload_preserves_executable_mode_and_framework_symlink(self):
        framework = self.app / "Frameworks/Fake.framework"
        framework.mkdir(parents=True)
        (framework / "Actual").write_bytes(b"fake framework")
        (framework / "Fake").symlink_to("Actual")
        module.package(self.app, self.output)
        with zipfile.ZipFile(self.output) as archive:
            self.assertIsNone(archive.testzip())
            self.assertTrue(all(name.startswith("Payload/") for name in archive.namelist()))
            executable = archive.getinfo("Payload/Runner.app/Runner")
            self.assertTrue((executable.external_attr >> 16) & stat.S_IXUSR)
            link = archive.getinfo("Payload/Runner.app/Frameworks/Fake.framework/Fake")
            self.assertTrue(stat.S_ISLNK(link.external_attr >> 16))
            self.assertEqual(archive.read(link), b"Actual")

    def test_rejects_simulator_and_missing_executable(self):
        self.write_info("iPhoneSimulator")
        with self.assertRaises(ValueError):
            module.package(self.app, self.output)
        self.write_info("iPhoneOS")
        (self.app / "Runner").unlink()
        with self.assertRaises(ValueError):
            module.package(self.app, self.output)
        self.assertFalse(self.output.exists())

    def test_rejects_signed_or_provisioned_bundle(self):
        for name in ["_CodeSignature", "embedded.mobileprovision"]:
            with self.subTest(name=name):
                marker = self.app / name
                marker.write_bytes(b"fake signing marker")
                with self.assertRaises(ValueError):
                    module.package(self.app, self.output)
                marker.unlink()
        self.assertFalse(self.output.exists())

    def test_preserves_existing_output(self):
        self.output.write_bytes(b"existing artifact")
        with self.assertRaises(ValueError):
            module.package(self.app, self.output)
        self.assertEqual(self.output.read_bytes(), b"existing artifact")


if __name__ == "__main__":
    unittest.main()
