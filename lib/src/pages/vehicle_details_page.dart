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
    this.embedded = false,
  });

  final String vehicleId;
  final VehicleSummary? initialVehicle;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          VehicleDetailsCubit(repository: context.read<AutoTraderRepository>())
            ..load(vehicleId: vehicleId, initialVehicle: initialVehicle),
      child: _VehicleDetailsView(
        vehicleId: vehicleId,
        initialVehicle: initialVehicle,
        embedded: embedded,
      ),
    );
  }
}

class _VehicleDetailsView extends StatelessWidget {
  const _VehicleDetailsView({
    required this.vehicleId,
    required this.initialVehicle,
    required this.embedded,
  });

  final String vehicleId;
  final VehicleSummary? initialVehicle;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistController>();

    return BlocBuilder<VehicleDetailsCubit, VehicleDetailsState>(
      builder: (context, state) {
        final body = state.isLoading
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
            : _DetailsContent(
                vehicle: state.vehicle!,
                fallback: initialVehicle,
                similarVehicles: state.similarVehicles,
                wishlist: wishlist,
                onToggleWishlist: (id) => _toggleWishlist(context, id),
              );

        if (embedded) {
          return body;
        }

        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(child: body),
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

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.vehicle,
    required this.fallback,
    required this.similarVehicles,
    required this.wishlist,
    required this.onToggleWishlist,
  });

  final VehicleDetails vehicle;
  final VehicleSummary? fallback;
  final List<VehicleSummary> similarVehicles;
  final WishlistController wishlist;
  final ValueChanged<String> onToggleWishlist;

  @override
  Widget build(BuildContext context) {
    final lotNumber = vehicle.lotNumber.isNotEmpty
        ? vehicle.lotNumber
        : (fallback?.lotNumber ?? '');
    final primaryDamage = vehicle.primaryDamage.isNotEmpty
        ? vehicle.primaryDamage
        : (fallback?.primaryDamage ?? '');
    final secondaryDamage = vehicle.secondaryDamage.isNotEmpty
        ? vehicle.secondaryDamage
        : (fallback?.secondaryDamage ?? '');
    final saleStatus = vehicle.saleStatus.isNotEmpty
        ? vehicle.saleStatus
        : (fallback?.saleStatus ?? '');
    final saleDate = vehicle.saleDate.isNotEmpty ? vehicle.saleDate : '';
    final location = vehicle.location;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        Row(
          children: [
            Text(
              'Home',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFDF3040),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 6),
            const Text('/'),
            const SizedBox(width: 6),
            Text(
              'Search results',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
            ),
            const SizedBox(width: 6),
            const Text('/'),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                vehicle.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          vehicle.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            if (lotNumber.isNotEmpty)
              Text(
                'Lot #$lotNumber',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
              ),
            if (location.isNotEmpty)
              Text(
                'Location: ${location.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFDF3040),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            if (saleDate.isNotEmpty)
              Text(
                'Sale Date: $saleDate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _Gallery(vehicle: vehicle),
        const SizedBox(height: 14),
        _InfoCard(
          title: lotNumber.isEmpty ? 'Lot Details' : 'Lot #$lotNumber Details',
          rows: [
            _InfoRow('VIN', vehicle.vin),
            _InfoRow(
              'Odometer',
              vehicle.odometer == null
                  ? '-'
                  : '${formatWholeNumber(vehicle.odometer!)} mi (Actual)',
            ),
            _InfoRow('Title Code', vehicle.titleCode.isEmpty ? '-' : vehicle.titleCode),
            _InfoRow(
              'Primary Damage',
              primaryDamage.isEmpty ? '-' : primaryDamage,
            ),
            _InfoRow(
              'Secondary Damage',
              secondaryDamage.isEmpty ? '-' : secondaryDamage,
            ),
            _InfoRow(
              'Body Style',
              vehicle.bodyType.isEmpty ? '-' : vehicle.bodyType,
            ),
            _InfoRow('Color', vehicle.color.isEmpty ? '-' : vehicle.color),
            _InfoRow('Engine', vehicle.engine.isEmpty ? '-' : vehicle.engine),
            _InfoRow('Cylinders', vehicle.cylinders.isEmpty ? '-' : vehicle.cylinders),
            _InfoRow(
              'Transmission',
              vehicle.transmission.isEmpty ? '-' : vehicle.transmission,
            ),
            _InfoRow('Drive', vehicle.drive.isEmpty ? '-' : vehicle.drive),
            _InfoRow('Fuel', vehicle.fuel.isEmpty ? '-' : vehicle.fuel),
            _InfoRow('Keys', vehicle.keys.isEmpty ? '-' : vehicle.keys),
            _InfoRow(
              'Highlights',
              vehicle.highlights.isEmpty ? '-' : vehicle.highlights.join(', '),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _InfoCard(
          title: 'Sale Information',
          rows: [
            _InfoRow(
              'Current Bid',
              vehicle.currentBid == null
                  ? '-'
                  : formatCurrency(vehicle.currentBid!, vehicle.currency),
            ),
            _InfoRow(
              'Buy now',
              vehicle.buyNow == null
                  ? '-'
                  : formatCurrency(vehicle.buyNow!, vehicle.currency),
            ),
            _InfoRow('Location', location.isEmpty ? '-' : location.toUpperCase()),
            _InfoRow('Sale Date', saleDate.isEmpty ? '-' : saleDate),
            _InfoRow('Time Left', vehicle.timeLeft.isEmpty ? '-' : vehicle.timeLeft),
            _InfoRow('Sale Status', saleStatus.isEmpty ? '-' : saleStatus),
            _InfoRow(
              'Estimated Retail Value',
              vehicle.estimatedRetailValue == null
                  ? '-'
                  : formatCurrency(vehicle.estimatedRetailValue!, vehicle.currency),
            ),
            _InfoRow(
              'Last Updated',
              vehicle.lastUpdated.isEmpty ? '-' : vehicle.lastUpdated,
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _InlineCalculatorCard(),
        const SizedBox(height: 14),
        _InfoCard(
          title: 'Additionally',
          rows: [
            _InfoRow(
              'Notes',
              vehicle.description.isEmpty
                  ? 'Additional information will appear here.'
                  : vehicle.description,
              multiline: true,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Similar Vehicles',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        if (similarVehicles.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7E1D8)),
            ),
            child: const Text('No similar vehicles available for this configuration.'),
          )
        else
          ...similarVehicles.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: VehicleCardTile(
                vehicle: item,
                isWishlisted: wishlist.contains(item.id),
                onToggleWishlist: () => onToggleWishlist(item.id),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => VehicleDetailsPage(
                        vehicleId: item.id,
                        initialVehicle: item,
                        embedded: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E1D8)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE7E1D8))),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: rows
                  .where((row) => row.value.trim().isNotEmpty)
                  .map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: row,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.multiline = false});

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final valueText = value.isEmpty ? '-' : value;
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
        ),
        Expanded(
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _InlineCalculatorCard extends StatefulWidget {
  const _InlineCalculatorCard();

  @override
  State<_InlineCalculatorCard> createState() => _InlineCalculatorCardState();
}

class _InlineCalculatorCardState extends State<_InlineCalculatorCard> {
  final TextEditingController _bidController = TextEditingController();
  String _country = 'Azerbaijan';
  num _bid = 0;
  num _auctionFee = 0;
  num _shippingFee = 0;
  num _deliveryCost = 0;
  num _customsFee = 0;
  num _finalPrice = 0;

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  void _calculate() {
    final bid = num.tryParse(_bidController.text.trim()) ?? 0;
    final auctionFee = bid * 0.1;
    final shippingFee = _country == 'Azerbaijan' ? 350 : 450;
    final deliveryCost = 75;
    final customsFee = bid * 0.05;
    final total =
        bid + auctionFee + shippingFee + deliveryCost + customsFee;

    setState(() {
      _bid = bid;
      _auctionFee = auctionFee;
      _shippingFee = shippingFee;
      _deliveryCost = deliveryCost;
      _customsFee = customsFee;
      _finalPrice = total;
    });
  }

  void _clear() {
    setState(() {
      _bidController.clear();
      _bid = 0;
      _auctionFee = 0;
      _shippingFee = 0;
      _deliveryCost = 0;
      _customsFee = 0;
      _finalPrice = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E1D8)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculate the Final Price for Any Vehicle',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Enter your bid',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _country,
              decoration: const InputDecoration(labelText: 'To country'),
              items: const [
                DropdownMenuItem(value: 'Azerbaijan', child: Text('Azerbaijan')),
                DropdownMenuItem(value: 'Georgia', child: Text('Georgia')),
                DropdownMenuItem(value: 'Turkey', child: Text('Turkey')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _country = value;
                });
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _calculate,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: const Color(0xFFD21D39),
                foregroundColor: Colors.white,
              ),
              child: const Text('Calculate'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _clear,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Clear'),
            ),
            const SizedBox(height: 12),
            _InfoRow('Bid', formatCurrency(_bid, 'USD')),
            const SizedBox(height: 6),
            _InfoRow('Auction Fee', formatCurrency(_auctionFee, 'USD')),
            const SizedBox(height: 6),
            _InfoRow('Shipping Fee', formatCurrency(_shippingFee, 'USD')),
            const SizedBox(height: 6),
            _InfoRow('Cost of Delivery', formatCurrency(_deliveryCost, 'USD')),
            const SizedBox(height: 6),
            _InfoRow('Customs Fee', formatCurrency(_customsFee, 'USD')),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6EC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _InfoRow('Final Price', formatCurrency(_finalPrice, 'USD')),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: const Color(0xFFD21D39),
                foregroundColor: Colors.white,
              ),
              child: const Text('Call'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Write us'),
            ),
          ],
        ),
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

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E1D8),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: selectedImage.isEmpty
                      ? const Icon(Icons.directions_car_filled_rounded, size: 64)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(5),
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
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7E1D8)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hd_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('HD Image'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (gallery.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: gallery.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                    width: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFDF3040)
                            : const Color(0xFFE7E1D8),
                        width: 1.5,
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              gallery.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _activeIndex
                      ? const Color(0xFFDF3040)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
