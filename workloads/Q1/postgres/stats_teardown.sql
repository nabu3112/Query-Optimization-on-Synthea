-- Q1 | PostgreSQL 18 | statistics teardown
-- Nguồn: claude_step1/Q1_04_stats_pg.sql (khôi phục thống kê mặc định).

ALTER TABLE encounters   ALTER COLUMN encounterclass SET STATISTICS -1;
ALTER TABLE encounters   ALTER COLUMN start          SET STATISTICS -1;
ALTER TABLE encounters   ALTER COLUMN patient        SET STATISTICS -1;
ALTER TABLE observations ALTER COLUMN encounter      SET STATISTICS -1;
ALTER TABLE observations ALTER COLUMN patient        SET STATISTICS -1;
ALTER TABLE conditions   ALTER COLUMN encounter      SET STATISTICS -1;
ALTER TABLE conditions   ALTER COLUMN patient        SET STATISTICS -1;
ANALYZE encounters;
ANALYZE observations;
ANALYZE conditions;
ANALYZE patients;
