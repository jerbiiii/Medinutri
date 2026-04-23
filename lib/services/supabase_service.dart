import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medinutri/models/health_models.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseService._init();

  // ─────────────────────────────────────────────────────────
  //  PROFILE
  // ─────────────────────────────────────────────────────────

  Future<PatientProfile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) return null;
      return PatientProfile.fromMap(response);
    } catch (e) {
      debugPrint('[SupabaseService] getProfile ERROR: $e');
      return null;
    }
  }

  /// Returns null on success, error string on failure.
  Future<String?> saveProfile(PatientProfile profile) async {
    try {
      final data = profile.toMap();
      data.remove('id'); // Let Supabase manage the PK
      debugPrint('[SupabaseService] saveProfile for user_id: ${profile.userId}');
      await _client
          .from('profiles')
          .upsert(data, onConflict: 'user_id');
      debugPrint('[SupabaseService] saveProfile SUCCESS');
      return null;
    } catch (e) {
      debugPrint('[SupabaseService] saveProfile ERROR: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  CHAT HISTORY
  // ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getActiveChatHistory(String userId) async {
    try {
      return await _client
          .from('chat_history')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', false)
          .order('timestamp', ascending: true);
    } catch (e) {
      debugPrint('[SupabaseService] getActiveChatHistory ERROR: $e');
      return [];
    }
  }

  Future<void> addMessage(String userId, Map<String, dynamic> messageData) async {
    try {
      await _client.from('chat_history').insert({
        'user_id': userId,
        ...messageData,
      });
    } catch (e) {
      debugPrint('[SupabaseService] addMessage ERROR: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getArchivedMessages(String userId) async {
    try {
      return await _client
          .from('chat_history')
          .select()
          .eq('user_id', userId)
          .eq('is_archived', true)
          .order('timestamp', ascending: false);
    } catch (e) {
      debugPrint('[SupabaseService] getArchivedMessages ERROR: $e');
      return [];
    }
  }

  Future<void> archiveConversation(
      String userId, String conversationId, String title) async {
    try {
      await _client
          .from('chat_history')
          .update({'is_archived': true, 'conversation_title': title})
          .eq('user_id', userId)
          .eq('conversation_id', conversationId)
          .eq('is_archived', false);
    } catch (e) {
      debugPrint('[SupabaseService] archiveConversation ERROR: $e');
    }
  }

  Future<void> deleteArchivedMessages(String userId) async {
    try {
      await _client
          .from('chat_history')
          .delete()
          .eq('user_id', userId)
          .eq('is_archived', true);
    } catch (e) {
      debugPrint('[SupabaseService] deleteArchivedMessages ERROR: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  NUTRITION PLAN
  // ─────────────────────────────────────────────────────────

  Future<NutritionPlan?> getLatestNutritionPlan(String userId) async {
    try {
      final response = await _client
          .from('nutrition_plans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return NutritionPlan.fromMap(response);
    } catch (e) {
      debugPrint('[SupabaseService] getLatestNutritionPlan ERROR: $e');
      return null;
    }
  }

  /// Returns null on success, error string on failure.
  Future<String?> saveNutritionPlan(NutritionPlan plan) async {
    try {
      debugPrint('[SupabaseService] saveNutritionPlan for user: ${plan.userId}');
      await _client.from('nutrition_plans').delete().eq('user_id', plan.userId);
      await _client.from('nutrition_plans').insert(plan.toMap());
      debugPrint('[SupabaseService] saveNutritionPlan SUCCESS');
      return null;
    } catch (e) {
      debugPrint('[SupabaseService] saveNutritionPlan ERROR: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  AI DOCTORS
  // ─────────────────────────────────────────────────────────

  Future<List<Doctor>> getAiDoctors() async {
    try {
      final response = await _client.from('ai_doctors').select();
      return response.map((data) => Doctor.fromMap(data)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] getAiDoctors ERROR: $e');
      return [];
    }
  }

  Future<void> clearAndSaveAiDoctors(List<Doctor> doctors) async {
    try {
      await _client.from('ai_doctors').delete().neq('doctor_id', '');
      final now = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> data = doctors.map((d) {
        final map = d.toMap();
        map['doctor_id'] = map['id'];
        map.remove('id');
        map['created_at'] = now;
        return map;
      }).toList();
      await _client.from('ai_doctors').insert(data);
    } catch (e) {
      debugPrint('[SupabaseService] clearAndSaveAiDoctors ERROR: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  STORAGE
  // ─────────────────────────────────────────────────────────

  Future<String?> uploadProfilePhoto(String userId, File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = 'photo_$userId.$fileExt';
      final storagePath = 'avatars/$fileName';

      debugPrint('[SupabaseService] Uploading to Storage: profiles/$storagePath');
      
      // Use upsert: true to overwrite if exists
      await _client.storage.from('profiles').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // Add cache-busting query param so Flutter doesn't serve stale cached image
      final baseUrl = _client.storage.from('profiles').getPublicUrl(storagePath);
      final url = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('[SupabaseService] Upload success, Public URL: $url');
      return url;
    } catch (e) {
      debugPrint('[SupabaseService] uploadProfilePhoto ERROR: $e');
      rethrow; // Rethrow to allow AuthProvider to catch and report
    }
  }

  // ─────────────────────────────────────────────────────────
  //  MEDICATIONS
  // ─────────────────────────────────────────────────────────

  Future<List<Medication>> getMedications(String userId) async {
    try {
      final response = await _client
          .from('medications')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return response.map((data) => Medication.fromMap(data)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] getMedications ERROR: $e');
      return [];
    }
  }

  Future<String?> saveMedication(Medication medication) async {
    try {
      final data = medication.toMap();
      data.remove('id');
      if (medication.id != null) {
        await _client
            .from('medications')
            .update(data)
            .eq('id', medication.id!);
      } else {
        await _client.from('medications').insert(data);
      }
      return null;
    } catch (e) {
      debugPrint('[SupabaseService] saveMedication ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> deleteMedication(String medicationId) async {
    try {
      await _client.from('medications').delete().eq('id', medicationId);
      return null;
    } catch (e) {
      debugPrint('[SupabaseService] deleteMedication ERROR: $e');
      return e.toString();
    }
  }

  Future<String?> deactivateMedication(String medicationId) async {
    try {
      await _client
          .from('medications')
          .update({'is_active': false})
          .eq('id', medicationId);
      return null;
    } catch (e) {
      debugPrint('[SupabaseService] deactivateMedication ERROR: $e');
      return e.toString();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  MEDICATION LOGS
  // ─────────────────────────────────────────────────────────

  Future<String?> logMedication(MedicationLog log) async {
    try {
      await _client.from('medication_logs').insert(log.toMap());
      return null;
    } catch (e) {
      debugPrint('[SupabaseService] logMedication ERROR: $e');
      return e.toString();
    }
  }

  Future<List<MedicationLog>> getMedicationLogs(String userId, {int limit = 50}) async {
    try {
      final response = await _client
          .from('medication_logs')
          .select()
          .eq('user_id', userId)
          .order('taken_at', ascending: false)
          .limit(limit);
      return response.map((data) => MedicationLog.fromMap(data)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] getMedicationLogs ERROR: $e');
      return [];
    }
  }

  Future<List<MedicationLog>> getTodayLogs(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final response = await _client
          .from('medication_logs')
          .select()
          .eq('user_id', userId)
          .gte('taken_at', '${today}T00:00:00')
          .lte('taken_at', '${today}T23:59:59')
          .order('taken_at', ascending: false);
      return response.map((data) => MedicationLog.fromMap(data)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] getTodayLogs ERROR: $e');
      return [];
    }
  }
}
