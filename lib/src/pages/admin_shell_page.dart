import 'package:flutter/material.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  late AdminSection _selectedSection;
  late AdminFeature _selectedFeature;

  @override
  void initState() {
    super.initState();
    _selectedSection = adminSections.first;
    _selectedFeature = adminSections.first.features.first;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      drawer: wide ? null : Drawer(child: _AdminMenu(onSelect: _selectFeature)),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              SizedBox(
                width: 300,
                child: Material(
                  color: Colors.white,
                  child: _AdminMenu(onSelect: _selectFeature),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedSection.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedFeature.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFeature.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('View list'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Section inventory',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          ..._selectedSection.features.map(
                            (feature) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(feature.title),
                              subtitle: Text(feature.route),
                              trailing: feature == _selectedFeature
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFFB4232F),
                                    )
                                  : null,
                              onTap: () =>
                                  _selectFeature(_selectedSection, feature),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectFeature(AdminSection section, AdminFeature feature) {
    setState(() {
      _selectedSection = section;
      _selectedFeature = feature;
    });
  }
}

class _AdminMenu extends StatelessWidget {
  const _AdminMenu({required this.onSelect});

  final void Function(AdminSection section, AdminFeature feature) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Admin sections',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        ...adminSections.map(
          (section) => Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...section.features.map(
                    (feature) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(feature.title),
                      subtitle: Text(feature.route),
                      onTap: () => onSelect(section, feature),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminSection {
  const AdminSection({required this.title, required this.features});

  final String title;
  final List<AdminFeature> features;
}

class AdminFeature {
  const AdminFeature({
    required this.title,
    required this.route,
    required this.description,
  });

  final String title;
  final String route;
  final String description;
}

const adminSections = <AdminSection>[
  AdminSection(
    title: 'Accounts',
    features: [
      AdminFeature(
        title: 'Users',
        route: '/admin/accounts/users',
        description: 'Manage customer accounts and user records.',
      ),
      AdminFeature(
        title: 'Orders',
        route: '/admin/accounts/orders',
        description: 'Manage account-linked order records.',
      ),
    ],
  ),
  AdminSection(
    title: 'Auction',
    features: [
      AdminFeature(
        title: 'Auction Active Bids',
        route: '/admin/auction/auction-active-bids',
        description: 'Track active bidding activity across auction feeds.',
      ),
      AdminFeature(
        title: 'Auction Currencies',
        route: '/admin/auction/auction-currencies',
        description: 'Manage exchange and auction currency settings.',
      ),
      AdminFeature(
        title: 'Auction Details',
        route: '/admin/auction/auction-details',
        description: 'Review and import auction detail records.',
      ),
      AdminFeature(
        title: 'Auction Vehicle Medias',
        route: '/admin/auction/auction-vehicle-medias',
        description: 'Manage auction vehicle media assets.',
      ),
      AdminFeature(
        title: 'Auction Vehicles',
        route: '/admin/auction/auction-vehicles',
        description: 'Manage auction vehicle master records.',
      ),
    ],
  ),
  AdminSection(
    title: 'Car Details',
    features: [
      AdminFeature(
        title: 'Body Styles',
        route: '/admin/cardetails/body-styles',
        description: 'Edit body style metadata.',
      ),
      AdminFeature(
        title: 'Colors',
        route: '/admin/cardetails/colors',
        description: 'Edit available color metadata.',
      ),
      AdminFeature(
        title: 'Drives',
        route: '/admin/cardetails/drives',
        description: 'Edit drivetrain metadata.',
      ),
      AdminFeature(
        title: 'Fuels',
        route: '/admin/cardetails/fuels',
        description: 'Edit fuel metadata.',
      ),
      AdminFeature(
        title: 'Transmissions',
        route: '/admin/cardetails/transmissions',
        description: 'Edit transmission metadata.',
      ),
      AdminFeature(
        title: 'Features',
        route: '/admin/cardetails/features',
        description: 'Manage vehicle feature labels.',
      ),
      AdminFeature(
        title: 'Labels',
        route: '/admin/cardetails/labels',
        description: 'Manage vehicle labels.',
      ),
      AdminFeature(
        title: 'Makes',
        route: '/admin/cardetails/makes',
        description: 'Manage vehicle make metadata.',
      ),
      AdminFeature(
        title: 'Models',
        route: '/admin/cardetails/models',
        description: 'Manage vehicle model metadata.',
      ),
      AdminFeature(
        title: 'Statuses',
        route: '/admin/cardetails/statuses',
        description: 'Manage vehicle status metadata.',
      ),
      AdminFeature(
        title: 'Vehicle Medias',
        route: '/admin/cardetails/vehicle-medias',
        description: 'Manage primary vehicle media records.',
      ),
    ],
  ),
  AdminSection(
    title: 'General',
    features: [
      AdminFeature(
        title: 'Callbacks',
        route: '/admin/general/callbacks',
        description: 'View callback requests from customers.',
      ),
      AdminFeature(
        title: 'Informations',
        route: '/admin/general/informations',
        description: 'Manage informational content blocks.',
      ),
      AdminFeature(
        title: 'Orders',
        route: '/admin/general/orders',
        description: 'Manage general order entries.',
      ),
    ],
  ),
  AdminSection(
    title: 'Shipping / Taggit / Vehicles',
    features: [
      AdminFeature(
        title: 'Countrys',
        route: '/admin/shipping/countrys',
        description: 'Manage shipping country entries.',
      ),
      AdminFeature(
        title: 'Tags',
        route: '/admin/taggit/tags',
        description: 'Manage taxonomy tags.',
      ),
      AdminFeature(
        title: 'Car Info',
        route: '/admin/vehicles/car-info',
        description: 'Manage vehicle information cards.',
      ),
      AdminFeature(
        title: 'Vehicles',
        route: '/admin/vehicles/vehicles',
        description: 'Manage core vehicle records.',
      ),
    ],
  ),
];
