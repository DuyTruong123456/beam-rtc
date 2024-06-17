#import <Foundation/Foundation.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCAudioTrack.h>

NS_ASSUME_NONNULL_BEGIN
@interface AudioSocketConnection : NSObject

@property (nonatomic, strong, readonly) RTCAudioSource *audioSource;
@property (nonatomic, strong, readonly) RTCAudioTrack *audioTrack;
- (instancetype)initWithFilePath:(NSString *)filePath
                      identifier:(NSString *)identifier
           peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnectionFactory;

- (void)openWithStreamDelegate:(id<NSStreamDelegate>)streamDelegate;
- (void)close;
- (void)sendData:(NSData *)data; // Add this method for sending data

@end

NS_ASSUME_NONNULL_END
