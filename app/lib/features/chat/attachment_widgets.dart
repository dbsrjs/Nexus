import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/message.dart';
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
  final text = value >= 100 ? value.round().toString() : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

/// 확장자로 고른 아이콘.
///
/// mime 을 먼저 본다 — 확장자가 없는 파일도 있고, 서버가 mime 을 준다.
IconData iconForAttachment(MessageAttachment attachment) {
  final mime = attachment.mime ?? '';
  if (mime.startsWith('image/')) return Icons.image_outlined;
  if (mime.startsWith('video/')) return Icons.movie_outlined;
  if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
  if (mime.startsWith('text/')) return Icons.description_outlined;
  if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
  if (mime.contains('zip') || mime.contains('compressed')) {
    return Icons.folder_zip_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

/// 메시지에 붙은 첨부 하나.
///
/// 이미지면 미리보기로, 아니면 파일 한 줄로 그린다.
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
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;

    // **큐에 있는 동안에는 파일 줄로 그린다.** 첨부는 이미 서버에 올라가 있지만
    // 메시지가 아직 없어 다른 기기에서는 보이지 않는 상태다. 굳이 미리보기를
    // 받아 올 이유가 없고, 실패하면 깨진 그림만 남는다.
    if (attachment.isImage && !message.isLocal) {
      return AttachmentImage(attachment: attachment);
    }

    return Container(
      margin: const EdgeInsets.only(top: NexusSpacing.sp1),
      padding: const EdgeInsets.symmetric(
        horizontal: NexusSpacing.sp3,
        vertical: NexusSpacing.sp2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(NexusRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconForAttachment(attachment), size: 18, color: muted),
          const SizedBox(width: NexusSpacing.sp2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  formatBytes(attachment.sizeBytes),
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
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
      padding: const EdgeInsets.only(bottom: NexusSpacing.sp3),
      child: Wrap(
        spacing: NexusSpacing.sp2,
        runSpacing: NexusSpacing.sp2,
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
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(
        horizontal: NexusSpacing.sp3,
        vertical: NexusSpacing.sp2,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: draft.isFailed ? theme.colorScheme.error : theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(NexusRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (draft.isUploading)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                // 진행률을 아는 동안은 그 값을 그린다. 0 이면 아직 아무것도
                // 보내지 못한 상태라 회전만 시킨다.
                value: draft.progress > 0 ? draft.progress : null,
                strokeWidth: 2,
              ),
            )
          else
            Icon(
              draft.isFailed ? Icons.error_outline : Icons.check_circle_outline,
              size: 14,
              color: draft.isFailed ? theme.colorScheme.error : muted,
            ),
          const SizedBox(width: NexusSpacing.sp2),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  draft.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  // 실패 문구는 앱이 정한다 — 서버 문구를 그대로 쓰지 않는다.
                  draft.isFailed
                      ? messageFor(draft.failure!)
                      : formatBytes(draft.sizeBytes),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: draft.isFailed ? theme.colorScheme.error : muted,
                  ),
                ),
              ],
            ),
          ),
          if (draft.isFailed)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 14),
              tooltip: '다시 올리기',
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 14),
            tooltip: '빼기',
            visualDensity: VisualDensity.compact,
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
    final theme = Theme.of(context);
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
      padding: const EdgeInsets.only(top: NexusSpacing.sp1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NexusRadius.md),
        child: InkWell(
          onTap: () => _openFull(context, ref, spaceId),
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
                      width: size?.width,
                      height: size?.height ?? 160,
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              // 못 받아도 대화가 깨지지 않게 파일 줄로 떨어진다.
              errorBuilder: (context, _, _) => _BrokenImage(attachment: attachment),
            ),
          ),
        ),
      ),
    );
  }

  /// 원본 비율을 지키면서 최대 크기 안에 넣는다. 크기를 모르면 null.
  static Size? fit(int? width, int? height) {
    if (width == null || height == null || width <= 0 || height <= 0) return null;
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
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullImage(
          name: attachment.name,
          // 원본을 받는다 — 확대해서 보려는 것이므로 축소본이면 뜻이 없다.
          url: api.urlFor(spaceId: spaceId, attachmentId: attachment.id),
          headers: api.authHeaders,
        ),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(NexusSpacing.sp4),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined,
              size: 18, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: NexusSpacing.sp2),
          Flexible(
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 전체 화면 보기. 확대·이동만 되면 충분하다.
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.network(
            url,
            headers: headers,
            errorBuilder: (context, _, _) => const Text(
              '이미지를 불러오지 못했습니다.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
