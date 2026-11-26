-- =====================================================================
-- POSTGRESQL: tạo bảng + nạp dữ liệu + khoá chính + khoá ngoại + index  (bộ x10)
-- >>> TRƯỚC KHI CHẠY: dùng Find & Replace (Ctrl+H) thay chuỗi  D:/DBMS_project/scale10/csv_x10  bằng đường dẫn
--     thư mục csv_x10 (kết quả của 01_scale_x10.py), ví dụ  C:/data/csv_x10
--     (dùng dấu / kể cả trên Windows, không để dấu / ở cuối). Chuỗi xuất hiện 17 lần (kể cả dòng chú thích này): chọn Replace All là xong.
--
-- CÁCH CHẠY (cần psql vì script dùng \copy):
--   1) Tạo database (1 lần, từ DB bất kỳ):   CREATE DATABASE synthea_x10;
--   2) Chạy bằng psql:
--        psql -U postgres -d synthea_x10 -f 02_postgres_x10.sql
--      hoặc trong pgAdmin 4: chuột phải database > PSQL Tool, rồi gõ:
--        \i 'duong/dan/toi/02_postgres_x10.sql'
--   3) Kết quả đối chiếu số dòng nằm ở cuối.
-- Thứ tự: tạo bảng (chưa có khoá) -> nạp -> khoá chính -> khoá ngoại -> index -> thống kê.
-- Nạp trước, tạo khoá/index sau để nhanh hơn và để đo được thời gian dựng từng thứ.
-- =====================================================================
\set ON_ERROR_STOP on
\timing on

-- 1. XOÁ BẢNG CŨ (cho phép chạy lại nhiều lần)
DROP TABLE IF EXISTS organizations, payers, providers, patients, encounters, allergies, careplans, conditions, devices, imaging_studies, immunizations, medications, observations, procedures, supplies, payer_transitions CASCADE;

-- 2. TẠO BẢNG (chưa có khoá chính / khoá ngoại / index)
CREATE TABLE organizations (
    id VARCHAR(36),
    name VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(10),
    zip VARCHAR(10),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    phone VARCHAR(50),
    revenue DOUBLE PRECISION,
    utilization INTEGER
);

CREATE TABLE payers (
    id VARCHAR(36),
    name VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    state_headquartered VARCHAR(10),
    zip VARCHAR(10),
    phone VARCHAR(50),
    amount_covered DOUBLE PRECISION,
    amount_uncovered DOUBLE PRECISION,
    revenue DOUBLE PRECISION,
    covered_encounters INTEGER,
    uncovered_encounters INTEGER,
    covered_medications INTEGER,
    uncovered_medications INTEGER,
    covered_procedures INTEGER,
    uncovered_procedures INTEGER,
    covered_immunizations INTEGER,
    uncovered_immunizations INTEGER,
    unique_customers INTEGER,
    qols_avg DOUBLE PRECISION,
    member_months INTEGER
);

CREATE TABLE providers (
    id VARCHAR(36),
    organization VARCHAR(36),
    name VARCHAR(255),
    gender VARCHAR(10),
    speciality VARCHAR(100),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(10),
    zip VARCHAR(10),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    utilization INTEGER
);

CREATE TABLE patients (
    id VARCHAR(36),
    birthdate DATE,
    deathdate DATE,
    ssn VARCHAR(20),
    drivers VARCHAR(20),
    passport VARCHAR(20),
    prefix VARCHAR(10),
    first VARCHAR(50),
    last VARCHAR(50),
    suffix VARCHAR(10),
    maiden VARCHAR(50),
    marital VARCHAR(10),
    race VARCHAR(30),
    ethnicity VARCHAR(30),
    gender VARCHAR(10),
    birthplace VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    county VARCHAR(100),
    zip VARCHAR(10),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    healthcare_expenses DOUBLE PRECISION,
    healthcare_coverage DOUBLE PRECISION
);

CREATE TABLE encounters (
    id VARCHAR(36),
    start TIMESTAMP,
    stop TIMESTAMP,
    patient VARCHAR(36),
    organization VARCHAR(36),
    provider VARCHAR(36),
    payer VARCHAR(36),
    encounterclass VARCHAR(20),
    code VARCHAR(20),
    description VARCHAR(255),
    base_encounter_cost DOUBLE PRECISION,
    total_claim_cost DOUBLE PRECISION,
    payer_coverage DOUBLE PRECISION,
    reasoncode VARCHAR(20),
    reasondescription VARCHAR(255)
);

CREATE TABLE allergies (
    start DATE,
    stop DATE,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255)
);

CREATE TABLE careplans (
    id VARCHAR(36),
    start DATE,
    stop DATE,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255),
    reasoncode VARCHAR(20),
    reasondescription VARCHAR(255)
);

CREATE TABLE conditions (
    start DATE,
    stop DATE,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255)
);

CREATE TABLE devices (
    start TIMESTAMP,
    stop TIMESTAMP,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255),
    udi VARCHAR(255)
);

CREATE TABLE imaging_studies (
    id VARCHAR(36),
    date TIMESTAMP,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    bodysite_code VARCHAR(20),
    bodysite_description VARCHAR(255),
    modality_code VARCHAR(20),
    modality_description VARCHAR(100),
    sop_code VARCHAR(50),
    sop_description VARCHAR(255)
);

CREATE TABLE immunizations (
    date TIMESTAMP,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255),
    base_cost DOUBLE PRECISION
);

CREATE TABLE medications (
    start TIMESTAMP,
    stop TIMESTAMP,
    patient VARCHAR(36),
    payer VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255),
    base_cost DOUBLE PRECISION,
    payer_coverage DOUBLE PRECISION,
    dispenses INTEGER,
    totalcost DOUBLE PRECISION,
    reasoncode VARCHAR(20),
    reasondescription VARCHAR(255)
);

CREATE TABLE observations (
    date TIMESTAMP,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255),
    value VARCHAR(100),
    units VARCHAR(50),
    type VARCHAR(20)
);

CREATE TABLE procedures (
    date TIMESTAMP,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255),
    base_cost DOUBLE PRECISION,
    reasoncode VARCHAR(20),
    reasondescription VARCHAR(255)
);

CREATE TABLE supplies (
    date DATE,
    patient VARCHAR(36),
    encounter VARCHAR(36),
    code VARCHAR(20),
    description VARCHAR(255),
    quantity INTEGER
);

CREATE TABLE payer_transitions (
    patient VARCHAR(36),
    start_year INTEGER,
    end_year INTEGER,
    payer VARCHAR(36),
    ownership VARCHAR(20)
);

-- 3. NẠP DỮ LIỆU (chuỗi rỗng trong CSV -> NULL)
\echo 'Nạp organizations ...'
\copy organizations FROM 'D:/DBMS_project/scale10/csv_x10/organizations.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp payers ...'
\copy payers FROM 'D:/DBMS_project/scale10/csv_x10/payers.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp providers ...'
\copy providers FROM 'D:/DBMS_project/scale10/csv_x10/providers.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp patients ...'
\copy patients FROM 'D:/DBMS_project/scale10/csv_x10/patients.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp encounters ...'
\copy encounters FROM 'D:/DBMS_project/scale10/csv_x10/encounters.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp allergies ...'
\copy allergies FROM 'D:/DBMS_project/scale10/csv_x10/allergies.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp careplans ...'
\copy careplans FROM 'D:/DBMS_project/scale10/csv_x10/careplans.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp conditions ...'
\copy conditions FROM 'D:/DBMS_project/scale10/csv_x10/conditions.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp devices ...'
\copy devices FROM 'D:/DBMS_project/scale10/csv_x10/devices.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp imaging_studies ...'
\copy imaging_studies FROM 'D:/DBMS_project/scale10/csv_x10/imaging_studies.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp immunizations ...'
\copy immunizations FROM 'D:/DBMS_project/scale10/csv_x10/immunizations.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp medications ...'
\copy medications FROM 'D:/DBMS_project/scale10/csv_x10/medications.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp observations ...'
\copy observations FROM 'D:/DBMS_project/scale10/csv_x10/observations.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp procedures ...'
\copy procedures FROM 'D:/DBMS_project/scale10/csv_x10/procedures.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp supplies ...'
\copy supplies FROM 'D:/DBMS_project/scale10/csv_x10/supplies.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')
\echo 'Nạp payer_transitions ...'
\copy payer_transitions FROM 'D:/DBMS_project/scale10/csv_x10/payer_transitions.csv' WITH (FORMAT csv, HEADER true, NULL '', ENCODING 'UTF8')

-- 4. KHOÁ CHÍNH (7)
ALTER TABLE organizations ADD PRIMARY KEY (id);
ALTER TABLE payers ADD PRIMARY KEY (id);
ALTER TABLE providers ADD PRIMARY KEY (id);
ALTER TABLE patients ADD PRIMARY KEY (id);
ALTER TABLE encounters ADD PRIMARY KEY (id);
ALTER TABLE careplans ADD PRIMARY KEY (id);
ALTER TABLE imaging_studies ADD PRIMARY KEY (id);

-- 5. KHOÁ NGOẠI (28) - cùng tên với MySQL
ALTER TABLE providers ADD CONSTRAINT fk_providers_org FOREIGN KEY (organization) REFERENCES organizations (id);
ALTER TABLE encounters ADD CONSTRAINT fk_encounters_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE encounters ADD CONSTRAINT fk_encounters_org FOREIGN KEY (organization) REFERENCES organizations (id);
ALTER TABLE encounters ADD CONSTRAINT fk_encounters_provider FOREIGN KEY (provider) REFERENCES providers (id);
ALTER TABLE encounters ADD CONSTRAINT fk_encounters_payer FOREIGN KEY (payer) REFERENCES payers (id);
ALTER TABLE allergies ADD CONSTRAINT fk_allergies_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE allergies ADD CONSTRAINT fk_allergies_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE careplans ADD CONSTRAINT fk_careplans_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE careplans ADD CONSTRAINT fk_careplans_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE conditions ADD CONSTRAINT fk_conditions_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE conditions ADD CONSTRAINT fk_conditions_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE devices ADD CONSTRAINT fk_devices_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE devices ADD CONSTRAINT fk_devices_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE imaging_studies ADD CONSTRAINT fk_imaging_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE imaging_studies ADD CONSTRAINT fk_imaging_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE immunizations ADD CONSTRAINT fk_immunizations_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE immunizations ADD CONSTRAINT fk_immunizations_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE medications ADD CONSTRAINT fk_medications_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE medications ADD CONSTRAINT fk_medications_payer FOREIGN KEY (payer) REFERENCES payers (id);
ALTER TABLE medications ADD CONSTRAINT fk_medications_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE observations ADD CONSTRAINT fk_observations_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE observations ADD CONSTRAINT fk_observations_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE procedures ADD CONSTRAINT fk_procedures_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE procedures ADD CONSTRAINT fk_procedures_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE supplies ADD CONSTRAINT fk_supplies_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE supplies ADD CONSTRAINT fk_supplies_encounter FOREIGN KEY (encounter) REFERENCES encounters (id);
ALTER TABLE payer_transitions ADD CONSTRAINT fk_transitions_patient FOREIGN KEY (patient) REFERENCES patients (id);
ALTER TABLE payer_transitions ADD CONSTRAINT fk_transitions_payer FOREIGN KEY (payer) REFERENCES payers (id);

-- 6. INDEX CHO CỘT KHOÁ NGOẠI (28) - tương đương index InnoDB tự tạo trên MySQL
--    Muốn PostgreSQL 'trần' (không có các index này): sinh lại với --no-pg-fk-indexes
CREATE INDEX idx_providers_organization ON providers (organization);
CREATE INDEX idx_encounters_patient ON encounters (patient);
CREATE INDEX idx_encounters_organization ON encounters (organization);
CREATE INDEX idx_encounters_provider ON encounters (provider);
CREATE INDEX idx_encounters_payer ON encounters (payer);
CREATE INDEX idx_allergies_patient ON allergies (patient);
CREATE INDEX idx_allergies_encounter ON allergies (encounter);
CREATE INDEX idx_careplans_patient ON careplans (patient);
CREATE INDEX idx_careplans_encounter ON careplans (encounter);
CREATE INDEX idx_conditions_patient ON conditions (patient);
CREATE INDEX idx_conditions_encounter ON conditions (encounter);
CREATE INDEX idx_devices_patient ON devices (patient);
CREATE INDEX idx_devices_encounter ON devices (encounter);
CREATE INDEX idx_imaging_studies_patient ON imaging_studies (patient);
CREATE INDEX idx_imaging_studies_encounter ON imaging_studies (encounter);
CREATE INDEX idx_immunizations_patient ON immunizations (patient);
CREATE INDEX idx_immunizations_encounter ON immunizations (encounter);
CREATE INDEX idx_medications_patient ON medications (patient);
CREATE INDEX idx_medications_payer ON medications (payer);
CREATE INDEX idx_medications_encounter ON medications (encounter);
CREATE INDEX idx_observations_patient ON observations (patient);
CREATE INDEX idx_observations_encounter ON observations (encounter);
CREATE INDEX idx_procedures_patient ON procedures (patient);
CREATE INDEX idx_procedures_encounter ON procedures (encounter);
CREATE INDEX idx_supplies_patient ON supplies (patient);
CREATE INDEX idx_supplies_encounter ON supplies (encounter);
CREATE INDEX idx_payer_transitions_patient ON payer_transitions (patient);
CREATE INDEX idx_payer_transitions_payer ON payer_transitions (payer);

-- 7. THỐNG KÊ + VISIBILITY MAP (cần cho index-only scan)
VACUUM (ANALYZE);

-- 8. ĐỐI CHIẾU SỐ DÒNG VỚI SỐ DÒNG MONG ĐỢI CỦA BỘ x10 (cột chenh_lech phải = 0)
SELECT bang, so_dong_db, so_dong_mong_doi, so_dong_db - so_dong_mong_doi AS chenh_lech
FROM (
  SELECT 'organizations' AS bang, (SELECT COUNT(*) FROM organizations) AS so_dong_db, 1119 AS so_dong_mong_doi
  UNION ALL
  SELECT 'payers' AS bang, (SELECT COUNT(*) FROM payers) AS so_dong_db, 10 AS so_dong_mong_doi
  UNION ALL
  SELECT 'providers' AS bang, (SELECT COUNT(*) FROM providers) AS so_dong_db, 5855 AS so_dong_mong_doi
  UNION ALL
  SELECT 'patients' AS bang, (SELECT COUNT(*) FROM patients) AS so_dong_db, 11710 AS so_dong_mong_doi
  UNION ALL
  SELECT 'encounters' AS bang, (SELECT COUNT(*) FROM encounters) AS so_dong_db, 533460 AS so_dong_mong_doi
  UNION ALL
  SELECT 'allergies' AS bang, (SELECT COUNT(*) FROM allergies) AS so_dong_db, 5970 AS so_dong_mong_doi
  UNION ALL
  SELECT 'careplans' AS bang, (SELECT COUNT(*) FROM careplans) AS so_dong_db, 34830 AS so_dong_mong_doi
  UNION ALL
  SELECT 'conditions' AS bang, (SELECT COUNT(*) FROM conditions) AS so_dong_db, 83760 AS so_dong_mong_doi
  UNION ALL
  SELECT 'devices' AS bang, (SELECT COUNT(*) FROM devices) AS so_dong_db, 780 AS so_dong_mong_doi
  UNION ALL
  SELECT 'imaging_studies' AS bang, (SELECT COUNT(*) FROM imaging_studies) AS so_dong_db, 8550 AS so_dong_mong_doi
  UNION ALL
  SELECT 'immunizations' AS bang, (SELECT COUNT(*) FROM immunizations) AS so_dong_db, 154780 AS so_dong_mong_doi
  UNION ALL
  SELECT 'medications' AS bang, (SELECT COUNT(*) FROM medications) AS so_dong_db, 429890 AS so_dong_mong_doi
  UNION ALL
  SELECT 'observations' AS bang, (SELECT COUNT(*) FROM observations) AS so_dong_db, 2996970 AS so_dong_mong_doi
  UNION ALL
  SELECT 'procedures' AS bang, (SELECT COUNT(*) FROM procedures) AS so_dong_db, 349810 AS so_dong_mong_doi
  UNION ALL
  SELECT 'supplies' AS bang, (SELECT COUNT(*) FROM supplies) AS so_dong_db, 0 AS so_dong_mong_doi
  UNION ALL
  SELECT 'payer_transitions' AS bang, (SELECT COUNT(*) FROM payer_transitions) AS so_dong_db, 38010 AS so_dong_mong_doi
) x
ORDER BY bang;

-- 9. XEM LẠI CẤU TRÚC
-- SELECT conrelid::regclass AS bang_con, conname, pg_get_constraintdef(oid) FROM pg_constraint
--   WHERE contype IN ('p','f') AND connamespace = 'public'::regnamespace ORDER BY 1, 2;
-- SELECT tablename, indexname, indexdef FROM pg_indexes WHERE schemaname = 'public' ORDER BY 1, 2;
