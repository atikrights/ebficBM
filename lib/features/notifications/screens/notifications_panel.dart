import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:bizos_x_pro/core/theme/colors.dart';
import 'package:bizos_x_pro/widgets/glass_container.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      width: 320,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          Expanded(child: _buildNotificationsList(context, isDark)),
          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
          const Icon(IconsaxPlusLinear.notification, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(BuildContext context, bool isDark) {
    final notifications = [
      {'title': 'Budget Limit Warning', 'desc': 'Project Alpha has reached 90% of budget.', 'type': 'warning', 'time': '2m ago'},
      {'title': 'New Feedback', 'desc': 'Client commented on Project Beta design.', 'type': 'info', 'time': '15m ago'},
      {'title': 'Deadline Impending', 'desc': 'ERP System build is due in 3 days.', 'type': 'error', 'time': '1h ago'},
      {'title': 'Payment Received', 'desc': '\$12,400 received from NextGen Solutions.', 'type': 'success', 'time': '3h ago'},
    ];

    return ListView.builder(
      itemCount: notifications.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final alert = notifications[index];
        final alertColor = _getAlertColor(alert['type']!);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 8, height: 40, decoration: BoxDecoration(color: alertColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert['title']!, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(alert['desc']!, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(alert['time']!, style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'warning': return AppColors.warning;
      case 'error': return AppColors.error;
      case 'success': return AppColors.success;
      default: return AppColors.info;
    }
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text('Mark All as Read', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
