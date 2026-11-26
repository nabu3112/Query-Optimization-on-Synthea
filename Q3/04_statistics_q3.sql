-- =====================================================================
-- Q3 - BƯỚC B(iii): CẬP NHẬT THỐNG KÊ (UPDATE STATISTICS)
-- Lưu ý: Đảm bảo đã RESET hết các index vừa tạo ở bước (ii) trước khi chạy!
-- =====================================================================

-- =====================================================================
-- PHẦN 1: POSTGRESQL
-- =====================================================================

-- 1.1. Cập nhật thống kê cơ bản cho 2 bảng
ANALYZE encounters;
ANALYZE observations;

-- 1.2. Tạo thống kê đa biến (Extended Statistics) cho các cặp cột có tương quan:
--      - (encounter, patient) trong observations: vì 1 encounter luôn gắn với 1 patient
--      - (start, encounterclass) trong encounters: vì các loại khám phân bố khác nhau theo thời gian
CREATE STATISTICS IF NOT EXISTS stat_obs_enc_pat (dependencies, ndistinct)
ON encounter, patient FROM observations;

CREATE STATISTICS IF NOT EXISTS stat_enc_start_class (dependencies, ndistinct)
ON start, encounterclass FROM encounters;

-- Bắt buộc chạy ANALYZE lại để hệ thống tính toán thống kê đa biến vừa tạo
ANALYZE observations;
ANALYZE encounters;

-- 1.3. Chạy lại EXPLAIN ANALYZE trên câu Q3 gốc để kiểm tra sai số ước lượng (rows vs actual rows)
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

-- 1.4. RESET VỀ BASELINE
DROP STATISTICS IF EXISTS stat_obs_enc_pat;
DROP STATISTICS IF EXISTS stat_enc_start_class;


-- =====================================================================
-- PHẦN 2: MYSQL 8.0
-- =====================================================================

-- 2.1. Cập nhật thống kê bảng và tạo Histogram cho các cột không có chỉ mục
ANALYZE TABLE encounters, observations;

ANALYZE TABLE encounters UPDATE HISTOGRAM ON start, encounterclass WITH 100 BUCKETS;
ANALYZE TABLE observations UPDATE HISTOGRAM ON encounter, patient WITH 100 BUCKETS;

-- Kiểm tra histogram đã được tạo:
SELECT TABLE_NAME, COLUMN_NAME, JSON_LENGTH(HISTOGRAM->'$.buckets') AS num_buckets
FROM information_schema.COLUMN_STATISTICS
WHERE SCHEMA_NAME = 'synthea_db';

-- 2.2. Chạy lại EXPLAIN ANALYZE trên câu Q3 gốc để kiểm tra ước lượng
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

-- 2.3. RESET VỀ BASELINE
ANALYZE TABLE encounters DROP HISTOGRAM ON start, encounterclass;
ANALYZE TABLE observations DROP HISTOGRAM ON encounter, patient;
