# BẢNG TỔNG HỢP KẾT QUẢ THỰC NGHIỆM Q1 (DỮ LIỆU SCALE 10X - `synthea_scale`)

> **Nguồn số liệu:** [RAW_LOGS_SCALE_Q1.md](file:///d:/NamHoc/Nam3ky1/hqtcsdl/Toi_uu_truy_van/scale/ThanhVienTung/result/RAW_LOGS_SCALE_Q1.md)  
> **Môi trường:** PostgreSQL 18.6 (`work_mem=4MB`, `shared_buffers=128MB`, `effective_cache_size=4GB`, `max_parallel_workers_per_gather=2`) & MySQL 9.4.0 (`innodb_buffer_pool_size=128MB`, `sort_buffer_size=256KB`, `join_buffer_size=256KB`).  
> **Quy trình đo:** 1 lượt warm-up + 5 lượt đo thực thi thuần (không `EXPLAIN`) lấy trung vị $T_{\text{med}}$; kế hoạch thực thi và số dòng ước lượng/thực tế lấy từ `EXPLAIN (ANALYZE, BUFFERS, SETTINGS)` (PG) và `EXPLAIN ANALYZE` (MySQL).  
> **Dung lượng gốc các bảng Q1 đọc (`patients`, `encounters`, `conditions`, `observations`):**  
> - PostgreSQL: $D_0 = 717.340.672\text{ bytes} \approx \mathbf{684.11\text{ MB}}$  
> - MySQL: $D_0 = 691.044.352\text{ bytes} \approx \mathbf{659.03\text{ MB}}$

---

## 1) Baseline

### Bảng đối chiếu Baseline (PostgreSQL vs. MySQL)

| Cột | PostgreSQL | MySQL |
| --- | --- | --- |
| **Tmed (ms)** | **881.505** *(min–max: 607.500 – 934.667)* | **51,854.044** *(min–max: 50,189.267 – 52,489.294)* |
| **Số dòng kết quả** | **12,910** | **12,910** |
| **Nút kế hoạch được đối chiếu** | `Sort` (nút gốc) | `Stream results` / `Left hash join` (nút gốc dưới `Sort`) |
| **Số dòng ước lượng** | **2** | **11.9e+9** *(11,900,000,000)* |
| **Số dòng thực tế mỗi vòng lặp** | **12,910.00** | **12,910** |
| **loops** | **1** | **1** |
| **Sai số E%** | **99.98%** *(ước lượng thiếu ~6,455×)* | **92,176,507%** *(ước lượng thừa ~921,765×)* |

### Cây kế hoạch truy vấn Baseline
- **PostgreSQL 18.6 (`EXPLAIN (ANALYZE, BUFFERS)` - Run 1, Execution Time: 578.766 ms):**
```text
Sort  (cost=108010.68..108010.68 rows=2 width=211) (actual time=577.347..578.766 rows=12910.00 loops=1)
  Sort Key: p.id, e.start, e.id, o.code
  Sort Method: quicksort  Memory: 3123kB
  -> Gather  (Workers Launched: 1) (actual rows=12910.00 loops=1)
       -> Parallel Hash Right Join  (Hash Cond: c.encounter = e.id AND c.patient = p.id) (actual rows=6455.00 loops=2)
            -> Parallel Seq Scan on conditions c  (actual rows=41880.00 loops=2)
            -> Parallel Hash  (actual rows=6455.00 loops=2)
                 -> Nested Loop  (Join Filter: p.id = e.patient) (actual rows=6455.00 loops=2)
                      -> Parallel Hash Join  (Hash Cond: o.patient = e.patient AND o.encounter = e.id)
                           -> Parallel Seq Scan on observations o  (actual rows=1498485.00 loops=2)
                           -> Parallel Hash  (actual rows=1920.00 loops=2)
                                -> Parallel Seq Scan on encounters e  (Filter: ambulatory & 2020)
                      -> Index Scan using patients_pkey on patients p  (actual rows=1.00 loops=12910)
```
- **MySQL 9.4.0 (`EXPLAIN ANALYZE` - Run 1, actual time=55050..55058 ms):**
```text
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=55050..55058 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=909..54973 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=909..54923 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=96.8..53623 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=96.3..53240 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (actual rows=2.69e+6 loops=1)
                        -> Table scan on o  (actual rows=3e+6 loops=1)
                    -> Filter: (e.patient = o.patient AND ambulatory AND 2020)  (actual rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (actual rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (actual rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (actual rows=83760 loops=1)
```

---

## 2) Viết lại truy vấn (Phương án 02a)
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **656.178** |
| **Khoảng dao động kết quả đo min - max** | **507.477 – 755.975 ms** |
| **S** | **1.343** |
| **ΔT%** | **+25.56%** |
| **E%** | **57.40%** *(20,320 vs 12,910 — giảm mạnh sai số nhờ bỏ điều kiện nối `patient` dư thừa)* |
| **ΔD (MB)** | **0 MB** |
| **Kế hoạch có đổi không** | **Có** (`Gather Merge` ở trên cùng + sắp xếp song song ở 2 worker; đổi thứ tự nối sang `observations ⋈ encounters` → `Hash Join patients` → `Parallel Hash Right Join conditions`, bỏ được `Nested Loop` 12,910 lần tra `patients_pkey`). |

---

## 3) Thiết kế chỉ mục (`idx_q1_enc_class_start`, `idx_q1_obs_enc_patient`, `idx_q1_cond_enc_patient`)
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **148.956** |
| **Khoảng dao động kết quả đo min - max** | **132.886 – 170.024 ms** |
| **S** | **5.918** |
| **ΔT%** | **+83.10%** *(giảm 83.10% thời gian thực thi)* |
| **E%** | **99.98%** *(2 vs 12,910)* |
| **ΔD (MB)** | **115.07 MB** *(120,659,968 bytes: `idx_q1_enc_class_start` 67 MB + `idx_q1_obs_enc_patient` 40 MB + `idx_q1_cond_enc_patient` 7.75 MB)* |
| **P/S = (S − 1) / (ΔD / D₀)** *(với $D_0 = 684.11\text{ MB}$)* | **29.24** |
| **Kế hoạch có đổi không** | **Có** (chuyển hoàn toàn từ `Seq Scan` + `Hash Join` sang `Bitmap Index Scan on idx_q1_enc_class_start` → `Nested Loop` + `Index Scan` qua `idx_q1_obs_enc_patient`, `patients_pkey` và `idx_q1_cond_enc_patient`, tránh đọc ~3 triệu dòng `observations`). |

+ **Cây kế hoạch PostgreSQL khi có chỉ mục (Run 1):**
```text
Sort  (cost=21745.66..21745.67 rows=2 width=211) (actual time=196.870..197.819 rows=12910.00 loops=1)
  -> Gather  (Workers Launched: 2) (actual rows=12910.00 loops=1)
       -> Nested Loop Left Join  (actual rows=4303.33 loops=3)
            -> Nested Loop  (actual rows=4303.33 loops=3)
                 -> Nested Loop  (actual rows=4303.33 loops=3)
                      -> Parallel Bitmap Heap Scan on encounters e -> Bitmap Index Scan on idx_q1_enc_class_start
                      -> Index Scan using idx_q1_obs_enc_patient on observations o
                 -> Index Scan using patients_pkey on patients p
            -> Index Scan using idx_q1_cond_enc_patient on conditions c
```

---

## 4) Cập nhật thống kê (`SET STATISTICS 1000` + `ANALYZE VERBOSE`)
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **1,243.836** |
| **Khoảng dao động kết quả đo min - max** | **859.451 – 1,516.555 ms** |
| **S** | **0.709** |
| **ΔT%** | **-41.10%** *(chậm hơn do dao động I/O, kế hoạch không đổi)* |
| **E%** | **99.98%** *(2 vs 12,910)* |
| **ΔD (MB)** | **0 MB** |
| **P/S** | **N/A** ($\Delta D = 0$) |
| **Kế hoạch có đổi không** | **Không** (vẫn giữ nguyên cây `Parallel Seq Scan` + `Parallel Hash Right Join` như Baseline vì nguyên nhân ước lượng sai 2 dòng nằm ở tương quan 2 khóa nối `(encounter, patient)` chứ không phải độ chi tiết thống kê đơn cột). |

---

## 5) Thiết kế tổng hợp
- **Tổ hợp sử dụng:** **(i) Viết lại truy vấn (02a)** + **(ii) Thiết kế chỉ mục (3 index `idx_q1_*`)**, giữ thống kê mặc định.
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **471.904** |
| **Khoảng dao động kết quả đo min - max** | **441.984 – 504.715 ms** |
| **S** | **1.868** |
| **ΔT%** | **+46.47%** |
| **E%** | **50.18%** *(19,388 vs 12,910)* |
| **ΔD (MB)** | **115.07 MB** |
| **Kế hoạch có đổi không** | **Có** (dùng `Bitmap Index Scan on idx_q1_enc_class_start` cho `encounters`, nhưng vẫn dùng `Parallel Hash Join` + `Parallel Seq Scan` trên `observations` và `conditions` — không dùng 2 index `idx_q1_obs_enc_patient` và `idx_q1_cond_enc_patient` như phương án Chỉ mục thuần trên SQL gốc, nên chậm hơn phương án Chỉ mục đơn lẻ!). |

---

## 6) So sánh với MySQL

### Bảng tổng hợp 1: So sánh nhanh

| Phương án | Speedup PG | Speedup MySQL | E% PG | E% MySQL | Kế hoạch đổi (PG / MySQL) |
| --- | --- | --- | --- | --- | --- |
| **(i) Viết lại (02a)** | **1.343** | **1.130** | 57.40% | 92,176,507% | Có / Không |
| **(ii) Chỉ mục** | **5.918** | **11.526** | 99.98% | 727.71% | Có / Có |
| **(iii) Thống kê** | **0.709** | **0.805** | 99.98% | 94,500,287% | Không / Không |
| **Tổ hợp (02a + Chỉ mục)** | **1.868** | **19.566** | 50.18% | 781.01% | Có / Có |

### Bảng tổng hợp 2: Chi tiết các chỉ số

| Phương án | DBMS | T_med (ms) | S | ΔT% | E% | ΔD (MB) |
| --- | --- | --- | --- | --- | --- | --- |
| **Baseline** | PostgreSQL | 881.505 | 1.000 | 0.00% | 99.98% | 0.00 |
| **Baseline** | MySQL | 51,854.044 | 1.000 | 0.00% | 92,176,507% | 0.00 |
| **Viết lại (02a)** | PostgreSQL | 656.178 | 1.343 | +25.56% | 57.40% | 0.00 |
| **Viết lại (02a)** | MySQL | 45,901.319 | 1.130 | +11.48% | 92,176,507% | 0.00 |
| **Chỉ mục** | PostgreSQL | **148.956** | **5.918** | **+83.10%** | 99.98% | 115.07 |
| **Chỉ mục** | MySQL | 4,498.850 | 11.526 | +91.32% | 727.71% | 342.38 |
| **Thống kê** | PostgreSQL | 1,243.836 | 0.709 | -41.10% | 99.98% | 0.00 |
| **Thống kê** | MySQL | 64,393.157 | 0.805 | -24.18% | 94,500,287% | 0.00 |
| **Tổ hợp** | PostgreSQL | 471.904 | 1.868 | +46.47% | 50.18% | 115.07 |
| **Tổ hợp** | MySQL | **2,650.146** | **19.566** | **+94.89%** | 781.01% | 342.38 |

### Kế hoạch truy vấn của MySQL trong những trường hợp có thay đổi
- **Chỉ mục & Tổ hợp trên MySQL:** Thay vì `Table scan` 3 triệu dòng `observations` rồi tra cứu `PRIMARY` của `encounters` 2.69 triệu lần như Baseline, MySQL chuyển sang **`Index range scan` trên `encounters` (`idx_q1_enc_class_start`)** để lấy trước 3,840 lần khám hợp lệ, sau đó dùng **`Index lookup`** vào `patients (PRIMARY)`, `conditions (idx_q1_cond_enc_patient)` và `observations (idx_q1_obs_enc_patient)`. Ở phương án Tổ hợp, bỏ điều kiện `patient` dư thừa giúp `T_med` giảm thêm từ `4,498.85 ms` xuống **`2,650.15 ms`** (**`S = 19.57×`**).
```text
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=2678..2690 rows=12910 loops=1)
    -> Stream results  (cost=138384 rows=113739) (actual time=13.9..2596 rows=12910 loops=1)
        -> Nested loop inner join  (cost=138384 rows=113739) (actual time=13.8..2526 rows=12910 loops=1)
            -> Nested loop left join  (cost=13271 rows=7937) (actual time=13.6..1434 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10493 rows=7276) (actual time=13.6..1310 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start ... (actual rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (actual rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (actual rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (actual rows=3.26 loops=3960)
```
