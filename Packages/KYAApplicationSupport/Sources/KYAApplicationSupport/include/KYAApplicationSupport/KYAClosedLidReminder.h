#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KYAClosedLidReminder : NSObject
- (instancetype)initWithInterval:(NSTimeInterval)interval
            notificationHandler:(void (^)(void))notificationHandler;
- (void)updateForActive:(BOOL)active indefinite:(BOOL)indefinite closedLidRunning:(BOOL)running;
@end

NS_ASSUME_NONNULL_END
