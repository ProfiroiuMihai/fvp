import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:fvp/mdk.dart';
import 'package:video_player/video_player.dart';

// Utility class to manage multiple video resources
class VideoOptimizer {
  // Static counter for HDR videos - only allow one playing with HDR enabled
  static int _activeHdrCount = 0;

  // Improved HDR detection that better identifies all HDR formats including Dolby Vision
  static bool isHdrContent(MediaInfo? mediaInfo) {
    if (mediaInfo == null || mediaInfo.video == null || mediaInfo.video!.isEmpty) return false;

    final videoInfo = mediaInfo.video![0];
    final metadata = videoInfo.metadata;
    final codec = videoInfo.codec;

    // Check codec format - 10bit and above formats often indicate HDR content
    final format = codec.formatName?.toLowerCase() ?? '';
    final is10BitOrHigher = format.contains('10le') || format.contains('10be') ||
        format.contains('12le') || format.contains('12be') ||
        format.contains('16le') || format.contains('16be');

    // Check codec - HEVC/H.265 is commonly used for HDR
    final isHevcCodec = codec.codec.toLowerCase().contains('hevc') ||
        codec.codec.toLowerCase().contains('h265');

    // Look for HDR indicators in metadata
    final containsHdrMetadata =
        (metadata.containsKey('color_space') &&
            (metadata['color_space'] == 'BT.2020' || metadata['color_space']?.contains('2020') == true)) ||
            (metadata.containsKey('color_transfer') &&
                (metadata['color_transfer'] == 'SMPTE ST 2084' ||
                    metadata['color_transfer'] == 'PQ' ||
                    metadata['color_transfer'] == 'HLG' ||
                    metadata['color_transfer']?.contains('2084') == true ||
                    metadata['color_transfer']?.contains('hlg') == true)) ||
            (metadata.containsKey('color_primaries') &&
                (metadata['color_primaries'] == 'bt2020' || metadata['color_primaries']?.contains('2020') == true)) ||
            (metadata.containsKey('hdr_format') &&
                (metadata['hdr_format']!.contains('HDR') ||
                    metadata['hdr_format']!.contains('Dolby')));

    // Check profile - profiles 2 (Main10) and higher in HEVC often indicate HDR
    final hasHdrProfile = isHevcCodec && codec.profile >= 2;

    // Additional checks for Dolby Vision
    final hasDolbyVisionIndication =
        metadata.containsKey('encoder') && metadata['encoder']?.contains('Dolby') == true ||
            metadata.containsKey('comment') && metadata['comment']?.contains('Dolby') == true ||
            metadata.containsKey('handler_name') && metadata['handler_name']?.contains('Dolby') == true;

    // Extra check for MP4 container tags that might indicate Dolby Vision
    final isDolbyVisionContainer =
        mediaInfo.metadata.containsKey('major_brand') &&
            (mediaInfo.metadata['major_brand']?.contains('dvh') == true ||
                mediaInfo.metadata['major_brand']?.contains('dvhe') == true);

    // Combined check for any 10-bit HEVC content
    final is10BitHevc = isHevcCodec &&
        (is10BitOrHigher || format == 'yuv420p10le' || format == 'yuv420p10' ||
            metadata.containsKey('bits_per_raw_sample') &&
                (metadata['bits_per_raw_sample'] == '10' ||
                    (int.tryParse(metadata['bits_per_raw_sample'] ?? '0') ?? 0) >= 10));

    // Print debug info to help identify why we think it's HDR or not
    print('HDR detection for ${codec.codec}:');
    print('- Format: ${codec.formatName}');
    print('- 10bit+: $is10BitOrHigher');
    print('- HEVC: $isHevcCodec');
    print('- HDR metadata: $containsHdrMetadata');
    print('- HDR profile: $hasHdrProfile');
    print('- Dolby Vision indications: $hasDolbyVisionIndication');
    print('- Dolby Vision container: $isDolbyVisionContainer');
    print('- 10-bit HEVC: $is10BitHevc');

    // Return true if any of the HDR indicators are present
    return containsHdrMetadata ||
        hasDolbyVisionIndication ||
        isDolbyVisionContainer ||
        is10BitHevc ||
        hasHdrProfile;
  }

  // Apply HDR optimizations - use for single primary HDR video
  static void applyHdrOptimizations(VideoPlayerController controller) {
    _activeHdrCount++;

    // Enable HDR processing with hardware acceleration
    controller.setVideoDecoders(['VT', 'FFmpeg']);
    controller.setProperty('video.hdr', '1');
  }

  // Apply non-HDR optimizations - use for multiple videos or when HDR is disabled
  static void applyNonHdrOptimizations(VideoPlayerController controller) {
    // Disable HDR processing for better performance
    controller.setVideoDecoders(['FFmpeg']);
    controller.setProperty('video.hdr', '0');

    // Apply color correction for better SDR appearance
    controller.setProperty('video.color_range', 'full');
    controller.setProperty('video.color_primaries', 'auto');
    controller.setProperty('video.color.space', 'bt709');
    controller.setProperty('video.color.gamma', '2.2');
  }

  // Release HDR slot when video is disposed
  static void releaseHdrSlot() {
    if (_activeHdrCount > 0) _activeHdrCount--;
  }

  // Check if we can use HDR for this video
  static bool canUseHdr() {
    // Only allow one HDR video at a time
    return _activeHdrCount < 1;
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isAsset;
  final String? assetPath;
  final bool showControls;
  final bool autoPlay;
  final bool loop;
  final bool disableHDR;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.isAsset = false,
    this.assetPath,
    this.showControls = false,
    this.autoPlay = true,
    this.loop = true,
    this.disableHDR = false,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isHdrVideo = false;

  @override
  void initState() {
    super.initState();
    // Register FVP plugin globally if not registered yet
    try {
      fvp.registerWith();
    } catch (e) {
      print('FVP may already be registered: $e');
    }
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      if (widget.isAsset) {
        _controller = VideoPlayerController.asset(widget.assetPath!);
      } else if (widget.videoUrl.startsWith('http')) {
        _controller = VideoPlayerController.network(widget.videoUrl);
      } else {
        // Handle file paths
        final file = File(widget.videoUrl);
        if (await file.exists()) {
          _controller = VideoPlayerController.file(file);
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = 'File does not exist: ${widget.videoUrl}';
          });
          return;
        }
      }

      _controller.addListener(() {
        if (_controller.value.hasError && !_hasError) {
          setState(() {
            _hasError = true;
            _errorMessage =
            'Error playing video: ${_controller.value.errorDescription}';
          });
        }
        if (mounted) {
          setState(() {});
        }
      });

      if (widget.loop) {
        _controller.setLooping(true);
      }

      await _controller.initialize();

      // After initialization, apply video optimization settings
      _applyVideoOptimizations();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.autoPlay) {
          _controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize video: $e';
        });
      }
      print('Error initializing video player: $e');
    }
  }

  void _applyVideoOptimizations() {
    try {
      // Get media info to detect if this is HDR content
      MediaInfo? mediaInfo = _controller.getMediaInfo();
      _isHdrVideo = VideoOptimizer.isHdrContent(mediaInfo);

      print("Is this video HDR? $_isHdrVideo");

      // If this is HDR content AND we can enable HDR (no other HDR videos playing)
      // AND user hasn't explicitly disabled HDR
      if (_isHdrVideo  && !widget.disableHDR) {
        print("Applying HDR optimizations");
        // Apply HDR optimizations
        VideoOptimizer.applyHdrOptimizations(_controller);
      } else {
        print("Applying non-HDR optimizations");
        // Apply non-HDR optimizations for better performance with multiple videos
        VideoOptimizer.applyNonHdrOptimizations(_controller);
      }
    } catch (e) {
      print('Error applying video optimizations: $e');
    }
  }

  @override
  void dispose() {
    // Release HDR slot if this was using HDR
    if (_isHdrVideo && VideoOptimizer.canUseHdr()) {
      VideoOptimizer.releaseHdrSlot();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Error playing video',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          VideoPlayer(_controller),
          // All controls have been removed as requested
        ],
      ),
    );
  }
}