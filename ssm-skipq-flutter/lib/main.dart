import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SkipQApp(services: AppServices()));
}
