import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/shared/markdown/block.dart';

String dump(List<BlockNode> blocks) =>
    blocks.map((b) => '${b.kind.name}(${b.lines.join('/')})').join('+');

void main() {
  test('평범한 글은 문단 하나다', () {
    expect(dump(parseBlocks('안녕\n하세요')), 'paragraph(안녕/하세요)');
  });

  test('빈 줄이 문단을 가른다', () {
    expect(dump(parseBlocks('a\n\nb')), 'paragraph(a)+paragraph(b)');
  });

  test('코드블록 — 언어를 읽는다', () {
    final blocks = parseBlocks('```dart\nvar a = 1;\n```');

    expect(blocks.single.kind, BlockKind.code);
    expect(blocks.single.language, 'dart');
    expect(blocks.single.lines, ['var a = 1;']);
  });

  test('코드블록 안에서는 다른 블록을 찾지 않는다', () {
    final blocks = parseBlocks('```\n# 제목\n> 인용\n```');

    expect(blocks.single.kind, BlockKind.code);
    expect(blocks.single.lines, ['# 제목', '> 인용']);
  });

  test('닫히지 않은 코드블록은 끝까지 코드다', () {
    final blocks = parseBlocks('```\na');

    expect(blocks.single.kind, BlockKind.code);
    expect(blocks.single.lines, ['a']);
  });

  test('인용 — 여러 줄이 한 블록이다', () {
    final blocks = parseBlocks('> a\n> b');

    expect(blocks.single.kind, BlockKind.quote);
    expect(blocks.single.lines, ['a', 'b']);
  });

  test('제목 — 세 단계까지', () {
    expect(parseBlocks('# a').single.level, 1);
    expect(parseBlocks('### a').single.level, 3);
    // #### 는 본문과 구분이 안 된다 — 제목으로 보지 않는다.
    expect(parseBlocks('#### a').single.kind, BlockKind.paragraph);
  });

  test('목록 — 순서 없는 것과 있는 것', () {
    final bullet = parseBlocks('- a\n- b').single;
    expect(bullet.kind, BlockKind.list);
    expect(bullet.ordered, isFalse);
    expect(bullet.lines, ['a', 'b']);

    expect(parseBlocks('1. a\n2. b').single.ordered, isTrue);
  });

  test('표 — 헤더와 본문을 나눈다', () {
    final table = parseBlocks('| 이름 | 값 |\n|---|---|\n| a | 1 |').single;

    expect(table.kind, BlockKind.table);
    expect(table.rows, [
      ['이름', '값'],
      ['a', '1'],
    ]);
  });

  test('구분 행이 없으면 표가 아니다', () {
    // 그냥 파이프를 쓴 문장이 표로 바뀌면 안 된다.
    expect(parseBlocks('| a | b |').single.kind, BlockKind.paragraph);
  });

  test('문단 도중에 목록이 시작되면 거기서 끊는다', () {
    expect(dump(parseBlocks('설명\n- 하나')), 'paragraph(설명)+list(하나)');
  });

  test('문단 도중에 표가 시작되면 거기서 끊는다', () {
    // **표는 구분 행까지 두 줄을 봐야 판별된다.** 문단을 끊는 검사가 한 줄만
    // 보면 표를 못 알아보고 문법이 통째로 글자가 된다 — 사람이 표를 쓰는 가장
    // 흔한 형태가 "설명 한 줄 쓰고 바로 표" 라 실제로 걸린다.
    final blocks = parseBlocks('결과는 아래와 같다\n| 이름 | 값 |\n|---|---|\n| a | 1 |');

    expect(blocks.map((b) => b.kind), [BlockKind.paragraph, BlockKind.table]);
    expect(blocks.first.lines, ['결과는 아래와 같다']);
    expect(blocks.last.rows, [
      ['이름', '값'],
      ['a', '1'],
    ]);
  });

  test('앞 공백이 있어도 제목 · 목록이다 — 인용 · 코드블록과 같게', () {
    // 인용과 코드블록은 앞 공백을 털고 보는데 제목과 목록만 줄 맨 앞을 요구하면,
    // 같은 글이 어디서 복사해 왔느냐에 따라 다르게 그려진다.
    final heading = parseBlocks('  # 제목').single;
    expect(heading.kind, BlockKind.heading);
    expect(heading.lines, ['제목']);

    final bullet = parseBlocks('  - 하나\n  - 둘').single;
    expect(bullet.kind, BlockKind.list);
    expect(bullet.lines, ['하나', '둘']);

    expect(parseBlocks('  1. 하나').single.ordered, isTrue);
  });

  test('빈 본문은 블록이 없다', () {
    expect(parseBlocks(''), isEmpty);
  });

  test('CRLF 로 온 본문도 LF 와 같게 그린다 — GitHub 본문이 그렇다', () {
    // **화면을 봐야만 드러난 결함이다.** PR 본문은 GitHub 이 CRLF 로 준다.
    // `'\n'` 으로만 쪼개면 줄 끝에 `\r` 이 남는데, Dart 에서 `.` 는 `\r` 을
    // 줄 종료 문자로 보아 건너뛰지 못하고 `$` 는 입력 끝에서만 맞는다. 그래서
    // `$` 로 끝나는 제목 · 번호목록 정규식만 조용히 매치에 실패했다 —
    // 인용은 `startsWith('>')` 라 멀쩡했고, 그 비대칭이 증상이었다.
    final blocks = parseBlocks('## Summary\r\n> 설명\r\n\r\n1. 하나\r\n');

    expect(dump(blocks), 'heading(Summary)+quote(설명)+list(하나)');
    expect(blocks[0].level, 2);
    expect(blocks[2].ordered, isTrue);
  });

  test('CR 만 쓰는 본문도 같게 그린다', () {
    expect(dump(parseBlocks('# 제목\r본문')), 'heading(제목)+paragraph(본문)');
  });
}
