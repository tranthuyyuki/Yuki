import { Composition } from 'remotion';
import { PhotoSlideshow, slideshowDuration, type SlideshowProps } from './PhotoSlideshow';

const defaultProps: SlideshowProps = {
  title: 'Kỷ niệm',
  photos: ['photos/01.jpg', 'photos/02.jpg', 'photos/03.jpg'],
  secondsPerPhoto: 4,
  transitionSeconds: 1,
};

export const RemotionRoot: React.FC = () => (
  <Composition
    id="PhotoSlideshow"
    component={PhotoSlideshow}
    width={1080}
    height={1920}
    fps={30}
    durationInFrames={slideshowDuration(defaultProps, 30)}
    defaultProps={defaultProps}
    calculateMetadata={({ props }) => ({ durationInFrames: slideshowDuration(props, 30) })}
  />
);
