SET @sql = (
    SELECT IF(
        COUNT(*) > 0,
        'DROP INDEX idx_q2_enc_cover ON encounters',
        'SELECT ''idx_q2_enc_cover not found'' AS info'
    )
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'encounters'
      AND index_name = 'idx_q2_enc_cover'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = (
    SELECT IF(
        COUNT(*) > 0,
        'DROP INDEX idx_q2_cond_active ON conditions',
        'SELECT ''idx_q2_cond_active not found'' AS info'
    )
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'conditions'
      AND index_name = 'idx_q2_cond_active'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ANALYZE TABLE encounters
    DROP HISTOGRAM ON encounterclass, reasoncode;

ANALYZE TABLE conditions
    DROP HISTOGRAM ON stop;

ANALYZE TABLE encounters, conditions;