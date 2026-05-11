import '../../domain/domain.dart';
import 'tesla_ble_constants.dart';

class TeslaAddKeyMessageCodec {
  const TeslaAddKeyMessageCodec({
    this.keyRole = TeslaKeyRole.owner,
    this.keyFormFactor = TeslaKeyFormFactor.androidDevice,
  });

  final TeslaKeyRole keyRole;
  final TeslaKeyFormFactor keyFormFactor;

  List<int> buildAddKeyEnvelope(PairingKeyMaterial keyMaterial) {
    final publicKey = _message([
      _bytesField(1, keyMaterial.publicKeySec1Bytes),
    ]);
    final permissionChange = _message([
      _bytesField(1, publicKey),
      _varintField(4, keyRole.value),
    ]);
    final keyMetadata = _message([_varintField(1, keyFormFactor.value)]);
    final whitelistOperation = _message([
      _bytesField(5, permissionChange),
      _bytesField(6, keyMetadata),
    ]);
    final unsignedMessage = _message([_bytesField(16, whitelistOperation)]);
    final signedMessage = _message([
      _bytesField(2, unsignedMessage),
      _varintField(3, 2),
    ]);
    return _message([_bytesField(1, signedMessage)]);
  }

  List<int> frame(List<int> payload) {
    if (payload.length > TeslaBleConstants.maxMessageSize) {
      throw StateError(
        'Tesla BLE payload exceeds ${TeslaBleConstants.maxMessageSize} bytes.',
      );
    }
    return List.unmodifiable([
      payload.length >> 8,
      payload.length & 0xff,
      ...payload,
    ]);
  }

  List<List<int>> chunks(
    List<int> payload, {
    int chunkSize = TeslaBleConstants.defaultChunkSize,
  }) {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be positive.');
    }
    final framed = frame(payload);
    return [
      for (var offset = 0; offset < framed.length; offset += chunkSize)
        List.unmodifiable(
          framed.sublist(
            offset,
            offset + chunkSize > framed.length
                ? framed.length
                : offset + chunkSize,
          ),
        ),
    ];
  }

  TeslaPairingResponse decodePairingResponse(List<int> payload) {
    final topLevel = _readFields(payload);
    final commandStatus = topLevel.lastLengthDelimited(4);
    if (commandStatus == null) {
      return const TeslaPairingResponse.waiting();
    }

    final statusFields = _readFields(commandStatus);
    final operationStatus = statusFields.lastVarint(1) ?? 1;
    final signedStatus = statusFields.lastLengthDelimited(2);
    if (signedStatus != null) {
      final signedFields = _readFields(signedStatus);
      final signedInformation = signedFields.lastVarint(2) ?? 0;
      if (signedInformation != 0) {
        return TeslaPairingResponse.failed(
          _signedMessageStatusMessage(signedInformation),
        );
      }
    }

    final whitelistStatus = statusFields.lastLengthDelimited(3);
    if (whitelistStatus != null) {
      final whitelistFields = _readFields(whitelistStatus);
      final information = whitelistFields.lastVarint(1) ?? 0;
      final whitelistOperationStatus =
          whitelistFields.lastVarint(3) ?? operationStatus;
      if (information != 0) {
        return TeslaPairingResponse.failed(
          _whitelistStatusMessage(information),
        );
      }
      if (whitelistOperationStatus == 0) {
        return const TeslaPairingResponse.paired();
      }
      if (whitelistOperationStatus == 2) {
        return const TeslaPairingResponse.failed('车辆拒绝配对请求。');
      }
      return const TeslaPairingResponse.waiting();
    }

    if (operationStatus == 0) {
      return const TeslaPairingResponse.paired();
    }
    if (operationStatus == 2) {
      return const TeslaPairingResponse.failed('车辆返回配对错误。');
    }
    return const TeslaPairingResponse.waiting();
  }
}

enum TeslaKeyRole {
  owner(2),
  driver(3);

  const TeslaKeyRole(this.value);

  final int value;
}

enum TeslaKeyFormFactor {
  androidDevice(7),
  cloudKey(9);

  const TeslaKeyFormFactor(this.value);

  final int value;
}

enum TeslaPairingResponseStatus { waiting, paired, failed }

class TeslaPairingResponse {
  const TeslaPairingResponse._(this.status, this.message);

  const TeslaPairingResponse.waiting()
    : this._(TeslaPairingResponseStatus.waiting, null);

  const TeslaPairingResponse.paired()
    : this._(TeslaPairingResponseStatus.paired, null);

  const TeslaPairingResponse.failed(String message)
    : this._(TeslaPairingResponseStatus.failed, message);

  final TeslaPairingResponseStatus status;
  final String? message;
}

class TeslaBleFrameAssembler {
  final _buffer = <int>[];

  List<List<int>> addChunk(List<int> chunk) {
    _buffer.addAll(chunk);
    final messages = <List<int>>[];
    while (_buffer.length >= 2) {
      final length = _buffer[0] * 256 + _buffer[1];
      if (length > TeslaBleConstants.maxMessageSize) {
        _buffer.clear();
        throw StateError('Tesla BLE response exceeds max message size.');
      }
      if (_buffer.length < length + 2) {
        break;
      }
      messages.add(List.unmodifiable(_buffer.sublist(2, length + 2)));
      _buffer.removeRange(0, length + 2);
    }
    return messages;
  }
}

List<int> _message(List<List<int>> fields) {
  return List.unmodifiable(fields.expand((field) => field));
}

List<int> _bytesField(int fieldNumber, List<int> value) {
  return [
    ..._varint((fieldNumber << 3) | 2),
    ..._varint(value.length),
    ...value,
  ];
}

List<int> _varintField(int fieldNumber, int value) {
  return [..._varint(fieldNumber << 3), ..._varint(value)];
}

List<int> _varint(int value) {
  final bytes = <int>[];
  var remaining = value;
  do {
    var byte = remaining & 0x7f;
    remaining >>= 7;
    if (remaining != 0) {
      byte |= 0x80;
    }
    bytes.add(byte);
  } while (remaining != 0);
  return bytes;
}

_ProtoFields _readFields(List<int> bytes) {
  final fields = <_ProtoField>[];
  var offset = 0;
  while (offset < bytes.length) {
    final tag = _readVarint(bytes, offset);
    offset = tag.nextOffset;
    final fieldNumber = tag.value >> 3;
    final wireType = tag.value & 0x07;
    switch (wireType) {
      case 0:
        final value = _readVarint(bytes, offset);
        offset = value.nextOffset;
        fields.add(_ProtoField.varint(fieldNumber, value.value));
        break;
      case 1:
        offset += 8;
        break;
      case 2:
        final length = _readVarint(bytes, offset);
        offset = length.nextOffset;
        final end = offset + length.value;
        if (end > bytes.length) {
          throw StateError('Malformed length-delimited protobuf field.');
        }
        fields.add(
          _ProtoField.lengthDelimited(fieldNumber, bytes.sublist(offset, end)),
        );
        offset = end;
        break;
      case 5:
        offset += 4;
        break;
      default:
        throw StateError('Unsupported protobuf wire type: $wireType');
    }
  }
  return _ProtoFields(fields);
}

_VarintResult _readVarint(List<int> bytes, int offset) {
  var result = 0;
  var shift = 0;
  var cursor = offset;
  while (cursor < bytes.length) {
    final byte = bytes[cursor];
    result |= (byte & 0x7f) << shift;
    cursor += 1;
    if ((byte & 0x80) == 0) {
      return _VarintResult(result, cursor);
    }
    shift += 7;
  }
  throw StateError('Malformed protobuf varint.');
}

class _VarintResult {
  const _VarintResult(this.value, this.nextOffset);

  final int value;
  final int nextOffset;
}

class _ProtoFields {
  const _ProtoFields(this.fields);

  final List<_ProtoField> fields;

  int? lastVarint(int fieldNumber) {
    for (final field in fields.reversed) {
      if (field.fieldNumber == fieldNumber && field.varintValue != null) {
        return field.varintValue;
      }
    }
    return null;
  }

  List<int>? lastLengthDelimited(int fieldNumber) {
    for (final field in fields.reversed) {
      if (field.fieldNumber == fieldNumber && field.bytesValue != null) {
        return field.bytesValue;
      }
    }
    return null;
  }
}

class _ProtoField {
  const _ProtoField.varint(this.fieldNumber, int value)
    : varintValue = value,
      bytesValue = null;

  const _ProtoField.lengthDelimited(this.fieldNumber, List<int> value)
    : bytesValue = value,
      varintValue = null;

  final int fieldNumber;
  final int? varintValue;
  final List<int>? bytesValue;
}

String _signedMessageStatusMessage(int status) {
  return switch (status) {
    2 => '车辆不认识当前配对凭证，请重新配对。',
    7 || 8 => '配对请求签名校验失败。',
    17 => '配对请求已过期，请重试。',
    _ => '车辆返回签名状态错误：$status。',
  };
}

String _whitelistStatusMessage(int status) {
  return switch (status) {
    4 => '车辆钥匙列表已满，请先在车机中删除旧钥匙。',
    5 => '当前车辆不允许添加钥匙。',
    6 => '车辆认为本机公钥无效。',
    13 => '该公钥已经在车辆钥匙列表中。',
    14 => '请将卡片放到中控台读卡区域后再确认。',
    24 => '车机端已拒绝本次配对。',
    25 => '等待卡片验证超时，请重试。',
    26 => '等待车机确认超时，请重试。',
    27 => '代客模式下不能添加钥匙。',
    28 => '配对已取消。',
    _ => '车辆返回钥匙添加错误：$status。',
  };
}
