import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/datasource/account_local_datasource.dart';
import '../../data/datasource/backup_local_datasource.dart';
import '../../data/datasource/budget_local_datasource.dart';
import '../../data/datasource/expense_local_datasource.dart';
import '../../data/datasource/recurring_subscription_local_datasource.dart';
import '../../../../core/utils/hive_bootstrap.dart';
import '../provider/preferences_providers.dart';

final backupLocalDatasourceProvider = Provider<BackupLocalDatasource>((ref) {
  return BackupLocalDatasource();
});

final backupControllerProvider = Provider<BackupController>((ref) {
  return BackupController(ref);
});

class BackupController {
  final Ref _ref;

  BackupController(this._ref);

  BackupLocalDatasource get _datasource =>
      _ref.read(backupLocalDatasourceProvider);

  Future<void> exportData() async {
    try {
      final backupFile = await _datasource.createBackup();

      // Share the file so user can save it anywhere
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'XPensa Data Backup',
      );

      // Clean up temporary file after sharing
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Exports all transactions as a CSV file and opens the system share sheet.
  Future<void> exportAsCSV() async {
    final csvFile = await _datasource.createCsvExport();
    try {
      await Share.shareXFiles(
        [XFile(csvFile.path, mimeType: 'text/csv')],
        subject: 'XPensa Transactions (CSV)',
      );
    } finally {
      if (await csvFile.exists()) await csvFile.delete();
    }
  }

  /// Exports all transactions as a JSON file and opens the system share sheet.
  Future<void> exportAsJSON() async {
    final jsonFile = await _datasource.createJsonExport();
    try {
      await Share.shareXFiles(
        [XFile(jsonFile.path, mimeType: 'application/json')],
        subject: 'XPensa Transactions (JSON)',
      );
    } finally {
      if (await jsonFile.exists()) await jsonFile.delete();
    }
  }

  /// Returns the app-scoped backup directory on external storage.
  ///
  /// This directory lives under `Android/data/<package>/files/XPensa/Backups/`
  /// which is accessible to the user via the Files app but requires **zero
  /// runtime permissions** to write from the app itself.  Falls back to the
  /// app's internal documents directory if external storage is unavailable.
  static Future<Directory> _defaultBackupDir() async {
    Directory base;
    try {
      // getExternalStorageDirectory returns the app-scoped external dir.
      // On Android this is /sdcard/Android/data/<pkg>/files — no permission needed.
      final ext = await getExternalStorageDirectory();
      base = ext ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      base = await getApplicationDocumentsDirectory();
    }
    final dir = Directory(p.join(base.path, 'XPensa', 'Backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns the effective backup directory: the user's saved path if valid,
  /// otherwise the app-scoped default (no runtime permission required).
  Future<Directory> _resolveBackupDir() async {
    final prefs = _ref.read(appPreferencesProvider).value;
    final savedPath = prefs?.backupDirectoryPath;
    if (savedPath != null) {
      final saved = Directory(savedPath);
      if (await saved.exists()) return saved;
    }
    final defaultDir = await _defaultBackupDir();
    // Persist the auto-resolved path so the Settings UI can show it.
    await _ref
        .read(appPreferencesControllerProvider)
        .setBackupDirectory(defaultDir.path);
    return defaultDir;
  }

  /// Creates a `.xpensa` backup immediately and saves it to the backup
  /// directory, creating it automatically if needed.
  ///
  /// No runtime storage permission is required — backups are written to the
  /// app-scoped external storage directory.
  ///
  /// Returns the [DateTime] of the backup on success.
  Future<DateTime?> backupNow() async {
    final targetDir = await _resolveBackupDir();

    final tmpFile = await _datasource.createBackup();
    try {
      final destPath = p.join(targetDir.path, p.basename(tmpFile.path));
      await tmpFile.copy(destPath);
    } finally {
      if (await tmpFile.exists()) await tmpFile.delete();
    }

    final now = DateTime.now();
    await _ref.read(appPreferencesControllerProvider).setLastBackup(now);
    return now;
  }

  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType
            .any, // .xpensa might not be recognized as a custom type easily
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final file = File(result.files.single.path!);

      // Basic validation: check extension if possible, or just attempt decode
      if (!file.path.endsWith(BackupLocalDatasource.backupExtension)) {
        throw Exception('Invalid file format. Please select a .xpensa file.');
      }

      // Close all Hive boxes before overwriting
      await Hive.close();

      await _datasource.restoreBackup(file);

      // Re-initialize Hive
      await HiveBootstrap.initialize();

      return true;
    } catch (e) {
      // Ensure Hive is re-initialized even on error if boxes were closed
      await HiveBootstrap.initialize();
      rethrow;
    }
  }

  /// Permanently clears all user data boxes (expenses, accounts, budgets,
  /// subscriptions). App preferences are intentionally preserved.
  Future<void> resetAllData() async {
    await Hive.box(ExpenseLocalDatasource.boxName).clear();
    await Hive.box(AccountLocalDatasource.boxName).clear();
    await Hive.box(BudgetLocalDatasource.boxName).clear();
    await Hive.box(RecurringSubscriptionLocalDatasource.boxName).clear();
  }
}
