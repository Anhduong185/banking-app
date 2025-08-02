import 'package:flutter/material.dart';
import '../services/banking_service.dart';
import '../services/audio_service.dart';
import '../models/banking_notification.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderNameController = TextEditingController();
  final _senderAccountController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  
  final BankingService _bankingService = BankingService();
  final AudioService _audioService = AudioService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderAccountController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      double amount = double.parse(_amountController.text.replaceAll(',', ''));
      
      // Tạo thông báo thủ công
      _bankingService.createManualNotification(
        senderName: _senderNameController.text.trim(),
        senderAccount: _senderAccountController.text.trim(),
        amount: amount,
        message: _messageController.text.trim(),
      );

      // Phát âm thanh thông báo
      await _audioService.playFullNotification(
        senderName: _senderNameController.text.trim(),
        amount: amount,
      );

      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tạo thông báo thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Quay lại màn hình chính
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _senderNameController.clear();
    _senderAccountController.clear();
    _amountController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Thông Báo Thủ Công'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Thông Tin Giao Dịch',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhập thông tin giao dịch để test thông báo âm thanh',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tên người gửi
              TextFormField(
                controller: _senderNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên người gửi *',
                  hintText: 'Ví dụ: Nguyễn Văn An',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên người gửi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Số tài khoản
              TextFormField(
                controller: _senderAccountController,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản',
                  hintText: 'Ví dụ: 1234567890',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Số tiền
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ) *',
                  hintText: 'Ví dụ: 1,000,000',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  try {
                    double amount = double.parse(value.replaceAll(',', ''));
                    if (amount <= 0) {
                      return 'Số tiền phải lớn hơn 0';
                    }
                  } catch (e) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Format số tiền với dấu phẩy
                  if (value.isNotEmpty) {
                    String numericValue = value.replaceAll(',', '');
                    if (numericValue.isNotEmpty) {
                      double? amount = double.tryParse(numericValue);
                      if (amount != null) {
                        String formatted = amount.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                        );
                        if (formatted != value) {
                          _amountController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 16),

              // Nội dung tin nhắn
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung tin nhắn',
                  hintText: 'Ví dụ: Chuyển tiền thanh toán',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _clearForm,
                      icon: const Icon(Icons.clear),
                      label: const Text('Xóa form'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitForm,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                      label: Text(_isLoading ? 'Đang xử lý...' : 'Tạo thông báo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick templates
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mẫu nhanh',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickTemplate('Nguyễn Văn An', '1,000,000', 'Chuyển tiền lương'),
                          _buildQuickTemplate('Trần Thị Bình', '500,000', 'Tiền thưởng'),
                          _buildQuickTemplate('Lê Văn Cường', '2,000,000', 'Tiền hoàn trả'),
                          _buildQuickTemplate('Phạm Thị Dung', '750,000', 'Tiền bán hàng'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTemplate(String name, String amount, String message) {
    return InkWell(
      onTap: () {
        _senderNameController.text = name;
        _amountController.text = amount;
        _messageController.text = message;
        _senderAccountController.text = '1234567890';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Text(
          '$name - $amount',
          style: TextStyle(
            color: Colors.blue[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
} 