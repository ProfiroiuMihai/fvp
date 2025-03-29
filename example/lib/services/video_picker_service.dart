import 'dart:io';
import 'package:hl_image_picker/hl_image_picker.dart';

import 'package:permission_handler/permission_handler.dart';

class VideoPickerService {
  static final HLImagePicker _picker = HLImagePicker();
  static bool _isPickerActive = false; // Add a lock variable

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

      // Use hl_image_picker to select a video with HDR support
      final List<HLPickerItem> videos = await _picker.openPicker(
        pickerOptions: HLPickerOptions(
          mediaType: MediaType.video,
          maxSelectedAssets: 1,
          enablePreview: true,
          // Ensure no max file size limit which might filter out large HDR videos
          maxFileSize: null,
          // Optional: You might need to increase this if your HDR videos are long
          maxDuration: null,
        ),
      );

      if (videos.isEmpty) {
        _isPickerActive = false; // Unlock if no selection
        return null;
      }

      // Get the raw file path
      final String? path = videos.first.path;
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

      // Use hl_image_picker for multiple videos with enhanced HDR support
      final List<HLPickerItem> videos = await _picker.openPicker(
        pickerOptions: HLPickerOptions(
          mediaType: MediaType.video,
          maxSelectedAssets: 10, // You can adjust this limit as needed
          enablePreview: true,
          // Ensure no max file size limit which might filter out large HDR videos
          maxFileSize: null,
          // Ensure no compression is applied to maintain HDR quality
          compressQuality: 1.0,
          // Optional: You might need to increase this if your HDR videos are long
          maxDuration: null,
        ),
      );

      if (videos.isEmpty) {
        _isPickerActive = false; // Unlock if no selection
        return [];
      }

      // Extract the paths from the selected videos
      final List<String> videoPaths =
          videos.map((video) => video.path).toList();

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
