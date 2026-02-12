import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/person.dart';

class PeopleProvider extends ChangeNotifier {
  static const String _boxName = 'people';
  List<Person> _people = [];

  List<Person> get people => List.unmodifiable(_people);
  List<Person> get activeMembers =>
      _people.where((p) => p.status == PersonStatus.active).toList();
  List<Person> get pendingInvites =>
      _people.where((p) => p.status == PersonStatus.pending).toList();

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    _people = box.values
        .map((e) => Person.fromMap(e as Map<dynamic, dynamic>))
        .toList();
    if (_people.isEmpty) _loadSampleData();
    notifyListeners();
  }

  void _loadSampleData() {
    _people = [
      Person(id: const Uuid().v4(), name: 'Alex Sterling',
        email: 'alex.s@company.com', role: 'Owner',
        avatarColorValue: 0xFF2463EB),
      Person(id: const Uuid().v4(), name: 'Sarah Chen',
        email: 's.chen@finance.io', role: 'Editor',
        avatarColorValue: 0xFF6C5CE7),
      Person(id: const Uuid().v4(), name: 'Marcus Vance',
        email: 'marcus.v@company.com', role: 'Viewer',
        avatarColorValue: 0xFF00B894),
      Person(id: const Uuid().v4(), name: 'Jessica Lee',
        email: 'j.lee@design.co', role: 'Editor',
        avatarColorValue: 0xFFFF7675),
      Person(id: const Uuid().v4(), name: 'Tom Harrison',
        email: 't.harrison@extern.al', role: 'Viewer',
        status: PersonStatus.pending, expiresInDays: 2,
        avatarColorValue: 0xFFFDCB6E),
      Person(id: const Uuid().v4(), name: 'David Kim',
        email: 'david.k@agency.net', role: 'Viewer',
        status: PersonStatus.pending, expiresInDays: 5,
        avatarColorValue: 0xFFE17055),
    ];
    _saveAll();
  }

  Future<void> addPerson(Person person) async {
    _people.add(person);
    await _save(person);
    notifyListeners();
  }

  Future<void> updatePerson(Person person) async {
    final idx = _people.indexWhere((p) => p.id == person.id);
    if (idx != -1) {
      _people[idx] = person;
      await _save(person);
      notifyListeners();
    }
  }

  Future<void> deletePerson(String id) async {
    _people.removeWhere((p) => p.id == id);
    final box = await Hive.openBox(_boxName);
    await box.delete(id);
    notifyListeners();
  }

  Future<void> _save(Person person) async {
    final box = await Hive.openBox(_boxName);
    await box.put(person.id, person.toMap());
  }

  Future<void> _saveAll() async {
    final box = await Hive.openBox(_boxName);
    for (final p in _people) {
      await box.put(p.id, p.toMap());
    }
  }
}
