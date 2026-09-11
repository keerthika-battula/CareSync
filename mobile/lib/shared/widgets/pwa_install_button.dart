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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Native install prompt is not currently available in this browser session. You can install CareSync from your browser menu (⋮) or address bar.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
