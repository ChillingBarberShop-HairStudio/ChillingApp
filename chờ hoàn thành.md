# Chờ hoàn thành - Chilling OS

## Đã hoàn thành trong phiên này

- Tài khoản `chillinghair.studio@gmail.com` đã được đặt thành `owner` và kích hoạt trên Supabase. Nếu trình duyệt đang mở Chilling OS, đăng xuất/đăng nhập lại hoặc tải lại trang để nhận JWT và quyền mới.
- Đã bỏ dữ liệu demo hiển thị trong Dashboard, Nhân viên, Kho, Khách hàng, Đơn online, Thanh toán, Hóa đơn và Chiết khấu. Các màn hình khởi tạo trống và tải dữ liệu trực tiếp từ Supabase.
- Đã thay biểu đồ doanh thu bằng layout có lưới cột, trục và SVG dùng chung một độ rộng cột. Điểm line trend nằm đúng tâm mỗi cột.
- Đã tạo menu số 11 Telegram Bot với hướng dẫn tạo bot, lấy Chat ID, nhập token và lưu token mã hóa trong Supabase Vault. Migration `20260712053903_add_telegram_booking_notifications_and_landing_media.sql` đã áp dụng lên project `iovvsanukqcuioaxhgzl`.
- Đã đưa 23 ảnh landing cũ vào bảng `landing_media`. Landing editor có thể xem, sửa mô tả, thay ảnh cũ, xóa ảnh, hoặc thêm ảnh trong giới hạn layout 1 / 9 / 3 / 10.
- Đã cập nhật landing public để ưu tiên `public_url` của ảnh legacy và dùng Supabase Storage cho ảnh thay thế.

## Việc còn chờ xác nhận bảo mật

1. Bật gửi booking từ Supabase sang Telegram. Việc này sẽ gửi tên khách, số điện thoại, lịch hẹn, dịch vụ, nhân viên, tổng tiền và có thể có ghi chú tới Chat ID Telegram đã chọn.
2. Chỉ thực hiện sau khi Owner xác nhận rõ ràng rằng dữ liệu booking trên được phép gửi tới Telegram. Khi được xác nhận, cần tạo migration bổ sung dùng `pg_net`, gửi tin thử và kiểm tra log phản hồi.

## Đã kiểm tra

- `npm run build` đã pass tại `chilling-management-system` và `../chilling_landing_codex_pack` ngày 2026-07-12.
- `git diff --check` đã pass ở cả hai repo; chỉ có cảnh báo CRLF của Git trên Windows.
- Supabase đã xác nhận: profile owner active, ảnh legacy `hero=1`, `studio=9`, `services=3`, `gallery=10`, cùng hai RPC Telegram cấu hình.
- Security Advisor chỉ còn cảnh báo cấu hình Supabase Auth `Leaked Password Protection Disabled`. Cần bật thủ công trong Supabase Dashboard nếu chưa bật.

## Cần triển khai

1. Deploy admin: `npx wrangler pages deploy dist --project-name chillingapp-admin --branch main`.
2. Commit/push ChillingApp và Chilling; kiểm tra HTTP production của admin Pages và GitHub Pages.
3. Sau deploy, đăng xuất/đăng nhập lại Chilling OS để session mới nhận quyền owner.

## Lưu ý bảo mật

- Không đưa Bot Token Telegram, service role key hoặc GitHub token vào `VITE_*`, source hay file commit.
- Bot token chỉ được lưu trong Supabase Vault; UI chỉ nhận trạng thái đã cấu hình, không bao giờ đọc lại token.
- Không xóa hoặc thay đổi quyền RLS để xử lý lỗi quyền. Profile owner hiện đã được sửa đúng cách.
