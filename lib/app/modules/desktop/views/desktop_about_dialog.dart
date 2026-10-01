import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 桌面端关于对话框
class DesktopAboutDialog extends StatelessWidget {
  const DesktopAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 88,
          height: 88,
          child: Image(
            image: AssetImage('assets/images/ic_logo.png'),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'app_name'.tr,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '1.0.2';
            return Text(
              'Version $version',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'app_summary'.tr,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'app_copyright'.tr,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
