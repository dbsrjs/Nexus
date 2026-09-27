import sharp from 'sharp';
import { AVATAR_EDGE, AvatarImageError, processAvatar } from './avatar-image';

/** 왼쪽 절반은 빨강, 오른쪽 절반은 파랑인 PNG. */
async function halves(width: number, height: number): Promise<Buffer> {
  const half = Math.floor(width / 2);
  const raw = Buffer.alloc(width * height * 3);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 3;
      if (x < half) raw[i] = 255;
      else raw[i + 2] = 255;
    }
  }
  return sharp(raw, { raw: { width, height, channels: 3 } }).png().toBuffer();
}

describe('processAvatar', () => {
  it('★ 결과는 256×256 WebP 다', async () => {
    const out = await processAvatar(await halves(600, 300));
    const meta = await sharp(out).metadata();
    expect(meta.format).toBe('webp');
    expect(meta.width).toBe(AVATAR_EDGE);
    expect(meta.height).toBe(AVATAR_EDGE);
  });

  it('★ 가로로 긴 사진은 늘이지 않고 가운데를 자른다', async () => {
    // 600×200 을 세 칸(빨강 · 초록 · 파랑)으로 나눈다. 가운데 정사각형이 곧
    // 초록 칸이다 — 잘랐으면 왼쪽 가장자리도 초록, 늘였으면 빨강이다.
    const width = 600;
    const height = 200;
    const raw = Buffer.alloc(width * height * 3);
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        raw[(y * width + x) * 3 + Math.floor(x / 200)] = 255;
      }
    }
    const png = await sharp(raw, { raw: { width, height, channels: 3 } }).png().toBuffer();
    const out = await processAvatar(png);
    const { data, info } = await sharp(out).raw().toBuffer({ resolveWithObject: true });
    const left = (128 * info.width + 5) * info.channels;
    expect(data[left]).toBeLessThan(60); // 빨강 없음
    expect(data[left + 1]).toBeGreaterThan(200); // 초록
  });

  it('작은 사진은 256 으로 키운다 - 자리마다 크기가 달라지지 않게', async () => {
    const tiny = await sharp({
      create: { width: 1, height: 1, channels: 3, background: '#00ff00' },
    })
      .jpeg()
      .toBuffer();
    const meta = await sharp(await processAvatar(tiny)).metadata();
    expect(meta.width).toBe(AVATAR_EDGE);
  });

  it('투명 PNG 도 받는다', async () => {
    const clear = await sharp({
      create: { width: 50, height: 50, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
    })
      .png()
      .toBuffer();
    await expect(processAvatar(clear)).resolves.toBeInstanceOf(Buffer);
  });

  it('GIF 는 첫 프레임을 쓴다', async () => {
    const gif = await sharp({
      create: { width: 40, height: 40, channels: 3, background: '#0000ff' },
    })
      .gif()
      .toBuffer();
    const meta = await sharp(await processAvatar(gif)).metadata();
    expect(meta.pages ?? 1).toBe(1);
  });

  it('★ 이미지가 아니면 AvatarImageError 다 - 확장자만 바꾼 파일을 거른다', async () => {
    await expect(processAvatar(Buffer.from('이건 그림이 아니다'))).rejects.toBeInstanceOf(
      AvatarImageError,
    );
  });
});
