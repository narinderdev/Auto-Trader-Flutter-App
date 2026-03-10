import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/wishlist/wishlist_controller.dart';
import '../features/search/presentation/cubit/search_cubit.dart';
import '../features/search/presentation/cubit/search_state.dart';
import '../models/auto_trader_models.dart';
import '../repositories/auto_trader_repository.dart';
import '../utils/formatters.dart';
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
  _QuickFilterType _quickFilter = _QuickFilterType.none;

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

  List<VehicleSummary> _applyQuickFilter(List<VehicleSummary> results) {
    if (_quickFilter == _QuickFilterType.none) {
      return results;
    }
    if (_quickFilter == _QuickFilterType.buyNow) {
      return results
          .where(
            (vehicle) =>
                vehicle.saleStatus.toLowerCase().contains('buy') ||
                vehicle.saleStatus.toLowerCase().contains('now'),
          )
          .toList();
    }
    return results
        .where(
          (vehicle) =>
              vehicle.primaryDamage.toLowerCase().contains('run') ||
              vehicle.primaryDamage.toLowerCase().contains('drive') ||
              vehicle.saleStatus.toLowerCase().contains('run'),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistController>();

    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        final filteredResults = _applyQuickFilter(state.results);
        final total = state.total;
        final hasResults = filteredResults.isNotEmpty;
        final pageStart = hasResults ? ((state.page - 1) * state.limit) + 1 : 0;
        final pageEnd =
            ((state.page - 1) * state.limit) + filteredResults.length;
        final showingText = total != null
            ? 'Showing $pageStart-$pageEnd of $total Results'
            : hasResults
            ? 'Showing $pageStart-$pageEnd Results'
            : 'Showing 0 Results';
        final hasKnownTotal = state.totalPages != null;
        final canPaginate = hasResults &&
            (hasKnownTotal
                ? state.totalPages! > 1
                : state.page > 1 || filteredResults.length == state.limit);
        final hasNextPage = hasKnownTotal
            ? state.page < state.totalPages!
            : filteredResults.length == state.limit;
        final content = SafeArea(
          child: state.isBusy && state.results.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => context.read<SearchCubit>().loadResults(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _QuickFiltersRow(
                        activeFilter: _quickFilter,
                        onSelect: (filter) {
                          setState(() {
                            _quickFilter = _quickFilter == filter
                                ? _QuickFilterType.none
                                : filter;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _FiltersCard(
                        state: state,
                        priceMinController: _priceMinController,
                        priceMaxController: _priceMaxController,
                        odometerMinController: _odometerMinController,
                        odometerMaxController: _odometerMaxController,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              showingText,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDECEC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFB4232F),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (filteredResults.isEmpty)
                        _NoResultsCard(
                          onDetailedSearch: () =>
                              _openDetailedSearch(context),
                        )
                      else
                        ...filteredResults.map(
                          (vehicle) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _SearchResultCard(
                              vehicle: vehicle,
                              isWishlisted: wishlist.contains(vehicle.id),
                              onToggleWishlist: () =>
                                  _toggleWishlist(vehicle.id),
                              onOpenDetails: () =>
                                  _openDetails(context, vehicle),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (canPaginate)
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
                                  hasKnownTotal
                                      ? 'Page ${state.page} of ${state.totalPages}'
                                      : 'Page ${state.page}',
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: hasNextPage
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
        builder: (_) => VehicleDetailsPage(
          vehicleId: vehicle.id,
          initialVehicle: vehicle,
          embedded: true,
        ),
      ),
    );
  }

  Future<void> _openDetailedSearch(BuildContext context) async {
    final cubit = context.read<SearchCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: _FiltersPage(
            priceMinController: _priceMinController,
            priceMaxController: _priceMaxController,
            odometerMinController: _odometerMinController,
            odometerMaxController: _odometerMaxController,
          ),
        ),
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
    final selectedChips = _buildSelectedFilters(filters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedChips.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected filters:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final chip in selectedChips)
                      _SelectedFilterChip(
                        label: chip.label,
                        onRemove: () async {
                          await cubit.applyFilters(chip.onRemove(filters));
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final cubit = context.read<SearchCubit>();
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: cubit,
                        child: _FiltersPage(
                          priceMinController: priceMinController,
                          priceMaxController: priceMaxController,
                          odometerMinController: odometerMinController,
                          odometerMaxController: odometerMaxController,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Filters'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  priceMinController.clear();
                  priceMaxController.clear();
                  odometerMinController.clear();
                  odometerMaxController.clear();
                  await cubit.clearFilters();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: const Text('Clear All Filters'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Sort by:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Sale Date'),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFDF3040),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.swap_vert_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<_SelectedFilter> _buildSelectedFilters(VehicleSearchFilters filters) {
    final selections = <_SelectedFilter>[];

    void addOption(
      String label,
      VehicleSearchFilters Function(VehicleSearchFilters current) onRemove,
    ) {
      selections.add(_SelectedFilter(label: label, onRemove: onRemove));
    }

    if (filters.make != null) {
      addOption(
        filters.make!.label,
        (current) => current.copyWith(make: null),
      );
    }
    if (filters.model != null) {
      addOption(
        filters.model!.label,
        (current) => current.copyWith(model: null),
      );
    }
    if (filters.country != null) {
      addOption(
        filters.country!.label,
        (current) => current.copyWith(country: null),
      );
    }
    if (filters.fuel != null) {
      addOption(
        filters.fuel!.label,
        (current) => current.copyWith(fuel: null),
      );
    }
    if (filters.primaryDamage != null) {
      addOption(
        filters.primaryDamage!.label,
        (current) => current.copyWith(primaryDamage: null),
      );
    }
    if (filters.secondaryDamage != null) {
      addOption(
        filters.secondaryDamage!.label,
        (current) => current.copyWith(secondaryDamage: null),
      );
    }
    if (filters.bodyType != null) {
      addOption(
        filters.bodyType!.label,
        (current) => current.copyWith(bodyType: null),
      );
    }
    if (filters.engineType != null) {
      addOption(
        filters.engineType!.label,
        (current) => current.copyWith(engineType: null),
      );
    }
    if (filters.transmission != null) {
      addOption(
        filters.transmission!.label,
        (current) => current.copyWith(transmission: null),
      );
    }
    if (filters.drive != null) {
      addOption(
        filters.drive!.label,
        (current) => current.copyWith(drive: null),
      );
    }
    if (filters.color != null) {
      addOption(
        filters.color!.label,
        (current) => current.copyWith(color: null),
      );
    }
    if (filters.yearFrom != null || filters.yearTo != null) {
      final yearLabel = [
        filters.yearFrom?.toString(),
        filters.yearTo?.toString(),
      ].whereType<String>().join(' - ');
      addOption(
        'Year $yearLabel',
        (current) => current.copyWith(yearFrom: null, yearTo: null),
      );
    }
    if (filters.priceMin != null || filters.priceMax != null) {
      final priceLabel = [
        filters.priceMin?.toString(),
        filters.priceMax?.toString(),
      ].whereType<String>().join(' - ');
      addOption(
        'Price $priceLabel',
        (current) => current.copyWith(priceMin: null, priceMax: null),
      );
    }
    if (filters.odometerMin != null || filters.odometerMax != null) {
      final odoLabel = [
        filters.odometerMin?.toString(),
        filters.odometerMax?.toString(),
      ].whereType<String>().join(' - ');
      addOption(
        'Odometer $odoLabel',
        (current) => current.copyWith(odometerMin: null, odometerMax: null),
      );
    }

    return selections;
  }
}

class _SearchResultCard extends StatefulWidget {
  const _SearchResultCard({
    required this.vehicle,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onOpenDetails,
  });

  final VehicleSummary vehicle;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final VoidCallback onOpenDetails;

  @override
  State<_SearchResultCard> createState() => _SearchResultCardState();
}

class _QuickFiltersRow extends StatelessWidget {
  const _QuickFiltersRow({
    required this.activeFilter,
    required this.onSelect,
  });

  final _QuickFilterType activeFilter;
  final ValueChanged<_QuickFilterType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Quick Filters:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
          ),
          _QuickFilterChip(
            label: 'Buy now',
            isSelected: activeFilter == _QuickFilterType.buyNow,
            onTap: () => onSelect(_QuickFilterType.buyNow),
          ),
          _QuickFilterChip(
            label: 'Run & Drive',
            isSelected: activeFilter == _QuickFilterType.runDrive,
            onTap: () => onSelect(_QuickFilterType.runDrive),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        backgroundColor: isSelected ? const Color(0xFFDF3040) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF111827),
        side: BorderSide(
          color: isSelected ? const Color(0xFFDF3040) : const Color(0xFFD1D5DB),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _QuickFilterType { none, buyNow, runDrive }

class _NoResultsCard extends StatelessWidget {
  const _NoResultsCard({required this.onDetailedSearch});

  final VoidCallback onDetailedSearch;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No results were found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your keywords or filters to expand the results and continue your search.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDetailedSearch,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDF3040),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Detailed Search'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFilter {
  const _SelectedFilter({required this.label, required this.onRemove});

  final String label;
  final VehicleSearchFilters Function(VehicleSearchFilters current) onRemove;
}

class _SelectedFilterChip extends StatelessWidget {
  const _SelectedFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersPage extends StatelessWidget {
  const _FiltersPage({
    required this.priceMinController,
    required this.priceMaxController,
    required this.odometerMinController,
    required this.odometerMaxController,
  });

  final TextEditingController priceMinController;
  final TextEditingController priceMaxController;
  final TextEditingController odometerMinController;
  final TextEditingController odometerMaxController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        final cubit = context.read<SearchCubit>();
        final filters = state.filters;
        final years = _resolveYearOptions(
          state.filterMetadata.fromYears,
          state.vehicleAttributes.yearRange,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _FilterListRow(
                        title: 'Make',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Make',
                              options: state.filterMetadata.makes,
                              selected: filters.make,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(make: value, model: null),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Model',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Model',
                              options: state.filterMetadata.models,
                              selected: filters.model,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(model: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Year',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _YearRangePage(
                              years: years,
                              fromYear: filters.yearFrom,
                              toYear: filters.yearTo,
                              onApply: (from, to) async {
                                await cubit.applyFilters(
                                  filters.copyWith(yearFrom: from, yearTo: to),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Color',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Color',
                              options: state.vehicleAttributes.colors,
                              selected: filters.color,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(color: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Odometer',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _RangeFilterPage(
                              title: 'Odometer',
                              minLabel: 'Min',
                              maxLabel: 'Max',
                              minController: odometerMinController,
                              maxController: odometerMaxController,
                              onApply: () async {
                                await cubit.applyFilters(
                                  filters.copyWith(
                                    odometerMin:
                                        _parseIntOrNull(odometerMinController.text),
                                    odometerMax:
                                        _parseIntOrNull(odometerMaxController.text),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Price',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _RangeFilterPage(
                              title: 'Price',
                              minLabel: 'Min',
                              maxLabel: 'Max',
                              minController: priceMinController,
                              maxController: priceMaxController,
                              onApply: () async {
                                await cubit.applyFilters(
                                  filters.copyWith(
                                    priceMin:
                                        _parseIntOrNull(priceMinController.text),
                                    priceMax:
                                        _parseIntOrNull(priceMaxController.text),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Engine Type',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Engine Type',
                              options: state.vehicleAttributes.engineTypes,
                              selected: filters.engineType,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(engineType: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Transmission',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Transmission',
                              options: state.vehicleAttributes.transmissions,
                              selected: filters.transmission,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(transmission: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Fuel Type',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Fuel Type',
                              options: state.vehicleAttributes.fuels.isNotEmpty
                                  ? state.vehicleAttributes.fuels
                                  : state.filterMetadata.fuels,
                              selected: filters.fuel,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(fuel: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Primary Damage',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Primary Damage',
                              options: state.vehicleAttributes.primaryDamages,
                              selected: filters.primaryDamage,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(primaryDamage: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Secondary Damage',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Secondary Damage',
                              options:
                                  state.vehicleAttributes.secondaryDamages,
                              selected: filters.secondaryDamage,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(secondaryDamage: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Drive',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Drive',
                              options: state.vehicleAttributes.drives,
                              selected: filters.drive,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(drive: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Body Style',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Body Style',
                              options: state.vehicleAttributes.bodyTypes,
                              selected: filters.bodyType,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(bodyType: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      _FilterListRow(
                        title: 'Country',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _FilterOptionsPage(
                              title: 'Country',
                              options: countryOptionsWithAuction(
                                state.filterMetadata.countries,
                              ),
                              selected: filters.country,
                              onApply: (value) async {
                                await cubit.applyFilters(
                                  filters.copyWith(country: value),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (filters.country != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Country',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: const Color(0xFF6B7280),
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      filters.country!.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await cubit.applyFilters(
                                    filters.copyWith(country: null),
                                  );
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
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

class _FilterListRow extends StatelessWidget {
  const _FilterListRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _FilterOptionsPage extends StatefulWidget {
  const _FilterOptionsPage({
    required this.title,
    required this.options,
    required this.selected,
    required this.onApply,
  });

  final String title;
  final List<LabeledOption> options;
  final LabeledOption? selected;
  final ValueChanged<LabeledOption?> onApply;

  @override
  State<_FilterOptionsPage> createState() => _FilterOptionsPageState();
}

class _FilterOptionsPageState extends State<_FilterOptionsPage> {
  late final TextEditingController _searchController;
  LabeledOption? _selected;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selected = widget.selected;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filtered = query.isEmpty
        ? widget.options
        : widget.options
            .where(
              (option) => option.label.toLowerCase().contains(query),
            )
            .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      setState(() {
                        _selected = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final option = filtered[index];
                  final isSelected = _isSameOption(_selected, option);
                  return ListTile(
                    title: Text(option.label),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        setState(() {
                          _selected = isSelected ? null : option;
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _selected = isSelected ? null : option;
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          widget.onApply(_selected);
                          Navigator.of(context).pop();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE5E7EB),
                    foregroundColor: const Color(0xFF6B7280),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameOption(LabeledOption? current, LabeledOption other) {
    if (current == null) {
      return false;
    }
    if (current.id != null && other.id != null) {
      return current.id == other.id;
    }
    return current.label == other.label;
  }
}

class _YearRangePage extends StatefulWidget {
  const _YearRangePage({
    required this.years,
    required this.fromYear,
    required this.toYear,
    required this.onApply,
  });

  final List<int> years;
  final int? fromYear;
  final int? toYear;
  final void Function(int? from, int? to) onApply;

  @override
  State<_YearRangePage> createState() => _YearRangePageState();
}

class _YearRangePageState extends State<_YearRangePage> {
  int? _fromYear;
  int? _toYear;

  @override
  void initState() {
    super.initState();
    _fromYear = widget.fromYear;
    _toYear = widget.toYear;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Year',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: _fromYear,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'From year'),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...widget.years.map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _fromYear = value;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _toYear,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'To year'),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Any'),
                      ),
                      ...widget.years.map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _toYear = value;
                    }),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(_fromYear, _toYear);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeFilterPage extends StatelessWidget {
  const _RangeFilterPage({
    required this.title,
    required this.minLabel,
    required this.maxLabel,
    required this.minController,
    required this.maxController,
    required this.onApply,
  });

  final String title;
  final String minLabel;
  final String maxLabel;
  final TextEditingController minController;
  final TextEditingController maxController;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: minLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: maxLabel),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    onApply();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SearchResultCardState extends State<_SearchResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final odometerText = vehicle.odometer == null
        ? '-'
        : '${formatWholeNumber(vehicle.odometer!)} mi';
    final lotNumber = vehicle.lotNumber.isEmpty ? '-' : vehicle.lotNumber;
    final primaryDamage =
        vehicle.primaryDamage.isEmpty ? '-' : vehicle.primaryDamage;
    final fuelType = vehicle.fuel.isNotEmpty
        ? vehicle.fuel
        : vehicle.engineType.isNotEmpty
        ? vehicle.engineType
        : '-';
    final transmission = vehicle.transmission.isNotEmpty
        ? vehicle.transmission
        : vehicle.drive.isNotEmpty
        ? vehicle.drive
        : '-';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E1D8)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onOpenDetails,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      vehicle.image,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 74,
                        height: 74,
                        color: const Color(0xFFE7E1D8),
                        child: const Icon(Icons.directions_car_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF111827),
                                ),
                            children: [
                              const TextSpan(text: 'Lot: '),
                              TextSpan(
                                text: lotNumber,
                                style: const TextStyle(
                                  color: Color(0xFFDF3040),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Odometer: $odometerText (Actual)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF111827),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Primary Damage: $primaryDamage',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF111827),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SearchFactColumn(
                                icon: Icons.speed_outlined,
                                label: 'Odometer',
                                value: '$odometerText (Actual)',
                              ),
                            ),
                            Expanded(
                              child: _SearchFactColumn(
                                icon: Icons.local_gas_station_outlined,
                                label: 'Fuel Type',
                                value: fuelType,
                              ),
                            ),
                            Expanded(
                              child: _SearchFactColumn(
                                icon:
                                    Icons.settings_input_component_outlined,
                                label: 'Transmission',
                                value: transmission,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEDEE),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_expanded ? 0 : 8),
                  bottomRight: Radius.circular(_expanded ? 0 : 8),
                ),
              ),
              child: Text(
                _expanded ? 'Less Details -' : 'More Details +',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFDF3040),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEDEE),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Secondary Damage',
                    value: vehicle.secondaryDamage.isEmpty
                        ? '-'
                        : vehicle.secondaryDamage,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Sale Status',
                    value: vehicle.saleStatus.isEmpty
                        ? 'On Approval'
                        : vehicle.saleStatus,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Transmission',
                    value: vehicle.transmission.isEmpty
                        ? '-'
                        : vehicle.transmission,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Drive',
                    value: vehicle.drive.isEmpty ? '-' : vehicle.drive,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Fuel Type',
                    value: vehicle.fuel.isEmpty ? '-' : vehicle.fuel,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Color',
                    value: vehicle.color.isEmpty ? '-' : vehicle.color,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _SearchFactColumn extends StatelessWidget {
  const _SearchFactColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFDF3040), size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8B92A7),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF323338),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
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

List<int> _resolveYearOptions(List<int> metadataYears, NumericRange? range) {
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
