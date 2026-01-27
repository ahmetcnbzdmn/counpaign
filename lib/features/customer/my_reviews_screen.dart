import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/language_provider.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.getReviews();
      setState(() {
        _reviews = data;
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
    final filteredReviews = _getFilteredReviews();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(lang.translate('my_reviews'), style: GoogleFonts.outfit(color: textColor)),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
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
                  child: filteredReviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_outline_rounded, size: 64, color: textColor.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                _reviews.isEmpty ? lang.translate('no_reviews_yet') : lang.translate('no_reviews_filter'),
                                style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReviews.length,
                          itemBuilder: (context, index) {
                            final review = filteredReviews[index];
                            final business = review['business'] ?? {};
                            final rating = review['rating'] ?? 0;
                            final comment = review['comment'];
                            final date = DateTime.parse(review['createdAt']).toLocal();
                            final formattedDate = DateFormat('dd MMM yyyy').format(date);
        
                            final colorHex = business['cardColor'] ?? '#333333';
                            final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
        
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: textColor.withOpacity(0.05)),
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
                                          color: color.withOpacity(0.1),
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
                                              style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(5, (starIndex) {
                                          return Icon(
                                            Icons.coffee_rounded,
                                            size: 16,
                                            color: (starIndex < rating) ? Colors.amber : Colors.grey.withOpacity(0.2),
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
                                        color: textColor.withOpacity(0.03),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        comment,
                                        style: GoogleFonts.outfit(color: textColor.withOpacity(0.8), fontSize: 14),
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
            ),
    );
  }
}
