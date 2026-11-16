import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nf5503_flutter/nf5503_flutter.dart';

void main() {
  group('Nf5503 NFC models', () {
    test('parses tag, NDEF and Mifare Classic information', () {
      final tag = Nf5503NfcTagInfo.fromMap(<Object?, Object?>{
        'id': Uint8List.fromList(<int>[0x04, 0xAB, 0xCD]),
        'idHex': '04ABCD',
        'techList': <String>[
          'android.nfc.tech.NfcA',
          'android.nfc.tech.MifareClassic',
        ],
        'ndefFormatable': true,
        'ndef': <String, Object?>{
          'type': 'NFC_FORUM_TYPE_2',
          'maxSize': 716,
          'writable': true,
          'canMakeReadOnly': true,
          'cachedMessage': <String, Object?>{
            'rawData': <int>[0xD1, 0x01, 0x03, 0x55],
            'records': <Object?>[
              <String, Object?>{
                'index': 0,
                'tnf': 1,
                'type': <int>[0x55],
                'id': <int>[],
                'payload': <int>[0x00, 0x41, 0x42],
                'typeName': 'U',
                'text': 'AB',
                'uri': null,
                'languageCode': 'en',
              },
            ],
          },
        },
        'mifareClassic': <String, Object?>{
          'type': 1,
          'size': 1024,
          'sectorCount': 16,
          'blockCount': 64,
          'maxTransceiveLength': 253,
        },
      });

      expect(tag.idHex, '04ABCD');
      expect(tag.reversedDecimalId, '13478660');
      expect(tag.ndefFormatable, isTrue);
      expect(tag.ndef?.writable, isTrue);
      expect(tag.ndef?.cachedMessage?.firstText, 'AB');
      expect(tag.mifareClassic?.type, Nf5503MifareClassicType.classic);
      expect(tag.mifareClassic?.sectorCount, 16);
      expect(tag.techList, contains('android.nfc.tech.MifareClassic'));
    });

    test('parses adapter state events and NFC status', () {
      final status = Nf5503NfcStatus.fromMap(<Object?, Object?>{
        'supported': true,
        'enabled': true,
        'readerModeActive': true,
        'adapterState': 3,
      });
      final event = Nf5503NfcEvent.fromMap(<Object?, Object?>{
        'type': 'adapterState',
        'state': 4,
        'status': <String, Object?>{
          'supported': true,
          'enabled': false,
          'readerModeActive': false,
          'adapterState': 4,
        },
      });

      expect(status.supported, isTrue);
      expect(status.enabled, isTrue);
      expect(status.readerModeActive, isTrue);
      expect(status.adapterState, Nf5503NfcAdapterState.on);
      expect(event.type, Nf5503NfcEventType.adapterState);
      expect(event.adapterState, Nf5503NfcAdapterState.turningOff);
      expect(event.status?.enabled, isFalse);
      expect(event.status?.readerModeActive, isFalse);
    });

    test('exposes official Mifare Classic default keys', () {
      expect(
        Nf5503MifareClassicConstants.keyDefault,
        <int>[0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
      );
      expect(
        Nf5503MifareClassicConstants.keyMifareApplicationDirectory,
        <int>[0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5],
      );
      expect(
        Nf5503MifareClassicConstants.keyNfcForum,
        <int>[0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7],
      );
    });
  });
}
