# Результаты проверки

Среда: Mac Apple Silicon, macOS 27.0, Xcode 27.0. Проверки выполнены 18 октября 2026 года. Физическое закрытие крышки оставлено Никите.

## Сборка и подпись

Команда `./scripts/build.sh` завершилась с кодом 0:

```text
BUILD SUCCEEDED: /Users/itsnikoko/keepyouawake/dist/KeepYouAwake.app
```

Команда `codesign --verify --deep --strict dist/KeepYouAwake.app` завершилась с кодом 0. Приложение имеет отдельный идентификатор `local.itsnikoko.KeepYouAwake`, схему URL `keepyouawake` и локальную подпись ad hoc. Процесс восстановления находится внутри приложения.

## Новые проверки

Команда `python3 -m unittest discover -s tests -v`:

```text
Ran 8 tests
OK
```

Один из восьми тестов компилирует и запускает Objective-C проверку управления сессией с 11 отдельными условиями. Проверены включение только при двух разрешающих флагах, повторное использование процесса, остановка при окончании сессии и снятии настройки, ошибки запуска, авария процесса и ошибка восстановления.

Полный вывод – `build/lid-tests.log`.

## Тесты Xcode

```bash
xcodebuild test -workspace KeepingYouAwake.xcworkspace -scheme KeepingYouAwake \
  -configuration Debug -destination 'platform=macOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO
```

Результат: 38 тестов, 0 ошибок. Из них 37 тестов исходного проекта и один тест сохранения и сброса новой настройки.

```text
KYAActivationDurationsTests: 16 tests, 0 failures
KYAApplicationEventsTests: 7 tests, 0 failures
KYAApplicationSupportTests: 15 tests, 0 failures
** TEST SUCCEEDED **
```

Полный вывод – `build/tests.log`. В исходном интерфейсе остаются предупреждения Xcode об устаревших методах NSStatusItem.

## Настоящий IOKit и готовое приложение

Команда `python3 scripts/smoke-native.py` запущена с открытой крышкой. Используется готовое приложение из `dist`, вызов IOKit не подменяется:

```text
PASS: IOKit accepted closed-lid enable without sudo
PASS: IOKit accepted restore after control-pipe EOF
PASS: ordinary timed session runs without closed-lid guard
PASS: timed session starts guard and restores on expiration/quit
PASS: guard restores and exits after application SIGKILL
PASS: global SleepDisabled setting unchanged
Physical lid closure remains untested.
```

Полный вывод – `build/native-smoke.log`.

Принятый ядром запрос подтверждает доступность интерфейса. Он не доказывает продолжение работы при физическом закрытии крышки. Для этого в README есть отдельная проверка с записью времени раз в секунду.

## Ревью

Отдельный агент проверил управление процессом, каналами, таймером, сборкой и подписью. Подтверждённых дефектов не обнаружено. Ограничение общего флага IOKit и взаимодействия с другими приложениями описано в README.

## Установка

Команда `./scripts/install.sh` установила приложение и зарегистрировала его в Launch Services:

```text
INSTALLED: /Applications/KeepYouAwake.app
```

Скрипт `./scripts/package.sh` создал `dist/KeepYouAwake.dmg` с приложением и ссылкой Applications. Проверка образа завершилась сообщением:

```text
hdiutil: verify: checksum of "dist/KeepYouAwake.dmg" is VALID
```
