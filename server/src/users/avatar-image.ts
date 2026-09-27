import sharp from 'sharp';

/**
 * 아바타 한 변. 쓰이는 가장 큰 자리가 설정 창 미리보기(96px)라, 고밀도
 * 화면(×2 · ×2.5)까지 256 이면 넉넉하다 (14단계 설계 D7).
 */
export const AVATAR_EDGE = 256;

/** 올릴 수 있는 원본 크기. 가공 뒤에는 수십 KB 가 된다. */
export const MAX_AVATAR_BYTES = 5 * 1024 * 1024;

export const AVATAR_MIME = 'image/webp';

/** 받은 바이트가 그림이 아니다. 컨트롤러가 400 으로 바꾼다. */
export class AvatarImageError extends Error {
  constructor() {
    super('이미지 파일만 올릴 수 있습니다');
    this.name = 'AvatarImageError';
  }
}

/**
 * 올린 사진을 256×256 WebP 로 바꾼다. **원본은 남기지 않는다** — 쓸 곳이 없다.
 *
 * - `rotate()` 는 EXIF 방향대로 세운다. 휴대폰 사진이 눕지 않게
 * - `cover` + 가운데 — 늘이지 않고 가운데를 자른다. 자르기 화면은 두지 않았다(설계 §4)
 * - `animated: false` — GIF 는 첫 프레임만. 움직이는 아바타는 목록을 산만하게 한다
 *
 * **mime 을 믿지 않는다.** 확장자만 바꾼 파일은 sharp 가 읽지 못해 여기서 걸린다.
 */
export async function processAvatar(input: Buffer): Promise<Buffer> {
  try {
    return await sharp(input, { animated: false })
      .rotate()
      .resize(AVATAR_EDGE, AVATAR_EDGE, { fit: 'cover', position: 'centre' })
      .webp({ quality: 85 })
      .toBuffer();
  } catch {
    throw new AvatarImageError();
  }
}
