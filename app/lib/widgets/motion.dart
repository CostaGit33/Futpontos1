import 'package:flutter/material.dart';

/// Entrada discreta para listas e blocos de conteúdo.
/// Respeita a preferência de movimento reduzido do sistema.
class MotionReveal extends StatefulWidget {
  const MotionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<MotionReveal> createState() => _MotionRevealState();
}

class _MotionRevealState extends State<MotionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _position = Tween<Offset>(
      begin: const Offset(0, .035),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _controller.value = 1;
        return;
      }
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _position, child: widget.child),
      );
}

/// Anima apenas a apresentação do valor recebido; não calcula estatísticas.
class MotionNumber extends StatelessWidget {
  const MotionNumber({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 520),
  });

  final num value;
  final TextStyle? style;
  final String suffix;
  final int decimals;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: reducedMotion ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => Text(
        '${current.toStringAsFixed(decimals)}$suffix',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Desenha o progresso gradualmente sem alterar o valor de origem.
class MotionProgressBar extends StatelessWidget {
  const MotionProgressBar({
    super.key,
    required this.value,
    this.minHeight = 7,
    this.backgroundColor,
    this.color,
    this.duration = const Duration(milliseconds: 650),
    this.semanticsLabel,
  });

  final double value;
  final double minHeight;
  final Color? backgroundColor;
  final Color? color;
  final Duration duration;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0).toDouble();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: reducedMotion ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => LinearProgressIndicator(
        value: progress,
        minHeight: minHeight,
        backgroundColor: backgroundColor,
        color: color,
        semanticsLabel: semanticsLabel,
        semanticsValue: '${(target * 100).round()}%',
      ),
    );
  }
}
