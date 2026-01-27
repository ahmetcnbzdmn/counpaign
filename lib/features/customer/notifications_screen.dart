import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/swipe_back_detector.dart';
import '../../core/providers/language_provider.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Store only stateful data here (ID, read status)
  // Content will be derived from LanguageProvider
  List<Map<String, dynamic>> _notificationStates = [
    {'id': '1', 'key': 'welcome', 'time': '2h', 'isRead': true},
    {'id': '2', 'key': 'coffee', 'time': '1d', 'isRead': false},
    {'id': '3', 'key': 'points', 'time': '3d', 'isRead': true},
  ];

  void _deleteNotification(String id) {
    setState(() {
      _notificationStates.removeWhere((n) => n['id'] == id);
    });
  }

  void _clearAll() {
    setState(() {
      _notificationStates.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    const primaryBrand = Color(0xFFEE2C2C);
    
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          lang.translate('notifications'),
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_notificationStates.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                lang.translate('delete_all'),
                style: GoogleFonts.outfit(color: primaryBrand, fontWeight: FontWeight.w600),
              ),
            )
        ],
      ),
      body: _notificationStates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: textColor.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('no_notifications'),
                    style: GoogleFonts.outfit(color: textColor.withOpacity(0.5), fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated( // Removed padding to allow Dismissible background to touch edges
              padding: const EdgeInsets.symmetric(vertical: 10), 
              itemCount: _notificationStates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final state = _notificationStates[index];
                final id = state['id'];
                final keyPrefix = "notif_${state['key']}";
                final title = lang.translate("${keyPrefix}_title");
                final message = lang.translate("${keyPrefix}_msg");

                return Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteNotification(id),
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    color: const Color(0xFFFF4C4C), // Red delete color
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20), // Margin for card look
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: state['isRead'] 
                          ? null 
                          : Border.all(color: primaryBrand.withOpacity(0.3), width: 1),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryBrand.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: primaryBrand,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state['time'],
                            style: GoogleFonts.outfit(color: textColor.withOpacity(0.4), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
