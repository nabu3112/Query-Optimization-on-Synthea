-- Q3 Index Teardown (MySQL 8.0)
-- Xóa Index của Q3 để reset về Baseline
USE synthea_db;

DROP INDEX idx_obs_enc_pat_code ON observations;
DROP INDEX idx_enc_start_class_cov ON encounters;
