import 'package:flutter/material.dart';

import 'search_page.dart';

class TextSearchPage extends StatelessWidget {
  const TextSearchPage({super.key, this.query = ''});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Search')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Text search',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        query.isNotEmpty
                            ? 'You searched for "$query". Continue with advanced filters to refine the inventory.'
                            : 'No free-text query was provided. Use advanced filters to browse the inventory.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SearchPage(),
                            ),
                          );
                        },
                        child: const Text('Open advanced search'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
