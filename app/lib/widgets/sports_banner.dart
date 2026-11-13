import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Faixa visual reutilizável das áreas esportivas do FutPontos.
class SportsBanner extends StatelessWidget {
  const SportsBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.tag = 'FUTPONTOS',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;

  @override
  Widget build(BuildContext context) => Container(
    height: 126,
    margin: const EdgeInsets.only(bottom: 14),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF171D24),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _SportsBannerPainter())),
      Positioned(
        right: 14,
        top: 8,
        bottom: 8,
        child: Icon(icon, size: 92, color: Colors.white.withValues(alpha: .12)),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(17, 15, 100, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.circle, size: 6, color: AppColors.redLight),
              const SizedBox(width: 7),
              Text(tag, style: const TextStyle(
                color: AppColors.muted, fontSize: 9, letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
              )),
            ]),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
      const Positioned(left: 0, bottom: 0,
        child: SizedBox(width: 48, height: 4,
          child: ColoredBox(color: AppColors.red))),
    ]),
  );
}

class _SportsBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final field = Rect.fromLTWH(size.width * .56, 8, size.width * .40, size.height - 16);
    canvas.drawRect(field, paint);
    canvas.drawLine(Offset(field.center.dx, field.top),
      Offset(field.center.dx, field.bottom), paint);
    canvas.drawCircle(field.center, 19, paint);
    canvas.drawRect(Rect.fromLTWH(field.left, field.top + 25, 18,
      field.height - 50), paint);
  }

  @override
  bool shouldRepaint(covariant _SportsBannerPainter oldDelegate) => false;
}
