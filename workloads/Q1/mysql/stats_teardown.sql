-- Q1 | MySQL 9.4 | statistics teardown
-- Nguồn: claude_step1/Q1_04_stats_mysql.sql (khôi phục thống kê mặc định).

ANALYZE TABLE encounters DROP HISTOGRAM ON encounterclass, start;
ALTER TABLE encounters   STATS_SAMPLE_PAGES = DEFAULT;
ALTER TABLE observations STATS_SAMPLE_PAGES = DEFAULT;
ALTER TABLE conditions   STATS_SAMPLE_PAGES = DEFAULT;
ALTER TABLE patients     STATS_SAMPLE_PAGES = DEFAULT;
ANALYZE TABLE patients, encounters, conditions, observations;
