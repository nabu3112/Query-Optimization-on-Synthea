-- Q3 Query Rewrite (PostgreSQL)
-- Kỹ thuật: Pre-aggregation bảng observations trước khi LEFT JOIN + DATE_TRUNC + bỏ DISTINCT trên e.id

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
