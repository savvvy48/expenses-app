import 'package:flutter_test/flutter_test.dart';
import 'package:daily_expenses/models/person.dart';

void main() {
  group('Person Model', () {
    test('should support phone number', () {
      final person = Person(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '123-456-7890',
      );

      expect(person.phone, '123-456-7890');
    });

    test('should serialize to map correctly with phone', () {
      final person = Person(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '123-456-7890',
      );

      final map = person.toMap();
      expect(map['phone'], '123-456-7890');
    });

    test('should deserialize from map correctly with phone', () {
      final map = {
        'id': '1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '123-456-7890',
        'role': 'Member',
        'status': 0,
      };

      final person = Person.fromMap(map);
      expect(person.phone, '123-456-7890');
    });
    
    test('should support null phone', () {
      final person = Person(
        id: '1',
        name: 'Jane Doe',
        email: 'jane@example.com',
      );
      
      expect(person.phone, null);
      final map = person.toMap();
      expect(map.containsKey('phone'), true);
      expect(map['phone'], null);
    });
  });
}
