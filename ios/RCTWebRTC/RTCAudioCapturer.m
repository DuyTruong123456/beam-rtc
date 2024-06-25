#import "RTCAudioCapturer.h"
#import <WebRTC/RTCAudioDeviceModule.h>
@implementation RTCAudioCapturer

@synthesize delegate = _delegate;

- (instancetype)initWithDelegate:(id<RTCAudioCapturerDelegate>)delegate
               audioDeviceModule:(RTCAudioDeviceModule *)audioDeviceModule {
  NSAssert(delegate != nil, @"delegate cannot be nil");
  if (self = [super init]) {
    _delegate = delegate;
  }
  return self;
}

@end
