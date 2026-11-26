-- Q3 Statistics Teardown (MySQL 8.0)
-- Xóa Histogram của Q3 để reset về Baseline
USE synthea_db;

ANALYZE TABLE encounters DROP HISTOGRAM ON start, encounterclass;
ANALYZE TABLE observations DROP HISTOGRAM ON encounter, patient;
