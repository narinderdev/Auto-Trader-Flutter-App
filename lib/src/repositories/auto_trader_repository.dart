import '../core/auto_trader_api.dart';
import '../models/auto_trader_models.dart';

class HomeBootstrapData {
  const HomeBootstrapData({
    required this.homepageVehicles,
    required this.filterMetadata,
    required this.azerbaijanFeatured,
    required this.electricFeatured,
  });

  final List<VehicleSummary> homepageVehicles;
  final FilterMetadata filterMetadata;
  final List<VehicleSummary> azerbaijanFeatured;
  final List<VehicleSummary> electricFeatured;
}

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

  Future<HomeBootstrapData> fetchHomeBootstrapData({
    void Function(int completedSteps, int totalSteps)? onProgress,
  }) async {
    const totalSteps = 4;
    var completedSteps = 0;

    Future<T> track<T>(Future<T> future) async {
      final result = await future;
      completedSteps += 1;
      onProgress?.call(completedSteps, totalSteps);
      return result;
    }

    final results = await Future.wait<dynamic>([
      track(fetchHomepageVehicles()),
      track(fetchFilters()),
      track(fetchAzerbaijanFeaturedVehicles()),
      track(fetchElectricFeaturedVehicles()),
    ]);

    return HomeBootstrapData(
      homepageVehicles: results[0] as List<VehicleSummary>,
      filterMetadata: results[1] as FilterMetadata,
      azerbaijanFeatured: results[2] as List<VehicleSummary>,
      electricFeatured: results[3] as List<VehicleSummary>,
    );
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

  Future<SearchResponse> searchVehiclesByQuery(
    String queryText, {
    required int page,
    int limit = 10,
  }) {
    return _api.searchVehiclesByQuery(queryText, page: page, limit: limit);
  }

  Future<List<VehicleSummary>> fetchAuctionLotSuggestions(
    String term, {
    int limit = 20,
  }) {
    return _api.fetchAuctionLotSuggestions(term, limit: limit);
  }

  Future<VehicleSummary?> fetchAuctionLotDetail(String lotNumber) {
    return _api.fetchAuctionLotDetail(lotNumber);
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
