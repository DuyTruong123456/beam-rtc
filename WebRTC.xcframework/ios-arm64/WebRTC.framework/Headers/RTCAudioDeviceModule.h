
#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

#import <WebRTC/RTCMacros.h>

NS_ASSUME_NONNULL_BEGIN

RTC_OBJC_EXPORT

NS_CLASS_AVAILABLE_IOS(2_0)
@interface RTCAudioDeviceModule : NSObject
+ (instancetype)sharedInstance;
- (void)deliverRecordedData:(CMSampleBufferRef)sampleBuffer;

- (void)setExternalAudio:(bool)enable;
- (void)resetUserAudio;
@end

NS_ASSUME_NONNULL_END
