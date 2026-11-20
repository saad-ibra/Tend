import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/checkin_controller.dart';
import '../controllers/coach_controller.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import '../services/gemini_coach_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'checkin_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final HabitController habitController;
  final CheckInController? checkInController;
  final CoachController? coachController;

  const ProfileScreen({
    super.key,
    required this.habitController,
    this.checkInController,
    this.coachController,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _groqKeyController = TextEditingController();
  bool _geminiKeySaved = false;
  bool _groqKeySaved = false;
  AiProvider _selectedProvider = AiProvider.auto;

  static const _geminiKeyPrefKey = 'tend_gemini_api_key';
  static const _groqKeyPrefKey = 'tend_groq_api_key';
  static const _providerPrefKey = 'tend_ai_provider';

  @override
  void initState() {
    super.initState();
    widget.habitController.addListener(_refresh);
    widget.checkInController?.addListener(_refresh);
    widget.coachController?.addListener(_refresh);
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final geminiKey = prefs.getString(_geminiKeyPrefKey) ?? '';
    final groqKey = prefs.getString(_groqKeyPrefKey) ?? '';
    final providerStr = prefs.getString(_providerPrefKey) ?? 'auto';

    AiProvider provider = AiProvider.auto;
    if (providerStr == 'groq') provider = AiProvider.groq;
    if (providerStr == 'gemini') provider = AiProvider.gemini;

    if (mounted) {
      setState(() {
        _geminiKeyController.text = geminiKey;
        _groqKeyController.text = groqKey;
        _selectedProvider = provider;
      });
    }
  }

  Future<void> _saveGroqKey() async {
    final key = _groqKeyController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groqKeyPrefKey, key);

    widget.coachController?.coachService.setGroqApiKey(key.isNotEmpty ? key : null);

    if (mounted) {
      setState(() => _groqKeySaved = true);
      if (key.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Groq API key cleared. On-device mode active.'),
            backgroundColor: AppColors.espresso,
          ),
        );
      } else {
        final testError = await widget.coachController?.coachService.testGroqApiKey(key);
        if (mounted) {
          if (testError == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Groq Key Verified! Cloud reasoning is active.'),
                backgroundColor: AppColors.primary,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Groq Key saved, but notice: $testError'),
                backgroundColor: Colors.amber.shade900,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _groqKeySaved = false);
      });
    }
  }

  Future<void> _saveGeminiKey() async {
    final key = _geminiKeyController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKeyPrefKey, key);

    widget.coachController?.coachService.setGeminiApiKey(key.isNotEmpty ? key : null);

    if (mounted) {
      setState(() => _geminiKeySaved = true);
      if (key.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemini API key cleared. On-device mode active.'),
            backgroundColor: AppColors.espresso,
          ),
        );
      } else {
        final testError = await widget.coachController?.coachService.testGeminiApiKey(key);
        if (mounted) {
          if (testError == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gemini Key Verified! Google Gemini reasoning is active.'),
                backgroundColor: AppColors.primary,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gemini Key saved, but notice: $testError'),
                backgroundColor: Colors.amber.shade900,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _geminiKeySaved = false);
      });
    }
  }

  Future<void> _changeProvider(AiProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerPrefKey, provider.name);
    widget.coachController?.coachService.setProvider(provider);
    setState(() => _selectedProvider = provider);
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _groqKeyController.dispose();
    widget.coachController?.removeListener(_refresh);
    widget.checkInController?.removeListener(_refresh);
    widget.habitController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final archivedHabits = widget.habitController.archivedHabits;
    final activeHabitsCount = widget.habitController.activeHabits.length;
    final checkInsCount = widget.checkInController?.totalCheckInsCount ?? 0;
    final checkInStreak = widget.checkInController?.checkInStreak ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Profile & Ledger', style: AppTypography.headlineMd()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'EV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Elena Vance',
                          style: AppTypography.headlineSm(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mindful Ground • Daily Practitioner',
                          style: AppTypography.bodySm(color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Strip
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Rhythms',
                    value: '$activeHabitsCount',
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Archived',
                    value: '${archivedHabits.length}',
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Check-in Streak',
                    value: '$checkInStreak d',
                    color: AppColors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Daily Mood & Energy Ledger Section
            if (widget.checkInController != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inner Weather & Mood',
                    style: AppTypography.headlineMd(color: AppColors.onSurface),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CheckInHistoryScreen(
                            controller: widget.checkInController!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.insights_outlined, size: 16),
                    label: const Text('View Trends'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Track patterns across emotional quality, energy reserves, and daily rhythms',
                style: AppTypography.bodySm(color: AppColors.outline),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Logged Check-ins', style: AppTypography.labelSm(color: AppColors.outline)),
                          const SizedBox(height: 4),
                          Text('$checkInsCount total', style: AppTypography.headlineSm()),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.borderSubtle),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Average Mood', style: AppTypography.labelSm(color: AppColors.outline)),
                          const SizedBox(height: 4),
                          Text(
                            checkInsCount > 0 ? '${widget.checkInController!.averageMood}/5' : '—',
                            style: AppTypography.headlineSm(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.borderSubtle),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Average Energy', style: AppTypography.labelSm(color: AppColors.outline)),
                          const SizedBox(height: 4),
                          Text(
                            checkInsCount > 0 ? '${widget.checkInController!.averageEnergy}/5' : '—',
                            style: AppTypography.headlineSm(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // AI Habit Coach & Gemini Configuration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Habit Coach Engine',
                  style: AppTypography.headlineMd(color: AppColors.onSurface),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (_groqKeyController.text.isNotEmpty ||
                            _geminiKeyController.text.isNotEmpty)
                        ? AppColors.secondaryContainer.withValues(alpha: 0.6)
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _groqKeyController.text.isNotEmpty
                        ? 'Groq Cloud'
                        : (_geminiKeyController.text.isNotEmpty
                            ? 'Google Gemini'
                            : 'On-Device'),
                    style: AppTypography.labelSm(
                      color: (_groqKeyController.text.isNotEmpty ||
                              _geminiKeyController.text.isNotEmpty)
                          ? AppColors.onSecondaryContainer
                          : AppColors.outline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Connect Groq (free tier with Llama 3.3 70B) or Google Gemini for live AI reasoning. If left empty, on-device contextual analysis will run.',
              style: AppTypography.bodySm(color: AppColors.outline),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preferred Provider Selector
                  Text(
                    'Active Model Provider',
                    style: AppTypography.labelMd(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Auto-Detect'),
                        selected: _selectedProvider == AiProvider.auto,
                        onSelected: (val) {
                          if (val) _changeProvider(AiProvider.auto);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedProvider == AiProvider.auto
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Groq Cloud'),
                        selected: _selectedProvider == AiProvider.groq,
                        onSelected: (val) {
                          if (val) _changeProvider(AiProvider.groq);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedProvider == AiProvider.groq
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Google Gemini'),
                        selected: _selectedProvider == AiProvider.gemini,
                        onSelected: (val) {
                          if (val) _changeProvider(AiProvider.gemini);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedProvider == AiProvider.gemini
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24, color: AppColors.borderSubtle),

                  // Groq API Key Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Groq API Key (Recommended & Free)',
                        style: AppTypography.labelMd(color: AppColors.onSurface),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'FASTEST',
                          style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get an instant key at console.groq.com/keys (free, no credit card). Uses high-throughput GPT-OSS / Qwen / Llama models.',
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _groqKeyController,
                    obscureText: true,
                    style: AppTypography.bodyMd(),
                    decoration: InputDecoration(
                      labelText: 'Groq API Key',
                      labelStyle: AppTypography.bodySm(color: AppColors.outline),
                      hintText: 'gsk_...',
                      hintStyle: AppTypography.bodySm(color: AppColors.outline),
                      filled: true,
                      fillColor: AppColors.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: _saveGroqKey,
                      icon: Icon(
                        _groqKeySaved ? Icons.check : Icons.bolt_outlined,
                        size: 16,
                      ),
                      label: Text(_groqKeySaved ? 'Groq Key Saved' : 'Save Groq Key'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _groqKeySaved
                            ? AppColors.secondary
                            : AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const Divider(height: 28, color: AppColors.borderSubtle),

                  // Google Gemini API Key Section
                  Text(
                    'Google Gemini API Key',
                    style: AppTypography.labelMd(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supports free & paid Gemini 1.5/2.0 Flash keys from aistudio.google.com.',
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _geminiKeyController,
                    obscureText: true,
                    style: AppTypography.bodyMd(),
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      labelStyle: AppTypography.bodySm(color: AppColors.outline),
                      hintText: 'AIzaSy...',
                      hintStyle: AppTypography.bodySm(color: AppColors.outline),
                      filled: true,
                      fillColor: AppColors.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: _saveGeminiKey,
                      icon: Icon(
                        _geminiKeySaved ? Icons.check : Icons.save_outlined,
                        size: 16,
                      ),
                      label: Text(_geminiKeySaved ? 'Gemini Key Saved' : 'Save Gemini Key'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _geminiKeySaved
                            ? AppColors.secondary
                            : AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Dedicated Archived Rhythms Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Archived Rhythms',
                  style: AppTypography.headlineMd(color: AppColors.onSurface),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${archivedHabits.length} stored',
                    style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Habits paused from your daily view with history intact',
              style: AppTypography.bodySm(color: AppColors.outline),
            ),
            const SizedBox(height: 12),

            if (archivedHabits.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.archive_outlined, size: 28, color: AppColors.outline),
                      const SizedBox(height: 8),
                      Text(
                        'No archived rhythms',
                        style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rhythms you archive will be preserved here.',
                        style: AppTypography.bodySm(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: archivedHabits.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final habit = archivedHabits[index];
                  return _buildArchivedHabitCard(habit);
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.headlineLg(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.labelSm(color: AppColors.outline),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Widget _buildArchivedHabitCard(Habit habit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 38,
            decoration: BoxDecoration(
              color: _parseColor(habit.colorHex).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                if (habit.description != null && habit.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    habit.description!,
                    style: AppTypography.bodySm(color: AppColors.outline),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.unarchive_outlined, size: 20, color: AppColors.primary),
            tooltip: 'Restore rhythm',
            onPressed: () {
              widget.habitController.unarchiveHabit(habit.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Restored rhythm: ${habit.title}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.outline),
            tooltip: 'Delete permanently',
            onPressed: () => _confirmDelete(habit),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Text('Delete Permanently?', style: AppTypography.headlineSm(color: AppColors.error)),
        content: Text(
          'Permanently remove "${habit.title}"? Historical logs will be deleted.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTypography.labelMd(color: AppColors.outline)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.habitController.deleteHabit(habit.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
