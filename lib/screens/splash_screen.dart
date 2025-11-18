import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TourGuard Logo from asset (with fallback)
            _buildLogo(),
            const SizedBox(height: 32),
            // App Name
            const Text(
              'TOURGUARD',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0066CC),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            // Tagline
            const Text(
              'Tourist Safety Hub',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to custom painted logo if image not found
          return CustomPaint(
            size: const Size(200, 200),
            painter: TourGuardLogoPainter(),
          );
        },
      ),
    );
  }
}

class TourGuardLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Define diamond shape points
    final topPoint = Offset(center.dx, center.dy - radius * 1.2);
    final rightPoint = Offset(center.dx + radius * 1.1, center.dy + radius * 0.3);
    final bottomPoint = Offset(center.dx, center.dy + radius * 1.2);
    final leftPoint = Offset(center.dx - radius * 1.1, center.dy + radius * 0.3);
    final midTopRight = Offset(center.dx + radius * 0.5, center.dy - radius * 0.4);
    final midBottomRight = Offset(center.dx + radius * 0.5, center.dy + radius * 0.8);

    // Top-left face (Light Blue)
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF42A5F5);
    canvas.drawPath(
      Path()
        ..moveTo(topPoint.dx, topPoint.dy)
        ..lineTo(center.dx, center.dy)
        ..lineTo(midTopRight.dx, midTopRight.dy)
        ..close(),
      paint,
    );

    // Top-right face (Darker Blue)
    paint.color = const Color(0xFF1976D2);
    canvas.drawPath(
      Path()
        ..moveTo(topPoint.dx, topPoint.dy)
        ..lineTo(midTopRight.dx, midTopRight.dy)
        ..lineTo(rightPoint.dx, rightPoint.dy)
        ..close(),
      paint,
    );

    // Left face (Dark Blue)
    paint.color = const Color(0xFF0D47A1);
    canvas.drawPath(
      Path()
        ..moveTo(topPoint.dx, topPoint.dy)
        ..lineTo(leftPoint.dx, leftPoint.dy)
        ..lineTo(center.dx, center.dy)
        ..close(),
      paint,
    );

    // Bottom-left face (Gray)
    paint.color = const Color(0xFF9E9E9E);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(leftPoint.dx, leftPoint.dy)
        ..lineTo(bottomPoint.dx, bottomPoint.dy)
        ..close(),
      paint,
    );

    // Bottom-right face (Darker Gray)
    paint.color = const Color(0xFF616161);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(bottomPoint.dx, bottomPoint.dy)
        ..lineTo(midBottomRight.dx, midBottomRight.dy)
        ..close(),
      paint,
    );

    // Right face (Medium Gray)
    paint.color = const Color(0xFF757575);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(midBottomRight.dx, midBottomRight.dy)
        ..lineTo(rightPoint.dx, rightPoint.dy)
        ..close(),
      paint,
    );

    // Draw "TG" text inside diamond
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'TG',
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
