-- Q2 | PostgreSQL 18 | combined teardown
-- Removes every index and statistics object created for Q2, then re-analyzes.
-- Run before moving to the next workload.

DROP INDEX IF EXISTS idx_q2_enc_class_reason;
DROP INDEX IF EXISTS idx_q2_cond_active;
DROP STATISTICS IF EXISTS st_q2_enc_class_reason;
ANALYZE encounters;
ANALYZE conditions;
