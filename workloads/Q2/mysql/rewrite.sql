-- Q2 | MySQL 8.4 | rewrite
-- Only change vs baseline: e.reasoncode <> ''  ->  e.reasoncode > ''.
-- Same result (985 rows). Use the same rewritten text on both DBMS for a fair comparison.
-- Run as EXPLAIN ANALYZE for the plan, and alone for timing.

WITH active_conditions AS (
    SELECT patient, encounter, code, description, `start`
    FROM conditions
    WHERE `stop` IS NULL
),
eligible_encounters AS (
    SELECT id, patient, encounterclass, reasoncode
    FROM encounters
    WHERE encounterclass = 'ambulatory'
      AND reasoncode > ''
),
matched_visits AS (
    SELECT
        c.patient,
        c.code,
        c.description,
        c.`start` AS condition_start,
        e.id AS encounter_id,
        e.encounterclass,
        e.reasoncode
    FROM active_conditions AS c
    JOIN eligible_encounters AS e
        ON e.id = c.encounter
       AND e.patient = c.patient
)
SELECT
    p.id AS patient_id,
    CONCAT(p.first, ' ', p.last) AS full_name,
    p.gender,
    p.city,
    v.code AS condition_code,
    v.description AS condition_description,
    v.condition_start,
    v.encounter_id,
    v.encounterclass,
    v.reasoncode
FROM matched_visits AS v
JOIN patients AS p
    ON p.id = v.patient
ORDER BY v.condition_start DESC, p.id, v.encounter_id, v.code;
