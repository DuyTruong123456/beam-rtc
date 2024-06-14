
import { NativeModules } from 'react-native';

import MediaStream from 'react-native-webrtc/src/MediaStream';
import MediaStreamError from 'react-native-webrtc/src/MediaStreamError';

const { WebRTCModule } = NativeModules;

export default function getDisplayMedia(): Promise<MediaStream> {
    return new Promise((resolve, reject) => {
        WebRTCModule.getDisplayMedia().then(
            data => {
                const { streamId, track } = data;
                console.log('display track', JSON.stringify(track, null, 2))
                const info = {
                    streamId: streamId,
                    streamReactTag: streamId,
                    tracks: track
                };

                const stream = new MediaStream(info);

                resolve(stream);
            },
            error => {
                reject(new MediaStreamError(error));
            }
        );
    });
}
