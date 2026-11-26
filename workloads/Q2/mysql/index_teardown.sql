-- Q2 | MySQL 8.4 | index teardown
-- Drops only the indexes created by index_setup.sql.
-- MySQL has no DROP INDEX IF EXISTS, so each drop checks information_schema first. Safe to re-run.

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
