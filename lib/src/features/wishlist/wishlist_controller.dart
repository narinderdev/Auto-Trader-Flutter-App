import 'package:flutter/foundation.dart';

class WishlistController extends ChangeNotifier {
  final Set<String> _vehicleIds = <String>{};

  Set<String> get vehicleIds => Set.unmodifiable(_vehicleIds);

  bool contains(String vehicleId) => _vehicleIds.contains(vehicleId);

  bool toggle(String vehicleId) {
    final added = !_vehicleIds.contains(vehicleId);
    if (added) {
      _vehicleIds.add(vehicleId);
    } else {
      _vehicleIds.remove(vehicleId);
    }
    notifyListeners();
    return added;
  }
}
