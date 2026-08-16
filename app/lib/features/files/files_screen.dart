import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api/api_failure.dart';
import '../../domain/models/attachment_item.dart';
import '../chat/attachment_widgets.dart';
import '../chat/message_controller.dart';
import '../space/space_controller.dart';

/// 스페이스에 올라온 파일 목록.
///
/// **캐시하지 않는다.** 대화를 읽는 데 필요한 값이 아니고(오프라인에서는 어차피
/// 내려받지도 못한다), 자주 여는 화면도 아니다. 멤버 목록과 같은 판단이다.
///
/// 서버가 **볼 수 있는 채널의 것만** 준다 — 비공개 채널의 파일은 여기 없다.
final spaceFilesProvider =
    FutureProvider.autoDispose<List<AttachmentItem>>((ref) async {
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

    return Scaffold(
      appBar: AppBar(title: const Text('파일')),
      body: files.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _FilesError(
          error: error,
          onRetry: () => ref.invalidate(spaceFilesProvider),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('아직 올라온 파일이 없습니다.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(spaceFilesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(NexusSpacing.sp4),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) =>
                      _FileTile(item: items[index], spaceId: spaceId),
                ),
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
    final theme = Theme.of(context);
    final api = ref.watch(attachmentsApiProvider);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: item.attachment.isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(NexusRadius.sm),
              child: Image.network(
                api.urlFor(
                  spaceId: spaceId,
                  attachmentId: item.attachment.id,
                  thumb: true,
                ),
                headers: api.authHeaders,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(iconForAttachment(item.attachment)),
              ),
            )
          : Icon(iconForAttachment(item.attachment)),
      title: Text(
        item.attachment.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        formatBytes(item.attachment.sizeBytes),
        style: theme.textTheme.labelSmall,
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
    final message = error is ApiException
        ? messageFor((error as ApiException).failure)
        : messageFor(ApiFailure.server);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: NexusSpacing.sp3),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
