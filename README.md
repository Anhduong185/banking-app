# Ứng Dụng Thông Báo Ngân Hàng

Ứng dụng Flutter để kết nối điện thoại với loa Bluetooth và phát thông báo khi nhận được tiền từ ngân hàng.

## Tính Năng Chính

### 🔵 Kết Nối Bluetooth
- Tự động tìm kiếm các thiết bị Bluetooth (loa, tai nghe)
- Kết nối với loa Bluetooth để phát âm thanh thông báo
- Hiển thị trạng thái kết nối real-time

### 🔊 Phát Âm Thanh Thông Báo
- Phát âm thanh beep khi nhận được thông báo ngân hàng
- Tùy chỉnh âm thanh và thời gian phát
- Test âm thanh trực tiếp từ ứng dụng

### 💰 Mô Phỏng Thông Báo Ngân Hàng
- Tạo thông báo ngẫu nhiên mỗi 30 giây
- Hiển thị thông tin chi tiết: người gửi, số tài khoản, số tiền, tin nhắn
- Lịch sử thông báo với giao diện đẹp

### 🎨 Giao Diện Hiện Đại
- Material Design 3 với theme xanh dương
- Cards với shadow và border radius
- Icons trực quan cho từng loại thiết bị
- Responsive design

## Cài Đặt Và Chạy

### Yêu Cầu Hệ Thống
- Flutter SDK 3.7.2+
- Android Studio / VS Code
- Thiết bị Android với Bluetooth

### Bước 1: Clone Project
```bash
git clone <repository-url>
cd my_flutter_app
```

### Bước 2: Cài Đặt Dependencies
```bash
flutter pub get
```

### Bước 3: Chạy Ứng Dụng
```bash
flutter run
```

## Cách Sử Dụng

### 1. Kết Nối Bluetooth
- Mở ứng dụng
- Chờ ứng dụng tìm kiếm thiết bị Bluetooth
- Chọn loa Bluetooth từ danh sách
- Nhấn "Kết nối" để kết nối

### 2. Bật Mô Phỏng
- Nhấn nút play (▶️) trên thanh toolbar
- Ứng dụng sẽ tạo thông báo ngẫu nhiên mỗi 30 giây
- Âm thanh sẽ được phát qua loa Bluetooth

### 3. Test Thủ Công
- Nhấn "Test thông báo" để tạo thông báo ngay lập tức
- Nhấn "Test âm thanh" để phát âm thanh test

## Cấu Trúc Project

```
lib/
├── main.dart                 # Entry point
├── models/
│   └── banking_notification.dart  # Model thông báo ngân hàng
├── services/
│   ├── bluetooth_service.dart     # Quản lý Bluetooth
│   ├── audio_service.dart         # Phát âm thanh
│   └── banking_service.dart       # Mô phỏng ngân hàng
├── screens/
│   └── home_screen.dart           # Màn hình chính
└── widgets/
    ├── notification_card.dart      # Card hiển thị thông báo
    └── bluetooth_device_card.dart # Card thiết bị Bluetooth
```

## Dependencies

- `flutter_bluetooth_serial`: Kết nối Bluetooth
- `audioplayers`: Phát âm thanh
- `flutter_local_notifications`: Thông báo local
- `http`: HTTP requests
- `shared_preferences`: Lưu cài đặt
- `permission_handler`: Quản lý quyền

## Quyền Cần Thiết

### Android
- `BLUETOOTH`: Kết nối Bluetooth
- `BLUETOOTH_ADMIN`: Quản lý Bluetooth
- `BLUETOOTH_CONNECT`: Kết nối Bluetooth (Android 12+)
- `BLUETOOTH_SCAN`: Tìm kiếm thiết bị (Android 12+)
- `ACCESS_FINE_LOCATION`: Vị trí (cần thiết cho Bluetooth)
- `RECORD_AUDIO`: Ghi âm
- `MODIFY_AUDIO_SETTINGS`: Điều chỉnh âm thanh

## Tính Năng Nâng Cao

### Tích Hợp Thực Tế
Để tích hợp với ngân hàng thực tế, bạn cần:

1. **API Banking**: Kết nối với API của ngân hàng
2. **Webhook**: Nhận thông báo real-time từ ngân hàng
3. **Bảo Mật**: Mã hóa dữ liệu và xác thực

### Cải Tiến Âm Thanh
- Thêm file âm thanh thực tế
- Text-to-speech để đọc số tiền
- Âm thanh tùy chỉnh cho từng loại giao dịch

### Giao Diện Nâng Cao
- Dark mode
- Đa ngôn ngữ
- Widget cho home screen
- Thông báo push

## Troubleshooting

### Bluetooth Không Hoạt Động
1. Kiểm tra Bluetooth đã bật chưa
2. Cấp quyền vị trí cho ứng dụng
3. Thử kết nối lại thiết bị

### Âm Thanh Không Phát
1. Kiểm tra loa Bluetooth đã kết nối
2. Tăng âm lượng loa
3. Test âm thanh từ ứng dụng

### Ứng Dụng Crash
1. Kiểm tra quyền đã được cấp
2. Restart ứng dụng
3. Kiểm tra log lỗi

## Đóng Góp

Mọi đóng góp đều được chào đón! Vui lòng:

1. Fork project
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## License

MIT License - xem file LICENSE để biết thêm chi tiết.

## Liên Hệ

Nếu có câu hỏi hoặc góp ý, vui lòng tạo issue trên GitHub.

---

**Lưu ý**: Đây là ứng dụng demo để học tập. Trong môi trường production, cần tuân thủ các quy định bảo mật và quyền riêng tư nghiêm ngặt.
