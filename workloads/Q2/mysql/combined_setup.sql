CREATE INDEX idx_q2_enc_cover
    ON encounters (encounterclass, reasoncode, patient);

CREATE INDEX idx_q2_cond_active
    ON conditions (stop, encounter, patient);

ANALYZE TABLE encounters, conditions;

ANALYZE TABLE encounters
    UPDATE HISTOGRAM ON encounterclass, reasoncode WITH 100 BUCKETS;

ANALYZE TABLE conditions
    UPDATE HISTOGRAM ON stop WITH 10 BUCKETS;

SELECT
    table_name,
    index_name,
    stat_value * @@innodb_page_size AS size_bytes
FROM mysql.innodb_index_stats
WHERE database_name = DATABASE()
  AND stat_name = 'size'
  AND index_name IN ('idx_q2_enc_cover', 'idx_q2_cond_active')
ORDER BY table_name, index_name;