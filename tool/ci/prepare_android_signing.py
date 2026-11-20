"""Prepare temporary Android signing files from GitHub Actions secrets."""

import base64
import binascii
import os
from pathlib import Path


def prepare(environ, project_root):
    names = (
        "ANDROID_KEYSTORE_BASE64",
        "ANDROID_STORE_PASSWORD",
        "ANDROID_KEY_ALIAS",
        "ANDROID_KEY_PASSWORD",
    )
    missing = [name for name in names if not environ.get(name)]
    if missing:
        raise ValueError("Missing repository secrets: " + ", ".join(missing))
    for name in names[1:]:
        if any(character in environ[name] for character in "\r\n\\"):
            raise ValueError("Unsupported characters in repository secret: " + name)
    try:
        data = base64.b64decode(environ[names[0]], validate=True)
    except (ValueError, binascii.Error) as error:
        raise ValueError("ANDROID_KEYSTORE_BASE64 is not valid base64.") from error
    if not data:
        raise ValueError("ANDROID_KEYSTORE_BASE64 decoded to an empty file.")
    keystore = Path(environ["RUNNER_TEMP"]) / "xiaoyu-release.jks"
    properties = Path(project_root) / "android/key.properties"
    if keystore.exists() or properties.exists():
        raise ValueError("Signing output already exists; refusing to overwrite it.")
    properties_text = (
        "storeFile=" + str(keystore) + "\n"
        "storePassword=" + environ["ANDROID_STORE_PASSWORD"] + "\n"
        "keyAlias=" + environ["ANDROID_KEY_ALIAS"] + "\n"
        "keyPassword=" + environ["ANDROID_KEY_PASSWORD"] + "\n"
    )
    keystore_created = False
    properties_created = False
    try:
        with keystore.open("xb") as output:
            keystore_created = True
            keystore.chmod(0o600)
            output.write(data)
        with properties.open("x") as output:
            properties_created = True
            properties.chmod(0o600)
            output.write(properties_text)
    except OSError:
        if keystore_created:
            keystore.unlink(missing_ok=True)
        if properties_created:
            properties.unlink(missing_ok=True)
        raise


if __name__ == "__main__":
    try:
        prepare(os.environ, Path.cwd())
    except (ValueError, KeyError, OSError) as error:
        # Only validation errors contain field names; OS errors may include paths.
        message = str(error) if isinstance(error, ValueError) else "Cannot prepare signing files."
        raise SystemExit(message) from None
