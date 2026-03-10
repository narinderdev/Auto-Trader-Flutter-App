import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/auto_trader_models.dart';

class AutoTraderApi {
  AutoTraderApi({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  Future<List<VehicleSummary>> fetchHomepageVehicles() async {
    final payload = await _getJson('');
    return _extractVehicleList(payload);
  }

  Future<FilterMetadata> fetchFilters({
    String? makeId,
    String? countryId,
    int? fromYear,
    int? toYear,
  }) async {
    final payload = await _getJson(
      '/metadata/filters',
      query: <String, String>{
        if (makeId != null && makeId.isNotEmpty) 'make_id': makeId,
        if (countryId != null && countryId.isNotEmpty) 'country_id': countryId,
        if (fromYear != null) 'from_year': '$fromYear',
        if (toYear != null) 'to_year': '$toYear',
      },
    );
    return FilterMetadata.fromJson(_extractPrimaryMap(payload));
  }

  Future<List<VehicleSummary>> fetchAzerbaijanFeaturedVehicles() async {
    final payload = await _getJson('/metadata/home/azerbaijan-vehicles');
    return _extractVehicleList(payload);
  }

  Future<List<VehicleSummary>> fetchElectricFeaturedVehicles() async {
    final payload = await _getJson('/metadata/home/electric-featured');
    return _extractVehicleList(payload);
  }

  Future<void> validateQuickSearch(VehicleSearchFilters filters) async {
    await _getJson(
      '/metadata/vehicle-results',
      query: filters.toQueryParameters(),
    );
  }

  Future<VehicleAttributes> fetchVehicleAttributes() async {
    final payload = await _getJson('/metadata/vehicle-attributes');
    return VehicleAttributes.fromJson(_extractPrimaryMap(payload));
  }

  Future<SearchResponse> searchVehicles(
    VehicleSearchFilters filters, {
    required int page,
    int limit = 10,
  }) async {
    final query = <String, String>{
      ...filters.toQueryParameters(),
      'page': '$page',
      'limit': '$limit',
    };

    if (kDebugMode) {
      debugPrint('Search query params: $query');
      debugPrint('Search uri: ${_buildUri('/metadata/vehicles', query: query)}');
    }

    final payload = await _getJson('/metadata/vehicles', query: query);
    final vehicles = _extractVehicleList(payload);
    final meta = _extractPaginationMeta(payload);

    return SearchResponse(
      vehicles: vehicles,
      page: meta.page ?? page,
      limit: meta.limit ?? limit,
      total: meta.total,
    );
  }

  Future<VehicleDetails> fetchVehicleDetails(
    String id, {
    VehicleSummary? fallback,
  }) async {
    final payload = await _getJson('/metadata/car-details/$id');
    return VehicleDetails.fromJson(_extractPrimaryMap(payload), fallback: fallback);
  }

  Future<List<VehicleSummary>> fetchSimilarVehicles(String make) async {
    final payload = await _getJson(
      '/metadata/similar-vehicles',
      query: <String, String>{'make': make},
    );
    return _extractVehicleList(payload);
  }

  Future<dynamic> _getJson(String path, {Map<String, String>? query}) async {
    final uri = _buildUri(path, query: query);
    final request = await _client.getUrl(uri);
    request.headers.set('Accept', 'application/json');
    request.headers.set('ngrok-skip-browser-warning', 'true');

    final response = await request.close();
    final body = await utf8.decodeStream(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Request failed with status ${response.statusCode}',
        uri: uri,
      );
    }

    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    return jsonDecode(body);
  }

  Uri _buildUri(String path, {Map<String, String>? query}) {
    final normalizedPath = path.startsWith('/') || path.isEmpty
        ? path
        : '/$path';
    final baseUri = Uri.parse(AppConfig.baseUrl);
    return baseUri.replace(
      path: '${baseUri.path}$normalizedPath',
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  List<VehicleSummary> _extractVehicleList(dynamic payload) {
    final candidateArrays = <dynamic>[
      payload,
      if (payload is Map) payload['results'],
      if (payload is Map) payload['data'],
      if (payload is Map && payload['data'] is Map) payload['data']['results'],
      if (payload is Map && payload['data'] is Map) payload['data']['data'],
      if (payload is Map) payload['items'],
    ];

    final records = candidateArrays.whereType<List>().firstWhere(
      (items) =>
          items.isNotEmpty ||
          identical(
            items,
            candidateArrays.firstWhere(
              (candidate) => candidate is List,
              orElse: () => const <dynamic>[],
            ),
          ),
      orElse: () => const <dynamic>[],
    );

    final vehicles = <VehicleSummary>[];
    for (var index = 0; index < records.length; index += 1) {
      final item = records[index];
      if (item is! Map) {
        continue;
      }
      vehicles.add(
        VehicleSummary.fromJson(Map<String, dynamic>.from(item), index: index),
      );
    }
    return vehicles;
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _extractPrimaryMap(dynamic payload) {
    final mapPayload = _asMap(payload);
    final nestedData = mapPayload['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }
    if (nestedData is Map) {
      return Map<String, dynamic>.from(nestedData);
    }
    return mapPayload;
  }

  _PaginationMeta _extractPaginationMeta(dynamic payload) {
    final sources = <Map<String, dynamic>>[];
    final mapPayload = _asMap(payload);
    if (mapPayload.isNotEmpty) {
      if (mapPayload['meta'] is Map) {
        sources.add(Map<String, dynamic>.from(mapPayload['meta'] as Map));
      }
      if (mapPayload['pagination'] is Map) {
        sources.add(Map<String, dynamic>.from(mapPayload['pagination'] as Map));
      }
      if (mapPayload['page_info'] is Map) {
        sources.add(Map<String, dynamic>.from(mapPayload['page_info'] as Map));
      }
      final data = mapPayload['data'];
      if (data is Map) {
        if (data['meta'] is Map) {
          sources.add(Map<String, dynamic>.from(data['meta'] as Map));
        }
        if (data['pagination'] is Map) {
          sources.add(Map<String, dynamic>.from(data['pagination'] as Map));
        }
        if (data['page_info'] is Map) {
          sources.add(Map<String, dynamic>.from(data['page_info'] as Map));
        }
      }
      sources.add(mapPayload);
    }

    int? total;
    int? page;
    int? limit;

    for (final source in sources) {
      total ??= _parseInt(
        source['total'] ??
            source['total_results'] ??
            source['total_count'] ??
            source['count'],
      );
      page ??= _parseInt(
        source['current_page'] ??
            source['page'] ??
            source['page_number'] ??
            source['currentPage'],
      );
      limit ??= _parseInt(
        source['per_page'] ??
            source['limit'] ??
            source['page_size'] ??
            source['perPage'],
      );
    }

    return _PaginationMeta(total: total, page: page, limit: limit);
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class _PaginationMeta {
  const _PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
  });

  final int? total;
  final int? page;
  final int? limit;
}
