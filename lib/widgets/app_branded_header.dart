import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

/// Consistent branded header used across all role dashboards.
/// Provides gradient background, logo watermark, name greeting,
/// and working language + notification buttons.
class AppBrandedHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final Widget? bottomContent;

  const AppBrandedHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.bottomContent,
  });

  static const _kPrimaryDark = Color(0xFF1B4332);
  static const _kPrimary = Color(0xFF2D6A4F);
  static const _kPrimaryLight = Color(0xFF40916C);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: bottomContent != null ? 16 : 28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimaryDark, _kPrimary, _kPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background logo watermark
          Positioned(
            right: -20,
            bottom: -10,
            child: Opacity(
              opacity: 0.08,
              child: Image.asset(
                'assets/images/logo.png',
                height: 180,
                width: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar — Logo + AgriLink + icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 24,
                          width: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AgriLink',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.language, color: Colors.white, size: 22),
                          tooltip: 'Switch Language',
                          onPressed: () {
                            final langService = Provider.of<LanguageService>(context, listen: false);
                            langService.toggleLanguage();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Language: ${langService.locale.languageCode == 'am' ? 'አማርኛ' : 'English'}'),
                                backgroundColor: _kPrimary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                          tooltip: 'Notifications',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('No new notifications'),
                                backgroundColor: _kPrimary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Greeting
              Text(
                greeting,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              if (bottomContent != null) ...[
                const SizedBox(height: 20),
                bottomContent!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}
