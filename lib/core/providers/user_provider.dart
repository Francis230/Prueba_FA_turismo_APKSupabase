// 3. lib/core/providers/user_provider.dart
import 'package:prueba_apkturismo_sbfr/core/models/user_profile.dart';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  final SupabaseService _supabaseService = SupabaseService();

  UserProfile? get userProfile => _userProfile;
  bool get isPublicador => _userProfile?.role == 'Publicador';

  Future<void> loadUserProfile() async {
    try {
      final profile = await _supabaseService.getProfile();
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando el perfil: $e');
      _userProfile = null;
      notifyListeners();
    }
  }

  void clearUserProfile() {
    _userProfile = null;
    notifyListeners();
  }
}