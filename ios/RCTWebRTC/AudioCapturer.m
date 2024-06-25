#import "AudioCapturer.h"
#import "AudioSocketConnection.h"
#import <WebRTC/RTCAudioTrack.h>
#import "RTCAudioCapturer.h"
const NSUInteger kMaxAudioReadLength = 10 * 1024;

@interface AudioMessage : NSObject

@property(nonatomic, strong) NSData *audioData;
@property(nonatomic, copy, nullable) void (^didComplete)(BOOL success, AudioMessage *message);

- (NSInteger)appendBytes:(UInt8 *)buffer length:(NSUInteger)length;

@end

@interface AudioMessage ()

@property(nonatomic, assign) CFHTTPMessageRef framedMessage;

@end

@implementation AudioMessage

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioData = [NSData data];
    }
    return self;
}

- (void)dealloc {
    if (_framedMessage) {
        CFRelease(_framedMessage);
    }
}

- (NSInteger)appendBytes:(UInt8 *)buffer length:(NSUInteger)length {
    if (!_framedMessage) {
        _framedMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, false);
    }
 
    CFHTTPMessageAppendBytes(_framedMessage, buffer, length);
    if (!CFHTTPMessageIsHeaderComplete(_framedMessage)) {
        return -1;
    }

    NSInteger contentLength =
        [CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(_framedMessage, (__bridge CFStringRef) @"Content-Length"))
            integerValue];
    NSInteger bodyLength = (NSInteger)[CFBridgingRelease(CFHTTPMessageCopyBody(_framedMessage)) length];

    NSInteger missingBytesCount = contentLength - bodyLength;
    if (missingBytesCount == 0) {
        BOOL success = [self unwrapMessage:self.framedMessage];
        self.didComplete(success, self);

        CFRelease(self.framedMessage);
        self.framedMessage = NULL;
    }

    return missingBytesCount;
}

- (BOOL)unwrapMessage:(CFHTTPMessageRef)framedMessage {
    NSData *messageData = CFBridgingRelease(CFHTTPMessageCopyBody(_framedMessage));
    self.audioData = messageData;
    return true;
}

@end

@interface AudioCapturer () <NSStreamDelegate>

@property(nonatomic, strong) dispatch_queue_t audioQueue;
@property(nonatomic, assign) BOOL isCapturing;
@property(nonatomic, strong) AudioSocketConnection *connection;
@property(nonatomic, strong) AudioMessage *message;

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
    self.message = nil;
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
   
    // Find the start of relevant audio data
    NSData *audioData = [self findAudioDataInBuffer:buffer length:numberOfBytesRead];
    
    if (!audioData) {
        NSLog(@"No audio data pattern found in the buffer. Using all bytes for processing.");
        audioData = [NSData dataWithBytes:buffer length:numberOfBytesRead];
    }

    // Process the audio data
    if (!self.message) {
        self.message = [[AudioMessage alloc] init];
        _readLength = kMaxAudioReadLength;

        __weak __typeof__(self) weakSelf = self;
        self.message.didComplete = ^(BOOL success, AudioMessage *message) {
            if (success) {
                [weakSelf didCaptureAudioData:message.audioData];
                NSLog(@"Audio data captured successfully.");
            } else {
                NSLog(@"Failed to capture audio data.");
            }

            weakSelf.message = nil;
        };
    }

    [self processAudioData:audioData];
    NSLog(@"Read %ld bytes from stream.", (long)numberOfBytesRead);
    NSLog(@"Buffer as NSData: %@", audioData);

    _readLength = [self.message appendBytes:buffer length:numberOfBytesRead];
    if (_readLength == -1) {
        NSLog(@"Not enough bytes were provided to compute the message length.");
    } else if (_readLength > kMaxAudioReadLength) {
        _readLength = kMaxAudioReadLength;
    }

    NSLog(@"Remaining bytes to read: %ld", (long)_readLength);
}

- (NSData *)findAudioDataInBuffer:(uint8_t *)buffer length:(NSInteger)length {
    // Convert buffer to NSData for easier manipulation
    NSData *data = [NSData dataWithBytes:buffer length:length];

    // Ensure that the range is within bounds
    if (length > 32) {
        return [data subdataWithRange:NSMakeRange(32, length - 32)];
    } else {
        // Handle the case where the buffer is too small
        NSLog(@"Error: Buffer size is less than 32 bytes");
        return nil; // Or handle error accordingly
    }
}










- (BOOL)isSilentAudioData:(NSData *)data {
    const uint8_t *bytes = data.bytes;
    NSUInteger length = data.length;

    // Define a threshold for what constitutes silence based on your audio format
    // Example: Consider data as silent if most bytes are within a small range
    int silentThreshold = 10; // Adjust as needed based on your data characteristics

    // Count the number of bytes close to zero
    NSUInteger silentCount = 0;
    for (NSUInteger i = 0; i < length; i++) {
        if (bytes[i] < silentThreshold) { // Adjust this condition based on your audio data format
            silentCount++;
        }
    }

    // Determine if the data is silent based on the proportion of silent bytes
    double silentRatio = (double)silentCount / (double)length;
    if (silentRatio > 0.95) { // Adjust the threshold (0.95) based on your data analysis
        return YES; // Data is mostly silent or empty
    } else {
        return NO; // Data contains significant non-silent content
    }
}



- (void)didCaptureAudioData:(NSData *)audioData {
    // Handle the captured audio data
    // For example, you can create an RTCAudioTrack from the audio data and pass it to the delegate
    // Sample code (assuming you have a method to create an RTCAudioTrack from NSData):
    // RTCAudioTrack *audioTrack = [self createAudioTrackFromData:audioData];
    [self.delegate setVolume:10];
}

- (void)processAudioData:(NSData *)data {
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
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mBytesPerPacket = 2;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 2;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel = 16;
    asbd.mReserved = 0;
    
    CMAudioFormatDescriptionRef audioFormatDescription = NULL;
    status = CMAudioFormatDescriptionCreate(
        kCFAllocatorDefault,
        &asbd,
        0,
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

    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = { data.length };
    status = CMSampleBufferCreate(
        kCFAllocatorDefault,
        blockBuffer,
        true,
        NULL,
        NULL,
        audioFormatDescription,
        data.length / asbd.mBytesPerFrame,
        0,
        NULL,
        1,
        sampleSizeArray,
        &sampleBuffer
    );

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
