import RTCRtcpParameters, { RTCRtcpParametersInit } from 'react-native-webrtc/lib/typescript/RTCRtcpParameters';
import RTCRtpCodecParameters, { RTCRtpCodecParametersInit } from 'react-native-webrtc/lib/typescript/RTCRtpCodecParameters';
import RTCRtpHeaderExtension, { RTCRtpHeaderExtensionInit } from 'react-native-webrtc/lib/typescript/RTCRtpHeaderExtension';
export interface RTCRtpParametersInit {
    codecs: RTCRtpCodecParametersInit[];
    headerExtensions: RTCRtpHeaderExtensionInit[];
    rtcp: RTCRtcpParametersInit;
}
export default class RTCRtpParameters {
    readonly codecs: RTCRtpCodecParameters[];
    readonly headerExtensions: RTCRtpHeaderExtension[];
    readonly rtcp: RTCRtcpParameters;
    constructor(init: RTCRtpParametersInit);
    toJSON(): RTCRtpParametersInit;
}
