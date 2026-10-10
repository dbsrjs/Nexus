/// 대화에 보이는 시각 글자 — 날짜 구분선 · 시각 툴팁(2026-10-10 UI/UX 검토).
///
/// 메시지는 무기한 보관된다. 시:분만 보이면 지난달 메시지와 오늘 메시지가 똑같이 `14:03` 이라,
/// 날이 바뀌는 곳에 구분선을 두고 시각에 올리면 전체 날짜를 보인다. 전부 **기기 시간대**로 본다.
library;

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 같은 날인가(기기 시간대).
bool isSameLocalDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// 구분선 글자 — 「오늘」 · 「어제」 · 「10월 3일 (금)」 · 해가 다르면 「2025년 10월 3일 (금)」.
/// [now] 는 테스트용이다.
String dayLabel(DateTime at, {DateTime? now}) {
  final local = at.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  if (isSameLocalDay(local, today)) return '오늘';
  // 하루를 빼는 대신 달력 날짜로 만든다 — 일광 절약 시간이 있는 곳에서 23·25시간 날이 있다.
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  if (isSameLocalDay(local, yesterday)) return '어제';
  final day = '${local.month}월 ${local.day}일 (${_weekdays[local.weekday - 1]})';
  return local.year == today.year ? day : '${local.year}년 $day';
}

/// 「14:03」.
String clockLabel(DateTime at) {
  final local = at.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

/// 툴팁용 전체 시각 — 「2026년 10월 10일 (토) 14:03」.
String fullStampLabel(DateTime at) {
  final local = at.toLocal();
  return '${local.year}년 ${local.month}월 ${local.day}일 '
      '(${_weekdays[local.weekday - 1]}) ${clockLabel(local)}';
}
