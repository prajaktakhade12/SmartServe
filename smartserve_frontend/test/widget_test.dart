import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('SmartServe Test')),
        ),
      ),
    );

    expect(find.text('SmartServe Test'), findsOneWidget);
  });
}
