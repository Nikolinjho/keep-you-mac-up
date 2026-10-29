"""Проверка настоящего приложения с открытой крышкой. Меняет режим сна на несколько секунд."""

from pathlib import Path
import os
import plistlib
import select
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'dist/Keep You Mac Up.app'
GUARD = APP / 'Contents/Helpers/KeepYouAwakeLidGuard'
PREFIX = 'info.marcel-dierkes.KeepingYouAwake.'


def power_state():
    data = subprocess.check_output(['ioreg', '-a', '-r', '-n', 'IOPMrootDomain', '-d', '1'])
    return plistlib.loads(data)[0]


def exists(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False


def child_guard(pid):
    result = subprocess.run(['pgrep', '-P', str(pid), '-f', 'KeepYouAwakeLidGuard'],
                            capture_output=True, text=True)
    return int(result.stdout.strip()) if result.returncode == 0 else None


def run_app(enabled, crash=False):
    arguments = [str(APP / 'Contents/MacOS/Keep You Mac Up'),
                 '-' + PREFIX + 'ActivateOnLaunch', 'YES',
                 '-' + PREFIX + 'TimeInterval', '3',
                 '-' + PREFIX + 'IsQuitOnTimerExpirationEnabled', 'YES',
                 '-' + PREFIX + 'KeepAwakeWhenLidClosed', 'YES' if enabled else 'NO']
    with open(ROOT / 'build/native-smoke-app.log', 'ab') as log:
        app = subprocess.Popen(arguments, stdout=log, stderr=log)
        guard_pid = None
        try:
            deadline = time.monotonic() + 2.5
            while time.monotonic() < deadline and app.poll() is None:
                guard_pid = child_guard(app.pid)
                if guard_pid:
                    break
                time.sleep(0.05)
            assert bool(guard_pid) == enabled, f'Unexpected guard: {guard_pid}, enabled={enabled}'
            if crash:
                app.kill()
            app.wait(timeout=8)
            if not crash:
                assert app.returncode == 0, f'App exit: {app.returncode}'
            if guard_pid:
                deadline = time.monotonic() + 3
                while exists(guard_pid) and time.monotonic() < deadline:
                    time.sleep(0.05)
                assert not exists(guard_pid), 'Guard survived application exit'
        finally:
            if app.poll() is None:
                app.kill()
                app.wait(timeout=3)
            subprocess.run([str(GUARD), '--restore'], check=True)


def main():
    before = power_state()
    assert before.get('AppleClamshellState') is False, 'Open the lid before running this check'
    assert subprocess.run(['pgrep', '-f', str(APP / 'Contents/MacOS/Keep You Mac Up')],
                          capture_output=True).returncode != 0, 'Quit KeepYouAwake before this check'
    assert subprocess.run(['pgrep', '-f', str(GUARD)], capture_output=True).returncode != 0, \
        'Another closed-lid guard is running'
    
    process = subprocess.Popen([str(GUARD)], stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        assert select.select([process.stdout], [], [], 3)[0], 'IOKit readiness timeout'
        assert process.stdout.read(1) == b'R', process.stderr.read().decode()
        print('PASS: IOKit accepted closed-lid enable without sudo', flush=True)
        process.stdin.close()
        process.wait(timeout=3)
        assert process.returncode == 0, process.stderr.read().decode()
        print('PASS: IOKit accepted restore after control-pipe EOF', flush=True)
    finally:
        if process.poll() is None:
            process.send_signal(signal.SIGTERM)
            process.wait(timeout=3)
        subprocess.run([str(GUARD), '--restore'], check=True)

    run_app(enabled=False)
    print('PASS: ordinary timed session runs without closed-lid guard', flush=True)
    run_app(enabled=True)
    print('PASS: timed session starts guard and restores on expiration/quit', flush=True)
    run_app(enabled=True, crash=True)
    print('PASS: guard restores and exits after application SIGKILL', flush=True)
    after = power_state()
    assert before.get('SleepDisabled') == after.get('SleepDisabled')
    print('PASS: global SleepDisabled setting unchanged', flush=True)
    print('Physical lid closure remains untested.', flush=True)


if __name__ == '__main__':
    main()
