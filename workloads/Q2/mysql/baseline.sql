-- Q2 | MySQL 8.4 | baseline
-- Original query, no optimization applied.
-- Plan:   run as EXPLAIN ANALYZE <this query>  -> record time, estimated vs actual rows.
-- Timing: run the query alone (without EXPLAIN) for the time measure.
-- Reference result: 985 rows.

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
FROM conditions c
JOIN encounters e
    ON e.id = c.encounter AND e.patient = c.patient
JOIN patients p
    ON p.id = c.patient
WHERE c.stop IS NULL
  AND e.encounterclass = 'ambulatory'
  AND e.reasoncode <> ''
ORDER BY c.start DESC, p.id, e.id, c.code;
