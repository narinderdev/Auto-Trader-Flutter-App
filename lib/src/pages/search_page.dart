import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/wishlist/wishlist_controller.dart';
import '../features/search/presentation/cubit/search_cubit.dart';
import '../features/search/presentation/cubit/search_state.dart';
import '../models/auto_trader_models.dart';
import '../repositories/auto_trader_repository.dart';
import '../utils/formatters.dart';
import '../widgets/vehicle_card_tile.dart';
import 'vehicle_details_page.dart';

const _dropdownMenuMaxHeight = 280.0;

class SearchPage extends StatelessWidget {
  const SearchPage({
    super.key,
    this.initialFilters = const VehicleSearchFilters(),
    this.showScaffold = true,
    this.title,
  });

  final VehicleSearchFilters initialFilters;
  final bool showScaffold;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? _defaultSearchTitle(initialFilters);

    return BlocProvider(
      create: (context) =>
          SearchCubit(repository: context.read<AutoTraderRepository>())
            ..initialize(initialFilters),
      child: _SearchView(
        initialFilters: initialFilters,
        showScaffold: showScaffold,
        title: resolvedTitle,
      ),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({
    required this.initialFilters,
    required this.showScaffold,
    required this.title,
  });

  final VehicleSearchFilters initialFilters;
  final bool showScaffold;
  final String title;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _priceMinController;
  late final TextEditingController _priceMaxController;
  late final TextEditingController _odometerMinController;
  late final TextEditingController _odometerMaxController;

  @override
  void initState() {
    super.initState();
    _priceMinController = TextEditingController(
      text: widget.initialFilters.priceMin?.toString() ?? '',
    );
    _priceMaxController = TextEditingController(
      text: widget.initialFilters.priceMax?.toString() ?? '',
    );
    _odometerMinController = TextEditingController(
      text: widget.initialFilters.odometerMin?.toString() ?? '',
    );
    _odometerMaxController = TextEditingController(
      text: widget.initialFilters.odometerMax?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _odometerMinController.dispose();
    _odometerMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistController>();

    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        final content = SafeArea(
          child: state.isBusy && state.results.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<SearchCubit>().loadResults(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _FiltersCard(
                        state: state,
                        priceMinController: _priceMinController,
                        priceMaxController: _priceMaxController,
                        odometerMinController: _odometerMinController,
                        odometerMaxController: _odometerMaxController,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.total == null
                                  ? '${state.results.length} vehicles'
                                  : '${state.results.length} of ${formatWholeNumber(state.total!)} vehicles',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (state.errorMessage != null)
                            Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFB4232F),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.results.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Text(
                              'No vehicles match the current filters.',
                            ),
                          ),
                        )
                      else
                        ...state.results.map(
                          (vehicle) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: VehicleCardTile(
                              vehicle: vehicle,
                              onTap: () => _openDetails(context, vehicle),
                              isWishlisted: wishlist.contains(vehicle.id),
                              onToggleWishlist: () =>
                                  _toggleWishlist(vehicle.id),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (state.totalPages != null && state.totalPages! > 1)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                OutlinedButton(
                                  onPressed: state.page > 1
                                      ? () => context
                                            .read<SearchCubit>()
                                            .goToPage(state.page - 1)
                                      : null,
                                  child: const Text('Previous'),
                                ),
                                const Spacer(),
                                Text(
                                  'Page ${state.page} of ${state.totalPages}',
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: state.page < state.totalPages!
                                      ? () => context
                                            .read<SearchCubit>()
                                            .goToPage(state.page + 1)
                                      : null,
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );

        if (!widget.showScaffold) {
          return content;
        }

        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: content,
        );
      },
    );
  }

  void _openDetails(BuildContext context, VehicleSummary vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            VehicleDetailsPage(vehicleId: vehicle.id, initialVehicle: vehicle),
      ),
    );
  }

  void _toggleWishlist(String vehicleId) {
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

String _defaultSearchTitle(VehicleSearchFilters filters) {
  final countryLabel = filters.country?.label.trim().toLowerCase();
  final fuelLabel = filters.fuel?.label.trim().toLowerCase();

  if (countryLabel == 'auction') {
    return 'Active Lots';
  }
  if (fuelLabel == 'electric') {
    return 'Electric Vehicles';
  }
  return 'Vehicle Search';
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.state,
    required this.priceMinController,
    required this.priceMaxController,
    required this.odometerMinController,
    required this.odometerMaxController,
  });

  final SearchState state;
  final TextEditingController priceMinController;
  final TextEditingController priceMaxController;
  final TextEditingController odometerMinController;
  final TextEditingController odometerMaxController;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    final filters = state.filters;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _OptionField(
                  title: 'Make',
                  options: state.filterMetadata.makes,
                  value: filters.make,
                  onChanged: (value) => cubit.updateFilters(
                    filters.copyWith(make: value, model: null),
                  ),
                ),
                _OptionField(
                  title: 'Model',
                  options: state.filterMetadata.models,
                  value: filters.model,
                  onChanged: (value) =>
                      cubit.updateFilters(filters.copyWith(model: value)),
                ),
                _OptionField(
                  title: 'Country',
                  options: countryOptionsWithAuction(
                    state.filterMetadata.countries,
                  ),
                  value: filters.country,
                  onChanged: (value) =>
                      cubit.updateFilters(filters.copyWith(country: value)),
                ),
                _OptionField(
                  title: 'Fuel',
                  options: state.vehicleAttributes.fuels,
                  value: filters.fuel,
                  onChanged: (value) =>
                      cubit.updateFilters(filters.copyWith(fuel: value)),
                ),
                _OptionField(
                  title: 'Body style',
                  options: state.vehicleAttributes.bodyTypes,
                  value: filters.bodyType,
                  onChanged: (value) =>
                      cubit.updateFilters(filters.copyWith(bodyType: value)),
                ),
                _OptionField(
                  title: 'Transmission',
                  options: state.vehicleAttributes.transmissions,
                  value: filters.transmission,
                  onChanged: (value) => cubit.updateFilters(
                    filters.copyWith(transmission: value),
                  ),
                ),
                _OptionField(
                  title: 'Drive',
                  options: state.vehicleAttributes.drives,
                  value: filters.drive,
                  onChanged: (value) =>
                      cubit.updateFilters(filters.copyWith(drive: value)),
                ),
                _OptionField(
                  title: 'Color',
                  options: state.vehicleAttributes.colors,
                  value: filters.color,
                  onChanged: (value) =>
                      cubit.updateFilters(filters.copyWith(color: value)),
                ),
                _YearField(
                  title: 'From year',
                  values: _yearOptions(
                    state.filterMetadata.fromYears,
                    state.vehicleAttributes.yearRange,
                  ),
                  value: filters.yearFrom,
                  onChanged: (value) =>
                      cubit.updateFilters(filters.copyWith(yearFrom: value)),
                ),
                _YearField(
                  title: 'To year',
                  values: _yearOptions(
                    state.filterMetadata.toYears,
                    state.vehicleAttributes.yearRange,
                  ),
                  value: filters.yearTo,
                  onChanged: (value) =>
                      cubit.updateFilters(filters.copyWith(yearTo: value)),
                ),
                _NumberField(
                  title: 'Price min',
                  controller: priceMinController,
                  hint: state.vehicleAttributes.priceRange == null
                      ? 'Min'
                      : '${state.vehicleAttributes.priceRange!.min.round()}',
                ),
                _NumberField(
                  title: 'Price max',
                  controller: priceMaxController,
                  hint: state.vehicleAttributes.priceRange == null
                      ? 'Max'
                      : '${state.vehicleAttributes.priceRange!.max.round()}',
                ),
                _NumberField(
                  title: 'Odometer min',
                  controller: odometerMinController,
                  hint: state.vehicleAttributes.odometerRange == null
                      ? 'Min'
                      : '${state.vehicleAttributes.odometerRange!.min.round()}',
                ),
                _NumberField(
                  title: 'Odometer max',
                  controller: odometerMaxController,
                  hint: state.vehicleAttributes.odometerRange == null
                      ? 'Max'
                      : '${state.vehicleAttributes.odometerRange!.max.round()}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final nextFilters = filters.copyWith(
                        priceMin: _parseIntOrNull(priceMinController.text),
                        priceMax: _parseIntOrNull(priceMaxController.text),
                        odometerMin: _parseIntOrNull(
                          odometerMinController.text,
                        ),
                        odometerMax: _parseIntOrNull(
                          odometerMaxController.text,
                        ),
                      );
                      await cubit.applyFilters(nextFilters);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFFB4232F),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply filters'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () async {
                    priceMinController.clear();
                    priceMaxController.clear();
                    odometerMinController.clear();
                    odometerMaxController.clear();
                    await cubit.clearFilters();
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<int> _yearOptions(List<int> metadataYears, NumericRange? range) {
    if (metadataYears.isNotEmpty) {
      return metadataYears;
    }
    if (range == null) {
      return const <int>[];
    }
    final min = range.min.round();
    final max = range.max.round();
    return [for (var year = max; year >= min; year -= 1) year];
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.title,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<LabeledOption> options;
  final LabeledOption? value;
  final ValueChanged<LabeledOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentKey = _selectedKey(options, value);
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$title-$currentKey'),
        initialValue: currentKey,
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

class _YearField extends StatelessWidget {
  const _YearField({
    required this.title,
    required this.values,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final List<int> values;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = values.contains(value) ? value : null;
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<int>(
        key: ValueKey('$title-$selectedValue'),
        initialValue: selectedValue,
        isExpanded: true,
        menuMaxHeight: _dropdownMenuMaxHeight,
        decoration: InputDecoration(labelText: title),
        items: [
          const DropdownMenuItem<int>(value: null, child: Text('Any')),
          ...values.map(
            (year) => DropdownMenuItem<int>(value: year, child: Text('$year')),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.title,
    required this.controller,
    required this.hint,
  });

  final String title;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: title, hintText: hint),
      ),
    );
  }
}

int? _parseIntOrNull(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return int.tryParse(trimmed);
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
