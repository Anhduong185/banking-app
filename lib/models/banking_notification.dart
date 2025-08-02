class BankingNotification {
  final String id;
  final String senderName;
  final String senderAccount;
  final double amount;
  final String message;
  final DateTime timestamp;
  final String transactionType;

  BankingNotification({
    required this.id,
    required this.senderName,
    required this.senderAccount,
    required this.amount,
    required this.message,
    required this.timestamp,
    required this.transactionType,
  });

  factory BankingNotification.fromJson(Map<String, dynamic> json) {
    return BankingNotification(
      id: json['id'] ?? '',
      senderName: json['senderName'] ?? '',
      senderAccount: json['senderAccount'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      transactionType: json['transactionType'] ?? 'transfer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderName': senderName,
      'senderAccount': senderAccount,
      'amount': amount,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'transactionType': transactionType,
    };
  }

  String get formattedAmount {
    return '${amount.toStringAsFixed(0)} VNĐ';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
} 