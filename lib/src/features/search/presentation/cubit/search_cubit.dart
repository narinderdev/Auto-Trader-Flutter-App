import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/auto_trader_models.dart';
import '../../../../repositories/auto_trader_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({required AutoTraderRepository repository})
    : _repository = repository,
      super(const SearchState());

  final AutoTraderRepository _repository;

  Future<void> initialize(VehicleSearchFilters initialFilters) async {
    emit(
      state.copyWith(
        isLoadingMetadata: true,
        isLoadingResults: true,
        errorMessage: null,
        filters: initialFilters,
      ),
    );

    try {
      final results = await Future.wait<dynamic>([
        _repository.fetchFilters(),
        _repository.fetchVehicleAttributes(),
      ]);

      final filterMetadata = results[0] as FilterMetadata;
      final vehicleAttributes = results[1] as VehicleAttributes;
      final resolvedFilters = _resolveInitialFilters(
        initialFilters,
        filterMetadata,
        vehicleAttributes,
      );

      emit(
        state.copyWith(
          isLoadingMetadata: false,
          filterMetadata: filterMetadata,
          vehicleAttributes: vehicleAttributes,
          filters: resolvedFilters,
        ),
      );

      await loadResults(resetPage: true);
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMetadata: false,
          isLoadingResults: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void updateFilters(VehicleSearchFilters filters) {
    emit(state.copyWith(filters: filters, errorMessage: null));
  }

  Future<void> loadResults({bool resetPage = false, int? requestedPage}) async {
    final nextPage = requestedPage ?? (resetPage ? 1 : state.page);
    emit(
      state.copyWith(
        isLoadingResults: true,
        errorMessage: null,
        page: resetPage ? 1 : nextPage,
      ),
    );

    try {
      final response = await _repository.searchVehicles(
        state.filters,
        page: nextPage,
        limit: state.limit,
      );

      emit(
        state.copyWith(
          isLoadingResults: false,
          results: response.vehicles,
          page: response.page,
          limit: response.limit,
          total: response.total,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingResults: false,
          results: const <VehicleSummary>[],
          total: null,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> applyFilters(VehicleSearchFilters filters) async {
    emit(state.copyWith(filters: filters));
    await loadResults(resetPage: true);
  }

  Future<void> clearFilters() async {
    emit(state.copyWith(filters: const VehicleSearchFilters()));
    await loadResults(resetPage: true);
  }

  Future<void> goToPage(int page) async {
    if (page < 1) {
      return;
    }
    final totalPages = state.totalPages;
    if (totalPages != null && page > totalPages) {
      return;
    }
    await loadResults(requestedPage: page);
  }

  VehicleSearchFilters _resolveInitialFilters(
    VehicleSearchFilters filters,
    FilterMetadata filterMetadata,
    VehicleAttributes vehicleAttributes,
  ) {
    LabeledOption? resolveOption(
      LabeledOption? current,
      List<LabeledOption> options,
    ) {
      if (current == null) {
        return null;
      }
      if (options.isEmpty) {
        return current;
      }
      final currentId = current.id?.trim();
      if (currentId != null && currentId.isNotEmpty) {
        final idLower = currentId.toLowerCase();
        for (final option in options) {
          final optionId = option.id?.trim();
          if (optionId != null && optionId.toLowerCase() == idLower) {
            return option;
          }
        }
      }
      final currentLabel = current.label.trim();
      if (currentLabel.isNotEmpty) {
        final labelLower = currentLabel.toLowerCase();
        for (final option in options) {
          if (option.label.trim().toLowerCase() == labelLower) {
            return option;
          }
        }
      }
      return current;
    }

    final fuelOptions = vehicleAttributes.fuels.isNotEmpty
        ? vehicleAttributes.fuels
        : filterMetadata.fuels;
    final primaryDamageOptions = vehicleAttributes.primaryDamages;
    final secondaryDamageOptions = vehicleAttributes.secondaryDamages;

    return filters.copyWith(
      make: resolveOption(filters.make, filterMetadata.makes),
      model: resolveOption(filters.model, filterMetadata.models),
      country: resolveOption(filters.country, filterMetadata.countries),
      bodyType: resolveOption(filters.bodyType, vehicleAttributes.bodyTypes),
      fuel: resolveOption(filters.fuel, fuelOptions),
      primaryDamage: resolveOption(filters.primaryDamage, primaryDamageOptions),
      secondaryDamage:
          resolveOption(filters.secondaryDamage, secondaryDamageOptions),
      engineType: resolveOption(
        filters.engineType,
        vehicleAttributes.engineTypes,
      ),
      transmission: resolveOption(
        filters.transmission,
        vehicleAttributes.transmissions,
      ),
      drive: resolveOption(filters.drive, vehicleAttributes.drives),
      color: resolveOption(filters.color, vehicleAttributes.colors),
    );
  }
}
