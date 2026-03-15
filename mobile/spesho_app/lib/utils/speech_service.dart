// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// Speaks a bilingual (Swahili + English) welcome message on login.
/// Two utterances are queued — Swahili first, then English.
class SpeechService {
  static void welcome(String name, String role) {
    try {
      final sw = _swahiliMessage(name, role).replaceAll("'", "\\'");
      final en = _englishMessage(name, role).replaceAll("'", "\\'");

      js.context.callMethod('eval', [
        '''(function(){
          try {
            if (!window.speechSynthesis) return;
            window.speechSynthesis.cancel();

            // — Swahili utterance —
            var u1 = new SpeechSynthesisUtterance('$sw');
            u1.lang = 'sw-TZ';
            u1.rate = 0.90;
            u1.pitch = 1.05;
            u1.volume = 1.0;

            // — English utterance —
            var u2 = new SpeechSynthesisUtterance('$en');
            u2.lang = 'en-US';
            u2.rate = 0.90;
            u2.pitch = 1.05;
            u2.volume = 1.0;

            window.speechSynthesis.speak(u1);
            window.speechSynthesis.speak(u2);
          } catch(e) {}
        })()'''
      ]);
    } catch (_) {}
  }

  // ── Swahili ────────────────────────────────────────────────────────────────

  static String _swahiliMessage(String name, String role) {
    final first = name.split(' ').first;
    final hour = DateTime.now().hour;

    if (hour < 12) {
      // Morning — exact phrase requested
      return 'Salaama, karibu Spesho, mfumo mkubwa, malengo makubwa. '
          '${_swRole(role, first)}';
    } else if (hour < 17) {
      return 'Habari za mchana $first. Karibu mfumo wa Spesho. '
          '${_swRole(role, first)}';
    } else {
      return 'Habari za jioni $first. Karibu mfumo wa Spesho. '
          '${_swRole(role, first)}';
    }
  }

  static String _swRole(String role, String first) {
    switch (role) {
      case 'super_admin':
        return 'Unaingia kama Msimamizi Mkuu. Una mamlaka ya kuona shughuli zote. Siku njema.';
      case 'manager':
        return 'Unaingia kama Meneja $first. Maduka yako yako tayari. Biashara nzuri.';
      default:
        return 'Uko tayari $first. Fanya kazi nzuri leo.';
    }
  }

  // ── English ────────────────────────────────────────────────────────────────

  static String _englishMessage(String name, String role) {
    final first = name.split(' ').first;
    final hour = DateTime.now().hour;
    final timeGreet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    switch (role) {
      case 'super_admin':
        return '$timeGreet $first. Welcome to Spesho, the powerful grain management system. '
            'You are logged in as System Administrator. Have a productive day.';
      case 'manager':
        return '$timeGreet $first. Welcome back to Spesho. '
            'Your shops are ready. Wishing you great business today.';
      default:
        return '$timeGreet $first. Welcome to Spesho. '
            'You are all set. Have a great working day.';
    }
  }
}
