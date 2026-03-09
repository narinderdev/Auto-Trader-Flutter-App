import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/home/presentation/cubit/home_state.dart';
import '../models/auto_trader_models.dart';
import '../repositories/auto_trader_repository.dart';
import '../widgets/vehicle_card_tile.dart';
import 'about_page.dart';
import 'auctions_page.dart';
import 'coming_soon_page.dart';
import 'contact_page.dart';
import 'information_page.dart';
import 'login_page.dart';
import 'search_page.dart';
import 'text_search_page.dart';
import 'vehicle_details_page.dart';

const _dropdownMenuMaxHeight = 280.0;

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HomeCubit(repository: context.read<AutoTraderRepository>())..load(),
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
  final Set<String> _wishlistIds = <String>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final content = SafeArea(
          child: ColoredBox(
            color: const Color(0xFFF3F3F5),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _WebsiteTopSection(
                                  onHomeTap: _scrollToTop,
                                  onAuctionTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const AuctionsPage(),
                                    ),
                                  ),
                                  onShippingTap:
                                      () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const InformationPage(),
                                        ),
                                      ),
                                  onElectricTap: () => _openSearch(
                                    const VehicleSearchFilters(
                                      fuel: LabeledOption(
                                        label: 'Electric',
                                        id: 'Electric',
                                      ),
                                    ),
                                  ),
                                  onImportTap: _openCountryMenu,
                                  onMoreTap: _openMoreMenu,
                                  onSearchTap: _openSearchOverlay,
                                ),
                                const SizedBox(height: 12),
                                _HeroBanner(
                                  showcaseVehicles:
                                      state.homepageVehicles.take(2).toList(),
                                  onBrowseAll: _openInventory,
                                  onContactTap: _openContact,
                                ),
                                const SizedBox(height: 20),
                                _QuickSearchCard(state: state),
                                const SizedBox(height: 28),
                                const _BrandLogoCarouselSection(),
                                const SizedBox(height: 30),
                                _HomepageInventorySection(
                                  titleStart: 'Vehicles in ',
                                  titleAccent: 'Azerbaijan',
                                  subtitle:
                                      'Browse vehicles in Azerbaijan, ready for you to drive home today.',
                                  vehicles:
                                      state.azerbaijanFeatured.take(3).toList(),
                                  onTap: (vehicle) =>
                                      _openDetails(context, vehicle),
                                  onToggleWishlist: _toggleWishlist,
                                  isWishlisted: _wishlistIds.contains,
                                  onViewAll: () => _openSearch(
                                    const VehicleSearchFilters(
                                      country: LabeledOption(
                                        label: 'Azerbaijan',
                                        id: 'Azerbaijan',
                                      ),
                                    ),
                                  ),
                                  eyebrowBuilder: (vehicle) =>
                                      _cardEyebrow(vehicle, preferBodyType: true),
                                  factsBuilder: _regionalFacts,
                                  enableImageCarousel: false,
                                  autoPlayGallery: false,
                                  showImageNavigation: false,
                                  showImageIndicators: false,
                                ),
                                const SizedBox(height: 30),
                                _HomepageInventorySection(
                                  titleStart: 'Electric ',
                                  titleAccent: 'Vehicles',
                                  subtitle:
                                      'Discover the Future of Driving - Clean, Quiet, Powerful.',
                                  vehicles:
                                      state.electricFeatured.take(3).toList(),
                                  onTap: (vehicle) =>
                                      _openDetails(context, vehicle),
                                  onToggleWishlist: _toggleWishlist,
                                  isWishlisted: _wishlistIds.contains,
                                  onViewAll: () => _openSearch(
                                    const VehicleSearchFilters(
                                      fuel: LabeledOption(
                                        label: 'Electric',
                                        id: 'Electric',
                                      ),
                                    ),
                                  ),
                                  eyebrowBuilder: (vehicle) =>
                                      _cardEyebrow(vehicle, preferBodyType: false),
                                  factsBuilder: _electricFacts,
                                  enableImageCarousel: true,
                                  autoPlayGallery: true,
                                  showImageNavigation: true,
                                  showImageIndicators: true,
                                ),
                                const SizedBox(height: 36),
                                _AutoTraderFooter(
                                  onHomeTap: _scrollToTop,
                                  onAuctionTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const AuctionsPage(),
                                    ),
                                  ),
                                  onShippingTap:
                                      () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const InformationPage(),
                                        ),
                                      ),
                                  onElectricTap: () => _openSearch(
                                    const VehicleSearchFilters(
                                      fuel: LabeledOption(
                                        label: 'Electric',
                                        id: 'Electric',
                                      ),
                                    ),
                                  ),
                                  onImportTap: _openInventory,
                                ),
                              ],
                            ),
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
          backgroundColor: const Color(0xFFF3F3F5),
          body: content,
        );
      },
    );
  }

  void _toggleWishlist(String vehicleId) {
    setState(() {
      if (!_wishlistIds.remove(vehicleId)) {
        _wishlistIds.add(vehicleId);
      }
    });
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

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openCountryMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 108, 24, 0),
      items: const [
        PopupMenuItem<String>(value: 'USA', child: Text('USA')),
        PopupMenuItem<String>(value: 'Azerbaijan', child: Text('Azerbaijan')),
        PopupMenuItem<String>(value: 'China', child: Text('China')),
      ],
    );

    if (!mounted || selected == null) {
      return;
    }

    _openSearch(
      VehicleSearchFilters(
        country: LabeledOption(label: selected, id: selected),
      ),
    );
  }

  Future<void> _openMoreMenu() async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1120, 108, 24, 0),
      items: const [
        PopupMenuItem<String>(value: 'about', child: Text('About')),
        PopupMenuItem<String>(value: 'contact', child: Text('Contact')),
        PopupMenuItem<String>(value: 'login', child: Text('Login')),
        PopupMenuItem<String>(value: 'coming_soon', child: Text('Coming Soon')),
      ],
    );

    if (!mounted || selected == null) {
      return;
    }

    switch (selected) {
      case 'about':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AboutPage()));
      case 'contact':
        _openContact();
      case 'login':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const LoginPage()));
      case 'coming_soon':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ComingSoonPage()),
        );
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

  void _openDetails(BuildContext context, VehicleSummary vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            VehicleDetailsPage(vehicleId: vehicle.id, initialVehicle: vehicle),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.showcaseVehicles,
    required this.onBrowseAll,
    required this.onContactTap,
  });

  final List<VehicleSummary> showcaseVehicles;
  final VoidCallback onBrowseAll;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicles = showcaseVehicles.isEmpty
        ? const <VehicleSummary>[]
        : showcaseVehicles;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: const Color(0xFFD21739),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Positioned(
                  left: -70,
                  top: -10,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: -50,
                  top: 40,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'Choose from thousands of vehicles',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Access a large selection of vehicles sourced from U.S. auctions, updated daily in one place.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.96),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        _HeroArrowButton(icon: Icons.arrow_back_rounded),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _HeroVehicleShowcase(vehicles: vehicles),
                        ),
                        const SizedBox(width: 20),
                        _HeroArrowButton(icon: Icons.arrow_forward_rounded),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: onBrowseAll,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1C1613),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('View Full Inventory'),
                        ),
                        OutlinedButton(
                          onPressed: onContactTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: const Text('Contact Us'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WebsiteTopSection extends StatelessWidget {
  const _WebsiteTopSection({
    required this.onHomeTap,
    required this.onAuctionTap,
    required this.onShippingTap,
    required this.onElectricTap,
    required this.onImportTap,
    required this.onMoreTap,
    required this.onSearchTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onAuctionTap;
  final VoidCallback onShippingTap;
  final VoidCallback onElectricTap;
  final VoidCallback onImportTap;
  final VoidCallback onMoreTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F2F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 18,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 18,
                runSpacing: 8,
                children: const [
                  _TopInfoItem(
                    icon: Icons.call_outlined,
                    text: '994505553485',
                  ),
                  _TopInfoItem(
                    icon: Icons.mail_outline_rounded,
                    text: 'info@autotrader.az',
                  ),
                ],
              ),
              const Wrap(
                spacing: 10,
                children: [
                  _TopSocialButton(icon: Icons.camera_alt_outlined),
                  _TopSocialButton(icon: Icons.facebook_rounded),
                  _TopSocialButton(icon: Icons.play_arrow_rounded),
                  _TopSocialButton(icon: Icons.chat_bubble_outline_rounded),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE4E7F4)),
              bottom: BorderSide(color: Color(0xFFE4E7F4)),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 20,
            children: [
              const _AutoTraderWordmark(),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HeaderLink(label: 'Home', onTap: onHomeTap),
                  _HeaderLink(label: 'Auction', onTap: onAuctionTap),
                  _HeaderLink(label: 'Shipping', onTap: onShippingTap),
                  _HeaderLink(
                    label: 'Electric Vehicles',
                    onTap: onElectricTap,
                  ),
                  _HeaderDropdownLink(
                    label: 'Import Auto',
                    onTap: onImportTap,
                  ),
                  _HeaderDropdownLink(label: 'More', onTap: onMoreTap),
                ],
              ),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HeaderIconButton(
                    icon: Icons.search_rounded,
                    onTap: onSearchTap,
                  ),
                  const _HeaderIconButton(
                    icon: Icons.notifications_none_rounded,
                  ),
                  const _LanguageChip(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AutoTraderWordmark extends StatelessWidget {
  const _AutoTraderWordmark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brands/logo.png',
      height: 34,
      fit: BoxFit.contain,
    );
  }
}

class _TopInfoItem extends StatelessWidget {
  const _TopInfoItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2B3339)),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF2B3339),
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}

class _TopSocialButton extends StatelessWidget {
  const _TopSocialButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF8C92AC),
      foregroundColor: Colors.white,
      child: Icon(icon, size: 16),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2B3339),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
      ),
      child: Text(label),
    );
  }
}

class _HeaderDropdownLink extends StatelessWidget {
  const _HeaderDropdownLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2B3339),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
      ),
      iconAlignment: IconAlignment.end,
      label: Text(label),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: const Color(0xFF2B3339)),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E7F4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 18),
          SizedBox(width: 6),
          Text('EN'),
          SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ],
      ),
    );
  }
}

class _HeroVehicleShowcase extends StatelessWidget {
  const _HeroVehicleShowcase({required this.vehicles});

  final List<VehicleSummary> vehicles;

  @override
  Widget build(BuildContext context) {
    final leftVehicle = vehicles.isNotEmpty ? vehicles.first : null;
    final rightVehicle = vehicles.length > 1 ? vehicles[1] : null;

    return Row(
      children: [
        Expanded(child: _HeroVehicleCard(vehicle: leftVehicle, dark: true)),
        const SizedBox(width: 18),
        Expanded(child: _HeroVehicleCard(vehicle: rightVehicle, dark: false)),
      ],
    );
  }
}

class _HeroVehicleCard extends StatelessWidget {
  const _HeroVehicleCard({
    required this.vehicle,
    required this.dark,
  });

  final VehicleSummary? vehicle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark ? const Color(0xFF2B2D38) : const Color(0xFFF5F5F7);
    final imageUrl = vehicle?.image ?? '';

    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: background,
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: imageUrl.isEmpty
          ? Icon(
              Icons.directions_car_filled_rounded,
              size: 120,
              color: dark ? Colors.white70 : const Color(0xFF848A98),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.directions_car_filled_rounded,
                  size: 120,
                  color: dark ? Colors.white70 : const Color(0xFF848A98),
                ),
              ),
            ),
    );
  }
}

class _HeroArrowButton extends StatelessWidget {
  const _HeroArrowButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
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
                    borderRadius: BorderRadius.circular(26),
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
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 620,
                          child: Row(
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
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _includeAuction,
                              activeColor: const Color(0xFFDF3040),
                              onChanged: (value) {
                                setState(() {
                                  _includeAuction = value ?? false;
                                });
                              },
                            ),
                            const Text('Auction'),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _includeOther,
                              activeColor: const Color(0xFFDF3040),
                              onChanged: (value) {
                                setState(() {
                                  _includeOther = value ?? false;
                                });
                              },
                            ),
                            const Text('Other'),
                          ],
                        ),
                        FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE5E8F0),
                            foregroundColor: const Color(0xFF666D7C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Search'),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick search',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Make narrows model only. Country and year ranges stay global from the backend filters.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B6156)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _OptionDropdown(
                  title: 'Make',
                  value: state.selectedMake,
                  options: state.filterMetadata.makes,
                  onChanged: cubit.selectMake,
                ),
                _OptionDropdown(
                  title: 'Model',
                  value: state.selectedModel,
                  options: state.availableModels,
                  onChanged: cubit.selectModel,
                ),
                _OptionDropdown(
                  title: 'Country',
                  value: state.selectedCountry,
                  options: state.availableCountries,
                  onChanged: cubit.selectCountry,
                ),
                _YearDropdown(
                  title: 'From year',
                  value: state.selectedFromYear,
                  options: state.availableFromYears,
                  onChanged: cubit.selectFromYear,
                ),
                _YearDropdown(
                  title: 'To year',
                  value: state.selectedToYear,
                  options: state.availableToYears,
                  onChanged: cubit.selectToYear,
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: state.isSubmittingQuickSearch
                        ? null
                        : () async {
                            final filters = await cubit.submitQuickSearch();
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
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDF3040),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: state.isSubmittingQuickSearch
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Find cars'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: cubit.clearQuickSearch,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
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
  final ValueChanged<String> onToggleWishlist;
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
            height: 1.1,
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
          const Card(
            child: Padding(
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
                  onToggleWishlist: () => onToggleWishlist(vehicle.id),
                  eyebrowLabel: eyebrowBuilder(vehicle),
                  facts: factsBuilder(vehicle),
                  enableImageCarousel: enableImageCarousel,
                  autoPlayGallery: autoPlayGallery,
                  showImageNavigation: showImageNavigation,
                  showImageIndicators: showImageIndicators,
                );
              }).toList();

              if (crossAxisCount == 1) {
                return Column(
                  children: [
                    for (var index = 0; index < cards.length; index += 1) ...[
                      cards[index],
                      if (index < cards.length - 1)
                        const SizedBox(height: 22),
                    ],
                  ],
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
          child: FilledButton(
            onPressed: onViewAll,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDF3040),
              foregroundColor: Colors.white,
              minimumSize: const Size(300, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('View Full Inventory'),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B6156)),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _BrandLogoCarouselSection extends StatelessWidget {
  const _BrandLogoCarouselSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      title: 'Brands',
      subtitle: 'Static homepage logo carousel from the website design.',
      child: _BrandLogoCarousel(),
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
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
            child: Column(
              children: [
                SizedBox(
                  height: width >= 760 ? 220 : 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
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
                                        horizontal: 10,
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
                      Positioned(
                        left: 0,
                        child: _CarouselArrow(
                          icon: Icons.chevron_left_rounded,
                          onPressed: _currentPage > 0
                              ? () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOut,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: _CarouselArrow(
                          icon: Icons.chevron_right_rounded,
                          onPressed: _currentPage < pages.length - 1
                              ? () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOut,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
        borderRadius: BorderRadius.circular(8),
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

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: onPressed == null
            ? Colors.grey.shade400
            : Colors.grey.shade700,
      ),
      icon: Icon(icon, size: 42),
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
        borderRadius: BorderRadius.circular(22),
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

    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$title-$selectedKey'),
        initialValue: selectedKey,
        isExpanded: true,
        menuMaxHeight: _dropdownMenuMaxHeight,
        decoration: InputDecoration(labelText: title),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Any')),
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
      ),
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

    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<int>(
        key: ValueKey('$title-$selectedValue'),
        initialValue: selectedValue,
        isExpanded: true,
        menuMaxHeight: _dropdownMenuMaxHeight,
        decoration: InputDecoration(labelText: title),
        items: [
          const DropdownMenuItem<int>(value: null, child: Text('Any')),
          ...options.map(
            (year) => DropdownMenuItem<int>(value: year, child: Text('$year')),
          ),
        ],
        onChanged: onChanged,
      ),
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
