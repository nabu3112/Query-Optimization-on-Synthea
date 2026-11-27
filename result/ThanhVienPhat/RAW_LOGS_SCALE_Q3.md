# RAW LOGS TẤT CẢ CÁC LẦN CHẠY Q3 TRÊN DỮ LIỆU SCALE 10X THUẦN (synthea_scale)

## 0. Phiên bản Hệ quản trị CSDL & Thông số môi trường
```text
version                                 
-------------------------------------------------------------------------
 PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35229, 64-bit
(1 row)

VERSION()
9.4.0
```

### Thông số môi trường & Dung lượng D0 (encounters, observations)
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
 encounters   |   533460 |   209928192 | 200 MB
 observations |  2995100 |   490504192 | 468 MB
(2 rows)

 d0_bytes  | d0_mb  
-----------+--------
 700432384 | 667.98
(1 row)

sort_buffer_size	join_buffer_size	innodb_buffer_pool_size	tmp_table_size
262144	262144	134217728	154140672
TABLE_NAME	TABLE_ROWS	total_bytes	total_mb
encounters	510483	211419136	201.63
observations	2914956	498073600	475.00
d0_bytes	d0_mb
709492736	676.63
```

### Kiểm tra số nhóm kết quả (Group Count Equivalence)
```text
-- PostgreSQL
n_baseline | n_rewrite 
------------+-----------
       4174 |      4174
(1 row)

-- MySQL
n_baseline	n_rewrite
4174	4174
```

## 1. Q3 Baseline

### PG Baseline Timing (5 runs after 1 warm-up): [36585.039, 37860.13, 37275.726, 37065.879, 36567.737] | median=37065.879 ms
```text
Timing is on.
Time: 36738,896 ms (00:36,739)
Time: 36585,039 ms (00:36,585)
Time: 37860,130 ms (00:37,860)
Time: 37275,726 ms (00:37,276)
Time: 37065,879 ms (00:37,066)
Time: 36567,737 ms (00:36,568)
```

### PG Baseline EXPLAIN Run 1:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187370.86..259903.54 rows=53346 width=116) (actual time=7943.530..37322.984 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15825 read=65829, temp read=130677 written=130928
   I/O Timings: shared read=259.720, temp read=1531.431 write=1589.404
   ->  Gather Merge  (cost=187370.86..249501.07 rows=533460 width=163) (actual time=7943.111..22831.052 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15825 read=65829, temp read=130677 written=130928
         I/O Timings: shared read=259.720, temp read=1531.431 write=1589.404
         ->  Sort  (cost=186370.84..186926.53 rows=222275 width=163) (actual time=7746.559..11564.418 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 119968kB
               Buffers: shared hit=15825 read=65829, temp read=130677 written=130928
               I/O Timings: shared read=259.720, temp read=1531.431 write=1589.404
               Worker 0:  Sort Method: external merge  Disk: 120232kB
               Worker 1:  Sort Method: external merge  Disk: 118624kB
               ->  Parallel Hash Right Join  (cost=30798.88..148395.61 rows=222275 width=163) (actual time=568.108..1613.008 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15795 read=65829, temp read=40984 written=41124
                     I/O Timings: shared read=259.720, temp read=192.615 write=367.396
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1247958 width=81) (actual time=1.101..173.510 rows=998990.00 loops=3)
                           Buffers: shared hit=1528 read=58328
                           I/O Timings: shared read=238.232
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=99.539..99.541 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5056kB
                           Buffers: shared hit=14267 read=7501, temp written=7660
                           I/O Timings: shared read=21.488, temp write=70.377
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.218..40.631 rows=177820.00 loops=3)
                                 Buffers: shared hit=14267 read=7501
                                 I/O Timings: shared read=21.488
 Planning:
   Buffers: shared hit=218 read=31
   I/O Timings: shared read=3.958
 Planning Time: 6.478 ms
 Execution Time: 37396.318 ms
(35 rows)
```

### PG Baseline EXPLAIN Run 2:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187370.86..259903.54 rows=53346 width=116) (actual time=7330.975..36569.208 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15822 read=65832, temp read=130677 written=130933
   I/O Timings: shared read=159.366, temp read=1487.121 write=1473.124
   ->  Gather Merge  (cost=187370.86..249501.07 rows=533460 width=163) (actual time=7330.665..21968.855 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15822 read=65832, temp read=130677 written=130933
         I/O Timings: shared read=159.366, temp read=1487.121 write=1473.124
         ->  Sort  (cost=186370.84..186926.53 rows=222275 width=163) (actual time=6955.965..10732.841 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 120080kB
               Buffers: shared hit=15822 read=65832, temp read=130677 written=130933
               I/O Timings: shared read=159.366, temp read=1487.121 write=1473.124
               Worker 0:  Sort Method: external merge  Disk: 117808kB
               Worker 1:  Sort Method: external merge  Disk: 120944kB
               ->  Parallel Hash Right Join  (cost=30798.88..148395.61 rows=222275 width=163) (actual time=527.832..1430.933 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15792 read=65832, temp read=40984 written=41128
                     I/O Timings: shared read=159.366, temp read=152.708 write=400.828
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1247958 width=81) (actual time=1.164..132.630 rows=998990.00 loops=3)
                           Buffers: shared hit=1807 read=58049
                           I/O Timings: shared read=146.031
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=98.271..98.272 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=13985 read=7783, temp written=7664
                           I/O Timings: shared read=13.335, temp write=66.302
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=0.844..39.062 rows=177820.00 loops=3)
                                 Buffers: shared hit=13985 read=7783
                                 I/O Timings: shared read=13.335
 Planning:
   Buffers: shared hit=249
 Planning Time: 2.683 ms
 Execution Time: 36640.354 ms
(34 rows)
```

### PG Baseline EXPLAIN Run 3:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187370.86..259903.54 rows=53346 width=116) (actual time=8449.037..36526.790 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15825 read=65829, temp read=130676 written=130940
   I/O Timings: shared read=448.028, temp read=1542.041 write=2037.932
   ->  Gather Merge  (cost=187370.86..249501.07 rows=533460 width=163) (actual time=8448.769..22477.260 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15825 read=65829, temp read=130676 written=130940
         I/O Timings: shared read=448.028, temp read=1542.041 write=2037.932
         ->  Sort  (cost=186370.84..186926.53 rows=222275 width=163) (actual time=8221.762..11811.724 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 120056kB
               Buffers: shared hit=15825 read=65829, temp read=130676 written=130940
               I/O Timings: shared read=448.028, temp read=1542.041 write=2037.932
               Worker 0:  Sort Method: external merge  Disk: 118080kB
               Worker 1:  Sort Method: external merge  Disk: 120688kB
               ->  Parallel Hash Right Join  (cost=30798.88..148395.61 rows=222275 width=163) (actual time=593.266..1669.571 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15795 read=65829, temp read=40983 written=41136
                     I/O Timings: shared read=448.028, temp read=187.320 write=345.529
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1247958 width=81) (actual time=3.209..219.233 rows=998990.00 loops=3)
                           Buffers: shared hit=2089 read=57767
                           I/O Timings: shared read=404.237
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=104.999..105.001 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=13706 read=8062, temp written=7672
                           I/O Timings: shared read=43.792, temp write=70.875
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.012..47.430 rows=177820.00 loops=3)
                                 Buffers: shared hit=13706 read=8062
                                 I/O Timings: shared read=43.792
 Planning:
   Buffers: shared hit=249
 Planning Time: 2.826 ms
 Execution Time: 36595.610 ms
(34 rows)
```

### PG Baseline EXPLAIN Run 4:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187370.86..259903.54 rows=53346 width=116) (actual time=7308.148..36702.906 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15919 read=65735, temp read=130676 written=130933
   I/O Timings: shared read=531.574, temp read=1453.457 write=1484.777
   ->  Gather Merge  (cost=187370.86..249501.07 rows=533460 width=163) (actual time=7307.891..22355.658 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15919 read=65735, temp read=130676 written=130933
         I/O Timings: shared read=531.574, temp read=1453.457 write=1484.777
         ->  Sort  (cost=186370.84..186926.53 rows=222275 width=163) (actual time=7063.660..10775.089 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 117760kB
               Buffers: shared hit=15919 read=65735, temp read=130676 written=130933
               I/O Timings: shared read=531.574, temp read=1453.457 write=1484.777
               Worker 0:  Sort Method: external merge  Disk: 121120kB
               Worker 1:  Sort Method: external merge  Disk: 119952kB
               ->  Parallel Hash Right Join  (cost=30798.88..148395.61 rows=222275 width=163) (actual time=689.689..1557.600 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15889 read=65735, temp read=40983 written=41128
                     I/O Timings: shared read=531.574, temp read=148.121 write=398.709
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1247958 width=81) (actual time=1.061..266.084 rows=998990.00 loops=3)
                           Buffers: shared hit=2371 read=57485
                           I/O Timings: shared read=516.601
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=99.594..99.596 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=13518 read=8250, temp written=7676
                           I/O Timings: shared read=14.973, temp write=76.841
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=0.665..38.492 rows=177820.00 loops=3)
                                 Buffers: shared hit=13518 read=8250
                                 I/O Timings: shared read=14.973
 Planning:
   Buffers: shared hit=249
 Planning Time: 2.545 ms
 Execution Time: 36775.520 ms
(34 rows)
```

### PG Baseline EXPLAIN Run 5:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187370.86..259903.54 rows=53346 width=116) (actual time=7032.117..36724.421 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15913 read=65741, temp read=130676 written=130939
   I/O Timings: shared read=197.804, temp read=1465.622 write=1544.885
   ->  Gather Merge  (cost=187370.86..249501.07 rows=533460 width=163) (actual time=7031.761..22465.834 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15913 read=65741, temp read=130676 written=130939
         I/O Timings: shared read=197.804, temp read=1465.622 write=1544.885
         ->  Sort  (cost=186370.84..186926.53 rows=222275 width=163) (actual time=6785.173..10527.337 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 119104kB
               Buffers: shared hit=15913 read=65741, temp read=130676 written=130939
               I/O Timings: shared read=197.804, temp read=1465.622 write=1544.885
               Worker 0:  Sort Method: external merge  Disk: 120240kB
               Worker 1:  Sort Method: external merge  Disk: 119472kB
               ->  Parallel Hash Right Join  (cost=30798.88..148395.61 rows=222275 width=163) (actual time=541.577..1411.113 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15883 read=65741, temp read=40984 written=41136
                     I/O Timings: shared read=197.804, temp read=149.437 write=365.321
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1247958 width=81) (actual time=1.461..149.867 rows=998990.00 loops=3)
                           Buffers: shared hit=2647 read=57209
                           I/O Timings: shared read=190.713
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=106.846..106.848 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=13236 read=8532, temp written=7672
                           I/O Timings: shared read=7.091, temp write=76.600
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=0.297..36.825 rows=177820.00 loops=3)
                                 Buffers: shared hit=13236 read=8532
                                 I/O Timings: shared read=7.091
 Planning:
   Buffers: shared hit=249
 Planning Time: 3.323 ms
 Execution Time: 36798.227 ms
(34 rows)
```

### MySQL Baseline Timing (5 runs after 1 warm-up): [72382.629, 71601.907, 71666.961, 70987.998, 78031.984] | median=71666.961 ms
```text
TIMING_MS=72789.668
TIMING_MS=72382.629
TIMING_MS=71601.907
TIMING_MS=71666.961
TIMING_MS=70987.998
TIMING_MS=78031.984
```

### MySQL Baseline EXPLAIN Run 1:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=58378..73595 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=58378..59885 rows=3.03e+6 loops=1)
        -> Stream results  (cost=149e+9 rows=1.49e+12) (actual time=17572..44052 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=149e+9 rows=1.49e+12) (actual time=17572..38383 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=57262 rows=510483) (actual time=0.814..2558 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=1.13..10358 rows=3e+6 loops=1)
```

### MySQL Baseline EXPLAIN Run 2:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=57686..73643 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=57686..59286 rows=3.03e+6 loops=1)
        -> Stream results  (cost=149e+9 rows=1.49e+12) (actual time=16884..43097 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=149e+9 rows=1.49e+12) (actual time=16884..37511 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=57262 rows=510483) (actual time=0.708..2236 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=1.41..9783 rows=3e+6 loops=1)
```

### MySQL Baseline EXPLAIN Run 3:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=58479..75264 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=58479..60184 rows=3.03e+6 loops=1)
        -> Stream results  (cost=149e+9 rows=1.49e+12) (actual time=16958..43913 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=149e+9 rows=1.49e+12) (actual time=16958..38055 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=57262 rows=510483) (actual time=0.699..2431 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=1.37..9869 rows=3e+6 loops=1)
```

### MySQL Baseline EXPLAIN Run 4:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=58785..75374 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=58785..60457 rows=3.03e+6 loops=1)
        -> Stream results  (cost=149e+9 rows=1.49e+12) (actual time=17452..44441 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=149e+9 rows=1.49e+12) (actual time=17452..38850 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=57262 rows=510483) (actual time=0.731..2688 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=0.995..10141 rows=3e+6 loops=1)
```

### MySQL Baseline EXPLAIN Run 5:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=59583..75418 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=59583..61132 rows=3.03e+6 loops=1)
        -> Stream results  (cost=149e+9 rows=1.49e+12) (actual time=17605..45208 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=149e+9 rows=1.49e+12) (actual time=17605..39376 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=57262 rows=510483) (actual time=0.6..2729 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=2.56..10264 rows=3e+6 loops=1)
```

## 2. Q3 Rewrite (Pre-aggregation observations + DATE_TRUNC/DATE_FORMAT)

### PG Rewrite Timing (5 runs after 1 warm-up): [12933.371, 12694.528, 12804.415, 13054.208, 12908.998] | median=12908.998 ms
```text
Timing is on.
Time: 7618,932 ms (00:07,619)
Time: 12933,371 ms (00:12,933)
Time: 12694,528 ms (00:12,695)
Time: 12804,415 ms (00:12,804)
Time: 13054,208 ms (00:13,054)
Time: 12908,998 ms (00:12,909)
```

### PG Rewrite EXPLAIN Run 1:
```text
SET
                                                                                         QUERY PLAN                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=595437.85..595571.22 rows=53346 width=148) (actual time=8071.224..8072.317 rows=4174.00 loops=1)
   Sort Key: (EXTRACT(year FROM (date_trunc('month'::text, e.start)))), (EXTRACT(month FROM (date_trunc('month'::text, e.start)))), e.encounterclass
   Sort Method: quicksort  Memory: 518kB
   Buffers: shared hit=15935 read=65711, temp read=36532 written=43458
   I/O Timings: shared read=190.518, temp read=301.834 write=463.340
   ->  GroupAggregate  (cost=576298.94..587234.87 rows=53346 width=148) (actual time=6324.375..8060.177 rows=4174.00 loops=1)
         Group Key: (date_trunc('month'::text, e.start)), e.encounterclass
         Buffers: shared hit=15932 read=65711, temp read=36532 written=43458
         I/O Timings: shared read=190.518, temp read=301.834 write=463.340
         ->  Sort  (cost=576298.94..577632.59 rows=533460 width=116) (actual time=6324.128..7411.472 rows=533460.00 loops=1)
               Sort Key: (date_trunc('month'::text, e.start)), e.encounterclass, e.patient
               Sort Method: external merge  Disk: 69480kB
               Buffers: shared hit=15932 read=65711, temp read=36532 written=43458
               I/O Timings: shared read=190.518, temp read=301.834 write=463.340
               ->  Hash Right Join  (cost=345375.14..459907.50 rows=533460 width=116) (actual time=961.128..2201.679 rows=533460.00 loops=1)
                     Hash Cond: (((oa.encounter)::text = (e.id)::text) AND ((oa.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15929 read=65711, temp read=19168 written=26073
                     I/O Timings: shared read=190.518, temp read=75.553 write=207.756
                     ->  Subquery Scan on oa  (cost=301934.64..397034.92 rows=299510 width=82) (actual time=689.011..897.998 rows=200300.00 loops=1)
                           Buffers: shared hit=4565 read=55307, temp read=9246 written=16151
                           I/O Timings: shared read=159.798, temp read=28.414 write=120.020
                           ->  Finalize GroupAggregate  (cost=301934.64..394039.82 rows=299510 width=82) (actual time=689.010..884.229 rows=200300.00 loops=1)
                                 Group Key: o.encounter, o.patient
                                 Buffers: shared hit=4565 read=55307, temp read=9246 written=16151
                                 I/O Timings: shared read=159.798, temp read=28.414 write=120.020
                                 ->  Gather Merge  (cost=301934.64..385653.54 rows=718824 width=82) (actual time=689.001..842.769 rows=202970.00 loops=1)
                                       Workers Planned: 2
                                       Workers Launched: 2
                                       Buffers: shared hit=4565 read=55307, temp read=9246 written=16151
                                       I/O Timings: shared read=159.798, temp read=28.414 write=120.020
                                       ->  Sort  (cost=300934.62..301683.39 rows=299510 width=82) (actual time=619.934..654.880 rows=67656.67 loops=3)
                                             Sort Key: o.encounter, o.patient
                                             Sort Method: external merge  Disk: 7064kB
                                             Buffers: shared hit=4565 read=55307, temp read=9246 written=16151
                                             I/O Timings: shared read=159.798, temp read=28.414 write=120.020
                                             Worker 0:  Sort Method: external merge  Disk: 6184kB
                                             Worker 1:  Sort Method: external merge  Disk: 6240kB
                                             ->  Partial HashAggregate  (cost=225721.13..259358.32 rows=299510 width=82) (actual time=368.501..415.115 rows=67656.67 loops=3)
                                                   Group Key: o.encounter, o.patient
                                                   Planned Partitions: 8  Batches: 9  Memory Usage: 8281kB  Disk Usage: 31352kB
                                                   Buffers: shared hit=4549 read=55307, temp read=6810 written=13710
                                                   I/O Timings: shared read=159.798, temp read=21.077 write=99.220
                                                   Worker 0:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 15504kB
                                                   Worker 1:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 15632kB
                                                   ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1120625 width=81) (actual time=0.726..133.517 rows=897780.00 loops=3)
                                                         Filter: (encounter IS NOT NULL)
                                                         Rows Removed by Filter: 101210
                                                         Buffers: shared hit=4549 read=55307
                                                         I/O Timings: shared read=159.798
                     ->  Hash  (cost=27102.60..27102.60 rows=533460 width=100) (actual time=270.852..270.854 rows=533460.00 loops=1)
                           Buckets: 65536  Batches: 16  Memory Usage: 4945kB
                           Buffers: shared hit=11364 read=10404, temp written=7564
                           I/O Timings: shared read=30.720, temp write=65.068
                           ->  Seq Scan on encounters e  (cost=0.00..27102.60 rows=533460 width=100) (actual time=0.328..124.452 rows=533460.00 loops=1)
                                 Buffers: shared hit=11364 read=10404
                                 I/O Timings: shared read=30.720
 Planning:
   Buffers: shared hit=220 read=37
   I/O Timings: shared read=3.952
 Planning Time: 6.385 ms
 Execution Time: 8181.478 ms
(61 rows)
```

### PG Rewrite EXPLAIN Run 2:
```text
SET
                                                                                         QUERY PLAN                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=595437.85..595571.22 rows=53346 width=148) (actual time=7827.843..7828.584 rows=4174.00 loops=1)
   Sort Key: (EXTRACT(year FROM (date_trunc('month'::text, e.start)))), (EXTRACT(month FROM (date_trunc('month'::text, e.start)))), e.encounterclass
   Sort Method: quicksort  Memory: 518kB
   Buffers: shared hit=16015 read=65631, temp read=36499 written=42832
   I/O Timings: shared read=163.868, temp read=298.493 write=424.528
   ->  GroupAggregate  (cost=576298.94..587234.87 rows=53346 width=148) (actual time=6061.625..7816.726 rows=4174.00 loops=1)
         Group Key: (date_trunc('month'::text, e.start)), e.encounterclass
         Buffers: shared hit=16012 read=65631, temp read=36499 written=42832
         I/O Timings: shared read=163.868, temp read=298.493 write=424.528
         ->  Sort  (cost=576298.94..577632.59 rows=533460 width=116) (actual time=6061.340..7154.387 rows=533460.00 loops=1)
               Sort Key: (date_trunc('month'::text, e.start)), e.encounterclass, e.patient
               Sort Method: external merge  Disk: 69480kB
               Buffers: shared hit=16012 read=65631, temp read=36499 written=42832
               I/O Timings: shared read=163.868, temp read=298.493 write=424.528
               ->  Hash Right Join  (cost=345375.14..459907.50 rows=533460 width=116) (actual time=972.398..2094.150 rows=533460.00 loops=1)
                     Hash Cond: (((oa.encounter)::text = (e.id)::text) AND ((oa.patient)::text = (e.patient)::text))
                     Buffers: shared hit=16009 read=65631, temp read=19135 written=25447
                     I/O Timings: shared read=163.868, temp read=67.109 write=205.077
                     ->  Subquery Scan on oa  (cost=301934.64..397034.92 rows=299510 width=82) (actual time=723.925..949.522 rows=200300.00 loops=1)
                           Buffers: shared hit=4842 read=55030, temp read=9213 written=15525
                           I/O Timings: shared read=155.343, temp read=31.627 write=116.114
                           ->  Finalize GroupAggregate  (cost=301934.64..394039.82 rows=299510 width=82) (actual time=723.924..934.612 rows=200300.00 loops=1)
                                 Group Key: o.encounter, o.patient
                                 Buffers: shared hit=4842 read=55030, temp read=9213 written=15525
                                 I/O Timings: shared read=155.343, temp read=31.627 write=116.114
                                 ->  Gather Merge  (cost=301934.64..385653.54 rows=718824 width=82) (actual time=723.916..889.071 rows=203019.00 loops=1)
                                       Workers Planned: 2
                                       Workers Launched: 2
                                       Buffers: shared hit=4842 read=55030, temp read=9213 written=15525
                                       I/O Timings: shared read=155.343, temp read=31.627 write=116.114
                                       ->  Sort  (cost=300934.62..301683.39 rows=299510 width=82) (actual time=658.546..699.227 rows=67673.00 loops=3)
                                             Sort Key: o.encounter, o.patient
                                             Sort Method: external merge  Disk: 6872kB
                                             Buffers: shared hit=4842 read=55030, temp read=9213 written=15525
                                             I/O Timings: shared read=155.343, temp read=31.627 write=116.114
                                             Worker 0:  Sort Method: external merge  Disk: 6272kB
                                             Worker 1:  Sort Method: external merge  Disk: 6352kB
                                             ->  Partial HashAggregate  (cost=225721.13..259358.32 rows=299510 width=82) (actual time=371.963..423.504 rows=67673.00 loops=3)
                                                   Group Key: o.encounter, o.patient
                                                   Planned Partitions: 8  Batches: 9  Memory Usage: 8281kB  Disk Usage: 23912kB
                                                   Buffers: shared hit=4826 read=55030, temp read=6776 written=13082
                                                   I/O Timings: shared read=155.343, temp read=23.187 write=99.930
                                                   Worker 0:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 15888kB
                                                   Worker 1:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 17944kB
                                                   ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1120625 width=81) (actual time=1.279..134.299 rows=897780.00 loops=3)
                                                         Filter: (encounter IS NOT NULL)
                                                         Rows Removed by Filter: 101210
                                                         Buffers: shared hit=4826 read=55030
                                                         I/O Timings: shared read=155.343
                     ->  Hash  (cost=27102.60..27102.60 rows=533460 width=100) (actual time=247.196..247.198 rows=533460.00 loops=1)
                           Buckets: 65536  Batches: 16  Memory Usage: 4945kB
                           Buffers: shared hit=11167 read=10601, temp written=7564
                           I/O Timings: shared read=8.525, temp write=61.025
                           ->  Seq Scan on encounters e  (cost=0.00..27102.60 rows=533460 width=100) (actual time=0.554..103.089 rows=533460.00 loops=1)
                                 Buffers: shared hit=11167 read=10601
                                 I/O Timings: shared read=8.525
 Planning:
   Buffers: shared hit=257
 Planning Time: 2.074 ms
 Execution Time: 7915.229 ms
(60 rows)
```

### PG Rewrite EXPLAIN Run 3:
```text
SET
                                                                                         QUERY PLAN                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=595437.85..595571.22 rows=53346 width=148) (actual time=7146.431..7147.122 rows=4174.00 loops=1)
   Sort Key: (EXTRACT(year FROM (date_trunc('month'::text, e.start)))), (EXTRACT(month FROM (date_trunc('month'::text, e.start)))), e.encounterclass
   Sort Method: quicksort  Memory: 518kB
   Buffers: shared hit=16034 read=65612, temp read=36485 written=43319
   I/O Timings: shared read=164.650, temp read=271.342 write=422.216
   ->  GroupAggregate  (cost=576298.94..587234.87 rows=53346 width=148) (actual time=5357.119..7132.581 rows=4174.00 loops=1)
         Group Key: (date_trunc('month'::text, e.start)), e.encounterclass
         Buffers: shared hit=16031 read=65612, temp read=36485 written=43319
         I/O Timings: shared read=164.650, temp read=271.342 write=422.216
         ->  Sort  (cost=576298.94..577632.59 rows=533460 width=116) (actual time=5356.947..6465.408 rows=533460.00 loops=1)
               Sort Key: (date_trunc('month'::text, e.start)), e.encounterclass, e.patient
               Sort Method: external merge  Disk: 69480kB
               Buffers: shared hit=16031 read=65612, temp read=36485 written=43319
               I/O Timings: shared read=164.650, temp read=271.342 write=422.216
               ->  Hash Right Join  (cost=345375.14..459907.50 rows=533460 width=116) (actual time=939.298..1959.358 rows=533460.00 loops=1)
                     Hash Cond: (((oa.encounter)::text = (e.id)::text) AND ((oa.patient)::text = (e.patient)::text))
                     Buffers: shared hit=16028 read=65612, temp read=19121 written=25934
                     I/O Timings: shared read=164.650, temp read=65.559 write=227.538
                     ->  Subquery Scan on oa  (cost=301934.64..397034.92 rows=299510 width=82) (actual time=684.653..886.659 rows=200300.00 loops=1)
                           Buffers: shared hit=5122 read=54750, temp read=9199 written=16012
                           I/O Timings: shared read=141.420, temp read=29.241 write=149.810
                           ->  Finalize GroupAggregate  (cost=301934.64..394039.82 rows=299510 width=82) (actual time=684.651..873.054 rows=200300.00 loops=1)
                                 Group Key: o.encounter, o.patient
                                 Buffers: shared hit=5122 read=54750, temp read=9199 written=16012
                                 I/O Timings: shared read=141.420, temp read=29.241 write=149.810
                                 ->  Gather Merge  (cost=301934.64..385653.54 rows=718824 width=82) (actual time=684.641..832.788 rows=202960.00 loops=1)
                                       Workers Planned: 2
                                       Workers Launched: 2
                                       Buffers: shared hit=5122 read=54750, temp read=9199 written=16012
                                       I/O Timings: shared read=141.420, temp read=29.241 write=149.810
                                       ->  Sort  (cost=300934.62..301683.39 rows=299510 width=82) (actual time=627.396..661.733 rows=67653.33 loops=3)
                                             Sort Key: o.encounter, o.patient
                                             Sort Method: external merge  Disk: 6968kB
                                             Buffers: shared hit=5122 read=54750, temp read=9199 written=16012
                                             I/O Timings: shared read=141.420, temp read=29.241 write=149.810
                                             Worker 0:  Sort Method: external merge  Disk: 6240kB
                                             Worker 1:  Sort Method: external merge  Disk: 6280kB
                                             ->  Partial HashAggregate  (cost=225721.13..259358.32 rows=299510 width=82) (actual time=370.386..419.041 rows=67653.33 loops=3)
                                                   Group Key: o.encounter, o.patient
                                                   Planned Partitions: 8  Batches: 9  Memory Usage: 8281kB  Disk Usage: 30264kB
                                                   Buffers: shared hit=5106 read=54750, temp read=6763 written=13570
                                                   I/O Timings: shared read=141.420, temp read=22.416 write=124.342
                                                   Worker 0:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 15664kB
                                                   Worker 1:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 15880kB
                                                   ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1120625 width=81) (actual time=0.591..128.147 rows=897780.00 loops=3)
                                                         Filter: (encounter IS NOT NULL)
                                                         Rows Removed by Filter: 101210
                                                         Buffers: shared hit=5106 read=54750
                                                         I/O Timings: shared read=141.420
                     ->  Hash  (cost=27102.60..27102.60 rows=533460 width=100) (actual time=253.327..253.329 rows=533460.00 loops=1)
                           Buckets: 65536  Batches: 16  Memory Usage: 4945kB
                           Buffers: shared hit=10906 read=10862, temp written=7564
                           I/O Timings: shared read=23.230, temp write=56.408
                           ->  Seq Scan on encounters e  (cost=0.00..27102.60 rows=533460 width=100) (actual time=0.390..114.998 rows=533460.00 loops=1)
                                 Buffers: shared hit=10906 read=10862
                                 I/O Timings: shared read=23.230
 Planning:
   Buffers: shared hit=257
 Planning Time: 1.976 ms
 Execution Time: 7238.062 ms
(60 rows)
```

### PG Rewrite EXPLAIN Run 4:
```text
SET
                                                                                         QUERY PLAN                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=595437.85..595571.22 rows=53346 width=148) (actual time=8036.035..8036.721 rows=4174.00 loops=1)
   Sort Key: (EXTRACT(year FROM (date_trunc('month'::text, e.start)))), (EXTRACT(month FROM (date_trunc('month'::text, e.start)))), e.encounterclass
   Sort Method: quicksort  Memory: 518kB
   Buffers: shared hit=16061 read=65585, temp read=36561 written=43654
   I/O Timings: shared read=263.511, temp read=300.768 write=455.300
   ->  GroupAggregate  (cost=576298.94..587234.87 rows=53346 width=148) (actual time=6316.314..8024.573 rows=4174.00 loops=1)
         Group Key: (date_trunc('month'::text, e.start)), e.encounterclass
         Buffers: shared hit=16058 read=65585, temp read=36561 written=43654
         I/O Timings: shared read=263.511, temp read=300.768 write=455.300
         ->  Sort  (cost=576298.94..577632.59 rows=533460 width=116) (actual time=6316.128..7381.899 rows=533460.00 loops=1)
               Sort Key: (date_trunc('month'::text, e.start)), e.encounterclass, e.patient
               Sort Method: external merge  Disk: 69480kB
               Buffers: shared hit=16058 read=65585, temp read=36561 written=43654
               I/O Timings: shared read=263.511, temp read=300.768 write=455.300
               ->  Hash Right Join  (cost=345375.14..459907.50 rows=533460 width=116) (actual time=1070.745..2173.146 rows=533460.00 loops=1)
                     Hash Cond: (((oa.encounter)::text = (e.id)::text) AND ((oa.patient)::text = (e.patient)::text))
                     Buffers: shared hit=16055 read=65585, temp read=19197 written=26269
                     I/O Timings: shared read=263.511, temp read=77.203 write=209.881
                     ->  Subquery Scan on oa  (cost=301934.64..397034.92 rows=299510 width=82) (actual time=766.676..975.838 rows=200300.00 loops=1)
                           Buffers: shared hit=5400 read=54472, temp read=9275 written=16347
                           I/O Timings: shared read=199.753, temp read=32.307 write=127.510
                           ->  Finalize GroupAggregate  (cost=301934.64..394039.82 rows=299510 width=82) (actual time=766.675..961.249 rows=200300.00 loops=1)
                                 Group Key: o.encounter, o.patient
                                 Buffers: shared hit=5400 read=54472, temp read=9275 written=16347
                                 I/O Timings: shared read=199.753, temp read=32.307 write=127.510
                                 ->  Gather Merge  (cost=301934.64..385653.54 rows=718824 width=82) (actual time=766.666..919.786 rows=202985.00 loops=1)
                                       Workers Planned: 2
                                       Workers Launched: 2
                                       Buffers: shared hit=5400 read=54472, temp read=9275 written=16347
                                       I/O Timings: shared read=199.753, temp read=32.307 write=127.510
                                       ->  Sort  (cost=300934.62..301683.39 rows=299510 width=82) (actual time=700.540..737.595 rows=67661.67 loops=3)
                                             Sort Key: o.encounter, o.patient
                                             Sort Method: external merge  Disk: 6928kB
                                             Buffers: shared hit=5400 read=54472, temp read=9275 written=16347
                                             I/O Timings: shared read=199.753, temp read=32.307 write=127.510
                                             Worker 0:  Sort Method: external merge  Disk: 6376kB
                                             Worker 1:  Sort Method: external merge  Disk: 6184kB
                                             ->  Partial HashAggregate  (cost=225721.13..259358.32 rows=299510 width=82) (actual time=380.815..434.663 rows=67661.67 loops=3)
                                                   Group Key: o.encounter, o.patient
                                                   Planned Partitions: 8  Batches: 9  Memory Usage: 8281kB  Disk Usage: 30304kB
                                                   Buffers: shared hit=5384 read=54472, temp read=6839 written=13906
                                                   I/O Timings: shared read=199.753, temp read=24.798 write=111.689
                                                   Worker 0:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 17928kB
                                                   Worker 1:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 15520kB
                                                   ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1120625 width=81) (actual time=0.949..146.023 rows=897780.00 loops=3)
                                                         Filter: (encounter IS NOT NULL)
                                                         Rows Removed by Filter: 101210
                                                         Buffers: shared hit=5384 read=54472
                                                         I/O Timings: shared read=199.753
                     ->  Hash  (cost=27102.60..27102.60 rows=533460 width=100) (actual time=302.774..302.776 rows=533460.00 loops=1)
                           Buckets: 65536  Batches: 16  Memory Usage: 4945kB
                           Buffers: shared hit=10655 read=11113, temp written=7564
                           I/O Timings: shared read=63.758, temp write=61.090
                           ->  Seq Scan on encounters e  (cost=0.00..27102.60 rows=533460 width=100) (actual time=0.797..158.428 rows=533460.00 loops=1)
                                 Buffers: shared hit=10655 read=11113
                                 I/O Timings: shared read=63.758
 Planning:
   Buffers: shared hit=257
 Planning Time: 2.721 ms
 Execution Time: 8149.027 ms
(60 rows)
```

### PG Rewrite EXPLAIN Run 5:
```text
SET
                                                                                         QUERY PLAN                                                                                         
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=595437.85..595571.22 rows=53346 width=148) (actual time=7499.207..7499.939 rows=4174.00 loops=1)
   Sort Key: (EXTRACT(year FROM (date_trunc('month'::text, e.start)))), (EXTRACT(month FROM (date_trunc('month'::text, e.start)))), e.encounterclass
   Sort Method: quicksort  Memory: 518kB
   Buffers: shared hit=16078 read=65568, temp read=36559 written=43036
   I/O Timings: shared read=180.565, temp read=283.488 write=435.815
   ->  GroupAggregate  (cost=576298.94..587234.87 rows=53346 width=148) (actual time=5778.551..7487.432 rows=4174.00 loops=1)
         Group Key: (date_trunc('month'::text, e.start)), e.encounterclass
         Buffers: shared hit=16075 read=65568, temp read=36559 written=43036
         I/O Timings: shared read=180.565, temp read=283.488 write=435.815
         ->  Sort  (cost=576298.94..577632.59 rows=533460 width=116) (actual time=5778.301..6846.909 rows=533460.00 loops=1)
               Sort Key: (date_trunc('month'::text, e.start)), e.encounterclass, e.patient
               Sort Method: external merge  Disk: 69480kB
               Buffers: shared hit=16075 read=65568, temp read=36559 written=43036
               I/O Timings: shared read=180.565, temp read=283.488 write=435.815
               ->  Hash Right Join  (cost=345375.14..459907.50 rows=533460 width=116) (actual time=976.171..2042.769 rows=533460.00 loops=1)
                     Hash Cond: (((oa.encounter)::text = (e.id)::text) AND ((oa.patient)::text = (e.patient)::text))
                     Buffers: shared hit=16072 read=65568, temp read=19195 written=25651
                     I/O Timings: shared read=180.565, temp read=63.919 write=221.304
                     ->  Subquery Scan on oa  (cost=301934.64..397034.92 rows=299510 width=82) (actual time=667.787..867.633 rows=200300.00 loops=1)
                           Buffers: shared hit=5676 read=54196, temp read=9273 written=15729
                           I/O Timings: shared read=146.287, temp read=28.217 write=132.386
                           ->  Finalize GroupAggregate  (cost=301934.64..394039.82 rows=299510 width=82) (actual time=667.786..852.923 rows=200300.00 loops=1)
                                 Group Key: o.encounter, o.patient
                                 Buffers: shared hit=5676 read=54196, temp read=9273 written=15729
                                 I/O Timings: shared read=146.287, temp read=28.217 write=132.386
                                 ->  Gather Merge  (cost=301934.64..385653.54 rows=718824 width=82) (actual time=667.779..813.327 rows=202929.00 loops=1)
                                       Workers Planned: 2
                                       Workers Launched: 2
                                       Buffers: shared hit=5676 read=54196, temp read=9273 written=15729
                                       I/O Timings: shared read=146.287, temp read=28.217 write=132.386
                                       ->  Sort  (cost=300934.62..301683.39 rows=299510 width=82) (actual time=617.586..652.308 rows=67643.00 loops=3)
                                             Sort Key: o.encounter, o.patient
                                             Sort Method: external merge  Disk: 6880kB
                                             Buffers: shared hit=5676 read=54196, temp read=9273 written=15729
                                             I/O Timings: shared read=146.287, temp read=28.217 write=132.386
                                             Worker 0:  Sort Method: external merge  Disk: 6320kB
                                             Worker 1:  Sort Method: external merge  Disk: 6288kB
                                             ->  Partial HashAggregate  (cost=225721.13..259358.32 rows=299510 width=82) (actual time=366.589..413.349 rows=67643.00 loops=3)
                                                   Group Key: o.encounter, o.patient
                                                   Planned Partitions: 8  Batches: 9  Memory Usage: 8281kB  Disk Usage: 25104kB
                                                   Buffers: shared hit=5660 read=54196, temp read=6837 written=13287
                                                   I/O Timings: shared read=146.287, temp read=21.736 write=112.657
                                                   Worker 0:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 17936kB
                                                   Worker 1:  Batches: 9  Memory Usage: 8281kB  Disk Usage: 15888kB
                                                   ->  Parallel Seq Scan on observations o  (cost=0.00..72335.58 rows=1120625 width=81) (actual time=1.796..129.359 rows=897780.00 loops=3)
                                                         Filter: (encounter IS NOT NULL)
                                                         Rows Removed by Filter: 101210
                                                         Buffers: shared hit=5660 read=54196
                                                         I/O Timings: shared read=146.287
                     ->  Hash  (cost=27102.60..27102.60 rows=533460 width=100) (actual time=307.126..307.128 rows=533460.00 loops=1)
                           Buckets: 65536  Batches: 16  Memory Usage: 4945kB
                           Buffers: shared hit=10396 read=11372, temp written=7564
                           I/O Timings: shared read=34.278, temp write=69.738
                           ->  Seq Scan on encounters e  (cost=0.00..27102.60 rows=533460 width=100) (actual time=0.292..140.249 rows=533460.00 loops=1)
                                 Buffers: shared hit=10396 read=11372
                                 I/O Timings: shared read=34.278
 Planning:
   Buffers: shared hit=257
 Planning Time: 5.063 ms
 Execution Time: 7592.368 ms
(60 rows)
```

### MySQL Rewrite Timing (5 runs after 1 warm-up): [38319.901, 37373.689, 37024.768, 37600.472, 38308.578] | median=37600.472 ms
```text
TIMING_MS=37912.604
TIMING_MS=38319.901
TIMING_MS=37373.689
TIMING_MS=37024.768
TIMING_MS=37600.472
TIMING_MS=38308.578
```

### MySQL Rewrite EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: report_year, report_month, e.encounterclass  (actual time=39907..39908 rows=4174 loops=1)
    -> Stream results  (cost=1.34e+6 rows=0) (actual time=30677..39881 rows=4174 loops=1)
        -> Group aggregate: sum(encounters.total_claim_cost), sum(oa.obs_count), count(encounters.id), count(distinct encounters.patient)  (cost=1.34e+6 rows=0) (actual time=30677..39813 rows=4174 loops=1)
            -> Nested loop left join  (cost=1.34e+6 rows=0) (actual time=30676..37252 rows=533460 loops=1)
                -> Sort: e.report_month_dt, e.encounterclass  (cost=59544 rows=510483) (actual time=4375..4825 rows=533460 loops=1)
                    -> Table scan on encounters  (cost=59544 rows=510483) (actual time=2.82..2302 rows=533460 loops=1)
                -> Index lookup on oa using <auto_key0> (encounter = encounters.id, patient = encounters.patient)  (cost=0.25..2.5 rows=10) (actual time=0.0594..0.0598 rows=0.375 loops=533460)
                    -> Materialize CTE obs_agg  (cost=0..0 rows=0) (actual time=26301..26301 rows=200300 loops=1)
                        -> Table scan on <temporary>  (actual time=24705..24829 rows=200300 loops=1)
                            -> Aggregate using temporary table  (actual time=24705..24705 rows=200300 loops=1)
                                -> Filter: (o.encounter is not null)  (cost=321896 rows=2.62e+6) (actual time=2.24..12259 rows=2.69e+6 loops=1)
                                    -> Table scan on o  (cost=321896 rows=2.91e+6) (actual time=2.24..11165 rows=3e+6 loops=1)
```

### MySQL Rewrite EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: report_year, report_month, e.encounterclass  (actual time=39109..39111 rows=4174 loops=1)
    -> Stream results  (cost=1.34e+6 rows=0) (actual time=29625..39083 rows=4174 loops=1)
        -> Group aggregate: sum(encounters.total_claim_cost), sum(oa.obs_count), count(encounters.id), count(distinct encounters.patient)  (cost=1.34e+6 rows=0) (actual time=29625..39013 rows=4174 loops=1)
            -> Nested loop left join  (cost=1.34e+6 rows=0) (actual time=29624..36401 rows=533460 loops=1)
                -> Sort: e.report_month_dt, e.encounterclass  (cost=59544 rows=510483) (actual time=3922..4385 rows=533460 loops=1)
                    -> Table scan on encounters  (cost=59544 rows=510483) (actual time=0.988..1988 rows=533460 loops=1)
                -> Index lookup on oa using <auto_key0> (encounter = encounters.id, patient = encounters.patient)  (cost=0.25..2.5 rows=10) (actual time=0.0585..0.059 rows=0.375 loops=533460)
                    -> Materialize CTE obs_agg  (cost=0..0 rows=0) (actual time=25702..25702 rows=200300 loops=1)
                        -> Table scan on <temporary>  (actual time=24085..24210 rows=200300 loops=1)
                            -> Aggregate using temporary table  (actual time=24085..24085 rows=200300 loops=1)
                                -> Filter: (o.encounter is not null)  (cost=321896 rows=2.62e+6) (actual time=1.64..11850 rows=2.69e+6 loops=1)
                                    -> Table scan on o  (cost=321896 rows=2.91e+6) (actual time=1.64..10770 rows=3e+6 loops=1)
```

### MySQL Rewrite EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: report_year, report_month, e.encounterclass  (actual time=40700..40701 rows=4174 loops=1)
    -> Stream results  (cost=1.34e+6 rows=0) (actual time=31489..40675 rows=4174 loops=1)
        -> Group aggregate: sum(encounters.total_claim_cost), sum(oa.obs_count), count(encounters.id), count(distinct encounters.patient)  (cost=1.34e+6 rows=0) (actual time=31488..40607 rows=4174 loops=1)
            -> Nested loop left join  (cost=1.34e+6 rows=0) (actual time=31486..38095 rows=533460 loops=1)
                -> Sort: e.report_month_dt, e.encounterclass  (cost=59544 rows=510483) (actual time=5087..5537 rows=533460 loops=1)
                    -> Table scan on encounters  (cost=59544 rows=510483) (actual time=0.756..2801 rows=533460 loops=1)
                -> Index lookup on oa using <auto_key0> (encounter = encounters.id, patient = encounters.patient)  (cost=0.25..2.5 rows=10) (actual time=0.0596..0.0601 rows=0.375 loops=533460)
                    -> Materialize CTE obs_agg  (cost=0..0 rows=0) (actual time=26399..26399 rows=200300 loops=1)
                        -> Table scan on <temporary>  (actual time=24773..24900 rows=200300 loops=1)
                            -> Aggregate using temporary table  (actual time=24773..24773 rows=200300 loops=1)
                                -> Filter: (o.encounter is not null)  (cost=321896 rows=2.62e+6) (actual time=2.43..12136 rows=2.69e+6 loops=1)
                                    -> Table scan on o  (cost=321896 rows=2.91e+6) (actual time=2.43..11013 rows=3e+6 loops=1)
```

### MySQL Rewrite EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: report_year, report_month, e.encounterclass  (actual time=40005..40006 rows=4174 loops=1)
    -> Stream results  (cost=1.34e+6 rows=0) (actual time=30312..39977 rows=4174 loops=1)
        -> Group aggregate: sum(encounters.total_claim_cost), sum(oa.obs_count), count(encounters.id), count(distinct encounters.patient)  (cost=1.34e+6 rows=0) (actual time=30311..39901 rows=4174 loops=1)
            -> Nested loop left join  (cost=1.34e+6 rows=0) (actual time=30311..37178 rows=533460 loops=1)
                -> Sort: e.report_month_dt, e.encounterclass  (cost=59544 rows=510483) (actual time=4095..4565 rows=533460 loops=1)
                    -> Table scan on encounters  (cost=59544 rows=510483) (actual time=3.35..2124 rows=533460 loops=1)
                -> Index lookup on oa using <auto_key0> (encounter = encounters.id, patient = encounters.patient)  (cost=0.25..2.5 rows=10) (actual time=0.0597..0.0601 rows=0.375 loops=533460)
                    -> Materialize CTE obs_agg  (cost=0..0 rows=0) (actual time=26216..26216 rows=200300 loops=1)
                        -> Table scan on <temporary>  (actual time=24554..24679 rows=200300 loops=1)
                            -> Aggregate using temporary table  (actual time=24554..24554 rows=200300 loops=1)
                                -> Filter: (o.encounter is not null)  (cost=321896 rows=2.62e+6) (actual time=4.69..12059 rows=2.69e+6 loops=1)
                                    -> Table scan on o  (cost=321896 rows=2.91e+6) (actual time=4.69..10976 rows=3e+6 loops=1)
```

### MySQL Rewrite EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: report_year, report_month, e.encounterclass  (actual time=41524..41525 rows=4174 loops=1)
    -> Stream results  (cost=1.34e+6 rows=0) (actual time=31727..41494 rows=4174 loops=1)
        -> Group aggregate: sum(encounters.total_claim_cost), sum(oa.obs_count), count(encounters.id), count(distinct encounters.patient)  (cost=1.34e+6 rows=0) (actual time=31727..41406 rows=4174 loops=1)
            -> Nested loop left join  (cost=1.34e+6 rows=0) (actual time=31727..38679 rows=533460 loops=1)
                -> Sort: e.report_month_dt, e.encounterclass  (cost=59544 rows=510483) (actual time=4647..5151 rows=533460 loops=1)
                    -> Table scan on encounters  (cost=59544 rows=510483) (actual time=0.982..2471 rows=533460 loops=1)
                -> Index lookup on oa using <auto_key0> (encounter = encounters.id, patient = encounters.patient)  (cost=0.25..2.5 rows=10) (actual time=0.0614..0.0618 rows=0.375 loops=533460)
                    -> Materialize CTE obs_agg  (cost=0..0 rows=0) (actual time=27080..27080 rows=200300 loops=1)
                        -> Table scan on <temporary>  (actual time=25334..25468 rows=200300 loops=1)
                            -> Aggregate using temporary table  (actual time=25334..25334 rows=200300 loops=1)
                                -> Filter: (o.encounter is not null)  (cost=321896 rows=2.62e+6) (actual time=208..12505 rows=2.69e+6 loops=1)
                                    -> Table scan on o  (cost=321896 rows=2.91e+6) (actual time=208..11397 rows=3e+6 loops=1)
```

## 3. Q3 Indexes (Covering Indexes)

### PG Index Setup & Sizes
```text
Timing is on.
CREATE INDEX
Time: 18445,906 ms (00:18,446)
CREATE INDEX
Time: 2447,107 ms (00:02,447)
ANALYZE
Time: 1698,888 ms (00:01,699)
ANALYZE
Time: 1960,658 ms (00:01,961)

indexname         | size_bytes |  size  
--------------------------+------------+--------
 idx_enc_start_class_inc  |   69902336 | 67 MB
 idx_obs_enc_pat_inc_code |  330407936 | 315 MB
(2 rows)

 delta_d_bytes | delta_d_mb 
---------------+------------
     400310272 |     381.77
(1 row)
```

### PG Index Timing (5 runs after 1 warm-up): [36102.056, 36329.818, 36811.615, 37015.452, 35879.924] | median=36329.818 ms

### PG Index EXPLAIN Run 1:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.38..259934.06 rows=53346 width=116) (actual time=7747.037..38286.588 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15529 read=66125, temp read=130676 written=130928
   I/O Timings: shared read=188.105, temp read=1492.109 write=1522.606
   ->  Gather Merge  (cost=187401.38..249531.59 rows=533460 width=163) (actual time=7746.493..23983.555 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15529 read=66125, temp read=130676 written=130928
         I/O Timings: shared read=188.105, temp read=1492.109 write=1522.606
         ->  Sort  (cost=186401.35..186957.04 rows=222275 width=163) (actual time=7426.190..11129.023 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 118104kB
               Buffers: shared hit=15529 read=66125, temp read=130676 written=130928
               I/O Timings: shared read=188.105, temp read=1492.109 write=1522.606
               Worker 0:  Sort Method: external merge  Disk: 117456kB
               Worker 1:  Sort Method: external merge  Disk: 123264kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.13 rows=222275 width=163) (actual time=555.065..1462.858 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15499 read=66125, temp read=40983 written=41124
                     I/O Timings: shared read=188.105, temp read=157.584 write=384.706
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.48 rows=1248648 width=81) (actual time=1.592..144.562 rows=998990.00 loops=3)
                           Buffers: shared hit=5726 read=54130
                           I/O Timings: shared read=160.494
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=113.698..113.700 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=9773 read=11995, temp written=7668
                           I/O Timings: shared read=27.610, temp write=82.932
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.315..44.271 rows=177820.00 loops=3)
                                 Buffers: shared hit=9773 read=11995
                                 I/O Timings: shared read=27.610
 Planning:
   Buffers: shared hit=294 read=30
   I/O Timings: shared read=14.077
 Planning Time: 23.797 ms
 Execution Time: 38351.950 ms
(35 rows)
```

### PG Index EXPLAIN Run 2:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.38..259934.06 rows=53346 width=116) (actual time=7025.552..36109.666 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15530 read=66124, temp read=130676 written=130936
   I/O Timings: shared read=205.256, temp read=1405.849 write=1420.175
   ->  Gather Merge  (cost=187401.38..249531.59 rows=533460 width=163) (actual time=7025.140..21995.148 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15530 read=66124, temp read=130676 written=130936
         I/O Timings: shared read=205.256, temp read=1405.849 write=1420.175
         ->  Sort  (cost=186401.35..186957.04 rows=222275 width=163) (actual time=6842.725..10567.854 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 119376kB
               Buffers: shared hit=15530 read=66124, temp read=130676 written=130936
               I/O Timings: shared read=205.256, temp read=1405.849 write=1420.175
               Worker 0:  Sort Method: external merge  Disk: 118512kB
               Worker 1:  Sort Method: external merge  Disk: 120928kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.13 rows=222275 width=163) (actual time=537.013..1398.137 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15500 read=66124, temp read=40984 written=41132
                     I/O Timings: shared read=205.256, temp read=145.407 write=316.554
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.48 rows=1248648 width=81) (actual time=2.450..157.230 rows=998990.00 loops=3)
                           Buffers: shared hit=5726 read=54130
                           I/O Timings: shared read=181.705
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=96.758..96.760 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=9774 read=11994, temp written=7672
                           I/O Timings: shared read=23.551, temp write=61.080
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.176..40.399 rows=177820.00 loops=3)
                                 Buffers: shared hit=9774 read=11994
                                 I/O Timings: shared read=23.551
 Planning:
   Buffers: shared hit=324
 Planning Time: 3.610 ms
 Execution Time: 36181.916 ms
(34 rows)
```

### PG Index EXPLAIN Run 3:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.38..259934.06 rows=53346 width=116) (actual time=7273.127..36836.228 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15546 read=66108, temp read=130672 written=130931
   I/O Timings: shared read=293.039, temp read=1473.468 write=1438.705
   ->  Gather Merge  (cost=187401.38..249531.59 rows=533460 width=163) (actual time=7272.638..22501.638 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15546 read=66108, temp read=130672 written=130931
         I/O Timings: shared read=293.039, temp read=1473.468 write=1438.705
         ->  Sort  (cost=186401.35..186957.04 rows=222275 width=163) (actual time=7044.690..10796.210 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 119944kB
               Buffers: shared hit=15546 read=66108, temp read=130672 written=130931
               I/O Timings: shared read=293.039, temp read=1473.468 write=1438.705
               Worker 0:  Sort Method: external merge  Disk: 119976kB
               Worker 1:  Sort Method: external merge  Disk: 118896kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.13 rows=222275 width=163) (actual time=593.259..1458.230 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15516 read=66108, temp read=40980 written=41128
                     I/O Timings: shared read=293.039, temp read=142.691 write=397.688
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.48 rows=1248648 width=81) (actual time=1.660..181.115 rows=998990.00 loops=3)
                           Buffers: shared hit=5687 read=54169
                           I/O Timings: shared read=272.159
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=112.560..112.562 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=9829 read=11939, temp written=7664
                           I/O Timings: shared read=20.880, temp write=67.428
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.366..45.405 rows=177820.00 loops=3)
                                 Buffers: shared hit=9829 read=11939
                                 I/O Timings: shared read=20.880
 Planning:
   Buffers: shared hit=324
 Planning Time: 9.365 ms
 Execution Time: 36905.962 ms
(34 rows)
```

### PG Index EXPLAIN Run 4:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.38..259934.06 rows=53346 width=116) (actual time=8258.550..38767.642 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15530 read=66124, temp read=130681 written=130929
   I/O Timings: shared read=342.896, temp read=1592.686 write=1563.194
   ->  Gather Merge  (cost=187401.38..249531.59 rows=533460 width=163) (actual time=8258.061..24352.992 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15530 read=66124, temp read=130681 written=130929
         I/O Timings: shared read=342.896, temp read=1592.686 write=1563.194
         ->  Sort  (cost=186401.35..186957.04 rows=222275 width=163) (actual time=7716.179..11455.037 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 114456kB
               Buffers: shared hit=15530 read=66124, temp read=130681 written=130929
               I/O Timings: shared read=342.896, temp read=1592.686 write=1563.194
               Worker 0:  Sort Method: external merge  Disk: 121120kB
               Worker 1:  Sort Method: external merge  Disk: 123248kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.13 rows=222275 width=163) (actual time=606.761..1608.918 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15500 read=66124, temp read=40988 written=41124
                     I/O Timings: shared read=342.896, temp read=178.701 write=362.690
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.48 rows=1248648 width=81) (actual time=1.958..202.737 rows=998990.00 loops=3)
                           Buffers: shared hit=5687 read=54169
                           I/O Timings: shared read=321.592
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=100.290..100.292 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5056kB
                           Buffers: shared hit=9813 read=11955, temp written=7660
                           I/O Timings: shared read=21.305, temp write=61.258
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.260..41.037 rows=177820.00 loops=3)
                                 Buffers: shared hit=9813 read=11955
                                 I/O Timings: shared read=21.305
 Planning:
   Buffers: shared hit=324
 Planning Time: 3.256 ms
 Execution Time: 38842.344 ms
(34 rows)
```

### PG Index EXPLAIN Run 5:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.38..259934.06 rows=53346 width=116) (actual time=7902.629..37140.880 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15624 read=66030, temp read=130675 written=130919
   I/O Timings: shared read=424.002, temp read=1486.875 write=1547.464
   ->  Gather Merge  (cost=187401.38..249531.59 rows=533460 width=163) (actual time=7902.153..23006.828 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15624 read=66030, temp read=130675 written=130919
         I/O Timings: shared read=424.002, temp read=1486.875 write=1547.464
         ->  Sort  (cost=186401.35..186957.04 rows=222275 width=163) (actual time=7631.837..11320.634 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 118864kB
               Buffers: shared hit=15624 read=66030, temp read=130675 written=130919
               I/O Timings: shared read=424.002, temp read=1486.875 write=1547.464
               Worker 0:  Sort Method: external merge  Disk: 120816kB
               Worker 1:  Sort Method: external merge  Disk: 119144kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.13 rows=222275 width=163) (actual time=646.821..1615.353 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15594 read=66030, temp read=40983 written=41116
                     I/O Timings: shared read=424.002, temp read=171.034 write=407.810
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.48 rows=1248648 width=81) (actual time=2.514..233.416 rows=998990.00 loops=3)
                           Buffers: shared hit=5687 read=54169
                           I/O Timings: shared read=416.120
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=92.819..92.821 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=9907 read=11861, temp written=7660
                           I/O Timings: shared read=7.882, temp write=62.554
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=0.655..35.431 rows=177820.00 loops=3)
                                 Buffers: shared hit=9907 read=11861
                                 I/O Timings: shared read=7.882
 Planning:
   Buffers: shared hit=324
 Planning Time: 3.566 ms
 Execution Time: 37212.486 ms
(34 rows)
```

### MySQL Index Setup (elapsed=39364.3 ms) & Sizes
```text
Table	Op	Msg_type	Msg_text
synthea_scale.observations	analyze	status	OK
synthea_scale.encounters	analyze	status	OK

table_name	index_name	size_bytes	size_mb
encounters	idx_enc_start_class_cov	64880640	61.88
observations	idx_obs_enc_pat_code	313507840	298.98
delta_d_bytes	delta_d_mb
378388480	360.86
```

### MySQL Index Timing (5 runs after 1 warm-up): [118701.762, 106544.191, 108483.439, 111595.912, 104889.27] | median=108483.439 ms

### MySQL Index EXPLAIN Run 1:
```text
EXPLAIN
-> Group aggregate: sum(e.total_claim_cost), count(distinct e.id), count(distinct e.patient), count(o.`code`)  (cost=3.11e+6 rows=1.42e+6) (actual time=2424..107485 rows=4174 loops=1)
    -> Nested loop left join  (cost=1.54e+6 rows=6.83e+6) (actual time=2419..92588 rows=3.03e+6 loops=1)
        -> Sort: report_year, report_month, e.encounterclass  (cost=61694 rows=509420) (actual time=2419..3037 rows=533460 loops=1)
            -> Covering index scan on e using idx_enc_start_class_cov  (cost=61694 rows=509420) (actual time=1.2..1072 rows=533460 loops=1)
        -> Covering index lookup on o using idx_obs_enc_pat_code (encounter = e.id, patient = e.patient)  (cost=1.56 rows=13.4) (actual time=0.145..0.166 rows=5.05 loops=533460)
```

### MySQL Index EXPLAIN Run 2:
```text
EXPLAIN
-> Group aggregate: sum(e.total_claim_cost), count(distinct e.id), count(distinct e.patient), count(o.`code`)  (cost=3.11e+6 rows=1.42e+6) (actual time=3041..105602 rows=4174 loops=1)
    -> Nested loop left join  (cost=1.54e+6 rows=6.83e+6) (actual time=3027..91754 rows=3.03e+6 loops=1)
        -> Sort: report_year, report_month, e.encounterclass  (cost=61694 rows=509420) (actual time=3027..3609 rows=533460 loops=1)
            -> Covering index scan on e using idx_enc_start_class_cov  (cost=61694 rows=509420) (actual time=1.87..1539 rows=533460 loops=1)
        -> Covering index lookup on o using idx_obs_enc_pat_code (encounter = e.id, patient = e.patient)  (cost=1.56 rows=13.4) (actual time=0.144..0.163 rows=5.05 loops=533460)
```

### MySQL Index EXPLAIN Run 3:
```text
EXPLAIN
-> Group aggregate: sum(e.total_claim_cost), count(distinct e.id), count(distinct e.patient), count(o.`code`)  (cost=3.11e+6 rows=1.42e+6) (actual time=2331..108599 rows=4174 loops=1)
    -> Nested loop left join  (cost=1.54e+6 rows=6.83e+6) (actual time=2324..93618 rows=3.03e+6 loops=1)
        -> Sort: report_year, report_month, e.encounterclass  (cost=61694 rows=509420) (actual time=2314..2927 rows=533460 loops=1)
            -> Covering index scan on e using idx_enc_start_class_cov  (cost=61694 rows=509420) (actual time=10..978 rows=533460 loops=1)
        -> Covering index lookup on o using idx_obs_enc_pat_code (encounter = e.id, patient = e.patient)  (cost=1.56 rows=13.4) (actual time=0.147..0.168 rows=5.05 loops=533460)
```

### MySQL Index EXPLAIN Run 4:
```text
EXPLAIN
-> Group aggregate: sum(e.total_claim_cost), count(distinct e.id), count(distinct e.patient), count(o.`code`)  (cost=3.11e+6 rows=1.42e+6) (actual time=2679..106976 rows=4174 loops=1)
    -> Nested loop left join  (cost=1.54e+6 rows=6.83e+6) (actual time=2667..92856 rows=3.03e+6 loops=1)
        -> Sort: report_year, report_month, e.encounterclass  (cost=61694 rows=509420) (actual time=2667..3262 rows=533460 loops=1)
            -> Covering index scan on e using idx_enc_start_class_cov  (cost=61694 rows=509420) (actual time=1.2..1320 rows=533460 loops=1)
        -> Covering index lookup on o using idx_obs_enc_pat_code (encounter = e.id, patient = e.patient)  (cost=1.56 rows=13.4) (actual time=0.146..0.166 rows=5.05 loops=533460)
```

### MySQL Index EXPLAIN Run 5:
```text
EXPLAIN
-> Group aggregate: sum(e.total_claim_cost), count(distinct e.id), count(distinct e.patient), count(o.`code`)  (cost=3.11e+6 rows=1.42e+6) (actual time=2783..115817 rows=4174 loops=1)
    -> Nested loop left join  (cost=1.54e+6 rows=6.83e+6) (actual time=2768..98976 rows=3.03e+6 loops=1)
        -> Sort: report_year, report_month, e.encounterclass  (cost=61694 rows=509420) (actual time=2768..3448 rows=533460 loops=1)
            -> Covering index scan on e using idx_enc_start_class_cov  (cost=61694 rows=509420) (actual time=4.6..1317 rows=533460 loops=1)
        -> Covering index lookup on o using idx_obs_enc_pat_code (encounter = e.id, patient = e.patient)  (cost=1.56 rows=13.4) (actual time=0.153..0.177 rows=5.05 loops=533460)
```

## 4. Q3 Statistics

### PG Stats Setup
```text
CREATE STATISTICS
CREATE STATISTICS
ANALYZE
ANALYZE
   statistics_name    |        attnames        | kinds 
----------------------+------------------------+-------
 stat_obs_enc_pat     | {patient,encounter}    | {d,f}
 stat_enc_start_class | {start,encounterclass} | {d,f}
(2 rows)
```

### PG Stats Timing (5 runs after 1 warm-up): [35683.277, 36035.118, 35636.529, 35856.038, 36219.078] | median=35856.038 ms

### PG Stats EXPLAIN Run 1:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.35..259872.27 rows=50258 width=116) (actual time=7485.081..37629.908 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15535 read=66119, temp read=130673 written=130916
   I/O Timings: shared read=229.807, temp read=1421.271 write=1535.750
   ->  Gather Merge  (cost=187401.35..249531.56 rows=533460 width=163) (actual time=7484.626..23322.069 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15535 read=66119, temp read=130673 written=130916
         I/O Timings: shared read=229.807, temp read=1421.271 write=1535.750
         ->  Sort  (cost=186401.33..186957.01 rows=222275 width=163) (actual time=6962.995..10688.232 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 119968kB
               Buffers: shared hit=15535 read=66119, temp read=130673 written=130916
               I/O Timings: shared read=229.807, temp read=1421.271 write=1535.750
               Worker 0:  Sort Method: external merge  Disk: 119328kB
               Worker 1:  Sort Method: external merge  Disk: 119528kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.10 rows=222275 width=163) (actual time=545.761..1409.280 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15505 read=66119, temp read=40980 written=41112
                     I/O Timings: shared read=229.807, temp read=148.014 write=391.010
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.46 rows=1248646 width=81) (actual time=1.774..151.433 rows=998990.00 loops=3)
                           Buffers: shared hit=5299 read=54557
                           I/O Timings: shared read=191.336
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=108.371..108.373 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=10206 read=11562, temp written=7668
                           I/O Timings: shared read=38.471, temp write=78.086
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=0.738..44.883 rows=177820.00 loops=3)
                                 Buffers: shared hit=10206 read=11562
                                 I/O Timings: shared read=38.471
 Planning:
   Buffers: shared hit=226 read=36
   I/O Timings: shared read=6.595
 Planning Time: 9.180 ms
 Execution Time: 37695.871 ms
(35 rows)
```

### PG Stats EXPLAIN Run 2:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.35..259872.27 rows=50258 width=116) (actual time=7228.447..37767.003 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15537 read=66117, temp read=130673 written=130943
   I/O Timings: shared read=310.711, temp read=1451.971 write=1337.237
   ->  Gather Merge  (cost=187401.35..249531.56 rows=533460 width=163) (actual time=7227.975..23460.053 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15537 read=66117, temp read=130673 written=130943
         I/O Timings: shared read=310.711, temp read=1451.971 write=1337.237
         ->  Sort  (cost=186401.33..186957.01 rows=222275 width=163) (actual time=7025.529..10705.931 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 119720kB
               Buffers: shared hit=15537 read=66117, temp read=130673 written=130943
               I/O Timings: shared read=310.711, temp read=1451.971 write=1337.237
               Worker 0:  Sort Method: external merge  Disk: 119064kB
               Worker 1:  Sort Method: external merge  Disk: 120040kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.10 rows=222275 width=163) (actual time=525.223..1454.474 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15507 read=66117, temp read=40981 written=41140
                     I/O Timings: shared read=310.711, temp read=160.535 write=275.900
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.46 rows=1248646 width=81) (actual time=1.954..170.670 rows=998990.00 loops=3)
                           Buffers: shared hit=5299 read=54557
                           I/O Timings: shared read=263.663
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=99.022..99.024 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=10208 read=11560, temp written=7668
                           I/O Timings: shared read=47.048, temp write=51.712
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.354..46.981 rows=177820.00 loops=3)
                                 Buffers: shared hit=10208 read=11560
                                 I/O Timings: shared read=47.048
 Planning:
   Buffers: shared hit=262
 Planning Time: 2.651 ms
 Execution Time: 37827.603 ms
(34 rows)
```

### PG Stats EXPLAIN Run 3:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.35..259872.27 rows=50258 width=116) (actual time=6792.336..36111.425 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15537 read=66117, temp read=130675 written=130930
   I/O Timings: shared read=256.996, temp read=1367.417 write=1403.019
   ->  Gather Merge  (cost=187401.35..249531.56 rows=533460 width=163) (actual time=6791.856..21936.345 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15537 read=66117, temp read=130675 written=130930
         I/O Timings: shared read=256.996, temp read=1367.417 write=1403.019
         ->  Sort  (cost=186401.33..186957.01 rows=222275 width=163) (actual time=6539.444..10246.765 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 119336kB
               Buffers: shared hit=15537 read=66117, temp read=130675 written=130930
               I/O Timings: shared read=256.996, temp read=1367.417 write=1403.019
               Worker 0:  Sort Method: external merge  Disk: 121208kB
               Worker 1:  Sort Method: external merge  Disk: 118264kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.10 rows=222275 width=163) (actual time=527.001..1399.020 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15507 read=66117, temp read=40985 written=41128
                     I/O Timings: shared read=256.996, temp read=142.077 write=387.217
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.46 rows=1248646 width=81) (actual time=3.309..150.411 rows=998990.00 loops=3)
                           Buffers: shared hit=5177 read=54679
                           I/O Timings: shared read=207.354
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=100.125..100.127 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=10330 read=11438, temp written=7672
                           I/O Timings: shared read=49.642, temp write=63.477
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=0.931..46.411 rows=177820.00 loops=3)
                                 Buffers: shared hit=10330 read=11438
                                 I/O Timings: shared read=49.642
 Planning:
   Buffers: shared hit=262
 Planning Time: 2.586 ms
 Execution Time: 36185.208 ms
(34 rows)
```

### PG Stats EXPLAIN Run 4:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.35..259872.27 rows=50258 width=116) (actual time=8151.542..37587.756 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15537 read=66117, temp read=130674 written=130939
   I/O Timings: shared read=473.430, temp read=1547.430 write=1541.206
   ->  Gather Merge  (cost=187401.35..249531.56 rows=533460 width=163) (actual time=8150.975..23181.405 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15537 read=66117, temp read=130674 written=130939
         I/O Timings: shared read=473.430, temp read=1547.430 write=1541.206
         ->  Sort  (cost=186401.33..186957.01 rows=222275 width=163) (actual time=7958.360..11694.155 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 119968kB
               Buffers: shared hit=15537 read=66117, temp read=130674 written=130939
               I/O Timings: shared read=473.430, temp read=1547.430 write=1541.206
               Worker 0:  Sort Method: external merge  Disk: 119520kB
               Worker 1:  Sort Method: external merge  Disk: 119328kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.10 rows=222275 width=163) (actual time=612.920..1643.146 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15507 read=66117, temp read=40982 written=41136
                     I/O Timings: shared read=473.430, temp read=187.623 write=309.430
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.46 rows=1248646 width=81) (actual time=2.634..234.112 rows=998990.00 loops=3)
                           Buffers: shared hit=5083 read=54773
                           I/O Timings: shared read=433.185
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=104.948..104.950 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=10424 read=11344, temp written=7668
                           I/O Timings: shared read=40.245, temp write=59.127
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.004..46.673 rows=177820.00 loops=3)
                                 Buffers: shared hit=10424 read=11344
                                 I/O Timings: shared read=40.245
 Planning:
   Buffers: shared hit=262
 Planning Time: 2.332 ms
 Execution Time: 37658.987 ms
(34 rows)
```

### PG Stats EXPLAIN Run 5:
```text
SET
                                                                           QUERY PLAN                                                                            
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=187401.35..259872.27 rows=50258 width=116) (actual time=7850.882..37743.142 rows=4174.00 loops=1)
   Group Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass
   Buffers: shared hit=15527 read=66127, temp read=130674 written=130936
   I/O Timings: shared read=259.715, temp read=1486.242 write=1726.223
   ->  Gather Merge  (cost=187401.35..249531.56 rows=533460 width=163) (actual time=7850.332..23470.923 rows=3026500.00 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=15527 read=66127, temp read=130674 written=130936
         I/O Timings: shared read=259.715, temp read=1486.242 write=1726.223
         ->  Sort  (cost=186401.33..186957.01 rows=222275 width=163) (actual time=7500.483..11215.082 rows=1008833.33 loops=3)
               Sort Key: (EXTRACT(year FROM e.start)), (EXTRACT(month FROM e.start)), e.encounterclass, e.id
               Sort Method: external merge  Disk: 118472kB
               Buffers: shared hit=15527 read=66127, temp read=130674 written=130936
               I/O Timings: shared read=259.715, temp read=1486.242 write=1726.223
               Worker 0:  Sort Method: external merge  Disk: 118560kB
               Worker 1:  Sort Method: external merge  Disk: 121792kB
               ->  Parallel Hash Right Join  (cost=30798.88..148426.10 rows=222275 width=163) (actual time=574.513..1455.595 rows=1008833.33 loops=3)
                     Hash Cond: (((o.encounter)::text = (e.id)::text) AND ((o.patient)::text = (e.patient)::text))
                     Buffers: shared hit=15497 read=66127, temp read=40982 written=41132
                     I/O Timings: shared read=259.715, temp read=151.040 write=445.604
                     ->  Parallel Seq Scan on observations o  (cost=0.00..72342.46 rows=1248646 width=81) (actual time=2.091..153.878 rows=998990.00 loops=3)
                           Buffers: shared hit=4934 read=54922
                           I/O Timings: shared read=194.423
                     ->  Parallel Hash  (cost=23990.75..23990.75 rows=222275 width=100) (actual time=116.141..116.142 rows=177820.00 loops=3)
                           Buckets: 65536  Batches: 16  Memory Usage: 5024kB
                           Buffers: shared hit=10563 read=11205, temp written=7676
                           I/O Timings: shared read=65.292, temp write=71.885
                           ->  Parallel Seq Scan on encounters e  (cost=0.00..23990.75 rows=222275 width=100) (actual time=1.192..54.342 rows=177820.00 loops=3)
                                 Buffers: shared hit=10563 read=11205
                                 I/O Timings: shared read=65.292
 Planning:
   Buffers: shared hit=262
 Planning Time: 3.364 ms
 Execution Time: 37813.357 ms
(34 rows)
```

### MySQL Stats (Histograms) Setup
```text
Table	Op	Msg_type	Msg_text
synthea_scale.encounters	analyze	status	OK
synthea_scale.observations	analyze	status	OK
Table	Op	Msg_type	Msg_text
synthea_scale.encounters	histogram	status	Histogram statistics created for column 'encounterclass'.
synthea_scale.encounters	histogram	status	Histogram statistics created for column 'start'.
Table	Op	Msg_type	Msg_text
synthea_scale.observations	histogram	status	Histogram statistics created for column 'encounter'.
synthea_scale.observations	histogram	status	Histogram statistics created for column 'patient'.
TABLE_NAME	COLUMN_NAME
encounters	encounterclass
encounters	start
observations	encounter
observations	patient
```

### MySQL Stats Timing (5 runs after 1 warm-up): [71349.964, 70238.227, 70862.947, 71541.051, 70668.242] | median=70862.947 ms

### MySQL Stats EXPLAIN Run 1:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=58308..74225 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=58308..59852 rows=3.03e+6 loops=1)
        -> Stream results  (cost=148e+9 rows=1.48e+12) (actual time=17953..43909 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=148e+9 rows=1.48e+12) (actual time=17953..38324 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=59362 rows=508889) (actual time=1.09..1669 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=0.0348..10597 rows=3e+6 loops=1)
```

### MySQL Stats EXPLAIN Run 2:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=57622..73804 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=57622..59217 rows=3.03e+6 loops=1)
        -> Stream results  (cost=148e+9 rows=1.48e+12) (actual time=17636..43222 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=148e+9 rows=1.48e+12) (actual time=17636..37582 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=59362 rows=508889) (actual time=1.06..1523 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=0.0096..10370 rows=3e+6 loops=1)
```

### MySQL Stats EXPLAIN Run 3:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=57475..73591 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=57474..59069 rows=3.03e+6 loops=1)
        -> Stream results  (cost=148e+9 rows=1.48e+12) (actual time=17652..43227 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=148e+9 rows=1.48e+12) (actual time=17652..37629 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=59362 rows=508889) (actual time=0.703..1572 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=0.0384..10340 rows=3e+6 loops=1)
```

### MySQL Stats EXPLAIN Run 4:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=57507..73632 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=57507..59046 rows=3.03e+6 loops=1)
        -> Stream results  (cost=148e+9 rows=1.48e+12) (actual time=16820..42815 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=148e+9 rows=1.48e+12) (actual time=16820..37080 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=59362 rows=508889) (actual time=8.02..1576 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=0.0512..9876 rows=3e+6 loops=1)
```

### MySQL Stats EXPLAIN Run 5:
```text
EXPLAIN
-> Group aggregate: sum(encounters.total_claim_cost), count(distinct encounters.id), count(distinct encounters.patient), count(observations.`code`)  (actual time=56859..74082 rows=4174 loops=1)
    -> Sort: report_year, report_month, e.encounterclass  (actual time=56859..58666 rows=3.03e+6 loops=1)
        -> Stream results  (cost=148e+9 rows=1.48e+12) (actual time=16649..42474 rows=3.03e+6 loops=1)
            -> Left hash join (o.patient = e.patient), (o.encounter = e.id)  (cost=148e+9 rows=1.48e+12) (actual time=16649..36758 rows=3.03e+6 loops=1)
                -> Table scan on e  (cost=59362 rows=508889) (actual time=0.775..1587 rows=533460 loops=1)
                -> Hash
                    -> Table scan on o  (cost=45.4 rows=2.91e+6) (actual time=0.0365..9638 rows=3e+6 loops=1)
```

## 5. Q3 Materialized View (PG) / Summary Table (MySQL)

### PG MatView Setup, Refresh & Size
```text
Timing is on.
DROP MATERIALIZED VIEW
Time: 0,573 ms
SELECT 4174
Time: 37438,751 ms (00:37,439)
ANALYZE
Time: 77,892 ms

[STDERR]
psql:<stdin>:5: NOTICE:  materialized view "mv_q3_monthly_report" does not exist, skipping

-- Refresh:
Timing is on.
REFRESH MATERIALIZED VIEW
Time: 35454,801 ms (00:35,455)

delta_d_bytes | delta_d_mb | size_pretty 
---------------+------------+-------------
        532480 |     0.5078 | 520 kB
(1 row)
```

### PG MatView Query 1 (Full report) Timing: [2.623, 2.703, 2.509, 2.533, 2.558] | median=2.558 ms

### PG MatView Query 2 (Filtered 2019 ambulatory) Timing: [0.347, 0.275, 0.276, 0.236, 0.238] | median=0.275 ms

### PG MatView Q1 EXPLAIN Run 1:
```text
SET
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=563.57..580.53 rows=6784 width=49) (actual time=1.154..1.262 rows=4174.00 loops=1)
   Sort Key: report_year, report_month, encounterclass
   Sort Method: quicksort  Memory: 500kB
   Buffers: shared hit=70
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..131.84 rows=6784 width=49) (actual time=0.012..0.301 rows=4174.00 loops=1)
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=69
 Planning Time: 0.866 ms
 Execution Time: 1.425 ms
(10 rows)
```

### PG MatView Q1 EXPLAIN Run 2:
```text
SET
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=563.57..580.53 rows=6784 width=49) (actual time=1.192..1.299 rows=4174.00 loops=1)
   Sort Key: report_year, report_month, encounterclass
   Sort Method: quicksort  Memory: 500kB
   Buffers: shared hit=70
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..131.84 rows=6784 width=49) (actual time=0.013..0.306 rows=4174.00 loops=1)
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=69
 Planning Time: 0.837 ms
 Execution Time: 1.468 ms
(10 rows)
```

### PG MatView Q1 EXPLAIN Run 3:
```text
SET
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=563.57..580.53 rows=6784 width=49) (actual time=1.213..1.347 rows=4174.00 loops=1)
   Sort Key: report_year, report_month, encounterclass
   Sort Method: quicksort  Memory: 500kB
   Buffers: shared hit=70
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..131.84 rows=6784 width=49) (actual time=0.011..0.332 rows=4174.00 loops=1)
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=69
 Planning Time: 0.725 ms
 Execution Time: 1.529 ms
(10 rows)
```

### PG MatView Q1 EXPLAIN Run 4:
```text
SET
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=563.57..580.53 rows=6784 width=49) (actual time=1.134..1.242 rows=4174.00 loops=1)
   Sort Key: report_year, report_month, encounterclass
   Sort Method: quicksort  Memory: 500kB
   Buffers: shared hit=70
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..131.84 rows=6784 width=49) (actual time=0.011..0.290 rows=4174.00 loops=1)
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=69
 Planning Time: 0.891 ms
 Execution Time: 1.403 ms
(10 rows)
```

### PG MatView Q1 EXPLAIN Run 5:
```text
SET
                                                           QUERY PLAN                                                           
--------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=563.57..580.53 rows=6784 width=49) (actual time=1.116..1.249 rows=4174.00 loops=1)
   Sort Key: report_year, report_month, encounterclass
   Sort Method: quicksort  Memory: 500kB
   Buffers: shared hit=70
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..131.84 rows=6784 width=49) (actual time=0.011..0.285 rows=4174.00 loops=1)
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=69
 Planning Time: 0.723 ms
 Execution Time: 1.423 ms
(10 rows)
```

### PG MatView Q2 EXPLAIN Run 1:
```text
SET
                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=166.34..166.40 rows=25 width=49) (actual time=0.902..0.904 rows=12.00 loops=1)
   Sort Key: report_month
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=67
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..165.76 rows=25 width=49) (actual time=0.763..0.854 rows=12.00 loops=1)
         Filter: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
         Rows Removed by Filter: 4162
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=62
 Planning Time: 1.062 ms
 Execution Time: 0.984 ms
(12 rows)
```

### PG MatView Q2 EXPLAIN Run 2:
```text
SET
                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=166.34..166.40 rows=25 width=49) (actual time=0.346..0.347 rows=12.00 loops=1)
   Sort Key: report_month
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=67
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..165.76 rows=25 width=49) (actual time=0.289..0.327 rows=12.00 loops=1)
         Filter: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
         Rows Removed by Filter: 4162
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=62
 Planning Time: 1.083 ms
 Execution Time: 0.379 ms
(12 rows)
```

### PG MatView Q2 EXPLAIN Run 3:
```text
SET
                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=166.34..166.40 rows=25 width=49) (actual time=0.478..0.479 rows=12.00 loops=1)
   Sort Key: report_month
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=67
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..165.76 rows=25 width=49) (actual time=0.418..0.454 rows=12.00 loops=1)
         Filter: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
         Rows Removed by Filter: 4162
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=62
 Planning Time: 1.283 ms
 Execution Time: 0.524 ms
(12 rows)
```

### PG MatView Q2 EXPLAIN Run 4:
```text
SET
                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=166.34..166.40 rows=25 width=49) (actual time=0.335..0.336 rows=12.00 loops=1)
   Sort Key: report_month
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=67
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..165.76 rows=25 width=49) (actual time=0.278..0.314 rows=12.00 loops=1)
         Filter: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
         Rows Removed by Filter: 4162
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=62
 Planning Time: 1.050 ms
 Execution Time: 0.366 ms
(12 rows)
```

### PG MatView Q2 EXPLAIN Run 5:
```text
SET
                                                         QUERY PLAN                                                         
----------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=166.34..166.40 rows=25 width=49) (actual time=0.327..0.327 rows=12.00 loops=1)
   Sort Key: report_month
   Sort Method: quicksort  Memory: 25kB
   Buffers: shared hit=67
   ->  Seq Scan on mv_q3_monthly_report  (cost=0.00..165.76 rows=25 width=49) (actual time=0.271..0.307 rows=12.00 loops=1)
         Filter: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
         Rows Removed by Filter: 4162
         Buffers: shared hit=64
 Planning:
   Buffers: shared hit=62
 Planning Time: 1.139 ms
 Execution Time: 0.356 ms
(12 rows)
```

### MySQL Summary Table Setup (elapsed=76014.8 ms) & Size
```text
Table	Op	Msg_type	Msg_text
synthea_scale.summary_q3_monthly_report	analyze	status	OK

TABLE_NAME	TABLE_ROWS	delta_d_bytes	delta_d_mb
summary_q3_monthly_report	4272	376832	0.3594
```

### MySQL Summary Query 1 (Full report) Timing: [65.683, 60.973, 64.917, 61.758, 64.782] | median=64.782 ms

### MySQL Summary Query 2 (Filtered 2019 ambulatory) Timing: [3.205, 3.718, 13.882, 8.374, 13.346] | median=8.374 ms

### MySQL Summary Q1 EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_year, summary_q3_monthly_report.report_month, summary_q3_monthly_report.encounterclass  (cost=433 rows=4272) (actual time=56.2..57.3 rows=4174 loops=1)
    -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0635..12.2 rows=4174 loops=1)
```

### MySQL Summary Q1 EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_year, summary_q3_monthly_report.report_month, summary_q3_monthly_report.encounterclass  (cost=433 rows=4272) (actual time=65.1..66.3 rows=4174 loops=1)
    -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0492..11.9 rows=4174 loops=1)
```

### MySQL Summary Q1 EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_year, summary_q3_monthly_report.report_month, summary_q3_monthly_report.encounterclass  (cost=433 rows=4272) (actual time=54.4..55.6 rows=4174 loops=1)
    -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0604..12.1 rows=4174 loops=1)
```

### MySQL Summary Q1 EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_year, summary_q3_monthly_report.report_month, summary_q3_monthly_report.encounterclass  (cost=433 rows=4272) (actual time=51.6..52.6 rows=4174 loops=1)
    -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0237..11 rows=4174 loops=1)
```

### MySQL Summary Q1 EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_year, summary_q3_monthly_report.report_month, summary_q3_monthly_report.encounterclass  (cost=433 rows=4272) (actual time=51.9..53 rows=4174 loops=1)
    -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0325..12.1 rows=4174 loops=1)
```

### MySQL Summary Q2 EXPLAIN Run 1:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_month  (cost=433 rows=4272) (actual time=1.91..1.91 rows=12 loops=1)
    -> Filter: ((summary_q3_monthly_report.report_year = 2019) and (summary_q3_monthly_report.encounterclass = 'ambulatory'))  (cost=433 rows=4272) (actual time=1.84..1.89 rows=12 loops=1)
        -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0242..1.75 rows=4174 loops=1)
```

### MySQL Summary Q2 EXPLAIN Run 2:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_month  (cost=433 rows=4272) (actual time=5.23..5.23 rows=12 loops=1)
    -> Filter: ((summary_q3_monthly_report.report_year = 2019) and (summary_q3_monthly_report.encounterclass = 'ambulatory'))  (cost=433 rows=4272) (actual time=4.77..5.16 rows=12 loops=1)
        -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0248..4.29 rows=4174 loops=1)
```

### MySQL Summary Q2 EXPLAIN Run 3:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_month  (cost=433 rows=4272) (actual time=7.7..7.7 rows=12 loops=1)
    -> Filter: ((summary_q3_monthly_report.report_year = 2019) and (summary_q3_monthly_report.encounterclass = 'ambulatory'))  (cost=433 rows=4272) (actual time=7.26..7.63 rows=12 loops=1)
        -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0284..6.11 rows=4174 loops=1)
```

### MySQL Summary Q2 EXPLAIN Run 4:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_month  (cost=433 rows=4272) (actual time=4.43..4.43 rows=12 loops=1)
    -> Filter: ((summary_q3_monthly_report.report_year = 2019) and (summary_q3_monthly_report.encounterclass = 'ambulatory'))  (cost=433 rows=4272) (actual time=3.99..4.36 rows=12 loops=1)
        -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0287..3.67 rows=4174 loops=1)
```

### MySQL Summary Q2 EXPLAIN Run 5:
```text
EXPLAIN
-> Sort: summary_q3_monthly_report.report_month  (cost=433 rows=4272) (actual time=5.58..5.58 rows=12 loops=1)
    -> Filter: ((summary_q3_monthly_report.report_year = 2019) and (summary_q3_monthly_report.encounterclass = 'ambulatory'))  (cost=433 rows=4272) (actual time=5.13..5.51 rows=12 loops=1)
        -> Table scan on summary_q3_monthly_report  (cost=433 rows=4272) (actual time=0.0215..4.56 rows=4174 loops=1)
```

## 6. Q3 Combined (MatView + Unique Index / Summary Table + PK)

### PG Combined Setup, Concurrent Refresh & Size
```text
Timing is on.
DROP MATERIALIZED VIEW
Time: 0,441 ms
SELECT 4174
Time: 36376,333 ms (00:36,376)
CREATE INDEX
Time: 21,631 ms
ANALYZE
Time: 53,198 ms

[STDERR]
psql:<stdin>:5: NOTICE:  materialized view "mv_q3_monthly_report" does not exist, skipping

-- Concurrent Refresh:
Timing is on.
REFRESH MATERIALIZED VIEW
Time: 35310,781 ms (00:35,311)

delta_d_bytes | delta_d_mb | size_pretty 
---------------+------------+-------------
        720896 |     0.6875 | 704 kB
(1 row)
```

### PG Combined Query 1 (Full report) Timing: [1.989, 1.824, 2.497, 1.906, 1.867] | median=1.906 ms

### PG Combined Query 2 (Filtered 2019 ambulatory) Timing: [0.213, 0.361, 0.383, 0.33, 0.258] | median=0.330 ms

### PG Combined Q1 EXPLAIN Run 1:
```text
SET
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..304.58 rows=4174 width=49) (actual time=0.016..0.468 rows=4174.00 loops=1)
   Index Searches: 1
   Buffers: shared hit=67
 Planning:
   Buffers: shared hit=94
 Planning Time: 1.461 ms
 Execution Time: 0.586 ms
(7 rows)
```

### PG Combined Q1 EXPLAIN Run 2:
```text
SET
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..304.58 rows=4174 width=49) (actual time=0.015..0.425 rows=4174.00 loops=1)
   Index Searches: 1
   Buffers: shared hit=67
 Planning:
   Buffers: shared hit=94
 Planning Time: 1.577 ms
 Execution Time: 0.542 ms
(7 rows)
```

### PG Combined Q1 EXPLAIN Run 3:
```text
SET
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..304.58 rows=4174 width=49) (actual time=0.016..0.531 rows=4174.00 loops=1)
   Index Searches: 1
   Buffers: shared hit=67
 Planning:
   Buffers: shared hit=94
 Planning Time: 1.291 ms
 Execution Time: 0.676 ms
(7 rows)
```

### PG Combined Q1 EXPLAIN Run 4:
```text
SET
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..304.58 rows=4174 width=49) (actual time=0.015..0.445 rows=4174.00 loops=1)
   Index Searches: 1
   Buffers: shared hit=67
 Planning:
   Buffers: shared hit=94
 Planning Time: 1.534 ms
 Execution Time: 0.561 ms
(7 rows)
```

### PG Combined Q1 EXPLAIN Run 5:
```text
SET
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..304.58 rows=4174 width=49) (actual time=0.015..0.418 rows=4174.00 loops=1)
   Index Searches: 1
   Buffers: shared hit=67
 Planning:
   Buffers: shared hit=94
 Planning Time: 1.498 ms
 Execution Time: 0.532 ms
(7 rows)
```

### PG Combined Q2 EXPLAIN Run 1:
```text
SET
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..57.32 rows=15 width=49) (actual time=0.058..0.067 rows=12.00 loops=1)
   Index Cond: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
   Index Searches: 1
   Buffers: shared hit=7
 Planning:
   Buffers: shared hit=92
 Planning Time: 1.563 ms
 Execution Time: 0.110 ms
(8 rows)
```

### PG Combined Q2 EXPLAIN Run 2:
```text
SET
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..57.32 rows=15 width=49) (actual time=0.038..0.043 rows=12.00 loops=1)
   Index Cond: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
   Index Searches: 1
   Buffers: shared hit=7
 Planning:
   Buffers: shared hit=92
 Planning Time: 1.341 ms
 Execution Time: 0.072 ms
(8 rows)
```

### PG Combined Q2 EXPLAIN Run 3:
```text
SET
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..57.32 rows=15 width=49) (actual time=0.049..0.055 rows=12.00 loops=1)
   Index Cond: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
   Index Searches: 1
   Buffers: shared hit=7
 Planning:
   Buffers: shared hit=92
 Planning Time: 1.264 ms
 Execution Time: 0.088 ms
(8 rows)
```

### PG Combined Q2 EXPLAIN Run 4:
```text
SET
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..57.32 rows=15 width=49) (actual time=0.049..0.054 rows=12.00 loops=1)
   Index Cond: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
   Index Searches: 1
   Buffers: shared hit=7
 Planning:
   Buffers: shared hit=92
 Planning Time: 1.655 ms
 Execution Time: 0.087 ms
(8 rows)
```

### PG Combined Q2 EXPLAIN Run 5:
```text
SET
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using idx_mv_q3_pk on mv_q3_monthly_report  (cost=0.28..57.32 rows=15 width=49) (actual time=0.036..0.042 rows=12.00 loops=1)
   Index Cond: ((report_year = 2019) AND ((encounterclass)::text = 'ambulatory'::text))
   Index Searches: 1
   Buffers: shared hit=7
 Planning:
   Buffers: shared hit=92
 Planning Time: 1.313 ms
 Execution Time: 0.070 ms
(8 rows)
```

### MySQL Combined Setup (elapsed=76494.1 ms) & Size
```text
Table	Op	Msg_type	Msg_text
synthea_scale.summary_q3_monthly_report	analyze	status	OK

TABLE_NAME	TABLE_ROWS	delta_d_bytes	delta_d_mb
summary_q3_monthly_report	4174	344064	0.3281
```

### MySQL Combined Query 1 (Full report) Timing: [7.474, 7.221, 8.194, 15.199, 10.798] | median=8.194 ms

### MySQL Combined Query 2 (Filtered 2019 ambulatory) Timing: [0.394, 0.441, 0.629, 0.451, 4.61] | median=0.451 ms

### MySQL Combined Q1 EXPLAIN Run 1:
```text
EXPLAIN
-> Index scan on summary_q3_monthly_report using PRIMARY  (cost=423 rows=4174) (actual time=0.212..4.25 rows=4174 loops=1)
```

### MySQL Combined Q1 EXPLAIN Run 2:
```text
EXPLAIN
-> Index scan on summary_q3_monthly_report using PRIMARY  (cost=423 rows=4174) (actual time=0.39..4.93 rows=4174 loops=1)
```

### MySQL Combined Q1 EXPLAIN Run 3:
```text
EXPLAIN
-> Index scan on summary_q3_monthly_report using PRIMARY  (cost=423 rows=4174) (actual time=0.109..1.13 rows=4174 loops=1)
```

### MySQL Combined Q1 EXPLAIN Run 4:
```text
EXPLAIN
-> Index scan on summary_q3_monthly_report using PRIMARY  (cost=423 rows=4174) (actual time=0.395..4.95 rows=4174 loops=1)
```

### MySQL Combined Q1 EXPLAIN Run 5:
```text
EXPLAIN
-> Index scan on summary_q3_monthly_report using PRIMARY  (cost=423 rows=4174) (actual time=0.097..1.48 rows=4174 loops=1)
```

### MySQL Combined Q2 EXPLAIN Run 1:
```text
EXPLAIN
-> Filter: (summary_q3_monthly_report.encounterclass = 'ambulatory')  (cost=1.01 rows=7.2) (actual time=0.0431..0.112 rows=12 loops=1)
    -> Index lookup on summary_q3_monthly_report using PRIMARY (report_year = 2019)  (cost=1.01 rows=72) (actual time=0.039..0.0961 rows=72 loops=1)
```

### MySQL Combined Q2 EXPLAIN Run 2:
```text
EXPLAIN
-> Filter: (summary_q3_monthly_report.encounterclass = 'ambulatory')  (cost=1.01 rows=7.2) (actual time=0.0683..0.179 rows=12 loops=1)
    -> Index lookup on summary_q3_monthly_report using PRIMARY (report_year = 2019)  (cost=1.01 rows=72) (actual time=0.0624..0.153 rows=72 loops=1)
```

### MySQL Combined Q2 EXPLAIN Run 3:
```text
EXPLAIN
-> Filter: (summary_q3_monthly_report.encounterclass = 'ambulatory')  (cost=1.01 rows=7.2) (actual time=0.0482..0.0723 rows=12 loops=1)
    -> Index lookup on summary_q3_monthly_report using PRIMARY (report_year = 2019)  (cost=1.01 rows=72) (actual time=0.0458..0.0655 rows=72 loops=1)
```

### MySQL Combined Q2 EXPLAIN Run 4:
```text
EXPLAIN
-> Filter: (summary_q3_monthly_report.encounterclass = 'ambulatory')  (cost=1.01 rows=7.2) (actual time=0.0204..0.0447 rows=12 loops=1)
    -> Index lookup on summary_q3_monthly_report using PRIMARY (report_year = 2019)  (cost=1.01 rows=72) (actual time=0.0182..0.0384 rows=72 loops=1)
```

### MySQL Combined Q2 EXPLAIN Run 5:
```text
EXPLAIN
-> Filter: (summary_q3_monthly_report.encounterclass = 'ambulatory')  (cost=1.01 rows=7.2) (actual time=0.0198..0.0432 rows=12 loops=1)
    -> Index lookup on summary_q3_monthly_report using PRIMARY (report_year = 2019)  (cost=1.01 rows=72) (actual time=0.0174..0.0367 rows=72 loops=1)
```
