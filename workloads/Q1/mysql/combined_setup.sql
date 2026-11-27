-- Q1 | MySQL 9.4 | combined setup
-- Nguồn: claude_step1/Q1_05_combined_mysql.sql (Tổ hợp: Viết lại 02a + 3 index Q1).
-- KHÔNG chạy ANALYZE TABLE / histogram / STATS_SAMPLE_PAGES để giữ thống kê mặc định.
-- Sau khi chạy file này, chạy rewrite.sql để đo phương án tổ hợp.

SET SESSION optimizer_switch = 'derived_merge=on';

CREATE INDEX idx_q1_enc_class_start  ON encounters   (encounterclass, start, patient);
CREATE INDEX idx_q1_obs_enc_patient  ON observations (encounter, patient);
CREATE INDEX idx_q1_cond_enc_patient ON conditions   (encounter, patient);

SELECT TABLE_NAME, INDEX_NAME,
       ROUND(stat_value * @@innodb_page_size / 1024) AS size_kb
FROM mysql.innodb_index_stats
WHERE database_name = DATABASE()
  AND stat_name = 'size'
  AND INDEX_NAME LIKE 'idx_q1_%';
