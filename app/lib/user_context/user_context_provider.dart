import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'event_settings.dart';

/// Provider de contexto de usuario/evento
///
/// Centraliza estado compartido entre flujos.
class UserContextProvider extends ChangeNotifier {
  static const _prefsEventIdKey = 'event_id';
  static const _prefsEventNameKey = 'event_name';
  static const _prefsEventDateKey = 'event_date';
  static const _prefsEventActiveKey = 'event_active';
  static const _prefsEventSettingsKey = 'event_settings';
  static const _prefsUserIdKey = 'user_id';
  static const _prefsIsAdminKey = 'is_admin';
  static const _prefsUserNameKey = 'user_name';

  bool _isInitialized = false;
  String? _userId;
  String? _userName;
  String? _eventId;
  String? _eventName;
  DateTime? _eventDate;
  bool _eventActive = false;
  UserEventSettings _settings = UserEventSettings.defaults();
  bool _isAdmin = false;

  bool get isInitialized => _isInitialized;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get eventId => _eventId;
  String? get eventName => _eventName;
  DateTime? get eventDate => _eventDate;
  bool get eventActive => _eventActive;
  UserEventSettings get settings => _settings;
  bool get isAdmin => _isAdmin;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_prefsUserIdKey);
    if (_userId == null || _userId!.isEmpty) {
      _userId = const Uuid().v4();
      await prefs.setString(_prefsUserIdKey, _userId!);
    }

    _userName = prefs.getString(_prefsUserNameKey);
    _eventId = prefs.getString(_prefsEventIdKey);
    _eventName = prefs.getString(_prefsEventNameKey);
    final rawDate = prefs.getString(_prefsEventDateKey);
    _eventDate = rawDate != null ? DateTime.tryParse(rawDate) : null;
    _eventActive = prefs.getBool(_prefsEventActiveKey) ?? false;

    final rawSettings = prefs.getString(_prefsEventSettingsKey);
    if (rawSettings != null && rawSettings.isNotEmpty) {
      _settings = UserEventSettings.fromMap(jsonDecode(rawSettings));
    }

    _isAdmin = prefs.getBool(_prefsIsAdminKey) ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    _userName = name.trim().isEmpty ? null : name.trim();
    if (_userName != null) {
      await prefs.setString(_prefsUserNameKey, _userName!);
    } else {
      await prefs.remove(_prefsUserNameKey);
    }
    notifyListeners();
  }

  Future<void> setEvent({
    required String eventId,
    required String eventName,
    required DateTime eventDate,
    required Map<String, dynamic> settings,
    required bool eventActive,
    bool isAdmin = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _eventId = eventId;
    _eventName = eventName;
    _eventDate = eventDate;
    _eventActive = eventActive;
    _settings = UserEventSettings.fromMap(settings);
    _isAdmin = isAdmin;

    await prefs.setString(_prefsEventIdKey, eventId);
    await prefs.setString(_prefsEventNameKey, eventName);
    await prefs.setString(_prefsEventDateKey, eventDate.toIso8601String());
    await prefs.setBool(_prefsEventActiveKey, eventActive);
    await prefs.setString(_prefsEventSettingsKey, jsonEncode(_settings.toMap()));
    await prefs.setBool(_prefsIsAdminKey, isAdmin);
    notifyListeners();
  }

  Future<void> clearEvent() async {
    final prefs = await SharedPreferences.getInstance();
    _eventId = null;
    _eventName = null;
    _eventDate = null;
    _eventActive = false;
    _settings = UserEventSettings.defaults();
    _isAdmin = false;

    await prefs.remove(_prefsEventIdKey);
    await prefs.remove(_prefsEventNameKey);
    await prefs.remove(_prefsEventDateKey);
    await prefs.remove(_prefsEventActiveKey);
    await prefs.remove(_prefsEventSettingsKey);
    await prefs.remove(_prefsIsAdminKey);
    notifyListeners();
  }
}
