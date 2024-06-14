import RTCRtpEncodingParameters, { RTCRtpEncodingParametersInit } from 'react-native-webrtc/lib/typescript/RTCRtpEncodingParameters';
import RTCRtpParameters, { RTCRtpParametersInit } from 'react-native-webrtc/lib/typescript/RTCRtpParameters';
declare type DegradationPreferenceType = 'maintain-framerate' | 'maintain-resolution' | 'balanced' | 'disabled';
export interface RTCRtpSendParametersInit extends RTCRtpParametersInit {
    transactionId: string;
    encodings: RTCRtpEncodingParametersInit[];
    degradationPreference?: string;
}
export default class RTCRtpSendParameters extends RTCRtpParameters {
    readonly transactionId: string;
    readonly encodings: RTCRtpEncodingParameters[];
    degradationPreference: DegradationPreferenceType | null;
    constructor(init: RTCRtpSendParametersInit);
    toJSON(): RTCRtpSendParametersInit;
}
export { };
