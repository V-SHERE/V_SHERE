import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/transfer_service.dart';
import 'home_screen.dart';
import 'receive_screen.dart';
import 'send_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TransferService _transferService = TransferService();
  int _currentIndex = 0;

  void switchTab(int index) {
    if (index < 0 || index > 2) return;
    setState(() => _currentIndex = index);
  }

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void openEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _openSaveFolder() async {
    if (kIsWeb) return;
    final dirPath = AppSettingsController.instance.saveDirectory.value.isNotEmpty
        ? AppSettingsController.instance.saveDirectory.value
        : await _transferService.getSaveDirectory();

    if (Platform.isWindows) {
      await Process.run('explorer.exe', [dirPath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [dirPath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [dirPath]);
    }
  }

  Widget _buildDrawerContent({
    required BuildContext context,
    required bool isLight,
    required AppLanguage lang,
  }) {
    final bgColor =
        isLight ? const Color(0xFFF1F6FC) : const Color(0xFF060A12);
    final cardColor =
        isLight ? const Color(0xFFFFFFFF) : const Color(0xFF0E1626);
    final textColor =
        isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final subColor =
        isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final accent =
        isLight ? const Color(0xFF0284C7) : const Color(0xFF00D9FF);

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

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'Asset/Logo.jpg',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'V-SHERE',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          tr(
                            km: 'ផ្ទេរឯកសារតាម Wi-Fi ផ្ទាល់',
                            en: 'Direct Wi-Fi Transfer',
                            zh: '直连 Wi-Fi 文件传输',
                            ja: '直接Wi-Fi転送',
                          ),
                          style: TextStyle(color: subColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Icon(Icons.home_rounded, color: accent),
              title: Text(
                tr(km: 'ទំព័រដើម', en: 'Home', zh: '首页', ja: 'ホーム'),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                switchTab(0);
              },
            ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Icon(Icons.upload_rounded, color: accent),
              title: Text(
                tr(
                  km: 'ផ្ញើឯកសារ',
                  en: 'Send Files',
                  zh: '发送文件',
                  ja: 'ファイル送信',
                ),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                switchTab(1);
              },
            ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Icon(Icons.download_rounded, color: accent),
              title: Text(
                tr(
                  km: 'ទទួលឯកសារ',
                  en: 'Receive Files',
                  zh: '接收文件',
                  ja: 'ファイル受信',
                ),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                switchTab(2);
              },
            ),
            if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS)
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(Icons.folder_open_rounded, color: accent),
                title: Text(
                  tr(
                    km: 'បើក Folder រក្សាទុក',
                    en: 'Open Folder',
                    zh: '打开文件夹',
                    ja: 'フォルダを開く',
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openSaveFolder();
                },
              ),
            const Divider(),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading: Icon(Icons.settings_rounded, color: accent),
              title: Text(
                tr(
                  km: 'ការកំណត់',
                  en: 'Settings',
                  zh: '设置',
                  ja: '設定',
                ),
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ).then((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // ផ្ទៃ Bottom Bar: ងងឹតច្បាស់ (#060A12) ក្នុង Dark Mode ឬ សភ្លឺច្បាស់ (#FFFFFF) ក្នុង Light Mode
    final navBgColor =
        isLight ? const Color(0xFFFFFFFF) : const Color(0xFF060A12);
    final navBorderColor = isLight
        ? const Color(0xFF0284C7).withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.08);
    final activeColor =
        isLight ? const Color(0xFF0284C7) : const Color(0xFF00D9FF);
    final pillColor = isLight
        ? const Color(0xFF0284C7).withValues(alpha: 0.14)
        : const Color(0xFF00D9FF).withValues(alpha: 0.16);
    final inactiveColor =
        isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final pages = [
      HomeScreen(onNavigateTab: switchTab),
      const SendScreen(),
      const ReceiveScreen(),
    ];

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

        final showOpenFolder = !kIsWeb && !Platform.isAndroid && !Platform.isIOS;

        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawerContent(
            context: context,
            isLight: isLight,
            lang: lang,
          ),
          endDrawer: _buildDrawerContent(
            context: context,
            isLight: isLight,
            lang: lang,
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBgColor,
              border: Border(
                top: BorderSide(color: navBorderColor, width: 1),
              ),
              boxShadow: isLight
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, -4),
                      ),
                    ]
                  : null,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: tr(
                        km: 'ទំព័រដើម',
                        en: 'Home',
                        zh: '首页',
                        ja: 'ホーム',
                      ),
                      selected: _currentIndex == 0,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      pillColor: pillColor,
                      onTap: () => switchTab(0),
                    ),
                    _NavItem(
                      icon: Icons.upload_rounded,
                      label: tr(
                        km: 'ផ្ញើ',
                        en: 'Send',
                        zh: '发送',
                        ja: '送信',
                      ),
                      selected: _currentIndex == 1,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      pillColor: pillColor,
                      onTap: () => switchTab(1),
                    ),
                    _NavItem(
                      icon: Icons.download_rounded,
                      label: tr(
                        km: 'ទទួល',
                        en: 'Receive',
                        zh: '接收',
                        ja: '受信',
                      ),
                      selected: _currentIndex == 2,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      pillColor: pillColor,
                      onTap: () => switchTab(2),
                    ),
                    if (showOpenFolder)
                      _NavItem(
                        icon: Icons.folder_open_rounded,
                        label: tr(
                          km: 'Folder',
                          en: 'Open Folder',
                          zh: '文件夹',
                          ja: 'フォルダ',
                        ),
                        selected: false,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        pillColor: pillColor,
                        onTap: _openSaveFolder,
                      ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final Color pillColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.pillColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = selected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected ? pillColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: fgColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}