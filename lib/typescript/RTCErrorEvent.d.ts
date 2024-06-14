import { Event } from 'react-native-webrtc/node_modules/event-target-shim';
declare type RTCPeerConnectionErrorFunc = 'addTransceiver' | 'getTransceivers' | 'addTrack' | 'removeTrack';
/**
 * @brief This class Represents internal error happening on the native side as
 * part of asynchronous invocations to synchronous web APIs.
 */
export default class RTCErrorEvent<TEventType extends RTCPeerConnectionErrorFunc> extends Event<TEventType> {
    readonly func: RTCPeerConnectionErrorFunc;
    readonly message: string;
    constructor(type: TEventType, func: RTCPeerConnectionErrorFunc, message: string);
}
export { };
