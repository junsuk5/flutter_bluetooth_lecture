import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_lecture/model/ble_device.dart';

class BleListTile extends StatelessWidget {
  final BleDevice device;

  BleListTile(this.device);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      //디바이스 이름과 맥주소 그리고 신호 세기를 표시한다.
      title: Text(device.deviceName),
      subtitle: Text(device.peripheral.identifier),
      trailing: Text("${device.rssi}"),
    );
  }
}
