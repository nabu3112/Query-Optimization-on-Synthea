-- Q3 Statistics Setup (PostgreSQL)
-- Tạo thống kê đa biến (Extended Statistics) cho các cặp cột có tương quan

CREATE STATISTICS IF NOT EXISTS stat_obs_enc_pat (dependencies, ndistinct)
ON encounter, patient FROM observations;

CREATE STATISTICS IF NOT EXISTS stat_enc_start_class (dependencies, ndistinct)
ON start, encounterclass FROM encounters;

ANALYZE observations;
ANALYZE encounters;
