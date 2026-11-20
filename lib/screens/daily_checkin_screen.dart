import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../controllers/checkin_controller.dart';
import '../models/mood_energy_checkin.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/tend_voice_button.dart';
import 'checkin_history_screen.dart';

class DailyCheckInScreen extends StatefulWidget {
  final CheckInController controller;

  const DailyCheckInScreen({
    super.key,
    required this.controller,
  });

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  int _selectedMood = 4; // Default to Grounded
  int _selectedEnergy = 3; // Default to Gentle
  final Set<String> _selectedTags = {};
  final TextEditingController _noteController = TextEditingController();

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isSpeechInitialized = false;
  bool _isVoiceRecording = false;
  double _soundLevel = 0.0;

  static const List<String> _availableTags = [
    'Sleep',
    'Deep Work',
    'Movement',
    'Nature',
    'Solitude',
    'Connection',
    'Stillness',
    'Nutrition',
  ];

  @override
  void initState() {
    super.initState();
    _initExistingCheckIn();
    _initSpeechRecognizerQuietly();
  }

  void _initExistingCheckIn() {
    final existing = widget.controller.todayCheckIn;
    if (existing != null) {
      _selectedMood = existing.moodScore;
      _selectedEnergy = existing.energyScore;
      _selectedTags.addAll(existing.tags);
      _noteController.text = existing.note;
    }
  }

  Future<void> _initSpeechRecognizerQuietly() async {
    try {
      final available = await _speechToText.initialize(
        onError: (val) => debugPrint('STT check-in error: ${val.errorMsg}'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isVoiceRecording) {
              setState(() {
                _isVoiceRecording = false;
                _soundLevel = 0.0;
              });
            }
          }
        },
      );
      if (mounted) {
        setState(() => _isSpeechInitialized = available);
      }
    } catch (e) {
      debugPrint('Speech init quiet: $e');
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceReflection() async {
    if (_isVoiceRecording) {
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _isVoiceRecording = false;
          _soundLevel = 0.0;
        });
      }
    } else {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speechToText.initialize();
      }

      if (_isSpeechInitialized) {
        setState(() => _isVoiceRecording = true);
        try {
          await _speechToText.listen(
            onResult: (result) {
              if (mounted) {
                final currentText = _noteController.text.trim();
                final spoken = result.recognizedWords.trim();
                if (result.finalResult && spoken.isNotEmpty) {
                  setState(() {
                    _noteController.text = currentText.isEmpty
                        ? spoken
                        : '$currentText $spoken';
                  });
                }
              }
            },
            onSoundLevelChange: (level) {
              if (mounted) {
                final norm = ((level + 6.0) / 14.0).clamp(0.0, 1.0);
                setState(() => _soundLevel = norm);
              }
            },
            listenFor: const Duration(minutes: 5),
            pauseFor: const Duration(seconds: 10),
            partialResults: true,
            cancelOnError: false,
            listenMode: stt.ListenMode.dictation,
          );
        } catch (e) {
          debugPrint('STT listen error: $e');
          setState(() => _isVoiceRecording = false);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission or speech recognition unavailable.')),
        );
      }
    }
  }

  Future<void> _saveCheckIn() async {
    if (_isVoiceRecording) {
      await _speechToText.stop();
    }

    await widget.controller.logCheckIn(
      moodScore: _selectedMood,
      energyScore: _selectedEnergy,
      tags: _selectedTags.toList(),
      note: _noteController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Daily Check-in saved: ${MoodEnergyCheckIn.getMoodLabel(_selectedMood)} • ${MoodEnergyCheckIn.getEnergyLabel(_selectedEnergy)}',
          ),
          backgroundColor: AppColors.espresso,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckInHistoryScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAlreadyCheckedIn = widget.controller.hasCheckedInToday;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Daily Check-in', style: AppTypography.headlineMd()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined, color: AppColors.primary),
            tooltip: 'View Trends & History',
            onPressed: _openHistory,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Prompt
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x063B2317),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inner Weather',
                        style: AppTypography.labelMd(color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAlreadyCheckedIn
                              ? AppColors.secondaryContainer.withValues(alpha: 0.6)
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAlreadyCheckedIn ? 'Checked in today' : 'Today\'s entry',
                          style: AppTypography.labelSm(
                            color: isAlreadyCheckedIn
                                ? AppColors.onSecondaryContainer
                                : AppColors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Observe your inner climate without judgment. How does your mind and body feel right now?',
                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dimension 1: Mood (Affect/Valence)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mood Quality', style: AppTypography.headlineSm()),
                Text(
                  MoodEnergyCheckIn.getMoodLabel(_selectedMood),
                  style: AppTypography.labelMd(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMoodSelector(),
            const SizedBox(height: 24),

            // Dimension 2: Energy (Vitality/Activation)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Energy Level', style: AppTypography.headlineSm()),
                Text(
                  MoodEnergyCheckIn.getEnergyLabel(_selectedEnergy),
                  style: AppTypography.labelMd(color: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildEnergySelector(),
            const SizedBox(height: 24),

            // Contextual Influences / Tags
            Text('Context & Influences', style: AppTypography.headlineSm()),
            const SizedBox(height: 4),
            Text(
              'What shaped your physical and emotional tone today?',
              style: AppTypography.bodySm(color: AppColors.outline),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  backgroundColor: AppColors.surfaceContainerLowest,
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: Colors.white,
                  labelStyle: AppTypography.labelSm(
                    color: isSelected ? Colors.white : AppColors.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Reflection Journal & Voice Dictation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mindful Reflection', style: AppTypography.headlineSm()),
                if (_isVoiceRecording)
                  Row(
                    children: [
                      const Icon(Icons.graphic_eq, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Listening...',
                        style: AppTypography.labelSm(color: AppColors.primary),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Capture a note, thought, or spoken reflection about your day.',
              style: AppTypography.bodySm(color: AppColors.outline),
            ),
            const SizedBox(height: 12),

            // Reflection Card with Preserved TendVoiceButton
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isVoiceRecording ? AppColors.primary : AppColors.borderSubtle,
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    style: AppTypography.bodyMd(),
                    decoration: InputDecoration(
                      hintText: 'Type your reflection or tap the voice button below to speak freely...',
                      hintStyle: AppTypography.bodySm(color: AppColors.outline),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isVoiceRecording
                            ? 'Transcribing voice reflection...'
                            : 'Tap mic to speak reflection',
                        style: AppTypography.bodySm(
                          color: _isVoiceRecording ? AppColors.primary : AppColors.outline,
                        ),
                      ),
                      TendVoiceButton(
                        size: 46,
                        state: _isVoiceRecording
                            ? TendVoiceState.listening
                            : TendVoiceState.idle,
                        simulatedAmplitude: _isVoiceRecording ? _soundLevel : 0.0,
                        onTap: _toggleVoiceReflection,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save / Log Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveCheckIn,
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  isAlreadyCheckedIn ? 'Update Today\'s Check-in' : 'Save Daily Check-in',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moodOptions = [
      {'score': 1, 'label': 'Heavy', 'icon': Icons.cloud_outlined},
      {'score': 2, 'label': 'Unsettled', 'icon': Icons.grain_outlined},
      {'score': 3, 'label': 'Steady', 'icon': Icons.wb_twilight_outlined},
      {'score': 4, 'label': 'Grounded', 'icon': Icons.spa_outlined},
      {'score': 5, 'label': 'Radiant', 'icon': Icons.wb_sunny_outlined},
    ];

    return Row(
      children: moodOptions.map((opt) {
        final score = opt['score'] as int;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final isSelected = _selectedMood == score;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => setState(() => _selectedMood = score),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.espresso.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? Colors.white : AppColors.outline,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTypography.labelSm(
                        color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                      ).copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 10.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnergySelector() {
    final energyOptions = [
      {'score': 1, 'label': 'Depleted', 'dots': 1},
      {'score': 2, 'label': 'Low', 'dots': 2},
      {'score': 3, 'label': 'Gentle', 'dots': 3},
      {'score': 4, 'label': 'Active', 'dots': 4},
      {'score': 5, 'label': 'Vibrant', 'dots': 5},
    ];

    return Row(
      children: energyOptions.map((opt) {
        final score = opt['score'] as int;
        final label = opt['label'] as String;
        final dots = opt['dots'] as int;
        final isSelected = _selectedEnergy == score;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => setState(() => _selectedEnergy = score),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondary
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : AppColors.borderSubtle,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (dotIdx) {
                        final filled = dotIdx < dots;
                        return Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (filled ? Colors.white : Colors.white38)
                                : (filled ? AppColors.secondary : AppColors.borderSubtle),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: AppTypography.labelSm(
                        color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                      ).copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 10.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
