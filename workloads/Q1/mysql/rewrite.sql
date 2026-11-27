-- Q1 | MySQL 9.4 | rewrite (Phương án 02a)
-- Nguồn: claude_step1/Q1_02_rewrite_mysql.sql (giữ nguyên SQL gốc).
-- Plan:   chạy với EXPLAIN ANALYZE <truy vấn này>
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
FROM (
    SELECT id, patient, start, encounterclass, total_claim_cost
    FROM encounters
    WHERE encounterclass = 'ambulatory'
      AND start >= TIMESTAMP '2020-01-01 00:00:00'
      AND start <  TIMESTAMP '2021-01-01 00:00:00'
) e
JOIN patients p      ON p.id = e.patient
JOIN observations o  ON o.encounter = e.id
LEFT JOIN conditions c ON c.encounter = e.id
ORDER BY p.id, e.start, e.id, o.code;

-- Phương án 02b (tuỳ chọn, đo riêng): ép vật chất hoá derived table
/*
SET SESSION optimizer_switch = 'derived_merge=off';
SELECT ...;
SET SESSION optimizer_switch = 'derived_merge=on';
*/
