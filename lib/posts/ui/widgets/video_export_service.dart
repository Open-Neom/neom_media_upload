import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class ExportService {
  final Trimmer _trimmer = Trimmer();

  Future<String?> trimVideo({
    required File videoFile,
    required double startValue,
    required double endValue,
    required String outputPath,
  }) async {
    try {
      await _trimmer.loadVideo(videoFile: videoFile);

      await _trimmer.saveTrimmedVideo(
        startValue: startValue,
        endValue: endValue,
        onSave: (outputPath) {
          debugPrint("Video guardado en: $outputPath");
        },
      );

      return outputPath;
    } catch (e) {
      debugPrint("Error recortando el video: $e");
      return null;
    }
  }
}
