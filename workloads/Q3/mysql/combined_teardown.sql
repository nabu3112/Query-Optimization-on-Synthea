-- Q3 Combined Teardown (MySQL 8.0)
-- Xóa Bảng tổng hợp kèm Index của Q3 để reset về Baseline
USE synthea_db;

DROP TABLE IF EXISTS summary_q3_monthly_report;
