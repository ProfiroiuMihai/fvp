import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';
import '../services/video_picker_service.dart';
import '../models/video_item.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final List<VideoItem> _videos = [];
  bool _isLoading = false;

  // Single video picker (keeping for backward compatibility)
  Future<void> _pickVideo() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final videoPath = await VideoPickerService.pickVideo();

    setState(() {
      _isLoading = false;
      if (videoPath != null) {
        _videos.add(
          VideoItem(
            path: videoPath,
            name: videoPath.split('/').last,
          ),
        );
      }
    });
  }

  // New method to pick multiple videos
  Future<void> _pickMultipleVideos() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final videoPaths = await VideoPickerService.pickMultipleVideos();

    setState(() {
      _isLoading = false;
      if (videoPaths.isNotEmpty) {
        for (final path in videoPaths) {
          _videos.add(
            VideoItem(
              path: path,
              name: path.split('/').last,
            ),
          );
        }
      }
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _videos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickVideo,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Add Video'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickMultipleVideos,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.video_library),
                  label: const Text('Add Multiple Videos'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _videos.isEmpty
                ? const Center(
                    child: Text('No videos selected. Tap to add videos.'))
                : ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      return Card(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 250,
                              child: VideoPlayerWidget(
                                videoUrl: video.path,
                                isAsset: false
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
