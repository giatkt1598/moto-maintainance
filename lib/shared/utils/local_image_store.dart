import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveVehicleImage(String sourcePath) async {
  final source = File(sourcePath);
  final dir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(p.join(dir.path, 'vehicle_images'));
  if (!imagesDir.existsSync()) {
    imagesDir.createSync(recursive: true);
  }

  final extension = p.extension(sourcePath);
  final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}$extension';
  final target = File(p.join(imagesDir.path, fileName));
  await source.copy(target.path);
  return target.path;
}

Future<String> saveVehicleImageBytes(
  Uint8List bytes, {
  String extension = '.png',
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(p.join(dir.path, 'vehicle_images'));
  if (!imagesDir.existsSync()) {
    imagesDir.createSync(recursive: true);
  }

  final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}$extension';
  final target = File(p.join(imagesDir.path, fileName));
  await target.writeAsBytes(bytes, flush: true);
  return target.path;
}
