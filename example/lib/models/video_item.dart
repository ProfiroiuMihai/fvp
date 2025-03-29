class VideoItem {
  final String path;
  final String name;
  final bool isPlaying;

  const VideoItem({
    required this.path,
    required this.name,
    this.isPlaying = false,
  });

  VideoItem copyWith({
    String? path,
    String? name,
    bool? isPlaying,
  }) {
    return VideoItem(
      path: path ?? this.path,
      name: name ?? this.name,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
