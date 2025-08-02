import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _audioCharacteristic;
  bool _isConnected = false;
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController<List<BluetoothDevice>>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  bool get isConnected => _isConnected;

  // Khởi tạo Bluetooth thực tế
  Future<void> initialize() async {
    try {
      // Yêu cầu quyền Bluetooth
      await _requestPermissions();
      
      // Kiểm tra Bluetooth có được bật không
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Thiết bị không hỗ trợ Bluetooth');
      }
      
      // Lắng nghe trạng thái Bluetooth
      FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on) {
          print('Bluetooth đã được bật');
        } else {
          print('Bluetooth đã tắt: $state');
        }
      });
      
      print('Bluetooth đã được khởi tạo thành công');
    } catch (e) {
      print('Lỗi khởi tạo Bluetooth (có thể do emulator): $e');
      // Không throw exception để app vẫn chạy được trên emulator
      // Chỉ hiển thị thông báo lỗi
    }
  }

  // Yêu cầu quyền truy cập
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    for (var status in statuses.values) {
      if (!status.isGranted) {
        throw Exception('Cần quyền truy cập Bluetooth và vị trí để hoạt động');
      }
    }
  }

  // Tìm các thiết bị Bluetooth thực tế
  Future<List<BluetoothDevice>> getAvailableDevices() async {
    try {
      List<BluetoothDevice> devices = [];
      
      // Bắt đầu quét thiết bị
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      
      // Lắng nghe thiết bị được tìm thấy
      FlutterBluePlus.scanResults.listen((results) {
        devices = results.map((result) => result.device).toList();
        
        // Lọc chỉ lấy các thiết bị loa
        List<BluetoothDevice> speakerDevices = devices.where((device) {
          String name = device.platformName.toLowerCase();
          return name.contains('jbl') || 
                 name.contains('sony') || 
                 name.contains('bose') || 
                 name.contains('samsung') || 
                 name.contains('apple') || 
                 name.contains('marshall') ||
                 name.contains('speaker') ||
                 name.contains('sound') ||
                 name.contains('audio') ||
                 name.contains('bluetooth');
        }).toList();

        _devicesController.add(speakerDevices);
      });
      
      return devices;
    } catch (e) {
      throw Exception('Không thể tìm thiết bị Bluetooth: $e');
    }
  }

  // Kết nối với thiết bị thực tế
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Ngắt kết nối hiện tại nếu có
      await disconnect();
      
      print('Đang kết nối với ${device.platformName}...');
      
      // Kết nối với thiết bị
      await device.connect(timeout: const Duration(seconds: 10));
      
      _connectedDevice = device;
      _isConnected = true;
      _connectionStatusController.add(true);
      
      print('Đã kết nối thành công với ${device.platformName}');
      
      // Tìm service và characteristic cho audio
      await _discoverServices(device);
      
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      throw Exception('Không thể kết nối với ${device.platformName}: $e');
    }
  }

  // Tìm services và characteristics
  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Tìm characteristic có thể ghi dữ liệu
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _audioCharacteristic = characteristic;
            print('Đã tìm thấy audio characteristic: ${characteristic.uuid}');
            break;
          }
        }
      }
    } catch (e) {
      print('Lỗi khi tìm services: $e');
    }
  }

  // Ngắt kết nối thực tế
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
      }
      _audioCharacteristic = null;
      _isConnected = false;
      _connectionStatusController.add(false);
      print('Đã ngắt kết nối Bluetooth');
    } catch (e) {
      print('Lỗi khi ngắt kết nối: $e');
    }
  }

  // Gửi dữ liệu qua Bluetooth thực tế
  Future<void> sendData(String data) async {
    if (_isConnected && _audioCharacteristic != null) {
      try {
        List<int> bytes = data.codeUnits;
        await _audioCharacteristic!.write(bytes);
        print('Đã gửi dữ liệu qua Bluetooth: $data');
      } catch (e) {
        print('Lỗi khi gửi dữ liệu: $e');
      }
    }
  }

  // Kiểm tra trạng thái kết nối
  bool getConnectionStatus() {
    return _isConnected && _connectedDevice != null;
  }

  void dispose() {
    disconnect();
    _connectionStatusController.close();
    _devicesController.close();
  }
} 