import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fesco_login_flutter/app.dart';

void main() {
  testWidgets('starts on login phone screen', (WidgetTester tester) async {
    await tester.pumpWidget(FescoLoginApp());
    await tester.pumpAndSettle();

    expect(find.text('Личный кабинет сотрудника'), findsOneWidget);
    expect(find.textContaining('route: login-phone'), findsOneWidget);
  });

  testWidgets('navigates to OTP after full phone entry', (WidgetTester tester) async {
    await tester.pumpWidget(FescoLoginApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9102345675');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Подтвердить номер'));
    await tester.pumpAndSettle();

    expect(find.text('Код подтверждения'), findsOneWidget);
    expect(find.textContaining('route: login-otp'), findsOneWidget);
    expect(find.textContaining('+7 910 234 56 75'), findsOneWidget);
  });
}
