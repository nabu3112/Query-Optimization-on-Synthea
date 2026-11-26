-- Q2 | MySQL 8.4 | statistics setup
-- Histograms are per column: they improve single-column estimates but cannot model the
-- correlation between encounterclass and reasoncode (compare with PostgreSQL extended statistics).
-- Run stats_teardown.sql first if re-running. Then run baseline.sql with EXPLAIN ANALYZE.

ANALYZE TABLE encounters UPDATE HISTOGRAM ON encounterclass, reasoncode WITH 100 BUCKETS;
ANALYZE TABLE conditions UPDATE HISTOGRAM ON `stop` WITH 10 BUCKETS;

-- Check the histograms
-- SELECT table_name, column_name FROM information_schema.column_statistics WHERE schema_name = DATABASE();
