import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  PatientProfile? _currentProfile;
  bool _isLoading = true; // Start as true while restoring session
  bool _isSigningUp = false; // Guard to block stream during signup
  StreamSubscription<sb.AuthState>? _authSubscription;

  final sb.SupabaseClient _supabase = sb.Supabase.instance.client;

  User? get currentUser => _currentUser;
  PatientProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Restore session persisted from a previous run
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserFromSession(session.user);
    }

    _isLoading = false;
    notifyListeners();

    // Listen for auth state changes (login, logout, token refresh, etc.)
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (data) async {
        // Skip stream events during signup — we handle state manually there
        if (_isSigningUp) return;

        final event = data.event;
        final sbUser = data.session?.user;
        if (event == sb.AuthChangeEvent.signedIn && sbUser != null) {
          await _loadUserFromSession(sbUser);
          notifyListeners();
        } else if (event == sb.AuthChangeEvent.signedOut) {
          _currentUser = null;
          _currentProfile = null;
          notifyListeners();
        }
      },
    );
  }

  Future<void> _loadUserFromSession(sb.User sbUser) async {
    // Derive username: strip the @medinutri.io suffix if present
    final email = sbUser.email ?? '';
    final username = email.endsWith('@medinutri.io')
        ? email.replaceAll('@medinutri.io', '')
        : email;
    _currentUser = User(id: sbUser.id, username: username);
    _currentProfile = await SupabaseService.instance.getProfile(sbUser.id);
    debugPrint('Session restored for: ${sbUser.id}, profile: ${_currentProfile != null}');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Mapping username to a virtual email for Supabase Auth consistency
  String _mapUsernameToEmail(String input) {
    final cleaned = input.toLowerCase().trim();
    if (cleaned.contains('@') && cleaned.contains('.')) {
      return cleaned; // It's already an email
    }
    // Sanitize username (replace symbols that break email format)
    final sanitized = cleaned.replaceAll(RegExp(r'[^a-z0-9._]'), '_');
    return "$sanitized@medinutri.io";
  }

  Future<String?> signUp(String username, String password, PatientProfile profileData) async {
    _isLoading = true;
    _isSigningUp = true; // Block auth stream during signup
    notifyListeners();

    try {
      final email = _mapUsernameToEmail(username);
      debugPrint("Attempting Sign Up with email: $email");

      // Supabase Sign Up
      final sb.AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final sbUser = res.user;
      debugPrint("Supabase Sign Up logic finished. User: ${sbUser?.id}");

      if (sbUser == null) throw Exception("Erreur lors de la création du compte.");

      // Create Profile row in Supabase
      final profile = PatientProfile(
        userId: sbUser.id,
        name: profileData.name,
        age: profileData.age,
        gender: profileData.gender,
        weight: profileData.weight,
        height: profileData.height,
      );

      await SupabaseService.instance.saveProfile(profile);
      debugPrint("Profile saved successfully for ${sbUser.id}");

      // Manually set state — stream was blocked during signup
      _currentUser = User(id: sbUser.id, username: username);
      _currentProfile = profile;

      _isLoading = false;
      _isSigningUp = false;
      notifyListeners();
      return null; // Success
    } on sb.AuthException catch (e) {
      debugPrint("Supabase Auth Error (Sign Up): ${e.message} (Code: ${e.statusCode})");
      _isLoading = false;
      _isSigningUp = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      debugPrint("General Error (Sign Up): $e");
      _isLoading = false;
      _isSigningUp = false;
      notifyListeners();
      return "Une erreur est survenue lors de l'inscription.";
    }
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final email = _mapUsernameToEmail(username);
      debugPrint("Attempting Login with email: $email");

      final sb.AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        debugPrint("Supabase Login failed: User is null despite no exception");
        _isLoading = false;
        notifyListeners();
        return "Nom d'utilisateur ou mot de passe incorrect.";
      }

      // _currentUser and _currentProfile are set by the auth stream listener.
      // We just stop the loading indicator here.
      debugPrint("Supabase Login Success. User: ${res.user!.id}");
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on sb.AuthException catch (e) {
      debugPrint("Supabase Auth Error (Login): ${e.message}");
      _isLoading = false;
      notifyListeners();
      return "Nom d'utilisateur ou mot de passe incorrect.";
    } catch (e) {
      debugPrint("General Error (Login): $e");
      _isLoading = false;
      notifyListeners();
      return "Erreur de connexion.";
    }
  }

  Future<String?> updateProfile(PatientProfile profile, {File? imageFile}) async {
    String? newPhotoPath = profile.photoPath;

    // If there is a new local image to upload
    if (imageFile != null && _currentUser?.id != null) {
      try {
        final cloudUrl = await SupabaseService.instance.uploadProfilePhoto(
          _currentUser!.id!,
          imageFile,
        );
        if (cloudUrl != null) {
          newPhotoPath = cloudUrl;
        }
      } catch (e) {
        debugPrint('[AuthProvider] upload error: $e');
        return "Erreur lors de l'envoi de la photo : $e";
      }
    }

    final updatedWithPhoto = profile.copyWithPhoto(newPhotoPath);
    final error = await SupabaseService.instance.saveProfile(updatedWithPhoto);
    if (error == null) {
      _currentProfile = updatedWithPhoto;
      notifyListeners();
    }
    return error;
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return "Utilisateur non connecté.";
    
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on sb.AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Erreur lors du changement de mot de passe.";
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _currentProfile = null;
    notifyListeners();
  }
}
