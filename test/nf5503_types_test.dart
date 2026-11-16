import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nf5503_flutter/nf5503_flutter.dart';

void main() {
  group('Nf5503 SDK constants', () {
    test('mirror decoder parameter and symbology IDs', () {
      expect(Nf5503ScanParamId.LIGHTS_MODE, 112);
      expect(Nf5503ScanParamId.CODE128_ENABLE, 250);
      expect(Nf5503ScanParamId.SYM_ALL_ENABLE, 1000);
      expect(Nf5503ScanSymbologyId.SYM_CODE128, 3);
      expect(Nf5503ScanSymbologyId.SYM_QR, 17);
      expect(Nf5503ScanLightsMode.CONCURRENT, 4);
    });

    test('mirror scan service constants', () {
      expect(Nf5503ScanConfig.ACTION_SCAN_RCV_MSG, 'scan.rcv.message');
      expect(Nf5503ScanConfig.BARCODE_DATA, 'barcodeData');
      expect(Nf5503ScanConfig.BARCODE_BYTE_DATA, 'barocode');
      expect(Nf5503ScanBroadcast.defaultAction, 'scan.rcv.message');
      expect(Nf5503ScanBroadcast.defaultKey, 'barcodeData');
    });
  });

  group('Nf5503ScanResult', () {
    test('preserves raw bytes and official broadcast metadata', () {
      final raw = Uint8List.fromList(<int>[0x41, 0x42, 0x43]);
      final aimId = Uint8List.fromList(<int>[0x5D, 0x43]);

      final result = Nf5503ScanResult.fromMap(<Object?, Object?>{
        'action': 'scan.rcv.message',
        'key': 'barcodeData',
        'data': 'ABC',
        'extras': <String, Object?>{
          'barcodeData': raw,
          'barocode': raw,
          'length': 3,
          'barcodeType': 7,
          'codeId': 'C',
          'aimId': aimId,
          'aimModifier': 0,
        },
      });

      expect(result.data, 'ABC');
      expect(result.action, 'scan.rcv.message');
      expect(result.broadcastKey, 'barcodeData');
      expect(result.rawData, raw);
      expect(result.length, 3);
      expect(result.barcodeType, 7);
      expect(result.codeId, 'C');
      expect(result.aimIdBytes, aimId);
      expect(result.aimId, ']C');
      expect(result.aimModifier, 0);
      expect(result.hasData, isTrue);
      expect(result.isEmpty, isFalse);
    });

    test('falls back to SDK raw byte fields and derives text metadata', () {
      final raw = Uint8List.fromList(<int>[0x31, 0x32, 0x33]);

      final result = Nf5503ScanResult.fromMap(<Object?, Object?>{
        'data': '',
        'extras': <String, Object?>{
          'barocode': raw,
          'barcodeType': '12',
          'length': '3',
        },
      });

      expect(result.rawData, raw);
      expect(result.barcodeType, 12);
      expect(result.length, 3);
      expect(result.hasData, isTrue);
    });
  });

  group('scanner value enums', () {
    test('unknown native values remain explicit', () {
      expect(
        Nf5503ScanOutputMode.fromValue(99),
        Nf5503ScanOutputMode.unknown,
      );
      expect(
        Nf5503ScanDecodeMode.fromValue(99),
        Nf5503ScanDecodeMode.unknown,
      );
      expect(Nf5503ScanEndMark.fromValue(99), Nf5503ScanEndMark.unknown);
    });
  });
}
