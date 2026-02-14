import '../../models/person.dart';

abstract class PeopleRepository {
  Future<void> init();
  
  List<Person> getAllPeople();
  Future<void> savePerson(Person person);
  Future<void> deletePerson(String id);
  Future<void> clearAllPeople();
}
