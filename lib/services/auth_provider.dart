import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/database_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  PatientProfile? _currentProfile;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  PatientProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<String?> signUp(String username, String password, PatientProfile profileData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      
      // Hash password
      final passwordHash = _hashPassword(password);
      
      // Create User
      final userId = await db.insert('users', {
        'username': username,
        'password_hash': passwordHash,
      });

      // Create Profile linked to User
      final profile = PatientProfile(
        userId: userId,
        name: profileData.name,
        age: profileData.age,
        gender: profileData.gender,
        weight: profileData.weight,
        height: profileData.height,
      );
      
      await db.insert('profiles', profile.toMap());

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Une erreur est survenue lors de l'inscription.";
    }
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final passwordHash = _hashPassword(password);

      final List<Map<String, dynamic>> users = await db.query(
        'users',
        where: 'username = ? AND password_hash = ?',
        whereArgs: [username, passwordHash],
      );

      if (users.isNotEmpty) {
        _currentUser = User.fromMap(users.first);
        
        final List<Map<String, dynamic>> profiles = await db.query(
          'profiles',
          where: 'user_id = ?',
          whereArgs: [_currentUser!.id],
        );
        
        if (profiles.isNotEmpty) {
          _currentProfile = PatientProfile.fromMap(profiles.first);
        }
        
        _isLoading = false;
        notifyListeners();
        return null; // Success
      } else {
        _isLoading = false;
        notifyListeners();
        return "Nom d'utilisateur ou mot de passe incorrect.";
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Erreur de connexion.";
    }
  }

  Future<void> updateProfile(PatientProfile profile) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
    _currentProfile = profile;
    notifyListeners();
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return "Utilisateur non connecté.";
    
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final currentHash = _hashPassword(currentPassword);

      if (_currentUser!.passwordHash != currentHash) {
        _isLoading = false;
        notifyListeners();
        return "L'ancien mot de passe est incorrect.";
      }

      final newHash = _hashPassword(newPassword);
      await db.update(
        'users',
        {'password_hash': newHash},
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      // Update local state
      _currentUser = User(
        id: _currentUser!.id,
        username: _currentUser!.username,
        passwordHash: newHash,
      );

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Erreur lors du changement de mot de passe.";
    }
  }

  void logout() {
    _currentUser = null;
    _currentProfile = null;
    notifyListeners();
  }
}
