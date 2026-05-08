import 'package:flutter/material.dart';

enum NoticePriority { low, medium, high, urgent }

class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime date;
  final NoticePriority priority;
  final IconData icon;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    this.priority = NoticePriority.medium,
    this.icon = Icons.notifications_active_rounded,
  });
}

final List<NoticeModel> dummyNotices = [
  NoticeModel(
    id: '1',
    title: 'New Headquarters Opening',
    content: 'We are excited to announce the opening of our new regional headquarters in the downtown business district. All staff are invited for the inauguration ceremony next Monday at 10:00 AM.',
    author: 'Admin Office',
    date: DateTime.now().subtract(const Duration(hours: 2)),
    priority: NoticePriority.high,
    icon: Icons.business_rounded,
  ),
  NoticeModel(
    id: '2',
    title: 'Salary & Bonus Update',
    content: 'The performance bonuses for the last quarter have been processed. Please check your personal dashboards for the breakdown. The amounts will reflect in your bank accounts by Friday.',
    author: 'HR Department',
    date: DateTime.now().subtract(const Duration(days: 1)),
    priority: NoticePriority.urgent,
    icon: Icons.account_balance_wallet_rounded,
  ),
  NoticeModel(
    id: '3',
    title: 'System Maintenance',
    content: 'The eBM system will undergo routine maintenance this Sunday starting from 12:00 AM for 4 hours. Access to project modules may be limited during this period.',
    author: 'IT Support',
    date: DateTime.now().subtract(const Duration(days: 3)),
    priority: NoticePriority.medium,
    icon: Icons.settings_suggest_rounded,
  ),
  NoticeModel(
    id: '4',
    title: 'Quarterly Review Meeting',
    content: 'The Q2 performance review meeting is scheduled for next Wednesday. Department heads are requested to prepare their presentations by Tuesday afternoon.',
    author: 'CEO Office',
    date: DateTime.now().subtract(const Duration(days: 5)),
    priority: NoticePriority.high,
    icon: Icons.groups_rounded,
  ),
];
