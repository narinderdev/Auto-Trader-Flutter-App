import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'customs_calculator_page.dart';
import '../models/auto_trader_models.dart';
import '../repositories/auto_trader_repository.dart';

class AuctionCalculatorPage extends StatefulWidget {
  const AuctionCalculatorPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AuctionCalculatorPage> createState() => _AuctionCalculatorPageState();
}

class _AuctionCalculatorPageState extends State<AuctionCalculatorPage> {
  static const _auctionCompanies = ['Copart', 'IAAI', 'Manheim'];
  static const _vehicleTypes = [
    '1 Regular Car',
    '2 SUV',
    '3 Truck',
    '4 Motorcycle',
  ];
  static const _destinations = ['Azerbaijan', 'Georgia', 'Turkey'];

  final TextEditingController _lotNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bidAmountController = TextEditingController();
  final FocusNode _lotNumberFocusNode = FocusNode();

  Timer? _lotSearchDebounce;
  List<VehicleSummary> _lotSuggestions = [];
  bool _isFetchingLots = false;
  bool _isSelectingLot = false;
  bool _locationLocked = false;
  bool _vehicleTypeLocked = false;
  int _lotDetailsRequestId = 0;

  String _auctionCompany = _auctionCompanies.first;
  String _vehicleType = _vehicleTypes.first;
  String _destination = _destinations.first;
  double _bid = 0;
  double _auctionFee = 0;
  double _shippingFee = 0;
  double _deliveryCost = 0;
  double _finalPrice = 0;
  bool _hasCalculated = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _lotNumberController.addListener(_onLotQueryChanged);
  }

  @override
  void dispose() {
    _lotSearchDebounce?.cancel();
    _lotNumberController.removeListener(_onLotQueryChanged);
    _lotNumberController.dispose();
    _lotNumberFocusNode.dispose();
    _locationController.dispose();
    _bidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationMissing = _locationController.text.trim().isEmpty;
    final bidValue = double.tryParse(_bidAmountController.text.trim());
    final bidMissing = bidValue == null || bidValue <= 0;
    final hasErrors = locationMissing || bidMissing;

    final theme = Theme.of(context);
    final radius = BorderRadius.circular(5);
    final inputTheme = theme.inputDecorationTheme.copyWith(
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFB4232F), width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFD91C3C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Color(0xFFD91C3C), width: 1.3),
      ),
    );

    final content = Theme(
      data: theme.copyWith(inputDecorationTheme: inputTheme),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const CalculatorBreadcrumb(),
          const SizedBox(height: 18),
          CalculatorTabs(
            isAuctionSelected: true,
            onSelectCustoms: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => CustomsCalculatorPage(
                    embedded: widget.embedded,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final form = _AuctionCalculatorForm(
                auctionCompany: _auctionCompany,
                vehicleType: _vehicleType,
                destination: _destination,
                lotNumberController: _lotNumberController,
                lotNumberFocusNode: _lotNumberFocusNode,
                lotSuggestions: _lotSuggestions,
                isLotLoading: _isFetchingLots,
                lotHintText: _lotHintText(),
                onLotSelected: _selectLotSuggestion,
                locationController: _locationController,
                locationReadOnly: _locationLocked,
                vehicleTypeReadOnly: _vehicleTypeLocked,
                bidAmountController: _bidAmountController,
                showErrors: _showErrors,
                locationInvalid: locationMissing,
                bidInvalid: bidMissing,
                showRequiredMessage: _showErrors && hasErrors,
                onAuctionCompanyChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _auctionCompany = value;
                  });
                },
                onVehicleTypeChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _vehicleType = value;
                  });
                },
                onDestinationChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _destination = value;
                  });
                },
                onCalculate: _calculate,
                onClear: _clear,
              );

              final result = _hasCalculated
                  ? _AuctionResultCard(
                      bid: _bid,
                      auctionFee: _auctionFee,
                      shippingFee: _shippingFee,
                      deliveryCost: _deliveryCost,
                      finalPrice: _finalPrice,
                    )
                  : const SizedBox.shrink();

              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    form,
                    if (_hasCalculated) ...[
                      const SizedBox(height: 16),
                      result,
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  if (_hasCalculated) ...[
                    const SizedBox(width: 22),
                    Expanded(child: result),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(child: content),
    );
  }

  void _onLotQueryChanged() {
    if (_isSelectingLot) {
      return;
    }
    _lotDetailsRequestId += 1;
    if (_locationLocked) {
      setState(() {
        _locationLocked = false;
      });
    }
    if (_vehicleTypeLocked) {
      setState(() {
        _vehicleTypeLocked = false;
      });
    }
    final query = _lotNumberController.text.trim();
    _lotSearchDebounce?.cancel();

    if (query.isEmpty || query.length < 3) {
      if (_lotSuggestions.isNotEmpty || _isFetchingLots) {
        setState(() {
          _lotSuggestions = [];
          _isFetchingLots = false;
        });
      } else {
        setState(() {});
      }
      return;
    }

    _lotSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchLotSuggestions(query);
    });
  }

  String? _lotHintText() {
    final query = _lotNumberController.text.trim();
    if (query.isEmpty) {
      return null;
    }
    if (query.length < 3) {
      return 'Please enter at least 3 digits to see suggestions.';
    }
    return null;
  }

  Future<void> _fetchLotSuggestions(String query) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isFetchingLots = true;
    });

    try {
      final repository = context.read<AutoTraderRepository>();
      final response = await repository.fetchAuctionLotSuggestions(
        query,
        limit: 8,
      );
      if (!mounted) {
        return;
      }
      final currentQuery = _lotNumberController.text.trim();
      if (currentQuery != query) {
        return;
      }
      setState(() {
        _lotSuggestions = response;
        _isFetchingLots = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lotSuggestions = [];
        _isFetchingLots = false;
      });
    }
  }

  void _selectLotSuggestion(VehicleSummary vehicle) {
    final lotLabel = _lotSuggestionLabel(vehicle);
    final location = _lotSuggestionLocation(vehicle);
    _isSelectingLot = true;
    _lotNumberController.text = lotLabel;
    _lotNumberController.selection = TextSelection.collapsed(
      offset: _lotNumberController.text.length,
    );
    setState(() {
      _locationLocked = location.isNotEmpty;
      _vehicleTypeLocked = true;
      if (location.isNotEmpty) {
        _locationController.text = location;
      } else {
        _locationController.clear();
      }
      _lotSuggestions = [];
    });
    _isSelectingLot = false;
    if (location.isEmpty) {
      _fillLocationFromLot(vehicle);
    }
  }

  String _lotSuggestionLabel(VehicleSummary vehicle) {
    return _buildLotDisplayLabel(vehicle);
  }

  String _lotSuggestionLocation(VehicleSummary vehicle) {
    final location = vehicle.location.trim();
    if (location.isNotEmpty) {
      return location;
    }
    return vehicle.country.trim();
  }

  Future<void> _fillLocationFromLot(VehicleSummary vehicle) async {
    final lotNumber = _resolveLotNumber(vehicle);
    if (lotNumber == null || lotNumber.isEmpty || !mounted) {
      return;
    }
    final requestId = ++_lotDetailsRequestId;
    try {
      final repository = context.read<AutoTraderRepository>();
      final detail = await repository.fetchAuctionLotDetail(lotNumber);
      if (!mounted || requestId != _lotDetailsRequestId) {
        return;
      }
      final location = detail?.location.trim() ?? '';
      if (location.isEmpty) {
        return;
      }
      setState(() {
        _locationController.text = location;
        _locationLocked = true;
      });
    } catch (_) {
      if (!mounted || requestId != _lotDetailsRequestId) {
        return;
      }
      setState(() {
        _locationLocked = false;
      });
    }
  }

  void _calculate() {
    final bid = double.tryParse(_bidAmountController.text.trim());
    final locationMissing = _locationController.text.trim().isEmpty;
    final bidMissing = bid == null || bid <= 0;

    if (locationMissing || bidMissing) {
      setState(() {
        _showErrors = true;
      });
      return;
    }

    final auctionFee = switch (_auctionCompany) {
      'Copart' => bid * 0.08 + 120,
      'IAAI' => bid * 0.075 + 105,
      _ => bid * 0.07 + 95,
    };

    final shippingMultiplier = switch (_vehicleType) {
      '2 SUV' => 1.22,
      '3 Truck' => 1.38,
      '4 Motorcycle' => 0.74,
      _ => 1.0,
    };

    final shippingFee = switch (_destination) {
          'Azerbaijan' => 820.0,
          'Georgia' => 640.0,
          _ => 890.0,
        } *
        shippingMultiplier;

    final deliveryCost =
        (_locationController.text.trim().isEmpty ? 0 : 85.0) +
        (_lotNumberController.text.trim().isEmpty ? 0 : 35.0);

    setState(() {
      _showErrors = false;
      _bid = bid;
      _auctionFee = auctionFee;
      _shippingFee = shippingFee;
      _deliveryCost = deliveryCost.toDouble();
      _finalPrice = bid + auctionFee + shippingFee + deliveryCost;
      _hasCalculated = true;
    });
  }

  void _clear() {
    setState(() {
      _showErrors = false;
      _auctionCompany = _auctionCompanies.first;
      _vehicleType = _vehicleTypes.first;
      _destination = _destinations.first;
      _lotNumberController.clear();
      _locationController.clear();
      _bidAmountController.clear();
      _lotSuggestions = [];
      _isFetchingLots = false;
      _locationLocked = false;
      _vehicleTypeLocked = false;
      _lotDetailsRequestId += 1;
      _bid = 0;
      _auctionFee = 0;
      _shippingFee = 0;
      _deliveryCost = 0;
      _finalPrice = 0;
      _hasCalculated = false;
    });
  }
}

class CalculatorBreadcrumb extends StatelessWidget {
  const CalculatorBreadcrumb({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: const Color(0xFF7E8695),
      fontWeight: FontWeight.w500,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        Text('Home', style: style),
        Text('/', style: style),
        Text(
          'Calculator',
          style: style?.copyWith(
            color: const Color(0xFF353B48),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class CalculatorTabs extends StatelessWidget {
  const CalculatorTabs({
    super.key,
    required this.isAuctionSelected,
    required this.onSelectCustoms,
    this.onSelectAuction,
  });

  final bool isAuctionSelected;
  final VoidCallback onSelectCustoms;
  final VoidCallback? onSelectAuction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CalculatorTab(
            label: 'Detailed Customs Fee Calculator',
            isSelected: !isAuctionSelected,
            onTap: onSelectCustoms,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CalculatorTab(
            label: 'Auction Calculator',
            isSelected: isAuctionSelected,
            onTap: onSelectAuction,
          ),
        ),
      ],
    );
  }
}

class CalculatorTab extends StatelessWidget {
  const CalculatorTab({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? Colors.white : const Color(0xFFE3354A);
    final backgroundColor =
        isSelected ? const Color(0xFFE3354A) : Colors.white;
    final borderColor = const Color(0xFFE4E7F4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _AuctionCalculatorForm extends StatelessWidget {
  const _AuctionCalculatorForm({
    required this.auctionCompany,
    required this.vehicleType,
    required this.destination,
    required this.lotNumberController,
    required this.lotNumberFocusNode,
    required this.lotSuggestions,
    required this.isLotLoading,
    required this.lotHintText,
    required this.onLotSelected,
    required this.locationController,
    required this.locationReadOnly,
    required this.vehicleTypeReadOnly,
    required this.bidAmountController,
    required this.showErrors,
    required this.locationInvalid,
    required this.bidInvalid,
    required this.showRequiredMessage,
    required this.onAuctionCompanyChanged,
    required this.onVehicleTypeChanged,
    required this.onDestinationChanged,
    required this.onCalculate,
    required this.onClear,
  });

  final String auctionCompany;
  final String vehicleType;
  final String destination;
  final TextEditingController lotNumberController;
  final FocusNode lotNumberFocusNode;
  final List<VehicleSummary> lotSuggestions;
  final bool isLotLoading;
  final String? lotHintText;
  final ValueChanged<VehicleSummary> onLotSelected;
  final TextEditingController locationController;
  final bool locationReadOnly;
  final bool vehicleTypeReadOnly;
  final TextEditingController bidAmountController;
  final bool showErrors;
  final bool locationInvalid;
  final bool bidInvalid;
  final bool showRequiredMessage;
  final ValueChanged<String?> onAuctionCompanyChanged;
  final ValueChanged<String?> onVehicleTypeChanged;
  final ValueChanged<String?> onDestinationChanged;
  final VoidCallback onCalculate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auction Calculator',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2E3440),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find out the final price for any vehicle',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF7E8695),
            ),
          ),
          const SizedBox(height: 20),
          const CalculatorFieldLabel('Auction *'),
          const SizedBox(height: 8),
          CalculatorDropdown(
            value: auctionCompany,
            items: const ['Copart', 'IAAI', 'Manheim'],
            onChanged: onAuctionCompanyChanged,
          ),
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Lot Number'),
          const SizedBox(height: 8),
          TextField(
            controller: lotNumberController,
            focusNode: lotNumberFocusNode,
            decoration: InputDecoration(
              hintText: 'Lot #',
              errorText: lotHintText,
            ),
          ),
          if (isLotLoading) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Searching lots...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ],
          if (lotSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _LotSuggestionsList(
              suggestions: lotSuggestions,
              onSelected: onLotSelected,
            ),
          ],
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Vehicle Type *'),
          const SizedBox(height: 8),
          CalculatorDropdown(
            value: vehicleType,
            items: const ['1 Regular Car', '2 SUV', '3 Truck', '4 Motorcycle'],
            onChanged: vehicleTypeReadOnly ? null : onVehicleTypeChanged,
          ),
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Location *'),
          const SizedBox(height: 8),
          TextField(
            controller: locationController,
            readOnly: locationReadOnly,
            decoration: InputDecoration(
              hintText: 'Enter location',
              errorText:
                  showErrors && locationInvalid ? 'This field is required' : null,
            ),
          ),
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Bid Amount (USD) *'),
          const SizedBox(height: 8),
          TextField(
            controller: bidAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.00',
              errorText:
                  showErrors && bidInvalid ? 'This field is required' : null,
            ),
          ),
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Destination *'),
          const SizedBox(height: 8),
          CalculatorDropdown(
            value: destination,
            items: const ['Azerbaijan', 'Georgia', 'Turkey'],
            onChanged: onDestinationChanged,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onCalculate,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF356CF3),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Calculate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF353B48),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
          if (showRequiredMessage) ...[
            const SizedBox(height: 10),
            Text(
              'Please fill all required fields',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuctionResultCard extends StatelessWidget {
  const _AuctionResultCard({
    required this.bid,
    required this.auctionFee,
    required this.shippingFee,
    required this.deliveryCost,
    required this.finalPrice,
  });

  final double bid;
  final double auctionFee;
  final double shippingFee;
  final double deliveryCost;
  final double finalPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Result',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2E3440),
            ),
          ),
          const SizedBox(height: 18),
          _AuctionResultRow(label: 'Bid', value: '${bid.toStringAsFixed(2)}\$'),
          _AuctionResultRow(
            label: 'Auction Fee',
            value: '${auctionFee.toStringAsFixed(2)}\$',
          ),
          _AuctionResultRow(
            label: 'Shipping Fee',
            value: '${shippingFee.toStringAsFixed(2)}\$',
          ),
          _AuctionResultRow(
            label: 'Cost of Delivery',
            value: '${deliveryCost.toStringAsFixed(2)}\$',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEDDD),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Final Price',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${finalPrice.toStringAsFixed(2)}\$',
                  style: const TextStyle(
                    color: Color(0xFF218838),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _launchExternal('tel:994505553485'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE3354A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Call Us'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      _launchExternal('https://wa.me/994505553485'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF59C85D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text('Write us'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LotSuggestionsList extends StatelessWidget {
  const _LotSuggestionsList({
    required this.suggestions,
    required this.onSelected,
  });

  final List<VehicleSummary> suggestions;
  final ValueChanged<VehicleSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return InkWell(
              onTap: () => onSelected(suggestion),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  _lotSuggestionText(suggestion),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF2E3440),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _lotSuggestionText(VehicleSummary vehicle) {
    return _buildLotDisplayLabel(vehicle);
  }
}

String _buildLotDisplayLabel(VehicleSummary vehicle) {
  final title = vehicle.title.trim();
  final lotNumber = _resolveLotNumber(vehicle);
  if (_looksLikeLotTitle(title)) {
    return title.toUpperCase();
  }
  final yearText = vehicle.year == null ? '' : vehicle.year.toString();
  final titleParts = [
    yearText,
    vehicle.make,
    vehicle.model,
  ].where((value) => value.trim().isNotEmpty).join(' ');
  final fallback = titleParts.isNotEmpty ? titleParts : title;
  if (lotNumber != null && fallback.isNotEmpty) {
    return '$lotNumber - ${fallback.toUpperCase()}';
  }
  if (lotNumber != null) {
    return lotNumber;
  }
  return fallback.isNotEmpty ? fallback.toUpperCase() : fallback;
}

bool _looksLikeLotTitle(String title) {
  return RegExp(r'^\d{5,}\s*-\s*').hasMatch(title);
}

String? _resolveLotNumber(VehicleSummary vehicle) {
  final lot = vehicle.lotNumber.trim();
  if (lot.isNotEmpty) {
    return lot;
  }
  final idLot = _extractLotFromId(vehicle.id);
  if (idLot != null) {
    return idLot;
  }
  final title = vehicle.title;
  for (final match in RegExp(r'\d{5,}').allMatches(title)) {
    final candidate = match.group(0);
    if (candidate == null) {
      continue;
    }
    if (!_looksLikeYear(candidate)) {
      return candidate;
    }
  }
  return null;
}

String? _extractLotFromId(String id) {
  final trimmed = id.trim();
  if (RegExp(r'^\d{5,}$').hasMatch(trimmed)) {
    return trimmed;
  }
  return null;
}

bool _looksLikeYear(String value) {
  if (value.length != 4) {
    return false;
  }
  final year = int.tryParse(value);
  if (year == null) {
    return false;
  }
  return year >= 1900 && year <= 2099;
}

class CalculatorFieldLabel extends StatelessWidget {
  const CalculatorFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: const Color(0xFF6B7280),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class CalculatorDropdown extends StatelessWidget {
  const CalculatorDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
      menuMaxHeight: 280,
      decoration: InputDecoration(errorText: errorText),
    );
  }
}

class _AuctionResultRow extends StatelessWidget {
  const _AuctionResultRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF353B48),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _launchExternal(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
