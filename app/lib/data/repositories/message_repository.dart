import '../../domain/models/message.dart';
import '../api/api_failure.dart';
import '../api/messages_api.dart';
import '../local/app_database.dart';

/// 메시지의 **단일 진실 공급원은 로컬 DB(drift)** 다 (docs/앱-설계.md §6).
///
/// REST 와 소켓은 로컬 DB 를 갱신하는 두 개의 입력원일 뿐이고, 화면은 언제나
/// drift 를 구독한다. 이렇게 두면 오프라인 표시와 실시간 갱신이 같은 코드
/// 경로를 탄다 — 화면이 "어디서 온 데이터인지" 를 몰라도 된다.
class MessageRepository {
  MessageRepository({required MessagesApi api, required AppDatabase db})
      : _api = api,
        _db = db;

  final MessagesApi _api;
  final AppDatabase _db;

  /// 화면이 구독하는 스트림. 캐시가 있으면 **즉시** 첫 프레임이 그려진다.
  Stream<List<Message>> watch(String channelId) =>
      _db.watchChannelMessages(channelId);

  /// 서버에서 최신 페이지를 받아 캐시를 맞춘다.
  ///
  /// 실패해도 예외를 밖으로 내보내지 않는다 — **캐시로 이미 화면이 그려져 있으므로**
  /// 목록 전체를 오류 화면으로 바꾸면 오프라인에서 읽을 수 있다는 이점이 사라진다.
  /// 대신 성공 여부를 돌려주어 호출부가 배너 등을 결정하게 한다.
  Future<bool> refresh({
    required String spaceId,
    required String channelId,
  }) async {
    try {
      final page = await _api.list(spaceId: spaceId, channelId: channelId);
      // 서버가 준 것으로 교체한다. 서버에서 지워진 메시지가 캐시에 남지 않게 하려면
      // 병합이 아니라 교체여야 한다. 아직 못 보낸 로컬 메시지는 유지된다.
      await _db.replaceServerMessages(spaceId, channelId, page.items);
      return true;
    } on ApiException {
      return false;
    }
  }

  /// 위로 스크롤했을 때. 이전 페이지는 **덧붙인다**(교체가 아니다).
  Future<String?> loadOlder({
    required String spaceId,
    required String channelId,
    required String cursor,
  }) async {
    try {
      final page = await _api.list(
        spaceId: spaceId,
        channelId: channelId,
        cursor: cursor,
      );
      await _db.upsertMessages(spaceId, page.items);
      return page.nextCursor;
    } on ApiException {
      return null;
    }
  }

  /// 서버가 브로드캐스트한 메시지. 같은 id 면 덮어써도 결과가 같다(멱등).
  Future<void> applyIncoming(String spaceId, Message message) =>
      _db.upsertMessage(spaceId, message);

  Future<void> applyDeleted(String messageId) =>
      _db.markMessageDeleted(messageId, DateTime.now());

  /// 낙관적 삽입. 로컬 id 로 먼저 저장해 화면에 즉시 보인다.
  Future<void> insertPending(String spaceId, Message message) =>
      _db.upsertMessage(spaceId, message.copyWith(pending: true, failed: false));

  /// 전송 성공. 로컬 행을 지우고 서버 메시지를 넣는다.
  ///
  /// id 가 바뀌므로 update 가 아니라 delete + insert 다. 소켓이 먼저 도착해
  /// 서버 메시지가 이미 들어와 있어도 결과는 같다 — 중복이 생기지 않는다.
  Future<void> settleSent(String spaceId, String localId, Message sent) async {
    await _db.deleteMessage(localId);
    await _db.upsertMessage(spaceId, sent);
  }

  Future<void> markFailed(String spaceId, Message message) =>
      _db.upsertMessage(spaceId, message.copyWith(pending: false, failed: true));

  Future<void> discard(String messageId) => _db.deleteMessage(messageId);
}
