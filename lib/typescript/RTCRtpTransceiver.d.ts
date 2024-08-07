import RTCRtpCodecCapability from 'react-native-webrtc/lib/typescript/RTCRtpCodecCapability';
import RTCRtpReceiver from 'react-native-webrtc/lib/typescript/RTCRtpReceiver';
import RTCRtpSender from 'react-native-webrtc/lib/typescript/RTCRtpSender';
export default class RTCRtpTransceiver {
    _peerConnectionId: number;
    _sender: RTCRtpSender;
    _receiver: RTCRtpReceiver;
    _mid: string | null;
    _direction: string;
    _currentDirection: string;
    _stopped: boolean;
    constructor(args: {
        peerConnectionId: number;
        isStopped: boolean;
        direction: string;
        currentDirection: string;
        mid?: string;
        sender: RTCRtpSender;
        receiver: RTCRtpReceiver;
    });
    get mid(): string | null;
    get stopped(): boolean;
    get direction(): string;
    set direction(val: string);
    get currentDirection(): string;
    get sender(): RTCRtpSender;
    get receiver(): RTCRtpReceiver;
    stop(): void;
    setCodecPreferences(codecs: RTCRtpCodecCapability[]): void;
    _setStopped(): void;
}
