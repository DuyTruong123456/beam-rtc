#if TARGET_OS_IOS

#import "ScreenCaptureController.h"
#import "ScreenCapturer.h"
#import "SocketConnection.h"
#import <os/log.h>

NSString *const kRTCScreensharingSocketFD = @"rtc_Video";
NSString *const kRTCAudioSocketFD = @"rtc_Audio";
NSString *const kRTCAppGroupIdentifier = @"RTCAppGroupIdentifier";

@interface ScreenCaptureController ()

@property(nonatomic, retain) ScreenCapturer *capturer;

@end

@interface ScreenCaptureController (CapturerEventsDelegate)<CapturerEventsDelegate>
- (void)capturerDidEnd:(RTCVideoCapturer *)capturer;
@end

@interface ScreenCaptureController (Private)

@property(nonatomic, readonly) NSString *appGroupIdentifier;

@end

@implementation ScreenCaptureController

- (instancetype)initWithCapturer:(nonnull ScreenCapturer *)capturer {
    self = [super init];
    if (self) {
        self.capturer = capturer;
    }

    return self;
}
- (NSData *)readFileAtPath:(NSString *)filePath {
    NSError *error;
    NSData *fileData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    if (error) {
        NSLog(@"Failed to read file at path %@ with error: %@", filePath, error.localizedDescription);
        return nil;
    }
    return fileData;
}
- (void)dealloc {
    [self.capturer stopCapture];
}

- (void)startCapture {
    if (!self.appGroupIdentifier) {
        NSLog(@"App group identifier is missing");
        return;
    }

    self.capturer.eventsDelegate = self;
    
    // Setup for rtc_SSFD
    NSString *ssfdSocketFilePath = [self filePathForApplicationGroupIdentifier:self.appGroupIdentifier component:kRTCScreensharingSocketFD];
    NSLog(@"Socket file path for rtc_SSFD: %{public}s", ssfdSocketFilePath);

    NSData *videoData = [self readFileAtPath:ssfdSocketFilePath ];
    if (videoData) {
        NSLog(@"Read video data: %@", videoData);
        // You can process the audio data as needed here.
    } else {
        NSLog(@"Failed to read video data");
    }
    SocketConnection *ssfdConnection = [[SocketConnection alloc] initWithFilePath:ssfdSocketFilePath identifier:kRTCScreensharingSocketFD];
    if (ssfdConnection) {
        [self.capturer startCaptureWithConnection:ssfdConnection];
    } else {
        NSLog(@"Failed to create SocketConnection for rtc_SSFD");
    }

    // Setup for rtc_Audio
    NSString *audioSocketFilePath = [self filePathForApplicationGroupIdentifier:self.appGroupIdentifier component:kRTCAudioSocketFD];
    NSLog(@"Socket file path for rtc_Audio: %{public}s", audioSocketFilePath);
        NSData *audioData = [self readFileAtPath:audioSocketFilePath];
    if (audioData) {
        NSLog(@"Read audio data: %@", audioData);
        // You can process the audio data as needed here.
    } else {
        NSLog(@"Failed to read audio data");
    }
    
    SocketConnection *audioConnection = [[SocketConnection alloc] initWithFilePath:audioSocketFilePath identifier:kRTCAudioSocketFD];
    if (audioConnection) {
     [audioConnection openWithStreamDelegate:audioConnection];
      NSLog(@"success to create SocketConnection for rtc_Audio");
   } else {
       NSLog(@"Failed to create SocketConnection for rtc_Audio");
   }
   
}

- (void)stopCapture {
    [self.capturer stopCapture];
}

// MARK: CapturerEventsDelegate Methods

- (void)capturerDidEnd:(RTCVideoCapturer *)capturer {
    [self.eventsDelegate capturerDidEnd:capturer];
}

// MARK: Private Methods

- (NSString *)appGroupIdentifier {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return infoDictionary[kRTCAppGroupIdentifier];
}

- (NSString *)filePathForApplicationGroupIdentifier:(nonnull NSString *)identifier component:(NSString *)component {
    NSURL *sharedContainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:identifier];
    NSString *socketFilePath = [[sharedContainer URLByAppendingPathComponent:component] path];
    NSLog(@"Socket file path for %{public}s: %{public}s", component, socketFilePath);
    return socketFilePath;
}

@end

#endif
