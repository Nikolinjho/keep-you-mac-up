"""Запись раз в секунду для ручной проверки сна с закрытой крышкой."""

from datetime import datetime, timedelta, timezone
from pathlib import Path
import time

path = Path(__file__).resolve().parents[1] / 'build/lid-heartbeat.log'
path.parent.mkdir(exist_ok=True)
msk = timezone(timedelta(hours=3))
print(f'Запись в {path}. Для остановки нажми Ctrl+C.', flush=True)
try:
    with path.open('a', buffering=1) as output:
        while True:
            output.write(datetime.now(msk).isoformat(timespec='seconds') + ' MSK\n')
            time.sleep(1)
except KeyboardInterrupt:
    print('Запись остановлена.')
