-- Q1 | PostgreSQL 18 | index setup
-- Nguồn: claude_step1/Q1_03_indexes_pg.sql (giữ nguyên câu lệnh tạo index).
-- Không chạy ANALYZE sau khi tạo index để không lẫn với kỹ thuật Statistics.

CREATE INDEX idx_q1_enc_class_start ON encounters (encounterclass, start, id, patient);
CREATE INDEX idx_q1_obs_enc_patient ON observations (encounter, patient);
CREATE INDEX idx_q1_cond_enc_patient ON conditions (encounter, patient);

-- Kích thước index (chi phí lưu trữ ΔD)
SELECT indexrelid::regclass AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index
WHERE indexrelid::regclass::text LIKE 'idx_q1_%';
