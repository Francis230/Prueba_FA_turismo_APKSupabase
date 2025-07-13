import 'package:prueba_apkturismo_sbfr/core/providers/user_provider.dart';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';
import 'package:prueba_apkturismo_sbfr/sites/edit_site_page.dart';
import 'package:prueba_apkturismo_sbfr/sites/site_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SiteCard extends StatelessWidget {
  final Map<String, dynamic> site;
  final VoidCallback onSiteChanged;

  const SiteCard({super.key, required this.site, required this.onSiteChanged});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Borrado'),
        content: const Text('¿Estás seguro de que quieres borrar este sitio? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteSite(context);
            },
            child: Text('Borrar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSite(BuildContext context) async {
    try {
      await context.read<SupabaseService>().deleteSite(site['id']);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sitio borrado con éxito'), backgroundColor: Colors.green));
      onSiteChanged();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al borrar el sitio: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final author = site['profiles']?['username'] ?? 'Anónimo';
    final isOwner = userProvider.userProfile?.id == site['user_id'];

    final photos = site['photos'] as List?;
    final previewImageUrl = (photos != null && photos.isNotEmpty) ? photos.first['image_url'] : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SiteDetailPage(siteId: site['id'])),
          );
          onSiteChanged();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Vista previa de la imagen con efecto de gradiente ---
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                if (previewImageUrl != null)
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      previewImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  )
                else
                  Container(
                    height: 200,
                    color: Colors.grey.shade800,
                    child: const Center(child: Icon(Icons.location_city, size: 60, color: Colors.white30)),
                  ),
                // Gradiente para que el texto sea legible sobre la imagen
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),
                // Título sobre la imagen
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    site['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                    ),
                  ),
                ),
                // Menú CRUD en la esquina superior derecha
                if (userProvider.isPublicador && isOwner)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => EditSitePage(site: site)),
                          );
                          if (result == true) onSiteChanged();
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
                        const PopupMenuItem<String>(value: 'delete', child: Text('Borrar')),
                      ],
                    ),
                  ),
              ],
            ),
            // --- Descripción y autor debajo de la imagen ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site['description'] ?? 'Sin descripción.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Publicado por: $author',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}