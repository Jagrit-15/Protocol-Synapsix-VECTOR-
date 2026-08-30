import 'package:flutter/material.dart';

import 'app.dart';
import 'services/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabaseClient().init();
  runApp(const ProtocolSynapsixApp());
}