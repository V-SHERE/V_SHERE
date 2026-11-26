import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/transfer_service.dart';
import 'main_shell.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TextEditingController deviceController = TextEditingController();
  final TransferService service = TransferService();

  List<PlatformFile> selectedFiles = [];
  bool sending = false;
  double transferProgress = 0.0;
  String status = '';

  List<DiscoveredDevice> discoveredDevices = [];
  DiscoverySession? discoverySession;
  DiscoveredDevice? selectedDevice;

  @override
  void initState() {
    super.initState();
    startScanning();
  }

  Future<void> startScanning() async {
    discoverySession?.stop();
    final targetName = deviceController.text.trim();

    final session = await service.startDiscovery(
      onDeviceFound: (device) {
        if (!mounted) return;
        setState(() {
          final index = discoveredDevices.indexWhere(
            (d) => d.ip == device.ip && d.port == device.port,
          );
          if (index >= 0) {
            discoveredDevices[index] = device;
          } else {
            discoveredDevices.add(device);
          }

          if (selectedDevice != null &&
              selectedDevice!.ip == device.ip &&
              selectedDevice!.port == device.port) {
            selectedDevice = device;
          }
        });
      },
    );

    if (!mounted) {
      session.stop();
      return;
    }
    discoverySession = session;

    if (targetName.isEmpty) return;

    setState(() => status = 'កំពុងស្វែងរក "$targetName"...');
    final device = await service.resolveTargetDevice(
      targetName,
      discoveredDevices,
    );
    if (!mounted) return;

    if (device != null) {
      setState(() {
        final alreadyListed = discoveredDevices.any(
          (existing) =>
              existing.ip == device.ip && existing.port == device.port,
        );
        if (!alreadyListed) discoveredDevices.add(device);
        status = '✓ រកឃើញ ${device.name}';
      });
    } else if (!discoveredDevices.any(
      (existing) => existing.name.toLowerCase() == targetName.toLowerCase(),
    )) {
      setState(() {
        status = 'រកមិនឃើញ "$targetName" ទេ។ សូមពិនិត្យឈ្មោះឧបករណ៍ទទួល។';
      });
    }
  }

  void selectDevice(DiscoveredDevice device) {
    setState(() {
      selectedDevice = device;
      deviceController.text = device.name;
      status = '✓ បានភ្ជាប់ទៅកាន់ ${device.name}';
    });
  }

  void _onDeviceInputChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    setState(() {
      if (selectedDevice != null &&
          selectedDevice!.name.toLowerCase() != trimmed) {
        selectedDevice = null;
      }
    });
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result == null || !mounted) return;

    setState(() {
      selectedFiles = [...selectedFiles, ...result.files];
      final seen = <String>{};
      selectedFiles = selectedFiles.where((f) {
        if (f.path == null) return true;
        return seen.add(f.path!);
      }).toList();
      if (!sending) {
        transferProgress = 0.0;
      }
    });
  }

  void removeFile(int index) {
    if (sending) return;
    setState(() {
      selectedFiles.removeAt(index);
      if (selectedFiles.isEmpty) {
        transferProgress = 0.0;
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> sendFiles() async {
    if (sending) return;

    final target = deviceController.text.trim();

    if (target.isEmpty) {
      setState(() => status = '⚠ សូមជ្រើសរើសឧបករណ៍ទទួលជាមុនសិន');
      return;
    }
    if (selectedFiles.isEmpty) {
      setState(() => status = '⚠ សូមជ្រើសរើសឯកសារយ៉ាងហោចណាស់មួយ');
      return;
    }

    setState(() {
      sending = true;
      transferProgress = 0.0;
      status = 'កំពុងស្វែងរកឧបករណ៍...';
    });

    final targetDevice = await service.resolveTargetDevice(
      target,
      discoveredDevices,
    );
    if (!mounted) return;

    if (targetDevice == null) {
      setState(() {
        sending = false;
        status = '✗ រកមិនឃើញឧបករណ៍ "$target"';
      });
      return;
    }

    setState(() {
      selectedDevice = targetDevice;
    });

    try {
      for (int i = 0; i < selectedFiles.length; i++) {
        if (!mounted) return;
        final file = selectedFiles[i];

        setState(() {
          transferProgress = i / selectedFiles.length;
          status = 'កំពុងផ្ញើ ${i + 1}/${selectedFiles.length}: ${file.name}';
        });

        await service.sendFile(
          receiverIp: targetDevice.ip,
          receiverPort: targetDevice.port,
          file: file,
        );
        if (!mounted) return;

        setState(() {
          transferProgress = (i + 1) / selectedFiles.length;
        });
      }

      if (!mounted) return;
      setState(() {
        status = '✓ ផ្ញើឯកសារទាំងអស់បានជោគជ័យ!';
        transferProgress = 1.0;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => status = '✗ $error');
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  void dispose() {
    discoverySession?.stop();
    deviceController.dispose();
    super.dispose();
  }

  IconData _getPlatformIcon(String platform) {
    final p = platform.toLowerCase();
    if (p.contains('win')) return Icons.laptop_windows_rounded;
    if (p.contains('android')) return Icons.phone_android_rounded;
    if (p.contains('ios')) return Icons.phone_iphone_rounded;
    if (p.contains('mac')) return Icons.laptop_mac_rounded;
    if (p.contains('linux')) return Icons.terminal_rounded;
    return Icons.devices_rounded;
  }

  Color _getFileColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return const Color(0xFFEF4444);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'svg':
        return const Color(0xFFA855F7);
      case 'mp4':
      case 'mkv':
      case 'mov':
      case 'avi':
        return const Color(0xFFF97316);
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'm4a':
        return const Color(0xFFEC4899);
      case 'apk':
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFF34D399);
      case 'doc':
      case 'docx':
      case 'txt':
      case 'xls':
      case 'xlsx':
        return const Color(0xFF00D9FF);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'svg':
        return Icons.image_rounded;
      case 'mp4':
      case 'mkv':
      case 'mov':
      case 'avi':
        return Icons.videocam_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'm4a':
        return Icons.audio_file_rounded;
      case 'apk':
        return Icons.android_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      case 'doc':
      case 'docx':
      case 'txt':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
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
    final totalBytes = selectedFiles.fold<int>(0, (sum, f) => sum + f.size);
    final isLinked =
        selectedDevice != null &&
        selectedDevice!.name.toLowerCase() ==
            deviceController.text.trim().toLowerCase();

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
    final cardAccent = isLinked ? mintPrimary : cyanPrimary;

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
          onPressed: sending
              ? null
              : () {
                  context
                      .findAncestorStateOfType<MainShellState>()
                      ?.openDrawer();
                },
        ),
        title: const Text(
          'Send Files',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Back to Home',
            onPressed: sending
                ? null
                : () {
                    context
                        .findAncestorStateOfType<MainShellState>()
                        ?.switchTab(0);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Receiver Input ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _homeStyleCard(
                  baseCard: baseCard,
                  accent: cardAccent,
                  isDark: isDark,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'RECEIVER',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: cyanPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (isLinked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: mintPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: mintPrimary,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Linked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: mintPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: deviceController,
                      enabled: !sending,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Device name',
                        hintStyle: TextStyle(
                          color: subTextColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.normal,
                          fontSize: 13,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.devices_rounded,
                            size: 18,
                            color: cyanPrimary,
                          ),
                        ),
                        suffixIcon: deviceController.text.isNotEmpty && !sending
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: subTextColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    deviceController.clear();
                                    selectedDevice = null;
                                  });
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: innerFieldColor,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: cyanPrimary,
                            width: 1.4,
                          ),
                        ),
                      ),
                      onChanged: _onDeviceInputChanged,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── Nearby Devices ───
              Row(
                children: [
                  const Icon(
                    Icons.radar_rounded,
                    size: 14,
                    color: cyanPrimary,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'NEARBY',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: subTextColor,
                    ),
                  ),
                  if (discoveredDevices.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cyanPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${discoveredDevices.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cyanPrimary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: sending
                        ? null
                        : () {
                            setState(() => discoveredDevices.clear());
                            startScanning();
                          },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 13,
                          color: cyanPrimary,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Scan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cyanPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (discoveredDevices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: baseCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cyanPrimary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: cyanPrimary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Scanning for receivers...',
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: discoveredDevices.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final device = discoveredDevices[index];
                      final isSelected =
                          selectedDevice == device ||
                          deviceController.text.trim().toLowerCase() ==
                              device.name.toLowerCase();

                      return GestureDetector(
                        onTap: sending ? null : () => selectDevice(device),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF00D9FF),
                                      Color(0xFF0284C7),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : baseCard,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: cyanPrimary.withValues(alpha: 0.22),
                                  ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : _getPlatformIcon(device.platform),
                                size: 15,
                                color: isSelected
                                    ? const Color(0xFF060A12)
                                    : cyanPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                device.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isSelected
                                      ? const Color(0xFF060A12)
                                      : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 14),

              // ─── Files Header ───
              Row(
                children: [
                  const Text(
                    'FILES',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: subTextColor,
                    ),
                  ),
                  if (selectedFiles.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: baseCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cyanPrimary.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        '${selectedFiles.length} • ${_formatBytes(totalBytes)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: subTextColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!sending) ...[
                      GestureDetector(
                        onTap: pickFiles,
                        child: const Text(
                          '+ Add',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cyanPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() {
                          selectedFiles.clear();
                          transferProgress = 0.0;
                        }),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // ─── Files List ───
              Expanded(
                child: selectedFiles.isEmpty
                    ? GestureDetector(
                        onTap: sending ? null : pickFiles,
                        child: Container(
                          width: double.infinity,
                          decoration: _homeStyleCard(
                            baseCard: baseCard,
                            accent: cyanPrimary,
                            isDark: isDark,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cyanPrimary.withValues(alpha: 0.24),
                                      const Color(0xFF0284C7)
                                          .withValues(alpha: 0.12),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: cyanPrimary.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  size: 30,
                                  color: cyanPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Choose Files',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to select photos, videos, docs',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: selectedFiles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final file = selectedFiles[index];
                          final color = _getFileColor(file.name);
                          final icon = _getFileIcon(file.name);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: baseCard,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: color.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatBytes(file.size),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!sending)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => removeFile(index),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: subTextColor,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),

              // ─── Status & Progress ───
              if (status.isNotEmpty || sending) ...[
                if (sending || transferProgress > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: subTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(transferProgress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cyanPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: transferProgress,
                      minHeight: 6,
                      backgroundColor: innerFieldColor,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(cyanPrimary),
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else if (status.isNotEmpty) ...[
                  Text(
                    status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],

              // ─── Send Action Button ───
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: sending ? null : sendFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyanPrimary,
                    foregroundColor: const Color(0xFF060A12),
                    disabledBackgroundColor: baseCard,
                    disabledForegroundColor: subTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF060A12),
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    sending
                        ? 'កំពុងផ្ញើ...'
                        : selectedFiles.isEmpty
                            ? 'Send Files'
                            : 'Send (${selectedFiles.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}