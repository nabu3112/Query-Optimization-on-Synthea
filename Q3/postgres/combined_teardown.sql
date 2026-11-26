-- Q3 Combined Teardown (PostgreSQL)
-- Xóa Index và Materialized View của Q3 để reset về Baseline

DROP INDEX IF EXISTS idx_mv_q3_pk;
DROP MATERIALIZED VIEW IF EXISTS mv_q3_monthly_report;
