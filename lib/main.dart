import 'package:flutter/material.dart';

void main() {
  runApp(const FescoLoginApp());
}

/// Baseline entry point for the FESCO login Flutter app.
class FescoLoginApp extends StatelessWidget {
  const FescoLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FESCO Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _LoginPlaceholder(),
    );
  }
}

class _LoginPlaceholder extends StatelessWidget {
  const _LoginPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FESCO Login')),
      body: const Center(
        child: Text('Login baseline — implement authentication here.'),
      ),
    );
  }
}
