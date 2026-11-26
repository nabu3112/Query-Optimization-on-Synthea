-- Q2 | MySQL 8.4 | index setup
-- Run index_teardown.sql first if re-running (MySQL has no CREATE INDEX IF NOT EXISTS).
-- Then run baseline.sql, then rewrite.sql, and compare the plans.
-- Note: the dump already has foreign-key indexes (e.g. conditions.encounter, conditions.patient).

CREATE INDEX idx_q2_enc_class_reason ON encounters (encounterclass, reasoncode);
CREATE INDEX idx_q2_cond_stop_enc ON conditions (`stop`, encounter);

-- Size of the new indexes in bytes (size-increase measure).
-- If the rows are missing, run ANALYZE TABLE on the table first (this refreshes index statistics).
SELECT table_name, index_name, stat_value * @@innodb_page_size AS size_bytes
FROM mysql.innodb_index_stats
WHERE database_name = DATABASE() AND stat_name = 'size' AND index_name LIKE 'idx_q2_%'
ORDER BY table_name, index_name;
