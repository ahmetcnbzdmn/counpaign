import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/utils/location_helper.dart';

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
  
  String _currentFilter = 'Tümü'; // 'Tümü', 'Cüzdandakiler', 'Diğerleri'

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

      // 2. Filter by category (Tümü, Cüzdandakiler, Diğerleri)
      if (_currentFilter == 'Cüzdandakiler') {
        filtered = filtered.where((firm) => _addedFirms.contains(firm['_id'])).toList();
      } else if (_currentFilter == 'Diğerleri') {
        filtered = filtered.where((firm) => !_addedFirms.contains(firm['_id'])).toList();
      }

      // 3. Sort (Prioritize Added in 'Tümü')
      if (_currentFilter == 'Tümü') {
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
    try {
      final api = context.read<ApiService>();
      
      final results = await Future.wait([
        api.getAvailableFirms(),
        api.getMyFirms(),
        api.getNewestBusinesses(), 
      ]);

      if (!mounted) return;

      final available = results[0] as List<dynamic>;
      final myFirms = results[1] as List<dynamic>;
      final newest = results[2] as List<dynamic>;
      
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
    final api = context.read<ApiService>();
    final isAdded = _addedFirms.contains(id);

    if (isAdded) return; 

    try {
      await api.addFirm(id);
      setState(() {
        _addedFirms.add(id);
        _applyFilters(); 
      });
      showCustomPopup(
        context,
        message: 'İşletme eklendi!',
        type: PopupType.success,
      );
    } catch (e) {
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

    return Scaffold(
      backgroundColor: bgColor, 
      appBar: AppBar(
        title: Text('Kafe Ekle', style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent, 
        scrolledUnderElevation: 0, 
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(color: textColor),
              decoration: InputDecoration(
                hintText: 'Kafe ara...',
                hintStyle: GoogleFonts.outfit(color: textColor.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.5)),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // [NEW] Location Filter Dropdowns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildDropdown<String>(
                    hint: 'İl',
                    value: _selectedCity,
                    items: _cities,
                    onChanged: _onCityChanged,
                    context: context,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdown<String>(
                    hint: 'İlçe',
                    value: _selectedDistrict,
                    items: _districts,
                    onChanged: _onDistrictChanged,
                    context: context,
                    enabled: _selectedCity != null,
                  ),
                  const SizedBox(width: 8),
                  _buildDropdown<String>(
                    hint: 'Semt',
                    value: _selectedNeighborhood,
                    items: _neighborhoods,
                    onChanged: _onNeighborhoodChanged,
                    context: context,
                    enabled: _selectedDistrict != null,
                  ),
                ],
              ),
            ),
          ),

          if (_newestFirms.isNotEmpty && !_isLoading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Yeni Eklenen Kafeler',
                style: GoogleFonts.outfit(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 110, 
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _newestFirms.length > 10 ? 10 : _newestFirms.length, 
                itemBuilder: (context, index) {
                  final firm = _newestFirms[index];
                  final colorHex = firm['cardColor'] ?? '#333333';
                  final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                  final id = firm['_id'].toString();
                  final isAdded = _addedFirms.contains(id);

                  return GestureDetector(
                    onTap: () => _handleFirmTap(id, firm),
                    child: Container(
                      width: 110, 
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: textColor.withOpacity(0.05)),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getIcon(firm['cardIcon']), color: color, size: 16),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      firm['companyName'] ?? '',
                                      style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      firm['category'] ?? '',
                                      style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 10),
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isAdded)
                            Positioned(
                              top: 6, right: 6,
                              child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tüm Kafeler',
              style: GoogleFonts.outfit(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12), 

          // Filter Chips 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Tümü'),
                const SizedBox(width: 8),
                _buildFilterChip('Cüzdandakiler'),
                const SizedBox(width: 8),
                _buildFilterChip('Diğerleri'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEE2C2C))) 
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredFirms.length,
                  itemBuilder: (context, index) {
                    final firm = _filteredFirms[index];
                    final id = firm['_id'];
                    final isAdded = _addedFirms.contains(id);

                    // Use visual props
                    final colorHex = firm['cardColor'] ?? '#333333';
                    final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                    
                    return Card(
                      color: cardColor,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: textColor.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getIcon(firm['cardIcon']), color: color),
                        ),
                        title: Text(
                          firm['companyName'] ?? 'Bilinmeyen',
                          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column( // Added Location info
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firm['category'] ?? 'Genel',
                              style: GoogleFonts.outfit(color: textColor.withOpacity(0.7), fontSize: 14),
                            ),
                            if (firm['district'] != null && firm['district'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  "${firm['district']} / ${firm['neighborhood'] ?? ''}",
                                  style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 12),
                                ),
                              )
                          ],
                        ),
                        onTap: () => _handleFirmTap(id, firm), 
                        trailing: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isAdded 
                              ? const Icon(Icons.check_circle, key: ValueKey('added'), color: Colors.green, size: 30)
                              : Icon(Icons.add_circle_outline_rounded, key: const ValueKey('add'), color: textColor.withOpacity(0.4), size: 30),
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
        color: enabled ? cardColor : cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: items.contains(value) ? value : null,
          hint: Text(hint, style: GoogleFonts.outfit(color: textColor.withOpacity(enabled ? 0.6 : 0.3), fontSize: 13)),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString(), style: GoogleFonts.outfit(color: textColor, fontSize: 13)),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
          dropdownColor: cardColor,
          icon: Icon(Icons.arrow_drop_down, color: textColor.withOpacity(enabled ? 0.6 : 0.3)),
          style: GoogleFonts.outfit(color: textColor, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _currentFilter == label;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = label;
          _applyFilters();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEE2C2C) : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : textColor.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : textColor.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
