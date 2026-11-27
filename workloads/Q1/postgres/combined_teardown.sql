-- Q1 | PostgreSQL 18 | combined teardown
-- Nguồn: claude_step1/Q1_05_combined_pg.sql

DROP INDEX IF EXISTS idx_q1_enc_class_start;
DROP INDEX IF EXISTS idx_q1_obs_enc_patient;
DROP INDEX IF EXISTS idx_q1_cond_enc_patient;
RESET enable_seqscan;
