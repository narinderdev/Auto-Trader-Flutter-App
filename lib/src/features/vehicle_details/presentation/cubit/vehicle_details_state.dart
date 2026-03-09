import 'package:equatable/equatable.dart';

import '../../../../models/auto_trader_models.dart';

class VehicleDetailsState extends Equatable {
  const VehicleDetailsState({
    this.isLoading = true,
    this.errorMessage,
    this.vehicle,
    this.similarVehicles = const <VehicleSummary>[],
  });

  final bool isLoading;
  final String? errorMessage;
  final VehicleDetails? vehicle;
  final List<VehicleSummary> similarVehicles;

  static const Object _unset = Object();

  VehicleDetailsState copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? vehicle = _unset,
    List<VehicleSummary>? similarVehicles,
  }) {
    return VehicleDetailsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      vehicle: identical(vehicle, _unset)
          ? this.vehicle
          : vehicle as VehicleDetails?,
      similarVehicles: similarVehicles ?? this.similarVehicles,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    vehicle,
    similarVehicles,
  ];
}
