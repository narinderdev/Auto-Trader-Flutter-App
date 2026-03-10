import 'dart:async';

import 'package:flutter/material.dart';

import '../models/auto_trader_models.dart';
import '../utils/formatters.dart';

class VehicleCardTile extends StatefulWidget {
  const VehicleCardTile({
    super.key,
    required this.vehicle,
    required this.onTap,
    this.isWishlisted = false,
    this.onToggleWishlist,
    this.eyebrowLabel,
    this.badgeLabel = 'Pre-order',
    this.ctaLabel = 'View Details',
    this.facts,
    this.enableImageCarousel = false,
    this.autoPlayGallery = false,
    this.showImageNavigation = false,
    this.showImageIndicators = false,
    this.cardRadius = 5,
  });

  final VehicleSummary vehicle;
  final VoidCallback onTap;
  final bool isWishlisted;
  final VoidCallback? onToggleWishlist;
  final String? eyebrowLabel;
  final String badgeLabel;
  final String ctaLabel;
  final List<VehicleFact>? facts;
  final bool enableImageCarousel;
  final bool autoPlayGallery;
  final bool showImageNavigation;
  final bool showImageIndicators;
  final double cardRadius;

  @override
  State<VehicleCardTile> createState() => _VehicleCardTileState();
}

class _VehicleCardTileState extends State<VehicleCardTile> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentImageIndex = 0;
  int _pageIndex = 0;

  List<String> get _images {
    final gallery = widget.vehicle.gallery;
    if (gallery.isNotEmpty) {
      return gallery;
    }
    if (widget.vehicle.image.isNotEmpty) {
      return [widget.vehicle.image];
    }
    return const <String>[];
  }

  bool get _canSlide =>
      widget.enableImageCarousel && _images.length > 1;

  @override
  void initState() {
    super.initState();
    final initialLength = _images.length;
    _pageIndex = initialLength == 0 ? 0 : initialLength * 100;
    _pageController = PageController(initialPage: _pageIndex);
    _configureTimer();
  }

  @override
  void didUpdateWidget(covariant VehicleCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.id != widget.vehicle.id ||
        oldWidget.vehicle.gallery.length != widget.vehicle.gallery.length ||
        oldWidget.autoPlayGallery != widget.autoPlayGallery ||
        oldWidget.enableImageCarousel != widget.enableImageCarousel) {
      _currentImageIndex = 0;
      final resetLength = _images.length;
      _pageIndex = resetLength == 0 ? 0 : resetLength * 100;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_pageIndex);
      }
      _configureTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _configureTimer() {
    _timer?.cancel();
    if (!_canSlide || !widget.autoPlayGallery) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        return;
      }
      _goToPage(_pageIndex + 1);
    });
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _previousImage() {
    if (!_canSlide) {
      return;
    }
    final nextIndex = _pageIndex - 1;
    if (nextIndex < 0) {
      return;
    }
    _goToPage(nextIndex);
  }

  void _nextImage() {
    if (!_canSlide) {
      return;
    }
    _goToPage(_pageIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedFacts = widget.facts ?? _defaultFacts(widget.vehicle);
    final label = widget.eyebrowLabel ?? _defaultEyebrow(widget.vehicle);
    final cardRadius = widget.cardRadius;
    final imageRadius = cardRadius;
    final badgeRadius = cardRadius < 8 ? cardRadius : 8.0;
    final chipRadius = cardRadius < 12 ? cardRadius : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: const Color(0xFFD9DEE6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _VehicleImageCarousel(
                  images: _images,
                  pageController: _pageController,
                  currentIndex: _currentImageIndex,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                      _currentImageIndex =
                          _images.isEmpty ? 0 : index % _images.length;
                    });
                  },
                  isWishlisted: widget.isWishlisted,
                  badgeLabel: widget.badgeLabel,
                  onToggleWishlist: widget.onToggleWishlist,
                  showNavigation: widget.showImageNavigation && _canSlide,
                  showIndicators: widget.showImageIndicators && _canSlide,
                  onPrevious: _previousImage,
                  onNext: _nextImage,
                  imageRadius: imageRadius,
                  badgeRadius: badgeRadius,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFFDF3040),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.vehicle.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF2A2A2A),
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.vehicle.year != null) ...[
                          const SizedBox(width: 12),
                          _YearChip(
                            year: widget.vehicle.year!,
                            radius: chipRadius,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency(
                        widget.vehicle.price,
                        widget.vehicle.currency,
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFFDF3040),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE1E5EB)),
                    const SizedBox(height: 10),
                    Row(
                      children: resolvedFacts
                          .take(3)
                          .map(
                            (fact) => Expanded(
                              child: _FactColumn(fact: fact),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE1E5EB)),
                    const SizedBox(height: 2),
                    TextButton(
                      onPressed: widget.onTap,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDF3040),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.ctaLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFFDF3040),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
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
  }
}

class VehicleFact {
  const VehicleFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _VehicleImageCarousel extends StatelessWidget {
  const _VehicleImageCarousel({
    required this.images,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
    required this.isWishlisted,
    required this.badgeLabel,
    required this.onToggleWishlist,
    required this.showNavigation,
    required this.showIndicators,
    required this.onPrevious,
    required this.onNext,
    required this.imageRadius,
    required this.badgeRadius,
  });

  final List<String> images;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final bool isWishlisted;
  final String badgeLabel;
  final VoidCallback? onToggleWishlist;
  final bool showNavigation;
  final bool showIndicators;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final double imageRadius;
  final double badgeRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(imageRadius),
      child: AspectRatio(
        aspectRatio: 1.55,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFE7E1D8)),
                child: Icon(Icons.directions_car_rounded, size: 52),
              )
            else
              PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  final imageUrl = images[index % images.length];
                  return DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFFE7E1D8)),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.directions_car_rounded, size: 52),
                    ),
                  );
                },
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x26000000),
                    Colors.transparent,
                    Color(0x55000000),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFDF3040),
                  borderRadius: BorderRadius.circular(badgeRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    badgeLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: IconButton(
                  onPressed: onToggleWishlist,
                  tooltip: isWishlisted
                      ? 'Remove from wishlist'
                      : 'Add to wishlist',
                  iconSize: 24,
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFFDF3040),
                    shape: const CircleBorder(),
                  ),
                  icon: Icon(
                    isWishlisted
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                ),
              ),
            ),
            if (showNavigation)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CarouselNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: onPrevious,
                  ),
                ),
              ),
            if (showNavigation)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CarouselNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: onNext,
                  ),
                ),
              ),
            if (showIndicators)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == currentIndex
                                ? const Color(0xFFDF3040)
                                : Colors.white70,
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

class _CarouselNavButton extends StatelessWidget {
  const _CarouselNavButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Icon(icon, color: Colors.white70, size: 34),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({required this.year, required this.radius});

  final int year;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFDF3040)),
      ),
      child: Text(
        '$year',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFDF3040),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FactColumn extends StatelessWidget {
  const _FactColumn({required this.fact});

  final VehicleFact fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(fact.icon, color: const Color(0xFFDF3040), size: 20),
          const SizedBox(height: 10),
          Text(
            fact.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8B92A7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fact.value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF323338),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

String _defaultEyebrow(VehicleSummary vehicle) {
  if (vehicle.bodyType.isNotEmpty) {
    return vehicle.bodyType.toUpperCase();
  }
  if (vehicle.make.isNotEmpty) {
    return vehicle.make.toUpperCase();
  }
  return vehicle.country.toUpperCase();
}

List<VehicleFact> _defaultFacts(VehicleSummary vehicle) {
  return <VehicleFact>[
    VehicleFact(
      icon: Icons.local_gas_station_outlined,
      label: 'Fuel Type',
      value: _firstNonEmpty(vehicle.fuel, vehicle.engineType, 'Unknown'),
    ),
    VehicleFact(
      icon: Icons.speed_outlined,
      label: 'Odometer',
      value: vehicle.odometer == null
          ? 'Unknown'
          : '${formatWholeNumber(vehicle.odometer!)} km',
    ),
    VehicleFact(
      icon: Icons.settings_input_component_outlined,
      label: vehicle.transmission.isNotEmpty ? 'Transmission' : 'Drive Type',
      value: _firstNonEmpty(
        vehicle.transmission,
        vehicle.drive,
        vehicle.bodyType,
        'Unknown',
      ),
    ),
  ];
}

String _firstNonEmpty(
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
