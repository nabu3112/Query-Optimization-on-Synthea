-- Q3 Combined Setup (MySQL 8.0)
-- Tổ hợp: Bảng tổng hợp (Summary Table) + Clustered Index (PRIMARY KEY)
USE synthea_db;

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
