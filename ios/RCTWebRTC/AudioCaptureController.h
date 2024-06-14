#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>  // Import WebRTC framework if not already imported
#import "AudioCaptureController.h"
#import "CapturerEventsDelegate.h"
#import "AudioCapturer.h"
#import "CaptureController.h"
NS_ASSUME_NONNULL_BEGIN

// Constants
extern NSString *const kRTCScreensharingSocketFD;
extern NSString *const kRTCAppGroupIdentifier;

@class AudioCapturer;

@interface AudioCaptureController : CaptureController

// Initializer
- (instancetype)initWithCapturer:(AudioCapturer *)capturer;

// Public methods
- (void)startCapture;
- (void)stopCapture;
- (nullable RTCAudioTrack *)getAudioTrack;  // Method to get the audio track

@end

NS_ASSUME_NONNULL_END
