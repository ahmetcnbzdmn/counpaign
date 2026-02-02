import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/swipe_back_detector.dart';
import '../../core/utils/ui_utils.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.getTransactions();
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error cleanly
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
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const activeColor = Color(0xFFEE2C2C); // Red

    final lang = context.watch<LanguageProvider>();
    final filteredTransactions = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(lang.translate('order_history'), style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                        child: ChoiceChip(
                          label: Text(lang.translate(filterKey), style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          )),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedFilter = filterKey);
                          },
                          selectedColor: activeColor,
                          backgroundColor: cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide(color: isSelected ? Colors.transparent : textColor.withOpacity(0.1)),
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
                              Icon(Icons.history_rounded, size: 64, color: textColor.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                _transactions.isEmpty ? lang.translate('no_orders_yet') : lang.translate('no_orders_filter'),
                                style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 16),
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
                            
                            print("DD_DEBUG: Raw: ${tx['createdAt']} -> ParsedUTC: $dateUtc -> Local: $date");
                            
                            final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
        
                            String title = lang.translate('transaction');
                            String amount = "";
                            Color amountColor = textColor;
                            IconData icon = Icons.receipt_long_rounded;
        
                            final description = tx['description'] ?? '';
                            final pointsEarned = tx['pointsEarned']; // Can be negative number, null, or string

                            if (type == 'gift_redemption') {
                               final isEntitlementText = description.toString().toLowerCase().contains('hediye hakkı');
                               final isZeroPoints = pointsEarned != null && (pointsEarned == 0 || pointsEarned == '0');
                               
                               if (isEntitlementText || isZeroPoints) {
                                  title = lang.translate('hediye_hakki_kullanimi');
                                  amount = "-1";
                                  amountColor = Colors.amber; // Yellow
                                  icon = Icons.coffee_rounded; 
                               } else {
                                  // Point Purchase (Hediye Alımı: [GiftName])
                                  // Extract gift name
                                  final giftName = description.replaceAll('Hediye Alımı: ', '');
                                  title = "${lang.translate('hediye_alimi')}: $giftName";
                                  
                                  // Safe cast to avoid 'null' string
                                  final cost = pointsEarned?.toString() ?? '0';
                                  amount = cost; 
                                  amountColor = const Color(0xFFEE2C2C); // Red
                                  icon = Icons.card_giftcard_rounded;
                               }
                            } else if (type == 'STAMP') {
                              title = lang.translate('stamp_earned'); 
                              amount = "+$value";
                              amountColor = Colors.orange;
                              icon = Icons.local_cafe_rounded;
                            } else if (type == 'POINT') {
                              // Check for negative points (spend)
                              if (pointsEarned != null && (pointsEarned is num) && pointsEarned < 0) {
                                 title = "Puan Harcama";
                                 amount = "$pointsEarned";
                                 amountColor = const Color(0xFFEE2C2C);
                                 icon = Icons.shopping_bag_outlined;
                              } else {
                                 title = lang.translate('point_earned');
                                 final val = tx['pointsEarned'] ?? value;
                                 amount = "+$val";
                                 amountColor = Colors.green;
                                 icon = Icons.stars_rounded;
                              }
                            } else if (type == 'GIFT_REDEEM') {
                              title = lang.translate('gift_redeemed');
                              amount = "-1";
                              amountColor = Colors.red;
                              icon = Icons.card_giftcard_rounded;
                            }
        
                            final colorHex = business['cardColor'] ?? '#333333';
                            final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
        
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: textColor.withOpacity(0.05)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color),
                                ),
                                title: Text(
                                  business['companyName'] ?? lang.translate('unknown_business'),
                                  style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(title, style: GoogleFonts.outfit(color: textColor.withOpacity(0.7))),
                                    Text(formattedDate, style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 12)),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      amount,
                                      style: GoogleFonts.outfit(color: amountColor, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    if (tx['review'] != null)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.coffee_rounded, size: 12, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${tx['review']['rating']}/5",
                                            style: GoogleFonts.outfit(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      )
                                    else if (type != 'GIFT_REDEEM') // Only rate earnings? Or everything? Let's allow all for now
                                      GestureDetector(
                                        onTap: () => _showRatingDialog(context, tx),
                                        child: Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                          ),
                                          child: Text(
                                            lang.translate('rate_transaction'),
                                            style: GoogleFonts.outfit(color: Colors.amber[800], fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
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
    int _rating = 0; // Start with 0 (unselected)
    final _commentController = TextEditingController();
    bool _isSubmitting = false;

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
                         onTap: () => setState(() => _rating = index + 1),
                         child: Padding(
                           padding: const EdgeInsets.all(4.0),
                           child: Icon(
                             Icons.coffee_rounded,
                             size: 32,
                             // If rating is 0, all gray. Otherwise, color up to rating.
                             color: (_rating > 0 && index < _rating) ? Colors.amber : Colors.grey.withOpacity(0.3),
                           ),
                         ),
                       );
                     }),
                   ),
                   const SizedBox(height: 20),
                   TextField(
                     controller: _commentController,
                     maxLength: 250,
                     maxLines: 3,
                     style: GoogleFonts.outfit(color: textColor),
                     decoration: InputDecoration(
                       hintText: lang.translate('comment_hint'),
                       hintStyle: GoogleFonts.outfit(color: textColor.withOpacity(0.5)),
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
                  child: Text(lang.translate('cancel'), style: GoogleFonts.outfit(color: textColor.withOpacity(0.5))),
                ),
                ElevatedButton(
                  // Disable if rating is 0 or submitting
                  onPressed: (_isSubmitting || _rating == 0) ? null : () async {
                    setState(() => _isSubmitting = true);
                    try {
                      final business = tx['business'] ?? {};
                      await context.read<ApiService>().submitReview(
                        tx['_id'], 
                        business['_id'] ?? business['id'], // Handle both populate and raw formats
                        _rating, 
                        _commentController.text
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
                       setState(() => _isSubmitting = false);
                        showCustomPopup(
                          context,
                          message: '$e',
                          type: PopupType.error,
                        );
                     }
                   },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    disabledBackgroundColor: Colors.amber.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
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
