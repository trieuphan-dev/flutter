import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:admin_template_analyzer_plugin/src/plugin.dart';

void start(List<String> args, SendPort sendPort) {
  ServerPluginStarter(
          AdminTemplateAnalyzerPlugin(PhysicalResourceProvider.INSTANCE))
      .start(sendPort);
}
