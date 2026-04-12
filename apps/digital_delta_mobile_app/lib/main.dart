import 'package:flutter/material.dart';

import 'digital_delta.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setup();
  runApp(const DigitalDeltaApp());
}
