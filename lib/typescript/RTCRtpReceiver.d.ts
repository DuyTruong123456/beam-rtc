import MediaStreamTrack from 'react-native-webrtc/lib/typescript/MediaStreamTrack';
import RTCRtpCapabilities from 'react-native-webrtc/lib/typescript/RTCRtpCapabilities';
import { RTCRtpParametersInit } from 'react-native-webrtc/lib/typescript/RTCRtpParameters';
import RTCRtpReceiveParameters from 'react-native-webrtc/lib/typescript/RTCRtpReceiveParameters';
export default class RTCRtpReceiver {
    _id: string;
    _peerConnectionId: number;
    _track: MediaStreamTrack | null;
    _rtpParameters: RTCRtpReceiveParameters;
    constructor(info: {
        peerConnectionId: number;
        id: string;
        track?: MediaStreamTrack;
        rtpParameters: RTCRtpParametersInit;
    });
    static getCapabilities(kind: 'audio' | 'video'): RTCRtpCapabilities;
    getStats(): any;
    getParameters(): RTCRtpReceiveParameters;
    get id(): string;
    get track(): MediaStreamTrack | null;
}
