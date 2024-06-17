#import "AudioCapturer.h"
#import "AudioSocketConnection.h"
#import <WebRTC/RTCAudioTrack.h>

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

- (instancetype)initWithDelegate:(id<CapturerEventsDelegate>)delegate {
    self = [super init];
    if (self) {
        _eventsDelegate = delegate;
        _audioQueue = dispatch_queue_create("audioQueue", DISPATCH_QUEUE_SERIAL);
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
        return;
    }
    
    if (!self.message) {
        self.message = [[AudioMessage alloc] init];
        _readLength = kMaxAudioReadLength;

        __weak __typeof__(self) weakSelf = self;
        self.message.didComplete = ^(BOOL success, AudioMessage *message) {
            if (success) {
                [weakSelf didCaptureAudioData:message.audioData];
            }

            weakSelf.message = nil;
        };
    }

    uint8_t buffer[_readLength];
    NSInteger numberOfBytesRead = [stream read:buffer maxLength:_readLength];
    if (numberOfBytesRead < 0) {
        NSLog(@"error reading bytes from stream");
        return;
    }

    _readLength = [self.message appendBytes:buffer length:numberOfBytesRead];
    if (_readLength == -1 || _readLength > kMaxAudioReadLength) {
        _readLength = kMaxAudioReadLength;
    }
}

- (void)didCaptureAudioData:(NSData *)audioData {
    // Handle the captured audio data
    // For example, you can create an RTCAudioTrack from the audio data and pass it to the delegate

    // Sample code (assuming you have a method to create an RTCAudioTrack from NSData):
    // RTCAudioTrack *audioTrack = [self createAudioTrackFromData:audioData];
    // [self.delegate capturer:self didCaptureAudioTrack:audioTrack];
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
