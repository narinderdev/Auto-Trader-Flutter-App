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
import 'vehicle_details_page.dart';

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

  void _openVehicleDetails(VehicleSummary vehicle) {
    setState(() {
      _currentIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _homeNavKey.currentState;
      if (navigator == null) {
        return;
      }
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => VehicleDetailsPage(
            vehicleId: vehicle.id,
            initialVehicle: vehicle,
            embedded: true,
          ),
        ),
      );
    });
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
        onOpenDetails: _openVehicleDetails,
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
  const _SearchOverlay({
    required this.onClose,
    required this.onSubmit,
    required this.onOpenDetails,
  });

  final VoidCallback onClose;
  final ValueChanged<VehicleSearchFilters> onSubmit;
  final ValueChanged<VehicleSummary> onOpenDetails;

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _suggestionsScrollController = ScrollController();
  bool _auction = true;
  bool _other = false;
  bool _isSubmitting = false;
  bool _showResultsModal = false;
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
    _suggestionsScrollController.dispose();
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
      _showResultsModal = next.trim().isNotEmpty;
    });

    _suggestionTimer?.cancel();
    if (next.trim().isEmpty) {
      setState(() {
        _showResultsModal = false;
        _isLoading = false;
        _results = const [];
      });
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
      final filters = VehicleSearchFilters(query: query);
      final response = await repository.searchVehicles(
        filters,
        page: 1,
        limit: 50,
      );
      if (!mounted || requestId != _requestId) {
        return;
      }
      final suggestions = <_SearchSuggestion>[];
      var generatedCount = 0;
      for (final vehicle in response.vehicles) {
        final items = _SearchSuggestion.fromVehicle(vehicle);
        generatedCount += items.length;
        for (final item in items) {
          suggestions.add(item);
          if (suggestions.length >= 8) {
            break;
          }
        }
        if (suggestions.length >= 8) {
          break;
        }
      }
      setState(() {
        _isLoading = false;
        if (suggestions.length > 8) {
          suggestions.removeRange(8, suggestions.length);
        }
        _results = suggestions;
      });
      debugPrint(
        'SearchOverlay suggestions: query="$query" '
        'api=${response.vehicles.length} '
        'generated=$generatedCount '
        'shown=${suggestions.length}',
      );
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
    if (_isSubmitting) {
      return;
    }
    final rawQuery = (overrideQuery ?? _queryText).trim();
    if (rawQuery.isEmpty) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _showResultsModal = false;
    });
    final filters = VehicleSearchFilters(query: rawQuery);
    widget.onSubmit(filters);
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _queryText.trim().isNotEmpty;
    final suggestions = _results;

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Align(
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 44,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _queryController,
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Search by make, model, lot, or VIN',
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
                              ),
                            ),
                          ),
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
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
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
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text('Other'),
                              const Spacer(),
                              FilledButton(
                                onPressed: (hasQuery && !_isSubmitting)
                                    ? _submitSearch
                                    : null,
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
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Search'),
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
                    ],
                  ),
                ),
              ),
            ),
            if (_showResultsModal)
              const Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: Colors.transparent,
                ),
              ),
            if (_showResultsModal)
              Positioned.fill(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 360,
                      minWidth: 260,
                      maxHeight:
                          MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Scrollbar(
                          controller: _suggestionsScrollController,
                          child: SingleChildScrollView(
                            controller: _suggestionsScrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Results',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _showResultsModal = false;
                                        });
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                if (_isLoading)
                                  const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 24),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                else if (suggestions.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 24),
                                      child: Text(
                                        'No results found',
                                        style: TextStyle(
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  for (final item in suggestions)
                                    Builder(
                                      builder: (context) {
                                        final isPrimary =
                                            item.type ==
                                                    _SearchSuggestionType.vin ||
                                                item.type ==
                                                    _SearchSuggestionType.lot;
                                        return InkWell(
                                          onTap: () {
                                            _suggestionTimer?.cancel();
                                            if (_isSubmitting) {
                                              return;
                                            }
                                            widget.onClose();
                                            _queryController.text = item.query;
                                            _queryController.selection =
                                                TextSelection.collapsed(
                                              offset: item.query.length,
                                            );
                                            setState(() {
                                              _queryText = item.query;
                                              _results = const [];
                                              _isLoading = false;
                                              _showResultsModal = false;
                                            });
                                            widget.onOpenDetails(
                                              item.vehicle,
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 4,
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
                                                        fontWeight: isPrimary
                                                            ? FontWeight.w600
                                                            : FontWeight.w500,
                                                        fontSize: isPrimary
                                                            ? 14
                                                            : 13,
                                                        color: const Color(
                                                          0xFF111827,
                                                        ),
                                                      ),
                                                ),
                                                if (isPrimary &&
                                                    item.subtitle.isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 2,
                                                    ),
                                                    child: Text(
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
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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

enum _SearchSuggestionType { vin, lot, make, model }

class _SearchSuggestion {
  const _SearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.query,
    required this.type,
    required this.vehicle,
  });

  final String title;
  final String subtitle;
  final String query;
  final _SearchSuggestionType type;
  final VehicleSummary vehicle;

  static List<_SearchSuggestion> fromVehicle(VehicleSummary vehicle) {
    String cleanText(String value) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) {
        return '';
      }
      final upper = cleaned.toUpperCase();
      if (upper == 'N/A' ||
          upper == 'NA' ||
          upper == 'NULL' ||
          upper == 'NONE' ||
          cleaned == '0' ||
          cleaned == '-') {
        return '';
      }
      return cleaned;
    }

    final subtitleParts = <String>[
      if (vehicle.year != null) vehicle.year.toString(),
      vehicle.make.trim(),
      vehicle.model.trim(),
    ].where((value) => value.isNotEmpty).toList();
    final subtitle =
        subtitleParts.isNotEmpty ? subtitleParts.join(' ').toUpperCase() : '';
    final vin = cleanText(vehicle.vin);
    final lot = cleanText(vehicle.lotNumber);
    final rawMake = vehicle.make.trim();
    final rawModel = vehicle.model.trim();
    var make = cleanText(rawMake);
    var model = cleanText(rawModel);
    if (make.isEmpty || model.isEmpty) {
      final title = vehicle.title.trim();
      if (title.isNotEmpty) {
        final parts = title.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
        var start = 0;
        if (parts.isNotEmpty && RegExp(r'^\d{4}$').hasMatch(parts[0])) {
          start = 1;
        }
        if (make.isEmpty && parts.length > start) {
          make = cleanText(parts[start]);
        }
        if (model.isEmpty && parts.length > start + 1) {
          model = cleanText(parts.sublist(start + 1).join(' '));
        }
      }
    }

    final suggestions = <_SearchSuggestion>[];
    void addSuggestion(
      String title,
      String query, {
      String? subtitleText,
      required _SearchSuggestionType type,
    }) {
      if (title.isEmpty || query.isEmpty) {
        return;
      }
      suggestions.add(
        _SearchSuggestion(
          title: title,
          subtitle: subtitleText ?? '',
          query: query,
          type: type,
          vehicle: vehicle,
        ),
      );
    }

    if (vin.isNotEmpty) {
      addSuggestion(
        vin,
        vin,
        subtitleText: subtitle,
        type: _SearchSuggestionType.vin,
      );
    }
    if (lot.isNotEmpty) {
      addSuggestion(
        'Lot $lot',
        lot,
        subtitleText: subtitle,
        type: _SearchSuggestionType.lot,
      );
    }
    if (make.isNotEmpty) {
      addSuggestion(
        make.toUpperCase(),
        make,
        type: _SearchSuggestionType.make,
      );
    }
    if (model.isNotEmpty) {
      addSuggestion(
        model.toUpperCase(),
        model,
        type: _SearchSuggestionType.model,
      );
    }

    return suggestions;
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
