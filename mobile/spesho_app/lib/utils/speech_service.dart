// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// ONE voice speaks the full message.
/// male user   → female voice (pitch high)
/// female user → male voice  (pitch low)
class SpeechService {
  static void welcome(String name, String role, {String? gender}) {
    try {
      final text = _buildMessage(name, role)
          .replaceAll("'", " ")
          .replaceAll('"', ' ');

      // male user → high pitch (sounds female), female user → low pitch (sounds male)
      final pitch = gender == 'female' ? 0.75 : 1.30;

      js.context.callMethod('eval', [
        '''(function(){
          try {
            var synth = window.speechSynthesis;
            if (!synth) return;
            synth.cancel();
            var u = new SpeechSynthesisUtterance("$text");
            u.lang   = "en-US";
            u.rate   = 0.88;
            u.pitch  = $pitch;
            u.volume = 1.0;
            synth.speak(u);
          } catch(e) {}
        })()'''
      ]);
    } catch (_) {}
  }

  static String _buildMessage(String name, String role) {
    final first = name.split(' ').first;
    final hour = DateTime.now().hour;
    final timeGreet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final roleDesc = switch (role) {
      'super_admin' => 'System Administrator',
      'manager'     => 'Business Manager',
      _             => 'team member',
    };

    final closing = switch (role) {
      'super_admin' => 'You have full access to all system operations. Have a productive day.',
      'manager'     => 'Your shops are ready. Wishing you great business today.',
      _             => 'You are all set. Have a wonderful working day.',
    };

    return '$timeGreet $first. Welcome to Spesho. '
        'You are logged in as $roleDesc. $closing';
  }
}
