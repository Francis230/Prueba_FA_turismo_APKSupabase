import 'package:flutter/material.dart';
import 'package:prueba_apkturismo_sbfr/core/models/user_profile.dart';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';

class ReplyWidget extends StatelessWidget {
  final Map<String, dynamic> reply;
  const ReplyWidget({super.key, required this.reply});

  @override
  Widget build(BuildContext context) {
    final userId = reply['user_id'];

    return FutureBuilder<UserProfile?>(
      future: SupabaseService().getProfileById(userId),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final profile = snapshot.data;
        final author = profile?.username ?? 'Usuario';
        final avatarUrl = profile?.avatarUrl;

        return Padding(
          padding: const EdgeInsets.only(left: 56, top: 8, right: 16, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                child: (avatarUrl == null) ? Text(author.substring(0, 1).toUpperCase()) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? const Text('Cargando...', style: TextStyle(fontStyle: FontStyle.italic))
                        : Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(reply['content']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
