#import <KYAApplicationSupport/KYAClosedLidReminder.h>

@interface KYAClosedLidReminder ()
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, copy) void (^notificationHandler)(void);
@end

@implementation KYAClosedLidReminder

- (instancetype)initWithInterval:(NSTimeInterval)interval
            notificationHandler:(void (^)(void))notificationHandler
{
    NSParameterAssert(interval > 0);
    NSParameterAssert(notificationHandler);
    self = [super init];
    if (self) {
        self.interval = interval;
        self.notificationHandler = notificationHandler;
    }
    return self;
}

- (void)dealloc
{
    [self.timer invalidate];
}

- (void)updateForActive:(BOOL)active indefinite:(BOOL)indefinite closedLidRunning:(BOOL)running
{
    if (!active || !indefinite || !running) {
        [self.timer invalidate];
        self.timer = nil;
        return;
    }
    if (self.timer != nil) return;

    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer timerWithTimeInterval:self.interval repeats:YES block:^(__unused NSTimer *timer) {
        KYAClosedLidReminder *strongSelf = weakSelf;
        if (strongSelf) strongSelf.notificationHandler();
    }];
    [NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
    self.notificationHandler();
}

@end
