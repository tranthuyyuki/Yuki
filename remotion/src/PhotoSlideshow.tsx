import { AbsoluteFill, Img, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig } from 'remotion';

export type SlideshowProps = {
  title: string;
  photos: string[];          // đường dẫn trong thư mục public/
  secondsPerPhoto: number;
  transitionSeconds: number;
};

export const slideshowDuration = (p: SlideshowProps, fps: number) =>
  Math.round((p.photos.length * p.secondsPerPhoto - (p.photos.length - 1) * p.transitionSeconds) * fps);

// Một ảnh: zoom chậm (Ken Burns) + mờ dần vào/ra để tạo chuyển cảnh chồng lên nhau.
const Slide: React.FC<{ src: string; frames: number; fade: number; index: number }> = ({ src, frames, fade, index }) => {
  const f = useCurrentFrame();
  const opacity = interpolate(f, [0, fade, frames - fade, frames], [index === 0 ? 1 : 0, 1, 1, 0], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });
  const scale = interpolate(f, [0, frames], [1, 1.12]);
  return (
    <AbsoluteFill style={{ opacity }}>
      <Img src={staticFile(src)} style={{ width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${scale})` }} />
    </AbsoluteFill>
  );
};

export const PhotoSlideshow: React.FC<SlideshowProps> = ({ title, photos, secondsPerPhoto, transitionSeconds }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const per = secondsPerPhoto * fps;
  const fade = transitionSeconds * fps;
  const step = per - fade;

  const titleIn = spring({ frame: frame - 10, fps, config: { damping: 200 } });
  const titleOut = interpolate(frame, [3 * fps, 4 * fps], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const fadeOut = interpolate(frame, [durationInFrames - fps, durationInFrames], [1, 0], { extrapolateLeft: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: 'black', opacity: fadeOut }}>
      {photos.map((src, i) => (
        <Sequence key={src} from={i * step} durationInFrames={per}>
          <Slide src={src} frames={per} fade={fade} index={i} />
        </Sequence>
      ))}
      <AbsoluteFill style={{ justifyContent: 'flex-start', alignItems: 'center', paddingTop: 230 }}>
        <h1 style={{
          margin: 0, color: 'white', fontFamily: 'DejaVu Sans, sans-serif', fontSize: 84, fontWeight: 700,
          textShadow: '0 4px 16px rgba(0,0,0,.6)',
          opacity: titleIn * titleOut, transform: `translateY(${(1 - titleIn) * 40}px)`,
        }}>{title}</h1>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
