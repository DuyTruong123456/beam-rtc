#import "AudioSocketConnection.h"
#include <sys/socket.h>
#include <sys/un.h>

@interface AudioSocketConnection () <NSStreamDelegate>

@property (nonatomic, assign) int serverSocket;
@property (nonatomic, strong) dispatch_source_t listeningSource;
@property (nonatomic, strong) NSThread *networkThread;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) RTCAudioSource *audioSource;
@property (nonatomic, strong) RTCPeerConnectionFactory *peerConnectionFactory;
@property (nonatomic, strong) RTCAudioTrack *audioTrack;
@property (nonatomic, assign) BOOL threadStarted;

@end
@implementation AudioSocketConnection {
    NSUInteger _readLength;
}

- (instancetype)initWithFilePath:(NSString *)filePath
                      identifier:(NSString *)identifier
           peerConnectionFactory:(RTCPeerConnectionFactory *)peerConnectionFactory {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _peerConnectionFactory = peerConnectionFactory;
        _threadStarted = NO;
        
        [self setupNetworkThread];
        
        self.serverSocket = socket(AF_UNIX, SOCK_STREAM, 0);
        if (self.serverSocket < 0) {
            NSLog(@"failure creating socket");
            return nil;
        }

        if (![self setupSocketWithFileAtPath:filePath]) {
            close(self.serverSocket);
            return nil;
        }

        self.audioSource = [self.peerConnectionFactory audioSourceWithConstraints:nil];
        self.audioTrack = [self.peerConnectionFactory audioTrackWithSource:self.audioSource trackId:identifier];
    }
    return self;
}

- (void)openWithStreamDelegate:(id<NSStreamDelegate>)streamDelegate {
    NSLog(@"openWithStream");
    int status = listen(self.serverSocket, 10);
    if (status < 0) {
        NSLog(@"failure: socket listening");
        return;
    }
    NSLog(@"openWithStream status",status);
    dispatch_source_t listeningSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, self.serverSocket, 0, NULL);
    dispatch_source_set_event_handler(listeningSource, ^{
        int clientSocket = accept(self.serverSocket, NULL, NULL);
        if (clientSocket < 0) {
            NSLog(@"failure accepting connection");
            return;
        }

        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;

        CFStreamCreatePairWithSocket(kCFAllocatorDefault, clientSocket, &readStream, &writeStream);

        self.inputStream = (__bridge_transfer NSInputStream *)readStream;
        self.inputStream.delegate = streamDelegate;
        [self.inputStream setProperty:@"kCFBooleanTrue" forKey:@"kCFStreamPropertyShouldCloseNativeSocket"];

        self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
        [self.outputStream setProperty:@"kCFBooleanTrue" forKey:@"kCFStreamPropertyShouldCloseNativeSocket"];

        if (!self.threadStarted) {
            [self.networkThread start];
            self.threadStarted = YES;
        }

        [self performSelector:@selector(scheduleStreams) onThread:self.networkThread withObject:nil waitUntilDone:true];

        [self.inputStream open];
        [self.outputStream open];
    });

    self.listeningSource = listeningSource;
    dispatch_resume(listeningSource);
}

- (void)close {
    [self stopStream];
}

- (void)stopStream {
    NSLog(@"[%@] Closing stream", self.identifier);
    [self performSelector:@selector(unscheduleStreams) onThread:self.networkThread withObject:nil waitUntilDone:true];

    self.inputStream.delegate = nil;
    self.outputStream.delegate = nil;

    [self.inputStream close];
    [self.outputStream close];

    [self.networkThread cancel];

    dispatch_source_cancel(self.listeningSource);
    close(self.serverSocket);
}
- (void)readBytesFromStream:(NSInputStream *)stream {
  //  NSLog(@"readbytes");
    if (!stream.hasBytesAvailable) {
       // NSLog(@"nobytes");
        return;
    }

    uint8_t buffer[_readLength];
    NSInteger numberOfBytesRead = [stream read:buffer maxLength:_readLength];
    if (numberOfBytesRead < 0) {
      //  NSLog(@"error reading bytes from stream");
        return;
    }
}

- (void)didCaptureAudioData:(NSData *)audioData {
    // Handle captured audio data here
    //NSLog(@"Received audio data of length: %lu", (unsigned long)audioData.length);
    // Example: Send audioData to processing or playback components
}
- (void)sendData:(NSData *)data {
    NSInteger bytesWritten = [self.outputStream write:data.bytes maxLength:data.length];
    if (bytesWritten < 0) {
       // NSLog(@"Failed to write data to output stream");
    }
}

// MARK: - Private Methods

- (void)setupNetworkThread {
    self.networkThread = [[NSThread alloc] initWithBlock:^{
        do {
            @autoreleasepool {
                [[NSRunLoop currentRunLoop] run];
            }
        } while (![NSThread currentThread].isCancelled);
    }];
    self.networkThread.qualityOfService = NSQualityOfServiceUserInitiated;
}

- (BOOL)setupSocketWithFileAtPath:(NSString *)filePath {
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;

    if (filePath.length > sizeof(addr.sun_path)) {
      //  NSLog(@"failure: path too long");
        return false;
    }

    unlink(filePath.UTF8String);
    strncpy(addr.sun_path, filePath.UTF8String, sizeof(addr.sun_path) - 1);

    int status = bind(self.serverSocket, (struct sockaddr *)&addr, sizeof(addr));
    if (status < 0) {
       // NSLog(@"failure: socket binding");
        return false;
    }

    return true;
}

- (void)scheduleStreams {
    [self.inputStream scheduleInRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
    [self.outputStream scheduleInRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
}

- (void)unscheduleStreams {
    [self.inputStream removeFromRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
    [self.outputStream removeFromRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
}
// MARK: - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
          //  NSLog(@"[%@] Stream opened", self.identifier);
            break;
        case NSStreamEventHasBytesAvailable:
          [self readBytesFromStream:(NSInputStream *)aStream];
            if (aStream == self.inputStream) {
                uint8_t buffer[1024];
                NSInteger len;
                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        NSData *data = [NSData dataWithBytes:buffer length:len];
                       // NSLog(@"[%@] Received data: %@", self.identifier, data);
                        // Process the received data as needed
                    }
                }
            }
            break;
        case NSStreamEventErrorOccurred:
         //   NSLog(@"[%@] Stream error: %@", self.identifier, aStream.streamError);
            break;
        case NSStreamEventEndEncountered:
         //   NSLog(@"[%@] Stream end encountered", self.identifier);
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:kCFRunLoopDefaultMode];
            break;
        default:
            break;
    }
}
@end
