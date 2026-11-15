import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class DiscoveredDevice {
  const DiscoveredDevice({
    required this.name,
    required this.ip,
    required this.port,
    required this.platform,
  });

  final String name;
  final String ip;
  final int port;
  final String platform;
}

class ReceivedFile {
  const ReceivedFile({required this.name, required this.path});

  final String name;
  final String path;
}

class DiscoverySession {
  DiscoverySession(this._sockets, this._timer);

  final List<RawDatagramSocket> _sockets;
  final Timer _timer;
  bool _stopped = false;

  void stop() {
    if (_stopped) return;
    _stopped = true;
    _timer.cancel();
    for (final socket in _sockets) {
      socket.close();
    }
  }
}

class TransferService {
  static const int androidPort = 4040;
  static const int windowsPort = 4041;
  static const int discoveryPort = 4042;
  static const String _saveDirectoryFileName = 'save_directory.txt';
  static const MethodChannel _multicastChannel = MethodChannel(
    'v_shere/wifi_multicast',
  );

  HttpServer? _server;
  RawDatagramSocket? _discoveryResponder;
  String? _selectedSaveDirectory;
  String? _localDeviceName;
  bool _multicastLockHeld = false;

  int get receiverPort {
    return Platform.isWindows ? windowsPort : androidPort;
  }

  Future<String> getLocalDeviceName() async {
    final cachedName = _localDeviceName;
    if (cachedName != null) return cachedName;

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final configuredName = deviceInfo.name.trim();
      final modelName = deviceInfo.model.trim();
      final name =
          configuredName.isNotEmpty &&
              configuredName.toLowerCase() != 'localhost'
          ? configuredName
          : modelName;
      final resolvedName = name.isNotEmpty ? name : 'Android device';
      _localDeviceName = resolvedName;
      return resolvedName;
    }

    final hostname = Platform.localHostname;
    _localDeviceName = hostname;
    return hostname;
  }

  String get _platformName {
    if (Platform.isWindows) return 'Windows';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  Future<DiscoverySession> startDiscovery({
    required void Function(DiscoveredDevice device) onDeviceFound,
  }) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final addresses = interfaces
        .expand((interface) => interface.addresses)
        .where(
          (address) =>
              !address.isLoopback && !address.address.startsWith('169.254.'),
        )
        .toList();
    final sockets = <RawDatagramSocket>[];

    try {
      for (final address in addresses) {
        final socket = await RawDatagramSocket.bind(address, 0);
        socket.broadcastEnabled = true;
        sockets.add(socket);
      }

      if (sockets.isEmpty) {
        final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        socket.broadcastEnabled = true;
        sockets.add(socket);
      }
    } on SocketException {
      for (final socket in sockets) {
        socket.close();
      }
      rethrow;
    }

    void scan() {
      final query = utf8.encode('V_SHERE_DISCOVER');
      for (final socket in sockets) {
        socket.send(query, InternetAddress('255.255.255.255'), discoveryPort);
      }
    }

    for (final socket in sockets) {
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;

        Datagram? datagram;
        while ((datagram = socket.receive()) != null) {
          try {
            final receivedDatagram = datagram!;
            final data = jsonDecode(utf8.decode(receivedDatagram.data));
            if (data is! Map<String, dynamic> || data['service'] != 'v-shere') {
              continue;
            }

            final name = data['name'];
            final port = data['port'];
            final platform = data['platform'];
            if (name is! String || port is! int || platform is! String) {
              continue;
            }

            onDeviceFound(
              DiscoveredDevice(
                name: name,
                ip: receivedDatagram.address.address,
                port: port,
                platform: platform,
              ),
            );
          } on FormatException {
            // Ignore unrelated UDP packets.
          }
        }
      });
    }

    scan();
    final timer = Timer.periodic(const Duration(seconds: 3), (_) => scan());
    return DiscoverySession(sockets, timer);
  }

  Future<DiscoveredDevice?> resolveTargetDevice(
    String target,
    List<DiscoveredDevice> devices,
  ) async {
    final normalizedTarget = target.toLowerCase();
    for (final device in devices) {
      if (device.name.toLowerCase() == normalizedTarget) {
        return device;
      }
    }

    if (InternetAddress.tryParse(target) != null) {
      return null;
    }

    final hostnames = target.toLowerCase().endsWith('.local')
        ? [target]
        : [target, '$target.local'];
    for (final hostname in hostnames) {
      late final List<InternetAddress> addresses;
      try {
        addresses = await InternetAddress.lookup(
          hostname,
          type: InternetAddressType.IPv4,
        );
      } on SocketException {
        continue;
      }

      for (final address in addresses) {
        for (final port in [windowsPort, androidPort]) {
          if (await _isVShereReceiver(address.address, port)) {
            return DiscoveredDevice(
              name: target,
              ip: address.address,
              port: port,
              platform: 'Unknown',
            );
          }
        }
      }
    }

    return null;
  }

  Future<bool> _isVShereReceiver(String host, int port) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
    final uri = Uri(scheme: 'http', host: host, port: port, path: '/health');

    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 1));
      final response = await request.close().timeout(
        const Duration(seconds: 1),
      );
      if (response.statusCode != HttpStatus.ok) return false;

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 1));
      return body == 'V-Shere is ready';
    } on SocketException {
      return false;
    } on HttpException {
      return false;
    } on TimeoutException {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  // Default folder when the user hasn't selected one.
  Future<String> getDefaultSaveDirectory() async {
    if (Platform.isAndroid) {
      // Use app-specific external storage (doesn't require permissions)
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final folder = Directory(
          '${directory.path}${Platform.pathSeparator}V-Shere-Received',
        );
        await folder.create(recursive: true);
        return folder.path;
      }
    }

    // Fallback for other platforms or if external storage fails
    final directory = await getApplicationDocumentsDirectory();

    final folder = Directory(
      '${directory.path}${Platform.pathSeparator}V-Shere-Received',
    );

    await folder.create(recursive: true);
    return folder.path;
  }

  Future<File> _saveDirectoryPreferencesFile() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File(
      '${directory.path}${Platform.pathSeparator}$_saveDirectoryFileName',
    );
  }

  // Persist the folder selected by the user.
  Future<void> setSaveDirectory(String directory) async {
    if (directory.isEmpty) {
      throw ArgumentError.value(directory, 'directory', 'Must not be empty');
    }

    final preferencesFile = await _saveDirectoryPreferencesFile();
    await preferencesFile.writeAsString(directory, flush: true);
    _selectedSaveDirectory = directory;
  }

  // Return the saved folder, or the default when no folder was selected.
  Future<String> getSaveDirectory() async {
    final selectedDirectory = _selectedSaveDirectory;
    if (selectedDirectory != null) return selectedDirectory;

    final preferencesFile = await _saveDirectoryPreferencesFile();
    if (await preferencesFile.exists()) {
      final savedDirectory = await preferencesFile.readAsString();
      if (savedDirectory.isNotEmpty) {
        _selectedSaveDirectory = savedDirectory;
        return savedDirectory;
      }
    }

    return getDefaultSaveDirectory();
  }

  Future<String> getLocalIp() async {
    try {
      final ip = await NetworkInfo().getWifiIP();

      if (ip != null && ip.isNotEmpty) {
        return ip;
      }
    } catch (_) {}

    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback && !address.address.startsWith('169.254.')) {
          return address.address;
        }
      }
    }

    return '127.0.0.1';
  }

  String sanitizeReceivedFileName(String value) {
    final trimmed = value.trim();
    final safeName = trimmed.isEmpty ? 'received_file' : trimmed;
    return safeName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String buildReceivedFileName(String value) {
    final safeName = sanitizeReceivedFileName(value);
    return '${DateTime.now().microsecondsSinceEpoch}_$safeName';
  }

  Future<String> startReceiver({
    required void Function(ReceivedFile file) onFileReceived,
  }) async {
    if (_server != null) {
      return getLocalIp();
    }

    final deviceName = await getLocalDeviceName();
    await _acquireMulticastLock();
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, receiverPort);
      await _startDiscoveryResponder(deviceName);
    } catch (_) {
      _discoveryResponder?.close();
      _discoveryResponder = null;
      await _server?.close(force: true);
      _server = null;
      await _releaseMulticastLock();
      rethrow;
    }

    _server!.listen((request) async {
      try {
        if (request.method == 'GET' && request.uri.path == '/health') {
          request.response.statusCode = HttpStatus.ok;
          request.response.write('V-Shere is ready');
          await request.response.close();
          return;
        }

        if (request.method != 'POST' || request.uri.path != '/upload') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final originalName =
            request.uri.queryParameters['name'] ?? 'received_file';

        final safeName = sanitizeReceivedFileName(originalName);
        final fileName = buildReceivedFileName(originalName);

        // Get the latest save directory (allows changing while receiving)
        final savePath = await getSaveDirectory();

        File outputFile;

        // Check if we're using SAF-managed directory (Android custom folder)
        if (Platform.isAndroid && _selectedSaveDirectory != null) {
          // For SAF directories, use a safer write method
          try {
            final saveFolder = Directory(savePath);
            await saveFolder.create(recursive: true);

            final filePath = '$savePath${Platform.pathSeparator}$fileName';
            outputFile = File(filePath);
          } catch (e) {
            // If SAF folder fails, fall back to default
            final defaultPath = await getDefaultSaveDirectory();
            final filePath = '$defaultPath${Platform.pathSeparator}$fileName';
            outputFile = File(filePath);
          }
        } else {
          // Non-Android or default folder
          final saveFolder = Directory(savePath);
          await saveFolder.create(recursive: true);

          final filePath = '$savePath${Platform.pathSeparator}$fileName';
          outputFile = File(filePath);
        }

        final sink = outputFile.openWrite();

        await sink.addStream(request);
        await sink.flush();
        await sink.close();

        onFileReceived(ReceivedFile(name: safeName, path: outputFile.path));

        request.response.statusCode = HttpStatus.ok;
        request.response.write('File received successfully');

        await request.response.close();
      } catch (error) {
        request.response.statusCode = HttpStatus.internalServerError;

        request.response.write('Receive failed: $error');

        try {
          await request.response.close();
        } catch (_) {}
      }
    });

    return getLocalIp();
  }

  Future<void> stopReceiver() async {
    _discoveryResponder?.close();
    _discoveryResponder = null;
    await _server?.close(force: true);
    _server = null;
    await _releaseMulticastLock();
  }

  Future<void> _acquireMulticastLock() async {
    if (!Platform.isAndroid || _multicastLockHeld) return;
    await _multicastChannel.invokeMethod<void>('acquire');
    _multicastLockHeld = true;
  }

  Future<void> _releaseMulticastLock() async {
    if (!Platform.isAndroid || !_multicastLockHeld) return;
    await _multicastChannel.invokeMethod<void>('release');
    _multicastLockHeld = false;
  }

  Future<void> _startDiscoveryResponder(String deviceName) async {
    _discoveryResponder = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
    );
    final ip = await getLocalIp();
    _discoveryResponder!.listen((event) {
      if (event != RawSocketEvent.read) return;

      Datagram? datagram;
      while ((datagram = _discoveryResponder!.receive()) != null) {
        if (utf8.decode(datagram!.data, allowMalformed: true) !=
            'V_SHERE_DISCOVER') {
          continue;
        }

        final response = utf8.encode(
          jsonEncode({
            'service': 'v-shere',
            'name': deviceName,
            'ip': ip,
            'port': receiverPort,
            'platform': _platformName,
          }),
        );
        _discoveryResponder!.send(response, datagram.address, datagram.port);
      }
    });
  }

  Future<void> sendFile({
    required String receiverIp,
    required int receiverPort,
    required PlatformFile file,
  }) async {
    if (file.path == null) {
      throw Exception('Cannot access ${file.name}');
    }

    final sourceFile = File(file.path!);

    if (!await sourceFile.exists()) {
      throw Exception('File does not exist: ${file.name}');
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final uri = Uri(
        scheme: 'http',
        host: receiverIp,
        port: receiverPort,
        path: '/upload',
        queryParameters: {'name': file.name},
      );

      final request = await client.postUrl(uri);
      request.contentLength = await sourceFile.length();

      await request.addStream(sourceFile.openRead());

      final response = await request.close();

      final responseText = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          responseText.isEmpty ? 'Transfer failed' : responseText,
        );
      }
    } finally {
      client.close(force: true);
    }
  }
}
