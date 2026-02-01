import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/business_provider.dart';
import '../../core/utils/ui_utils.dart';

class GiftSelectionScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final double currentPoints;

  const GiftSelectionScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.currentPoints,
  });

  @override
  State<GiftSelectionScreen> createState() => _GiftSelectionScreenState();
}

class _GiftSelectionScreenState extends State<GiftSelectionScreen> {
  bool _isLoading = true;
  List<dynamic> _gifts = [];

  // State for redemption process
  String? _redeemingGiftId; 

  @override
  void initState() {
    super.initState();
    _fetchGifts();
  }

  Future<void> _fetchGifts() async {
    try {
      final api = context.read<ApiService>();
      final gifts = await api.getBusinessGifts(widget.businessId);
      setState(() {
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching gifts: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _redeemGift(dynamic gift) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    
    // 1. Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('confirm'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          "${gift['title']} ${lang.translate('gift_redeem_confirm')} (${gift['pointCost']} ${lang.translate('points')})",
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel'), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE2C2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('confirm'), style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Process Redemption
    setState(() => _redeemingGiftId = gift['_id']);

    try {
      final api = context.read<ApiService>();
      await api.redeemGift(widget.businessId, gift['_id']);
      
      // 3. Success Feedback
      if (mounted) {
        showCustomPopup(
          context,
          message: lang.translate('gift_redeem_success'),
          type: PopupType.success,
        );
        
        // Refresh business data (points)
        context.read<BusinessProvider>().fetchMyFirms();
        
        // Navigate back or refresh screen?
        // Let's go back for now, effectively closing the "spend" flow
        context.pop(true); // Return true to indicate something happened
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = lang.translate('error');
        if (e.toString().contains('Yetersiz puan')) {
          errorMsg = lang.translate('insufficient_points'); // Assuming you add this key
        }
        showCustomPopup(
          context,
          message: errorMsg,
          type: PopupType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _redeemingGiftId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    // Hardcoded key for now if missing in localization
    final String titleText = "Hediye Seçimi"; // lang.translate('gift_selection_title'); 

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(titleText, style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: theme.textTheme.bodyLarge?.color),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Points Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            width: double.infinity,
            color: theme.scaffoldBackgroundColor,
            child: Column(
              children: [
                Text(
                  widget.businessName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${widget.currentPoints.toInt()}",
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFEE2C2C),
                    height: 1.0,
                  ),
                ),
                Text(
                  lang.translate('current_points'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _gifts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_rounded, size: 60, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          "Bu işletmede henüz hediye yok", // lang.translate('no_gifts_found'),
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _gifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final gift = _gifts[index];
                      final cost = gift['pointCost'];
                      final canAfford = widget.currentPoints >= cost;
                      final isRedeeming = _redeemingGiftId == gift['_id'];

                      return Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: canAfford ? const Color(0xFFEE2C2C).withOpacity(0.1) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (canAfford && !isRedeeming) ? () => _redeemGift(gift) : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(
                                      color: canAfford ? const Color(0xFFEE2C2C).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.coffee_rounded, // Generic icon for gifts
                                      color: canAfford ? const Color(0xFFEE2C2C) : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          gift['title'],
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: canAfford ? theme.textTheme.bodyLarge?.color : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$cost ${lang.translate('points')}",
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFEE2C2C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action
                                  if (isRedeeming)
                                    const SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEE2C2C)),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: canAfford ? const Color(0xFFEE2C2C) : Colors.grey.withOpacity(0.3),
                                    ),
                                ],
                              ),
                            ),
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
