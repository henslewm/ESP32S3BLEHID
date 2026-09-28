from __future__ import annotations

import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parent.parent


def load_validate_bootstrap_ci():
    spec = importlib.util.spec_from_file_location("validate_bootstrap_ci", ROOT / "scripts" / "validate_bootstrap_ci.py")
    if spec is None or spec.loader is None:
        raise AssertionError("cannot load scripts/validate_bootstrap_ci.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


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
        module = load_validate_bootstrap_ci()

        self.assertTrue(module.require_active("push", "refs/heads/main"))
        self.assertTrue(module.require_active("workflow_dispatch", "refs/heads/main"))
        self.assertFalse(module.require_active("pull_request", "refs/pull/14/merge"))
        self.assertFalse(module.require_active("push", "refs/heads/feature"))

    def test_main_push_adds_require_active(self) -> None:
        module = load_validate_bootstrap_ci()

        with mock.patch.object(module.subprocess, "run", return_value=mock.Mock(returncode=0)) as run:
            code = module.main(["--event-name", "push", "--ref", "refs/heads/main"])

        self.assertEqual(code, 0)
        run.assert_called_once_with(
            [sys.executable, str(ROOT / "scripts" / "validate_bootstrap.py"), "config/bootstrap.json", "--require-active"],
            check=False,
        )

    def test_pull_request_uses_structural_validation(self) -> None:
        module = load_validate_bootstrap_ci()

        with mock.patch.object(module.subprocess, "run", return_value=mock.Mock(returncode=0)) as run:
            code = module.main(["--event-name", "pull_request", "--ref", "refs/pull/14/merge"])

        self.assertEqual(code, 0)
        run.assert_called_once_with(
            [sys.executable, str(ROOT / "scripts" / "validate_bootstrap.py"), "config/bootstrap.json"],
            check=False,
        )


if __name__ == "__main__":
    unittest.main()
