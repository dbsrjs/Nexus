import 'package:freezed_annotation/freezed_annotation.dart';

part 'space.freezed.dart';
part 'space.g.dart';

/// 스페이스 안에서의 내 역할. 서열은 guest < member < admin < owner
/// (server/src/spaces/space-role.ts).
@JsonEnum(valueField: 'wire')
enum SpaceRole {
  guest('guest', 0),
  member('member', 1),
  admin('admin', 2),
  owner('owner', 3);

  const SpaceRole(this.wire, this.rank);

  final String wire;
  final int rank;

  bool atLeast(SpaceRole minimum) => rank >= minimum.rank;
}

/// `GET /api/spaces` 의 한 항목.
///
/// 서버는 스페이스 레코드에 내 `role` 을 얹어서 준다
/// (server/src/spaces/spaces.service.ts 의 listForUser).
///
/// `storageUsedBytes` 같은 bigint 필드는 서버가 **문자열**로 내보낸다
/// (JSON 에 BigInt 를 그대로 담을 수 없어서다 — server/src/common/bigint-serializer.ts).
/// 지금 화면에서 쓰지 않으므로 모델에 넣지 않았다. 쓰게 되면 String 으로 받아야 한다.
@freezed
abstract class Space with _$Space {
  const factory Space({
    required String id,
    required String slug,
    required String name,
    required SpaceRole role,
    String? iconUrl,
    String? ownerId,
  }) = _Space;

  factory Space.fromJson(Map<String, dynamic> json) => _$SpaceFromJson(json);
}
