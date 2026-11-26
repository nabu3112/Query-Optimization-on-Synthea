-- Q3 Combined Setup (PostgreSQL)
-- Tổ hợp: Materialized View + Unique Index trên chính MV

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

-- Đánh Unique Index trên các cột nhóm/lọc/sắp xếp của MV (đồng thời hỗ trợ REFRESH CONCURRENTLY)
CREATE UNIQUE INDEX idx_mv_q3_pk
ON mv_q3_monthly_report (report_year, report_month, encounterclass);

ANALYZE mv_q3_monthly_report;
