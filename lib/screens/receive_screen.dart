import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/transfer_service.dart';
import 'main_shell.dart';
import 'settings_screen.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final service = TransferService();

  String deviceName = '';
  String status = kIsWeb
      ? 'File receiving is available in the Windows and Android apps.'
      : 'Receiver is not running';
  String saveDirectory = 'Loading folder...';

  bool isRunning = false;

  final List<ReceivedFile> receivedFiles = [];

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      saveDirectory = 'Unavailable in a web browser';
    } else {
      loadSaveDirectory();
    }
  }

  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  Future<void> loadSaveDirectory() async {
    final path = await service.getSaveDirectory();

    if (!mounted) return;

    AppSettingsController.instance.saveDirectory.value = path;
    setState(() {
      saveDirectory = path;
    });
  }

  Future<void> saveReceivedFile(ReceivedFile receivedFile) async {
    if (kIsWeb) return;

    try {
      final sourceFile = File(receivedFile.path);
      if (!await sourceFile.exists()) {
        throw FileSystemException(
          'Received file no longer exists',
          receivedFile.path,
        );
      }

      final activeDir =
          AppSettingsController.instance.saveDirectory.value.isNotEmpty
              ? AppSettingsController.instance.saveDirectory.value
              : saveDirectory;

      final destinationPath = await FilePicker.saveFile(
        dialogTitle: 'Save received file',
        fileName: receivedFile.name,
        initialDirectory: Platform.isWindows ? activeDir : null,
        lockParentWindow: Platform.isWindows,
        bytes: Platform.isWindows ? null : await sourceFile.readAsBytes(),
      );
      if (destinationPath == null) return;

      if (Platform.isWindows) {
        final sourcePath = sourceFile.resolveSymbolicLinksSync();
        final destResolved = File(destinationPath).absolute.path;
        final sameFile =
            sourcePath.toLowerCase() == destResolved.toLowerCase();
        if (!sameFile) {
          await sourceFile.copy(destinationPath);
        }
      }

      if (!mounted) return;

      showSnackBar('Saved ${receivedFile.name}');
    } catch (error) {
      if (!mounted) return;

      showSnackBar('Could not save ${receivedFile.name}: $error');
    }
  }

  Future<void> startReceiving() async {
    if (kIsWeb) return;

    setState(() {
      status = 'Starting receiver...';
    });

    try {
      final name = await service.getLocalDeviceName();
      await service.startReceiver(
        onFileReceived: (file) {
          if (!mounted) return;

          setState(() {
            receivedFiles.insert(0, file);
            status = 'Received: ${file.name}';
          });
        },
      );

      if (!mounted) return;

      setState(() {
        deviceName = name;
        isRunning = true;
        status = 'Ready to receive files';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        status = 'Error: $error';
        isRunning = false;
      });
    }
  }

  Future<void> stopReceiving() async {
    await service.stopReceiver();

    if (!mounted) return;

    setState(() {
      isRunning = false;
      deviceName = '';
      status = 'Receiver stopped';
    });
  }

  @override
  void dispose() {
    service.stopReceiver();
    super.dispose();
  }

  BoxDecoration _homeStyleCard({
    required Color baseCard,
    required Color accent,
    required bool isDark,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.08 : 0.11),
            baseCard,
          ),
          baseCard,
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: accent.withValues(alpha: 0.26),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accent.withValues(alpha: 0.06),
          blurRadius: 20,
          spreadRadius: -2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        isDark ? const Color(0xFF060A12) : const Color(0xFF0F172A);
    final baseCard =
        isDark ? const Color(0xFF0E1626) : const Color(0xFF172236);
    final innerFieldColor =
        isDark ? const Color(0xFF080D18) : const Color(0xFF0F172A);
    const cyanPrimary = Color(0xFF00D9FF);
    const mintPrimary = Color(0xFF34D399);
    const textColor = Color(0xFFF8FAFC);
    const subTextColor = Color(0xFF94A3B8);
    final badgeColor = isRunning ? mintPrimary : cyanPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: cyanPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: cyanPrimary.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(Icons.menu_rounded, size: 18, color: textColor),
          ),
          tooltip: 'Menu',
          onPressed: () {
            context.findAncestorStateOfType<MainShellState>()?.openDrawer();
          },
        ),
        title: const Text(
          'Receive Files',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Back to Home',
            onPressed: () {
              context.findAncestorStateOfType<MainShellState>()?.switchTab(0);
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
              child: const Icon(Icons.home_rounded, size: 18, color: textColor),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // ─── Hero Status Card ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: _homeStyleCard(
                baseCard: baseCard,
                accent: badgeColor,
                isDark: isDark,
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          badgeColor.withValues(alpha: 0.24),
                          badgeColor.withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      isRunning
                          ? Icons.wifi_tethering_rounded
                          : Icons.wifi_rounded,
                      size: 30,
                      color: badgeColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ready to receive?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: subTextColor,
                    ),
                  ),
                  if (isRunning && deviceName.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: innerFieldColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cyanPrimary.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.devices_rounded,
                            size: 16,
                            color: cyanPrimary,
                          ),
                          const SizedBox(width: 8),
                          SelectableText(
                            deviceName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cyanPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ─── Save Location Info Only (Synced with Settings) ───
            ValueListenableBuilder<String>(
              valueListenable: AppSettingsController.instance.saveDirectory,
              builder: (context, currentDir, _) {
                final displayPath =
                    currentDir.isNotEmpty ? currentDir : saveDirectory;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _homeStyleCard(
                    baseCard: baseCard,
                    accent: cyanPrimary,
                    isDark: isDark,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.folder_rounded,
                            size: 16,
                            color: cyanPrimary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SAVE LOCATION',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: cyanPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: innerFieldColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cyanPrimary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: SelectableText(
                          displayPath,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // ─── Start / Stop Button ───
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isWeb
                    ? null
                    : isRunning
                        ? stopReceiving
                        : startReceiving,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning
                      ? Colors.redAccent.withValues(alpha: 0.18)
                      : cyanPrimary,
                  foregroundColor:
                      isRunning ? Colors.redAccent : const Color(0xFF060A12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  isWeb
                      ? Icons.info_outline
                      : isRunning
                          ? Icons.stop_rounded
                          : Icons.wifi_rounded,
                ),
                label: Text(
                  isWeb
                      ? 'Use Windows or Android app'
                      : isRunning
                          ? 'Stop Receiving'
                          : 'Start Receiving',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ─── Received Files Section ───
            Row(
              children: [
                const Text(
                  'RECEIVED FILES',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(width: 8),
                if (receivedFiles.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: mintPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${receivedFiles.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: mintPrimary,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              constraints: const BoxConstraints(minHeight: 150, maxHeight: 240),
              decoration: _homeStyleCard(
                baseCard: baseCard,
                accent: mintPrimary,
                isDark: isDark,
              ),
              child: receivedFiles.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No files received yet',
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: receivedFiles.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: mintPrimary.withValues(alpha: 0.14),
                      ),
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.check_circle_rounded,
                            color: mintPrimary,
                            size: 20,
                          ),
                          title: Text(
                            receivedFiles[index].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Save a copy',
                            onPressed: kIsWeb
                                ? null
                                : () => saveReceivedFile(receivedFiles[index]),
                            icon: const Icon(
                              Icons.download_outlined,
                              size: 20,
                              color: cyanPrimary,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}