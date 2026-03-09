import 'package:equatable/equatable.dart';

import '../../../../models/auto_trader_models.dart';

class HomeState extends Equatable {
  const HomeState({
    this.isLoading = true,
    this.isSubmittingQuickSearch = false,
    this.errorMessage,
    this.quickSearchError,
    this.homepageVehicles = const <VehicleSummary>[],
    this.azerbaijanFeatured = const <VehicleSummary>[],
    this.electricFeatured = const <VehicleSummary>[],
    this.filterMetadata = FilterMetadata.empty,
    this.scopedFilterMetadata = FilterMetadata.empty,
    this.selectedMake,
    this.selectedModel,
    this.selectedCountry,
    this.selectedFromYear,
    this.selectedToYear,
  });

  final bool isLoading;
  final bool isSubmittingQuickSearch;
  final String? errorMessage;
  final String? quickSearchError;
  final List<VehicleSummary> homepageVehicles;
  final List<VehicleSummary> azerbaijanFeatured;
  final List<VehicleSummary> electricFeatured;
  final FilterMetadata filterMetadata;
  final FilterMetadata scopedFilterMetadata;
  final LabeledOption? selectedMake;
  final LabeledOption? selectedModel;
  final LabeledOption? selectedCountry;
  final int? selectedFromYear;
  final int? selectedToYear;

  static const Object _unset = Object();

  List<LabeledOption> get availableModels {
    if (selectedMake != null && scopedFilterMetadata.models.isNotEmpty) {
      return scopedFilterMetadata.models;
    }
    return filterMetadata.models;
  }

  List<LabeledOption> get availableCountries {
    return countryOptionsWithAuction(filterMetadata.countries);
  }

  List<int> get availableFromYears {
    return filterMetadata.fromYears;
  }

  List<int> get availableToYears {
    return filterMetadata.toYears;
  }

  VehicleSearchFilters get quickSearchFilters {
    return VehicleSearchFilters(
      make: selectedMake,
      model: selectedModel,
      country: selectedCountry,
      yearFrom: selectedFromYear,
      yearTo: selectedToYear,
    );
  }

  HomeState copyWith({
    bool? isLoading,
    bool? isSubmittingQuickSearch,
    Object? errorMessage = _unset,
    Object? quickSearchError = _unset,
    List<VehicleSummary>? homepageVehicles,
    List<VehicleSummary>? azerbaijanFeatured,
    List<VehicleSummary>? electricFeatured,
    FilterMetadata? filterMetadata,
    FilterMetadata? scopedFilterMetadata,
    Object? selectedMake = _unset,
    Object? selectedModel = _unset,
    Object? selectedCountry = _unset,
    Object? selectedFromYear = _unset,
    Object? selectedToYear = _unset,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isSubmittingQuickSearch:
          isSubmittingQuickSearch ?? this.isSubmittingQuickSearch,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      quickSearchError: identical(quickSearchError, _unset)
          ? this.quickSearchError
          : quickSearchError as String?,
      homepageVehicles: homepageVehicles ?? this.homepageVehicles,
      azerbaijanFeatured: azerbaijanFeatured ?? this.azerbaijanFeatured,
      electricFeatured: electricFeatured ?? this.electricFeatured,
      filterMetadata: filterMetadata ?? this.filterMetadata,
      scopedFilterMetadata: scopedFilterMetadata ?? this.scopedFilterMetadata,
      selectedMake: identical(selectedMake, _unset)
          ? this.selectedMake
          : selectedMake as LabeledOption?,
      selectedModel: identical(selectedModel, _unset)
          ? this.selectedModel
          : selectedModel as LabeledOption?,
      selectedCountry: identical(selectedCountry, _unset)
          ? this.selectedCountry
          : selectedCountry as LabeledOption?,
      selectedFromYear: identical(selectedFromYear, _unset)
          ? this.selectedFromYear
          : selectedFromYear as int?,
      selectedToYear: identical(selectedToYear, _unset)
          ? this.selectedToYear
          : selectedToYear as int?,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSubmittingQuickSearch,
    errorMessage,
    quickSearchError,
    homepageVehicles,
    azerbaijanFeatured,
    electricFeatured,
    filterMetadata,
    scopedFilterMetadata,
    selectedMake,
    selectedModel,
    selectedCountry,
    selectedFromYear,
    selectedToYear,
  ];
}
