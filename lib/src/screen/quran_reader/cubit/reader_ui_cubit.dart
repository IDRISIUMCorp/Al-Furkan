import "package:flutter_bloc/flutter_bloc.dart";
import "package:shared_preferences/shared_preferences.dart";

import "reader_ui_state.dart";

class ReaderUICubit extends Cubit<ReaderUIState> {
  ReaderUICubit() : super(const ReaderUIState()) {
    _loadLastReadPosition();
  }

  static const String _keyLastReadPage = "last_read_page";
  static const String _keyLastReadAyahKey = "last_read_ayah_key";

  /// Toggle UI visibility (AppBar + BottomBar)
  void toggleUIVisibility() {
    emit(state.copyWith(isUIVisible: !state.isUIVisible));
  }

  /// Show UI
  void showUI() {
    if (!state.isUIVisible) {
      emit(state.copyWith(isUIVisible: true));
    }
  }

  /// Hide UI
  void hideUI() {
    if (state.isUIVisible) {
      emit(state.copyWith(isUIVisible: false));
    }
  }

  /// Set audio playing state
  void setAudioPlaying(bool isPlaying) {
    emit(state.copyWith(isAudioPlaying: isPlaying));
  }

  /// Save last read position
  Future<void> saveLastReadPosition({
    required int pageNumber,
    required String ayahKey,
  }) async {
    emit(state.copyWith(
      lastReadPage: pageNumber,
      lastReadAyahKey: ayahKey,
    ));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastReadPage, pageNumber);
    await prefs.setString(_keyLastReadAyahKey, ayahKey);
  }

  /// Load last read position from storage
  Future<void> _loadLastReadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final page = prefs.getInt(_keyLastReadPage) ?? 1;
    final ayahKey = prefs.getString(_keyLastReadAyahKey);
    
    emit(state.copyWith(
      lastReadPage: page,
      lastReadAyahKey: ayahKey,
    ));
  }

  /// Get last read ayah key for navigation
  String? get lastReadAyahKey => state.lastReadAyahKey;
  
  /// Get last read page number
  int get lastReadPage => state.lastReadPage;
}
