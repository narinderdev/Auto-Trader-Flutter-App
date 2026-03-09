import 'package:flutter/material.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    const articles = [
      (
        '14 Jan 2026',
        '🔋',
        'How to evaluate battery health before buying an imported EV',
      ),
      (
        '08 Jan 2026',
        '🚗',
        'What vehicle grading reports actually mean for overseas buyers',
      ),
      (
        '02 Jan 2026',
        '🇨🇳',
        'Why Chinese EV supply is reshaping the Azerbaijan import market',
      ),
    ];

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          'Information',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        ...articles.map(
          (article) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 92, child: Text(article.$1)),
                const Text('-'),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Text(
                            article.$2,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              article.$3,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
      appBar: AppBar(title: const Text('Information')),
      body: SafeArea(child: content),
    );
  }
}
