import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];
  List<dynamic> _pendingReviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getReviews(),
        api.getPendingReviews(),
      ]);
      
      setState(() {
        _reviews = results[0];
        _pendingReviews = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _selectedFilter = 'filter_all';
  final List<String> _filters = ['filter_all', 'filter_today', 'filter_yesterday', 'filter_1_week', 'filter_1_month', 'filter_3_months', 'filter_1_year'];

  List<dynamic> _getFilteredReviews() {
    if (_selectedFilter == 'filter_all') return _reviews;

    final now = DateTime.now();
    return _reviews.where((review) {
      final date = DateTime.parse(review['createdAt']).toLocal();
      final difference = now.difference(date);

      // Check for same day explicitly for "Bugün"
      final isSameDay = now.year == date.year && now.month == date.month && now.day == date.day;

      switch (_selectedFilter) {
        case 'filter_today':
          return isSameDay;
        case 'filter_yesterday':
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(lang.translate('my_reviews'), style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
          backgroundColor: bgColor,
          iconTheme: IconThemeData(color: textColor),
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: activeColor,
            labelColor: activeColor,
            unselectedLabelColor: textColor.withValues(alpha: 0.5),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: lang.translate('rated_tab')),
              Tab(text: lang.translate('pending_tab')),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRatedList(lang, textColor, cardColor),
                  _buildPendingList(lang, textColor, cardColor),
                ],
              ),
      ),
    );
  }

  Widget _buildRatedList(LanguageProvider lang, Color textColor, Color cardColor) {
    final filteredReviews = _getFilteredReviews();
    return Column(
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
                  selectedColor: const Color(0xFFEE2C2C),
                  backgroundColor: cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: isSelected ? Colors.transparent : textColor.withValues(alpha: 0.1)),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filteredReviews.isEmpty
              ? _buildEmptyState(lang, textColor, 'no_reviews_yet')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    final review = filteredReviews[index];
                    final business = review['business'] ?? {};
                    final rating = review['rating'] ?? 0;
                    final comment = review['comment'];
                    final dateStr = review['createdAt'];
                    final date = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();
                    final formattedDate = DateFormat('dd MMM yyyy').format(date);

                    final colorHex = business['cardColor'] ?? '#333333';
                    final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: textColor.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.store_rounded, color: color, size: 20),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      business['companyName'] ?? lang.translate('unknown_business'),
                                      style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    Icons.coffee_rounded,
                                    size: 16,
                                    color: (starIndex < rating) ? Colors.amber : Colors.grey.withValues(alpha: 0.2),
                                  );
                                }),
                              )
                            ],
                          ),
                          if (comment != null && comment.toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: textColor.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                comment,
                                style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.8), fontSize: 14),
                              ),
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPendingList(LanguageProvider lang, Color textColor, Color cardColor) {
    return _pendingReviews.isEmpty
        ? _buildEmptyState(lang, textColor, 'no_pending_reviews')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingReviews.length,
            itemBuilder: (context, index) {
              final tx = _pendingReviews[index];
              final business = tx['business'] ?? {};
              final dateStr = tx['createdAt'];
              final date = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

              final colorHex = business['cardColor'] ?? '#333333';
              final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: textColor.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.history_rounded, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business['companyName'] ?? lang.translate('unknown_business'),
                            style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            formattedDate,
                            style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showRateNowBottomSheet(tx['_id'], business['_id'] ?? business['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEE2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(lang.translate('rate_now')),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildEmptyState(LanguageProvider lang, Color textColor, String key) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded, size: 64, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            lang.translate(key),
            style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showRateNowBottomSheet(String transactionId, String businessId) async {
    int rating = 5;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(
                Provider.of<LanguageProvider>(context).translate('rate_experience'),
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setModalState(() => rating = index + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.coffee_rounded,
                        size: 40,
                        color: index < rating ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: Provider.of<LanguageProvider>(context).translate('rating_comment_hint'),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEE2C2C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSubmitting ? null : () async {
                      setModalState(() => isSubmitting = true);
                      try {
                        final api = context.read<ApiService>();
                        await api.submitReview(transactionId, businessId, rating, commentController.text);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _fetchReviews(); // Refresh lists
                        showCustomPopup(context, message: Provider.of<LanguageProvider>(context, listen: false).translate('success_review'), type: PopupType.success);
                      } catch (e) {
                         setModalState(() => isSubmitting = false);
                         if (!context.mounted) return;
                         showCustomPopup(context, message: e.toString(), type: PopupType.error);
                      }
                    },
                    child: isSubmitting 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(Provider.of<LanguageProvider>(context).translate('submit_review'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
