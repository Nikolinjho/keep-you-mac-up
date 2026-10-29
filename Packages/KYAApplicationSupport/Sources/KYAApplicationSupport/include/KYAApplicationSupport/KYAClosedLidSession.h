#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KYAClosedLidSession : NSObject
@property (nonatomic, readonly, getter=isRunning) BOOL running;
@property (nonatomic, readonly) int processIdentifier;
@property (nonatomic, copy, nullable) void (^failureHandler)(NSError *error);

- (instancetype)initWithExecutableURL:(NSURL *)executableURL;
- (BOOL)updateForActive:(BOOL)active enabled:(BOOL)enabled error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
