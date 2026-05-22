import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_core/utils/enums/media_type.dart';
import 'package:neom_media_upload/utils/constants/media_upload_constants.dart';
import 'package:neom_media_upload/utils/media_upload_utilities.dart';
import 'package:neom_media_upload/utils/mappers/file_type_mapper.dart';
import 'package:file_picker/file_picker.dart';

/// Helper that creates a temporary file with specified bytes.
Future<File> _writeTempFile(String name, int bytes) async {
  final dir = await Directory.systemTemp.createTemp('neom_mu_test_');
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(List<int>.filled(bytes, 0));
  return f;
}

void main() {
  group('getMediaTypeFromExtension', () {
    test('jpg => image', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/x.jpg')),
          equals(MediaType.image));
    });

    test('PNG (uppercase) => image', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/x.PNG')),
          equals(MediaType.image));
    });

    test('mp4 => video', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/clip.mp4')),
          equals(MediaType.video));
    });

    test('mp3 => audio', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/song.mp3')),
          equals(MediaType.audio));
    });

    test('pdf => document', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/doc.pdf')),
          equals(MediaType.document));
    });

    test('exe (unsupported) => unknown', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/virus.exe')),
          equals(MediaType.unknown));
    });

    test('file with no extension is unknown (not crash)', () {
      // BUG SURFACE: split('.').last on a path without '.' returns full path
      // → which definitely doesn't match any extension list, so returns unknown.
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/Makefile')),
          equals(MediaType.unknown));
    });

    test('mixed case extension MP3 => audio', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/SONG.MP3')),
          equals(MediaType.audio));
    });

    test('double-extension takes the last (.tar.gz => gz unknown)', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/archive.tar.gz')),
          equals(MediaType.unknown));
    });

    test('hidden file with extension .pdf still detected', () {
      expect(MediaUploadUtilities.getMediaTypeFromExtension(File('/tmp/.hidden.pdf')),
          equals(MediaType.document));
    });
  });

  group('isValidFileSize boundaries', () {
    test('image just under limit is valid', () async {
      final f = await _writeTempFile('a.jpg', MediaUploadConstants.maxImageFileSize - 1);
      expect(await MediaUploadUtilities.isValidFileSize(f, MediaType.image), isTrue);
    });

    test('image exactly at limit is invalid (strict <)', () async {
      final f = await _writeTempFile('a.jpg', MediaUploadConstants.maxImageFileSize);
      // Implementation uses `<`, NOT `<=`. Document this.
      expect(await MediaUploadUtilities.isValidFileSize(f, MediaType.image), isFalse);
    });

    test('image over limit is invalid', () async {
      final f = await _writeTempFile('a.jpg', MediaUploadConstants.maxImageFileSize + 1);
      expect(await MediaUploadUtilities.isValidFileSize(f, MediaType.image), isFalse);
    });

    test('audio under audio limit is valid', () async {
      final f = await _writeTempFile('a.mp3', 1024);
      expect(await MediaUploadUtilities.isValidFileSize(f, MediaType.audio), isTrue);
    });

    test('document under pdf limit is valid', () async {
      final f = await _writeTempFile('a.pdf', 1024);
      expect(await MediaUploadUtilities.isValidFileSize(f, MediaType.document), isTrue);
    });

    test('empty file (0 bytes) is valid (still <)', () async {
      final f = await _writeTempFile('a.jpg', 0);
      expect(await MediaUploadUtilities.isValidFileSize(f, MediaType.image), isTrue);
    });

    test('non-existent file gracefully returns false', () async {
      final missing = File('/tmp/__definitely_not_a_real_file_xyz__.jpg');
      expect(await MediaUploadUtilities.isValidFileSize(missing, MediaType.image),
          isFalse);
    });

    test('unknown media type returns false', () async {
      final f = await _writeTempFile('a.bin', 10);
      expect(await MediaUploadUtilities.isValidFileSize(f, MediaType.unknown), isFalse);
    });
  });

  group('Media size constants sanity', () {
    test('image limit is positive and below 1 GB', () {
      expect(MediaUploadConstants.maxImageFileSize, greaterThan(0));
      expect(MediaUploadConstants.maxImageFileSize, lessThan(1024 * 1024 * 1024));
    });

    test('video limit > image limit', () {
      expect(MediaUploadConstants.maxVideoFileSize,
          greaterThan(MediaUploadConstants.maxImageFileSize));
    });

    test('all constants > 0', () {
      expect(MediaUploadConstants.maxImageFileSize, greaterThan(0));
      expect(MediaUploadConstants.maxVideoFileSize, greaterThan(0));
      expect(MediaUploadConstants.maxAudioFileSize, greaterThan(0));
      expect(MediaUploadConstants.maxPdfFileSize, greaterThan(0));
    });
  });

  group('convertPlatformFile(s)ToFile(s)', () {
    test('null platform file returns null', () {
      expect(MediaUploadUtilities.convertPlatformFileToFile(null), isNull);
    });

    test('platform file with empty path returns null', () {
      final pf = PlatformFile(name: 'a.jpg', size: 0, path: '');
      expect(MediaUploadUtilities.convertPlatformFileToFile(pf), isNull);
    });

    test('platform file with valid path returns File', () {
      final pf = PlatformFile(name: 'a.jpg', size: 0, path: '/tmp/a.jpg');
      final f = MediaUploadUtilities.convertPlatformFileToFile(pf);
      expect(f, isNotNull);
      expect(f!.path, equals('/tmp/a.jpg'));
    });

    test('null list returns empty list (no NPE)', () {
      expect(MediaUploadUtilities.convertPlatformFilesToFiles(null), isEmpty);
    });

    test('empty list returns empty list', () {
      expect(MediaUploadUtilities.convertPlatformFilesToFiles([]), isEmpty);
    });

    test('skips entries with null/empty paths but keeps valid ones', () {
      final result = MediaUploadUtilities.convertPlatformFilesToFiles([
        PlatformFile(name: 'a.jpg', size: 0, path: '/tmp/a.jpg'),
        PlatformFile(name: 'b.jpg', size: 0, path: ''),
        PlatformFile(name: 'c.jpg', size: 0, path: '/tmp/c.jpg'),
      ]);
      expect(result.length, equals(2));
      expect(result.map((f) => f.path).toList(), equals(['/tmp/a.jpg', '/tmp/c.jpg']));
    });
  });

  group('FileTypeMapper.fromMediaType', () {
    test('image => FileType.image', () {
      expect(FileTypeMapper.fromMediaType(MediaType.image), equals(FileType.image));
    });

    test('audio => FileType.audio', () {
      expect(FileTypeMapper.fromMediaType(MediaType.audio), equals(FileType.audio));
    });

    test('document => FileType.custom (caller must supply extensions)', () {
      expect(FileTypeMapper.fromMediaType(MediaType.document), equals(FileType.custom));
    });

    test('unknown => FileType.any', () {
      expect(FileTypeMapper.fromMediaType(MediaType.unknown), equals(FileType.any));
    });
  });
}
