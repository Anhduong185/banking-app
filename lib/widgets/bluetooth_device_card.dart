import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothDeviceCard extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onConnect;
  final bool isConnected;

  const BluetoothDeviceCard({
    super.key,
    required this.device,
    required this.onConnect,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isConnected ? Colors.green : Colors.blue,
          child: Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: Colors.white,
          ),
        ),
        title: Text(
          device.platformName.isNotEmpty ? device.platformName : 'Thiết bị không tên',
          style: TextStyle(
            fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
            color: isConnected ? Colors.green : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Địa chỉ: ${device.remoteId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              isConnected ? 'Đã kết nối' : 'Chưa kết nối',
              style: TextStyle(
                fontSize: 12,
                color: isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: isConnected
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              )
            : ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Kết nối'),
              ),
        onTap: isConnected ? null : onConnect,
      ),
    );
  }
} 