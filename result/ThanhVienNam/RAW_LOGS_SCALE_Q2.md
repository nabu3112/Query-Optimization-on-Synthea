# RAW LOGS TẤT CẢ CÁC LẦN CHẠY Q2 TRÊN DỮ LIỆU SCALE 10X THUẦN (synthea_scale)

## 0. Phiên bản Hệ quản trị CSDL & Thông số môi trường
```text
version                                 
-------------------------------------------------------------------------
 PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35229, 64-bit
(1 row)

VERSION()
9.4.0
```

### Thông số môi trường & Dung lượng D0 (conditions, encounters, patients)
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

 table_name | est_rows | total_bytes | total_size 
------------+----------+-------------+------------
 conditions |    83760 |    12746752 | 12 MB
 encounters |   533460 |   209928192 | 200 MB
 patients   |        0 |     4161536 | 4064 kB
(3 rows)

 d0_bytes  | d0_mb  
-----------+--------
 226836480 | 216.33
(1 row)

sort_buffer_size	join_buffer_size	innodb_buffer_pool_size	tmp_table_size
262144	262144	134217728	154140672
TABLE_NAME	TABLE_ROWS	total_bytes	total_mb
conditions	81947	13123584	12.52
encounters	508358	176160768	168.00
patients	11551	3686400	3.52
d0_bytes	d0_mb
192970752	184.03
```

### Kiểm tra tương đương kết quả (Equivalence Check)
```text
-- PostgreSQL
n_baseline | n_rewrite 
------------+-----------
       9850 |      9850
(1 row)

-- MySQL
n_baseline	n_rewrite
9850	9850
```

## 1. Q2 Baseline

### PG Baseline Timing (5 runs after 1 warm-up): [207.302, 240.684, 182.975, 199.556, 175.619] | median=199.556 ms
```text
Timing is on.
Time: 192,542 ms
Time: 207,302 ms
Time: 240,684 ms
Time: 182,975 ms
Time: 199,556 ms
Time: 175,619 ms
```

### PG Baseline EXPLAIN Run 1:
```text
SET
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.68..28575.69 rows=1 width=174) (actual time=180.614..182.960 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=35730 read=17146
   I/O Timings: shared read=73.108
   ->  Nested Loop  (cost=26413.36..28575.67 rows=1 width=174) (actual time=136.071..173.901 rows=9850.00 loops=1)
         Buffers: shared hit=35724 read=17146
         I/O Timings: shared read=73.108
         ->  Gather  (cost=26413.08..28575.33 rows=1 width=168) (actual time=136.012..139.588 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=6174 read=17146
               I/O Timings: shared read=73.108
               ->  Parallel Hash Join  (cost=25413.08..27575.23 rows=1 width=168) (actual time=107.975..118.502 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared hit=6174 read=17146
                     I/O Timings: shared read=73.108
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.005..3.638 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20730 width=93) (actual time=107.854..107.856 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16512kB
                           Buffers: shared hit=4622 read=17146
                           I/O Timings: shared read=73.108
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=20730 width=93) (actual time=0.662..84.289 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=4622 read=17146
                                 I/O Timings: shared read=73.108
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=311
 Planning Time: 3.744 ms
 Execution Time: 183.397 ms
(38 rows)
```

### PG Baseline EXPLAIN Run 2:
```text
SET
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.68..28575.69 rows=1 width=174) (actual time=177.868..180.564 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=35918 read=16958
   I/O Timings: shared read=58.678
   ->  Nested Loop  (cost=26413.36..28575.67 rows=1 width=174) (actual time=129.960..170.343 rows=9850.00 loops=1)
         Buffers: shared hit=35912 read=16958
         I/O Timings: shared read=58.678
         ->  Gather  (cost=26413.08..28575.33 rows=1 width=168) (actual time=129.900..133.359 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=6362 read=16958
               I/O Timings: shared read=58.678
               ->  Parallel Hash Join  (cost=25413.08..27575.23 rows=1 width=168) (actual time=99.344..110.909 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared hit=6362 read=16958
                     I/O Timings: shared read=58.678
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.007..4.034 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20730 width=93) (actual time=99.197..99.198 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared hit=4810 read=16958
                           I/O Timings: shared read=58.678
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=20730 width=93) (actual time=0.991..75.653 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=4810 read=16958
                                 I/O Timings: shared read=58.678
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=311
 Planning Time: 3.809 ms
 Execution Time: 181.140 ms
(38 rows)
```

### PG Baseline EXPLAIN Run 3:
```text
SET
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.68..28575.69 rows=1 width=174) (actual time=166.615..169.227 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=36106 read=16770
   I/O Timings: shared read=78.670
   ->  Nested Loop  (cost=26413.36..28575.67 rows=1 width=174) (actual time=120.678..160.034 rows=9850.00 loops=1)
         Buffers: shared hit=36100 read=16770
         I/O Timings: shared read=78.670
         ->  Gather  (cost=26413.08..28575.33 rows=1 width=168) (actual time=120.624..124.313 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=6550 read=16770
               I/O Timings: shared read=78.670
               ->  Parallel Hash Join  (cost=25413.08..27575.23 rows=1 width=168) (actual time=98.869..109.806 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared hit=6550 read=16770
                     I/O Timings: shared read=78.670
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.007..3.759 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20730 width=93) (actual time=98.699..98.700 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared hit=4998 read=16770
                           I/O Timings: shared read=78.670
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=20730 width=93) (actual time=0.727..78.732 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=4998 read=16770
                                 I/O Timings: shared read=78.670
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=311
 Planning Time: 3.926 ms
 Execution Time: 169.690 ms
(38 rows)
```

### PG Baseline EXPLAIN Run 4:
```text
SET
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.68..28575.69 rows=1 width=174) (actual time=170.936..173.394 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=36294 read=16582
   I/O Timings: shared read=79.656
   ->  Nested Loop  (cost=26413.36..28575.67 rows=1 width=174) (actual time=124.659..164.486 rows=9850.00 loops=1)
         Buffers: shared hit=36288 read=16582
         I/O Timings: shared read=79.656
         ->  Gather  (cost=26413.08..28575.33 rows=1 width=168) (actual time=124.600..128.308 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=6738 read=16582
               I/O Timings: shared read=79.656
               ->  Parallel Hash Join  (cost=25413.08..27575.23 rows=1 width=168) (actual time=99.338..110.248 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared hit=6738 read=16582
                     I/O Timings: shared read=79.656
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.005..3.622 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20730 width=93) (actual time=99.204..99.205 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared hit=5186 read=16582
                           I/O Timings: shared read=79.656
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=20730 width=93) (actual time=1.468..79.803 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=5186 read=16582
                                 I/O Timings: shared read=79.656
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=311
 Planning Time: 3.849 ms
 Execution Time: 173.835 ms
(38 rows)
```

### PG Baseline EXPLAIN Run 5:
```text
SET
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.68..28575.69 rows=1 width=174) (actual time=189.165..191.677 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=36482 read=16394
   I/O Timings: shared read=48.412
   ->  Nested Loop  (cost=26413.36..28575.67 rows=1 width=174) (actual time=144.787..182.731 rows=9850.00 loops=1)
         Buffers: shared hit=36476 read=16394
         I/O Timings: shared read=48.412
         ->  Gather  (cost=26413.08..28575.33 rows=1 width=168) (actual time=144.727..148.458 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=6926 read=16394
               I/O Timings: shared read=48.412
               ->  Parallel Hash Join  (cost=25413.08..27575.23 rows=1 width=168) (actual time=105.789..116.678 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared hit=6926 read=16394
                     I/O Timings: shared read=48.412
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.005..3.724 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20730 width=93) (actual time=105.631..105.631 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16512kB
                           Buffers: shared hit=5374 read=16394
                           I/O Timings: shared read=48.412
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=20730 width=93) (actual time=2.015..79.367 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=5374 read=16394
                                 I/O Timings: shared read=48.412
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=311
 Planning Time: 3.531 ms
 Execution Time: 192.129 ms
(38 rows)
```

### MySQL Baseline Timing (5 runs after 1 warm-up): [4038.253, 3542.097, 3689.801, 4510.737, 3859.067] | median=3859.067 ms
```text
TIMING_MS=3862.774
TIMING_MS=4038.253
TIMING_MS=3542.097
TIMING_MS=3689.801
TIMING_MS=4510.737
TIMING_MS=3859.067
```

### MySQL Baseline EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=3715..3721 rows=9850 loops=1)
    -> Stream results  (cost=13103 rows=410) (actual time=1.32..3655 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13103 rows=410) (actual time=1.29..3595 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12959 rows=410) (actual time=1.23..3492 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8395 rows=8195) (actual time=1.16..317 rows=38110 loops=1)
                    -> Table scan on c  (cost=8395 rows=81947) (actual time=1.16..282 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.457 rows=0.05) (actual time=0.0828..0.0829 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.457 rows=1) (actual time=0.0805..0.0806 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.00972..0.0098 rows=1 loops=9850)
```

### MySQL Baseline EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=4285..4288 rows=9850 loops=1)
    -> Stream results  (cost=13103 rows=410) (actual time=1.29..4224 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13103 rows=410) (actual time=1.28..4148 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12959 rows=410) (actual time=1.24..4029 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8395 rows=8195) (actual time=1.15..382 rows=38110 loops=1)
                    -> Table scan on c  (cost=8395 rows=81947) (actual time=1.15..336 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.457 rows=0.05) (actual time=0.0952..0.0953 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.457 rows=1) (actual time=0.0923..0.0924 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0113..0.0114 rows=1 loops=9850)
```

### MySQL Baseline EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=5664..5672 rows=9850 loops=1)
    -> Stream results  (cost=13103 rows=410) (actual time=1.07..5582 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13103 rows=410) (actual time=1.06..5498 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12959 rows=410) (actual time=1.02..5350 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8395 rows=8195) (actual time=0.949..458 rows=38110 loops=1)
                    -> Table scan on c  (cost=8395 rows=81947) (actual time=0.945..393 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.457 rows=0.05) (actual time=0.128..0.128 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.457 rows=1) (actual time=0.124..0.124 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.014..0.014 rows=1 loops=9850)
```

### MySQL Baseline EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=6095..6098 rows=9850 loops=1)
    -> Stream results  (cost=13066 rows=410) (actual time=1.44..6021 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13066 rows=410) (actual time=1.42..5930 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12922 rows=410) (actual time=1.39..5774 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8395 rows=8195) (actual time=1.34..507 rows=38110 loops=1)
                    -> Table scan on c  (cost=8395 rows=81947) (actual time=1.33..447 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.452 rows=0.05) (actual time=0.138..0.138 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.452 rows=1) (actual time=0.134..0.134 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0148..0.0149 rows=1 loops=9850)
```

### MySQL Baseline EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=6122..6130 rows=9850 loops=1)
    -> Stream results  (cost=13066 rows=410) (actual time=1.82..6036 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13066 rows=410) (actual time=1.8..5947 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12922 rows=410) (actual time=1.73..5792 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8395 rows=8195) (actual time=1.67..508 rows=38110 loops=1)
                    -> Table scan on c  (cost=8395 rows=81947) (actual time=1.66..447 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.452 rows=0.05) (actual time=0.138..0.138 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.452 rows=1) (actual time=0.134..0.134 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0146..0.0147 rows=1 loops=9850)
```

## 2. Q2 Rewrite (`e.reasoncode > ''`)

### PG Rewrite Timing (5 runs after 1 warm-up): [249.694, 249.245, 207.699, 244.138, 245.539] | median=245.539 ms
```text
Timing is on.
Time: 236,748 ms
Time: 249,694 ms
Time: 249,245 ms
Time: 207,699 ms
Time: 244,138 ms
Time: 245,539 ms
```

### PG Rewrite EXPLAIN Run 1:
```text
SET
                                                                         QUERY PLAN                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.94..28575.94 rows=1 width=174) (actual time=420.778..424.071 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=37798 read=15078
   I/O Timings: shared read=294.972
   ->  Nested Loop  (cost=26413.62..28575.93 rows=1 width=174) (actual time=372.767..413.498 rows=9850.00 loops=1)
         Buffers: shared hit=37792 read=15078
         I/O Timings: shared read=294.972
         ->  Gather  (cost=26413.33..28575.58 rows=1 width=168) (actual time=372.718..376.884 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=8242 read=15078
               I/O Timings: shared read=294.972
               ->  Parallel Hash Join  (cost=25413.33..27575.48 rows=1 width=168) (actual time=311.556..322.493 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared hit=8242 read=15078
                     I/O Timings: shared read=294.972
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.010..3.705 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20747 width=93) (actual time=311.283..311.284 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared hit=6690 read=15078
                           I/O Timings: shared read=294.972
                           ->  Parallel Seq Scan on encounters  (cost=0.00..25102.12 rows=20747 width=93) (actual time=1.400..263.459 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text > ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=6690 read=15078
                                 I/O Timings: shared read=294.972
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=314
 Planning Time: 4.642 ms
 Execution Time: 424.701 ms
(38 rows)
```

### PG Rewrite EXPLAIN Run 2:
```text
SET
                                                                         QUERY PLAN                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.94..28575.94 rows=1 width=174) (actual time=289.188..291.908 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=37986 read=14890
   I/O Timings: shared read=183.510
   ->  Nested Loop  (cost=26413.62..28575.93 rows=1 width=174) (actual time=234.956..281.075 rows=9850.00 loops=1)
         Buffers: shared hit=37980 read=14890
         I/O Timings: shared read=183.510
         ->  Gather  (cost=26413.33..28575.58 rows=1 width=168) (actual time=234.891..238.485 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=8430 read=14890
               I/O Timings: shared read=183.510
               ->  Parallel Hash Join  (cost=25413.33..27575.48 rows=1 width=168) (actual time=181.049..193.343 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared hit=8430 read=14890
                     I/O Timings: shared read=183.510
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.012..4.147 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20747 width=93) (actual time=180.781..180.782 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared hit=6878 read=14890
                           I/O Timings: shared read=183.510
                           ->  Parallel Seq Scan on encounters  (cost=0.00..25102.12 rows=20747 width=93) (actual time=1.979..154.303 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text > ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=6878 read=14890
                                 I/O Timings: shared read=183.510
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.004..0.004 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=314
 Planning Time: 5.939 ms
 Execution Time: 292.458 ms
(38 rows)
```

### PG Rewrite EXPLAIN Run 3:
```text
SET
                                                                         QUERY PLAN                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.94..28575.94 rows=1 width=174) (actual time=215.781..218.072 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=38174 read=14702
   I/O Timings: shared read=117.214
   ->  Nested Loop  (cost=26413.62..28575.93 rows=1 width=174) (actual time=161.685..207.894 rows=9850.00 loops=1)
         Buffers: shared hit=38168 read=14702
         I/O Timings: shared read=117.214
         ->  Gather  (cost=26413.33..28575.58 rows=1 width=168) (actual time=161.626..165.178 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=8618 read=14702
               I/O Timings: shared read=117.214
               ->  Parallel Hash Join  (cost=25413.33..27575.48 rows=1 width=168) (actual time=138.749..151.301 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared hit=8618 read=14702
                     I/O Timings: shared read=117.214
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.005..4.404 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20747 width=93) (actual time=138.617..138.619 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16512kB
                           Buffers: shared hit=7066 read=14702
                           I/O Timings: shared read=117.214
                           ->  Parallel Seq Scan on encounters  (cost=0.00..25102.12 rows=20747 width=93) (actual time=0.770..115.439 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text > ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=7066 read=14702
                                 I/O Timings: shared read=117.214
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.004..0.004 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=314
 Planning Time: 3.550 ms
 Execution Time: 218.535 ms
(38 rows)
```

### PG Rewrite EXPLAIN Run 4:
```text
SET
                                                                         QUERY PLAN                                                                         
------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.94..28575.94 rows=1 width=174) (actual time=248.287..250.844 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=38362 read=14514
   I/O Timings: shared read=68.010
   ->  Nested Loop  (cost=26413.62..28575.93 rows=1 width=174) (actual time=201.379..241.565 rows=9850.00 loops=1)
         Buffers: shared hit=38356 read=14514
         I/O Timings: shared read=68.010
         ->  Gather  (cost=26413.33..28575.58 rows=1 width=168) (actual time=201.327..205.001 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=8806 read=14514
               I/O Timings: shared read=68.010
               ->  Parallel Hash Join  (cost=25413.33..27575.48 rows=1 width=168) (actual time=112.330..124.310 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared hit=8806 read=14514
                     I/O Timings: shared read=68.010
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.006..3.742 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20747 width=93) (actual time=112.192..112.193 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared hit=7254 read=14514
                           I/O Timings: shared read=68.010
                           ->  Parallel Seq Scan on encounters  (cost=0.00..25102.12 rows=20747 width=93) (actual time=0.146..90.260 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text > ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=7254 read=14514
                                 I/O Timings: shared read=68.010
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=314
 Planning Time: 3.530 ms
 Execution Time: 251.282 ms
(38 rows)
```

### PG Rewrite EXPLAIN Run 5:
```text
SET
                                                                         QUERY PLAN                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28575.94..28575.94 rows=1 width=174) (actual time=244.488..246.816 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=38456 read=14420
   I/O Timings: shared read=177.315
   ->  Nested Loop  (cost=26413.62..28575.93 rows=1 width=174) (actual time=196.942..236.924 rows=9850.00 loops=1)
         Buffers: shared hit=38450 read=14420
         I/O Timings: shared read=177.315
         ->  Gather  (cost=26413.33..28575.58 rows=1 width=168) (actual time=196.889..200.290 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared hit=8900 read=14420
               I/O Timings: shared read=177.315
               ->  Parallel Hash Join  (cost=25413.33..27575.48 rows=1 width=168) (actual time=166.007..177.077 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared hit=8900 read=14420
                     I/O Timings: shared read=177.315
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22371 width=112) (actual time=0.005..3.735 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared hit=1552
                     ->  Parallel Hash  (cost=25102.12..25102.12 rows=20747 width=93) (actual time=165.867..165.868 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16512kB
                           Buffers: shared hit=7348 read=14420
                           I/O Timings: shared read=177.315
                           ->  Parallel Seq Scan on encounters  (cost=0.00..25102.12 rows=20747 width=93) (actual time=0.581..143.139 rows=59645.00 loops=2)
                                 Filter: (((reasoncode)::text > ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                                 Rows Removed by Filter: 207085
                                 Buffers: shared hit=7348 read=14420
                                 I/O Timings: shared read=177.315
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=314
 Planning Time: 5.559 ms
 Execution Time: 247.298 ms
(38 rows)
```

### MySQL Rewrite Timing (5 runs after 1 warm-up): [6039.077, 6084.421, 5871.706, 4081.664, 3608.769] | median=5871.706 ms
```text
TIMING_MS=5550.239
TIMING_MS=6039.077
TIMING_MS=6084.421
TIMING_MS=5871.706
TIMING_MS=4081.664
TIMING_MS=3608.769
```

### MySQL Rewrite EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3810..3812 rows=9850 loops=1)
    -> Stream results  (cost=13103 rows=410) (actual time=0.886..3753 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13103 rows=410) (actual time=0.878..3679 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12959 rows=410) (actual time=0.857..3569 rows=9850 loops=1)
                -> Filter: ((conditions.`stop` is null) and (conditions.encounter is not null) and (conditions.patient is not null))  (cost=8395 rows=8195) (actual time=0.833..352 rows=38110 loops=1)
                    -> Table scan on conditions  (cost=8395 rows=81947) (actual time=0.831..308 rows=83760 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.457 rows=0.05) (actual time=0.0839..0.084 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.457 rows=1) (actual time=0.082..0.0821 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0104..0.0105 rows=1 loops=9850)
```

### MySQL Rewrite EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=4124..4131 rows=9850 loops=1)
    -> Stream results  (cost=13103 rows=410) (actual time=0.791..4051 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13103 rows=410) (actual time=0.777..3968 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12959 rows=410) (actual time=0.756..3841 rows=9850 loops=1)
                -> Filter: ((conditions.`stop` is null) and (conditions.encounter is not null) and (conditions.patient is not null))  (cost=8395 rows=8195) (actual time=0.715..416 rows=38110 loops=1)
                    -> Table scan on conditions  (cost=8395 rows=81947) (actual time=0.711..362 rows=83760 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.457 rows=0.05) (actual time=0.0893..0.0894 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.457 rows=1) (actual time=0.0871..0.0872 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0119..0.0119 rows=1 loops=9850)
```

### MySQL Rewrite EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3449..3455 rows=9850 loops=1)
    -> Stream results  (cost=13066 rows=410) (actual time=1.71..3386 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13066 rows=410) (actual time=1.69..3321 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12923 rows=410) (actual time=1.58..3221 rows=9850 loops=1)
                -> Filter: ((conditions.`stop` is null) and (conditions.encounter is not null) and (conditions.patient is not null))  (cost=8395 rows=8195) (actual time=1.5..319 rows=38110 loops=1)
                    -> Table scan on conditions  (cost=8395 rows=81947) (actual time=1.5..282 rows=83760 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.453 rows=0.05) (actual time=0.0757..0.0758 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.453 rows=1) (actual time=0.074..0.0741 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.00941..0.00949 rows=1 loops=9850)
```

### MySQL Rewrite EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=4158..4164 rows=9850 loops=1)
    -> Stream results  (cost=13103 rows=410) (actual time=0.969..4084 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13103 rows=410) (actual time=0.961..3998 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12959 rows=410) (actual time=0.951..3864 rows=9850 loops=1)
                -> Filter: ((conditions.`stop` is null) and (conditions.encounter is not null) and (conditions.patient is not null))  (cost=8395 rows=8195) (actual time=0.927..427 rows=38110 loops=1)
                    -> Table scan on conditions  (cost=8395 rows=81947) (actual time=0.925..368 rows=83760 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.457 rows=0.05) (actual time=0.0896..0.0897 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.457 rows=1) (actual time=0.0874..0.0874 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0127..0.0128 rows=1 loops=9850)
```

### MySQL Rewrite EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=4124..4130 rows=9850 loops=1)
    -> Stream results  (cost=13075 rows=410) (actual time=1.08..4049 rows=9850 loops=1)
        -> Nested loop inner join  (cost=13075 rows=410) (actual time=1.06..3960 rows=9850 loops=1)
            -> Nested loop inner join  (cost=12932 rows=410) (actual time=1.03..3825 rows=9850 loops=1)
                -> Filter: ((conditions.`stop` is null) and (conditions.encounter is not null) and (conditions.patient is not null))  (cost=8395 rows=8195) (actual time=0.95..446 rows=38110 loops=1)
                    -> Table scan on conditions  (cost=8395 rows=81947) (actual time=0.947..383 rows=83760 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.454 rows=0.05) (actual time=0.0881..0.0881 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.454 rows=1) (actual time=0.0857..0.0857 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0126..0.0127 rows=1 loops=9850)
```

## 3. Q2 Indexes

### PG Index Setup & Sizes
```text
CREATE INDEX
CREATE INDEX
        indexname        |  size   
-------------------------+---------
 idx_q2_cond_active      | 3432 kB
 idx_q2_enc_class_reason | 3744 kB
(2 rows)

ANALYZE
ANALYZE

indexname        | size_bytes |  size   
-------------------------+------------+---------
 idx_q2_cond_active      |    3514368 | 3432 kB
 idx_q2_enc_class_reason |    3833856 | 3744 kB
(2 rows)

 delta_d_bytes | delta_d_mb 
---------------+------------
       7348224 |       7.01
(1 row)
```

### PG Index + Baseline SQL (`<> ''`) Timing: [257.236, 246.179, 218.912, 230.947, 231.742] | median=231.742 ms

### PG Index + Baseline SQL EXPLAIN Run 1:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28544.62..28544.63 rows=1 width=174) (actual time=200.417..203.411 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=22116
   I/O Timings: shared read=130.868
   ->  Nested Loop  (cost=26383.51..28544.61 rows=1 width=174) (actual time=151.422..193.978 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=22116
         I/O Timings: shared read=130.868
         ->  Gather  (cost=26383.23..28544.26 rows=1 width=168) (actual time=151.364..157.077 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=22116
               I/O Timings: shared read=130.868
               ->  Parallel Hash Join  (cost=25383.23..27544.16 rows=1 width=168) (actual time=129.550..141.226 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared read=22116
                     I/O Timings: shared read=130.868
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.929..5.289 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=2.986
                     ->  Parallel Hash  (cost=25071.27..25071.27 rows=20797 width=93) (actual time=128.458..128.459 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared read=20564
                           I/O Timings: shared read=127.882
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=2113.11..25071.27 rows=20797 width=93) (actual time=4.960..109.099 rows=59645.00 loops=2)
                                 Recheck Cond: ((encounterclass)::text = 'ambulatory'::text)
                                 Filter: ((reasoncode)::text <> ''::text)
                                 Rows Removed by Filter: 35035
                                 Heap Blocks: exact=12872
                                 Buffers: shared read=20564
                                 I/O Timings: shared read=127.882
                                 Worker 0:  Heap Blocks: exact=7525
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..2100.63 rows=190427 width=0) (actual time=5.996..5.997 rows=189360.00 loops=1)
                                       Index Cond: ((encounterclass)::text = 'ambulatory'::text)
                                       Index Searches: 1
                                       Buffers: shared read=167
                                       I/O Timings: shared read=1.105
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=302 read=45
   I/O Timings: shared read=3.907
 Planning Time: 8.072 ms
 Execution Time: 203.853 ms
(48 rows)
```

### PG Index + Baseline SQL EXPLAIN Run 2:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28544.62..28544.63 rows=1 width=174) (actual time=213.886..216.783 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=22116
   I/O Timings: shared read=154.080
   ->  Nested Loop  (cost=26383.51..28544.61 rows=1 width=174) (actual time=164.688..207.310 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=22116
         I/O Timings: shared read=154.080
         ->  Gather  (cost=26383.23..28544.26 rows=1 width=168) (actual time=164.632..170.741 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=22116
               I/O Timings: shared read=154.080
               ->  Parallel Hash Join  (cost=25383.23..27544.16 rows=1 width=168) (actual time=141.038..152.278 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared read=22116
                     I/O Timings: shared read=154.080
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22139 width=112) (actual time=1.100..5.323 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=3.497
                     ->  Parallel Hash  (cost=25071.27..25071.27 rows=20797 width=93) (actual time=139.762..139.763 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared read=20564
                           I/O Timings: shared read=150.583
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=2113.11..25071.27 rows=20797 width=93) (actual time=4.878..120.186 rows=59645.00 loops=2)
                                 Recheck Cond: ((encounterclass)::text = 'ambulatory'::text)
                                 Filter: ((reasoncode)::text <> ''::text)
                                 Rows Removed by Filter: 35035
                                 Heap Blocks: exact=12501
                                 Buffers: shared read=20564
                                 I/O Timings: shared read=150.583
                                 Worker 0:  Heap Blocks: exact=7896
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..2100.63 rows=190427 width=0) (actual time=6.320..6.320 rows=189360.00 loops=1)
                                       Index Cond: ((encounterclass)::text = 'ambulatory'::text)
                                       Index Searches: 1
                                       Buffers: shared read=167
                                       I/O Timings: shared read=1.160
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=321 read=26
   I/O Timings: shared read=2.618
 Planning Time: 6.945 ms
 Execution Time: 217.233 ms
(48 rows)
```

### PG Index + Baseline SQL EXPLAIN Run 3:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28544.62..28544.63 rows=1 width=174) (actual time=209.031..212.452 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=22116
   I/O Timings: shared read=143.415
   ->  Nested Loop  (cost=26383.51..28544.61 rows=1 width=174) (actual time=162.436..203.171 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=22116
         I/O Timings: shared read=143.415
         ->  Gather  (cost=26383.23..28544.26 rows=1 width=168) (actual time=162.376..167.538 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=22116
               I/O Timings: shared read=143.415
               ->  Parallel Hash Join  (cost=25383.23..27544.16 rows=1 width=168) (actual time=139.155..149.953 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared read=22116
                     I/O Timings: shared read=143.415
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.561..4.360 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=1.596
                     ->  Parallel Hash  (cost=25071.27..25071.27 rows=20797 width=93) (actual time=138.431..138.432 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared read=20564
                           I/O Timings: shared read=141.819
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=2113.11..25071.27 rows=20797 width=93) (actual time=5.969..118.446 rows=59645.00 loops=2)
                                 Recheck Cond: ((encounterclass)::text = 'ambulatory'::text)
                                 Filter: ((reasoncode)::text <> ''::text)
                                 Rows Removed by Filter: 35035
                                 Heap Blocks: exact=12694
                                 Buffers: shared read=20564
                                 I/O Timings: shared read=141.819
                                 Worker 0:  Heap Blocks: exact=7703
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..2100.63 rows=190427 width=0) (actual time=7.025..7.025 rows=189360.00 loops=1)
                                       Index Cond: ((encounterclass)::text = 'ambulatory'::text)
                                       Index Searches: 1
                                       Buffers: shared read=167
                                       I/O Timings: shared read=1.190
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=307 read=40
   I/O Timings: shared read=4.575
 Planning Time: 8.622 ms
 Execution Time: 212.938 ms
(48 rows)
```

### PG Index + Baseline SQL EXPLAIN Run 4:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28544.62..28544.63 rows=1 width=174) (actual time=212.447..215.229 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=22116
   I/O Timings: shared read=150.539
   ->  Nested Loop  (cost=26383.51..28544.61 rows=1 width=174) (actual time=161.515..205.638 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=22116
         I/O Timings: shared read=150.539
         ->  Gather  (cost=26383.23..28544.26 rows=1 width=168) (actual time=161.457..166.736 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=22116
               I/O Timings: shared read=150.539
               ->  Parallel Hash Join  (cost=25383.23..27544.16 rows=1 width=168) (actual time=141.185..153.300 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared read=22116
                     I/O Timings: shared read=150.539
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.884..5.245 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=2.558
                     ->  Parallel Hash  (cost=25071.27..25071.27 rows=20797 width=93) (actual time=140.165..140.166 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16512kB
                           Buffers: shared read=20564
                           I/O Timings: shared read=147.981
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=2113.11..25071.27 rows=20797 width=93) (actual time=5.294..120.031 rows=59645.00 loops=2)
                                 Recheck Cond: ((encounterclass)::text = 'ambulatory'::text)
                                 Filter: ((reasoncode)::text <> ''::text)
                                 Rows Removed by Filter: 35035
                                 Heap Blocks: exact=12814
                                 Buffers: shared read=20564
                                 I/O Timings: shared read=147.981
                                 Worker 0:  Heap Blocks: exact=7583
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..2100.63 rows=190427 width=0) (actual time=6.257..6.257 rows=189360.00 loops=1)
                                       Index Cond: ((encounterclass)::text = 'ambulatory'::text)
                                       Index Searches: 1
                                       Buffers: shared read=167
                                       I/O Timings: shared read=1.248
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=325 read=22
   I/O Timings: shared read=2.048
 Planning Time: 6.073 ms
 Execution Time: 215.732 ms
(48 rows)
```

### PG Index + Baseline SQL EXPLAIN Run 5:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28544.62..28544.63 rows=1 width=174) (actual time=191.083..193.755 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=22116
   I/O Timings: shared read=115.003
   ->  Nested Loop  (cost=26383.51..28544.61 rows=1 width=174) (actual time=145.737..185.043 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=22116
         I/O Timings: shared read=115.003
         ->  Gather  (cost=26383.23..28544.26 rows=1 width=168) (actual time=145.673..150.195 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=22116
               I/O Timings: shared read=115.003
               ->  Parallel Hash Join  (cost=25383.23..27544.16 rows=1 width=168) (actual time=120.655..131.180 rows=4925.00 loops=2)
                     Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (e.patient)::text))
                     Buffers: shared read=22116
                     I/O Timings: shared read=115.003
                     ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.473..4.333 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=1.277
                     ->  Parallel Hash  (cost=25071.27..25071.27 rows=20797 width=93) (actual time=120.037..120.038 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared read=20564
                           I/O Timings: shared read=113.727
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=2113.11..25071.27 rows=20797 width=93) (actual time=5.405..101.555 rows=59645.00 loops=2)
                                 Recheck Cond: ((encounterclass)::text = 'ambulatory'::text)
                                 Filter: ((reasoncode)::text <> ''::text)
                                 Rows Removed by Filter: 35035
                                 Heap Blocks: exact=13290
                                 Buffers: shared read=20564
                                 I/O Timings: shared read=113.727
                                 Worker 0:  Heap Blocks: exact=7107
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..2100.63 rows=190427 width=0) (actual time=6.350..6.351 rows=189360.00 loops=1)
                                       Index Cond: ((encounterclass)::text = 'ambulatory'::text)
                                       Index Searches: 1
                                       Buffers: shared read=167
                                       I/O Timings: shared read=1.134
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=325 read=22
   I/O Timings: shared read=2.009
 Planning Time: 6.228 ms
 Execution Time: 194.192 ms
(48 rows)
```

### PG Index + Rewrite SQL (`> ''`) Timing: [222.529, 196.156, 195.339, 209.114, 256.186] | median=209.114 ms

### PG Index + Rewrite SQL EXPLAIN Run 1:
```text
SET
                                                                                 QUERY PLAN                                                                                 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=26242.15..26242.16 rows=1 width=174) (actual time=235.040..238.031 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=177.488
   ->  Nested Loop  (cost=24081.05..26242.14 rows=1 width=174) (actual time=177.826..227.915 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=177.488
         ->  Gather  (cost=24080.76..26241.80 rows=1 width=168) (actual time=177.773..183.050 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=177.488
               ->  Parallel Hash Join  (cost=23080.76..25241.70 rows=1 width=168) (actual time=153.052..166.733 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=177.488
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.746..5.988 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=2.318
                     ->  Parallel Hash  (cost=22768.58..22768.58 rows=20812 width=93) (actual time=152.143..152.144 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=175.169
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=688.40..22768.58 rows=20812 width=93) (actual time=4.282..130.308 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=11611
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=175.169
                                 Worker 0:  Heap Blocks: exact=6769
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..675.91 rows=49949 width=0) (actual time=5.474..5.474 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.853
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.004..0.004 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=306 read=42
   I/O Timings: shared read=4.263
 Planning Time: 8.734 ms
 Execution Time: 238.532 ms
(46 rows)
```

### PG Index + Rewrite SQL EXPLAIN Run 2:
```text
SET
                                                                                 QUERY PLAN                                                                                 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=26242.15..26242.16 rows=1 width=174) (actual time=224.973..227.779 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=176.909
   ->  Nested Loop  (cost=24081.05..26242.14 rows=1 width=174) (actual time=179.225..219.011 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=176.909
         ->  Gather  (cost=24080.76..26241.80 rows=1 width=168) (actual time=179.128..184.297 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=176.909
               ->  Parallel Hash Join  (cost=23080.76..25241.70 rows=1 width=168) (actual time=156.447..167.571 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=176.909
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.605..4.871 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=1.792
                     ->  Parallel Hash  (cost=22768.58..22768.58 rows=20812 width=93) (actual time=155.679..155.680 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=175.117
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=688.40..22768.58 rows=20812 width=93) (actual time=4.453..132.119 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=11706
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=175.117
                                 Worker 0:  Heap Blocks: exact=6674
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..675.91 rows=49949 width=0) (actual time=4.578..4.578 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.700
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=308 read=40
   I/O Timings: shared read=3.959
 Planning Time: 8.334 ms
 Execution Time: 228.284 ms
(46 rows)
```

### PG Index + Rewrite SQL EXPLAIN Run 3:
```text
SET
                                                                                 QUERY PLAN                                                                                 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=26242.15..26242.16 rows=1 width=174) (actual time=191.053..193.748 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=141.576
   ->  Nested Loop  (cost=24081.05..26242.14 rows=1 width=174) (actual time=144.459..184.667 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=141.576
         ->  Gather  (cost=24080.76..26241.80 rows=1 width=168) (actual time=144.388..149.370 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=141.576
               ->  Parallel Hash Join  (cost=23080.76..25241.70 rows=1 width=168) (actual time=125.248..136.786 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=141.576
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.659..5.179 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=2.202
                     ->  Parallel Hash  (cost=22768.58..22768.58 rows=20812 width=93) (actual time=124.413..124.414 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16512kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=139.375
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=688.40..22768.58 rows=20812 width=93) (actual time=3.909..105.813 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=11211
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=139.375
                                 Worker 0:  Heap Blocks: exact=7169
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..675.91 rows=49949 width=0) (actual time=4.781..4.782 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.698
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=326 read=22
   I/O Timings: shared read=2.194
 Planning Time: 6.019 ms
 Execution Time: 194.256 ms
(46 rows)
```

### PG Index + Rewrite SQL EXPLAIN Run 4:
```text
SET
                                                                                 QUERY PLAN                                                                                 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=26242.15..26242.16 rows=1 width=174) (actual time=194.372..197.504 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=119.509
   ->  Nested Loop  (cost=24081.05..26242.14 rows=1 width=174) (actual time=147.633..188.181 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=119.509
         ->  Gather  (cost=24080.76..26241.80 rows=1 width=168) (actual time=147.572..152.352 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=119.509
               ->  Parallel Hash Join  (cost=23080.76..25241.70 rows=1 width=168) (actual time=121.100..132.458 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=119.509
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.425..4.735 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=1.209
                     ->  Parallel Hash  (cost=22768.58..22768.58 rows=20812 width=93) (actual time=120.548..120.550 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=118.300
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=688.40..22768.58 rows=20812 width=93) (actual time=4.301..99.635 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=11961
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=118.300
                                 Worker 0:  Heap Blocks: exact=6419
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..675.91 rows=49949 width=0) (actual time=4.405..4.405 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.662
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=326 read=22
   I/O Timings: shared read=2.212
 Planning Time: 6.392 ms
 Execution Time: 198.024 ms
(46 rows)
```

### PG Index + Rewrite SQL EXPLAIN Run 5:
```text
SET
                                                                                 QUERY PLAN                                                                                 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=26242.15..26242.16 rows=1 width=174) (actual time=200.294..203.145 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=148.532
   ->  Nested Loop  (cost=24081.05..26242.14 rows=1 width=174) (actual time=154.656..194.239 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=148.532
         ->  Gather  (cost=24080.76..26241.80 rows=1 width=168) (actual time=154.609..159.524 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=148.532
               ->  Parallel Hash Join  (cost=23080.76..25241.70 rows=1 width=168) (actual time=130.216..141.624 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=148.532
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22139 width=112) (actual time=0.434..4.796 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=1.591
                     ->  Parallel Hash  (cost=22768.58..22768.58 rows=20812 width=93) (actual time=129.582..129.584 rows=59645.00 loops=2)
                           Buckets: 131072 (originally 65536)  Batches: 1 (originally 1)  Memory Usage: 16544kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=146.941
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=688.40..22768.58 rows=20812 width=93) (actual time=3.957..110.841 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=11214
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=146.941
                                 Worker 0:  Heap Blocks: exact=7166
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..675.91 rows=49949 width=0) (actual time=4.715..4.715 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.691
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.34 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=308 read=40
   I/O Timings: shared read=4.218
 Planning Time: 9.084 ms
 Execution Time: 203.658 ms
(46 rows)
```

### MySQL Index Setup & Sizes
```text
table_name	index_name	size_bytes
conditions	idx_q2_cond_stop_enc	5783552
encounters	idx_q2_enc_class_reason	35258368
Table	Op	Msg_type	Msg_text
synthea_scale.encounters	analyze	status	OK
synthea_scale.conditions	analyze	status	OK

table_name	index_name	size_bytes	size_mb
conditions	idx_q2_cond_stop_enc	5783552	5.52
encounters	idx_q2_enc_class_reason	35258368	33.63
delta_d_bytes	delta_d_mb
41041920	39.14
```

### MySQL Index + Baseline SQL (`<> ''`) Timing: [3272.922, 2975.173, 2957.327, 3012.464, 2779.042] | median=2975.173 ms

### MySQL Index + Baseline SQL EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=3319..3321 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.223..3262 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.205..3194 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.179..3033 rows=9850 loops=1)
                -> Filter: (c.patient is not null)  (cost=4760 rows=41591) (actual time=0.0625..456 rows=38110 loops=1)
                    -> Index lookup on c using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((c.`stop` is null) and (c.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0612..443 rows=38110 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.582 rows=0.05) (actual time=0.067..0.0671 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.582 rows=1) (actual time=0.0642..0.0643 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0155..0.0156 rows=1 loops=9850)
```

### MySQL Index + Baseline SQL EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=3279..3287 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.187..3223 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.175..3161 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.154..3005 rows=9850 loops=1)
                -> Filter: (c.patient is not null)  (cost=4760 rows=41591) (actual time=0.0506..394 rows=38110 loops=1)
                    -> Index lookup on c using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((c.`stop` is null) and (c.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0497..383 rows=38110 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.582 rows=0.05) (actual time=0.068..0.068 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.582 rows=1) (actual time=0.0654..0.0655 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.015..0.0151 rows=1 loops=9850)
```

### MySQL Index + Baseline SQL EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=3083..3095 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.0643..3027 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.0586..2966 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.0502..2820 rows=9850 loops=1)
                -> Filter: (c.patient is not null)  (cost=4760 rows=41591) (actual time=0.023..409 rows=38110 loops=1)
                    -> Index lookup on c using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((c.`stop` is null) and (c.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0225..397 rows=38110 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.582 rows=0.05) (actual time=0.0627..0.0628 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.582 rows=1) (actual time=0.0602..0.0603 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.014..0.0141 rows=1 loops=9850)
```

### MySQL Index + Baseline SQL EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=3216..3222 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.0562..3151 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.0508..3090 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.0436..2939 rows=9850 loops=1)
                -> Filter: (c.patient is not null)  (cost=4760 rows=41591) (actual time=0.0185..399 rows=38110 loops=1)
                    -> Index lookup on c using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((c.`stop` is null) and (c.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0182..388 rows=38110 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.582 rows=0.05) (actual time=0.0661..0.0662 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.582 rows=1) (actual time=0.0637..0.0638 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0145..0.0146 rows=1 loops=9850)
```

### MySQL Index + Baseline SQL EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=3184..3188 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.225..3128 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.209..3066 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.183..2917 rows=9850 loops=1)
                -> Filter: (c.patient is not null)  (cost=4760 rows=41591) (actual time=0.064..411 rows=38110 loops=1)
                    -> Index lookup on c using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((c.`stop` is null) and (c.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0627..400 rows=38110 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.582 rows=0.05) (actual time=0.0652..0.0653 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.582 rows=1) (actual time=0.0626..0.0626 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0142..0.0143 rows=1 loops=9850)
```

### MySQL Index + Rewrite SQL (`> ''`) Timing: [2808.673, 3332.386, 3493.554, 3701.206, 3801.106] | median=3493.554 ms

### MySQL Index + Rewrite SQL EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3502..3512 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.0755..3439 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.0674..3363 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.0583..3212 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4760 rows=41591) (actual time=0.0268..418 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0264..406 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.582 rows=0.05) (actual time=0.0727..0.0728 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.582 rows=1) (actual time=0.0709..0.071 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0145..0.0146 rows=1 loops=9850)
```

### MySQL Index + Rewrite SQL EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3626..3633 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.0658..3559 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.0594..3480 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.0517..3329 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4760 rows=41591) (actual time=0.0252..422 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0248..411 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.582 rows=0.05) (actual time=0.0757..0.0758 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.582 rows=1) (actual time=0.0739..0.074 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0145..0.0146 rows=1 loops=9850)
```

### MySQL Index + Rewrite SQL EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3574..3580 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.0616..3509 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.0558..3430 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.0485..3277 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4760 rows=41591) (actual time=0.0197..413 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0194..402 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.582 rows=0.05) (actual time=0.0746..0.0746 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.582 rows=1) (actual time=0.0726..0.0727 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0147..0.0148 rows=1 loops=9850)
```

### MySQL Index + Rewrite SQL EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3883..3886 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.301..3818 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.275..3729 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.24..3550 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4760 rows=41591) (actual time=0.0943..510 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0928..494 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.582 rows=0.05) (actual time=0.0791..0.0792 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.582 rows=1) (actual time=0.0769..0.077 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0172..0.0173 rows=1 loops=9850)
```

### MySQL Index + Rewrite SQL EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=2914..2926 rows=9850 loops=1)
    -> Stream results  (cost=33856 rows=2080) (actual time=0.0629..2864 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33856 rows=2080) (actual time=0.0563..2795 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33128 rows=2080) (actual time=0.0484..2653 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4760 rows=41591) (actual time=0.0207..377 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4760 rows=41591) (actual time=0.0202..367 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.582 rows=0.05) (actual time=0.0592..0.0592 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.582 rows=1) (actual time=0.0575..0.0576 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0137..0.0137 rows=1 loops=9850)
```

## 4. Q2 Statistics

### PG Stats Setup
```text
CREATE STATISTICS
ANALYZE
    statistics_name     |          attnames           | kinds 
------------------------+-----------------------------+-------
 st_q2_enc_class_reason | {encounterclass,reasoncode} | {m}
(1 row)
```

### PG Stats + Baseline SQL Timing: [161.587, 130.952, 124.015, 125.661, 130.727] | median=130.727 ms

### PG Stats EXPLAIN Run 1:
```text
SET
                                                                         QUERY PLAN                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28856.74..28856.74 rows=1 width=174) (actual time=115.430..117.067 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=44959 read=7917
   I/O Timings: shared read=42.434
   ->  Nested Loop  (cost=3382.52..28856.73 rows=1 width=174) (actual time=18.432..107.513 rows=9850.00 loops=1)
         Buffers: shared hit=44953 read=7917
         I/O Timings: shared read=42.434
         ->  Gather  (cost=3382.24..28856.40 rows=1 width=168) (actual time=18.384..67.180 rows=9850.00 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               Buffers: shared hit=15403 read=7917
               I/O Timings: shared read=42.434
               ->  Parallel Hash Join  (cost=2382.24..27856.30 rows=1 width=168) (actual time=7.477..60.660 rows=3283.33 loops=3)
                     Hash Cond: (((e.id)::text = (c.encounter)::text) AND ((e.patient)::text = (c.patient)::text))
                     Buffers: shared hit=15403 read=7917
                     I/O Timings: shared read=42.434
                     ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=49591 width=93) (actual time=1.293..44.277 rows=39763.33 loops=3)
                           Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                           Rows Removed by Filter: 138057
                           Buffers: shared hit=13851 read=7917
                           I/O Timings: shared read=42.434
                     ->  Parallel Hash  (cost=2044.71..2044.71 rows=22502 width=112) (actual time=5.850..5.851 rows=12703.33 loops=3)
                           Buckets: 65536  Batches: 1  Memory Usage: 6144kB
                           Buffers: shared hit=1552
                           ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22502 width=112) (actual time=0.011..8.614 rows=38110.00 loops=1)
                                 Filter: (stop IS NULL)
                                 Rows Removed by Filter: 45650
                                 Buffers: shared hit=1552
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.004..0.004 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=278 read=40
   I/O Timings: shared read=4.876
 Planning Time: 8.230 ms
 Execution Time: 117.519 ms
(38 rows)
```

### PG Stats EXPLAIN Run 2:
```text
SET
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28856.74..28856.74 rows=1 width=174) (actual time=134.784..136.465 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=44959 read=7917
   I/O Timings: shared read=52.712
   ->  Nested Loop  (cost=3382.52..28856.73 rows=1 width=174) (actual time=31.558..126.072 rows=9850.00 loops=1)
         Buffers: shared hit=44953 read=7917
         I/O Timings: shared read=52.712
         ->  Gather  (cost=3382.24..28856.40 rows=1 width=168) (actual time=31.500..80.356 rows=9850.00 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               Buffers: shared hit=15403 read=7917
               I/O Timings: shared read=52.712
               ->  Parallel Hash Join  (cost=2382.24..27856.30 rows=1 width=168) (actual time=11.092..69.395 rows=3283.33 loops=3)
                     Hash Cond: (((e.id)::text = (c.encounter)::text) AND ((e.patient)::text = (c.patient)::text))
                     Buffers: shared hit=15403 read=7917
                     I/O Timings: shared read=52.712
                     ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=49591 width=93) (actual time=0.952..48.582 rows=39763.33 loops=3)
                           Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                           Rows Removed by Filter: 138057
                           Buffers: shared hit=13851 read=7917
                           I/O Timings: shared read=52.712
                     ->  Parallel Hash  (cost=2044.71..2044.71 rows=22502 width=112) (actual time=9.944..9.944 rows=12703.33 loops=3)
                           Buckets: 65536  Batches: 1  Memory Usage: 6144kB
                           Buffers: shared hit=1552
                           ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22502 width=112) (actual time=0.016..14.059 rows=38110.00 loops=1)
                                 Filter: (stop IS NULL)
                                 Rows Removed by Filter: 45650
                                 Buffers: shared hit=1552
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.004..0.004 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=318
 Planning Time: 3.830 ms
 Execution Time: 136.915 ms
(37 rows)
```

### PG Stats EXPLAIN Run 3:
```text
SET
                                                                         QUERY PLAN                                                                          
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28856.74..28856.74 rows=1 width=174) (actual time=134.295..136.006 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=44959 read=7917
   I/O Timings: shared read=89.250
   ->  Nested Loop  (cost=3382.52..28856.73 rows=1 width=174) (actual time=21.361..124.795 rows=9850.00 loops=1)
         Buffers: shared hit=44953 read=7917
         I/O Timings: shared read=89.250
         ->  Gather  (cost=3382.24..28856.40 rows=1 width=168) (actual time=21.309..84.390 rows=9850.00 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               Buffers: shared hit=15403 read=7917
               I/O Timings: shared read=89.250
               ->  Parallel Hash Join  (cost=2382.24..27856.30 rows=1 width=168) (actual time=7.987..77.038 rows=3283.33 loops=3)
                     Hash Cond: (((e.id)::text = (c.encounter)::text) AND ((e.patient)::text = (c.patient)::text))
                     Buffers: shared hit=15403 read=7917
                     I/O Timings: shared read=89.250
                     ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=49591 width=93) (actual time=1.214..59.746 rows=39763.33 loops=3)
                           Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                           Rows Removed by Filter: 138057
                           Buffers: shared hit=13851 read=7917
                           I/O Timings: shared read=89.250
                     ->  Parallel Hash  (cost=2044.71..2044.71 rows=22502 width=112) (actual time=6.596..6.597 rows=12703.33 loops=3)
                           Buckets: 65536  Batches: 1  Memory Usage: 6144kB
                           Buffers: shared hit=1552
                           ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22502 width=112) (actual time=0.032..9.575 rows=38110.00 loops=1)
                                 Filter: (stop IS NULL)
                                 Rows Removed by Filter: 45650
                                 Buffers: shared hit=1552
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.004..0.004 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=318
 Planning Time: 3.614 ms
 Execution Time: 136.465 ms
(37 rows)
```

### PG Stats EXPLAIN Run 4:
```text
SET
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28856.74..28856.74 rows=1 width=174) (actual time=127.164..128.523 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=44959 read=7917
   I/O Timings: shared read=51.184
   ->  Nested Loop  (cost=3382.52..28856.73 rows=1 width=174) (actual time=30.216..119.041 rows=9850.00 loops=1)
         Buffers: shared hit=44953 read=7917
         I/O Timings: shared read=51.184
         ->  Gather  (cost=3382.24..28856.40 rows=1 width=168) (actual time=30.137..79.072 rows=9850.00 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               Buffers: shared hit=15403 read=7917
               I/O Timings: shared read=51.184
               ->  Parallel Hash Join  (cost=2382.24..27856.30 rows=1 width=168) (actual time=11.218..65.687 rows=3283.33 loops=3)
                     Hash Cond: (((e.id)::text = (c.encounter)::text) AND ((e.patient)::text = (c.patient)::text))
                     Buffers: shared hit=15403 read=7917
                     I/O Timings: shared read=51.184
                     ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=49591 width=93) (actual time=1.248..46.256 rows=39763.33 loops=3)
                           Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                           Rows Removed by Filter: 138057
                           Buffers: shared hit=13851 read=7917
                           I/O Timings: shared read=51.184
                     ->  Parallel Hash  (cost=2044.71..2044.71 rows=22502 width=112) (actual time=9.325..9.325 rows=12703.33 loops=3)
                           Buckets: 65536  Batches: 1  Memory Usage: 6144kB
                           Buffers: shared hit=1552
                           ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22502 width=112) (actual time=0.014..13.342 rows=38110.00 loops=1)
                                 Filter: (stop IS NULL)
                                 Rows Removed by Filter: 45650
                                 Buffers: shared hit=1552
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.004..0.004 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=318
 Planning Time: 3.750 ms
 Execution Time: 128.985 ms
(37 rows)
```

### PG Stats EXPLAIN Run 5:
```text
SET
                                                                          QUERY PLAN                                                                          
--------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28856.74..28856.74 rows=1 width=174) (actual time=161.432..163.105 rows=9850.00 loops=1)
   Sort Key: c.start DESC, p.id, e.id, c.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=45053 read=7823
   I/O Timings: shared read=23.108
   ->  Nested Loop  (cost=3382.52..28856.73 rows=1 width=174) (actual time=22.478..152.107 rows=9850.00 loops=1)
         Buffers: shared hit=45047 read=7823
         I/O Timings: shared read=23.108
         ->  Gather  (cost=3382.24..28856.40 rows=1 width=168) (actual time=22.427..104.430 rows=9850.00 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               Buffers: shared hit=15497 read=7823
               I/O Timings: shared read=23.108
               ->  Parallel Hash Join  (cost=2382.24..27856.30 rows=1 width=168) (actual time=7.854..59.644 rows=3283.33 loops=3)
                     Hash Cond: (((e.id)::text = (c.encounter)::text) AND ((e.patient)::text = (c.patient)::text))
                     Buffers: shared hit=15497 read=7823
                     I/O Timings: shared read=23.108
                     ->  Parallel Seq Scan on encounters e  (cost=0.00..25102.12 rows=49591 width=93) (actual time=1.190..61.356 rows=59645.00 loops=2)
                           Filter: (((reasoncode)::text <> ''::text) AND ((encounterclass)::text = 'ambulatory'::text))
                           Rows Removed by Filter: 207085
                           Buffers: shared hit=13945 read=7823
                           I/O Timings: shared read=23.108
                     ->  Parallel Hash  (cost=2044.71..2044.71 rows=22502 width=112) (actual time=6.940..6.940 rows=12703.33 loops=3)
                           Buckets: 65536  Batches: 1  Memory Usage: 6144kB
                           Buffers: shared hit=1552
                           ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=22502 width=112) (actual time=0.014..10.017 rows=38110.00 loops=1)
                                 Filter: (stop IS NULL)
                                 Rows Removed by Filter: 45650
                                 Buffers: shared hit=1552
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.004..0.004 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (e.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=318
 Planning Time: 3.759 ms
 Execution Time: 163.572 ms
(37 rows)
```

### MySQL Stats (Histograms) Setup
```text
Table	Op	Msg_type	Msg_text
synthea_scale.encounters	histogram	status	Histogram statistics created for column 'encounterclass'.
synthea_scale.encounters	histogram	status	Histogram statistics created for column 'reasoncode'.
Table	Op	Msg_type	Msg_text
synthea_scale.conditions	histogram	status	Histogram statistics created for column 'stop'.
TABLE_NAME	COLUMN_NAME
conditions	stop
encounters	encounterclass
encounters	reasoncode
```

### MySQL Stats + Baseline SQL Timing: [4308.369, 4055.866, 4334.511, 4204.335, 4428.7] | median=4308.369 ms

### MySQL Stats EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=4573..4576 rows=9850 loops=1)
    -> Stream results  (cost=31164 rows=1892) (actual time=3.08..4514 rows=9850 loops=1)
        -> Nested loop inner join  (cost=31164 rows=1892) (actual time=3.06..4448 rows=9850 loops=1)
            -> Nested loop inner join  (cost=30502 rows=1892) (actual time=3.01..4337 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8519 rows=37847) (actual time=2.93..368 rows=38110 loops=1)
                    -> Table scan on c  (cost=8519 rows=83183) (actual time=2.93..329 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.481 rows=0.05) (actual time=0.104..0.104 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.481 rows=1) (actual time=0.101..0.101 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0105..0.0106 rows=1 loops=9850)
```

### MySQL Stats EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=4040..4047 rows=9850 loops=1)
    -> Stream results  (cost=30261 rows=1892) (actual time=2.54..3973 rows=9850 loops=1)
        -> Nested loop inner join  (cost=30261 rows=1892) (actual time=2.53..3909 rows=9850 loops=1)
            -> Nested loop inner join  (cost=29599 rows=1892) (actual time=2.51..3801 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8519 rows=37847) (actual time=2.47..319 rows=38110 loops=1)
                    -> Table scan on c  (cost=8519 rows=83183) (actual time=2.46..283 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.457 rows=0.05) (actual time=0.0909..0.0909 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.457 rows=1) (actual time=0.0885..0.0885 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0101..0.0102 rows=1 loops=9850)
```

### MySQL Stats EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=4369..4375 rows=9850 loops=1)
    -> Stream results  (cost=30261 rows=1892) (actual time=3.07..4304 rows=9850 loops=1)
        -> Nested loop inner join  (cost=30261 rows=1892) (actual time=3.05..4238 rows=9850 loops=1)
            -> Nested loop inner join  (cost=29599 rows=1892) (actual time=3.02..4121 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8519 rows=37847) (actual time=2.94..358 rows=38110 loops=1)
                    -> Table scan on c  (cost=8519 rows=83183) (actual time=2.94..316 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.457 rows=0.05) (actual time=0.0983..0.0983 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.457 rows=1) (actual time=0.0955..0.0956 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0109..0.011 rows=1 loops=9850)
```

### MySQL Stats EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=4507..4512 rows=9850 loops=1)
    -> Stream results  (cost=30261 rows=1892) (actual time=3.42..4445 rows=9850 loops=1)
        -> Nested loop inner join  (cost=30261 rows=1892) (actual time=3.37..4379 rows=9850 loops=1)
            -> Nested loop inner join  (cost=29599 rows=1892) (actual time=3.35..4265 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8519 rows=37847) (actual time=3.28..337 rows=38110 loops=1)
                    -> Table scan on c  (cost=8519 rows=83183) (actual time=3.28..296 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.457 rows=0.05) (actual time=0.103..0.103 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.457 rows=1) (actual time=0.1..0.1 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0107..0.0108 rows=1 loops=9850)
```

### MySQL Stats EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: c.`start` DESC, p.id, e.id, c.`code`  (actual time=4849..4855 rows=9850 loops=1)
    -> Stream results  (cost=30261 rows=1892) (actual time=3.54..4784 rows=9850 loops=1)
        -> Nested loop inner join  (cost=30261 rows=1892) (actual time=3.51..4710 rows=9850 loops=1)
            -> Nested loop inner join  (cost=29599 rows=1892) (actual time=3.48..4590 rows=9850 loops=1)
                -> Filter: ((c.`stop` is null) and (c.encounter is not null) and (c.patient is not null))  (cost=8519 rows=37847) (actual time=3.39..352 rows=38110 loops=1)
                    -> Table scan on c  (cost=8519 rows=83183) (actual time=3.38..310 rows=83760 loops=1)
                -> Filter: ((e.patient = c.patient) and (e.encounterclass = 'ambulatory') and (e.reasoncode <> ''))  (cost=0.457 rows=0.05) (actual time=0.111..0.111 rows=0.258 loops=38110)
                    -> Single-row index lookup on e using PRIMARY (id = c.encounter)  (cost=0.457 rows=1) (actual time=0.108..0.108 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = c.patient)  (cost=0.25 rows=1) (actual time=0.0114..0.0115 rows=1 loops=9850)
```

## 5. Q2 Combined (Indexes + Stats + Rewrite)

### PG Combined Setup
```text
CREATE INDEX
CREATE INDEX
CREATE STATISTICS
ANALYZE
        indexname        |  size   
-------------------------+---------
 idx_q2_cond_active      | 3432 kB
 idx_q2_enc_class_reason | 3744 kB
(2 rows)

ANALYZE
```

### PG Combined Timing: [184.104, 214.17, 195.19, 182.18, 191.72] | median=191.720 ms

### PG Combined EXPLAIN Run 1:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28035.51..28035.52 rows=1 width=174) (actual time=179.964..182.737 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=112.797
   ->  Nested Loop  (cost=25874.19..28035.50 rows=1 width=174) (actual time=132.036..173.800 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=112.797
         ->  Gather  (cost=25873.91..28035.18 rows=1 width=168) (actual time=131.959..137.939 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=112.797
               ->  Parallel Hash Join  (cost=24873.91..27035.08 rows=1 width=168) (actual time=112.939..124.828 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=112.797
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22184 width=112) (actual time=0.459..4.882 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=2.033
                     ->  Parallel Hash  (cost=24135.04..24135.04 rows=49258 width=93) (actual time=112.250..112.252 rows=59645.00 loops=2)
                           Buckets: 131072  Batches: 1  Memory Usage: 16000kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=110.764
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=1628.17..24135.04 rows=49258 width=93) (actual time=3.884..93.888 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=11333
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=110.764
                                 Worker 0:  Heap Blocks: exact=7047
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..1598.62 rows=118219 width=0) (actual time=4.533..4.533 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.701
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=306 read=48
   I/O Timings: shared read=3.442
 Planning Time: 6.931 ms
 Execution Time: 183.211 ms
(46 rows)
```

### PG Combined EXPLAIN Run 2:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28035.51..28035.52 rows=1 width=174) (actual time=192.752..195.539 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=127.030
   ->  Nested Loop  (cost=25874.19..28035.50 rows=1 width=174) (actual time=144.645..186.566 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=127.030
         ->  Gather  (cost=25873.91..28035.18 rows=1 width=168) (actual time=144.576..150.638 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=127.030
               ->  Parallel Hash Join  (cost=24873.91..27035.08 rows=1 width=168) (actual time=118.936..131.121 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=127.030
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22184 width=112) (actual time=0.596..5.101 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=2.103
                     ->  Parallel Hash  (cost=24135.04..24135.04 rows=49258 width=93) (actual time=118.072..118.073 rows=59645.00 loops=2)
                           Buckets: 131072  Batches: 1  Memory Usage: 16032kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=124.927
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=1628.17..24135.04 rows=49258 width=93) (actual time=3.890..99.895 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=11373
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=124.927
                                 Worker 0:  Heap Blocks: exact=7007
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..1598.62 rows=118219 width=0) (actual time=4.752..4.752 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.699
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=325 read=29
   I/O Timings: shared read=4.564
 Planning Time: 8.916 ms
 Execution Time: 196.064 ms
(46 rows)
```

### PG Combined EXPLAIN Run 3:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28035.51..28035.52 rows=1 width=174) (actual time=195.615..198.602 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=102.257
   ->  Nested Loop  (cost=25874.19..28035.50 rows=1 width=174) (actual time=149.566..189.734 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=102.257
         ->  Gather  (cost=25873.91..28035.18 rows=1 width=168) (actual time=149.507..154.246 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=102.257
               ->  Parallel Hash Join  (cost=24873.91..27035.08 rows=1 width=168) (actual time=110.564..122.099 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=102.257
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22184 width=112) (actual time=0.444..4.392 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=1.119
                     ->  Parallel Hash  (cost=24135.04..24135.04 rows=49258 width=93) (actual time=109.895..109.896 rows=59645.00 loops=2)
                           Buckets: 131072  Batches: 1  Memory Usage: 16000kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=101.138
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=1628.17..24135.04 rows=49258 width=93) (actual time=4.392..90.453 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=13872
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=101.138
                                 Worker 0:  Heap Blocks: exact=4508
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..1598.62 rows=118219 width=0) (actual time=5.018..5.018 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.799
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=308 read=46
   I/O Timings: shared read=5.832
 Planning Time: 10.498 ms
 Execution Time: 199.111 ms
(46 rows)
```

### PG Combined EXPLAIN Run 4:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28035.51..28035.52 rows=1 width=174) (actual time=189.169..191.788 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=118.915
   ->  Nested Loop  (cost=25874.19..28035.50 rows=1 width=174) (actual time=141.295..183.190 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=118.915
         ->  Gather  (cost=25873.91..28035.18 rows=1 width=168) (actual time=141.250..145.901 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=118.915
               ->  Parallel Hash Join  (cost=24873.91..27035.08 rows=1 width=168) (actual time=116.390..128.705 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=118.915
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22184 width=112) (actual time=0.452..4.868 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=1.306
                     ->  Parallel Hash  (cost=24135.04..24135.04 rows=49258 width=93) (actual time=115.660..115.661 rows=59645.00 loops=2)
                           Buckets: 131072  Batches: 1  Memory Usage: 16032kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=117.610
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=1628.17..24135.04 rows=49258 width=93) (actual time=4.215..97.037 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=12416
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=117.610
                                 Worker 0:  Heap Blocks: exact=5964
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..1598.62 rows=118219 width=0) (actual time=5.163..5.164 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.765
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=329 read=25
   I/O Timings: shared read=2.602
 Planning Time: 5.977 ms
 Execution Time: 192.230 ms
(46 rows)
```

### PG Combined EXPLAIN Run 5:
```text
SET
                                                                                  QUERY PLAN                                                                                  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=28035.51..28035.52 rows=1 width=174) (actual time=184.549..187.298 rows=9850.00 loops=1)
   Sort Key: conditions.start DESC, p.id, encounters.id, conditions.code
   Sort Method: quicksort  Memory: 2223kB
   Buffers: shared hit=29556 read=20038
   I/O Timings: shared read=107.566
   ->  Nested Loop  (cost=25874.19..28035.50 rows=1 width=174) (actual time=136.208..178.103 rows=9850.00 loops=1)
         Buffers: shared hit=29550 read=20038
         I/O Timings: shared read=107.566
         ->  Gather  (cost=25873.91..28035.18 rows=1 width=168) (actual time=136.148..140.901 rows=9850.00 loops=1)
               Workers Planned: 1
               Workers Launched: 1
               Buffers: shared read=20038
               I/O Timings: shared read=107.566
               ->  Parallel Hash Join  (cost=24873.91..27035.08 rows=1 width=168) (actual time=110.820..122.475 rows=4925.00 loops=2)
                     Hash Cond: (((conditions.encounter)::text = (encounters.id)::text) AND ((conditions.patient)::text = (encounters.patient)::text))
                     Buffers: shared read=20038
                     I/O Timings: shared read=107.566
                     ->  Parallel Seq Scan on conditions  (cost=0.00..2044.71 rows=22184 width=112) (actual time=0.439..4.636 rows=19055.00 loops=2)
                           Filter: (stop IS NULL)
                           Rows Removed by Filter: 22825
                           Buffers: shared read=1552
                           I/O Timings: shared read=1.240
                     ->  Parallel Hash  (cost=24135.04..24135.04 rows=49258 width=93) (actual time=110.167..110.169 rows=59645.00 loops=2)
                           Buckets: 131072  Batches: 1  Memory Usage: 16000kB
                           Buffers: shared read=18486
                           I/O Timings: shared read=106.327
                           ->  Parallel Bitmap Heap Scan on encounters  (cost=1628.17..24135.04 rows=49258 width=93) (actual time=4.260..91.662 rows=59645.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                 Heap Blocks: exact=11645
                                 Buffers: shared read=18486
                                 I/O Timings: shared read=106.327
                                 Worker 0:  Heap Blocks: exact=6735
                                 ->  Bitmap Index Scan on idx_q2_enc_class_reason  (cost=0.00..1598.62 rows=118219 width=0) (actual time=4.420..4.420 rows=119290.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND ((reasoncode)::text > ''::text))
                                       Index Searches: 1
                                       Buffers: shared read=106
                                       I/O Timings: shared read=0.677
         ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.32 rows=1 width=67) (actual time=0.003..0.003 rows=1.00 loops=9850)
               Index Cond: ((id)::text = (encounters.patient)::text)
               Index Searches: 9850
               Buffers: shared hit=29550
 Planning:
   Buffers: shared hit=329 read=25
   I/O Timings: shared read=2.380
 Planning Time: 5.710 ms
 Execution Time: 187.824 ms
(46 rows)
```

### MySQL Combined Setup
```text
Table	Op	Msg_type	Msg_text
synthea_scale.encounters	histogram	status	Histogram statistics created for column 'encounterclass'.
synthea_scale.encounters	histogram	status	Histogram statistics created for column 'reasoncode'.
Table	Op	Msg_type	Msg_text
synthea_scale.conditions	histogram	status	Histogram statistics created for column 'stop'.
table_name	index_name	size_bytes
conditions	idx_q2_cond_stop_enc	5783552
encounters	idx_q2_enc_class_reason	35258368
Table	Op	Msg_type	Msg_text
synthea_scale.encounters	analyze	status	OK
synthea_scale.conditions	analyze	status	OK
```

### MySQL Combined Timing: [3023.618, 2913.209, 2786.497, 2850.48, 3279.778] | median=2913.209 ms

### MySQL Combined EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3260..3265 rows=9850 loops=1)
    -> Stream results  (cost=33781 rows=2078) (actual time=0.304..3202 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33781 rows=2078) (actual time=0.295..3134 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33054 rows=2078) (actual time=0.284..2988 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4756 rows=41552) (actual time=0.0237..394 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4756 rows=41552) (actual time=0.0227..382 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.581 rows=0.05) (actual time=0.0676..0.0676 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.581 rows=1) (actual time=0.0658..0.0659 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0141..0.0141 rows=1 loops=9850)
```

### MySQL Combined EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=2871..2876 rows=9850 loops=1)
    -> Stream results  (cost=33781 rows=2078) (actual time=0.727..2813 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33781 rows=2078) (actual time=0.706..2747 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33054 rows=2078) (actual time=0.679..2608 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4756 rows=41552) (actual time=0.0761..374 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4756 rows=41552) (actual time=0.0748..363 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.581 rows=0.05) (actual time=0.0581..0.0581 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.581 rows=1) (actual time=0.0563..0.0564 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0133..0.0134 rows=1 loops=9850)
```

### MySQL Combined EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=3101..3107 rows=9850 loops=1)
    -> Stream results  (cost=33781 rows=2078) (actual time=0.384..3040 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33781 rows=2078) (actual time=0.368..2968 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33054 rows=2078) (actual time=0.347..2825 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4756 rows=41552) (actual time=0.0259..380 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4756 rows=41552) (actual time=0.0254..370 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.581 rows=0.05) (actual time=0.0636..0.0637 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.581 rows=1) (actual time=0.0619..0.062 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0135..0.0136 rows=1 loops=9850)
```

### MySQL Combined EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=2990..2993 rows=9850 loops=1)
    -> Stream results  (cost=33781 rows=2078) (actual time=0.832..2936 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33781 rows=2078) (actual time=0.8..2869 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33054 rows=2078) (actual time=0.765..2726 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4756 rows=41552) (actual time=0.0703..386 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4756 rows=41552) (actual time=0.0691..374 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.581 rows=0.05) (actual time=0.0608..0.0609 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.581 rows=1) (actual time=0.0591..0.0592 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0137..0.0138 rows=1 loops=9850)
```

### MySQL Combined EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: v.condition_start DESC, p.id, v.encounter_id, v.condition_code  (actual time=4273..4280 rows=9850 loops=1)
    -> Stream results  (cost=33781 rows=2078) (actual time=1.05..4207 rows=9850 loops=1)
        -> Nested loop inner join  (cost=33781 rows=2078) (actual time=1.03..4111 rows=9850 loops=1)
            -> Nested loop inner join  (cost=33054 rows=2078) (actual time=0.986..3906 rows=9850 loops=1)
                -> Filter: (conditions.patient is not null)  (cost=4756 rows=41552) (actual time=0.103..521 rows=38110 loops=1)
                    -> Index lookup on conditions using idx_q2_cond_stop_enc (stop = NULL), with index condition: ((conditions.`stop` is null) and (conditions.encounter is not null))  (cost=4756 rows=41552) (actual time=0.102..506 rows=38110 loops=1)
                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.patient = conditions.patient) and (encounters.reasoncode > ''))  (cost=0.581 rows=0.05) (actual time=0.0882..0.0883 rows=0.258 loops=38110)
                    -> Single-row index lookup on encounters using PRIMARY (id = conditions.encounter)  (cost=0.581 rows=1) (actual time=0.0856..0.0856 rows=1 loops=38110)
            -> Single-row index lookup on p using PRIMARY (id = conditions.patient)  (cost=0.25 rows=1) (actual time=0.0199..0.02 rows=1 loops=9850)
```
