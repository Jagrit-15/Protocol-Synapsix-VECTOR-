import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _error;
  bool _busy = false;

  Future<void> _requestPermissions() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        throw const SensorException(
          'Location permission denied. Demo map still runs on mock GNSS.',
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      setState(() => _error = message);
      if (!mounted) return;
      // Demo must still be reachable without real sensors.
      Navigator.of(context).pushReplacementNamed('/home');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${AppConstants.problemCode} — intelligent dead-reckoning demo skeleton.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              const Text(
                'This build uses scripted mock sensors. Grant location if you '
                'want the live GNSS wrapper later; the tunnel demo runs either way.',
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _requestPermissions,
                child: Text(_busy ? 'Checking…' : 'Continue to map demo'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/home'),
                child: const Text('Skip permissions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
