# RAW LOGS TẤT CẢ CÁC LẦN CHẠY TRÊN DỮ LIỆU SCALE 10X THUẦN (CHỈ PK, KHÔNG INDEX PHỤ)

## 0. Phiên bản Hệ quản trị CSDL (Server Versions)
```text
version                                 
-------------------------------------------------------------------------
 PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35229, 64-bit
(1 row)

VERSION()
9.4.0
```

## 1. Q1_01_baseline_pg.sql (Full file + 5 lần EXPLAIN)

### Full File Execution (`psql -f Q1_01_baseline_pg.sql`):
```text
Timing is on.
     tbl      |    n    
--------------+---------
 patients     |   11710
 conditions   |   83760
 encounters   |  533460
 observations | 2996970
(4 rows)

Time: 1489,124 ms (00:01,489)
 encounterclass |   n    |  pct  
----------------+--------+-------
 wellness       | 191060 | 35.82
 ambulatory     | 189360 | 35.50
 outpatient     |  90030 | 16.88
 urgentcare     |  23730 |  4.45
 emergency      |  20900 |  3.92
 inpatient      |  18380 |  3.45
(6 rows)

Time: 201,759 ms
 enc_ambulatory_2020 | pct_of_encounters 
---------------------+-------------------
                3840 |              0.72
(1 row)

Time: 451,057 ms
 result_rows 
-------------
       12910
(1 row)

Time: 985,564 ms
 tablename  |    indexname    |                                 indexdef                                  
------------+-----------------+---------------------------------------------------------------------------
 encounters | encounters_pkey | CREATE UNIQUE INDEX encounters_pkey ON public.encounters USING btree (id)
 patients   | patients_pkey   | CREATE UNIQUE INDEX patients_pkey ON public.patients USING btree (id)
(2 rows)

Time: 34,012 ms
 cond_patient_mismatch 
-----------------------
                     0
(1 row)

Time: 279,057 ms
 obs_patient_mismatch 
----------------------
                    0
(1 row)

Time: 2194,916 ms (00:02,195)
 work_mem 
----------
 4MB
(1 row)

Time: 0,218 ms
 shared_buffers 
----------------
 128MB
(1 row)

Time: 0,107 ms
 effective_cache_size 
----------------------
 4GB
(1 row)

Time: 0,128 ms
 max_parallel_workers_per_gather 
---------------------------------
 2
(1 row)

Time: 0,118 ms
SET
Time: 0,185 ms
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107988.51..107988.52 rows=2 width=212) (actual time=1707.530..1713.786 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=51195 read=70718
   I/O Timings: shared read=769.942
   ->  Gather  (cost=105574.05..107988.50 rows=2 width=212) (actual time=1487.787..1543.170 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=51192 read=70718
         I/O Timings: shared read=769.942
         ->  Parallel Hash Right Join  (cost=104574.05..106988.30 rows=1 width=212) (actual time=1446.763..1475.198 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=51192 read=70718
               I/O Timings: shared read=769.942
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.024..6.526 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104574.04..104574.04 rows=1 width=165) (actual time=1444.756..1444.764 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=49637 read=70718
                     I/O Timings: shared read=769.942
                     ->  Nested Loop  (cost=25678.68..104574.04 rows=1 width=165) (actual time=207.373..1380.360 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=49637 read=70718
                           I/O Timings: shared read=769.942
                           ->  Parallel Hash Join  (cost=25678.39..104573.09 rows=3 width=181) (actual time=207.169..1292.617 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=10906 read=70718
                                 I/O Timings: shared read=769.942
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=118) (actual time=0.779..552.904 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3213 read=56643
                                       I/O Timings: shared read=568.392
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=204.203..204.205 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=7693 read=14075
                                       I/O Timings: shared read=201.551
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1372 width=100) (actual time=3.160..199.972 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=7693 read=14075
                                             I/O Timings: shared read=201.551
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.012..0.012 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=81
 Planning Time: 2.043 ms
 Execution Time: 1717.462 ms
(48 rows)

Time: 1721,427 ms (00:01,721)
```

### PG Baseline Run 1:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107988.51..107988.52 rows=2 width=212) (actual time=1080.944..1082.472 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=51574 read=70342
   I/O Timings: shared read=963.901
   ->  Gather  (cost=105574.05..107988.50 rows=2 width=212) (actual time=1028.624..1047.060 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=51568 read=70342
         I/O Timings: shared read=963.901
         ->  Parallel Hash Right Join  (cost=104574.05..106988.30 rows=1 width=212) (actual time=932.238..945.363 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=51568 read=70342
               I/O Timings: shared read=963.901
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.009..2.870 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104574.04..104574.04 rows=1 width=165) (actual time=932.086..932.091 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3128kB
                     Buffers: shared hit=50013 read=70342
                     I/O Timings: shared read=963.901
                     ->  Nested Loop  (cost=25678.68..104574.04 rows=1 width=165) (actual time=265.853..910.014 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=50013 read=70342
                           I/O Timings: shared read=963.901
                           ->  Parallel Hash Join  (cost=25678.39..104573.09 rows=3 width=181) (actual time=265.789..873.237 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=11282 read=70342
                                 I/O Timings: shared read=963.901
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=118) (actual time=1.416..390.693 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3401 read=56455
                                       I/O Timings: shared read=581.714
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=260.195..260.196 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=7881 read=13887
                                       I/O Timings: shared read=382.187
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1372 width=100) (actual time=3.522..258.077 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=7881 read=13887
                                             I/O Timings: shared read=382.187
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.005..0.005 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=343
 Planning Time: 6.721 ms
 Execution Time: 1083.205 ms
(48 rows)
```

### PG Baseline Run 2:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107988.51..107988.52 rows=2 width=212) (actual time=764.620..767.442 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=51950 read=69966
   I/O Timings: shared read=559.797
   ->  Gather  (cost=105574.05..107988.50 rows=2 width=212) (actual time=713.464..731.325 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=51944 read=69966
         I/O Timings: shared read=559.797
         ->  Parallel Hash Right Join  (cost=104574.05..106988.30 rows=1 width=212) (actual time=675.610..688.898 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=51944 read=69966
               I/O Timings: shared read=559.797
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.008..2.966 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104574.04..104574.04 rows=1 width=165) (actual time=675.443..675.449 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=50389 read=69966
                     I/O Timings: shared read=559.797
                     ->  Nested Loop  (cost=25678.68..104574.04 rows=1 width=165) (actual time=136.632..652.288 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=50389 read=69966
                           I/O Timings: shared read=559.797
                           ->  Parallel Hash Join  (cost=25678.39..104573.09 rows=3 width=181) (actual time=136.545..623.261 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=11658 read=69966
                                 I/O Timings: shared read=559.797
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=118) (actual time=0.509..290.702 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3589 read=56267
                                       I/O Timings: shared read=400.934
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=133.197..133.198 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8069 read=13699
                                       I/O Timings: shared read=158.863
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1372 width=100) (actual time=5.859..131.658 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8069 read=13699
                                             I/O Timings: shared read=158.863
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=343
 Planning Time: 5.769 ms
 Execution Time: 768.272 ms
(48 rows)
```

### PG Baseline Run 3:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107988.51..107988.52 rows=2 width=212) (actual time=770.438..772.127 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=52326 read=69590
   I/O Timings: shared read=508.783
   ->  Gather  (cost=105574.05..107988.50 rows=2 width=212) (actual time=721.427..737.584 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=52320 read=69590
         I/O Timings: shared read=508.783
         ->  Parallel Hash Right Join  (cost=104574.05..106988.30 rows=1 width=212) (actual time=636.550..649.459 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=52320 read=69590
               I/O Timings: shared read=508.783
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.006..2.820 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104574.04..104574.04 rows=1 width=165) (actual time=636.436..636.441 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=50765 read=69590
                     I/O Timings: shared read=508.783
                     ->  Nested Loop  (cost=25678.68..104574.04 rows=1 width=165) (actual time=93.226..624.094 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=50765 read=69590
                           I/O Timings: shared read=508.783
                           ->  Parallel Hash Join  (cost=25678.39..104573.09 rows=3 width=181) (actual time=93.160..591.558 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=12034 read=69590
                                 I/O Timings: shared read=508.783
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=118) (actual time=1.634..302.158 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3777 read=56079
                                       I/O Timings: shared read=424.552
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=89.348..89.349 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8257 read=13511
                                       I/O Timings: shared read=84.232
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1372 width=100) (actual time=0.507..88.011 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8257 read=13511
                                             I/O Timings: shared read=84.232
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=343
 Planning Time: 4.895 ms
 Execution Time: 772.844 ms
(48 rows)
```

### PG Baseline Run 4:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107988.51..107988.52 rows=2 width=212) (actual time=887.054..889.424 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=52608 read=69308
   I/O Timings: shared read=771.961
   ->  Gather  (cost=105574.05..107988.50 rows=2 width=212) (actual time=831.862..847.590 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=52602 read=69308
         I/O Timings: shared read=771.961
         ->  Parallel Hash Right Join  (cost=104574.05..106988.30 rows=1 width=212) (actual time=797.608..808.781 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=52602 read=69308
               I/O Timings: shared read=771.961
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.006..2.453 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104574.04..104574.04 rows=1 width=165) (actual time=797.498..797.504 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=51047 read=69308
                     I/O Timings: shared read=771.961
                     ->  Nested Loop  (cost=25678.68..104574.04 rows=1 width=165) (actual time=150.293..781.250 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=51047 read=69308
                           I/O Timings: shared read=771.961
                           ->  Parallel Hash Join  (cost=25678.39..104573.09 rows=3 width=181) (actual time=150.223..748.579 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=12316 read=69308
                                 I/O Timings: shared read=771.961
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=118) (actual time=0.938..386.060 rows=1498485.00 loops=2)
                                       Buffers: shared hit=3965 read=55891
                                       I/O Timings: shared read=576.106
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=145.873..145.874 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8351 read=13417
                                       I/O Timings: shared read=195.855
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1372 width=100) (actual time=2.784..144.476 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8351 read=13417
                                             I/O Timings: shared read=195.855
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=343
 Planning Time: 4.221 ms
 Execution Time: 890.287 ms
(48 rows)
```

### PG Baseline Run 5:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107988.51..107988.52 rows=2 width=212) (actual time=765.059..766.763 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=52984 read=68932
   I/O Timings: shared read=634.923
   ->  Gather  (cost=105574.05..107988.50 rows=2 width=212) (actual time=715.757..731.468 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=52978 read=68932
         I/O Timings: shared read=634.923
         ->  Parallel Hash Right Join  (cost=104574.05..106988.30 rows=1 width=212) (actual time=677.231..688.817 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=52978 read=68932
               I/O Timings: shared read=634.923
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.005..2.595 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104574.04..104574.04 rows=1 width=165) (actual time=677.115..677.120 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=51423 read=68932
                     I/O Timings: shared read=634.923
                     ->  Nested Loop  (cost=25678.68..104574.04 rows=1 width=165) (actual time=209.688..665.737 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=51423 read=68932
                           I/O Timings: shared read=634.923
                           ->  Parallel Hash Join  (cost=25678.39..104573.09 rows=3 width=181) (actual time=209.306..637.342 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=12692 read=68932
                                 I/O Timings: shared read=634.923
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=118) (actual time=1.146..252.100 rows=1498485.00 loops=2)
                                       Buffers: shared hit=4153 read=55703
                                       I/O Timings: shared read=342.762
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=206.948..206.949 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=8539 read=13229
                                       I/O Timings: shared read=292.161
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1372 width=100) (actual time=3.219..205.108 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8539 read=13229
                                             I/O Timings: shared read=292.161
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=343
 Planning Time: 5.092 ms
 Execution Time: 767.442 ms
(48 rows)
```

## 2. Q1_01_baseline_mysql.sql (Full file + 5 lần EXPLAIN)

### Full File Execution (`mysql < Q1_01_baseline_mysql.sql`):
```text
tbl	n
patients	11710
encounters	533460
conditions	83760
observations	2996970
encounterclass	n	pct
wellness	191060	35.82
ambulatory	189360	35.50
outpatient	90030	16.88
urgentcare	23730	4.45
emergency	20900	3.92
inpatient	18380	3.45
enc_ambulatory_2020	pct_of_encounters
3840	0.72
result_rows
12910
TABLE_NAME	INDEX_NAME	SEQ_IN_INDEX	COLUMN_NAME	CARDINALITY
encounters	PRIMARY	1	id	510483
patients	PRIMARY	1	id	11551
cond_patient_mismatch
0
obs_patient_mismatch
0
sort_buffer_size	join_buffer_size	innodb_buffer_pool_size	tmp_table_size
262144	262144	134217728	154140672
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=69677..69688 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=1007..69594 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=1007..69542 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.12e+6 rows=142490) (actual time=49.2..68023 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.96e+6 rows=142490) (actual time=48.4..67623 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=315381 rows=2.85e+6) (actual time=1.49..14885 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.49..13044 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.479 rows=0.05) (actual time=0.0192..0.0192 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.479 rows=1) (actual time=0.0166..0.0167 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.996 rows=1) (actual time=0.0302..0.0305 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83067) (actual time=0.774..409 rows=83760 loops=1)
```

### MySQL Baseline Run 1:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=69675..69689 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=1215..69533 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=1214..69457 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=91..67617 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=90.4..67215 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=315381 rows=2.85e+6) (actual time=1.39..15078 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.39..13165 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.019..0.019 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0164..0.0165 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0304..0.0305 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83067) (actual time=1.01..463 rows=83760 loops=1)
```

### MySQL Baseline Run 2:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=67023..67032 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=958..66937 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=958..66885 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=121..65472 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=120..65072 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=315381 rows=2.85e+6) (actual time=1.47..14315 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.47..12611 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0185..0.0185 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.016..0.0161 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0304..0.0304 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83067) (actual time=1.24..331 rows=83760 loops=1)
```

### MySQL Baseline Run 3:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=69065..69073 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=1055..68975 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=1055..68921 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=90.6..67363 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=90..66967 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=315381 rows=2.85e+6) (actual time=2.11..15098 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=2.11..13297 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0189..0.0189 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0163..0.0164 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0299..0.03 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83067) (actual time=1.41..360 rows=83760 loops=1)
```

### MySQL Baseline Run 4:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=71626..71635 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=952..71549 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=952..71499 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=86.3..70096 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=85.8..69666 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=315381 rows=2.85e+6) (actual time=1.46..15773 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.45..13806 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0196..0.0196 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0169..0.017 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0326..0.0327 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83067) (actual time=1.64..339 rows=83760 loops=1)
```

### MySQL Baseline Run 5:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=65747..65756 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=1203..65648 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=1203..65574 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=123..63726 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=121..63334 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=315381 rows=2.85e+6) (actual time=3.48..14389 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=3.47..12653 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0178..0.0178 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0153..0.0154 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0297..0.0298 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83067) (actual time=1.12..399 rows=83760 loops=1)
```

## 3. Q1_02_rewrite_pg.sql (Full file + 5 lần 02a & 5 lần 02b)

### Full File Execution (`psql -f Q1_02_rewrite_pg.sql`):
```text
Timing is on.
SET
Time: 0,114 ms
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106144.71..108253.28 rows=18501 width=212) (actual time=682.241..691.517 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=15472 read=68556
   I/O Timings: shared read=456.387
   ->  Sort  (cost=105144.70..105171.90 rows=10883 width=212) (actual time=561.240..561.618 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3007kB
         Buffers: shared hit=15472 read=68556
         I/O Timings: shared read=456.387
         Worker 0:  Sort Method: quicksort  Memory: 140kB
         ->  Parallel Hash Right Join  (cost=102089.61..104415.00 rows=10883 width=212) (actual time=531.433..542.732 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=15457 read=68556
               I/O Timings: shared read=456.387
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.007..2.802 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=101993.25..101993.25 rows=7709 width=165) (actual time=531.238..531.244 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=13902 read=68556
                     I/O Timings: shared read=456.387
                     ->  Hash Join  (cost=26355.44..101993.25 rows=7709 width=165) (actual time=140.504..527.398 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=13902 read=68556
                           I/O Timings: shared read=456.387
                           ->  Parallel Hash Join  (cost=25674.96..101292.53 rows=7709 width=144) (actual time=133.844..518.933 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13068 read=68556
                                 I/O Timings: shared read=456.387
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=81) (actual time=0.645..243.097 rows=1498485.00 loops=2)
                                       Buffers: shared hit=4341 read=55515
                                       I/O Timings: shared read=323.703
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=127.798..127.799 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8727 read=13041
                                       I/O Timings: shared read=132.685
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=2.012..126.089 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8727 read=13041
                                             I/O Timings: shared read=132.685
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=6.598..6.599 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.394..3.854 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=315
 Planning Time: 4.608 ms
 Execution Time: 692.376 ms
(50 rows)

Time: 698,533 ms
                                                                                                 QUERY PLAN                                                                                                 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=165903.55..166253.34 rows=139916 width=313) (actual time=722.987..723.708 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=15355 read=68238
   I/O Timings: shared read=364.055
   CTE e
     ->  Gather  (cost=1000.00..26987.21 rows=3294 width=100) (actual time=1.903..158.688 rows=3840.00 loops=1)
           Workers Planned: 2
           Workers Launched: 2
           Buffers: shared hit=8859 read=12909
           I/O Timings: shared read=288.203
           ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=3.461..127.352 rows=1280.00 loops=3)
                 Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                 Rows Removed by Filter: 176540
                 Buffers: shared hit=8859 read=12909
                 I/O Timings: shared read=288.203
   ->  Hash Join  (cost=3587.99..106391.58 rows=139916 width=313) (actual time=186.446..688.186 rows=12910.00 loops=1)
         Hash Cond: ((o.encounter)::text = (e.id)::text)
         Buffers: shared hit=15355 read=68238
         I/O Timings: shared read=364.055
         ->  Seq Scan on observations o  (cost=0.00..89818.54 rows=2996254 width=81) (actual time=0.306..237.336 rows=2996970.00 loops=1)
               Buffers: shared hit=4527 read=55329
               I/O Timings: shared read=75.852
         ->  Hash  (cost=3539.85..3539.85 rows=3851 width=256) (actual time=184.179..184.182 rows=3960.00 loops=1)
               Buckets: 4096  Batches: 1  Memory Usage: 737kB
               Buffers: shared hit=10828 read=12909
               I/O Timings: shared read=288.203
               ->  Hash Join  (cost=787.53..3539.85 rows=3851 width=256) (actual time=167.116..183.030 rows=3960.00 loops=1)
                     Hash Cond: ((e.patient)::text = (p.id)::text)
                     Buffers: shared hit=10828 read=12909
                     I/O Timings: shared read=288.203
                     ->  Hash Right Join  (cost=107.06..2849.26 rows=3851 width=288) (actual time=162.814..177.616 rows=3960.00 loops=1)
                           Hash Cond: ((c.encounter)::text = (e.id)::text)
                           Buffers: shared hit=10411 read=12909
                           I/O Timings: shared read=288.203
                           ->  Seq Scan on conditions c  (cost=0.00..2389.60 rows=83760 width=71) (actual time=0.019..4.252 rows=83760.00 loops=1)
                                 Buffers: shared hit=1552
                           ->  Hash  (cost=65.88..65.88 rows=3294 width=254) (actual time=162.747..162.747 rows=3840.00 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 561kB
                                 Buffers: shared hit=8859 read=12909
                                 I/O Timings: shared read=288.203
                                 ->  CTE Scan on e  (cost=0.00..65.88 rows=3294 width=254) (actual time=1.907..160.603 rows=3840.00 loops=1)
                                       Storage: Memory  Maximum Storage: 543kB
                                       Buffers: shared hit=8859 read=12909
                                       I/O Timings: shared read=288.203
                     ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.254..4.255 rows=11710.00 loops=1)
                           Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                           Buffers: shared hit=417
                           ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.006..1.796 rows=11710.00 loops=1)
                                 Buffers: shared hit=417
 Planning:
   Buffers: shared hit=6
 Planning Time: 0.357 ms
 Execution Time: 724.700 ms
(54 rows)

Time: 725,530 ms
```

### PG Rewrite 02a Run 1:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106144.71..108253.28 rows=18501 width=212) (actual time=666.788..678.997 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=15969 read=68059
   I/O Timings: shared read=531.766
   ->  Sort  (cost=105144.70..105171.90 rows=10883 width=212) (actual time=610.837..611.240 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 146kB
         Buffers: shared hit=15969 read=68059
         I/O Timings: shared read=531.766
         Worker 0:  Sort Method: quicksort  Memory: 3001kB
         ->  Parallel Hash Right Join  (cost=102089.61..104415.00 rows=10883 width=212) (actual time=580.028..591.760 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=15954 read=68059
               I/O Timings: shared read=531.766
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.008..2.828 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=101993.25..101993.25 rows=7709 width=165) (actual time=579.778..579.781 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=14399 read=68059
                     I/O Timings: shared read=531.766
                     ->  Hash Join  (cost=26355.44..101993.25 rows=7709 width=165) (actual time=98.866..575.992 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14399 read=68059
                           I/O Timings: shared read=531.766
                           ->  Parallel Hash Join  (cost=25674.96..101292.53 rows=7709 width=144) (actual time=92.893..568.015 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13565 read=68059
                                 I/O Timings: shared read=531.766
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=81) (actual time=0.559..313.937 rows=1498485.00 loops=2)
                                       Buffers: shared hit=4621 read=55235
                                       I/O Timings: shared read=444.723
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=89.117..89.118 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8944 read=12824
                                       I/O Timings: shared read=87.043
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=2.390..87.938 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8944 read=12824
                                             I/O Timings: shared read=87.043
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=5.912..5.912 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.888..3.547 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=315
 Planning Time: 4.273 ms
 Execution Time: 679.631 ms
(50 rows)
```

### PG Rewrite 02a Run 2:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106144.71..108253.28 rows=18501 width=212) (actual time=701.221..710.397 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=15999 read=68029
   I/O Timings: shared read=646.902
   ->  Sort  (cost=105144.70..105171.90 rows=10883 width=212) (actual time=655.488..655.914 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 2999kB
         Buffers: shared hit=15999 read=68029
         I/O Timings: shared read=646.902
         Worker 0:  Sort Method: quicksort  Memory: 148kB
         ->  Parallel Hash Right Join  (cost=102089.61..104415.00 rows=10883 width=212) (actual time=627.887..639.439 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=15984 read=68029
               I/O Timings: shared read=646.902
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.006..3.024 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=101993.25..101993.25 rows=7709 width=165) (actual time=627.731..627.736 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=14429 read=68029
                     I/O Timings: shared read=646.902
                     ->  Hash Join  (cost=26355.44..101993.25 rows=7709 width=165) (actual time=130.682..623.971 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14429 read=68029
                           I/O Timings: shared read=646.902
                           ->  Parallel Hash Join  (cost=25674.96..101292.53 rows=7709 width=144) (actual time=125.040..616.385 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13595 read=68029
                                 I/O Timings: shared read=646.902
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=81) (actual time=0.888..332.104 rows=1498485.00 loops=2)
                                       Buffers: shared hit=4625 read=55231
                                       I/O Timings: shared read=480.350
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=122.890..122.891 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8970 read=12798
                                       I/O Timings: shared read=166.552
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=1.772..121.842 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8970 read=12798
                                             I/O Timings: shared read=166.552
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=5.592..5.592 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.366..3.087 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=315
 Planning Time: 3.747 ms
 Execution Time: 711.393 ms
(50 rows)
```

### PG Rewrite 02a Run 3:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106144.71..108253.28 rows=18501 width=212) (actual time=746.669..754.478 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=16066 read=67962
   I/O Timings: shared read=605.039
   ->  Sort  (cost=105144.70..105171.90 rows=10883 width=212) (actual time=690.040..690.346 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3000kB
         Buffers: shared hit=16066 read=67962
         I/O Timings: shared read=605.039
         Worker 0:  Sort Method: quicksort  Memory: 147kB
         ->  Parallel Hash Right Join  (cost=102089.61..104415.00 rows=10883 width=212) (actual time=664.283..674.767 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=16051 read=67962
               I/O Timings: shared read=605.039
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.006..2.833 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=101993.25..101993.25 rows=7709 width=165) (actual time=664.115..664.120 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=14496 read=67962
                     I/O Timings: shared read=605.039
                     ->  Hash Join  (cost=26355.44..101993.25 rows=7709 width=165) (actual time=128.111..659.862 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14496 read=67962
                           I/O Timings: shared read=605.039
                           ->  Parallel Hash Join  (cost=25674.96..101292.53 rows=7709 width=144) (actual time=120.387..649.957 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13662 read=67962
                                 I/O Timings: shared read=605.039
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=81) (actual time=0.604..339.987 rows=1498485.00 loops=2)
                                       Buffers: shared hit=4692 read=55164
                                       I/O Timings: shared read=472.812
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=118.414..118.414 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8970 read=12798
                                       I/O Timings: shared read=132.227
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=1.903..117.129 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8970 read=12798
                                             I/O Timings: shared read=132.227
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=7.645..7.645 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=1.123..4.593 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=315
 Planning Time: 7.527 ms
 Execution Time: 755.283 ms
(50 rows)
```

### PG Rewrite 02a Run 4:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106144.71..108253.28 rows=18501 width=212) (actual time=632.480..640.955 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=16199 read=67829
   I/O Timings: shared read=550.794
   ->  Sort  (cost=105144.70..105171.90 rows=10883 width=212) (actual time=587.237..587.621 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 2978kB
         Buffers: shared hit=16199 read=67829
         I/O Timings: shared read=550.794
         Worker 0:  Sort Method: quicksort  Memory: 170kB
         ->  Parallel Hash Right Join  (cost=102089.61..104415.00 rows=10883 width=212) (actual time=557.914..570.111 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=16184 read=67829
               I/O Timings: shared read=550.794
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.008..2.696 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=101993.25..101993.25 rows=7709 width=165) (actual time=557.740..557.745 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=14629 read=67829
                     I/O Timings: shared read=550.794
                     ->  Hash Join  (cost=26355.44..101993.25 rows=7709 width=165) (actual time=129.297..554.537 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14629 read=67829
                           I/O Timings: shared read=550.794
                           ->  Parallel Hash Join  (cost=25674.96..101292.53 rows=7709 width=144) (actual time=124.935..548.461 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=13795 read=67829
                                 I/O Timings: shared read=550.794
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=81) (actual time=0.750..280.370 rows=1498485.00 loops=2)
                                       Buffers: shared hit=4880 read=54976
                                       I/O Timings: shared read=399.173
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=122.427..122.428 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8915 read=12853
                                       I/O Timings: shared read=151.621
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=1.697..121.275 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8915 read=12853
                                             I/O Timings: shared read=151.621
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.310..4.311 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.311..2.468 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=315
 Planning Time: 5.435 ms
 Execution Time: 641.811 ms
(50 rows)
```

### PG Rewrite 02a Run 5:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=106144.71..108253.28 rows=18501 width=212) (actual time=563.071..570.083 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=16422 read=67606
   I/O Timings: shared read=362.810
   ->  Sort  (cost=105144.70..105171.90 rows=10883 width=212) (actual time=473.327..473.655 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3004kB
         Buffers: shared hit=16422 read=67606
         I/O Timings: shared read=362.810
         Worker 0:  Sort Method: quicksort  Memory: 143kB
         ->  Parallel Hash Right Join  (cost=102089.61..104415.00 rows=10883 width=212) (actual time=445.693..457.035 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=16407 read=67606
               I/O Timings: shared read=362.810
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.021..2.758 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=101993.25..101993.25 rows=7709 width=165) (actual time=445.510..445.514 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=14852 read=67606
                     I/O Timings: shared read=362.810
                     ->  Hash Join  (cost=26355.44..101993.25 rows=7709 width=165) (actual time=87.340..442.410 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=14852 read=67606
                           I/O Timings: shared read=362.810
                           ->  Parallel Hash Join  (cost=25674.96..101292.53 rows=7709 width=144) (actual time=82.130..435.601 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=14018 read=67606
                                 I/O Timings: shared read=362.810
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72340.39 rows=1248439 width=81) (actual time=1.133..219.459 rows=1498485.00 loops=2)
                                       Buffers: shared hit=5068 read=54788
                                       I/O Timings: shared read=288.093
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=79.070..79.071 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=8950 read=12818
                                       I/O Timings: shared read=74.717
                                       ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=0.585..77.938 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=8950 read=12818
                                             I/O Timings: shared read=74.717
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=5.162..5.163 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.671..3.054 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=315
 Planning Time: 4.091 ms
 Execution Time: 570.900 ms
(50 rows)
```

### PG Rewrite 02b Run 1:
```text
SET
                                                                                                 QUERY PLAN                                                                                                 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=165903.55..166253.34 rows=139916 width=313) (actual time=877.048..878.151 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=15895 read=67704
   I/O Timings: shared read=807.167
   CTE e
     ->  Gather  (cost=1000.00..26987.21 rows=3294 width=100) (actual time=1.493..299.839 rows=3840.00 loops=1)
           Workers Planned: 2
           Workers Launched: 2
           Buffers: shared hit=8673 read=13095
           I/O Timings: shared read=710.274
           ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=1.444..270.106 rows=1280.00 loops=3)
                 Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                 Rows Removed by Filter: 176540
                 Buffers: shared hit=8673 read=13095
                 I/O Timings: shared read=710.274
   ->  Hash Join  (cost=3587.99..106391.58 rows=139916 width=313) (actual time=331.121..841.647 rows=12910.00 loops=1)
         Hash Cond: ((o.encounter)::text = (e.id)::text)
         Buffers: shared hit=15889 read=67704
         I/O Timings: shared read=807.167
         ->  Seq Scan on observations o  (cost=0.00..89818.54 rows=2996254 width=81) (actual time=0.207..254.405 rows=2996970.00 loops=1)
               Buffers: shared hit=5247 read=54609
               I/O Timings: shared read=96.894
         ->  Hash  (cost=3539.85..3539.85 rows=3851 width=256) (actual time=329.508..329.512 rows=3960.00 loops=1)
               Buckets: 4096  Batches: 1  Memory Usage: 737kB
               Buffers: shared hit=10642 read=13095
               I/O Timings: shared read=710.274
               ->  Hash Join  (cost=787.53..3539.85 rows=3851 width=256) (actual time=308.610..328.357 rows=3960.00 loops=1)
                     Hash Cond: ((e.patient)::text = (p.id)::text)
                     Buffers: shared hit=10642 read=13095
                     I/O Timings: shared read=710.274
                     ->  Hash Right Join  (cost=107.06..2849.26 rows=3851 width=288) (actual time=303.543..322.113 rows=3960.00 loops=1)
                           Hash Cond: ((c.encounter)::text = (e.id)::text)
                           Buffers: shared hit=10225 read=13095
                           I/O Timings: shared read=710.274
                           ->  Seq Scan on conditions c  (cost=0.00..2389.60 rows=83760 width=71) (actual time=0.029..5.458 rows=83760.00 loops=1)
                                 Buffers: shared hit=1552
                           ->  Hash  (cost=65.88..65.88 rows=3294 width=254) (actual time=303.448..303.449 rows=3840.00 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 561kB
                                 Buffers: shared hit=8673 read=13095
                                 I/O Timings: shared read=710.274
                                 ->  CTE Scan on e  (cost=0.00..65.88 rows=3294 width=254) (actual time=1.498..301.725 rows=3840.00 loops=1)
                                       Storage: Memory  Maximum Storage: 543kB
                                       Buffers: shared hit=8673 read=13095
                                       I/O Timings: shared read=710.274
                     ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.999..5.000 rows=11710.00 loops=1)
                           Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                           Buffers: shared hit=417
                           ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.016..2.618 rows=11710.00 loops=1)
                                 Buffers: shared hit=417
 Planning:
   Buffers: shared hit=296
 Planning Time: 4.108 ms
 Execution Time: 879.219 ms
(54 rows)
```

### PG Rewrite 02b Run 2:
```text
SET
                                                                                                 QUERY PLAN                                                                                                 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=165903.55..166253.34 rows=139916 width=313) (actual time=754.451..755.224 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=15904 read=67695
   I/O Timings: shared read=429.818
   CTE e
     ->  Gather  (cost=1000.00..26987.21 rows=3294 width=100) (actual time=3.960..227.769 rows=3840.00 loops=1)
           Workers Planned: 2
           Workers Launched: 2
           Buffers: shared hit=8588 read=13180
           I/O Timings: shared read=357.640
           ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=3.558..150.524 rows=1280.00 loops=3)
                 Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                 Rows Removed by Filter: 176540
                 Buffers: shared hit=8588 read=13180
                 I/O Timings: shared read=357.640
   ->  Hash Join  (cost=3587.99..106391.58 rows=139916 width=313) (actual time=254.784..722.892 rows=12910.00 loops=1)
         Hash Cond: ((o.encounter)::text = (e.id)::text)
         Buffers: shared hit=15898 read=67695
         I/O Timings: shared read=429.818
         ->  Seq Scan on observations o  (cost=0.00..89818.54 rows=2996254 width=81) (actual time=0.283..222.290 rows=2996970.00 loops=1)
               Buffers: shared hit=5341 read=54515
               I/O Timings: shared read=72.177
         ->  Hash  (cost=3539.85..3539.85 rows=3851 width=256) (actual time=252.859..252.863 rows=3960.00 loops=1)
               Buckets: 4096  Batches: 1  Memory Usage: 737kB
               Buffers: shared hit=10557 read=13180
               I/O Timings: shared read=357.640
               ->  Hash Join  (cost=787.53..3539.85 rows=3851 width=256) (actual time=235.788..251.775 rows=3960.00 loops=1)
                     Hash Cond: ((e.patient)::text = (p.id)::text)
                     Buffers: shared hit=10557 read=13180
                     I/O Timings: shared read=357.640
                     ->  Hash Right Join  (cost=107.06..2849.26 rows=3851 width=288) (actual time=231.369..246.124 rows=3960.00 loops=1)
                           Hash Cond: ((c.encounter)::text = (e.id)::text)
                           Buffers: shared hit=10140 read=13180
                           I/O Timings: shared read=357.640
                           ->  Seq Scan on conditions c  (cost=0.00..2389.60 rows=83760 width=71) (actual time=0.023..4.615 rows=83760.00 loops=1)
                                 Buffers: shared hit=1552
                           ->  Hash  (cost=65.88..65.88 rows=3294 width=254) (actual time=231.286..231.287 rows=3840.00 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 561kB
                                 Buffers: shared hit=8588 read=13180
                                 I/O Timings: shared read=357.640
                                 ->  CTE Scan on e  (cost=0.00..65.88 rows=3294 width=254) (actual time=3.966..229.744 rows=3840.00 loops=1)
                                       Storage: Memory  Maximum Storage: 543kB
                                       Buffers: shared hit=8588 read=13180
                                       I/O Timings: shared read=357.640
                     ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.368..4.369 rows=11710.00 loops=1)
                           Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                           Buffers: shared hit=417
                           ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.009..2.265 rows=11710.00 loops=1)
                                 Buffers: shared hit=417
 Planning:
   Buffers: shared hit=296
 Planning Time: 6.692 ms
 Execution Time: 756.109 ms
(54 rows)
```

### PG Rewrite 02b Run 3:
```text
SET
                                                                                                 QUERY PLAN                                                                                                 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=165903.55..166253.34 rows=139916 width=313) (actual time=1213.006..1213.821 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=15992 read=67607
   I/O Timings: shared read=575.886
   CTE e
     ->  Gather  (cost=1000.00..26987.21 rows=3294 width=100) (actual time=2.396..172.452 rows=3840.00 loops=1)
           Workers Planned: 2
           Workers Launched: 2
           Buffers: shared hit=8588 read=13180
           I/O Timings: shared read=116.371
           ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=1.487..77.608 rows=1280.00 loops=3)
                 Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                 Rows Removed by Filter: 176540
                 Buffers: shared hit=8588 read=13180
                 I/O Timings: shared read=116.371
   ->  Hash Join  (cost=3587.99..106391.58 rows=139916 width=313) (actual time=202.143..1178.530 rows=12910.00 loops=1)
         Hash Cond: ((o.encounter)::text = (e.id)::text)
         Buffers: shared hit=15986 read=67607
         I/O Timings: shared read=575.886
         ->  Seq Scan on observations o  (cost=0.00..89818.54 rows=2996254 width=81) (actual time=0.616..656.349 rows=2996970.00 loops=1)
               Buffers: shared hit=5429 read=54427
               I/O Timings: shared read=459.515
         ->  Hash  (cost=3539.85..3539.85 rows=3851 width=256) (actual time=199.445..199.448 rows=3960.00 loops=1)
               Buckets: 4096  Batches: 1  Memory Usage: 737kB
               Buffers: shared hit=10557 read=13180
               I/O Timings: shared read=116.371
               ->  Hash Join  (cost=787.53..3539.85 rows=3851 width=256) (actual time=181.285..198.366 rows=3960.00 loops=1)
                     Hash Cond: ((e.patient)::text = (p.id)::text)
                     Buffers: shared hit=10557 read=13180
                     I/O Timings: shared read=116.371
                     ->  Hash Right Join  (cost=107.06..2849.26 rows=3851 width=288) (actual time=177.283..193.214 rows=3960.00 loops=1)
                           Hash Cond: ((c.encounter)::text = (e.id)::text)
                           Buffers: shared hit=10140 read=13180
                           I/O Timings: shared read=116.371
                           ->  Seq Scan on conditions c  (cost=0.00..2389.60 rows=83760 width=71) (actual time=0.018..5.004 rows=83760.00 loops=1)
                                 Buffers: shared hit=1552
                           ->  Hash  (cost=65.88..65.88 rows=3294 width=254) (actual time=177.175..177.175 rows=3840.00 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 561kB
                                 Buffers: shared hit=8588 read=13180
                                 I/O Timings: shared read=116.371
                                 ->  CTE Scan on e  (cost=0.00..65.88 rows=3294 width=254) (actual time=2.401..175.117 rows=3840.00 loops=1)
                                       Storage: Memory  Maximum Storage: 543kB
                                       Buffers: shared hit=8588 read=13180
                                       I/O Timings: shared read=116.371
                     ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=3.947..3.947 rows=11710.00 loops=1)
                           Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                           Buffers: shared hit=417
                           ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.011..2.093 rows=11710.00 loops=1)
                                 Buffers: shared hit=417
 Planning:
   Buffers: shared hit=296
 Planning Time: 3.939 ms
 Execution Time: 1214.688 ms
(54 rows)
```

### PG Rewrite 02b Run 4:
```text
SET
                                                                                                 QUERY PLAN                                                                                                 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=165903.55..166253.34 rows=139916 width=313) (actual time=679.614..680.856 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=15887 read=67712
   I/O Timings: shared read=283.267
   CTE e
     ->  Gather  (cost=1000.00..26987.21 rows=3294 width=100) (actual time=1.140..148.437 rows=3840.00 loops=1)
           Workers Planned: 2
           Workers Launched: 2
           Buffers: shared hit=8401 read=13367
           I/O Timings: shared read=215.221
           ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=2.752..101.400 rows=1280.00 loops=3)
                 Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                 Rows Removed by Filter: 176540
                 Buffers: shared hit=8401 read=13367
                 I/O Timings: shared read=215.221
   ->  Hash Join  (cost=3587.99..106391.58 rows=139916 width=313) (actual time=178.605..639.566 rows=12910.00 loops=1)
         Hash Cond: ((o.encounter)::text = (e.id)::text)
         Buffers: shared hit=15881 read=67712
         I/O Timings: shared read=283.267
         ->  Seq Scan on observations o  (cost=0.00..89818.54 rows=2996254 width=81) (actual time=0.215..214.930 rows=2996970.00 loops=1)
               Buffers: shared hit=5511 read=54345
               I/O Timings: shared read=68.046
         ->  Hash  (cost=3539.85..3539.85 rows=3851 width=256) (actual time=176.726..176.729 rows=3960.00 loops=1)
               Buckets: 4096  Batches: 1  Memory Usage: 737kB
               Buffers: shared hit=10370 read=13367
               I/O Timings: shared read=215.221
               ->  Hash Join  (cost=787.53..3539.85 rows=3851 width=256) (actual time=157.499..175.286 rows=3960.00 loops=1)
                     Hash Cond: ((e.patient)::text = (p.id)::text)
                     Buffers: shared hit=10370 read=13367
                     I/O Timings: shared read=215.221
                     ->  Hash Right Join  (cost=107.06..2849.26 rows=3851 width=288) (actual time=151.855..168.255 rows=3960.00 loops=1)
                           Hash Cond: ((c.encounter)::text = (e.id)::text)
                           Buffers: shared hit=9953 read=13367
                           I/O Timings: shared read=215.221
                           ->  Seq Scan on conditions c  (cost=0.00..2389.60 rows=83760 width=71) (actual time=0.024..4.991 rows=83760.00 loops=1)
                                 Buffers: shared hit=1552
                           ->  Hash  (cost=65.88..65.88 rows=3294 width=254) (actual time=151.766..151.767 rows=3840.00 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 561kB
                                 Buffers: shared hit=8401 read=13367
                                 I/O Timings: shared read=215.221
                                 ->  CTE Scan on e  (cost=0.00..65.88 rows=3294 width=254) (actual time=1.144..150.260 rows=3840.00 loops=1)
                                       Storage: Memory  Maximum Storage: 543kB
                                       Buffers: shared hit=8401 read=13367
                                       I/O Timings: shared read=215.221
                     ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=5.588..5.588 rows=11710.00 loops=1)
                           Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                           Buffers: shared hit=417
                           ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.011..2.870 rows=11710.00 loops=1)
                                 Buffers: shared hit=417
 Planning:
   Buffers: shared hit=296
 Planning Time: 4.346 ms
 Execution Time: 681.895 ms
(54 rows)
```

### PG Rewrite 02b Run 5:
```text
SET
                                                                                                 QUERY PLAN                                                                                                 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=165903.55..166253.34 rows=139916 width=313) (actual time=805.270..806.047 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=15899 read=67700
   I/O Timings: shared read=331.483
   CTE e
     ->  Gather  (cost=1000.00..26987.21 rows=3294 width=100) (actual time=3.647..126.915 rows=3840.00 loops=1)
           Workers Planned: 2
           Workers Launched: 2
           Buffers: shared hit=8319 read=13449
           I/O Timings: shared read=180.745
           ->  Parallel Seq Scan on encounters  (cost=0.00..25657.81 rows=1372 width=100) (actual time=1.994..87.983 rows=1280.00 loops=3)
                 Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                 Rows Removed by Filter: 176540
                 Buffers: shared hit=8319 read=13449
                 I/O Timings: shared read=180.745
   ->  Hash Join  (cost=3587.99..106391.58 rows=139916 width=313) (actual time=156.180..769.736 rows=12910.00 loops=1)
         Hash Cond: ((o.encounter)::text = (e.id)::text)
         Buffers: shared hit=15893 read=67700
         I/O Timings: shared read=331.483
         ->  Seq Scan on observations o  (cost=0.00..89818.54 rows=2996254 width=81) (actual time=0.215..328.245 rows=2996970.00 loops=1)
               Buffers: shared hit=5605 read=54251
               I/O Timings: shared read=150.739
         ->  Hash  (cost=3539.85..3539.85 rows=3851 width=256) (actual time=154.418..154.421 rows=3960.00 loops=1)
               Buckets: 4096  Batches: 1  Memory Usage: 737kB
               Buffers: shared hit=10288 read=13449
               I/O Timings: shared read=180.745
               ->  Hash Join  (cost=787.53..3539.85 rows=3851 width=256) (actual time=136.151..153.410 rows=3960.00 loops=1)
                     Hash Cond: ((e.patient)::text = (p.id)::text)
                     Buffers: shared hit=10288 read=13449
                     I/O Timings: shared read=180.745
                     ->  Hash Right Join  (cost=107.06..2849.26 rows=3851 width=288) (actual time=130.306..146.469 rows=3960.00 loops=1)
                           Hash Cond: ((c.encounter)::text = (e.id)::text)
                           Buffers: shared hit=9871 read=13449
                           I/O Timings: shared read=180.745
                           ->  Seq Scan on conditions c  (cost=0.00..2389.60 rows=83760 width=71) (actual time=0.024..5.820 rows=83760.00 loops=1)
                                 Buffers: shared hit=1552
                           ->  Hash  (cost=65.88..65.88 rows=3294 width=254) (actual time=130.224..130.225 rows=3840.00 loops=1)
                                 Buckets: 4096  Batches: 1  Memory Usage: 561kB
                                 Buffers: shared hit=8319 read=13449
                                 I/O Timings: shared read=180.745
                                 ->  CTE Scan on e  (cost=0.00..65.88 rows=3294 width=254) (actual time=3.651..128.760 rows=3840.00 loops=1)
                                       Storage: Memory  Maximum Storage: 543kB
                                       Buffers: shared hit=8319 read=13449
                                       I/O Timings: shared read=180.745
                     ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=5.786..5.787 rows=11710.00 loops=1)
                           Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                           Buffers: shared hit=417
                           ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.012..3.013 rows=11710.00 loops=1)
                                 Buffers: shared hit=417
 Planning:
   Buffers: shared hit=296
 Planning Time: 3.916 ms
 Execution Time: 806.930 ms
(54 rows)
```

## 4. Q1_02_rewrite_mysql.sql (Full file + 5 lần 02a & 5 lần 02b)

### Full File Execution (`mysql < Q1_02_rewrite_mysql.sql`):
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=62664..62675 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=812..62583 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=812..62531 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=38.7..61246 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=38.3..60860 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=3.54..13767 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=3.54..12708 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.0171..0.0171 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0157..0.0157 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.923 rows=1) (actual time=0.0292..0.0293 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83067) (actual time=0.473..260 rows=83760 loops=1)

EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=37563..37574 rows=12910 loops=1)
    -> Stream results  (cost=356e+9 rows=3.55e+12) (actual time=3787..37467 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=356e+9 rows=3.55e+12) (actual time=3786..37408 rows=12910 loops=1)
            -> Nested loop inner join  (cost=59.1e+6 rows=42.8e+6) (actual time=2856..35960 rows=12910 loops=1)
                -> Nested loop inner join  (cost=15.3e+6 rows=42.8e+6) (actual time=2855..35412 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=2.27..15561 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=2.27..14384 rows=3e+6 loops=1)
                    -> Filter: (e.patient is not null)  (cost=3.75 rows=15) (actual time=0.00691..0.00692 rows=0.00479 loops=2.69e+6)
                        -> Index lookup on e using <auto_key2> (id = o.encounter)  (cost=57518..57521 rows=15) (actual time=0.00652..0.00653 rows=0.00479 loops=2.69e+6)
                            -> Materialize  (cost=57517..57517 rows=5671) (actual time=2806..2806 rows=3840 loops=1)
                                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=56211 rows=5671) (actual time=1.6..2723 rows=3840 loops=1)
                                    -> Table scan on encounters  (cost=56211 rows=510483) (actual time=0.678..2442 rows=533460 loops=1)
                -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.923 rows=1) (actual time=0.0418..0.0419 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.16 rows=83067) (actual time=1.08..354 rows=83760 loops=1)
```

### MySQL Rewrite 02a Run 1:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=62308..62317 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=783..62222 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=783..62167 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.52e+6 rows=142490) (actual time=116..60964 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.43e+6 rows=142490) (actual time=116..60622 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=1.39..13428 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.38..12345 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.641 rows=0.05) (actual time=0.0172..0.0172 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.641 rows=1) (actual time=0.0157..0.0158 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.528 rows=1) (actual time=0.0258..0.0259 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83067) (actual time=0.963..277 rows=83760 loops=1)
```

### MySQL Rewrite 02a Run 2:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=64333..64342 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=921..64250 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=921..64193 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=106..62864 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=106..62476 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=8.69..13973 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=8.69..12827 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.0176..0.0176 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0161..0.0162 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.923 rows=1) (actual time=0.0293..0.0294 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83067) (actual time=1.43..340 rows=83760 loops=1)
```

### MySQL Rewrite 02a Run 3:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=63142..63152 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=176..63052 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=176..62992 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=35.9..62268 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=35.6..61881 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=0.933..13462 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=0.932..12404 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.0176..0.0176 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0161..0.0162 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.923 rows=1) (actual time=0.0293..0.0294 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83067) (actual time=1.03..63.1 rows=83760 loops=1)
```

### MySQL Rewrite 02a Run 4:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=62012..62020 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=837..61911 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=837..61851 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=89..60527 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=88.4..60143 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=1.46..13248 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.46..12206 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.0171..0.0171 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0156..0.0157 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.923 rows=1) (actual time=0.029..0.0291 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83067) (actual time=1.03..308 rows=83760 loops=1)
```

### MySQL Rewrite 02a Run 5:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=68409..68420 rows=12910 loops=1)
    -> Stream results  (cost=1.18e+9 rows=11.8e+9) (actual time=925..68323 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=1.18e+9 rows=11.8e+9) (actual time=925..68263 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.11e+6 rows=142490) (actual time=125..66787 rows=12910 loops=1)
                -> Nested loop inner join  (cost=1.97e+6 rows=142490) (actual time=124..66282 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=29.7..13794 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=29.6..12693 rows=3e+6 loops=1)
                    -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00') and (encounters.patient is not null))  (cost=0.48 rows=0.05) (actual time=0.0191..0.0191 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on encounters using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0176..0.0177 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.923 rows=1) (actual time=0.0384..0.0385 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.22 rows=83067) (actual time=1.28..371 rows=83760 loops=1)
```

### MySQL Rewrite 02b Run 1:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=35108..35119 rows=12910 loops=1)
    -> Stream results  (cost=356e+9 rows=3.55e+12) (actual time=3611..35021 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=356e+9 rows=3.55e+12) (actual time=3611..34968 rows=12910 loops=1)
            -> Nested loop inner join  (cost=59.1e+6 rows=42.8e+6) (actual time=2834..33689 rows=12910 loops=1)
                -> Nested loop inner join  (cost=15.3e+6 rows=42.8e+6) (actual time=2831..33386 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=1.92..14204 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.91..13121 rows=3e+6 loops=1)
                    -> Filter: (e.patient is not null)  (cost=3.75 rows=15) (actual time=0.00668..0.00668 rows=0.00479 loops=2.69e+6)
                        -> Index lookup on e using <auto_key2> (id = o.encounter)  (cost=57518..57521 rows=15) (actual time=0.00629..0.00629 rows=0.00479 loops=2.69e+6)
                            -> Materialize  (cost=57517..57517 rows=5671) (actual time=2778..2778 rows=3840 loops=1)
                                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=56211 rows=5671) (actual time=1.16..2704 rows=3840 loops=1)
                                    -> Table scan on encounters  (cost=56211 rows=510483) (actual time=0.18..2431 rows=533460 loops=1)
                -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.923 rows=1) (actual time=0.0228..0.0229 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.16 rows=83067) (actual time=3.79..341 rows=83760 loops=1)
```

### MySQL Rewrite 02b Run 2:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=34714..34724 rows=12910 loops=1)
    -> Stream results  (cost=356e+9 rows=3.55e+12) (actual time=3667..34630 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=356e+9 rows=3.55e+12) (actual time=3667..34575 rows=12910 loops=1)
            -> Nested loop inner join  (cost=42.3e+6 rows=42.8e+6) (actual time=2912..33317 rows=12910 loops=1)
                -> Nested loop inner join  (cost=15.3e+6 rows=42.8e+6) (actual time=2912..33089 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=0.826..14095 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=0.825..13015 rows=3e+6 loops=1)
                    -> Filter: (e.patient is not null)  (cost=3.75 rows=15) (actual time=0.00661..0.00662 rows=0.00479 loops=2.69e+6)
                        -> Index lookup on e using <auto_key2> (id = o.encounter)  (cost=59244..59248 rows=15) (actual time=0.00624..0.00625 rows=0.00479 loops=2.69e+6)
                            -> Materialize  (cost=59244..59244 rows=5671) (actual time=2875..2875 rows=3840 loops=1)
                                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=57938 rows=5671) (actual time=0.956..2802 rows=3840 loops=1)
                                    -> Table scan on encounters  (cost=57938 rows=510483) (actual time=0.693..2521 rows=533460 loops=1)
                -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.532 rows=1) (actual time=0.0167..0.0167 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.16 rows=83067) (actual time=2.08..309 rows=83760 loops=1)
```

### MySQL Rewrite 02b Run 3:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=34487..34497 rows=12910 loops=1)
    -> Stream results  (cost=356e+9 rows=3.55e+12) (actual time=3515..34400 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=356e+9 rows=3.55e+12) (actual time=3515..34348 rows=12910 loops=1)
            -> Nested loop inner join  (cost=42.5e+6 rows=42.8e+6) (actual time=2809..33156 rows=12910 loops=1)
                -> Nested loop inner join  (cost=15.3e+6 rows=42.8e+6) (actual time=2809..32932 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=1.56..14011 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.56..12926 rows=3e+6 loops=1)
                    -> Filter: (e.patient is not null)  (cost=3.75 rows=15) (actual time=0.0066..0.00661 rows=0.00479 loops=2.69e+6)
                        -> Index lookup on e using <auto_key2> (id = o.encounter)  (cost=59249..59253 rows=15) (actual time=0.00624..0.00624 rows=0.00479 loops=2.69e+6)
                            -> Materialize  (cost=59249..59249 rows=5671) (actual time=2762..2762 rows=3840 loops=1)
                                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=57942 rows=5671) (actual time=2.56..2691 rows=3840 loops=1)
                                    -> Table scan on encounters  (cost=57942 rows=510483) (actual time=1.63..2432 rows=533460 loops=1)
                -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.535 rows=1) (actual time=0.0166..0.0167 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.16 rows=83067) (actual time=1.13..290 rows=83760 loops=1)
```

### MySQL Rewrite 02b Run 4:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=34829..34838 rows=12910 loops=1)
    -> Stream results  (cost=356e+9 rows=3.55e+12) (actual time=3746..34741 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=356e+9 rows=3.55e+12) (actual time=3746..34688 rows=12910 loops=1)
            -> Nested loop inner join  (cost=42e+6 rows=42.8e+6) (actual time=3030..33468 rows=12910 loops=1)
                -> Nested loop inner join  (cost=15.3e+6 rows=42.8e+6) (actual time=3030..33258 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=1.2..14137 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.2..13068 rows=3e+6 loops=1)
                    -> Filter: (e.patient is not null)  (cost=3.75 rows=15) (actual time=0.00665..0.00666 rows=0.00479 loops=2.69e+6)
                        -> Index lookup on e using <auto_key2> (id = o.encounter)  (cost=59252..59256 rows=15) (actual time=0.00627..0.00628 rows=0.00479 loops=2.69e+6)
                            -> Materialize  (cost=59252..59252 rows=5671) (actual time=2973..2973 rows=3840 loops=1)
                                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=57945 rows=5671) (actual time=1.97..2898 rows=3840 loops=1)
                                    -> Table scan on encounters  (cost=57945 rows=510483) (actual time=1.29..2618 rows=533460 loops=1)
                -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.524 rows=1) (actual time=0.0155..0.0157 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.16 rows=83067) (actual time=1.05..294 rows=83760 loops=1)
```

### MySQL Rewrite 02b Run 5:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=35200..35210 rows=12910 loops=1)
    -> Stream results  (cost=356e+9 rows=3.55e+12) (actual time=3766..35116 rows=12910 loops=1)
        -> Left hash join (c.encounter = o.encounter)  (cost=356e+9 rows=3.55e+12) (actual time=3766..35065 rows=12910 loops=1)
            -> Nested loop inner join  (cost=42e+6 rows=42.8e+6) (actual time=2954..33773 rows=12910 loops=1)
                -> Nested loop inner join  (cost=15.3e+6 rows=42.8e+6) (actual time=2954..33573 rows=12910 loops=1)
                    -> Filter: (o.encounter is not null)  (cost=315381 rows=2.85e+6) (actual time=1.5..14228 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=315381 rows=2.85e+6) (actual time=1.5..13127 rows=3e+6 loops=1)
                    -> Filter: (e.patient is not null)  (cost=3.75 rows=15) (actual time=0.00674..0.00675 rows=0.00479 loops=2.69e+6)
                        -> Index lookup on e using <auto_key2> (id = o.encounter)  (cost=59253..59256 rows=15) (actual time=0.00636..0.00636 rows=0.00479 loops=2.69e+6)
                            -> Materialize  (cost=59253..59253 rows=5671) (actual time=2905..2905 rows=3840 loops=1)
                                -> Filter: ((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=57946 rows=5671) (actual time=2.14..2834 rows=3840 loops=1)
                                    -> Table scan on encounters  (cost=57946 rows=510483) (actual time=1.44..2554 rows=533460 loops=1)
                -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.524 rows=1) (actual time=0.0149..0.0149 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.16 rows=83067) (actual time=1.82..298 rows=83760 loops=1)
```

## 5. Q1_03_indexes_pg.sql (Full file + 5 lần EXPLAIN khi có index)

### Full File Execution (`psql -f Q1_03_indexes_pg.sql` - gồm tạo & xóa):
```text
Timing is on.
SET
Time: 0,196 ms
CREATE INDEX
Time: 1502,398 ms (00:01,502)
CREATE INDEX
Time: 17068,692 ms (00:17,069)
CREATE INDEX
Time: 1460,485 ms (00:01,460)
       index_name        |  size   
-------------------------+---------
 idx_q1_enc_class_start  | 67 MB
 idx_q1_obs_enc_patient  | 40 MB
 idx_q1_cond_enc_patient | 7936 kB
(3 rows)

Time: 12,361 ms
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=24411.29..24411.29 rows=2 width=212) (actual time=431.665..434.590 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=88394 read=5439
   I/O Timings: shared read=165.522
   ->  Gather  (cost=1255.68..24411.28 rows=2 width=212) (actual time=2.289..293.195 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=88394 read=5439
         I/O Timings: shared read=165.522
         ->  Nested Loop Left Join  (cost=255.68..23411.08 rows=1 width=212) (actual time=4.398..254.687 rows=6455.00 loops=2)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=88394 read=5439
               I/O Timings: shared read=165.522
               ->  Nested Loop  (cost=255.26..23407.54 rows=1 width=165) (actual time=3.910..176.771 rows=6455.00 loops=2)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=49281 read=4718
                     I/O Timings: shared read=145.914
                     ->  Nested Loop  (cost=254.98..23406.27 rows=4 width=181) (actual time=2.976..101.741 rows=6455.00 loops=2)
                           Buffers: shared hit=10632 read=4636
                           I/O Timings: shared read=106.700
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=254.55..9093.53 rows=1938 width=100) (actual time=1.540..25.562 rows=1920.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=626
                                 Buffers: shared hit=221 read=1937
                                 I/O Timings: shared read=30.678
                                 Worker 0:  Heap Blocks: exact=1447
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..253.73 rows=3294 width=0) (actual time=0.858..0.859 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared read=65
                                       I/O Timings: shared read=0.415
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.38 rows=1 width=118) (actual time=0.036..0.037 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=10411 read=2699
                                 I/O Timings: shared read=76.021
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.010..0.010 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38649 read=82
                           I/O Timings: shared read=39.215
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.52 rows=1 width=108) (actual time=0.011..0.011 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39110 read=721
                     I/O Timings: shared read=19.607
 Planning:
   Buffers: shared hit=308 read=22
   I/O Timings: shared read=1.231
 Planning Time: 6.841 ms
 Execution Time: 436.608 ms
(52 rows)

Time: 445,702 ms
DROP INDEX
Time: 43,529 ms
DROP INDEX
Time: 30,518 ms
DROP INDEX
Time: 9,216 ms
RESET
Time: 0,344 ms
```

### PG Index Run 1:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=24411.29..24411.29 rows=2 width=212) (actual time=133.338..134.187 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93839
   ->  Gather  (cost=1255.68..24411.28 rows=2 width=212) (actual time=1.464..99.491 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=93833
         ->  Nested Loop Left Join  (cost=255.68..23411.08 rows=1 width=212) (actual time=0.994..75.785 rows=6455.00 loops=2)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93833
               ->  Nested Loop  (cost=255.26..23407.54 rows=1 width=165) (actual time=0.958..45.258 rows=6455.00 loops=2)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=53999
                     ->  Nested Loop  (cost=254.98..23406.27 rows=4 width=181) (actual time=0.929..21.590 rows=6455.00 loops=2)
                           Buffers: shared hit=15268
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=254.55..9093.53 rows=1938 width=100) (actual time=0.835..3.302 rows=1920.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1277
                                 Buffers: shared hit=2158
                                 Worker 0:  Heap Blocks: exact=796
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..253.73 rows=3294 width=0) (actual time=0.606..0.606 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.38 rows=1 width=118) (actual time=0.008..0.009 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13110
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.003..0.003 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38731
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.52 rows=1 width=108) (actual time=0.004..0.004 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39831
 Planning:
   Buffers: shared hit=420
 Planning Time: 6.431 ms
 Execution Time: 134.815 ms
(41 rows)
```

### PG Index Run 2:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=24411.29..24411.29 rows=2 width=212) (actual time=158.457..159.517 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93839
   ->  Gather  (cost=1255.68..24411.28 rows=2 width=212) (actual time=1.313..121.903 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=93833
         ->  Nested Loop Left Join  (cost=255.68..23411.08 rows=1 width=212) (actual time=1.310..91.802 rows=6455.00 loops=2)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93833
               ->  Nested Loop  (cost=255.26..23407.54 rows=1 width=165) (actual time=1.277..54.808 rows=6455.00 loops=2)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=53999
                     ->  Nested Loop  (cost=254.98..23406.27 rows=4 width=181) (actual time=1.255..25.932 rows=6455.00 loops=2)
                           Buffers: shared hit=15268
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=254.55..9093.53 rows=1938 width=100) (actual time=1.192..4.012 rows=1920.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1364
                                 Buffers: shared hit=2158
                                 Worker 0:  Heap Blocks: exact=709
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..253.73 rows=3294 width=0) (actual time=0.566..0.566 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.38 rows=1 width=118) (actual time=0.010..0.010 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13110
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38731
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.52 rows=1 width=108) (actual time=0.005..0.005 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39831
 Planning:
   Buffers: shared hit=420
 Planning Time: 8.818 ms
 Execution Time: 160.263 ms
(41 rows)
```

### PG Index Run 3:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=24411.29..24411.29 rows=2 width=212) (actual time=165.374..166.285 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93839
   ->  Gather  (cost=1255.68..24411.28 rows=2 width=212) (actual time=2.235..130.488 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=93833
         ->  Nested Loop Left Join  (cost=255.68..23411.08 rows=1 width=212) (actual time=1.464..92.433 rows=6455.00 loops=2)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93833
               ->  Nested Loop  (cost=255.26..23407.54 rows=1 width=165) (actual time=1.417..55.331 rows=6455.00 loops=2)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=53999
                     ->  Nested Loop  (cost=254.98..23406.27 rows=4 width=181) (actual time=1.383..26.102 rows=6455.00 loops=2)
                           Buffers: shared hit=15268
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=254.55..9093.53 rows=1938 width=100) (actual time=1.264..4.228 rows=1920.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1339
                                 Buffers: shared hit=2158
                                 Worker 0:  Heap Blocks: exact=734
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..253.73 rows=3294 width=0) (actual time=0.985..0.985 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.38 rows=1 width=118) (actual time=0.010..0.010 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13110
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38731
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.52 rows=1 width=108) (actual time=0.005..0.005 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39831
 Planning:
   Buffers: shared hit=420
 Planning Time: 9.250 ms
 Execution Time: 166.904 ms
(41 rows)
```

### PG Index Run 4:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=24411.29..24411.29 rows=2 width=212) (actual time=132.134..133.035 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93839
   ->  Gather  (cost=1255.68..24411.28 rows=2 width=212) (actual time=2.203..98.554 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=93833
         ->  Nested Loop Left Join  (cost=255.68..23411.08 rows=1 width=212) (actual time=1.155..75.899 rows=6455.00 loops=2)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93833
               ->  Nested Loop  (cost=255.26..23407.54 rows=1 width=165) (actual time=1.124..45.681 rows=6455.00 loops=2)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=53999
                     ->  Nested Loop  (cost=254.98..23406.27 rows=4 width=181) (actual time=1.102..21.875 rows=6455.00 loops=2)
                           Buffers: shared hit=15268
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=254.55..9093.53 rows=1938 width=100) (actual time=1.011..3.594 rows=1920.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=1215
                                 Buffers: shared hit=2158
                                 Worker 0:  Heap Blocks: exact=858
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..253.73 rows=3294 width=0) (actual time=1.000..1.000 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.38 rows=1 width=118) (actual time=0.008..0.009 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13110
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.003..0.003 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38731
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.52 rows=1 width=108) (actual time=0.004..0.004 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39831
 Planning:
   Buffers: shared hit=420
 Planning Time: 7.013 ms
 Execution Time: 133.647 ms
(41 rows)
```

### PG Index Run 5:
```text
SET
                                                                                                              QUERY PLAN                                                                                                              
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=24411.29..24411.29 rows=2 width=212) (actual time=211.215..212.078 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=93839
   ->  Gather  (cost=1255.68..24411.28 rows=2 width=212) (actual time=3.111..170.253 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=93833
         ->  Nested Loop Left Join  (cost=255.68..23411.08 rows=1 width=212) (actual time=1.721..86.397 rows=6455.00 loops=2)
               Join Filter: ((c.patient)::text = (p.id)::text)
               Buffers: shared hit=93833
               ->  Nested Loop  (cost=255.26..23407.54 rows=1 width=165) (actual time=1.688..51.493 rows=6455.00 loops=2)
                     Join Filter: ((p.id)::text = (e.patient)::text)
                     Buffers: shared hit=53999
                     ->  Nested Loop  (cost=254.98..23406.27 rows=4 width=181) (actual time=1.664..24.937 rows=6455.00 loops=2)
                           Buffers: shared hit=15268
                           ->  Parallel Bitmap Heap Scan on encounters e  (cost=254.55..9093.53 rows=1938 width=100) (actual time=1.581..4.453 rows=1920.00 loops=2)
                                 Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=2019
                                 Buffers: shared hit=2158
                                 Worker 0:  Heap Blocks: exact=54
                                 ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..253.73 rows=3294 width=0) (actual time=1.708..1.708 rows=3840.00 loops=1)
                                       Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                       Index Searches: 1
                                       Buffers: shared hit=65
                           ->  Index Scan using idx_q1_obs_enc_patient on observations o  (cost=0.43..7.38 rows=1 width=118) (actual time=0.009..0.010 rows=3.36 loops=3840)
                                 Index Cond: (((encounter)::text = (e.id)::text) AND ((patient)::text = (e.patient)::text))
                                 Index Searches: 3840
                                 Buffers: shared hit=13110
                     ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                           Index Cond: ((id)::text = (o.patient)::text)
                           Index Searches: 12910
                           Buffers: shared hit=38731
               ->  Index Scan using idx_q1_cond_enc_patient on conditions c  (cost=0.42..3.52 rows=1 width=108) (actual time=0.005..0.005 rows=0.09 loops=12910)
                     Index Cond: ((encounter)::text = (e.id)::text)
                     Index Searches: 12910
                     Buffers: shared hit=39831
 Planning:
   Buffers: shared hit=420
 Planning Time: 7.586 ms
 Execution Time: 212.677 ms
(41 rows)
```

## 6. Q1_03_indexes_mysql.sql (Full file + 5 lần EXPLAIN khi có index)

### Full File Execution (`mysql < Q1_03_indexes_mysql.sql` - gồm tạo & xóa):
```text
TABLE_NAME	INDEX_NAME	size_kb
conditions	idx_q1_cond_enc_patient	8768
encounters	idx_q1_enc_class_start	58192
observations	idx_q1_obs_enc_patient	283632
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=4141..4149 rows=12910 loops=1)
    -> Stream results  (cost=144753 rows=113879) (actual time=24.4..4052 rows=12910 loops=1)
        -> Nested loop inner join  (cost=144753 rows=113879) (actual time=24.3..3962 rows=12910 loops=1)
            -> Nested loop left join  (cost=19485 rows=7934) (actual time=23.2..2368 rows=3960 loops=1)
                -> Nested loop inner join  (cost=16709 rows=7276) (actual time=23.1..2059 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=8732 rows=7276) (actual time=22.5..1870 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.996 rows=1) (actual time=0.0479..0.0481 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.273 rows=1.09) (actual time=0.0767..0.0791 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=14.4 rows=14.4) (actual time=0.344..0.4 rows=3.26 loops=3960)
```

### MySQL Index Run 1:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3525..3533 rows=12910 loops=1)
    -> Stream results  (cost=130165 rows=106230) (actual time=21.7..3427 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130165 rows=106230) (actual time=21.6..3335 rows=12910 loops=1)
            -> Nested loop left join  (cost=13313 rows=7915) (actual time=21..1906 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10542 rows=7276) (actual time=21..1681 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7943 rows=7276) (actual time=20.9..1573 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.257 rows=1) (actual time=0.0268..0.0269 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.272 rows=1.09) (actual time=0.0552..0.0573 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.4 rows=13.4) (actual time=0.307..0.358 rows=3.26 loops=3960)
```

### MySQL Index Run 2:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3717..3730 rows=12910 loops=1)
    -> Stream results  (cost=130099 rows=106230) (actual time=23.4..3635 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130099 rows=106230) (actual time=23.3..3551 rows=12910 loops=1)
            -> Nested loop left join  (cost=13246 rows=7915) (actual time=22.3..1983 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10476 rows=7276) (actual time=22.2..1763 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7903 rows=7276) (actual time=22.1..1658 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.254 rows=1) (actual time=0.0261..0.0263 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.272 rows=1.09) (actual time=0.0532..0.0555 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.4 rows=13.4) (actual time=0.343..0.393 rows=3.26 loops=3960)
```

### MySQL Index Run 3:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3430..3442 rows=12910 loops=1)
    -> Stream results  (cost=130041 rows=106230) (actual time=28.8..3347 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130041 rows=106230) (actual time=28.8..3260 rows=12910 loops=1)
            -> Nested loop left join  (cost=13188 rows=7915) (actual time=28.1..1793 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10418 rows=7276) (actual time=28..1572 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7871 rows=7276) (actual time=28..1468 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.25 rows=1) (actual time=0.026..0.0262 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.272 rows=1.09) (actual time=0.054..0.0563 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.4 rows=13.4) (actual time=0.318..0.368 rows=3.26 loops=3960)
```

### MySQL Index Run 4:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3564..3569 rows=12910 loops=1)
    -> Stream results  (cost=130122 rows=106230) (actual time=27.4..3489 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130122 rows=106230) (actual time=27.4..3406 rows=12910 loops=1)
            -> Nested loop left join  (cost=13269 rows=7915) (actual time=26.5..1901 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10499 rows=7276) (actual time=26.5..1720 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7952 rows=7276) (actual time=26.4..1622 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.25 rows=1) (actual time=0.0242..0.0244 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.272 rows=1.09) (actual time=0.044..0.0462 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.4 rows=13.4) (actual time=0.331..0.378 rows=3.26 loops=3960)
```

### MySQL Index Run 5:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=3527..3536 rows=12910 loops=1)
    -> Stream results  (cost=130016 rows=106230) (actual time=29.5..3435 rows=12910 loops=1)
        -> Nested loop inner join  (cost=130016 rows=106230) (actual time=29.4..3357 rows=12910 loops=1)
            -> Nested loop left join  (cost=13163 rows=7915) (actual time=28.7..1997 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10393 rows=7276) (actual time=28.6..1819 rows=3840 loops=1)
                    -> Index range scan on e using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (e.patient is not null))  (cost=7847 rows=7276) (actual time=28.6..1730 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = e.patient)  (cost=0.25 rows=1) (actual time=0.0222..0.0223 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = e.id, patient = e.patient)  (cost=0.272 rows=1.09) (actual time=0.0431..0.045 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = e.id, patient = e.patient)  (cost=13.4 rows=13.4) (actual time=0.296..0.341 rows=3.26 loops=3960)
```

## 7. Q1_04_stats_pg.sql (Full file + 5 lần EXPLAIN sau khi SET STATISTICS 1000)

### Full File Execution (`psql -f Q1_04_stats_pg.sql` - gồm trước, sau & khôi phục):
```text
Timing is on.
SET
Time: 0,119 ms
 default_statistics_target 
---------------------------
 100
(1 row)

Time: 0,156 ms
  tablename   |    attname     | n_distinct  | null_frac  |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   most_common_vals                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        most_common_freqs                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
--------------+----------------+-------------+------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 conditions   | patient        | -0.12865329 |          0 | {922f8261-f71f-2edc-1ed5-ade58cadf98f,f7bb6e12-8390-1468-e2d3-d8847a175ab3,642e07f0-a75a-8593-2392-4c94b4accd71,85c35d0c-2106-5204-f03b-b50acf6a1f3e,ac7fd2bf-5f9d-1130-6ea3-16be40df0355,122b43b0-c826-d632-d6c2-6702596d4515,481de371-ef23-97d6-221f-0d70e1c977ac,5f14407c-c37d-f4e4-63dc-5e5c6f865ec6,60e3a5d3-48e8-8051-3fba-be03caa21e2c,63b43c14-a948-fe3f-7ef4-e8eacf3ee726,67a755f2-f0c3-2cd9-dd8d-1068ca1e4422,93a4ac35-d696-6c47-3ecd-034af162055d,95a6706b-fe7d-c74c-e542-2377671c9ba1,9b229bea-fddb-e71e-53e8-50fc90cbaccb,a949916f-c853-7aaf-3210-88287336a57a,b9839ed7-11a6-ae5c-2228-d76af9438b72,f9c745a9-f886-0c4c-cca4-75579d5b8977,0812f7cd-2106-6d61-0d0e-1273eb10a4b3,0c3529b9-ee69-ab12-7b97-4e9bdd3ffe92,0edce679-77b9-46ea-26f7-55ff588eeb6a,13a3a783-ecc5-4ec5-b3dc-168b15cebb88,3e6659a1-d04c-4ef0-f98b-d91f7357f658,427ee3fe-dde7-8e6f-1bc5-bb6371ceda2b,4d8ef0b9-aa04-80b4-6bc0-52c350ed9a21,55ea6459-af14-0487-52bc-b3a11effd538,591c81cc-a08b-2ef6-8829-06bb016552d5,637a78f8-a74a-9334-d688-ee792baa47c2,6663e87f-eb64-dfc6-81e0-f1e561274660,7db213c9-e4f4-dbab-d3bc-6e615bcff0ab,8ed57397-e427-4415-2f67-a4f5c13b1ea5,a563c02d-bdd1-c4c2-c6c6-26944cb94add,b1b10f6e-e97a-426a-9581-f1a5c29b6e05,b9b87952-4b36-0e00-15c2-a397d5be2d64,caf36c2f-5c59-6a6a-2968-5333e765f92b,cd867097-7f68-4f02-28b2-8c29bde19570,d34d619b-8f8e-efdd-1797-ab031b9066f1,d97bfdf8-d0bb-3989-2d54-f25951b66329,e5d557f7-b177-f6cb-df68-525a9cb7f049,e6edfd22-e775-5ad4-5316-b39c20487f1e,ef6b5b97-d1ea-3c3e-3ec1-e119d2dc36a2,fb805618-39b5-3d3a-644c-4c7e000a2a6a,06741430-2cff-1043-39f4-1878d168223c,0de81645-48d9-1633-da7d-d472d877d353,13bf40f2-fea7-7866-0131-308fd9fad8a6,1c0cea09-f0db-4ef0-a551-d67645ee4538,2d5cfe23-0a6f-df23-16a5-8d39a2fa8e1d,2dd14034-7c79-70b9-2e1e-a0b3ca03b4b7,32f699a4-8b74-2de0-9dd1-9590f509353b,36e1c387-4abe-6d4a-9f23-e7ff5461756b,3b46f9a9-3447-441d-abd4-4f8e46f9e0c2,4865ac64-c93b-dc94-d2a4-36c8a8f80880,4ac41356-2a6f-984c-6abb-3d1612417b1d,503de5a3-b2ec-e4b4-c76a-f0b8e9d75036,539fc8f6-8038-bdff-7273-2dd55676106c,53b37be8-f6b7-cde7-1b31-3a2e7848ab74,53ffc0e7-869c-f4ff-a592-9225fddf722e,5484323f-8fd4-36e1-9566-f34bf236ec22,5d85e710-7625-4485-8f38-08df25c73439,5ff33b4e-099f-0001-f3cf-d7bd7f9e20ae,61d865e3-5b26-088f-1d38-41a35a623f51,65243e61-da11-42a6-826e-a43d960d1e84,66a52ad5-b693-e80a-cfa4-e98422897dc1,66f251b6-6418-ffda-be3c-e48374f3050c,68a793f5-9c1a-fe21-df78-4aa6b7348575,68ee5e92-5775-7151-3786-dc67be16ab55,6a06be24-745e-b9e9-0ca3-59dd1067cada,6c7e2846-01a3-c952-523d-ec47c9093c71,6dafa93d-3698-4124-9bbd-7429cc2a7374,6ec18ddf-e9ee-421a-9033-456f558c7b4b,71acf44d-f321-c0f0-6907-d2c6d3dbea73,74845fbc-bb34-3049-6293-29d0a0ec71f0,77149f5a-f01f-8707-83f2-7f5fd4cc65d1,778ee4ee-a95c-f55c-65c2-6c139e182ad3,7b00dcfb-22f1-75fb-8704-5c8910250e17,817d7365-56fc-43f6-845e-ea9f5623d1aa,8f0650e1-c2b7-517a-e6f2-f91f547f2f56,8ffd3ff2-6f23-ec6b-5a2e-18fe716a7927,9332c1c0-0205-803a-be3e-973c4e5b592a,9394cb52-7d92-4577-976e-d017af06ed8f,992564c2-4d2c-53c2-7228-068fb916ba41,9aa7be5d-59c7-a1e5-3ec4-ea78961fb215,9c2fb5c7-6152-034f-7073-55f67b6673f7,9cb6faa8-86ee-c766-b1de-75f0a90147ba,a415d006-0a13-81c2-dd69-9c7bc4dc2e33,a65fcee6-b799-52aa-9771-aef4685ef040,a692310a-e746-fc49-dcbb-fc122797b37a,a913ff89-b5bc-a480-783b-59ff8d92c83c,a9488095-2108-a9f5-6594-e428c142b82b,adf638bc-c5b4-e168-1ba9-70b09262ade7,b0c82d09-fafb-186e-cf75-344f74ee10d7,b18efe1e-ac3a-ab1c-2af9-25978c29b13d,b3903811-7896-3401-1ed0-0ff116877990,b59f1821-9cdb-2229-d8a8-63742a3b326a,b6c32818-6dc3-2845-9f25-d0a0b150b8f7,b8d1adf7-dcc3-f0a0-e315-5b6c35651fd4,c0c0b86b-0fd0-a725-474b-ea3251bdbe71,c3a31b6e-1278-2e99-f68e-684f1ba8dbbe,c52aeb0a-1a47-437c-162b-c60ee7de2721,c5424b8f-3961-fdbf-6d10-0c8dea85e108,ca75e7ea-b90d-ceb4-e3e4-45fbe5840a78} | {0.00043333333,0.00043333333,0.0004,0.0004,0.0004,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00036666667,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.00033333333,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003,0.0003}
 conditions   | encounter      | -0.85545605 |          0 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | 
 encounters   | patient        |        9841 |          0 | {31d183f5-f733-7c53-dbef-8fe3c852fa5d,122b43b0-c826-d632-d6c2-6702596d4515,9cecd6da-732b-bc27-edc2-efe333b174aa,857c392f-a3ae-e788-2b10-3197da7c6294,f9c745a9-f886-0c4c-cca4-75579d5b8977,37e1f5fe-2e42-b09c-7310-5845f5d1e350,cae10920-f977-48b4-a0d3-4d70ad561fd1,6ff8a994-549e-f010-ba4e-d691a013dd96,990416ff-d91b-cca3-36c5-376f577ba521,d9fbdde6-cb1e-de38-e196-19ed0dfee1a3,c471159d-c8a1-f4f4-4e1a-79dabcfd8207,47fd027a-e8d8-416a-8a9a-cef726e9e290,4d937d26-b2b9-1321-523f-9319c052b902,d89999ee-520b-982e-3082-9ffd96dd5c5b,d690b752-746a-42bb-4fe9-d31b28dc8620,718ebd98-a076-10d3-1765-54adaab2d729,88f0d738-ecc1-ff8b-2a5c-d891289fc8a6,b9839ed7-11a6-ae5c-2228-d76af9438b72,32f699a4-8b74-2de0-9dd1-9590f509353b,3f336702-bf73-4fc8-bd59-3ba77fd65d0d,d3ff6cd1-0f11-c8cb-079e-1b4fe189d6d3,07ae0a6b-2620-94f6-0315-dfcd70b9c8b9,6101cb14-5f2d-9ad8-ee61-35bdb8c9aca1,1d6644f4-ec70-e2f3-b3b2-f2d824b18590,c5424b8f-3961-fdbf-6d10-0c8dea85e108,0825cb70-0237-e458-61c0-baf8f447243d,0b6ddaae-7f02-85f2-43c0-eae03fe2954b,84bebad5-7200-d4af-50c5-997dfa5fd351,06d2a994-3512-37d0-43c9-4fbe1cf3f3c9,19d2cfb8-439b-454a-b47e-5274c219005b,c2e6f531-da45-c14b-4a15-47a92885fe07,0a8273cb-eedb-ec95-9378-a32caae54e32,6538a813-a327-be92-8b57-fc9b08470e41,3acf9313-1874-4dff-ab2a-3187516d92d6,4c17f239-aa11-55b0-9332-fd8d5a2309d5,6b12fc31-3c23-9d2f-6c25-0a023f5ceb2b,d3354e1c-bc02-dc94-3d5c-c672a9bc4935,199bdb33-cebe-a079-da8c-91e476691866,5f53179f-05b7-3c2c-9b01-4272c5303837,3cd17abb-4a45-7f2b-7baf-bc08a2b372fa,a6c683ca-cd27-e3d2-709c-fe95bdf9c359,f9358505-f843-8479-720b-6c986f76615e,6ec18ddf-e9ee-421a-9033-456f558c7b4b,d8252506-7fe8-01a9-92ec-82daed551fc6,e6edfd22-e775-5ad4-5316-b39c20487f1e,798079b2-c51c-89f9-ca7b-f048438047ce,9c2fb5c7-6152-034f-7073-55f67b6673f7,f7bb6e12-8390-1468-e2d3-d8847a175ab3,2bb3f4c6-8a3f-9c5a-031b-e386d31cfee4,3dd2dd29-7cd0-48f7-b859-136c6e9d36e0,66c333ff-9754-992d-3495-9b4655595ceb,3dda7c97-b2d6-1640-6fec-77a87ea5a9fc,adf20c7b-eabf-fb6b-60d4-820e464ded70,b7901c79-e61a-2365-a664-10f10bfa9dd2,56eb31d0-48b8-0070-fbed-b8e4e5b1cba7,ad6e1c82-a614-e31c-f54f-4e50cc12b7f6,137acc1b-dbca-473e-84bb-fe1baaf98819,1398e5a3-0a57-b8d2-3510-26b01726e3f0,a3f2f074-e32b-7c82-77b7-e869ab4b6251,a65fcee6-b799-52aa-9771-aef4685ef040,a7bcba61-bab3-77c8-3816-9b7c8327936c,ae9bb913-6abf-bf4d-62cb-aa93f4605794,e14fe415-f7e9-a22a-1510-7eabad27cb85,23298e85-4fb0-18b6-bf5f-1f1ddd3d7d39,3e42f0d6-03c8-61e7-789c-087a86b27f85,9a30694a-27fd-d3fc-fff3-bb19ed194238,b13c989b-1835-d41d-837d-c846e8d665e0,d85b2b3b-eb14-e119-fd52-1d6780deb5fa,57183035-ee9b-acf4-d45c-1f29873bbeb0,66f251b6-6418-ffda-be3c-e48374f3050c,67a755f2-f0c3-2cd9-dd8d-1068ca1e4422,7489a357-1815-8bf4-bcbc-c5f6c3c8d4d3,7d442d39-ea09-ac6b-de2d-e68a4a2af790,85c35d0c-2106-5204-f03b-b50acf6a1f3e,a708bca4-8fc9-4567-8c22-8b13d44f4f45,b59f1821-9cdb-2229-d8a8-63742a3b326a,b8970fe2-0270-8954-46d2-88a4c76483a0,1e2cbd20-028f-0355-d453-b4962726c0c2,4c29af27-d2b7-22f7-3110-a32cff1c5e6d,591c81cc-a08b-2ef6-8829-06bb016552d5,714b9c18-783d-4f52-aa64-cc3a05a286d9,95a6706b-fe7d-c74c-e542-2377671c9ba1,97148535-e94b-71e0-d4d4-ea2bd01d793b,b3903811-7896-3401-1ed0-0ff116877990,2c71dd97-7085-416a-aa07-d675bbe3adf2,3f7564e3-bfd4-e6f5-fe34-42e5cf4107ed,59179568-ceb5-9a81-c232-c7c818abda89,a415d006-0a13-81c2-dd69-9c7bc4dc2e33,ac7fd2bf-5f9d-1130-6ea3-16be40df0355,481de371-ef23-97d6-221f-0d70e1c977ac,503de5a3-b2ec-e4b4-c76a-f0b8e9d75036,642e07f0-a75a-8593-2392-4c94b4accd71,906e20fc-4962-9c07-eced-12fa38a15117,93a4ac35-d696-6c47-3ecd-034af162055d,d241ca67-c3f9-ac5f-d5ea-85fc698487ea,e92f33b4-3d3c-55b5-4e48-8f802e0804d8,ef6b5b97-d1ea-3c3e-3ec1-e119d2dc36a2,f5eed22d-5563-fe39-bf26-9593cded5272,fe22e029-fa41-8ab9-3faf-20fafc03a867,2ebf675e-37d5-5e58-76f6-f40637f7a4e2} | {0.004466667,0.0042333333,0.0042,0.0039666668,0.0038666667,0.0038333333,0.0038,0.0035333333,0.0035,0.0034333332,0.0034,0.0032666668,0.0032,0.0031666667,0.0031333333,0.0031,0.0031,0.0031,0.0030666667,0.0030666667,0.0030666667,0.003,0.0029666666,0.0029333334,0.0027666667,0.0027333333,0.0027333333,0.0027,0.0026333334,0.0023666667,0.0018,0.0017,0.0016333334,0.0016,0.0016,0.0015333333,0.0015333333,0.0012666667,0.0012666667,0.0012333334,0.0011666666,0.0010666667,0.0010333334,0.0010333334,0.0010333334,0.001,0.0009666667,0.0009666667,0.00093333336,0.0009,0.0009,0.00086666667,0.00086666667,0.00086666667,0.00083333335,0.00083333335,0.0008,0.0008,0.0008,0.0008,0.0008,0.0008,0.0008,0.00076666666,0.00076666666,0.00076666666,0.00076666666,0.00076666666,0.00073333335,0.00073333335,0.00073333335,0.00073333335,0.00073333335,0.00073333335,0.00073333335,0.00073333335,0.00073333335,0.0007,0.0007,0.0007,0.0007,0.0007,0.0007,0.0007,0.00066666666,0.00066666666,0.00066666666,0.00066666666,0.00066666666,0.00063333334,0.00063333334,0.00063333334,0.00063333334,0.00063333334,0.00063333334,0.00063333334,0.00063333334,0.00063333334,0.00063333334,0.0006}
 encounters   | encounterclass |           6 |          0 | {wellness,ambulatory,outpatient,urgentcare,emergency,inpatient}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | {0.35606667,0.355,0.17123333,0.044233333,0.038566668,0.0349}
 observations | encounter      |       74026 | 0.10226667 | {3da9e81a-ebb1-91ab-2582-3abb50c94219}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | {0.0002}
 observations | patient        |        9496 |          0 | {122b43b0-c826-d632-d6c2-6702596d4515,31d183f5-f733-7c53-dbef-8fe3c852fa5d,d9fbdde6-cb1e-de38-e196-19ed0dfee1a3,06d2a994-3512-37d0-43c9-4fbe1cf3f3c9,37e1f5fe-2e42-b09c-7310-5845f5d1e350,718ebd98-a076-10d3-1765-54adaab2d729,d690b752-746a-42bb-4fe9-d31b28dc8620,990416ff-d91b-cca3-36c5-376f577ba521,9cecd6da-732b-bc27-edc2-efe333b174aa,c471159d-c8a1-f4f4-4e1a-79dabcfd8207,3f336702-bf73-4fc8-bd59-3ba77fd65d0d,6101cb14-5f2d-9ad8-ee61-35bdb8c9aca1,cae10920-f977-48b4-a0d3-4d70ad561fd1,6ff8a994-549e-f010-ba4e-d691a013dd96,1d6644f4-ec70-e2f3-b3b2-f2d824b18590,84bebad5-7200-d4af-50c5-997dfa5fd351,4d937d26-b2b9-1321-523f-9319c052b902,47fd027a-e8d8-416a-8a9a-cef726e9e290,19d2cfb8-439b-454a-b47e-5274c219005b,857c392f-a3ae-e788-2b10-3197da7c6294,0b6ddaae-7f02-85f2-43c0-eae03fe2954b,b9839ed7-11a6-ae5c-2228-d76af9438b72,07ae0a6b-2620-94f6-0315-dfcd70b9c8b9,88f0d738-ecc1-ff8b-2a5c-d891289fc8a6,f9c745a9-f886-0c4c-cca4-75579d5b8977,d3ff6cd1-0f11-c8cb-079e-1b4fe189d6d3,d89999ee-520b-982e-3082-9ffd96dd5c5b,0825cb70-0237-e458-61c0-baf8f447243d,c5424b8f-3961-fdbf-6d10-0c8dea85e108,32f699a4-8b74-2de0-9dd1-9590f509353b,fa9b0d98-f8e9-1557-7320-22db69280d56,d5df8edf-fd55-ffb5-02b1-55709686ceb9,d4adfa2e-89ba-4ae6-9770-ef5a7ec4173a,6a06be24-745e-b9e9-0ca3-59dd1067cada,199bdb33-cebe-a079-da8c-91e476691866,aac0730a-4c48-7f03-ca20-eef3ff7a8cc1,16831b33-2f35-f54b-2f4e-3ff79e45ee37,74447d99-c8af-1fa4-5eda-6d0f26fcd31c,970eff65-1268-9ade-f3c8-117d224a1b2b,08678af4-202f-9278-1f62-cea8ad8b31d4,694305b7-18ec-a7ae-dcd9-8bd290d2db9e,74845fbc-bb34-3049-6293-29d0a0ec71f0,3b46f9a9-3447-441d-abd4-4f8e46f9e0c2,e14fe415-f7e9-a22a-1510-7eabad27cb85,0a8273cb-eedb-ec95-9378-a32caae54e32,1d02dee9-29b3-af80-bb75-db2f91fb007a,6a9603ee-ee12-0eee-5520-065b7e25e795,832e28e9-b57a-4fb7-5cbf-a4821c068abb,abaf3493-10bf-f0ac-9fd3-ff455c1619b4,ec2ffa5e-784d-e996-fc0c-237fbe205358,f95ab8fb-6341-1428-0c29-d77a5d7b7938,3acf9313-1874-4dff-ab2a-3187516d92d6,cd867097-7f68-4f02-28b2-8c29bde19570,1bd26679-732c-614b-00a1-3f48942b66c7,6538a813-a327-be92-8b57-fc9b08470e41,74c818aa-a9ae-18de-e507-fe916167d5b6,888734c8-0a96-9177-42b9-3715aa42fa7e,e16fcaa4-60bb-05a6-b541-6c48b24a9d30,1ff96904-a0c4-ab1c-2220-629472b0d0e7,42ed3ffc-ad75-498c-9dbc-ddff639a75d4,4c17f239-aa11-55b0-9332-fd8d5a2309d5,591c81cc-a08b-2ef6-8829-06bb016552d5,a4f046e8-39d2-4800-e05a-6d73464e7b31,d8252506-7fe8-01a9-92ec-82daed551fc6,e6edfd22-e775-5ad4-5316-b39c20487f1e,adf20c7b-eabf-fb6b-60d4-820e464ded70,b2b612b0-d4ac-4b83-8d33-4ed6b295c01c,df3db66c-2f73-795b-3fae-6fb7cc97ae3e,3bf1f955-b473-dfa8-1f39-bc19199e90b5,5b347f5f-fcc1-497a-bfb8-b3d15b58a1ee,5f53179f-05b7-3c2c-9b01-4272c5303837,6ec18ddf-e9ee-421a-9033-456f558c7b4b,ad6e1c82-a614-e31c-f54f-4e50cc12b7f6,b59f1821-9cdb-2229-d8a8-63742a3b326a,d83e3c63-2ddc-69e9-5cf8-c0351364d84e,ffff8ca0-6ad4-7f25-0879-3ec64a35a277,213b3801-2e51-5828-a808-0275b815fe30,3cd17abb-4a45-7f2b-7baf-bc08a2b372fa,53f3587e-b9bf-473a-b36e-62f0e1946fa1,59cf17d9-6c13-4333-a1cb-cc5fdf63366d,5f33611e-74fe-bfd1-28ae-d3a6b6137ad3,85cd72ce-221a-1064-6e5a-c347b927d76d,941f66eb-5ca6-45cc-b205-6de1f1a59233,a7bcba61-bab3-77c8-3816-9b7c8327936c,c2e6f531-da45-c14b-4a15-47a92885fe07,d482aa6b-c7a2-880a-c886-e8bfa045be47,f8eec504-1f15-8a3d-e7e5-923fc253ba94,20ab31b8-2fbe-2949-6aa5-d223f9faa7bd,642e07f0-a75a-8593-2392-4c94b4accd71,7cfb7700-9fbc-d3b6-56dc-5fc1a7dccbd3,9214c807-138f-2bd7-e8b1-2cb96eaedceb,a65fcee6-b799-52aa-9771-aef4685ef040,cb97cc3f-8d48-e6f9-c443-374a1620b558,de1a760b-57e3-db8b-7692-169fb69b72be,1398e5a3-0a57-b8d2-3510-26b01726e3f0,1e8adec0-a52e-b4f4-7a0d-41b4c6c09884,6e2bf4ed-fb15-305a-c226-89bd1e2cd33e,782a6f51-be0d-ee18-6d56-63ae37f46417,906e20fc-4962-9c07-eced-12fa38a15117,a708bca4-8fc9-4567-8c22-8b13d44f4f45} | {0.0038,0.0034333332,0.0034,0.0033333334,0.0033333334,0.0032333334,0.0031333333,0.0031,0.0030666667,0.0030666667,0.0029666666,0.0029,0.0029,0.0028333333,0.0028,0.0028,0.0027666667,0.0027333333,0.0026666666,0.0026666666,0.0025,0.0025,0.0024,0.0024,0.0023666667,0.0023333333,0.0023,0.0022,0.0020666667,0.0019333333,0.0015,0.0014333334,0.0013666666,0.0013333333,0.0012,0.0012,0.0011666666,0.0011666666,0.0011666666,0.0011333333,0.0011333333,0.0011333333,0.0011,0.0011,0.0010333334,0.0010333334,0.0010333334,0.0010333334,0.0010333334,0.0010333334,0.0010333334,0.001,0.001,0.0009666667,0.0009666667,0.0009666667,0.0009666667,0.0009666667,0.00093333336,0.00093333336,0.00093333336,0.00093333336,0.00093333336,0.00093333336,0.00093333336,0.0009,0.0009,0.0009,0.00086666667,0.00086666667,0.00086666667,0.00086666667,0.00086666667,0.00086666667,0.00086666667,0.00086666667,0.00083333335,0.00083333335,0.00083333335,0.00083333335,0.00083333335,0.00083333335,0.00083333335,0.00083333335,0.00083333335,0.00083333335,0.00083333335,0.0008,0.0008,0.0008,0.0008,0.0008,0.0008,0.0008,0.00076666666,0.00076666666,0.00076666666,0.00076666666,0.00076666666,0.00076666666}
(6 rows)

Time: 15,087 ms
 attname | n_hist_bounds 
---------+---------------
 start   |           101
(1 row)

Time: 1,876 ms
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107993.06..107993.07 rows=2 width=212) (actual time=873.042..874.740 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=50781 read=71135
   I/O Timings: shared read=720.708
   ->  Gather  (cost=105578.60..107993.05 rows=2 width=212) (actual time=827.269..843.514 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=50775 read=71135
         I/O Timings: shared read=720.708
         ->  Parallel Hash Right Join  (cost=104578.60..106992.85 rows=1 width=212) (actual time=782.541..794.250 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=50775 read=71135
               I/O Timings: shared read=720.708
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.005..2.511 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104578.59..104578.59 rows=1 width=165) (actual time=782.409..782.413 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=49220 read=71135
                     I/O Timings: shared read=720.708
                     ->  Nested Loop  (cost=25678.68..104578.59 rows=1 width=165) (actual time=239.021..758.502 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=49220 read=71135
                           I/O Timings: shared read=720.708
                           ->  Parallel Hash Join  (cost=25678.39..104577.64 rows=3 width=181) (actual time=238.946..728.231 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=10489 read=71135
                                 I/O Timings: shared read=720.708
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.142..289.104 rows=1498485.00 loops=2)
                                       Buffers: shared hit=5920 read=53936
                                       I/O Timings: shared read=398.538
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1372 width=100) (actual time=232.798..232.799 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=4569 read=17199
                                       I/O Timings: shared read=322.170
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1372 width=100) (actual time=2.708..230.559 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=4569 read=17199
                                             I/O Timings: shared read=322.170
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=292
 Planning Time: 3.821 ms
 Execution Time: 875.354 ms
(48 rows)

Time: 880,239 ms
ALTER TABLE
Time: 12,235 ms
ALTER TABLE
Time: 0,341 ms
ALTER TABLE
Time: 0,219 ms
ALTER TABLE
Time: 0,180 ms
ALTER TABLE
Time: 0,143 ms
ALTER TABLE
Time: 0,193 ms
ALTER TABLE
Time: 0,163 ms
ANALYZE
Time: 12042,508 ms (00:12,043)
ANALYZE
Time: 14689,659 ms (00:14,690)
ANALYZE
Time: 2697,282 ms (00:02,697)
ANALYZE
Time: 1107,910 ms (00:01,108)
 tablename  |    attname     | n_distinct |                        most_common_vals                         |                          most_common_freqs                          
------------+----------------+------------+-----------------------------------------------------------------+---------------------------------------------------------------------
 encounters | encounterclass |          6 | {wellness,ambulatory,outpatient,urgentcare,emergency,inpatient} | {0.35779333,0.35562333,0.16831,0.044723332,0.039133333,0.034416668}
(1 row)

Time: 4,117 ms
 attname | n_hist_bounds 
---------+---------------
 start   |          1001
(1 row)

Time: 3,177 ms
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107993.90..107993.91 rows=2 width=212) (actual time=1324.982..1329.754 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=51663 read=70247
   I/O Timings: shared read=336.265
   ->  Gather  (cost=105579.44..107993.89 rows=2 width=212) (actual time=1178.983..1202.645 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=51663 read=70247
         I/O Timings: shared read=336.265
         ->  Parallel Hash Right Join  (cost=104579.44..106993.69 rows=1 width=212) (actual time=1134.864..1151.190 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=51663 read=70247
               I/O Timings: shared read=336.265
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.014..3.245 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.43..104579.43 rows=1 width=165) (actual time=1134.578..1134.585 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=50108 read=70247
                     I/O Timings: shared read=336.265
                     ->  Nested Loop  (cost=25679.52..104579.43 rows=1 width=165) (actual time=204.618..1064.756 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=50108 read=70247
                           I/O Timings: shared read=336.265
                           ->  Parallel Hash Join  (cost=25679.23..104578.48 rows=3 width=181) (actual time=204.558..983.530 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=11377 read=70247
                                 I/O Timings: shared read=336.265
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.124..282.736 rows=1498485.00 loops=2)
                                       Buffers: shared hit=6364 read=53492
                                       I/O Timings: shared read=130.055
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1428 width=100) (actual time=199.045..199.047 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=5013 read=16755
                                       I/O Timings: shared read=206.210
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1428 width=100) (actual time=3.575..195.319 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=5013 read=16755
                                             I/O Timings: shared read=206.210
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.011..0.011 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=218
 Planning Time: 67.629 ms
 Execution Time: 1332.052 ms
(48 rows)

Time: 1401,066 ms (00:01,401)
ALTER TABLE
Time: 3,976 ms
ALTER TABLE
Time: 0,509 ms
ALTER TABLE
Time: 0,308 ms
ALTER TABLE
Time: 0,305 ms
ALTER TABLE
Time: 0,279 ms
ALTER TABLE
Time: 0,277 ms
ALTER TABLE
Time: 0,218 ms
ANALYZE
Time: 2013,308 ms (00:02,013)
ANALYZE
Time: 1851,022 ms (00:01,851)
ANALYZE
Time: 955,555 ms
ANALYZE
Time: 947,709 ms

[STDERR]
psql:claude_step1/Q1_04_stats_pg.sql:50: INFO:  analyzing "public.encounters"
psql:claude_step1/Q1_04_stats_pg.sql:50: INFO:  "encounters": scanned 21768 of 21768 pages, containing 533460 live rows and 0 dead rows; 300000 rows in sample, 533460 estimated total rows
psql:claude_step1/Q1_04_stats_pg.sql:50: INFO:  finished analyzing table "synthea_scale.public.encounters"
I/O timings: read: 53.539 ms, write: 0.000 ms
avg read rate: 11.077 MB/s, avg write rate: 0.020 MB/s
buffer usage: 5137 hits, 17038 reads, 31 dirtied
WAL usage: 191 records, 16 full page images, 224975 bytes, 0 buffers full
system usage: CPU: user: 10.95 s, system: 0.20 s, elapsed: 12.01 s
psql:claude_step1/Q1_04_stats_pg.sql:51: INFO:  analyzing "public.observations"
psql:claude_step1/Q1_04_stats_pg.sql:51: INFO:  "observations": scanned 59856 of 59856 pages, containing 2996970 live rows and 0 dead rows; 300000 rows in sample, 2996970 estimated total rows
psql:claude_step1/Q1_04_stats_pg.sql:51: INFO:  finished analyzing table "synthea_scale.public.observations"
I/O timings: read: 211.635 ms, write: 0.886 ms
avg read rate: 28.620 MB/s, avg write rate: 0.015 MB/s
buffer usage: 6405 hits, 53759 reads, 29 dirtied
WAL usage: 189 records, 11 full page images, 236416 bytes, 0 buffers full
system usage: CPU: user: 13.26 s, system: 0.15 s, elapsed: 14.67 s
psql:claude_step1/Q1_04_stats_pg.sql:52: INFO:  analyzing "public.conditions"
psql:claude_step1/Q1_04_stats_pg.sql:52: INFO:  "conditions": scanned 1552 of 1552 pages, containing 83760 live rows and 0 dead rows; 83760 rows in sample, 83760 estimated total rows
psql:claude_step1/Q1_04_stats_pg.sql:52: INFO:  finished analyzing table "synthea_scale.public.conditions"
I/O timings: read: 0.157 ms, write: 1.491 ms
avg read rate: 0.009 MB/s, avg write rate: 0.081 MB/s
buffer usage: 1937 hits, 3 reads, 28 dirtied
WAL usage: 198 records, 6 full page images, 213341 bytes, 0 buffers full
system usage: CPU: user: 2.46 s, system: 0.03 s, elapsed: 2.69 s
psql:claude_step1/Q1_04_stats_pg.sql:53: INFO:  analyzing "public.patients"
psql:claude_step1/Q1_04_stats_pg.sql:53: INFO:  "patients": scanned 417 of 417 pages, containing 11710 live rows and 0 dead rows; 11710 rows in sample, 11710 estimated total rows
psql:claude_step1/Q1_04_stats_pg.sql:53: INFO:  finished analyzing table "synthea_scale.public.patients"
I/O timings: read: 1.862 ms, write: 0.096 ms
avg read rate: 0.120 MB/s, avg write rate: 0.163 MB/s
buffer usage: 715 hits, 17 reads, 23 dirtied
WAL usage: 99 records, 21 full page images, 144923 bytes, 0 buffers full
system usage: CPU: user: 1.04 s, system: 0.01 s, elapsed: 1.10 s
```

### PG Stats Run 1:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107993.81..107993.82 rows=2 width=212) (actual time=1421.681..1423.303 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53445 read=68471
   I/O Timings: shared read=1400.036
   ->  Gather  (cost=105579.35..107993.80 rows=2 width=212) (actual time=1376.674..1392.953 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53439 read=68471
         I/O Timings: shared read=1400.036
         ->  Parallel Hash Right Join  (cost=104579.35..106993.60 rows=1 width=212) (actual time=1345.719..1357.392 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53439 read=68471
               I/O Timings: shared read=1400.036
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.005..2.583 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.34..104579.34 rows=1 width=165) (actual time=1345.596..1345.601 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=51884 read=68471
                     I/O Timings: shared read=1400.036
                     ->  Nested Loop  (cost=25679.43..104579.34 rows=1 width=165) (actual time=149.425..1319.403 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=51884 read=68471
                           I/O Timings: shared read=1400.036
                           ->  Parallel Hash Join  (cost=25679.14..104578.39 rows=3 width=181) (actual time=149.371..1266.908 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13153 read=68471
                                 I/O Timings: shared read=1400.036
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.080..761.003 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7252 read=52604
                                       I/O Timings: shared read=1209.572
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1422 width=100) (actual time=146.757..146.759 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=5901 read=15867
                                       I/O Timings: shared read=190.464
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1422 width=100) (actual time=0.993..145.266 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=5901 read=15867
                                             I/O Timings: shared read=190.464
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.007..0.007 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=414
 Planning Time: 20.292 ms
 Execution Time: 1423.993 ms
(48 rows)
```

### PG Stats Run 2:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107993.81..107993.82 rows=2 width=212) (actual time=649.650..651.170 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53750 read=68166
   I/O Timings: shared read=438.397
   ->  Gather  (cost=105579.35..107993.80 rows=2 width=212) (actual time=599.384..614.283 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53744 read=68166
         I/O Timings: shared read=438.397
         ->  Parallel Hash Right Join  (cost=104579.35..106993.60 rows=1 width=212) (actual time=564.994..576.778 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53744 read=68166
               I/O Timings: shared read=438.397
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.005..2.661 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.34..104579.34 rows=1 width=165) (actual time=564.870..564.875 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52189 read=68166
                     I/O Timings: shared read=438.397
                     ->  Nested Loop  (cost=25679.43..104579.34 rows=1 width=165) (actual time=149.744..554.648 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52189 read=68166
                           I/O Timings: shared read=438.397
                           ->  Parallel Hash Join  (cost=25679.14..104578.39 rows=3 width=181) (actual time=149.673..527.560 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13458 read=68166
                                 I/O Timings: shared read=438.397
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.081..204.265 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7369 read=52487
                                       I/O Timings: shared read=251.495
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1422 width=100) (actual time=145.929..145.930 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=6089 read=15679
                                       I/O Timings: shared read=186.902
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1422 width=100) (actual time=0.859..144.336 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=6089 read=15679
                                             I/O Timings: shared read=186.902
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=414
 Planning Time: 22.885 ms
 Execution Time: 651.863 ms
(48 rows)
```

### PG Stats Run 3:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107993.81..107993.82 rows=2 width=212) (actual time=756.961..758.711 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53837 read=68079 written=1
   I/O Timings: shared read=482.486 write=0.193
   ->  Gather  (cost=105579.35..107993.80 rows=2 width=212) (actual time=710.395..725.842 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53831 read=68079 written=1
         I/O Timings: shared read=482.486 write=0.193
         ->  Parallel Hash Right Join  (cost=104579.35..106993.60 rows=1 width=212) (actual time=662.504..674.580 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53831 read=68079 written=1
               I/O Timings: shared read=482.486 write=0.193
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.007..2.544 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.34..104579.34 rows=1 width=165) (actual time=662.339..662.345 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52276 read=68079 written=1
                     I/O Timings: shared read=482.486 write=0.193
                     ->  Nested Loop  (cost=25679.43..104579.34 rows=1 width=165) (actual time=124.955..640.698 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52276 read=68079 written=1
                           I/O Timings: shared read=482.486 write=0.193
                           ->  Parallel Hash Join  (cost=25679.14..104578.39 rows=3 width=181) (actual time=124.913..608.414 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13545 read=68079 written=1
                                 I/O Timings: shared read=482.486 write=0.193
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.577..271.085 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7553 read=52303 written=1
                                       I/O Timings: shared read=349.521 write=0.193
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1422 width=100) (actual time=122.308..122.309 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=5992 read=15776
                                       I/O Timings: shared read=132.965
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1422 width=100) (actual time=3.334..120.612 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=5992 read=15776
                                             I/O Timings: shared read=132.965
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=414
 Planning Time: 22.990 ms
 Execution Time: 759.891 ms
(48 rows)
```

### PG Stats Run 4:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107993.81..107993.82 rows=2 width=212) (actual time=628.531..629.948 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53806 read=68110 written=4
   I/O Timings: shared read=403.433 write=1.710
   ->  Gather  (cost=105579.35..107993.80 rows=2 width=212) (actual time=584.575..599.380 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53800 read=68110 written=4
         I/O Timings: shared read=403.433 write=1.710
         ->  Parallel Hash Right Join  (cost=104579.35..106993.60 rows=1 width=212) (actual time=543.713..554.185 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53800 read=68110 written=4
               I/O Timings: shared read=403.433 write=1.710
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.004..2.270 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.34..104579.34 rows=1 width=165) (actual time=543.603..543.608 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52245 read=68110 written=4
                     I/O Timings: shared read=403.433 write=1.710
                     ->  Nested Loop  (cost=25679.43..104579.34 rows=1 width=165) (actual time=133.039..532.834 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52245 read=68110 written=4
                           I/O Timings: shared read=403.433 write=1.710
                           ->  Parallel Hash Join  (cost=25679.14..104578.39 rows=3 width=181) (actual time=132.980..506.669 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13514 read=68110 written=4
                                 I/O Timings: shared read=403.433 write=1.710
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.889..205.078 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7613 read=52243 written=4
                                       I/O Timings: shared read=257.774 write=1.710
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1422 width=100) (actual time=128.920..128.921 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=5901 read=15867
                                       I/O Timings: shared read=145.659
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1422 width=100) (actual time=1.391..127.181 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=5901 read=15867
                                             I/O Timings: shared read=145.659
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=414
 Planning Time: 25.993 ms
 Execution Time: 630.644 ms
(48 rows)
```

### PG Stats Run 5:
```text
SET
                                                                                                               QUERY PLAN                                                                                                               
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=107993.81..107993.82 rows=2 width=212) (actual time=755.864..757.533 rows=12910.00 loops=1)
   Sort Key: p.id, e.start, e.id, o.code
   Sort Method: quicksort  Memory: 3123kB
   Buffers: shared hit=53838 read=68078 written=1
   I/O Timings: shared read=552.116 write=0.687
   ->  Gather  (cost=105579.35..107993.80 rows=2 width=212) (actual time=709.104..724.386 rows=12910.00 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         Buffers: shared hit=53832 read=68078 written=1
         I/O Timings: shared read=552.116 write=0.687
         ->  Parallel Hash Right Join  (cost=104579.35..106993.60 rows=1 width=212) (actual time=667.080..678.710 rows=6455.00 loops=2)
               Hash Cond: (((c.encounter)::text = (e.id)::text) AND ((c.patient)::text = (p.id)::text))
               Buffers: shared hit=53832 read=68078 written=1
               I/O Timings: shared read=552.116 write=0.687
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=108) (actual time=0.009..2.604 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=104579.34..104579.34 rows=1 width=165) (actual time=666.913..666.918 rows=6455.00 loops=2)
                     Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 3096kB
                     Buffers: shared hit=52277 read=68078 written=1
                     I/O Timings: shared read=552.116 write=0.687
                     ->  Nested Loop  (cost=25679.43..104579.34 rows=1 width=165) (actual time=155.998..649.749 rows=6455.00 loops=2)
                           Join Filter: ((p.id)::text = (e.patient)::text)
                           Buffers: shared hit=52277 read=68078 written=1
                           I/O Timings: shared read=552.116 write=0.687
                           ->  Parallel Hash Join  (cost=25679.14..104578.39 rows=3 width=181) (actual time=155.954..620.409 rows=6455.00 loops=2)
                                 Hash Cond: (((o.patient)::text = (e.patient)::text) AND ((o.encounter)::text = (e.id)::text))
                                 Buffers: shared hit=13546 read=68078 written=1
                                 I/O Timings: shared read=552.116 write=0.687
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=118) (actual time=0.510..270.572 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7689 read=52167 written=1
                                       I/O Timings: shared read=367.813 write=0.687
                                 ->  Parallel Hash  (cost=25657.81..25657.81 rows=1422 width=100) (actual time=151.632..151.633 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 608kB
                                       Buffers: shared hit=5857 read=15911
                                       I/O Timings: shared read=184.304
                                       ->  Parallel Seq Scan on encounters e  (cost=0.00..25657.81 rows=1422 width=100) (actual time=2.617..149.801 rows=1920.00 loops=2)
                                             Filter: ((start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone) AND ((encounterclass)::text = 'ambulatory'::text))
                                             Rows Removed by Filter: 264810
                                             Buffers: shared hit=5857 read=15911
                                             I/O Timings: shared read=184.304
                           ->  Index Scan using patients_pkey on patients p  (cost=0.29..0.30 rows=1 width=58) (actual time=0.004..0.004 rows=1.00 loops=12910)
                                 Index Cond: ((id)::text = (o.patient)::text)
                                 Index Searches: 12910
                                 Buffers: shared hit=38731
 Planning:
   Buffers: shared hit=414
 Planning Time: 20.987 ms
 Execution Time: 758.346 ms
(48 rows)
```

## 8. Q1_04_stats_mysql.sql (Full file + 5 lần EXPLAIN sau khi STATS_SAMPLE_PAGES=200 & Hist)

### Full File Execution (`mysql < Q1_04_stats_mysql.sql` - gồm trước, sau & khôi phục):
```text
persistent	sample_pages
1	20
TABLE_NAME	INDEX_NAME	COLUMN_NAME	CARDINALITY
encounters	PRIMARY	id	509952
patients	PRIMARY	id	11521
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=78631..78640 rows=12910 loops=1)
    -> Stream results  (cost=1.19e+9 rows=11.9e+9) (actual time=1198..78552 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.19e+9 rows=11.9e+9) (actual time=1198..78502 rows=12910 loops=1)
            -> Nested loop inner join  (cost=3.27e+6 rows=143475) (actual time=199..76940 rows=12910 loops=1)
                -> Nested loop inner join  (cost=3.22e+6 rows=143475) (actual time=199..76634 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=317350 rows=2.87e+6) (actual time=0.0505..15795 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=317350 rows=2.87e+6) (actual time=0.0481..13811 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.911 rows=0.05) (actual time=0.0222..0.0222 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.911 rows=1) (actual time=0.0194..0.0195 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.25 rows=1) (actual time=0.023..0.0231 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83105) (actual time=1.33..380 rows=83760 loops=1)

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
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=76462..76473 rows=12910 loops=1)
    -> Stream results  (cost=1.24e+9 rows=12.4e+9) (actual time=1105..76370 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.24e+9 rows=12.4e+9) (actual time=1105..76315 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.34e+6 rows=148649) (actual time=56.2..74619 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.29e+6 rows=148649) (actual time=56.2..74190 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=327698 rows=2.97e+6) (actual time=0.856..16536 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=327698 rows=2.97e+6) (actual time=0.854..14510 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.56 rows=0.05) (actual time=0.021..0.021 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.56 rows=1) (actual time=0.0182..0.0183 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.254 rows=1) (actual time=0.0326..0.0326 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83105) (actual time=0.263..482 rows=83760 loops=1)

Table	Op	Msg_type	Msg_text
synthea_scale.encounters	histogram	status	Histogram statistics removed for column 'encounterclass'.
synthea_scale.encounters	histogram	status	Histogram statistics removed for column 'start'.
Table	Op	Msg_type	Msg_text
synthea_scale.patients	analyze	status	OK
synthea_scale.encounters	analyze	status	OK
synthea_scale.conditions	analyze	status	OK
synthea_scale.observations	analyze	status	OK
```

### MySQL Stats Run 1:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=67774..67785 rows=12910 loops=1)
    -> Stream results  (cost=1.24e+9 rows=12.4e+9) (actual time=1612..67694 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.24e+9 rows=12.4e+9) (actual time=1612..67643 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.21e+6 rows=148793) (actual time=87.7..65562 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.05e+6 rows=148793) (actual time=87.2..65167 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=327986 rows=2.98e+6) (actual time=1.44..14392 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=327986 rows=2.98e+6) (actual time=1.44..12604 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0185..0.0185 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0159..0.016 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0299..0.03 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83090) (actual time=0.861..659 rows=83760 loops=1)
```

### MySQL Stats Run 2:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=67141..67151 rows=12910 loops=1)
    -> Stream results  (cost=1.24e+9 rows=12.4e+9) (actual time=876..67062 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.24e+9 rows=12.4e+9) (actual time=876..67009 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.21e+6 rows=148793) (actual time=83..65675 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.05e+6 rows=148793) (actual time=82.5..65287 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=327986 rows=2.98e+6) (actual time=1.49..14616 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=327986 rows=2.98e+6) (actual time=1.49..12779 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0185..0.0185 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0159..0.0159 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0294..0.0295 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83090) (actual time=1.13..299 rows=83760 loops=1)
```

### MySQL Stats Run 3:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=68438..68448 rows=12910 loops=1)
    -> Stream results  (cost=1.24e+9 rows=12.4e+9) (actual time=872..68350 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.24e+9 rows=12.4e+9) (actual time=872..68300 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.21e+6 rows=148793) (actual time=88.3..66926 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.05e+6 rows=148793) (actual time=87.8..66545 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=327986 rows=2.98e+6) (actual time=2.24..14986 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=327986 rows=2.98e+6) (actual time=2.23..13057 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0188..0.0188 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0162..0.0162 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.0289..0.029 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83090) (actual time=1.1..295 rows=83760 loops=1)
```

### MySQL Stats Run 4:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=70133..70141 rows=12910 loops=1)
    -> Stream results  (cost=1.24e+9 rows=12.4e+9) (actual time=1051..70043 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.24e+9 rows=12.4e+9) (actual time=1051..69992 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.21e+6 rows=148793) (actual time=112..68503 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.05e+6 rows=148793) (actual time=111..68079 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=327986 rows=2.98e+6) (actual time=3.03..14877 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=327986 rows=2.98e+6) (actual time=3.02..12941 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0194..0.0194 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0168..0.0169 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.92 rows=1) (actual time=0.0322..0.0323 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83090) (actual time=0.955..355 rows=83760 loops=1)
```

### MySQL Stats Run 5:
```text
EXPLAIN
-> Sort: p.id, e.`start`, e.id, o.`code`  (actual time=66324..66333 rows=12910 loops=1)
    -> Stream results  (cost=1.24e+9 rows=12.4e+9) (actual time=994..66241 rows=12910 loops=1)
        -> Left hash join (c.patient = o.patient), (c.encounter = o.encounter)  (cost=1.24e+9 rows=12.4e+9) (actual time=994..66187 rows=12910 loops=1)
            -> Nested loop inner join  (cost=2.21e+6 rows=148793) (actual time=104..64706 rows=12910 loops=1)
                -> Nested loop inner join  (cost=2.05e+6 rows=148793) (actual time=103..64336 rows=12910 loops=1)
                    -> Filter: ((o.encounter is not null) and (o.patient is not null))  (cost=327986 rows=2.98e+6) (actual time=10.7..14629 rows=2.69e+6 loops=1)
                        -> Table scan on o  (cost=327986 rows=2.98e+6) (actual time=10.7..12750 rows=3e+6 loops=1)
                    -> Filter: ((e.patient = o.patient) and (e.encounterclass = 'ambulatory') and (e.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (e.`start` < TIMESTAMP'2021-01-01 00:00:00'))  (cost=0.48 rows=0.05) (actual time=0.0181..0.0181 rows=0.00479 loops=2.69e+6)
                        -> Single-row index lookup on e using PRIMARY (id = o.encounter)  (cost=0.48 rows=1) (actual time=0.0156..0.0157 rows=1 loops=2.69e+6)
                -> Single-row index lookup on p using PRIMARY (id = o.patient)  (cost=0.923 rows=1) (actual time=0.028..0.0281 rows=1 loops=12910)
            -> Hash
                -> Table scan on c  (cost=2.33 rows=83090) (actual time=0.969..343 rows=83760 loops=1)
```

## 9. Q1_05_combined_pg.sql (Check + Equiv + Setup + 5 lần EXPLAIN + pg_stat_user_indexes + Reset)

### PG Combined Check, Equivalence & Setup:
```text
tablename | indexname 
-----------+-----------
(0 rows)

 n_baseline | n_rewrite 
------------+-----------
      12910 |     12910
(1 row)

CREATE INDEX
CREATE INDEX
CREATE INDEX
       index_name        |  size   
-------------------------+---------
 idx_q1_enc_class_start  | 67 MB
 idx_q1_obs_enc_patient  | 40 MB
 idx_q1_cond_enc_patient | 7936 kB
(3 rows)
```

### PG Combined Run 1:
```text
SET
RESET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89334.27..91374.23 rows=17899 width=212) (actual time=576.761..586.355 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12330 read=52068
   I/O Timings: shared read=506.622
   ->  Sort  (cost=88334.26..88360.58 rows=10529 width=212) (actual time=528.286..528.693 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 174kB
         Buffers: shared hit=12330 read=52068
         I/O Timings: shared read=506.622
         Worker 0:  Sort Method: quicksort  Memory: 2973kB
         ->  Parallel Hash Right Join  (cost=85306.54..87630.81 rows=10529 width=212) (actual time=502.620..512.710 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12315 read=52068
               I/O Timings: shared read=506.622
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.007..2.474 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85213.31..85213.31 rows=7458 width=165) (actual time=502.453..502.458 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=10760 read=52068
                     I/O Timings: shared read=506.622
                     ->  Hash Join  (cost=9572.39..85213.31 rows=7458 width=165) (actual time=9.522..498.978 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=10760 read=52068
                           I/O Timings: shared read=506.622
                           ->  Parallel Hash Join  (cost=8891.91..84513.25 rows=7458 width=144) (actual time=4.623..492.246 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=9926 read=52068
                                 I/O Timings: shared read=506.622
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.118..340.138 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7788 read=52068
                                       I/O Timings: shared read=506.622
                                 ->  Parallel Hash  (cost=8868.49..8868.49 rows=1874 width=100) (actual time=3.630..3.631 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=249.17..8868.49 rows=1874 width=100) (actual time=0.860..6.287 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..248.38 rows=3186 width=0) (actual time=0.525..0.525 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.843..4.844 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.333..2.779 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=402
 Planning Time: 10.243 ms
 Execution Time: 587.009 ms
(52 rows)
```

### PG Combined Run 2:
```text
SET
RESET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89334.27..91374.23 rows=17899 width=212) (actual time=472.199..481.257 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12518 read=51880
   I/O Timings: shared read=359.780
   ->  Sort  (cost=88334.26..88360.58 rows=10529 width=212) (actual time=433.095..433.417 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 166kB
         Buffers: shared hit=12518 read=51880
         I/O Timings: shared read=359.780
         Worker 0:  Sort Method: quicksort  Memory: 2981kB
         ->  Parallel Hash Right Join  (cost=85306.54..87630.81 rows=10529 width=212) (actual time=405.885..416.395 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12503 read=51880
               I/O Timings: shared read=359.780
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.009..2.720 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85213.31..85213.31 rows=7458 width=165) (actual time=405.677..405.680 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=10948 read=51880
                     I/O Timings: shared read=359.780
                     ->  Hash Join  (cost=9572.39..85213.31 rows=7458 width=165) (actual time=9.165..402.728 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=10948 read=51880
                           I/O Timings: shared read=359.780
                           ->  Parallel Hash Join  (cost=8891.91..84513.25 rows=7458 width=144) (actual time=4.301..396.296 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=10114 read=51880
                                 I/O Timings: shared read=359.780
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.164..256.226 rows=1498485.00 loops=2)
                                       Buffers: shared hit=7976 read=51880
                                       I/O Timings: shared read=359.780
                                 ->  Parallel Hash  (cost=8868.49..8868.49 rows=1874 width=100) (actual time=3.113..3.114 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=249.17..8868.49 rows=1874 width=100) (actual time=0.987..5.463 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..248.38 rows=3186 width=0) (actual time=0.765..0.765 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.827..4.827 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.318..2.560 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=402
 Planning Time: 5.089 ms
 Execution Time: 481.796 ms
(52 rows)
```

### PG Combined Run 3:
```text
SET
RESET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89334.27..91374.23 rows=17899 width=212) (actual time=541.038..548.430 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12706 read=51692
   I/O Timings: shared read=410.914
   ->  Sort  (cost=88334.26..88360.58 rows=10529 width=212) (actual time=497.944..498.296 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3003kB
         Buffers: shared hit=12706 read=51692
         I/O Timings: shared read=410.914
         Worker 0:  Sort Method: quicksort  Memory: 144kB
         ->  Parallel Hash Right Join  (cost=85306.54..87630.81 rows=10529 width=212) (actual time=471.180..481.176 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12691 read=51692
               I/O Timings: shared read=410.914
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.012..2.519 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85213.31..85213.31 rows=7458 width=165) (actual time=471.012..471.016 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=11136 read=51692
                     I/O Timings: shared read=410.914
                     ->  Hash Join  (cost=9572.39..85213.31 rows=7458 width=165) (actual time=10.187..467.609 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=11136 read=51692
                           I/O Timings: shared read=410.914
                           ->  Parallel Hash Join  (cost=8891.91..84513.25 rows=7458 width=144) (actual time=5.999..461.521 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=10302 read=51692
                                 I/O Timings: shared read=410.914
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.143..295.103 rows=1498485.00 loops=2)
                                       Buffers: shared hit=8164 read=51692
                                       I/O Timings: shared read=410.914
                                 ->  Parallel Hash  (cost=8868.49..8868.49 rows=1874 width=100) (actual time=3.912..3.913 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=249.17..8868.49 rows=1874 width=100) (actual time=0.711..6.533 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..248.38 rows=3186 width=0) (actual time=0.508..0.508 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.147..4.147 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.280..2.370 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=402
 Planning Time: 5.680 ms
 Execution Time: 549.419 ms
(52 rows)
```

### PG Combined Run 4:
```text
SET
RESET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89334.27..91374.23 rows=17899 width=212) (actual time=1023.893..1033.422 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=12894 read=51504
   I/O Timings: shared read=1324.972
   ->  Sort  (cost=88334.26..88360.58 rows=10529 width=212) (actual time=984.022..984.368 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 167kB
         Buffers: shared hit=12894 read=51504
         I/O Timings: shared read=1324.972
         Worker 0:  Sort Method: quicksort  Memory: 2981kB
         ->  Parallel Hash Right Join  (cost=85306.54..87630.81 rows=10529 width=212) (actual time=958.064..968.726 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=12879 read=51504
               I/O Timings: shared read=1324.972
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.006..2.830 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85213.31..85213.31 rows=7458 width=165) (actual time=957.923..957.928 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3104kB
                     Buffers: shared hit=11324 read=51504
                     I/O Timings: shared read=1324.972
                     ->  Hash Join  (cost=9572.39..85213.31 rows=7458 width=165) (actual time=7.941..953.841 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=11324 read=51504
                           I/O Timings: shared read=1324.972
                           ->  Parallel Hash Join  (cost=8891.91..84513.25 rows=7458 width=144) (actual time=3.637..947.199 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=10490 read=51504
                                 I/O Timings: shared read=1324.972
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=0.105..765.186 rows=1498485.00 loops=2)
                                       Buffers: shared hit=8352 read=51504
                                       I/O Timings: shared read=1324.972
                                 ->  Parallel Hash  (cost=8868.49..8868.49 rows=1874 width=100) (actual time=2.846..2.847 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=249.17..8868.49 rows=1874 width=100) (actual time=0.692..4.976 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..248.38 rows=3186 width=0) (actual time=0.493..0.493 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.259..4.260 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.304..2.427 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=402
 Planning Time: 6.205 ms
 Execution Time: 1033.980 ms
(52 rows)
```

### PG Combined Run 5:
```text
SET
RESET
                                                                                                                    QUERY PLAN                                                                                                                    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Gather Merge  (cost=89334.27..91374.23 rows=17899 width=212) (actual time=486.065..493.099 rows=12910.00 loops=1)
   Workers Planned: 1
   Workers Launched: 1
   Buffers: shared hit=13082 read=51316
   I/O Timings: shared read=253.551
   ->  Sort  (cost=88334.26..88360.58 rows=10529 width=212) (actual time=386.879..387.204 rows=6455.00 loops=2)
         Sort Key: p.id, encounters.start, encounters.id, o.code
         Sort Method: quicksort  Memory: 3007kB
         Buffers: shared hit=13082 read=51316
         I/O Timings: shared read=253.551
         Worker 0:  Sort Method: quicksort  Memory: 141kB
         ->  Parallel Hash Right Join  (cost=85306.54..87630.81 rows=10529 width=212) (actual time=359.249..369.361 rows=6455.00 loops=2)
               Hash Cond: ((c.encounter)::text = (encounters.id)::text)
               Buffers: shared hit=13067 read=51316
               I/O Timings: shared read=253.551
               ->  Parallel Seq Scan on conditions c  (cost=0.00..2044.71 rows=49271 width=71) (actual time=0.010..2.497 rows=41880.00 loops=2)
                     Buffers: shared hit=1552
               ->  Parallel Hash  (cost=85213.31..85213.31 rows=7458 width=165) (actual time=358.925..358.930 rows=6455.00 loops=2)
                     Buckets: 32768  Batches: 1  Memory Usage: 3072kB
                     Buffers: shared hit=11512 read=51316
                     I/O Timings: shared read=253.551
                     ->  Hash Join  (cost=9572.39..85213.31 rows=7458 width=165) (actual time=12.682..356.087 rows=6455.00 loops=2)
                           Hash Cond: ((encounters.patient)::text = (p.id)::text)
                           Buffers: shared hit=11512 read=51316
                           I/O Timings: shared read=253.551
                           ->  Parallel Hash Join  (cost=8891.91..84513.25 rows=7458 width=144) (actual time=7.674..349.511 rows=6455.00 loops=2)
                                 Hash Cond: ((o.encounter)::text = (encounters.id)::text)
                                 Buffers: shared hit=10678 read=51316
                                 I/O Timings: shared read=253.551
                                 ->  Parallel Seq Scan on observations o  (cost=0.00..72343.38 rows=1248738 width=81) (actual time=1.463..205.053 rows=1498485.00 loops=2)
                                       Buffers: shared hit=8540 read=51316
                                       I/O Timings: shared read=253.551
                                 ->  Parallel Hash  (cost=8868.49..8868.49 rows=1874 width=100) (actual time=3.678..3.679 rows=1920.00 loops=2)
                                       Buckets: 4096  Batches: 1  Memory Usage: 576kB
                                       Buffers: shared hit=2138
                                       ->  Parallel Bitmap Heap Scan on encounters  (cost=249.17..8868.49 rows=1874 width=100) (actual time=0.694..6.226 rows=3840.00 loops=1)
                                             Recheck Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                             Heap Blocks: exact=2073
                                             Buffers: shared hit=2138
                                             ->  Bitmap Index Scan on idx_q1_enc_class_start  (cost=0.00..248.38 rows=3186 width=0) (actual time=0.497..0.497 rows=3840.00 loops=1)
                                                   Index Cond: (((encounterclass)::text = 'ambulatory'::text) AND (start >= '2020-01-01 00:00:00'::timestamp without time zone) AND (start < '2021-01-01 00:00:00'::timestamp without time zone))
                                                   Index Searches: 1
                                                   Buffers: shared hit=65
                           ->  Hash  (cost=534.10..534.10 rows=11710 width=58) (actual time=4.963..4.963 rows=11710.00 loops=2)
                                 Buckets: 16384  Batches: 1  Memory Usage: 1174kB
                                 Buffers: shared hit=834
                                 ->  Seq Scan on patients p  (cost=0.00..534.10 rows=11710 width=58) (actual time=0.815..3.028 rows=11710.00 loops=2)
                                       Buffers: shared hit=834
 Planning:
   Buffers: shared hit=402
 Planning Time: 5.689 ms
 Execution Time: 493.790 ms
(52 rows)
```

### PG Combined Index Usage:
```text
pg_stat_force_next_flush 
--------------------------
 
(1 row)

  table_name  |       index_name        | idx_scan 
--------------+-------------------------+----------
 conditions   | idx_q1_cond_enc_patient |       12
 encounters   | idx_q1_enc_class_start  |        6
 observations | idx_q1_obs_enc_patient  |       12
(3 rows)
```

## 10. Q1_05_combined_mysql.sql (Check + Equiv + Setup + TRUNCATE perf_schema + 5 lần EXPLAIN + COUNT_READ + Reset)

### MySQL Combined Check, Equivalence, Setup & Truncate Perf Schema:
```text
n_baseline	n_rewrite
12910	12910
TABLE_NAME	INDEX_NAME	size_kb
conditions	idx_q1_cond_enc_patient	8768
encounters	idx_q1_enc_class_start	58192
observations	idx_q1_obs_enc_patient	283632
```

### MySQL Combined Run 1:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=3965..3976 rows=12910 loops=1)
    -> Stream results  (cost=125943 rows=102423) (actual time=26.6..3858 rows=12910 loops=1)
        -> Nested loop inner join  (cost=125943 rows=102423) (actual time=26.6..3739 rows=12910 loops=1)
            -> Nested loop left join  (cost=13277 rows=7770) (actual time=26..2126 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10558 rows=7276) (actual time=26..1869 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7985 rows=7276) (actual time=25.9..1739 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.254 rows=1) (actual time=0.0312..0.0313 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.267 rows=1.07) (actual time=0.063..0.0658 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=13.2 rows=13.2) (actual time=0.353..0.405 rows=3.26 loops=3960)
```

### MySQL Combined Run 2:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=4270..4280 rows=12910 loops=1)
    -> Stream results  (cost=125810 rows=102423) (actual time=24.1..4169 rows=12910 loops=1)
        -> Nested loop inner join  (cost=125810 rows=102423) (actual time=24.1..4060 rows=12910 loops=1)
            -> Nested loop left join  (cost=13145 rows=7770) (actual time=23.2..2338 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10426 rows=7276) (actual time=23.2..2125 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7879 rows=7276) (actual time=23.1..2003 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.25 rows=1) (actual time=0.0302..0.0303 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.267 rows=1.07) (actual time=0.0513..0.0541 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=13.2 rows=13.2) (actual time=0.378..0.432 rows=3.26 loops=3960)
```

### MySQL Combined Run 3:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=3982..3996 rows=12910 loops=1)
    -> Stream results  (cost=125783 rows=102423) (actual time=21.3..3868 rows=12910 loops=1)
        -> Nested loop inner join  (cost=125783 rows=102423) (actual time=21.2..3737 rows=12910 loops=1)
            -> Nested loop left join  (cost=13118 rows=7770) (actual time=20.5..2038 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10398 rows=7276) (actual time=20.4..1839 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7852 rows=7276) (actual time=20.3..1714 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.25 rows=1) (actual time=0.0299..0.0301 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.267 rows=1.07) (actual time=0.0485..0.0507 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=13.2 rows=13.2) (actual time=0.367..0.426 rows=3.26 loops=3960)
```

### MySQL Combined Run 4:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=3942..3956 rows=12910 loops=1)
    -> Stream results  (cost=125778 rows=102423) (actual time=22.8..3834 rows=12910 loops=1)
        -> Nested loop inner join  (cost=125778 rows=102423) (actual time=22.7..3726 rows=12910 loops=1)
            -> Nested loop left join  (cost=13113 rows=7770) (actual time=21.4..2082 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10393 rows=7276) (actual time=21.3..1883 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7847 rows=7276) (actual time=21.2..1765 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.25 rows=1) (actual time=0.0294..0.0295 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.267 rows=1.07) (actual time=0.0483..0.0507 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=13.2 rows=13.2) (actual time=0.356..0.412 rows=3.26 loops=3960)
```

### MySQL Combined Run 5:
```text
EXPLAIN
-> Sort: p.id, e.encounter_start, e.encounter_id, o.`code`  (actual time=3873..3883 rows=12910 loops=1)
    -> Stream results  (cost=125773 rows=102423) (actual time=25.1..3766 rows=12910 loops=1)
        -> Nested loop inner join  (cost=125773 rows=102423) (actual time=25.1..3662 rows=12910 loops=1)
            -> Nested loop left join  (cost=13107 rows=7770) (actual time=24.3..2087 rows=3960 loops=1)
                -> Nested loop inner join  (cost=10388 rows=7276) (actual time=24.2..1898 rows=3840 loops=1)
                    -> Index range scan on encounters using idx_q1_enc_class_start over (encounterclass = 'ambulatory' AND '2020-01-01 00:00:00' <= start < '2021-01-01 00:00:00'), with index condition: (((encounters.encounterclass = 'ambulatory') and (encounters.`start` >= TIMESTAMP'2020-01-01 00:00:00') and (encounters.`start` < TIMESTAMP'2021-01-01 00:00:00')) and (encounters.patient is not null))  (cost=7841 rows=7276) (actual time=24.1..1789 rows=3840 loops=1)
                    -> Single-row index lookup on p using PRIMARY (id = encounters.patient)  (cost=0.25 rows=1) (actual time=0.0271..0.0273 rows=1 loops=3840)
                -> Index lookup on c using idx_q1_cond_enc_patient (encounter = encounters.id)  (cost=0.267 rows=1.07) (actual time=0.0456..0.0481 rows=0.354 loops=3840)
            -> Index lookup on o using idx_q1_obs_enc_patient (encounter = encounters.id)  (cost=13.2 rows=13.2) (actual time=0.34..0.394 rows=3.26 loops=3960)
```

### MySQL Combined Index Usage (Clean Count):
```text
table_name	INDEX_NAME	COUNT_READ
conditions	idx_q1_cond_enc_patient	31200
encounters	idx_q1_enc_class_start	23046
observations	idx_q1_obs_enc_patient	93480
```
