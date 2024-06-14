import { EventTarget, Event } from 'react-native-webrtc/node_modules/event-target-shim';
declare type MediaDevicesEventMap = {
    devicechange: Event<'devicechange'>;
};
declare class MediaDevices extends EventTarget<MediaDevicesEventMap> {
    /**
     * W3C "Media Capture and Streams" compatible {@code enumerateDevices}
     * implementation.
     */
    enumerateDevices(): Promise<unknown>;
    /**
     * W3C "Screen Capture" compatible {@code getDisplayMedia} implementation.
     * See: https://w3c.github.io/mediacapture-screen-share/
     *
     * @returns {Promise}
     */
    getDisplayMedia(): Promise<import("react-native-webrtc/lib/typescript/MediaStream").default>;
    /**
     * W3C "Media Capture and Streams" compatible {@code getUserMedia}
     * implementation.
     * See: https://www.w3.org/TR/mediacapture-streams/#dom-mediadevices-enumeratedevices
     *
     * @param {*} constraints
     * @returns {Promise}
     */
    getUserMedia(constraints: any): Promise<import("react-native-webrtc/lib/typescript/MediaStream").default>;
}
declare const _default: MediaDevices;
export default _default;
