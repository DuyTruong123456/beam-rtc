#if TARGET_OS_IOS

#import "AudioCaptureController.h"
#import "AudioCapturer.h"
#import "SocketConnection.h"
#import "AudioSocketConnection.h"
#import <os/log.h>

NSString *const kRTCAudioSocketFD = @"rtc_Audio";
NSString *const kaudioRTCAppGroupIdentifier = @"RTCAppGroupIdentifier";

@interface AudioCaptureController () <CapturerEventsDelegate>

@property (nonatomic, strong) AudioCapturer *capturer;
@property (nonatomic, strong) RTCAudioTrack *audioTrack;
@property (nonatomic, strong) AudioSocketConnection *audioConnection;
@end

@implementation AudioCaptureController

- (instancetype)initWithCapturer:(AudioCapturer *)capturer {
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
   // [self.capturer stopCapture];
}

- (void)startCapture {
    if (!self.appGroupIdentifier) {
        NSLog(@"App group identifier is missing");
        return;
    }
  //  [self.audioConnection close];
    self.capturer.eventsDelegate = self;

    // Setup for rtc_Audio (Audio)
    NSString *audioSocketFilePath = [self filePathForApplicationGroupIdentifier:self.appGroupIdentifier component:kRTCAudioSocketFD];
    NSLog(@"Socket file path for rtc_Audio: %@", audioSocketFilePath);
    RTCPeerConnectionFactory *peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    self.audioConnection = [[AudioSocketConnection alloc] initWithFilePath:audioSocketFilePath
                                                                  identifier:kRTCAudioSocketFD
                                                        peerConnectionFactory:peerConnectionFactory];
    if (self.audioConnection) {
        [self.capturer startCaptureWithConnection:self.audioConnection];
        //[self.audioConnection openWithStreamDelegate:audioConnection];
       // self.audioTrack = self.audioConnection.audioTrack;
        NSLog(@"Created AudioSocketConnection for rtc_Audio");
    } else {
        NSLog(@"Failed to create AudioSocketConnection for rtc_Audio");
    }
}

- (void)stopCapture {
   // [self.audioConnection close];
   // [self.capturer stopCapture];
}
- (nullable RTCAudioTrack *)getAudioTrack {
    return self.audioTrack;
}
// MARK: CapturerEventsDelegate Methods

- (void)capturerDidEnd:(RTCVideoCapturer *)capturer {
    //[self.eventsDelegate capturerDidEnd:capturer];
}

// MARK: Private Methods

- (NSString *)appGroupIdentifier {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return infoDictionary[kaudioRTCAppGroupIdentifier];
}

- (NSString *)filePathForApplicationGroupIdentifier:(NSString *)identifier component:(NSString *)component {
    NSURL *sharedContainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:identifier];
    NSString *socketFilePath = [[sharedContainer URLByAppendingPathComponent:component] path];
    NSLog(@"Socket file path for %{public}s: %{public}s", component, socketFilePath);
    return socketFilePath;
}

@end

#endif
