#import <Foundation/Foundation.h>
#import <KYAApplicationSupport/KYAClosedLidReminder.h>

static void check(BOOL condition, NSString *message)
{
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        exit(1);
    }
}

static void advance(NSTimeInterval interval)
{
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
}

int main(void)
{
    @autoreleasepool {
        __block NSUInteger count = 0;
        KYAClosedLidReminder *reminder = [[KYAClosedLidReminder alloc]
            initWithInterval:0.08 notificationHandler:^{ count++; }];

        [reminder updateForActive:NO indefinite:YES closedLidRunning:YES];
        [reminder updateForActive:YES indefinite:NO closedLidRunning:YES];
        [reminder updateForActive:YES indefinite:YES closedLidRunning:NO];
        advance(0.12);
        check(count == 0, @"Нет напоминаний без активной бессрочной защиты крышки");

        [reminder updateForActive:YES indefinite:YES closedLidRunning:YES];
        check(count == 1, @"Первое уведомление сразу после включения");
        for (NSUInteger i = 0; i < 5; i++) {
            advance(0.02);
            [reminder updateForActive:YES indefinite:YES closedLidRunning:YES];
        }
        check(count >= 2, @"Повторная синхронизация не откладывает напоминание");
        advance(0.1);
        check(count >= 3, @"Напоминания повторяются");

        [reminder updateForActive:NO indefinite:YES closedLidRunning:YES];
        NSUInteger stoppedCount = count;
        advance(0.12);
        check(count == stoppedCount, @"Выключение сессии останавливает напоминания");

        [reminder updateForActive:YES indefinite:YES closedLidRunning:YES];
        check(count == stoppedCount + 1, @"Новая сессия начинает новый цикл");
        [reminder updateForActive:YES indefinite:NO closedLidRunning:YES];
        stoppedCount = count;
        advance(0.12);
        check(count == stoppedCount, @"Переход на таймер останавливает напоминания");

        [reminder updateForActive:YES indefinite:YES closedLidRunning:YES];
        [reminder updateForActive:YES indefinite:YES closedLidRunning:NO];
        stoppedCount = count;
        advance(0.12);
        check(count == stoppedCount, @"Остановка защиты крышки отменяет напоминания");

        [reminder updateForActive:YES indefinite:YES closedLidRunning:YES];
        __weak KYAClosedLidReminder *weakReminder = reminder;
        reminder = nil;
        check(weakReminder == nil, @"Таймер не удерживает объект напоминаний");
        stoppedCount = count;
        advance(0.12);
        check(count == stoppedCount, @"Освобождение объекта останавливает таймер");
        NSLog(@"PASS: 10 проверок жизненного цикла напоминаний");
    }
    return 0;
}
