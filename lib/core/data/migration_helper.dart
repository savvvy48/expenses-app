import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class MigrationHelper {
  static const int _currentVersion = 1;
  static const String _versionKey = 'schema_version';

  static Future<void> checkAndMigrate() async {
    try {
      final settingsBox = await Hive.openBox(AppConstants.boxSettings);
      final storedVersion = settingsBox.get(_versionKey, defaultValue: 0) as int;

      if (storedVersion < _currentVersion) {
        log('Starting migration from version $storedVersion to $_currentVersion');
        
        // Execute migrations sequentially
        if (storedVersion < 1) {
          await _migrateToV1();
        }
        
        await settingsBox.put(_versionKey, _currentVersion);
        log('Migration completed successfully');
      }
    } catch (e, stack) {
      log('Migration failed: $e', error: e, stackTrace: stack);
      // Decide if we should rethrow or handle gracefully depending on severity
    }
  }

  static Future<void> _migrateToV1() async {
    // Example migration: ensure all expenses have a 'createdAt' field or similar
    // For now, this is a placeholder for future schema changes
    log('Executing V1 migration...');
  }
}
