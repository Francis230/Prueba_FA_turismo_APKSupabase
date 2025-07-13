// 1. lib/auth/splash_page.dart
import 'package:prueba_apkturismo_sbfr/core/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 1));
    final session = Supabase.instance.client.auth.currentSession;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (mounted) {
      if (session != null) {
        await userProvider.loadUserProfile();
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        userProvider.clearUserProfile();
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // El ícono se generará automáticamente con flutter_launcher_icons
            // pero podemos poner un placeholder.
            Icon(
              Icons.landscape, // Icono de paisaje
              size: 100,
              color: Theme.of(context).colorScheme.secondary, // Usa el color de acento dorado
            ),
            SizedBox(height: 24),
            Text(
              "Búhomap Turístico",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(221, 255, 255, 255),
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}