// Tests for `FileTypeMapper`.

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_media_upload/utils/mappers/file_type_mapper.dart';
import 'package:neom_core/utils/enums/media_type.dart';

void main() {
  group('FileTypeMapper.fromMediaType', () {
    test('image → FileType.image', () {
      expect(
        FileTypeMapper.fromMediaType(MediaType.image),
        FileType.image,
      );
    });

    test('audio → FileType.audio', () {
      expect(
        FileTypeMapper.fromMediaType(MediaType.audio),
        FileType.audio,
      );
    });

    test('video → FileType.video', () {
      expect(
        FileTypeMapper.fromMediaType(MediaType.video),
        FileType.video,
      );
    });

    test('document → FileType.custom (necesita extensions)', () {
      expect(
        FileTypeMapper.fromMediaType(MediaType.document),
        FileType.custom,
      );
    });

    test('media → FileType.media', () {
      expect(
        FileTypeMapper.fromMediaType(MediaType.media),
        FileType.media,
      );
    });

    test('unknown → FileType.any', () {
      expect(
        FileTypeMapper.fromMediaType(MediaType.unknown),
        FileType.any,
      );
    });

    test('switch exhaustivo: cubre todos los MediaType', () {
      for (final t in MediaType.values) {
        expect(
          () => FileTypeMapper.fromMediaType(t),
          returnsNormally,
          reason: '$t no está cubierto',
        );
      }
    });
  });
}
