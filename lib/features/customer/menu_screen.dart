import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui'; // For ImageFilter
import '../../core/services/api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/ui_utils.dart';

class MenuScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final dynamic businessColor;
  final String? businessImage;

  const MenuScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    this.businessColor,
    this.businessImage,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _isLoading = true;
  List<dynamic> _allProducts = []; // Store all fetched products
  List<dynamic> _products = []; // Currently displayed (filtered/sorted)
  List<dynamic> _popularProducts = [];
  late Color _brandColor;
  late Color _brandDark;
  late Color _brandLight;

  // Categories
  final List<String> _categories = [
    'Tümü',
    'Sıcak Kahveler',
    'Soğuk Kahveler',
    'Sıcak İçecekler',
    'Soğuk İçecekler',
    'Tatlılar'
  ];
  String _selectedCategory = 'Tümü';

  // Sorting
  String _sortOption = 'default'; // default, price_asc, price_desc

  @override
  void initState() {
    super.initState();
    _parseColor();
    _fetchMenu();
  }

  void _parseColor() {
    Color base;
    if (widget.businessColor is Color) {
      base = widget.businessColor;
    } else if (widget.businessColor is String) {
      try {
        base = Color(int.parse(widget.businessColor.replaceAll('#', '0xFF')));
      } catch (e) {
        base = Colors.black;
      }
    } else {
      base = Colors.black;
    }
    _brandColor = base;
    _brandDark = HSLColor.fromColor(base).withLightness(0.3).toColor();
    _brandLight = HSLColor.fromColor(base).withLightness(0.9).toColor();
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
      print('Error fetching menu: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilterAndSort() {
    List<dynamic> temp = List.from(_allProducts);

    // Filter by Category and Availability
    temp = temp.where((p) => p['isAvailable'] != false).toList();
    if (_selectedCategory != 'Tümü') {
      temp = temp.where((p) => p['category'] == _selectedCategory).toList();
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

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilterAndSort();
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sıralama', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort),
                title: Text('Varsayılan', style: GoogleFonts.outfit()),
                selected: _sortOption == 'default',
                selectedColor: _brandColor,
                onTap: () {
                  setState(() => _sortOption = 'default');
                  _applyFilterAndSort();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: Text('Fiyat: Artan', style: GoogleFonts.outfit()),
                selected: _sortOption == 'price_asc',
                selectedColor: _brandColor,
                onTap: () {
                  setState(() => _sortOption = 'price_asc');
                  _applyFilterAndSort();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: Text('Fiyat: Azalan', style: GoogleFonts.outfit()),
                selected: _sortOption == 'price_desc',
                selectedColor: _brandColor,
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
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$baseUrl$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _brandColor))
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
                            'Menü Hazırlanıyor...',
                            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (_popularProducts.isNotEmpty && _selectedCategory == 'Tümü') _buildPopularHeader(),
                  if (_popularProducts.isNotEmpty && _selectedCategory == 'Tümü') _buildPopularList(),
                  
                  _buildStickyHeader(), // Categories & Sort
                  
                  _buildProductGrid(),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
    );
  }

  Widget _buildCreativeAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: _brandColor,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          widget.businessName.toUpperCase(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 1.2,
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.3), offset: const Offset(0, 2), blurRadius: 4),
            ]
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: _brandColor),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            // Light Patterns
            Positioned(
              right: -50, top: -50,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              ),
            ),
            if (widget.businessImage != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Image.network(
                    resolveImageUrl(widget.businessImage) ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => const SizedBox(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              'Öne Çıkanlar',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularList() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 280,
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
    );
  }

  Widget _buildStickyHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyFilterDelegate(
        child: Container(
          color: const Color(0xFFF5F5F7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4, height: 24,
                          decoration: BoxDecoration(color: _brandColor, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Menü',
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
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    return GestureDetector(
                      onTap: () => _onCategorySelected(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _brandColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected 
                              ? [BoxShadow(color: _brandColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                        ),
                        child: Text(
                          category,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreativePopularCard(dynamic product) {
    final imageUrl = _getImageUrl(product['imageUrl']);
    
    return Container(
      width: 200,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF9E9E9E).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
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
                      errorBuilder: (_,__,___) => Container(color: Colors.grey[200]),
                    )
                  : Container(color: _brandLight),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _brandColor,
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
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.1),
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
                    color: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: _products.isEmpty 
      ? SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: Text(
              'Bu kategoride ürün bulunamadı.',
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      )
      : SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65, // Increased height ratio (Height = width / 0.65) to fix overflow
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _products[index];
            return _buildCreativeGridCard(product);
          },
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildCreativeGridCard(dynamic product) {
    final imageUrl = _getImageUrl(product['imageUrl']);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Area
          Expanded(
            flex: 55, // 55% Image
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => Container(color: Colors.grey[100]),
                          )
                        : Container(color: Colors.grey[50], child: Icon(Icons.fastfood_rounded, color: Colors.grey[300], size: 40)),
                  ),
                ),
                Positioned(
                  bottom: 8, left: 8,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
                        ),
                        child: Text(
                          '₺${(product['price'] as num) - (product['discount'] ?? 0)}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: _brandColor, fontSize: 14),
                        ),
                      ),
                      if ((product['discount'] ?? 0) > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '₺${product['price']}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            decoration: TextDecoration.lineThrough,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if ((product['discount'] ?? 0) > 0)
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '%${product['price'] != 0 ? ((product['discount'] / product['price']) * 100).toInt() : 0} İNDİRİM',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Info Area
          Expanded(
            flex: 45, // 45% Text - More space
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start, // Start aligning to avoid space between issues
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF2D2D2D), height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  if (product['description'] != null && product['description'].isNotEmpty)
                    Expanded( // Use expanded to fill remaining space but respect limit
                      child: Text(
                        product['description'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                      ),
                    )
                  else
                    Spacer(), // Push content up if no desc
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFilterDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 140.0; // Adjusted for header + list

  @override
  double get minExtent => 140.0;

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) {
    return true; // Rebuild when styles change (selection)
  }
}
