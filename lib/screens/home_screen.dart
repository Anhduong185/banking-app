import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';
import '../services/audio_service.dart';
import '../services/banking_service.dart';
import '../services/notification_service.dart';
import '../models/banking_notification.dart';
import '../widgets/notification_card.dart';
import '../widgets/bluetooth_device_card.dart';
import 'manual_input_screen.dart';
import '../services/platform_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothManager _bluetoothService = BluetoothManager();
  final AudioService _audioService = AudioService();
  final BankingService _bankingService = BankingService();
  final NotificationService _notificationService = NotificationService();
  final PlatformService _platformService = PlatformService();

  List<BluetoothDevice> _availableDevices = [];
  List<BankingNotification> _notifications = [];
  bool _isBluetoothConnected = false;
  bool _isSimulating = false;
  bool _isLoading = false;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupListeners();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _bluetoothService.initialize();
      await _audioService.initialize();
      await _bankingService.initialize();
      await _notificationService.initialize();
      await _loadAvailableDevices();
      
      // Kiểm tra theo platform
      if (_platformService.isAndroid) {
        await _bankingService.checkRecentSms(); // Kiểm tra SMS cũ (Android)
      } else if (_platformService.isIOS) {
        await _bankingService.checkBankingAPI(); // Kiểm tra API ngân hàng (iOS)
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khởi tạo: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupListeners() {
    // Lắng nghe trạng thái kết nối Bluetooth
    _bluetoothService.connectionStatus.listen((isConnected) {
      setState(() {
        _isBluetoothConnected = isConnected;
      });
    });

    // Lắng nghe danh sách thiết bị Bluetooth
    _bluetoothService.devicesStream.listen((devices) {
      setState(() {
        _availableDevices = devices;
      });
    });

    // Lắng nghe thông báo ngân hàng
    _bankingService.notificationStream.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
        if (_notifications.length > 10) {
          _notifications.removeLast();
        }
      });

      // Phát âm thanh thông báo qua loa Bluetooth
      _playNotificationSound(notification);
      
      // Hiển thị thông báo hệ thống
      _notificationService.showBankingNotification(notification);
    });
  }

  Future<void> _loadAvailableDevices() async {
    try {
      final devices = await _bluetoothService.getAvailableDevices();
      setState(() {
        _availableDevices = devices;
      });
    } catch (e) {
      _showErrorSnackBar('Không thể tìm thiết bị Bluetooth: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothService.connectToDevice(device);
      setState(() {
        _connectedDevice = device;
      });
      _showSuccessSnackBar('Đã kết nối với ${device.platformName}');
    } catch (e) {
      _showErrorSnackBar('Không thể kết nối: $e');
    }
  }

  Future<void> _disconnectBluetooth() async {
    try {
      await _bluetoothService.disconnect();
      setState(() {
        _connectedDevice = null;
      });
      _showSuccessSnackBar('Đã ngắt kết nối Bluetooth');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi ngắt kết nối: $e');
    }
  }

  // Phát âm thanh thông báo
  Future<void> _playNotificationSound(BankingNotification notification) async {
    try {
      // Luôn phát thông báo đầy đủ với tên người chuyển tiền
      await _audioService.playFullNotification(
        senderName: notification.senderName,
        amount: notification.amount,
      );
    } catch (e) {
      print('Lỗi khi phát âm thanh thông báo: $e');
    }
  }

  void _toggleSimulation() {
    if (_isSimulating) {
      _bankingService.stopSimulation();
      setState(() {
        _isSimulating = false;
      });
      _showSuccessSnackBar('Đã dừng mô phỏng');
    } else {
      _bankingService.startSimulation();
      setState(() {
        _isSimulating = true;
      });
      _showSuccessSnackBar('Đã bắt đầu mô phỏng (30s/lần)');
    }
  }

  void _testNotification() {
    _bankingService.createManualNotification(
      senderName: 'Nguyễn Văn Test',
      senderAccount: '1234567890',
      amount: 1000000,
      message: 'Tiền test thông báo',
    );
  }

  void _testSystemNotification() {
    _notificationService.showTestNotification();
  }

  void _openManualInput() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualInputScreen()),
    );
  }

  void _testBluetoothAudio() async {
    if (_isBluetoothConnected) {
      await _audioService.playFullNotification(
        senderName: 'Test Bluetooth',
        amount: 500000,
      );
      _showSuccessSnackBar('Đã test âm thanh qua Bluetooth');
    } else {
      _showErrorSnackBar('Vui lòng kết nối Bluetooth trước');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo Ngân Hàng'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSimulating ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleSimulation,
            tooltip: _isSimulating ? 'Dừng mô phỏng' : 'Bắt đầu mô phỏng',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trạng thái kết nối
                  _buildConnectionStatus(),
                  const SizedBox(height: 20),

                  // Danh sách thiết bị Bluetooth
                  _buildBluetoothDevices(),
                  const SizedBox(height: 20),

                  // Nút test
                  _buildTestButtons(),
                  const SizedBox(height: 20),

                  // Danh sách thông báo
                  _buildNotificationsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isBluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isBluetoothConnected ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trạng thái Bluetooth',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _isBluetoothConnected 
                        ? 'Đã kết nối với ${_connectedDevice?.name ?? "Thiết bị"}'
                        : 'Chưa kết nối',
                    style: TextStyle(
                      color: _isBluetoothConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (_isBluetoothConnected)
              ElevatedButton(
                onPressed: _disconnectBluetooth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ngắt kết nối'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothDevices() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth_searching),
                const SizedBox(width: 8),
                Text(
                  'Thiết bị Bluetooth (${_availableDevices.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAvailableDevices,
                  tooltip: 'Làm mới danh sách',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_availableDevices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Không tìm thấy thiết bị Bluetooth nào.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Trên emulator: Bluetooth có thể không hoạt động\n• Trên thiết bị thật: Vui lòng bật Bluetooth và ghép nối với loa',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ..._availableDevices.map((device) => BluetoothDeviceCard(
                device: device,
                onConnect: () => _connectToDevice(device),
                isConnected: _isBluetoothConnected && _connectedDevice?.remoteId == device.remoteId,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thử nghiệm',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testNotification,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test thông báo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testBluetoothAudio,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Test Bluetooth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _audioService.playMoneyNotificationSound(),
                    icon: const Icon(Icons.speaker),
                    label: const Text('Test âm thanh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                                 Expanded(
                   child: ElevatedButton.icon(
                     onPressed: _openManualInput,
                     icon: const Icon(Icons.edit_note),
                     label: const Text('Nhập thủ công'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.indigo,
                       foregroundColor: Colors.white,
                     ),
                   ),
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Text(
                  'Lịch sử thông báo (${_notifications.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_notifications.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _notifications.clear();
                      });
                    },
                    child: const Text('Xóa tất cả'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chưa có thông báo nào.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Trên emulator: Sử dụng nút "Test thông báo" để mô phỏng\n• Trên thiết bị thật: App sẽ tự động phát hiện SMS từ ngân hàng',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ..._notifications.map((notification) => NotificationCard(
                notification: notification,
              )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    _audioService.dispose();
    _bankingService.dispose();
    super.dispose();
  }
} 