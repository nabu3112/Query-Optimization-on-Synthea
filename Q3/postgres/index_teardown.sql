-- Q3 Index Teardown (PostgreSQL)
-- Xóa Index của Q3 để reset về Baseline

DROP INDEX IF EXISTS idx_obs_enc_pat_inc_code;
DROP INDEX IF EXISTS idx_enc_start_class_inc;
