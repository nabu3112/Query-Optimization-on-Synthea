-- =====================================================================
-- MYSQL 8: tạo bảng + nạp dữ liệu + khoá chính + khoá ngoại (+ index tự tạo)  (bộ x10)
-- >>> TRƯỚC KHI CHẠY: dùng Find & Replace (Ctrl+H) thay chuỗi  D:/DBMS_project/scale10/csv_x10  bằng đường dẫn
--     thư mục csv_x10 (kết quả của 01_scale_x10.py), ví dụ  C:/data/csv_x10
--     (dùng dấu / kể cả trên Windows, không để dấu / ở cuối). Chuỗi xuất hiện 17 lần (kể cả dòng chú thích này): chọn Replace All là xong.
--
-- ĐIỀU KIỆN TRƯỚC KHI CHẠY (LOAD DATA LOCAL):
--   * Phía máy chủ:   SET GLOBAL local_infile = 1;      (cần quyền quản trị)
--   * Phía Workbench: Edit Connection > Advanced > mục "Others" thêm dòng:
--                     OPT_LOCAL_INFILE=1      rồi kết nối lại.
--   Nếu vẫn bị chặn, đặt CSV vào thư mục secure_file_priv (SHOW VARIABLES LIKE 'secure_file_priv')
--   và bỏ chữ LOCAL trong các lệnh LOAD DATA.
-- Chạy cả file (Ctrl+Shift+Enter trong Workbench) hoặc từng đoạn theo số thứ tự.
-- Khoá ngoại được thêm SAU khi nạp; InnoDB tự tạo index trùng tên với ràng buộc (fk_...),
-- đúng như kết quả information_schema.statistics bạn đã thấy.
-- =====================================================================
CREATE DATABASE IF NOT EXISTS `synthea_x10` CHARACTER SET utf8mb4;
USE `synthea_x10`;

-- 1. XOÁ BẢNG CŨ (cho phép chạy lại nhiều lần)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `organizations`;
DROP TABLE IF EXISTS `payers`;
DROP TABLE IF EXISTS `providers`;
DROP TABLE IF EXISTS `patients`;
DROP TABLE IF EXISTS `encounters`;
DROP TABLE IF EXISTS `allergies`;
DROP TABLE IF EXISTS `careplans`;
DROP TABLE IF EXISTS `conditions`;
DROP TABLE IF EXISTS `devices`;
DROP TABLE IF EXISTS `imaging_studies`;
DROP TABLE IF EXISTS `immunizations`;
DROP TABLE IF EXISTS `medications`;
DROP TABLE IF EXISTS `observations`;
DROP TABLE IF EXISTS `procedures`;
DROP TABLE IF EXISTS `supplies`;
DROP TABLE IF EXISTS `payer_transitions`;
SET FOREIGN_KEY_CHECKS = 1;

-- 2. TẠO BẢNG (khoá chính khai báo ngay trong bảng)
CREATE TABLE `organizations` (
    `id` VARCHAR(36),
    `name` VARCHAR(255),
    `address` VARCHAR(255),
    `city` VARCHAR(100),
    `state` VARCHAR(10),
    `zip` VARCHAR(10),
    `lat` DOUBLE,
    `lon` DOUBLE,
    `phone` VARCHAR(50),
    `revenue` DOUBLE,
    `utilization` INT,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `payers` (
    `id` VARCHAR(36),
    `name` VARCHAR(255),
    `address` VARCHAR(255),
    `city` VARCHAR(100),
    `state_headquartered` VARCHAR(10),
    `zip` VARCHAR(10),
    `phone` VARCHAR(50),
    `amount_covered` DOUBLE,
    `amount_uncovered` DOUBLE,
    `revenue` DOUBLE,
    `covered_encounters` INT,
    `uncovered_encounters` INT,
    `covered_medications` INT,
    `uncovered_medications` INT,
    `covered_procedures` INT,
    `uncovered_procedures` INT,
    `covered_immunizations` INT,
    `uncovered_immunizations` INT,
    `unique_customers` INT,
    `qols_avg` DOUBLE,
    `member_months` INT,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `providers` (
    `id` VARCHAR(36),
    `organization` VARCHAR(36),
    `name` VARCHAR(255),
    `gender` VARCHAR(10),
    `speciality` VARCHAR(100),
    `address` VARCHAR(255),
    `city` VARCHAR(100),
    `state` VARCHAR(10),
    `zip` VARCHAR(10),
    `lat` DOUBLE,
    `lon` DOUBLE,
    `utilization` INT,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `patients` (
    `id` VARCHAR(36),
    `birthdate` DATE,
    `deathdate` DATE,
    `ssn` VARCHAR(20),
    `drivers` VARCHAR(20),
    `passport` VARCHAR(20),
    `prefix` VARCHAR(10),
    `first` VARCHAR(50),
    `last` VARCHAR(50),
    `suffix` VARCHAR(10),
    `maiden` VARCHAR(50),
    `marital` VARCHAR(10),
    `race` VARCHAR(30),
    `ethnicity` VARCHAR(30),
    `gender` VARCHAR(10),
    `birthplace` VARCHAR(255),
    `address` VARCHAR(255),
    `city` VARCHAR(100),
    `state` VARCHAR(50),
    `county` VARCHAR(100),
    `zip` VARCHAR(10),
    `lat` DOUBLE,
    `lon` DOUBLE,
    `healthcare_expenses` DOUBLE,
    `healthcare_coverage` DOUBLE,
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `encounters` (
    `id` VARCHAR(36),
    `start` DATETIME,
    `stop` DATETIME,
    `patient` VARCHAR(36),
    `organization` VARCHAR(36),
    `provider` VARCHAR(36),
    `payer` VARCHAR(36),
    `encounterclass` VARCHAR(20),
    `code` VARCHAR(20),
    `description` VARCHAR(255),
    `base_encounter_cost` DOUBLE,
    `total_claim_cost` DOUBLE,
    `payer_coverage` DOUBLE,
    `reasoncode` VARCHAR(20),
    `reasondescription` VARCHAR(255),
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `allergies` (
    `start` DATE,
    `stop` DATE,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `careplans` (
    `id` VARCHAR(36),
    `start` DATE,
    `stop` DATE,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255),
    `reasoncode` VARCHAR(20),
    `reasondescription` VARCHAR(255),
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `conditions` (
    `start` DATE,
    `stop` DATE,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `devices` (
    `start` DATETIME,
    `stop` DATETIME,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255),
    `udi` VARCHAR(255)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `imaging_studies` (
    `id` VARCHAR(36),
    `date` DATETIME,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `bodysite_code` VARCHAR(20),
    `bodysite_description` VARCHAR(255),
    `modality_code` VARCHAR(20),
    `modality_description` VARCHAR(100),
    `sop_code` VARCHAR(50),
    `sop_description` VARCHAR(255),
    PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `immunizations` (
    `date` DATETIME,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255),
    `base_cost` DOUBLE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `medications` (
    `start` DATETIME,
    `stop` DATETIME,
    `patient` VARCHAR(36),
    `payer` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255),
    `base_cost` DOUBLE,
    `payer_coverage` DOUBLE,
    `dispenses` INT,
    `totalcost` DOUBLE,
    `reasoncode` VARCHAR(20),
    `reasondescription` VARCHAR(255)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `observations` (
    `date` DATETIME,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255),
    `value` VARCHAR(100),
    `units` VARCHAR(50),
    `type` VARCHAR(20)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `procedures` (
    `date` DATETIME,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255),
    `base_cost` DOUBLE,
    `reasoncode` VARCHAR(20),
    `reasondescription` VARCHAR(255)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `supplies` (
    `date` DATE,
    `patient` VARCHAR(36),
    `encounter` VARCHAR(36),
    `code` VARCHAR(20),
    `description` VARCHAR(255),
    `quantity` INT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE `payer_transitions` (
    `patient` VARCHAR(36),
    `start_year` INT,
    `end_year` INT,
    `payer` VARCHAR(36),
    `ownership` VARCHAR(20)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- 3. NẠP DỮ LIỆU (chuỗi rỗng -> NULL; 'YYYY-MM-DDTHH:MM:SSZ' -> DATETIME)
SET SESSION foreign_key_checks = 0;
SET SESSION unique_checks = 0;

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/organizations.csv'
INTO TABLE `organizations`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10)
SET
    `id` = NULLIF(@v0, ''),
    `name` = NULLIF(@v1, ''),
    `address` = NULLIF(@v2, ''),
    `city` = NULLIF(@v3, ''),
    `state` = NULLIF(@v4, ''),
    `zip` = NULLIF(@v5, ''),
    `lat` = NULLIF(@v6, ''),
    `lon` = NULLIF(@v7, ''),
    `phone` = NULLIF(@v8, ''),
    `revenue` = NULLIF(@v9, ''),
    `utilization` = NULLIF(@v10, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/payers.csv'
INTO TABLE `payers`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11, @v12, @v13, @v14, @v15, @v16, @v17, @v18, @v19, @v20)
SET
    `id` = NULLIF(@v0, ''),
    `name` = NULLIF(@v1, ''),
    `address` = NULLIF(@v2, ''),
    `city` = NULLIF(@v3, ''),
    `state_headquartered` = NULLIF(@v4, ''),
    `zip` = NULLIF(@v5, ''),
    `phone` = NULLIF(@v6, ''),
    `amount_covered` = NULLIF(@v7, ''),
    `amount_uncovered` = NULLIF(@v8, ''),
    `revenue` = NULLIF(@v9, ''),
    `covered_encounters` = NULLIF(@v10, ''),
    `uncovered_encounters` = NULLIF(@v11, ''),
    `covered_medications` = NULLIF(@v12, ''),
    `uncovered_medications` = NULLIF(@v13, ''),
    `covered_procedures` = NULLIF(@v14, ''),
    `uncovered_procedures` = NULLIF(@v15, ''),
    `covered_immunizations` = NULLIF(@v16, ''),
    `uncovered_immunizations` = NULLIF(@v17, ''),
    `unique_customers` = NULLIF(@v18, ''),
    `qols_avg` = NULLIF(@v19, ''),
    `member_months` = NULLIF(@v20, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/providers.csv'
INTO TABLE `providers`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11)
SET
    `id` = NULLIF(@v0, ''),
    `organization` = NULLIF(@v1, ''),
    `name` = NULLIF(@v2, ''),
    `gender` = NULLIF(@v3, ''),
    `speciality` = NULLIF(@v4, ''),
    `address` = NULLIF(@v5, ''),
    `city` = NULLIF(@v6, ''),
    `state` = NULLIF(@v7, ''),
    `zip` = NULLIF(@v8, ''),
    `lat` = NULLIF(@v9, ''),
    `lon` = NULLIF(@v10, ''),
    `utilization` = NULLIF(@v11, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/patients.csv'
INTO TABLE `patients`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11, @v12, @v13, @v14, @v15, @v16, @v17, @v18, @v19, @v20, @v21, @v22, @v23, @v24)
SET
    `id` = NULLIF(@v0, ''),
    `birthdate` = NULLIF(@v1, ''),
    `deathdate` = NULLIF(@v2, ''),
    `ssn` = NULLIF(@v3, ''),
    `drivers` = NULLIF(@v4, ''),
    `passport` = NULLIF(@v5, ''),
    `prefix` = NULLIF(@v6, ''),
    `first` = NULLIF(@v7, ''),
    `last` = NULLIF(@v8, ''),
    `suffix` = NULLIF(@v9, ''),
    `maiden` = NULLIF(@v10, ''),
    `marital` = NULLIF(@v11, ''),
    `race` = NULLIF(@v12, ''),
    `ethnicity` = NULLIF(@v13, ''),
    `gender` = NULLIF(@v14, ''),
    `birthplace` = NULLIF(@v15, ''),
    `address` = NULLIF(@v16, ''),
    `city` = NULLIF(@v17, ''),
    `state` = NULLIF(@v18, ''),
    `county` = NULLIF(@v19, ''),
    `zip` = NULLIF(@v20, ''),
    `lat` = NULLIF(@v21, ''),
    `lon` = NULLIF(@v22, ''),
    `healthcare_expenses` = NULLIF(@v23, ''),
    `healthcare_coverage` = NULLIF(@v24, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/encounters.csv'
INTO TABLE `encounters`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11, @v12, @v13, @v14)
SET
    `id` = NULLIF(@v0, ''),
    `start` = STR_TO_DATE(NULLIF(@v1, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `stop` = STR_TO_DATE(NULLIF(@v2, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `patient` = NULLIF(@v3, ''),
    `organization` = NULLIF(@v4, ''),
    `provider` = NULLIF(@v5, ''),
    `payer` = NULLIF(@v6, ''),
    `encounterclass` = NULLIF(@v7, ''),
    `code` = NULLIF(@v8, ''),
    `description` = NULLIF(@v9, ''),
    `base_encounter_cost` = NULLIF(@v10, ''),
    `total_claim_cost` = NULLIF(@v11, ''),
    `payer_coverage` = NULLIF(@v12, ''),
    `reasoncode` = NULLIF(@v13, ''),
    `reasondescription` = NULLIF(@v14, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/allergies.csv'
INTO TABLE `allergies`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5)
SET
    `start` = NULLIF(@v0, ''),
    `stop` = NULLIF(@v1, ''),
    `patient` = NULLIF(@v2, ''),
    `encounter` = NULLIF(@v3, ''),
    `code` = NULLIF(@v4, ''),
    `description` = NULLIF(@v5, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/careplans.csv'
INTO TABLE `careplans`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8)
SET
    `id` = NULLIF(@v0, ''),
    `start` = NULLIF(@v1, ''),
    `stop` = NULLIF(@v2, ''),
    `patient` = NULLIF(@v3, ''),
    `encounter` = NULLIF(@v4, ''),
    `code` = NULLIF(@v5, ''),
    `description` = NULLIF(@v6, ''),
    `reasoncode` = NULLIF(@v7, ''),
    `reasondescription` = NULLIF(@v8, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/conditions.csv'
INTO TABLE `conditions`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5)
SET
    `start` = NULLIF(@v0, ''),
    `stop` = NULLIF(@v1, ''),
    `patient` = NULLIF(@v2, ''),
    `encounter` = NULLIF(@v3, ''),
    `code` = NULLIF(@v4, ''),
    `description` = NULLIF(@v5, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/devices.csv'
INTO TABLE `devices`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6)
SET
    `start` = STR_TO_DATE(NULLIF(@v0, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `stop` = STR_TO_DATE(NULLIF(@v1, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `patient` = NULLIF(@v2, ''),
    `encounter` = NULLIF(@v3, ''),
    `code` = NULLIF(@v4, ''),
    `description` = NULLIF(@v5, ''),
    `udi` = NULLIF(@v6, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/imaging_studies.csv'
INTO TABLE `imaging_studies`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9)
SET
    `id` = NULLIF(@v0, ''),
    `date` = STR_TO_DATE(NULLIF(@v1, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `patient` = NULLIF(@v2, ''),
    `encounter` = NULLIF(@v3, ''),
    `bodysite_code` = NULLIF(@v4, ''),
    `bodysite_description` = NULLIF(@v5, ''),
    `modality_code` = NULLIF(@v6, ''),
    `modality_description` = NULLIF(@v7, ''),
    `sop_code` = NULLIF(@v8, ''),
    `sop_description` = NULLIF(@v9, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/immunizations.csv'
INTO TABLE `immunizations`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5)
SET
    `date` = STR_TO_DATE(NULLIF(@v0, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `patient` = NULLIF(@v1, ''),
    `encounter` = NULLIF(@v2, ''),
    `code` = NULLIF(@v3, ''),
    `description` = NULLIF(@v4, ''),
    `base_cost` = NULLIF(@v5, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/medications.csv'
INTO TABLE `medications`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11, @v12)
SET
    `start` = STR_TO_DATE(NULLIF(@v0, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `stop` = STR_TO_DATE(NULLIF(@v1, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `patient` = NULLIF(@v2, ''),
    `payer` = NULLIF(@v3, ''),
    `encounter` = NULLIF(@v4, ''),
    `code` = NULLIF(@v5, ''),
    `description` = NULLIF(@v6, ''),
    `base_cost` = NULLIF(@v7, ''),
    `payer_coverage` = NULLIF(@v8, ''),
    `dispenses` = NULLIF(@v9, ''),
    `totalcost` = NULLIF(@v10, ''),
    `reasoncode` = NULLIF(@v11, ''),
    `reasondescription` = NULLIF(@v12, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/observations.csv'
INTO TABLE `observations`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7)
SET
    `date` = STR_TO_DATE(NULLIF(@v0, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `patient` = NULLIF(@v1, ''),
    `encounter` = NULLIF(@v2, ''),
    `code` = NULLIF(@v3, ''),
    `description` = NULLIF(@v4, ''),
    `value` = NULLIF(@v5, ''),
    `units` = NULLIF(@v6, ''),
    `type` = NULLIF(@v7, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/procedures.csv'
INTO TABLE `procedures`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7)
SET
    `date` = STR_TO_DATE(NULLIF(@v0, ''), '%Y-%m-%dT%H:%i:%sZ'),
    `patient` = NULLIF(@v1, ''),
    `encounter` = NULLIF(@v2, ''),
    `code` = NULLIF(@v3, ''),
    `description` = NULLIF(@v4, ''),
    `base_cost` = NULLIF(@v5, ''),
    `reasoncode` = NULLIF(@v6, ''),
    `reasondescription` = NULLIF(@v7, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/supplies.csv'
INTO TABLE `supplies`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5)
SET
    `date` = NULLIF(@v0, ''),
    `patient` = NULLIF(@v1, ''),
    `encounter` = NULLIF(@v2, ''),
    `code` = NULLIF(@v3, ''),
    `description` = NULLIF(@v4, ''),
    `quantity` = NULLIF(@v5, '');

LOAD DATA LOCAL INFILE 'D:/DBMS_project/scale10/csv_x10/payer_transitions.csv'
INTO TABLE `payer_transitions`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4)
SET
    `patient` = NULLIF(@v0, ''),
    `start_year` = NULLIF(@v1, ''),
    `end_year` = NULLIF(@v2, ''),
    `payer` = NULLIF(@v3, ''),
    `ownership` = NULLIF(@v4, '');

SET SESSION unique_checks = 1;
SET SESSION foreign_key_checks = 1;

-- 4. KHOÁ NGOẠI (28) - mỗi bảng một lệnh ALTER; InnoDB tự tạo index tên fk_...
ALTER TABLE `providers`
    ADD CONSTRAINT `fk_providers_org` FOREIGN KEY (`organization`) REFERENCES `organizations` (`id`);
ALTER TABLE `encounters`
    ADD CONSTRAINT `fk_encounters_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_encounters_org` FOREIGN KEY (`organization`) REFERENCES `organizations` (`id`),
    ADD CONSTRAINT `fk_encounters_provider` FOREIGN KEY (`provider`) REFERENCES `providers` (`id`),
    ADD CONSTRAINT `fk_encounters_payer` FOREIGN KEY (`payer`) REFERENCES `payers` (`id`);
ALTER TABLE `allergies`
    ADD CONSTRAINT `fk_allergies_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_allergies_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `careplans`
    ADD CONSTRAINT `fk_careplans_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_careplans_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `conditions`
    ADD CONSTRAINT `fk_conditions_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_conditions_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `devices`
    ADD CONSTRAINT `fk_devices_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_devices_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `imaging_studies`
    ADD CONSTRAINT `fk_imaging_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_imaging_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `immunizations`
    ADD CONSTRAINT `fk_immunizations_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_immunizations_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `medications`
    ADD CONSTRAINT `fk_medications_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_medications_payer` FOREIGN KEY (`payer`) REFERENCES `payers` (`id`),
    ADD CONSTRAINT `fk_medications_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `observations`
    ADD CONSTRAINT `fk_observations_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_observations_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `procedures`
    ADD CONSTRAINT `fk_procedures_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_procedures_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `supplies`
    ADD CONSTRAINT `fk_supplies_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_supplies_encounter` FOREIGN KEY (`encounter`) REFERENCES `encounters` (`id`);
ALTER TABLE `payer_transitions`
    ADD CONSTRAINT `fk_transitions_patient` FOREIGN KEY (`patient`) REFERENCES `patients` (`id`),
    ADD CONSTRAINT `fk_transitions_payer` FOREIGN KEY (`payer`) REFERENCES `payers` (`id`);

-- 5. THỐNG KÊ
ANALYZE TABLE `organizations`, `payers`, `providers`, `patients`, `encounters`, `allergies`, `careplans`, `conditions`, `devices`, `imaging_studies`, `immunizations`, `medications`, `observations`, `procedures`, `supplies`, `payer_transitions`;

-- 6. ĐỐI CHIẾU SỐ DÒNG VỚI SỐ DÒNG MONG ĐỢI CỦA BỘ x10 (cột chenh_lech phải = 0)
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

-- 7. XEM LẠI CẤU TRÚC: chạy inspect_schema_mysql.sql (mục 3 và mục 4)
