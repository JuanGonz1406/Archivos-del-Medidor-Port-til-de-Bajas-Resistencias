import 'dart:async';
import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  runApp(OhmApp(controller: controller));
  unawaited(controller.initialize());
}
