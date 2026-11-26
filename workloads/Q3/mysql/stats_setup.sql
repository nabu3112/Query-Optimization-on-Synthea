-- Q3 Statistics Setup (MySQL 8.0)
-- Cập nhật thống kê và tạo Histogram 100 buckets cho các cột lọc/nhóm/nối
USE synthea_db;

ANALYZE TABLE encounters, observations;

ANALYZE TABLE encounters UPDATE HISTOGRAM ON start, encounterclass WITH 100 BUCKETS;
ANALYZE TABLE observations UPDATE HISTOGRAM ON encounter, patient WITH 100 BUCKETS;
