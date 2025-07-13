import 'package:prueba_apkturismo_sbfr/core/models/user_profile.dart';
import 'package:prueba_apkturismo_sbfr/core/providers/user_provider.dart';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';
import 'package:prueba_apkturismo_sbfr/sites/widgets/reply_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReviewWidget extends StatefulWidget {
  final Map<String, dynamic> review;
  const ReviewWidget({super.key, required this.review});

  @override
  State<ReviewWidget> createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  late Future<UserProfile?> _authorProfileFuture;
  bool _showReplies = false;

  @override
  void initState() {
    super.initState();
    final authorId = widget.review['user_id'];
    if (authorId != null) {
      _authorProfileFuture = context.read<SupabaseService>().getProfileById(authorId);
    } else {
      _authorProfileFuture = Future.value(null);
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('d MMM. yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Borrado'),
        content: const Text('¿Estás seguro? Esta acción es permanente.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: Text('Borrar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rating = widget.review['rating'] ?? 0;
    final createdAt = _formatDateTime(widget.review['created_at']);
    final userProvider = context.read<UserProvider>();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserProfile?>(
              future: _authorProfileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(children: [CircleAvatar(radius: 20), SizedBox(width: 12), Text('Cargando...')]);
                }
                final authorProfile = snapshot.data;
                final author = authorProfile?.username ?? 'Usuario';
                final avatarUrl = authorProfile?.avatarUrl;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                      child: (avatarUrl == null) ? Text(author.substring(0, 1).toUpperCase()) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              ...List.generate(5, (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: Theme.of(context).colorScheme.secondary, size: 16)),
                              const SizedBox(width: 8),
                              Text(createdAt, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (userProvider.isPublicador)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          _showDeleteConfirmation(context, () async {
                            await context.read<SupabaseService>().deleteReview(widget.review['id']);
                            if (mounted) setState(() {});
                          });
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(widget.review['content'] ?? ''),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _showReplies = !_showReplies),
              child: Text(_showReplies ? 'Ocultar Respuestas' : 'Ver Respuestas'),
            ),
            if (_showReplies)
              RepliesSection(reviewId: widget.review['id']),
          ],
        ),
      ),
    );
  }
}

class RepliesSection extends StatefulWidget {
  final int reviewId;
  const RepliesSection({super.key, required this.reviewId});

  @override
  State<RepliesSection> createState() => _RepliesSectionState();
}

class _RepliesSectionState extends State<RepliesSection> {
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();
  bool _isPostingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _postReply() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _isPostingReply = true);
    try {
      await context.read<SupabaseService>().postReply(
            reviewId: widget.reviewId,
            content: _replyController.text.trim(),
          );
      _replyController.clear();
      _replyFocusNode.unfocus();
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar respuesta: $e')));
    } finally {
      if (mounted) setState(() => _isPostingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabaseService = context.read<SupabaseService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabaseService.getRepliesStream(widget.reviewId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Padding(padding: EdgeInsets.all(8.0), child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Padding(padding: EdgeInsets.all(8.0), child: Text('No hay respuestas aún.'));
            }
            final replies = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: replies.length,
              itemBuilder: (context, index) {
                return ReplyWidget(
                  key: ValueKey(replies[index]['id']),
                  reply: replies[index],
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _replyController,
          focusNode: _replyFocusNode,
          decoration: InputDecoration(
            hintText: 'Escribe una respuesta...',
            suffixIcon: _isPostingReply
                ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _postReply,
                  ),
          ),
        ),
      ],
    );
  }
}
