#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import <KYAUserNotifications/KYAUserNotificationCenter.h>
#import "KYAActivationUserNotification.h"

@interface KYAUserNotificationCenter (Testing)
- (instancetype)initWithUserNotificationCenter:(UNUserNotificationCenter *)center;
@end

@interface TestSettings : NSObject
@property UNAuthorizationStatus authorizationStatus;
@end
@implementation TestSettings
@end

@interface TestNotificationCenter : NSObject
@property (weak) id<UNUserNotificationCenterDelegate> delegate;
@property TestSettings *settings;
@property UNAuthorizationOptions requestedOptions;
@property NSUInteger authorizationRequests;
@property UNNotificationRequest *request;
@end

@implementation TestNotificationCenter
- (void)getNotificationSettingsWithCompletionHandler:(void (^)(UNNotificationSettings *))completion
{
    completion((id)self.settings);
}
- (void)requestAuthorizationWithOptions:(UNAuthorizationOptions)options
                    completionHandler:(void (^)(BOOL, NSError *))completion
{
    self.authorizationRequests++;
    self.requestedOptions = options;
    completion(YES, nil);
}
- (void)addNotificationRequest:(UNNotificationRequest *)request
        withCompletionHandler:(void (^)(NSError *))completion
{
    self.request = request;
    completion(nil);
}
@end

static void check(BOOL condition, NSString *message)
{
    if (!condition) {
        NSLog(@"FAIL: %@", message);
        exit(1);
    }
}

int main(void)
{
    @autoreleasepool {
        TestNotificationCenter *system = [TestNotificationCenter new];
        system.settings = [TestSettings new];
        KYAUserNotificationCenter *center = [[KYAUserNotificationCenter alloc]
            initWithUserNotificationCenter:(id)system];

        system.settings.authorizationStatus = UNAuthorizationStatusAuthorized;
        __block NSInteger status = -1;
        [center getAuthorizationStatusWithCompletion:^(KYAUserNotificationAuthorizationStatus value) {
            status = value;
        }];
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        check(status == KYAUserNotificationAuthorizationStatusGranted, @"Разрешённые уведомления распознаются корректно");

        system.settings.authorizationStatus = UNAuthorizationStatusDenied;
        [center getAuthorizationStatusWithCompletion:^(KYAUserNotificationAuthorizationStatus value) {
            status = value;
        }];
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
        check(status == KYAUserNotificationAuthorizationStatusDenied, @"Запрет уведомлений распознаётся корректно");
        [center requestAuthorizationIfUndetermined];
        check(system.authorizationRequests == 0, @"При отказе пользователя повторного запроса нет");

        system.settings.authorizationStatus = UNAuthorizationStatusProvisional;
        [center requestAuthorizationIfUndetermined];
        check(system.authorizationRequests == 1, @"Тихое разрешение заменяется запросом баннеров");
        check(system.requestedOptions == UNAuthorizationOptionAlert, @"Запрос разрешения без тихой доставки");

        __block UNNotificationPresentationOptions presentation = 0;
        [system.delegate userNotificationCenter:(id)system willPresentNotification:(id)[NSObject new]
            withCompletionHandler:^(UNNotificationPresentationOptions options) {
                presentation = options;
            }];
        check((presentation & UNNotificationPresentationOptionBanner) != 0, @"Баннер виден при активном приложении");

        [center postNotification:KYAActivationUserNotification.closedLidReminderNotification];
        check([system.request.content.title isEqualToString:@"Preventing Sleep Indefinitely"], @"Заголовок указывает бессрочную сессию");
        check([system.request.content.body containsString:@"even with the lid closed"], @"Текст сообщает о закрытой крышке");
        check([system.request.identifier isEqualToString:KYAActivationUserNotificationIdentifier], @"Смена состояния заменяет старое уведомление");
        NSLog(@"PASS: 9 проверок доставки уведомлений");
    }
    return 0;
}
