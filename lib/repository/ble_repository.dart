import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_bluetooth_lecture/model/ble_device.dart';

class BleRepository with ChangeNotifier {
  BleManager _bleManager = BleManager();
  bool isScanning = false;
  List<BleDevice> deviceList = [];

  void init() async {
    await _bleManager
        .createClient(
            restoreStateIdentifier: "example-restore-state-identifier",
            restoreStateAction: (peripherals) {
              peripherals?.forEach((peripheral) {
                print("Restored peripheral: ${peripheral.name}");
              });
            })
        .catchError((e) => print("Couldn't create BLE client  $e"));
  }

  //스캔 ON/OFF
  void scan() async {
    if (!isScanning) {
      deviceList.clear();
      _bleManager.startPeripheralScan().listen((scanResult) {
        // 주변기기 항목에 이름이 있으면 그걸 사용하고
        // 없다면 어드버타이지먼트 데이터의 이름을 사용하고 그것마저 없다면 Unknown으로 표시
        var name = scanResult.peripheral.name ??
            scanResult.advertisementData.localName ??
            "Unknown";

        // 이미 검색된 장치인지 확인 mac 주소로 확인
        var findDevice = deviceList.any((element) {
          if (element.peripheral.identifier ==
              scanResult.peripheral.identifier) {
            //이미 존재하면 기존 값을 갱신.
            element.peripheral = scanResult.peripheral;
            element.advertisementData = scanResult.advertisementData;
            element.rssi = scanResult.rssi;
            return true;
          }
          return false;
        });
        // 처음 발견된 장치라면 devicelist에 추가
        if (!findDevice) {
          deviceList.add(BleDevice(name, scanResult.rssi, scanResult.peripheral,
              scanResult.advertisementData));
        }
        // 갱신 적용.
        notifyListeners();
      });
      // 스캔중으로 변수 변경
      isScanning = true;
      notifyListeners();
    } else {
      // 스캔중이었다면 스캔 정지
      _bleManager.stopPeripheralScan();
      isScanning = false;
      notifyListeners();
    }
  }
}
