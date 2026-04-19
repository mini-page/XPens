import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
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

  /// Creates a `.xpensa` backup immediately and saves it to the configured
  /// backup directory. Returns the [DateTime] of the backup on success, or
  /// `null` if no backup directory is configured or the directory is missing.
  Future<DateTime?> backupNow() async {
    final prefs = _ref.read(appPreferencesProvider).value;
    final backupPath = prefs?.backupDirectoryPath;
    if (backupPath == null) return null;

    final targetDir = Directory(backupPath);
    if (!await targetDir.exists()) return null;

    // Create .xpensa in app docs dir, then copy to backup directory.
    final tmpFile = await _datasource.createBackup();
    try {
      final destPath =
          p.join(targetDir.path, p.basename(tmpFile.path));
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
