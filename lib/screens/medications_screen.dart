import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/notification_service.dart';
import 'package:medinutri/services/supabase_service.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  List<Medication> _medications = [];
  List<MedicationLog> _todayLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    final meds = await SupabaseService.instance.getMedications(userId);
    final logs = await SupabaseService.instance.getTodayLogs(userId);
    if (mounted) {
      setState(() {
        _medications = meds;
        _todayLogs = logs;
        _isLoading = false;
      });
    }
  }

  double get _adherenceRate {
    if (_medications.isEmpty) return 1.0;
    int totalExpected = 0;
    for (var med in _medications) {
      totalExpected += med.times.length;
    }
    if (totalExpected == 0) return 1.0;
    final taken = _todayLogs.where((l) => l.status == 'taken').length;
    return (taken / totalExpected).clamp(0.0, 1.0);
  }

  bool _isTakenToday(String medId, String time) {
    return _todayLogs.any((l) =>
        l.medicationId == medId &&
        l.scheduledTime == time &&
        l.status == 'taken');
  }

  Future<void> _markTaken(Medication med, String time) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id;
    if (userId == null || med.id == null) return;

    HapticFeedback.mediumImpact();
    final log = MedicationLog(
      medicationId: med.id!,
      userId: userId,
      scheduledTime: time,
      status: 'taken',
    );
    await SupabaseService.instance.logMedication(log);
    await _loadData();
  }

  Future<void> _deleteMed(Medication med) async {
    if (med.id == null) return;
    await NotificationService.instance.cancelMedicationReminders(med.id!);
    await SupabaseService.instance.deleteMedication(med.id!);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mes Médicaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: ThemeNotifier.primaryGradient),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddMedicationSheet(context, isDark),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Adherence card
                  _buildAdherenceCard(isDark).animate().fadeIn().slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),

                  if (_medications.isEmpty)
                    _buildEmptyState(isDark)
                  else ...[
                    Text(
                      'Traitements actifs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    ..._medications.asMap().entries.map((entry) {
                      return _buildMedicationCard(entry.value, isDark, entry.key)
                          .animate(delay: (300 + entry.key * 100).ms)
                          .fadeIn()
                          .slideX(begin: 0.05, end: 0);
                    }),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildAdherenceCard(bool isDark) {
    final percent = (_adherenceRate * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? const Color(0xFF121212) : null,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : const Color(0xFF0D9488).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _adherenceRate,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    percent >= 80 ? Colors.greenAccent : (percent >= 50 ? Colors.orangeAccent : Colors.redAccent),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adhérence aujourd\'hui',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _medications.isEmpty
                      ? 'Ajoutez vos médicaments pour commencer'
                      : '${_todayLogs.where((l) => l.status == 'taken').length} prise(s) sur ${_medications.fold<int>(0, (sum, m) => sum + m.times.length)} prévue(s)',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication med, bool isDark, int index) {
    final color = _parseColor(med.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : color.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : color.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medication_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    if (med.dosage.isNotEmpty)
                      Text(
                        med.dosage,
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[500], fontSize: 13),
                      ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.redAccent.withValues(alpha: 0.6), size: 20),
                onPressed: () => _showDeleteDialog(med),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Frequency badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  med.frequencyLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
              if (med.notes.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    med.notes,
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Time chips with take action
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: med.times.map((time) {
              final taken = _isTakenToday(med.id ?? '', time);
              return GestureDetector(
                onTap: taken ? null : () => _markTaken(med, time),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: taken
                        ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)])
                        : null,
                    color: taken ? null : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(12),
                    border: taken ? null : Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        taken ? Icons.check_circle : Icons.access_time_rounded,
                        size: 16,
                        color: taken ? Colors.white : (isDark ? Colors.white60 : Colors.grey[500]),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: taken ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                      if (!taken) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Prendre',
                          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.medication_outlined, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun médicament',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez vos traitements pour\nrecevoir des rappels intelligents.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  void _showDeleteDialog(Medication med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce médicament ?'),
        content: Text('${med.name} sera supprimé définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteMed(med);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddMedicationSheet(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String frequency = 'daily';
    List<String> times = ['08:00'];
    String selectedColor = '#0D9488';

    final colors = ['#0D9488', '#EF4444', '#3B82F6', '#F59E0B', '#8B5CF6', '#EC4899', '#10B981'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF121212) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Ajouter un médicament', style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                )),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom du médicament',
                    prefixIcon: Icon(Icons.medication, color: Color(0xFF0D9488)),
                  ),
                ),
                const SizedBox(height: 14),

                // Dosage
                TextFormField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dosage (ex: 500mg)',
                    prefixIcon: Icon(Icons.science_outlined, color: Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(height: 14),

                // Frequency
                DropdownButtonFormField<String>(
                  initialValue: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence',
                    prefixIcon: Icon(Icons.repeat, color: Color(0xFFF59E0B)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Chaque jour')),
                    DropdownMenuItem(value: 'twice_daily', child: Text('2 fois/jour')),
                    DropdownMenuItem(value: 'three_daily', child: Text('3 fois/jour')),
                    DropdownMenuItem(value: 'weekly', child: Text('Chaque semaine')),
                    DropdownMenuItem(value: 'as_needed', child: Text('Si nécessaire')),
                  ],
                  onChanged: (val) {
                    setSheetState(() {
                      frequency = val ?? 'daily';
                      if (frequency == 'twice_daily') {
                        times = ['08:00', '20:00'];
                      } else if (frequency == 'three_daily') {
                        times = ['08:00', '14:00', '20:00'];
                      } else {
                        times = ['08:00'];
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Times
                Text('Heures de prise', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: times.asMap().entries.map((e) {
                    return ActionChip(
                      avatar: const Icon(Icons.access_time, size: 16),
                      label: Text(e.value),
                      onPressed: () async {
                        final parts = e.value.split(':');
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay(
                            hour: int.tryParse(parts[0]) ?? 8,
                            minute: int.tryParse(parts[1]) ?? 0,
                          ),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            times[e.key] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Color selection
                Text('Couleur', style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                )),
                const SizedBox(height: 8),
                Row(
                  children: colors.map((c) {
                    final isSelected = c == selectedColor;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _parseColor(c),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: isSelected ? [BoxShadow(color: _parseColor(c).withValues(alpha: 0.4), blurRadius: 8)] : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Notes
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optionnel)',
                    prefixIcon: Icon(Icons.notes, color: Color(0xFF8B5CF6)),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: ThemeNotifier.primaryGradient),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final auth = Provider.of<AuthProvider>(ctx, listen: false);
                        final userId = auth.currentUser?.id;
                        if (userId == null) return;

                        final med = Medication(
                          userId: userId,
                          name: nameCtrl.text.trim(),
                          dosage: dosageCtrl.text.trim(),
                          frequency: frequency,
                          times: times,
                          notes: notesCtrl.text.trim(),
                          color: selectedColor,
                        );

                        Navigator.pop(ctx);
                        final error = await SupabaseService.instance.saveMedication(med);
                        if (error == null) {
                          // Schedule notifications
                          final meds = await SupabaseService.instance.getMedications(userId);
                          if (meds.isNotEmpty) {
                            final saved = meds.first;
                            await NotificationService.instance.scheduleMedicationReminders(
                              medicationId: saved.id!,
                              medicationName: saved.name,
                              dosage: saved.dosage,
                              times: saved.times,
                            );
                          }
                        }
                        if (!mounted) return;
                        await _loadData();
                        if (!context.mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error ?? '💊 ${med.name} ajouté avec rappels !'),
                            backgroundColor: error != null ? Colors.redAccent : const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Ajouter le médicament', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF0D9488);
    }
  }
}
