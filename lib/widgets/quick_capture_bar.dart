import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class QuickCaptureBar extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final ValueChanged<bool>? onRecordingChanged;

  const QuickCaptureBar({
    super.key,
    required this.onSubmit,
    this.onRecordingChanged,
  });

  @override
  State<QuickCaptureBar> createState() => _QuickCaptureBarState();
}

class _QuickCaptureBarState extends State<QuickCaptureBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    widget.onRecordingChanged?.call(_isRecording);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _focusNode.hasFocus
              ? AppColors.primaryContainer.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x081B1C1A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Edit note icon container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.edit_note,
                size: 20,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Input field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSubmit(),
              style: AppTypography.bodyMd(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: _isRecording
                    ? 'Listening... Speak your thought'
                    : 'Capture a thought or note...',
                hintStyle: AppTypography.bodyMd(
                  color: _isRecording
                      ? AppColors.error
                      : AppColors.outline.withValues(alpha: 0.8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),

          // Voice note mic button
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _isRecording
                    ? AppColors.errorContainer
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  size: 20,
                  color: _isRecording
                      ? AppColors.onErrorContainer
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Submit button
          GestureDetector(
            onTap: _handleSubmit,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 19,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
