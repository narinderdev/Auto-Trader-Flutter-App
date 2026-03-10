import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    const articles = [
      ('March 04, 2026', 'Test header'),
      ('March 02, 2026', '🚗 Hibird avtomobilleri: 2026-ci ilə qədər alaq, ya gözləyək'),
      ('February 27, 2026', 'Çindən necə yeni avtomobil idxal etmək olar'),
      ('February 26, 2026', '🪫 BYD necə Tesla-nı məğlub etdi? Çin elektrik avtomobillərinin yüksəlişi'),
    ];

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFDEDEE),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Information',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Home',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFD21D39),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(width: 6),
                  const Text('/'),
                  const SizedBox(width: 6),
                  Text(
                    'Information',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...articles.map(
          (article) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    article.$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9CA3AF),
                        ),
                  ),
                ),
                const Text('-'),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    article.$2,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.underline,
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(child: content),
    );
  }
}
