-- Q1 | MySQL 9.4 | index teardown
-- Xóa các index Q1 (kiểm tra information_schema trước khi xóa để chạy lại an toàn).

SET @sql = (SELECT IF(COUNT(*) > 0,
    'DROP INDEX idx_q1_enc_class_start ON encounters',
    'SELECT ''index idx_q1_enc_class_start not found'' AS info')
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'encounters' AND index_name = 'idx_q1_enc_class_start');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(COUNT(*) > 0,
    'DROP INDEX idx_q1_obs_enc_patient ON observations',
    'SELECT ''index idx_q1_obs_enc_patient not found'' AS info')
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'observations' AND index_name = 'idx_q1_obs_enc_patient');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (SELECT IF(COUNT(*) > 0,
    'DROP INDEX idx_q1_cond_enc_patient ON conditions',
    'SELECT ''index idx_q1_cond_enc_patient not found'' AS info')
    FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'conditions' AND index_name = 'idx_q1_cond_enc_patient');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
