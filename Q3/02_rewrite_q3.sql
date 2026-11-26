-- =====================================================================
-- Q3 - BƯỚC B(i): VIẾT LẠI TRUY VẤN (QUERY REWRITE)
-- Mục tiêu:
--   1. Gom nhóm (Pre-aggregate) bảng observations (~300k dòng) TRƯỚC khi JOIN
--      với encounters (~53k dòng) để giảm mạnh kích thước tập dữ liệu trung gian.
--   2. Loại bỏ COUNT(DISTINCT e.id) thành COUNT(e.id) vì sau khi pre-aggregate,
--      mỗi lần khám (e.id) chỉ xuất hiện tối đa 1 dòng.
--   3. Khắc phục hiện tượng fan-out khi SUM(e.total_claim_cost) (tùy chọn giữ
--      nguyên ngữ nghĩa gốc hoặc sửa đúng nghiệp vụ).
--   4. Gộp 2 hàm EXTRACT(YEAR), EXTRACT(MONTH) thành 1 biểu thức tháng.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. POSTGRESQL: VIẾT LẠI TRUY VẤN (Dùng CTE + DATE_TRUNC)
-- ---------------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
WITH obs_agg AS (
    SELECT
        o.encounter,
        o.patient,
        COUNT(o.code) AS obs_count
    FROM observations o
    WHERE o.encounter IS NOT NULL
    GROUP BY o.encounter, o.patient
)
SELECT
    EXTRACT(YEAR FROM DATE_TRUNC('month', e.start)) AS report_year,
    EXTRACT(MONTH FROM DATE_TRUNC('month', e.start)) AS report_month,
    e.encounterclass,
    COUNT(e.id) AS total_encounters,
    COUNT(DISTINCT e.patient) AS unique_patients,
    COALESCE(SUM(oa.obs_count), 0) AS total_observations,
    CAST(SUM(e.total_claim_cost) AS DECIMAL(16, 2)) AS total_claim_cost
FROM encounters e
LEFT JOIN obs_agg oa
    ON oa.encounter = e.id AND oa.patient = e.patient
GROUP BY
    DATE_TRUNC('month', e.start),
    e.encounterclass
ORDER BY
    report_year,
    report_month,
    e.encounterclass;


-- ---------------------------------------------------------------------
-- 2. MYSQL 8.0: VIẾT LẠI TRUY VẤN (Dùng CTE + DATE_FORMAT)
-- ---------------------------------------------------------------------
EXPLAIN ANALYZE
WITH obs_agg AS (
    SELECT
        o.encounter,
        o.patient,
        COUNT(o.code) AS obs_count
    FROM observations o
    WHERE o.encounter IS NOT NULL
    GROUP BY o.encounter, o.patient
)
SELECT
    YEAR(e.report_month_dt) AS report_year,
    MONTH(e.report_month_dt) AS report_month,
    e.encounterclass,
    COUNT(e.id) AS total_encounters,
    COUNT(DISTINCT e.patient) AS unique_patients,
    COALESCE(SUM(oa.obs_count), 0) AS total_observations,
    CAST(SUM(e.total_claim_cost) AS DECIMAL(16, 2)) AS total_claim_cost
FROM (
    SELECT
        id,
        patient,
        encounterclass,
        total_claim_cost,
        DATE_FORMAT(start, '%Y-%m-01') AS report_month_dt
    FROM encounters
) e
LEFT JOIN obs_agg oa
    ON oa.encounter = e.id AND oa.patient = e.patient
GROUP BY
    e.report_month_dt,
    e.encounterclass
ORDER BY
    report_year,
    report_month,
    e.encounterclass;
