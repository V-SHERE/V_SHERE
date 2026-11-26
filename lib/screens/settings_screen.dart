import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/transfer_service.dart';

enum AppLanguage { khmer, english, chinese, japanese }

class AppSettingsController {
  AppSettingsController._();
  static final AppSettingsController instance = AppSettingsController._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );
  final ValueNotifier<AppLanguage> language = ValueNotifier<AppLanguage>(
    AppLanguage.khmer,
  );
  final ValueNotifier<bool> showIpWhenNotFound = ValueNotifier<bool>(true);
  final ValueNotifier<String> saveDirectory = ValueNotifier<String>('');
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TransferService service = TransferService();
  final TextEditingController _nameController = TextEditingController();
  final AppSettingsController _settings = AppSettingsController.instance;

  String saveDirectory = '';
  String localIpAddress = '';
  bool loading = true;
  bool loadingIp = false;

  AppLanguage get _lang => _settings.language.value;

  String _tr({
    required String km,
    required String en,
    String? zh,
    String? ja,
  }) {
    switch (_lang) {
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

  @override
  void initState() {
    super.initState();
    _loadInfo();
    if (_settings.showIpWhenNotFound.value) {
      _loadLocalIp();
    }
  }

  Future<void> _loadInfo() async {
    try {
      final name = kIsWeb ? 'Web Browser' : await service.getLocalDeviceName();
      final dir = kIsWeb
          ? _tr(
              km: 'មិនគាំទ្រលើ Web',
              en: 'Unavailable in browser',
              zh: '浏览器中不可用',
              ja: 'ブラウザでは利用不可',
            )
          : await service.getSaveDirectory();

      if (!mounted) return;
      _settings.saveDirectory.value = dir;
      setState(() {
        _nameController.text = name;
        saveDirectory = dir;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        saveDirectory = _tr(
          km: 'មិនអាចផ្ទុក folder បាន',
          en: 'Could not load folder',
          zh: '无法加载文件夹',
          ja: 'フォルダを読み込めません',
        );
        loading = false;
      });
    }
  }

  Future<void> _loadLocalIp() async {
    if (kIsWeb) {
      if (!mounted) return;
      setState(() => localIpAddress = 'N/A (Web)');
      return;
    }

    setState(() => loadingIp = true);
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      String foundIp = '';
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            foundIp = addr.address;
            break;
          }
        }
        if (foundIp.isNotEmpty) break;
      }

      if (!mounted) return;
      setState(() {
        localIpAddress = foundIp.isNotEmpty
            ? foundIp
            : _tr(
                km: 'រកមិនឃើញ IP (ពិនិត្យ Wi-Fi)',
                en: 'No IP found (check Wi-Fi)',
                zh: '未找到 IP（请检查 Wi-Fi）',
                ja: 'IPが見つかりません（Wi-Fiを確認）',
              );
        loadingIp = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        localIpAddress = _tr(
          km: 'មិនអាចទាញយក IP បាន',
          en: 'Could not read IP address',
          zh: '无法读取 IP 地址',
          ja: 'IPアドレスを読み取れません',
        );
        loadingIp = false;
      });
    }
  }

  Future<void> _pickSaveFolder() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              km: 'លើ Android ឯកសារត្រូវបានរក្សាទុកក្នុង folder app',
              en: 'On Android, files are saved in the app folder',
              zh: '在 Android 上，文件保存在应用文件夹中',
              ja: 'Androidではファイルはアプリフォルダに保存されます',
            ),
          ),
        ),
      );
      return;
    }

    final selected = await FilePicker.getDirectoryPath();
    if (selected == null) return;

    final dir = Directory(selected);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await service.setSaveDirectory(selected);

    if (!mounted) return;
    _settings.saveDirectory.value = selected;
    setState(() => saveDirectory = selected);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tr(
            km: 'បានកំណត់ Save Folder រួចរាល់',
            en: 'Save folder updated',
            zh: '保存文件夹已更新',
            ja: '保存フォルダを更新しました',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.themeMode.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF060A12) : const Color(0xFF1E293B);
    final cardColor = isDark ? const Color(0xFF0F1520) : const Color(0xFF273549);
    final fieldColor =
        isDark ? const Color(0xFF080D18) : const Color(0xFF162032);
    final borderColor =
        const Color(0xFF00D9FF).withValues(alpha: isDark ? 0.16 : 0.22);
    const accentColor = Color(0xFF00D9FF);
    const textColor = Color(0xFFF8FAFC);
    const subTextColor = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        title: Text(
          _tr(
            km: 'ការកំណត់ (Settings)',
            en: 'Settings',
            zh: '设置',
            ja: '設定',
          ),
          style: const TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ─── Appearance: Dark Mode & Language ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APPEARANCE & LANGUAGE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: accentColor,
                        inactiveThumbColor: subTextColor,
                        inactiveTrackColor: fieldColor,
                        secondary: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: accentColor,
                        ),
                        title: Text(
                          _tr(
                            km: 'មុខងារងងឹត (Dark Mode)',
                            en: 'Dark Mode',
                            zh: '深色模式',
                            ja: 'ダークモード',
                          ),
                          style: const TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isDark
                              ? _tr(
                                  km: 'កំពុងបើក Dark Mode',
                                  en: 'Dark theme active',
                                  zh: '深色主题已启用',
                                  ja: 'ダークテーマが有効です',
                                )
                              : _tr(
                                  km: 'កំពុងបើក Slate Mode',
                                  en: 'Slate theme active',
                                  zh: '深蓝主题已启用',
                                  ja: 'スレートテーマが有効です',
                                ),
                          style:
                              const TextStyle(fontSize: 12, color: subTextColor),
                        ),
                        value: isDark,
                        onChanged: (value) {
                          setState(() {
                            _settings.themeMode.value = value
                                ? ThemeMode.dark
                                : ThemeMode.light;
                          });
                        },
                      ),
                      Divider(color: borderColor),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.translate_rounded, color: accentColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr(
                                    km: 'ភាសា (Language)',
                                    en: 'Language',
                                    zh: '语言',
                                    ja: '言語',
                                  ),
                                  style: const TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _tr(
                                    km: 'ជ្រើសរើសភាសារបស់កម្មវិធី',
                                    en: 'Choose display language',
                                    zh: '选择显示语言',
                                    ja: '表示言語を選択',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in const [
                            (AppLanguage.khmer, 'ខ្មែរ'),
                            (AppLanguage.english, 'English'),
                            (AppLanguage.chinese, '中文'),
                            (AppLanguage.japanese, '日本語'),
                          ])
                            ChoiceChip(
                              label: Text(entry.$2),
                              selected: _lang == entry.$1,
                              backgroundColor: fieldColor,
                              selectedColor: accentColor.withValues(alpha: 0.2),
                              side: BorderSide(
                                color: _lang == entry.$1
                                    ? accentColor
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                              labelStyle: TextStyle(
                                color: _lang == entry.$1
                                    ? accentColor
                                    : textColor,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (_) => setState(
                                () => _settings.language.value = entry.$1,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ─── Discovery & Fallback IP When Not Found ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DISCOVERY & IP FALLBACK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        activeTrackColor: accentColor,
                        inactiveThumbColor: subTextColor,
                        inactiveTrackColor: fieldColor,
                        secondary: const Icon(
                          Icons.router_rounded,
                          color: accentColor,
                        ),
                        title: Text(
                          _tr(
                            km: 'បង្ហាញ IP ពេលរកមិនឃើញ',
                            en: 'Show IP When Not Found',
                            zh: '未找到设备时显示 IP',
                            ja: '見つからない時にIPを表示',
                          ),
                          style: const TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _tr(
                            km: 'បង្ហាញ IP ក្នុងស្រុក ដើម្បីវាយភ្ជាប់ផ្ទាល់ពេលស្កេនរកមិនឃើញ',
                            en: 'Display local IP for manual connection when discovery fails',
                            zh: '扫描失败时显示本地 IP 以便手动连接',
                            ja: '検出できない時に手動接続用のローカルIPを表示',
                          ),
                          style:
                              const TextStyle(fontSize: 12, color: subTextColor),
                        ),
                        value: _settings.showIpWhenNotFound.value,
                        onChanged: (value) {
                          setState(() {
                            _settings.showIpWhenNotFound.value = value;
                          });
                          if (value && localIpAddress.isEmpty) {
                            _loadLocalIp();
                          }
                        },
                      ),
                      if (_settings.showIpWhenNotFound.value) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: fieldColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.wifi_tethering_rounded,
                                size: 18,
                                color: accentColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: loadingIp
                                    ? Text(
                                        _tr(
                                          km: 'កំពុងពិនិត្យ IP...',
                                          en: 'Checking IP...',
                                          zh: '正在检查 IP...',
                                          ja: 'IPを確認中...',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: subTextColor,
                                        ),
                                      )
                                    : SelectableText(
                                        localIpAddress.isEmpty
                                            ? '-'
                                            : 'IP: $localIpAddress',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: accentColor,
                                        ),
                                      ),
                              ),
                              IconButton(
                                tooltip: _tr(
                                  km: 'ផ្ទុក IP ឡើងវិញ',
                                  en: 'Refresh IP',
                                  zh: '刷新 IP',
                                  ja: 'IPを更新',
                                ),
                                onPressed: loadingIp ? null : _loadLocalIp,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ─── Device Name ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DEVICE NAME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        readOnly: true,
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.devices_rounded,
                            color: subTextColor,
                          ),
                          filled: true,
                          fillColor: fieldColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ─── Save Directory ───
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SAVE DIRECTORY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<String>(
                        valueListenable: _settings.saveDirectory,
                        builder: (context, currentDir, _) {
                          final displayDir =
                              currentDir.isNotEmpty ? currentDir : saveDirectory;
                          return SelectableText(
                            displayDir,
                            style:
                                const TextStyle(fontSize: 12, color: subTextColor),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            backgroundColor: fieldColor,
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: kIsWeb ? null : _pickSaveFolder,
                          icon: const Icon(
                            Icons.folder_open_rounded,
                            color: accentColor,
                          ),
                          label: Text(
                            _tr(
                              km: 'ជ្រើសរើស Folder រក្សាទុក',
                              en: 'Choose Save Folder',
                              zh: '选择保存文件夹',
                              ja: '保存フォルダを選択',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ─── App Info ───
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      leading: const Icon(Icons.info_outline, color: accentColor),
                      title: const Text(
                        'V-Shere',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _tr(
                          km: 'ជំនាន់ 1.0 • ផ្ទេរឯកសារតាម Wi-Fi ដោយផ្ទាល់',
                          en: 'Version 1.0 • Direct Wi-Fi Transfer',
                          zh: '版本 1.0 • 直连 Wi-Fi 文件传输',
                          ja: 'バージョン 1.0 • 直接Wi-Fi転送',
                        ),
                        style: const TextStyle(color: subTextColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}