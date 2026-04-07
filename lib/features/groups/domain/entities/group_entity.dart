// lib/features/groups/domain/entities/group_entity.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';

part 'group_entity.g.dart';

@HiveType(typeId: HiveTypeIds.group)
class GroupEntity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  String color;

  @HiveField(4)
  DateTime createdAt;

  GroupEntity({
    required this.id,
    required this.name,
    this.icon = 'folder',
    this.color = '#3B82F6',
    required this.createdAt,
  });

  factory GroupEntity.fromMap(Map<String, dynamic> map) => GroupEntity(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String? ?? 'folder',
        color: map['color'] as String? ?? '#3B82F6',
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'created_at': createdAt.toIso8601String(),
      };

  GroupEntity copyWith({
    String? name,
    String? icon,
    String? color,
  }) =>
      GroupEntity(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        createdAt: createdAt,
      );
}
