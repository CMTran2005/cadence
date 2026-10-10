# Cadence Finance 💳⚡

**Cadence** là ứng dụng quản lý tài chính cá nhân thế hệ mới: Hỗ trợ **quét hóa đơn OCR tự động**, quản lý **gói dịch vụ định kỳ (Subscriptions)**, biểu đồ **phân tích dòng tiền theo tuần/tháng/năm** và tính toán **chỉ số chi tiêu an toàn hàng ngày (Safe-to-Spend)**.

Thiết kế giao diện được chuẩn hóa theo tiêu chuẩn **Taste-Skill (Anti-AI Slop)**: Sử dụng bảng màu Zinc/Slate/OLED tối giản, font số Tabular Figures, viền mảnh 1px có chủ đích và phân cấp thị giác tinh tế.

---

## 🚀 Tính năng nổi bật

### 1. Nhập liệu kép linh hoạt & Phản hồi tức thì
- **Quét hóa đơn bằng Camera (On-Device OCR):** Tích hợp Google ML Kit Text Recognition chạy 100% offline trên thiết bị (zero-cloud cost, bảo mật dữ liệu). Tự động nhận diện tổng số tiền, tên cửa hàng/dịch vụ, ngày giờ và gợi ý danh mục chi tiêu.
- **Hỗ trợ thử hóa đơn mẫu:** Nút *"Thử bill mẫu"* giúp test ngay luồng OCR mà không cần bill giấy thực tế.
- **Màn hình Ghi chép giao dịch chuyên dụng (Manual Entry Screen):** Phản hồi tức thì không khựng, chuyển đổi Thu/Chi nhanh chóng, bàn phím số lớn, chip cộng tiền nhanh (+20k, +50k, +100k, +200k, +500k), lưu giao dịch mượt mà dưới 2 giây.

### 2. Quản lý Gói dịch vụ định kỳ (Subscriptions Hub)
- Theo dõi các khoản chi cố định: Netflix, Spotify, iCloud, ChatGPT, Tiền trọ, Gói cước 4G, Gym...
- Tự động chuẩn hóa chi phí theo tháng (Normalized monthly burn rate).
- Đếm ngược hạn trừ tiền tiếp theo (*"Còn 3 ngày"*, *"Đến hạn hôm nay"*).
- Tính năng **"Đã thanh toán kỳ này"**: 1 chạm tự động chuyển kỳ thanh toán tới và tự động sinh bản ghi chi tiêu vào sổ giao dịch.

### 3. Chỉ số tài chính "Safe-to-Spend" (An toàn để tiêu hôm nay)
- Công thức thông minh:
  $$\text{Safe-to-Spend} = \frac{\text{Tổng thu} - \text{Gói định kỳ} - \text{Quỹ tiết kiệm mục tiêu} - \text{Đã tiêu}}{\text{Số ngày còn lại trong tháng}}$$
- Giúp người dùng biết chính xác mỗi ngày được tiêu tối đa bao nhiêu để cuối tháng không bị âm tiền.

### 4. Báo cáo & Biểu đồ biến động chi tiêu theo Tuần / Tháng / Năm
- **Biểu đồ cột trực quan (Spending Bar Chart):** Theo dõi mức độ chi tiêu theo 7 ngày trong tuần, các tuần trong tháng, hoặc 12 tháng trong năm. Chạm vào cột để xem số tiền chi tiết và điểm chi tiêu cao nhất (Peak).
- **Bộ lọc mốc thời gian linh hoạt:** Dễ dàng lật lại xem báo cáo hoặc danh sách giao dịch của bất kỳ tháng hoặc năm nào trong quá khứ.

### 5. Cài đặt cá nhân hóa toàn diện (Settings Hub)
- **Màu nền giao diện (Theme Background):** Hỗ trợ 4 phong cách tối sang trọng:
  - *Dark Zinc* (Zinc 950 mặc định)
  - *OLED Pure Black* (Đen tuyền #000000, siêu tiết kiệm pin màn hình AMOLED)
  - *Midnight Slate* (Xanh đêm sâu thẳm)
  - *Warm Charcoal* (Than chì ấm áp, dịu mắt)
- **Tiền tệ linh hoạt:** VND (₫), USD ($), EUR (€), JPY (¥).
- **Đa ngôn ngữ:** Tiếng Việt 🇻🇳, English 🇬🇧.

---

## 🛠️ Công nghệ cốt lõi

- **Framework:** Flutter (Dart 3.x)
- **ML & Vision:** `google_mlkit_text_recognition: ^0.13.0`
- **Camera & Image:** `camera: ^0.11.0`, `image_picker: ^1.1.2`
- **Cơ sở dữ liệu:** `sqflite: ^2.4.1` (SQLite cục bộ 100%)
- **Hệ thống thiết kế:** Tuân thủ `taste-skill` standards (.agents/skills)

---

## 📦 Đóng gói APK & Tối ưu dung lượng (GitHub Actions)

Dự án đã tích hợp sẵn GitHub Actions workflow tự động biên dịch và tạo bản phát hành GitHub Release khi đẩy tag phiên bản:

1. **Bản siêu nhẹ Split ABI:** `cadence-arm64-v8a.apk` (**~16MB**, giảm hơn 65% dung lượng nhờ chia kiến trúc và bật R8 code shrinking).
2. **Bản phổ thông:** `cadence-universal.apk` (tương thích mọi thiết bị).

Cách kích hoạt phát hành bản mới:
```bash
git tag v1.1.0
git push origin v1.1.0
```
Máy chủ GitHub Actions sẽ tự động biên dịch và gắn sẵn link tải APK trực tiếp trong mục **Releases** của repo.
