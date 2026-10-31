import { Config } from '@remotion/cli/config';

// Chất lượng xuất mặc định: H.264, CRF 18, ảnh khung JPEG chất lượng cao.
Config.setVideoImageFormat('jpeg');
Config.setJpegQuality(95);
Config.setCodec('h264');
Config.setCrf(18);
Config.setPixelFormat('yuv420p');
Config.setOverwriteOutput(true);
// Dùng Chromium có sẵn nếu biến môi trường được đặt (vd. môi trường cloud/CI).
if (process.env.REMOTION_BROWSER_EXECUTABLE) {
  Config.setBrowserExecutable(process.env.REMOTION_BROWSER_EXECUTABLE);
}
