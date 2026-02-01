import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/models/campaign_model.dart';
import '../../core/widgets/campaign_slider.dart';
import '../../core/widgets/auto_text.dart';
import '../../core/providers/business_provider.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/icons/takeaway_cup_icon.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Map<String, dynamic> businessData;

  const BusinessDetailScreen({super.key, required this.businessData});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  // Real Local state to allow refreshing UI on sim
  late int _stamps;
  late int _stampsTarget;
  late int _giftsCount;
  late String _points;
  late String _businessId;
  bool _isAddingLoading = false;

  bool _isNew = false;
  String? _address;

  @override
  void initState() {
    super.initState();
    final data = widget.businessData;
    _stamps = data['stamps'] ?? 0;
    _stampsTarget = data['stampsTarget'] ?? 6;
    _giftsCount = data['giftsCount'] ?? 0;
    _points = (data['points'] ?? '0').toString();
    _businessId = data['id'] ?? '';
    _isNew = data['isNew'] ?? false;
    
    // Format Address
    final city = data['city'] ?? '';
    final district = data['district'] ?? '';
    final neighborhood = data['neighborhood'] ?? '';
    List<String> parts = [];
    if (neighborhood.toString().isNotEmpty) parts.add(neighborhood.toString());
    if (district.toString().isNotEmpty) parts.add(district.toString());
    if (city.toString().isNotEmpty) parts.add(city.toString());
    _address = parts.isNotEmpty ? parts.join(', ') : null;

    // Fetch campaigns for this business
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().fetchCampaigns(_businessId);
    });
  }

  Future<void> _navigateToScanner() async {
    print("🔘 BusinessDetailScreen: Navigating to scanner with ID: $_businessId, Name: ${widget.businessData['name']}");
    
    // Navigate to general scanner which handles validations
    // We pass the expected business ID and Name to enforce validation
    await context.push('/customer-scanner', extra: {
      'expectedBusinessId': _businessId,
      'expectedBusinessName': widget.businessData['name'],
      'expectedBusinessColor': widget.businessData['color'],
      'currentStamps': _stamps,
      'targetStamps': _stampsTarget,
      'currentGifts': _giftsCount,
      'currentPoints': _points,
    });
    // Refresh data after return
    if (mounted) {
       _refreshData();
    }
  }

  Future<void> _refreshData() async {
      // Re-fetch business data to update stamps/points
      try {
        final api = context.read<ApiService>();
        // We might need a specific endpoint to get single business details or just refresh list
        // For now, re-fetching global list and finding this business again
        // Or if we have a direct endpoint:
        final updatedData = await api.getBusinessById(_businessId);
        setState(() {
            _stamps = updatedData['stamps'] ?? _stamps;
            _stampsTarget = updatedData['stampsTarget'] ?? _stampsTarget;
            _giftsCount = updatedData['giftsCount'] ?? _giftsCount;
            _points = (updatedData['points'] ?? _points).toString();
        });
      } catch (e) {
          print("Error refreshing business data: $e");
      }
  }

  Future<void> _showSpendQRDialog() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    if (_giftsCount <= 0) {
      showCustomPopup(
        context,
        message: Provider.of<LanguageProvider>(context, listen: false).translate('no_gift_to_spend'),
        type: PopupType.error,
      );
      return;
    }

    final qrData = '{"customer": "${user.id}", "business": "$_businessId", "type": "GIFT_REDEEM"}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Provider.of<LanguageProvider>(context, listen: false).translate('payment_qr'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              Text(Provider.of<LanguageProvider>(context, listen: false).translate('scan_to_redeem'), 
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
              ),
              const SizedBox(height: 24),
              // Simulation Buttons Removed
              const SizedBox(height: 8),
              // Stamp (+1) Button Removed
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('close'), style: GoogleFonts.outfit(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(
                Provider.of<LanguageProvider>(context, listen: false).translate('order_history'),
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: context.read<ApiService>().getTransactionHistory(_businessId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("${Provider.of<LanguageProvider>(context, listen: false).translate('error')}: ${snapshot.error}"));
                    }
                    final history = snapshot.data ?? [];
                    if (history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(Provider.of<LanguageProvider>(context, listen: false).translate('no_orders_yet'), style: GoogleFonts.outfit(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: history.length,
                      separatorBuilder: (context, index) => const Divider(height: 32),
                      itemBuilder: (context, index) {
                        final tx = history[index];
                        final type = tx['type']; // 'STAMP', 'POINT', or 'GIFT_REDEEM'
                        final category = tx['category']; // 'KAZANIM' or 'HARCAMA'
                        final isEarn = category == 'KAZANIM';
                        final value = tx['value'] ?? 1;
                        
                        final date = DateTime.parse(tx['createdAt']);
                        final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(date);

                        String title = "İşlem";
                        String sign = isEarn ? "+" : "-";
                        
                        if (type == 'STAMP') {
                          title = Provider.of<LanguageProvider>(context, listen: false).translate('stamp_earned');
                        } else if (type == 'POINT') {
                          title = Provider.of<LanguageProvider>(context, listen: false).translate('point_earned');
                        } else if (type == 'GIFT_REDEEM') {
                          title = Provider.of<LanguageProvider>(context, listen: false).translate('gift_redeemed');
                        }
                        
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isEarn ? Colors.green : Colors.orange).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isEarn ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                                color: isEarn ? Colors.green : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "$sign$value",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isEarn ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
    
  @override
  Widget build(BuildContext context) {
    final data = widget.businessData;
    final String name = data['name'] ?? 'İşletme';
    final String value = data['value'] ?? '0.00'; 
    dynamic rawColor = data['color'];
    Color brandColor;
    if (rawColor is Color) {
      brandColor = rawColor;
    } else if (rawColor is String) {
      try {
        brandColor = Color(int.parse(rawColor.replaceAll('#', '0xFF')));
      } catch (e) {
        brandColor = const Color(0xFF333333);
      }
    } else {
      brandColor = const Color(0xFF333333);
    } 
    
    // User Name
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final userName = user?.fullName ?? "Misafir";
    final lang = context.watch<LanguageProvider>();

    // Dynamic Greeting Logic
    final hour = DateTime.now().hour;
    String greetingKey;
    if (hour >= 6 && hour < 12) {
      greetingKey = 'good_morning';
    } else if (hour >= 12 && hour < 18) {
      greetingKey = 'good_afternoon';
    } else if (hour >= 18 && hour < 22) {
      greetingKey = 'good_evening';
    } else {
      greetingKey = 'good_night';
    }
    final greeting = lang.translate(greetingKey);

    return Scaffold(
      backgroundColor: brandColor, 
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isNew,
            child: CustomScrollView(
              physics: _isNew 
                  ? const NeverScrollableScrollPhysics() 
                  : const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: brandColor,
            elevation: 0,
            // Shape removed -> Flat bottom, but visual curve comes from Body Top Radius
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Transform.translate(
              offset: const Offset(-8, 0),
              child: Text(
                name,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ),
            centerTitle: false,
            titleSpacing: 0,
            actions: [
               const SizedBox(width: 48),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  color: brandColor,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),
                        
                        // [1] HEADER
                        Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                image: const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&q=80&w=100'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(greeting, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)), // Dynamic greeting
                                  Text(userName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // QR Scanner Button
                            GestureDetector(
                               onTap: _navigateToScanner,
                               child: Container(
                                 width: 50, height: 50,
                                 decoration: const BoxDecoration(
                                   color: Colors.white,
                                   shape: BoxShape.circle,
                                 ),
                                 child: Icon(Icons.qr_code_scanner_rounded, color: brandColor, size: 28),
                               ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // [2] STATS ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end, // Align bottom
                          children: [
                            SizedBox(
                              width: 80, height: 90,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 70, height: 70,
                                    child: CircularProgressIndicator(
                                      value: _stamps / _stampsTarget,
                                      color: const Color(0xFFFFD54F),
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      strokeWidth: 4,
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.local_cafe_outlined, color: Colors.white, size: 28),
                                      const SizedBox(height: 4),
                                      Text("$_stamps/$_stampsTarget", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(lang.translate('my_coffees'), style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text("$_giftsCount", style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.0)),
                                    const SizedBox(width: 6),
                                    const TakeawayCupIcon(color: Colors.white, size: 24),
                                  ],
                                ),
                                const SizedBox(height: 8), // Alignment correction
                              ],
                            ),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(lang.translate('my_points'), style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(_points, style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.0)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                                  ],
                                ),
                                const SizedBox(height: 8), // Alignment correction
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // [3] CAMPAIGN CARD (Dynamic Slider)
                        Consumer<CampaignProvider>(
                          builder: (context, campProvider, child) {
                            final allCampaigns = campProvider.getCampaignsForBusiness(_businessId);
                            final promotedCampaigns = allCampaigns.where((c) => c.isPromoted).toList();
                            
                            if (promotedCampaigns.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return CampaignSlider(campaigns: promotedCampaigns);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_address != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 16, color: brandColor.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _address!,
                            style: GoogleFonts.outfit(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showSpendQRDialog,
                          child: Container(
                            height: 100,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: brandColor, // Dynamic Brand Color
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lang.translate('spend_qr'), 
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.1),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.stars_rounded, color: Colors.white),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(lang.translate('spend_gifts'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showHistoryBottomSheet,
                          child: Container(
                            height: 100,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: brandColor, // Dynamic Brand Color
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start, // Align icon to top
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lang.translate('order_history').replaceFirst(' ', '\n'), 
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.1),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.history, color: Colors.white),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(lang.translate('all'), style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 10),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // 3. News Section (DARK SECTION -> NOW WHITE)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              color: Colors.white, // Full White
              // No padding here for full width slider, padding applied to children except slider
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 30.0, bottom: 16.0),
                    child: Text(lang.translate('campaigns'), style: GoogleFonts.outfit(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  
                   // Slider (Full width)
                   SizedBox(
                     height: 180,
                     child: Consumer<CampaignProvider>(
                       builder: (context, campProvider, child) {
                         final campaigns = campProvider.getCampaignsForBusiness(_businessId);
                         // Sort: Newest first (createdAt descending)
                         final sortedCampaigns = List<CampaignModel>.from(campaigns)
                           ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                         if (sortedCampaigns.isEmpty) {
                           return Center(
                             child: Text(
                               lang.translate('no_campaigns_soon'),
                               style: GoogleFonts.outfit(color: Colors.grey),
                             ),
                           );
                         }

                         return ListView.builder(
                           scrollDirection: Axis.horizontal,
                           padding: const EdgeInsets.symmetric(horizontal: 20),
                           itemCount: sortedCampaigns.length,
                           itemBuilder: (context, index) {
                             return _buildCampaignCard(sortedCampaigns[index], brandColor);
                           },
                         );
                       },
                     ),
                   ),
                   const Spacer(),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
          if (_isNew)
            Positioned.fill(
              child: Container(
                color: Colors.grey.withOpacity(0.2), // Light grey overlay
              ),
            ),
          // [FIX] Active Back Button even when locked
          if (_isNew)
             Positioned(
               top: 0, 
               left: 0,
               child: SafeArea(
                 child: Container(
                   margin: const EdgeInsets.only(left: 4), // Match usual leading padding roughly
                   child: IconButton(
                     icon: const Icon(Icons.arrow_back_ios_new, color: Colors.transparent),
                     onPressed: () => context.pop(),
                   ),
                 ),
               ),
             ),
        ],
      ),
      bottomNavigationBar: _isNew 
        ? Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: ElevatedButton(
              onPressed: _isAddingLoading ? null : _addToWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isAddingLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(lang.translate('add_to_wallet'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        : null,
    );
  }

  Future<void> _addToWallet() async {
    setState(() => _isAddingLoading = true);
    try {
      await context.read<ApiService>().addFirm(_businessId);
      if (mounted) {
        showCustomPopup(
          context,
          message: Provider.of<LanguageProvider>(context, listen: false).translate('added_to_wallet_msg'),
          type: PopupType.success,
        );
        // Refresh providers
        context.read<BusinessProvider>().fetchMyFirms();
        context.read<BusinessProvider>().fetchExploreFirms();
        // Unlock screen instead of popping
        setState(() {
           _isNew = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomPopup(
          context,
          message: "${Provider.of<LanguageProvider>(context, listen: false).translate('error')}: $e",
          type: PopupType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingLoading = false);
    }
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard(CampaignModel campaign, Color color) {
    final lang = context.read<LanguageProvider>();
    return GestureDetector(
      onTap: () => context.push('/campaign-detail', extra: campaign),
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              if (campaign.headerImage != null)
                Positioned.fill(
                  child: Image.network(
                    resolveImageUrl(campaign.headerImage)!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: color.withOpacity(0.1)),
                  ),
                ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.2),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "FIRSAT",
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    AutoText(
                      campaign.title,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign.shortDescription,
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
