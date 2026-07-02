import 'package:flutter/material.dart';

/// Shown only for the brief moment AuthController.bootstrap() is checking
/// for a stored token; the router redirects away as soon as that resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
