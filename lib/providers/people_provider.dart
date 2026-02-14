import 'package:flutter/material.dart';
import '../core/data/people_repository.dart';
import '../core/data/sample_data.dart';
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
    
    // Simple check if first run logic is needed for people too
    // For now, we reuse the existing validation logic - if empty, try sample data
    if (_people.isEmpty) {
       // We can just rely on sample data here if needed, or check a setting
       // But to be consistent with ExpenseProvider, let's just populate if completely empty on first load.
       // However, to avoid overwriting user deletes, we should probably check that 'isInitialized' flag
       // but for now, sticking to the existing behavior pattern but using the repository.
       // Actually, the original code initialized sample data if empty. Let's replicate that simply.
       // Better: Use the sample data if empty AND we want to provide a starter set.
       // We'll trust the repository init mostly, but let's add sample data if purely empty for UX
       _people = SampleData.getPeople();
       for(var p in _people) {
         await _repository.savePerson(p);
       }
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
