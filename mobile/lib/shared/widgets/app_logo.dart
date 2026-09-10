import 'package:caresync/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 36,
    this.showWordmark = true,
    this.wordmarkColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
              child: Icon(Icons.medical_services_rounded, color: Colors.white, size: size * 0.6),
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: size * 0.3),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CARESYNC',
                  style: TextStyle(
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: wordmarkColor ?? const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w500,
                      color: (wordmarkColor ?? AppColors.textSecondary).withOpacity(0.8),
                      letterSpacing: 0.2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
