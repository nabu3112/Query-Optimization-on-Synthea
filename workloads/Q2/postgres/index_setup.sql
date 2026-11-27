CREATE INDEX IF NOT EXISTS idx_q2_enc_cover
    ON encounters (encounterclass, reasoncode)
    INCLUDE (id, patient);

CREATE INDEX IF NOT EXISTS idx_q2_cond_active
    ON conditions (encounter, patient)
    WHERE stop IS NULL;

VACUUM (ANALYZE) encounters;
VACUUM (ANALYZE) conditions;

SELECT
    indexname,
    pg_relation_size(format('%I.%I', schemaname, indexname)) AS size_bytes,
    pg_size_pretty(
        pg_relation_size(format('%I.%I', schemaname, indexname))
    ) AS size
FROM pg_indexes
WHERE schemaname = current_schema()
  AND indexname IN ('idx_q2_enc_cover', 'idx_q2_cond_active')
ORDER BY indexname;
