import 'package:flutter/material.dart';

class BackgroundPattern extends StatelessWidget {
  final Widget child;

  const BackgroundPattern({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE8F5E9), // Light Green 50
                Colors.white,
              ],
            ),
          ),
        ),
        
        // Abstract Organic Shapes (Circles)
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9).withOpacity(0.3), // Green 100
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Icons Pattern
        _buildIconPattern(context),

        // Child Content
        child,
      ],
    );
  }

  Widget _buildIconPattern(BuildContext context) {
    const iconColor = Color(0xFF81C784); // Green 300
    const iconOpacity = 0.1;

    return Stack(
      children: [
        Positioned(
          top: 100,
          left: 40,
          child: Transform.rotate(
            angle: -0.2,
            child: Icon(Icons.grass, size: 60, color: iconColor.withOpacity(iconOpacity)),
          ),
        ),
        Positioned(
          top: 200,
          right: 30,
          child: Transform.rotate(
            angle: 0.2,
            child: Icon(Icons.wb_sunny, size: 80, color: Colors.orange.withOpacity(iconOpacity * 0.8)),
          ),
        ),
        Positioned(
          bottom: 100,
          right: 60,
          child: Transform.rotate(
            angle: -0.1,
            child: Icon(Icons.eco, size: 50, color: iconColor.withOpacity(iconOpacity)),
          ),
        ),
        Positioned(
          bottom: 250,
          left: 20,
          child: Icon(Icons.water_drop, size: 40, color: Colors.blue.withOpacity(iconOpacity * 0.8)),
        ),
      ],
    );
  }
}
