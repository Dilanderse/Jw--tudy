import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:jw_study_v2/features/bible/domain/models/bible_models.dart';
import 'package:jw_study_v2/features/bible/presentation/providers/video_providers.dart';
import 'package:jw_study_v2/core/services/video_download_service.dart';

import 'package:jw_study_v2/features/bible/presentation/widgets/media_editor_dialog.dart';

import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class BookIntroVideoPanel extends ConsumerStatefulWidget {
  final String bookId;
  final String bookName;

  const BookIntroVideoPanel({
    super.key,
    required this.bookId,
    required this.bookName,
  });

  @override
  ConsumerState<BookIntroVideoPanel> createState() => _BookIntroVideoPanelState();
}

class _BookIntroVideoPanelState extends ConsumerState<BookIntroVideoPanel> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isDownloading = false;
  bool _isInitializing = false;
  double _downloadProgress = 0;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.close();
    super.dispose();
  }

  void _showMediaEditor(BookIntroVideo? video) {
    showDialog(
      context: context,
      builder: (context) => MediaEditorDialog(
        initialVideo: video,
        bookId: widget.bookId,
        bookName: widget.bookName,
      ),
    );
  }

  bool _isYoutube(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  Future<void> _initializePlayer(BookIntroVideo video) async {
    if (_isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    try {
      _videoPlayerController?.dispose();
      _chewieController?.dispose();
      _youtubeController?.close();
      _videoPlayerController = null;
      _chewieController = null;
      _youtubeController = null;

      if (video.localPath == null && _isYoutube(video.streamUrl)) {
        if (Platform.isLinux) {
          final videoId = YoutubePlayerController.convertUrlToId(video.streamUrl);
          if (videoId == null) throw Exception("ID YouTube invalide");

          // Extract direct stream URL for Linux
          final ytExplode = yt.YoutubeExplode();
          try {
            final manifest = await ytExplode.videos.streams.getManifest(videoId);
            final streamInfo = manifest.muxed.withHighestBitrate();
            final streamUrl = streamInfo.url.toString();
            
            _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
            await _videoPlayerController!.initialize();
            
            _setupChewie();
          } finally {
            ytExplode.close();
          }
        } else {
          final videoId = YoutubePlayerController.convertUrlToId(video.streamUrl);
          if (videoId == null) throw Exception("ID YouTube invalide");
          
          _youtubeController = YoutubePlayerController.fromVideoId(
            videoId: videoId,
            params: const YoutubePlayerParams(
              showControls: true,
              showFullscreenButton: true,
              mute: false,
            ),
          );
        }
      } else {
        final source = video.localPath != null && await File(video.localPath!).exists()
            ? VideoPlayerController.file(File(video.localPath!))
            : VideoPlayerController.networkUrl(Uri.parse(video.streamUrl));

        _videoPlayerController = source;
        await _videoPlayerController!.initialize();
        _setupChewie();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de lecture : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _setupChewie() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      cupertinoProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFACACAC),
        handleColor: const Color(0xFFACACAC),
        bufferedColor: Colors.white.withOpacity(0.2),
        backgroundColor: Colors.white.withOpacity(0.1),
      ),
      additionalOptions: (context) {
        return [
          OptionItem(
            onTap: (context) {
              final current = _videoPlayerController!.value.position;
              _videoPlayerController!.seekTo(current - const Duration(seconds: 15));
              Navigator.pop(context);
            },
            iconData: Icons.replay_10,
            title: '-15 Seconds',
          ),
          OptionItem(
            onTap: (context) {
              final current = _videoPlayerController!.value.position;
              _videoPlayerController!.seekTo(current + const Duration(seconds: 15));
              Navigator.pop(context);
            },
            iconData: Icons.forward_10,
            title: '+15 Seconds',
          ),
        ];
      },
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  Future<void> _handleDownload(BookIntroVideo video) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      final downloader = ref.read(videoDownloadServiceProvider);
      await downloader.downloadVideo(
        video.bookId,
        video.streamUrl,
        (progress) => setState(() => _downloadProgress = progress),
      );
      
      ref.invalidate(bookIntroVideoProvider(widget.bookId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleDelete(BookIntroVideo video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Supprimer la vidéo ?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('Cela libérera de l\'espace sur votre disque.', style: TextStyle(color: Color(0xFFACACAC), fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final downloader = ref.read(videoDownloadServiceProvider);
      await downloader.deleteDownloadedVideo(video.bookId);
      ref.invalidate(bookIntroVideoProvider(widget.bookId));
      
      // Clean up players
      _videoPlayerController?.dispose();
      _chewieController?.dispose();
      _youtubeController?.close();
      setState(() {
        _videoPlayerController = null;
        _chewieController = null;
        _youtubeController = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(bookIntroVideoProvider(widget.bookId));

    return Card(
      margin: const EdgeInsets.all(20),
      color: const Color(0xFF1E1E1E), 
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRÉSENTATION VIDÉO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.bookName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                videoAsync.when(
                  data: (video) => IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFACACAC)),
                    onPressed: () => _showMediaEditor(video),
                    tooltip: 'Modifier les médias',
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          videoAsync.when(
            data: (video) {
              if (video == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'Aucune vidéo n\'est configurée pour ce livre.',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showMediaEditor(null),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ajouter une vidéo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFACACAC),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _youtubeController != null 
                        ? YoutubePlayer(controller: _youtubeController!)
                        : _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                if (video.thumbnailUrl != null)
                                  Image.network(
                                    video.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                                  ),
                                Container(color: Colors.black.withOpacity(0.4)),
                                if (_isInitializing)
                                  const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                else
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, size: 48, color: Colors.white),
                                    onPressed: () => _initializePlayer(video),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                video.localPath == null 
                                  ? (_isYoutube(video.streamUrl) ? 'Streaming YouTube' : 'Streaming Direct')
                                  : 'Local (Hors-ligne)',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (video.localPath == null && !_isYoutube(video.streamUrl))
                          _isDownloading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    value: _downloadProgress,
                                    strokeWidth: 2,
                                    color: const Color(0xFFACACAC),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download, color: Color(0xFFACACAC), size: 18),
                                  onPressed: () => _handleDownload(video),
                                  tooltip: 'Télécharger pour un accès hors-ligne',
                                )
                        else if (video.localPath != null)
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFFACACAC), size: 18),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                onPressed: () => _handleDelete(video),
                                tooltip: 'Supprimer du cache local',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, st) => AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(child: Text('Erreur: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
