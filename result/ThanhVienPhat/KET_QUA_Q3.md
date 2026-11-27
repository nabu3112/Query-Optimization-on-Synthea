# BẢNG TỔNG HỢP KẾT QUẢ THỰC NGHIỆM Q3 (DỮ LIỆU SCALE 10X - `synthea_scale`)

> **Nguồn số liệu:** [RAW_LOGS_SCALE_Q3.md](file:///d:/NamHoc/Nam3ky1/hqtcsdl/Toi_uu_truy_van/scale/ThanhVienPhat/RAW_LOGS_SCALE_Q3.md)  
> **Môi trường:** PostgreSQL 18.6 (`work_mem=4MB`, `shared_buffers=128MB`, `effective_cache_size=4GB`, `max_parallel_workers_per_gather=2`) & MySQL 9.4.0 (`innodb_buffer_pool_size=128MB`, `sort_buffer_size=256KB`, `join_buffer_size=256KB`).  
> **Quy trình đo:** 1 lượt warm-up + 5 lượt đo thực thi thuần (không `EXPLAIN`) lấy trung vị $T_{\text{med}}$; kế hoạch thực thi và số dòng ước lượng/thực tế lấy từ `EXPLAIN (ANALYZE, BUFFERS, SETTINGS)` (PG) và `EXPLAIN ANALYZE` (MySQL).  
> **Dung lượng gốc các bảng Q3 đọc (`encounters`, `observations`):**  
> - PostgreSQL: $D_0 = 700.432.384\text{ bytes} \approx \mathbf{667.98\text{ MB}}$  
> - MySQL: $D_0 = 709.492.736\text{ bytes} \approx \mathbf{676.63\text{ MB}}$

---

## 1) Baseline

### Bảng đối chiếu Baseline (PostgreSQL vs. MySQL)

| Cột | PostgreSQL | MySQL |
| --- | --- | --- |
| **Tmed (ms)** | **37,065.879** *(min–max: 36,567.737 – 37,860.130)* | **71,666.961** *(min–max: 70,987.998 – 78,031.984)* |
| **Số dòng kết quả** | **4,174** *(4,174 nhóm năm–tháng–loại hình khám)* | **4,174** |
| **Nút kế hoạch được đối chiếu** | `GroupAggregate` (nút gốc) *(và `Gather Merge` trung gian)* | `Stream results` / `Left hash join` *(nút `Group aggregate` không ghi ước lượng dòng)* |
| **Số dòng ước lượng** | **53,346** *(tại `Gather Merge`: 533,460)* | **1.49e+12** *(tại `Stream results` / `Left hash join`)* |
| **Số dòng thực tế mỗi vòng lặp** | **4,174.00** *(tại `Gather Merge`: 3,026,500.00)* | **3.03e+6** *(3,026,500 dòng trước khi `Group aggregate` ra 4,174 dòng)* |
| **loops** | **1** | **1** |
| **Sai số E%** | **1,178.05%** *(ước lượng thừa ~12.8× tại `GroupAggregate`; tại `Gather Merge`: 82.37%)* | **49,174,817%** *(ước lượng tích Đề-các do thiếu thống kê cặp khóa nối)* |

### Cây kế hoạch truy vấn Baseline
- **PostgreSQL 18.6 (`EXPLAIN (ANALYZE, BUFFERS)` - Run 1, Execution Time: 37,396.318 ms):**
```text
GroupAggregate  (cost=187370.86..259903.54 rows=53346 width=116) (actual time=7943.530..37322.984 rows=4174.00 loops=1)
  Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
  Buffers: shared hit=15825 read=65829, temp read=130677 written=130928
  -> Gather Merge  (cost=187370.86..249501.07 rows=533460 width=163) (actual time=7943.111..22831.052 rows=3026500.00 loops=1)
       -> Sort  (Sort Method: external merge Disk: ~120MB/worker) (actual rows=1008833.33 loops=3)
            -> Parallel Hash Right Join  (actual rows=1008833.33 loops=3)
                 Hash Cond: ((o.encounter = e.id) AND (o.patient = e.patient))
                 -> Parallel Seq Scan on observations o  (actual rows=998990.00 loops=3)
                 -> Parallel Hash  (Batches: 16) (actual rows=177820.00 loops=3)
                      -> Parallel Seq Scan on encounters e  (actual rows=177820.00 loops=3)
```
- **MySQL 9.4.0 (`EXPLAIN ANALYZE` - Run 1, actual time=58378..73595 ms):**
```text
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=58378..73595 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=58378..59885 rows=3.03e+6 loops=1)
        -> Stream results  (cost=149e+9 rows=1.49e+12) (actual time=17572..44052 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=149e+9 rows=1.49e+12) (actual time=17572..38383 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=57262 rows=510483) (actual time=0.814..2558 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=1.13..10358 rows=3e+6 loops=1)
```

---

## 2) Viết lại truy vấn (Pre-aggregation `observations` + `DATE_TRUNC` / `DATE_FORMAT` + bỏ `DISTINCT e.id`)
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **12,908.998** |
| **Khoảng dao động kết quả đo min - max** | **12,694.528 – 13,054.208 ms** |
| **S** | **2.871** |
| **ΔT%** | **+65.17%** *(giảm 65.17% thời gian thực thi)* |
| **E%** | **1,178.05%** *(53,346 vs 4,174)* |
| **ΔD (MB)** | **0 MB** |
| **Kế hoạch có đổi không** | **Có** (gom nhóm trước bảng `observations` từ ~3M dòng xuống ~200,300 nhóm `(encounter, patient)` rồi mới `LEFT JOIN` với `encounters` và dùng `COUNT(e.id)` thay `COUNT(DISTINCT e.id)`, giúp giảm mạnh lượng dữ liệu phải sort/hash). |

---

## 3) Thiết kế chỉ mục (Covering Indexes: `idx_obs_enc_pat_inc_code`, `idx_enc_start_class_inc`)
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **36,329.818** |
| **Khoảng dao động kết quả đo min - max** | **35,879.924 – 37,015.452 ms** |
| **S** | **1.020** |
| **ΔT%** | **+1.99%** |
| **E%** | **1,178.05%** |
| **ΔD (MB)** | **381.77 MB** *(400,310,272 bytes: `idx_obs_enc_pat_inc_code` 315 MB + `idx_enc_start_class_inc` 67 MB)* |
| **P/S = (S − 1) / (ΔD / D₀)** *(với $D_0 = 667.98\text{ MB}$)* | **0.035** *(gần như bằng 0 — rất kém hiệu quả về mặt đánh đổi dung lượng)* |
| **Kế hoạch có đổi không** | **Không** (vẫn chọn `Parallel Seq Scan` + `Parallel Hash Right Join` + `Sort` tràn đĩa + `GroupAggregate` vì Q3 quét toàn bộ 100% bảng không có `WHERE`). |

---

## 4) Cập nhật thống kê (`stat_obs_enc_pat`, `stat_enc_start_class`)
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **35,856.038** |
| **Khoảng dao động kết quả đo min - max** | **35,636.529 – 36,219.078 ms** |
| **S** | **1.034** |
| **ΔT%** | **+3.26%** |
| **E%** | **1,104.07%** *(50,258 vs 4,174 — cải thiện rất ít)* |
| **ΔD (MB)** | **0 MB** |
| **P/S** | **N/A** ($\Delta D = 0$) |
| **Kế hoạch có đổi không** | **Không** (truy vấn tổng hợp toàn cục bắt buộc đọc toàn bảng, nên thống kê không làm đổi kế hoạch). |

---

## 5) Materialized View (PG) / Bảng tổng hợp (MySQL) & Thiết kế tổng hợp (MV + Unique Index / Summary Table + PK)

### Kết quả trên PostgreSQL (đọc toàn bộ báo cáo Q1 & lọc theo năm/loại khám Q2)

| Phương án | Truy vấn | T_med (ms) | min - max (ms) | S | ΔT% | E% | ΔD (MB) | P/S | Kế hoạch có đổi không |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **Materialized View** (`mv_q3_monthly_report`) | Toàn bộ báo cáo (4,174 dòng) | **2.558** | 2.509 – 2.703 | **14,490.2** | **+99.99%** | 62.53% *(6,784 vs 4,174)* | **0.51 MB** *(520 kB)* | **19,059,290** | **Có** (`Seq Scan` + `Sort` trên 4,174 dòng) |
| **Materialized View** (`mv_q3_monthly_report`) | Lọc `2019 & ambulatory` (12 dòng) | **0.275** | 0.236 – 0.347 | **134,785.0** | **+100.00%** | 108.33% *(25 vs 12)* | **0.51 MB** | **177,296,966** | **Có** (`Seq Scan` + `Filter` trên 4,174 dòng) |
| **Tổ hợp** (`MV + Unique Index idx_mv_q3_pk`) | Toàn bộ báo cáo (4,174 dòng) | **1.906** | 1.824 – 2.497 | **19,446.9** | **+99.99%** | **0.00%** *(4,174 vs 4,174)* | **0.69 MB** *(704 kB)* | **18,893,946** | **Có** (`Index Scan using idx_mv_q3_pk`, bỏ được bước `Sort`) |
| **Tổ hợp** (`MV + Unique Index idx_mv_q3_pk`) | Lọc `2019 & ambulatory` (12 dòng) | **0.330** | 0.213 – 0.383 | **112,320.8** | **+100.00%** | 25.00% *(15 vs 12)* | **0.69 MB** | **109,131,494** | **Có** (`Index Scan using idx_mv_q3_pk` với `Index Cond`) |

- **Chi phí tạo & làm mới trên PostgreSQL:**
  - Tạo MV (`CREATE MATERIALIZED VIEW`): **37,438.751 ms** (không index) / **36,376.333 ms** + tạo Unique Index **21.631 ms** (có index).
  - Làm mới (`REFRESH MATERIALIZED VIEW`): **35,454.801 ms**; (`REFRESH MATERIALIZED VIEW CONCURRENTLY`): **35,310.781 ms**.

---

## 6) So sánh với MySQL

### Bảng tổng hợp 1: So sánh nhanh

| Phương án | Speedup PG | Speedup MySQL | E% PG | E% MySQL | Kế hoạch đổi (PG / MySQL) |
| --- | --- | --- | --- | --- | --- |
| **(i) Viết lại** | **2.871** | **1.906** | 1,178.05% | 100.00% *(0 vs 4174)* | Có / Có |
| **(ii) Chỉ mục** | **1.020** | **0.661** *(chậm hơn)* | 1,178.05% | 33,920% | Không / Có *(Covering NLJ chậm hơn Hash Join)* |
| **(iii) Thống kê** | **1.034** | **1.011** | 1,104.07% | 48,844,784% | Không / Không |
| **(iv) MV / Summary Table** *(Full / Filtered)* | **14,490 / 134,785** | **1,106 / 8,558** | 62.5% / 108.3% | 2.35% / 35,500% | Có / Có |
| **Tổ hợp** *(MV+Idx / Summary+PK - Full / Filtered)* | **19,447 / 112,321** | **8,746 / 158,907** | **0.00%** / 25.0% | **0.00%** / 40.0% | Có / Có |

### Bảng tổng hợp 2: Chi tiết các chỉ số

| Phương án | DBMS | T_med (ms) | S | ΔT% | E% | ΔD (MB) |
| --- | --- | --- | --- | --- | --- | --- |
| **Baseline** | PostgreSQL | 37,065.879 | 1.000 | 0.00% | 1,178.05% | 0.00 |
| **Baseline** | MySQL | 71,666.961 | 1.000 | 0.00% | 49,174,817% | 0.00 |
| **Viết lại** | PostgreSQL | 12,908.998 | 2.871 | +65.17% | 1,178.05% | 0.00 |
| **Viết lại** | MySQL | 37,600.472 | 1.906 | +47.53% | 100.00% | 0.00 |
| **Chỉ mục** | PostgreSQL | 36,329.818 | 1.020 | +1.99% | 1,178.05% | 381.77 |
| **Chỉ mục** | MySQL | 108,483.439 | 0.661 | -51.37% | 33,920.12% | 360.86 |
| **Thống kê** | PostgreSQL | 35,856.038 | 1.034 | +3.26% | 1,104.07% | 0.00 |
| **Thống kê** | MySQL | 70,862.947 | 1.011 | +1.12% | 48,844,784% | 0.00 |
| **MV / Summary** *(Full)* | PostgreSQL | 2.558 | 14,490.179 | +99.99% | 62.53% | 0.51 |
| **MV / Summary** *(Full)* | MySQL | 64.782 | 1,106.279 | +99.91% | 2.35% | 0.36 |
| **Tổ hợp** *(Full)* | PostgreSQL | 1.906 | 19,446.946 | +99.99% | 0.00% | 0.69 |
| **Tổ hợp** *(Full)* | MySQL | 8.194 | 8,746.273 | +99.99% | 0.00% | 0.33 |

- **Chi phí tạo bảng tổng hợp trên MySQL:** **76,014.8 ms** (`summary_setup.sql`) và **76,494.1 ms** (`combined_setup.sql` có `PRIMARY KEY`).

### Kế hoạch truy vấn của MySQL trong những trường hợp có thay đổi
1. **Viết lại truy vấn (`obs_agg`):** Chuyển từ `Left hash join` trên 3M dòng sang `Materialize CTE obs_agg` (gom 3M dòng → 200,300 dòng) rồi `Nested loop left join` với `encounters` qua `<auto_key0>`, giảm một nửa thời gian xuống `37,600.472 ms`.
2. **Thiết kế chỉ mục (Covering Indexes):** MySQL chuyển sang `Covering index scan` trên `encounters` + `Covering index lookup` trên `observations` qua `Nested loop left join`, nhưng phải thực hiện ~533,460 lần tra cứu B-tree (`0.166 ms/lần`), khiến tổng thời gian tăng lên `108,483.439 ms` (chậm hơn `Left hash join` của Baseline!).
3. **Tổ hợp (`Summary Table + PRIMARY KEY`):** Đọc trực tiếp trên 4,174 dòng theo thứ tự khóa chính (`Index scan on summary_q3_monthly_report using PRIMARY`), bỏ hoàn toàn bước `Sort` và chỉ mất **`8.194 ms`** (toàn bộ báo cáo) hoặc **`0.451 ms`** (lọc năm 2019 & `ambulatory`).
