import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shell/app_shell.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/attachment_item.dart';
import '../../shared/widgets/file_kind.dart';
import '../../ui/ui.dart';
import '../chat/attachment_widgets.dart' show formatBytes;
import '../chat/message_controller.dart';
import '../space/space_controller.dart';

/// 스페이스에 올라온 파일 목록.
///
/// **캐시하지 않는다.** 대화를 읽는 데 필요한 값이 아니고(오프라인에서는 어차피
/// 내려받지도 못한다), 자주 여는 화면도 아니다. 멤버 목록과 같은 판단이다.
///
/// 서버가 **볼 수 있는 채널의 것만** 준다 — 비공개 채널의 파일은 여기 없다.
final spaceFilesProvider = FutureProvider.autoDispose<List<AttachmentItem>>((
  ref,
) async {
  final spaceId = ref.watch(currentSpaceIdProvider);
  if (spaceId == null) return const [];
  return ref.watch(attachmentsApiProvider).listForSpace(spaceId: spaceId);
});

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(spaceFilesProvider);

    return NxPage(
      // 끌어 내려 새로고침(RefreshIndicator)은 Material 이라 버튼으로 둔다.
      header: ShellHeader(
        title: '파일',
        actions: [
          NxIconButton(
            icon: NxIcons.refresh,
            label: '새로고침',
            onPressed: () => ref.invalidate(spaceFilesProvider),
          ),
        ],
      ),
      body: files.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(NxSpacing.sp7),
          child: NxSkeleton(lines: 6, lineHeight: 40),
        ),
        error: (error, _) => _FilesError(
          error: error,
          onRetry: () => ref.invalidate(spaceFilesProvider),
        ),
        data: (items) => items.isEmpty
            // 어디서 채워지는지를 말한다 — 한 줄짜리 빈 화면에서 사용자가 멈췄다(2026-10-10 UI/UX 검토).
            ? const NxEmptyState(
                title: '아직 올라온 파일이 없습니다',
                description: '대화 입력창의 클립 버튼으로 올린 파일이 여기에 모입니다.',
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: NxSpacing.sp7,
                  vertical: NxSpacing.sp4,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const NxDivider(),
                itemBuilder: (_, index) =>
                    _FileTile(item: items[index], spaceId: spaceId),
              ),
      ),
    );
  }
}

class _FileTile extends ConsumerWidget {
  const _FileTile({required this.item, required this.spaceId});

  final AttachmentItem item;
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nx = NxTheme.of(context);
    final api = ref.watch(attachmentsApiProvider);
    final attachment = item.attachment;
    final kind = FileKindBadge(name: attachment.name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NxSpacing.sp4),
      child: Row(
        children: [
          // 사진은 썸네일, 나머지는 확장자 — 둘 다 무엇인지 알려 주는 표시다.
          attachment.isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(NxRadius.sm),
                  child: Image.network(
                    api.urlFor(
                      spaceId: spaceId,
                      attachmentId: attachment.id,
                      thumb: true,
                    ),
                    headers: api.authHeaders,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => kind,
                  ),
                )
              : kind,
          const SizedBox(width: NxSpacing.sp5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nx.text.base,
                ),
                const SizedBox(height: NxSpacing.sp1),
                Text(formatBytes(attachment.sizeBytes), style: nx.text.mono),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilesError extends StatelessWidget {
  const _FilesError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // 서버 문구를 그대로 쓰지 않는다 — 실패 종류만 받아 앱이 자기 문구를 쓴다.
    final message = messageForError(error);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: NxTheme.of(context).text.secondary),
          const SizedBox(height: NxSpacing.sp4),
          NxButton(
            label: '다시 시도',
            kind: NxButtonKind.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
