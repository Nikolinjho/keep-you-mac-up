"""Проверка Objective-C управления настоящим дочерним процессом."""

from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SUPPORT = ROOT / 'Packages/KYAApplicationSupport/Sources/KYAApplicationSupport'


class SessionTests(unittest.TestCase):
    def test_жизненный_цикл_сессии(self):
        with tempfile.TemporaryDirectory() as directory:
            guard = Path(directory) / 'guard'
            runner = Path(directory) / 'session-tests'
            subprocess.run(['xcrun', 'clang', '-DKYA_LID_TESTING=1',
                            str(ROOT / 'LidGuard/main.c'), '-o', str(guard)], check=True)
            subprocess.run(['xcrun', 'clang', '-fobjc-arc', '-fmodules', '-Wall', '-Wextra', '-Werror',
                            '-framework', 'Foundation', '-I', str(SUPPORT / 'include'),
                            str(ROOT / 'tests/session_tests.m'),
                            str(SUPPORT / 'KYAClosedLidSession.m'), '-o', str(runner)], check=True)
            result = subprocess.run([str(runner), str(guard)], capture_output=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            print(result.stderr.decode())


if __name__ == '__main__':
    unittest.main()
