import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/auto_trader_models.dart';
import '../../../../repositories/auto_trader_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required AutoTraderRepository repository,
    HomeBootstrapData? initialData,
  })
    : _repository = repository,
      super(
        initialData == null
            ? const HomeState()
            : HomeState(
                isLoading: false,
                loadingProgress: 100,
                homepageVehicles: initialData.homepageVehicles,
                filterMetadata: initialData.filterMetadata,
                scopedFilterMetadata: initialData.filterMetadata,
                azerbaijanFeatured: initialData.azerbaijanFeatured,
                electricFeatured: initialData.electricFeatured,
              ),
      );

  final AutoTraderRepository _repository;

  Future<void> load() async {
    if (!state.isLoading &&
        state.homepageVehicles.isNotEmpty &&
        state.filterMetadata != FilterMetadata.empty &&
        state.azerbaijanFeatured.isNotEmpty &&
        state.electricFeatured.isNotEmpty) {
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        loadingProgress: 0,
        errorMessage: null,
        quickSearchError: null,
      ),
    );

    try {
      final results = await _repository.fetchHomeBootstrapData(
        onProgress: (completedSteps, totalSteps) {
          emit(
            state.copyWith(
              isLoading: true,
              loadingProgress: ((completedSteps / totalSteps) * 100).round(),
            ),
          );
        },
      );

      final filters = results.filterMetadata;
      emit(
        state.copyWith(
          isLoading: false,
          loadingProgress: 100,
          homepageVehicles: results.homepageVehicles,
          filterMetadata: filters,
          scopedFilterMetadata: filters,
          azerbaijanFeatured: results.azerbaijanFeatured,
          electricFeatured: results.electricFeatured,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> selectMake(LabeledOption? make) async {
    emit(
      state.copyWith(
        selectedMake: make,
        selectedModel: null,
        quickSearchError: null,
      ),
    );
    await _refreshScopedFilters();
  }

  Future<void> selectCountry(LabeledOption? country) async {
    emit(state.copyWith(selectedCountry: country, quickSearchError: null));
  }

  Future<void> selectFromYear(int? year) async {
    emit(state.copyWith(selectedFromYear: year, quickSearchError: null));
  }

  Future<void> selectToYear(int? year) async {
    emit(state.copyWith(selectedToYear: year, quickSearchError: null));
  }

  void selectModel(LabeledOption? model) {
    emit(state.copyWith(selectedModel: model, quickSearchError: null));
  }

  void clearQuickSearch() {
    emit(
      state.copyWith(
        selectedMake: null,
        selectedModel: null,
        selectedCountry: null,
        selectedFromYear: null,
        selectedToYear: null,
        quickSearchError: null,
        scopedFilterMetadata: state.filterMetadata,
      ),
    );
  }

  Future<VehicleSearchFilters?> submitQuickSearch() async {
    final filters = state.quickSearchFilters;
    if (!filters.hasActiveValues) {
      emit(
        state.copyWith(
          quickSearchError: 'Select at least one filter before searching.',
        ),
      );
      return null;
    }

    if (state.selectedFromYear != null &&
        state.selectedToYear != null &&
        state.selectedFromYear! > state.selectedToYear!) {
      emit(
        state.copyWith(
          quickSearchError:
              '"Year To" must be greater than or equal to "Year From".',
        ),
      );
      return null;
    }

    emit(state.copyWith(isSubmittingQuickSearch: true, quickSearchError: null));

    try {
      await _repository.validateQuickSearch(filters);
      emit(state.copyWith(isSubmittingQuickSearch: false));
      return filters;
    } catch (_) {
      emit(
        state.copyWith(
          isSubmittingQuickSearch: false,
          quickSearchError: 'Quick search failed. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<void> _refreshScopedFilters() async {
    if (state.selectedMake == null) {
      emit(
        state.copyWith(
          scopedFilterMetadata: state.filterMetadata,
          selectedModel: null,
        ),
      );
      return;
    }

    try {
      final scoped = await _repository.fetchFilters(
        makeId: state.selectedMake?.id,
      );

      final hasSelectedModel =
          state.selectedModel != null &&
          scoped.models.any((item) => item.id == state.selectedModel?.id);

      emit(
        state.copyWith(
          scopedFilterMetadata: scoped,
          selectedModel: hasSelectedModel ? state.selectedModel : null,
        ),
      );
    } catch (_) {
      emit(state.copyWith(scopedFilterMetadata: state.filterMetadata));
    }
  }
}
