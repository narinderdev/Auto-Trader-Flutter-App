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
    return make != null ||
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
    );
  }

  factory VehicleSummary.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final id =
        _pickString(
          json['id'],
          json['vin'],
          json['slug'],
          json['uuid'],
          json['stock_number'],
        ) ??
        'vehicle-$index';
    final make =
        _pickString(json['make'], json['brand'], json['manufacturer']) ?? '';
    final model =
        _pickString(
          json['model'],
          json['model_name'],
          json['trim'],
          json['series'],
        ) ??
        '';
    final year = _pickInt(
      json['year'],
      json['model_year'],
      json['production_year'],
    );
    final title =
        _pickString(
          json['title'],
          [make, model].where((value) => value.isNotEmpty).join(' '),
          model,
          make,
        ) ??
        'Vehicle ${index + 1}';

    final gallery = _resolveGallery(json);
    final image = gallery.isEmpty ? '' : gallery.first;
    final price =
        _pickNumber(
          json['price'],
          json['current_price'],
          json['sale_price'],
          json['amount'],
          json['list_price'],
        ) ??
        0;
    final currency =
        _pickString(json['currency'], json['currency_code']) ?? 'USD';
    final odometer = _pickInt(
      json['odometer'],
      json['mileage'],
      json['kilometers'],
      json['kilometres'],
      json['km'],
      json['odometer_km'],
    );
    final lotNumber =
        _pickString(
          json['lot_number'],
          json['lotNumber'],
          json['lot'],
          json['lot_id'],
          json['lotId'],
          json['stock_number'],
        ) ??
        '';
    final primaryDamage =
        _pickString(
          json['primary_damage'],
          json['primaryDamage'],
          json['damage_primary'],
          json['primary_damage_desc'],
        ) ??
        '';
    final secondaryDamage =
        _pickString(
          json['secondary_damage'],
          json['secondaryDamage'],
          json['damage_secondary'],
          json['secondary_damage_desc'],
        ) ??
        '';
    final saleStatus =
        _pickString(
          json['sale_status'],
          json['saleStatus'],
          json['status'],
          json['auction_status'],
        ) ??
        '';
    final location =
        _pickString(
          json['location'],
          _combineLocation(json['city'], json['country']),
          json['country_name'],
          json['countryName'],
        ) ??
        '';
    final country =
        _pickString(
          json['country'],
          json['country_name'],
          json['countryName'],
          _extractCountry(location),
        ) ??
        '';

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
            json['transmission'],
            json['transmission_type'],
            json['gearbox'],
          ) ??
          '',
      fuel:
          _pickString(
            json['fuel'],
            json['fuel_type'],
            json['engine_type'],
            json['energy_type'],
            json['powertrain'],
          ) ??
          '',
      bodyType:
          _pickString(
            json['bodyType'],
            json['body_type'],
            json['body_style'],
          ) ??
          '',
      batteryRange:
          _pickString(
            json['batteryRange'],
            json['battery_range'],
            json['range_km'],
            json['range'],
            json['electric_range'],
          ) ??
          '',
      acceleration0100:
          _pickString(
            json['acceleration0100'],
            json['acceleration_0_100'],
            json['acceleration-0-100'],
            json['zero_to_hundred'],
            json['acceleration'],
          ) ??
          '',
      motorPower:
          _pickString(
            json['motorPower'],
            json['motor_power'],
            json['engine_power'],
            json['power_kw'],
            json['horsepower'],
          ) ??
          '',
      motorPowerUnit:
          _pickString(
            json['motorPowerUnit'],
            json['motor_power_unit'],
            json['engine_power_unit'],
            json['power_unit'],
          ) ??
          '',
      engineType:
          _pickString(
            json['engineType'],
            json['engine_type'],
            json['motor_type'],
            json['engineLayout'],
            json['engine_layout'],
            json['motor_kind'],
          ) ??
          '',
      drive:
          _pickString(
            json['drive'],
            json['drive_type'],
            json['drivetrain'],
            json['wheel_drive'],
            json['driveTrain'],
          ) ??
          '',
      color:
          _pickString(
            json['color'],
            json['colour'],
            json['paint_color'],
            json['paint'],
            json['exterior_color'],
          ) ??
          '',
      country: country,
      location: location,
      make: make,
      model: model,
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
    final baseImage = fallback?.image ?? '';
    final gallery = _resolveGallery(json, fallbackImage: baseImage);
    final location =
        _pickString(
          json['location'],
          _combineLocation(json['city'], json['country']),
          json['country'],
          fallback?.location,
        ) ??
        '';

    final highlights = <String>[];
    final features = json['features'];
    if (features is List) {
      for (final item in features) {
        final value = _normalizeString(item);
        if (value != null) {
          highlights.add(value);
        }
      }
    }

    final badges = <String>[];
    final rawBadges = json['labels'];
    if (rawBadges is List) {
      for (final item in rawBadges) {
        final value = _normalizeString(item);
        if (value != null) {
          badges.add(value);
        }
      }
    }

    return VehicleDetails(
      id: _pickString(json['id'], json['vin'], fallback?.id) ?? '',
      title:
          _pickString(
            json['title'],
            '${_pickString(json['year']) ?? fallback?.year ?? ''} ${_pickString(json['make']) ?? fallback?.make ?? ''} ${_pickString(json['model']) ?? fallback?.model ?? ''}'
                .trim(),
            fallback?.title,
          ) ??
          'Vehicle',
      make: _pickString(json['make'], fallback?.make) ?? '',
      model: _pickString(json['model'], fallback?.model) ?? '',
      year: _pickInt(json['year'], fallback?.year),
      price: _pickNumber(json['price'], fallback?.price) ?? 0,
      currency:
          _pickString(
            json['currency_code'],
            json['currency'],
            fallback?.currency,
          ) ??
          'USD',
      odometer: _pickInt(json['odometer'], fallback?.odometer),
      lotNumber:
          _pickString(
            json['lot_number'],
            json['lotNumber'],
            json['lot'],
            json['lot_id'],
            json['lotId'],
            fallback?.lotNumber,
          ) ??
          '',
      primaryDamage:
          _pickString(
            json['primary_damage'],
            json['primaryDamage'],
            json['damage_primary'],
            json['primary_damage_desc'],
            fallback?.primaryDamage,
          ) ??
          '',
      secondaryDamage:
          _pickString(
            json['secondary_damage'],
            json['secondaryDamage'],
            json['damage_secondary'],
            json['secondary_damage_desc'],
            fallback?.secondaryDamage,
          ) ??
          '',
      saleStatus:
          _pickString(
            json['sale_status'],
            json['saleStatus'],
            json['status'],
            json['auction_status'],
          ) ??
          '',
      saleDate:
          _pickString(
            json['sale_date'],
            json['saleDate'],
            json['auction_date'],
            json['auctionDate'],
          ) ??
          '',
      timeLeft:
          _pickString(
            json['time_left'],
            json['timeLeft'],
            json['time_remaining'],
          ) ??
          '',
      currentBid:
          _pickNumber(
            json['current_bid'],
            json['currentBid'],
            json['bid_amount'],
          ),
      buyNow:
          _pickNumber(
            json['buy_now'],
            json['buyNow'],
            json['buy_now_price'],
          ),
      estimatedRetailValue:
          _pickNumber(
            json['estimated_retail_value'],
            json['estimatedRetailValue'],
          ),
      lastUpdated:
          _pickString(
            json['last_updated'],
            json['lastUpdated'],
            json['updated_at'],
          ) ??
          '',
      titleCode:
          _pickString(
            json['title_code'],
            json['titleCode'],
          ) ??
          '',
      cylinders:
          _pickString(
            json['cylinders'],
            json['cylinders_count'],
          ) ??
          '',
      keys:
          _pickString(
            json['keys'],
            json['keys_status'],
          ) ??
          '',
      transmission:
          _pickString(json['transmission'], fallback?.transmission) ?? '',
      fuel: _pickString(json['fuel'], fallback?.fuel) ?? '',
      bodyType:
          _pickString(
            json['body_style'],
            json['bodyType'],
            fallback?.bodyType,
          ) ??
          '',
      color: _pickString(json['color'], fallback?.color) ?? '',
      drive:
          _pickString(json['drive'], json['drive_type'], fallback?.drive) ?? '',
      engineType: _pickString(json['engine_type'], fallback?.engineType) ?? '',
      engine:
          _pickString(
            json['engine'],
            json['engine_description'],
            json['engine_type'],
            fallback?.engineType,
          ) ??
          '',
      country: _pickString(json['country'], fallback?.country) ?? '',
      condition: _pickString(json['status'], json['condition']) ?? '',
      vin: _pickString(json['vin']) ?? '',
      location: location,
      image: gallery.isEmpty ? baseImage : gallery.first,
      gallery: gallery,
      highlights: highlights,
      description: _pickString(json['description']) ?? '',
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
  return null;
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
