-- Q3 Query Rewrite (MySQL 8.0)
-- Kỹ thuật: Pre-aggregation bảng observations trước khi LEFT JOIN + DATE_FORMAT + bỏ DISTINCT trên e.id
USE synthea_db;

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
