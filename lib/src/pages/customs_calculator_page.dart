import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class CustomsCalculatorPage extends StatefulWidget {
  const CustomsCalculatorPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CustomsCalculatorPage> createState() => _CustomsCalculatorPageState();
}

class _CustomsCalculatorPageState extends State<CustomsCalculatorPage> {
  final TextEditingController _priceController = TextEditingController(
    text: '20000',
  );
  final TextEditingController _shippingController = TextEditingController(
    text: '1200',
  );
  final TextEditingController _engineController = TextEditingController(
    text: '2000',
  );
  final TextEditingController _ageController = TextEditingController(text: '3');

  @override
  void dispose() {
    _priceController.dispose();
    _shippingController.dispose();
    _engineController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _calculate();

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customs & duty calculator',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Estimate the landed cost of importing a vehicle into Azerbaijan including duty, excise, and VAT.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final form = Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _NumberInput(
                      label: 'Vehicle price (USD)',
                      controller: _priceController,
                      onChanged: (_) => setState(() {}),
                    ),
                    _NumberInput(
                      label: 'Shipping & logistics (USD)',
                      controller: _shippingController,
                      onChanged: (_) => setState(() {}),
                    ),
                    _NumberInput(
                      label: 'Engine size (cc)',
                      controller: _engineController,
                      onChanged: (_) => setState(() {}),
                    ),
                    _NumberInput(
                      label: 'Vehicle age (years)',
                      controller: _ageController,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            );
            final summary = Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated costs',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    ...result.rows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(row.label)),
                            Text('\$${formatWholeNumber(row.value)}'),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total landed cost',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '\$${formatWholeNumber(result.total)}',
                          style: const TextStyle(
                            color: Color(0xFFB4232F),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4E8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Figures are estimates based on current customs guidelines and may change with official tariff updates or vehicle classification.',
                      ),
                    ),
                  ],
                ),
              ),
            );

            if (constraints.maxWidth < 860) {
              return Column(
                children: [form, const SizedBox(height: 14), summary],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: form),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: summary),
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
      appBar: AppBar(title: const Text('Customs Calculator')),
      body: SafeArea(child: content),
    );
  }

  _CalculationResult _calculate() {
    final price = num.tryParse(_priceController.text) ?? 0;
    final shipping = num.tryParse(_shippingController.text) ?? 0;
    final engineSize = num.tryParse(_engineController.text) ?? 0;
    final age = num.tryParse(_ageController.text) ?? 0;

    final cif = price + shipping;
    final dutyRate = cif > 25000 ? 0.15 : 0.1;
    final duty = cif * dutyRate;
    final excise = engineSize > 3000 ? engineSize * 0.6 : engineSize * 0.3;
    final depreciationFactor = (1 - age * 0.05).clamp(0.6, 1.0);
    final taxableBase = (cif + duty + excise) * depreciationFactor;
    final vat = taxableBase * 0.18;
    final total = cif + duty + excise + vat;

    return _CalculationResult(
      rows: [
        _CalculationRow(label: 'CIF (vehicle + shipping)', value: cif),
        _CalculationRow(
          label: 'Import duty (${(dutyRate * 100).round()}%)',
          value: duty,
        ),
        _CalculationRow(label: 'Excise tax', value: excise),
        _CalculationRow(
          label:
              'VAT (18% after depreciation factor ${(depreciationFactor * 100).round()}%)',
          value: vat,
        ),
      ],
      total: total,
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _CalculationRow {
  const _CalculationRow({required this.label, required this.value});

  final String label;
  final num value;
}

class _CalculationResult {
  const _CalculationResult({required this.rows, required this.total});

  final List<_CalculationRow> rows;
  final num total;
}
