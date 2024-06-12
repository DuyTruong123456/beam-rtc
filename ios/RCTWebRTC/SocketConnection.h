#import <Foundation/Foundation.h>

@interface SocketConnection : NSObject

@property(nonatomic, strong, readonly) NSString *identifier;

- (instancetype)initWithFilePath:(nonnull NSString *)filePath identifier:(NSString *)identifier;

- (void)openWithStreamDelegate:(id<NSStreamDelegate>)streamDelegate;
- (void)close;

@end
