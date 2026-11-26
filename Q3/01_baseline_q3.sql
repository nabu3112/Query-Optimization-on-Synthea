-- =====================================================================
-- Q3 - BƯỚC A: TRUY VẤN GỐC VÀ KẾ HOẠCH CƠ SỞ (BASELINE)
-- Hệ CSDL: PostgreSQL 16/18 & MySQL 8.0
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TRUY VẤN GỐC (Chạy được trên cả PostgreSQL và MySQL)
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- 2. ĐO KẾ HOẠCH THỰC THI BASELINE TRÊN POSTGRESQL
-- (Copy đoạn dưới chạy trong pgAdmin 4 Query Tool)
-- ---------------------------------------------------------------------
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


-- ---------------------------------------------------------------------
-- 3. ĐO KẾ HOẠCH THỰC THI BASELINE TRÊN MYSQL 8.0
-- (Copy đoạn dưới chạy trong MySQL Workbench)
-- ---------------------------------------------------------------------
EXPLAIN ANALYZE
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
