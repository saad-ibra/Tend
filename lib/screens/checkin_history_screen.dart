import 'package:flutter/material.dart';
import '../controllers/checkin_controller.dart';
import '../models/mood_energy_checkin.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CheckInHistoryScreen extends StatefulWidget {
  final CheckInController controller;
  final bool isEmbedded;

  const CheckInHistoryScreen({
    super.key,
    required this.controller,
    this.isEmbedded = false,
  });

  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final checkIns = widget.controller.checkIns;
    final pastWeek = widget.controller.getPastSevenDays();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text('Inner Weather & Trends', style: AppTypography.headlineMd()),
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
            // Stats Row: Streak, Average Mood, Average Energy
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Current Streak',
                    value: '${widget.controller.checkInStreak} d',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Avg Mood',
                    value: checkIns.isNotEmpty
                        ? '${widget.controller.averageMood}/5'
                        : '—',
                    color: AppColors.caramelDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Avg Energy',
                    value: checkIns.isNotEmpty
                        ? '${widget.controller.averageEnergy}/5'
                        : '—',
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 7-Day Mindful Rhythm Bar
            Text('Last 7 Days', style: AppTypography.headlineSm()),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (idx) {
                  final checkIn = pastWeek[idx];
                  final dayOffset = 6 - idx;
                  final dayDate = DateTime.now().subtract(Duration(days: dayOffset));
                  final isToday = dayOffset == 0;
                  final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final dayLabel = dayLabels[dayDate.weekday - 1];

                  return Column(
                    children: [
                      Text(
                        dayLabel,
                        style: AppTypography.labelSm(
                          color: isToday ? AppColors.primary : AppColors.outline,
                        ).copyWith(fontWeight: isToday ? FontWeight.w700 : FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 32,
                        height: 48,
                        decoration: BoxDecoration(
                          color: checkIn != null
                              ? AppColors.caramelCream.withValues(alpha: 0.5)
                              : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday ? AppColors.primary : AppColors.borderSubtle,
                            width: isToday ? 1.5 : 1.0,
                          ),
                        ),
                        child: checkIn != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${checkIn.moodScore}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Container(
                                    width: 12,
                                    height: 1,
                                    color: AppColors.borderSubtle,
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                  ),
                                  Text(
                                    '${checkIn.energyScore}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Text('·', style: TextStyle(color: AppColors.outline, fontSize: 18)),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday ? AppColors.primary : AppColors.outline,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Reflections Journal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reflections Journal', style: AppTypography.headlineMd()),
                Text(
                  '${checkIns.length} logged',
                  style: AppTypography.labelSm(color: AppColors.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (checkIns.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.wb_twilight_outlined, size: 40, color: AppColors.outline),
                      const SizedBox(height: 12),
                      Text('No check-ins logged yet', style: AppTypography.headlineSm()),
                      const SizedBox(height: 6),
                      Text(
                        'Check in daily with your mood and energy to reveal personal patterns and mindful rhythms.',
                        style: AppTypography.bodySm(color: AppColors.outline),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: checkIns.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = checkIns[index];
                  return _buildCheckInCard(item);
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelSm(color: AppColors.outline)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.headlineSm(color: color)),
        ],
      ),
    );
  }

  Widget _buildCheckInCard(MoodEnergyCheckIn checkIn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x043B2317),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(checkIn.createdAt),
                style: AppTypography.labelSm(color: AppColors.outline),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.outline),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _confirmDelete(checkIn.id),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mood & Energy Status Badges
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.caramelCream.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.spa_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
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
                  color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_outlined, size: 14, color: AppColors.onSecondaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Energy: ${checkIn.energyLabel} (${checkIn.energyScore}/5)',
                      style: AppTypography.labelSm(color: AppColors.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tags if any
          if (checkIn.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: checkIn.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('#$tag', style: AppTypography.labelSm(color: AppColors.outline)),
                );
              }).toList(),
            ),
          ],

          // Reflection note if any
          if (checkIn.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                checkIn.note,
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Check-in?', style: AppTypography.headlineSm()),
        content: Text(
          'Are you sure you want to delete this check-in entry?',
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
              widget.controller.deleteCheckIn(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espresso,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
