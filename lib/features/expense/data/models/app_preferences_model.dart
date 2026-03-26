import 'package:hive/hive.dart';

class AppPreferencesModel {
  const AppPreferencesModel({
    required this.themeModeKey,
    required this.privacyModeEnabled,
    required this.smartRemindersEnabled,
    required this.locale,
    required this.currencySymbol,
  });

  static const AppPreferencesModel defaults = AppPreferencesModel(
    themeModeKey: 'light',
    privacyModeEnabled: false,
    smartRemindersEnabled: true,
    locale: 'en_IN',
    currencySymbol: '₹',
  );

  final String themeModeKey;
  final bool privacyModeEnabled;
  final bool smartRemindersEnabled;
  final String locale;
  final String currencySymbol;

  AppPreferencesModel copyWith({
    String? themeModeKey,
    bool? privacyModeEnabled,
    bool? smartRemindersEnabled,
    String? locale,
    String? currencySymbol,
  }) {
    return AppPreferencesModel(
      themeModeKey: themeModeKey ?? this.themeModeKey,
      privacyModeEnabled: privacyModeEnabled ?? this.privacyModeEnabled,
      smartRemindersEnabled:
          smartRemindersEnabled ?? this.smartRemindersEnabled,
      locale: locale ?? this.locale,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}

class AppPreferencesModelAdapter extends TypeAdapter<AppPreferencesModel> {
  static const int typeIdValue = 3;

  @override
  final int typeId = typeIdValue;

  @override
  AppPreferencesModel read(BinaryReader reader) {
    return AppPreferencesModel(
      themeModeKey: reader.readString(),
      privacyModeEnabled: reader.readBool(),
      smartRemindersEnabled: reader.readBool(),
      locale: reader.readString(),
      currencySymbol: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, AppPreferencesModel obj) {
    writer
      ..writeString(obj.themeModeKey)
      ..writeBool(obj.privacyModeEnabled)
      ..writeBool(obj.smartRemindersEnabled)
      ..writeString(obj.locale)
      ..writeString(obj.currencySymbol);
  }
}
