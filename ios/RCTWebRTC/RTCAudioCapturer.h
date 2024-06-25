#import <Foundation/Foundation.h>
#import <WebRTC/RTCMacros.h>
#import <WebRTC/RTCAudioDeviceModule.h>
NS_ASSUME_NONNULL_BEGIN

@class RTCAudioCapturer;

// Protocol definition
RTC_OBJC_EXPORT
@protocol RTCAudioCapturerDelegate <NSObject>
- (instancetype)initWithNativeAudioSource;
- (void)setVolume:(float)volume;
- (void)capturer:(RTCAudioCapturer *)capturer didCaptureAudioData:(NSData *)audioData;
@end

// Class definition
RTC_OBJC_EXPORT
@interface RTCAudioCapturer : NSObject

@property (nonatomic, weak) id<RTCAudioCapturerDelegate> delegate;

// Designated initializer
- (instancetype)initWithDelegate:(id<RTCAudioCapturerDelegate>)delegate
               audioDeviceModule:(RTCAudioDeviceModule *)audioDeviceModule;


@end

NS_ASSUME_NONNULL_END

