import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/core/pwa/pwa_install_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PwaInstallButton extends ConsumerWidget {
  final bool compact;

  const PwaInstallButton({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return const SizedBox.shrink();

    final pwaState = ref.watch(pwaInstallProvider);
    if (pwaState.isInstalled) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 640;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Tooltip(
        message: 'Install CareSync application for fast offline & desktop access',
        child: InkWell(
          onTap: pwaState.isPrompting ? null : () => showInstallGuideOrPrompt(context, ref),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: (compact || !isDesktop) ? 10 : 12,
              vertical: (compact || !isDesktop) ? 6 : 7,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDesktop ? Icons.install_desktop_rounded : Icons.install_mobile_rounded,
                  size: (compact || !isDesktop) ? 16 : 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  (compact || !isDesktop) ? 'Install' : 'Install CareSync',
                  style: TextStyle(
                    fontSize: (compact || !isDesktop) ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showInstallGuideOrPrompt(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(pwaInstallProvider.notifier).promptInstall();

    if (result.supported && result.accepted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ CareSync installed successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (!result.supported && context.mounted) {
      _showFallbackDialog(context);
    }
  }

  static void _showFallbackDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.install_desktop_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Install CareSync',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Install CareSync on your device for quick access, desktop launch, and enhanced speed.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildInstructionStep(
                icon: Icons.computer_rounded,
                title: 'Desktop (Chrome, Edge, Brave)',
                detail: 'Click the install icon (⊕ or ⬇) in the browser address bar, or open Menu (⋮) → "Install CareSync".',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                icon: Icons.phone_iphone_rounded,
                title: 'iPhone / iPad (Safari)',
                detail: 'Tap the Share button (⎋) at the bottom and select "Add to Home Screen".',
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                icon: Icons.android_rounded,
                title: 'Android (Chrome)',
                detail: 'Tap Menu (⋮) and select "Install app" or "Add to Home screen".',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInstructionStep({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
