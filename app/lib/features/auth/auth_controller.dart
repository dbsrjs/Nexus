import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_client.dart';
import '../../data/api/auth_api.dart';
import '../../data/auth_storage.dart';
import '../../domain/models/user.dart';
import '../space/space_controller.dart';

/// 인증 상태. 셋을 구분하는 이유는 **앱 시작 직후**가 "로그아웃"과 다르기
/// 때문이다. 저장된 토큰을 확인하는 동안 로그인 화면을 깜빡 보여주면 안 된다.
sealed class AuthState {
  const AuthState();
}

/// 저장된 토큰을 확인하는 중. 앱 시작 직후의 상태다.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final User user;
}

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(storage: ref.watch(authStorageProvider));
  // 리프레시까지 실패하면 컨트롤러가 로그아웃 상태로 내려간다. 라우터가
  // 그걸 보고 로그인 화면으로 보낸다.
  client.onSessionExpired = () {
    ref.read(authControllerProvider.notifier).handleSessionExpired();
  };
  return client;
});

final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // 복원은 네트워크를 탄다. 여기서 기다리면 서버가 꺼져 있을 때 앱이 최대
    // 타임아웃만큼 빈 화면으로 멈춘다. 먼저 그리고 나중에 결론 낸다.
    Future.microtask(_restore);
    return const AuthRestoring();
  }

  ApiClient get _client => ref.read(apiClientProvider);
  AuthApi get _api => ref.read(authApiProvider);

  Future<void> _restore() async {
    await _client.restore();
    if (!_client.hasTokens) {
      state = const AuthSignedOut();
      return;
    }

    try {
      // 토큰이 아직 쓸 수 있는지 서버에 물어본다. 만료됐으면 인터셉터가
      // 리프레시를 한 번 시도하고, 그것도 실패하면 예외가 온다.
      final user = await _api.me();
      await ref.read(authStorageProvider).writeUser(user);
      state = AuthSignedIn(user);
    } on AuthException catch (e) {
      if (e.failure == AuthFailure.network) {
        // **서버에 못 닿은 것이지 토큰이 죽은 것이 아니다.**
        // 여기서 로그인 화면으로 보내면 오프라인에서는 캐시된 대화를 볼 방법이
        // 없다 — 6단계에서 drift 캐시를 넣은 의미가 사라진다.
        // 마지막으로 확인된 계정으로 로그인 상태를 유지하고, 화면은 캐시를 그린다.
        final cached = await ref.read(authStorageProvider).readUser();
        state = cached != null ? AuthSignedIn(cached) : const AuthSignedOut();
        return;
      }
      // 401 등 — 토큰이 실제로 못 쓰게 됐다. 흔적을 지운다.
      await _client.clearTokens();
      state = const AuthSignedOut();
    }
  }

  /// 성공하면 null, 실패하면 그 이유를 돌려준다.
  Future<AuthFailure?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _api.login(email: email, password: password);
      await _client.setTokens(result.tokens);
      // 오프라인으로 켤 때 쓸 수 있도록 계정을 함께 저장한다.
      await ref.read(authStorageProvider).writeUser(result.user);
      state = AuthSignedIn(result.user);
      return null;
    } on AuthException catch (e) {
      return e.failure;
    }
  }

  Future<void> signOut() async {
    final tokens = await ref.read(authStorageProvider).read();
    await _api.logout(tokens?.refreshToken);
    await _client.clearTokens();
    // 로컬 캐시도 비운다. 다른 계정으로 로그인했을 때 이전 계정의 대화가
    // 남아 있으면 안 된다.
    await ref.read(appDatabaseProvider).clearAll();
    state = const AuthSignedOut();
  }

  /// 인터셉터가 리프레시까지 실패했을 때 부른다.
  void handleSessionExpired() {
    if (state is AuthSignedIn) {
      state = const AuthSignedOut();
    }
  }
}
