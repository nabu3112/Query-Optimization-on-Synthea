-- Q2 | PostgreSQL 18 | index setup
-- Run index_teardown.sql first if re-running.
-- Then run baseline.sql (does the planner switch to the new indexes?).
-- Then run rewrite.sql: with '> ''' the composite index on encounters becomes usable.

CREATE INDEX IF NOT EXISTS idx_q2_enc_class_reason
    ON encounters (encounterclass, reasoncode);

CREATE INDEX IF NOT EXISTS idx_q2_cond_active
    ON conditions (encounter, patient)
    WHERE stop IS NULL;

-- Size of the new indexes (size-increase measure)
SELECT indexname,
       pg_size_pretty(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname))) AS size
FROM pg_indexes
WHERE indexname LIKE 'idx_q2_%'
ORDER BY indexname;
