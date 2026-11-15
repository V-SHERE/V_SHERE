import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_shere/services/transfer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory supportDirectory;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'v_shere_transfer_service_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (call) async => supportDirectory.path,
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await supportDirectory.delete(recursive: true);
  });

  test('selected save folder persists across service instances', () async {
    const selectedDirectory = r'C:\Received Files';

    await TransferService().setSaveDirectory(selectedDirectory);

    expect(await TransferService().getSaveDirectory(), selectedDirectory);
  });

  test(
    'received file names stay readable while stored files remain unique',
    () {
      final service = TransferService();

      expect(service.sanitizeReceivedFileName('report?.pdf'), 'report_.pdf');

      final storedName = service.buildReceivedFileName('report?.pdf');
      expect(storedName, matches(RegExp(r'^\d+_report_.pdf$')));
    },
  );

  test('resolves discovered devices by name only', () async {
    final service = TransferService();
    const device = DiscoveredDevice(
      name: 'Office PC',
      ip: '192.168.1.20',
      port: 4041,
      platform: 'Windows',
    );

    expect(await service.resolveTargetDevice('office pc', [device]), device);
    expect(await service.resolveTargetDevice(device.ip, [device]), isNull);
  });

  test('starts and stops discovery across available interfaces', () async {
    final session = await TransferService().startDiscovery(
      onDeviceFound: (_) {},
    );

    session.stop();
    session.stop();
  });
}
