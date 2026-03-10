import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ShippingCalculatorPage extends StatefulWidget {
  const ShippingCalculatorPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ShippingCalculatorPage> createState() => _ShippingCalculatorPageState();
}

class _ShippingCalculatorPageState extends State<ShippingCalculatorPage> {
  static const _auctionCompanies = ['Copart', 'IAAI', 'Manheim'];
  static const _vehicleTypes = [
    'Select',
    '1 Regular Car',
    'Large Motorcycle',
    'Motorcycle',
    'Oversize Car',
  ];
  static const _destinations = ['Azerbaijan', 'Georgia', 'Turkey'];

  final TextEditingController _lotNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _auctionCompany = _auctionCompanies.first;
  String _vehicleType = _vehicleTypes.first;
  String _destination = _destinations.first;
  double _shippingFee = 0;
  double _deliveryCost = 0;
  double _finalPrice = 0;
  String? _vehicleTypeError;
  String? _locationError;
  String? _formError;

  @override
  void dispose() {
    _lotNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          'Shipping Calculator',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Find Out the Final Price for Any Vehicle',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: const Color(0xFF6B7280)),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Auction Company *'),
                const SizedBox(height: 8),
                _StyledDropdown<String>(
                  value: _auctionCompany,
                  items: _auctionCompanies,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _auctionCompany = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _FieldLabel('Lot Number'),
                const SizedBox(height: 8),
                TextField(
                  controller: _lotNumberController,
                  decoration: const InputDecoration(hintText: 'Lot #'),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Vehicle Type *'),
                const SizedBox(height: 8),
                _StyledDropdown<String>(
                  value: _vehicleType,
                  items: _vehicleTypes,
                  errorText: _vehicleTypeError,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _vehicleType = value;
                      _vehicleTypeError = null;
                      _formError = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _FieldLabel('Location *'),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  onChanged: (_) {
                    if (_locationError == null && _formError == null) {
                      return;
                    }
                    setState(() {
                      if (_locationController.text.trim().isNotEmpty) {
                        _locationError = null;
                      }
                      _formError = null;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search location',
                    errorText: _locationError,
                  ),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Destination *'),
                const SizedBox(height: 8),
                _StyledDropdown<String>(
                  value: _destination,
                  items: _destinations,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _destination = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _calculate,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4A95F0),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Calculate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2D2D2D),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _formError!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFD91C3C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: Column(
                    children: [
                      _ResultRow(
                        label: 'Shipping Fee',
                        value: '${_shippingFee.toStringAsFixed(2)}\$',
                      ),
                      const SizedBox(height: 8),
                      _ResultRow(
                        label: 'Cost of Delivery',
                        value: '${_deliveryCost.toStringAsFixed(2)}\$',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDFF3E3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Final Price',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${_finalPrice.toStringAsFixed(2)}\$',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _launchExternal('tel:994505553485'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD91C3C),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Call Us'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            _launchExternal('https://wa.me/994505553485'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF57CC5A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Write us'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Calculator')),
      body: SafeArea(child: content),
    );
  }

  void _calculate() {
    final location = _locationController.text.trim();
    final hasVehicleType = _vehicleType != _vehicleTypes.first;
    final hasLocation = location.isNotEmpty;

    if (!hasVehicleType || !hasLocation) {
      setState(() {
        _vehicleTypeError = hasVehicleType ? null : 'This field is required';
        _locationError = hasLocation ? null : 'This field is required';
        _formError = 'Please fill all required fields';
        _shippingFee = 0;
        _deliveryCost = 0;
        _finalPrice = 0;
      });
      return;
    }

    final baseFee = switch (_auctionCompany) {
      'Copart' => 450.0,
      'IAAI' => 420.0,
      _ => 390.0,
    };

    final vehicleMultiplier = switch (_vehicleType) {
      '1 Regular Car' => 1.0,
      'Large Motorcycle' => 0.72,
      'Motorcycle' => 0.58,
      'Oversize Car' => 1.34,
      _ => 1.0,
    };

    final destinationFee = switch (_destination) {
      'Azerbaijan' => 780.0,
      'Georgia' => 620.0,
      _ => 860.0,
    };

    final locationAdjustment = location.isEmpty ? 0.0 : 95.0;
    final lotAdjustment = _lotNumberController.text.trim().isEmpty ? 0.0 : 40.0;

    setState(() {
      _vehicleTypeError = null;
      _locationError = null;
      _formError = null;
      _shippingFee = baseFee * vehicleMultiplier;
      _deliveryCost = destinationFee + locationAdjustment + lotAdjustment;
      _finalPrice = _shippingFee + _deliveryCost;
    });
  }

  void _clear() {
    setState(() {
      _auctionCompany = _auctionCompanies.first;
      _vehicleType = _vehicleTypes.first;
      _destination = _destinations.first;
      _lotNumberController.clear();
      _locationController.clear();
      _vehicleTypeError = null;
      _locationError = null;
      _formError = null;
      _shippingFee = 0;
      _deliveryCost = 0;
      _finalPrice = 0;
    });
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6B7280),
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text('$item'),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(errorText: errorText),
      menuMaxHeight: 280,
      isExpanded: true,
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

Future<void> _launchExternal(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
