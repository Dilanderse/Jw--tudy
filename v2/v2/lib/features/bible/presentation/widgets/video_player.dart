import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VerseVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const VerseVideoPlayer({super.key, required this.videoUrl});

  @override
  State<VerseVideoPlayer> createState() => _VerseVideoPlayerState();
}

class _VerseVideoPlayerState extends State<VerseVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
