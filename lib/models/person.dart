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

  final String? phone;

  static const List<int> avatarColors = [
    0xFFFF7675, 0xFF6C5CE7, 0xFF00B894, 0xFFFDCB6E, 
    0xFFE17055, 0xFF55EFC4, 0xFFA29BFE, 0xFFFD79A8,
    0xFF636E72, 0xFF0984E3, 0xFFD63031, 0xFFE84393
  ];

  Person({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'Member',
    this.status = PersonStatus.active,
    this.expiresInDays,
    int? avatarColorValue,
  }) : avatarColorValue = avatarColorValue ?? avatarColors[name.hashCode.abs() % avatarColors.length];

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
    String? phone,
    String? role,
    PersonStatus? status,
    int? expiresInDays,
    int? avatarColorValue,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
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
        'phone': phone,
        'role': role,
        'status': status.index,
        'expiresInDays': expiresInDays,
        'avatarColorValue': avatarColorValue,
      };

  factory Person.fromMap(Map<dynamic, dynamic> map) => Person(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        phone: map['phone'] as String?,
        role: map['role'] as String? ?? 'Member',
        status: PersonStatus.values[map['status'] as int? ?? 0],
        expiresInDays: map['expiresInDays'] as int?,
        avatarColorValue: map['avatarColorValue'] as int?,
      );
}
