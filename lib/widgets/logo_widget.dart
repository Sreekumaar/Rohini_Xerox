import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final bool showTagline;
  final double size;

  const LogoWidget({super.key, this.showTagline = false, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'R',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'X',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ROHINI XEROX',
              style: TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (showTagline)
              Text(
                'KING OF XEROX - SINCE 2002',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }
}
