import os
import subprocess

PG_BIN = r'C:\Program Files\PostgreSQL\18\bin\psql.exe'
MY_BIN = r'C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe'

PG_DB = 'synthea_scale'
MY_DB = 'synthea_scale'

PG_ENV = os.environ.copy()
PG_ENV['PGPASSWORD'] = '123'
PG_ENV['PGCLIENTENCODING'] = 'UTF8'

MY_ENV = os.environ.copy()
MY_ENV['MYSQL_PWD'] = 'Tungabc123?'

def run_pg_sql(sql, fail_on_error=True):
    cmd = [PG_BIN, '-h', '127.0.0.1', '-U', 'postgres', '-d', PG_DB,
           '-v', 'ON_ERROR_STOP=1', '-f', '-']
    res = subprocess.run(cmd, env=PG_ENV, input=sql.encode('utf-8'), capture_output=True)
    out = res.stdout.decode('utf-8', errors='replace')
    err = res.stderr.decode('utf-8', errors='replace').strip()
    if res.returncode != 0 and fail_on_error:
        raise RuntimeError(f"PostgreSQL command failed (rc={res.returncode}):\n{err}\nSQL:\n{sql[:300]}")
    return out + (f"\n[STDERR]\n{err}" if err else "")

def run_pg_file(filepath):
    cmd = [PG_BIN, '-h', '127.0.0.1', '-U', 'postgres', '-d', PG_DB,
           '-v', 'ON_ERROR_STOP=1', '-f', filepath]
    res = subprocess.run(cmd, env=PG_ENV, capture_output=True)
    out = res.stdout.decode('utf-8', errors='replace')
    err = res.stderr.decode('utf-8', errors='replace').strip()
    if res.returncode != 0:
        raise RuntimeError(f"PostgreSQL file {filepath} failed (rc={res.returncode}):\n{err}")
    return out + (f"\n[STDERR]\n{err}" if err else "")

def run_mysql_sql(sql, force=False):
    cmd = [MY_BIN, '-h', '127.0.0.1', '-u', 'root', '--raw']
    if force:
        cmd.append('--force')
    cmd.extend([MY_DB])
    res = subprocess.run(cmd, env=MY_ENV, input=sql.encode('utf-8'), capture_output=True)
    out = res.stdout.decode('utf-8', errors='replace')
    err = res.stderr.decode('utf-8', errors='replace').strip()
    if res.returncode != 0 and not force:
        raise RuntimeError(f"MySQL command failed (rc={res.returncode}):\n{err}\nSQL:\n{sql[:300]}")
    return out + (f"\n[STDERR]\n{err}" if err else "")

def run_mysql_file(filepath, force=False):
    with open(filepath, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    cmd = [MY_BIN, '-h', '127.0.0.1', '-u', 'root', '--raw']
    if force:
        cmd.append('--force')
    cmd.extend([MY_DB])
    res = subprocess.run(cmd, env=MY_ENV, input=sql_content.encode('utf-8'), capture_output=True)
    out = res.stdout.decode('utf-8', errors='replace')
    err = res.stderr.decode('utf-8', errors='replace').strip()
    if res.returncode != 0 and not force:
        raise RuntimeError(f"MySQL file {filepath} failed (rc={res.returncode}):\n{err}")
    return out + (f"\n[STDERR]\n{err}" if err else "")

SQL_BASELINE = """
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
FROM patients p
JOIN encounters e ON e.patient = p.id
LEFT JOIN conditions c ON c.encounter = e.id AND c.patient = p.id
JOIN observations o ON o.encounter = e.id AND o.patient = p.id
WHERE e.encounterclass = 'ambulatory'
  AND e.start >= TIMESTAMP '2020-01-01 00:00:00'
  AND e.start <  TIMESTAMP '2021-01-01 00:00:00'
ORDER BY p.id, e.start, e.id, o.code;
"""

SQL_REWRITE_02A = """
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
"""

SQL_REWRITE_02B_PG = """
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
"""

SQL_EQUIV = """
SELECT
  (SELECT COUNT(*)
   FROM patients p
   JOIN encounters e ON e.patient = p.id
   LEFT JOIN conditions c ON c.encounter = e.id AND c.patient = p.id
   JOIN observations o ON o.encounter = e.id AND o.patient = p.id
   WHERE e.encounterclass = 'ambulatory'
     AND e.start >= TIMESTAMP '2020-01-01 00:00:00'
     AND e.start <  TIMESTAMP '2021-01-01 00:00:00') AS n_baseline,
  (SELECT COUNT(*)
   FROM (
       SELECT id, patient, start, encounterclass, total_claim_cost
       FROM encounters
       WHERE encounterclass = 'ambulatory'
         AND start >= TIMESTAMP '2020-01-01 00:00:00'
         AND start <  TIMESTAMP '2021-01-01 00:00:00'
   ) e
   JOIN patients p       ON p.id = e.patient
   JOIN observations o   ON o.encounter = e.id
   LEFT JOIN conditions c ON c.encounter = e.id) AS n_rewrite;
"""

def reset_all():
    run_pg_sql("""
    DROP INDEX IF EXISTS idx_q1_enc_class_start;
    DROP INDEX IF EXISTS idx_q1_obs_enc_patient;
    DROP INDEX IF EXISTS idx_q1_cond_enc_patient;
    ALTER TABLE encounters   ALTER COLUMN encounterclass SET STATISTICS -1;
    ALTER TABLE encounters   ALTER COLUMN start          SET STATISTICS -1;
    ALTER TABLE encounters   ALTER COLUMN patient        SET STATISTICS -1;
    ALTER TABLE observations ALTER COLUMN encounter      SET STATISTICS -1;
    ALTER TABLE observations ALTER COLUMN patient        SET STATISTICS -1;
    ALTER TABLE conditions   ALTER COLUMN encounter      SET STATISTICS -1;
    ALTER TABLE conditions   ALTER COLUMN patient        SET STATISTICS -1;
    ANALYZE encounters; ANALYZE observations; ANALYZE conditions; ANALYZE patients;
    """)
    run_mysql_sql("""
    DROP INDEX idx_q1_enc_class_start  ON encounters;
    DROP INDEX idx_q1_obs_enc_patient  ON observations;
    DROP INDEX idx_q1_cond_enc_patient ON conditions;
    ANALYZE TABLE encounters DROP HISTOGRAM ON encounterclass, start;
    ALTER TABLE encounters   STATS_SAMPLE_PAGES = DEFAULT;
    ALTER TABLE observations STATS_SAMPLE_PAGES = DEFAULT;
    ALTER TABLE conditions   STATS_SAMPLE_PAGES = DEFAULT;
    ALTER TABLE patients     STATS_SAMPLE_PAGES = DEFAULT;
    ANALYZE TABLE patients, encounters, conditions, observations;
    """, force=True)

def main():
    reset_all()
    logs = []
    logs.append("# RAW LOGS TẤT CẢ CÁC LẦN CHẠY TRÊN DỮ LIỆU SCALE (synthea_scale - 10X)\n")

    # 0. Version verification
    print("Recording Server Versions...")
    pg_ver = run_pg_sql("SELECT version();").strip()
    my_ver = run_mysql_sql("SELECT VERSION();").strip()
    logs.append("## 0. Phiên bản Hệ quản trị CSDL (Server Versions)\n```text\n" + pg_ver + "\n\n" + my_ver + "\n```\n")

    # ---------------- 1. Q1_01_baseline ----------------
    print("Running Q1_01_baseline...")
    logs.append("## 1. Q1_01_baseline_pg.sql (Full file + 5 lần EXPLAIN)\n")
    logs.append("### Full File Execution (`psql -f Q1_01_baseline_pg.sql`):\n```text\n" + run_pg_file("claude_step1/Q1_01_baseline_pg.sql").strip() + "\n```\n")
    for i in range(1, 6):
        logs.append(f"### PG Baseline Run {i}:\n```text\n" + run_pg_sql(f"SET track_io_timing = on; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_BASELINE}").strip() + "\n```\n")

    logs.append("## 2. Q1_01_baseline_mysql.sql (Full file + 5 lần EXPLAIN)\n")
    logs.append("### Full File Execution (`mysql < Q1_01_baseline_mysql.sql`):\n```text\n" + run_mysql_file("claude_step1/Q1_01_baseline_mysql.sql").strip() + "\n```\n")
    for i in range(1, 6):
        logs.append(f"### MySQL Baseline Run {i}:\n```text\n" + run_mysql_sql(f"EXPLAIN ANALYZE {SQL_BASELINE}").strip() + "\n```\n")

    # ---------------- 2. Q1_02_rewrite ----------------
    print("Running Q1_02_rewrite...")
    logs.append("## 3. Q1_02_rewrite_pg.sql (Full file + 5 lần 02a & 5 lần 02b)\n")
    logs.append("### Full File Execution (`psql -f Q1_02_rewrite_pg.sql`):\n```text\n" + run_pg_file("claude_step1/Q1_02_rewrite_pg.sql").strip() + "\n```\n")
    for i in range(1, 6):
        logs.append(f"### PG Rewrite 02a Run {i}:\n```text\n" + run_pg_sql(f"SET track_io_timing = on; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_REWRITE_02A}").strip() + "\n```\n")
    for i in range(1, 6):
        logs.append(f"### PG Rewrite 02b Run {i}:\n```text\n" + run_pg_sql(f"SET track_io_timing = on; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_REWRITE_02B_PG}").strip() + "\n```\n")

    logs.append("## 4. Q1_02_rewrite_mysql.sql (Full file + 5 lần 02a & 5 lần 02b)\n")
    logs.append("### Full File Execution (`mysql < Q1_02_rewrite_mysql.sql`):\n```text\n" + run_mysql_file("claude_step1/Q1_02_rewrite_mysql.sql").strip() + "\n```\n")
    for i in range(1, 6):
        logs.append(f"### MySQL Rewrite 02a Run {i}:\n```text\n" + run_mysql_sql(f"EXPLAIN ANALYZE {SQL_REWRITE_02A}").strip() + "\n```\n")
    for i in range(1, 6):
        logs.append(f"### MySQL Rewrite 02b Run {i}:\n```text\n" + run_mysql_sql(f"SET SESSION optimizer_switch = 'derived_merge=off'; EXPLAIN ANALYZE {SQL_REWRITE_02A}").strip() + "\n```\n")

    # ---------------- 3. Q1_03_indexes ----------------
    print("Running Q1_03_indexes...")
    logs.append("## 5. Q1_03_indexes_pg.sql (Full file + 5 lần EXPLAIN khi có index)\n")
    logs.append("### Full File Execution (`psql -f Q1_03_indexes_pg.sql` - gồm tạo & xóa):\n```text\n" + run_pg_file("claude_step1/Q1_03_indexes_pg.sql").strip() + "\n```\n")
    run_pg_sql("CREATE INDEX idx_q1_enc_class_start ON encounters (encounterclass, start, id, patient); CREATE INDEX idx_q1_obs_enc_patient ON observations (encounter, patient); CREATE INDEX idx_q1_cond_enc_patient ON conditions (encounter, patient);")
    run_pg_sql(f"SET track_io_timing = on; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_BASELINE}") # warm-up
    for i in range(1, 6):
        logs.append(f"### PG Index Run {i}:\n```text\n" + run_pg_sql(f"SET track_io_timing = on; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_BASELINE}").strip() + "\n```\n")
    run_pg_sql("DROP INDEX IF EXISTS idx_q1_enc_class_start, idx_q1_obs_enc_patient, idx_q1_cond_enc_patient;")

    logs.append("## 6. Q1_03_indexes_mysql.sql (Full file + 5 lần EXPLAIN khi có index)\n")
    logs.append("### Full File Execution (`mysql < Q1_03_indexes_mysql.sql` - gồm tạo & xóa):\n```text\n" + run_mysql_file("claude_step1/Q1_03_indexes_mysql.sql", force=True).strip() + "\n```\n")
    run_mysql_sql("CREATE INDEX idx_q1_enc_class_start ON encounters (encounterclass, start, patient); CREATE INDEX idx_q1_obs_enc_patient ON observations (encounter, patient); CREATE INDEX idx_q1_cond_enc_patient ON conditions (encounter, patient);")
    run_mysql_sql(f"EXPLAIN ANALYZE {SQL_BASELINE}") # warm-up
    for i in range(1, 6):
        logs.append(f"### MySQL Index Run {i}:\n```text\n" + run_mysql_sql(f"EXPLAIN ANALYZE {SQL_BASELINE}").strip() + "\n```\n")
    run_mysql_sql("DROP INDEX idx_q1_enc_class_start ON encounters; DROP INDEX idx_q1_obs_enc_patient ON observations; DROP INDEX idx_q1_cond_enc_patient ON conditions;", force=True)

    # ---------------- 4. Q1_04_stats ----------------
    print("Running Q1_04_stats...")
    logs.append("## 7. Q1_04_stats_pg.sql (Full file + 5 lần EXPLAIN sau khi SET STATISTICS 1000)\n")
    logs.append("### Full File Execution (`psql -f Q1_04_stats_pg.sql` - gồm trước, sau & khôi phục):\n```text\n" + run_pg_file("claude_step1/Q1_04_stats_pg.sql").strip() + "\n```\n")
    run_pg_sql("""
    ALTER TABLE encounters   ALTER COLUMN encounterclass SET STATISTICS 1000;
    ALTER TABLE encounters   ALTER COLUMN start          SET STATISTICS 1000;
    ALTER TABLE encounters   ALTER COLUMN patient        SET STATISTICS 1000;
    ALTER TABLE observations ALTER COLUMN encounter      SET STATISTICS 1000;
    ALTER TABLE observations ALTER COLUMN patient        SET STATISTICS 1000;
    ALTER TABLE conditions   ALTER COLUMN encounter      SET STATISTICS 1000;
    ALTER TABLE conditions   ALTER COLUMN patient        SET STATISTICS 1000;
    ANALYZE encounters; ANALYZE observations; ANALYZE conditions; ANALYZE patients;
    """)
    run_pg_sql(f"SET track_io_timing = on; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_BASELINE}") # warm-up
    for i in range(1, 6):
        logs.append(f"### PG Stats Run {i}:\n```text\n" + run_pg_sql(f"SET track_io_timing = on; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_BASELINE}").strip() + "\n```\n")
    reset_all()

    logs.append("## 8. Q1_04_stats_mysql.sql (Full file + 5 lần EXPLAIN sau khi STATS_SAMPLE_PAGES=200 & Hist)\n")
    logs.append("### Full File Execution (`mysql < Q1_04_stats_mysql.sql` - gồm trước, sau & khôi phục):\n```text\n" + run_mysql_file("claude_step1/Q1_04_stats_mysql.sql").strip() + "\n```\n")
    run_mysql_sql("""
    ALTER TABLE encounters   STATS_SAMPLE_PAGES = 200;
    ALTER TABLE observations STATS_SAMPLE_PAGES = 200;
    ALTER TABLE conditions   STATS_SAMPLE_PAGES = 200;
    ALTER TABLE patients     STATS_SAMPLE_PAGES = 200;
    ANALYZE TABLE patients, encounters, conditions, observations;
    ANALYZE TABLE encounters UPDATE HISTOGRAM ON encounterclass, start WITH 100 BUCKETS;
    """)
    run_mysql_sql(f"EXPLAIN ANALYZE {SQL_BASELINE}") # warm-up
    for i in range(1, 6):
        logs.append(f"### MySQL Stats Run {i}:\n```text\n" + run_mysql_sql(f"EXPLAIN ANALYZE {SQL_BASELINE}").strip() + "\n```\n")
    reset_all()

    # ---------------- 5. Q1_05_combined ----------------
    print("Running Q1_05_combined...")
    logs.append("## 9. Q1_05_combined_pg.sql (Check + Equiv + Setup + 5 lần EXPLAIN + pg_stat_user_indexes + Reset)\n")
    pg_comb_setup = run_pg_sql(f"""
    SELECT tablename, indexname FROM pg_indexes WHERE schemaname = current_schema() AND indexname LIKE 'idx_q1_%';
    {SQL_EQUIV}
    CREATE INDEX idx_q1_enc_class_start  ON encounters   (encounterclass, start, id, patient);
    CREATE INDEX idx_q1_obs_enc_patient  ON observations (encounter, patient);
    CREATE INDEX idx_q1_cond_enc_patient ON conditions   (encounter, patient);
    SELECT indexrelid::regclass AS index_name, pg_size_pretty(pg_relation_size(indexrelid)) AS size FROM pg_index WHERE indexrelid::regclass::text LIKE 'idx_q1_%';
    """)
    logs.append("### PG Combined Check, Equivalence & Setup:\n```text\n" + pg_comb_setup.strip() + "\n```\n")
    run_pg_sql(f"SET track_io_timing = on; RESET enable_seqscan; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_REWRITE_02A}") # warm-up
    for i in range(1, 6):
        logs.append(f"### PG Combined Run {i}:\n```text\n" + run_pg_sql(f"SET track_io_timing = on; RESET enable_seqscan; EXPLAIN (ANALYZE, BUFFERS, SETTINGS) {SQL_REWRITE_02A}").strip() + "\n```\n")
    pg_comb_usage = run_pg_sql("SELECT pg_stat_force_next_flush(); SELECT relname AS table_name, indexrelname AS index_name, idx_scan FROM pg_stat_user_indexes WHERE indexrelname LIKE 'idx_q1_%' ORDER BY relname;")
    logs.append("### PG Combined Index Usage:\n```text\n" + pg_comb_usage.strip() + "\n```\n")
    run_pg_sql("DROP INDEX IF EXISTS idx_q1_enc_class_start, idx_q1_obs_enc_patient, idx_q1_cond_enc_patient; RESET enable_seqscan;")

    logs.append("## 10. Q1_05_combined_mysql.sql (Check + Equiv + Setup + TRUNCATE perf_schema + 5 lần EXPLAIN + COUNT_READ + Reset)\n")
    my_comb_setup = run_mysql_sql(f"""
    SELECT TABLE_NAME, INDEX_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND INDEX_NAME LIKE 'idx_q1_%' GROUP BY TABLE_NAME, INDEX_NAME;
    {SQL_EQUIV}
    CREATE INDEX idx_q1_enc_class_start  ON encounters   (encounterclass, start, patient);
    CREATE INDEX idx_q1_obs_enc_patient  ON observations (encounter, patient);
    CREATE INDEX idx_q1_cond_enc_patient ON conditions   (encounter, patient);
    SELECT TABLE_NAME, INDEX_NAME, ROUND(stat_value * @@innodb_page_size / 1024) AS size_kb FROM mysql.innodb_index_stats WHERE database_name = DATABASE() AND stat_name = 'size' AND INDEX_NAME LIKE 'idx_q1_%';
    TRUNCATE TABLE performance_schema.table_io_waits_summary_by_index_usage;
    """)
    logs.append("### MySQL Combined Check, Equivalence, Setup & Truncate Perf Schema:\n```text\n" + my_comb_setup.strip() + "\n```\n")
    run_mysql_sql(f"SET SESSION optimizer_switch = 'derived_merge=on'; EXPLAIN ANALYZE {SQL_REWRITE_02A}") # warm-up
    for i in range(1, 6):
        logs.append(f"### MySQL Combined Run {i}:\n```text\n" + run_mysql_sql(f"SET SESSION optimizer_switch = 'derived_merge=on'; EXPLAIN ANALYZE {SQL_REWRITE_02A}").strip() + "\n```\n")
    my_comb_usage = run_mysql_sql("SELECT OBJECT_NAME AS table_name, INDEX_NAME, COUNT_READ FROM performance_schema.table_io_waits_summary_by_index_usage WHERE OBJECT_SCHEMA = DATABASE() AND INDEX_NAME LIKE 'idx_q1_%' ORDER BY OBJECT_NAME;")
    logs.append("### MySQL Combined Index Usage (Clean Count):\n```text\n" + my_comb_usage.strip() + "\n```\n")
    reset_all()

    out_text = "\n".join(logs)
    with open("RAW_LOGS_SCALE_Q1.md", "w", encoding="utf-8") as f:
        f.write(out_text)
    print(f"DONE! Written RAW_LOGS_SCALE_Q1.md ({len(out_text)} chars)")

if __name__ == "__main__":
    main()
