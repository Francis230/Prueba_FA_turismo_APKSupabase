import 'package:prueba_apkturismo_sbfr/core/providers/user_provider.dart';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';
import 'package:prueba_apkturismo_sbfr/sites/add_site_page.dart';
import 'package:prueba_apkturismo_sbfr/sites/widgets/site_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _sitesFuture;

  @override
  void initState() {
    super.initState();
    _refreshSites();
  }

  void _refreshSites() {
    setState(() {
      _sitesFuture = context.read<SupabaseService>().getSites();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final supabaseService = context.read<SupabaseService>();
    await supabaseService.signOut();

    if (context.mounted) {
      context.read<UserProvider>().clearUserProfile();

      // Espera un frame para asegurarse que Navigator.pop() del loading
      Navigator.of(context).pop();

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    userProvider.userProfile?.username?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bienvenido', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      userProvider.userProfile?.username ?? 'Usuario',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout_outlined, color: Colors.white),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => _refreshSites(),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _sitesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar sitios: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aún no hay sitios publicados.\n¡Sé el primero en añadir uno!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final sites = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sites.length,
                  itemBuilder: (context, index) {
                    final site = sites[index];
                    return SiteCard(site: site, onSiteChanged: _refreshSites);
                  },
                );
              },
            ),
          ),
          floatingActionButton: userProvider.isPublicador
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddSitePage()),
                    );
                    _refreshSites();
                  },
                  label: const Text('Añadir Sitio'),
                  icon: const Icon(Icons.add_location_alt_outlined),
                )
              : null,
        );
      },
    );
  }
}
