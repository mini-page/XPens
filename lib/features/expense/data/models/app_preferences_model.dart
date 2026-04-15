import 'package:hive/hive.dart';

class AppPreferencesModel {
  const AppPreferencesModel({
    required this.themeModeKey,
    required this.privacyModeEnabled,
    required this.smartRemindersEnabled,
    required this.locale,
    required this.currencySymbol,
    required this.isOnboardingCompleted,
    this.autoBackupEnabled = false,
    this.backupFrequency = 'daily',
    this.backupDirectoryPath,
    this.lastBackupDateTime,
    this.disabledExpenseCategories = const <String>[],
    this.disabledIncomeCategories = const <String>[],
    this.disabledAccountIds = const <String>[],
  });

  static const AppPreferencesModel defaults = AppPreferencesModel(
    themeModeKey: 'light',
    privacyModeEnabled: false,
    smartRemindersEnabled: true,
    locale: 'en_IN',
    currencySymbol: '₹',
    isOnboardingCompleted: false,
    autoBackupEnabled: false,
    backupFrequency: 'daily',
    disabledExpenseCategories: <String>[],
    disabledIncomeCategories: <String>[],
    disabledAccountIds: <String>[],
  );

  final String themeModeKey;
  final bool privacyModeEnabled;
  final bool smartRemindersEnabled;
  final String locale;
  final String currencySymbol;
  final bool isOnboardingCompleted;
  final bool autoBackupEnabled;
  final String backupFrequency;
  final String? backupDirectoryPath;
  final DateTime? lastBackupDateTime;
  final List<String> disabledExpenseCategories;
  final List<String> disabledIncomeCategories;
  final List<String> disabledAccountIds;

  AppPreferencesModel copyWith({
    String? themeModeKey,
    bool? privacyModeEnabled,
    bool? smartRemindersEnabled,
    String? locale,
    String? currencySymbol,
    bool? isOnboardingCompleted,
    bool? autoBackupEnabled,
    String? backupFrequency,
    String? backupDirectoryPath,
    DateTime? lastBackupDateTime,
    List<String>? disabledExpenseCategories,
    List<String>? disabledIncomeCategories,
    List<String>? disabledAccountIds,
    bool clearBackupDirectory = false,
  }) {
    return AppPreferencesModel(
      themeModeKey: themeModeKey ?? this.themeModeKey,
      privacyModeEnabled: privacyModeEnabled ?? this.privacyModeEnabled,
      smartRemindersEnabled:
          smartRemindersEnabled ?? this.smartRemindersEnabled,
      locale: locale ?? this.locale,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      backupDirectoryPath: clearBackupDirectory
          ? null
          : (backupDirectoryPath ?? this.backupDirectoryPath),
      lastBackupDateTime: lastBackupDateTime ?? this.lastBackupDateTime,
      disabledExpenseCategories:
          disabledExpenseCategories ?? this.disabledExpenseCategories,
      disabledIncomeCategories:
          disabledIncomeCategories ?? this.disabledIncomeCategories,
      disabledAccountIds: disabledAccountIds ?? this.disabledAccountIds,
    );
  }
}

class AppPreferencesModelAdapter extends TypeAdapter<AppPreferencesModel> {
  static const int typeIdValue = 3;

  @override
  final int typeId = typeIdValue;

  @override
  AppPreferencesModel read(BinaryReader reader) {
    final themeModeKey = reader.readString();
    final privacyModeEnabled = reader.readBool();
    final smartRemindersEnabled = reader.readBool();

    // Defaults for existing fields
    String locale = AppPreferencesModel.defaults.locale;
    String currencySymbol = AppPreferencesModel.defaults.currencySymbol;
    bool isOnboardingCompleted =
        AppPreferencesModel.defaults.isOnboardingCompleted;
    bool autoBackupEnabled = AppPreferencesModel.defaults.autoBackupEnabled;
    String backupFrequency = AppPreferencesModel.defaults.backupFrequency;
    String? backupDirectoryPath;
    DateTime? lastBackupDateTime;
    List<String> disabledExpenseCategories =
        AppPreferencesModel.defaults.disabledExpenseCategories;
    List<String> disabledIncomeCategories =
        AppPreferencesModel.defaults.disabledIncomeCategories;
    List<String> disabledAccountIds =
        AppPreferencesModel.defaults.disabledAccountIds;

    try {
      if (reader.availableBytes > 0) locale = reader.readString();
      if (reader.availableBytes > 0) currencySymbol = reader.readString();
      if (reader.availableBytes > 0) isOnboardingCompleted = reader.readBool();
      if (reader.availableBytes > 0) autoBackupEnabled = reader.readBool();
      if (reader.availableBytes > 0) backupFrequency = reader.readString();
      if (reader.availableBytes > 0) {
        final path = reader.readString();
        backupDirectoryPath = path.isEmpty ? null : path;
      }
      if (reader.availableBytes > 0) {
        final millis = reader.readInt();
        lastBackupDateTime =
            millis == 0 ? null : DateTime.fromMillisecondsSinceEpoch(millis);
      }
      if (reader.availableBytes > 0) {
        disabledExpenseCategories = _readStringList(reader);
      }
      if (reader.availableBytes > 0) {
        disabledIncomeCategories = _readStringList(reader);
      }
      if (reader.availableBytes > 0) {
        disabledAccountIds = _readStringList(reader);
      }
    } catch (_) {
      // Fallback if reading fails
    }

    return AppPreferencesModel(
      themeModeKey: themeModeKey,
      privacyModeEnabled: privacyModeEnabled,
      smartRemindersEnabled: smartRemindersEnabled,
      locale: locale,
      currencySymbol: currencySymbol,
      isOnboardingCompleted: isOnboardingCompleted,
      autoBackupEnabled: autoBackupEnabled,
      backupFrequency: backupFrequency,
      backupDirectoryPath: backupDirectoryPath,
      lastBackupDateTime: lastBackupDateTime,
      disabledExpenseCategories: disabledExpenseCategories,
      disabledIncomeCategories: disabledIncomeCategories,
      disabledAccountIds: disabledAccountIds,
    );
  }

  @override
  void write(BinaryWriter writer, AppPreferencesModel obj) {
    writer
      ..writeString(obj.themeModeKey)
      ..writeBool(obj.privacyModeEnabled)
      ..writeBool(obj.smartRemindersEnabled)
      ..writeString(obj.locale)
      ..writeString(obj.currencySymbol)
      ..writeBool(obj.isOnboardingCompleted)
      ..writeBool(obj.autoBackupEnabled)
      ..writeString(obj.backupFrequency)
      ..writeString(obj.backupDirectoryPath ?? '')
      ..writeInt(obj.lastBackupDateTime?.millisecondsSinceEpoch ?? 0);

    _writeStringList(writer, obj.disabledExpenseCategories);
    _writeStringList(writer, obj.disabledIncomeCategories);
    _writeStringList(writer, obj.disabledAccountIds);
  }

  List<String> _readStringList(BinaryReader reader) {
    final length = reader.readInt();
    return List<String>.generate(length, (_) => reader.readString());
  }

  void _writeStringList(BinaryWriter writer, List<String> values) {
    writer.writeInt(values.length);
    for (final value in values) {
      writer.writeString(value);
    }
  }
}
