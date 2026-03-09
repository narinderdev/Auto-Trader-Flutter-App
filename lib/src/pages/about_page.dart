import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: const [
        _HeroCard(
          title: 'About Autotrader Azerbaijan',
          body:
              'We are a locally operated team with direct representation in Japan, UAE, Europe, and the United States, specialising in sourcing trustworthy vehicles for the Caucasus and Central Asian markets.',
        ),
        SizedBox(height: 16),
        _InfoCard(
          title: 'Regional expertise',
          body:
              'Our consultants speak Azerbaijani, Russian, English, Turkish, and Japanese. They negotiate on your behalf, explain auction reports, and manage import documentation at every stage.',
        ),
        SizedBox(height: 16),
        _InfoCard(
          title: 'Inspection-first philosophy',
          body:
              'Every vehicle is inspected by certified mechanics before purchase. You receive graded condition reports, detailed photo galleries, and live video walkarounds when required.',
        ),
        SizedBox(height: 16),
        _InfoCard(
          title: 'Transparent costs',
          body:
              'Our pricing covers auction fees, inland transport, ocean freight, customs brokerage, and delivery to your door. There are no hidden charges and payments are milestone-based.',
        ),
      ],
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(child: content),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
