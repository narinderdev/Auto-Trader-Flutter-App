import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autotrader/src/app.dart';

void main() {
  testWidgets('renders the Auto Trader splash screen', (tester) async {
    await tester.pumpWidget(const AutoTraderApp());

    expect(find.byType(AutoTraderApp), findsOneWidget);
    expect(find.text('Auto Trader'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
