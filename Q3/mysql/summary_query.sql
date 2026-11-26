-- Q3 Summary Table Query (MySQL 8.0)
-- Đo hiệu năng truy vấn đọc trực tiếp từ Bảng tổng hợp
USE synthea_db;

-- 1. Toàn bộ báo cáo định kỳ
EXPLAIN ANALYZE
SELECT *
FROM summary_q3_monthly_report
ORDER BY report_year, report_month, encounterclass;

-- 2. Lọc báo cáo theo năm và loại hình khám
EXPLAIN ANALYZE
SELECT *
FROM summary_q3_monthly_report
WHERE report_year = 2019 AND encounterclass = 'ambulatory'
ORDER BY report_month;
