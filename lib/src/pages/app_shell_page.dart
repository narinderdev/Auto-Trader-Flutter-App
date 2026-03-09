import 'package:flutter/material.dart';

import '../models/auto_trader_models.dart';
import 'about_page.dart';
import 'admin_shell_page.dart';
import 'auctions_page.dart';
import 'coming_soon_page.dart';
import 'contact_page.dart';
import 'customs_calculator_page.dart';
import 'home_page.dart';
import 'information_page.dart';
import 'login_page.dart';
import 'search_page.dart';
import 'text_search_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    const HomePage(showScaffold: false),
    const SearchPage(showScaffold: false),
    const AuctionsPage(embedded: true),
    const InformationPage(embedded: true),
    const _MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _tabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.gavel_outlined),
            selectedIcon: Icon(Icons.gavel_rounded),
            label: 'Auctions',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: 'Info',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage();

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreEntry(
        title: 'About',
        subtitle: 'Company and sourcing model',
        icon: Icons.business_outlined,
        builder: () => const AboutPage(),
      ),
      _MoreEntry(
        title: 'Contact',
        subtitle: 'Office details and social channels',
        icon: Icons.contact_mail_outlined,
        builder: () => const ContactPage(),
      ),
      _MoreEntry(
        title: 'Customs Calculator',
        subtitle: 'Estimate landed import cost',
        icon: Icons.calculate_outlined,
        builder: () => const CustomsCalculatorPage(),
      ),
      _MoreEntry(
        title: 'Text Search',
        subtitle: 'Website free-text flow',
        icon: Icons.text_fields_rounded,
        builder: () => const TextSearchPage(query: 'electric suv'),
      ),
      _MoreEntry(
        title: 'Login',
        subtitle: 'Client login screen',
        icon: Icons.lock_outline_rounded,
        builder: () => const LoginPage(),
      ),
      _MoreEntry(
        title: 'Admin Panel',
        subtitle: 'Separate admin navigation shell',
        icon: Icons.admin_panel_settings_outlined,
        builder: () => const AdminShellPage(),
      ),
      _MoreEntry(
        title: 'Coming Soon',
        subtitle: 'Placeholder flow from website',
        icon: Icons.hourglass_bottom_rounded,
        builder: () => const ComingSoonPage(),
      ),
      _MoreEntry(
        title: 'Import from USA',
        subtitle: 'Country-filtered search shortcut',
        icon: Icons.flag_outlined,
        builder: () => SearchPage(
          initialFilters: const VehicleSearchFilters(
            country: LabeledOption(label: 'USA'),
          ),
        ),
      ),
      _MoreEntry(
        title: 'Import from Azerbaijan',
        subtitle: 'Country-filtered search shortcut',
        icon: Icons.public_outlined,
        builder: () => SearchPage(
          initialFilters: const VehicleSearchFilters(
            country: LabeledOption(label: 'Azerbaijan'),
          ),
        ),
      ),
      _MoreEntry(
        title: 'Import from China',
        subtitle: 'Country-filtered search shortcut',
        icon: Icons.electric_car_outlined,
        builder: () => SearchPage(
          initialFilters: const VehicleSearchFilters(
            country: LabeledOption(label: 'China'),
          ),
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          'More',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Public utility pages, shortcuts, and separate app sections.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFCE4E8),
                  foregroundColor: const Color(0xFFB4232F),
                  child: Icon(item.icon),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => item.builder()),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreEntry {
  const _MoreEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;
}
