import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_lecture/repository/ble_repository.dart';
import 'package:flutter_bluetooth_lecture/widget/ble_list_tile.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Demo',
      home: ChangeNotifierProvider.value(
        value: BleRepository(),
        child: MyHomePage(title: 'Flutter BLE Demo Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _checkPermissions().then((value) {
      context.read<BleRepository>().init();
    });
  }

  //퍼미션 체크 및 없으면 퍼미션 동의 화면 출력
  Future _checkPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.contacts.request().isGranted) {}
      Map<Permission, PermissionStatus> statuses =
          await [Permission.location].request();
      print(statuses[Permission.location]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleRepository = context.watch<BleRepository>();
    return Scaffold(
      appBar: AppBar(
        title: Text('${bleRepository.connected}'),
      ),
      body: _buildBody(bleRepository),
      floatingActionButton: FloatingActionButton(
        onPressed: bleRepository.scan, //버튼이 눌리면 스캔 ON/OFF 동작
        child: Icon(bleRepository.isScanning
            ? Icons.stop
            : Icons.bluetooth_searching), //_isScanning 변수에 따라 아이콘 표시 변경
      ),
    );
  }

  Widget _buildBody(BleRepository repository) {
    return ListView.builder(
      itemCount: repository.deviceList.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            repository.connect(repository.deviceList[index]);
          },
          child: BleListTile(repository.deviceList[index]),
        );
      },
    );
  }
}
