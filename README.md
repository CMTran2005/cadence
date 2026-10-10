# Cadence Finance 💳⚡

**Cadence** là ứng dụng quản lý tài chính cá nhân thế hệ mới: Hỗ trợ **quét hóa đơn OCR tự động**, quản lý **gói dịch vụ định kỳ (Subscriptions)** và tính toán **chỉ số chi tiêu an toàn hàng ngày (Safe-to-Spend)**.

Thiết kế giao diện được chuẩn hóa theo tiêu chuẩn **Taste-Skill (Anti-AI Slop)**: Sử dụng bảng màu Zinc/Slate tối giản, font số Tabular Figures, viền mảnh 1px có chủ đích và phân cấp thị giác tinh tế.

---

## 🚀 Tính năng nổi bật

### 1. Nhập liệu kép linh hoạt (Dual Entry)
- **Quét hóa đơn bằng Camera (On-Device OCR):** Tích hợp Google ML Kit Text Recognition chạy 100% offline trên thiết bị (zero-cloud cost, bảo mật dữ liệu). Tự động nhận diện tổng số tiền, tên cửa hàng/dịch vụ, ngày giờ và gợi ý danh mục chi tiêu.
- **Hỗ trợ thử hóa đơn mẫu:** Nút *"Thử bill mẫu"* giúp test ngay luồng OCR mà không cần bill giấy thực tế.
- **Nhập thủ công nhanh (Quick Manual Entry):** Modal chuyển đổi Thu/Chi mượt mà, bàn phím số nhạy, lưu giao dịch trong 3 giây.

### 2. Quản lý Gói dịch vụ định kỳ (Subscriptions Hub)
- Theo dõi các khoản chi cố định: Netflix, Spotify, iCloud, ChatGPT, Tiền trọ, Gói cước 4G, Gym...
- Tự động chuẩn hóa chi phí theo tháng (Normalized monthly burn rate).
- Đếm ngược hạn trừ tiền tiếp theo (*"Còn 3 ngày"*, *"Đến hạn hôm nay"*).
- Tính năng **"Đã thanh toán kỳ này"**: 1 chạm tự động chuyển kỳ thanh toán tới và tự động sinh bản ghi chi tiêu vào sổ giao dịch.

### 3. Chỉ số tài chính "Safe-to-Spend" (An toàn để tiêu hôm nay)
- Công thức thông minh:
  $$\text{Safe-to-Spend} = \frac{\text{Tổng thu} - \text{Gói định kỳ} - \text{Quỹ tiết kiệm mục tiêu} - \text{Đã tiêu}}{\text{Số ngày còn lại trong tháng}}$$
- Giúp người dùng biết chính xác mỗi ngày được tiêu tối đa bao nhiêu để cuối tháng không bị âm tiền.

### 4. Phân tích dòng tiền & Báo cáo trực quan
- Phân bổ chi tiêu theo danh mục (Ăn uống, Mua sắm, Di chuyển, Hóa đơn...).
- Thống kê dòng tiền ròng (Thặng dư / Thâm hụt).

---

## 🛠️ Công nghệ cốt lõi

- **Framework:** Flutter (Dart 3.x)
- **ML & Vision:** `google_mlkit_text_recognition: ^0.13.0`
- **Camera & Image:** `camera: ^0.11.0`, `image_picker: ^1.1.2`
- **Cơ sở dữ liệu:** `sqflite: ^2.4.1` (SQLite cục bộ 100%)
- **Hệ thống thiết kế:** Tuân thủ `taste-skill` standards (.agents/skills)

---

## 📦 Đóng gói APK

File cài đặt Android APK đã được biên dịch hoàn tất tại:
```
build/app/outputs/flutter-apk/app-debug.apk
```

Để đóng gói lại:
```powershell
flutter build apk --debug
# Hoặc đóng gói bản release:
flutter build apk --release
```

---

## 🧪 Kiểm thử

Chạy kiểm thử:
```powershell
flutter test
```
Kiểm tra code lints:
```powershell
dart analyze lib
```
