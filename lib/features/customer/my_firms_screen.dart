import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/business_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/api_config.dart';

class MyFirmsScreen extends StatefulWidget {
  const MyFirmsScreen({super.key});

  @override
  State<MyFirmsScreen> createState() => _MyFirmsScreenState();
}

class _MyFirmsScreenState extends State<MyFirmsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<AuthProvider>().isAuthenticated) return;
      context.read<BusinessProvider>().fetchMyFirms();
    });
  }

  Future<void> _saveOrder(List<dynamic> firms) async {
    try {
      final api = context.read<ApiService>();
      final orderedIds = firms.map((f) => f['id'].toString()).toList();
      await api.reorderWallet(orderedIds);
    } catch (e) {
      if (!mounted) return;
      showCustomPopup(
        context,
        message: '${Provider.of<LanguageProvider>(context, listen: false).translate('error_reorder')}: $e',
        type: PopupType.error,
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    context.read<BusinessProvider>().reorderFirms(oldIndex, newIndex);
    final newOrder = context.read<BusinessProvider>().myFirms;
    _saveOrder(newOrder);
  }

  String _translateCategory(String category, LanguageProvider lang) {
    final key = 'cat_${category.toLowerCase()}';
    final translated = lang.translate(key);
    return translated == key ? category : translated;
  }

  String _formatAddress(dynamic business) {
    final city = business['city'] ?? '';
    final district = business['district'] ?? '';
    final neighborhood = business['neighborhood'] ?? '';

    final List<String> parts = [];
    if (neighborhood != null && neighborhood.toString().isNotEmpty) parts.add(neighborhood.toString());
    if (district != null && district.toString().isNotEmpty) parts.add(district.toString());
    if (city != null && city.toString().isNotEmpty) parts.add(city.toString());

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFEBEBEB);
    const cardColor = Colors.white;
    const textColor = Color(0xFF131313);
    const yellow = Color(0xFFF9C06A);

    final provider = context.watch<BusinessProvider>();
    final isAuth = context.read<AuthProvider>().isAuthenticated;
    final guestProvider = context.watch<GuestProvider>();
    // Guests see their wallet; authenticated users see their real firms
    final firms = isAuth ? provider.myFirms : guestProvider.wallet.map((e) {
      final id = (e['_id'] ?? e['id'] ?? '').toString();
      // Hydrate from explore list to get static details (name, logo, ratings)
      final exploreData = provider.exploreFirms.firstWhere(
        (f) => (f['_id'] ?? f['id']) == id,
        orElse: () => <String, dynamic>{},
      );
      final merged = {...exploreData, ...e};

      return {
        'id': id,
        'companyName': merged['companyName'] ?? 'Bilinmeyen',
        'category': merged['category'] ?? '',
        'logo': merged['logo'],
        'image': merged['image'],
        'cardColor': merged['cardColor'],
        'city': merged['city'],
        'district': merged['district'],
        'neighborhood': merged['neighborhood'],
        'reviewScore': parseRating(merged['reviewScore'] ?? merged['rating'] ?? merged['avgRating'] ?? merged['averageRating']),
        'reviewCount': parseReviewCount(merged['reviewCount'] ?? merged['ratingCount'] ?? merged['reviewsCount']),
        'rating': parseRating(merged['rating'] ?? merged['reviewScore']),
        'ratingCount': parseReviewCount(merged['ratingCount'] ?? merged['reviewCount']),
      };
    }).toList();
    final isLoading = isAuth ? provider.isLoading : false;
    final lang = context.watch<LanguageProvider>();


    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Premium Fixed Header (campaigns_screen style) ─────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 24),
            decoration: const BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Title + hint subtitle
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.translate('my_firms_title'),
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          lang.translate('swipe_hint'),
                          style: GoogleFonts.outfit(
                            color: textColor.withValues(alpha: 0.38),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── List ──────────────────────────────────────────────────
          Expanded(
            child: isLoading && firms.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : !isLoading && firms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9C06A).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                size: 46,
                                color: Color(0xFFF9C06A),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              lang.translate('no_firms_added'),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF131313).withValues(alpha: 0.7),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lang.translate('no_firms_added_sub'),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF131313).withValues(alpha: 0.38),
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: firms.length,
                    onReorder: isAuth ? _onReorder : (_, __) {},
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          return Material(
                            elevation: 8,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final firm = firms[index];
                      final rawLogo = firm['logo'] ?? firm['image'] ?? firm['logoUrl'];
                      final logoUrl = resolveImageUrl(rawLogo) ?? '';
                      final rawCat = firm['category'] as String? ?? '';
                      final cat = rawCat.isNotEmpty ? _translateCategory(rawCat, lang) : lang.translate('general');
                      final addr = _formatAddress(firm);
                      final subtitle = addr.isNotEmpty ? '$cat • $addr' : cat;

                      return Dismissible(
                        key: ValueKey(firm['id']),
                        direction: isAuth ? DismissDirection.endToStart : DismissDirection.none,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          // Guest: simple confirm, no password needed
                          if (!isAuth) {
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: cardColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(
                                  Provider.of<LanguageProvider>(context, listen: false).translate('delete_firm_title'),
                                  style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
                                ),
                                content: Text(
                                  Provider.of<LanguageProvider>(context, listen: false).translate('delete_firm_content'),
                                  style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.8), fontSize: 16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('cancel'), style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.6))),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('yes_delete'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return false;
                            if (!context.mounted) return false;
                            await context.read<GuestProvider>().removeFromWallet(firm['id']);
                            return true;
                          }

                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text(
                                Provider.of<LanguageProvider>(context, listen: false).translate('delete_firm_title'),
                                style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                Provider.of<LanguageProvider>(context, listen: false).translate('delete_firm_content'),
                                style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.8), fontSize: 16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('cancel'), style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.6))),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('yes_delete'), style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return false;
                          if (!context.mounted) return false;

                          final passwordController = TextEditingController();
                          final bool? deleted = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              bool isLoading = false;
                              String? errorText;
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    backgroundColor: cardColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text(
                                      Provider.of<LanguageProvider>(context, listen: false).translate('security_verification'),
                                      style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Provider.of<LanguageProvider>(context, listen: false).translate('enter_password_msg'),
                                          style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.8)),
                                        ),
                                        const SizedBox(height: 20),
                                        TextField(
                                          controller: passwordController,
                                          obscureText: true,
                                          style: GoogleFonts.outfit(color: textColor),
                                          decoration: InputDecoration(
                                            hintText: Provider.of<LanguageProvider>(context, listen: false).translate('your_password'),
                                            hintStyle: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5)),
                                            filled: true,
                                            fillColor: bgColor,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            errorText: errorText,
                                            errorStyle: GoogleFonts.outfit(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                                        child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('cancel'), style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.6))),
                                      ),
                                      isLoading
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)),
                                            )
                                          : ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              ),
                                              onPressed: () async {
                                                setState(() { isLoading = true; errorText = null; });
                                                try {
                                                  await context.read<BusinessProvider>().removeFirm(firm['id'], passwordController.text);
                                                  if (context.mounted) {
                                                    context.read<CampaignProvider>().fetchAllCampaigns();
                                                    Navigator.of(context).pop(true);
                                                  }
                                                } catch (e) {
                                                  setState(() {
                                                    isLoading = false;
                                                    errorText = (e.toString().contains('401') || e.toString().contains('Şifre hatalı'))
                                                        ? Provider.of<LanguageProvider>(context, listen: false).translate('wrong_password')
                                                        : Provider.of<LanguageProvider>(context, listen: false).translate('error');
                                                  });
                                                }
                                              },
                                              child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('confirm'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                            ),
                                    ],
                                  );
                                },
                              );
                            },
                          );

                          if (deleted == true) {
                            if (!context.mounted) return false;
                            showCustomPopup(
                              context,
                              message: Provider.of<LanguageProvider>(context, listen: false).translate('firm_deleted_success'),
                              type: PopupType.success,
                            );
                            return true;
                          }
                          return false;
                        },
                        onDismissed: (_) {},
                        child: Container(
                          key: ValueKey(firm['id']),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: yellow, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: yellow.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: yellow.withValues(alpha: 0.4), width: 1.5),
                                image: logoUrl.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                                    : null,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: logoUrl.isEmpty
                                  ? const Icon(Icons.storefront_rounded, color: AppTheme.deepBrown, size: 24)
                                  : null,
                            ),
                            title: Text(
                              firm['companyName'] ?? '',
                              style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.55), fontSize: 13),
                            ),
                            trailing: Icon(Icons.drag_handle_rounded, color: textColor.withValues(alpha: 0.3)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
