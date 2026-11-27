-- Q1 | MySQL 9.4 | index setup
-- Nguồn: claude_step1/Q1_03_indexes_mysql.sql (giữ nguyên câu lệnh tạo index).
-- Lưu ý InnoDB: index phụ tự động chứa khoá chính (id) ở cuối.

CREATE INDEX idx_q1_enc_class_start  ON encounters   (encounterclass, start, patient);
CREATE INDEX idx_q1_obs_enc_patient  ON observations (encounter, patient);
CREATE INDEX idx_q1_cond_enc_patient ON conditions   (encounter, patient);

SELECT TABLE_NAME, INDEX_NAME,
       ROUND(stat_value * @@innodb_page_size / 1024) AS size_kb
FROM mysql.innodb_index_stats
WHERE database_name = DATABASE()
  AND stat_name = 'size'
  AND INDEX_NAME LIKE 'idx_q1_%';
