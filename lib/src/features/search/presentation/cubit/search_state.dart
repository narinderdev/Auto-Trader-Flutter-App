import 'package:equatable/equatable.dart';

import '../../../../models/auto_trader_models.dart';

class SearchState extends Equatable {
  const SearchState({
    this.isLoadingMetadata = true,
    this.isLoadingResults = true,
    this.errorMessage,
    this.filterMetadata = FilterMetadata.empty,
    this.vehicleAttributes = VehicleAttributes.empty,
    this.filters = const VehicleSearchFilters(),
    this.results = const <VehicleSummary>[],
    this.page = 1,
    this.limit = 10,
    this.total,
  });

  final bool isLoadingMetadata;
  final bool isLoadingResults;
  final String? errorMessage;
  final FilterMetadata filterMetadata;
  final VehicleAttributes vehicleAttributes;
  final VehicleSearchFilters filters;
  final List<VehicleSummary> results;
  final int page;
  final int limit;
  final int? total;

  static const Object _unset = Object();

  bool get isBusy => isLoadingMetadata || isLoadingResults;

  int? get totalPages {
    if (total == null) {
      return null;
    }
    return ((total! / limit).ceil()).clamp(1, 999999);
  }

  SearchState copyWith({
    bool? isLoadingMetadata,
    bool? isLoadingResults,
    Object? errorMessage = _unset,
    FilterMetadata? filterMetadata,
    VehicleAttributes? vehicleAttributes,
    VehicleSearchFilters? filters,
    List<VehicleSummary>? results,
    int? page,
    int? limit,
    Object? total = _unset,
  }) {
    return SearchState(
      isLoadingMetadata: isLoadingMetadata ?? this.isLoadingMetadata,
      isLoadingResults: isLoadingResults ?? this.isLoadingResults,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      filterMetadata: filterMetadata ?? this.filterMetadata,
      vehicleAttributes: vehicleAttributes ?? this.vehicleAttributes,
      filters: filters ?? this.filters,
      results: results ?? this.results,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: identical(total, _unset) ? this.total : total as int?,
    );
  }

  @override
  List<Object?> get props => [
    isLoadingMetadata,
    isLoadingResults,
    errorMessage,
    filterMetadata,
    vehicleAttributes,
    filters,
    results,
    page,
    limit,
    total,
  ];
}
