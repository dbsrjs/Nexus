#!/usr/bin/env python3
"""
Nexus 로고 자산 생성기.

**이 스크립트가 로고의 유일한 원본이다.** 브랜드 제안서(2026-08-31)의 «2D Flat
Minimalist Vector System» 을 기하로 옮겨 두고, 필요한 모든 크기를 여기서 뽑는다.
PNG 를 손으로 그려 저장소에 넣으면 크기마다 미세하게 갈라지고, 나중에 형태를
고칠 때 어느 것이 맞는지 알 수 없게 된다.

**왜 새 의존성을 들이지 않았나** — 이 프로젝트는 마크다운 파서 · 신택스
하이라이터 · 번다운 차트를 전부 직접 만들어 패키지를 거절해 왔다. 로고도
같다. 마크가 꺾은선 둘과 원 하나라 Pillow 의 선 · 원만으로 충분하다.

**형태는 2026-10-05 시안 C «연결점» 이다.** 지금 마크를 다듬은 안(A)과 새 심볼
셋을 크기 · 바탕별로 나란히 놓고 골랐다. 로그인에 쓰던 3D 모놀리스 PNG 도 이때
걷었다 — 워드마크가 그림자에 묻혀 «N XUS» 로 읽혔고, 아이콘과 다른 물건이었다.
이제 앱 안 · 아이콘 · 파비콘이 전부 이 마크 한 벌이다.

실행:
    python design-system/logo/build_logo.py
"""
from __future__ import annotations

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
# 판과 획은 제안서 §6 «Material System» 그대로다. 노드만 앱 다크 테마의
# `accent`(#77AECF)로 바꿨다 — 시안 C 는 노드가 끊긴 대각을 잇는 «연결점» 이라
# 형태의 주인공인데, 옛 Titanium Grey 는 검은 판 위에서 획보다 어두워 묻힌다.
# 판 · 획은 앱 토큰을 따르지 않는다 — 아이콘은 OS 런처와 브라우저 탭에 놓이는
# 것이라 앱 배경이 아니라 그 바깥 환경을 상대한다.
SPACE_BLACK = (0, 0, 0, 255)        # #000000  타일 바탕
PURE_STEEL = (255, 255, 255, 255)   # #FFFFFF  N 획
NODE_ACCENT = (119, 174, 207, 255)  # #77AECF  연결점(앱 다크 accent)

# ── 마크 기하 (시안 C «연결점», 2026-10-05) ─────────────
# 'N' 을 두 획으로 나눈다. 왼쪽 획은 세로를 올라가 대각 위쪽 절반까지,
# 오른쪽 획은 세로를 내려가 대각 아래쪽 절반까지 온다. 둘이 만나야 할 대각
# 한가운데를 비우고 노드가 그 자리를 잇는다 — 이름(nexus, 연결점)이 곧 형태다.
#
# 옛 마크는 획 셋을 따로 그려 꺾이는 모서리마다 둥근 끝이 겹쳐 혹처럼
# 튀어나왔다. 이제 한 획 안의 꺾임은 꼭짓점에 원을 얹어 둥근 이음매로 만든다.
N_TOP, N_BOTTOM = 260.0, 740.0
N_LEFT, N_RIGHT = 300.0, 700.0
# 옛 마크(N 높이의 12%)보다 1.5배 굵다. 가늘면 16px 파비콘에서 획이 흐려졌다.
STROKE = 85.0
CENTER = ART / 2.0
NODE_RADIUS = 62.0
# 대각이 노드 중심에서 끊기는 거리. 노드 가장자리와 획 끝 사이에 ~33 단위의
# 틈이 남는다 — 더 좁히면 큰 크기에서도 그냥 점 찍힌 N 이 되고, 더 넓히면
# «이음» 보다 «끊김» 이 먼저 읽힌다.
GAP_FROM_CENTER = 138.0

# 노드는 **모든 크기에서 그린다.** 옛 마크는 64px 아래에서 노드를 뺐지만, 이제
# 노드가 없으면 대각이 끊긴 채 남아 'N' 이 부러져 보인다. 16px 에서는 틈이
# 닫혀 굵은 N 으로 읽힌다.

# 타일(앱 아이콘) 모서리 반경. 안드로이드 · 윈도우가 각자 마스킹을 하므로
# 우리가 그리는 값은 «마스킹이 없을 때 보이는 모양» 이다.
TILE_RADIUS_RATIO = 0.225


def _round_polyline(draw: ImageDraw.ImageDraw, points, width, fill) -> None:
    """둥근 끝 · 둥근 이음매를 가진 꺾은선. Pillow 의 line 은 끝을 잘라 놓으므로
    꼭짓점마다 원을 얹는다 — 끝에서는 둥근 끝, 꺾이는 곳에서는 둥근 이음매가 된다."""
    draw.line(points, fill=fill, width=int(round(width)))
    r = width / 2.0
    for (x, y) in points:
        draw.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def _diagonal_end(sx: float, sy: float) -> tuple[float, float]:
    """(sx, sy) 에서 중심을 향하는 대각이 중심에서 GAP_FROM_CENTER 만큼 앞에서 멈추는 점."""
    dx, dy = CENTER - sx, CENTER - sy
    length = (dx * dx + dy * dy) ** 0.5
    t = (length - GAP_FROM_CENTER) / length
    return sx + dx * t, sy + dy * t


def draw_mark(size: int, stroke_color=PURE_STEEL, node_color=NODE_ACCENT) -> Image.Image:
    """'N' 마크만. 배경은 투명하다 — 타일 위에도, 앱 화면 위에도 얹는다."""
    canvas = Image.new('RGBA', (ART * SS, ART * SS), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    k = SS  # 1000 단위 → 실제 픽셀

    def px(p):
        return (p[0] * k, p[1] * k)

    left = [(N_LEFT, N_BOTTOM), (N_LEFT, N_TOP), _diagonal_end(N_LEFT, N_TOP)]
    right = [(N_RIGHT, N_TOP), (N_RIGHT, N_BOTTOM), _diagonal_end(N_RIGHT, N_BOTTOM)]
    for stroke in (left, right):
        _round_polyline(draw, [px(p) for p in stroke], STROKE * k, stroke_color)

    c, r = CENTER * k, NODE_RADIUS * k
    draw.ellipse([c - r, c - r, c + r, c + r], fill=node_color)

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
    # 줄인 256 은 16px 에서 획이 뭉개진다 — 작은 크기는 그 크기로 그려야 선다.
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
