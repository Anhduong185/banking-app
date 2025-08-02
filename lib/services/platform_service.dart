import 'dart:io';
import 'package:platform/platform.dart';

class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  final Platform _platform = const LocalPlatform();

  // Kiểm tra platform
  bool get isAndroid => _platform.isAndroid;
  bool get isIOS => _platform.isIOS;
  bool get isWindows => _platform.isWindows;
  bool get isMacOS => _platform.isMacOS;
  bool get isLinux => _platform.isLinux;

  // Lấy tên platform
  String get platformName {
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }

  // Kiểm tra có thể đọc SMS không (chỉ Android)
  bool get canReadSms => isAndroid;

  // Kiểm tra có thể dùng push notifications không (iOS + Android)
  bool get canUsePushNotifications => isIOS || isAndroid;

  // Kiểm tra có thể dùng Bluetooth không
  bool get canUseBluetooth => isAndroid || isIOS;

  // Lấy thông tin platform
  Map<String, dynamic> get platformInfo {
    return {
      'platform': platformName,
      'version': _platform.operatingSystemVersion,
      'isAndroid': isAndroid,
      'isIOS': isIOS,
      'canReadSms': canReadSms,
      'canUsePushNotifications': canUsePushNotifications,
      'canUseBluetooth': canUseBluetooth,
    };
  }

  // In thông tin platform
  void printPlatformInfo() {
    print('📱 Platform: $platformName');
    print('🔧 OS Version: ${_platform.operatingSystemVersion}');
    print('📨 Can read SMS: $canReadSms');
    print('🔔 Can use push notifications: $canUsePushNotifications');
    print('📶 Can use Bluetooth: $canUseBluetooth');
  }
} 