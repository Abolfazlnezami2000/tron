import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/material.dart';
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;
import 'package:secp256k1/secp256k1.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:tron_test/test.dart';

import 'abi.dart';

final smartContractAddress = "TMnwEQ57Y5GmSFZFX3f4ptJJu97pq6o13M";

void main() async{
  // print("\n-----------------Run All Tests---------------\n");
  // await tests();

  File("/tron/QmbxRku7o3DtYZVEYcmZVS5sUTLPyU5vZW5uVHP6pQsyBQ").create();

  runApp(MyApp());
}

void tests() async{
  print('Start');

  print(" balance >> " + decodeUint256("000000000000000000000000000000000000000000115eec47f6cf7e34fffa88".characters).toString());
  print(" name    >> " + decodeString("0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000c6920626f6f6b20746f6b656e0000000000000000000000000000000000000000".characters).toString());

  print("\n-----------------Generate Key Pair---------------\n");
  // var prik = PrivateKey.generate();
  var prik = PrivateKey.fromHex("0b4886320c73a788e78889983b55192a8131bad41b13702763b22c1360250000");
  final String privateKey = prik.toHex().toString();
  print('Private Key is : ${prik.D}');
  var pubk = prik.publicKey;

  var publicKey = publicBigIntToBase58(pubk);
  print('Public Key is  : $publicKey');

  // Create 12 word
  print("\n-----------------Private Key To Mnemonic 12 words---------------\n");
  String words = bip39.entropyToMnemonic(prik.toHex());
  print(" >>> 12 words : " + words);

  print("\n-----------------Mnemonic 12 words to Private Key---------------\n");
  String wordsEntropy = bip39.mnemonicToEntropy(words);
  // print(" >>> entropy " + wordsEntropy);

  var private1 = PrivateKey.fromHex(wordsEntropy);
  print('Private Key is : ${private1.D}');
  var public1 = private1.publicKey;
  print('Public Key is  : ' + publicBigIntToBase58(public1));

  /*
    AES
  */
  print("             --------------            ");
  print("-------------------AES-----------------");

  // encrypt
  print("\n-----------------Encrypt---------------\n");
  print(" >>> hex :    " + wordsEntropy);
  print(" >>> base64 : " + encryptPrivateKeyByPassword(wordsEntropy,'testpass'));

  // decrypt
  print("\n-----------------Decrypt---------------\n");
  print(" >>> hex :    " + decryptPrivateKeyByPassword(encryptPrivateKeyByPassword(wordsEntropy,'testpass'),'testpass'));
  print(" >>> hex :    " + decryptPrivateKeyByPassword("Ae5oc08yLmDIYksiNsMP6jYOB4+YAEPxZxzQezmegZcfdfORDshZgoetGMjF+1O7L6yReZrdDsM9RgOGS7yK/11VeX+yXP80eFNPRLv4ves=",'testpass'));

  print("\n-----------------Get Contract Name---------------\n");
  print(" name    >> " + await getContractName("41c57c69232a779d1da8d3ef8e0041dcbdb3a5634d0633da9e"));

  print("\n-----------------Get IBT Balance---------------\n");
  print(" IBT balance >> " + await getIBTBalance("41c57c69232a779d1da8d3ef8e0041dcbdb3a5634d0633da9e"));

  print("\n-----------------Get TRX Balance---------------\n");
  print(" TRX balance >> " + await getTRXBalance("41c57c69232a779d1da8d3ef8e0041dcbdb3a5634d0633da9e"));

  print("\n-----------------Purchase An Item---------------\n");
  var transaction = await purchaseAnItem("41c57c69232a779d1da8d3ef8e0041dcbdb3a5634d0633da9e", 69, 69);
  // print(transaction);
  print("\n-----------------Sign The Transaction---------------\n");
  var signedTransaction = await signTransaction(privateKey, transaction);
  print("Transaction Signed Successfully");
  print("\n-----------------Broadcast The Transaction---------------\n");
  await broadCastTransaction(signedTransaction);

  print('End');
}

base58ToNormal(String addressBase58) async{
}

Future<String> getTRXBalance(String address) async{
  String addressBase58 = Base58Encode(HEX.decode(address));
  address = address.toString().substring(0, address.length-8);
  print(" Get Balance Of : " + addressBase58);
  var headers = {
    'Content-Type': 'application/json'
  };
  String parameter = "";
  for (var i = 0 ; i < 64 - address.length ; i ++ ){
    parameter = parameter + "0";
  }
  parameter = parameter + address;

  var request = http.Request('POST', Uri.parse('https://api.shasta.trongrid.io/wallet/getaccount'));
  request.body = json.encode({
    "address": addressBase58,
    "visible": true
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final Map parsed = json.decode(await response.stream.bytesToString());
    // if (parsed["result"].toString() == "{result: true}") {
      return parsed["balance"].toString();
    // }else{
    //   return " FAILED !";
    // }
  }else {
    print(response.reasonPhrase);
    return " FAILED !";
  }
}

Future<String> getIBTBalance(String address) async{
  String addressBase58 = Base58Encode(HEX.decode(address));
  address = address.toString().substring(0, address.length-8);
  print(" Get Balance Of : " + addressBase58);
  var headers = {
    'Content-Type': 'application/json'
  };
  String parameter = "";
  for (var i = 0 ; i < 64 - address.length ; i ++ ){
    parameter = parameter + "0";
  }
  parameter = parameter + address;

  var request = http.Request('POST', Uri.parse('https://api.shasta.trongrid.io/wallet/triggersmartcontract'));
  request.body = json.encode({
    "owner_address": addressBase58,
    "contract_address": smartContractAddress,
    "function_selector": "balanceOf(address)",
    "parameter": parameter.toString(),
    "call_value": 0,
    "visible": true
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final Map parsed = json.decode(await response.stream.bytesToString());
    if (parsed["result"].toString() == "{result: true}") {
      final responseString = parsed["constant_result"].toString().replaceAll("[", "").replaceAll("]", "");
      return decodeUint256(responseString.characters).toString();
    }else{
      return " FAILED !";
    }
  }else {
    print(response.reasonPhrase);
    return " FAILED !";
  }
}

Future<String> getContractName(String address) async{
  String addressBase58 = Base58Encode(HEX.decode(address));
  var headers = {
    'Content-Type': 'application/json'
  };
  var request = http.Request('POST', Uri.parse('https://api.shasta.trongrid.io/wallet/triggersmartcontract'));
  request.body = json.encode({
    "owner_address": addressBase58,
    "contract_address": smartContractAddress,
    "function_selector": "name()",
    "call_value": 0,
    "visible": true
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final Map parsed = json.decode(await response.stream.bytesToString());
    if (parsed["result"].toString() == "{result: true}") {
      final responseString = parsed["constant_result"].toString().replaceAll("[", "").replaceAll("]", "");
      return decodeString(responseString.toString().characters).toString();
    }else{
      return " FAILED !";
    }
  }
  else {
    print(response.reasonPhrase);
    return " FAILED !";
  }
}

broadCastTransaction(String signedTransaction) async{
  var headers = {
    'Content-Type': 'application/json'
  };
  var request = http.Request('POST', Uri.parse('https://api.shasta.trongrid.io/wallet/broadcasttransaction'));
  request.body = signedTransaction;

  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final Map parsed = json.decode(await response.stream.bytesToString());
    print(parsed.toString());
  }
  else {
    print(response.reasonPhrase);
  }
}

Future<String> signTransaction(String privateKey, String transaction) async{
  var headers = {
    'Content-Type': 'application/json'
  };

  var request = http.Request('POST', Uri.parse('https://api.shasta.trongrid.io/wallet/gettransactionsign'));
  request.body = json.encode({
    "transaction": json.decode(transaction),
    "privateKey": privateKey
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    final jsonResponse = await response.stream.bytesToString();
    return jsonResponse;
  }else {
    print(response.reasonPhrase);
  }
  return " FAILED ! ";
}

Future<String> purchaseAnItem(String address, int itemId, int count) async{
  String addressBase58 = Base58Encode(HEX.decode(address));
  address = address.toString().substring(0, address.length-8);
  print(" Caller Address : " + addressBase58);
  var headers = {
    'Content-Type': 'application/json'
  };
  String parameter = "";
  for (var i = 0 ; i < 64 - itemId.toString().length ; i ++ ){
    parameter = parameter + "0";
  }
  parameter = parameter + itemId.toString();

  for (var i = 0 ; i < 64 - count.toString().length ; i ++ ){
    parameter = parameter + "0";
  }
  parameter = parameter + encodeUint256(count).toString();

  print(parameter);
  var request = http.Request('POST', Uri.parse('https://api.shasta.trongrid.io/wallet/triggersmartcontract'));
  request.body = json.encode({
    "owner_address": addressBase58,
    "contract_address": smartContractAddress,
    "function_selector": "purchaseAnItem(uint256, uint256)",
    "parameter": parameter.toString(),
    "call_value": 0,
    "visible": true
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    // final Map parsed = json.decode(await response.stream.bytesToString());
    var jsonResponse = await response.stream.bytesToString();
    jsonResponse = jsonResponse.toString();
    var indexOfTransaction = jsonResponse.indexOf("transaction");
    if (indexOfTransaction != -1) {
      return jsonResponse.substring(indexOfTransaction+"transaction\":".length, jsonResponse.length-2);
    }else{
      print(" FAILED !");
    }
  }else {
    print(response.reasonPhrase);
  }
  return " FAILED ! ";
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  var IBTBalance = '';
  var TRXBalance = '';


  void setIBTBalance() async{
    IBTBalance = await getIBTBalance("41c57c69232a779d1da8d3ef8e0041dcbdb3a5634d0633da9e");
  }
  void setTRXBalance() async{
    TRXBalance = await getTRXBalance("41c57c69232a779d1da8d3ef8e0041dcbdb3a5634d0633da9e");
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    setIBTBalance();
    setTRXBalance();
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.white24,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Tron"),
        centerTitle: true,
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.network("https://ipfs.infura.io:5001/api/v0/cat?arg=QmbxRku7o3DtYZVEYcmZVS5sUTLPyU5vZW5uVHP6pQsyBQ"),
            Text(
              'IBT balance : ',
            ),
            Text(
              '$IBTBalance',
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(
              'TRX balance : ',
            ),
            Text(
              '$TRXBalance',
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
