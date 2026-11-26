-- Q2 | PostgreSQL 18 | index teardown
-- Drops only the indexes created by index_setup.sql. Safe to re-run.

DROP INDEX IF EXISTS idx_q2_enc_class_reason;
DROP INDEX IF EXISTS idx_q2_cond_active;
