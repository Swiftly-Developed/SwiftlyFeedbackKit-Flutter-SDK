import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persisting FeedbackKit data.
class FeedbackKitStorage {
  static const String _userIdKey = 'feedbackkit_user_id';
  static const String _listSortKey = 'feedbackkit_list_sort';

  SharedPreferences? _prefs;

  /// Initializes the storage service.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Gets the stored user ID.
  Future<String?> getUserId() async {
    await init();
    return _prefs!.getString(_userIdKey);
  }

  /// Stores the user ID.
  Future<void> setUserId(String? userId) async {
    await init();
    if (userId != null) {
      await _prefs!.setString(_userIdKey, userId);
    } else {
      await _prefs!.remove(_userIdKey);
    }
  }

  /// Gets the feedback list's last sort, as a `FeedbackSortOption` name.
  Future<String?> getListSort() async {
    await init();
    return _prefs!.getString(_listSortKey);
  }

  /// Stores the feedback list's sort, as a `FeedbackSortOption` name.
  Future<void> setListSort(String sort) async {
    await init();
    await _prefs!.setString(_listSortKey, sort);
  }

  /// Clears all stored data.
  Future<void> clear() async {
    await init();
    await _prefs!.remove(_userIdKey);
    await _prefs!.remove(_listSortKey);
  }
}
