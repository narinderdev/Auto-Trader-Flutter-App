import '../core/auto_trader_api.dart';
import '../models/auto_trader_models.dart';

class AutoTraderRepository {
  AutoTraderRepository({AutoTraderApi? api}) : _api = api ?? AutoTraderApi();

  final AutoTraderApi _api;

  Future<List<VehicleSummary>> fetchHomepageVehicles() {
    return _api.fetchHomepageVehicles();
  }

  Future<FilterMetadata> fetchFilters({
    String? makeId,
    String? countryId,
    int? fromYear,
    int? toYear,
  }) {
    return _api.fetchFilters(
      makeId: makeId,
      countryId: countryId,
      fromYear: fromYear,
      toYear: toYear,
    );
  }

  Future<List<VehicleSummary>> fetchAzerbaijanFeaturedVehicles() {
    return _api.fetchAzerbaijanFeaturedVehicles();
  }

  Future<List<VehicleSummary>> fetchElectricFeaturedVehicles() {
    return _api.fetchElectricFeaturedVehicles();
  }

  Future<void> validateQuickSearch(VehicleSearchFilters filters) {
    return _api.validateQuickSearch(filters);
  }

  Future<VehicleAttributes> fetchVehicleAttributes() {
    return _api.fetchVehicleAttributes();
  }

  Future<SearchResponse> searchVehicles(
    VehicleSearchFilters filters, {
    required int page,
    int limit = 10,
  }) {
    return _api.searchVehicles(filters, page: page, limit: limit);
  }

  Future<VehicleDetails> fetchVehicleDetails(
    String id, {
    VehicleSummary? fallback,
  }) {
    return _api.fetchVehicleDetails(id, fallback: fallback);
  }

  Future<List<VehicleSummary>> fetchSimilarVehicles(String make) {
    return _api.fetchSimilarVehicles(make);
  }
}
