import { Event } from 'react-native-webrtc/node_modules/event-target-shim';
import MediaStream from 'react-native-webrtc/lib/typescript/MediaStream';
import type MediaStreamTrack from 'react-native-webrtc/lib/typescript/MediaStreamTrack';
import RTCRtpReceiver from 'react-native-webrtc/lib/typescript/RTCRtpReceiver';
import RTCRtpTransceiver from 'react-native-webrtc/lib/typescript/RTCRtpTransceiver';
declare type TRACK_EVENTS = 'track';
interface IRTCTrackEventInitDict extends Event.EventInit {
    streams: MediaStream[];
    transceiver: RTCRtpTransceiver;
}
/**
 * @eventClass
 * This event is fired whenever the Track is changed in PeerConnection.
 * @param {TRACK_EVENTS} type - The type of event.
 * @param {IRTCTrackEventInitDict} eventInitDict - The event init properties.
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/RTCPeerConnection/track_event MDN} for details.
 */
export default class RTCTrackEvent<TEventType extends TRACK_EVENTS> extends Event<TEventType> {
    /** @eventProperty */
    readonly streams: MediaStream[];
    /** @eventProperty */
    readonly transceiver: RTCRtpTransceiver;
    /** @eventProperty */
    readonly receiver: RTCRtpReceiver | null;
    /** @eventProperty */
    readonly track: MediaStreamTrack | null;
    constructor(type: TEventType, eventInitDict: IRTCTrackEventInitDict);
}
export { };
