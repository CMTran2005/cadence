# Cadence

Cadence là ứng dụng theo dõi và quản lý tài chính cá nhân: Hỗ trợ quét hóa đơn OCR tự động trên thiết bị, quản lý gói dịch vụ định kỳ, phân tích dòng tiền theo thời gian thực và tính toán chỉ số chi tiêu an toàn hàng ngày (Safe-to-Spend).

Thiết kế giao diện tuân theo tiêu chuẩn Taste-Skill (Anti-AI Slop): Bảng màu tối giản (Zinc, OLED, Slate, Charcoal, Forest, Obsidian, Crimson, Arctic), font số Tabular Figures, viền mảnh 1px có chủ đích và phân cấp thị giác rõ ràng.

---

## Tính năng chính

### 1. Nhập liệu linh hoạt và tức thì
- **Quét hóa đơn bằng Camera (On-Device OCR):** Tích hợp Google ML Kit Text Recognition chạy ngoại tuyến trên thiết bị, bảo mật dữ liệu, không gửi thông tin tài chính ra máy chủ ngoài. Tự động nhận diện số tiền, tên cửa hàng và gợi ý danh mục. Hỗ trợ phân loại hóa đơn mua hàng (Chi tiêu) hoặc bill chuyển khoản (Thu nhập).
- **Màn hình Ghi chép giao dịch chuyên dụng:** Chuyển đổi nhanh giữa Thu nhập và Chi tiêu, bàn phím số tối ưu, phím cộng tiền nhanh, phản hồi tức thì.
- **Tùy biến danh mục:** Tách biệt danh mục Thu nhập và Chi tiêu, hỗ trợ người dùng tạo thêm danh mục tùy chỉnh với biểu tượng và màu sắc riêng.
- **Thao tác nhanh trên sổ giao dịch:** Vuốt sang phải để chỉnh sửa giao dịch, vuốt sang trái để xóa.

### 2. Quản lý gói dịch vụ định kỳ (Subscriptions Hub)
- Theo dõi các khoản chi phí cố định lặp lại: Netflix, Spotify, iCloud, tiền nhà, cước viễn thông, gym...
- Tự động chuẩn hóa chi phí theo tháng và tính toán mức tiêu tốn ước tính theo năm.
- Cảnh báo thời hạn thanh toán (hôm nay, sắp tới, quá hạn).
- Đánh dấu đã thanh toán kỳ này để tự động chuyển kỳ kế tiếp và ghi nhận vào sổ thu chi.

### 3. Chỉ số Safe-to-Spend (Hạn mức an toàn mỗi ngày)
- Công thức tính toán:
  $$\text{Safe-to-Spend} = \frac{\text{Tổng thu} - \text{Gói định kỳ} - \text{Quỹ tiết kiệm mục tiêu} - \text{Đã chi tiêu}}{\text{Số ngày còn lại trong tháng}}$$
- Cung cấp hạn mức chi tiêu an toàn theo ngày để đảm bảo người dùng luôn đạt được mục tiêu tài chính cuối tháng.

### 4. Quản lý Ngân sách & Cảnh báo hạn mức (Budget Management)
- Thiết lập ngân sách chi tiêu hàng tháng trực tiếp từ bảng điều khiển chính hoặc cài đặt.
- Thanh tiến độ chuyển màu thông minh: An toàn (Xanh) -> Cảnh báo chạm mức 70% (Vàng) -> Vượt ngân sách (Đỏ).
- Cảnh báo tức thì khi ghi chép giao dịch chi tiêu vượt ngưỡng 80% hoặc vượt 100% hạn mức ngân sách tháng.

### 5. Báo cáo, biểu đồ tròn và so sánh biến động
- **Biểu đồ tròn (Interactive Donut Chart):** Biểu đồ phân bổ tỷ lệ phần trăm theo danh mục với khả năng chạm chọn lát để xem chi tiết danh mục, số tiền và tỷ lệ phần trăm.
- **So sánh biến động theo kỳ (Period-over-Period Comparison):** Phân tích so sánh chi tiêu với kỳ trước (tuần, tháng, năm) thể hiện rõ mức tiết kiệm hoặc gia tăng chi tiêu kèm tỷ lệ %.
- **Biểu đồ cột trực quan:** Theo dõi biến động chi tiêu theo tuần, theo các tuần trong tháng (chuẩn theo lịch thực tế), hoặc 12 tháng trong năm.
- **Thống kê trung bình linh hoạt:** Tự động tính toán mức chi tiêu trung bình theo ngày, theo tuần hoặc theo tháng tương ứng với mốc thời gian đang xem.

### 6. Cài đặt và tùy biến cá nhân
- **Màu nền giao diện:** Hỗ trợ 8 bảng màu tối (Zinc, OLED, Slate, Charcoal, Forest, Obsidian, Crimson, Arctic) hiển thị dạng lưới 4 màu 1 hàng căn đều từ trái.
- **Đa tiền tệ:** Hỗ trợ VND (₫), USD ($), EUR (€), JPY (¥), GBP (£), KRW (₩), SGD (S$) dạng Dropdown gọn gàng.
- **Đa ngôn ngữ (9 ngôn ngữ):** Hỗ trợ Tiếng Việt, English, Français, 日本語, 简体中文, 한국어, Español, Deutsch, Русский dạng Dropdown. Thay đổi ngôn ngữ có hiệu lực tức thì trên toàn bộ ứng dụng.
- **Quản lý dữ liệu:** Lưu trữ cục bộ với SQLite, hỗ trợ xóa sạch dữ liệu an toàn.

---

## Công nghệ sử dụng

- **Framework:** Flutter (Dart 3.x)
- **OCR Engine:** Google ML Kit Text Recognition (`google_mlkit_text_recognition`)
- **Camera & Image:** Camera, Image Picker
- **Cơ sở dữ liệu:** SQLite (`sqflite`)
- **Quốc tế hóa:** Hỗ trợ đa ngôn ngữ và định dạng tiền tệ động (`intl`)

---

## Đóng gói APK Release (GitHub Actions)

Dự án tích hợp GitHub Actions workflow tự động biên dịch và phát hành bản cài APK khi tạo tag phiên bản:

1. **Bản tối ưu dung lượng (Split ABI):** `cadence-arm64-v8a.apk` (giảm hơn 60% dung lượng nhờ phân tách kiến trúc CPU 64-bit).
2. **Bản tương thích toàn diện:** `cadence-universal.apk` (tương thích mọi thiết bị Android).

Cách kích hoạt phát hành bản mới:
```bash
git tag v1.1.5
git push origin v1.1.5
```
Workflow sẽ tự động chạy kiểm thử, biên dịch APK và đính kèm file tải trực tiếp trong mục Releases trên GitHub.
