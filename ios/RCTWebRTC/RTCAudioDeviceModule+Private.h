/*
 *  Copyright 2019 pixiv Inc. All Rights Reserved.
 *
 *  Use of this source code is governed by a license that can be
 *  found in the LICENSE.pixiv file in the root of the source tree.
 */

#import "RTCAudioDeviceModule.h"


#include "webrtc-87.0.4280.142-pixiv0 10-50-01-596.142-pixiv0/sdk/objc/native/src/audio/audio_device_module_ios.h"

NS_ASSUME_NONNULL_BEGIN

@interface RTCAudioDeviceModule ()

@property(nonatomic, readonly) rtc::scoped_refptr<webrtc::ios_adm::AudioDeviceModuleIOS>
    nativeModule;

@end

NS_ASSUME_NONNULL_END
#endif
