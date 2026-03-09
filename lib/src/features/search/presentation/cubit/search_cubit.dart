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

      emit(
        state.copyWith(
          isLoadingMetadata: false,
          filterMetadata: results[0] as FilterMetadata,
          vehicleAttributes: results[1] as VehicleAttributes,
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
}
