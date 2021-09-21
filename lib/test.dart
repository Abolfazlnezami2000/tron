import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:hex/hex.dart';
import 'package:secp256k1/secp256k1.dart';
import 'package:sha3/sha3.dart';
import 'package:crypto/crypto.dart';
import 'package:fast_base58/fast_base58.dart';

encryptPrivateKeyByPassword(String privateKey , String password) {

  String password32length = password;
  for(int i = 0 ; i < 32 - password.length ; i++)
  {
    password32length = password32length + '0';
  }
  final key = Key.fromUtf8(password32length);
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(key));
  final encrypted = encrypter.encrypt(privateKey, iv: iv);

  return encrypted.base64;
}


decryptPrivateKeyByPassword(String privateKey , String password) {

  String password32length = password;
  for(int i = 0 ; i < 32 - password.length ; i++)
  {
    password32length = password32length + '0';
  }
  final key = Key.fromUtf8(password32length);
  final iv = IV.fromLength(16);
  final decrypter = Encrypter(AES(key));

  final privateKeyEncrypted = Encrypted.fromBase64(privateKey);
  final decrypted = decrypter.decrypt(privateKeyEncrypted, iv: iv);

  return decrypted;
}
publicBigIntToBase58(PublicKey pub) {
  String step1 = pub.toString();
  String step2 = step1.substring(2 , 130);
  var sha3 = SHA3(256, KECCAK_PADDING, 256);
  sha3.update(HEX.decode(step2));
  var hash = sha3.digest();
  var step3 = HEX.encode(hash).toString();
  var step4 = step3.substring(24 , 64);
  var step5 = '41' + step4;
  var bytes = HEX.decode(step5);
  var step6 = sha256.convert(bytes);
  var step7 = sha256.convert(step6.bytes);
  var step8 = step7.toString().substring(0 , 8);
  var step9 = step5 + step8;
  var publicKey = Base58Encode(HEX.decode(step9));

  print("step9 : " + step9);

  return publicKey;
}