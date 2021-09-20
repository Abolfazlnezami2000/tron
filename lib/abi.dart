///
/// https://docs.soliditylang.org/en/v0.5.3/abi-spec.html
/// https://github.com/nbltrust/dart-eth-abi-codec
///
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:hex/hex.dart';

BigInt decodeUint256(Iterable b) {
  var testB = b.skip(32).take(b.length).toList();
  String testD = "";
  testB.forEach((element) {
    testD = testD + element;
  });

  return BigInt.parse(testD, radix: 16);
}

int decodeInt(Iterable b) {
  return decodeUint256(b).toInt();
}

bool decodeBool(Iterable b) {
  var decoded = decodeUint256(b).toInt();
  if(decoded != 0 && decoded != 1) {
    throw Exception("invalid encoded value for bool");
  }

  return decoded == 1;
}

Uint8List decodeBytes(Iterable b) {
  var length = decodeInt(b);
  var testB = b.skip(32).take(length).toList();
  var testC;
  testB.forEach((element) {
    testC.add(int.fromEnvironment(element));
  });
  return Uint8List.fromList(testC);
}

String decodeString(Iterable b) {
  var length = decodeInt(b);
  var testB = b.skip(32).take(length).toList();
  String testD = "";
  testB.forEach((element) {
    testD = testD + element.toString();
  });
  String test = String.fromCharCodes(HEX.decode(testD));
  return test.substring(test.indexOf("\f"), test.length);
}

dynamic decodeType(String type, Iterable b) {
  switch (type) {
    case 'string':
      return decodeString(b);
    case 'bool':
      return decodeBool(b);
    case 'bytes':
      return decodeBytes(b);
    default:
      break;
  }

  // support uint8, uint128, uint256 ...
  if(type.startsWith('uint')) {
    return decodeUint256(b);
  }

  if(type.startsWith('int')) {
    return decodeUint256(b);
  }
}
