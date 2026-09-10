import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../services/language_service.dart';
import '../../widgets/product_image.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'package:agrilink/l10n/generated/app_localizations.dart';

class PublicDashboardScreen extends StatefulWidget {
  const PublicDashboardScreen({super.key});

  @override
  State<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends State<PublicDashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _bottomNavIndex = 0;

  // Brand colors
  static const _kDark = Color(0xFF1B4332);
  static const _kPrimary = Color(0xFF2D6A4F);
  static const _kPrimaryLight = Color(0xFF40916C);
  static const _kAccent = Color(0xFF52B788);
  static const _kOrange = Color(0xFFFF8500);
  static const _kBg = Color(0xFFF7F8FA);
  static const _kText = Color(0xFF1F2937);
  static const _kTextMuted = Color(0xFF6B7280);
  static const _kBorder = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  Stream<List<ProductModel>> get _publicListings {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'AVAILABLE')
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => ProductModel.fromFirestore(d)).toList());
  }

  Map<String, double> _computeAveragePrices(List<ProductModel> products) {
    final Map<String, List<double>> grouped = {};
    for (final p in products) {
      final key = p.cropName.trim();
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(p.pricePerKg);
    }
    return grouped.map(
      (crop, prices) =>
          MapEntry(crop, prices.reduce((a, b) => a + b) / prices.length),
    );
  }

  String _cropEmoji(String crop) {
    final l = crop.toLowerCase();
    if (l.contains('tomato')) return '🍅';
    if (l.contains('maize') || l.contains('corn')) return '🌽';
    if (l.contains('wheat')) return '🌾';
    if (l.contains('teff')) return '🌾';
    if (l.contains('coffee')) return '☕';
    if (l.contains('potato')) return '🥔';
    if (l.contains('onion')) return '🧅';
    if (l.contains('pepper') || l.contains('chili')) return '🌶️';
    if (l.contains('bean') || l.contains('lentil')) return '🫘';
    if (l.contains('avocado')) return '🥑';
    if (l.contains('banana') || l.contains('enset')) return '🍌';
    if (l.contains('mango')) return '🥭';
    if (l.contains('orange') || l.contains('citrus')) return '🍊';
    if (l.contains('sorghum') || l.contains('barley')) return '🌾';
    if (l.contains('sesame')) return '🌱';
    return '🌿';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildTopBar(context),
            _buildHeroSection(context, l10n),
            _buildStatsSection(l10n),
            _buildLiveMarketplace(l10n),
            _buildReadyToTradeCTA(context, l10n),
            _buildMarketPricesTicker(l10n),
            _buildBecomeAFarmerCTA(context, l10n),
            _buildFooter(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, l10n),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TOP BAR — Logo + Sign In
  // ═══════════════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _kDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 26,
                    width: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AgriLink',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // Sign In + Language
          Row(
            children: [
              // Language toggle
              GestureDetector(
                onTap: () {
                  final langService =
                      Provider.of<LanguageService>(context, listen: false);
                  langService.toggleLanguage();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Language: ${langService.locale.languageCode == 'am' ? 'አማርኛ' : 'English'}',
                      ),
                      backgroundColor: _kPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.language, size: 18, color: _kPrimary),
                ),
              ),
              const SizedBox(width: 8),
              // Sign In button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary, width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'SIGN IN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HERO SECTION — Farm background + title
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeroSection(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kDark, _kPrimary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.70),
                ],
              ),
            ),
          ),
          // Text content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.publicDashboardTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.publicDashboardSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STATS SECTION — Vertical stat rows
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatsSection(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('products')
          .where('status', isEqualTo: 'AVAILABLE')
          .snapshots(),
      builder: (context, snap) {
        int listings = 0;
        double volume = 0;
        Set<String> farmerIds = {};

        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            listings++;
            farmerIds.add(data['farmer_id'] ?? '');
            volume += (data['quantity_kg'] ?? 0).toDouble();
          }
        }

        final fmt = NumberFormat('#,###');

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.publicStatsSectionTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.publicLiveMarketData,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stat rows
              _StatRow(
                icon: Icons.people_alt_rounded,
                iconBg: const Color(0xFFECFDF5),
                iconColor: _kPrimary,
                label: l10n.publicStatFarmers,
                value: fmt.format(farmerIds.length),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _kBorder),
              ),
              _StatRow(
                icon: Icons.inventory_2_rounded,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: _kOrange,
                label: l10n.publicStatListings,
                value: fmt.format(listings),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _kBorder),
              ),
              _StatRow(
                icon: Icons.show_chart_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF3B82F6),
                label: l10n.publicStatVolume,
                value: '${fmt.format(volume)} kg',
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  LIVE MARKETPLACE — Product cards
  // ═══════════════════════════════════════════════════════════
  Widget _buildLiveMarketplace(AppLocalizations l10n) {
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return StreamBuilder<List<ProductModel>>(
      stream: _publicListings,
      builder: (context, snap) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            size: 14, color: _kPrimary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.publicLiveListings.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kTextMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          '${l10n.viewAll} ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: _kPrimary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Product cards
            if (snap.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                    child: CircularProgressIndicator(color: _kPrimary)),
              )
            else if (!snap.hasData || snap.data!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(l10n.publicNoListings,
                          style: const TextStyle(color: _kTextMuted)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snap.data!.length > 5 ? 5 : snap.data!.length,
                itemBuilder: (context, i) {
                  final p = snap.data![i];
                  return _ProductListingCard(
                    product: p,
                    currency: currency,
                    timeAgo: _timeAgo(p.createdAt),
                    emoji: _cropEmoji(p.cropName),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  READY TO TRADE CTA
  // ═══════════════════════════════════════════════════════════
  Widget _buildReadyToTradeCTA(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kDark, Color(0xFF264E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.publicCtaTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.publicCtaSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.publicLoginToTrade,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  MARKET PRICES TICKER — horizontal scroll
  // ═══════════════════════════════════════════════════════════
  Widget _buildMarketPricesTicker(AppLocalizations l10n) {
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return StreamBuilder<List<ProductModel>>(
      stream: _publicListings,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final avgPrices = _computeAveragePrices(snap.data!);
        if (avgPrices.isEmpty) return const SizedBox.shrink();

        final sorted = avgPrices.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.trending_up_rounded,
                        size: 14, color: _kOrange),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.publicMarketPrices.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kTextMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final e = sorted[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(_cropEmoji(e.key),
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kTextMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currency.format(e.value)}/kg',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BECOME A FARMER CTA
  // ═══════════════════════════════════════════════════════════
  Widget _buildBecomeAFarmerCTA(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimary, _kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.agriculture, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.publicBecomeAFarmer,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.publicBecomeAFarmerDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.publicJoinMarketplace,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  FOOTER
  // ═══════════════════════════════════════════════════════════
  Widget _buildFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 22,
                    width: 22,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AgriLink',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerLink('MARKETPLACE'),
              _footerDot(),
              _footerLink('ABOUT US'),
              _footerDot(),
              _footerLink('HELP'),
            ],
          ),
          const SizedBox(height: 20),
          // Social
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(Icons.facebook),
              const SizedBox(width: 16),
              _socialIcon(Icons.telegram),
              const SizedBox(width: 16),
              _socialIcon(Icons.phone),
            ],
          ),
          const SizedBox(height: 20),
          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),
          // Copyright
          Text(
            '© 2024 AgriLink Inc. Empowering Ethiopian Agriculture.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.65),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _footerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BOTTOM NAV BAR
  // ═══════════════════════════════════════════════════════════
  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // Home
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _bottomNavIndex == 0,
                activeColor: _kPrimary,
                onTap: () => setState(() => _bottomNavIndex = 0),
              ),
              // Browse
              _BottomNavItem(
                icon: Icons.explore_rounded,
                label: l10n.market,
                isActive: _bottomNavIndex == 1,
                activeColor: _kPrimary,
                onTap: () => setState(() => _bottomNavIndex = 1),
              ),
              // Login
              _BottomNavItem(
                icon: Icons.login_rounded,
                label: l10n.login,
                isActive: false,
                activeColor: _kPrimary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              // Sign Up
              _BottomNavItem(
                icon: Icons.person_add_rounded,
                label: l10n.createAccount,
                isActive: false,
                activeColor: _kPrimary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  STAT ROW — icon + label + value
// ══════════════════════════════════════════════════════════════
class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PRODUCT LISTING CARD — image + info (no private data)
// ══════════════════════════════════════════════════════════════
class _ProductListingCard extends StatelessWidget {
  final ProductModel product;
  final NumberFormat currency;
  final String timeAgo;
  final String emoji;

  const _ProductListingCard({
    required this.product,
    required this.currency,
    required this.timeAgo,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image / emoji fallback
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: ProductImage(
                imageUrl: product.imageUrl,
                width: 80,
                height: 80,
                borderRadius: 11,
                fit: BoxFit.cover,
                fallback: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.cropName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF40916C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      product.description,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Quantity + location
                  Row(
                    children: [
                      Icon(Icons.scale_rounded,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${NumberFormat('#,###').format(product.quantityKg)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (product.location != null &&
                          product.location!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            product.location!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Text(
                    '${currency.format(product.pricePerKg)}/kg',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  BOTTOM NAV ITEM
// ══════════════════════════════════════════════════════════════
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : const Color(0xFF9CA3AF),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
