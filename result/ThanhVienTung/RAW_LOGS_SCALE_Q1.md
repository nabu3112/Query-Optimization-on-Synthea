# RAW LOGS TẤT CẢ CÁC LẦN CHẠY Q1 TRÊN DỮ LIỆU SCALE 10X THUẦN (synthea_scale)

## 0. Phiên bản Hệ quản trị CSDL & Thông số môi trường
```text
version                                 
-------------------------------------------------------------------------
 PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35229, 64-bit
(1 row)

VERSION()
9.4.0
```

### Thông số môi trường & Dung lượng D0 (patients, encounters, conditions, observations)
```text
work_mem 
----------
 4MB
(1 row)

 shared_buffers 
----------------
 128MB
(1 row)

 effective_cache_size 
----------------------
 4GB
(1 row)

 max_parallel_workers_per_gather 
---------------------------------
 2
(1 row)

  table_name  | est_rows | total_bytes | total_size 
--------------+----------+-------------+------------
 conditions   |    83760 |    12746752 | 12 MB
 encounters   |   533460 |   209928192 | 200 MB
 observations |  2999426 |   490504192 | 468 MB
 patients     |    11710 |     4161536 | 4064 kB
(4 rows)

 d0_bytes  | d0_mb  
-----------+--------
 717340672 | 684.11
(1 row)

sort_buffer_size	join_buffer_size	innodb_buffer_pool_size	tmp_table_size
262144	262144	134217728	154140672
TABLE_NAME	TABLE_ROWS	total_bytes	total_mb
conditions	83183	13123584	12.52
encounters	510483	176160768	168.00
observations	2871019	498073600	475.00
patients	11592	3686400	3.52
d0_bytes	d0_mb
691044352	659.03
```

### Kiểm tra tương đương kết quả (Equivalence Check)
```text
-- PostgreSQL
n_baseline | n_rewrite 
------------+-----------
      12910 |     12910
(1 row)

-- MySQL
n_baseline	n_rewrite
12910	12910
```

## 1. Q1 Baseline

### PG Baseline Timing (5 runs after 1 warm-up): [607.5, 708.618, 893.784, 934.667, 881.505] | median=881.505 ms
```text
Timing is on.
Time: 873,790 ms
Time: 607,500 ms
Time: 708,618 ms
Time: 893,784 ms
Time: 934,667 ms
Time: 881,505 ms
```

### PG Baseline EXPLAIN Run 1:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=108010.68..108010.68 rows=2 width=211) (actual time=577.347..578.766 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=54194 read=67722
   I/O Timings: shared read=284.269
   ->  Gather  (cost=105596.22..108010.67 rows=2 width=211) (actual time=534.453..547.440 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=54188 read=67722
         I/O Timings: shared read=284.269
         ->  Parallel Hash Right Join  (cost=104596.22..107010.47 rows=1 width=211) (actual time=451.047..461.011 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=54188 read=67722
               I/O Timings: shared read=284.269
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.007..2.154 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104596.20..104596.20 rows=1 width=164) (actual time=450.913..450.917 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52633 read=67722
                     I/O Timings: shared read=284.269
                     ->  Nested Loop  (cost=25680.69..104596.20 rows=1 width=164) (actual time=72.545..440.508 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52633 read=67722
                           I/O Timings: shared read=284.269
                           ->  Parallel Hash Join  (cost=25680.40..104595.26 rows=3 width=180) (actual time=72.503..416.652 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13902 read=67722
                                 I/O Timings: shared read=284.269
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=117) (actual time=0.641..190.343 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3205 read=56651
                                       I/O Timings: shared read=247.458
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=68.638..68.639 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=10697 read=11071
                                       I/O Timings: shared read=36.811
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1506 width=100) (actual time=1.582..134.649 rows=3840.00 loops=1)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 529620
                                             Buffers: shared hit=10697 read=11071
                                             I/O Timings: shared read=36.811
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.003..0.003 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=308 read=44
   I/O Timings: shared read=5.456
 Planning Time: 9.842 ms
 Execution Time: 579.907 ms
(49 rows)
```

### PG Baseline EXPLAIN Run 2:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=108010.68..108010.68 rows=2 width=211) (actual time=550.904..552.356 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=54105 read=67811
   I/O Timings: shared read=355.644
   ->  Gather  (cost=105596.22..108010.67 rows=2 width=211) (actual time=506.854..520.481 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=54099 read=67811
         I/O Timings: shared read=355.644
         ->  Parallel Hash Right Join  (cost=104596.22..107010.47 rows=1 width=211) (actual time=472.085..482.707 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=54099 read=67811
               I/O Timings: shared read=355.644
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.007..2.356 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104596.20..104596.20 rows=1 width=164) (actual time=471.915..471.919 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52544 read=67811
                     I/O Timings: shared read=355.644
                     ->  Nested Loop  (cost=25680.69..104596.20 rows=1 width=164) (actual time=90.084..463.340 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52544 read=67811
                           I/O Timings: shared read=355.644
                           ->  Parallel Hash Join  (cost=25680.40..104595.26 rows=3 width=180) (actual time=90.048..440.406 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13813 read=67811
                                 I/O Timings: shared read=355.644
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=117) (actual time=0.815..202.487 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3205 read=56651
                                       I/O Timings: shared read=278.169
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=87.363..87.364 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=10608 read=11160
                                       I/O Timings: shared read=77.475
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1506 width=100) (actual time=1.612..86.095 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=10608 read=11160
                                             I/O Timings: shared read=77.475
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.003..0.003 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=352
 Planning Time: 3.810 ms
 Execution Time: 553.023 ms
(48 rows)
```

### PG Baseline EXPLAIN Run 3:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=108010.68..108010.68 rows=2 width=211) (actual time=636.672..638.228 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=54105 read=67811
   I/O Timings: shared read=401.726
   ->  Gather  (cost=105596.22..108010.67 rows=2 width=211) (actual time=583.893..602.188 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=54099 read=67811
         I/O Timings: shared read=401.726
         ->  Parallel Hash Right Join  (cost=104596.22..107010.47 rows=1 width=211) (actual time=548.238..562.040 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=54099 read=67811
               I/O Timings: shared read=401.726
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.012..3.057 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104596.20..104596.20 rows=1 width=164) (actual time=548.033..548.037 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52544 read=67811
                     I/O Timings: shared read=401.726
                     ->  Nested Loop  (cost=25680.69..104596.20 rows=1 width=164) (actual time=80.939..535.246 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52544 read=67811
                           I/O Timings: shared read=401.726
                           ->  Parallel Hash Join  (cost=25680.40..104595.26 rows=3 width=180) (actual time=80.898..506.427 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13813 read=67811
                                 I/O Timings: shared read=401.726
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=117) (actual time=0.780..244.083 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3205 read=56651
                                       I/O Timings: shared read=332.094
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=78.586..78.587 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=10608 read=11160
                                       I/O Timings: shared read=69.632
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1506 width=100) (actual time=1.985..77.336 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=10608 read=11160
                                             I/O Timings: shared read=69.632
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=352
 Planning Time: 4.586 ms
 Execution Time: 638.887 ms
(48 rows)
```

### PG Baseline EXPLAIN Run 4:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=108010.68..108010.68 rows=2 width=211) (actual time=524.884..526.238 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=54105 read=67811
   I/O Timings: shared read=290.947
   ->  Gather  (cost=105596.22..108010.67 rows=2 width=211) (actual time=482.019..495.138 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=54099 read=67811
         I/O Timings: shared read=290.947
         ->  Parallel Hash Right Join  (cost=104596.22..107010.47 rows=1 width=211) (actual time=445.668..455.929 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=54099 read=67811
               I/O Timings: shared read=290.947
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.003..2.245 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104596.20..104596.20 rows=1 width=164) (actual time=445.560..445.565 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52544 read=67811
                     I/O Timings: shared read=290.947
                     ->  Nested Loop  (cost=25680.69..104596.20 rows=1 width=164) (actual time=99.469..432.624 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52544 read=67811
                           I/O Timings: shared read=290.947
                           ->  Parallel Hash Join  (cost=25680.40..104595.26 rows=3 width=180) (actual time=99.427..409.464 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13813 read=67811
                                 I/O Timings: shared read=290.947
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=117) (actual time=1.459..158.305 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3205 read=56651
                                       I/O Timings: shared read=187.115
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=96.719..96.720 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=10608 read=11160
                                       I/O Timings: shared read=103.833
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1506 width=100) (actual time=2.285..95.497 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=10608 read=11160
                                             I/O Timings: shared read=103.833
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.003..0.003 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=352
 Planning Time: 4.488 ms
 Execution Time: 526.937 ms
(48 rows)
```

### PG Baseline EXPLAIN Run 5:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=108010.68..108010.68 rows=2 width=211) (actual time=584.290..585.793 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=54199 read=67717
   I/O Timings: shared read=302.998
   ->  Gather  (cost=105596.22..108010.67 rows=2 width=211) (actual time=539.042..553.824 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=54193 read=67717
         I/O Timings: shared read=302.998
         ->  Parallel Hash Right Join  (cost=104596.22..107010.47 rows=1 width=211) (actual time=463.643..474.372 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=54193 read=67717
               I/O Timings: shared read=302.998
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.003..2.362 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104596.20..104596.20 rows=1 width=164) (actual time=463.547..463.552 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52638 read=67717
                     I/O Timings: shared read=302.998
                     ->  Nested Loop  (cost=25680.69..104596.20 rows=1 width=164) (actual time=76.258..447.773 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52638 read=67717
                           I/O Timings: shared read=302.998
                           ->  Parallel Hash Join  (cost=25680.40..104595.26 rows=3 width=180) (actual time=76.223..423.719 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13907 read=67717
                                 I/O Timings: shared read=302.998
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=117) (actual time=1.087..188.378 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3205 read=56651
                                       I/O Timings: shared read=239.255
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=72.107..72.108 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=10702 read=11066
                                       I/O Timings: shared read=63.743
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1506 width=100) (actual time=0.789..142.294 rows=3840.00 loops=1)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 529620
                                             Buffers: shared hit=10702 read=11066
                                             I/O Timings: shared read=63.743
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.003..0.003 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=352
 Planning Time: 3.732 ms
 Execution Time: 586.503 ms
(48 rows)
```

### MySQL Baseline Timing (5 runs after 1 warm-up): [52489.294, 50189.267, 51854.044, 50491.679, 52276.877] | median=51854.044 ms
```text
TIMING_MS=52024.027
TIMING_MS=52489.294
TIMING_MS=50189.267
TIMING_MS=51854.044
TIMING_MS=50491.679
TIMING_MS=52276.877
```

### MySQL Baseline EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=55050..55058 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=909..54973 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=909..54923 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=96.8..53623 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=96.3..53240 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=317502 rows=2.87e+6) (actual time=2.62..9880 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=2.61..8723 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0158..0.0158 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.014..0.0141 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.029..0.0291 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83183) (actual time=0.897..317 rows=83760 loops=1)
```

### MySQL Baseline EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=52873..52882 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=945..52793 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=945..52740 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=104..51404 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=104..51071 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=317502 rows=2.87e+6) (actual time=1.62..9290 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=1.61..8291 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0153..0.0153 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0135..0.0136 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0253..0.0253 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83183) (actual time=1.06..315 rows=83760 loops=1)
```

### MySQL Baseline EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=55410..55420 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=943..55321 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=943..55265 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.14e+6 rows=143551) (actual time=86.5..53869 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2e+6 rows=143551) (actual time=86..53497 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=317502 rows=2.87e+6) (actual time=1.68..9544 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=1.67..8453 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.485 rows=0.05) (actual time=0.0161..0.0161 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.485 rows=1) (actual time=0.0142..0.0143 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0283..0.0284 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83183) (actual time=1.28..328 rows=83760 loops=1)
```

### MySQL Baseline EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=52435..52444 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=959..52350 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=959..52289 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=93.7..50824 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=92.3..50493 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=317502 rows=2.87e+6) (actual time=1.87..9082 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=1.87..8107 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0151..0.0151 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0134..0.0135 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.927 rows=1) (actual time=0.0251..0.0252 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83183) (actual time=1.17..324 rows=83760 loops=1)
```

### MySQL Baseline EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=55011..55021 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=964..54928 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=964..54873 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=94..53500 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=93.4..53146 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=317502 rows=2.87e+6) (actual time=1.61..9782 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=1.61..8707 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0158..0.0158 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.014..0.0141 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0268..0.0269 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83183) (actual time=1.24..325 rows=83760 loops=1)
```

## 2. Q1 Rewrite (02a)

### PG Rewrite Timing (5 runs after 1 warm-up): [737.428, 507.477, 570.602, 755.975, 656.178] | median=656.178 ms
```text
Timing is on.
Time: 689,872 ms
Time: 737,428 ms
Time: 507,477 ms
Time: 570,602 ms
Time: 755,975 ms
Time: 656,178 ms
```

### PG Rewrite EXPLAIN Run 1:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106257.74..108573.62 rows=20320 width=211) (actual time=506.258..513.200 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=16239 read=67789
   I/O Timings: shared read=420.076
   ->  Sort  (cost=105257.73..105287.61 rows=11953 width=211) (actual time=471.011..471.282 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3000kB
         Buffers: shared hit=16239 read=67789
         I/O Timings: shared read=420.076
         Worker 0:  Sort Method: quicksort  Memory: 148kB
         ->  Parallel Hash Right Join  (cost=102119.44..104448.20 rows=11953 width=211) (actual time=447.887..456.736 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=16224 read=67789
               I/O Timings: shared read=420.076
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.003..2.120 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=102013.60..102013.60 rows=8467 width=164) (actual time=447.756..447.760 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=14669 read=67789
                     I/O Timings: shared read=420.076
                     ->  Hash Join  (cost=26357.11..102013.60 rows=8467 width=164) (actual time=86.812..444.962 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14669 read=67789
                           I/O Timings: shared read=420.076
                           ->  Parallel Hash Join  (cost=25676.64..101310.89 rows=8467 width=143) (actual time=82.465..439.192 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13835 read=67789
                                 I/O Timings: shared read=420.076
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=80) (actual time=0.999..234.810 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3214 read=56642
                                       I/O Timings: shared read=336.901
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=78.346..78.346 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=10621 read=11147
                                       I/O Timings: shared read=83.174
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1506 width=100) (actual time=2.230..77.464 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=10621 read=11147
                                             I/O Timings: shared read=83.174
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.304..4.304 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.265..2.462 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=282 read=38
   I/O Timings: shared read=4.107
 Planning Time: 7.910 ms
 Execution Time: 514.038 ms
(51 rows)
```

### PG Rewrite EXPLAIN Run 2:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106257.74..108573.62 rows=20320 width=211) (actual time=654.563..661.713 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=16333 read=67695
   I/O Timings: shared read=541.298
   ->  Sort  (cost=105257.73..105287.61 rows=11953 width=211) (actual time=559.781..560.138 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3005kB
         Buffers: shared hit=16333 read=67695
         I/O Timings: shared read=541.298
         Worker 0:  Sort Method: quicksort  Memory: 143kB
         ->  Parallel Hash Right Join  (cost=102119.44..104448.20 rows=11953 width=211) (actual time=534.155..543.892 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=16318 read=67695
               I/O Timings: shared read=541.298
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.004..2.358 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=102013.60..102013.60 rows=8467 width=164) (actual time=534.025..534.029 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=14763 read=67695
                     I/O Timings: shared read=541.298
                     ->  Hash Join  (cost=26357.11..102013.60 rows=8467 width=164) (actual time=74.349..530.817 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14763 read=67695
                           I/O Timings: shared read=541.298
                           ->  Parallel Hash Join  (cost=25676.64..101310.89 rows=8467 width=143) (actual time=70.246..525.088 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13929 read=67695
                                 I/O Timings: shared read=541.298
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=80) (actual time=0.567..315.414 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3214 read=56642
                                       I/O Timings: shared read=478.486
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=67.318..67.319 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=10715 read=11053
                                       I/O Timings: shared read=62.813
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1506 width=100) (actual time=1.355..133.049 rows=3840.00 loops=1)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 529620
                                             Buffers: shared hit=10715 read=11053
                                             I/O Timings: shared read=62.813
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.060..4.061 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.284..2.359 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=320
 Planning Time: 3.483 ms
 Execution Time: 662.499 ms
(50 rows)
```

### PG Rewrite EXPLAIN Run 3:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106257.74..108573.62 rows=20320 width=211) (actual time=606.084..613.293 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=16239 read=67789
   I/O Timings: shared read=532.436
   ->  Sort  (cost=105257.73..105287.61 rows=11953 width=211) (actual time=557.774..558.113 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3011kB
         Buffers: shared hit=16239 read=67789
         I/O Timings: shared read=532.436
         Worker 0:  Sort Method: quicksort  Memory: 137kB
         ->  Parallel Hash Right Join  (cost=102119.44..104448.20 rows=11953 width=211) (actual time=533.499..542.986 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=16224 read=67789
               I/O Timings: shared read=532.436
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.005..2.286 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=102013.60..102013.60 rows=8467 width=164) (actual time=533.339..533.343 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=14669 read=67789
                     I/O Timings: shared read=532.436
                     ->  Hash Join  (cost=26357.11..102013.60 rows=8467 width=164) (actual time=123.031..530.002 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14669 read=67789
                           I/O Timings: shared read=532.436
                           ->  Parallel Hash Join  (cost=25676.64..101310.89 rows=8467 width=143) (actual time=116.931..522.282 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13835 read=67789
                                 I/O Timings: shared read=532.436
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=80) (actual time=1.400..269.715 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3214 read=56642
                                       I/O Timings: shared read=390.723
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=113.475..113.475 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=10621 read=11147
                                       I/O Timings: shared read=141.714
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1506 width=100) (actual time=2.740..112.309 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=10621 read=11147
                                             I/O Timings: shared read=141.714
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=6.058..6.059 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=1.740..4.061 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=320
 Planning Time: 4.978 ms
 Execution Time: 614.212 ms
(50 rows)
```

### PG Rewrite EXPLAIN Run 4:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106257.74..108573.62 rows=20320 width=211) (actual time=703.076..709.657 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=16391 read=67637
   I/O Timings: shared read=709.716
   ->  Sort  (cost=105257.73..105287.61 rows=11953 width=211) (actual time=616.271..616.539 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 2986kB
         Buffers: shared hit=16391 read=67637
         I/O Timings: shared read=709.716
         Worker 0:  Sort Method: quicksort  Memory: 162kB
         ->  Parallel Hash Right Join  (cost=102119.44..104448.20 rows=11953 width=211) (actual time=592.671..601.521 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=16376 read=67637
               I/O Timings: shared read=709.716
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.003..2.123 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=102013.60..102013.60 rows=8467 width=164) (actual time=592.527..592.531 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=14821 read=67637
                     I/O Timings: shared read=709.716
                     ->  Hash Join  (cost=26357.11..102013.60 rows=8467 width=164) (actual time=77.526..589.926 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14821 read=67637
                           I/O Timings: shared read=709.716
                           ->  Parallel Hash Join  (cost=25676.64..101310.89 rows=8467 width=143) (actual time=73.434..584.380 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13987 read=67637
                                 I/O Timings: shared read=709.716
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=80) (actual time=1.737..388.951 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3272 read=56584
                                       I/O Timings: shared read=643.721
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=68.735..68.736 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=10715 read=11053
                                       I/O Timings: shared read=65.995
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1506 width=100) (actual time=1.159..135.720 rows=3840.00 loops=1)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 529620
                                             Buffers: shared hit=10715 read=11053
                                             I/O Timings: shared read=65.995
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.054..4.055 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.213..2.307 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=320
 Planning Time: 3.964 ms
 Execution Time: 710.453 ms
(50 rows)
```

### PG Rewrite EXPLAIN Run 5:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106257.74..108573.62 rows=20320 width=211) (actual time=513.730..524.465 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=16379 read=67649
   I/O Timings: shared read=410.657
   ->  Sort  (cost=105257.73..105287.61 rows=11953 width=211) (actual time=475.814..476.099 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 156kB
         Buffers: shared hit=16379 read=67649
         I/O Timings: shared read=410.657
         Worker 0:  Sort Method: quicksort  Memory: 2991kB
         ->  Parallel Hash Right Join  (cost=102119.44..104448.20 rows=11953 width=211) (actual time=451.623..460.906 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=16364 read=67649
               I/O Timings: shared read=410.657
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.003..2.231 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=102013.60..102013.60 rows=8467 width=164) (actual time=451.500..451.504 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=14809 read=67649
                     I/O Timings: shared read=410.657
                     ->  Hash Join  (cost=26357.11..102013.60 rows=8467 width=164) (actual time=87.302..448.585 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14809 read=67649
                           I/O Timings: shared read=410.657
                           ->  Parallel Hash Join  (cost=25676.64..101310.89 rows=8467 width=143) (actual time=82.428..442.200 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13975 read=67649
                                 I/O Timings: shared read=410.657
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72353.61 rows=1249761 width=80) (actual time=1.120..230.810 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3412 read=56444
                                       I/O Timings: shared read=321.558
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1506 width=100) (actual time=79.322..79.323 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=10563 read=11205
                                       I/O Timings: shared read=89.099
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1506 width=100) (actual time=1.908..78.515 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=10563 read=11205
                                             I/O Timings: shared read=89.099
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.829..4.829 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=1.060..3.089 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=320
 Planning Time: 3.921 ms
 Execution Time: 525.063 ms
(50 rows)
```

### MySQL Rewrite Timing (5 runs after 1 warm-up): [45832.935, 45409.274, 45901.319, 63113.702, 66892.294] | median=45901.319 ms
```text
TIMING_MS=47334.231
TIMING_MS=45832.935
TIMING_MS=45409.274
TIMING_MS=45901.319
TIMING_MS=63113.702
TIMING_MS=66892.294
```

### MySQL Rewrite EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=50825..50834 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=803..50743 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=803..50687 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=105..49565 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=104..49235 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=317502 rows=2.87e+6) (actual time=4.33..9060 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=4.33..8383 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.0147..0.0147 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0137..0.0138 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.927 rows=1) (actual time=0.025..0.0251 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83183) (actual time=1.09..298 rows=83760 loops=1)
```

### MySQL Rewrite EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=59699..59711 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=727..59608 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=727..59546 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.14e+6 rows=143551) (actual time=97.7..58426 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.99e+6 rows=143551) (actual time=97.1..58061 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=317502 rows=2.87e+6) (actual time=1.37..12896 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=1.37..11895 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.483 rows=0.05) (actual time=0.0164..0.0164 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.483 rows=1) (actual time=0.015..0.0151 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.923 rows=1) (actual time=0.0277..0.0277 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83183) (actual time=1.03..259 rows=83760 loops=1)
```

### MySQL Rewrite EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=61549..61559 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=751..61468 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=751..61409 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=82.9..60268 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=82.4..59883 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=317502 rows=2.87e+6) (actual time=2.26..13460 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=2.26..12294 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.0169..0.0169 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0154..0.0155 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.923 rows=1) (actual time=0.0291..0.0292 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83183) (actual time=0.999..290 rows=83760 loops=1)
```

### MySQL Rewrite EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=63863..63874 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=876..63766 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=876..63705 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=103..62439 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=103..62037 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=317502 rows=2.87e+6) (actual time=2.47..13278 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=2.47..12239 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.0178..0.0178 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0163..0.0164 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.927 rows=1) (actual time=0.0303..0.0304 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83183) (actual time=0.972..320 rows=83760 loops=1)
```

### MySQL Rewrite EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=64824..64835 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=868..64738 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=868..64681 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.13e+6 rows=143551) (actual time=116..63438 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.98e+6 rows=143551) (actual time=116..63035 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=317502 rows=2.87e+6) (actual time=2.39..13515 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317502 rows=2.87e+6) (actual time=2.39..12488 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.018..0.018 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0166..0.0167 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.927 rows=1) (actual time=0.0305..0.0305 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83183) (actual time=1.39..327 rows=83760 loops=1)
```

## 3. Q1 Indexes (no ANALYZE)

### PG Index Setup & Sizes
```text
Timing is on.
CREATE INDEX
Time: 1458,451 ms (00:01,458)
CREATE INDEX
Time: 17846,531 ms (00:17,847)
CREATE INDEX
Time: 1531,260 ms (00:01,531)
       index_name        |  size   
-------------------------+---------
 idx_q1_enc_class_start  | 67 MB
 idx_q1_obs_enc_patient  | 40 MB
 idx_q1_cond_enc_patient | 7936 kB
(3 rows)

Time: 43,730 ms

indexname        | size_bytes |  size   
-------------------------+------------+---------
 idx_q1_cond_enc_patient |    8126464 | 7936 kB
 idx_q1_enc_class_start  |   70287360 | 67 MB
 idx_q1_obs_enc_patient  |   42246144 | 40 MB
(3 rows)

 delta_d_bytes | delta_d_mb 
---------------+------------
     120659968 |     115.07
(1 row)
```

### PG Index Timing (5 runs after 1 warm-up): [170.024, 155.329, 148.956, 132.886, 137.916] | median=148.956 ms

### PG Index EXPLAIN Run 1:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=21745.66..21745.67 rows=2 width=211) (actual time=196.870..197.819 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93859
   ->  Gather  (cost=1283.76..21745.65 rows=2 width=211) (actual time=1.922..162.362 rows=12910.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=93853
         ->  Nested Loop Left Join  (cost=283.76..20745.45 rows=1 width=211) (actual time=1.216..71.297 rows=4303.33 loops=3)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93853
               ->  Nested Loop  (cost=283.34..20742.19 rows=1 width=164) (actual time=1.179..42.820 rows=4303.33 loops=3)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=54019
                     ->  Nested Loop  (cost=283.06..20741.24 rows=3 width=180) (actual time=1.162..20.381 rows=4303.33 loops=3)
                           Buffers: shared hit=15288
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=282.63..9737.34 rows=1506 width=100) (actual time=1.103..3.640 rows=1280.00 loops=3)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1374
                                 Buffers: shared hit=2178
                                 Worker 0:  Heap Blocks: exact=699
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..281.73 rows=3614 width=0) (actual time=0.768..0.769 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.30 rows=1 width=117) (actual time=0.011..0.012 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13110
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.005..0.005 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38731
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.25 rows=1 width=108) (actual time=0.006..0.006 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39831
 Planning:
   Buffers: shared hit=429
 Planning Time: 17.479 ms
 Execution Time: 198.472 ms
(41 rows)
```

### PG Index EXPLAIN Run 2:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=21745.66..21745.67 rows=2 width=211) (actual time=149.820..150.809 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93865
   ->  Gather  (cost=1283.76..21745.65 rows=2 width=211) (actual time=1.570..112.595 rows=12910.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=93859
         ->  Nested Loop Left Join  (cost=283.76..20745.45 rows=1 width=211) (actual time=1.226..64.677 rows=4303.33 loops=3)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93859
               ->  Nested Loop  (cost=283.34..20742.19 rows=1 width=164) (actual time=1.187..38.720 rows=4303.33 loops=3)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=54021
                     ->  Nested Loop  (cost=283.06..20741.24 rows=3 width=180) (actual time=1.161..18.231 rows=4303.33 loops=3)
                           Buffers: shared hit=15289
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=282.63..9737.34 rows=1506 width=100) (actual time=1.052..3.089 rows=1280.00 loops=3)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1312
                                 Buffers: shared hit=2178
                                 Worker 0:  Heap Blocks: exact=395
                                 Worker 1:  Heap Blocks: exact=366
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..281.73 rows=3614 width=0) (actual time=0.575..0.575 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.30 rows=1 width=117) (actual time=0.010..0.011 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13111
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38732
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.25 rows=1 width=108) (actual time=0.005..0.006 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39832
 Planning:
   Buffers: shared hit=429
 Planning Time: 10.332 ms
 Execution Time: 151.954 ms
(42 rows)
```

### PG Index EXPLAIN Run 3:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=21745.66..21745.67 rows=2 width=211) (actual time=149.271..150.359 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93865
   ->  Gather  (cost=1283.76..21745.65 rows=2 width=211) (actual time=3.569..113.883 rows=12910.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=93859
         ->  Nested Loop Left Join  (cost=283.76..20745.45 rows=1 width=211) (actual time=1.989..70.456 rows=4303.33 loops=3)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93859
               ->  Nested Loop  (cost=283.34..20742.19 rows=1 width=164) (actual time=1.924..42.232 rows=4303.33 loops=3)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=54021
                     ->  Nested Loop  (cost=283.06..20741.24 rows=3 width=180) (actual time=1.872..19.927 rows=4303.33 loops=3)
                           Buffers: shared hit=15289
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=282.63..9737.34 rows=1506 width=100) (actual time=1.762..4.012 rows=1280.00 loops=3)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1050
                                 Buffers: shared hit=2178
                                 Worker 0:  Heap Blocks: exact=589
                                 Worker 1:  Heap Blocks: exact=434
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..281.73 rows=3614 width=0) (actual time=1.374..1.375 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.30 rows=1 width=117) (actual time=0.011..0.011 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13111
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.005..0.005 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38732
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.25 rows=1 width=108) (actual time=0.006..0.006 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39832
 Planning:
   Buffers: shared hit=429
 Planning Time: 13.391 ms
 Execution Time: 151.113 ms
(42 rows)
```

### PG Index EXPLAIN Run 4:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=21745.66..21745.67 rows=2 width=211) (actual time=181.283..182.144 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93859
   ->  Gather  (cost=1283.76..21745.65 rows=2 width=211) (actual time=1.364..144.252 rows=12910.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=93853
         ->  Nested Loop Left Join  (cost=283.76..20745.45 rows=1 width=211) (actual time=1.305..59.062 rows=4303.33 loops=3)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93853
               ->  Nested Loop  (cost=283.34..20742.19 rows=1 width=164) (actual time=1.278..35.526 rows=4303.33 loops=3)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=54019
                     ->  Nested Loop  (cost=283.06..20741.24 rows=3 width=180) (actual time=1.257..16.655 rows=4303.33 loops=3)
                           Buffers: shared hit=15288
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=282.63..9737.34 rows=1506 width=100) (actual time=1.199..3.179 rows=1280.00 loops=3)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1380
                                 Buffers: shared hit=2178
                                 Worker 0:  Heap Blocks: exact=693
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..281.73 rows=3614 width=0) (actual time=0.560..0.560 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.30 rows=1 width=117) (actual time=0.009..0.010 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13110
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38731
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.25 rows=1 width=108) (actual time=0.005..0.005 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39831
 Planning:
   Buffers: shared hit=429
 Planning Time: 6.430 ms
 Execution Time: 182.697 ms
(41 rows)
```

### PG Index EXPLAIN Run 5:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=21745.66..21745.67 rows=2 width=211) (actual time=154.460..156.253 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93865
   ->  Gather  (cost=1283.76..21745.65 rows=2 width=211) (actual time=1.404..116.805 rows=12910.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=93859
         ->  Nested Loop Left Join  (cost=283.76..20745.45 rows=1 width=211) (actual time=1.332..68.579 rows=4303.33 loops=3)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93859
               ->  Nested Loop  (cost=283.34..20742.19 rows=1 width=164) (actual time=1.289..40.891 rows=4303.33 loops=3)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=54021
                     ->  Nested Loop  (cost=283.06..20741.24 rows=3 width=180) (actual time=1.263..19.137 rows=4303.33 loops=3)
                           Buffers: shared hit=15289
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=282.63..9737.34 rows=1506 width=100) (actual time=1.150..3.420 rows=1280.00 loops=3)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1084
                                 Buffers: shared hit=2178
                                 Worker 0:  Heap Blocks: exact=478
                                 Worker 1:  Heap Blocks: exact=511
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..281.73 rows=3614 width=0) (actual time=0.530..0.530 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.30 rows=1 width=117) (actual time=0.011..0.011 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13111
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.005..0.005 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38732
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.25 rows=1 width=108) (actual time=0.006..0.006 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39832
 Planning:
   Buffers: shared hit=429
 Planning Time: 6.303 ms
 Execution Time: 156.888 ms
(42 rows)
```

### MySQL Index Setup & Sizes
```text
TABLE_NAME	INDEX_NAME	size_kb
conditions	idx_q1_cond_enc_patient	8768
encounters	idx_q1_enc_class_start	58192
observations	idx_q1_obs_enc_patient	283632

table_name	index_name	size_bytes	size_mb
conditions	idx_q1_cond_enc_patient	8978432	8.56
encounters	idx_q1_enc_class_start	59588608	56.83
observations	idx_q1_obs_enc_patient	290439168	276.98
delta_d_bytes	delta_d_mb
359006208	342.38
```

### MySQL Index Timing (5 runs after 1 warm-up): [4498.85, 4580.788, 4325.02, 4374.922, 4521.91] | median=4498.850 ms

### MySQL Index EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=4050..4061 rows=12910 loops=1)
    -> Stream results  (cost=130781 rows=106857) (actual time=11.4..3952 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130781 rows=106857) (actual time=11.4..3858 rows=12910 loops=1)
            -> Nested loop left join  (cost=13238 rows=8131) (actual time=11.1..2095 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10393 rows=7276) (actual time=11.1..1906 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7819 rows=7276) (actual time=11.1..1789 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.254 rows=1) (actual time=0.0293..0.0294 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.279 rows=1.12) (actual time=0.0451..0.048 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.1 rows=13.1) (actual time=0.387..0.442 rows=3.26 loops=3960)
```

### MySQL Index EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3780..3790 rows=12910 loops=1)
    -> Stream results  (cost=130776 rows=106857) (actual time=23.4..3686 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130776 rows=106857) (actual time=23.4..3598 rows=12910 loops=1)
            -> Nested loop left join  (cost=13234 rows=8131) (actual time=22.9..1946 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10388 rows=7276) (actual time=22.8..1765 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7815 rows=7276) (actual time=22.8..1648 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.254 rows=1) (actual time=0.0294..0.0295 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.279 rows=1.12) (actual time=0.0437..0.0461 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.1 rows=13.1) (actual time=0.353..0.414 rows=3.26 loops=3960)
```

### MySQL Index EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3492..3505 rows=12910 loops=1)
    -> Stream results  (cost=130776 rows=106857) (actual time=20.6..3389 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130776 rows=106857) (actual time=20.5..3292 rows=12910 loops=1)
            -> Nested loop left join  (cost=13234 rows=8131) (actual time=20.2..1780 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10388 rows=7276) (actual time=20.1..1596 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7815 rows=7276) (actual time=20.1..1485 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.254 rows=1) (actual time=0.0277..0.0278 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.279 rows=1.12) (actual time=0.0443..0.0467 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.1 rows=13.1) (actual time=0.327..0.379 rows=3.26 loops=3960)
```

### MySQL Index EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3244..3254 rows=12910 loops=1)
    -> Stream results  (cost=130776 rows=106857) (actual time=20.1..3150 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130776 rows=106857) (actual time=20.1..3059 rows=12910 loops=1)
            -> Nested loop left join  (cost=13234 rows=8131) (actual time=19.7..1680 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10388 rows=7276) (actual time=19.6..1514 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7815 rows=7276) (actual time=19.6..1416 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.254 rows=1) (actual time=0.0245..0.0246 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.279 rows=1.12) (actual time=0.0398..0.0421 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.1 rows=13.1) (actual time=0.294..0.346 rows=3.26 loops=3960)
```

### MySQL Index EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3430..3439 rows=12910 loops=1)
    -> Stream results  (cost=130776 rows=106857) (actual time=18.9..3333 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130776 rows=106857) (actual time=18.8..3239 rows=12910 loops=1)
            -> Nested loop left join  (cost=13234 rows=8131) (actual time=18.4..1758 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10388 rows=7276) (actual time=18.3..1582 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7815 rows=7276) (actual time=18.3..1477 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.254 rows=1) (actual time=0.0258..0.0259 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.279 rows=1.12) (actual time=0.0424..0.0447 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.1 rows=13.1) (actual time=0.321..0.371 rows=3.26 loops=3960)
```

## 4. Q1 Statistics

### PG Stats Setup
```text
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ALTER TABLE
ANALYZE
ANALYZE
ANALYZE
ANALYZE

[STDERR]
psql:<stdin>:12: INFO:  analyzing "public.encounters"
psql:<stdin>:12: INFO:  "encounters": scanned 21768 of 21768 pages, containing 533460 live rows and 0 dead rows; 300000 rows in sample, 533460 estimated total rows
psql:<stdin>:12: INFO:  finished analyzing table "synthea_scale.public.encounters"
avg read rate: 13.330 MB/s, avg write rate: 0.034 MB/s
buffer usage: 6397 hits, 16119 reads, 41 dirtied
WAL usage: 195 records, 26 full page images, 292838 bytes, 0 buffers full
system usage: CPU: user: 8.07 s, system: 0.32 s, elapsed: 9.44 s
psql:<stdin>:13: INFO:  analyzing "public.observations"
psql:<stdin>:13: INFO:  "observations": scanned 59856 of 59856 pages, containing 2996970 live rows and 0 dead rows; 300000 rows in sample, 2996970 estimated total rows
psql:<stdin>:13: INFO:  finished analyzing table "synthea_scale.public.observations"
avg read rate: 27.218 MB/s, avg write rate: 0.015 MB/s
buffer usage: 5187 hits, 55074 reads, 30 dirtied
WAL usage: 184 records, 12 full page images, 233381 bytes, 0 buffers full
system usage: CPU: user: 14.25 s, system: 0.25 s, elapsed: 15.80 s
psql:<stdin>:14: INFO:  analyzing "public.conditions"
psql:<stdin>:14: INFO:  "conditions": scanned 1552 of 1552 pages, containing 83760 live rows and 0 dead rows; 83760 rows in sample, 83760 estimated total rows
psql:<stdin>:14: INFO:  finished analyzing table "synthea_scale.public.conditions"
avg read rate: 0.010 MB/s, avg write rate: 0.075 MB/s
buffer usage: 2007 hits, 4 reads, 29 dirtied
WAL usage: 197 records, 9 full page images, 229605 bytes, 0 buffers full
system usage: CPU: user: 2.76 s, system: 0.04 s, elapsed: 3.02 s
psql:<stdin>:15: INFO:  analyzing "public.patients"
psql:<stdin>:15: INFO:  "patients": scanned 417 of 417 pages, containing 11710 live rows and 0 dead rows; 11710 rows in sample, 11710 estimated total rows
psql:<stdin>:15: INFO:  finished analyzing table "synthea_scale.public.patients"
avg read rate: 0.097 MB/s, avg write rate: 0.145 MB/s
buffer usage: 721 hits, 14 reads, 21 dirtied
WAL usage: 99 records, 19 full page images, 149993 bytes, 0 buffers full
system usage: CPU: user: 1.00 s, system: 0.04 s, elapsed: 1.12 s
```

### PG Stats Timing (5 runs after 1 warm-up): [965.574, 859.451, 1516.555, 1329.607, 1243.836] | median=1243.836 ms

### PG Stats EXPLAIN Run 1:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107994.20..107994.21 rows=2 width=212) (actual time=771.472..772.807 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53529 read=68387
   I/O Timings: shared read=420.427
   ->  Gather  (cost=105579.74..107994.19 rows=2 width=212) (actual time=728.466..742.870 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53523 read=68387
         I/O Timings: shared read=420.427
         ->  Parallel Hash Right Join  (cost=104579.74..106993.99 rows=1 width=212) (actual time=685.047..695.340 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53523 read=68387
               I/O Timings: shared read=420.427
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.004..2.253 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.73..104579.73 rows=1 width=165) (actual time=684.937..684.941 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=51968 read=68387
                     I/O Timings: shared read=420.427
                     ->  Nested Loop  (cost=25679.82..104579.73 rows=1 width=165) (actual time=147.666..665.569 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=51968 read=68387
                           I/O Timings: shared read=420.427
                           ->  Parallel Hash Join  (cost=25679.53..104578.78 rows=3 width=181) (actual time=147.569..630.224 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13237 read=68387
                                 I/O Timings: shared read=420.427
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=1.062..236.199 rows=1498485.00 loops=2)
                                       Buffers: shared hit=6171 read=53685
                                       I/O Timings: shared read=259.397
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1448 width=100) (actual time=143.571..143.572 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=7066 read=14702
                                       I/O Timings: shared read=161.030
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1448 width=100) (actual time=2.276..141.752 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=7066 read=14702
                                             I/O Timings: shared read=161.030
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.005..0.005 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=413
 Planning Time: 20.729 ms
 Execution Time: 773.516 ms
(48 rows)
```

### PG Stats EXPLAIN Run 2:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107994.20..107994.21 rows=2 width=212) (actual time=728.249..729.697 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53905 read=68011
   I/O Timings: shared read=512.431
   ->  Gather  (cost=105579.74..107994.19 rows=2 width=212) (actual time=685.618..699.219 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53899 read=68011
         I/O Timings: shared read=512.431
         ->  Parallel Hash Right Join  (cost=104579.74..106993.99 rows=1 width=212) (actual time=605.853..616.524 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53899 read=68011
               I/O Timings: shared read=512.431
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.024..2.334 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.73..104579.73 rows=1 width=165) (actual time=605.691..605.696 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3128kB
                     Buffers: shared hit=52344 read=68011
                     I/O Timings: shared read=512.431
                     ->  Nested Loop  (cost=25679.82..104579.73 rows=1 width=165) (actual time=92.349..585.697 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52344 read=68011
                           I/O Timings: shared read=512.431
                           ->  Parallel Hash Join  (cost=25679.53..104578.78 rows=3 width=181) (actual time=92.301..559.331 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13613 read=68011
                                 I/O Timings: shared read=512.431
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.476..287.956 rows=1498485.00 loops=2)
                                       Buffers: shared hit=6359 read=53497
                                       I/O Timings: shared read=419.943
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1448 width=100) (actual time=89.940..89.941 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=7254 read=14514
                                       I/O Timings: shared read=92.488
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1448 width=100) (actual time=2.189..88.837 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=7254 read=14514
                                             I/O Timings: shared read=92.488
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=413
 Planning Time: 18.155 ms
 Execution Time: 730.374 ms
(48 rows)
```

### PG Stats EXPLAIN Run 3:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107994.20..107994.21 rows=2 width=212) (actual time=743.175..744.618 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53802 read=68114
   I/O Timings: shared read=399.317
   ->  Gather  (cost=105579.74..107994.19 rows=2 width=212) (actual time=700.067..714.290 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53796 read=68114
         I/O Timings: shared read=399.317
         ->  Parallel Hash Right Join  (cost=104579.74..106993.99 rows=1 width=212) (actual time=661.343..672.169 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53796 read=68114
               I/O Timings: shared read=399.317
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.004..2.301 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.73..104579.73 rows=1 width=165) (actual time=661.231..661.235 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52241 read=68114
                     I/O Timings: shared read=399.317
                     ->  Nested Loop  (cost=25679.82..104579.73 rows=1 width=165) (actual time=149.148..642.207 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52241 read=68114
                           I/O Timings: shared read=399.317
                           ->  Parallel Hash Join  (cost=25679.53..104578.78 rows=3 width=181) (actual time=149.103..606.111 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13510 read=68114
                                 I/O Timings: shared read=399.317
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.192..224.088 rows=1498485.00 loops=2)
                                       Buffers: shared hit=6410 read=53446
                                       I/O Timings: shared read=244.687
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1448 width=100) (actual time=146.975..146.976 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=7100 read=14668
                                       I/O Timings: shared read=154.630
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1448 width=100) (actual time=5.217..145.052 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=7100 read=14668
                                             I/O Timings: shared read=154.630
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.005..0.005 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=413
 Planning Time: 19.553 ms
 Execution Time: 745.296 ms
(48 rows)
```

### PG Stats EXPLAIN Run 4:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107994.20..107994.21 rows=2 width=212) (actual time=569.485..570.956 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53820 read=68096 written=1
   I/O Timings: shared read=362.319 write=2.148
   ->  Gather  (cost=105579.74..107994.19 rows=2 width=212) (actual time=527.239..540.391 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53814 read=68096 written=1
         I/O Timings: shared read=362.319 write=2.148
         ->  Parallel Hash Right Join  (cost=104579.74..106993.99 rows=1 width=212) (actual time=493.258..503.173 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53814 read=68096 written=1
               I/O Timings: shared read=362.319 write=2.148
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.004..2.136 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.73..104579.73 rows=1 width=165) (actual time=493.153..493.158 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52259 read=68096 written=1
                     I/O Timings: shared read=362.319 write=2.148
                     ->  Nested Loop  (cost=25679.82..104579.73 rows=1 width=165) (actual time=94.773..477.931 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52259 read=68096 written=1
                           I/O Timings: shared read=362.319 write=2.148
                           ->  Parallel Hash Join  (cost=25679.53..104578.78 rows=3 width=181) (actual time=94.731..454.891 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13528 read=68096 written=1
                                 I/O Timings: shared read=362.319 write=2.148
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.183..202.839 rows=1498485.00 loops=2)
                                       Buffers: shared hit=6434 read=53422 written=1
                                       I/O Timings: shared read=268.370 write=2.148
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1448 width=100) (actual time=91.418..91.419 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=7094 read=14674
                                       I/O Timings: shared read=93.949
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1448 width=100) (actual time=2.351..90.300 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=7094 read=14674
                                             I/O Timings: shared read=93.949
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.003..0.003 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=413
 Planning Time: 19.025 ms
 Execution Time: 571.651 ms
(48 rows)
```

### PG Stats EXPLAIN Run 5:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107994.20..107994.21 rows=2 width=212) (actual time=846.235..847.738 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53897 read=68019 written=1
   I/O Timings: shared read=344.758 write=1.072
   ->  Gather  (cost=105579.74..107994.19 rows=2 width=212) (actual time=801.443..816.394 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53891 read=68019 written=1
         I/O Timings: shared read=344.758 write=1.072
         ->  Parallel Hash Right Join  (cost=104579.74..106993.99 rows=1 width=212) (actual time=748.855..759.919 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53891 read=68019 written=1
               I/O Timings: shared read=344.758 write=1.072
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.006..2.430 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.73..104579.73 rows=1 width=165) (actual time=748.695..748.700 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52336 read=68019 written=1
                     I/O Timings: shared read=344.758 write=1.072
                     ->  Nested Loop  (cost=25679.82..104579.73 rows=1 width=165) (actual time=128.419..724.458 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52336 read=68019 written=1
                           I/O Timings: shared read=344.758 write=1.072
                           ->  Parallel Hash Join  (cost=25679.53..104578.78 rows=3 width=181) (actual time=128.353..680.870 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13605 read=68019 written=1
                                 I/O Timings: shared read=344.758 write=1.072
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.783..250.098 rows=1498485.00 loops=2)
                                       Buffers: shared hit=6511 read=53345 written=1
                                       I/O Timings: shared read=238.196 write=1.072
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1448 width=100) (actual time=124.079..124.080 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=7094 read=14674
                                       I/O Timings: shared read=106.561
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1448 width=100) (actual time=5.182..122.179 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=7094 read=14674
                                             I/O Timings: shared read=106.561
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.006..0.006 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=413
 Planning Time: 19.696 ms
 Execution Time: 848.433 ms
(48 rows)
```

### MySQL Stats Setup
```text
Table	Op	Msg_type	Msg_text
synthea_scale.patients	analyze	status	OK
synthea_scale.encounters	analyze	status	OK
synthea_scale.conditions	analyze	status	OK
synthea_scale.observations	analyze	status	OK
Table	Op	Msg_type	Msg_text
synthea_scale.encounters	histogram	status	Histogram statistics created for column 'encounterclass'.
synthea_scale.encounters	histogram	status	Histogram statistics created for column 'start'.
COLUMN_NAME	hist_type	buckets
encounterclass	"singleton"	100
start	"equi-height"	100
```

### MySQL Stats Timing (5 runs after 1 warm-up): [67459.713, 64393.157, 63382.676, 61795.374, 67685.231] | median=64393.157 ms

### MySQL Stats EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=61319..61331 rows=12910 loops=1)
    -> Stream results  (cost=1.22e+9 rows=12.2e+9) (actual time=897..61231 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.22e+9 rows=12.2e+9) (actual time=897..61178 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.18e+6 rows=146748) (actual time=97.4..59863 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.03e+6 rows=146748) (actual time=97..59504 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=323895 rows=2.93e+6) (actual time=2.24..12872 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=323895 rows=2.93e+6) (actual time=2.23..11239 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.017..0.017 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0146..0.0147 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0271..0.0272 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=82851) (actual time=0.99..297 rows=83760 loops=1)
```

### MySQL Stats EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=59831..59840 rows=12910 loops=1)
    -> Stream results  (cost=1.22e+9 rows=12.2e+9) (actual time=910..59748 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.22e+9 rows=12.2e+9) (actual time=910..59692 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.18e+6 rows=146748) (actual time=101..58347 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.03e+6 rows=146748) (actual time=100..57989 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=323895 rows=2.93e+6) (actual time=1.66..12366 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=323895 rows=2.93e+6) (actual time=1.65..10831 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0166..0.0166 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0143..0.0144 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.927 rows=1) (actual time=0.027..0.0271 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=82851) (actual time=0.847..312 rows=83760 loops=1)
```

### MySQL Stats EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=61085..61094 rows=12910 loops=1)
    -> Stream results  (cost=1.22e+9 rows=12.2e+9) (actual time=927..61004 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.22e+9 rows=12.2e+9) (actual time=926..60949 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.18e+6 rows=146748) (actual time=91.9..59500 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.03e+6 rows=146748) (actual time=91.4..59141 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=323895 rows=2.93e+6) (actual time=1.54..12468 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=323895 rows=2.93e+6) (actual time=1.54..10919 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.017..0.017 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0147..0.0148 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0272..0.0273 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=82851) (actual time=0.748..311 rows=83760 loops=1)
```

### MySQL Stats EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=59286..59294 rows=12910 loops=1)
    -> Stream results  (cost=1.22e+9 rows=12.2e+9) (actual time=858..59208 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.22e+9 rows=12.2e+9) (actual time=858..59154 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.18e+6 rows=146748) (actual time=90.1..57897 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.03e+6 rows=146748) (actual time=89.5..57549 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=323895 rows=2.93e+6) (actual time=2.09..12105 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=323895 rows=2.93e+6) (actual time=2.08..10525 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0165..0.0166 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0143..0.0144 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.927 rows=1) (actual time=0.0263..0.0264 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=82851) (actual time=1.04..304 rows=83760 loops=1)
```

### MySQL Stats EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=58265..58272 rows=12910 loops=1)
    -> Stream results  (cost=1.22e+9 rows=12.2e+9) (actual time=934..58185 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.22e+9 rows=12.2e+9) (actual time=934..58134 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.18e+6 rows=146748) (actual time=87.2..56758 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.03e+6 rows=146748) (actual time=86.6..56400 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=323895 rows=2.93e+6) (actual time=1.5..11006 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=323895 rows=2.93e+6) (actual time=1.5..9641 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0166..0.0166 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0145..0.0146 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0271..0.0272 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=82851) (actual time=1.11..345 rows=83760 loops=1)
```

## 5. Q1 Combined (Rewrite 02a + Indexes, no ANALYZE)

### PG Combined Setup
```text
Timing is on.
RESET
Time: 0,248 ms
CREATE INDEX
Time: 1320,360 ms (00:01,320)
CREATE INDEX
Time: 15889,537 ms (00:15,890)
CREATE INDEX
Time: 1371,943 ms (00:01,372)
       index_name        |  size   
-------------------------+---------
 idx_q1_enc_class_start  | 67 MB
 idx_q1_obs_enc_patient  | 40 MB
 idx_q1_cond_enc_patient | 7936 kB
(3 rows)

Time: 23,203 ms
```

### PG Combined Timing (5 runs after 1 warm-up): [504.715, 471.904, 465.114, 441.984, 479.643] | median=471.904 ms

### PG Combined EXPLAIN Run 1:
```text
SET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89945.97..92155.64 rows=19388 width=212) (actual time=492.837..502.174 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12183 read=52215
   I/O Timings: shared read=354.191
   ->  Sort  (cost=88945.96..88974.48 rows=11405 width=212) (actual time=440.778..441.096 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 153kB
         Buffers: shared hit=12183 read=52215
         I/O Timings: shared read=354.191
         Worker 0:  Sort Method: quicksort  Memory: 2995kB
         ->  Parallel Hash Right Join  (cost=85850.38..88177.42 rows=11405 width=212) (actual time=413.384..424.563 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12168 read=52215
               I/O Timings: shared read=354.191
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.017..2.790 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85749.41..85749.41 rows=8078 width=165) (actual time=413.123..413.127 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=10613 read=52215
                     I/O Timings: shared read=354.191
                     ->  Hash Join  (cost=10106.86..85749.41 rows=8078 width=165) (actual time=10.488..409.994 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=10613 read=52215
                           I/O Timings: shared read=354.191
                           ->  Parallel Hash Join  (cost=9426.38..85047.72 rows=8078 width=144) (actual time=5.884..403.749 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=9779 read=52215
                                 I/O Timings: shared read=354.191
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.013..256.998 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7641 read=52215
                                       I/O Timings: shared read=354.191
                                 ->  Parallel Hash  (cost=9408.41..9408.41 rows=1438 width=100) (actual time=3.847..3.848 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=268.55..9408.41 rows=1438 width=100) (actual time=0.761..6.677 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..267.69 rows=3451 width=0) (actual time=0.557..0.557 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.565..4.566 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.260..2.601 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=397
 Planning Time: 5.786 ms
 Execution Time: 502.752 ms
(52 rows)
```

### PG Combined EXPLAIN Run 2:
```text
SET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89945.97..92155.64 rows=19388 width=212) (actual time=388.135..396.808 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12371 read=52027
   I/O Timings: shared read=210.765
   ->  Sort  (cost=88945.96..88974.48 rows=11405 width=212) (actual time=350.486..350.786 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 141kB
         Buffers: shared hit=12371 read=52027
         I/O Timings: shared read=210.765
         Worker 0:  Sort Method: quicksort  Memory: 3007kB
         ->  Parallel Hash Right Join  (cost=85850.38..88177.42 rows=11405 width=212) (actual time=326.142..335.740 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12356 read=52027
               I/O Timings: shared read=210.765
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.013..2.349 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85749.41..85749.41 rows=8078 width=165) (actual time=325.962..325.966 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=10801 read=52027
                     I/O Timings: shared read=210.765
                     ->  Hash Join  (cost=10106.86..85749.41 rows=8078 width=165) (actual time=9.763..322.819 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=10801 read=52027
                           I/O Timings: shared read=210.765
                           ->  Parallel Hash Join  (cost=9426.38..85047.72 rows=8078 width=144) (actual time=5.462..316.910 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=9967 read=52027
                                 I/O Timings: shared read=210.765
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.010..179.926 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7829 read=52027
                                       I/O Timings: shared read=210.765
                                 ->  Parallel Hash  (cost=9408.41..9408.41 rows=1438 width=100) (actual time=4.338..4.339 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=268.55..9408.41 rows=1438 width=100) (actual time=1.257..7.507 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..267.69 rows=3451 width=0) (actual time=0.907..0.907 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.260..4.260 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.271..2.419 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=397
 Planning Time: 5.948 ms
 Execution Time: 397.392 ms
(52 rows)
```

### PG Combined EXPLAIN Run 3:
```text
SET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89945.97..92155.64 rows=19388 width=212) (actual time=458.703..469.236 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12559 read=51839
   I/O Timings: shared read=302.582
   ->  Sort  (cost=88945.96..88974.48 rows=11405 width=212) (actual time=411.508..411.926 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 156kB
         Buffers: shared hit=12559 read=51839
         I/O Timings: shared read=302.582
         Worker 0:  Sort Method: quicksort  Memory: 2992kB
         ->  Parallel Hash Right Join  (cost=85850.38..88177.42 rows=11405 width=212) (actual time=386.079..395.674 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12544 read=51839
               I/O Timings: shared read=302.582
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.007..2.316 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85749.41..85749.41 rows=8078 width=165) (actual time=385.911..385.916 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=10989 read=51839
                     I/O Timings: shared read=302.582
                     ->  Hash Join  (cost=10106.86..85749.41 rows=8078 width=165) (actual time=13.037..383.000 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=10989 read=51839
                           I/O Timings: shared read=302.582
                           ->  Parallel Hash Join  (cost=9426.38..85047.72 rows=8078 width=144) (actual time=7.791..376.075 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=10155 read=51839
                                 I/O Timings: shared read=302.582
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.010..228.956 rows=1498485.00 loops=2)
                                       Buffers: shared hit=8017 read=51839
                                       I/O Timings: shared read=302.582
                                 ->  Parallel Hash  (cost=9408.41..9408.41 rows=1438 width=100) (actual time=6.272..6.273 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=268.55..9408.41 rows=1438 width=100) (actual time=1.107..10.619 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..267.69 rows=3451 width=0) (actual time=0.707..0.707 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=5.204..5.204 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.283..2.936 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=397
 Planning Time: 5.798 ms
 Execution Time: 469.832 ms
(52 rows)
```

### PG Combined EXPLAIN Run 4:
```text
SET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89945.97..92155.64 rows=19388 width=212) (actual time=405.125..413.694 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12747 read=51651
   I/O Timings: shared read=232.907
   ->  Sort  (cost=88945.96..88974.48 rows=11405 width=212) (actual time=363.408..363.716 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 175kB
         Buffers: shared hit=12747 read=51651
         I/O Timings: shared read=232.907
         Worker 0:  Sort Method: quicksort  Memory: 2972kB
         ->  Parallel Hash Right Join  (cost=85850.38..88177.42 rows=11405 width=212) (actual time=338.462..348.547 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12732 read=51651
               I/O Timings: shared read=232.907
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.009..2.431 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85749.41..85749.41 rows=8078 width=165) (actual time=338.274..338.278 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=11177 read=51651
                     I/O Timings: shared read=232.907
                     ->  Hash Join  (cost=10106.86..85749.41 rows=8078 width=165) (actual time=9.019..335.369 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=11177 read=51651
                           I/O Timings: shared read=232.907
                           ->  Parallel Hash Join  (cost=9426.38..85047.72 rows=8078 width=144) (actual time=4.508..329.318 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=10343 read=51651
                                 I/O Timings: shared read=232.907
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.007..191.533 rows=1498485.00 loops=2)
                                       Buffers: shared hit=8205 read=51651
                                       I/O Timings: shared read=232.907
                                 ->  Parallel Hash  (cost=9408.41..9408.41 rows=1438 width=100) (actual time=3.615..3.616 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=268.55..9408.41 rows=1438 width=100) (actual time=0.775..6.261 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..267.69 rows=3451 width=0) (actual time=0.572..0.572 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.471..4.472 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.258..2.572 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=397
 Planning Time: 5.621 ms
 Execution Time: 414.224 ms
(52 rows)
```

### PG Combined EXPLAIN Run 5:
```text
SET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89945.97..92155.64 rows=19388 width=212) (actual time=413.608..420.776 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12935 read=51463
   I/O Timings: shared read=267.604
   ->  Sort  (cost=88945.96..88974.48 rows=11405 width=212) (actual time=376.704..377.008 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3002kB
         Buffers: shared hit=12935 read=51463
         I/O Timings: shared read=267.604
         Worker 0:  Sort Method: quicksort  Memory: 146kB
         ->  Parallel Hash Right Join  (cost=85850.38..88177.42 rows=11405 width=212) (actual time=351.971..361.334 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12920 read=51463
               I/O Timings: shared read=267.604
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.008..2.260 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85749.41..85749.41 rows=8078 width=165) (actual time=351.791..351.795 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=11365 read=51463
                     I/O Timings: shared read=267.604
                     ->  Hash Join  (cost=10106.86..85749.41 rows=8078 width=165) (actual time=9.245..348.851 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=11365 read=51463
                           I/O Timings: shared read=267.604
                           ->  Parallel Hash Join  (cost=9426.38..85047.72 rows=8078 width=144) (actual time=4.729..342.860 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=10531 read=51463
                                 I/O Timings: shared read=267.604
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.009..207.557 rows=1498485.00 loops=2)
                                       Buffers: shared hit=8393 read=51463
                                       I/O Timings: shared read=267.604
                                 ->  Parallel Hash  (cost=9408.41..9408.41 rows=1438 width=100) (actual time=3.559..3.559 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=268.55..9408.41 rows=1438 width=100) (actual time=0.681..6.143 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..267.69 rows=3451 width=0) (actual time=0.482..0.483 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.470..4.471 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.260..2.552 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=397
 Planning Time: 5.586 ms
 Execution Time: 421.619 ms
(52 rows)
```

### MySQL Combined Setup
```text
TABLE_NAME	INDEX_NAME	size_kb
conditions	idx_q1_cond_enc_patient	8768
encounters	idx_q1_enc_class_start	58192
observations	idx_q1_obs_enc_patient	283632
```

### MySQL Combined Timing (5 runs after 1 warm-up): [3094.257, 2650.146, 2416.586, 2382.133, 2780.837] | median=2650.146 ms

### MySQL Combined EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=2678..2690 rows=12910 loops=1)
    -> Stream results  (cost=138384 rows=113739) (actual time=13.9..2596 rows=12910 loops=1)
        -> Nested loop inner join  (cost=138384 rows=113739) (actual time=13.8..2526 rows=12910 loops=1)
            -> Nested loop left join  (cost=13271 rows=7937) (actual time=13.6..1434 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10493 rows=7276) (actual time=13.6..1310 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7893 rows=7276) (actual time=13.6..1235 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.257 rows=1) (actual time=0.0188..0.0189 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.273 rows=1.09) (actual time=0.0299..0.0314 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=14.3 rows=14.3) (actual time=0.237..0.274 rows=3.26 loops=3960)
```

### MySQL Combined EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=2862..2875 rows=12910 loops=1)
    -> Stream results  (cost=138363 rows=113739) (actual time=23.1..2785 rows=12910 loops=1)
        -> Nested loop inner join  (cost=138363 rows=113739) (actual time=23.1..2710 rows=12910 loops=1)
            -> Nested loop left join  (cost=13251 rows=7937) (actual time=22.7..1485 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10473 rows=7276) (actual time=22.7..1344 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7873 rows=7276) (actual time=22.6..1258 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.257 rows=1) (actual time=0.0215..0.0216 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.273 rows=1.09) (actual time=0.0342..0.0359 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=14.3 rows=14.3) (actual time=0.269..0.307 rows=3.26 loops=3960)
```

### MySQL Combined EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=2817..2825 rows=12910 loops=1)
    -> Stream results  (cost=138359 rows=113739) (actual time=27.4..2731 rows=12910 loops=1)
        -> Nested loop inner join  (cost=138359 rows=113739) (actual time=27.4..2656 rows=12910 loops=1)
            -> Nested loop left join  (cost=13246 rows=7937) (actual time=26.9..1522 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10468 rows=7276) (actual time=26.9..1384 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7869 rows=7276) (actual time=26.8..1302 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.257 rows=1) (actual time=0.0203..0.0204 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.273 rows=1.09) (actual time=0.0333..0.035 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=14.3 rows=14.3) (actual time=0.247..0.284 rows=3.26 loops=3960)
```

### MySQL Combined EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=2907..2917 rows=12910 loops=1)
    -> Stream results  (cost=138358 rows=113739) (actual time=23..2813 rows=12910 loops=1)
        -> Nested loop inner join  (cost=138358 rows=113739) (actual time=23..2739 rows=12910 loops=1)
            -> Nested loop left join  (cost=13246 rows=7937) (actual time=22.5..1570 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10468 rows=7276) (actual time=22.5..1431 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7868 rows=7276) (actual time=22.3..1346 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.257 rows=1) (actual time=0.0212..0.0213 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.273 rows=1.09) (actual time=0.0332..0.0349 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=14.3 rows=14.3) (actual time=0.255..0.293 rows=3.26 loops=3960)
```

### MySQL Combined EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=2709..2717 rows=12910 loops=1)
    -> Stream results  (cost=138358 rows=113739) (actual time=23.4..2621 rows=12910 loops=1)
        -> Nested loop inner join  (cost=138358 rows=113739) (actual time=23.4..2536 rows=12910 loops=1)
            -> Nested loop left join  (cost=13246 rows=7937) (actual time=23..1448 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10468 rows=7276) (actual time=23..1313 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7868 rows=7276) (actual time=22.9..1227 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.257 rows=1) (actual time=0.0214..0.0215 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.273 rows=1.09) (actual time=0.0324..0.0341 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=14.3 rows=14.3) (actual time=0.232..0.273 rows=3.26 loops=3960)
```
