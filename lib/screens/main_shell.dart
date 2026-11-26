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
  final TransferService _service = TransferService();
  int _currentIndex = 0;

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void openEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void switchTab(int index) {
    if (index < 0 || index > 3) return;
    setState(() => _currentIndex = index);
  }

  Future<void> openSaveFolder() async {
    if (kIsWeb) return;

    try {
      final path =
          AppSettingsController.instance.saveDirectory.value.isNotEmpty
              ? AppSettingsController.instance.saveDirectory.value
              : await _service.getSaveDirectory();
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      if (Platform.isWindows) {
        await Process.start('explorer.exe', [directory.path]);
      } else if (Platform.isMacOS) {
        await Process.start('open', [directory.path]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [directory.path]);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save folder: ${directory.path}')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open save folder: $error')),
      );
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showNetworkHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1520),
        title: const Text(
          'Connection Help',
          style: TextStyle(color: Color(0xFFF8FAFC)),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ឧបករណ៍ទាំងពីរគួរភ្ជាប់ Wi-Fi ឬ Hotspot តែមួយ។',
              style: TextStyle(color: Color(0xFFE2E8F0)),
            ),
            SizedBox(height: 6),
            Text(
              '• នៅលើឧបករណ៍ទទួល សូមចុច Start Receiving។',
              style: TextStyle(color: Color(0xFFE2E8F0)),
            ),
            SizedBox(height: 6),
            Text(
              '• ប្រសិនបើរកមិនឃើញ សូមពិនិត្យ Firewall ឬចុច Scan ម្តងទៀត។',
              style: TextStyle(color: Color(0xFFE2E8F0)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'យល់ព្រម',
              style: TextStyle(color: Color(0xFF00D9FF)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'V-Shere',
      applicationVersion: 'Version 1.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'Asset/Logo.jpg',
          width: 42,
          height: 42,
          fit: BoxFit.cover,
        ),
      ),
      children: const [
        Text('Direct Wi-Fi file transfer — Fast. Private. Direct.'),
      ],
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: Color(0xFF00D9FF),
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    const titleColor = Color(0xFFF8FAFC);
    const subColor = Color(0xFFCBD5E1);
    const activeColor = Color(0xFF00D9FF);

    return Material(
      color: selected
          ? activeColor.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: selected,
        selectedColor: activeColor,
        iconColor: iconColor,
        textColor: titleColor,
        leading: Icon(icon, color: selected ? activeColor : iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? activeColor : titleColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: subColor,
                ),
              ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    const drawerBg = Color(0xFF0A0F1D);
    const headerBg = Color(0xFF0F1520);
    const textColor = Color(0xFFF8FAFC);
    const accentColor = Color(0xFF00D9FF);

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'Asset/Logo.jpg',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'V-SHERE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fast. Private. Direct.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            _sectionLabel('MENU'),
            _drawerTile(
              icon: Icons.home_rounded,
              iconColor: accentColor,
              title: 'Home',
              selected: _currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                switchTab(0);
              },
            ),
            _drawerTile(
              icon: Icons.upload_rounded,
              iconColor: accentColor,
              title: 'Send Files',
              selected: _currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                switchTab(1);
              },
            ),
            _drawerTile(
              icon: Icons.download_rounded,
              iconColor: const Color(0xFF34D399),
              title: 'Receive Files',
              selected: _currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                switchTab(2);
              },
            ),
            const SizedBox(height: 6),
            const Divider(color: Colors.white12),
            _sectionLabel('SETTINGS & STORAGE'),
            _drawerTile(
              icon: Icons.settings_rounded,
              iconColor: accentColor,
              title: 'Settings',
              subtitle: 'Device name & save directory',
              onTap: () {
                Navigator.pop(context);
                _openSettings();
              },
            ),
            _drawerTile(
              icon: Icons.folder_open_rounded,
              iconColor: accentColor,
              title: 'Open Save Folder',
              onTap: () async {
                Navigator.pop(context);
                await openSaveFolder();
              },
            ),
            const SizedBox(height: 6),
            const Divider(color: Colors.white12),
            _sectionLabel('SUPPORT'),
            _drawerTile(
              icon: Icons.help_outline_rounded,
              iconColor: const Color(0xFFE2E8F0),
              title: 'Connection Help',
              onTap: () {
                Navigator.pop(context);
                _showNetworkHelpDialog();
              },
            ),
            _drawerTile(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFFE2E8F0),
              title: 'About V-Shere',
              subtitle: 'Version 1.0',
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onNavigateTab: switchTab),
      const SendScreen(),
      const ReceiveScreen(),
      const SizedBox.shrink(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      endDrawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1D),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: const Color(0xFF0A0F1D),
          indicatorColor: const Color(0xFF00D9FF).withValues(alpha: 0.16),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) async {
            if (index == 3) {
              await openSaveFolder();
              return;
            }
            switchTab(index);
          },
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              tooltip: '',
              icon: Icon(Icons.home_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF00D9FF)),
              label: 'Home',
            ),
            NavigationDestination(
              tooltip: '',
              icon: Icon(Icons.upload_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.upload_rounded, color: Color(0xFF00D9FF)),
              label: 'Send',
            ),
            NavigationDestination(
              tooltip: '',
              icon: Icon(Icons.download_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(
                Icons.download_rounded,
                color: Color(0xFF34D399),
              ),
              label: 'Receive',
            ),
            NavigationDestination(
              tooltip: '',
              icon: Icon(Icons.folder_open_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(
                Icons.folder_open_rounded,
                color: Color(0xFF00D9FF),
              ),
              label: 'Open Folder',
            ),
          ],
        ),
      ),
    );
  }
}