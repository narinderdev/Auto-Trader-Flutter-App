import 'package:flutter/material.dart';
import 'dart:async';

import '../repositories/auto_trader_repository.dart';
import 'customs_calculator_page.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
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
    const _CalculatorTabNavigator(),
    const _SearchTabNavigator(),
    const NotificationsPage(embedded: true),
    ProfilePage(
      embedded: true,
      onReturnHome: () {
        setState(() {
          _currentIndex = 0;
        });
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = _currentIndex >= _tabs.length ? 0 : _currentIndex;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _AppHeader(),
            Expanded(
              child: IndexedStack(index: activeIndex, children: _tabs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: activeIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onSearchTap: () => _showSearchOverlay(context),
      ),
    );
  }

  void _showSearchOverlay(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) => _SearchOverlay(
        onClose: () => Navigator.of(context).pop(),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }
}

class _CalculatorTabNavigator extends StatelessWidget {
  const _CalculatorTabNavigator();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (_) => const CustomsCalculatorPage(embedded: true),
          settings: settings,
        );
      },
    );
  }
}

class _SearchTabNavigator extends StatelessWidget {
  const _SearchTabNavigator();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (_) => const SearchPage(showScaffold: false),
          settings: settings,
        );
      },
    );
  }
}

class _AppHeader extends StatefulWidget {
  const _AppHeader();

  @override
  State<_AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<_AppHeader> {
  String _language = 'EN';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E7F4)),
        ),
      ),
      child: Row(
        children: [
          Image.asset('assets/brands/logo.png', height: 28),
          const Spacer(),
          Row(
            children: [
              Builder(
                builder: (context) => InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _showLanguageMenu(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Text(
                          _language,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE4E7F4)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.menu_rounded, size: 20),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (box == null) {
      return;
    }
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(const Offset(0, 0), ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      items: const [
        PopupMenuItem(value: 'AZ', child: Text('AZ')),
        PopupMenuItem(value: 'EN', child: Text('EN')),
      ],
    );
    if (selected != null && selected != _language) {
      setState(() {
        _language = selected;
      });
    }
  }
}

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final TextEditingController _queryController = TextEditingController();
  bool _auction = true;
  bool _other = false;
  String _queryText = '';
  bool _isLoading = false;
  List<_SearchSuggestion> _results = const [];
  Timer? _suggestionTimer;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _suggestionTimer?.cancel();
    _queryController.removeListener(_handleQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final next = _queryController.text;
    if (next == _queryText) {
      return;
    }
    setState(() {
      _queryText = next;
      _isLoading = next.trim().isNotEmpty;
      _results = const [];
    });

    _suggestionTimer?.cancel();
    if (next.trim().isEmpty) {
      return;
    }
    _suggestionTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) {
        return;
      }
      final normalized = next.trim().toLowerCase();
      final hasMatch = normalized.contains('harley') ||
          normalized.contains('1hd') ||
          normalized.contains('lot');
      setState(() {
        _isLoading = false;
        _results = hasMatch
            ? const [
                _SearchSuggestion(
                  title: '1HD1KH711RB634834',
                  subtitle: '2024 HARLEY-DAVIDSON\nFL',
                ),
                _SearchSuggestion(
                  title: 'Lot 66498035',
                  subtitle: '2024 HARLEY-DAVIDSON\nFL',
                ),
                _SearchSuggestion(
                  title: 'HARLEY-DAVIDSON',
                  subtitle: 'FL',
                ),
              ]
            : const [];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _queryText.trim().isNotEmpty;
    final suggestions = _results;

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                      Expanded(
                        child: TextField(
                          controller: _queryController,
                          decoration: const InputDecoration(
                            hintText: 'Search by make, model, lot, or VIN',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasQuery) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 240,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'Loading suggestions...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF6B7280),
                                      ),
                                ),
                              )
                            : suggestions.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'No results found',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF6B7280),
                                      ),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: suggestions
                                    .map(
                                      (item) => InkWell(
                                        onTap: () {
                                          _queryController.text = item.title;
                                          _queryController.selection =
                                              TextSelection.collapsed(
                                            offset: item.title.length,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            10,
                                            12,
                                            10,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF111827,
                                                      ),
                                                    ),
                                              ),
                                              if (item.subtitle.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.subtitle,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF6B7280,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _auction,
                        onChanged: (value) {
                          setState(() {
                            _auction = value ?? false;
                            if (_auction) {
                              _other = false;
                            }
                          });
                        },
                        activeColor: const Color(0xFFD21D39),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('Auction'),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _other,
                        onChanged: (value) {
                          setState(() {
                            _other = value ?? false;
                            if (_other) {
                              _auction = false;
                            }
                          });
                        },
                        activeColor: const Color(0xFFD21D39),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('Other'),
                      const Spacer(),
                      FilledButton(
                        onPressed: hasQuery ? widget.onClose : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: hasQuery
                              ? const Color(0xFFD21D39)
                              : const Color(0xFFE5E7EB),
                          foregroundColor: hasQuery
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Search'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _SearchSuggestion {
  const _SearchSuggestion({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
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
