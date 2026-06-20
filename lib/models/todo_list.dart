import 'package:flutter/material.dart';

class TodoList {
  const TodoList({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final int sortOrder;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  static List<IconData> get availableIcons => [
    Icons.work_rounded,
    Icons.person_rounded,
    Icons.school_rounded,
    Icons.favorite_rounded,
    Icons.lightbulb_rounded,
    Icons.home_rounded,
    Icons.shopping_cart_rounded,
    Icons.flight_rounded,
    Icons.pets_rounded,
    Icons.sports_esports_rounded,
    Icons.restaurant_rounded,
    Icons.payments_rounded,
  ];

  static const List<int> availableColorValues = [
    0xFF8F4E00,
    0xFF1D7860,
    0xFF2B5EB8,
    0xFFB83625,
    0xFF7540B8,
    0xFF1A7B84,
  ];

  factory TodoList.fromJson(Map<String, dynamic> json) {
    return TodoList(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'sortOrder': sortOrder,
    };
  }

  TodoList copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    int? sortOrder,
  }) {
    return TodoList(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
