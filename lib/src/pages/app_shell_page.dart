import 'package:flutter/material.dart';

import '../repositories/auto_trader_repository.dart';
import 'coming_soon_page.dart';
import 'customs_calculator_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'search_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    this.initialHomeData,
  });

  final HomeBootstrapData? initialHomeData;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    HomePage(showScaffold: false, initialData: widget.initialHomeData),
    const CustomsCalculatorPage(),
    const SearchPage(showScaffold: false),
    const ComingSoonPage(),
    const LoginPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = _currentIndex >= _tabs.length ? 0 : _currentIndex;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: activeIndex, children: _tabs),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: activeIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onSearchTap: () {
          setState(() {
            _currentIndex = 2;
          });
        },
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onSearchTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    const inactiveColor = Color(0xFF8C92AC);
    const activeColor = Color(0xFFD21D39);

    return SizedBox(
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE4E7F4)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  label: 'HOME',
                  icon: Icons.home_outlined,
                  isActive: currentIndex == 0,
                  onTap: () => onTabSelected(0),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _NavItem(
                  label: 'CALCULATOR',
                  icon: Icons.calculate_outlined,
                  isActive: currentIndex == 1,
                  onTap: () => onTabSelected(1),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                const SizedBox(width: 56),
                _NavItem(
                  label: 'NOTIFICATION',
                  icon: Icons.notifications_none_rounded,
                  isActive: currentIndex == 3,
                  onTap: () => onTabSelected(3),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                _NavItem(
                  label: 'PROFILE',
                  icon: Icons.person_outline_rounded,
                  isActive: currentIndex == 4,
                  onTap: () => onTabSelected(4),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
