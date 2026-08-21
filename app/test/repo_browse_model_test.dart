import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/domain/models/repo_browse.dart';

void main() {
  test('디렉터리 항목을 구분한다', () {
    const dir = TreeEntry(name: 'src', path: 'src', type: 'dir', size: null);
    const file = TreeEntry(name: 'a.ts', path: 'src/a.ts', type: 'file', size: 10);

    expect(dir.isDir, isTrue);
    expect(file.isDir, isFalse);
  });

  test('omitted 세 값이 각각 다른 문구가 된다', () {
    // 하나로 뭉치면 "사용자가 할 수 있는 일이 다르다"는 것이 사라진다.
    const binary = BlobView(path: 'a.png', size: 4, content: null, omitted: 'binary');
    const tooLarge =
        BlobView(path: 'b.txt', size: 600000, content: null, omitted: 'too_large');
    const unavailable =
        BlobView(path: 'c.bin', size: 1000, content: null, omitted: 'unavailable');

    final messages = {
      binary.omittedMessage,
      tooLarge.omittedMessage,
      unavailable.omittedMessage,
    };
    expect(messages.length, 3);
    expect(messages.every((m) => m != null && m.isNotEmpty), isTrue);
  });

  test('큰 파일 문구에는 크기가 들어간다', () {
    const kb = BlobView(path: 'b.txt', size: 600 * 1024, content: null, omitted: 'too_large');
    const mb = BlobView(path: 'c.txt', size: 3 * 1024 * 1024, content: null, omitted: 'too_large');

    // 얼마나 큰지 모르면 사용자가 다음에 무엇을 할지 정할 수 없다.
    // 1024 기준(KiB)으로 적는다 — 파일 탐색기와 어긋나면 같은 파일인지 의심한다.
    expect(kb.omittedMessage, contains('600.0 KB'));
    expect(mb.omittedMessage, contains('3.0 MB'));
  });

  test('본문이 있으면 문구가 없다', () {
    const shown = BlobView(path: 'a.ts', size: 3, content: 'abc', omitted: null);

    expect(shown.omittedMessage, isNull);
  });

  test('모르는 omitted 값도 문구를 준다', () {
    // 서버가 갈래를 늘렸을 때 화면이 빈 채로 남지 않아야 한다.
    const unknown = BlobView(path: 'a', size: 1, content: null, omitted: 'future_reason');

    expect(unknown.omittedMessage, isNotNull);
  });
}
