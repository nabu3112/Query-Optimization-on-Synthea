-- Q2 | PostgreSQL 18 | statistics teardown
-- Removes the extended statistics and re-analyzes the table to return to the default state.

DROP STATISTICS IF EXISTS st_q2_enc_class_reason;
ANALYZE encounters;
