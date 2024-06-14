
import type MediaStreamError from 'react-native-webrtc/src/MediaStreamError';

export default class MediaStreamErrorEvent {
    type: string;
    error?: MediaStreamError;
    constructor(type, eventInitDict) {
        this.type = type.toString();
        Object.assign(this, eventInitDict);
    }
}
