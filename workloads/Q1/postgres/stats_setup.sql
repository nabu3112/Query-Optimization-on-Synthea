-- Q1 | PostgreSQL 18 | statistics setup
-- Nguồn: claude_step1/Q1_04_stats_pg.sql (giữ nguyên câu lệnh tăng mẫu thống kê).

ALTER TABLE encounters   ALTER COLUMN encounterclass SET STATISTICS 1000;
ALTER TABLE encounters   ALTER COLUMN start          SET STATISTICS 1000;
ALTER TABLE encounters   ALTER COLUMN patient        SET STATISTICS 1000;
ALTER TABLE observations ALTER COLUMN encounter      SET STATISTICS 1000;
ALTER TABLE observations ALTER COLUMN patient        SET STATISTICS 1000;
ALTER TABLE conditions   ALTER COLUMN encounter      SET STATISTICS 1000;
ALTER TABLE conditions   ALTER COLUMN patient        SET STATISTICS 1000;

ANALYZE VERBOSE encounters;
ANALYZE VERBOSE observations;
ANALYZE VERBOSE conditions;
ANALYZE VERBOSE patients;
