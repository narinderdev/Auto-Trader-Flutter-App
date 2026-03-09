import 'package:flutter/material.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          'Contact',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 820;
            final cards = const [
              _ContactCard(
                icon: Icons.location_on_outlined,
                title: 'Our location',
                body: 'Baku, Azerbaijan\nAutoTrader customer service desk',
              ),
              _ContactCard(
                icon: Icons.mail_outline,
                title: 'Email address',
                body: 'info@autotrader.az',
              ),
              _ContactCard(
                icon: Icons.phone_outlined,
                title: 'Phone number',
                body: '+994 (50) 555 34 85',
              ),
            ];
            if (!wide) {
              return Column(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                    )
                    .toList(),
              );
            }
            return Row(
              children: cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow us',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Stay in touch through our main social channels and WhatsApp support.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _SocialCard(
                      label: 'Instagram',
                      value: '@autotraderazerbaijan',
                    ),
                    _SocialCard(
                      label: 'Facebook',
                      value: 'AutoTraderAzerbaijan',
                    ),
                    _SocialCard(
                      label: 'YouTube',
                      value: '@autotrader.azerbaijan',
                    ),
                    _SocialCard(label: 'WhatsApp', value: '+994505553485'),
                  ],
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
      appBar: AppBar(title: const Text('Contact')),
      body: SafeArea(child: content),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFB4232F),
              foregroundColor: Colors.white,
              radius: 24,
              child: Icon(icon),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
