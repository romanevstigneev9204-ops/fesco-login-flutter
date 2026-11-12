import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router/app_router.dart';
import 'theme/fesco_theme.dart';

class FescoLoginApp extends StatelessWidget {
  FescoLoginApp({super.key});

  final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FESCO Login',
      debugShowCheckedModeBanner: false,
      theme: FescoTheme.light(),
      routerConfig: _router,
    );
  }
}
