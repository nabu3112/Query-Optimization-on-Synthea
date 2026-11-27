-- Q1 | PostgreSQL 18 | rewrite (Phương án 02a)
-- Nguồn: claude_step1/Q1_02_rewrite_pg.sql (giữ nguyên SQL gốc).
-- Thay đổi so với baseline:
--   (1) Lọc sớm encounters bằng derived table.
--   (2) Bỏ vị từ nối "patient" thừa trên conditions/observations.
--   (3) Nối INNER JOIN observations trước, LEFT JOIN conditions sau cùng.
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

-- Phương án 02b (tuỳ chọn, đo riêng): ép vật chất hoá CTE
/*
WITH e AS MATERIALIZED (
    SELECT id, patient, start, encounterclass, total_claim_cost
    FROM encounters
    WHERE encounterclass = 'ambulatory'
      AND start >= TIMESTAMP '2020-01-01 00:00:00'
      AND start <  TIMESTAMP '2021-01-01 00:00:00'
)
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
FROM e
JOIN patients p      ON p.id = e.patient
JOIN observations o  ON o.encounter = e.id
LEFT JOIN conditions c ON c.encounter = e.id
ORDER BY p.id, e.start, e.id, o.code;
*/
