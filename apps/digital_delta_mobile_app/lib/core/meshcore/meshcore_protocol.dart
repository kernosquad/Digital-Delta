// MeshCore binary frame protocol — adapted from:
// https://github.com/zjs81/meshcore-open/blob/main/lib/connector/meshcore_protocol.dart
//
// Module 2/3 — BLE NUS frame builder & parser.

import 'dart:convert';
import 'dart:typed_data';

// ─────────────────────────────────────────────────────────────────────────────
// BufferReader
// ─────────────────────────────────────────────────────────────────────────────

/// Sequential binary data reader with pointer tracking.
class BufferReader {
  int _pointer = 0;
  final Uint8List _buffer;

  BufferReader(Uint8List data) : _buffer = Uint8List.fromList(data);

  int get remaining => _buffer.length - _pointer;

  int readByte() => readBytes(1)[0];

  Uint8List readBytes(int count) {
    if (_pointer + count > _buffer.length) {
      throw RangeError(
        'Attempted to read $count bytes at offset $_pointer, '
        'but only $remaining bytes remaining.',
      );
    }
    final data = _buffer.sublist(_pointer, _pointer + count);
    _pointer += count;
    return data;
  }

  void skipBytes(int count) {
    if (_pointer + count > _buffer.length) {
      throw RangeError(
        'Attempted to skip $count bytes at offset $_pointer, '
        'but only $remaining bytes remaining.',
      );
    }
    _pointer += count;
  }

  Uint8List readRemainingBytes() => readBytes(remaining);

  String readCString({int maxLength = -1}) {
    final value = <int>[];
    int counter = 0;
    final maxLen = maxLength >= 0 ? maxLength : remaining;
    while (counter < maxLen && remaining > 0) {
      final byte = readByte();
      if (byte == 0) break;
      value.add(byte);
      counter++;
    }
    try {
      return utf8.decode(Uint8List.fromList(value), allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(value);
    }
  }

  int readUInt8() => readBytes(1).buffer.asByteData().getUint8(0);
  int readInt8() => readBytes(1).buffer.asByteData().getInt8(0);
  int readUInt32LE() =>
      readBytes(4).buffer.asByteData().getUint32(0, Endian.little);
  int readInt32LE() =>
      readBytes(4).buffer.asByteData().getInt32(0, Endian.little);
  int readUInt16LE() =>
      readBytes(2).buffer.asByteData().getUint16(0, Endian.little);

  void resetPointer() => _pointer = 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// BufferWriter
// ─────────────────────────────────────────────────────────────────────────────

/// Accumulating binary data builder.
class BufferWriter {
  final BytesBuilder _builder = BytesBuilder();

  Uint8List toBytes() => _builder.toBytes();

  void writeByte(int byte) => _builder.addByte(byte & 0xFF);
  void writeBytes(Uint8List bytes) => _builder.add(bytes);

  void writeUInt32LE(int num) {
    final bytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeInt32LE(int num) {
    final bytes = Uint8List(4)
      ..buffer.asByteData().setInt32(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeUInt16LE(int num) {
    final bytes = Uint8List(2)
      ..buffer.asByteData().setUint16(0, num, Endian.little);
    writeBytes(bytes);
  }

  void writeString(String string) =>
      writeBytes(Uint8List.fromList(utf8.encode(string)));

  /// Write null-padded C string of exactly [maxLength] bytes.
  void writeCString(String string, int maxLength) {
    final bytes = Uint8List(maxLength);
    final encoded = utf8.encode(string);
    for (int i = 0; i < maxLength - 1 && i < encoded.length; i++) {
      bytes[i] = encoded[i];
    }
    writeBytes(bytes);
  }

  void writeBytesPadded(Uint8List bytes, int totalLength) {
    final padded = Uint8List(totalLength);
    final len = bytes.length < totalLength ? bytes.length : totalLength;
    for (int i = 0; i < len; i++) {
      padded[i] = bytes[i];
    }
    writeBytes(padded);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Command codes (host → device over BLE NUS / RX characteristic)
// ─────────────────────────────────────────────────────────────────────────────

const int cmdAppStart = 1;
const int cmdSendTxtMsg = 2;
const int cmdSendChannelTxtMsg = 3;
const int cmdGetContacts = 4;
const int cmdGetDeviceTime = 5;
const int cmdSetDeviceTime = 6;
const int cmdSendSelfAdvert = 7;
const int cmdSetAdvertName = 8;
const int cmdAddUpdateContact = 9;
const int cmdSyncNextMessage = 10;
const int cmdSetRadioParams = 11;
const int cmdSetRadioTxPower = 12;
const int cmdResetPath = 13;
const int cmdSetAdvertLatLon = 14;
const int cmdRemoveContact = 15;
const int cmdShareContact = 16;
const int cmdExportContact = 17;
const int cmdImportContact = 18;
const int cmdReboot = 19;
const int cmdGetBattAndStorage = 20;
const int cmdDeviceQuery = 22;
const int cmdSendLogin = 26;
const int cmdSendStatusReq = 27;
const int cmdGetContactByKey = 30;
const int cmdGetChannel = 31;
const int cmdSetChannel = 32;
const int cmdSendTracePath = 36;
const int cmdSetOtherParams = 38;
const int cmdSendTelemetryReq = 39;
const int cmdGetCustomVar = 40;
const int cmdSetCustomVar = 41;
const int cmdSendBinaryReq = 50;
const int cmdGetStats = 56;
const int cmdSendAnonReq = 57;
const int cmdSetAutoAddConfig = 58;
const int cmdGetAutoAddConfig = 59;
const int cmdSetPathHashMode = 61;

// ─────────────────────────────────────────────────────────────────────────────
// Response codes (device → host over TX characteristic)
// ─────────────────────────────────────────────────────────────────────────────

const int respCodeOk = 0;
const int respCodeErr = 1;
const int respCodeContactsStart = 2;
const int respCodeContact = 3;
const int respCodeEndOfContacts = 4;
const int respCodeSelfInfo = 5;
const int respCodeSent = 6;
const int respCodeContactMsgRecv = 7;
const int respCodeChannelMsgRecv = 8;
const int respCodeCurrTime = 9;
const int respCodeNoMoreMessages = 10;
const int respCodeExportContact = 11;
const int respCodeBattAndStorage = 12;
const int respCodeDeviceInfo = 13;
const int respCodeContactMsgRecvV3 = 16;
const int respCodeChannelMsgRecvV3 = 17;
const int respCodeChannelInfo = 18;
const int respCodeCustomVars = 21;
const int respCodeStats = 24;
const int respCodeAutoAddConfig = 25;

// ─────────────────────────────────────────────────────────────────────────────
// Push codes — async unsolicited frames from device
// ─────────────────────────────────────────────────────────────────────────────

const int pushCodeAdvert = 0x80;
const int pushCodePathUpdated = 0x81;
const int pushCodeSendConfirmed = 0x82;
const int pushCodeMsgWaiting = 0x83;
const int pushCodeLoginSuccess = 0x85;
const int pushCodeLoginFail = 0x86;
const int pushCodeStatusResponse = 0x87;
const int pushCodeLogRxData = 0x88;
const int pushCodeTraceData = 0x89;
const int pushCodeNewAdvert = 0x8A;
const int pushCodeTelemetryResponse = 0x8B;
const int pushCodeBinaryResponse = 0x8C;

// ─────────────────────────────────────────────────────────────────────────────
// Contact / advertisement types
// ─────────────────────────────────────────────────────────────────────────────

const int advTypeChat = 1;
const int advTypeRepeater = 2;
const int advTypeRoom = 3;
const int advTypeSensor = 4;

// Text message type flags
const int txtTypePlain = 0;
const int txtTypeCliData = 1;
const int txtTypeSigned = 2;

// Contact flags
const int contactFlagFavorite = 0x01;
const int contactFlagTeleBase = 0x02;
const int contactFlagTeleLoc = 0x04;
const int contactFlagTeleEnv = 0x08;

// ─────────────────────────────────────────────────────────────────────────────
// Frame sizes & offsets
// ─────────────────────────────────────────────────────────────────────────────

const int pubKeySize = 32;
const int maxNameSize = 32;
const int maxPathSize = 64;
const int maxFrameSize = 172;
const int appProtocolVersion = 3;

// Contact frame offsets (for respCodeContact frames):
// [code:1][pub_key:32][type:1][flags:1][path_len:1][path:64][name:32][ts:4][lat:4][lon:4][lastmod:4]
const int contactPubKeyOffset = 1;
const int contactTypeOffset = 33;
const int contactFlagsOffset = 34;
const int contactPathLenOffset = 35;
const int contactPathOffset = 36;
const int contactNameOffset = 100;
const int contactTimestampOffset = 132;
const int contactLatOffset = 136;
const int contactLonOffset = 140;
const int contactLastModOffset = 144;
const int contactFrameSize = 148;

// ─────────────────────────────────────────────────────────────────────────────
// Frame builder helpers
// ─────────────────────────────────────────────────────────────────────────────

/// CMD_APP_START — must be sent once after connecting.
Uint8List buildAppStartFrame({
  String appName = 'DigitalDelta',
  int appVersion = 1,
}) {
  final writer = BufferWriter();
  writer.writeByte(cmdAppStart);
  writer.writeByte(appVersion);
  writer.writeBytes(Uint8List(6)); // reserved
  writer.writeString(appName);
  writer.writeByte(0);
  return writer.toBytes();
}

/// CMD_DEVICE_QUERY — requests device info (name, pub key).
Uint8List buildDeviceQueryFrame({int appVersion = appProtocolVersion}) {
  return Uint8List.fromList([cmdDeviceQuery, appVersion]);
}

/// CMD_GET_CONTACTS — fetch the contact list.
Uint8List buildGetContactsFrame({int? since}) {
  final writer = BufferWriter();
  writer.writeByte(cmdGetContacts);
  if (since != null) writer.writeUInt32LE(since);
  return writer.toBytes();
}

/// CMD_GET_BATT_AND_STORAGE — request battery level.
Uint8List buildGetBattAndStorageFrame() {
  return Uint8List.fromList([cmdGetBattAndStorage]);
}

/// CMD_SEND_TXT_MSG — send a direct message to a contact.
/// Format: [cmd][txt_type][attempt][ts:4][pub_prefix:6][text...]\0
Uint8List buildSendTextMsgFrame(
  Uint8List recipientPubKey,
  String text, {
  int attempt = 0,
  int? timestampSeconds,
}) {
  final timestamp =
      timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  final writer = BufferWriter();
  writer.writeByte(cmdSendTxtMsg);
  writer.writeByte(txtTypePlain);
  writer.writeByte(attempt.clamp(0, 255));
  writer.writeUInt32LE(timestamp);
  writer.writeBytes(recipientPubKey.sublist(0, 6));
  writer.writeString(text);
  writer.writeByte(0);
  return writer.toBytes();
}

/// CMD_SEND_SELF_ADVERT — broadcast our own advertisement.
Uint8List buildSendSelfAdvertFrame({bool flood = false}) {
  return Uint8List.fromList([cmdSendSelfAdvert, flood ? 1 : 0]);
}

/// CMD_SYNC_NEXT_MESSAGE — pull next queued (store-and-forward) message.
Uint8List buildSyncNextMessageFrame() {
  return Uint8List.fromList([cmdSyncNextMessage]);
}

/// CMD_SET_DEVICE_TIME — synchronise device clock.
Uint8List buildSetDeviceTimeFrame(int timestamp) {
  final writer = BufferWriter();
  writer.writeByte(cmdSetDeviceTime);
  writer.writeUInt32LE(timestamp);
  return writer.toBytes();
}

/// CMD_RESET_PATH — force flood path for a contact.
Uint8List buildResetPathFrame(Uint8List pubKey) {
  final writer = BufferWriter();
  writer.writeByte(cmdResetPath);
  writer.writeBytes(pubKey);
  return writer.toBytes();
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Convert a public key [Uint8List] to lowercase hex string.
String pubKeyToHex(Uint8List pubKey) =>
    pubKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Check if the first 6 bytes of [fullKey] match [prefix].
bool matchesKeyPrefix(Uint8List fullKey, Uint8List prefix) {
  if (fullKey.length < prefix.length) return false;
  for (int i = 0; i < prefix.length; i++) {
    if (fullKey[i] != prefix[i]) return false;
  }
  return true;
}

/// Parse a self-info frame (respCodeSelfInfo).
/// Frame layout: [code:1][pub_key:32][name:32][lat?][lon?]
({Uint8List pubKey, String name, double? lat, double? lon})? parseSelfInfoFrame(
  Uint8List frame,
) {
  try {
    if (frame.isEmpty || frame[0] != respCodeSelfInfo) return null;
    if (frame.length < 65) return null;
    final pubKey = frame.sublist(1, 33);
    final nameBytes = frame.sublist(33, 65);
    final nullIdx = nameBytes.indexWhere((b) => b == 0);
    final name = utf8.decode(
      nullIdx >= 0 ? nameBytes.sublist(0, nullIdx) : nameBytes,
      allowMalformed: true,
    );
    double? lat, lon;
    if (frame.length >= 73) {
      lat =
          ByteData.sublistView(frame, 65, 69).getInt32(0, Endian.little) / 1e6;
      lon =
          ByteData.sublistView(frame, 69, 73).getInt32(0, Endian.little) / 1e6;
    }
    return (pubKey: pubKey, name: name, lat: lat, lon: lon);
  } catch (_) {
    return null;
  }
}

/// Parse a contact frame (respCodeContact).
/// Frame: [code:1][pubKey:32][type:1][flags:1][pathLen:1][path:64][name:32][ts:4][lat:4][lon:4]
({
  Uint8List pubKey,
  int type,
  int flags,
  int pathLen,
  Uint8List path,
  String name,
  DateTime lastSeen,
  double? lat,
  double? lon,
})?
parseContactFrame(Uint8List frame) {
  try {
    if (frame.isEmpty || frame[0] != respCodeContact) return null;
    if (frame.length < contactFrameSize) return null;
    final pubKey = frame.sublist(contactPubKeyOffset, contactPubKeyOffset + 32);
    final type = frame[contactTypeOffset];
    final flags = frame[contactFlagsOffset];
    final pathLen = frame[contactPathLenOffset];
    final path = frame.sublist(contactPathOffset, contactPathOffset + 64);
    final nameBytes = frame.sublist(contactNameOffset, contactNameOffset + 32);
    final nullIdx = nameBytes.indexWhere((b) => b == 0);
    final name = utf8.decode(
      nullIdx >= 0 ? nameBytes.sublist(0, nullIdx) : nameBytes,
      allowMalformed: true,
    );
    final ts = ByteData.sublistView(
      frame,
      contactTimestampOffset,
      contactTimestampOffset + 4,
    ).getUint32(0, Endian.little);
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    double? lat, lon;
    if (frame.length >= contactLonOffset + 4) {
      final latRaw = ByteData.sublistView(
        frame,
        contactLatOffset,
        contactLatOffset + 4,
      ).getInt32(0, Endian.little);
      final lonRaw = ByteData.sublistView(
        frame,
        contactLonOffset,
        contactLonOffset + 4,
      ).getInt32(0, Endian.little);
      if (latRaw != 0 || lonRaw != 0) {
        lat = latRaw / 1e6;
        lon = lonRaw / 1e6;
      }
    }
    return (
      pubKey: pubKey,
      type: type,
      flags: flags,
      pathLen: pathLen,
      path: path,
      name: name,
      lastSeen: lastSeen,
      lat: lat,
      lon: lon,
    );
  } catch (_) {
    return null;
  }
}

/// Parse an incoming direct message frame (respCodeContactMsgRecv / V3).
/// Frame: [code:1]{[snr:1][res:2] if V3}[prefix:6][pathLen:1][txtType:1][ts:4][text...]\0
({Uint8List senderPrefix, String text, DateTime timestamp, bool isCli})?
parseContactMessageFrame(Uint8List frame) {
  try {
    if (frame.isEmpty) return null;
    final code = frame[0];
    if (code != respCodeContactMsgRecv && code != respCodeContactMsgRecvV3) {
      return null;
    }
    final reader = BufferReader(frame);
    reader.readByte(); // consume code
    if (code == respCodeContactMsgRecvV3) {
      reader.skipBytes(3); // SNR + reserved
    }
    final senderPrefix = reader.readBytes(6);
    reader.skipBytes(1); // pathLen
    final txtType = reader.readByte();
    final tsRaw = reader.readUInt32LE();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(tsRaw * 1000);
    final shiftedType = txtType >> 2;
    final isSigned = shiftedType == txtTypeSigned || txtType == txtTypeSigned;
    if (isSigned) reader.skipBytes(4); // extra bytes for signed
    final text = reader.readCString();
    if (text.isEmpty) return null;
    final isCli = txtType == txtTypeCliData || shiftedType == txtTypeCliData;
    return (
      senderPrefix: senderPrefix,
      text: text,
      timestamp: timestamp,
      isCli: isCli,
    );
  } catch (_) {
    return null;
  }
}

/// Parse battery-and-storage response (respCodeBattAndStorage).
/// Returns millivolts value.
int? parseBatteryFrame(Uint8List frame) {
  try {
    if (frame.isEmpty || frame[0] != respCodeBattAndStorage) return null;
    if (frame.length < 3) return null;
    return ByteData.sublistView(frame, 1, 3).getUint16(0, Endian.little);
  } catch (_) {
    return null;
  }
}

/// Rough battery percentage from millivolts (assumes LiPo 3.7V nominal).
int batteryMvToPercent(int mv) {
  const maxMv = 4200;
  const minMv = 3300;
  if (mv >= maxMv) return 100;
  if (mv <= minMv) return 0;
  return ((mv - minMv) * 100 ~/ (maxMv - minMv)).clamp(0, 100);
}

/// Parse an advertisement push frame (pushCodeAdvert / pushCodeNewAdvert).
/// Layout mirrors the contact frame but starts with the push code byte.
({
  Uint8List pubKey,
  int type,
  int pathLen,
  Uint8List path,
  String name,
  double? lat,
  double? lon,
})?
parseAdvertFrame(Uint8List frame) {
  try {
    if (frame.isEmpty) return null;
    final code = frame[0];
    if (code != pushCodeAdvert && code != pushCodeNewAdvert) return null;
    // Re-use contact parser by substituting the code byte
    final fake = Uint8List(frame.length);
    fake[0] = respCodeContact;
    fake.setRange(1, frame.length, frame, 1);
    if (fake.length < contactFrameSize) return null;
    final result = parseContactFrame(fake);
    if (result == null) return null;
    return (
      pubKey: result.pubKey,
      type: result.type,
      pathLen: result.pathLen,
      path: result.path,
      name: result.name,
      lat: result.lat,
      lon: result.lon,
    );
  } catch (_) {
    return null;
  }
}
