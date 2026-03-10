import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/wishlist/wishlist_controller.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/home/presentation/cubit/home_state.dart';
import '../models/auto_trader_models.dart';
import '../config/app_config.dart';
import '../repositories/auto_trader_repository.dart';
import '../widgets/vehicle_card_tile.dart';
import 'auction_calculator_page.dart';
import 'auctions_page.dart';
import 'contact_page.dart';
import 'customs_calculator_page.dart';
import 'information_page.dart';
import 'search_page.dart';
import 'shipping_calculator_page.dart';
import 'text_search_page.dart';
import 'vehicle_details_page.dart';

const _dropdownMenuMaxHeight = 280.0;

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.showScaffold = true,
    this.initialData,
  });

  final bool showScaffold;
  final HomeBootstrapData? initialData;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HomeCubit(
            repository: context.read<AutoTraderRepository>(),
            initialData: initialData,
          )..load(),
      child: _HomeView(showScaffold: showScaffold),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView({required this.showScaffold});

  final bool showScaffold;

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistController>();

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final content = SafeArea(
          child: ColoredBox(
            color: const Color(0xFFF9FAFB),
            child: state.isLoading
                ? _HomeLoadingState(progress: state.loadingProgress)
                : state.errorMessage != null
                ? _ErrorState(
                    message: state.errorMessage!,
                    onRetry: context.read<HomeCubit>().load,
                  )
                : RefreshIndicator(
                    onRefresh: context.read<HomeCubit>().load,
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              const _HeroBanner(),
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _QuickSearchCard(state: state),
                                    const SizedBox(height: 16),
                                    const _BrandLogoCarouselSection(),
                                    const SizedBox(height: 26),
                                    _HomepageInventorySection(
                                      titleStart: 'Electric ',
                                      titleAccent: 'Vehicles',
                                      subtitle:
                                          'Discover the Future of Driving - Clean, Quiet, Powerful.',
                                      vehicles: state.electricFeatured
                                          .take(3)
                                          .toList(),
                                  onTap: (vehicle) =>
                                      _openDetails(context, vehicle),
                                      onToggleWishlist: _toggleWishlist,
                                      isWishlisted: wishlist.contains,
                                      onViewAll: () => _openSearch(
                                        const VehicleSearchFilters(
                                          fuel: LabeledOption(
                                            label: 'Electric',
                                            id: 'Electric',
                                          ),
                                        ),
                                      ),
                                      eyebrowBuilder: (vehicle) => _cardEyebrow(
                                        vehicle,
                                        preferBodyType: false,
                                      ),
                                      factsBuilder: _electricFacts,
                                      enableImageCarousel: true,
                                      autoPlayGallery: true,
                                      showImageNavigation: true,
                                      showImageIndicators: true,
                                    ),
                                    const SizedBox(height: 26),
                                    _HomepageInventorySection(
                                      titleStart: 'Vehicles in ',
                                      titleAccent: 'Azerbaijan',
                                      subtitle:
                                          'Browse vehicles in Azerbaijan, ready for you to drive home today.',
                                      vehicles: state.azerbaijanFeatured
                                          .take(3)
                                          .toList(),
                                  onTap: (vehicle) => _openDetails(
                                    context,
                                    vehicle,
                                    variant: VehicleDetailsVariant.azerbaijan,
                                  ),
                                      onToggleWishlist: _toggleWishlist,
                                      isWishlisted: wishlist.contains,
                                      onViewAll: () => _openSearch(
                                        const VehicleSearchFilters(
                                          country: LabeledOption(
                                            label: 'Azerbaijan',
                                            id: 'Azerbaijan',
                                          ),
                                        ),
                                      ),
                                      eyebrowBuilder: (vehicle) => _cardEyebrow(
                                        vehicle,
                                        preferBodyType: true,
                                      ),
                                      factsBuilder: _regionalFacts,
                                      enableImageCarousel: true,
                                      autoPlayGallery: true,
                                      showImageNavigation: true,
                                      showImageIndicators: true,
                                    ),
                                    const SizedBox(height: 36),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );

        if (!widget.showScaffold) {
          return content;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: content,
        );
      },
    );
  }

  void _toggleWishlist(BuildContext context, String vehicleId) {
    final added = context.read<WishlistController>().toggle(vehicleId);

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added ? 'Added to wishlist' : 'Removed from wishlist',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openInventory() {
    _openSearch(const VehicleSearchFilters());
  }

  void _openContact() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ContactPage()),
    );
  }

  void _openSearch(VehicleSearchFilters filters) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(initialFilters: filters),
      ),
    );
  }

  void _openActiveLots() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(
          initialFilters: const VehicleSearchFilters(
            country: auctionCountryOption,
          ),
          title: 'Active Lots',
        ),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _openImportCountrySearch(String selected) {
    _openSearch(
      VehicleSearchFilters(
        country: LabeledOption(label: selected, id: selected),
      ),
    );
  }

  void _handleHeaderMenuAction(String action) {
    switch (action) {
      case 'auction_active_lots':
        _openActiveLots();
        return;
      case 'auction_calculator':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AuctionCalculatorPage(),
          ),
        );
        return;
      case 'auction_customs_calculator':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CustomsCalculatorPage(),
          ),
        );
        return;
      case 'shipping_calculator':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ShippingCalculatorPage(),
          ),
        );
        return;
      case 'more_contact':
        _openContact();
        return;
      case 'more_information':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const InformationPage()));
        return;
    }
  }

  Future<void> _openSearchOverlay() async {
    final result = await showGeneralDialog<_SearchOverlayResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search inventory',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _HeaderSearchOverlay(animation: animation);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.query.trim().isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TextSearchPage(query: result.query.trim()),
        ),
      );
      return;
    }

    if (result.includeAuction && !result.includeOther) {
      _openSearch(
        const VehicleSearchFilters(country: auctionCountryOption),
      );
      return;
    }

    _openInventory();
  }

  void _openDetails(
    BuildContext context,
    VehicleSummary vehicle, {
    VehicleDetailsVariant variant = VehicleDetailsVariant.auction,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VehicleDetailsPage(
          vehicleId: vehicle.id,
          initialVehicle: vehicle,
          embedded: true,
          variant: variant,
        ),
      ),
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/brands/logo.png',
              height: 54,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              '$progress%',
              style: theme.textTheme.displaySmall?.copyWith(
                color: const Color(0xFFD21739),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Loading home inventory and filters...',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress == 0 ? null : progress / 100,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFD21739),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatefulWidget {
  const _HeroBanner();

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  static const _slides = [
    _HeroSlide(
      title: 'Choose from thousands of\nvehicles',
      subtitle:
          'Access a large selection of vehicles sourced from\nU.S. auctions, updated daily in one place.',
      leftAsset: 'assets/brands/1.webp',
      rightAsset: 'assets/brands/2.webp',
    ),
    _HeroSlide(
      title: 'See the price instantly, no phone\ncalls',
      subtitle:
          'Use the calculator to instantly calculate and\ncompare all costs up to delivery in Azerbaijan.',
      leftAsset: 'assets/brands/3.webp',
      rightAsset: 'assets/brands/4.webp',
    ),
    _HeroSlide(
      title: 'Safe shipping from the USA to\nAzerbaijan',
      subtitle:
          'Affordable shipping rates, insured delivery, and\noptional protective packaging services.',
      leftAsset: 'assets/brands/5.webp',
      rightAsset: 'assets/brands/6.webp',
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;
  int _pageIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageIndex = _slides.length * 100;
    _pageController = PageController(initialPage: _pageIndex);
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_pageController.hasClients) {
        return;
      }
      final nextPage = _pageIndex + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: const Color(0xFFD21D39),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      child: Stack(
        children: [
          Positioned(
            left: -70,
            top: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -50,
            top: 20,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            children: [
              Text(
                _slides[_currentPage].title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _slides[_currentPage].subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 170,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _pageIndex = page;
                      _currentPage = page % _slides.length;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index % _slides.length];
                    return Row(
                      children: [
                        Expanded(
                          child: Image.asset(
                            slide.leftAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Image.asset(
                            slide.rightAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSlide {
  const _HeroSlide({
    required this.title,
    required this.subtitle,
    required this.leftAsset,
    required this.rightAsset,
  });

  final String title;
  final String subtitle;
  final String leftAsset;
  final String rightAsset;
}

class _WebsiteTopSection extends StatefulWidget {
  const _WebsiteTopSection({
    required this.onHomeTap,
    required this.onElectricTap,
    required this.onMenuAction,
    required this.onImportCountrySelected,
    required this.onSearchTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onElectricTap;
  final ValueChanged<String> onMenuAction;
  final ValueChanged<String> onImportCountrySelected;
  final VoidCallback onSearchTap;

  @override
  State<_WebsiteTopSection> createState() => _WebsiteTopSectionState();
}

class _WebsiteTopSectionState extends State<_WebsiteTopSection> {
  String _language = 'EN';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
              onPressed: () => _showMenu(context),
              icon: const Icon(Icons.menu_rounded, size: 20),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) => _HomeMenuOverlay(
        onClose: () => Navigator.of(context).pop(),
        onHomeTap: widget.onHomeTap,
        onElectricTap: widget.onElectricTap,
        onMenuAction: widget.onMenuAction,
        onImportCountrySelected: widget.onImportCountrySelected,
        onSearchTap: widget.onSearchTap,
      ),
      transitionBuilder: (context, animation, _, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.02),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
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

class _HomeMenuOverlay extends StatefulWidget {
  const _HomeMenuOverlay({
    required this.onClose,
    required this.onHomeTap,
    required this.onElectricTap,
    required this.onMenuAction,
    required this.onImportCountrySelected,
    required this.onSearchTap,
  });

  final VoidCallback onClose;
  final VoidCallback onHomeTap;
  final VoidCallback onElectricTap;
  final ValueChanged<String> onMenuAction;
  final ValueChanged<String> onImportCountrySelected;
  final VoidCallback onSearchTap;

  @override
  State<_HomeMenuOverlay> createState() => _HomeMenuOverlayState();
}

class _HomeMenuOverlayState extends State<_HomeMenuOverlay> {
  bool _auctionOpen = false;
  bool _shippingOpen = false;
  bool _importOpen = false;
  bool _moreOpen = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/brands/logo.png', height: 28),
                      const Spacer(),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: const Color(0xFF2F353B),
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OverlayMenuItem(
                          label: 'Home',
                          onTap: () {
                            widget.onClose();
                            widget.onHomeTap();
                          },
                        ),
                        _OverlayMenuSection(
                          label: 'Auction',
                          isOpen: _auctionOpen,
                          onTap: () =>
                              setState(() => _auctionOpen = !_auctionOpen),
                          children: [
                            _OverlayMenuSubItem(
                              label: 'Active Lots',
                              onTap: () {
                                widget.onClose();
                                widget.onMenuAction('auction_active_lots');
                              },
                            ),
                            _OverlayMenuSubItem(
                              label: 'Calculator',
                              onTap: () {
                                widget.onClose();
                                widget.onMenuAction('auction_calculator');
                              },
                            ),
                            _OverlayMenuSubItem(
                              label: 'Customs Calculator',
                              onTap: () {
                                widget.onClose();
                                widget.onMenuAction(
                                  'auction_customs_calculator',
                                );
                              },
                            ),
                          ],
                        ),
                        _OverlayMenuSection(
                          label: 'Shipping',
                          isOpen: _shippingOpen,
                          onTap: () =>
                              setState(() => _shippingOpen = !_shippingOpen),
                          children: [
                            _OverlayMenuSubItem(
                              label: 'Shipping Calculator',
                              onTap: () {
                                widget.onClose();
                                widget.onMenuAction('shipping_calculator');
                              },
                            ),
                          ],
                        ),
                        _OverlayMenuItem(
                          label: 'Electric Vehicles',
                          onTap: () {
                            widget.onClose();
                            widget.onElectricTap();
                          },
                        ),
                        _OverlayMenuSection(
                          label: 'Import Auto',
                          isOpen: _importOpen,
                          onTap: () =>
                              setState(() => _importOpen = !_importOpen),
                          children: [
                            _OverlayMenuSubItem(
                              label: 'USA',
                              onTap: () {
                                widget.onClose();
                                widget.onImportCountrySelected('USA');
                              },
                            ),
                            _OverlayMenuSubItem(
                              label: 'Azerbaijan',
                              onTap: () {
                                widget.onClose();
                                widget.onImportCountrySelected('Azerbaijan');
                              },
                            ),
                            _OverlayMenuSubItem(
                              label: 'China',
                              onTap: () {
                                widget.onClose();
                                widget.onImportCountrySelected('China');
                              },
                            ),
                          ],
                        ),
                        _OverlayMenuSection(
                          label: 'More',
                          isOpen: _moreOpen,
                          onTap: () => setState(() => _moreOpen = !_moreOpen),
                          children: [
                            _OverlayMenuSubItem(
                              label: 'Contact',
                              onTap: () {
                                widget.onClose();
                                widget.onMenuAction('more_contact');
                              },
                            ),
                            _OverlayMenuSubItem(
                              label: 'Information',
                              onTap: () {
                                widget.onClose();
                                widget.onMenuAction('more_information');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayMenuSection extends StatelessWidget {
  const _OverlayMenuSection({
    required this.label,
    required this.isOpen,
    required this.onTap,
    required this.children,
  });

  final String label;
  final bool isOpen;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverlayMenuItem(
          label: label,
          trailing: Icon(
            isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: Colors.white70,
          ),
          onTap: onTap,
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              children: children,
            ),
          ),
      ],
    );
  }
}

class _OverlayMenuItem extends StatelessWidget {
  const _OverlayMenuItem({
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class _OverlayMenuSubItem extends StatelessWidget {
  const _OverlayMenuSubItem({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSearchOverlay extends StatefulWidget {
  const _HeaderSearchOverlay({required this.animation});

  final Animation<double> animation;

  @override
  State<_HeaderSearchOverlay> createState() => _HeaderSearchOverlayState();
}

class _HeaderSearchOverlayState extends State<_HeaderSearchOverlay> {
  late final TextEditingController _controller;
  bool _includeAuction = true;
  bool _includeOther = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOut,
    );

    return FadeTransition(
      opacity: fade,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(fade),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 40,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 760;
                        final searchField = Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF98A0B3),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                autofocus: true,
                                onSubmitted: (_) => _submit(),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                  filled: false,
                                  hintText:
                                      'Search by make, model, lot, or VIN',
                                ),
                              ),
                            ),
                          ],
                        );

                        final controls = Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _OverlayCheckbox(
                              label: 'Auction',
                              value: _includeAuction,
                              onChanged: (value) {
                                setState(() {
                                  _includeAuction = value;
                                  if (value) {
                                    _includeOther = false;
                                  }
                                });
                              },
                            ),
                            _OverlayCheckbox(
                              label: 'Other',
                              value: _includeOther,
                              onChanged: (value) {
                                setState(() {
                                  _includeOther = value;
                                  if (value) {
                                    _includeAuction = false;
                                  }
                                });
                              },
                            ),
                            FilledButton(
                              onPressed: _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE5E8F0),
                                foregroundColor: const Color(0xFF666D7C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              child: const Text('Search'),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        );

                        if (isCompact) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: searchField),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    _OverlayCheckbox(
                                      label: 'Auction',
                                      value: _includeAuction,
                                      onChanged: (value) {
                                        setState(() {
                                          _includeAuction = value;
                                          if (value) {
                                            _includeOther = false;
                                          }
                                        });
                                      },
                                    ),
                                    _OverlayCheckbox(
                                      label: 'Other',
                                      value: _includeOther,
                                      onChanged: (value) {
                                        setState(() {
                                          _includeOther = value;
                                          if (value) {
                                            _includeAuction = false;
                                          }
                                        });
                                      },
                                    ),
                                    FilledButton(
                                      onPressed: _submit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE5E8F0),
                                        foregroundColor:
                                            const Color(0xFF666D7C),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                      ),
                                      child: const Text('Search'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 12),
                            controls,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      _SearchOverlayResult(
        query: _controller.text,
        includeAuction: _includeAuction,
        includeOther: _includeOther,
      ),
    );
  }
}

class _OverlayCheckbox extends StatelessWidget {
  const _OverlayCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          activeColor: const Color(0xFFDF3040),
          onChanged: (nextValue) => onChanged(nextValue ?? false),
        ),
        Text(label),
      ],
    );
  }
}

class _SearchOverlayResult {
  const _SearchOverlayResult({
    required this.query,
    required this.includeAuction,
    required this.includeOther,
  });

  final String query;
  final bool includeAuction;
  final bool includeOther;
}

class _QuickSearchCard extends StatelessWidget {
  const _QuickSearchCard({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    final items = <Widget>[
      _OptionDropdown(
        title: 'All Makes',
        value: state.selectedMake,
        options: state.filterMetadata.makes,
        onChanged: cubit.selectMake,
      ),
      _OptionDropdown(
        title: 'All Models',
        value: state.selectedModel,
        options: state.availableModels,
        onChanged: cubit.selectModel,
      ),
      _YearDropdown(
        title: 'From Year',
        value: state.selectedFromYear,
        options: state.availableFromYears,
        onChanged: cubit.selectFromYear,
      ),
      _YearDropdown(
        title: 'To Year',
        value: state.selectedToYear,
        options: state.availableToYears,
        onChanged: cubit.selectToYear,
      ),
      _OptionDropdown(
        title: 'USA',
        value: state.selectedCountry,
        options: state.availableCountries,
        onChanged: cubit.selectCountry,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              const spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) /
                  columns;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final item in items)
                        SizedBox(width: itemWidth, child: item),
                      SizedBox(
                        width: itemWidth,
                        child: FilledButton.icon(
                          onPressed: state.isSubmittingQuickSearch
                              ? null
                              : () async {
                                  final filters =
                                      await cubit.submitQuickSearch();
                                  if (filters == null || !context.mounted) {
                                    return;
                                  }
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          SearchPage(initialFilters: filters),
                                    ),
                                  );
                                },
                          icon: state.isSubmittingQuickSearch
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Find Your Car'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD21D39),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.quickSearchError != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      state.quickSearchError!,
                      style: const TextStyle(
                        color: Color(0xFFB4232F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
  }
}

class _HomepageInventorySection extends StatelessWidget {
  const _HomepageInventorySection({
    required this.titleStart,
    required this.titleAccent,
    required this.subtitle,
    required this.vehicles,
    required this.onTap,
    required this.onToggleWishlist,
    required this.isWishlisted,
    required this.onViewAll,
    required this.eyebrowBuilder,
    required this.factsBuilder,
    required this.enableImageCarousel,
    required this.autoPlayGallery,
    required this.showImageNavigation,
    required this.showImageIndicators,
  });

  final String titleStart;
  final String titleAccent;
  final String subtitle;
  final List<VehicleSummary> vehicles;
  final ValueChanged<VehicleSummary> onTap;
  final void Function(BuildContext context, String vehicleId) onToggleWishlist;
  final bool Function(String) isWishlisted;
  final VoidCallback onViewAll;
  final String Function(VehicleSummary vehicle) eyebrowBuilder;
  final List<VehicleFact> Function(VehicleSummary vehicle) factsBuilder;
  final bool enableImageCarousel;
  final bool autoPlayGallery;
  final bool showImageNavigation;
  final bool showImageIndicators;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionAccent(),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: titleStart),
              TextSpan(
                text: titleAccent,
                style: const TextStyle(color: Color(0xFFDF3040)),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: const Color(0xFF202124),
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF30323A),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        if (vehicles.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Text('No vehicles available from this endpoint yet.'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1180
                  ? 3
                  : width >= 760
                  ? 2
                  : 1;
              final cards = vehicles.map((vehicle) {
                return VehicleCardTile(
                  vehicle: vehicle,
                  onTap: () => onTap(vehicle),
                  isWishlisted: isWishlisted(vehicle.id),
                  onToggleWishlist: () => onToggleWishlist(context, vehicle.id),
                  eyebrowLabel: eyebrowBuilder(vehicle),
                  facts: factsBuilder(vehicle),
                  enableImageCarousel: enableImageCarousel,
                  autoPlayGallery: autoPlayGallery,
                  showImageNavigation: showImageNavigation,
                  showImageIndicators: showImageIndicators,
                  cardRadius: 5,
                );
              }).toList();

              if (crossAxisCount == 1) {
                final cardWidth = width;
                final cardHeight = (cardWidth / 1.55) + 420;
                return SizedBox(
                  height: cardHeight,
                  child: PageView.builder(
                    itemCount: cards.length,
                    controller: PageController(viewportFraction: 1),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: cards[index],
                    ),
                  ),
                );
              }

              final aspectRatio = crossAxisCount == 3 ? 0.68 : 0.72;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 22,
                  crossAxisSpacing: 22,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) => cards[index],
              );
            },
          ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: onViewAll,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD21D39),
              foregroundColor: Colors.white,
              minimumSize: const Size(300, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('View Inventory'),
          ),
        ),
      ],
    );
  }
}

class _HelpRequestCard extends StatefulWidget {
  const _HelpRequestCard({required this.countries});

  final List<LabeledOption> countries;

  @override
  State<_HelpRequestCard> createState() => _HelpRequestCardState();
}

class _HelpRequestCardState extends State<_HelpRequestCard> {
  late final TextEditingController _nameController;
  String? _selectedCountryKey;
  bool _isVerified = false;
  String? _recaptchaToken;
  bool _hasName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_handleNameChanged)
      ..dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    final hasName = _nameController.text.trim().isNotEmpty;
    if (hasName == _hasName) {
      return;
    }
    setState(() {
      _hasName = hasName;
      if (_hasName && _selectedCountryKey == null) {
        _selectedCountryKey = _defaultCountryKey(widget.countries);
      }
    });
  }

  String? _defaultCountryKey(List<LabeledOption> countries) {
    if (countries.isEmpty) {
      return null;
    }
    final preferred = countries.firstWhere(
      (option) => option.label.toLowerCase() == 'azerbaijan',
      orElse: () => countries.firstWhere(
        (option) => option.label.toLowerCase() == 'usa',
        orElse: () => countries.first,
      ),
    );
    return _optionKey(preferred);
  }

  String? _resolveCountryKey(List<LabeledOption> countries) {
    if (countries.isEmpty) {
      return null;
    }
    if (!_hasName) {
      return null;
    }
    if (_selectedCountryKey != null &&
        countries.any((option) => _optionKey(option) == _selectedCountryKey)) {
      return _selectedCountryKey;
    }
    return _defaultCountryKey(countries);
  }

  String? _countryDialCode(String? label) {
    if (label == null || label.trim().isEmpty) {
      return null;
    }
    final normalized = label.trim().toLowerCase();
    const mapping = {
      'azerbaijan': '+994',
      'usa': '+1',
      'united states': '+1',
      'united states of america': '+1',
      'canada': '+1',
      'uk': '+44',
      'united kingdom': '+44',
      'turkey': '+90',
      'china': '+86',
      'germany': '+49',
      'france': '+33',
      'italy': '+39',
      'spain': '+34',
      'russia': '+7',
      'uae': '+971',
      'united arab emirates': '+971',
      'japan': '+81',
      'south korea': '+82',
      'korea': '+82',
      'india': '+91',
      'pakistan': '+92',
      'georgia': '+995',
      'armenia': '+374',
    };
    return mapping[normalized];
  }

  @override
  Widget build(BuildContext context) {
    final countries = widget.countries;
    final selectedKey = _resolveCountryKey(countries);
    final selectedCountry = selectedKey == null
        ? null
        : countries.cast<LabeledOption?>().firstWhere(
              (option) => _optionKey(option!) == selectedKey,
              orElse: () => null,
            );
    final dialCode = _countryDialCode(selectedCountry?.label);
    final canSubmit = _recaptchaToken != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDEE),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                'assets/brands/5.webp',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get Expert Help for Your Vehicle Purchase',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2B2F38),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your phone number, and our team will contact you.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4B5563),
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Your name',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: Color(0xFFD21D39)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(selectedKey),
              initialValue: selectedKey,
              items: countries
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: _optionKey(option),
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
              onChanged: _hasName
                  ? (value) {
                      setState(() {
                        _selectedCountryKey = value;
                      });
                    }
                  : null,
              decoration: InputDecoration(
                hintText: _hasName ? 'Country' : 'Enter your name first',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: Color(0xFFD21D39)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: dialCode == null ? null : '$dialCode ',
                hintText: '40 123 45 67',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: Color(0xFFD21D39)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _isVerified
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFE4E7F4),
                ),
              ),
              child: _RecaptchaBox(
                isVerified: _isVerified,
                onVerified: (token) {
                  setState(() {
                    _isVerified = true;
                    _recaptchaToken = token;
                  });
                },
                onExpired: () {
                  setState(() {
                    _isVerified = false;
                    _recaptchaToken = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canSubmit ? () {} : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD21D39),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Text('Request Callback'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecaptchaBox extends StatefulWidget {
  const _RecaptchaBox({
    required this.isVerified,
    required this.onVerified,
    required this.onExpired,
  });

  final bool isVerified;
  final ValueChanged<String> onVerified;
  final VoidCallback onExpired;

  @override
  State<_RecaptchaBox> createState() => _RecaptchaBoxState();
}

class _RecaptchaBoxState extends State<_RecaptchaBox> {
  late final WebViewController _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'Recaptcha',
        onMessageReceived: (message) {
          final payload = message.message.trim();
          if (payload == 'expired' || payload == 'error') {
            widget.onExpired();
            return;
          }
          if (payload.isNotEmpty) {
            widget.onVerified(payload);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoaded = true);
            }
          },
        ),
      )
      ..loadHtmlString(_recaptchaHtml(), baseUrl: 'https://autotrader.az');
  }

  String _recaptchaHtml() {
    final siteKey = AppConfig.recaptchaSiteKey;
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://www.google.com/recaptcha/api.js" async defer></script>
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background: transparent;
      }
      .wrapper {
        display: flex;
        align-items: center;
        justify-content: flex-start;
        min-height: 72px;
      }
    </style>
    <script>
      function onCaptchaVerified(token) {
        Recaptcha.postMessage(token);
      }
      function onCaptchaExpired() {
        Recaptcha.postMessage('expired');
      }
      function onCaptchaError() {
        Recaptcha.postMessage('error');
      }
    </script>
  </head>
  <body>
    <div class="wrapper">
      <div class="g-recaptcha"
        data-sitekey="$siteKey"
        data-callback="onCaptchaVerified"
        data-expired-callback="onCaptchaExpired"
        data-error-callback="onCaptchaError">
      </div>
    </div>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.recaptchaSiteKey.isEmpty) {
      return Text(
        'Add your reCAPTCHA site key in AppConfig.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 78,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: WebViewWidget(controller: _controller),
          ),
        ),
        if (!_isLoaded)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Loading reCAPTCHA...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
            ),
          ),
        if (widget.isVerified)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Verified',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}

class _SalvageInventorySection extends StatefulWidget {
  const _SalvageInventorySection({required this.makes});

  final List<LabeledOption> makes;

  @override
  State<_SalvageInventorySection> createState() =>
      _SalvageInventorySectionState();
}

class _SalvageInventorySectionState extends State<_SalvageInventorySection> {
  int _selectedIndex = 0;

  static const _tabs = [
    'Popular Makes',
    'Body Style',
    'Damage Type',
  ];

  @override
  Widget build(BuildContext context) {
    final items = _selectedIndex == 0
        ? widget.makes
            .map((make) => _MakeCount(make.label, make.count))
            .toList()
        : const <_MakeCount>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionAccent(),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'View Full Salvage '),
              TextSpan(
                text: 'Auto Auction\nInventory',
                style: const TextStyle(color: Color(0xFFDF3040)),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: List.generate(
            _tabs.length,
            (index) => ChoiceChip(
              label: Text(_tabs[index]),
              selected: _selectedIndex == index,
              onSelected: (selected) {
                if (!selected) {
                  return;
                }
                setState(() {
                  _selectedIndex = index;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: const BorderSide(color: Color(0xFFE4E7F4)),
              ),
              selectedColor: const Color(0xFFDF3040),
              labelStyle: TextStyle(
                color: _selectedIndex == index ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Text(
            _selectedIndex == 0
                ? 'Loading makes from inventory...'
                : 'More categories coming soon.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: columnWidth,
                        child: Text(
                          item.count == null
                              ? item.make
                              : '${item.make} (${item.count})',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

class _MakeCount {
  const _MakeCount(this.make, this.count);

  final String make;
  final int? count;
}

class _BrandLogoCarouselSection extends StatelessWidget {
  const _BrandLogoCarouselSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionAccent(),
        SizedBox(height: 10),
        _BrandLogoCarousel(),
      ],
    );
  }
}

class _SectionAccent extends StatelessWidget {
  const _SectionAccent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFFDF3040),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _BrandLogoCarousel extends StatefulWidget {
  const _BrandLogoCarousel();

  @override
  State<_BrandLogoCarousel> createState() => _BrandLogoCarouselState();
}

class _BrandLogoCarouselState extends State<_BrandLogoCarousel> {
  late final PageController _controller;
  int _currentPage = 0;

  static const _logos = [
    ('assets/brands/acura.png', 'Acura'),
    ('assets/brands/aston.png', 'Aston Martin'),
    ('assets/brands/bmw.png', 'BMW'),
    ('assets/brands/chevrolet.png', 'Chevrolet'),
    ('assets/brands/ferrari.png', 'Ferrari'),
    ('assets/brands/fiat.png', 'Fiat'),
    ('assets/brands/ford.png', 'Ford'),
    ('assets/brands/gmc.png', 'GMC'),
    ('assets/brands/hyundai.png', 'Hyundai'),
    ('assets/brands/kia.png', 'Kia'),
    ('assets/brands/lexus.png', 'Lexus'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemsPerPage = width >= 1400
            ? 6
            : width >= 1000
            ? 5
            : width >= 760
            ? 4
            : 3;
        final pages = <List<(String, String)>>[];
        for (var index = 0; index < _logos.length; index += itemsPerPage) {
          final end = (index + itemsPerPage) > _logos.length
              ? _logos.length
              : index + itemsPerPage;
          pages.add(_logos.sublist(index, end));
        }

        final clampedPage = _currentPage >= pages.length ? 0 : _currentPage;
        if (clampedPage != _currentPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _currentPage = clampedPage;
            });
          });
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFE4E7F4)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
            child: Column(
              children: [
                SizedBox(
                  height: width >= 600 ? 150 : 110,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      final pageItems = pages[pageIndex];
                      return Row(
                        children: pageItems
                            .map(
                              (item) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: _BrandLogoCard(
                                    assetPath: item.$1,
                                    alt: item.$2,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? const Color(0xFFDF3040)
                            : const Color(0xFFCCD2DD),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BrandLogoCard extends StatelessWidget {
  const _BrandLogoCard({
    required this.assetPath,
    required this.alt,
  });

  final String assetPath;
  final String alt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            alt,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5E5E5E),
                ),
          ),
        ],
      ),
    );
  }
}

class _AutoTraderFooter extends StatelessWidget {
  const _AutoTraderFooter({
    required this.onHomeTap,
    required this.onAuctionTap,
    required this.onShippingTap,
    required this.onElectricTap,
    required this.onImportTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onAuctionTap;
  final VoidCallback onShippingTap;
  final VoidCallback onElectricTap;
  final VoidCallback onImportTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
            child: Wrap(
              spacing: 40,
              runSpacing: 26,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'auto',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF121212),
                              ),
                            ),
                            TextSpan(
                              text: ' trader',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFDF3040),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Auto Trader LLC imports quality vehicles from the USA, Europe, and Asia, handling every step from purchase to shipping and customs.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF2F3137),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          _SocialButton(icon: Icons.camera_alt_outlined),
                          SizedBox(width: 10),
                          _SocialButton(icon: Icons.facebook_rounded),
                          SizedBox(width: 10),
                          _SocialButton(icon: Icons.play_arrow_rounded),
                          SizedBox(width: 10),
                          _SocialButton(icon: Icons.chat_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Useful Links',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FooterLink(label: 'Home', onTap: onHomeTap),
                      _FooterLink(label: 'Auction', onTap: onAuctionTap),
                      _FooterLink(label: 'Shipping', onTap: onShippingTap),
                      _FooterLink(
                        label: 'Electric Vehicles',
                        onTap: onElectricTap,
                      ),
                      _FooterLink(label: 'Import Auto', onTap: onImportTap),
                    ],
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Us',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _ContactRow(
                        icon: Icons.location_on,
                        text:
                            'Heydar Aliyev Ave 115, Sport Plaza Hotel & Apartments 187B',
                      ),
                      const SizedBox(height: 16),
                      const _ContactRow(
                        icon: Icons.schedule,
                        text: 'Monday-Friday, 09:00-18:00',
                      ),
                      const SizedBox(height: 16),
                      const _ContactRow(
                        icon: Icons.call,
                        text: '+994 (50) 555 34 85',
                      ),
                      const SizedBox(height: 16),
                      const _ContactRow(
                        icon: Icons.mail,
                        text: 'info@autotrader.az',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFDF3040),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: const Text(
              '2025 Auto Trader LLC. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFF9EA5BE),
      foregroundColor: Colors.white,
      child: Icon(icon, size: 18),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF2F3137),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.circle, size: 0),
        ),
        Icon(icon, size: 22, color: Colors.black87),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF2F3137),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final LabeledOption? value;
  final List<LabeledOption> options;
  final ValueChanged<LabeledOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedKey = _selectedKey(options, value);

    return DropdownButtonFormField<String>(
      key: ValueKey('$title-$selectedKey'),
      initialValue: selectedKey,
      isExpanded: true,
      menuMaxHeight: _dropdownMenuMaxHeight,
      decoration: InputDecoration(
        hintText: title,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFD21D39)),
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            title,
            style: const TextStyle(color: Color(0xFF8B90A7)),
          ),
        ),
        ...options.map(
          (option) => DropdownMenuItem<String>(
            value: _optionKey(option),
            child: Text(option.label),
          ),
        ),
      ],
      onChanged: (key) {
        if (key == null) {
          onChanged(null);
          return;
        }
        final selected = options
            .where((item) => _optionKey(item) == key)
            .firstOrNull;
        onChanged(selected);
      },
    );
  }
}

class _YearDropdown extends StatelessWidget {
  const _YearDropdown({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final int? value;
  final List<int> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = options.contains(value) ? value : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('$title-$selectedValue'),
      initialValue: selectedValue,
      isExpanded: true,
      menuMaxHeight: _dropdownMenuMaxHeight,
      decoration: InputDecoration(
        hintText: title,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFD21D39)),
        ),
      ),
      items: [
        DropdownMenuItem<int>(
          value: null,
          child: Text(
            title,
            style: const TextStyle(color: Color(0xFF8B90A7)),
          ),
        ),
        ...options.map(
          (year) => DropdownMenuItem<int>(value: year, child: Text('$year')),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_tethering_error_rounded, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _optionKey(LabeledOption option) {
  return option.id == null ? 'label:${option.label}' : 'id:${option.id}';
}

String? _selectedKey(List<LabeledOption> options, LabeledOption? value) {
  if (value == null) {
    return null;
  }
  final selected = options
      .where((item) => item.id == value.id || item.label == value.label)
      .firstOrNull;
  return selected == null ? null : _optionKey(selected);
}

String _cardEyebrow(VehicleSummary vehicle, {required bool preferBodyType}) {
  if (preferBodyType && vehicle.bodyType.trim().isNotEmpty) {
    return vehicle.bodyType.toUpperCase();
  }
  if (vehicle.make.trim().isNotEmpty) {
    return vehicle.make.toUpperCase();
  }
  if (vehicle.bodyType.trim().isNotEmpty) {
    return vehicle.bodyType.toUpperCase();
  }
  return vehicle.country.toUpperCase();
}

List<VehicleFact> _regionalFacts(VehicleSummary vehicle) {
  return [
    VehicleFact(
      icon: Icons.local_gas_station_outlined,
      label: 'Fuel Type',
      value: _firstValue(vehicle.fuel, vehicle.engineType, 'Unknown'),
    ),
    VehicleFact(
      icon: Icons.speed_outlined,
      label: 'Odometer',
      value: vehicle.odometer == null ? 'Unknown' : '${vehicle.odometer} km',
    ),
    VehicleFact(
      icon: Icons.directions_car_outlined,
      label: vehicle.engineType.trim().isNotEmpty ? 'Engine Type' : 'Drive Type',
      value: _firstValue(
        vehicle.engineType,
        vehicle.drive,
        vehicle.transmission,
        'Unknown',
      ),
    ),
  ];
}

List<VehicleFact> _electricFacts(VehicleSummary vehicle) {
  return [
    VehicleFact(
      icon: Icons.speed_outlined,
      label: 'Odometer',
      value: vehicle.odometer == null ? 'Unknown' : '${vehicle.odometer} km',
    ),
    VehicleFact(
      icon: Icons.bolt_outlined,
      label: 'Fuel Type',
      value: _firstValue(vehicle.fuel, vehicle.engineType, 'Electric'),
    ),
    VehicleFact(
      icon: Icons.settings_input_component_outlined,
      label: 'Transmission',
      value: _firstValue(
        vehicle.transmission,
        vehicle.drive,
        vehicle.batteryRange,
        'Automatic',
      ),
    ),
  ];
}

String _firstValue(
  String first,
  String second, [
  String third = '',
  String fallback = '',
]) {
  if (first.trim().isNotEmpty) {
    return first.trim();
  }
  if (second.trim().isNotEmpty) {
    return second.trim();
  }
  if (third.trim().isNotEmpty) {
    return third.trim();
  }
  return fallback;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
