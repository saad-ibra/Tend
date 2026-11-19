import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum TendVoiceState {
  idle,
  listening,
  processing,
}

class TendVoiceButton extends StatefulWidget {
  final TendVoiceState? state;
  final ValueChanged<TendVoiceState>? onStateChanged;
  final double size;
  final double? simulatedAmplitude;

  const TendVoiceButton({
    super.key,
    this.state,
    this.onStateChanged,
    this.size = 68.0,
    this.simulatedAmplitude,
  });

  @override
  State<TendVoiceButton> createState() => _TendVoiceButtonState();
}

class _TendVoiceButtonState extends State<TendVoiceButton>
    with TickerProviderStateMixin {
  late TendVoiceState _internalState;

  // Controllers for distinct state animations
  late AnimationController _idleController;
  late AnimationController _pressController;
  late AnimationController _listeningController;
  late AnimationController _processingController;

  TendVoiceState get _effectiveState => widget.state ?? _internalState;

  @override
  void initState() {
    super.initState();
    _internalState = widget.state ?? TendVoiceState.idle;

    // Idle: Slow, subtle, 4.5-second breathing cycle
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);

    // Press: Quick tactile contraction
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    // Listening: Responsive wave dynamics
    _listeningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Processing: Smooth, restrained orbital rotation (1 rev / 2.6s)
    _processingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _updateControllerActivity();
  }

  @override
  void didUpdateWidget(covariant TendVoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != null && widget.state != oldWidget.state) {
      _internalState = widget.state!;
      _updateControllerActivity();
    }
  }

  void _updateControllerActivity() {
    final state = _effectiveState;
    if (state == TendVoiceState.processing) {
      if (!_processingController.isAnimating) {
        _processingController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _pressController.dispose();
    _listeningController.dispose();
    _processingController.dispose();
    super.dispose();
  }

  void _handleTap() {
    final nextState = switch (_effectiveState) {
      TendVoiceState.idle => TendVoiceState.listening,
      TendVoiceState.listening => TendVoiceState.processing,
      TendVoiceState.processing => TendVoiceState.idle,
    };

    setState(() {
      _internalState = nextState;
    });
    widget.onStateChanged?.call(nextState);

    // If transitioned to processing, auto-resolve to idle after 2.4s for demonstration
    if (nextState == TendVoiceState.processing && widget.state == null) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted && _internalState == TendVoiceState.processing) {
          setState(() {
            _internalState = TendVoiceState.idle;
          });
          widget.onStateChanged?.call(TendVoiceState.idle);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final state = _effectiveState;

    return Semantics(
      button: true,
      label: switch (state) {
        TendVoiceState.idle => 'Tend Voice Input: Idle. Tap to listen',
        TendVoiceState.listening => 'Tend Voice Input: Listening. Tap to finish',
        TendVoiceState.processing => 'Tend Voice Input: Processing reflection',
      },
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          _handleTap();
        },
        onTapCancel: () => _pressController.reverse(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size + 14,
          height: widget.size + 14,
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _idleController,
                _pressController,
                _listeningController,
                _processingController,
              ]),
              builder: (context, _) {
                // Press scale
                final pressFactor = _pressController.value;
                final scale = 1.0 - (0.07 * pressFactor);

                // Idle breath value (0.0 to 1.0)
                final idleBreath = reduceMotion ? 0.5 : _idleController.value;

                // Processing angle
                final processingAngle =
                    reduceMotion ? 0.0 : _processingController.value * 2 * math.pi;

                // Voice Amplitude calculation
                double amplitude;
                if (widget.simulatedAmplitude != null) {
                  amplitude = widget.simulatedAmplitude!.clamp(0.0, 1.0);
                } else if (state == TendVoiceState.listening && !reduceMotion) {
                  // Organic multi-harmonic wave simulating human speech cadence
                  final t = _listeningController.value * 2 * math.pi;
                  final rawAmp = 0.35 +
                      0.32 * math.sin(t * 2.2) +
                      0.20 * math.cos(t * 4.7) +
                      0.13 * math.sin(t * 8.1);
                  amplitude = rawAmp.clamp(0.08, 0.95);
                } else {
                  amplitude = 0.0;
                }

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.espressoDeep,
                      border: Border.all(
                        color: state == TendVoiceState.listening
                            ? AppColors.caramelMid.withValues(alpha: 0.7)
                            : AppColors.caramelDark,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espressoDeep.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                        if (state == TendVoiceState.listening)
                          BoxShadow(
                            color: AppColors.caramelMid.withValues(alpha: 0.22),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: ClipOval(
                      child: CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _TendAcousticMarkPainter(
                          state: state,
                          idleBreath: idleBreath,
                          amplitude: amplitude,
                          processingAngle: processingAngle,
                          pressFactor: pressFactor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TendAcousticMarkPainter extends CustomPainter {
  final TendVoiceState state;
  final double idleBreath;
  final double amplitude;
  final double processingAngle;
  final double pressFactor;

  _TendAcousticMarkPainter({
    required this.state,
    required this.idleBreath,
    required this.amplitude,
    required this.processingAngle,
    required this.pressFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.29; // ~20px on a 68px button

    // 1. Subtle tactile inner bezel ring
    final bezelPaint = Paint()
      ..color = AppColors.espresso.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, size.width * 0.44, bezelPaint);

    // 2. Draw Listening Acoustic Resonance Rings (subtle hairline concentric arcs)
    if (state == TendVoiceState.listening && amplitude > 0.15) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = AppColors.caramelLight
            .withValues(alpha: (0.28 * (amplitude - 0.15)).clamp(0.0, 0.35));

      final outerWaveRadius = baseRadius + 4 + (amplitude * 9);
      canvas.drawCircle(center, outerWaveRadius, ringPaint);
    }

    // 3. Coordinate transformation for rotational animation
    canvas.save();
    canvas.translate(center.dx, center.dy);

    double globalRotation = 0.0;
    if (state == TendVoiceState.processing) {
      globalRotation = processingAngle;
    } else if (state == TendVoiceState.listening) {
      globalRotation = amplitude * 0.18; // Subtle reactive orientation flex
    } else {
      // Idle gentle sway
      globalRotation = math.sin(idleBreath * 2 * math.pi) * 0.025;
    }
    canvas.rotate(globalRotation);

    // 4. Render the 4 Interlocking Tend Knot Petals
    final petalCount = 4;
    for (int i = 0; i < petalCount; i++) {
      final petalAngle = (i * 2 * math.pi) / petalCount;
      canvas.save();
      canvas.rotate(petalAngle);

      _drawSingleInterlockingPetal(
        canvas: canvas,
        baseRadius: baseRadius,
        state: state,
        idleBreath: idleBreath,
        amplitude: amplitude,
        pressFactor: pressFactor,
        petalIndex: i,
      );

      canvas.restore();
    }

    // 5. Center Aperture (Negative Space Diamond/Star)
    _drawCentralAperture(
      canvas: canvas,
      baseRadius: baseRadius,
      state: state,
      idleBreath: idleBreath,
      amplitude: amplitude,
    );

    canvas.restore();
  }

  void _drawSingleInterlockingPetal({
    required Canvas canvas,
    required double baseRadius,
    required TendVoiceState state,
    required double idleBreath,
    required double amplitude,
    required double pressFactor,
    required int petalIndex,
  }) {
    // Dynamic parameters based on state and voice amplitude
    double expansion = 0.0;
    double curveTension = 1.0;

    if (state == TendVoiceState.listening) {
      expansion = amplitude * 4.5;
      curveTension = 1.0 + (amplitude * 0.35);
    } else if (state == TendVoiceState.idle) {
      expansion = (idleBreath - 0.5) * 0.8;
      curveTension = 0.98 + (idleBreath * 0.04);
    }

    // Tactile press contraction
    expansion -= pressFactor * 2.2;

    final rOuter = baseRadius + expansion;
    final rInner = (baseRadius * 0.28) + (state == TendVoiceState.listening ? amplitude * 1.5 : 0.0);

    // Geometry of 1 sculpted curved petal ribbon
    final path = Path();
    path.moveTo(0, -rInner);

    // Outer sweeping crest
    path.cubicTo(
      rOuter * 0.42 * curveTension,
      -rOuter * 0.95,
      rOuter * 0.92,
      -rOuter * 0.55 * curveTension,
      rOuter * 0.88,
      -rOuter * 0.05,
    );

    // Outer-to-inner returning curl (interlocking fold)
    path.cubicTo(
      rOuter * 0.75,
      rOuter * 0.32,
      rOuter * 0.30,
      rOuter * 0.22,
      rInner * 1.1,
      rInner * 0.2,
    );

    // Inward tuck towards the aperture diamond
    path.quadraticBezierTo(
      rInner * 0.4,
      -rInner * 0.4,
      0,
      -rInner,
    );
    path.close();

    // Petal Shader / Dual Tone
    // Alternating subtly between caramel highlight and rich terracotta
    final isAlternate = petalIndex % 2 == 1;
    final startColor = isAlternate ? AppColors.caramelMid : AppColors.caramelLight;
    final endColor = isAlternate ? AppColors.caramelDark : AppColors.caramel;

    final petalPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          startColor,
          endColor,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: rOuter))
      ..style = PaintingStyle.fill;

    // Outer hairline stroke for crisp tactile boundary
    final strokePaint = Paint()
      ..color = AppColors.caramelCream.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    canvas.drawPath(path, petalPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawCentralAperture({
    required Canvas canvas,
    required double baseRadius,
    required TendVoiceState state,
    required double idleBreath,
    required double amplitude,
  }) {
    // The central diamond star cutout that breathes with the user's voice
    double diamondSize = baseRadius * 0.22;
    if (state == TendVoiceState.listening) {
      diamondSize += amplitude * 2.2;
    } else if (state == TendVoiceState.idle) {
      diamondSize += (idleBreath - 0.5) * 0.6;
    }

    final diamondPath = Path();
    diamondPath.moveTo(0, -diamondSize);
    diamondPath.lineTo(diamondSize, 0);
    diamondPath.lineTo(0, diamondSize);
    diamondPath.lineTo(-diamondSize, 0);
    diamondPath.close();

    final aperturePaint = Paint()
      ..color = AppColors.espressoDeep
      ..style = PaintingStyle.fill;

    final apertureBorder = Paint()
      ..color = AppColors.caramelLight.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawPath(diamondPath, aperturePaint);
    canvas.drawPath(diamondPath, apertureBorder);
  }

  @override
  bool shouldRepaint(covariant _TendAcousticMarkPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.idleBreath != idleBreath ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.processingAngle != processingAngle ||
        oldDelegate.pressFactor != pressFactor;
  }
}
