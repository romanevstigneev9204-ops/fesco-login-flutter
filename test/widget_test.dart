import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fesco_login_flutter/main.dart';

void main() {
  testWidgets('shows login placeholder title', (WidgetTester tester) async {
    await tester.pumpWidget(const FescoLoginApp());

    expect(find.text('FESCO Login'), findsOneWidget);
    expect(
      find.text('Login baseline — implement authentication here.'),
      findsOneWidget,
    );
  });
}
