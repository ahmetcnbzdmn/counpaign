import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/language_provider.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final data = await apiService.getUserNotifications();
      
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("Notification Fetch Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _fetchNotifications();
  }

  Future<void> _markAsRead(String notificationId, int index) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.markNotificationAsRead(notificationId);
      
      setState(() {
        _notifications[index]['isRead'] = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim okundu olarak işaretlendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Mark Read Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.deleteNotification(notificationId);
      
      setState(() {
        _notifications.removeAt(index);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim silindi'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silme işlemi başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      return "${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
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
        title: Text(
          lang.translate('notifications'),
          style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryBrand),
            onPressed: _fetchNotifications,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryBrand)) 
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 64, color: textColor.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        lang.translate('no_notifications'),
                        style: GoogleFonts.outfit(color: textColor.withValues(alpha: 0.5), fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: primaryBrand,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final notificationId = item['_id'] ?? '';
                      final title = item['title'] ?? 'Bildirim';
                      final body = item['body'] ?? '';
                      final time = _formatDate(item['createdAt']);
                      final isRead = item['isRead'] ?? false;

                      return Dismissible(
                        key: Key(notificationId),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            // Swipe left → Mark as read
                            if (!isRead) {
                              await _markAsRead(notificationId, index);
                            }
                            return false; // Don't remove, just mark as read
                          } else if (direction == DismissDirection.startToEnd) {
                            // Swipe right → Delete
                            await _deleteNotification(notificationId, index);
                            return false; // We handle removal manually
                          }
                          return false;
                        },
                        background: Container(
                          // Swipe right background (Delete - Red)
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 24),
                          child: Row(
                            children: [
                              const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Sil',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          // Swipe left background (Mark as read - Green)
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                isRead ? 'Okundu' : 'Okundu İşaretle',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                            ],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: isRead 
                                ? null 
                                : Border.all(color: primaryBrand.withValues(alpha: 0.3), width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isRead 
                                    ? Colors.grey.withValues(alpha: 0.1) 
                                    : primaryBrand.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isRead ? Icons.notifications_none_rounded : Icons.notifications_rounded,
                                color: isRead ? Colors.grey : primaryBrand,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              title,
                              style: GoogleFonts.outfit(
                                color: isRead ? textColor.withValues(alpha: 0.5) : textColor,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: TextStyle(
                                    color: isRead ? textColor.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.7), 
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      time,
                                      style: GoogleFonts.outfit(
                                        color: isRead ? textColor.withValues(alpha: 0.3) : textColor.withValues(alpha: 0.4), 
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (isRead) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.check_circle,
                                        size: 12,
                                        color: Colors.green.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Okundu',
                                        style: GoogleFonts.outfit(
                                          color: Colors.green.withValues(alpha: 0.6),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
