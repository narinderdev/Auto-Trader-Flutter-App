import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/auto_trader_models.dart';
import '../../../../repositories/auto_trader_repository.dart';
import 'vehicle_details_state.dart';

class VehicleDetailsCubit extends Cubit<VehicleDetailsState> {
  VehicleDetailsCubit({required AutoTraderRepository repository})
    : _repository = repository,
      super(const VehicleDetailsState());

  final AutoTraderRepository _repository;

  Future<void> load({
    required String vehicleId,
    VehicleSummary? initialVehicle,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final details = await _repository.fetchVehicleDetails(
        vehicleId,
        fallback: initialVehicle,
      );

      final similar = details.make.isEmpty
          ? const <VehicleSummary>[]
          : await _repository.fetchSimilarVehicles(details.make);

      emit(
        state.copyWith(
          isLoading: false,
          vehicle: details,
          similarVehicles: similar
              .where((item) => item.id != vehicleId)
              .take(3)
              .toList(),
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}
