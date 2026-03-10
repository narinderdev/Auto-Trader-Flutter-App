import 'package:flutter/material.dart';

import 'auction_calculator_page.dart';

class CustomsCalculatorPage extends StatefulWidget {
  const CustomsCalculatorPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CustomsCalculatorPage> createState() => _CustomsCalculatorPageState();
}

class _CustomsCalculatorPageState extends State<CustomsCalculatorPage> {
  static const _vehicleTypes = ['Passenger car', 'SUV', 'Pickup', 'Van'];
  static const _engineTypes = ['Select', 'Petrol', 'Diesel', 'Hybrid', 'Electric'];
  static const _originCountries = [
    'Other countries',
    'United States',
    'China',
    'European Union',
  ];

  final TextEditingController _invoiceValueController = TextEditingController(
    text: '0',
  );
  final TextEditingController _transportationCostsController =
      TextEditingController(text: '0');
  final TextEditingController _otherExpensesController = TextEditingController(
    text: '0',
  );
  final TextEditingController _engineCapacityController = TextEditingController(
    text: '0',
  );

  String _vehicleType = _vehicleTypes.first;
  String _engineType = _engineTypes.first;
  String _originCountry = _originCountries.first;
  DateTime? _issueDate;

  late List<_CustomsResultItem> _resultItems;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _resultItems = _emptyResultItems();
  }

  @override
  void dispose() {
    _invoiceValueController.dispose();
    _transportationCostsController.dispose();
    _otherExpensesController.dispose();
    _engineCapacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engineTypeInvalid = _engineType == _engineTypes.first;
    final invoiceInvalid =
        (double.tryParse(_invoiceValueController.text.trim()) ?? 0) <= 0;
    final transportationInvalid =
        (double.tryParse(_transportationCostsController.text.trim()) ?? 0) <= 0;
    final otherInvalid =
        (double.tryParse(_otherExpensesController.text.trim()) ?? 0) <= 0;
    final engineCapacityInvalid =
        (double.tryParse(_engineCapacityController.text.trim()) ?? 0) <= 0;
    final issueDateInvalid = _issueDate == null;
    final hasErrors = engineTypeInvalid ||
        invoiceInvalid ||
        transportationInvalid ||
        otherInvalid ||
        engineCapacityInvalid ||
        issueDateInvalid;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const CalculatorBreadcrumb(),
        const SizedBox(height: 18),
        CalculatorTabs(
          isAuctionSelected: false,
          onSelectCustoms: () {},
          onSelectAuction: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => AuctionCalculatorPage(
                  embedded: widget.embedded,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final form = _CustomsVehicleForm(
              vehicleType: _vehicleType,
              engineType: _engineType,
              originCountry: _originCountry,
              invoiceValueController: _invoiceValueController,
              transportationCostsController: _transportationCostsController,
              otherExpensesController: _otherExpensesController,
              engineCapacityController: _engineCapacityController,
              issueDate: _issueDate,
              showErrors: _showErrors,
              engineTypeInvalid: engineTypeInvalid,
              invoiceInvalid: invoiceInvalid,
              transportationInvalid: transportationInvalid,
              otherInvalid: otherInvalid,
              engineCapacityInvalid: engineCapacityInvalid,
              issueDateInvalid: issueDateInvalid,
              showRequiredMessage: _showErrors && hasErrors,
              onVehicleTypeChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _vehicleType = value;
                });
              },
              onEngineTypeChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _engineType = value;
                });
              },
              onOriginCountryChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _originCountry = value;
                });
              },
              onIssueDateTap: _pickIssueDate,
              onCalculate: _calculate,
              onClear: _clear,
            );

            final result = _CustomsResultCard(items: _resultItems);

            if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  form,
                  const SizedBox(height: 16),
                  result,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form),
                const SizedBox(width: 22),
                Expanded(child: result),
              ],
            );
          },
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('Customs Calculator')),
      body: SafeArea(child: content),
    );
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? DateTime.now(),
      firstDate: DateTime(2018),
      lastDate: DateTime.now(),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _issueDate = picked;
    });
  }

  void _calculate() {
    final engineTypeInvalid = _engineType == _engineTypes.first;
    final invoiceInvalid =
        (double.tryParse(_invoiceValueController.text.trim()) ?? 0) <= 0;
    final transportationInvalid =
        (double.tryParse(_transportationCostsController.text.trim()) ?? 0) <= 0;
    final otherInvalid =
        (double.tryParse(_otherExpensesController.text.trim()) ?? 0) <= 0;
    final engineCapacityInvalid =
        (double.tryParse(_engineCapacityController.text.trim()) ?? 0) <= 0;
    final issueDateInvalid = _issueDate == null;

    if (engineTypeInvalid ||
        invoiceInvalid ||
        transportationInvalid ||
        otherInvalid ||
        engineCapacityInvalid ||
        issueDateInvalid) {
      setState(() {
        _showErrors = true;
      });
      return;
    }

    final invoiceValue =
        double.tryParse(_invoiceValueController.text.trim()) ?? 0;
    final transportCost =
        double.tryParse(_transportationCostsController.text.trim()) ?? 0;
    final otherExpenses =
        double.tryParse(_otherExpensesController.text.trim()) ?? 0;
    final engineCapacity =
        double.tryParse(_engineCapacityController.text.trim()) ?? 0;

    final customsBase = invoiceValue + transportCost + otherExpenses;
    final importDuty = customsBase * 0.15;
    final vat = (customsBase + importDuty) * 0.18;
    final clearanceFee = customsBase * 0.01;
    final exciseTax = _engineType == 'Electric' ? 0.0 : engineCapacity * 0.06;
    final certificateFee = _originCountry == 'European Union' ? 60.0 : 90.0;

    setState(() {
      _showErrors = false;
      _resultItems = [
        _CustomsResultItem('Import customs duty', importDuty),
        _CustomsResultItem('Value added tax (VAT)', vat),
        _CustomsResultItem(
          'Customs fees for customs clearance of goods',
          clearanceFee,
        ),
        _CustomsResultItem('Excise tax', exciseTax),
        _CustomsResultItem('Customs fees for issuing certificates', 45.0),
        _CustomsResultItem('Electronic customs service fee', 30.0),
        _CustomsResultItem('VAT on electronic customs services', 5.4),
        _CustomsResultItem('Disposal fee', 25.0),
        _CustomsResultItem('Conducting customs expertise fee', 40.0),
        _CustomsResultItem(
          'Certificate of compliance with standards fee',
          certificateFee,
        ),
      ];
    });
  }

  void _clear() {
    setState(() {
      _showErrors = false;
      _vehicleType = _vehicleTypes.first;
      _engineType = _engineTypes.first;
      _originCountry = _originCountries.first;
      _invoiceValueController.text = '0';
      _transportationCostsController.text = '0';
      _otherExpensesController.text = '0';
      _engineCapacityController.text = '0';
      _issueDate = null;
      _resultItems = _emptyResultItems();
    });
  }

  List<_CustomsResultItem> _emptyResultItems() {
    return const [
      _CustomsResultItem('Import customs duty', 0),
      _CustomsResultItem('Value added tax (VAT)', 0),
      _CustomsResultItem('Customs fees for customs clearance of goods', 0),
      _CustomsResultItem('Excise tax', 0),
      _CustomsResultItem('Customs fees for issuing certificates', 0),
      _CustomsResultItem('Electronic customs service fee', 0),
      _CustomsResultItem('VAT on electronic customs services', 0),
      _CustomsResultItem('Disposal fee', 0),
      _CustomsResultItem('Conducting customs expertise fee', 0),
      _CustomsResultItem(
        'Certificate of compliance with standards fee',
        0,
      ),
    ];
  }
}

class _CustomsVehicleForm extends StatelessWidget {
  const _CustomsVehicleForm({
    required this.vehicleType,
    required this.engineType,
    required this.originCountry,
    required this.invoiceValueController,
    required this.transportationCostsController,
    required this.otherExpensesController,
    required this.engineCapacityController,
    required this.issueDate,
    required this.showErrors,
    required this.engineTypeInvalid,
    required this.invoiceInvalid,
    required this.transportationInvalid,
    required this.otherInvalid,
    required this.engineCapacityInvalid,
    required this.issueDateInvalid,
    required this.showRequiredMessage,
    required this.onVehicleTypeChanged,
    required this.onEngineTypeChanged,
    required this.onOriginCountryChanged,
    required this.onIssueDateTap,
    required this.onCalculate,
    required this.onClear,
  });

  final String vehicleType;
  final String engineType;
  final String originCountry;
  final TextEditingController invoiceValueController;
  final TextEditingController transportationCostsController;
  final TextEditingController otherExpensesController;
  final TextEditingController engineCapacityController;
  final DateTime? issueDate;
  final bool showErrors;
  final bool engineTypeInvalid;
  final bool invoiceInvalid;
  final bool transportationInvalid;
  final bool otherInvalid;
  final bool engineCapacityInvalid;
  final bool issueDateInvalid;
  final bool showRequiredMessage;
  final ValueChanged<String?> onVehicleTypeChanged;
  final ValueChanged<String?> onEngineTypeChanged;
  final ValueChanged<String?> onOriginCountryChanged;
  final VoidCallback onIssueDateTap;
  final VoidCallback onCalculate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle data',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2E3440),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculation of customs duty and other payments of the car',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF7E8695),
            ),
          ),
          const SizedBox(height: 20),
          const CalculatorFieldLabel('Type of vehicle'),
          const SizedBox(height: 8),
          CalculatorDropdown(
            value: vehicleType,
            items: const ['Passenger car', 'SUV', 'Pickup', 'Van'],
            onChanged: onVehicleTypeChanged,
          ),
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Engine type'),
          const SizedBox(height: 8),
          CalculatorDropdown(
            value: engineType,
            items: const ['Select', 'Petrol', 'Diesel', 'Hybrid', 'Electric'],
            onChanged: onEngineTypeChanged,
            errorText:
                showErrors && engineTypeInvalid ? 'This field is required' : null,
          ),
          const SizedBox(height: 16),
          _NumberField(
            label: 'Invoice value (USD)',
            controller: invoiceValueController,
            errorText:
                showErrors && invoiceInvalid ? 'This field is required' : null,
          ),
          const SizedBox(height: 14),
          _NumberField(
            label: 'Transportation costs (USD)',
            controller: transportationCostsController,
            errorText: showErrors && transportationInvalid
                ? 'This field is required'
                : null,
          ),
          const SizedBox(height: 14),
          _NumberField(
            label: 'Other expenses (USD)',
            controller: otherExpensesController,
            errorText:
                showErrors && otherInvalid ? 'This field is required' : null,
          ),
          const SizedBox(height: 14),
          _NumberField(
            label: 'Engine Capacity (cm3)',
            controller: engineCapacityController,
            errorText: showErrors && engineCapacityInvalid
                ? 'This field is required'
                : null,
          ),
          const SizedBox(height: 14),
          _DateField(
            label: 'Date of issue *',
            value: issueDate,
            onTap: onIssueDateTap,
            errorText: showErrors && issueDateInvalid
                ? 'Date of issue is required'
                : null,
          ),
          const SizedBox(height: 14),
          const CalculatorFieldLabel(
            'About the country of origin\n(production) and the country of the sender',
          ),
          const SizedBox(height: 8),
          CalculatorDropdown(
            value: originCountry,
            items: const [
              'Other countries',
              'United States',
              'China',
              'European Union',
            ],
            onChanged: onOriginCountryChanged,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              FilledButton(
                onPressed: onCalculate,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF356CF3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(88, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Calculate'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF353B48),
                  minimumSize: const Size(74, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Clear'),
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalculatorFieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(errorText: errorText),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'dd/mm/yyyy'
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalculatorFieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              errorText: errorText,
            ),
            child: Text(text),
          ),
        ),
      ],
    );
  }
}

class _CustomsResultCard extends StatelessWidget {
  const _CustomsResultCard({required this.items});

  final List<_CustomsResultItem> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF606977),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${item.value.toStringAsFixed(2)} AZN',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF606977),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEDDD),
              borderRadius: BorderRadius.circular(8),
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
                  '${total.toStringAsFixed(2)} AZN',
                  style: const TextStyle(
                    color: Color(0xFF218838),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomsResultItem {
  const _CustomsResultItem(this.label, this.value);

  final String label;
  final double value;
}
