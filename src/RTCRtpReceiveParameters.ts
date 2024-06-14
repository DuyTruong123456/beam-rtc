import RTCRtpParameters, { RTCRtpParametersInit } from 'react-native-webrtc/src/RTCRtpParameters';

export default class RTCRtpReceiveParameters extends RTCRtpParameters {
    constructor(init: RTCRtpParametersInit) {
        super(init);
    }
}
