import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/bible_models.dart';
import '../providers/bible_providers.dart';
import '../providers/video_providers.dart';

class MediaEditorDialog extends ConsumerStatefulWidget {
  final BookIntroVideo? initialVideo;
  final String bookId;
  final String bookName;

  const MediaEditorDialog({
    super.key,
    this.initialVideo,
    required this.bookId,
    required this.bookName,
  });

  @override
  ConsumerState<MediaEditorDialog> createState() => _MediaEditorDialogState();
}

class _MediaEditorDialogState extends ConsumerState<MediaEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _thumbnailController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialVideo?.title ?? 'Introduction au livre de ${widget.bookName}');
    _urlController = TextEditingController(text: widget.initialVideo?.streamUrl ?? '');
    _thumbnailController = TextEditingController(text: widget.initialVideo?.thumbnailUrl ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final database = ref.read(bibleDatabaseProvider);
    
    final video = BookIntroVideo(
      bookId: widget.bookId,
      title: _titleController.text.trim(),
      streamUrl: _urlController.text.trim(),
      thumbnailUrl: _thumbnailController.text.trim().isEmpty ? null : _thumbnailController.text.trim(),
      localPath: widget.initialVideo?.localPath,
    );

    if (video.streamUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'URL de la vidéo est requise.')),
      );
      return;
    }

    await database.setBookIntroVideo(video);
    ref.invalidate(bookIntroVideoProvider(widget.bookId));
    
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modifier le média : ${widget.bookName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildField('Titre de la vidéo', _titleController, 'Ex: Introduction au livre de...'),
            const SizedBox(height: 16),
            _buildField('URL de la vidéo (Stream)', _urlController, 'Ex: https://.../video.mp4'),
            const SizedBox(height: 16),
            _buildField('URL de la miniature (Optionnel)', _thumbnailController, 'Ex: https://.../image.jpg'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler', style: TextStyle(color: Color(0xFFACACAC))),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2C98D),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFE2C98D)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
