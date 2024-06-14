#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <WebRTC/RTCAudioSource.h>
#import <WebRTC/RTCAudioTrack.h>
#import "CapturerEventsDelegate.h"
#import "AudioSocketConnection.h"
NS_ASSUME_NONNULL_BEGIN

@interface AudioCapturer : NSObject

@property (nonatomic, weak) id<CapturerEventsDelegate> eventsDelegate;

- (instancetype)initWithDelegate:delegate;
- (void)startCapture;
- (void)stopCapture;
- (void)startCaptureWithConnection:(AudioSocketConnection *)connection; // Declare the new method

@end

NS_ASSUME_NONNULL_END
