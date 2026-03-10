import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/vehicle_details/presentation/cubit/vehicle_details_cubit.dart';
import '../features/vehicle_details/presentation/cubit/vehicle_details_state.dart';
import '../features/wishlist/wishlist_controller.dart';
import '../models/auto_trader_models.dart';
import '../repositories/auto_trader_repository.dart';
import '../utils/formatters.dart';
import '../widgets/vehicle_card_tile.dart';

class VehicleDetailsPage extends StatelessWidget {
  const VehicleDetailsPage({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
  });

  final String vehicleId;
  final VehicleSummary? initialVehicle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          VehicleDetailsCubit(repository: context.read<AutoTraderRepository>())
            ..load(vehicleId: vehicleId, initialVehicle: initialVehicle),
      child: _VehicleDetailsView(
        vehicleId: vehicleId,
        initialVehicle: initialVehicle,
      ),
    );
  }
}

class _VehicleDetailsView extends StatelessWidget {
  const _VehicleDetailsView({
    required this.vehicleId,
    required this.initialVehicle,
  });

  final String vehicleId;
  final VehicleSummary? initialVehicle;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistController>();

    return BlocBuilder<VehicleDetailsCubit, VehicleDetailsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                context.read<VehicleDetailsCubit>().load(
                                  vehicleId: vehicleId,
                                  initialVehicle: initialVehicle,
                                ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _Gallery(vehicle: state.vehicle!),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.vehicle!.title,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                formatCurrency(
                                  state.vehicle!.price,
                                  state.vehicle!.currency,
                                ),
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: const Color(0xFFB4232F),
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (state.vehicle!.location.isNotEmpty)
                                    _SpecPill(label: state.vehicle!.location),
                                  if (state.vehicle!.fuel.isNotEmpty)
                                    _SpecPill(label: state.vehicle!.fuel),
                                  if (state.vehicle!.transmission.isNotEmpty)
                                    _SpecPill(
                                      label: state.vehicle!.transmission,
                                    ),
                                  if (state.vehicle!.bodyType.isNotEmpty)
                                    _SpecPill(label: state.vehicle!.bodyType),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _DetailGrid(vehicle: state.vehicle!),
                              if (state.vehicle!.highlights.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                Text(
                                  'Highlights',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: state.vehicle!.highlights
                                      .map((item) => _SpecPill(label: item))
                                      .toList(),
                                ),
                              ],
                              if (state.vehicle!.description.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                Text(
                                  'Description',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  state.vehicle!.description,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (state.similarVehicles.isNotEmpty) ...[
                        Text(
                          'Similar vehicles',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        ...state.similarVehicles.map(
                          (vehicle) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: VehicleCardTile(
                              vehicle: vehicle,
                              isWishlisted: wishlist.contains(vehicle.id),
                              onToggleWishlist: () =>
                                  _toggleWishlist(context, vehicle.id),
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => VehicleDetailsPage(
                                      vehicleId: vehicle.id,
                                      initialVehicle: vehicle,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
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
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.vehicle});

  final VehicleDetails vehicle;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final gallery = widget.vehicle.gallery.isEmpty
        ? <String>[widget.vehicle.image]
        : widget.vehicle.gallery;
    final selectedImage = gallery[_activeIndex.clamp(0, gallery.length - 1)];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFE7E1D8),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: selectedImage.isEmpty
                    ? const Icon(Icons.directions_car_filled_rounded, size: 64)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          selectedImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.directions_car_filled_rounded,
                                size: 64,
                              ),
                        ),
                      ),
              ),
            ),
            if (gallery.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: gallery.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final image = gallery[index];
                    final isSelected = index == _activeIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeIndex = index;
                        });
                      },
                      child: Container(
                        width: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFB4232F)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFE7E1D8),
                                ),
                                child: Icon(Icons.image_not_supported_outlined),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.vehicle});

  final VehicleDetails vehicle;

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String>>[
      MapEntry('VIN', vehicle.vin),
      MapEntry('Year', vehicle.year?.toString() ?? ''),
      MapEntry(
        'Mileage',
        vehicle.odometer == null
            ? ''
            : '${formatWholeNumber(vehicle.odometer!)} km',
      ),
      MapEntry('Engine', vehicle.engine),
      MapEntry('Drive', vehicle.drive),
      MapEntry('Color', vehicle.color),
      MapEntry('Condition', vehicle.condition),
      MapEntry('Country', vehicle.country),
    ].where((entry) => entry.value.isNotEmpty).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 760 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFE8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.key,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF6B6156),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SpecPill extends StatelessWidget {
  const _SpecPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
