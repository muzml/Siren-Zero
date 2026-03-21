import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';
import 'package:runanywhere_onnx/runanywhere_onnx.dart';

import 'package:siren_zero/services/model_service.dart';
import 'package:siren_zero/theme/app_theme.dart';
import 'package:siren_zero/views/siren_zero_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the RunAnywhere SDK
  await RunAnywhere.initialize();

  // Register backends
  await LlamaCpp.register();
  await Onnx.register();

  // Register models
  ModelService.registerDefaultModels();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ModelService(),
      child: const RunAnywhereStarterApp(),
    ),
  );
}

class RunAnywhereStarterApp extends StatelessWidget {
  const RunAnywhereStarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siren-Zero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SirenZeroHomeView(),
    );
  }
}
