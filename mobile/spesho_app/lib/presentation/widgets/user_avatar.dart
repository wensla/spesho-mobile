import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Animated avatar using real human portrait photos.
/// Male users get a male photo, female users get a female photo.
/// Photo index is derived from username so each user always gets the same photo.
class UserAvatar extends StatefulWidget {
  final String username;
  final String displayName;
  final String? gender;
  final double radius;
  final bool showRing;
  final Color? ringColor;

  const UserAvatar({
    super.key,
    required this.username,
    required this.displayName,
    this.gender,
    this.radius = 20,
    this.showRing = false,
    this.ringColor,
  });

  /// Real human portrait photo — gender-specific, consistent per username.
  static String avatarUrl(String username, {int size = 80, String? gender}) {
    // Hash username to a stable index 0–99
    int hash = 0;
    for (final c in username.toLowerCase().trim().codeUnits) {
      hash = (hash * 31 + c) & 0xFFFFFFFF;
    }
    final index = hash % 99;
    final category = gender == 'female' ? 'women' : 'men';
    // wsrv.nl proxies the image and adds Access-Control-Allow-Origin: *
    // so Flutter web CanvasKit can render it without CORS errors
    return 'https://wsrv.nl/?url=randomuser.me/api/portraits/$category/$index.jpg&w=$size&h=$size&fit=cover&output=jpg';
  }

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.ringColor ?? AppTheme.primary;
    final size = widget.radius * 2;

    Widget avatar = ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: size,
          height: size,
          decoration: widget.showRing
              ? const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : null,
          padding: widget.showRing ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
          child: ClipOval(
            child: Image.network(
              UserAvatar.avatarUrl(widget.username,
                  size: (widget.radius * 4).toInt(), gender: widget.gender),
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return _InitialAvatar(
                    displayName: widget.displayName,
                    radius: widget.radius,
                    color: ringColor);
              },
              errorBuilder: (_, __, ___) => _InitialAvatar(
                  displayName: widget.displayName,
                  radius: widget.radius,
                  color: ringColor),
            ),
          ),
        ),
      ),
    );

    return avatar;
  }
}

class _InitialAvatar extends StatelessWidget {
  final String displayName;
  final double radius;
  final Color color;

  const _InitialAvatar({
    required this.displayName,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: color.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        (displayName.isNotEmpty ? displayName[0] : 'U').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
