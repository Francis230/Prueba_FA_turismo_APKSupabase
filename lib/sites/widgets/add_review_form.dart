import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Este es un widget autocontenido que maneja su propio estado.
class AddReviewForm extends StatefulWidget {
  final int siteId;
  const AddReviewForm({super.key, required this.siteId});

  @override
  State<AddReviewForm> createState() => _AddReviewFormState();
}

class _AddReviewFormState extends State<AddReviewForm> {
  final _reviewController = TextEditingController();
  int _currentRating = 5;
  bool _isPosting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _postReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, escribe una reseña.')));
      return;
    }
    setState(() => _isPosting = true);
    try {
      await context.read<SupabaseService>().postReview(
        siteId: widget.siteId,
        content: _reviewController.text.trim(),
        rating: _currentRating,
      );
      _reviewController.clear();
      FocusScope.of(context).unfocus();
      // Reseteamos las estrellas al valor por defecto
      setState(() => _currentRating = 5); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reseña publicada con éxito')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al publicar reseña: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deja tu reseña', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Las estrellas ahora solo reconstruyen este widget, no toda la página.
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _currentRating ? Icons.star : Icons.star_border,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 30,
                ),
                onPressed: () {
                  // setState aquí solo afecta a _AddReviewFormState.
                  setState(() => _currentRating = index + 1);
                },
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            decoration: const InputDecoration(
              hintText: 'Escribe tu opinión...',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _isPosting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _postReview,
                  child: const Text('Publicar Reseña'),
                ),
        ],
      ),
    );
  }
}