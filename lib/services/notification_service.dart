import '../models/banking_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    print('NotificationService initialized (Mock)');
  }

  Future<void> showBankingNotification(BankingNotification notification) async {
    // Mock notification - trên thiết bị thật sẽ hiển thị notification thật
    print('=== THÔNG BÁO NGÂN HÀNG ===');
    print('Nhận tiền: ${notification.formattedAmount}');
    print('Từ: ${notification.senderName}');
    print('Nội dung: ${notification.message}');
    print('Thời gian: ${notification.formattedTime}');
    print('==========================');
  }

  Future<void> showTestNotification() async {
    // Mock notification - trên thiết bị thật sẽ hiển thị notification thật
    print('=== TEST THÔNG BÁO ===');
    print('Đây là thông báo test');
    print('Trên thiết bị thật sẽ hiển thị notification thật');
    print('======================');
  }
} 