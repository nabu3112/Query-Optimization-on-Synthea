-- Q1 | MySQL 9.4 | statistics setup
-- Nguồn: claude_step1/Q1_04_stats_mysql.sql (giữ nguyên câu lệnh thống kê & histogram).

ALTER TABLE encounters   STATS_SAMPLE_PAGES = 200;
ALTER TABLE observations STATS_SAMPLE_PAGES = 200;
ALTER TABLE conditions   STATS_SAMPLE_PAGES = 200;
ALTER TABLE patients     STATS_SAMPLE_PAGES = 200;

ANALYZE TABLE patients, encounters, conditions, observations;

ANALYZE TABLE encounters UPDATE HISTOGRAM ON encounterclass, start WITH 100 BUCKETS;

SELECT COLUMN_NAME,
       JSON_EXTRACT(HISTOGRAM, '$."histogram-type"') AS hist_type,
       JSON_EXTRACT(HISTOGRAM, '$."number-of-buckets-specified"') AS buckets
FROM information_schema.COLUMN_STATISTICS
WHERE SCHEMA_NAME = DATABASE() AND TABLE_NAME = 'encounters';
