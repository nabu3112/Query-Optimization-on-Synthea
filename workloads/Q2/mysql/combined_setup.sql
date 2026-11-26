-- Q2 | MySQL 8.4 | combined setup
-- Indexes + histograms selected for Q2. Adjust after the single-technique results.
-- Run combined_teardown.sql first if re-running.
-- Then run rewrite.sql (NOT baseline.sql) to measure the combination.

CREATE INDEX idx_q2_enc_class_reason ON encounters (encounterclass, reasoncode);
CREATE INDEX idx_q2_cond_stop_enc ON conditions (`stop`, encounter);

ANALYZE TABLE encounters UPDATE HISTOGRAM ON encounterclass, reasoncode WITH 100 BUCKETS;
ANALYZE TABLE conditions UPDATE HISTOGRAM ON `stop` WITH 10 BUCKETS;

-- Size of the new indexes in bytes (size-increase measure).
SELECT table_name, index_name, stat_value * @@innodb_page_size AS size_bytes
FROM mysql.innodb_index_stats
WHERE database_name = DATABASE() AND stat_name = 'size' AND index_name LIKE 'idx_q2_%'
ORDER BY table_name, index_name;
