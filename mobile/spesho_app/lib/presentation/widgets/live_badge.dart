import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

/// Pulsing green dot + "Updated HH:mm:ss • every Xs" label.
class LiveBadge extends StatefulWidget {
  final DateTime? lastUpdated;
  final Duration interval;
  const LiveBadge({super.key, required this.lastUpdated, required this.interval});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    // Rebuild every second so the timestamp stays current
    _tick = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = widget.lastUpdated;
    final label = ts == null
        ? 'Loading…'
        : 'Updated ${DateFormat('HH:mm:ss').format(ts)}  •  auto-refresh every ${widget.interval.inSeconds}s';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        FadeTransition(
          opacity: _pulse,
          child: Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    );
  }
}
