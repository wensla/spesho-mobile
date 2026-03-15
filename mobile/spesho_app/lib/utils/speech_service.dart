// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// Bilingual English welcome — female and male voices alternate.
class SpeechService {
  static void welcome(String name, String role, {String? gender}) {
    try {
      final parts = _buildParts(name, role, gender: gender);

      // Build JS array of {text, gender} objects
      final partsJs = parts
          .map((p) => '{text:"${p.$1.replaceAll('"', '')}",gender:"${p.$2}"}')
          .join(',');

      js.context.callMethod('eval', [
        '''(function(){
          try {
            var synth = window.speechSynthesis;
            if (!synth) return;
            synth.cancel();

            var parts = [$partsJs];

            function speak(voices) {
              // Pick female voice (higher pitch, softer)
              var fv = voices.find(function(v){
                return /female|zira|samantha|victoria|karen|moira/i.test(v.name)
                    && /en/i.test(v.lang);
              }) || voices.find(function(v){ return /en/i.test(v.lang); });

              // Pick male voice (lower pitch, deeper) — different from female
              var mv = voices.find(function(v){
                return /male|david|alex|daniel|mark|james|fred/i.test(v.name)
                    && /en/i.test(v.lang);
              }) || (voices.filter(function(v){ return /en/i.test(v.lang); })[1] || fv);

              parts.forEach(function(p) {
                var u = new SpeechSynthesisUtterance(p.text);
                u.lang  = 'en-US';
                u.rate  = 0.88;
                if (p.gender === 'female') {
                  u.pitch = 1.25;
                  u.volume = 1.0;
                  if (fv) u.voice = fv;
                } else {
                  u.pitch = 0.82;
                  u.volume = 1.0;
                  if (mv) u.voice = mv;
                }
                synth.speak(u);
              });
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

  /// Returns list of (text, gender) pairs that alternate female → male → female…
  static List<(String, String)> _buildParts(String name, String role, {String? gender}) {
    final first = name.split(' ').first;
    final hour  = DateTime.now().hour;

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

    final closingF = switch (role) {
      'super_admin' => 'You have full access to all system operations.',
      'manager'     => 'Your shops are ready and waiting for you.',
      _             => 'You are all set and ready to go.',
    };

    final closingM = switch (role) {
      'super_admin' => 'Have a powerful and productive day.',
      'manager'     => 'Wishing you great business today.',
      _             => 'Have a wonderful working day.',
    };

    // If user is female → male voice greets her personally (opposite attracts)
    // If user is male   → female voice greets him personally
    // Unknown           → default female → male alternation
    final personalVoice = gender == 'female' ? 'male' : 'female';
    final responseVoice = gender == 'female' ? 'female' : 'male';

    return [
      ('Welcome to Spesho!',                 responseVoice),
      ('$timeGreet, $first.',                personalVoice),
      ('You are logged in as $roleDesc.',    responseVoice),
      (closingF,                             personalVoice),
      (closingM,                             responseVoice),
    ];
  }
}
