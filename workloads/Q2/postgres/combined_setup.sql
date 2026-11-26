-- Q2 | PostgreSQL 18 | combined setup
-- Indexes + statistics selected for Q2. Adjust after the single-technique results.
-- Run combined_teardown.sql first if re-running.
-- Then run rewrite.sql (NOT baseline.sql) to measure the combination.

CREATE INDEX IF NOT EXISTS idx_q2_enc_class_reason
    ON encounters (encounterclass, reasoncode);

CREATE INDEX IF NOT EXISTS idx_q2_cond_active
    ON conditions (encounter, patient)
    WHERE stop IS NULL;

CREATE STATISTICS IF NOT EXISTS st_q2_enc_class_reason (mcv)
    ON encounterclass, reasoncode
    FROM encounters;

ANALYZE encounters;

-- Size of the new indexes (size-increase measure)
SELECT indexname,
       pg_size_pretty(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname))) AS size
FROM pg_indexes
WHERE indexname LIKE 'idx_q2_%'
ORDER BY indexname;
