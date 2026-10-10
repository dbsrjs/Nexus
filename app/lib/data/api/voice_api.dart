import 'api_client.dart';
import 'api_failure.dart';

/// 음성 채널에 들어갈 표(20단계). 미디어 서버(LiveKit) 주소와 그 룸 하나에만 통하는 토큰.
class VoiceTicket {
  const VoiceTicket({
    required this.url,
    required this.token,
    required this.canSpeak,
  });

  /// 앱이 붙는 LiveKit 주소(ws:// · wss://). API 주소와 다르다 — 배포에서는 터널의 다른 호스트 이름이다.
  final String url;
  final String token;

  /// 거짓이면 읽기 전용 채널이다 — 듣기만 한다. 토큰이 그렇게 발급돼 앱을 고쳐도 말할 수 없다.
  final bool canSpeak;
}

class VoiceApi {
  VoiceApi(this._client);

  final ApiClient _client;

  /// GET /api/voice — 이 서버에 통화가 켜져 있나. 꺼져 있으면 음성 채널을 만들 수 없게 감춘다.
  Future<bool> enabled() => guardApi(() async {
    final res = await _client.dio.get<Map<String, dynamic>>('/voice');
    return res.data?['enabled'] == true;
  });

  /// POST /api/spaces/:spaceId/channels/:channelId/voice/token — 볼 수 없으면 404.
  Future<VoiceTicket> ticket(String spaceId, String channelId) =>
      guardApi(() async {
        final res = await _client.dio.post<Map<String, dynamic>>(
          '/spaces/$spaceId/channels/$channelId/voice/token',
        );
        final data = res.data!;
        return VoiceTicket(
          url: data['url'] as String,
          token: data['token'] as String,
          canSpeak: data['canSpeak'] == true,
        );
      });

  /// GET /api/spaces/:spaceId/voice — 지금 통화 중인 사람. 내가 볼 수 있는 음성 채널만 온다.
  Future<Map<String, List<String>>> roster(String spaceId) =>
      guardApi(() async {
        final res = await _client.dio.get<Map<String, dynamic>>(
          '/spaces/$spaceId/voice',
        );
        final channels = (res.data?['channels'] as Map?) ?? const {};
        return {
          for (final e in channels.entries)
            if (e.key is String && e.value is List)
              e.key as String: [
                for (final id in e.value as List)
                  if (id is String) id,
              ],
        };
      });
}
