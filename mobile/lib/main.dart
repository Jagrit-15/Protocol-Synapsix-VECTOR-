import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'services/sensor_pipeline_service.dart';
import 'services/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await AppSupabaseClient().init();

  // Start real sensor streaming + SQLite logging app-wide. Failures here
  // (e.g. permissions denied) are swallowed so the app still launches —
  // the debug screen will show sensors as unavailable instead of crashing.
  try {
    await SensorPipelineService.instance.start();
  } catch (_) {}

  runApp(const ProtocolSynapsixApp());
}