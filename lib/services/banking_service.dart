import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/banking_notification.dart';
import 'platform_service.dart';

class BankingService {
  static final BankingService _instance = BankingService._internal();
  factory BankingService() => _instance;
  BankingService._internal();

  final StreamController<BankingNotification> _notificationController = 
      StreamController<BankingNotification>.broadcast();
  
  Stream<BankingNotification> get notificationStream => _notificationController.stream;
  
  Timer? _simulationTimer;
  bool _isSimulating = false;
  FirebaseMessaging? _firebaseMessaging;
  SmsQuery? _smsQuery;
  StreamSubscription<SmsMessage>? _smsSubscription;
  
  final PlatformService _platformService = PlatformService();
  
  // Cấu hình ngân hàng
  List<String> _bankKeywords = [
    'vcb', 'tcb', 'mb', 'acb', 'vib', 'tpb', 'bidv', 'vpb', 'stb', 'hdbank',
    'agribank', 'sacombank', 'techcombank', 'vpbank', 'shb', 'ocb', 'msb',
    'vietinbank', 'seabank', 'pvb', 'gpbank', 'abbank', 'lienvietpostbank',
    'kienlongbank', 'namabank', 'pvcombank', 'vietbank', 'baovietbank'
  ];

  // Danh sách tên người gửi mẫu
  final List<String> _sampleNames = [
    'Nguyễn Văn An',
    'Trần Thị Bình',
    'Lê Văn Cường',
    'Phạm Thị Dung',
    'Hoàng Văn Em',
    'Vũ Thị Phương',
    'Đặng Văn Giang',
    'Bùi Thị Hoa',
    'Ngô Văn Inh',
    'Lý Thị Kim',
  ];

  // Danh sách tin nhắn mẫu
  final List<String> _sampleMessages = [
    'Chuyển tiền thanh toán',
    'Trả nợ vay',
    'Tiền lương tháng',
    'Tiền thưởng',
    'Tiền hoàn trả',
    'Tiền bán hàng',
    'Tiền đầu tư',
    'Tiền quà tặng',
    'Tiền hỗ trợ',
    'Tiền bồi thường',
  ];

  // Khởi tạo service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      
      // In thông tin platform
      _platformService.printPlatformInfo();
      
      // Khởi tạo theo platform
      if (_platformService.isAndroid) {
        await _initializeAndroid();
      } else if (_platformService.isIOS) {
        await _initializeIOS();
      }
      
      print('Banking service đã được khởi tạo (${_platformService.platformName} mode)');
    } catch (e) {
      print('Lỗi khởi tạo banking service: $e');
    }
  }

  // Tải cài đặt
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _bankKeywords = prefs.getStringList('bank_keywords') ?? _bankKeywords;
  }

  // Khởi tạo cho Android
  Future<void> _initializeAndroid() async {
    try {
      await _startSmsListener();
      print('Đã khởi tạo SMS listener cho Android');
    } catch (e) {
      print('Không thể khởi tạo SMS listener: $e');
    }
  }

  // Khởi tạo cho iOS
  Future<void> _initializeIOS() async {
    try {
      await _initializeFirebase();
      print('Đã khởi tạo Firebase cho iOS');
    } catch (e) {
      print('Không thể khởi tạo Firebase: $e');
    }
  }

  // Bắt đầu lắng nghe SMS (Android)
  Future<void> _startSmsListener() async {
    if (!_platformService.canReadSms) {
      print('Platform không hỗ trợ đọc SMS');
      return;
    }

    try {
      _smsQuery = SmsQuery();
      
      // Lắng nghe SMS mới
      _smsSubscription = _smsQuery!.onSmsReceived!.listen((SmsMessage message) {
        _processSmsMessage(message);
      });
      
      print('Đã bắt đầu lắng nghe SMS thực tế');
    } catch (e) {
      print('Không thể lắng nghe SMS: $e');
    }
  }

  // Khởi tạo Firebase cho push notifications (iOS)
  Future<void> _initializeFirebase() async {
    if (!_platformService.canUsePushNotifications) {
      print('Platform không hỗ trợ push notifications');
      return;
    }

    try {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Yêu cầu quyền thông báo
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('Đã được cấp quyền thông báo');
        
        // Lắng nghe push notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _processPushNotification(message);
        });
        
        // Lắng nghe khi app mở từ thông báo
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _processPushNotification(message);
        });
        
        // Lấy FCM token để gửi thông báo
        String? token = await _firebaseMessaging!.getToken();
        print('FCM Token: $token');
      }
    } catch (e) {
      print('Không thể khởi tạo Firebase: $e');
    }
  }

  // Xử lý SMS nhận được (Android)
  void _processSmsMessage(SmsMessage message) {
    try {
      String body = message.body?.toLowerCase() ?? '';
      
      // Kiểm tra xem có phải SMS từ ngân hàng không
      bool isBankSms = _bankKeywords.any((keyword) => body.contains(keyword));
      
      if (isBankSms) {
        // Phân tích SMS để lấy thông tin giao dịch
        BankingNotification? notification = _parseBankingSms(message);
        
        if (notification != null) {
          _notificationController.add(notification);
          print('Đã phát hiện thông báo ngân hàng thực tế: ${notification.senderName} - ${notification.amount}');
        }
      }
    } catch (e) {
      print('Lỗi xử lý SMS: $e');
    }
  }

  // Xử lý push notification (iOS)
  void _processPushNotification(RemoteMessage message) {
    try {
      Map<String, dynamic> data = message.data;
      
      // Kiểm tra xem có phải thông báo ngân hàng không
      if (data['type'] == 'banking' || data['source'] == 'bank') {
        BankingNotification? notification = _parsePushNotification(data);
        
        if (notification != null) {
          _notificationController.add(notification);
          print('Đã phát hiện thông báo ngân hàng từ push: ${notification.senderName} - ${notification.amount}');
        }
      }
    } catch (e) {
      print('Lỗi xử lý push notification: $e');
    }
  }

  // Phân tích SMS ngân hàng (Android)
  BankingNotification? _parseBankingSms(SmsMessage message) {
    try {
      String body = message.body ?? '';
      
      // Tìm số tiền trong SMS (pattern: số + VND hoặc số + đ)
      RegExp amountRegex = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*(?:VND|đ|dong)', caseSensitive: false);
      Match? amountMatch = amountRegex.firstMatch(body);
      
      if (amountMatch != null) {
        String amountStr = amountMatch.group(1)!.replaceAll(',', '');
        double amount = double.tryParse(amountStr) ?? 0;
        
        // Tìm tên người gửi (thường có format: "TK: Tên người gửi")
        RegExp senderRegex = RegExp(r'(?:TK|Tai khoan|Từ|From):\s*([A-Za-zÀ-ỹ\s]+)', caseSensitive: false);
        Match? senderMatch = senderRegex.firstMatch(body);
        String senderName = senderMatch?.group(1)?.trim() ?? 'Không xác định';
        
        // Tìm số tài khoản
        RegExp accountRegex = RegExp(r'\d{10,16}');
        Match? accountMatch = accountRegex.firstMatch(body);
        String accountNumber = accountMatch?.group(0) ?? 'Không xác định';
        
        return BankingNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: senderName,
          senderAccount: accountNumber,
          amount: amount,
          message: 'Chuyển tiền từ ngân hàng',
          timestamp: DateTime.now(),
          transactionType: 'transfer',
        );
      }
    } catch (e) {
      print('Lỗi phân tích SMS: $e');
    }
    
    return null;
  }

  // Phân tích push notification (iOS)
  BankingNotification? _parsePushNotification(Map<String, dynamic> data) {
    try {
      String senderName = data['sender_name'] ?? 'Không xác định';
      String senderAccount = data['sender_account'] ?? 'Không xác định';
      double amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
      String message = data['message'] ?? 'Chuyển tiền từ ngân hàng';
      
      return BankingNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderName: senderName,
        senderAccount: senderAccount,
        amount: amount,
        message: message,
        timestamp: DateTime.now(),
        transactionType: 'transfer',
      );
    } catch (e) {
      print('Lỗi phân tích push notification: $e');
      return null;
    }
  }

  // Kiểm tra SMS cũ (Android)
  Future<void> checkRecentSms() async {
    if (!_platformService.canReadSms) return;
    
    try {
      if (_smsQuery != null) {
        List<SmsMessage> messages = await _smsQuery!.querySms(
          kinds: [SmsQueryKind.inbox],
          count: 50, // Kiểm tra 50 SMS gần nhất
        );
        
        for (SmsMessage message in messages) {
          _processSmsMessage(message);
        }
      }
    } catch (e) {
      print('Lỗi kiểm tra SMS cũ: $e');
    }
  }

  // Kiểm tra API ngân hàng (iOS)
  Future<void> checkBankingAPI() async {
    try {
      // Gọi API ngân hàng để lấy thông tin giao dịch mới
      // Đây là ví dụ, cần thay thế bằng API thực tế của ngân hàng
      final response = await http.get(
        Uri.parse('https://api.bank.com/transactions'),
        headers: {'Authorization': 'Bearer YOUR_API_KEY'},
      );
      
      if (response.statusCode == 200) {
        // Xử lý dữ liệu từ API
        print('Đã kiểm tra API ngân hàng');
      }
    } catch (e) {
      print('Lỗi kiểm tra API ngân hàng: $e');
    }
  }

  // Bắt đầu mô phỏng nhận thông báo (cho testing)
  void startSimulation() {
    if (_isSimulating) return;
    
    _isSimulating = true;
    _simulationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _generateRandomNotification();
    });
    print('Đã bắt đầu mô phỏng thông báo ngân hàng');
  }

  // Dừng mô phỏng
  void stopSimulation() {
    _isSimulating = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    print('Đã dừng mô phỏng thông báo ngân hàng');
  }

  // Tạo thông báo ngẫu nhiên (cho testing)
  void _generateRandomNotification() {
    final random = Random();
    
    final notification = BankingNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: _sampleNames[random.nextInt(_sampleNames.length)],
      senderAccount: _generateRandomAccountNumber(),
      amount: _generateRandomAmount(),
      message: _sampleMessages[random.nextInt(_sampleMessages.length)],
      timestamp: DateTime.now(),
      transactionType: 'transfer',
    );

    _notificationController.add(notification);
    print('Đã tạo thông báo mô phỏng: ${notification.senderName} - ${notification.amount}');
  }

  // Tạo số tài khoản ngẫu nhiên
  String _generateRandomAccountNumber() {
    final random = Random();
    String accountNumber = '';
    for (int i = 0; i < 10; i++) {
      accountNumber += random.nextInt(10).toString();
    }
    return accountNumber;
  }

  // Tạo số tiền ngẫu nhiên
  double _generateRandomAmount() {
    final random = Random();
    // Tạo số tiền từ 50,000 đến 50,000,000 VNĐ
    return (random.nextDouble() * 49500000 + 50000).roundToDouble();
  }

  // Tạo thông báo thủ công
  void createManualNotification({
    required String senderName,
    required String senderAccount,
    required double amount,
    required String message,
  }) {
    final notification = BankingNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: senderName,
      senderAccount: senderAccount,
      amount: amount,
      message: message,
      timestamp: DateTime.now(),
      transactionType: 'transfer',
    );

    _notificationController.add(notification);
    print('Đã tạo thông báo thủ công: $senderName - $amount');
  }

  // Kiểm tra trạng thái mô phỏng
  bool get isSimulating => _isSimulating;

  // Giải phóng tài nguyên
  void dispose() {
    stopSimulation();
    _smsSubscription?.cancel();
    _notificationController.close();
  }
} 