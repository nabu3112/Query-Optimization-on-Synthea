import os, subprocess

PG_BIN = r'C:\Program Files\PostgreSQL\18\bin\psql.exe'
MY_BIN = r'C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe'
PG_ENV = os.environ.copy(); PG_ENV['PGPASSWORD'] = '123'
MY_ENV = os.environ.copy(); MY_ENV['MYSQL_PWD'] = 'Tungabc123?'

def pg_query(db, sql):
    res = subprocess.run([PG_BIN, '-h', '127.0.0.1', '-U', 'postgres', '-d', db, '-t', '-A', '-c', sql], env=PG_ENV, capture_output=True)
    return res.stdout.decode('utf-8', errors='replace').strip()

def my_query(db, sql):
    res = subprocess.run([MY_BIN, '-h', '127.0.0.1', '-u', 'root', '-N', db], env=MY_ENV, input=sql.encode('utf-8'), capture_output=True)
    if res.returncode != 0:
        print("MySQL err:", res.stderr.decode('utf-8', errors='replace'))
    return res.stdout.decode('utf-8', errors='replace').strip()

print("=== 1. Original 1x Indexes ===")
print("PG Synthea_db_v2:")
print(pg_query('Synthea_db_v2', "SELECT tablename || '.' || indexname FROM pg_indexes WHERE schemaname='public' ORDER BY 1;"))
print("\nMySQL synthea:")
print(my_query('synthea', "SELECT CONCAT(TABLE_NAME, '.', INDEX_NAME) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='synthea' GROUP BY TABLE_NAME, INDEX_NAME ORDER BY 1;"))

print("\n=== 2. Stripping non-PK indexes from PG synthea_scale ===")
pg_non_pk = pg_query('synthea_scale', "SELECT indexname FROM pg_indexes WHERE schemaname='public' AND indexname NOT LIKE '%_pkey';")
if pg_non_pk:
    for idx in pg_non_pk.splitlines():
        idx = idx.strip()
        if idx:
            print(f"  PG DROP INDEX {idx}")
            pg_query('synthea_scale', f'DROP INDEX IF EXISTS "{idx}";')
pg_query('synthea_scale', "ANALYZE;")

print("\n=== 3. Stripping FKs & non-PRIMARY indexes from MySQL synthea_scale ===")
fks = my_query('synthea_scale', "SELECT CONCAT(TABLE_NAME, '|', CONSTRAINT_NAME) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='synthea_scale' AND CONSTRAINT_TYPE='FOREIGN KEY';")
if fks:
    for line in fks.splitlines():
        tbl, fk = line.strip().split('|')
        print(f"  MySQL DROP FK {tbl}.{fk}")
        my_query('synthea_scale', f"ALTER TABLE `{tbl}` DROP FOREIGN KEY `{fk}`;")

idxs = my_query('synthea_scale', "SELECT DISTINCT CONCAT(TABLE_NAME, '|', INDEX_NAME) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='synthea_scale' AND INDEX_NAME <> 'PRIMARY';")
if idxs:
    for line in idxs.splitlines():
        tbl, idx = line.strip().split('|')
        print(f"  MySQL DROP INDEX {tbl}.{idx}")
        my_query('synthea_scale', f"ALTER TABLE `{tbl}` DROP INDEX `{idx}`;")

my_query('synthea_scale', "ANALYZE TABLE patients, encounters, conditions, observations;")

print("\n=== 4. Final Indexes on synthea_scale ===")
print("PG synthea_scale:")
print(pg_query('synthea_scale', "SELECT tablename || '.' || indexname FROM pg_indexes WHERE schemaname='public' ORDER BY 1;"))
print("\nMySQL synthea_scale:")
print(my_query('synthea_scale', "SELECT CONCAT(TABLE_NAME, '.', INDEX_NAME) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='synthea_scale' GROUP BY TABLE_NAME, INDEX_NAME ORDER BY 1;"))
