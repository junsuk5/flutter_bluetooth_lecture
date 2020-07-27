import 'package:flutter/material.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_bluetooth_lecture/model/ble_device.dart';

class BleRepository with ChangeNotifier {
  BleManager _bleManager = BleManager();
  bool isScanning = false;
  List<BleDevice> deviceList = [];

  bool connected = false;
  var _curPeripheral;
  String _state = '';

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

  //연결 함수
  connect(BleDevice device) async {
    if(connected) {  //이미 연결상태면 연결 해제후 종료
      await _curPeripheral?.disconnectOrCancelConnection();
      return;
    }

    //선택한 장치의 peripheral 값을 가져온다.
    Peripheral peripheral = device.peripheral;

    //해당 장치와의 연결상태를 관촬하는 리스너 실행
    peripheral.observeConnectionState(emitCurrentValue: true)
        .listen((connectionState) {
      // 연결상태가 변경되면 해당 루틴을 탐.
      switch(connectionState) {
        case PeripheralConnectionState.connected: {  //연결됨
          _curPeripheral = peripheral;
          notifyListeners();
          setBLEState('connected');
        }
        break;
        case PeripheralConnectionState.connecting: { setBLEState('connecting'); }//연결중
        break;
        case PeripheralConnectionState.disconnected: { //해제됨
          connected=false;
          notifyListeners();
          print("${peripheral.name} has DISCONNECTED");
          setBLEState('disconnected');
        }
        break;
        case PeripheralConnectionState.disconnecting: { setBLEState('disconnecting');}//해제중
        break;
        default:{//알수없음...
          print("unkown connection state is: \n $connectionState");
        }
        break;
      }
    });

    _runWithErrorHandling(() async {
      //해당 장치와 이미 연결되어 있는지 확인
      bool isConnected = await peripheral.isConnected();
      if(isConnected) {
        print('device is already connected');
        //이미 연결되어 있기때문에 무시하고 종료..
        return;
      }

      //연결 시작!
      await peripheral.connect().then((_) {
      //연결이 되면 장치의 모든 서비스와 캐릭터리스틱을 검색한다.
      peripheral.discoverAllServicesAndCharacteristics()
          .then((_) => peripheral.services())
          .then((services) async {
        print("PRINTING SERVICES for ${peripheral.name}");
        //각각의 서비스의 하위 캐릭터리스틱 정보를 디버깅창에 표시한다.
        for(var service in services) {
          print("Found service ${service.uuid}");
          List<Characteristic> characteristics = await service.characteristics();
          for( var characteristic in characteristics ) {
            print("${characteristic.uuid}");
          }
        }
        //모든 과정이 마무리되면 연결되었다고 표시
        connected = true;
        notifyListeners();
        print("${peripheral.name} has CONNECTED");
      });
    });
  });
  }

  //BLE 연결시 예외 처리를 위한 래핑 함수
  _runWithErrorHandling(runFunction) async {
    try {
      await runFunction();
    } on BleError catch (e) {
      print("BleError caught: ${e.errorCode.value} ${e.reason}");
    } catch (e) {
      if (e is Error) {
        debugPrintStack(stackTrace: e.stackTrace);
      }
      print("${e.runtimeType}: $e");
    }
  }

  setBLEState(state) {
    _state = state;
    notifyListeners();
  }
}
