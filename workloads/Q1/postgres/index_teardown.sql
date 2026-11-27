-- Q1 | PostgreSQL 18 | index teardown
-- Xóa các index Q1 và khôi phục tham số phiên.

DROP INDEX IF EXISTS idx_q1_enc_class_start;
DROP INDEX IF EXISTS idx_q1_obs_enc_patient;
DROP INDEX IF EXISTS idx_q1_cond_enc_patient;
RESET enable_seqscan;
