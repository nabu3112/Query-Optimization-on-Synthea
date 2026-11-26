-- Q3 Materialized View Query (PostgreSQL)
-- Đo hiệu năng truy vấn đọc trực tiếp từ Materialized View

-- 1. Toàn bộ báo cáo định kỳ
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM mv_q3_monthly_report
ORDER BY report_year, report_month, encounterclass;

-- 2. Lọc báo cáo theo năm và loại hình khám
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM mv_q3_monthly_report
WHERE report_year = 2019 AND encounterclass = 'ambulatory'
ORDER BY report_month;
