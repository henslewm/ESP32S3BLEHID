"""PlatformIO pre-script: inject FIRMWARE_BUILD_ID from build metadata.

ID = <git short sha>[-dirty]-pio-<env>, so every serial capture names the source
state, toolchain and environment that produced the running artifact. Falls back
to "nogit-pio-<env>" outside a Git checkout.
"""
import subprocess

Import("env")  # noqa: F821 - provided by PlatformIO/SCons


def _git(*args):
    return subprocess.run(["git", *args], cwd=env.subst("$PROJECT_DIR"),  # noqa: F821
                          capture_output=True, text=True, check=True).stdout.strip()


try:
    sha = _git("rev-parse", "--short=10", "HEAD")
    dirty = "-dirty" if _git("status", "--porcelain", "--untracked-files=no") else ""
    source = sha + dirty
except (OSError, subprocess.CalledProcessError):
    source = "nogit"

build_id = f"{source}-pio-{env['PIOENV']}"  # noqa: F821
env.Append(CPPDEFINES=[("FIRMWARE_BUILD_ID", env.StringifyMacro(build_id))])  # noqa: F821
print(f"FIRMWARE_BUILD_ID={build_id}")
