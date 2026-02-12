import 'package:flutter/material.dart';

enum PersonStatus { active, pending }

class Person {
  final String id;
  final String name;
  final String email;
  final String role;
  final PersonStatus status;
  final int? expiresInDays;
  final int avatarColorValue;

  Person({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'Member',
    this.status = PersonStatus.active,
    this.expiresInDays,
    int? avatarColorValue,
  }) : avatarColorValue = avatarColorValue ?? 0xFF2463EB;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get avatarColor => Color(avatarColorValue);

  Person copyWith({
    String? name,
    String? email,
    String? role,
    PersonStatus? status,
    int? expiresInDays,
    int? avatarColorValue,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      expiresInDays: expiresInDays ?? this.expiresInDays,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'status': status.index,
        'expiresInDays': expiresInDays,
        'avatarColorValue': avatarColorValue,
      };

  factory Person.fromMap(Map<dynamic, dynamic> map) => Person(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        role: map['role'] as String? ?? 'Member',
        status: PersonStatus.values[map['status'] as int? ?? 0],
        expiresInDays: map['expiresInDays'] as int?,
        avatarColorValue: map['avatarColorValue'] as int?,
      );
}
