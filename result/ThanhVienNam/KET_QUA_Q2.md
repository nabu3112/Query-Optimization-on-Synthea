# BẢNG TỔNG HỢP KẾT QUẢ THỰC NGHIỆM Q2 (DỮ LIỆU SCALE 10X - `synthea_scale`)

> **Nguồn số liệu:** [RAW_LOGS_SCALE_Q2.md](file:///d:/NamHoc/Nam3ky1/hqtcsdl/Toi_uu_truy_van/scale/ThanhVienNam/RAW_LOGS_SCALE_Q2.md)  
> **Môi trường:** PostgreSQL 18.6 (`work_mem=4MB`, `shared_buffers=128MB`, `effective_cache_size=4GB`, `max_parallel_workers_per_gather=2`) & MySQL 9.4.0 (`innodb_buffer_pool_size=128MB`, `sort_buffer_size=256KB`, `join_buffer_size=256KB`).  
> **Quy trình đo:** 1 lượt warm-up + 5 lượt đo thực thi thuần (không `EXPLAIN`) lấy trung vị $T_{\text{med}}$; kế hoạch thực thi và số dòng ước lượng/thực tế lấy từ `EXPLAIN (ANALYZE, BUFFERS, SETTINGS)` (PG) và `EXPLAIN ANALYZE` (MySQL).  
> **Dung lượng gốc các bảng Q2 đọc (`conditions`, `encounters`, `patients`):**  
> - PostgreSQL: $D_0 = 226.836.480\text{ bytes} \approx \mathbf{216.33\text{ MB}}$  
> - MySQL: $D_0 = 192.970.752\text{ bytes} \approx \mathbf{184.03\text{ MB}}$

---

## 1) Baseline

### Bảng đối chiếu Baseline (PostgreSQL vs. MySQL)

| Cột | PostgreSQL | MySQL |
| --- | --- | --- |
| **Tmed (ms)** | **199.556** *(min–max: 175.619 – 240.684)* | **3859.067** *(min–max: 3542.097 – 4510.737)* |
| **Số dòng kết quả** | **9,850** | **9,850** |
| **Nút kế hoạch được đối chiếu** | `Sort` / `Nested Loop` (nút gốc) *(và `Parallel Seq Scan on encounters`)* | `Stream results` / `Nested loop inner join` (nút gốc) *(và `Filter` trên `e`)* |
| **Số dòng ước lượng** | **1** *(tại `encounters`: 20,730 / worker)* | **410** *(tại `Filter e`: 0.05 / vòng lặp)* |
| **Số dòng thực tế mỗi vòng lặp** | **9,850.00** *(tại `encounters`: 59,645.00)* | **9,850** *(tại `Filter e`: 0.258)* |
| **loops** | **1** *(tại `encounters`: 2)* | **1** *(tại `Filter e`: 38,110)* |
| **Sai số E%** | **99.99%** *(tại `encounters`: 65.24%)* | **95.84%** *(tại `Filter e`: 80.62%)* |

### Cây kế hoạch truy vấn Baseline
- **PostgreSQL 18.6 (`EXPLAIN (ANALYZE, BUFFERS)` - Run 1, Execution Time: 182.960 ms):**
```text
Sort  (cost=28575.68..28575.69 rows=1 width=174) (actual time=180.614..182.960 rows=9850.00 loops=1)
  Sort Key: c.start DESC, p.id, e.id, c.code
  Sort Method: quicksort  Memory: 2223kB
  -> Nested Loop  (cost=26413.36..28575.67 rows=1 width=174) (actual time=136.071..173.901 rows=9850.00 loops=1)
       -> Gather  (cost=26413.08..28575.33 rows=1 width=168) (actual time=136.012..139.588 rows=9850.00 loops=1)
            -> Parallel Hash Join  (cost=25413.08..27575.23 rows=1 width=168) (actual time=107.975..118.502 rows=4925.00 loops=2)
                 Hash Cond: ((c.encounter = e.id) AND (c.patient = e.patient))
                 -> Parallel Seq Scan on conditions c  (rows=22371) (actual rows=19055.00 loops=2) [Filter: stop IS NULL]
                 -> Parallel Hash  (rows=20730) (actual rows=59645.00 loops=2)
                      -> Parallel Seq Scan on encounters e  (rows=20730) (actual rows=59645.00 loops=2) [Filter: reasoncode <> '' AND encounterclass = 'ambulatory']
       -> Index Scan using patients_pkey on patients p  (rows=1) (actual rows=1.00 loops=9850)
```
- **MySQL 9.4.0 (`EXPLAIN ANALYZE` - Run 1, actual time=3715..3721 ms):**
```text
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=3715..3721 rows=9850 loops=1)
    -> Stream results  (cost=13103 rows=410) (actual time=1.32..3655 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13103 rows=410) (actual time=1.29..3595 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12959 rows=410) (actual time=1.23..3492 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8395 rows=8195) (actual time=1.16..317 rows=38110 loops=1)
                    -> Table scan on c  (cost=8395 rows=81947) (actual time=1.16..282 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.457 rows=0.05) (actual time=0.0828..0.0829 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.457 rows=1) (actual time=0.0805..0.0806 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.014..0.0141 rows=1 loops=9850)
```

---

## 2) Viết lại truy vấn (`e.reasoncode > ''`)
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **245.539** |
| **Khoảng dao động kết quả đo min - max** | **207.699 – 249.694 ms** |
| **S** | **0.813** |
| **ΔT%** | **-23.04%** *(chậm hơn baseline do chưa có index trên `encounters`)* |
| **E%** | **99.99%** |
| **ΔD (MB)** | **0 MB** |
| **Kế hoạch có đổi không** | **Không** (vẫn là `Parallel Seq Scan on encounters` + `Parallel Hash Join` + `Nested Loop` với `patients_pkey` + `Sort`, vì chưa có index B-tree cho phép `>` dùng index). |

---

## 3) Thiết kế chỉ mục (`idx_q2_enc_class_reason`, `idx_q2_cond_active` / `idx_q2_cond_stop_enc`)
- **Kết quả trên PostgreSQL:**
  - *Lưu ý:* Bảng dưới ghi nhận cả 2 trường hợp theo hướng dẫn Q2: chạy với `baseline.sql` (`<> ''`) và chạy với `rewrite.sql` (`> ''`).

| Chỉ số | Với `baseline.sql` (`<> ''`) | Với `rewrite.sql` (`> ''`) |
| --- | --- | --- |
| **T_med (ms)** | **231.742** | **209.114** |
| **Khoảng dao động kết quả đo min - max** | **218.912 – 257.236 ms** | **195.339 – 256.186 ms** |
| **S** | **0.861** | **0.954** |
| **ΔT%** | **-16.13%** | **-4.79%** |
| **E%** | **99.99%** | **99.99%** |
| **ΔD (MB)** | **7.01 MB** *(7,348,224 bytes: `idx_q2_cond_active` 3.35 MB + `idx_q2_enc_class_reason` 3.66 MB)* | **7.01 MB** |
| **P/S = (S − 1) / (ΔD / D₀)** *(với $D_0 = 216.33\text{ MB}$)* | **-4.29** | **-1.41** |
| **Kế hoạch có đổi không** | **Có** (chuyển `Seq Scan on encounters` → `Parallel Bitmap Heap Scan` + `Bitmap Index Scan on idx_q2_enc_class_reason`, nhưng chỉ lọc được `encounterclass = 'ambulatory'`, vẫn phải `Filter` `reasoncode <> ''` trên 189,360 dòng). | **Có** (`Bitmap Index Scan on idx_q2_enc_class_reason` dùng được cả 2 điều kiện `encounterclass = 'ambulatory' AND reasoncode > ''`, đọc 119,290 TIDs thay vì 189,360; tuy nhiên chưa nhanh hơn `Parallel Seq Scan` do tỷ lệ chọn lọc còn cao ~22.4%). |

+ **Cây kế hoạch PostgreSQL khi có chỉ mục (`rewrite.sql` - Run 1, Execution Time: 196.064 ms):**
```text
Sort  (cost=28035.51..28035.52 rows=1 width=174) (actual time=192.752..195.539 rows=9850.00 loops=1)
  -> Nested Loop  (actual time=144.645..186.566 rows=9850.00 loops=1)
       -> Gather  (actual time=144.576..150.638 rows=9850.00 loops=1)
            -> Parallel Hash Join  (actual time=118.936..131.121 rows=4925.00 loops=2)
                 -> Parallel Seq Scan on conditions  (actual rows=19055.00 loops=2) [Filter: stop IS NULL]
                 -> Parallel Hash  (actual rows=59645.00 loops=2)
                      -> Parallel Bitmap Heap Scan on encounters  (actual rows=59645.00 loops=2)
                           Recheck Cond: ((encounterclass = 'ambulatory') AND (reasoncode > ''))
                           -> Bitmap Index Scan on idx_q2_enc_class_reason  (actual rows=119290.00 loops=1)
       -> Index Scan using patients_pkey on patients p  (actual rows=1.00 loops=9850)
```

---

## 4) Cập nhật thống kê (`CREATE STATISTICS st_q2_enc_class_reason (mcv) ON encounterclass, reasoncode FROM encounters`)
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **130.727** |
| **Khoảng dao động kết quả đo min - max** | **124.015 – 161.587 ms** |
| **S** | **1.527** |
| **ΔT%** | **+34.49%** *(giảm 34.49% thời gian thực thi)* |
| **E%** | **99.99%** tại nút gốc `Sort/Join`; **nhưng tại `encounters` sai số giảm từ 65.24% xuống ~0.2%** (ước lượng `49,591` dòng/worker khớp với thực tế 119,290 dòng). |
| **ΔD (MB)** | **0 MB** |
| **P/S** | **N/A** ($\Delta D = 0$) |
| **Kế hoạch có đổi không** | **Có** (đổi chiều dựng bảng băm của `Parallel Hash Join`: dựng `Parallel Hash` trên bảng nhỏ `conditions` ~38,110 dòng thay vì bảng lớn `encounters` ~119,290 dòng, và tăng lên 2 workers). |

+ **Cây kế hoạch PostgreSQL sau cập nhật thống kê (`EXPLAIN (ANALYZE, BUFFERS)` - Run 1, Execution Time: 117.519 ms):**
```text
Sort  (cost=28856.74..28856.74 rows=1 width=174) (actual time=115.430..117.067 rows=9850.00 loops=1)
  -> Nested Loop  (actual time=18.432..107.513 rows=9850.00 loops=1)
       -> Gather  (Workers Planned: 2, Workers Launched: 2) (actual time=18.384..67.180 rows=9850.00 loops=1)
            -> Parallel Hash Join  (actual time=7.477..60.660 rows=3283.33 loops=3)
                 -> Parallel Seq Scan on encounters e  (rows=49591) (actual rows=39763.33 loops=3)
                 -> Parallel Hash  (rows=22502) (actual rows=12703.33 loops=3)
                      -> Parallel Seq Scan on conditions c  (rows=22502) (actual rows=38110.00 loops=1) [Filter: stop IS NULL]
       -> Index Scan using patients_pkey on patients p  (actual rows=1.00 loops=9850)
```

---

## 5) Thiết kế tổng hợp
- **Tổ hợp sử dụng:** Chỉ mục (`idx_q2_enc_class_reason`, `idx_q2_cond_active`) + Thống kê đa cột (`st_q2_enc_class_reason (mcv)`) + Viết lại truy vấn (`e.reasoncode > ''`).
- **Kết quả trên PostgreSQL:**

| Chỉ số | Giá trị |
| --- | --- |
| **T_med (ms)** | **191.720** |
| **Khoảng dao động kết quả đo min - max** | **182.180 – 214.170 ms** |
| **S** | **1.041** |
| **ΔT%** | **+3.93%** |
| **E%** | **99.99%** *(tại nút `encounters`: ~0.9% — `Bitmap Index Scan` ước lượng 118,219 vs thực tế 119,290)* |
| **ΔD (MB)** | **7.01 MB** |
| **Kế hoạch có đổi không** | **Có** (dùng `Parallel Bitmap Heap Scan` + `Bitmap Index Scan on idx_q2_enc_class_reason` với cả 2 điều kiện, `Parallel Hash` dựng trên `encounters` như phương án Chỉ mục). |

---

## 6) So sánh với MySQL

### Bảng tổng hợp 1: So sánh nhanh

| Phương án | Speedup PG | Speedup MySQL | E% PG | E% MySQL | Kế hoạch đổi (PG / MySQL) |
| --- | --- | --- | --- | --- | --- |
| **(i) Viết lại** | **0.813** | **0.657** | 99.99% | 95.84% | Không / Không |
| **(ii) Chỉ mục** *(baseline / rewrite)* | **0.861 / 0.954** | **1.297 / 1.105** | 99.99% | 78.88% | Có / Có |
| **(iii) Thống kê** | **1.527** | **0.896** | 99.99% *(encounters: ~0.2%)* | 80.79% | Có / Không |
| **Tổ hợp** | **1.041** | **1.325** | 99.99% *(encounters: ~0.9%)* | 78.90% | Có / Có |

### Bảng tổng hợp 2: Chi tiết các chỉ số

| Phương án | DBMS | T_med (ms) | S | ΔT% | E% | ΔD (MB) |
| --- | --- | --- | --- | --- | --- | --- |
| **Baseline** | PostgreSQL | 199.556 | 1.000 | 0.00% | 99.99% | 0.00 |
| **Baseline** | MySQL | 3859.067 | 1.000 | 0.00% | 95.84% | 0.00 |
| **Viết lại** | PostgreSQL | 245.539 | 0.813 | -23.04% | 99.99% | 0.00 |
| **Viết lại** | MySQL | 5871.706 | 0.657 | -52.15% | 95.84% | 0.00 |
| **Chỉ mục** *(baseline SQL)* | PostgreSQL | 231.742 | 0.861 | -16.13% | 99.99% | 7.01 |
| **Chỉ mục** *(rewrite SQL)* | PostgreSQL | 209.114 | 0.954 | -4.79% | 99.99% | 7.01 |
| **Chỉ mục** *(baseline SQL)* | MySQL | 2975.173 | 1.297 | +22.90% | 78.88% | 39.14 |
| **Chỉ mục** *(rewrite SQL)* | MySQL | 3493.554 | 1.105 | +9.47% | 78.88% | 39.14 |
| **Thống kê** | PostgreSQL | 130.727 | 1.527 | +34.49% | 99.99% | 0.00 |
| **Thống kê** | MySQL | 4308.369 | 0.896 | -11.64% | 80.79% | 0.00 |
| **Tổ hợp** | PostgreSQL | 191.720 | 1.041 | +3.93% | 99.99% | 7.01 |
| **Tổ hợp** | MySQL | 2913.209 | 1.325 | +24.51% | 78.90% | 39.14 |

### Kế hoạch truy vấn của MySQL trong những trường hợp có thay đổi
- **Chỉ mục (`idx_q2_cond_stop_enc`) & Tổ hợp trên MySQL:** Thay vì `Table scan on conditions` (quét 83,760 dòng), MySQL chuyển sang dùng **`Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL)`** với *index condition* (`stop is null and encounter is not null`), giúp giảm chi phí ước lượng từ `8395` xuống `4760` và giảm thời gian thực thi từ `3859 ms` xuống `~2913–2975 ms`. Tuy nhiên, `idx_q2_enc_class_reason` không được chọn vì MySQL xuất phát từ bảng `conditions` rồi tra cứu `encounters` qua `PRIMARY (id = c.encounter)`.
```text
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3260..3265 rows=9850 loops=1)
    -> Stream results  (cost=33781 rows=2078) (actual time=0.304..3202 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33781 rows=2078) (actual time=0.295..3134 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33054 rows=2078) (actual time=0.284..2988 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4756 rows=41552) (actual time=0.0237..394 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4756 rows=41552) (actual time=0.0227..382 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.581 rows=0.05) (actual time=0.0676..0.0676 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.581 rows=1) (actual time=0.0658..0.0659 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.014..0.0141 rows=1 loops=9850)
```
