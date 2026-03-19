import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:file_picker/file_picker.dart';

import '../platform_interface.dart';
import '../../core/errors/exceptions.dart';

/// Windows implementation of FileService
class WindowsFileService implements FileService {
  @override
  Future<List<FileMetadata>> pickFiles(FilePickerOptions options) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: options.allowMultiple,
        allowedExtensions: options.allowedExtensions,
        dialogTitle: options.dialogTitle,
        initialDirectory: options.initialDirectory,
        type: options.allowedExtensions != null
            ? FileType.custom
            : FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final metadataList = <FileMetadata>[];
      for (final file in result.files) {
        if (file.path != null) {
          final stat = await File(file.path!).stat();
          metadataList.add(
            FileMetadata(
              name: file.name,
              path: file.path!,
              size: stat.size,
              extension: p.extension(file.name).replaceAll('.', ''),
              mimeType: _getMimeType(p.extension(file.name)),
              createdAt: stat.changed,
              modifiedAt: stat.modified,
            ),
          );
        }
      }

      return metadataList;
    } catch (e) {
      throw CacheException(message: 'Failed to pick files: $e', code: 3001);
    }
  }

  @override
  Future<FileMetadata?> pickFile(FilePickerOptions options) async {
    final files = await pickFiles(
      FilePickerOptions(
        allowedExtensions: options.allowedExtensions,
        allowMultiple: false,
        dialogTitle: options.dialogTitle,
        initialDirectory: options.initialDirectory,
      ),
    );

    return files.isNotEmpty ? files.first : null;
  }

  @override
  Future<String?> saveFile(FileSaveOptions options, Uint8List data) async {
    try {
      String? outputPath;

      if (options.allowedExtensions != null) {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: options.dialogTitle,
          fileName: options.suggestedName,
          initialDirectory: options.initialDirectory,
          type: FileType.custom,
          allowedExtensions: options.allowedExtensions,
        );
      } else {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: options.dialogTitle,
          fileName: options.suggestedName,
          initialDirectory: options.initialDirectory,
        );
      }

      if (outputPath == null) {
        return null;
      }

      // Ensure proper extension
      if (options.allowedExtensions != null &&
          options.allowedExtensions!.isNotEmpty &&
          !outputPath.endsWith('.${options.allowedExtensions!.first}')) {
        outputPath = '$outputPath.${options.allowedExtensions!.first}';
      }

      final file = File(outputPath);
      await file.writeAsBytes(data);

      return outputPath;
    } catch (e) {
      throw CacheException(message: 'Failed to save file: $e', code: 3002);
    }
  }

  @override
  Future<Uint8List?> readFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsBytes();
    } catch (e) {
      throw CacheException(message: 'Failed to read file: $e', code: 3003);
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return false;
      }
      await file.delete();
      return true;
    } catch (e) {
      throw CacheException(message: 'Failed to delete file: $e', code: 3004);
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    final file = File(path);
    return await file.exists();
  }

  @override
  Future<FileMetadata?> getFileMetadata(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      return FileMetadata(
        name: p.basename(path),
        path: path,
        size: stat.size,
        extension: p.extension(path).replaceAll('.', ''),
        mimeType: _getMimeType(p.extension(path)),
        createdAt: stat.changed,
        modifiedAt: stat.modified,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> getDocumentsDirectory() async {
    final directory = await path_provider.getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<String> getTemporaryDirectory() async {
    final directory = await path_provider.getTemporaryDirectory();
    return directory.path;
  }

  @override
  Future<String?> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      // Create destination directory if needed
      final destinationDir = Directory(p.dirname(destinationPath));
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      final newFile = await sourceFile.copy(destinationPath);
      return newFile.path;
    } catch (e) {
      throw CacheException(message: 'Failed to copy file: $e', code: 3005);
    }
  }

  @override
  Future<String?> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      // Create destination directory if needed
      final destinationDir = Directory(p.dirname(destinationPath));
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      await sourceFile.rename(destinationPath);
      return destinationPath;
    } catch (e) {
      throw CacheException(message: 'Failed to move file: $e', code: 3006);
    }
  }

  String? _getMimeType(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    const mimeTypes = <String, String>{
      // Images
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      // Audio
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'aac': 'audio/aac',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'wma': 'audio/x-ms-wma',
      // Video
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'wmv': 'video/x-ms-wmv',
      // Documents
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'json': 'application/json',
      'xml': 'application/xml',
    };

    return mimeTypes[ext];
  }
}
