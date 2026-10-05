import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_failure.dart';
import '../../domain/models/message.dart';
import '../../shared/widgets/file_kind.dart';
import '../../ui/ui.dart';
import '../space/space_controller.dart';
import 'attachment_draft.dart';
import 'message_controller.dart';

/// 파일 크기를 사람이 읽는 단위로.
///
/// 1024 로 나눈다(KiB). 파일 탐색기가 보여 주는 값과 어긋나면 사용자가
/// 같은 파일인지 의심한다.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  // 1KB 미만 소수점은 의미가 없고, 큰 값에서는 한 자리면 충분하다.
  final text = value >= 100
      ? value.round().toString()
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// 메시지에 붙은 첨부 하나.
///
/// 이미지면 미리보기로, 아니면 파일 한 줄로 그린다. 파일 종류는 아이콘이 아니라
/// 확장자 표지다(15단계 D5).
class AttachmentRow extends ConsumerWidget {
  const AttachmentRow({
    super.key,
    required this.attachment,
    required this.message,
  });

  final MessageAttachment attachment;

  /// 아직 큐에 있는 메시지인지 보려고 받는다. 큐에 있는 동안에는 서버에
  /// 없으므로 미리보기를 받을 수 없다.
  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final c = nx.colors;

    // **큐에 있는 동안에는 파일 줄로 그린다.** 첨부는 이미 서버에 올라가 있지만
    // 메시지가 아직 없어 다른 기기에서는 보이지 않는 상태다. 굳이 미리보기를
    // 받아 올 이유가 없고, 실패하면 깨진 그림만 남는다.
    if (attachment.isImage && !message.isLocal) {
      return AttachmentImage(attachment: attachment);
    }

    return Container(
      margin: const EdgeInsets.only(top: NxSpacing.sp2),
      padding: const EdgeInsets.all(NxSpacing.sp3),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.divider),
        borderRadius: BorderRadius.circular(NxRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FileKindBadge(name: attachment.name, size: 32),
          const SizedBox(width: NxSpacing.sp4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.sm,
                ),
                Text(formatBytes(attachment.sizeBytes), style: nx.text.mono),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력창 위에 붙는 첨부 목록. 업로드 진행률이 여기서 보인다.
///
/// 진행률을 보여 주지 않으면 큰 파일에서 앱이 멈춘 것으로 보인다.
class AttachmentDraftBar extends StatelessWidget {
  const AttachmentDraftBar({
    super.key,
    required this.drafts,
    required this.onRemove,
    required this.onRetry,
  });

  final List<AttachmentDraft> drafts;
  final void Function(String localId) onRemove;
  final void Function(String localId) onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NxSpacing.sp4),
      child: Wrap(
        spacing: NxSpacing.sp3,
        runSpacing: NxSpacing.sp3,
        children: [
          for (final draft in drafts)
            _DraftChip(
              draft: draft,
              onRemove: () => onRemove(draft.localId),
              onRetry: () => onRetry(draft.localId),
            ),
        ],
      ),
    );
  }
}

class _DraftChip extends StatelessWidget {
  const _DraftChip({
    required this.draft,
    required this.onRemove,
    required this.onRetry,
  });

  final AttachmentDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    final c = nx.colors;

    // 진행률을 아는 동안은 숫자로, 아직 0 이면 작은 호로 — 버튼 안처럼 작은 자리라
    // 회전 표시가 화면을 흔들지 않는다(D10).
    final Widget status = draft.isUploading
        ? (draft.progress > 0
              ? Text(
                  '${(draft.progress * 100).round()}%',
                  style: nx.text.mono.copyWith(color: c.accent),
                )
              : const NxSpinner(size: NxIconSize.xs))
        : draft.isFailed
        ? NxIcon(NxIcons.warning, size: NxIconSize.sm, color: c.danger)
        : NxIcon(NxIcons.check, size: NxIconSize.sm, color: c.success);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.fromLTRB(
        NxSpacing.sp4,
        NxSpacing.sp2,
        NxSpacing.sp1,
        NxSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: draft.isFailed ? c.danger : c.divider),
        borderRadius: BorderRadius.circular(NxRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 32, child: Center(child: status)),
          const SizedBox(width: NxSpacing.sp2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  draft.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.sm,
                ),
                Text(
                  // 실패 문구는 앱이 정한다 — 서버 문구를 그대로 쓰지 않는다.
                  draft.isFailed
                      ? messageFor(draft.failure!)
                      : formatBytes(draft.sizeBytes),
                  style: draft.isFailed
                      ? nx.text.meta.copyWith(color: c.danger)
                      : nx.text.mono,
                ),
              ],
            ),
          ),
          if (draft.isFailed)
            NxIconButton(
              icon: NxIcons.refresh,
              label: '다시 올리기',
              size: NxSize.sm,
              onPressed: onRetry,
            ),
          NxIconButton(
            icon: NxIcons.close,
            label: '${draft.name} 빼기',
            size: NxSize.sm,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// 이미지 첨부의 미리보기.
///
/// **자리를 먼저 잡는다.** 서버가 업로드 때 재 둔 `width`·`height` 로 비율을
/// 고정하므로, 이미지가 로드될 때 목록이 튀지 않는다. 크기를 모르는 이미지만
/// 로드 뒤에 자리가 정해진다.
class AttachmentImage extends ConsumerWidget {
  const AttachmentImage({super.key, required this.attachment});

  final MessageAttachment attachment;

  /// 미리보기 최대 크기. 대화 흐름을 이미지가 통째로 밀어내지 않게 한다.
  static const double maxWidth = 320;
  static const double maxHeight = 320;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = NxTheme.of(context).colors;
    final spaceId = ref.watch(currentSpaceIdProvider);
    if (spaceId == null) return const SizedBox.shrink();

    final api = ref.watch(attachmentsApiProvider);
    final url = api.urlFor(
      spaceId: spaceId,
      attachmentId: attachment.id,
      thumb: true,
    );

    final size = fit(attachment.width, attachment.height);

    return Padding(
      padding: const EdgeInsets.only(top: NxSpacing.sp2),
      child: NxPressable(
        onPressed: () => _openFull(context, ref, spaceId),
        semanticLabel: '${attachment.name} 크게 보기',
        builder: (context, s) => ClipRRect(
          borderRadius: BorderRadius.circular(NxRadius.md),
          child: SizedBox(
            width: size?.width,
            height: size?.height,
            child: Image.network(
              url,
              headers: api.authHeaders,
              fit: BoxFit.cover,
              // 크기를 아는 동안은 그 자리를 지킨다 — 로드 중에도 흔들리지 않는다.
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : Container(
                      width: size?.width ?? maxWidth,
                      height: size?.height ?? 160,
                      color: c.bgElevated,
                    ),
              // 못 받아도 대화가 깨지지 않게 파일 줄로 떨어진다.
              errorBuilder: (context, _, _) =>
                  _BrokenImage(attachment: attachment),
            ),
          ),
        ),
      ),
    );
  }

  /// 원본 비율을 지키면서 최대 크기 안에 넣는다. 크기를 모르면 null.
  static Size? fit(int? width, int? height) {
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    final scale = [
      maxWidth / width,
      maxHeight / height,
      1.0, // 작은 이미지를 늘리지 않는다.
    ].reduce((a, b) => a < b ? a : b);
    return Size(width * scale, height * scale);
  }

  void _openFull(BuildContext context, WidgetRef ref, String spaceId) {
    final api = ref.read(attachmentsApiProvider);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: NxMotion.panel,
        reverseTransitionDuration: NxMotion.panel,
        pageBuilder: (_, _, _) => _FullImage(
          name: attachment.name,
          // 원본을 받는다 — 확대해서 보려는 것이므로 축소본이면 뜻이 없다.
          url: api.urlFor(spaceId: spaceId, attachmentId: attachment.id),
          headers: api.authHeaders,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

/// 미리보기를 못 받았을 때. 파일이라는 사실은 남긴다.
class _BrokenImage extends StatelessWidget {
  const _BrokenImage({required this.attachment});

  final MessageAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final nx = NxTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(NxSpacing.sp4),
      color: nx.colors.bgElevated,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FileKindBadge(name: attachment.name, size: 28),
          const SizedBox(width: NxSpacing.sp4),
          Flexible(
            child: Text(
              '${attachment.name} — 미리보기를 불러오지 못했습니다',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nx.text.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 전체 화면 보기. 확대 · 이동만 되면 충분하다. **밝기와 무관하게 검은 바탕** —
/// 사진은 어두운 바탕에서 제 색으로 보인다. Esc · 닫기로 나간다.
class _FullImage extends StatelessWidget {
  const _FullImage({
    required this.name,
    required this.url,
    required this.headers,
  });

  final String name;
  final String url;
  final Map<String, String> headers;

  @override
  Widget build(BuildContext context) {
    // 검은 바탕 위라 다크 토큰으로 머리 줄을 그린다.
    return NxTheme(
      data: NxThemeData.of(Brightness.dark),
      child: Builder(
        builder: (context) {
          final nx = NxTheme.of(context);
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  Navigator.of(context).pop(),
            },
            child: Focus(
              autofocus: true,
              child: NxPage(
                background: NxBrand.plate, // 사진 보기는 테마와 무관하게 검정 바탕
                header: NxHeader(
                  title: name,
                  actions: [
                    NxIconButton(
                      icon: NxIcons.close,
                      label: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                body: Center(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Image.network(
                      url,
                      headers: headers,
                      errorBuilder: (context, _, _) =>
                          Text('이미지를 불러오지 못했습니다.', style: nx.text.secondary),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
