"""Проверка напоминаний без изменения питания и отправки уведомлений macOS."""

from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SUPPORT = ROOT / 'Packages/KYAApplicationSupport/Sources/KYAApplicationSupport'


class ReminderTests(unittest.TestCase):
    def test_разрешения_баннеры_и_содержимое_уведомления(self):
        notifications = ROOT / 'Packages/KYAUserNotifications/Sources/KYAUserNotifications'
        common = ROOT / 'Packages/KYACommon/Sources/KYACommon/include'
        activation = ROOT / 'KeepingYouAwake/KYAActivationUserNotification'
        with tempfile.TemporaryDirectory() as directory:
            runner = Path(directory) / 'notification-tests'
            subprocess.run([
                'xcrun', 'clang', '-fobjc-arc', '-fmodules', '-Wall', '-Wextra', '-Werror',
                '-fmodules-cache-path=' + str(ROOT / 'build/test-module-cache'),
                '-framework', 'Cocoa', '-framework', 'UserNotifications',
                '-I', str(notifications / 'include'), '-I', str(common),
                '-I', str(activation), '-I', str(ROOT / 'KeepingYouAwake'),
                str(ROOT / 'tests/notification_tests.m'),
                str(notifications / 'KYAUserNotificationCenter.m'),
                str(notifications / 'NSDate+RemainingTime.m'),
                str(activation / 'KYAActivationUserNotification.m'), '-o', str(runner),
            ], check=True)
            result = subprocess.run([str(runner)], capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            print(result.stderr.decode())

    def test_повторение_и_остановка_напоминаний(self):
        with tempfile.TemporaryDirectory() as directory:
            runner = Path(directory) / 'reminder-tests'
            subprocess.run([
                'xcrun', 'clang', '-fobjc-arc', '-fmodules', '-Wall', '-Wextra', '-Werror',
                '-fmodules-cache-path=' + str(ROOT / 'build/test-module-cache'),
                '-framework', 'Foundation', '-I', str(SUPPORT / 'include'),
                str(ROOT / 'tests/reminder_tests.m'),
                str(SUPPORT / 'KYAClosedLidReminder.m'), '-o', str(runner),
            ], check=True)
            result = subprocess.run([str(runner)], capture_output=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            print(result.stderr.decode())
