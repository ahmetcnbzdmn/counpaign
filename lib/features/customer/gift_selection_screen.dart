import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/business_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/auto_text.dart';

class GiftSelectionScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final double currentPoints;
  final int currentGifts;

  const GiftSelectionScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.currentPoints,
    required this.currentGifts,
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

  Future<void> _cancelCode(String? code) async {
    if (code == null) return;
    try {
        await context.read<ApiService>().cancelRedemption(code);
        print("Explicit cancel for code: $code");
    } catch (e) {
        print("Cancel failed (might already be used): $e");
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
        title: Text(lang.translate('confirm_redeem_title'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          "${lang.translate('confirm_redeem_msg')}${gift['title']}?\n(${gift['pointCost']} ${lang.translate('points')})",
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

    // 2. Prepare Redemption (Get Code)
    setState(() => _redeemingGiftId = gift['_id']);

    try {
      final api = context.read<ApiService>();
      final result = await api.prepareRedemption(widget.businessId, gift['_id']);
      final code = result['token'];
      
      // 3. Show Code Dialog & Start Polling
      if (mounted) {
        bool isDialogOpen = true;

        Future<void> pollStatus() async {
          while (isDialogOpen && mounted) {
            await Future.delayed(const Duration(seconds: 2));
            if (!isDialogOpen || !mounted) break;
            try {
              final statusRes = await api.checkConfirmationStatus(code);
              if (statusRes['status'] == 'used') {
                if (mounted && isDialogOpen) {
                  Navigator.of(context).pop();
                  
                  // [Counpaign UI Polish] Show Success Popup instead of Snackbar
                  await showCustomPopup(
                    context,
                    message: lang.translate('gift_delivered_msg'),
                    type: PopupType.success,
                  );
                  
                  if (mounted) context.go('/home');
                }
                break;
              }
            } catch (e) {
              print("Polling error: $e");
            }
          }
        }
        pollStatus();

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Icon(Icons.qr_code_2_rounded, size: 60, color: const Color(0xFFEE2C2C)),
                const SizedBox(height: 16),
                Text(
                  lang.translate('gift_code_title'),
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  lang.translate('gift_code_desc'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEE2C2C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEE2C2C).withOpacity(0.3)),
                  ),
                  child: Text(
                    code,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: const Color(0xFFEE2C2C),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    isDialogOpen = false;
                    _cancelCode(code); // Explicitly cancel
                    Navigator.pop(context);
                    context.go('/home'); // Close screen and refresh
                  },
                  child: Text(lang.translate('close'), style: GoogleFonts.outfit(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ).then((_) {
            isDialogOpen = false;
             // If user dismissed via barrier or back button without using "used" logic
             if (mounted) _cancelCode(code);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = lang.translate('error');
        if (e.toString().contains('Yetersiz puan')) {
          errorMsg = lang.translate('insufficient_points');
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

  Future<void> _redeemGiftEntitlement() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // 1. Confirm Entitlement Usage
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang.translate('redeem_entitlement_title'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          lang.translate('gift_entitlement_confirm'),
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel'), style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEE2C2C)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('confirm'), style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Prepare Redemption (Get Code) & Start Polling
    try {
      final api = context.read<ApiService>();
      // Pass empty giftId for entitlement, type='GIFT_ENTITLEMENT'
      final result = await api.prepareRedemption(widget.businessId, "", type: 'GIFT_ENTITLEMENT');
      final code = result['token'];

      if (mounted) {
        // Start polling in background
        bool isDialogOpen = true;
        
        // Polling Function
        Future<void> pollStatus() async {
          while (isDialogOpen && mounted) {
            await Future.delayed(const Duration(seconds: 2));
            if (!isDialogOpen || !mounted) break;
            
            try {
              final statusRes = await api.checkConfirmationStatus(code);
              if (statusRes['status'] == 'used') {
                if (mounted && isDialogOpen) {
                  Navigator.of(context).pop(); // Close Dialog
                  
                  // [Counpaign UI Polish] Show Success Popup instead of Snackbar
                  await showCustomPopup(
                    context,
                    message: lang.translate('gift_delivered_msg'),
                    type: PopupType.success,
                  );
                  
                  if (mounted) context.go('/home'); // Navigate to Home
                }
                break;
              }
            } catch (e) {
              print("Polling error: $e");
            }
          }
        }
        pollStatus();

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Icon(Icons.card_giftcard, size: 60, color: const Color(0xFFEE2C2C)),
                const SizedBox(height: 16),
                Text(
                  lang.translate('gift_code_title'),
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  lang.translate('gift_code_desc'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEE2C2C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEE2C2C).withOpacity(0.3)),
                  ),
                  child: Text(
                    code,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: const Color(0xFFEE2C2C),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    isDialogOpen = false;
                    _cancelCode(code); // Explicitly cancel
                    Navigator.pop(context);
                    context.go('/home');
                  },
                  child: Text(lang.translate('close'), style: GoogleFonts.outfit(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ).then((_) {
            isDialogOpen = false;
            if (mounted) _cancelCode(code);
        }); // Ensure flag is false when dialog closes
      }
    } catch (e) {
      if (mounted) {
        showCustomPopup(
          context,
          message: lang.translate('gift_error_msg'),
          type: PopupType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    
    // Use passed gift count directly for consistent UI with previous screen
    final int giftsCount = widget.currentGifts;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          lang.translate('gift_selection_title'), 
          style: GoogleFonts.outfit(
            color: theme.textTheme.bodyLarge?.color, 
            fontWeight: FontWeight.bold,
            // Removed fixed fontSize to match other screens
          )
        ),
        // ... (rest of AppBar)
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)
              ]
            ),
            child: Icon(Icons.arrow_back_rounded, color: theme.textTheme.bodyLarge?.color, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Points Header (Premium Card Style)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEE2C2C), Color(0xFFB71C1C)], // Premium Red
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                 BoxShadow(color: const Color(0xFFEE2C2C).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  widget.businessName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "${widget.currentPoints.toInt()}",
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lang.translate('points'),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // Changed to White
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lang.translate('spendable_amount'),
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEE2C2C)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // FREE GIFT CARD (If Eligible)
                    if (giftsCount > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)], // Gold Gradient
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFA000).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _redeemGiftEntitlement(),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                                      ],
                                    ),
                                    child: const Icon(Icons.card_giftcard, color: Color(0xFFFFA000), size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.translate('gift_entitlement_title'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [Shadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$giftsCount ${lang.translate('gift_entitlement_subtitle')}",
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.95),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                    // Empty State
                    if (_gifts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.card_giftcard_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                lang.translate('no_gifts_yet'),
                                style: GoogleFonts.outfit(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_gifts.isNotEmpty)
                      Padding(
                         padding: const EdgeInsets.only(bottom: 16, left: 8),
                         child: Text(
                           lang.translate('available_gifts_header'),
                           style: GoogleFonts.outfit(
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                             color: theme.textTheme.bodyLarge?.color,
                           ),
                         ),
                      ),
                    
                    // ... List Mapping ...


                    // Gift List
                    ..._gifts.map((gift) {
                      final cost = gift['pointCost'];
                      final canAfford = widget.currentPoints >= cost;
                      final isRedeeming = _redeemingGiftId == gift['_id'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: (canAfford && !isRedeeming) ? () => _redeemGift(gift) : null,
                            borderRadius: BorderRadius.circular(20),
                            overlayColor: MaterialStateProperty.all(const Color(0xFFEE2C2C).withOpacity(0.1)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Icon Wrapper
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      color: canAfford 
                                          ? const Color(0xFFEE2C2C).withOpacity(0.1) 
                                          : Colors.grey.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.local_cafe_rounded,
                                      color: canAfford ? const Color(0xFFEE2C2C) : Colors.grey.withOpacity(0.4),
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  
                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AutoText(
                                          gift['title'],
                                          style: GoogleFonts.outfit(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: canAfford ? theme.textTheme.bodyLarge?.color : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: canAfford 
                                                ? const Color(0xFFEE2C2C).withOpacity(0.08) 
                                                : Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.stars_rounded, // Changed Icon
                                                size: 14, 
                                                color: canAfford ? const Color(0xFFEE2C2C) : Colors.grey
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "$cost ${lang.translate('points')}",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: canAfford ? const Color(0xFFEE2C2C) : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Button / State
                                  if (isRedeeming)
                                    Container(
                                      width: 44, height: 44,
                                      padding: const EdgeInsets.all(12),
                                      child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEE2C2C)),
                                    )
                                  else 
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: canAfford ? const Color(0xFFEE2C2C) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        border: canAfford ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: canAfford ? Colors.white : Colors.grey.withOpacity(0.3),
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    // Bottom Padding
                    const SizedBox(height: 40),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
