-- =====================================================================
-- Q3 - BƯỚC C: KẾT HỢP CÁC KỸ THUẬT (COMBINED OPTIMIZATION)
-- Tổ hợp chọn:
--   - PostgreSQL: Materialized View + Index trên chính Materialized View
--   - MySQL 8.0 : Bảng tổng hợp (Summary Table) + Index trên bảng tổng hợp
-- =====================================================================

-- =====================================================================
-- PHẦN 1: POSTGRESQL (MATERIALIZED VIEW + INDEX)
-- =====================================================================

-- 1.1. Tạo Materialized View lưu sẵn kết quả tổng hợp
DROP MATERIALIZED VIEW IF EXISTS mv_q3_monthly_report;

CREATE MATERIALIZED VIEW mv_q3_monthly_report AS
SELECT
    EXTRACT(YEAR FROM e.start)::INT AS report_year,
    EXTRACT(MONTH FROM e.start)::INT AS report_month,
    e.encounterclass,
    COUNT(DISTINCT e.id) AS total_encounters,
    COUNT(DISTINCT e.patient) AS unique_patients,
    COUNT(o.code) AS total_observations,
    CAST(SUM(e.total_claim_cost) AS DECIMAL(16, 2)) AS total_claim_cost
FROM encounters e
LEFT JOIN observations o
    ON o.encounter = e.id AND o.patient = e.patient
GROUP BY
    EXTRACT(YEAR FROM e.start),
    EXTRACT(MONTH FROM e.start),
    e.encounterclass;

-- 1.2. Đánh chỉ mục trực tiếp lên các cột nhóm/lọc/sắp xếp của Materialized View
CREATE UNIQUE INDEX idx_mv_q3_pk
ON mv_q3_monthly_report (report_year, report_month, encounterclass);

ANALYZE mv_q3_monthly_report;

-- 1.3. Đo thời gian truy vấn báo cáo khi khai thác từ Materialized View
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM mv_q3_monthly_report
ORDER BY report_year, report_month, encounterclass;

-- Thử nghiệm lọc theo năm & loại hình khám (tận dụng Index trên MV):
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM mv_q3_monthly_report
WHERE report_year = 2019 AND encounterclass = 'ambulatory'
ORDER BY report_month;

-- Lệnh làm mới dữ liệu định kỳ khi bảng gốc có biến động:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_q3_monthly_report;


-- =====================================================================
-- PHẦN 2: MYSQL 8.0 (BẢNG TỔNG HỢP + INDEX)
-- (MySQL không hỗ trợ Materialized View native nên dùng Summary Table)
-- =====================================================================

-- 2.1. Tạo bảng tổng hợp kèm Khóa chính (Clustered Index trong InnoDB)
DROP TABLE IF EXISTS summary_q3_monthly_report;

CREATE TABLE summary_q3_monthly_report (
    report_year INT NOT NULL,
    report_month INT NOT NULL,
    encounterclass VARCHAR(50) NOT NULL,
    total_encounters BIGINT,
    unique_patients BIGINT,
    total_observations BIGINT,
    total_claim_cost DECIMAL(16, 2),
    PRIMARY KEY (report_year, report_month, encounterclass)
) ENGINE=InnoDB;

-- 2.2. Nạp dữ liệu tổng hợp vào bảng
INSERT INTO summary_q3_monthly_report
SELECT
    EXTRACT(YEAR FROM e.start) AS report_year,
    EXTRACT(MONTH FROM e.start) AS report_month,
    e.encounterclass,
    COUNT(DISTINCT e.id) AS total_encounters,
    COUNT(DISTINCT e.patient) AS unique_patients,
    COUNT(o.code) AS total_observations,
    CAST(SUM(e.total_claim_cost) AS DECIMAL(16, 2)) AS total_claim_cost
FROM encounters e
LEFT JOIN observations o
    ON o.encounter = e.id AND o.patient = e.patient
GROUP BY
    EXTRACT(YEAR FROM e.start),
    EXTRACT(MONTH FROM e.start),
    e.encounterclass;

ANALYZE TABLE summary_q3_monthly_report;

-- 2.3. Đo thời gian truy vấn báo cáo khi khai thác từ bảng tổng hợp
EXPLAIN ANALYZE
SELECT *
FROM summary_q3_monthly_report
ORDER BY report_year, report_month, encounterclass;

-- Thử nghiệm lọc theo năm & loại hình khám (tận dụng Clustered Index):
EXPLAIN ANALYZE
SELECT *
FROM summary_q3_monthly_report
WHERE report_year = 2019 AND encounterclass = 'ambulatory'
ORDER BY report_month;

-- (Tùy chọn) Tạo Stored Procedure làm mới bảng tổng hợp định kỳ hàng tháng:
DELIMITER //
CREATE PROCEDURE sp_refresh_q3_summary()
BEGIN
    TRUNCATE TABLE summary_q3_monthly_report;
    INSERT INTO summary_q3_monthly_report
    SELECT
        EXTRACT(YEAR FROM e.start),
        EXTRACT(MONTH FROM e.start),
        e.encounterclass,
        COUNT(DISTINCT e.id),
        COUNT(DISTINCT e.patient),
        COUNT(o.code),
        CAST(SUM(e.total_claim_cost) AS DECIMAL(16, 2))
    FROM encounters e
    LEFT JOIN observations o
        ON o.encounter = e.id AND o.patient = e.patient
    GROUP BY
        EXTRACT(YEAR FROM e.start),
        EXTRACT(MONTH FROM e.start),
        e.encounterclass;
END //
DELIMITER ;
