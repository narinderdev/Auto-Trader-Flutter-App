import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'customs_calculator_page.dart';

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

  String _auctionCompany = _auctionCompanies.first;
  String _vehicleType = _vehicleTypes.first;
  String _destination = _destinations.first;
  double _bid = 0;
  double _auctionFee = 0;
  double _shippingFee = 0;
  double _deliveryCost = 0;
  double _finalPrice = 0;

  @override
  void dispose() {
    _lotNumberController.dispose();
    _locationController.dispose();
    _bidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const CalculatorBreadcrumb(),
        const SizedBox(height: 18),
        CalculatorTabs(
          isAuctionSelected: true,
          onSelectCustoms: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const CustomsCalculatorPage(),
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
              locationController: _locationController,
              bidAmountController: _bidAmountController,
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

            final result = _AuctionResultCard(
              bid: _bid,
              auctionFee: _auctionFee,
              shippingFee: _shippingFee,
              deliveryCost: _deliveryCost,
              finalPrice: _finalPrice,
            );

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
      appBar: AppBar(title: const Text('Calculator')),
      body: SafeArea(child: content),
    );
  }

  void _calculate() {
    final bid = double.tryParse(_bidAmountController.text.trim()) ?? 0;

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
      _bid = bid;
      _auctionFee = auctionFee;
      _shippingFee = shippingFee;
      _deliveryCost = deliveryCost.toDouble();
      _finalPrice = bid + auctionFee + shippingFee + deliveryCost;
    });
  }

  void _clear() {
    setState(() {
      _auctionCompany = _auctionCompanies.first;
      _vehicleType = _vehicleTypes.first;
      _destination = _destinations.first;
      _lotNumberController.clear();
      _locationController.clear();
      _bidAmountController.clear();
      _bid = 0;
      _auctionFee = 0;
      _shippingFee = 0;
      _deliveryCost = 0;
      _finalPrice = 0;
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
        CalculatorTab(
          label: 'Detailed Customs Fee Calculator',
          icon: Icons.directions_car_outlined,
          isSelected: !isAuctionSelected,
          onTap: onSelectCustoms,
        ),
        const SizedBox(width: 26),
        CalculatorTab(
          label: 'Auction Calculator',
          icon: Icons.construction_rounded,
          isSelected: isAuctionSelected,
          onTap: onSelectAuction,
        ),
      ],
    );
  }
}

class CalculatorTab extends StatelessWidget {
  const CalculatorTab({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFFE3354A) : const Color(0xFF636B79);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFE3354A) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    required this.locationController,
    required this.bidAmountController,
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
  final TextEditingController locationController;
  final TextEditingController bidAmountController;
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
        borderRadius: BorderRadius.circular(16),
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
            decoration: const InputDecoration(hintText: 'Lot #'),
          ),
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Vehicle Type *'),
          const SizedBox(height: 8),
          CalculatorDropdown(
            value: vehicleType,
            items: const ['1 Regular Car', '2 SUV', '3 Truck', '4 Motorcycle'],
            onChanged: onVehicleTypeChanged,
          ),
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Location *'),
          const SizedBox(height: 8),
          TextField(
            controller: locationController,
            decoration: const InputDecoration(hintText: 'Enter location'),
          ),
          const SizedBox(height: 16),
          const CalculatorFieldLabel('Bid Amount (USD) *'),
          const SizedBox(height: 8),
          TextField(
            controller: bidAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: '0.00'),
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
                      borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
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
                      borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
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
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

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
      decoration: const InputDecoration(),
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
