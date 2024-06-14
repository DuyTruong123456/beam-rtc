import { NativeModules, Platform } from 'react-native';
const { WebRTCModule } = NativeModules;

if (WebRTCModule === null) {
    throw new Error(`WebRTC native module not found.\n${Platform.OS === 'ios' ?
        'Try executing the "pod install" command inside your projects ios folder.' :
        'Try executing the "npm install" command inside your projects folder.'
        }`);
}

import { setupNativeEvents } from 'react-native-webrtc/src/EventEmitter';
import Logger from 'react-native-webrtc/src/Logger';
import mediaDevices from 'react-native-webrtc/src/MediaDevices';
import MediaStream from 'react-native-webrtc/src/MediaStream';
import MediaStreamTrack from 'react-native-webrtc/src/MediaStreamTrack';
import MediaStreamTrackEvent from 'react-native-webrtc/src/MediaStreamTrackEvent';
import permissions from 'react-native-webrtc/src/Permissions';
import RTCErrorEvent from 'react-native-webrtc/src/RTCErrorEvent';
import RTCIceCandidate from 'react-native-webrtc/src/RTCIceCandidate';
import RTCPeerConnection from 'react-native-webrtc/src/RTCPeerConnection';
import RTCRtpReceiver from 'react-native-webrtc/src/RTCRtpReceiver';
import RTCRtpSender from 'react-native-webrtc/src/RTCRtpSender';
import RTCRtpTransceiver from 'react-native-webrtc/src/RTCRtpTransceiver';
import RTCSessionDescription from 'react-native-webrtc/src/RTCSessionDescription';
import RTCView from 'react-native-webrtc/src/RTCView';
import ScreenCapturePickerView from 'react-native-webrtc/src/ScreenCapturePickerView';

Logger.enable(`${Logger.ROOT_PREFIX}:*`);

// Add listeners for the native events early, since they are added asynchronously.
setupNativeEvents();

export {
    RTCIceCandidate,
    RTCPeerConnection,
    RTCSessionDescription,
    RTCView,
    ScreenCapturePickerView,
    RTCRtpTransceiver,
    RTCRtpReceiver,
    RTCRtpSender,
    RTCErrorEvent,
    MediaStream,
    MediaStreamTrack,
    mediaDevices,
    permissions,
    registerGlobals
};

declare const global: any;

function registerGlobals(): void {
    // Should not happen. React Native has a global navigator object.
    if (typeof global.navigator !== 'object') {
        throw new Error('navigator is not an object');
    }

    if (!global.navigator.mediaDevices) {
        global.navigator.mediaDevices = {};
    }

    global.navigator.mediaDevices.getUserMedia = mediaDevices.getUserMedia.bind(mediaDevices);
    global.navigator.mediaDevices.getDisplayMedia = mediaDevices.getDisplayMedia.bind(mediaDevices);
    global.navigator.mediaDevices.enumerateDevices = mediaDevices.enumerateDevices.bind(mediaDevices);

    global.RTCIceCandidate = RTCIceCandidate;
    global.RTCPeerConnection = RTCPeerConnection;
    global.RTCRtpReceiver = RTCRtpReceiver;
    global.RTCRtpSender = RTCRtpReceiver;
    global.RTCSessionDescription = RTCSessionDescription;
    global.MediaStream = MediaStream;
    global.MediaStreamTrack = MediaStreamTrack;
    global.MediaStreamTrackEvent = MediaStreamTrackEvent;
    global.RTCRtpTransceiver = RTCRtpTransceiver;
    global.RTCRtpReceiver = RTCRtpReceiver;
    global.RTCRtpSender = RTCRtpSender;
    global.RTCErrorEvent = RTCErrorEvent;
}
