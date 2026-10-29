#import <Foundation/Foundation.h>
#import <KYAApplicationSupport/KYAClosedLidSession.h>
#include <signal.h>

static void check(BOOL condition, NSString *description)
{
    if (!condition) {
        NSLog(@"FAIL: %@", description);
        exit(1);
    }
    NSLog(@"PASS: %@", description);
}

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        if (argc != 2) return 64;
        NSURL *url = [NSURL fileURLWithPath:@(argv[1])];
        KYAClosedLidSession *session = [[KYAClosedLidSession alloc] initWithExecutableURL:url];
        NSError *error = nil;

        check([session updateForActive:NO enabled:YES error:&error] && !session.running,
              @"Настройка без активной сессии не запускает процесс");
        check([session updateForActive:YES enabled:NO error:&error] && !session.running,
              @"Активная сессия без настройки не запускает процесс");
        check([session updateForActive:YES enabled:YES error:&error] && session.running,
              @"Настройка и активная сессия запускают процесс");
        pid_t process = session.processIdentifier;
        check([session updateForActive:YES enabled:YES error:&error] && session.processIdentifier == process,
              @"Повторная синхронизация не создаёт второй процесс");
        check([session updateForActive:NO enabled:YES error:&error] && !session.running,
              @"Окончание сессии останавливает процесс");
        check(kill(process, 0) == -1 && errno == ESRCH,
              @"Остановка дожидается завершения процесса");

        [session updateForActive:YES enabled:YES error:&error];
        check([session updateForActive:YES enabled:NO error:&error] && !session.running,
              @"Снятие настройки останавливает процесс");

        KYAClosedLidSession *missing = [[KYAClosedLidSession alloc]
            initWithExecutableURL:[NSURL fileURLWithPath:@"/nonexistent/KeepYouAwakeLidGuard"]];
        error = nil;
        check(![missing updateForActive:YES enabled:YES error:&error] && error != nil && !missing.running,
              @"Отсутствующий процесс возвращает ошибку");

        setenv("KYA_TEST_FAIL_ENABLE", "1", 1);
        error = nil;
        check(![session updateForActive:YES enabled:YES error:&error] && error != nil && !session.running,
              @"Ошибка IOKit не выдаётся за включённый режим");
        unsetenv("KYA_TEST_FAIL_ENABLE");

        [session updateForActive:YES enabled:YES error:&error];
        __block BOOL reported = NO;
        session.failureHandler = ^(NSError *failure) { reported = failure != nil; };
        kill(session.processIdentifier, SIGKILL);
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3];
        while (!reported && deadline.timeIntervalSinceNow > 0) {
            [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        }
        check(reported && !session.running, @"Авария процесса вызывает восстановление и сообщение об ошибке");

        setenv("KYA_TEST_FAIL_RESTORE", "1", 1);
        [session updateForActive:YES enabled:YES error:&error];
        error = nil;
        check(![session updateForActive:NO enabled:NO error:&error] && error != nil,
              @"Ошибка восстановления возвращается вызывающему коду");
        unsetenv("KYA_TEST_FAIL_RESTORE");
        NSLog(@"11 проверок управления сессией пройдены");
    }
    return 0;
}
