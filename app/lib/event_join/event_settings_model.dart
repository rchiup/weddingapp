/// Modelo de settings del evento
///
/// Representa flags de visibilidad y configuración de features.
class EventSettingsModel {
  final bool guestsVisible;
  final bool tablesVisible;
  final bool singlesEnabled;
  final bool photosEnabled;
  final bool giftRegistryEnabled;
  final String giftRegistryProvider;
  final String giftRegistryCode;
  final String? giftRegistryUrlOverride;
  final bool adminExportEnabled;

  EventSettingsModel({
    required this.guestsVisible,
    required this.tablesVisible,
    required this.singlesEnabled,
    required this.photosEnabled,
    required this.giftRegistryEnabled,
    required this.giftRegistryProvider,
    required this.giftRegistryCode,
    this.giftRegistryUrlOverride,
    required this.adminExportEnabled,
  });

  factory EventSettingsModel.fromMap(Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};
    return EventSettingsModel(
      guestsVisible: map['guestsVisible'] ?? false,
      tablesVisible: map['tablesVisible'] ?? true,
      singlesEnabled: map['singlesEnabled'] ?? false,
      photosEnabled: map['photosEnabled'] ?? true,
      giftRegistryEnabled: map['giftRegistryEnabled'] ?? false,
      giftRegistryProvider: map['giftRegistryProvider'] ?? 'other',
      giftRegistryCode: map['giftRegistryCode'] ?? '',
      giftRegistryUrlOverride: map['giftRegistryUrlOverride'],
      adminExportEnabled: map['adminExportEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guestsVisible': guestsVisible,
      'tablesVisible': tablesVisible,
      'singlesEnabled': singlesEnabled,
      'photosEnabled': photosEnabled,
      'giftRegistryEnabled': giftRegistryEnabled,
      'giftRegistryProvider': giftRegistryProvider,
      'giftRegistryCode': giftRegistryCode,
      'giftRegistryUrlOverride': giftRegistryUrlOverride,
      'adminExportEnabled': adminExportEnabled,
    };
  }
}
