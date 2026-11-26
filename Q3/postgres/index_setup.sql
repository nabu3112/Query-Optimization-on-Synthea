-- Q3 Index Setup (PostgreSQL)
-- Tạo Covering Index hỗ trợ Index-Only Scan

CREATE INDEX IF NOT EXISTS idx_obs_enc_pat_inc_code
ON observations (encounter, patient) INCLUDE (code);

CREATE INDEX IF NOT EXISTS idx_enc_start_class_inc
ON encounters (start, encounterclass) INCLUDE (id, patient, total_claim_cost);

ANALYZE observations;
ANALYZE encounters;
