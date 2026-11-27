-- Q1 | PostgreSQL 18 | combined setup
-- Nguồn: claude_step1/Q1_05_combined_pg.sql (Tổ hợp: Viết lại 02a + 3 index Q1).
-- KHÔNG chạy ANALYZE / SET STATISTICS để giữ thống kê mặc định.
-- Sau khi chạy file này, chạy rewrite.sql để đo phương án tổ hợp.

RESET enable_seqscan;

CREATE INDEX idx_q1_enc_class_start  ON encounters   (encounterclass, start, id, patient);
CREATE INDEX idx_q1_obs_enc_patient  ON observations (encounter, patient);
CREATE INDEX idx_q1_cond_enc_patient ON conditions   (encounter, patient);

SELECT indexrelid::regclass AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index
WHERE indexrelid::regclass::text LIKE 'idx_q1_%';
