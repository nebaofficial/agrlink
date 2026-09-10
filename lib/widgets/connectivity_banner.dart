import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Persistent banner that shows when device is offline.
/// Displays "Working offline — changes will sync when connected"
/// and briefly shows a green "Back online" banner on reconnection.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showBackOnline = false;
  bool _hasBeenOffline = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
    // Check initial state
    Connectivity().checkConnectivity().then(_onChanged);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final offline = results.contains(ConnectivityResult.none) || results.isEmpty;

    if (offline && !_isOffline) {
      // Just went offline
      setState(() {
        _isOffline = true;
        _hasBeenOffline = true;
        _showBackOnline = false;
      });
    } else if (!offline && _isOffline) {
      // Just came back online
      setState(() {
        _isOffline = false;
        if (_hasBeenOffline) {
          _showBackOnline = true;
        }
      });
      // Hide "Back online" banner after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showBackOnline = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Offline banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline ? 36 : (_showBackOnline ? 36 : 0),
          color: _isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          child: _isOffline
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Working offline — changes will sync when connected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : _showBackOnline
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_done, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Back online ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
        ),
        // Main content
        Expanded(child: widget.child),
      ],
    );
  }
}
