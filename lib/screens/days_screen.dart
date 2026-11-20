import 'package:flutter/material.dart';
import '../controllers/checkin_controller.dart';
import '../controllers/habit_controller.dart';
import '../models/habit.dart';
import '../models/mood_energy_checkin.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'checkin_history_screen.dart';
import 'daily_checkin_screen.dart';

class DaysScreen extends StatefulWidget {
  final CheckInController checkInController;
  final HabitController habitController;

  const DaysScreen({
    super.key,
    required this.checkInController,
    required this.habitController,
  });

  @override
  State<DaysScreen> createState() => _DaysScreenState();
}

class _DaysScreenState extends State<DaysScreen> {
  int _selectedView = 0; // 0: Calendar Ledger, 1: Reflections Journal
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    widget.checkInController.addListener(_refresh);
    widget.habitController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.checkInController.removeListener(_refresh);
    widget.habitController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  List<Habit> _getHabitsCompletedOn(DateTime date) {
    return widget.habitController.getCompletedHabitsForDate(date);
  }

  MoodEnergyCheckIn? _getCheckInOn(DateTime date) {
    return widget.checkInController.getCheckInForDate(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // View Switcher Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedView = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedView == 0
                              ? AppColors.surfaceContainerLowest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedView == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                size: 16,
                                color: _selectedView == 0
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Calendar Ledger',
                                style: AppTypography.labelSm(
                                  color: _selectedView == 0
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ).copyWith(
                                  fontWeight:
                                      _selectedView == 0 ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedView = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedView == 1
                              ? AppColors.surfaceContainerLowest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _selectedView == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_edu_outlined,
                                size: 16,
                                color: _selectedView == 1
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Reflections Journal',
                                style: AppTypography.labelSm(
                                  color: _selectedView == 1
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ).copyWith(
                                  fontWeight:
                                      _selectedView == 1 ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body Content
          Expanded(
            child: _selectedView == 0
                ? _buildCalendarLedgerView()
                : CheckInHistoryScreen(
                    controller: widget.checkInController,
                    isEmbedded: true,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLedgerView() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthTitle = '${months[_displayedMonth.month - 1]} ${_displayedMonth.year}';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.onSurface),
                  onPressed: _previousMonth,
                  splashRadius: 20,
                ),
                GestureDetector(
                  onTap: _goToToday,
                  child: Column(
                    children: [
                      Text(
                        monthTitle,
                        style: AppTypography.headlineSm(color: AppColors.onSurface).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tap for Today',
                        style: AppTypography.labelSm(color: AppColors.outline).copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.onSurface),
                  onPressed: _nextMonth,
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Calendar Grid Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                // Weekday Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                    return SizedBox(
                      width: 38,
                      child: Center(
                        child: Text(
                          day,
                          style: AppTypography.labelSm(color: AppColors.outline).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 8),

                // Calendar Days Grid
                _buildDaysGrid(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selected Day Inspector Card
          _buildDayInspectorCard(),
        ],
      ),
    );
  }

  Widget _buildDaysGrid() {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Weekday in Dart is 1 (Mon) to 7 (Sun)
    final startingWeekday = firstDayOfMonth.weekday; // 1 to 7

    final totalCells = ((startingWeekday - 1) + daysInMonth <= 35) ? 35 : 42;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final dayOffset = index - (startingWeekday - 1);
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNumber = dayOffset + 1;
        final cellDate = DateTime(year, month, dayNumber);
        final isSelected = cellDate.year == _selectedDate.year &&
            cellDate.month == _selectedDate.month &&
            cellDate.day == _selectedDate.day;
        final isToday = cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;

        final completedHabits = _getHabitsCompletedOn(cellDate);
        final checkIn = _getCheckInOn(cellDate);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryContainer.withValues(alpha: 0.15)
                  : (isToday
                      ? AppColors.surfaceContainer
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isToday ? AppColors.borderSubtle : Colors.transparent),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isToday ? AppColors.onSurface : AppColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 3),
                // Indicator dots row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (completedHabits.isNotEmpty)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _parseColor(completedHabits.first.colorHex),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (checkIn != null) ...[
                      const SizedBox(width: 2),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayInspectorCard() {
    final completedHabits = _getHabitsCompletedOn(_selectedDate);
    final checkIn = _getCheckInOn(_selectedDate);

    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final formattedHeader =
        '${weekdays[_selectedDate.weekday - 1]}, ${months[_selectedDate.month - 1]} ${_selectedDate.day}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedHeader,
                style: AppTypography.headlineSm(color: AppColors.onSurface).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (checkIn == null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DailyCheckInScreen(
                          controller: widget.checkInController,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Check In', style: TextStyle(color: AppColors.primary)),
                ),
            ],
          ),

          const Divider(height: 20, color: AppColors.borderSubtle),

          // Tended Rhythms Section
          Text(
            'Tended Rhythms',
            style: AppTypography.labelMd(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          if (completedHabits.isEmpty)
            Text(
              'No rhythms were completed on this day.',
              style: AppTypography.bodySm(color: AppColors.outline),
            )
          else
            ...completedHabits.map((habit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _parseColor(habit.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        habit.title,
                        style: AppTypography.bodyMd(color: AppColors.onSurface),
                      ),
                    ),
                    const Icon(Icons.check_circle, size: 16, color: AppColors.secondary),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),

          // Mood & Energy Section
          Text(
            'Inner Weather & Energy',
            style: AppTypography.labelMd(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          if (checkIn == null)
            Text(
              'No inner weather check-in logged for this day.',
              style: AppTypography.bodySm(color: AppColors.outline),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_vintage_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Mood: ${checkIn.moodLabel} (${checkIn.moodScore}/5)',
                            style: AppTypography.labelSm(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            'Energy: ${checkIn.energyLabel} (${checkIn.energyScore}/5)',
                            style: AppTypography.labelSm(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (checkIn.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: checkIn.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          '#$tag',
                          style: AppTypography.labelSm(color: AppColors.outline).copyWith(fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (checkIn.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '"${checkIn.note.trim()}"',
                      style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
