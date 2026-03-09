class AuctionEvent {
  const AuctionEvent({
    required this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.lots,
    required this.highlights,
    required this.description,
  });

  final String id;
  final String name;
  final String location;
  final String date;
  final int lots;
  final List<String> highlights;
  final String description;
}

const auctionEvents = <AuctionEvent>[
  AuctionEvent(
    id: 'iaa-japan-2024-10-12',
    name: 'USS Tokyo Premium Auction',
    location: 'Tokyo, Japan',
    date: '2024-10-12',
    lots: 1550,
    highlights: <String>[
      'Hybrid and EV focus',
      'Live translation desk',
      'Real-time bid analytics',
    ],
    description:
        'Weekly premium sale with a curated list of hybrid hatchbacks and executive sedans. Remote bidding available with concierge service.',
  ),
  AuctionEvent(
    id: 'copart-uae-2024-10-16',
    name: 'Copart UAE Elite Sale',
    location: 'Dubai, UAE',
    date: '2024-10-16',
    lots: 980,
    highlights: <String>[
      'Luxury SUVs',
      'Insurance grade vehicles',
      'Door-to-door shipping assistance',
    ],
    description:
        'High-demand event for GCC buyers featuring low-mileage premium SUVs and sports cars with full inspection reports.',
  ),
  AuctionEvent(
    id: 'manheim-eu-2024-10-22',
    name: 'Manheim Europe Digital Lane',
    location: 'Munich, Germany',
    date: '2024-10-22',
    lots: 1200,
    highlights: <String>[
      'Certified dealer network',
      'Flexible financing',
      'On-site inspection ready',
    ],
    description:
        'Pan-European auction with live HD feed and packaged logistics options into the Caucasus and Central Asia regions.',
  ),
];
