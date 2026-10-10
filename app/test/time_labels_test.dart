import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/shared/time_labels.dart';

void main() {
  // 기기 시간대로 보이므로 로컬 시각으로 만든다 — UTC 로 만들면 CI 시간대에 따라 날이 바뀐다.
  final now = DateTime(2026, 10, 10, 9, 30);

  test('오늘 · 어제', () {
    expect(dayLabel(DateTime(2026, 10, 10, 0, 1), now: now), '오늘');
    expect(dayLabel(DateTime(2026, 10, 9, 23, 59), now: now), '어제');
  });

  test('그보다 앞이면 월 · 일 · 요일, 해가 다르면 연도까지', () {
    expect(dayLabel(DateTime(2026, 10, 3, 12), now: now), '10월 3일 (토)');
    expect(dayLabel(DateTime(2025, 10, 3, 12), now: now), '2025년 10월 3일 (금)');
  });

  test('달이 바뀐 다음 날의 「어제」', () {
    expect(
      dayLabel(DateTime(2026, 9, 30, 20), now: DateTime(2026, 10, 1, 8)),
      '어제',
    );
  });

  test('시각 · 툴팁 전체 시각', () {
    final at = DateTime(2026, 10, 10, 7, 5);
    expect(clockLabel(at), '07:05');
    expect(fullStampLabel(at), '2026년 10월 10일 (토) 07:05');
  });

  test('같은 날 판정', () {
    expect(
      isSameLocalDay(DateTime(2026, 10, 10, 0), DateTime(2026, 10, 10, 23)),
      isTrue,
    );
    expect(
      isSameLocalDay(DateTime(2026, 10, 10, 23), DateTime(2026, 10, 11, 0)),
      isFalse,
    );
  });
}
