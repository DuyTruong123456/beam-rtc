#import "AudioCapturer.h"
#import "AudioSocketConnection.h"
#import <WebRTC/RTCPeerConnectionFactory.h>
@interface AudioCapturer () <AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) RTCAudioSource *audioSource;
@property (nonatomic, strong) RTCAudioTrack *audioTrack;
@property (nonatomic, strong) dispatch_queue_t audioQueue;
@property (nonatomic, assign) BOOL isCapturing;
@property(nonatomic, strong) AudioSocketConnection *connection;
@end

@implementation AudioCapturer

- (instancetype)initWithDelegate:delegate {
    self = [super init];
    if (self) {
        _eventsDelegate = delegate;
        _audioQueue = dispatch_queue_create("audioQueue", NULL);
        [self setupAudioTrack];
    }
    return self;
}

- (void)dealloc {
    [self stopCapture];
}

- (void)startCapture {
    if (self.isCapturing) {
        return;
    }

    dispatch_async(self.audioQueue, ^{
        [self.audioTrack setIsEnabled:YES];
    });

    self.isCapturing = YES;
}

- (void)stopCapture {
    if (!self.isCapturing) {
        return;
    }

    dispatch_async(self.audioQueue, ^{
        [self.audioTrack setIsEnabled:NO];
    });

    self.isCapturing = NO;
}
- (void)startCaptureWithConnection:(AudioSocketConnection *)connection {
    NSLog(@"Started capturing audio with connection.");
    if (self.isCapturing) {
        // If already capturing, stop current capture first
        [self stopCapture];
    }

    self.connection = connection;
    self.isCapturing = YES;

    dispatch_async(self.audioQueue, ^{
        [self.audioTrack setIsEnabled:YES];
    });

    // Here you might want to notify the delegate or perform any setup related to the connection
    // For example:
    // [self.connection open]; // If open method exists on SocketConnection
    [self.connection openWithStreamDelegate:self.connection];
    NSLog(@"Started");
}
#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (!self.isCapturing) {
        return;
    }

    dispatch_async(self.audioQueue, ^{
        CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
        size_t bufferLength = CMBlockBufferGetDataLength(blockBufferRef);
        NSMutableData *data = [NSMutableData dataWithLength:bufferLength];
        CMBlockBufferCopyDataBytes(blockBufferRef, 0, bufferLength, data.mutableBytes);

        // Process the audio data as needed
        [self processAudioData:data];
    });
}

- (void)processAudioData:(NSData *)data {
    // Example method for processing audio data
    // In a real scenario, this would involve sending data to RTC or other processing logic
    NSLog(@"Processing audio data: %@", data);
}

- (void)setupAudioTrack {
    // Example method for setting up audio track
    RTCPeerConnectionFactory *peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    self.audioSource = [peerConnectionFactory audioSourceWithConstraints:nil];
    self.audioTrack = [peerConnectionFactory audioTrackWithSource:self.audioSource trackId:@"audioTrackId"];
}

@end
