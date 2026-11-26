-- Q3 Index Setup (MySQL 8.0)
-- Tạo Covering Index cho observations và encounters
USE synthea_db;

CREATE INDEX idx_obs_enc_pat_code
ON observations (encounter, patient, code);

CREATE INDEX idx_enc_start_class_cov
ON encounters (start, encounterclass, id, patient, total_claim_cost);

ANALYZE TABLE observations, encounters;
