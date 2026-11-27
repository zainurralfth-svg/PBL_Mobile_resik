import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

Widget buildPickedImage(File file, {BoxFit fit = BoxFit.cover}) {
  if (kIsWeb) {
    return Image.network(file.path, fit: fit);
  }
  return Image.file(file, fit: fit);
}