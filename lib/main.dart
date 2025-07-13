import 'package:prueba_apkturismo_sbfr/auth/login_page.dart';
import 'package:prueba_apkturismo_sbfr/auth/register_page.dart';
import 'package:prueba_apkturismo_sbfr/auth/splash_page.dart';
import 'package:prueba_apkturismo_sbfr/core/providers/user_provider.dart';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';
import 'package:prueba_apkturismo_sbfr/home/home_page.dart';
import 'package:prueba_apkturismo_sbfr/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Asegura que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // REEMPLAZA con tus propias credenciales de Supabase.
  await Supabase.initialize(
    url: 'https://helpdjfhqnnszqgjcyuu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhlbHBkamZocW5uc3pxZ2pjeXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyOTc0NjQsImV4cCI6MjA2Mzg3MzQ2NH0.3uCIEkgCnMvdEY1Ul8wUnnvFdXot-2Q8_1EhLHbhtEg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider para proveer los servicios y providers a toda la app
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(create: (_) => SupabaseService()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'El Búho Turístico',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        // La ruta inicial es la SplashPage, que decidirá a dónde redirigir al usuario
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}