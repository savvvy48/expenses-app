import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/person.dart';
import '../constants/app_constants.dart';
import 'people_repository.dart';

class HivePeopleRepository implements PeopleRepository {
  late Box<Map> _peopleBox;

  @override
  Future<void> init() async {
    try {
      _peopleBox = await Hive.openBox<Map>(AppConstants.boxPeople);
    } catch (e, stack) {
      log('Error initializing people box: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  List<Person> getAllPeople() {
    try {
      return _peopleBox.values
          .map((e) => Person.fromMap(e))
          .toList();
    } catch (e, stack) {
      log('Error fetching people: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<void> savePerson(Person person) async {
    try {
      await _peopleBox.put(person.id, person.toMap());
    } catch (e, stack) {
      log('Error saving person: $e', error: e, stackTrace: stack);
      throw Exception('Failed to save person');
    }
  }

  @override
  Future<void> deletePerson(String id) async {
    try {
      await _peopleBox.delete(id);
    } catch (e, stack) {
      log('Error deleting person: $e', error: e, stackTrace: stack);
      throw Exception('Failed to delete person');
    }
  }
  
  @override
  Future<void> clearAllPeople() async {
    try {
      await _peopleBox.clear();
    } catch (e, stack) {
      log('Error clearing people: $e', error: e, stackTrace: stack);
      throw Exception('Failed to clear people data');
    }
  }
}
