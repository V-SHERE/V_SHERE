import 'package:flutter/material.dart';

import 'main_shell.dart';
import 'receive_screen.dart';
import 'send_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  Widget featureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color primaryColor,
    required Color secondaryColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseCard =
        isDark ? const Color(0xFF0E1626) : const Color(0xFF172236);
    const textColor = Color(0xFFF8FAFC);
    const subColor = Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              primaryColor.withValues(alpha: isDark ? 0.08 : 0.11),
              baseCard,
            ),
            baseCard,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.26),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          splashColor: primaryColor.withValues(alpha: 0.14),
          highlightColor: primaryColor.withValues(alpha: 0.06),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withValues(alpha: 0.24),
                        secondaryColor.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(icon, color: primaryColor, size: 27),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: subColor,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF060A12) : const Color(0xFF0F172A);
    const cyanPrimary = Color(0xFF00D9FF);
    const cyanSecondary = Color(0xFF0284C7);
    const mintPrimary = Color(0xFF34D399);
    const mintSecondary = Color(0xFF059669);
    const textColor = Color(0xFFF8FAFC);
    const subColor = Color(0xFF94A3B8);

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppSettingsController.instance.language,
      builder: (context, lang, _) {
        String tr({
          required String km,
          required String en,
          String? zh,
          String? ja,
        }) {
          switch (lang) {
            case AppLanguage.khmer:
              return km;
            case AppLanguage.english:
              return en;
            case AppLanguage.chinese:
              return zh ?? en;
            case AppLanguage.japanese:
              return ja ?? en;
          }
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: cyanPrimary.withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cyanPrimary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'Asset/Logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'V-SHERE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: textColor,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Menu',
                onPressed: () {
                  context
                      .findAncestorStateOfType<MainShellState>()
                      ?.openEndDrawer();
                },
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cyanPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: cyanPrimary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    size: 18,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgColor,
                  Color.alphaBlend(
                    cyanPrimary.withValues(alpha: 0.03),
                    bgColor,
                  ),
                  bgColor,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFBAE6FD),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        tr(
                          km: 'ផ្ញើឯកសារ',
                          en: 'Share files.',
                          zh: '分享文件。',
                          ja: 'ファイルを共有。',
                        ),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        km: 'លឿន • សុវត្ថិភាព • ផ្ទាល់',
                        en: 'Fast. Private. Direct.',
                        zh: '快速、私密、直连。',
                        ja: '高速・安全・直接転送。',
                      ),
                      style: const TextStyle(
                        fontSize: 15.5,
                        color: subColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 26),
                    featureCard(
                      context: context,
                      icon: Icons.upload_rounded,
                      title: tr(
                        km: 'ផ្ញើឯកសារ (Send Files)',
                        en: 'Send Files',
                        zh: '发送文件',
                        ja: 'ファイルを送信',
                      ),
                      description: tr(
                        km: 'ផ្ញើរូបភាព វីដេអូ និងឯកសារ',
                        en: 'Send photos, videos and documents',
                        zh: '发送照片、视频和文档',
                        ja: '写真・動画・ドキュメントを送信',
                      ),
                      primaryColor: cyanPrimary,
                      secondaryColor: cyanSecondary,
                      onTap: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(1);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SendScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    featureCard(
                      context: context,
                      icon: Icons.download_rounded,
                      title: tr(
                        km: 'ទទួលឯកសារ (Receive Files)',
                        en: 'Receive Files',
                        zh: '接收文件',
                        ja: 'ファイルを受信',
                      ),
                      description: tr(
                        km: 'រៀបចំឧបករណ៍ឱ្យរួចរាល់ក្នុងការទទួល',
                        en: 'Make this device ready to receive',
                        zh: '让此设备准备好接收文件',
                        ja: '受信待機状態にする',
                      ),
                      primaryColor: mintPrimary,
                      secondaryColor: mintSecondary,
                      onTap: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(2);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReceiveScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cyanPrimary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.wifi_rounded,
                              color: cyanPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'DIRECT WI-FI TRANSFER',
                            style: TextStyle(
                              letterSpacing: 1.5,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'V-Shere • Version 1.0',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}