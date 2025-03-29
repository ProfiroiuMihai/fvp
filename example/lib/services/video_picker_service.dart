import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoPickerService {
  static bool _isPickerActive = false; // Keep the lock variable

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  static Future<String?> pickVideo() async {
    // Check if picker is already active
    if (_isPickerActive) {
      print('A media picker is already active');
      return null;
    }

    try {
      _isPickerActive = true; // Lock the picker

      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        _isPickerActive = false; // Unlock if permission denied
        return null;
      }

      // Use file_picker to select a video file
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _isPickerActive = false; // Unlock if no selection
        return null;
      }

      // Get the raw file path
      final String? path = result.files.single.path;
      if (path == null || path.isEmpty) {
        _isPickerActive = false; // Unlock if no path
        return null;
      }

      // Verify it's a video file
      final file = File(path);
      if (!await file.exists()) {
        _isPickerActive = false; // Unlock if file doesn't exist
        return null;
      }

      _isPickerActive = false; // Unlock after successful completion
      return path;
    } catch (e) {
      _isPickerActive = false; // Unlock in case of error
      print('Error picking video: $e');
      return null;
    }
  }

  // Updated method to pick multiple videos
  static Future<List<String>> pickMultipleVideos() async {
    // Check if picker is already active
    if (_isPickerActive) {
      print('A media picker is already active');
      return [];
    }

    try {
      _isPickerActive = true; // Lock the picker

      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        _isPickerActive = false; // Unlock if permission denied
        return [];
      }

      // Use file_picker for multiple videos
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        _isPickerActive = false; // Unlock if no selection
        return [];
      }

      // Extract the paths from the selected videos
      final List<String> videoPaths = result.paths
          .where((path) => path != null && path.isNotEmpty)
          .map((path) => path!)
          .toList();

      // Verify files exist
      List<String> validPaths = [];
      for (String path in videoPaths) {
        final file = File(path);
        if (await file.exists()) {
          validPaths.add(path);
        }
      }

      _isPickerActive = false; // Unlock after successful completion
      return validPaths;
    } catch (e) {
      _isPickerActive = false; // Unlock in case of error
      print('Error picking multiple videos: $e');
      return [];
    }
  }
}
