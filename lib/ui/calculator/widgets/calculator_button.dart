import 'package:flutter/material.dart';

import 'package:wevacalc/config/theme/app_layout.dart';

/// Variantes visuais do botão da calculadora.
/// - [numeric]: dígitos 0-9, 00, 000 — cor onSurface, LED glow branco ao digitar
/// - [functional]: operadores e ações (C, %, ⌫, ÷, ×, −, +, =) — cor primary
enum ButtonVariant { numeric, functional }

class CalculatorButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final ButtonVariant variant;

  const CalculatorButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.variant = ButtonVariant.numeric,
  });

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton>
    with TickerProviderStateMixin {
  // LED glow: acende imediatamente e apaga lentamente (~500ms)
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  // Background tap: surge suave e desaparece com fade out
  late final AnimationController _bgController;
  late final Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOutQuart,
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _bgAnimation = CurvedAnimation(
      parent: _bgController,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _bgController.value = 0.0;
    _glowController.value = 0.0;
  }

  void _handleTapUp(TapUpDetails _) {
    _bgController.forward(from: 0.0);
    _glowController.forward(from: 0.0);
  }

  void _handleTap() {
    widget.onPressed();
    _bgController.forward(from: 0.0);
    _glowController.forward(from: 0.0);
  }

  void _handleTapCancel() {
    _bgController.forward();
    _glowController.forward();
  }

  Color _baseTextColor(ColorScheme colors) {
    if (widget.variant == ButtonVariant.functional) {
      return colors.primary;
    }

    return colors.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseTextColor = _baseTextColor(colors);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTap: _handleTap,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          // bgAnimation: 0 = just tapped (full bg), 1 = fully faded
          final bgOpacity = (1.0 - _bgAnimation.value) * 0.12;

          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: bgOpacity),
              borderRadius: BorderRadius.circular(AppLayout.radius.small),
            ),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.icon != null
            ? _buildIconContent(baseTextColor)
            : _buildTextContent(baseTextColor),
      ),
    );
  }

  Widget _buildIconContent(Color baseColor) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = 1.0 - _glowAnimation.value;
        final color = Color.lerp(
          baseColor,
          _glowTarget(baseColor),
          glowIntensity * 0.7,
        )!;

        return Icon(widget.icon, color: color, size: AppLayout.spacing.large);
      },
    );
  }

  Widget _buildTextContent(Color baseColor) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = 1.0 - _glowAnimation.value;
        final color = Color.lerp(
          baseColor,
          _glowTarget(baseColor),
          glowIntensity * 0.7,
        )!;

        return Text(
          widget.label,
          style: TextStyle(
            color: color,
            fontSize: 26.0,
            fontWeight: FontWeight.w400,
          ),
        );
      },
    );
  }

  /// Cor alvo do LED glow — branco para numéricos, primary mais brilhante para funcionais.
  Color _glowTarget(Color base) {
    if (widget.variant == ButtonVariant.functional) {
      return Colors.white;
    }

    return Colors.white;
  }
}
