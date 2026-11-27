import os
import re
import statistics
import subprocess
import time

PG_BIN = r'C:\Program Files\PostgreSQL\18\bin\psql.exe'
MY_BIN = r'C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe'

PG_DB = 'synthea_scale'
MY_DB = 'synthea_scale'

PG_ENV = os.environ.copy()
PG_ENV['PGPASSWORD'] = '123'
PG_ENV['PGCLIENTENCODING'] = 'UTF8'

MY_ENV = os.environ.copy()
MY_ENV['MYSQL_PWD'] = 'Tungabc123?'

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
Q3_DIR = os.path.abspath(os.path.join(BASE_DIR, '..', 'Query-Optimization-on-Synthea', 'workloads', 'Q3'))
RAW_LOG_PATH = os.path.join(BASE_DIR, 'RAW_LOGS_SCALE_Q3.md')


def read_sql(rel_path):
    with open(os.path.join(Q3_DIR, rel_path), 'r', encoding='utf-8') as f:
        sql = f.read().strip()
    # Replace USE synthea_db; if present
    sql = re.sub(r'(?i)^\s*USE\s+\w+\s*;\s*$', '', sql, flags=re.MULTILINE).strip()
    return sql


def run_pg_sql(sql, fail_on_error=True):
    cmd = [PG_BIN, '-h', '127.0.0.1', '-U', 'postgres', '-d', PG_DB,
           '-v', 'ON_ERROR_STOP=1', '-f', '-']
    res = subprocess.run(cmd, env=PG_ENV, input=sql.encode('utf-8'), capture_output=True)
    out = res.stdout.decode('utf-8', errors='replace')
    err = res.stderr.decode('utf-8', errors='replace').strip()
    if res.returncode != 0 and fail_on_error:
        raise RuntimeError(f"PostgreSQL failed (rc={res.returncode}):\n{err}\nSQL:\n{sql[:300]}")
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
        raise RuntimeError(f"MySQL failed (rc={res.returncode}):\n{err}\nSQL:\n{sql[:300]}")
    return out + (f"\n[STDERR]\n{err}" if err else "")


def extract_query_only(sql):
    lines = [ln for ln in sql.splitlines() if not ln.strip().startswith('--')]
    cleaned = '\n'.join(lines).strip()
    cleaned = re.sub(r'(?i)^\s*EXPLAIN\s*\(ANALYZE,\s*BUFFERS\)\s*', '', cleaned)
    cleaned = re.sub(r'(?i)^\s*EXPLAIN\s+ANALYZE\s*', '', cleaned)
    if cleaned.endswith(';'):
        cleaned = cleaned[:-1].strip()
    return cleaned


def split_two_queries(sql):
    """For matview_query.sql / summary_query.sql which contain 2 SELECTs."""
    lines = [ln for ln in sql.splitlines() if not ln.strip().startswith('--')]
    cleaned = '\n'.join(lines).strip()
    parts = [p.strip() for p in cleaned.split(';') if p.strip()]
    res = []
    for p in parts:
        q = re.sub(r'(?i)^\s*EXPLAIN\s*\(ANALYZE,\s*BUFFERS\)\s*', '', p).strip()
        q = re.sub(r'(?i)^\s*EXPLAIN\s+ANALYZE\s*', '', q).strip()
        res.append(q)
    return res


def measure_pg_timing(query_sql):
    q = extract_query_only(query_sql)
    script_parts = ["\\timing on", "\\o NUL"]
    for _ in range(6):  # 1 warm-up + 5 measured
        script_parts.append(q + ";")
    script_parts.append("\\o")
    out = run_pg_sql("\n".join(script_parts))
    times = [float(m.group(1).replace(',', '.')) for m in re.finditer(r'Time:\s+([\d.,]+)\s+ms', out)]
    return times[1:6], out


def measure_mysql_timing(query_sql):
    q = extract_query_only(query_sql)
    script_parts = []
    for _ in range(6):  # 1 warm-up + 5 measured
        script_parts.append("SET @t0 = SYSDATE(6);")
        script_parts.append(q + ";")
        script_parts.append("SELECT CONCAT('TIMING_MS=', ROUND(TIMESTAMPDIFF(MICROSECOND, @t0, SYSDATE(6)) / 1000.0, 3)) AS t;")
    out = run_mysql_sql("\n".join(script_parts))
    times = [float(m.group(1)) for m in re.finditer(r'TIMING_MS=([\d.]+)', out)]
    measured = times[1:6] if len(times) >= 6 else times
    timing_lines = [ln for ln in out.splitlines() if 'TIMING_MS=' in ln]
    return measured, '\n'.join(timing_lines)


def run_pg_explain_5(query_sql):
    q = extract_query_only(query_sql)
    plans = []
    for i in range(1, 6):
        out = run_pg_sql(f"SET track_io_timing = on;\nEXPLAIN (ANALYZE, BUFFERS, SETTINGS) {q};")
        plans.append((i, out.strip()))
    return plans


def run_mysql_explain_5(query_sql):
    q = extract_query_only(query_sql)
    plans = []
    for i in range(1, 6):
        out = run_mysql_sql(f"EXPLAIN ANALYZE {q};")
        plans.append((i, out.strip()))
    return plans


def main():
    pg_baseline = read_sql('postgres/baseline.sql')
    pg_rewrite = read_sql('postgres/rewrite.sql')
    pg_idx_setup = read_sql('postgres/index_setup.sql')
    pg_idx_teardown = read_sql('postgres/index_teardown.sql')
    pg_stats_setup = read_sql('postgres/stats_setup.sql')
    pg_stats_teardown = read_sql('postgres/stats_teardown.sql')
    pg_mv_setup = read_sql('postgres/matview_setup.sql')
    pg_mv_query = read_sql('postgres/matview_query.sql')
    pg_mv_teardown = read_sql('postgres/matview_teardown.sql')
    pg_comb_setup = read_sql('postgres/combined_setup.sql')
    pg_comb_teardown = read_sql('postgres/combined_teardown.sql')

    my_baseline = read_sql('mysql/baseline.sql')
    my_rewrite = read_sql('mysql/rewrite.sql')
    my_idx_setup = read_sql('mysql/index_setup.sql')
    my_idx_teardown = read_sql('mysql/index_teardown.sql')
    my_stats_setup = read_sql('mysql/stats_setup.sql')
    my_stats_teardown = read_sql('mysql/stats_teardown.sql')
    my_sum_setup = read_sql('mysql/summary_setup.sql')
    my_sum_query = read_sql('mysql/summary_query.sql')
    my_sum_teardown = read_sql('mysql/summary_teardown.sql')
    my_comb_setup = read_sql('mysql/combined_setup.sql')
    my_comb_teardown = read_sql('mysql/combined_teardown.sql')

    print("Resetting Q3 objects on PG & MySQL...")
    run_pg_sql(pg_idx_teardown + "\n" + pg_stats_teardown + "\n" + pg_comb_teardown)
    run_mysql_sql(my_idx_teardown + "\n" + my_stats_teardown + "\n" + my_comb_teardown, force=True)

    logs = []
    logs.append("# RAW LOGS TẤT CẢ CÁC LẦN CHẠY Q3 TRÊN DỮ LIỆU SCALE 10X THUẦN (synthea_scale)\n")

    # 0. Versions, env, D0 sizes, equivalence
    print("0. Collecting versions, environment, D0 sizes, and equivalence...")
    pg_ver = run_pg_sql("SELECT version();").strip()
    my_ver = run_mysql_sql("SELECT VERSION();").strip()
    logs.append("## 0. Phiên bản Hệ quản trị CSDL & Thông số môi trường\n```text\n" + pg_ver + "\n\n" + my_ver + "\n```\n")

    pg_env_info = run_pg_sql("""
        SHOW work_mem;
        SHOW shared_buffers;
        SHOW effective_cache_size;
        SHOW max_parallel_workers_per_gather;
        SELECT relname AS table_name,
               n_live_tup AS est_rows,
               pg_total_relation_size(relid) AS total_bytes,
               pg_size_pretty(pg_total_relation_size(relid)) AS total_size
        FROM pg_stat_user_tables
        WHERE relname IN ('encounters', 'observations')
        ORDER BY relname;
        SELECT SUM(pg_total_relation_size(relid)) AS d0_bytes,
               ROUND(SUM(pg_total_relation_size(relid)) / 1048576.0, 2) AS d0_mb
        FROM pg_stat_user_tables
        WHERE relname IN ('encounters', 'observations');
    """).strip()

    my_env_info = run_mysql_sql("""
        SELECT @@sort_buffer_size AS sort_buffer_size,
               @@join_buffer_size AS join_buffer_size,
               @@innodb_buffer_pool_size AS innodb_buffer_pool_size,
               @@tmp_table_size AS tmp_table_size;
        SELECT TABLE_NAME, TABLE_ROWS,
               DATA_LENGTH + INDEX_LENGTH AS total_bytes,
               ROUND((DATA_LENGTH + INDEX_LENGTH) / 1048576.0, 2) AS total_mb
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME IN ('encounters', 'observations')
        ORDER BY TABLE_NAME;
        SELECT SUM(DATA_LENGTH + INDEX_LENGTH) AS d0_bytes,
               ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1048576.0, 2) AS d0_mb
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME IN ('encounters', 'observations');
    """).strip()

    logs.append("### Thông số môi trường & Dung lượng D0 (encounters, observations)\n```text\n" + pg_env_info + "\n\n" + my_env_info + "\n```\n")

    pg_b_q = extract_query_only(pg_baseline)
    pg_r_q = extract_query_only(pg_rewrite)
    my_b_q = extract_query_only(my_baseline)
    my_r_q = extract_query_only(my_rewrite)

    pg_eq = run_pg_sql(f"""
        SELECT (SELECT COUNT(*) FROM ({pg_b_q}) b) AS n_baseline,
               (SELECT COUNT(*) FROM ({pg_r_q}) r) AS n_rewrite;
    """).strip()
    my_eq = run_mysql_sql(f"""
        SELECT (SELECT COUNT(*) FROM ({my_b_q}) b) AS n_baseline,
               (SELECT COUNT(*) FROM ({my_r_q}) r) AS n_rewrite;
    """).strip()
    logs.append("### Kiểm tra số nhóm kết quả (Group Count Equivalence)\n```text\n-- PostgreSQL\n" + pg_eq + "\n\n-- MySQL\n" + my_eq + "\n```\n")

    # ---------------- 1. BASELINE ----------------
    print("1. Running Q3 Baseline (PG & MySQL)...")
    logs.append("## 1. Q3 Baseline\n")
    pg_t_base, pg_t_base_raw = measure_pg_timing(pg_baseline)
    logs.append(f"### PG Baseline Timing (5 runs after 1 warm-up): {pg_t_base} | median={statistics.median(pg_t_base):.3f} ms\n```text\n{pg_t_base_raw.strip()}\n```\n")
    for i, out in run_pg_explain_5(pg_baseline):
        logs.append(f"### PG Baseline EXPLAIN Run {i}:\n```text\n{out}\n```\n")

    my_t_base, my_t_base_raw = measure_mysql_timing(my_baseline)
    logs.append(f"### MySQL Baseline Timing (5 runs after 1 warm-up): {my_t_base} | median={statistics.median(my_t_base):.3f} ms\n```text\n{my_t_base_raw.strip()}\n```\n")
    for i, out in run_mysql_explain_5(my_baseline):
        logs.append(f"### MySQL Baseline EXPLAIN Run {i}:\n```text\n{out}\n```\n")

    # ---------------- 2. REWRITE ----------------
    print("2. Running Q3 Rewrite (PG & MySQL)...")
    logs.append("## 2. Q3 Rewrite (Pre-aggregation observations + DATE_TRUNC/DATE_FORMAT)\n")
    pg_t_rew, pg_t_rew_raw = measure_pg_timing(pg_rewrite)
    logs.append(f"### PG Rewrite Timing (5 runs after 1 warm-up): {pg_t_rew} | median={statistics.median(pg_t_rew):.3f} ms\n```text\n{pg_t_rew_raw.strip()}\n```\n")
    for i, out in run_pg_explain_5(pg_rewrite):
        logs.append(f"### PG Rewrite EXPLAIN Run {i}:\n```text\n{out}\n```\n")

    my_t_rew, my_t_rew_raw = measure_mysql_timing(my_rewrite)
    logs.append(f"### MySQL Rewrite Timing (5 runs after 1 warm-up): {my_t_rew} | median={statistics.median(my_t_rew):.3f} ms\n```text\n{my_t_rew_raw.strip()}\n```\n")
    for i, out in run_mysql_explain_5(my_rewrite):
        logs.append(f"### MySQL Rewrite EXPLAIN Run {i}:\n```text\n{out}\n```\n")

    # ---------------- 3. INDEXES ----------------
    print("3. Running Q3 Indexes (PG & MySQL)...")
    logs.append("## 3. Q3 Indexes (Covering Indexes)\n")
    pg_idx_out = run_pg_sql("\\timing on\n" + pg_idx_setup).strip()
    pg_idx_size = run_pg_sql("""
        SELECT indexname,
               pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname)) AS size_bytes,
               pg_size_pretty(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname))) AS size
        FROM pg_indexes WHERE indexname IN ('idx_obs_enc_pat_inc_code', 'idx_enc_start_class_inc') ORDER BY indexname;
        SELECT SUM(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname))) AS delta_d_bytes,
               ROUND(SUM(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname))) / 1048576.0, 2) AS delta_d_mb
        FROM pg_indexes WHERE indexname IN ('idx_obs_enc_pat_inc_code', 'idx_enc_start_class_inc');
    """).strip()
    logs.append("### PG Index Setup & Sizes\n```text\n" + pg_idx_out + "\n\n" + pg_idx_size + "\n```\n")
    pg_t_idx, _ = measure_pg_timing(pg_baseline)
    logs.append(f"### PG Index Timing (5 runs after 1 warm-up): {pg_t_idx} | median={statistics.median(pg_t_idx):.3f} ms\n")
    for i, out in run_pg_explain_5(pg_baseline):
        logs.append(f"### PG Index EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_pg_sql(pg_idx_teardown + "\nANALYZE observations; ANALYZE encounters;")

    t0 = time.perf_counter()
    my_idx_out = run_mysql_sql(my_idx_setup).strip()
    my_idx_setup_ms = (time.perf_counter() - t0) * 1000.0
    my_idx_size = run_mysql_sql("""
        SELECT table_name, index_name, stat_value * @@innodb_page_size AS size_bytes,
               ROUND((stat_value * @@innodb_page_size) / 1048576.0, 2) AS size_mb
        FROM mysql.innodb_index_stats
        WHERE database_name = DATABASE() AND stat_name = 'size'
          AND index_name IN ('idx_obs_enc_pat_code', 'idx_enc_start_class_cov')
        ORDER BY table_name, index_name;
        SELECT SUM(stat_value * @@innodb_page_size) AS delta_d_bytes,
               ROUND(SUM(stat_value * @@innodb_page_size) / 1048576.0, 2) AS delta_d_mb
        FROM mysql.innodb_index_stats
        WHERE database_name = DATABASE() AND stat_name = 'size'
          AND index_name IN ('idx_obs_enc_pat_code', 'idx_enc_start_class_cov');
    """).strip()
    logs.append(f"### MySQL Index Setup (elapsed={my_idx_setup_ms:.1f} ms) & Sizes\n```text\n" + my_idx_out + "\n\n" + my_idx_size + "\n```\n")
    my_t_idx, _ = measure_mysql_timing(my_baseline)
    logs.append(f"### MySQL Index Timing (5 runs after 1 warm-up): {my_t_idx} | median={statistics.median(my_t_idx):.3f} ms\n")
    for i, out in run_mysql_explain_5(my_baseline):
        logs.append(f"### MySQL Index EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_mysql_sql(my_idx_teardown, force=True)

    # ---------------- 4. STATS ----------------
    print("4. Running Q3 Stats (PG & MySQL)...")
    logs.append("## 4. Q3 Statistics\n")
    pg_stats_out = run_pg_sql(pg_stats_setup + "\nSELECT statistics_name, attnames, kinds FROM pg_stats_ext WHERE statistics_name LIKE 'stat_%';").strip()
    logs.append("### PG Stats Setup\n```text\n" + pg_stats_out + "\n```\n")
    pg_t_stats, _ = measure_pg_timing(pg_baseline)
    logs.append(f"### PG Stats Timing (5 runs after 1 warm-up): {pg_t_stats} | median={statistics.median(pg_t_stats):.3f} ms\n")
    for i, out in run_pg_explain_5(pg_baseline):
        logs.append(f"### PG Stats EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_pg_sql(pg_stats_teardown)

    my_stats_out = run_mysql_sql(my_stats_setup + "\nSELECT table_name, column_name FROM information_schema.column_statistics WHERE schema_name = DATABASE();").strip()
    logs.append("### MySQL Stats (Histograms) Setup\n```text\n" + my_stats_out + "\n```\n")
    my_t_stats, _ = measure_mysql_timing(my_baseline)
    logs.append(f"### MySQL Stats Timing (5 runs after 1 warm-up): {my_t_stats} | median={statistics.median(my_t_stats):.3f} ms\n")
    for i, out in run_mysql_explain_5(my_baseline):
        logs.append(f"### MySQL Stats EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_mysql_sql(my_stats_teardown, force=True)

    # ---------------- 5. MATERIALIZED VIEW (PG) / SUMMARY TABLE (MySQL) ----------------
    print("5. Running Q3 MatView (PG) & Summary Table (MySQL)...")
    logs.append("## 5. Q3 Materialized View (PG) / Summary Table (MySQL)\n")
    pg_mv_setup_out = run_pg_sql("\\timing on\n" + pg_mv_setup).strip()
    pg_mv_refresh_out = run_pg_sql("\\timing on\nREFRESH MATERIALIZED VIEW mv_q3_monthly_report;").strip()
    pg_mv_size = run_pg_sql("""
        SELECT pg_total_relation_size('mv_q3_monthly_report') AS delta_d_bytes,
               ROUND(pg_total_relation_size('mv_q3_monthly_report') / 1048576.0, 4) AS delta_d_mb,
               pg_size_pretty(pg_total_relation_size('mv_q3_monthly_report')) AS size_pretty;
    """).strip()
    logs.append("### PG MatView Setup, Refresh & Size\n```text\n" + pg_mv_setup_out + "\n\n-- Refresh:\n" + pg_mv_refresh_out + "\n\n" + pg_mv_size + "\n```\n")

    pg_mv_q1, pg_mv_q2 = split_two_queries(pg_mv_query)
    pg_t_mv1, _ = measure_pg_timing(pg_mv_q1)
    pg_t_mv2, _ = measure_pg_timing(pg_mv_q2)
    logs.append(f"### PG MatView Query 1 (Full report) Timing: {pg_t_mv1} | median={statistics.median(pg_t_mv1):.3f} ms\n")
    logs.append(f"### PG MatView Query 2 (Filtered 2019 ambulatory) Timing: {pg_t_mv2} | median={statistics.median(pg_t_mv2):.3f} ms\n")
    for i, out in run_pg_explain_5(pg_mv_q1):
        logs.append(f"### PG MatView Q1 EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    for i, out in run_pg_explain_5(pg_mv_q2):
        logs.append(f"### PG MatView Q2 EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_pg_sql(pg_mv_teardown)

    t0 = time.perf_counter()
    my_sum_setup_out = run_mysql_sql(my_sum_setup).strip()
    my_sum_setup_ms = (time.perf_counter() - t0) * 1000.0
    my_sum_size = run_mysql_sql("""
        SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH + INDEX_LENGTH AS delta_d_bytes,
               ROUND((DATA_LENGTH + INDEX_LENGTH) / 1048576.0, 4) AS delta_d_mb
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'summary_q3_monthly_report';
    """).strip()
    logs.append(f"### MySQL Summary Table Setup (elapsed={my_sum_setup_ms:.1f} ms) & Size\n```text\n" + my_sum_setup_out + "\n\n" + my_sum_size + "\n```\n")

    my_sum_q1, my_sum_q2 = split_two_queries(my_sum_query)
    my_t_sum1, _ = measure_mysql_timing(my_sum_q1)
    my_t_sum2, _ = measure_mysql_timing(my_sum_q2)
    logs.append(f"### MySQL Summary Query 1 (Full report) Timing: {my_t_sum1} | median={statistics.median(my_t_sum1):.3f} ms\n")
    logs.append(f"### MySQL Summary Query 2 (Filtered 2019 ambulatory) Timing: {my_t_sum2} | median={statistics.median(my_t_sum2):.3f} ms\n")
    for i, out in run_mysql_explain_5(my_sum_q1):
        logs.append(f"### MySQL Summary Q1 EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    for i, out in run_mysql_explain_5(my_sum_q2):
        logs.append(f"### MySQL Summary Q2 EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_mysql_sql(my_sum_teardown, force=True)

    # ---------------- 6. COMBINED ----------------
    print("6. Running Q3 Combined (PG & MySQL)...")
    logs.append("## 6. Q3 Combined (MatView + Unique Index / Summary Table + PK)\n")
    pg_comb_out = run_pg_sql("\\timing on\n" + pg_comb_setup).strip()
    pg_comb_refresh_out = run_pg_sql("\\timing on\nREFRESH MATERIALIZED VIEW CONCURRENTLY mv_q3_monthly_report;").strip()
    pg_comb_size = run_pg_sql("""
        SELECT pg_total_relation_size('mv_q3_monthly_report') AS delta_d_bytes,
               ROUND(pg_total_relation_size('mv_q3_monthly_report') / 1048576.0, 4) AS delta_d_mb,
               pg_size_pretty(pg_total_relation_size('mv_q3_monthly_report')) AS size_pretty;
    """).strip()
    logs.append("### PG Combined Setup, Concurrent Refresh & Size\n```text\n" + pg_comb_out + "\n\n-- Concurrent Refresh:\n" + pg_comb_refresh_out + "\n\n" + pg_comb_size + "\n```\n")

    pg_t_comb1, _ = measure_pg_timing(pg_mv_q1)
    pg_t_comb2, _ = measure_pg_timing(pg_mv_q2)
    logs.append(f"### PG Combined Query 1 (Full report) Timing: {pg_t_comb1} | median={statistics.median(pg_t_comb1):.3f} ms\n")
    logs.append(f"### PG Combined Query 2 (Filtered 2019 ambulatory) Timing: {pg_t_comb2} | median={statistics.median(pg_t_comb2):.3f} ms\n")
    for i, out in run_pg_explain_5(pg_mv_q1):
        logs.append(f"### PG Combined Q1 EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    for i, out in run_pg_explain_5(pg_mv_q2):
        logs.append(f"### PG Combined Q2 EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_pg_sql(pg_comb_teardown)

    t0 = time.perf_counter()
    my_comb_out = run_mysql_sql(my_comb_setup).strip()
    my_comb_setup_ms = (time.perf_counter() - t0) * 1000.0
    my_comb_size = run_mysql_sql("""
        SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH + INDEX_LENGTH AS delta_d_bytes,
               ROUND((DATA_LENGTH + INDEX_LENGTH) / 1048576.0, 4) AS delta_d_mb
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'summary_q3_monthly_report';
    """).strip()
    logs.append(f"### MySQL Combined Setup (elapsed={my_comb_setup_ms:.1f} ms) & Size\n```text\n" + my_comb_out + "\n\n" + my_comb_size + "\n```\n")

    my_t_comb1, _ = measure_mysql_timing(my_sum_q1)
    my_t_comb2, _ = measure_mysql_timing(my_sum_q2)
    logs.append(f"### MySQL Combined Query 1 (Full report) Timing: {my_t_comb1} | median={statistics.median(my_t_comb1):.3f} ms\n")
    logs.append(f"### MySQL Combined Query 2 (Filtered 2019 ambulatory) Timing: {my_t_comb2} | median={statistics.median(my_t_comb2):.3f} ms\n")
    for i, out in run_mysql_explain_5(my_sum_q1):
        logs.append(f"### MySQL Combined Q1 EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    for i, out in run_mysql_explain_5(my_sum_q2):
        logs.append(f"### MySQL Combined Q2 EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_mysql_sql(my_comb_teardown, force=True)

    with open(RAW_LOG_PATH, 'w', encoding='utf-8') as f:
        f.write('\n'.join(logs))
    print(f"Done! Saved raw logs to {RAW_LOG_PATH}")


if __name__ == '__main__':
    main()
