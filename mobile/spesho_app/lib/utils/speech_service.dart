// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// One voice only:
///   male user   → female voice speaks
///   female user → male voice speaks
///   unknown     → female voice speaks (default)
class SpeechService {
  static void welcome(String name, String role, {String? gender}) {
    try {
      final text = _buildMessage(name, role);
      // male user → use female voice; female user → use male voice
      final useVoice = gender == 'female' ? 'male' : 'female';
      final safeText = text.replaceAll('"', '').replaceAll("'", "\\'");

      js.context.callMethod('eval', [
        '''(function(){
          try {
            var synth = window.speechSynthesis;
            if (!synth) return;
            synth.cancel();

            function speak(voices) {
              var chosen;
              if ("$useVoice" === "female") {
                chosen = voices.find(function(v){
                  return /female|zira|samantha|victoria|karen|moira/i.test(v.name)
                      && /en/i.test(v.lang);
                }) || voices.find(function(v){ return /en/i.test(v.lang); });
              } else {
                chosen = voices.find(function(v){
                  return /\\bmale\\b|david|alex|daniel|mark|james|fred/i.test(v.name)
                      && /en/i.test(v.lang);
                }) || (voices.filter(function(v){ return /en/i.test(v.lang); })[1]
                    || voices.find(function(v){ return /en/i.test(v.lang); }));
              }

              var u = new SpeechSynthesisUtterance('$safeText');
              u.lang   = 'en-US';
              u.rate   = 0.88;
              u.pitch  = "$useVoice" === "female" ? 1.25 : 0.80;
              u.volume = 1.0;
              if (chosen) u.voice = chosen;
              synth.speak(u);
            }

            var voices = synth.getVoices();
            if (voices.length > 0) {
              speak(voices);
            } else {
              synth.onvoiceschanged = function() { speak(synth.getVoices()); };
            }
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
