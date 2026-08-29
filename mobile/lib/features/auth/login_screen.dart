import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('PLACEHOLDER — no real Supabase auth yet.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                // Demo session is AuthSession.demo
                Navigator.of(context).pushReplacementNamed('/home');
              },
              child: const Text('Continue as demo user'),
            ),
          ],
        ),
      ),
    );
  }
}
