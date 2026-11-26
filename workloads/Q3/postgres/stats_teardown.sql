-- Q3 Statistics Teardown (PostgreSQL)
-- Xóa thống kê đa biến của Q3 để reset về Baseline

DROP STATISTICS IF EXISTS stat_obs_enc_pat;
DROP STATISTICS IF EXISTS stat_enc_start_class;

ANALYZE observations;
ANALYZE encounters;
