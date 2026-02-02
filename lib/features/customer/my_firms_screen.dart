import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/business_provider.dart';
import '../../core/widgets/swipe_back_detector.dart';
import '../../core/providers/participation_provider.dart';
import '../../core/providers/campaign_provider.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/providers/language_provider.dart';

class MyFirmsScreen extends StatefulWidget {
  const MyFirmsScreen({super.key});

  @override
  State<MyFirmsScreen> createState() => _MyFirmsScreenState();
}

class _MyFirmsScreenState extends State<MyFirmsScreen> {

  @override
  void initState() {
    super.initState();
    // Fetch via provider on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessProvider>().fetchMyFirms();
    });
  }

  Future<void> _saveOrder(List<dynamic> firms) async {
    try {
      final api = context.read<ApiService>();
      final orderedIds = firms.map((f) => f['id'].toString()).toList();
      await api.reorderWallet(orderedIds);
    } catch (e) {
      showCustomPopup(
        context,
        message: '${Provider.of<LanguageProvider>(context, listen: false).translate('error_reorder')}: $e',
        type: PopupType.error,
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    // Update Provider State for instant reflection in Home
    context.read<BusinessProvider>().reorderFirms(oldIndex, newIndex);
    
    // Get new list to save
    final newOrder = context.read<BusinessProvider>().myFirms;
    _saveOrder(newOrder); 
  }

  String _formatAddress(dynamic business) {
    final city = business['city'] ?? '';
    final district = business['district'] ?? '';
    final neighborhood = business['neighborhood'] ?? '';
    
    List<String> parts = [];
    if (neighborhood != null && neighborhood.toString().isNotEmpty) parts.add(neighborhood.toString());
    if (district != null && district.toString().isNotEmpty) parts.add(district.toString());
    if (city != null && city.toString().isNotEmpty) parts.add(city.toString());
    
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    final provider = context.watch<BusinessProvider>();
    final firms = provider.myFirms;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(Provider.of<LanguageProvider>(context).translate('my_firms_title'), style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        centerTitle: true,
      ),
      body: provider.isLoading && firms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: firms.length,
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (BuildContext context, Widget? child) {
                    return Material(
                      elevation: 8,
                      color: Colors.transparent, // Important for custom shapes
                      shadowColor: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final firm = firms[index];
                
                final colorHex = firm['cardColor'] ?? '#333333';
                final color = Color(int.parse(colorHex.replaceAll('#', '0xFF')));
                final iconName = firm['cardIcon'] ?? 'storefront';
                    
                IconData iconData = Icons.storefront;
                if (iconName == 'local_cafe_rounded') iconData = Icons.local_cafe_rounded;
                else if (iconName == 'coffee_rounded') iconData = Icons.coffee_rounded;
                else if (iconName == 'lunch_dining_rounded') iconData = Icons.lunch_dining_rounded;
                else if (iconName == 'checkroom_rounded') iconData = Icons.checkroom_rounded;

                return Dismissible(
                  key: ValueKey(firm['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    // 1. Show Confirmation Dialog (Styled)
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          Provider.of<LanguageProvider>(context, listen: false).translate('delete_firm_title'), 
                          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)
                        ),
                        content: Text(
                          Provider.of<LanguageProvider>(context, listen: false).translate('delete_firm_content'),
                          style: GoogleFonts.outfit(color: textColor.withOpacity(0.8), fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('cancel'), style: GoogleFonts.outfit(color: textColor.withOpacity(0.6))),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('yes_delete'), style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return false;

                    // 2. Show Password Dialog (Styled & Stateful for Error Handling)
                    final passwordController = TextEditingController();
                    
                    // We need a variable to store the result of the dialog interaction (true if deleted)
                    final bool? deleted = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        // Define state variables OUTSIDE the StatefulBuilder so they persist
                        bool isLoading = false;
                        String? errorText;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              backgroundColor: cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text(
                                Provider.of<LanguageProvider>(context, listen: false).translate('security_verification'), 
                                style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Provider.of<LanguageProvider>(context, listen: false).translate('enter_password_msg'),
                                    style: GoogleFonts.outfit(color: textColor.withOpacity(0.8)),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: true,
                                    style: GoogleFonts.outfit(color: textColor),
                                    decoration: InputDecoration(
                                      hintText: Provider.of<LanguageProvider>(context, listen: false).translate('your_password'),
                                      hintStyle: GoogleFonts.outfit(color: textColor.withOpacity(0.5)),
                                      filled: true,
                                      fillColor: bgColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      errorText: errorText,
                                      errorStyle: GoogleFonts.outfit(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                                  child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('cancel'), style: GoogleFonts.outfit(color: textColor.withOpacity(0.6))),
                                ),
                                isLoading 
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    child: SizedBox(
                                      width: 20, height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)
                                    ),
                                  )
                                : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      isLoading = true;
                                      errorText = null;
                                    });

                                    try {
                                      await context.read<BusinessProvider>().removeFirm(
                                        firm['id'], 
                                        passwordController.text
                                      );
                                      
                                      // [FIX] Instant Refresh State
                                      if (context.mounted) {
                                         // 1. Refresh global participations to clear 'Joined' status
                                         // Need to import providers first
                                         context.read<ParticipationProvider>().fetchMyParticipations();
                                         
                                         // 2. Refresh global campaigns (optional but good practice)
                                         context.read<CampaignProvider>().fetchAllCampaigns();
                                         
                                         // 3. Close dialog
                                         Navigator.of(context).pop(true);
                                      }
                                    } catch (e) {
                                      // Handle error inside the dialog
                                      setState(() {
                                        isLoading = false;
                                        if (e.toString().contains('401') || e.toString().contains('Şifre hatalı')) {
                                          errorText = Provider.of<LanguageProvider>(context, listen: false).translate('wrong_password');
                                        } else {
                                          errorText = Provider.of<LanguageProvider>(context, listen: false).translate('error');
                                        }
                                      });
                                    }
                                  },
                                  child: Text(Provider.of<LanguageProvider>(context, listen: false).translate('confirm'), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            );
                          }
                        );
                      },
                    );

                    if (deleted == true) {
                      showCustomPopup(
                        context,
                        message: Provider.of<LanguageProvider>(context, listen: false).translate('firm_deleted_success'),
                        type: PopupType.success,
                      );
                      return true; // Item dismissed
                    } 
                    
                    return false; // Not dismissed
                  },
                  onDismissed: (direction) {
                    // Handled by confirmDismiss logic mostly, but provider update happens there
                  },
                  child: Card(
                    key: ValueKey(firm['id']), // Key is required for ReorderableListView
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(iconData, color: color),
                      ),
                      title: Text(
                        firm['companyName'] ?? '',
                        style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${firm['category'] ?? Provider.of<LanguageProvider>(context).translate('general')}${_formatAddress(firm).isNotEmpty ? ' • ${_formatAddress(firm)}' : ''}",
                        style: GoogleFonts.outfit(color: textColor.withOpacity(0.7)),
                      ),
                      trailing: Icon(Icons.drag_handle_rounded, color: textColor.withOpacity(0.3)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
