import os
import re
import statistics
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

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
Q1_DIR = os.path.abspath(os.path.join(BASE_DIR, '..', '..', 'Query-Optimization-on-Synthea', 'workloads', 'Q1'))
RAW_LOG_PATH = os.path.join(BASE_DIR, 'RAW_LOGS_SCALE_Q1.md')


def read_sql(rel_path):
    with open(os.path.join(Q1_DIR, rel_path), 'r', encoding='utf-8') as f:
        return f.read().strip()


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


def strip_comments_and_semicolon(sql):
    # Remove /* ... */ block comments first
    no_block = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
    lines = [ln for ln in no_block.splitlines() if not ln.strip().startswith('--')]
    cleaned = '\n'.join(lines).strip()
    if cleaned.endswith(';'):
        cleaned = cleaned[:-1].strip()
    return cleaned


def measure_pg_timing(query_sql):
    q = strip_comments_and_semicolon(query_sql)
    script_parts = ["\\timing on", "\\o NUL"]
    for _ in range(6):  # 1 warm-up + 5 measured
        script_parts.append(q + ";")
    script_parts.append("\\o")
    out = run_pg_sql("\n".join(script_parts))
    times = [float(m.group(1).replace(',', '.')) for m in re.finditer(r'Time:\s+([\d.,]+)\s+ms', out)]
    return times[1:6], out


def measure_mysql_timing(query_sql):
    q = strip_comments_and_semicolon(query_sql)
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
    q = strip_comments_and_semicolon(query_sql)
    plans = []
    for i in range(1, 6):
        out = run_pg_sql(f"SET track_io_timing = on;\nEXPLAIN (ANALYZE, BUFFERS, SETTINGS) {q};")
        plans.append((i, out.strip()))
    return plans


def run_mysql_explain_5(query_sql):
    q = strip_comments_and_semicolon(query_sql)
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
    pg_comb_setup = read_sql('postgres/combined_setup.sql')
    pg_comb_teardown = read_sql('postgres/combined_teardown.sql')

    my_baseline = read_sql('mysql/baseline.sql')
    my_rewrite = read_sql('mysql/rewrite.sql')
    my_idx_setup = read_sql('mysql/index_setup.sql')
    my_idx_teardown = read_sql('mysql/index_teardown.sql')
    my_stats_setup = read_sql('mysql/stats_setup.sql')
    my_stats_teardown = read_sql('mysql/stats_teardown.sql')
    my_comb_setup = read_sql('mysql/combined_setup.sql')
    my_comb_teardown = read_sql('mysql/combined_teardown.sql')

    print("Resetting Q1 objects on PG & MySQL...")
    run_pg_sql(pg_idx_teardown + "\n" + pg_stats_teardown)
    run_mysql_sql(my_idx_teardown + "\n" + my_stats_teardown, force=True)

    logs = []
    logs.append("# RAW LOGS TẤT CẢ CÁC LẦN CHẠY Q1 TRÊN DỮ LIỆU SCALE 10X THUẦN (synthea_scale)\n")

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
        WHERE relname IN ('patients', 'encounters', 'conditions', 'observations')
        ORDER BY relname;
        SELECT SUM(pg_total_relation_size(relid)) AS d0_bytes,
               ROUND(SUM(pg_total_relation_size(relid)) / 1048576.0, 2) AS d0_mb
        FROM pg_stat_user_tables
        WHERE relname IN ('patients', 'encounters', 'conditions', 'observations');
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
          AND TABLE_NAME IN ('patients', 'encounters', 'conditions', 'observations')
        ORDER BY TABLE_NAME;
        SELECT SUM(DATA_LENGTH + INDEX_LENGTH) AS d0_bytes,
               ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1048576.0, 2) AS d0_mb
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME IN ('patients', 'encounters', 'conditions', 'observations');
    """).strip()

    logs.append("### Thông số môi trường & Dung lượng D0 (patients, encounters, conditions, observations)\n```text\n" + pg_env_info + "\n\n" + my_env_info + "\n```\n")

    pg_b_q = strip_comments_and_semicolon(pg_baseline)
    pg_r_q = strip_comments_and_semicolon(pg_rewrite)
    my_b_q = strip_comments_and_semicolon(my_baseline)
    my_r_q = strip_comments_and_semicolon(my_rewrite)

    pg_eq = run_pg_sql(f"""
        SELECT (SELECT COUNT(*) FROM ({pg_b_q}) b) AS n_baseline,
               (SELECT COUNT(*) FROM ({pg_r_q}) r) AS n_rewrite;
    """).strip()
    my_eq = run_mysql_sql(f"""
        SELECT (SELECT COUNT(*) FROM ({my_b_q}) b) AS n_baseline,
               (SELECT COUNT(*) FROM ({my_r_q}) r) AS n_rewrite;
    """).strip()
    logs.append("### Kiểm tra tương đương kết quả (Equivalence Check)\n```text\n-- PostgreSQL\n" + pg_eq + "\n\n-- MySQL\n" + my_eq + "\n```\n")

    # ---------------- 1. BASELINE ----------------
    print("1. Running Q1 Baseline (PG & MySQL)...")
    logs.append("## 1. Q1 Baseline\n")
    pg_t_base, pg_t_base_raw = measure_pg_timing(pg_baseline)
    logs.append(f"### PG Baseline Timing (5 runs after 1 warm-up): {pg_t_base} | median={statistics.median(pg_t_base):.3f} ms\n```text\n{pg_t_base_raw.strip()}\n```\n")
    for i, out in run_pg_explain_5(pg_baseline):
        logs.append(f"### PG Baseline EXPLAIN Run {i}:\n```text\n{out}\n```\n")

    my_t_base, my_t_base_raw = measure_mysql_timing(my_baseline)
    logs.append(f"### MySQL Baseline Timing (5 runs after 1 warm-up): {my_t_base} | median={statistics.median(my_t_base):.3f} ms\n```text\n{my_t_base_raw.strip()}\n```\n")
    for i, out in run_mysql_explain_5(my_baseline):
        logs.append(f"### MySQL Baseline EXPLAIN Run {i}:\n```text\n{out}\n```\n")

    # ---------------- 2. REWRITE ----------------
    print("2. Running Q1 Rewrite (PG & MySQL)...")
    logs.append("## 2. Q1 Rewrite (02a)\n")
    pg_t_rew, pg_t_rew_raw = measure_pg_timing(pg_rewrite)
    logs.append(f"### PG Rewrite Timing (5 runs after 1 warm-up): {pg_t_rew} | median={statistics.median(pg_t_rew):.3f} ms\n```text\n{pg_t_rew_raw.strip()}\n```\n")
    for i, out in run_pg_explain_5(pg_rewrite):
        logs.append(f"### PG Rewrite EXPLAIN Run {i}:\n```text\n{out}\n```\n")

    my_t_rew, my_t_rew_raw = measure_mysql_timing(my_rewrite)
    logs.append(f"### MySQL Rewrite Timing (5 runs after 1 warm-up): {my_t_rew} | median={statistics.median(my_t_rew):.3f} ms\n```text\n{my_t_rew_raw.strip()}\n```\n")
    for i, out in run_mysql_explain_5(my_rewrite):
        logs.append(f"### MySQL Rewrite EXPLAIN Run {i}:\n```text\n{out}\n```\n")

    # ---------------- 3. INDEXES ----------------
    print("3. Running Q1 Indexes (PG & MySQL)...")
    logs.append("## 3. Q1 Indexes (no ANALYZE)\n")
    pg_idx_out = run_pg_sql("\\timing on\n" + pg_idx_setup).strip()
    pg_idx_size = run_pg_sql("""
        SELECT indexname,
               pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname)) AS size_bytes,
               pg_size_pretty(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname))) AS size
        FROM pg_indexes WHERE indexname LIKE 'idx_q1_%' ORDER BY indexname;
        SELECT SUM(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname))) AS delta_d_bytes,
               ROUND(SUM(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(indexname))) / 1048576.0, 2) AS delta_d_mb
        FROM pg_indexes WHERE indexname LIKE 'idx_q1_%';
    """).strip()
    logs.append("### PG Index Setup & Sizes\n```text\n" + pg_idx_out + "\n\n" + pg_idx_size + "\n```\n")
    pg_t_idx, _ = measure_pg_timing(pg_baseline)
    logs.append(f"### PG Index Timing (5 runs after 1 warm-up): {pg_t_idx} | median={statistics.median(pg_t_idx):.3f} ms\n")
    for i, out in run_pg_explain_5(pg_baseline):
        logs.append(f"### PG Index EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_pg_sql(pg_idx_teardown)

    my_idx_out = run_mysql_sql(my_idx_setup).strip()
    my_idx_size = run_mysql_sql("""
        SELECT table_name, index_name, stat_value * @@innodb_page_size AS size_bytes,
               ROUND((stat_value * @@innodb_page_size) / 1048576.0, 2) AS size_mb
        FROM mysql.innodb_index_stats
        WHERE database_name = DATABASE() AND stat_name = 'size' AND index_name LIKE 'idx_q1_%'
        ORDER BY table_name, index_name;
        SELECT SUM(stat_value * @@innodb_page_size) AS delta_d_bytes,
               ROUND(SUM(stat_value * @@innodb_page_size) / 1048576.0, 2) AS delta_d_mb
        FROM mysql.innodb_index_stats
        WHERE database_name = DATABASE() AND stat_name = 'size' AND index_name LIKE 'idx_q1_%';
    """).strip()
    logs.append("### MySQL Index Setup & Sizes\n```text\n" + my_idx_out + "\n\n" + my_idx_size + "\n```\n")
    my_t_idx, _ = measure_mysql_timing(my_baseline)
    logs.append(f"### MySQL Index Timing (5 runs after 1 warm-up): {my_t_idx} | median={statistics.median(my_t_idx):.3f} ms\n")
    for i, out in run_mysql_explain_5(my_baseline):
        logs.append(f"### MySQL Index EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_mysql_sql(my_idx_teardown, force=True)

    # ---------------- 4. STATS ----------------
    print("4. Running Q1 Stats (PG & MySQL)...")
    logs.append("## 4. Q1 Statistics\n")
    pg_stats_out = run_pg_sql(pg_stats_setup).strip()
    logs.append("### PG Stats Setup\n```text\n" + pg_stats_out + "\n```\n")
    pg_t_stats, _ = measure_pg_timing(pg_baseline)
    logs.append(f"### PG Stats Timing (5 runs after 1 warm-up): {pg_t_stats} | median={statistics.median(pg_t_stats):.3f} ms\n")
    for i, out in run_pg_explain_5(pg_baseline):
        logs.append(f"### PG Stats EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_pg_sql(pg_stats_teardown)

    my_stats_out = run_mysql_sql(my_stats_setup).strip()
    logs.append("### MySQL Stats Setup\n```text\n" + my_stats_out + "\n```\n")
    my_t_stats, _ = measure_mysql_timing(my_baseline)
    logs.append(f"### MySQL Stats Timing (5 runs after 1 warm-up): {my_t_stats} | median={statistics.median(my_t_stats):.3f} ms\n")
    for i, out in run_mysql_explain_5(my_baseline):
        logs.append(f"### MySQL Stats EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_mysql_sql(my_stats_teardown, force=True)

    # ---------------- 5. COMBINED ----------------
    print("5. Running Q1 Combined (PG & MySQL)...")
    logs.append("## 5. Q1 Combined (Rewrite 02a + Indexes, no ANALYZE)\n")
    pg_comb_out = run_pg_sql("\\timing on\n" + pg_comb_setup).strip()
    logs.append("### PG Combined Setup\n```text\n" + pg_comb_out + "\n```\n")
    pg_t_comb, _ = measure_pg_timing(pg_rewrite)
    logs.append(f"### PG Combined Timing (5 runs after 1 warm-up): {pg_t_comb} | median={statistics.median(pg_t_comb):.3f} ms\n")
    for i, out in run_pg_explain_5(pg_rewrite):
        logs.append(f"### PG Combined EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_pg_sql(pg_comb_teardown)

    my_comb_out = run_mysql_sql(my_comb_setup).strip()
    logs.append("### MySQL Combined Setup\n```text\n" + my_comb_out + "\n```\n")
    my_t_comb, _ = measure_mysql_timing(my_rewrite)
    logs.append(f"### MySQL Combined Timing (5 runs after 1 warm-up): {my_t_comb} | median={statistics.median(my_t_comb):.3f} ms\n")
    for i, out in run_mysql_explain_5(my_rewrite):
        logs.append(f"### MySQL Combined EXPLAIN Run {i}:\n```text\n{out}\n```\n")
    run_mysql_sql(my_comb_teardown, force=True)

    with open(RAW_LOG_PATH, 'w', encoding='utf-8') as f:
        f.write('\n'.join(logs))
    print(f"Done! Saved raw logs to {RAW_LOG_PATH}")


if __name__ == '__main__':
    main()
