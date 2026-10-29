"""Проверка процесса закрытой крышки без изменения питания компьютера."""

import os
from pathlib import Path
import signal
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LidGuardTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = tempfile.TemporaryDirectory()
        cls.binary = Path(cls.directory.name) / 'lid-guard'
        subprocess.run(['xcrun', 'clang', '-Wall', '-Wextra', '-Werror',
                        '-DKYA_LID_TESTING=1', '-DKYA_REFRESH_MS=50',
                        str(ROOT / 'LidGuard/main.c'), '-o', str(cls.binary)], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.directory.cleanup()

    def start(self, **environment):
        process = subprocess.Popen([str(self.binary)], stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   env={**os.environ, **environment})
        self.addCleanup(self.cleanup_process, process)
        return process

    @staticmethod
    def cleanup_process(process):
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=3)
        for stream in (process.stdin, process.stdout, process.stderr):
            if stream:
                stream.close()

    def ready(self, process):
        self.assertEqual(process.stdout.read(1), b'R')

    def finish(self, process):
        process.stdin.close()
        process.wait(timeout=3)
        return process.stderr.read().decode()

    def test_восстанавливает_сон_после_закрытия_канала(self):
        process = self.start()
        self.ready(process)
        log = self.finish(process)
        self.assertEqual(process.returncode, 0)
        self.assertEqual(log.splitlines(), ['disable', 'restore'])

    def test_восстанавливает_сон_после_sigterm(self):
        process = self.start()
        self.ready(process)
        process.send_signal(signal.SIGTERM)
        process.wait(timeout=3)
        self.assertEqual(process.returncode, 0)
        self.assertEqual(process.stderr.read().decode().splitlines(), ['disable', 'restore'])

    def test_не_сообщает_готовность_при_ошибке_включения(self):
        process = self.start(KYA_TEST_FAIL_ENABLE='1')
        self.assertEqual(process.stdout.read(), b'')
        process.wait(timeout=3)
        self.assertNotEqual(process.returncode, 0)
        self.assertIn('restore', process.stderr.read().decode())

    def test_повторяет_запрос_пока_канал_открыт(self):
        process = self.start()
        self.ready(process)
        time.sleep(0.17)
        log = self.finish(process)
        self.assertGreaterEqual(log.splitlines().count('disable'), 2)
        self.assertEqual(log.splitlines()[-1], 'restore')

    def test_сообщает_ошибку_восстановления(self):
        process = self.start(KYA_TEST_FAIL_RESTORE='1')
        self.ready(process)
        log = self.finish(process)
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(log.splitlines().count('restore'), 3)

    def test_команда_восстановления_не_включает_режим(self):
        result = subprocess.run([str(self.binary), '--restore'], capture_output=True, check=True)
        self.assertEqual(result.stderr.decode().splitlines(), ['restore'])

    def test_неизвестный_аргумент_не_меняет_питание(self):
        result = subprocess.run([str(self.binary), '--unknown'], capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(b'disable', result.stderr)
        self.assertNotIn(b'restore', result.stderr)


if __name__ == '__main__':
    unittest.main()
