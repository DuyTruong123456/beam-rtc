#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <WebRTC/RTCAudioSource.h>
#import <WebRTC/RTCAudioTrack.h>
#import "CapturerEventsDelegate.h"
#import "AudioSocketConnection.h"
#import "RTCAudioCapturer.h"
NS_ASSUME_NONNULL_BEGIN
@interface AudioCapturer : RTCAudioCapturer
@property (nonatomic, weak) id<CapturerEventsDelegate> eventsDelegate;
@property (nonatomic, weak) RTCAudioDeviceModule * audioDeviceModule;
@property(nonatomic) float numBufferReceive;
- (instancetype)initWithDelegate:(__weak id<RTCAudioCapturerDelegate>)delegate
                audioDeviceModule:(RTCAudioDeviceModule*)audioDeviceModule;
- (void)startCapture;
- (void)stopCapture;
- (void)startCaptureWithConnection:(AudioSocketConnection *)connection; // Declare the new method
@end
NS_ASSUME_NONNULL_END
