// lib/features/links/domain/entities/link_entity.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';

part 'link_entity.g.dart';

@HiveType(typeId: HiveTypeIds.link)
class LinkEntity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String url;

  @HiveField(3)
  String description;

  @HiveField(4)
  String? groupId;

  @HiveField(5)
  bool isFavorite;

  @HiveField(6)
  int clickCount;

  @HiveField(7)
  DateTime? lastOpenedAt;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  String? faviconUrl;

  LinkEntity({
    required this.id,
    required this.title,
    required this.url,
    this.description = '',
    this.groupId,
    this.isFavorite = false,
    this.clickCount = 0,
    this.lastOpenedAt,
    required this.createdAt,
    required this.updatedAt,
    this.faviconUrl,
  });

  factory LinkEntity.fromMap(Map<String, dynamic> map) => LinkEntity(
        id: map['id'] as String,
        title: map['title'] as String,
        url: map['url'] as String,
        description: map['description'] as String? ?? '',
        groupId: map['group_id'] as String?,
        isFavorite: map['is_favorite'] as bool? ?? false,
        clickCount: map['click_count'] as int? ?? 0,
        lastOpenedAt: map['last_opened_at'] != null
            ? DateTime.parse(map['last_opened_at'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        faviconUrl: map['favicon_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'url': url,
        'description': description,
        'group_id': groupId,
        'is_favorite': isFavorite,
        'click_count': clickCount,
        'last_opened_at': lastOpenedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'favicon_url': faviconUrl,
      };

  LinkEntity copyWith({
    String? id,
    String? title,
    String? url,
    String? description,
    String? groupId,
    bool? isFavorite,
    int? clickCount,
    DateTime? lastOpenedAt,
    DateTime? updatedAt,
    String? faviconUrl,
  }) =>
      LinkEntity(
        id: id ?? this.id,
        title: title ?? this.title,
        url: url ?? this.url,
        description: description ?? this.description,
        groupId: groupId ?? this.groupId,
        isFavorite: isFavorite ?? this.isFavorite,
        clickCount: clickCount ?? this.clickCount,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        faviconUrl: faviconUrl ?? this.faviconUrl,
      );
}
