import 'dart:async';
import 'dart:io';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoExportService {
  final Trimmer _trimmer = Trimmer();

  Future<String> trimVideo({
    required File videoFile,
    required double startValue,
    required double endValue,
    // required String outputPath,
    required String videoName,
  }) async {

    final Completer<String> completer = Completer();

    try {
      await _trimmer.loadVideo(videoFile: videoFile);

      await _trimmer.saveTrimmedVideo(
        startValue: startValue,
        endValue: endValue,
        videoFileName: videoName,
        outputFormat: FileFormat.mp4,
        onSave: (path) {
          if (path != null) {
            AppUtilities.logger.d("✅ Video guardado en: $path");
            completer.complete(path);
          } else {
            AppUtilities.logger.e("⛔️ La ruta de guardado retornada es nula.");
            completer.complete('');
          }

          // if(path != null) outputPath = path;
          // AppUtilities.logger.d("Video guardado en: $outputPath");
        },
      );

      return completer.future;
    } catch (e) {
      AppUtilities.logger.e("Error recortando el video: $e");
      return '';
    }
  }
}
