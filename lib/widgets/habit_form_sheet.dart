import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HabitFormSheet extends StatefulWidget {
  final Habit? initialHabit;
  final ValueChanged<Habit> onSave;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const HabitFormSheet({
    super.key,
    this.initialHabit,
    required this.onSave,
    this.onArchive,
    this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    Habit? habit,
    required ValueChanged<Habit> onSave,
    VoidCallback? onArchive,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => HabitFormSheet(
        initialHabit: habit,
        onSave: onSave,
        onArchive: onArchive,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late HabitFrequencyType _frequencyType;
  late List<int> _selectedWeekdays;
  late String _selectedColorHex;

  static const List<String> _colorOptions = [
    '#744127', // Espresso Caramel
    '#835136', // Warm Caramel
    '#B97B54', // Caramel Mid
    '#55614E', // Sage
    '#875E26', // Warm Ochre
  ];

  static const List<Map<String, dynamic>> _weekdayItems = [
    {'label': 'M', 'value': 1},
    {'label': 'T', 'value': 2},
    {'label': 'W', 'value': 3},
    {'label': 'T', 'value': 4},
    {'label': 'F', 'value': 5},
    {'label': 'S', 'value': 6},
    {'label': 'S', 'value': 7},
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.initialHabit;
    _titleController = TextEditingController(text: h?.title ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _frequencyType = h?.frequencyType ?? HabitFrequencyType.daily;
    _selectedWeekdays = h?.targetWeekdays != null
        ? List<int>.from(h!.targetWeekdays)
        : [1, 2, 3, 4, 5, 6, 7];
    _selectedColorHex = h?.colorHex ?? _colorOptions[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      final habit = Habit(
        id: widget.initialHabit?.id ?? 'h_${now.millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
        frequencyType: _frequencyType,
        targetWeekdays: _frequencyType == HabitFrequencyType.daily
            ? const [1, 2, 3, 4, 5, 6, 7]
            : (_selectedWeekdays.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : _selectedWeekdays),
        colorHex: _selectedColorHex,
        isArchived: widget.initialHabit?.isArchived ?? false,
        createdAt: widget.initialHabit?.createdAt ?? now,
      );
      widget.onSave(habit);
      Navigator.of(context).pop();
    }
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialHabit != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Rhythm' : 'New Rhythm',
                    style: AppTypography.headlineMd(color: AppColors.onSurface),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMd(color: AppColors.onSurface),
                decoration: InputDecoration(
                  labelText: 'Habit Title',
                  labelStyle: AppTypography.bodySm(color: AppColors.outline),
                  hintText: 'e.g. Morning stillness',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a habit title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description / Intention Field
              TextFormField(
                controller: _descController,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMd(color: AppColors.onSurface),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Intention / Notes (Optional)',
                  labelStyle: AppTypography.bodySm(color: AppColors.outline),
                  hintText: 'e.g. 10 minutes of quiet observation',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Frequency Selector
              Text(
                'Frequency',
                style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Every day'),
                    selected: _frequencyType == HabitFrequencyType.daily,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _frequencyType = HabitFrequencyType.daily;
                          _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
                        });
                      }
                    },
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      color: _frequencyType == HabitFrequencyType.daily
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Selected weekdays'),
                    selected: _frequencyType == HabitFrequencyType.weekdays,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _frequencyType = HabitFrequencyType.weekdays;
                        });
                      }
                    },
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      color: _frequencyType == HabitFrequencyType.weekdays
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              // Weekday picker if selected
              if (_frequencyType == HabitFrequencyType.weekdays) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekdayItems.map((item) {
                    final int val = item['value'] as int;
                    final bool isSelected = _selectedWeekdays.contains(val);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            if (_selectedWeekdays.length > 1) {
                              _selectedWeekdays.remove(val);
                            }
                          } else {
                            _selectedWeekdays.add(val);
                          }
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primaryContainer
                              : AppColors.surfaceContainerLowest,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 18),

              // Accent Color Swatches
              Text(
                'Tone Accent',
                style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: _colorOptions.map((hex) {
                  final isSelected = _selectedColorHex == hex;
                  final color = _parseColor(hex);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check, size: 16, color: Colors.white),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create Rhythm',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onArchive?.call();
                        },
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: const Text('Archive'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceVariant,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDelete?.call();
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
