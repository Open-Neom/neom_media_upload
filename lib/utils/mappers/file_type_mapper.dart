import 'package:file_picker/file_picker.dart';
import 'package:neom_core/utils/enums/media_type.dart';

class FileTypeMapper {
  static FileType fromMediaType(MediaType type) {
    switch (type) {
      case MediaType.image:
        return FileType.image;
      case MediaType.audio:
        return FileType.audio;
      case MediaType.video:
        return FileType.video;
      case MediaType.document:
      // Para PDF, se usaría FileType.custom con extensiones específicas.
      // Aquí retornamos FileType.custom, y el llamador debería usar getAllowedExtensions().
        return FileType.custom;
      case MediaType.media:
        return FileType.media;
      case MediaType.unknown:
        return FileType.any; // Para tipos desconocidos, permite cualquier archivo.
    }
  }
}
