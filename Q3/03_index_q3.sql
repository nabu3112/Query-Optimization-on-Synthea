-- =====================================================================
-- Q3 - BƯỚC B(ii): THIẾT KẾ CHỈ MỤC (INDEX DESIGN)
-- Lưu ý: Đảm bảo đã chạy ở trạng thái Baseline (chưa dùng MV/bảng tổng hợp)
--        và chạy trên CÂU TRUY VẤN GỐC để đo đúng tác động của chỉ mục.
-- =====================================================================

-- =====================================================================
-- PHẦN 1: POSTGRESQL
-- =====================================================================

-- 1.1. Covering Index trên observations: hỗ trợ Index-Only Scan khi nối & đếm o.code
CREATE INDEX idx_obs_enc_pat_inc_code
ON observations (encounter, patient) INCLUDE (code);

-- 1.2. Covering Index trên encounters: hỗ trợ gom nhóm/nối không cần đọc lại Heap Table
CREATE INDEX idx_enc_start_class_inc
ON encounters (start, encounterclass) INCLUDE (id, patient, total_claim_cost);

-- (Tùy chọn) Expression Index khớp trực tiếp với GROUP BY của truy vấn gốc:
-- CREATE INDEX idx_enc_ym_class ON encounters (
--     EXTRACT(YEAR FROM start),
--     EXTRACT(MONTH FROM start),
--     encounterclass
-- );

-- 1.3. Chạy lại EXPLAIN ANALYZE trên câu Q3 gốc để đo kết quả:
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

-- 1.4. RESET VỀ BASELINE (Chạy xong nhớ xóa index trước khi test kỹ thuật iii)
DROP INDEX IF EXISTS idx_obs_enc_pat_inc_code;
DROP INDEX IF EXISTS idx_enc_start_class_inc;
-- DROP INDEX IF EXISTS idx_enc_ym_class;


-- =====================================================================
-- PHẦN 2: MYSQL 8.0
-- =====================================================================

-- 2.1. Covering Index trên observations (encounter, patient, code)
CREATE INDEX idx_obs_enc_pat_code
ON observations (encounter, patient, code);

-- 2.2. Covering Index trên encounters (start, encounterclass, id, patient, total_claim_cost)
CREATE INDEX idx_enc_start_class_cov
ON encounters (start, encounterclass, id, patient, total_claim_cost);

-- 2.3. Chạy lại EXPLAIN ANALYZE trên câu Q3 gốc để đo kết quả:
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

-- 2.4. RESET VỀ BASELINE (Xóa index trước khi test kỹ thuật iii)
DROP INDEX idx_obs_enc_pat_code ON observations;
DROP INDEX idx_enc_start_class_cov ON encounters;
