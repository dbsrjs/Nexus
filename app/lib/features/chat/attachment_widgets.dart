import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/message.dart';
import 'attachment_draft.dart';

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

/// 메시지에 붙은 파일 한 줄.
///
/// 이미지도 지금은 같은 줄로 그린다. **미리보기는 8-3 이다** — 목록이 튀지
/// 않게 자리를 먼저 잡는 일(width·height 활용)과 함께 해야 해서 나눴다.
class AttachmentRow extends StatelessWidget {
  const AttachmentRow({
    super.key,
    required this.attachment,
    required this.message,
  });

  final MessageAttachment attachment;

  /// 아직 큐에 있는 메시지인지 보려고 받는다. 큐에 있는 동안에는 서버에서
  /// 받아올 수 없어 눌러도 아무 일이 없다.
  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.color;

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
