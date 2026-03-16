import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui'; // For ImageFilter
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/language_provider.dart';
import '../../core/widgets/auto_text.dart';
import 'menu_item_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final dynamic businessColor;
  final String? businessImage;
  final String? businessLogo;

  const MenuScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    this.businessColor,
    this.businessImage,
    this.businessLogo,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _isLoading = true;
  List<dynamic> _allProducts = []; // Store all fetched products
  List<dynamic> _products = []; // Currently displayed (filtered/sorted)
  List<dynamic> _popularProducts = [];

  // Categories — stored as localization keys
  final List<String> _categoryKeys = [
    'cat_all',
    'cat_deals',
    'cat_hot_coffee',
    'cat_cold_coffee',
    'cat_hot_drinks',
    'cat_cold_drinks',
    'cat_desserts',
  ];
  // Map from localization key -> Turkish DB category value (for filtering)
  final Map<String, String> _categoryTrValues = {
    'cat_all': 'Tümü',
    'cat_deals': 'Fırsatlar',
    'cat_hot_coffee': 'Sıcak Kahveler',
    'cat_cold_coffee': 'Soğuk Kahveler',
    'cat_hot_drinks': 'Sıcak İçecekler',
    'cat_cold_drinks': 'Soğuk İçecekler',
    'cat_desserts': 'Tatlılar',
  };
  String _selectedCategoryKey = 'cat_all'; // key into _categoryKeys

  // Sorting
  String _sortOption = 'default'; // default, price_asc, price_desc

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      final api = context.read<ApiService>();
      final products = await api.getBusinessProducts(widget.businessId);
      
      if (mounted) {
        setState(() {
          _allProducts = products;
          _popularProducts = products.where((p) => p['isPopular'] == true).toList();
          _isLoading = false;
          _applyFilterAndSort(); // Initial Application
        });
      }
    } catch (e) {
      debugPrint('Error fetching menu: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilterAndSort() {
    List<dynamic> temp = List.from(_allProducts);

    // Filter by Category and Availability
    temp = temp.where((p) => p['isAvailable'] != false).toList();
    final trValue = _categoryTrValues[_selectedCategoryKey] ?? 'Tümü';
    if (trValue != 'Tümü') {
      temp = temp.where((p) => p['category'] == trValue).toList();
    }

    // Sort - use effective price (price - discount)
    if (_sortOption == 'price_asc') {
      temp.sort((a, b) {
        final priceA = (a['price'] as num) - (a['discount'] ?? 0);
        final priceB = (b['price'] as num) - (b['discount'] ?? 0);
        return priceA.compareTo(priceB);
      });
    } else if (_sortOption == 'price_desc') {
      temp.sort((a, b) {
        final priceA = (a['price'] as num) - (a['discount'] ?? 0);
        final priceB = (b['price'] as num) - (b['discount'] ?? 0);
        return priceB.compareTo(priceA);
      });
    }

    setState(() {
      _products = temp;
    });
  }

  void _onCategorySelected(String categoryKey) {
    setState(() {
      _selectedCategoryKey = categoryKey;
      _applyFilterAndSort();
    });
  }

  void _showSortOptions() {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.translate('sort_title'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort),
                title: Text(lang.translate('sort_default'), style: GoogleFonts.outfit()),
                selected: _sortOption == 'default',
                selectedColor: AppTheme.primaryColor,
                onTap: () {
                  setState(() => _sortOption = 'default');
                  _applyFilterAndSort();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: Text(lang.translate('sort_price_asc'), style: GoogleFonts.outfit()),
                selected: _sortOption == 'price_asc',
                selectedColor: AppTheme.primaryColor,
                onTap: () {
                  setState(() => _sortOption = 'price_asc');
                  _applyFilterAndSort();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: Text(lang.translate('sort_price_desc'), style: GoogleFonts.outfit()),
                selected: _sortOption == 'price_desc',
                selectedColor: AppTheme.primaryColor,
                onTap: () {
                  setState(() => _sortOption = 'price_desc');
                  _applyFilterAndSort();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final baseUrl = ApiConfig.baseUrl.replaceAll(RegExp(r'/api$'), '');
    return '$baseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildCreativeAppBar(),
                
                if (_allProducts.isEmpty)
                 SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            context.read<LanguageProvider>().translate('menu_preparing'),
                            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (_popularProducts.isNotEmpty && _selectedCategoryKey == 'cat_all') _buildPopularSection(),
                  
                  _buildMenuSection(),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
    );
  }

  Widget _buildCreativeAppBar() {
    final logoUrl = _getImageUrl(widget.businessLogo ?? widget.businessImage);
    final coverUrl = _getImageUrl(widget.businessImage);
    final bool hasCover = coverUrl.isNotEmpty && coverUrl != logoUrl;

    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFEBEBEB),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.deepBrown, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          widget.businessName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: AppTheme.deepBrown,
            fontSize: 20,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image or Default Gradient
            if (hasCover)
               Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container())
            else
               Container(
                 decoration: BoxDecoration(
                   gradient: LinearGradient(
                     begin: Alignment.topCenter,
                     end: Alignment.bottomCenter,
                     colors: [
                       AppTheme.primaryColor.withValues(alpha: 0.08),
                       const Color(0xFFEBEBEB),
                     ],
                   )
                 ),
               ),

            // Subtle overlay to ensure text readability and smooth transition to page body
            if (hasCover)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      const Color(0xFFEBEBEB),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

            // Big Logo Graphic
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                if (logoUrl.isNotEmpty)
                   Container(
                     width: 90, height: 90,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.white,
                       image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 5))],
                       border: Border.all(color: Colors.white, width: 4),
                     ),
                   )
                else 
                   Container(
                     width: 90, height: 90,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.white,
                       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 5))],
                       border: Border.all(color: Colors.white, width: 4),
                     ),
                     child: const Icon(Icons.storefront_rounded, color: AppTheme.deepBrown, size: 40),
                   ),
                const SizedBox(height: 25), // Space for the title
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 5)),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    context.watch<LanguageProvider>().translate('popular_products'),
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _popularProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final product = _popularProducts[index];
                  return _buildCreativePopularCard(product);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 5)),
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Internal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4, height: 24,
                        decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.watch<LanguageProvider>().translate('menu_header'),
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.sort_rounded, color: Colors.grey[800]),
                    onPressed: _showSortOptions,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Categories List
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                 itemCount: _categoryKeys.length,
                 separatorBuilder: (_, __) => const SizedBox(width: 8),
                 itemBuilder: (context, index) {
                   final key = _categoryKeys[index];
                   final isSelected = key == _selectedCategoryKey;
                   final label = context.watch<LanguageProvider>().translate(key);
                   return GestureDetector(
                     onTap: () => _onCategorySelected(key),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       decoration: BoxDecoration(
                         color: isSelected ? AppTheme.primaryColor : const Color(0xFFF5F5F7),
                         borderRadius: BorderRadius.circular(20),
                         boxShadow: isSelected
                             ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))]
                             : const [],
                       ),
                       child: Text(
                         label,
                         style: GoogleFonts.outfit(
                           color: isSelected ? Colors.white : Colors.black87,
                           fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                           fontSize: 14,
                         ),
                       ),
                     ),
                   );
                 },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Products Grid (Shrunk wrapped so it fits inside the column)
            if (_products.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
                child: Center(
                  child: Text(
                    context.watch<LanguageProvider>().translate('no_products_in_cat'),
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _buildCreativeGridCard(product);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreativePopularCard(dynamic product) {
    final imageUrl = _getImageUrl(product['imageUrl']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuItemDetailScreen(
              product: Map<String, dynamic>.from(product),
              businessName: widget.businessName,
              businessLogo: widget.businessLogo ?? widget.businessImage,
            ),
          ),
        );
      },
      child: Container(
      width: 160,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF9E9E9E).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Container(color: AppTheme.cardBackground),
                    )
                  : Container(color: AppTheme.cardBackground),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₺${(product['price'] as num) - (product['discount'] ?? 0)}',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                      if ((product['discount'] ?? 0) > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₺${product['price']}',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  AutoText(
                    product['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12, right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }


  Widget _buildCreativeGridCard(dynamic product) {
    final imageUrl = _getImageUrl(product['imageUrl']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuItemDetailScreen(
              product: Map<String, dynamic>.from(product),
              businessName: widget.businessName,
              businessLogo: widget.businessLogo ?? widget.businessImage,
            ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Figma standard
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Area
          Expanded(
            flex: 60,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => Container(color: const Color(0xFFF5F5F5)),
                          )
                        : Container(color: const Color(0xFFF5F5F5), child: Icon(Icons.fastfood_rounded, color: Colors.grey[300], size: 40)),
                  ),
                ),
                Positioned(
                  bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20), // Pill shape
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                    ),
                    child: Text(
                      '${(((product['price'] as num) - (product['discount'] ?? 0)).toInt())}₺',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Info Area
          Expanded(
            flex: 40,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoText(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.lightTextPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: AutoText(
                      product['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
