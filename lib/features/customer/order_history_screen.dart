import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/smart_network_image.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final auth = context.read<AuthProvider>();
    final guest = context.read<GuestProvider>();

    try {
      final api = context.read<ApiService>();
      List<dynamic> data;
      if (auth.isAuthenticated) {
        data = await api.getTransactions();
      } else if (guest.isGuest && guest.guestId != null) {
        debugPrint('🔍 Fetching guest transactions for: ${guest.guestId}');
        try {
          data = await api.getGuestTransactions(guest.guestId!);
        } catch (_) {
          // Fallback: use getSession which now returns per-scan transactions
          final session = await api.getGuestSession(guest.guestId!);
          // Prefer the 'transactions' field (per-scan) if available
          if (session['transactions'] is List && (session['transactions'] as List).isNotEmpty) {
            data = session['transactions'] as List<dynamic>;
          } else {
            // Last resort: wallet summary (one entry per business)
            final wallet = (session['wallet'] as List? ?? []);
            data = wallet.where((w) {
              final pts = (w['points'] ?? 0) as num;
              final stm = (w['stamps'] ?? 0) as num;
              return pts > 0 || stm > 0;
            }).map((w) => {
              'business': {
                '_id': w['_id'] ?? w['id'],
                'companyName': w['companyName'],
                'logo': w['logo'],
                'image': w['image'],
                'cardColor': w['cardColor'],
              },
              'type': (w['stamps'] ?? 0) > 0 ? 'STAMP' : 'POINT',
              'value': w['stamps'] ?? 0,
              'pointsEarned': w['points'] ?? 0,
              'createdAt': DateTime.now().toIso8601String(),
              'isGuest': true,
            }).toList();
          }
        }
        debugPrint('✅ Guest transactions count: ${data.length}');
      } else {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _transactions = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('❌ Fetch transactions error: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _selectedFilter = 'filter_all';
  final List<String> _filters = ['filter_all', 'filter_today', 'filter_yesterday', 'filter_1_week', 'filter_1_month', 'filter_3_months', 'filter_1_year'];

  List<dynamic> _getFilteredTransactions() {
    if (_selectedFilter == 'filter_all') return _transactions;

    final now = DateTime.now();
    return _transactions.where((tx) {
      String rawDate = tx['createdAt'].toString();
      if (!rawDate.endsWith('Z')) rawDate += 'Z';
      final date = DateTime.parse(rawDate).toLocal();
      final difference = now.difference(date);

      // Check for same day explicitly for "Bugün"
      final isSameDay = now.year == date.year && now.month == date.month && now.day == date.day;
      
      switch (_selectedFilter) {
        case 'filter_today':
          return isSameDay;
        case 'filter_yesterday':
           // Rough check: difference in hours between 24 and 48, or simply day difference of 1 and not same day
           // Better approach for "Dün":
           final yesterday = now.subtract(const Duration(days: 1));
           return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
        case 'filter_1_week':
          return difference.inDays <= 7;
        case 'filter_1_month':
          return difference.inDays <= 30;
        case 'filter_3_months':
          return difference.inDays <= 90;
        case 'filter_1_year':
          return difference.inDays <= 365;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFEBEBEB);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF131313);
    const activeColor = Color(0xFFF9C06A); // Changed from 0xFF76410B to Yellow/Gold theme

    final lang = context.watch<LanguageProvider>();
    final filteredTransactions = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(lang.translate('order_history'), style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded, size: 64, color: textColor.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('Veriler yüklenemedi', style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5), fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(_error!, style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.3), fontSize: 11), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () { setState(() { _isLoading = true; _error = null; }); _fetchTransactions(); },
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
              children: [
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: _filters.map((filterKey) {
                      final isSelected = _selectedFilter == filterKey;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filterKey),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? activeColor : cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? Colors.transparent : textColor.withValues(alpha: 0.1)),
                              boxShadow: isSelected ? [BoxShadow(color: activeColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))] : [],
                            ),
                            child: Text(
                              lang.translate(filterKey),
                              style: GoogleFonts.outfit(
                                color: isSelected ? const Color(0xFF131313) : textColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                Expanded(
                  child: filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 64, color: textColor.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                _transactions.isEmpty ? lang.translate('no_orders_yet') : lang.translate('no_orders_filter'),
                                style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5), fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = filteredTransactions[index];
                            final business = tx['business'] ?? {};
                            final type = tx['type'];
                            final value = tx['value'];
                            // Strict UTC handling & Debugging
                            String rawDate = tx['createdAt'].toString();
                            if (!rawDate.endsWith('Z')) {
                              rawDate += 'Z';
                            }
                            final dateUtc = DateTime.parse(rawDate);
                            final date = dateUtc.toLocal();
                            
                            debugPrint("DD_DEBUG: Raw: ${tx['createdAt']} -> ParsedUTC: $dateUtc -> Local: $date");
                            
                            final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
        
                            String title = lang.translate('transaction');
                            IconData icon = Icons.receipt_long_rounded;
                            
                            final description = tx['description'] ?? '';
                            final pointsEarned = tx['pointsEarned']; // Can be negative number, null, or string
                            
                            final List<Widget> amountWidgets = [];
                            
                            // Parse points securely
                            double? pts;
                            if (pointsEarned != null) {
                               if (pointsEarned is num) pts = pointsEarned.toDouble();
                               if (pointsEarned is String) pts = double.tryParse(pointsEarned);
                            } else if (type == 'POINT' && value != null) {
                               if (value is num) pts = value.toDouble();
                               if (value is String) pts = double.tryParse(value);
                            }

                            if (type == 'gift_redemption') {
                               final isEntitlementText = description.toString().toLowerCase().contains('hediye hakkı');
                               final isZeroPoints = pts == null || pts == 0;
                               
                               if (isEntitlementText || isZeroPoints) {
                                  title = lang.translate('hediye_hakki_kullanimi');
                                  icon = Icons.coffee_rounded; 
                                  amountWidgets.add(Text("-1 ${lang.translate('unit_gift')}", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)));
                               } else {
                                  final giftName = description.replaceAll('Hediye Alımı: ', '');
                                  title = "${lang.translate('hediye_alimi')}: $giftName";
                                  icon = Icons.card_giftcard_rounded;
                                  amountWidgets.add(Text("${pts.toInt()} ${lang.translate('unit_point')}", style: GoogleFonts.outfit(color: const Color(0xFF76410B), fontWeight: FontWeight.bold, fontSize: 15)));
                               }
                            } else if (type == 'STAMP') {
                               title = lang.translate('stamp_earned'); 
                               icon = Icons.local_cafe_rounded;
                               if (value != null && value > 0) {
                                  amountWidgets.add(Text("+$value ${lang.translate('unit_stamp')}", style: GoogleFonts.outfit(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15)));
                               }
                               if (pts != null && pts != 0) {
                                  amountWidgets.add(Text("+${pts.toInt()} ${lang.translate('unit_point')}", style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)));
                               }
                            } else if (type == 'POINT') {
                               if (pts != null && pts < 0) {
                                  title = lang.translate('point_spending');
                                  icon = Icons.shopping_bag_outlined;
                                  amountWidgets.add(Text("${pts.toInt()} ${lang.translate('unit_point')}", style: GoogleFonts.outfit(color: const Color(0xFF76410B), fontWeight: FontWeight.bold, fontSize: 15)));
                               } else {
                                  title = lang.translate('point_earned');
                                  icon = Icons.stars_rounded;
                                  if (pts != null && pts > 0) {
                                     amountWidgets.add(Text("+${pts.toInt()} ${lang.translate('unit_point')}", style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)));
                                  }
                               }
                            } else if (type == 'GIFT_REDEEM') {
                               title = lang.translate('gift_redeemed');
                               icon = Icons.card_giftcard_rounded;
                               amountWidgets.add(Text("-1 ${lang.translate('unit_gift')}", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)));
                            }
        
                            final colorHex = business['cardColor'] ?? '#333333';
                            final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                            final String? logoUrl = resolveImageUrl(business['logo'] ?? business['image'] ?? business['logoUrl']);
        
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: textColor.withValues(alpha: 0.05)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 50, height: 50,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: (logoUrl != null && logoUrl.isNotEmpty)
                                         ? SmartNetworkImage(url: logoUrl, fit: BoxFit.cover)
                                         : Padding(
                                             padding: const EdgeInsets.all(8.0),
                                             child: Image.asset('assets/images/splash_logo.png', fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(icon, color: color)),
                                           ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            business['companyName'] ?? lang.translate('unknown_business'),
                                            style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(title, style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.7))),
                                          Text(formattedDate, style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4), fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        ...amountWidgets,
                                        if (tx['review'] != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.coffee_rounded, size: 12, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${tx['review']['rating']}/5",
                                                style: GoogleFonts.outfit(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          )
                                        else if (type != 'GIFT_REDEEM' && tx['isGuest'] != true) // Hide rating for guest transactions
                                          GestureDetector(
                                            onTap: () => _showRatingDialog(context, tx),
                                            child: Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                              ),
                                              child: Text(
                                                lang.translate('rate_transaction'),
                                                style: GoogleFonts.outfit(color: Colors.amber[800], fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
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

  void _showRatingDialog(BuildContext context, dynamic tx) {
    int rating = 0; // Start with 0 (unselected)
    final commentController = TextEditingController();
    bool isSubmitting = false;

    // StatefulBuilder needed for icon state update
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
            final lang = context.read<LanguageProvider>();

            return AlertDialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(lang.translate('rate_dialog_title'), style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: List.generate(5, (index) {
                       return GestureDetector(
                         onTap: () => setState(() => rating = index + 1),
                         child: Padding(
                           padding: const EdgeInsets.all(4.0),
                           child: Icon(
                             Icons.coffee_rounded,
                             size: 32,
                             // If rating is 0, all gray. Otherwise, color up to rating.
                             color: (rating > 0 && index < rating) ? Colors.amber : Colors.grey.withValues(alpha: 0.3),
                           ),
                         ),
                       );
                     }),
                   ),
                   const SizedBox(height: 20),
                   TextField(
                     controller: commentController,
                     maxLength: 250,
                     maxLines: 3,
                     style: GoogleFonts.outfit(color: textColor),
                     decoration: InputDecoration(
                       hintText: lang.translate('comment_hint'),
                       hintStyle: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5)),
                       filled: true,
                       fillColor: theme.scaffoldBackgroundColor,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                     ),
                   )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lang.translate('cancel'), style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5))),
                ),
                ElevatedButton(
                  // Disable if rating is 0 or submitting
                  onPressed: (isSubmitting || rating == 0) ? null : () async {
                    setState(() => isSubmitting = true);
                    try {
                      final business = tx['business'] ?? {};
                      await context.read<ApiService>().submitReview(
                        tx['_id'], 
                        business['_id'] ?? business['id'], // Handle both populate and raw formats
                        rating, 
                        commentController.text
                      );
                      if (context.mounted) {
                         Navigator.pop(context);
                         _fetchTransactions(); // Refresh list
                          showCustomPopup(
                            context,
                            message: lang.translate('success_review'),
                            type: PopupType.success,
                          );
                       }
                     } catch (e) {
                       setState(() => isSubmitting = false);
                       if (!context.mounted) return;
                        showCustomPopup(
                          context,
                          message: '$e',
                          type: PopupType.error,
                        );
                     }
                   },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    disabledBackgroundColor: Colors.amber.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                     : Text(lang.translate('send'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
