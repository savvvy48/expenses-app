import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/data/people_repository.dart';
import '../models/person.dart';

class PeopleProvider extends ChangeNotifier {
  final PeopleRepository _repository;
  List<Person> _people = [];

  PeopleProvider(this._repository);

  List<Person> get people => List.unmodifiable(_people);
  List<Person> get activeMembers =>
      _people.where((p) => p.status == PersonStatus.active).toList();
  List<Person> get pendingInvites =>
      _people.where((p) => p.status == PersonStatus.pending).toList();

  Future<void> init() async {
    await _repository.init();
    _people = _repository.getAllPeople();
    
    final settings = await Hive.openBox('settings');
    final isFirstRun = settings.get('isFirstRun_people', defaultValue: true) as bool;

    if (_people.isEmpty && isFirstRun) {
       _people = [
         Person(id: 'sample_1', name: 'Alice', email: 'alice@email.com'),
         Person(id: 'sample_2', name: 'Bob', email: 'bob@email.com'),
       ];
       for(var p in _people) {
         await _repository.savePerson(p);
       }
       await settings.put('isFirstRun_people', false);
    } else if (isFirstRun) {
       await settings.put('isFirstRun_people', false);
    }
    notifyListeners();
  }

  Future<void> addPerson(Person person) async {
    _people.add(person);
    notifyListeners();
    await _repository.savePerson(person);
  }

  Future<void> updatePerson(Person person) async {
    final idx = _people.indexWhere((p) => p.id == person.id);
    if (idx != -1) {
      _people[idx] = person;
      notifyListeners();
      await _repository.savePerson(person);
    }
  }

  Future<void> deletePerson(String id) async {
    _people.removeWhere((p) => p.id == id);
    notifyListeners();
    await _repository.deletePerson(id);
  }
}
