// lib/widgets/common/offline_banner.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

/// Monitors network reachability and shows a subtle offline indicator.
/// Wrap around your root widget or place inside a Scaffold body column.
class OfflineAwareBanner extends StatefulWidget {
  final Widget child;
  const OfflineAwareBanner({super.key, required this.child});

  @override
  State<OfflineAwareBanner> createState() => _OfflineAwareBannerState();
}

class _OfflineAwareBannerState extends State<OfflineAwareBanner> {
  // Simple connectivity check via HTTP HEAD request
  bool _isOffline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  Future<void> _check() async {
    try {
      // Using dart:io to avoid extra dependency
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (mounted && online != !_isOffline) {
        setState(() => _isOffline = !online);
      }
    } catch (_) {
      if (mounted && !_isOffline) setState(() => _isOffline = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: AppColors.warning.withOpacity(0.9),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded,
                    color: Colors.black87, size: 14),
                SizedBox(width: 6),
                Text(
                  'Offline — changes will sync when connected',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Sora',
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -1, duration: 300.ms),
        Expanded(child: widget.child),
      ],
    );
  }
}

// Need this import
import 'dart:io' show InternetAddress;
