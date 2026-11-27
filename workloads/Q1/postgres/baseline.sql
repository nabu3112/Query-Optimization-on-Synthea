-- Q1 | PostgreSQL 18 | baseline
-- Nguồn: claude_step1/Q1_01_baseline_pg.sql (giữ nguyên SQL gốc).
-- Plan:   chạy với EXPLAIN (ANALYZE, BUFFERS, SETTINGS) <truy vấn này>
-- Timing: chạy trực tiếp truy vấn (không EXPLAIN) để đo thời gian.

SELECT
    p.id AS patient_id,
    CONCAT(p.first, ' ', p.last) AS full_name,
    p.gender,
    e.id AS encounter_id,
    e.start AS encounter_start,
    e.encounterclass,
    e.total_claim_cost,
    c.code AS condition_code,
    c.description AS condition_description,
    o.code AS observation_code,
    o.description AS observation_description,
    o.value AS observation_value,
    o.units
FROM patients p
JOIN encounters e
    ON e.patient = p.id
LEFT JOIN conditions c
    ON c.encounter = e.id AND c.patient = p.id
JOIN observations o
    ON o.encounter = e.id AND o.patient = p.id
WHERE e.encounterclass = 'ambulatory'
  AND e.start >= TIMESTAMP '2020-01-01 00:00:00'
  AND e.start <  TIMESTAMP '2021-01-01 00:00:00'
ORDER BY p.id, e.start, e.id, o.code;
