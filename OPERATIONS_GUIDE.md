# Tài liệu vận hành Chilling OS

## 1. Đăng nhập và phân quyền

1. Tạo tài khoản trong Supabase Auth.
2. Gán vai trò `owner` cho chủ shop; chỉ owner/manager được thêm nhân viên, chỉnh kho, tỷ lệ chiết khấu, Landing và tài khoản ngân hàng.
3. Không chia sẻ mật khẩu, Supabase service-role key hoặc token GitHub qua nhóm chat.

## 2. Luồng đặt lịch online

1. Khách đặt lịch trên Landing page.
2. Đơn xuất hiện tại `Đơn online` với trạng thái `Chờ phục vụ`.
3. Nhấn `Nhận phục vụ` khi khách đến.
4. Nhấn `Chuyển thanh toán`; Chilling OS mở quầy thanh toán và tự điền tên, số điện thoại, dịch vụ, nhân viên và số lượng từ booking.
5. Chọn tiền mặt hoặc chuyển khoản. Với chuyển khoản, QR VietQR, số tiền và nội dung chuyển khoản thay đổi theo thời gian thực.
6. Nhấn `Xác nhận thanh toán`. Hệ thống tạo hóa đơn, đồng bộ doanh thu/KPI/khách hàng và chuyển booking sang hoàn thành.

## 3. Luồng khách offline

1. Vào `Thanh toán`.
2. Nhập khách hàng, chọn dịch vụ, nhân viên và số lượng.
3. Chọn phương thức thanh toán, giảm giá (nếu có) và tài khoản nhận tiền.
4. Kiểm tra hóa đơn tạm tính hoặc QR rồi xác nhận thanh toán.

## 4. Kho hàng

- `Nhập kho`: sản phẩm mới nhận mã tự sinh; số lượng x đơn giá tự tạo khoản chi trong ngày.
- Khi nhập thêm sản phẩm cũ, chọn sản phẩm trong danh sách ở form Nhập kho để không tạo mã mới.
- `Xuất kho`: chỉ chọn được hàng đã có trong tồn kho và hệ thống chặn xuất âm.
- Có thể sửa trực tiếp dữ liệu trong bảng tồn kho, sau đó bấm `Lưu` từng dòng.
- Lịch sử nhập/xuất được giữ 90 ngày. Hóa đơn, doanh thu và khoản chi không bị xóa theo cơ chế này.

## 5. Chiết khấu chủ và thợ

- Menu `Chiết khấu chủ & thợ` cho phép đặt tỷ lệ 0-100% riêng cho từng nhân viên; mặc định 50/50.
- Tỷ lệ được chụp tại lúc thanh toán hóa đơn. Thay đổi tỷ lệ sau này không làm sai báo cáo cũ.
- Dùng bộ lọc ngày, tháng hoặc toàn bộ để đối soát phần thợ và phần chủ shop.

## 6. Hóa đơn và PDF

- `Hóa đơn` lưu mã tự sinh, khách hàng, dịch vụ, đơn giá, tổng tiền và lời cảm ơn.
- Nút tải PDF tạo file có thể gửi qua email/Zalo hoặc in.
- Nút In phù hợp khi cần in trực tiếp hoặc lưu PDF bằng trình duyệt.

## 7. Landing page

- Chỉ sửa các header đã có sẵn trong `Landing page`; không tạo header mới để giữ đúng bố cục quảng cáo.
- Ảnh Hero, Studio, Dịch vụ và Gallery có thể thêm, xóa hoặc sửa mô tả. Ảnh được lưu trong Supabase Storage và landing page đọc động nên cập nhật ngay.
- Nút `Yêu cầu deploy` chỉ dùng khi cần khởi động lại pipeline tĩnh. Không đặt GitHub token trong frontend.

## 8. Dashboard và báo cáo

- Chọn `Theo ngày`, `Theo tháng` hoặc `Tất cả từ trước đến nay` trước khi đọc KPI.
- Biểu đồ doanh thu hiển thị số ngay trên cột; đường xanh theo đúng tâm từng cột.
- Ba bảng xếp hạng đều hiển thị Top 5.

## 9. Kiểm tra cuối ngày

1. Đối chiếu tiền mặt/chuyển khoản với Dashboard.
2. Kiểm tra chi phí nhập kho và lợi nhuận tạm tính.
3. Kiểm tra hóa đơn còn thiếu nhân viên hoặc dịch vụ.
4. Kiểm tra các đơn online đang `Chờ phục vụ` hoặc `Đang phục vụ`.
5. Xuất PDF các hóa đơn cần gửi khách.

## 10. Bảo mật và khôi phục

- Trình duyệt chỉ dùng public/anon key với RLS. Không đưa service-role key vào `.env` frontend hay GitHub Pages.
- Bucket ảnh cho phép đọc công khai để hiển thị avatar/landing, nhưng chỉ owner/manager đăng nhập mới có quyền tải lên, sửa hoặc xóa.
- Thu hồi ngay token GitHub đã từng được gửi qua chat và tạo token mới theo nguyên tắc quyền tối thiểu.
- Dùng Supabase Database Backups và Cloudflare Pages deployment history để khôi phục khi cần.
