import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/auto_trader_models.dart';
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
  final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>();
  VehicleSearchFilters _searchFilters = const VehicleSearchFilters();
  int _searchSeed = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();
    final activeIndex = _currentIndex >= tabs.length ? 0 : _currentIndex;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _AppHeader(),
            Expanded(
              child: IndexedStack(index: activeIndex, children: tabs),
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
          if (index == 0) {
            _homeNavKey.currentState?.popUntil((route) => route.isFirst);
          }
        },
        onSearchTap: () => _showSearchOverlay(context),
      ),
    );
  }

  List<Widget> _buildTabs() {
    return [
      _HomeTabNavigator(
        initialHomeData: widget.initialHomeData,
        navigatorKey: _homeNavKey,
      ),
      const _CalculatorTabNavigator(),
      _SearchTabNavigator(
        key: ValueKey('search-tab-$_searchSeed'),
        initialFilters: _searchFilters,
      ),
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
        onSubmit: (filters) {
          Navigator.of(context).pop();
          setState(() {
            _searchFilters = filters;
            _searchSeed += 1;
            _currentIndex = 2;
          });
        },
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

class _HomeTabNavigator extends StatelessWidget {
  const _HomeTabNavigator({
    required this.initialHomeData,
    required this.navigatorKey,
  });

  final HomeBootstrapData? initialHomeData;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (_) => HomePage(
            showScaffold: false,
            initialData: initialHomeData,
          ),
          settings: settings,
        );
      },
    );
  }
}

class _SearchTabNavigator extends StatelessWidget {
  const _SearchTabNavigator({super.key, required this.initialFilters});

  final VehicleSearchFilters initialFilters;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: (_) => SearchPage(
            showScaffold: false,
            initialFilters: initialFilters,
          ),
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
          Image.asset('assets/brands/logo.png', height: 58),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      constraints: const BoxConstraints(minWidth: 0),
      items: [
        PopupMenuItem(
          value: 'AZ',
          padding: EdgeInsets.zero,
          height: 32,
          child: _LanguageMenuItem(
            label: 'AZ',
            isSelected: _language == 'AZ',
          ),
        ),
        PopupMenuItem(
          value: 'EN',
          padding: EdgeInsets.zero,
          height: 32,
          child: _LanguageMenuItem(
            label: 'EN',
            isSelected: _language == 'EN',
          ),
        ),
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
  const _SearchOverlay({required this.onClose, required this.onSubmit});

  final VoidCallback onClose;
  final ValueChanged<VehicleSearchFilters> onSubmit;

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
  int _requestId = 0;

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
      _loadSuggestions(next.trim());
    });
  }

  Future<void> _loadSuggestions(String query) async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _results = const [];
    });

    try {
      final repository = context.read<AutoTraderRepository>();
      final filters = VehicleSearchFilters(
        query: query,
        country: _auction ? auctionCountryOption : null,
      );
      final response = await repository.searchVehicles(
        filters,
        page: 1,
        limit: 5,
      );
      if (!mounted || requestId != _requestId) {
        return;
      }
      final suggestions = response.vehicles.map(_SearchSuggestion.fromVehicle);
      setState(() {
        _isLoading = false;
        _results = suggestions.toList();
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _isLoading = false;
        _results = const [];
      });
    }
  }

  void _submitSearch({String? overrideQuery}) {
    final rawQuery = (overrideQuery ?? _queryText).trim();
    if (rawQuery.isEmpty) {
      return;
    }
    final filters = VehicleSearchFilters(
      query: rawQuery,
      country: _auction ? auctionCountryOption : null,
    );
    widget.onSubmit(filters);
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
                          onSubmitted: (_) => _submitSearch(),
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
                                          _queryController.text = item.query;
                                          _queryController.selection =
                                              TextSelection.collapsed(
                                            offset: item.query.length,
                                          );
                                          _submitSearch(
                                            overrideQuery: item.query,
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
                          if (_queryText.trim().isNotEmpty) {
                            _loadSuggestions(_queryText.trim());
                          }
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
                          if (_queryText.trim().isNotEmpty) {
                            _loadSuggestions(_queryText.trim());
                          }
                        },
                        activeColor: const Color(0xFFD21D39),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('Other'),
                      const Spacer(),
                      FilledButton(
                        onPressed: hasQuery ? _submitSearch : null,
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
  const _SearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.query,
  });

  final String title;
  final String subtitle;
  final String query;

  factory _SearchSuggestion.fromVehicle(VehicleSummary vehicle) {
    final vin = vehicle.vin.trim();
    final lot = vehicle.lotNumber.trim();
    final title =
        vin.isNotEmpty ? vin : (lot.isNotEmpty ? 'Lot $lot' : vehicle.title);
    final subtitleParts = <String>[
      if (vehicle.year != null) vehicle.year.toString(),
      vehicle.make.trim(),
      vehicle.model.trim(),
    ].where((value) => value.isNotEmpty).toList();
    final subtitle =
        subtitleParts.isNotEmpty ? subtitleParts.join(' ') : vehicle.title;
    final query = vin.isNotEmpty ? vin : (lot.isNotEmpty ? lot : vehicle.title);
    return _SearchSuggestion(title: title, subtitle: subtitle, query: query);
  }
}
class _LanguageMenuItem extends StatelessWidget {
  const _LanguageMenuItem({
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
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
