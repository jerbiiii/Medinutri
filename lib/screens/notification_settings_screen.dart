import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/services/notification_service.dart';
import 'package:medinutri/services/theme_notifier.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _globalEnabled = false;
  bool _breakfastEnabled = true;
  bool _lunchEnabled = true;
  bool _dinnerEnabled = true;
  bool _waterEnabled = false;

  TimeOfDay _breakfastTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 30);

  bool _isLoading = true;

  final _notifService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _globalEnabled = await _notifService.isEnabled;
    _breakfastEnabled = await _notifService.isBreakfastEnabled;
    _lunchEnabled = await _notifService.isLunchEnabled;
    _dinnerEnabled = await _notifService.isDinnerEnabled;
    _waterEnabled = await _notifService.isWaterEnabled;
    _breakfastTime = await _notifService.getBreakfastTime();
    _lunchTime = await _notifService.getLunchTime();
    _dinnerTime = await _notifService.getDinnerTime();

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rappels de Repas'),
        actions: [
          // Test button
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            tooltip: 'Envoyer une notification test',
            onPressed: () async {
              await _notifService.showTestNotification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Notification test envoyée !'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Main ON/OFF card ────────────────────
                  _buildMainToggleCard(isDark, theme)
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),

                  // ── Status indicator ────────────────────
                  _buildStatusBanner(isDark, theme)
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),

                  // ── Meal reminders section ──────────────
                  _buildSectionTitle('Rappels de repas', isDark)
                      .animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 12),

                  _buildMealCard(
                    isDark: isDark,
                    theme: theme,
                    icon: Icons.wb_sunny_rounded,
                    iconColor: Colors.orange,
                    title: 'Petit-déjeuner',
                    subtitle: 'Commencez bien la journée',
                    enabled: _breakfastEnabled,
                    time: _breakfastTime,
                    onToggle: (val) async {
                      setState(() => _breakfastEnabled = val);
                      await _notifService.setBreakfastEnabled(val);
                    },
                    onTimeTap: () => _pickTime(
                      current: _breakfastTime,
                      onPicked: (t) async {
                        setState(() => _breakfastTime = t);
                        await _notifService.setBreakfastTime(t);
                      },
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(),

                  const SizedBox(height: 10),
                  _buildMealCard(
                    isDark: isDark,
                    theme: theme,
                    icon: Icons.restaurant_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Déjeuner',
                    subtitle: 'Rechargez vos batteries',
                    enabled: _lunchEnabled,
                    time: _lunchTime,
                    onToggle: (val) async {
                      setState(() => _lunchEnabled = val);
                      await _notifService.setLunchEnabled(val);
                    },
                    onTimeTap: () => _pickTime(
                      current: _lunchTime,
                      onPicked: (t) async {
                        setState(() => _lunchTime = t);
                        await _notifService.setLunchTime(t);
                      },
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideX(),

                  const SizedBox(height: 10),
                  _buildMealCard(
                    isDark: isDark,
                    theme: theme,
                    icon: Icons.nightlight_round,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Dîner',
                    subtitle: 'Nutrition de fin de journée',
                    enabled: _dinnerEnabled,
                    time: _dinnerTime,
                    onToggle: (val) async {
                      setState(() => _dinnerEnabled = val);
                      await _notifService.setDinnerEnabled(val);
                    },
                    onTimeTap: () => _pickTime(
                      current: _dinnerTime,
                      onPicked: (t) async {
                        setState(() => _dinnerTime = t);
                        await _notifService.setDinnerTime(t);
                      },
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideX(),

                  const SizedBox(height: 24),

                  // ── Hydration section ───────────────────
                  _buildSectionTitle('Hydratation', isDark)
                      .animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 12),

                  _buildWaterCard(isDark, theme)
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .slideX(),

                  const SizedBox(height: 32),

                  // ── Info footer ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D9488).withValues(alpha: 0.06)
                          : const Color(0xFF0D9488).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF0D9488),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Les notifications seront envoyées chaque jour aux heures sélectionnées, même si l\'app est fermée.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  WIDGETS
  // ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ThemeNotifier.primaryGradient,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildMainToggleCard(bool isDark, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _globalEnabled
            ? const LinearGradient(
                colors: ThemeNotifier.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _globalEnabled
            ? null
            : (isDark ? const Color(0xFF121212) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isDark && !_globalEnabled
            ? Border.all(color: Colors.white10)
            : (!_globalEnabled ? Border.all(color: Colors.grey[200]!) : null),
        boxShadow: _globalEnabled
            ? [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _globalEnabled
                  ? Colors.white.withValues(alpha: 0.2)
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[100]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _globalEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: _globalEnabled
                  ? Colors.white
                  : (isDark ? Colors.white38 : Colors.grey[400]),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rappels activés',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _globalEnabled
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _globalEnabled
                      ? 'Vous recevrez des rappels quotidiens'
                      : 'Activez pour ne plus oublier vos repas',
                  style: TextStyle(
                    fontSize: 13,
                    color: _globalEnabled
                        ? Colors.white70
                        : (isDark ? Colors.white38 : Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.15,
            child: Switch.adaptive(
              value: _globalEnabled,
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.3),
              inactiveTrackColor:
                  isDark ? Colors.white12 : Colors.grey[300],
              onChanged: (val) async {
                setState(() => _globalEnabled = val);
                await _notifService.setEnabled(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isDark, ThemeData theme) {
    if (!_globalEnabled) return const SizedBox.shrink();

    int activeCount = 0;
    if (_breakfastEnabled) activeCount++;
    if (_lunchEnabled) activeCount++;
    if (_dinnerEnabled) activeCount++;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Text(
            '$activeCount rappel${activeCount > 1 ? 's' : ''} de repas actif${activeCount > 1 ? 's' : ''}${_waterEnabled ? ' + hydratation' : ''}',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required bool isDark,
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    final isActive = _globalEnabled && enabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? iconColor.withValues(alpha: 0.2)
              : (isDark ? Colors.white10 : Colors.grey[100]!),
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? iconColor.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: isDark ? 0.0 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Meal icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        iconColor.withValues(alpha: 0.15),
                        iconColor.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              color: isActive
                  ? null
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[50]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isActive
                  ? iconColor
                  : (isDark ? Colors.white38 : Colors.grey[400]),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isActive
                        ? (isDark ? Colors.white : const Color(0xFF1E293B))
                        : (isDark ? Colors.white38 : Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white30 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // Time button
          GestureDetector(
            onTap: _globalEnabled ? onTimeTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? iconColor.withValues(alpha: 0.1)
                    : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[50]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isActive
                      ? iconColor
                      : (isDark ? Colors.white38 : Colors.grey[400]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Switch
          Switch.adaptive(
            value: enabled,
            activeColor: iconColor,
            onChanged: _globalEnabled ? onToggle : null,
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard(bool isDark, ThemeData theme) {
    final isActive = _globalEnabled && _waterEnabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.cyan.withValues(alpha: 0.2)
              : (isDark ? Colors.white10 : Colors.grey[100]!),
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? Colors.cyan.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: isDark ? 0.0 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Water icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        Colors.cyan.withValues(alpha: 0.15),
                        Colors.cyan.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              color: isActive
                  ? null
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[50]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.water_drop_rounded,
              color: isActive
                  ? Colors.cyan
                  : (isDark ? Colors.white38 : Colors.grey[400]),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rappels d\'hydratation',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isActive
                        ? (isDark ? Colors.white : const Color(0xFF1E293B))
                        : (isDark ? Colors.white38 : Colors.grey[400]),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toutes les 2h de 8h à 22h',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white30 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: _waterEnabled,
            activeColor: Colors.cyan,
            onChanged: _globalEnabled
                ? (val) async {
                    setState(() => _waterEnabled = val);
                    await _notifService.setWaterEnabled(val);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  TIME PICKER
  // ─────────────────────────────────────────────────────────

  Future<void> _pickTime({
    required TimeOfDay current,
    required Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: 'Choisir l\'heure du rappel',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await onPicked(picked);
    }
  }
}
