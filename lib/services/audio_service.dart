import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AUDIO SERVICE
// ═══════════════════════════════════════════════════════════════════════════════
// لتفعيل الأصوات:
//   1. أضف ملفات .mp3 في assets/sounds/  (راجع assets/sounds/README.txt)
//   2. أضف إلى pubspec.yaml:
//        audioplayers: ^6.0.0
//   3. احذف التعليقات وفعّل الكود أدناه
// ═══════════════════════════════════════════════════════════════════════════════

class AudioService {
  static bool _enabled = true;

  static void setEnabled(bool v) => _enabled = v;

  // استخدام HapticFeedback مؤقتاً حتى إضافة ملفات الصوت
  static void playClick()   => _enabled ? HapticFeedback.selectionClick()  : null;
  static void playCorrect() => _enabled ? HapticFeedback.lightImpact()     : null;
  static void playWrong()   => _enabled ? HapticFeedback.heavyImpact()     : null;
  static void playStreak()  => _enabled ? HapticFeedback.mediumImpact()    : null;
  static void playThunder() => _enabled ? HapticFeedback.vibrate()         : null;
  static void playComplete(){ if(_enabled){ HapticFeedback.mediumImpact(); } }

  // ── كود audioplayers (فعّله بعد إضافة الملفات) ────────────────────────
  //
  // import 'package:audioplayers/audioplayers.dart';
  // static final AudioPlayer _player = AudioPlayer();
  //
  // static Future<void> _play(String file) async {
  //   if (!_enabled) return;
  //   try {
  //     await _player.play(AssetSource('sounds/$file'));
  //   } catch (_) {}
  // }
  //
  // static void playClick()   => _play('click.mp3');
  // static void playCorrect() => _play('correct.mp3');
  // static void playWrong()   => _play('wrong.mp3');
  // static void playStreak()  => _play('streak.mp3');
  // static void playThunder() => _play('thunder.mp3');
  // static void playComplete(){ _play('complete.mp3'); }
}
