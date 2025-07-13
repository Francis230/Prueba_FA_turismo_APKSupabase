import 'package:prueba_apkturismo_sbfr/core/providers/user_provider.dart';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';
import 'package:prueba_apkturismo_sbfr/sites/widgets/add_review_form.dart'; // <-- Importa el nuevo widget
import 'package:prueba_apkturismo_sbfr/sites/widgets/review_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SiteDetailPage extends StatefulWidget {
  final int siteId;
  const SiteDetailPage({super.key, required this.siteId});

  @override
  State<SiteDetailPage> createState() => _SiteDetailPageState();
}

class _SiteDetailPageState extends State<SiteDetailPage> {
  late Future<Map<String, dynamic>> _siteDetailsFuture;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _pageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadData() {
    _siteDetailsFuture = context.read<SupabaseService>().getSiteDetails(widget.siteId);
  }

  Future<void> _launchMap(double latitude, double longitude) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa.')));
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(child: Image.network(imageUrl)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(userProvider.userProfile?.username ?? 'Usuario', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Text(
                      userProvider.userProfile?.username?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _siteDetailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(heightFactor: 10, child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(child: Text('Error al cargar el sitio: ${snapshot.error}'));
                  }

                  final site = snapshot.data!;
                  final photos = (site['photos'] as List).map((p) => p['image_url'] as String).toList();
                  final latitude = site['latitude'] as double;
                  final longitude = site['longitude'] as double;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInteractivePhotoGallery(photos),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(site['title'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Publicado por: ${site['profiles']?['username'] ?? 'Anónimo'}', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 16),
                            Text(site['description'], style: const TextStyle(fontSize: 16, height: 1.5)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Ver en el Mapa'),
                              onPressed: () => _launchMap(latitude, longitude),
                              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text('Reseñas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      _buildReviewsSection(),
                      // Usamos el nuevo widget autocontenido para el formulario.
                      AddReviewForm(siteId: widget.siteId),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractivePhotoGallery(List<String> photos) {
    if (photos.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey.shade800,
        child: const Center(child: Icon(Icons.location_city, size: 60, color: Colors.white30)),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(context, photos[index]),
                    child: Image.network(
                      photos[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stack) => const Icon(Icons.error),
                    ),
                  );
                },
              ),
              if (photos.length > 1)
                Positioned(
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  ),
                ),
              if (photos.length > 1)
                Positioned(
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (photos.length > 1)
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                bool isSelected = _pageController.hasClients ? (_pageController.page?.round() == index) : (index == 0);
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                        width: 2,
                      ),
                      image: DecorationImage(image: NetworkImage(photos[index]), fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<SupabaseService>().getReviewsStream(widget.siteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Sé el primero en dejar una reseña.')));
        }
        final reviews = snapshot.data!;
        return Column(
          children: reviews.map((review) => ReviewWidget(key: ValueKey(review['id']), 
          review: review)).toList(),
        );
      },
    );
  }
}
