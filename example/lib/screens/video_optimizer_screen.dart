import 'package:flutter/material.dart';
import '../models/video_item.dart';
import '../services/video_picker_service.dart';
import '../widgets/video_player_widget.dart';

class VideoOptimizerScreen extends StatefulWidget {
  const VideoOptimizerScreen({Key? key}) : super(key: key);

  @override
  _VideoOptimizerScreenState createState() => _VideoOptimizerScreenState();
}

class _VideoOptimizerScreenState extends State<VideoOptimizerScreen> {
  final List<VideoItem> _videos = [];
  bool _isLoading = false;
  bool _disableHDR = false;

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
      appBar: AppBar(
        title: const Text('Video Optimizer'),
      ),
      body: Column(
        children: [
          // HDR Toggle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SwitchListTile(
              title: const Text('Disable HDR Processing'),
              subtitle: const Text(
                  'Turn off for better performance with multiple videos'),
              value: _disableHDR,
              onChanged: (value) {
                setState(() {
                  _disableHDR = value;
                });
              },
            ),
          ),

          // Buttons row
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

          // Video list
          Expanded(
            child: _videos.isEmpty
                ? const Center(
                    child: Text('No videos selected. Tap to add videos.'))
                : ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(video.name),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeVideo(index),
                              ),
                            ),
                            SizedBox(
                              height: 250,
                              child: VideoPlayerWidget(
                                videoUrl: video.path,
                                isAsset: false,
                                showControls: false, // No controls as requested
                                disableHDR: _disableHDR,
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
