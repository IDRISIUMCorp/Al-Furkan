import "package:flutter/foundation.dart";

@immutable
class ReaderUIState {
  final bool isUIVisible;
  final bool isAudioPlaying;
  final int lastReadPage;
  final String? lastReadAyahKey;

  const ReaderUIState({
    this.isUIVisible = true,
    this.isAudioPlaying = false,
    this.lastReadPage = 1,
    this.lastReadAyahKey,
  });

  ReaderUIState copyWith({
    bool? isUIVisible,
    bool? isAudioPlaying,
    int? lastReadPage,
    String? lastReadAyahKey,
  }) {
    return ReaderUIState(
      isUIVisible: isUIVisible ?? this.isUIVisible,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastReadAyahKey: lastReadAyahKey ?? this.lastReadAyahKey,
    );
  }
}
