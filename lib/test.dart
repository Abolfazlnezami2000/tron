import 'dart:convert';

import 'package:encrypt/encrypt.dart';

encryptPrivateKeyByPassword(String privateKey , String password) {

  String b64key0 = password;
  for(int i = 0 ; i < 32 - password.length ; i++)
  {
    b64key0 = b64key0 + '0';
  }
  print(b64key0.length);
  final key = Key.fromUtf8(b64key0);
  print(base64Url.decode(key.toString()).length);
  final b64key = Key.fromUtf8(base64Url.encode(key.bytes));
  final fernet = Fernet(b64key);
  final encrypter = Encrypter(fernet);

  final encrypted = encrypter.encrypt(privateKey);

  return encrypted;
}
