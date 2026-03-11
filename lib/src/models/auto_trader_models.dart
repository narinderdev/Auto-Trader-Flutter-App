import 'package:flutter/foundation.dart';

class LabeledOption {
  const LabeledOption({required this.label, this.id, this.count});

  final String label;
  final String? id;
  final int? count;

  static List<LabeledOption> parseList(dynamic rawItems) {
    if (rawItems is Map) {
      rawItems =
          rawItems['data'] ??
          rawItems['results'] ??
          rawItems['items'] ??
          rawItems['list'] ??
          rawItems['values'] ??
          rawItems['options'];
    }

    if (rawItems is! List) {
      return const <LabeledOption>[];
    }

    final options = <LabeledOption>[];
    final seen = <String>{};

    for (final item in rawItems) {
      final option = _parse(item);
      if (option == null) {
        continue;
      }
      final key = '${option.id ?? ''}|${option.label.toLowerCase()}';
      if (seen.add(key)) {
        options.add(option);
      }
    }

    options.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return options;
  }

  static LabeledOption? _parse(dynamic item) {
    if (item is String) {
      final label = item.trim();
      return label.isEmpty
          ? null
          : LabeledOption(label: label, id: label);
    }
    if (item is num) {
      final label = item.toString();
      return LabeledOption(label: label, id: label);
    }
    if (item is! Map) {
      return null;
    }

    final label = _pickString(
      item['name'],
      item['label'],
      item['title'],
      item['value'],
      item['make'],
      item['brand'],
      item['display_name'],
      item['displayName'],
      item['code'],
    );

    if (label == null || label.isEmpty) {
      return null;
    }

    final count = _pickInt(
      item['count'],
      item['total'],
      item['total_count'],
      item['totalResults'],
      item['total_results'],
      item['vehicle_count'],
      item['inventory_count'],
    );

    final rawId =
        item['id'] ??
        item['value_id'] ??
        item['identifier'] ??
        item['code'] ??
        item['key'] ??
        item['value'];

    final id = _normalizeString(rawId) ?? label;
    return LabeledOption(label: label, id: id, count: count);
  }
}

const auctionCountryOption = LabeledOption(label: 'Auction');

List<LabeledOption> countryOptionsWithAuction(List<LabeledOption> options) {
  final hasAuction = options.any(
    (option) => option.label.trim().toLowerCase() == 'auction',
  );
  if (hasAuction) {
    return options;
  }
  return [auctionCountryOption, ...options];
}

class NumericRange {
  const NumericRange({required this.min, required this.max});

  final num min;
  final num max;

  static NumericRange? parse(
    Map<String, dynamic>? source, {
    required String rangeKey,
    required String minKey,
    required String maxKey,
  }) {
    if (source == null) {
      return null;
    }

    final explicitRange = source[rangeKey];
    if (explicitRange is List && explicitRange.length >= 2) {
      final minValue = _pickNumber(explicitRange[0]);
      final maxValue = _pickNumber(explicitRange[1]);
      if (minValue != null && maxValue != null) {
        return NumericRange(min: minValue, max: maxValue);
      }
    }

    final minValue = _pickNumber(source[minKey]);
    final maxValue = _pickNumber(source[maxKey]);
    if (minValue != null && maxValue != null) {
      return NumericRange(min: minValue, max: maxValue);
    }

    return null;
  }
}

class FilterMetadata {
  const FilterMetadata({
    required this.makes,
    required this.models,
    required this.countries,
    required this.fuels,
    required this.fromYears,
    required this.toYears,
  });

  final List<LabeledOption> makes;
  final List<LabeledOption> models;
  final List<LabeledOption> countries;
  final List<LabeledOption> fuels;
  final List<int> fromYears;
  final List<int> toYears;

  factory FilterMetadata.fromJson(Map<String, dynamic> json) {
    final source = json['filters'] is Map
        ? Map<String, dynamic>.from(json['filters'] as Map)
        : json;
    return FilterMetadata(
      makes: _firstPopulatedOptions(source, const [
        'makes',
        'popular_makes',
        'popularMakes',
        'make_list',
        'makeList',
        'make',
        'brands',
      ]),
      models: _firstPopulatedOptions(source, const [
        'models',
        'popular_models',
        'popularModels',
        'model_list',
        'modelList',
        'model',
      ]),
      countries: _firstPopulatedOptions(source, const [
        'countries',
        'country_list',
        'countryList',
        'locations',
        'origin_countries',
        'originCountries',
      ]),
      fuels: _firstPopulatedOptions(source, const [
        'fuel_types',
        'fuels',
        'fuel',
      ]),
      fromYears: _parseYearList(source['from_years']),
      toYears: _parseYearList(source['to_years']),
    );
  }

  static const empty = FilterMetadata(
    makes: <LabeledOption>[],
    models: <LabeledOption>[],
    countries: <LabeledOption>[],
    fuels: <LabeledOption>[],
    fromYears: <int>[],
    toYears: <int>[],
  );
}

class VehicleAttributes {
  const VehicleAttributes({
    required this.bodyTypes,
    required this.fuels,
    required this.primaryDamages,
    required this.secondaryDamages,
    required this.engineTypes,
    required this.transmissions,
    required this.drives,
    required this.colors,
    required this.yearRange,
    required this.odometerRange,
    required this.priceRange,
  });

  final List<LabeledOption> bodyTypes;
  final List<LabeledOption> fuels;
  final List<LabeledOption> primaryDamages;
  final List<LabeledOption> secondaryDamages;
  final List<LabeledOption> engineTypes;
  final List<LabeledOption> transmissions;
  final List<LabeledOption> drives;
  final List<LabeledOption> colors;
  final NumericRange? yearRange;
  final NumericRange? odometerRange;
  final NumericRange? priceRange;

  factory VehicleAttributes.fromJson(Map<String, dynamic> json) {
    return VehicleAttributes(
      bodyTypes: _firstPopulatedOptions(json, const [
        'body_styles',
        'bodyTypes',
        'body_types',
      ]),
      fuels: _firstPopulatedOptions(json, const [
        'fuel_types',
        'fuels',
        'fuel',
      ]),
      primaryDamages: _firstPopulatedOptions(json, const [
        'primary_damages',
        'primary_damage',
        'damage_primary',
        'primary_damage_options',
      ]),
      secondaryDamages: _firstPopulatedOptions(json, const [
        'secondary_damages',
        'secondary_damage',
        'damage_secondary',
        'secondary_damage_options',
      ]),
      engineTypes: _firstPopulatedOptions(json, const [
        'engine_types',
        'engine',
        'engines',
      ]),
      transmissions: _firstPopulatedOptions(json, const [
        'transmissions',
        'transmission_types',
      ]),
      drives: _firstPopulatedOptions(json, const ['drives', 'drive_types']),
      colors: _firstPopulatedOptions(json, const [
        'colors',
        'colours',
        'colour_options',
      ]),
      yearRange: NumericRange.parse(
        json,
        rangeKey: 'year_range',
        minKey: 'year_min',
        maxKey: 'year_max',
      ),
      odometerRange: NumericRange.parse(
        json,
        rangeKey: 'odometer_range',
        minKey: 'odometer_min',
        maxKey: 'odometer_max',
      ),
      priceRange: NumericRange.parse(
        json,
        rangeKey: 'price_range',
        minKey: 'price_min',
        maxKey: 'price_max',
      ),
    );
  }

  static const empty = VehicleAttributes(
    bodyTypes: <LabeledOption>[],
    fuels: <LabeledOption>[],
    primaryDamages: <LabeledOption>[],
    secondaryDamages: <LabeledOption>[],
    engineTypes: <LabeledOption>[],
    transmissions: <LabeledOption>[],
    drives: <LabeledOption>[],
    colors: <LabeledOption>[],
    yearRange: null,
    odometerRange: null,
    priceRange: null,
  );
}

class VehicleSearchFilters {
  const VehicleSearchFilters({
    this.query,
    this.make,
    this.model,
    this.bodyType,
    this.fuel,
    this.primaryDamage,
    this.secondaryDamage,
    this.engineType,
    this.transmission,
    this.drive,
    this.color,
    this.country,
    this.priceMin,
    this.priceMax,
    this.yearFrom,
    this.yearTo,
    this.odometerMin,
    this.odometerMax,
  });

  final String? query;
  final LabeledOption? make;
  final LabeledOption? model;
  final LabeledOption? bodyType;
  final LabeledOption? fuel;
  final LabeledOption? primaryDamage;
  final LabeledOption? secondaryDamage;
  final LabeledOption? engineType;
  final LabeledOption? transmission;
  final LabeledOption? drive;
  final LabeledOption? color;
  final LabeledOption? country;
  final int? priceMin;
  final int? priceMax;
  final int? yearFrom;
  final int? yearTo;
  final int? odometerMin;
  final int? odometerMax;

  static const _unset = Object();

  VehicleSearchFilters copyWith({
    Object? query = _unset,
    Object? make = _unset,
    Object? model = _unset,
    Object? bodyType = _unset,
    Object? fuel = _unset,
    Object? primaryDamage = _unset,
    Object? secondaryDamage = _unset,
    Object? engineType = _unset,
    Object? transmission = _unset,
    Object? drive = _unset,
    Object? color = _unset,
    Object? country = _unset,
    Object? priceMin = _unset,
    Object? priceMax = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    Object? odometerMin = _unset,
    Object? odometerMax = _unset,
  }) {
    return VehicleSearchFilters(
      query: identical(query, _unset) ? this.query : query as String?,
      make: identical(make, _unset) ? this.make : make as LabeledOption?,
      model: identical(model, _unset) ? this.model : model as LabeledOption?,
      bodyType: identical(bodyType, _unset)
          ? this.bodyType
          : bodyType as LabeledOption?,
      fuel: identical(fuel, _unset) ? this.fuel : fuel as LabeledOption?,
      primaryDamage: identical(primaryDamage, _unset)
          ? this.primaryDamage
          : primaryDamage as LabeledOption?,
      secondaryDamage: identical(secondaryDamage, _unset)
          ? this.secondaryDamage
          : secondaryDamage as LabeledOption?,
      engineType: identical(engineType, _unset)
          ? this.engineType
          : engineType as LabeledOption?,
      transmission: identical(transmission, _unset)
          ? this.transmission
          : transmission as LabeledOption?,
      drive: identical(drive, _unset) ? this.drive : drive as LabeledOption?,
      color: identical(color, _unset) ? this.color : color as LabeledOption?,
      country: identical(country, _unset)
          ? this.country
          : country as LabeledOption?,
      priceMin: identical(priceMin, _unset) ? this.priceMin : priceMin as int?,
      priceMax: identical(priceMax, _unset) ? this.priceMax : priceMax as int?,
      yearFrom: identical(yearFrom, _unset) ? this.yearFrom : yearFrom as int?,
      yearTo: identical(yearTo, _unset) ? this.yearTo : yearTo as int?,
      odometerMin: identical(odometerMin, _unset)
          ? this.odometerMin
          : odometerMin as int?,
      odometerMax: identical(odometerMax, _unset)
          ? this.odometerMax
          : odometerMax as int?,
    );
  }

  bool get hasActiveValues {
    return (query != null && query!.trim().isNotEmpty) ||
        make != null ||
        model != null ||
        bodyType != null ||
        fuel != null ||
        primaryDamage != null ||
        secondaryDamage != null ||
        engineType != null ||
        transmission != null ||
        drive != null ||
        color != null ||
        country != null ||
        priceMin != null ||
        priceMax != null ||
        yearFrom != null ||
        yearTo != null ||
        odometerMin != null ||
        odometerMax != null;
  }

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    final queryValue = query?.trim();
    if (queryValue != null && queryValue.isNotEmpty) {
      final normalizedQuery = _normalizeSearchValue(queryValue);
      params['q'] = normalizedQuery;
      final vin = _extractVin(normalizedQuery);
      if (vin != null) {
        params['vin'] = vin;
      } else {
        final lot = _extractLot(normalizedQuery);
        if (lot != null) {
          params['lot_number'] = lot;
          params['lot'] = lot;
        }
      }
    }

    _putOption(params, option: make, idKey: 'make_id', fallbackKey: 'make');
    _putOption(params, option: model, idKey: 'model_id', fallbackKey: 'model');
    _putOption(
      params,
      option: bodyType,
      idKey: 'body_style',
      fallbackKey: 'body_style',
    );
    _putOption(
      params,
      option: fuel,
      idKey: 'fuel_type',
      fallbackKey: 'fuel_type',
    );
    _putOption(
      params,
      option: primaryDamage,
      idKey: 'primary_damage',
      fallbackKey: 'primary_damage',
    );
    _putOption(
      params,
      option: secondaryDamage,
      idKey: 'secondary_damage',
      fallbackKey: 'secondary_damage',
    );
    _putOption(
      params,
      option: engineType,
      idKey: 'engine_type',
      fallbackKey: 'engine_type',
    );
    _putOption(
      params,
      option: transmission,
      idKey: 'transmission',
      fallbackKey: 'transmission',
    );
    _putOption(params, option: drive, idKey: 'drive', fallbackKey: 'drive');
    _putOption(params, option: color, idKey: 'color', fallbackKey: 'color');
    _putOption(
      params,
      option: country,
      idKey: 'country_id',
      fallbackKey: 'country',
    );

    if (priceMin != null) {
      params['price_min'] = '$priceMin';
    }
    if (priceMax != null) {
      params['price_max'] = '$priceMax';
    }
    if (yearFrom != null) {
      params['from_year'] = '$yearFrom';
    }
    if (yearTo != null) {
      params['to_year'] = '$yearTo';
    }
    if (odometerMin != null) {
      params['odometer_min'] = '$odometerMin';
    }
    if (odometerMax != null) {
      params['odometer_max'] = '$odometerMax';
    }

    return params;
  }

  static void _putOption(
    Map<String, String> params, {
    required LabeledOption? option,
    required String idKey,
    required String fallbackKey,
  }) {
    if (option == null) {
      return;
    }
    if (option.id != null && option.id!.isNotEmpty) {
      params[idKey] = option.id!;
      return;
    }
    params[fallbackKey] = option.label;
  }
}

class SearchResponse {
  const SearchResponse({
    required this.vehicles,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<VehicleSummary> vehicles;
  final int page;
  final int limit;
  final int? total;
}

class VehicleSummary {
  const VehicleSummary({
    required this.id,
    required this.title,
    required this.image,
    required this.gallery,
    required this.price,
    required this.currency,
    required this.year,
    required this.odometer,
    required this.lotNumber,
    required this.primaryDamage,
    required this.secondaryDamage,
    required this.saleStatus,
    required this.transmission,
    required this.fuel,
    required this.bodyType,
    required this.batteryRange,
    required this.acceleration0100,
    required this.motorPower,
    required this.motorPowerUnit,
    required this.engineType,
    required this.drive,
    required this.color,
    required this.country,
    required this.location,
    required this.make,
    required this.model,
    this.vin = '',
    this.titleCode = '',
    this.cylinders = '',
    this.keys = '',
  });

  final String id;
  final String title;
  final String image;
  final List<String> gallery;
  final num price;
  final String currency;
  final int? year;
  final int? odometer;
  final String lotNumber;
  final String primaryDamage;
  final String secondaryDamage;
  final String saleStatus;
  final String transmission;
  final String fuel;
  final String bodyType;
  final String batteryRange;
  final String acceleration0100;
  final String motorPower;
  final String motorPowerUnit;
  final String engineType;
  final String drive;
  final String color;
  final String country;
  final String location;
  final String make;
  final String model;
  final String vin;
  final String titleCode;
  final String cylinders;
  final String keys;

  VehicleSummary copyWith({
    String? id,
    String? title,
    String? image,
    List<String>? gallery,
    num? price,
    String? currency,
    int? year,
    int? odometer,
    String? lotNumber,
    String? primaryDamage,
    String? secondaryDamage,
    String? saleStatus,
    String? transmission,
    String? fuel,
    String? bodyType,
    String? batteryRange,
    String? acceleration0100,
    String? motorPower,
    String? motorPowerUnit,
    String? engineType,
    String? drive,
    String? color,
    String? country,
    String? location,
    String? make,
    String? model,
    String? vin,
    String? titleCode,
    String? cylinders,
    String? keys,
  }) {
    return VehicleSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      gallery: gallery ?? this.gallery,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      year: year ?? this.year,
      odometer: odometer ?? this.odometer,
      lotNumber: lotNumber ?? this.lotNumber,
      primaryDamage: primaryDamage ?? this.primaryDamage,
      secondaryDamage: secondaryDamage ?? this.secondaryDamage,
      saleStatus: saleStatus ?? this.saleStatus,
      transmission: transmission ?? this.transmission,
      fuel: fuel ?? this.fuel,
      bodyType: bodyType ?? this.bodyType,
      batteryRange: batteryRange ?? this.batteryRange,
      acceleration0100: acceleration0100 ?? this.acceleration0100,
      motorPower: motorPower ?? this.motorPower,
      motorPowerUnit: motorPowerUnit ?? this.motorPowerUnit,
      engineType: engineType ?? this.engineType,
      drive: drive ?? this.drive,
      color: color ?? this.color,
      country: country ?? this.country,
      location: location ?? this.location,
      make: make ?? this.make,
      model: model ?? this.model,
      vin: vin ?? this.vin,
      titleCode: titleCode ?? this.titleCode,
      cylinders: cylinders ?? this.cylinders,
      keys: keys ?? this.keys,
    );
  }

  factory VehicleSummary.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final source = _mergePreferNonEmpty(json, [
      json['vehicle'],
      json['car'],
      json['item'],
      json['result'],
      json['data'],
      json['details'],
      json['title'],
      json['title_info'],
      json['titleDetails'],
    ]);
    final id =
        _pickString(
          source['id'],
          source['vin'],
          source['slug'],
          source['uuid'],
          source['stock_number'],
        ) ??
        'vehicle-$index';
    final make =
        _pickString(
          source['make'],
          source['brand'],
          source['manufacturer'],
        ) ??
        '';
    final model =
        _pickString(
          source['model'],
          source['model_name'],
          source['trim'],
          source['series'],
        ) ??
        '';
    final year = _pickInt(
      source['year'],
      source['model_year'],
      source['production_year'],
    );
    final title =
        _pickString(
          source['title'],
          [make, model].where((value) => value.isNotEmpty).join(' '),
          model,
          make,
        ) ??
        'Vehicle ${index + 1}';

    final gallery = _resolveGallery(source);
    final image = gallery.isEmpty ? '' : gallery.first;
    final price =
        _pickNumber(
          source['price'],
          source['current_price'],
          source['sale_price'],
          source['amount'],
          source['list_price'],
        ) ??
        0;
    final currency =
        _pickString(source['currency'], source['currency_code']) ?? 'USD';
    final odometer = _pickInt(
      source['odometer'],
      source['mileage'],
      source['kilometers'],
      source['kilometres'],
      source['km'],
      source['odometer_km'],
      source['odometer_miles'],
    );
    final documentInfo = source['document_info'];
    var lotNumber =
        _firstNonEmptyString([
          source['lot_number'],
          source['lotNumber'],
          source['lot'],
          source['lot_id'],
          source['lotId'],
          source['stock_number'],
          source['lot_no'],
          source['lotNo'],
          source['lot_number_text'],
          source['lotNumberText'],
          source['auction_lot'],
          source['auctionLot'],
          source['auction_lot_number'],
          source['auctionLotNumber'],
          documentInfo is Map ? documentInfo['lot_number'] : null,
          documentInfo is Map ? documentInfo['lotNumber'] : null,
          documentInfo is Map ? documentInfo['lot'] : null,
          documentInfo is Map ? documentInfo['lot_id'] : null,
          documentInfo is Map ? documentInfo['lotNo'] : null,
        ]) ??
        '';
    if (lotNumber.isEmpty) {
      lotNumber =
          _extractLongNumber(
            documentInfo is Map ? documentInfo['info'] : null,
          ) ??
          _extractLongNumber(source['title']) ??
          '';
    }
    final vin =
        _pickString(
          source['vin'],
          source['vin_number'],
          source['vinNumber'],
          source['vehicle_vin'],
          source['vehicleVin'],
        ) ??
        '';
    final titleCode =
        _pickString(
          source['title_code'],
          source['titleCode'],
          source['title_code_desc'],
          source['title_status'],
          source['title_type'],
          source['titleType'],
        ) ??
        '';
    final cylinders =
        _pickString(
          source['cylinders'],
          source['cylinders_count'],
          source['cylinder_count'],
          source['engine_cylinders'],
          source['engineCylinders'],
        ) ??
        '';
    final keys = _pickString(
          source['keys'],
          source['keys_status'],
          source['key_status'],
          source['keysStatus'],
        ) ??
        _pickYesNo(
          source['has_keys'],
          source['keys_present'],
          source['keysPresent'],
        ) ??
        '';
    final primaryDamage =
        _pickString(
          source['primary_damage'],
          source['primaryDamage'],
          source['damage_primary'],
          source['primary_damage_desc'],
          source['primary_damage_type'],
          source['primaryDamageType'],
        ) ??
        '';
    final secondaryDamage =
        _pickString(
          source['secondary_damage'],
          source['secondaryDamage'],
          source['damage_secondary'],
          source['secondary_damage_desc'],
          source['secondary_damage_type'],
          source['secondaryDamageType'],
        ) ??
        '';
    final saleStatus =
        _pickString(
          source['sale_status'],
          source['saleStatus'],
          source['status'],
          source['auction_status'],
        ) ??
        '';
    final location =
        _pickString(
          source['location'],
          _combineLocation(source['city'], source['country']),
          source['country_name'],
          source['countryName'],
        ) ??
        '';
    final country =
        _pickString(
          source['country'],
          source['country_name'],
          source['countryName'],
          _extractCountry(location),
        ) ??
        '';

    _debugLogVehicleFields(
      'VehicleSummary',
      json: json,
      source: source,
      raws: {
        'title_code': source['title_code'],
        'titleCode': source['titleCode'],
        'primary_damage': source['primary_damage'],
        'primaryDamage': source['primaryDamage'],
        'secondary_damage': source['secondary_damage'],
        'secondaryDamage': source['secondaryDamage'],
        'cylinders': source['cylinders'],
        'keys': source['keys'],
      },
      values: {
        'vin': vin,
        'odometer': odometer,
        'titleCode': titleCode,
        'primaryDamage': primaryDamage,
        'secondaryDamage': secondaryDamage,
        'cylinders': cylinders,
        'keys': keys,
      },
    );

    return VehicleSummary(
      id: id,
      title: title,
      image: image,
      gallery: gallery,
      price: price,
      currency: currency,
      year: year,
      odometer: odometer,
      lotNumber: lotNumber,
      primaryDamage: primaryDamage,
      secondaryDamage: secondaryDamage,
      saleStatus: saleStatus,
      transmission:
          _pickString(
            source['transmission'],
            source['transmission_type'],
            source['gearbox'],
          ) ??
          '',
      fuel:
          _pickString(
            source['fuel'],
            source['fuel_type'],
            source['engine_type'],
            source['energy_type'],
            source['powertrain'],
          ) ??
          '',
      bodyType:
          _pickString(
            source['bodyType'],
            source['body_type'],
            source['body_style'],
          ) ??
          '',
      batteryRange:
          _pickString(
            source['batteryRange'],
            source['battery_range'],
            source['range_km'],
            source['range'],
            source['electric_range'],
          ) ??
          '',
      acceleration0100:
          _pickString(
            source['acceleration0100'],
            source['acceleration_0_100'],
            source['acceleration-0-100'],
            source['zero_to_hundred'],
            source['acceleration'],
          ) ??
          '',
      motorPower:
          _pickString(
            source['motorPower'],
            source['motor_power'],
            source['engine_power'],
            source['power_kw'],
            source['horsepower'],
          ) ??
          '',
      motorPowerUnit:
          _pickString(
            source['motorPowerUnit'],
            source['motor_power_unit'],
            source['engine_power_unit'],
            source['power_unit'],
          ) ??
          '',
      engineType:
          _pickString(
            source['engineType'],
            source['engine_type'],
            source['motor_type'],
            source['engineLayout'],
            source['engine_layout'],
            source['motor_kind'],
          ) ??
          '',
      drive:
          _pickString(
            source['drive'],
            source['drive_type'],
            source['drivetrain'],
            source['wheel_drive'],
            source['driveTrain'],
          ) ??
          '',
      color:
          _pickString(
            source['color'],
            source['colour'],
            source['paint_color'],
            source['paint'],
            source['exterior_color'],
          ) ??
          '',
      country: country,
      location: location,
      make: make,
      model: model,
      vin: vin,
      titleCode: titleCode,
      cylinders: cylinders,
      keys: keys,
    );
  }
}

class VehicleDetails {
  const VehicleDetails({
    required this.id,
    required this.title,
    required this.make,
    required this.model,
    required this.year,
    required this.price,
    required this.currency,
    required this.odometer,
    this.lotNumber = '',
    this.primaryDamage = '',
    this.secondaryDamage = '',
    this.saleStatus = '',
    this.saleDate = '',
    this.timeLeft = '',
    this.currentBid,
    this.buyNow,
    this.estimatedRetailValue,
    this.lastUpdated = '',
    this.titleCode = '',
    this.cylinders = '',
    this.keys = '',
    required this.transmission,
    required this.fuel,
    required this.bodyType,
    required this.color,
    required this.drive,
    required this.engineType,
    required this.engine,
    required this.country,
    required this.condition,
    required this.vin,
    required this.location,
    required this.image,
    required this.gallery,
    required this.highlights,
    required this.description,
    required this.badges,
  });

  final String id;
  final String title;
  final String make;
  final String model;
  final int? year;
  final num price;
  final String currency;
  final int? odometer;
  final String lotNumber;
  final String primaryDamage;
  final String secondaryDamage;
  final String saleStatus;
  final String saleDate;
  final String timeLeft;
  final num? currentBid;
  final num? buyNow;
  final num? estimatedRetailValue;
  final String lastUpdated;
  final String titleCode;
  final String cylinders;
  final String keys;
  final String transmission;
  final String fuel;
  final String bodyType;
  final String color;
  final String drive;
  final String engineType;
  final String engine;
  final String country;
  final String condition;
  final String vin;
  final String location;
  final String image;
  final List<String> gallery;
  final List<String> highlights;
  final String description;
  final List<String> badges;

  factory VehicleDetails.fromJson(
    Map<String, dynamic> json, {
    VehicleSummary? fallback,
  }) {
    final source = _mergePreferNonEmpty(json, [
      json['vehicle'],
      json['car'],
      json['item'],
      json['result'],
      json['data'],
      json['details'],
      json['title'],
      json['title_info'],
      json['titleDetails'],
    ]);
    final baseImage = fallback?.image ?? '';
    final gallery = _resolveGallery(source, fallbackImage: baseImage);
    final location =
        _pickString(
          source['location'],
          _combineLocation(source['city'], source['country']),
          source['country'],
          fallback?.location,
        ) ??
        '';

    final highlights = <String>[];
    final features = source['features'];
    if (features is List) {
      for (final item in features) {
        final value = _normalizeString(item);
        if (value != null) {
          highlights.add(value);
        }
      }
    }

    final descriptionPairs = _extractDescriptionPairs(
      source['description_pairs'] ?? source['details'] ?? source['documents'],
    );

    final badges = <String>[];
    final rawBadges = source['labels'];
    if (rawBadges is List) {
      for (final item in rawBadges) {
        final value = _normalizeString(item);
        if (value != null) {
          badges.add(value);
        }
      }
    }

    _debugLogVehicleFields(
      'VehicleDetails',
      json: json,
      source: source,
      pairs: descriptionPairs,
      raws: {
        'title_code': source['title_code'],
        'titleCode': source['titleCode'],
        'primary_damage': source['primary_damage'],
        'primaryDamage': source['primaryDamage'],
        'secondary_damage': source['secondary_damage'],
        'secondaryDamage': source['secondaryDamage'],
        'cylinders': source['cylinders'],
        'keys': source['keys'],
        'documents': source['documents'],
        'description_pairs': source['description_pairs'],
      },
      values: {
        'vin': _pickString(
          source['vin'],
          source['vin_number'],
          source['vinNumber'],
          source['vehicle_vin'],
          source['vehicleVin'],
          fallback?.vin,
        ),
        'odometer': _pickInt(
          source['odometer'],
          source['mileage'],
          source['kilometers'],
          source['kilometres'],
          source['km'],
          source['odometer_km'],
          source['odometer_miles'],
          fallback?.odometer,
        ),
        'titleCode': _pickString(
          source['title_code'],
          source['titleCode'],
          source['title_code_desc'],
          source['title_status'],
          source['title_type'],
          source['titleType'],
        ),
        'primaryDamage': _pickString(
          source['primary_damage'],
          source['primaryDamage'],
          source['damage_primary'],
          source['primary_damage_desc'],
          source['primary_damage_type'],
          source['primaryDamageType'],
          fallback?.primaryDamage,
        ),
        'secondaryDamage': _pickString(
          source['secondary_damage'],
          source['secondaryDamage'],
          source['damage_secondary'],
          source['secondary_damage_desc'],
          source['secondary_damage_type'],
          source['secondaryDamageType'],
          fallback?.secondaryDamage,
        ),
        'cylinders': _pickString(
          source['cylinders'],
          source['cylinders_count'],
          source['cylinder_count'],
          source['engine_cylinders'],
          source['engineCylinders'],
        ),
        'keys': _pickString(
          source['keys'],
          source['keys_status'],
          source['key_status'],
          source['keysStatus'],
        ),
      },
    );

    return VehicleDetails(
      id: _pickString(source['id'], source['vin'], fallback?.id) ?? '',
      title:
          _pickString(
            source['title'],
            '${_pickString(source['year']) ?? fallback?.year ?? ''} ${_pickString(source['make']) ?? fallback?.make ?? ''} ${_pickString(source['model']) ?? fallback?.model ?? ''}'
                .trim(),
            fallback?.title,
          ) ??
          'Vehicle',
      make: _pickString(source['make'], fallback?.make) ?? '',
      model: _pickString(source['model'], fallback?.model) ?? '',
      year: _pickInt(source['year'], fallback?.year),
      price: _pickNumber(source['price'], fallback?.price) ?? 0,
      currency:
          _pickString(
            source['currency_code'],
            source['currency'],
            fallback?.currency,
          ) ??
          'USD',
      odometer: _pickInt(
        source['odometer'],
        source['mileage'],
        source['kilometers'],
        source['kilometres'],
        source['km'],
        source['odometer_km'],
        source['odometer_miles'],
        fallback?.odometer,
      ),
      lotNumber:
          _pickString(
            source['lot_number'],
            source['lotNumber'],
            source['lot'],
            source['lot_id'],
            source['lotId'],
            fallback?.lotNumber,
          ) ??
          '',
      primaryDamage:
          _pickString(
            source['primary_damage'],
            source['primaryDamage'],
            source['damage_primary'],
            source['primary_damage_desc'],
            source['primary_damage_type'],
            source['primaryDamageType'],
            _pairValue(descriptionPairs, const [
              'primarydamage',
              'primary_damage',
              'primarydamagetype',
              'primary_damage_type',
              'primarydamagedesc',
              'primary_damage_desc',
            ]),
            fallback?.primaryDamage,
          ) ??
          '',
      secondaryDamage:
          _pickString(
            source['secondary_damage'],
            source['secondaryDamage'],
            source['damage_secondary'],
            source['secondary_damage_desc'],
            source['secondary_damage_type'],
            source['secondaryDamageType'],
            _pairValue(descriptionPairs, const [
              'secondarydamage',
              'secondary_damage',
              'secondarydamagetype',
              'secondary_damage_type',
              'secondarydamagedesc',
              'secondary_damage_desc',
            ]),
            fallback?.secondaryDamage,
          ) ??
          '',
      saleStatus:
          _pickString(
            source['sale_status'],
            source['saleStatus'],
            source['status'],
            source['auction_status'],
          ) ??
          '',
      saleDate:
          _pickString(
            source['sale_date'],
            source['saleDate'],
            source['auction_date'],
            source['auctionDate'],
          ) ??
          '',
      timeLeft:
          _pickString(
            source['time_left'],
            source['timeLeft'],
            source['time_remaining'],
          ) ??
          '',
      currentBid:
          _pickNumber(
            source['current_bid'],
            source['currentBid'],
            source['bid_amount'],
          ),
      buyNow:
          _pickNumber(
            source['buy_now'],
            source['buyNow'],
            source['buy_now_price'],
          ),
      estimatedRetailValue:
          _pickNumber(
            source['estimated_retail_value'],
            source['estimatedRetailValue'],
          ),
      lastUpdated:
          _pickString(
            source['last_updated'],
            source['lastUpdated'],
            source['updated_at'],
          ) ??
          '',
      titleCode:
          _pickString(
            source['title_code'],
            source['titleCode'],
            source['title_code_desc'],
            source['title_status'],
            source['title_type'],
            source['titleType'],
            _pairValue(descriptionPairs, const [
              'titlecode',
              'title_code',
              'titlestatus',
              'title_status',
              'titletype',
              'title_type',
            ]),
          ) ??
          '',
      cylinders:
          _pickString(
            source['cylinders'],
            source['cylinders_count'],
            source['cylinder_count'],
            source['engine_cylinders'],
            source['engineCylinders'],
            _pairValue(descriptionPairs, const [
              'cylinders',
              'cylinderscount',
              'cylindercount',
              'enginecylinders',
            ]),
          ) ??
          '',
      keys:
          _pickString(
            source['keys'],
            source['keys_status'],
            source['key_status'],
            source['keysStatus'],
            _pairValue(descriptionPairs, const [
              'keys',
              'keysstatus',
              'key_status',
              'keystatus',
            ]),
          ) ??
          _pickYesNo(
            source['has_keys'],
            source['keys_present'],
            source['keysPresent'],
          ) ??
          _pairValue(descriptionPairs, const [
            'haskeys',
            'keys_present',
            'keyspresent',
          ]) ??
          '',
      transmission:
          _pickString(source['transmission'], fallback?.transmission) ?? '',
      fuel: _pickString(source['fuel'], fallback?.fuel) ?? '',
      bodyType:
          _pickString(
            source['body_style'],
            source['bodyType'],
            fallback?.bodyType,
          ) ??
          '',
      color: _pickString(source['color'], fallback?.color) ?? '',
      drive:
          _pickString(
            source['drive'],
            source['drive_type'],
            fallback?.drive,
          ) ??
          '',
      engineType: _pickString(source['engine_type'], fallback?.engineType) ?? '',
      engine:
          _pickString(
            source['engine'],
            source['engine_description'],
            source['engine_type'],
            fallback?.engineType,
          ) ??
          '',
      country: _pickString(source['country'], fallback?.country) ?? '',
      condition: _pickString(source['status'], source['condition']) ?? '',
      vin:
          _pickString(
            source['vin'],
            source['vin_number'],
            source['vinNumber'],
            source['vehicle_vin'],
            source['vehicleVin'],
            fallback?.vin,
          ) ??
          '',
      location: location,
      image: gallery.isEmpty ? baseImage : gallery.first,
      gallery: gallery,
      highlights: highlights,
      description: _pickString(source['description']) ?? '',
      badges: badges,
    );
  }
}

List<LabeledOption> _firstPopulatedOptions(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final options = LabeledOption.parseList(json[key]);
    if (options.isNotEmpty) {
      return options;
    }
  }
  return const <LabeledOption>[];
}

List<int> _parseYearList(dynamic rawItems) {
  if (rawItems is! List) {
    return const <int>[];
  }

  final years = <int>{};
  final currentYear = DateTime.now().year;
  const minAllowedYear = 1900;
  final maxAllowedYear = currentYear + 1;

  for (final item in rawItems) {
    final year = _pickInt(item);
    if (year != null && year >= minAllowedYear && year <= maxAllowedYear) {
      years.add(year);
    }
  }

  if (years.isEmpty) {
    return const <int>[];
  }

  final maxYear = years.reduce((a, b) => a > b ? a : b);
  final minYear = years.reduce((a, b) => a < b ? a : b);
  return [for (var year = maxYear; year >= minYear; year -= 1) year];
}

List<String> _resolveGallery(
  Map<String, dynamic> json, {
  String? fallbackImage,
}) {
  final images = <String>{};

  void addCandidate(dynamic value) {
    final normalized = _normalizeString(value);
    if (normalized != null) {
      images.add(normalized);
    }
  }

  final image = json['image'];
  if (image is String) {
    addCandidate(image);
  } else if (image is Map) {
    addCandidate(image['image_url']);
    addCandidate(image['imagePath']);
    addCandidate(image['image_path']);
    addCandidate(image['url']);
    addCandidate(image['path']);
  }

  addCandidate(json['image_url']);
  addCandidate(json['cover_image']);
  addCandidate(json['thumbnail']);

  final imagesList = json['images'];
  if (imagesList is List) {
    for (final item in imagesList) {
      if (item is String) {
        addCandidate(item);
        continue;
      }
      if (item is! Map) {
        continue;
      }
      addCandidate(item['image_url']);
      addCandidate(item['url']);
      addCandidate(item['path']);
      addCandidate(item['image_path']);
    }
  }

  final mediaGallery = json['media_gallery'];
  if (mediaGallery is List) {
    for (final item in mediaGallery) {
      if (item is String) {
        addCandidate(item);
        continue;
      }
      if (item is! Map) {
        continue;
      }
      addCandidate(item['image_url']);
      addCandidate(item['url']);
      addCandidate(item['path']);
      addCandidate(item['image_path']);
    }
  }

  addCandidate(fallbackImage);

  return images.toList();
}

String? _pickString([
  dynamic value1,
  dynamic value2,
  dynamic value3,
  dynamic value4,
  dynamic value5,
  dynamic value6,
  dynamic value7,
  dynamic value8,
  dynamic value9,
]) {
  final values = [
    value1,
    value2,
    value3,
    value4,
    value5,
    value6,
    value7,
    value8,
    value9,
  ];
  for (final value in values) {
    final normalized = _normalizeString(value);
    if (normalized != null) {
      return normalized;
    }
  }
  return null;
}

String? _normalizeString(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num) {
    return value.toString();
  }
  if (value is Map) {
    return _pickString(
      value['value'],
      value['label'],
      value['name'],
      value['title'],
      value['code'],
      value['description'],
      value['desc'],
      value['display_name'],
      value['displayName'],
    );
  }
  return null;
}

void _debugLogVehicleFields(
  String label, {
  required Map<String, dynamic> json,
  required Map<String, dynamic> source,
  required Map<String, Object?> values,
  Map<String, String>? pairs,
  Map<String, Object?>? raws,
}) {
  if (!kDebugMode) {
    return;
  }
  final missing = values.entries
      .where((entry) => !_hasValue(entry.value))
      .map((entry) => entry.key)
      .toList();
  if (missing.isEmpty) {
    return;
  }
  debugPrint('$label missing fields: ${missing.join(', ')}');
  debugPrint(
    '$label source keys: ${source.keys.take(40).join(', ')}',
  );
  debugPrint(
    '$label raw keys: ${json.keys.take(40).join(', ')}',
  );
  if (pairs != null && pairs.isNotEmpty) {
    debugPrint(
      '$label description_pairs keys: ${pairs.keys.take(40).join(', ')}',
    );
  }
  if (raws != null && raws.isNotEmpty) {
    raws.forEach((key, value) {
      if (value == null) return;
      debugPrint('$label raw $key: $value');
    });
  }
}

bool _hasValue(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is String) {
    return value.trim().isNotEmpty;
  }
  if (value is Map) {
    return value.isNotEmpty;
  }
  if (value is Iterable) {
    return value.isNotEmpty;
  }
  return true;
}

Map<String, dynamic> _mergePreferNonEmpty(
  Map<String, dynamic> base,
  List<dynamic> candidates,
) {
  final merged = Map<String, dynamic>.from(base);
  for (final candidate in candidates) {
    if (candidate is! Map) {
      continue;
    }
    candidate.forEach((key, value) {
      if (!_hasValue(merged[key]) && _hasValue(value)) {
        merged[key.toString()] = value;
      }
    });
  }
  return merged;
}

String? _pickYesNo([
  dynamic value1,
  dynamic value2,
  dynamic value3,
]) {
  final values = [value1, value2, value3];
  for (final value in values) {
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    if (value is num) {
      if (value == 0) {
        return 'No';
      }
      return 'Yes';
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      if (normalized == 'yes' ||
          normalized == 'y' ||
          normalized == 'true' ||
          normalized == '1') {
        return 'Yes';
      }
      if (normalized == 'no' ||
          normalized == 'n' ||
          normalized == 'false' ||
          normalized == '0') {
        return 'No';
      }
      return value.trim();
    }
  }
  return null;
}

Map<String, String> _extractDescriptionPairs(dynamic raw) {
  final result = <String, String>{};

  dynamic resolved = raw;
  if (resolved is Map) {
    final nested =
        resolved['data'] ??
        resolved['items'] ??
        resolved['list'] ??
        resolved['pairs'] ??
        resolved['documents'] ??
        resolved['details'] ??
        resolved['description_pairs'];
    if (nested is List) {
      resolved = nested;
    }
  }

  if (resolved is List) {
    for (final item in resolved) {
      if (item is Map) {
        final key = _pickString(
          item['label'],
          item['name'],
          item['key'],
          item['title'],
          item['field'],
        );
        final value = _pickString(
          item['value'],
          item['text'],
          item['description'],
          item['data'],
          item['content'],
          item['detail'],
          item['details'],
          item['info'],
          item['value_text'] ?? item['valueText'],
        );
        if (key == null || value == null) {
          continue;
        }
        result[_normalizePairKey(key)] = value;
        continue;
      }

      if (item is List && item.length >= 2) {
        final key = _normalizeString(item[0]);
        final value = _normalizeString(item[1]);
        if (key != null && value != null) {
          result[_normalizePairKey(key)] = value;
        }
        continue;
      }

      if (item is String) {
        final rawText = item.trim();
        if (rawText.isEmpty) {
          continue;
        }
        String? key;
        String? value;
        final colonParts = rawText.split(':');
        if (colonParts.length >= 2) {
          key = colonParts.first.trim();
          value = colonParts.sublist(1).join(':').trim();
        } else {
          final dashParts = rawText.split(' - ');
          if (dashParts.length >= 2) {
            key = dashParts.first.trim();
            value = dashParts.sublist(1).join(' - ').trim();
          }
        }
        if (key != null && value != null && key.isNotEmpty && value.isNotEmpty) {
          result[_normalizePairKey(key)] = value;
        }
      }
    }
    return result;
  }

  if (resolved is Map) {
    resolved.forEach((key, value) {
      final normalizedKey = _normalizePairKey(key.toString());
      final normalizedValue = _normalizeString(value);
      if (normalizedValue != null) {
        result[normalizedKey] = normalizedValue;
      }
    });
  }
  return result;
}

String? _pairValue(Map<String, String> pairs, List<String> keys) {
  for (final key in keys) {
    final normalizedKey = _normalizePairKey(key);
    final value = pairs[normalizedKey];
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

String _normalizePairKey(String key) {
  final buffer = StringBuffer();
  for (final rune in key.runes) {
    final char = String.fromCharCode(rune);
    final lower = char.toLowerCase();
    final isAlphaNum =
        (lower.codeUnitAt(0) >= 97 && lower.codeUnitAt(0) <= 122) ||
        (lower.codeUnitAt(0) >= 48 && lower.codeUnitAt(0) <= 57);
    if (isAlphaNum) {
      buffer.write(lower);
    }
  }
  return buffer.toString();
}

String _normalizeSearchValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final vin = _extractVin(trimmed);
  if (vin != null) {
    return vin;
  }
  final lot = _extractLot(trimmed);
  if (lot != null) {
    return lot;
  }
  return trimmed.replaceAll(RegExp(r'\s+'), ' ');
}

String? _extractVin(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (cleaned.length != 17) {
    return null;
  }
  return cleaned.toUpperCase();
}

String? _extractLot(String raw) {
  final hasLetters = RegExp(r'[A-Za-z]').hasMatch(raw);
  final hasLotWord = RegExp(r'\blot\b', caseSensitive: false).hasMatch(raw);
  if (hasLetters && !hasLotWord) {
    return null;
  }
  final match = RegExp(r'\d{5,}').firstMatch(raw);
  if (match == null) {
    return null;
  }
  return match.group(0);
}

num? _pickNumber([
  dynamic value1,
  dynamic value2,
  dynamic value3,
  dynamic value4,
  dynamic value5,
  dynamic value6,
  dynamic value7,
  dynamic value8,
]) {
  final values = [
    value1,
    value2,
    value3,
    value4,
    value5,
    value6,
    value7,
    value8,
  ];
  for (final value in values) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

int? _pickInt([
  dynamic value1,
  dynamic value2,
  dynamic value3,
  dynamic value4,
  dynamic value5,
  dynamic value6,
  dynamic value7,
  dynamic value8,
]) {
  final number = _pickNumber(
    value1,
    value2,
    value3,
    value4,
    value5,
    value6,
    value7,
    value8,
  );
  return number?.round();
}

String? _extractLongNumber(dynamic value) {
  if (value is num) {
    final asInt = value.round().toString();
    return asInt.length >= 5 ? asInt : null;
  }
  if (value is String) {
    final match = RegExp(r'\d{5,}').firstMatch(value);
    return match?.group(0);
  }
  return null;
}

String? _firstNonEmptyString(Iterable<dynamic> values) {
  for (final value in values) {
    final normalized = _normalizeString(value);
    if (normalized != null) {
      return normalized;
    }
  }
  return null;
}

String _combineLocation(dynamic city, dynamic country) {
  final cityText = _normalizeString(city);
  final countryText = _normalizeString(country);
  if (cityText != null && countryText != null) {
    return '$cityText, $countryText';
  }
  return cityText ?? countryText ?? '';
}

String _extractCountry(String location) {
  if (location.isEmpty) {
    return '';
  }
  final parts = location.split(',');
  return parts.last.trim();
}
