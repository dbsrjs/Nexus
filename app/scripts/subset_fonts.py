"""app/assets/fonts 의 서체를 만든다. 원본 서체를 고치면 이 스크립트로 다시 뽑는다.

    python3 -m pip install fonttools
    python3 app/scripts/subset_fonts.py <Pretendard static/alternative 폴더> <JetBrainsMono fonts/ttf 폴더>

원본: Pretendard 1.3.9(npm `pretendard`, dist/public/static/alternative/*.ttf),
JetBrains Mono 2.304(GitHub 릴리스 zip, fonts/ttf/*.ttf). 둘 다 OFL-1.1.

왜 자르는가: Pretendard 한 굵기가 2.7MB 다(대부분 한글 11,172자). 웹은 첫 화면 전에
이것을 받아야 하므로 KS X 1001 완성형 2,350자 + 라틴 · 기호로 줄여 굵기당 0.54MB 로 둔다.
목록 밖 음절(똠 · 쌰 같은 드문 글자)은 OS 대체 서체로 그려진다 — 깨지지는 않는다.
"""

import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / 'assets' / 'fonts'

# 한글 자모(입력 중 조합 표시) · 라틴 · 일반 문장 부호 · 화살표 · 도형(▾ ·) · 원 문자 등.
UNICODES = ','.join([
    'U+0020-007E', 'U+00A0-00FF', 'U+0131', 'U+0152-0153', 'U+02C6', 'U+02DA', 'U+02DC',
    'U+2000-206F', 'U+20A9', 'U+20AC', 'U+2100-215F', 'U+2190-21FF', 'U+2200-22FF',
    'U+2460-24FF', 'U+2500-25FF', 'U+2600-26FF', 'U+2700-27BF', 'U+3000-303F',
    'U+3131-318E', 'U+FF01-FF5E',
])

# 앱이 쓰는 굵기만 싣는다 — 400 · 600 · 700. 500 은 Flutter 가 가까운 400 으로 그린다.
PRETENDARD = ['Regular', 'SemiBold', 'Bold']
MONO = ['Regular', 'SemiBold']


def ksx1001_hangul() -> str:
    chars = []
    for hi in range(0xB0, 0xC9):
        for lo in range(0xA1, 0xFF):
            try:
                c = bytes([hi, lo]).decode('euc-kr')
            except UnicodeDecodeError:
                continue
            if 0xAC00 <= ord(c) <= 0xD7A3:
                chars.append(c)
    return ''.join(sorted(set(chars)))


def main() -> None:
    pretendard_dir, mono_dir = Path(sys.argv[1]), Path(sys.argv[2])
    text = OUT / '.hangul.txt'
    text.write_text(ksx1001_hangul(), encoding='utf-8')
    try:
        for w in PRETENDARD:
            subprocess.run([
                'pyftsubset', str(pretendard_dir / f'Pretendard-{w}.ttf'),
                f'--text-file={text}', f'--unicodes={UNICODES}',
                '--layout-features=*', f'--output-file={OUT / f"Pretendard-{w}.ttf"}',
            ], check=True)
    finally:
        text.unlink()
    # 코드용 모노는 자르지 않는다(0.2MB). 합자 없는 NL 판 — 코드에서 `!=` 가 ≠ 로 바뀌면 읽는 사람이 헷갈린다.
    for w in MONO:
        (OUT / f'JetBrainsMonoNL-{w}.ttf').write_bytes(
            (mono_dir / f'JetBrainsMonoNL-{w}.ttf').read_bytes())


if __name__ == '__main__':
    main()
