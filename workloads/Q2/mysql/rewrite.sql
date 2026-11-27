-- Q2 | MySQL 8.4 | rewrite
-- Only change vs baseline: e.reasoncode <> ''  ->  e.reasoncode > ''.
-- Same result (985 rows). Use the same rewritten text on both DBMS for a fair comparison.
-- Run as EXPLAIN ANALYZE for the plan, and alone for timing.

SELECT
    p.id AS patient_id,
    CONCAT(p.first, ' ', p.last) AS full_name,
    p.gender,
    p.city,
    c.code AS condition_code,
    c.description AS condition_description,
    c.start AS condition_start,
    e.id AS encounter_id,
    e.encounterclass,
    e.reasoncode
FROM conditions AS c
JOIN encounters AS e
    ON e.id = c.encounter
JOIN patients AS p
    ON p.id = c.patient
WHERE c.stop IS NULL
  AND e.encounterclass = 'ambulatory'
  AND e.reasoncode <> ''
ORDER BY c.start DESC, p.id, e.id, c.code;
