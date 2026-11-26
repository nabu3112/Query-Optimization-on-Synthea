-- Q2 | PostgreSQL 18 | statistics setup
-- Run stats_teardown.sql first if re-running.
-- Multi-column statistics on encounters: reasoncode depends strongly on encounterclass.
-- Then run baseline.sql with EXPLAIN (ANALYZE): compare estimated vs actual rows.
-- Kind used: mcv (the condition reasoncode <> '' is not an equality, which dependencies statistics need).

CREATE STATISTICS IF NOT EXISTS st_q2_enc_class_reason (mcv)
    ON encounterclass, reasoncode
    FROM encounters;

ANALYZE encounters;

-- Check that the statistics object was built
-- SELECT statistics_name, attnames, kinds FROM pg_stats_ext WHERE statistics_name = 'st_q2_enc_class_reason';

-- Optional variants to compare (run teardown between variants):
--   kind (dependencies), or (ndistinct, dependencies, mcv)
--   103 distinct (encounterclass, reasoncode) pairs exist, close to the default MCV capacity (100):
--   ALTER STATISTICS st_q2_enc_class_reason SET STATISTICS 200;
--   ANALYZE encounters;
