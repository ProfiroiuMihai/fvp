// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// An example of using the fvp plugin, controlling lifecycle and playback of the
/// video.

import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart';
import 'package:fvp/mdk.dart';
import 'screens/video_screens.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  // Register FVP with optimized decoders for iOS local assets
  registerWith(options: {
  });

  runApp(
    const MaterialApp(
      home: App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Video Player'),
      ),
      body: const VideoScreen(),
    );
  }

  // Use this function before showing the video picker
  Future<void> pickVideo(BuildContext context) async {
    bool hasPermission = await requestStoragePermission();

    if (hasPermission) {
      // Show your video picker here
      // For example:
      // FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    } else {
      // Show a dialog informing the user that permission is required
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Permission Required'),
          content: Text('Storage permission is required to pick videos'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // Open app settings so user can enable permission manually
              },
              child: Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }
}

Future<bool> requestStoragePermission() async {
  // For Android 13 and above (SDK 33+)
  if (Platform.isAndroid) {
    if (await Permission.videos.request().isGranted &&
        await Permission.photos.request().isGranted) {
      return true;
    }

    // For older Android versions
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    return false;
  }

  // For iOS or other platforms
  return true;
}
