import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/smart_network_image.dart';
import '../../core/utils/location_helper.dart';
import '../../core/providers/language_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/guest_provider.dart';
import '../../core/theme/app_theme.dart';

class AddFirmScreen extends StatefulWidget {
  const AddFirmScreen({super.key});

  @override
  State<AddFirmScreen> createState() => _AddFirmScreenState();
}



class _AddFirmScreenState extends State<AddFirmScreen> {
  bool _isLoading = true;
  List<dynamic> _allFirms = [];
  List<dynamic> _filteredFirms = [];
  List<dynamic> _newestFirms = []; 
  final Set<String> _addedFirms = {}; 
  final Map<String, dynamic> _myFirmsMap = {};
  final TextEditingController _searchController = TextEditingController();
  
  String _currentFilter = 'all'; // 'all', 'in_wallet', 'others'

  // [NEW] Location Filters
  String? _selectedCity = 'Ankara';
  String? _selectedDistrict;
  String? _selectedNeighborhood;
  List<String> _cities = [];
  List<String> _districts = [];
  List<String> _neighborhoods = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadLocationData();
    });
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadLocationData() async {
    await LocationHelper.loadData();
    setState(() {
      _cities = LocationHelper.getCities();
      if (_cities.isNotEmpty) {
        _selectedCity = 'Ankara'; // Pre-select Ankara as requested
        _districts = LocationHelper.getDistricts(_selectedCity!);
      }
    });
  }

  void _onCityChanged(String? value) {
    if (value == _selectedCity) return;
    setState(() {
      _selectedCity = value;
      _selectedDistrict = null;
      _selectedNeighborhood = null;
      _districts = value != null ? LocationHelper.getDistricts(value) : [];
      _neighborhoods = [];
      _applyFilters();
    });
  }

  void _onDistrictChanged(String? value) {
    if (value == _selectedDistrict) return;
    setState(() {
      _selectedDistrict = value;
      _selectedNeighborhood = null;
      _neighborhoods = (value != null && _selectedCity != null) 
          ? LocationHelper.getNeighborhoods(_selectedCity!, value) 
          : [];
      _applyFilters();
    });
  }

  void _onNeighborhoodChanged(String? value) {
    setState(() {
      _selectedNeighborhood = value;
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      // 1. Filter by search query AND Location
      var filtered = _allFirms.where((firm) {
        final name = (firm['companyName'] ?? '').toLowerCase();
        final category = (firm['category'] ?? '').toLowerCase();
        
        // Location Check
        final firmCity = firm['city'] as String?; // Optional
        final firmDistrict = firm['district'] as String?;
        final firmNeighborhood = firm['neighborhood'] as String?;

        bool locationMatch = true;
        if (_selectedCity != null) {
          if (firmCity != null && firmCity != _selectedCity) locationMatch = false;
        }
        if (_selectedDistrict != null) {
          if (firmDistrict != null && firmDistrict != _selectedDistrict) locationMatch = false;
        }
        if (_selectedNeighborhood != null) {
          if (firmNeighborhood != null && firmNeighborhood != _selectedNeighborhood) locationMatch = false;
        }

        return (name.contains(query) || category.contains(query)) && locationMatch;
      }).toList();

      // 2. Filter by category (all, in_wallet, others)
      if (_currentFilter == 'in_wallet') {
        filtered = filtered.where((firm) => _addedFirms.contains(firm['_id'])).toList();
      } else if (_currentFilter == 'others') {
        filtered = filtered.where((firm) => !_addedFirms.contains(firm['_id'])).toList();
      }

      // 3. Sort (Prioritize Added in 'all')
      if (_currentFilter == 'all') {
        filtered.sort((a, b) {
          final aId = a['_id'].toString();
          final bId = b['_id'].toString();
          final aAdded = _addedFirms.contains(aId);
          final bAdded = _addedFirms.contains(bId);
          
          if (aAdded && !bAdded) return -1; // Added comes first
          if (!aAdded && bAdded) return 1;  // Not added comes last
          
          return (a['companyName'] ?? '').toLowerCase().compareTo((b['companyName'] ?? '').toLowerCase());
        });
      }

      _filteredFirms = filtered;
    });
  }

  // ... (Load Data Logic remains same)
  // Re-pasting _loadData, _toggleFirm, _handleFirmTap to match line count/context if needed, 
  // but since I am replacing the class content extensively, I will just reference existing methods if I could, 
  // but "replace_file_content" logic requires contiguous block.
  // I will just implement the _loadData and others as they were but inside this replacement block?
  // No, the tool replaced LINES 14 to 410. So I need to provide the FULL content of the class state.

  Future<void> _loadData() async {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    try {
      final api = context.read<ApiService>();

      if (isAuthenticated) {
        final results = await Future.wait([
          api.getAvailableFirms(),
          api.getMyFirms(),
          api.getNewestBusinesses(),
        ]);

        if (!mounted) return;

        final available = results[0];
        final myFirms = results[1];
        final newest = results[2];

        final myFirmIds = myFirms.map((f) => f['id'].toString()).toSet();

        setState(() {
          _allFirms = available;
          _newestFirms = newest;
          _addedFirms.clear();
          _addedFirms.addAll(myFirmIds);

          _myFirmsMap.clear();
          for (var firm in myFirms) {
            _myFirmsMap[firm['id'].toString()] = firm;
          }

          _isLoading = false;
          _applyFilters();
        });
      } else {
        // Guest: load explore data + populate addedFirms from guest wallet
        final results = await Future.wait([
          api.getAvailableFirms().catchError((_) => <dynamic>[]),
          api.getNewestBusinesses().catchError((_) => <dynamic>[]),
        ]);

        if (!mounted) return;

        final guestProvider = context.read<GuestProvider>();
        // Sync from backend first so wallet is fresh before populating _addedFirms
        await guestProvider.syncFromBackend().catchError((_) {});

        if (!mounted) return;

        final guestWallet = guestProvider.wallet;
        final guestWalletIds = guestWallet.map((f) => (f['_id'] ?? f['id'] ?? '').toString()).toSet();

        setState(() {
          _allFirms = results[0];
          _newestFirms = results[1];
          _addedFirms.clear();
          _addedFirms.addAll(guestWalletIds);
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showCustomPopup(
        context,
        message: '$e',
        type: PopupType.error,
      );
    }
  }

  Future<void> _toggleFirm(String id) async {
    final isAdded = _addedFirms.contains(id);
    if (isAdded) return;

    if (!context.read<AuthProvider>().isAuthenticated) {
      // Guest: add to guest wallet
      final guest = context.read<GuestProvider>();
      final firmData = _allFirms.firstWhere(
        (f) => (f['_id'] ?? '').toString() == id,
        orElse: () => <String, dynamic>{},
      );
      await guest.addToWallet(id, firmData);
      if (!mounted) return;
      setState(() {
        _addedFirms.add(id);
        _applyFilters();
      });
      showCustomPopup(
        context,
        message: Provider.of<LanguageProvider>(context, listen: false).translate('success_firm_added'),
        type: PopupType.success,
      );
      return;
    }

    final api = context.read<ApiService>();
    try {
      await api.addFirm(id);
      if (!mounted) return;
      setState(() {
        _addedFirms.add(id);
        _applyFilters();
      });
      showCustomPopup(
        context,
        message: Provider.of<LanguageProvider>(context, listen: false).translate('success_firm_added'),
        type: PopupType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showCustomPopup(
        context,
        message: '$e',
        type: PopupType.error,
      );
    }
  }

  void _handleFirmTap(String id, Map<String, dynamic> firmData) {
    if (_addedFirms.contains(id)) {
      final myFirmData = _myFirmsMap[id];
      
      context.push('/business-detail', extra: {
        'id': myFirmData?['id'] ?? id,
        'name': myFirmData?['companyName'] ?? firmData['companyName'],
        'color': myFirmData?['cardColor'] ?? firmData['cardColor'],
        'stamps': myFirmData?['stamps'] ?? 0,
        'stampsTarget': myFirmData?['stampsTarget'] ?? 6,
        'giftsCount': myFirmData?['giftsCount'] ?? 0,
        'points': myFirmData?['points'] ?? '0',
        'icon': myFirmData?['cardIcon'] ?? firmData['cardIcon'],
        'logo': myFirmData?['logo'] ?? firmData['logo'],
        'image': myFirmData?['image'] ?? firmData['image'],
        'city': myFirmData?['city'] ?? firmData['city'],
        'district': myFirmData?['district'] ?? firmData['district'],
        'neighborhood': myFirmData?['neighborhood'] ?? firmData['neighborhood'],
        'reviewScore': myFirmData?['reviewScore'] ?? firmData['reviewScore'] ?? 0.0,
        'reviewCount': myFirmData?['reviewCount'] ?? firmData['reviewCount'] ?? 0,
      });
    } else {
      _toggleFirm(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final lang = Provider.of<LanguageProvider>(context);

    const yellow = Color(0xFFF9C06A);
    const deepBrown = Color(0xFF76410B);

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                              child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang.translate('page_title_add_cafe'),
                              style: GoogleFonts.outfit(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: yellow, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(
                                  lang.translate('discover_new_places'),
                                  style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.38), fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.outfit(color: textColor),
                        decoration: InputDecoration(
                          hintText: lang.translate('search_cafe'),
                          hintStyle: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4)),
                          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 22),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.15), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ),

                // Location Filter Dropdowns
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildDropdown<String>(hint: lang.translate('dropdown_city'), value: _selectedCity, items: _cities, onChanged: _onCityChanged, context: context),
                          const SizedBox(width: 8),
                          _buildDropdown<String>(hint: lang.translate('dropdown_district'), value: _selectedDistrict, items: _districts, onChanged: _onDistrictChanged, context: context, enabled: _selectedCity != null),
                          const SizedBox(width: 8),
                          _buildDropdown<String>(hint: lang.translate('dropdown_neighborhood'), value: _selectedNeighborhood, items: _neighborhoods, onChanged: _onNeighborhoodChanged, context: context, enabled: _selectedDistrict != null),
                        ],
                      ),
                    ),
                  ),
                ),

                // Yeni Eklenen Kafeler
                if (_newestFirms.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                      child: Row(
                        children: [
                          Container(width: 4, height: 20, decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 10),
                          Text(lang.translate('section_new_cafes'), style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      child: SizedBox(
                        height: 155,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: _newestFirms.length > 10 ? 10 : _newestFirms.length,
                          itemBuilder: (context, index) {
                            final firm = _newestFirms[index];
                            final id = firm['_id'].toString();
                            final isAdded = _addedFirms.contains(id);
                            final rawCat = firm['category'] ?? '';
                            final catText = rawCat.isNotEmpty ? _translateCategory(rawCat, lang) : lang.translate('general');
                            return GestureDetector(
                              onTap: () => _handleFirmTap(id, firm),
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: isAdded ? Colors.green : yellow, width: 2),
                                  boxShadow: [BoxShadow(color: yellow.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 56, height: 56,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(color: yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                                            child: (firm['logo'] != null || firm['image'] != null)
                                                ? SmartNetworkImage(url: resolveImageUrl(firm['logo'] ?? firm['image']) ?? '', fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => Icon(_getIcon(firm['cardIcon']), color: deepBrown, size: 25))
                                                : Icon(_getIcon(firm['cardIcon']), color: deepBrown, size: 25),
                                          ),
                                          const Spacer(),
                                          Text(firm['companyName'] ?? '', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 3),
                                          Text(catText, style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    if (isAdded)
                                      Positioned(
                                        top: 13, right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                                        ),
                                      )
                                    else
                                      Positioned(
                                        top: 13, right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(8)),
                                          child: Text(lang.translate('new_badge'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],

                // Tüm Kafeler başlığı + filter chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(width: 4, height: 20, decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 10),
                        Text(lang.translate('section_all_cafes'), style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: yellow.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text('${_filteredFirms.length}', style: GoogleFonts.outfit(color: deepBrown, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterChip('all', lang.translate('all')),
                          const SizedBox(width: 8),
                          _buildFilterChip('in_wallet', lang.translate('in_wallet')),
                          const SizedBox(width: 8),
                          _buildFilterChip('others', lang.translate('others')),
                        ],
                      ),
                    ),
                  ),
                ),

                // Firma listesi
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final firm = _filteredFirms[index];
                        final id = firm['_id'];
                        final isAdded = _addedFirms.contains(id);
                        final rawCategory = firm['category'] ?? '';
                        final category = rawCategory.isNotEmpty ? _translateCategory(rawCategory, lang) : '';
                        final double ratingVal = parseRating(firm['rating'] ?? firm['reviewScore'] ?? firm['avgRating'] ?? firm['averageRating']);
                        final int reviewCount = parseReviewCount(firm['reviewCount'] ?? firm['ratingCount'] ?? firm['reviewsCount']);

                        return GestureDetector(
                          onTap: () => _handleFirmTap(id, firm),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isAdded ? Colors.green.withValues(alpha: 0.5) : yellow.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: [BoxShadow(color: yellow.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60, height: 60,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(color: yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
                                    child: (firm['logo'] != null || firm['image'] != null)
                                        ? SmartNetworkImage(url: resolveImageUrl(firm['logo'] ?? firm['image']) ?? '', fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(_getIcon(firm['cardIcon']), color: deepBrown, size: 27))
                                        : Icon(_getIcon(firm['cardIcon']), color: deepBrown, size: 27),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firm['companyName'] ?? lang.translate('unknown_business'),
                                          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            if (category.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(color: yellow.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                                                child: Text(category, style: GoogleFonts.outfit(color: deepBrown, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            if (ratingVal > 0) ...[
                                              const Icon(Icons.star_rounded, size: 13, color: Color(0xFFE68A00)),
                                              const SizedBox(width: 2),
                                              Text(ratingVal.toStringAsFixed(1), style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                                              if (reviewCount > 0) Text(' ($reviewCount)', style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.35), fontSize: 11)),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        if (firm['district'] != null && (firm['district'] as String).isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_rounded, size: 12, color: textColor.withValues(alpha: 0.3)),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  "${firm['district']}${firm['neighborhood'] != null && (firm['neighborhood'] as String).isNotEmpty ? ' / ${firm['neighborhood']}' : ''}",
                                                  style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.4), fontSize: 12),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: isAdded
                                        ? Container(
                                            key: const ValueKey('added'),
                                            width: 38, height: 38,
                                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                                          )
                                        : Container(
                                            key: const ValueKey('add'),
                                            width: 38, height: 38,
                                            decoration: BoxDecoration(
                                              color: yellow,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [BoxShadow(color: yellow.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                                            ),
                                            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _filteredFirms.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _translateCategory(String raw, LanguageProvider lang) {
    final key = 'cat_${raw.toLowerCase().replaceAll(' ', '_')}';
    final translated = lang.translate(key);
    return translated != key ? translated : raw;
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required BuildContext context,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled ? cardColor : cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.08)),
        boxShadow: enabled ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ] : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : null,
          hint: Text(hint, style: GoogleFonts.outfit(color: textColor.withValues(alpha: enabled ? 0.55 : 0.3), fontSize: 13)),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString(), style: GoogleFonts.outfit(color: textColor, fontSize: 13)),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
          dropdownColor: cardColor,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor.withValues(alpha: enabled ? 0.5 : 0.25), size: 20),
          style: GoogleFonts.outfit(color: textColor, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _currentFilter == key;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = key;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : textColor.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? const Color(0xFF131313) : textColor.withValues(alpha: 0.7),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? iconName) {
    if (iconName == 'local_cafe_rounded') return Icons.local_cafe_rounded;
    if (iconName == 'coffee_rounded') return Icons.coffee_rounded;
    if (iconName == 'lunch_dining_rounded') return Icons.lunch_dining_rounded;
    if (iconName == 'checkroom_rounded') return Icons.checkroom_rounded;
    return Icons.storefront;
  }
}
