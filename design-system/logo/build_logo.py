#!/usr/bin/env python3
"""
Nexus 로고 자산 생성기.

**이 스크립트가 로고의 유일한 원본이다.** 브랜드 제안서(2026-08-31)의 «2D Flat
Minimalist Vector System» 을 기하로 옮겨 두고, 필요한 모든 크기를 여기서 뽑는다.
PNG 를 손으로 그려 저장소에 넣으면 크기마다 미세하게 갈라지고, 나중에 형태를
고칠 때 어느 것이 맞는지 알 수 없게 된다.

**왜 새 의존성을 들이지 않았나** — 이 프로젝트는 마크다운 파서 · 신택스
하이라이터 · 번다운 차트를 전부 직접 만들어 패키지를 거절해 왔다. 로고도
같다. 마크가 직선 셋과 원 하나라 Pillow 의 폴리곤만으로 충분하다.

**3D 모놀리스는 여기서 만들지 않는다.** 제안서의 메인 심볼(CNC 티타늄
모놀리스)은 발표 자료용이고, 제안서 자신이 아이콘 · 파비콘 자리에는 2D 플랫을
쓰라고 갈라 두었다. 작은 크기에서 3D 페셋은 뭉개져 읽히지 않는다.

실행:
    python design-system/logo/build_logo.py
"""
from __future__ import annotations

import math
import os
from PIL import Image, ImageDraw

# ── 좌표계 ────────────────────────────────────────────
# 모든 기하를 1000×1000 단위로 적어 두고 마지막에 원하는 크기로 줄인다.
# 크기마다 좌표를 다시 잡으면 그때부터 형태가 갈라진다.
ART = 1000

# **8배로 그린 뒤 줄인다.** Pillow 의 폴리곤에는 안티에일리어싱이 없어,
# 그대로 그리면 대각선과 원의 가장자리가 계단이 된다.
SS = 8

# ── 색 ────────────────────────────────────────────────
# 제안서 §6 «Material System» 을 그대로 쓴다. 앱 테마 토큰(#121314 계열)과
# 다른 값이지만 **토큰을 고치지 않는다** — 아이콘은 OS 런처와 브라우저 탭에
# 놓이는 것이라 앱 배경이 아니라 그 바깥 환경을 상대한다.
SPACE_BLACK = (0, 0, 0, 255)        # #000000  타일 바탕
PURE_STEEL = (255, 255, 255, 255)   # #FFFFFF  N 획
TITANIUM_GREY = (134, 134, 139, 255)  # #86868B 중앙 노드

# ── 마크 기하 ─────────────────────────────────────────
# 'N' 은 획 셋이다: 왼쪽 세로 · 대각 · 오른쪽 세로. 모두 둥근 끝(round cap).
N_TOP, N_BOTTOM = 268.0, 732.0
# 폭:높이 = 0.78. 제안서 시안의 비례다 — 더 좁히면 'N' 이 아니라 'M' 처럼
# 대각이 서고, 더 넓히면 타일 안에서 답답해진다.
N_LEFT, N_RIGHT = 320.0, 680.0
# 획 두께는 N 높이의 12% 다. 더 가늘면 16px 파비콘에서 사라지고, 더 굵으면
# 대각과 세로가 붙어 'N' 이 아니라 덩어리로 보인다.
STROKE = (N_BOTTOM - N_TOP) * 0.12

# 중앙 넥서스 코어. 제안서가 말하는 «4대 개발 요소가 응축된 노드» 다.
NODE_RADIUS = STROKE * 0.34

# **작은 크기에서는 노드를 그리지 않는다.** 16px 파비콘에서 이 점은 흰 획
# 위의 회색 픽셀 한둘이 되어 노드가 아니라 잡티로 읽힌다. 제안서의 파비콘
# 시안도 'N' 만 있다. 64px 부터 그린다.
NODE_MIN_SIZE = 64

# 타일(앱 아이콘) 모서리 반경. 안드로이드 · 윈도우가 각자 마스킹을 하므로
# 우리가 그리는 값은 «마스킹이 없을 때 보이는 모양» 이다.
TILE_RADIUS_RATIO = 0.225


def _round_stroke(draw: ImageDraw.ImageDraw, a, b, width, fill) -> None:
    """둥근 끝을 가진 선 하나. Pillow 의 line 은 끝을 잘라 놓으므로 원을 얹는다."""
    draw.line([a, b], fill=fill, width=int(round(width)))
    r = width / 2.0
    for (x, y) in (a, b):
        draw.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def draw_mark(size: int, stroke_color=PURE_STEEL, node_color=TITANIUM_GREY) -> Image.Image:
    """'N' 마크만. 배경은 투명하다 — 타일 위에도, 앱 화면 위에도 얹는다."""
    canvas = Image.new('RGBA', (ART * SS, ART * SS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    k = SS  # 1000 단위 → 실제 픽셀

    left_top = (N_LEFT * k, N_TOP * k)
    left_bottom = (N_LEFT * k, N_BOTTOM * k)
    right_top = (N_RIGHT * k, N_TOP * k)
    right_bottom = (N_RIGHT * k, N_BOTTOM * k)

    # 대각을 먼저 그린다. 세로 획이 그 위에 얹혀야 끝이 깔끔하게 덮인다.
    _round_stroke(draw, left_top, right_bottom, STROKE * k, stroke_color)
    _round_stroke(draw, left_top, left_bottom, STROKE * k, stroke_color)
    _round_stroke(draw, right_top, right_bottom, STROKE * k, stroke_color)

    if size >= NODE_MIN_SIZE:
        cx = cy = (ART / 2.0) * k
        r = NODE_RADIUS * k
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=node_color)

    return canvas.resize((size, size), Image.LANCZOS)


def draw_tile(size: int, radius_ratio: float = TILE_RADIUS_RATIO) -> Image.Image:
    """앱 아이콘. 검은 라운드 타일 위에 마크를 얹는다."""
    big = size * 4
    tile = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(tile).rounded_rectangle(
        [0, 0, big - 1, big - 1],
        radius=int(big * radius_ratio),
        fill=SPACE_BLACK,
    )
    tile = tile.resize((size, size), Image.LANCZOS)
    tile.alpha_composite(draw_mark(size))
    return tile


def draw_square(size: int) -> Image.Image:
    """모서리를 깎지 않은 정사각 타일. 마스킹을 스스로 하는 곳에 쓴다
    (안드로이드 적응형 · PWA maskable). 라운드를 두 번 먹으면 모서리가 파인다."""
    tile = Image.new('RGBA', (size, size), SPACE_BLACK)
    # maskable 은 바깥 20% 가 잘릴 수 있어 마크를 안쪽으로 밀어 넣는다.
    inner = int(size * 0.72)
    mark = draw_mark(inner)
    tile.alpha_composite(mark, ((size - inner) // 2, (size - inner) // 2))
    return tile


def save(img: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f'  {path}  {img.size[0]}x{img.size[1]}')


def main() -> None:
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
    app = os.path.join(root, 'app')

    print('원본 (design-system/logo/)')
    here = os.path.dirname(os.path.abspath(__file__))
    save(draw_mark(1024), os.path.join(here, 'nexus-mark.png'))
    save(draw_tile(1024), os.path.join(here, 'nexus-icon.png'))

    print('앱 내부 표시 (assets/logo/)')
    for s in (256, 512):
        save(draw_mark(s), os.path.join(app, 'assets', 'logo', f'nexus-mark-{s}.png'))

    print('Windows')
    ico = os.path.join(app, 'windows', 'runner', 'resources', 'app_icon.ico')
    # **한 파일에 여러 크기를 담는다.** 탐색기는 16, 작업 표시줄은 32,
    # 바로 가기 큰 아이콘은 256 을 고른다. 하나만 넣으면 나머지가 늘어난다.
    #
    # **크기마다 새로 그린다.** `sizes=` 로 맡기면 Pillow 가 256 을 줄여 넣는데,
    # 그러면 노드를 빼는 규칙(NODE_MIN_SIZE)이 무시된 채 16px 에도 회색 점이
    # 딸려 들어간다 — 작은 크기를 위해 만든 규칙이 정작 작은 크기에서 안 돈다.
    ico_sizes = [256, 128, 64, 48, 32, 16]
    tiles = [draw_tile(s) for s in ico_sizes]
    tiles[0].save(ico, format='ICO', append_images=tiles[1:],
                  sizes=[(s, s) for s in ico_sizes])
    print(f'  {ico}  {" ".join(str(s) for s in reversed(ico_sizes))} 다중')

    print('Web')
    save(draw_tile(32), os.path.join(app, 'web', 'favicon.png'))
    for s in (192, 512):
        save(draw_tile(s), os.path.join(app, 'web', 'icons', f'Icon-{s}.png'))
        save(draw_square(s), os.path.join(app, 'web', 'icons', f'Icon-maskable-{s}.png'))

    print('Android')
    for density, s in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)):
        save(draw_tile(s),
             os.path.join(app, 'android', 'app', 'src', 'main', 'res', f'mipmap-{density}', 'ic_launcher.png'))

    print('\n완료.')


if __name__ == '__main__':
    main()
