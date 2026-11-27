# Workload Q1: Tra cứu lịch sử khám, chẩn đoán và xét nghiệm theo thời gian và loại hình khám

Kết quả tham chiếu: **1,291 dòng** (dữ liệu 1x) / **12,910 dòng** (dữ liệu scale 10x), kiểm tra tương đương giữa `baseline.sql` và `rewrite.sql` trên cả PostgreSQL và MySQL (`cond_patient_mismatch = 0`, `obs_patient_mismatch = 0`).

## Thứ tự chạy (mỗi hệ quản trị có thư mục riêng: `postgres/`, `mysql/`)

| Bước | Chạy | Đo / quan sát |
| --- | --- | --- |
| 1 | `baseline.sql` | Mốc chuẩn: thời gian, số dòng ước lượng và thực tế (`EXPLAIN (ANALYZE, BUFFERS, SETTINGS)` / `EXPLAIN ANALYZE`) |
| 2 | `rewrite.sql` | Viết lại truy vấn (02a): lọc sớm `encounters` bằng derived table, bỏ vị từ `patient` thừa, `INNER JOIN observations` trước, `LEFT JOIN conditions` sau cùng |
| 3 | `index_setup.sql` -> `baseline.sql` -> `index_teardown.sql` | Thiết kế chỉ mục trên SQL gốc (không chạy `ANALYZE` sau khi tạo index để không lẫn với bước Thống kê) |
| 4 | `stats_setup.sql` -> `baseline.sql` -> `stats_teardown.sql` | Cập nhật thống kê (`SET STATISTICS 1000` trên PG; `STATS_SAMPLE_PAGES = 200` + Histogram 100 buckets trên MySQL) |
| 5 | `combined_setup.sql` -> `rewrite.sql` -> `combined_teardown.sql` | Tổ hợp: viết lại truy vấn (02a) + thiết kế chỉ mục (giống bước 3) |

Sau mỗi kỹ thuật phải chạy file `*_teardown.sql` tương ứng để đưa cơ sở dữ liệu về trạng thái baseline trước khi đo kỹ thuật tiếp theo.

## Lưu ý

- Giữ nguyên hoàn toàn logic và cách thức thực thi câu lệnh SQL từ `claude_step1/Q1_*.sql`.
- Tên các index (`idx_q1_*`) có tiền tố riêng để `*_teardown.sql` không xóa nhầm index có sẵn.
- Trong `index_setup.sql` và `combined_setup.sql` không chạy `ANALYZE` trên bảng để giữ nguyên thống kê mặc định như thiết kế ban đầu ở `claude_step1`.
