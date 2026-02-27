import React from 'react';
import { IIIFPlayer, MediaPlayer } from '@samvera/ramp';
import 'video.js/dist/video-js.css';
import '@samvera/ramp/dist/ramp.css';

const RampPlayer = ({ manifestUrl }) => {
  return (
    <IIIFPlayer manifestUrl={manifestUrl}>
      <MediaPlayer enableFileDownload={false} />
    </IIIFPlayer>
  );
};

export default RampPlayer;
