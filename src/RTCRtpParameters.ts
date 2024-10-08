import RTCRtcpParameters, { RTCRtcpParametersInit } from 'react-native-webrtc/src/RTCRtcpParameters';
import RTCRtpCodecParameters, { RTCRtpCodecParametersInit } from 'react-native-webrtc/src/RTCRtpCodecParameters';
import RTCRtpHeaderExtension, { RTCRtpHeaderExtensionInit } from 'react-native-webrtc/src/RTCRtpHeaderExtension';


export interface RTCRtpParametersInit {
    codecs: RTCRtpCodecParametersInit[],
    headerExtensions: RTCRtpHeaderExtensionInit[],
    rtcp: RTCRtcpParametersInit
}

export default class RTCRtpParameters {
    readonly codecs: RTCRtpCodecParameters[] = [];
    readonly headerExtensions: RTCRtpHeaderExtension[] = [];
    readonly rtcp: RTCRtcpParameters;

    constructor(init: RTCRtpParametersInit) {
        for (const codec of init.codecs) {
            this.codecs.push(new RTCRtpCodecParameters(codec));
        }

        for (const ext of init.headerExtensions) {
            this.headerExtensions.push(new RTCRtpHeaderExtension(ext));
        }

        this.rtcp = new RTCRtcpParameters(init.rtcp);
    }

    toJSON(): RTCRtpParametersInit {
        return {
            codecs: this.codecs.map(c => c.toJSON()),
            headerExtensions: this.headerExtensions.map(he => he.toJSON()),
            rtcp: this.rtcp.toJSON()
        };
    }
}
