from __future__ import annotations

import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("validate_bootstrap_ci", ROOT / "scripts" / "validate_bootstrap_ci.py")
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MODULE)


class ValidationTests(unittest.TestCase):
    def test_template_validates(self) -> None:
        result = subprocess.run(
            [sys.executable, str(ROOT / "scripts/validate_project.py")],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stdout + result.stderr)


class BootstrapCiValidationTests(unittest.TestCase):
    def test_require_active_only_for_push_to_main(self) -> None:
        self.assertTrue(MODULE.require_active("push", "refs/heads/main"))
        self.assertFalse(MODULE.require_active("pull_request", "refs/heads/main"))
        self.assertFalse(MODULE.require_active("push", "refs/heads/feature"))

    @mock.patch.object(MODULE.subprocess, "run")
    def test_main_push_adds_require_active(self, run: mock.Mock) -> None:
        run.return_value = mock.Mock(returncode=0)

        code = MODULE.main(["--event-name", "push", "--ref", "refs/heads/main"])

        self.assertEqual(code, 0)
        run.assert_called_once_with(
            [sys.executable, str(ROOT / "scripts" / "validate_bootstrap.py"), "config/bootstrap.json", "--require-active"],
            check=False,
        )

    @mock.patch.object(MODULE.subprocess, "run")
    def test_pull_request_uses_structural_validation(self, run: mock.Mock) -> None:
        run.return_value = mock.Mock(returncode=0)

        code = MODULE.main(["--event-name", "pull_request", "--ref", "refs/pull/14/merge"])

        self.assertEqual(code, 0)
        run.assert_called_once_with(
            [sys.executable, str(ROOT / "scripts" / "validate_bootstrap.py"), "config/bootstrap.json"],
            check=False,
        )


if __name__ == "__main__":
    unittest.main()
