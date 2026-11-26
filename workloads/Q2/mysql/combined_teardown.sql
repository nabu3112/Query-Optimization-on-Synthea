-- Q2 | MySQL 8.4 | combined teardown
-- Removes every index and histogram created for Q2. Run before moving to the next workload.

SET @sql = (SELECT IF(COUNT(*) > 0,
    'DROP INDEX idx_q2_enc_class_reason ON encounters',
    'SELECT ''index idx_q2_enc_class_reason not found'' AS info')
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'encounters' AND index_name = 'idx_q2_enc_class_reason');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(COUNT(*) > 0,
    'DROP INDEX idx_q2_cond_stop_enc ON conditions',
    'SELECT ''index idx_q2_cond_stop_enc not found'' AS info')
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'conditions' AND index_name = 'idx_q2_cond_stop_enc');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ANALYZE TABLE encounters DROP HISTOGRAM ON encounterclass, reasoncode;
ANALYZE TABLE conditions DROP HISTOGRAM ON `stop`;
