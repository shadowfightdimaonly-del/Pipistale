import 'package:flutter/material.dart';

void main() {
  runApp(const PipistaleApp());
}

class PipistaleApp extends StatelessWidget {
  const PipistaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pipistale',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const PrototypeScreen(),
    );
  }
}

class PrototypeScreen extends StatelessWidget {
  const PrototypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF000000),
      body: Center(
        child: Text(
          'PIPISTALE\n\nPrototype 0.1',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
