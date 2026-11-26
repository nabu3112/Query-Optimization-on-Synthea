-- Q3 Baseline (PostgreSQL)
-- Chạy trực tiếp để đo thời gian và kế hoạch thực thi cơ sở

EXPLAIN (ANALYZE, BUFFERS)
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
    e.encounterclass
ORDER BY
    report_year,
    report_month,
    e.encounterclass;
