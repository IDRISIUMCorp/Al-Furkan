import "package:al_quran_v3/src/theme/values/values.dart";
import "package:al_quran_v3/src/widget/jump_to_ayah/jump_to_ayah.dart";
import "package:flutter/material.dart";

Future<void> popupJumpToAyah({
  required BuildContext context,
  String? initAyahKey,
  required bool isAudioPlayer,
  bool? selectMultipleAndShare,
  Function(String ayahKey)? onPlaySelected,
  final Function(String ayahKey)? onSelectAyah,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "jump_to_ayah",
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Center(
          child: Dialog(
            insetPadding: const EdgeInsets.only(
              top: 20,
              left: 10,
              right: 10,
              bottom: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(roundedRadius),
            ),
            child: JumpToAyahView(
              initAyahKey: initAyahKey,
              isAudioPlayer: isAudioPlayer,
              onPlaySelected: onPlaySelected,
              selectMultipleAndShare: selectMultipleAndShare,
              onSelectAyah: onSelectAyah,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
