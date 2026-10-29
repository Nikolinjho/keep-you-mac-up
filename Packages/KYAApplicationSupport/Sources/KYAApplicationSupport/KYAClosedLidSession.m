#import <KYAApplicationSupport/KYAClosedLidSession.h>
#include <poll.h>
#include <unistd.h>

@interface KYAClosedLidSession ()
@property (nonatomic) NSURL *executableURL;
@property (nonatomic, nullable) NSTask *task;
@property (nonatomic, nullable) NSFileHandle *control;
@end

@implementation KYAClosedLidSession

- (instancetype)initWithExecutableURL:(NSURL *)executableURL
{
    self = [super init];
    if (self) _executableURL = [executableURL copy];
    return self;
}

- (void)dealloc
{
    [self stopWithError:nil];
}

- (BOOL)isRunning
{
    return self.task.running;
}

- (int)processIdentifier
{
    return self.task.processIdentifier;
}

- (NSError *)errorWithDescription:(NSString *)description
{
    NSString *recovery = [NSString stringWithFormat:
        @"To restore normal lid sleep, run \"%@\" --restore in Terminal, or restart your Mac.",
        self.executableURL.path];
    return [NSError errorWithDomain:@"local.itsnikoko.KeepYouAwake.ClosedLid" code:1
                          userInfo:@{NSLocalizedDescriptionKey: description,
                                     NSLocalizedRecoverySuggestionErrorKey: recovery}];
}

- (BOOL)waitForTask:(NSTask *)task timeout:(NSTimeInterval)timeout
{
    NSTimeInterval deadline = NSProcessInfo.processInfo.systemUptime + timeout;
    while (task.running && NSProcessInfo.processInfo.systemUptime < deadline) usleep(10000);
    return !task.running;
}

- (BOOL)restoreWithError:(NSError **)error
{
    NSTask *task = [NSTask new];
    task.executableURL = self.executableURL;
    task.arguments = @[@"--restore"];
    if (![task launchAndReturnError:error]) return NO;
    if (![self waitForTask:task timeout:3] || task.terminationStatus != 0) {
        if (error) *error = [self errorWithDescription:@"Could not restore normal lid sleep."];
        return NO;
    }
    return YES;
}

- (BOOL)stopWithError:(NSError **)error
{
    NSTask *task = self.task;
    if (!task) return YES;
    task.terminationHandler = nil;
    [self.control closeFile];
    self.control = nil;

    if (![self waitForTask:task timeout:3]) {
        [task terminate];
        if (![self waitForTask:task timeout:1]) {
            if (error) *error = [self errorWithDescription:@"The closed-lid process did not stop."];
            return NO;
        }
    }
    self.task = nil;
    if (task.terminationStatus != 0 || task.terminationReason != NSTaskTerminationReasonExit) {
        return [self restoreWithError:error];
    }
    return YES;
}

- (BOOL)updateForActive:(BOOL)active enabled:(BOOL)enabled error:(NSError **)error
{
    if (!active || !enabled) return [self stopWithError:error];
    if (self.running) return YES;
    if (self.task && ![self stopWithError:error]) return NO;

    NSTask *task = [NSTask new];
    NSPipe *control = [NSPipe pipe];
    NSPipe *status = [NSPipe pipe];
    task.executableURL = self.executableURL;
    task.standardInput = control;
    task.standardOutput = status;
    if (![task launchAndReturnError:error]) return NO;

    self.task = task;
    self.control = control.fileHandleForWriting;
    struct pollfd descriptor = {.fd = status.fileHandleForReading.fileDescriptor, .events = POLLIN};
    char ready = 0;
    BOOL started = poll(&descriptor, 1, 3000) > 0 &&
        read(descriptor.fd, &ready, 1) == 1 && ready == 'R';
    [status.fileHandleForReading closeFile];
    if (!started) {
        NSError *restoreError = nil;
        [self stopWithError:&restoreError];
        if (error) *error = restoreError ?: [self errorWithDescription:
            @"Could not enable closed-lid mode. Ordinary keep-awake still works."];
        return NO;
    }

    __weak typeof(self) weakSelf = self;
    task.terminationHandler = ^(NSTask *finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            KYAClosedLidSession *session = weakSelf;
            if (!session || session.task != finished) return;
            NSError *restoreError = nil;
            [session stopWithError:&restoreError];
            NSError *failure = restoreError ?: [session errorWithDescription:
                @"Closed-lid mode stopped unexpectedly and has been disabled."];
            if (session.failureHandler) session.failureHandler(failure);
        });
    };
    return YES;
}

@end
