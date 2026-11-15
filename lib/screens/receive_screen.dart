import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/transfer_service.dart';

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

    setState(() {
      saveDirectory = path;
    });
  }

  // Let the user choose a destination folder.
  Future<void> chooseSaveFolder() async {
    if (kIsWeb) return;

    try {
      // On Android, use app-specific external storage only
      // to avoid permission issues with scoped storage
      if (Platform.isAndroid) {
        showSnackBar(
          'On Android, files are saved to app storage folder',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final selectedDirectory = await FilePicker.getDirectoryPath();

      if (selectedDirectory == null) return;

      final directory = Directory(selectedDirectory);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await service.setSaveDirectory(selectedDirectory);

      if (!mounted) return;

      setState(() {
        saveDirectory = selectedDirectory;
        status = 'Save location updated';
      });

      showSnackBar('Save folder updated successfully');
    } catch (error) {
      if (!mounted) return;

      showSnackBar('Could not select folder: $error');
    }
  }

  Future<void> openSaveFolder() async {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      final directory = Directory(saveDirectory);
      if (!await directory.exists()) {
        throw FileSystemException('Save folder does not exist', saveDirectory);
      }

      await Process.start('explorer.exe', [directory.path]);
    } catch (error) {
      if (!mounted) return;

      showSnackBar('Could not open save folder: $error');
    }
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

      final destinationPath = await FilePicker.saveFile(
        dialogTitle: 'Save received file',
        fileName: receivedFile.name,
        initialDirectory: Platform.isWindows ? saveDirectory : null,
        lockParentWindow: Platform.isWindows,
        bytes: Platform.isWindows ? null : await sourceFile.readAsBytes(),
      );
      if (destinationPath == null) return;

      if (Platform.isWindows) {
        // Compare resolved paths to avoid copying a file onto itself.
        // FileSystemEntity.identical() throws if either path doesn't exist
        // (the destination is a new path, not yet a file), so we compare
        // canonicalized path strings instead.
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

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final isAndroid = !isWeb && Platform.isAndroid;
    final isWindows = !isWeb && Platform.isWindows;

    return Scaffold(
      appBar: AppBar(title: const Text('Receive Files')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            Container(
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.wifi,
                size: 40,
                color: Colors.greenAccent,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Ready to receive?',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),

            const SizedBox(height: 16),

            // Save location card.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.folder, color: Color(0xFF00D9FF)),
                        SizedBox(width: 10),
                        Text(
                          'SAVE LOCATION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SelectableText(
                      saveDirectory,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: isWeb
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Unavailable in a web browser'),
                            )
                          : isAndroid
                          ? OutlinedButton.icon(
                              onPressed: null, // Disabled on Android
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Android uses app storage'),
                            )
                          : isWindows
                          ? Column(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: openSaveFolder,
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Open Save Folder'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: chooseSaveFolder,
                                  icon: const Icon(Icons.folder),
                                  label: const Text('Choose Save Folder'),
                                ),
                              ],
                            )
                          : OutlinedButton.icon(
                              onPressed: chooseSaveFolder,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Choose Save Folder'),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (isRunning)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR DEVICE NAME',
                        style: TextStyle(
                          color: Colors.white60,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      SelectableText(
                        deviceName,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D9FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isWeb
                    ? null
                    : isRunning
                    ? stopReceiving
                    : startReceiving,
                icon: Icon(
                  isWeb
                      ? Icons.info_outline
                      : isRunning
                      ? Icons.stop
                      : Icons.wifi,
                ),
                label: Text(
                  isWeb
                      ? 'Use Windows or Android app'
                      : isRunning
                      ? 'Stop Receiving'
                      : 'Start Receiving',
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Received Files',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 200,
              child: receivedFiles.isEmpty
                  ? const Center(
                      child: Text(
                        'No files received yet',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      primary: false,
                      itemCount: receivedFiles.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                          ),
                          title: Text(
                            receivedFiles[index].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Save a copy',
                            onPressed: kIsWeb
                                ? null
                                : () => saveReceivedFile(receivedFiles[index]),
                            icon: const Icon(Icons.download_outlined),
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
