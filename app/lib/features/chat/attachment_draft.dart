import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../data/api/api_failure.dart';
import '../../data/api/attachments_api.dart';
import '../../domain/models/message.dart';

/// 입력창에 담아 둔 파일 하나.
///
/// **고르는 즉시 올라간다.** 전송 때 몰아서 올리지 않는 이유는 서버가 그렇게
/// 설계돼 있기 때문이다 — 업로드가 `messageId = null` 로 먼저 끝나고 전송이
/// 이어 붙인다. 덕분에 큰 파일이 올라가는 동안에도 본문을 계속 쓸 수 있고,
/// 전송 버튼을 누르는 순간에는 기다릴 것이 없다.
class AttachmentDraft {
  AttachmentDraft({
    required this.localId,
    required this.name,
    required this.sizeBytes,
    this.progress = 0,
    this.uploaded,
    this.failure,
  });

  /// 화면에서 이 항목을 가리키는 값. 서버 id 는 업로드가 끝나야 생긴다.
  final String localId;

  final String name;
  final int sizeBytes;

  /// 0.0~1.0. 큰 파일에서 아무 표시가 없으면 멈춘 것으로 보인다.
  final double progress;

  /// 업로드가 끝났으면 서버가 준 값. 이것이 있어야 전송할 수 있다.
  final MessageAttachment? uploaded;

  /// 실패 종류. 문구는 화면이 정한다 — 서버 문구를 그대로 쓰지 않는다.
  final ApiFailure? failure;

  bool get isDone => uploaded != null;
  bool get isFailed => failure != null;
  bool get isUploading => !isDone && !isFailed;

  AttachmentDraft copyWith({
    double? progress,
    MessageAttachment? uploaded,
    ApiFailure? failure,
    bool clearFailure = false,
  }) =>
      AttachmentDraft(
        localId: localId,
        name: name,
        sizeBytes: sizeBytes,
        progress: progress ?? this.progress,
        uploaded: uploaded ?? this.uploaded,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

/// 입력창의 첨부 목록을 들고 업로드를 진행한다.
///
/// 채널마다 하나가 아니라 **입력창마다 하나**다. 채널을 옮기면 버린다 —
/// 업로드 주소에 채널이 들어 있어, 담아 둔 채로 옮기면 엉뚱한 채널로 간다.
class AttachmentDraftController extends ChangeNotifier {
  AttachmentDraftController(this._api);

  final AttachmentsApi _api;

  final List<AttachmentDraft> _drafts = [];
  final Map<String, CancelToken> _cancels = {};
  final Map<String, Uint8List> _bytes = {};

  int _serial = 0;
  bool _disposed = false;

  List<AttachmentDraft> get drafts => List.unmodifiable(_drafts);

  bool get isEmpty => _drafts.isEmpty;

  /// 하나라도 올라가는 중이면 전송을 막는다. 아직 id 가 없는 첨부는 실어
  /// 보낼 수 없고, 빼고 보내면 사용자가 붙인 파일이 조용히 사라진다.
  bool get isUploading => _drafts.any((d) => d.isUploading);

  /// 보낼 수 있는 첨부. 실패한 것은 빠진다.
  List<MessageAttachment> get uploaded =>
      [for (final d in _drafts) if (d.uploaded != null) d.uploaded!];

  /// 파일을 고르고 곧바로 올린다.
  ///
  /// **경로가 아니라 바이트를 읽어 둔다.** 웹에는 경로가 없고, 데스크톱에서도
  /// 경로만 들고 있으면 올리기 전에 사용자가 파일을 옮기거나 지울 수 있다.
  Future<void> pick({
    required String spaceId,
    required String channelId,
  }) async {
    final picked = await FilePicker.pickFiles();

    for (final file in picked) {
      final bytes = await file.readAsBytes();
      _add(
        spaceId: spaceId,
        channelId: channelId,
        name: file.name,
        bytes: bytes,
      );
    }
  }

  void _add({
    required String spaceId,
    required String channelId,
    required String name,
    required Uint8List bytes,
  }) {
    final localId = 'draft-${_serial++}';
    _bytes[localId] = bytes;
    _drafts.add(
      AttachmentDraft(localId: localId, name: name, sizeBytes: bytes.length),
    );
    _notify();
    _upload(localId, spaceId: spaceId, channelId: channelId);
  }

  Future<void> _upload(
    String localId, {
    required String spaceId,
    required String channelId,
  }) async {
    final bytes = _bytes[localId];
    final draft = _find(localId);
    if (bytes == null || draft == null) return;

    final cancel = CancelToken();
    _cancels[localId] = cancel;

    try {
      final result = await _api.upload(
        spaceId: spaceId,
        channelId: channelId,
        filename: draft.name,
        bytes: bytes,
        cancelToken: cancel,
        onProgress: (progress) => _patch(localId, (d) => d.copyWith(progress: progress)),
      );
      _patch(localId, (d) => d.copyWith(uploaded: result, progress: 1));
      // 올라갔으면 바이트를 들고 있을 이유가 없다. 큰 파일이면 그대로 메모리다.
      _bytes.remove(localId);
    } on ApiException catch (e) {
      _patch(localId, (d) => d.copyWith(failure: e.failure));
    } catch (_) {
      // 취소도 여기로 온다. 항목이 이미 지워졌으면 아무 일도 하지 않는다.
      _patch(localId, (d) => d.copyWith(failure: ApiFailure.server));
    } finally {
      _cancels.remove(localId);
    }
  }

  /// 실패한 것을 다시 올린다.
  Future<void> retry(
    String localId, {
    required String spaceId,
    required String channelId,
  }) async {
    _patch(localId, (d) => d.copyWith(progress: 0, clearFailure: true));
    await _upload(localId, spaceId: spaceId, channelId: channelId);
  }

  /// 목록에서 뺀다. 올라가는 중이면 취소한다.
  ///
  /// **서버에 이미 올라간 것은 지우지 않는다.** 메시지에 연결되지 않은 채로
  /// 남았다가 24시간 뒤 서버가 정리한다 — 지우는 API 를 따로 두는 것보다
  /// 경로가 하나 적다.
  void remove(String localId) {
    _cancels.remove(localId)?.cancel();
    _bytes.remove(localId);
    _drafts.removeWhere((d) => d.localId == localId);
    _notify();
  }

  /// 전송이 끝났다. 담아 둔 것을 비운다.
  void clear() {
    for (final cancel in _cancels.values) {
      cancel.cancel();
    }
    _cancels.clear();
    _bytes.clear();
    _drafts.clear();
    _notify();
  }

  AttachmentDraft? _find(String localId) {
    for (final draft in _drafts) {
      if (draft.localId == localId) return draft;
    }
    return null;
  }

  void _patch(String localId, AttachmentDraft Function(AttachmentDraft) update) {
    final index = _drafts.indexWhere((d) => d.localId == localId);
    // 올라가는 도중에 사용자가 뺐을 수 있다.
    if (index < 0) return;
    _drafts[index] = update(_drafts[index]);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    for (final cancel in _cancels.values) {
      cancel.cancel();
    }
    _disposed = true;
    super.dispose();
  }
}
