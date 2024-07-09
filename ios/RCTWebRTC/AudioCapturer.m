#import "AudioCapturer.h"
#import "AudioSocketConnection.h"
#import <WebRTC/RTCAudioTrack.h>
#import "RTCAudioCapturer.h"
const NSUInteger kMaxAudioReadLength = 10 * 1024;

@interface AudioCapturer () <NSStreamDelegate>

@property(nonatomic, strong) dispatch_queue_t audioQueue;
@property(nonatomic, assign) BOOL isCapturing;
@property(nonatomic, strong) AudioSocketConnection *connection;

@end

@implementation AudioCapturer {
    NSInteger _readLength;
}
- (instancetype)initWithDelegate:(id<RTCAudioCapturerDelegate>)delegate
                audioDeviceModule:(RTCAudioDeviceModule *)audioDeviceModule {
    self = [super initWithDelegate:delegate audioDeviceModule:audioDeviceModule];
     if (self) {
         _audioQueue = dispatch_queue_create("audioQueue", DISPATCH_QUEUE_SERIAL);
         self.audioDeviceModule=audioDeviceModule;
         self.numBufferReceive =0;
     }
     return self;
}
- (void)dealloc {
    [self stopCapture];
}

- (void)setConnection:(AudioSocketConnection *)connection {
    if (_connection != connection) {
        [_connection close];
        _connection = connection;
    }
}

- (void)startCapture {
    if (self.isCapturing) {
        return;
    }

    self.isCapturing = YES;
}
- (void)startCaptureWithConnection:(AudioSocketConnection *)connection {
    if (self.isCapturing) {
        [self stopCapture];
    }

    self.connection = connection;
    self.isCapturing = YES;

    [self.connection openWithStreamDelegate:self];
}

- (void)stopCapture {
    if (!self.isCapturing) {
        return;
    }

    self.isCapturing = NO;
    self.connection = nil;
}

- (void)readBytesFromStream:(NSInputStream *)stream {
    if (!stream.hasBytesAvailable) {
        NSLog(@"No bytes available to read from stream.");
        return;
    }
    
    uint8_t buffer[kMaxAudioReadLength];
    NSInteger numberOfBytesRead = [stream read:buffer maxLength:kMaxAudioReadLength];
    if (numberOfBytesRead < 0) {
        NSLog(@"Error reading bytes from stream: %@", stream.streamError.localizedDescription);
        return;
    }
   
    // Create NSData from the remaining data in buffer
    NSData *audioData = [NSData dataWithBytes:buffer length:numberOfBytesRead];
    [self processAudioData:audioData];
    NSLog(@"Read %ld bytes from stream.", (long)numberOfBytesRead);
    NSLog(@"Buffer as NSData: %@", audioData);
}


- (void)processAudioData:(NSData *)data {
    self.numBufferReceive++;
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(
        kCFAllocatorDefault,
        (void *)data.bytes,
        data.length,
        kCFAllocatorNull,
        NULL,
        0,
        data.length,
        0,
        &blockBuffer
    );

    if (status != kCMBlockBufferNoErr) {
        NSLog(@"CMBlockBuffer creation failed with status: %d", (int)status);
        return;
    }
    [self printFullData:data];
    // Create an audio format description.
    // This is an example format; adjust as necessary for your actual audio format.
    AudioStreamBasicDescription asbd = {0};
      asbd.mSampleRate = 44100;
      asbd.mFormatID = kAudioFormatLinearPCM; // 'lpcm' for linear PCM
      asbd.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
      asbd.mBytesPerPacket = 4;
      asbd.mFramesPerPacket = 1;
      asbd.mBytesPerFrame = 4;
      asbd.mChannelsPerFrame = 2;
      asbd.mBitsPerChannel = 16;
      asbd.mReserved = 0;
    CMAudioFormatDescriptionRef audioFormatDescription = NULL;
    status = CMAudioFormatDescriptionCreate(
        kCFAllocatorDefault,
        &asbd,
        4,
        NULL,
        0,
        NULL,
        NULL,
        &audioFormatDescription
    );

    if (status != noErr) {
        NSLog(@"CMAudioFormatDescription creation failed with status: %d", (int)status);
        CFRelease(blockBuffer);
        return;
    }

    // Number of samples
    CMItemCount numSamples = data.length / asbd.mBytesPerFrame;

    // Create sample timing info array
    CMSampleTimingInfo *timingInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo) * numSamples);
    if (timingInfo == NULL) {
        NSLog(@"Failed to allocate memory for timing info");
        CFRelease(blockBuffer);
        CFRelease(audioFormatDescription);
        return;
    }

    CMTime frameDuration = CMTimeMake(1, asbd.mSampleRate);
    CMTime startPresentationTime = CMTimeMakeWithSeconds(677495.289706/*+ self.numBufferReceive* 0.23213*/, asbd.mSampleRate); // Starting presentation timestamp

    // Increment for each sample
    CMTime incrementTime = CMTimeMakeWithSeconds(0.23213, asbd.mSampleRate);

    for (CMItemCount i = 0; i < numSamples; i++) {
        timingInfo[i].duration = frameDuration;
        timingInfo[i].presentationTimeStamp = CMTimeAdd(startPresentationTime, CMTimeMultiply(incrementTime, i));
        timingInfo[i].decodeTimeStamp = kCMTimeInvalid;
    }

    // Number of entries in the sampleSizeArray
    CMItemCount numSampleSizeEntries = 1;
    const size_t sampleSize = asbd.mBytesPerFrame;

    // Create a CMSampleBuffer with dataReady set to true
    CMSampleBufferRef sampleBuffer = NULL;
    status = CMSampleBufferCreate(
        kCFAllocatorDefault,
        blockBuffer,
        true, // dataReady is true
        NULL,
        NULL,
        audioFormatDescription,
        numSamples,
        numSamples, // Number of timing entries
        timingInfo,
        numSampleSizeEntries,
        &sampleSize,
        &sampleBuffer
    );
    free(timingInfo);
    CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
    if (CMTIME_IS_INVALID(duration)) {
        NSLog(@"Duration is invalid");
    } else {
        NSLog(@"Duration: %.2f seconds", CMTimeGetSeconds(duration));
    }

    // Get the presentation timestamp of the sample buffer
    CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    if (CMTIME_IS_INVALID(presentationTimeStamp)) {
        NSLog(@"Presentation timestamp is invalid");
    } else {
        NSLog(@"Presentation Timestamp: %.5f seconds", CMTimeGetSeconds(presentationTimeStamp));
    }

    // Get the decode timestamp of the sample buffer
    CMTime decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer);
    if (CMTIME_IS_INVALID(decodeTimeStamp)) {
        NSLog(@"Decode timestamp is invalid");
    } else {
        NSLog(@"Decode Timestamp: %.2f seconds", CMTimeGetSeconds(decodeTimeStamp));
    }

    if (status != noErr) {
        
        NSLog(@"CMSampleBuffer creation failed with status: %d", (int)status);
        CFRelease(blockBuffer);
        CFRelease(audioFormatDescription);
        return;
        
    }

    // Process the sample buffer as needed
    [self handleSampleBuffer:sampleBuffer];

    // Clean up
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
    CFRelease(audioFormatDescription);
}

- (void)handleSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // Handle the CMSampleBuffer (e.g., pass it to an encoder or another part of your pipeline)
    // This method should be implemented based on your specific requirements
    [self.audioDeviceModule deliverRecordedData:sampleBuffer ];
}
- (void)printFullData:(NSData *)data {
    const uint8_t *bytes = data.bytes;
    NSUInteger length = data.length;

    NSMutableString *hexString = [NSMutableString stringWithCapacity:length * 2];
    for (NSUInteger i = 0; i < length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }

    NSLog(@"Full data as hexadecimal: %@", hexString);
}
@end

@implementation AudioCapturer (NSStreamDelegate)

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            NSLog(@"audio stream open completed");
            break;
        case NSStreamEventHasBytesAvailable:
            
            [self readBytesFromStream:(NSInputStream *)aStream];
            
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"audio stream end encountered");
            [self stopCapture];
            [self.eventsDelegate capturerDidEnd:self];
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"audio stream error encountered: %@", aStream.streamError.localizedDescription);
            break;
        default:
            break;
    }
}

@end
