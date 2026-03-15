// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// Speaks a personalised Swahili welcome using the browser Web Speech API.
/// Fails silently if the browser does not support it.
class SpeechService {
  static void welcome(String name, String role) {
    try {
      final text = _buildMessage(name, role).replaceAll("'", "\\'");
      js.context.callMethod('eval', [
        '''(function(){
          try {
            if (!window.speechSynthesis) return;
            window.speechSynthesis.cancel();
            var u = new SpeechSynthesisUtterance('$text');
            u.lang = 'sw-TZ';
            u.rate = 0.88;
            u.pitch = 1.05;
            u.volume = 1.0;
            window.speechSynthesis.speak(u);
          } catch(e) {}
        })()'''
      ]);
    } catch (_) {}
  }

  static String _buildMessage(String name, String role) {
    final greeting = _timeGreeting();
    final first = name.split(' ').first;
    switch (role) {
      case 'super_admin':
        return '$greeting $first. Karibu sana mfumo wa Spesho. '
            'Unaingia kama Msimamizi Mkuu wa mfumo. '
            'Una mamlaka ya kuona shughuli zote. Siku njema ya kazi.';
      case 'manager':
        return '$greeting $first. Karibu mfumo wa Spesho. '
            'Unaingia kama Meneja wa biashara. '
            'Maduka yako yako tayari. Biashara nzuri leo.';
      default:
        return '$greeting $first. Karibu mfumo wa Spesho. '
            'Uko tayari kuanza kazi. Fanya kazi nzuri leo.';
    }
  }

  static String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Habari za asubuhi,';
    if (hour < 17) return 'Habari za mchana,';
    return 'Habari za jioni,';
  }
}
