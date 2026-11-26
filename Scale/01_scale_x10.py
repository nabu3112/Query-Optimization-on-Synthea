#!/usr/bin/env python3
"""
Nhân bản có kiểm soát bộ CSV của Synthea (mục "scale dữ liệu").

Ý tưởng: bản sao thứ k (k = 1..FACTOR-1) của mỗi bệnh nhân giữ nguyên toàn bộ giá trị
(ngày, mã, chi phí...) và các tỷ lệ chọn lọc; CHỈ các mã định danh (Id bệnh nhân,
Id lần khám, Id careplan, Id imaging) được đổi sang UUID mới, sinh theo công thức cố định:

    new_id = UUID( MD5( "<id_gốc>|<k>" ) )

Công thức cố định nên chạy lại ra đúng kết quả cũ, và cùng bộ CSV đầu ra nạp vào cả
PostgreSQL lẫn MySQL nên hai hệ có dữ liệu giống hệt nhau.

Bản sao k = 0 chính là dữ liệu gốc (giữ nguyên). Các bảng danh mục
(organizations, providers, payers) được chép đúng một lần, không nhân bản.

Cách dùng:
    python 01_scale_x10.py --src ./csv_goc --dst ./csv_x10 --factor 10 --verify

Sau đó nạp vào cơ sở dữ liệu bằng 02_postgres_x10.sql (PostgreSQL) và
03_mysql_x10.sql (MySQL); cả hai nạp CÙNG thư mục csv_x10 này.
Số dòng mong đợi với --factor 10 trên bộ 16 file hiện tại: 4.655.504 dòng
(các script SQL đã có sẵn số dòng mong đợi từng bảng để đối chiếu).

KHÔNG ghi đè lên thư mục gốc (script sẽ từ chối nếu --dst trùng --src).
Chỉ dùng thư viện chuẩn của Python 3.8 trở lên.
"""
import argparse
import csv
import hashlib
import os
import sys
import uuid

csv.field_size_limit(sys.maxsize)

# Bảng danh mục: chép nguyên, không nhân bản
STATIC_TABLES = ["organizations", "providers", "payers"]

# Bảng gắn với bệnh nhân: tên bảng -> các cột chứa mã cần đổi sang mã mới
# (Id của chính nó, và các khoá ngoại tới patients / encounters)
SCALED_TABLES = {
    "patients":          ["Id"],
    "encounters":        ["Id", "PATIENT"],
    "careplans":         ["Id", "PATIENT", "ENCOUNTER"],
    "imaging_studies":   ["Id", "PATIENT", "ENCOUNTER"],
    "allergies":         ["PATIENT", "ENCOUNTER"],
    "conditions":        ["PATIENT", "ENCOUNTER"],
    "devices":           ["PATIENT", "ENCOUNTER"],
    "immunizations":     ["PATIENT", "ENCOUNTER"],
    "medications":       ["PATIENT", "ENCOUNTER"],
    "observations":      ["PATIENT", "ENCOUNTER"],
    "procedures":        ["PATIENT", "ENCOUNTER"],
    "supplies":          ["PATIENT", "ENCOUNTER"],
    "payer_transitions": ["PATIENT"],
}


def new_id(old, k):
    """Mã mới cho bản sao thứ k. k = 0 giữ nguyên mã gốc. Giá trị rỗng giữ rỗng."""
    if k == 0 or old == "":
        return old
    h = hashlib.md5(f"{old}|{k}".encode("utf-8")).hexdigest()
    return str(uuid.UUID(hex=h))


def copy_static(src, dst, name):
    n = 0
    with open(os.path.join(src, f"{name}.csv"), newline="", encoding="utf-8") as fin, \
         open(os.path.join(dst, f"{name}.csv"), "w", newline="", encoding="utf-8") as fout:
        r, w = csv.reader(fin), csv.writer(fout, lineterminator="\n")
        w.writerow(next(r))
        for row in r:
            w.writerow(row)
            n += 1
    return n


def scale_table(src, dst, name, id_cols, factor):
    n = 0
    path_in = os.path.join(src, f"{name}.csv")
    with open(os.path.join(dst, f"{name}.csv"), "w", newline="", encoding="utf-8") as fout:
        w = csv.writer(fout, lineterminator="\n")
        header_written = False
        for k in range(factor):
            with open(path_in, newline="", encoding="utf-8") as fin:
                r = csv.reader(fin)
                header = next(r)
                idx = [header.index(c) for c in id_cols]
                if not header_written:
                    w.writerow(header)
                    header_written = True
                for row in r:
                    if k > 0:
                        for i in idx:
                            row[i] = new_id(row[i], k)
                    w.writerow(row)
                    n += 1
    return n


def read_column(dst, name, col):
    with open(os.path.join(dst, f"{name}.csv"), newline="", encoding="utf-8") as f:
        r = csv.reader(f)
        i = next(r).index(col)
        for row in r:
            yield row[i]


def verify(dst):
    """Kiểm tra: Id không trùng, mọi khoá ngoại PATIENT/ENCOUNTER đều có cha."""
    ok = True
    patient_ids = set(read_column(dst, "patients", "Id"))
    n_pat = sum(1 for _ in read_column(dst, "patients", "Id"))
    print(f"[verify] patients: {n_pat} dòng, {len(patient_ids)} Id khác nhau",
          "OK" if n_pat == len(patient_ids) else "TRÙNG ID!")
    ok &= (n_pat == len(patient_ids))

    enc_ids = set(read_column(dst, "encounters", "Id"))
    n_enc = sum(1 for _ in read_column(dst, "encounters", "Id"))
    print(f"[verify] encounters: {n_enc} dòng, {len(enc_ids)} Id khác nhau",
          "OK" if n_enc == len(enc_ids) else "TRÙNG ID!")
    ok &= (n_enc == len(enc_ids))

    for name, cols in SCALED_TABLES.items():
        for col in cols:
            if col == "Id":
                continue
            parents = patient_ids if col == "PATIENT" else enc_ids
            bad = sum(1 for v in read_column(dst, name, col) if v != "" and v not in parents)
            status = "OK" if bad == 0 else f"{bad} KHOÁ NGOẠI MỒ CÔI"
            print(f"[verify] {name}.{col}: {status}")
            ok &= (bad == 0)
    print("[verify] KẾT QUẢ:", "TẤT CẢ ĐẠT" if ok else "CÓ LỖI")
    return ok


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--src", required=True, help="thư mục chứa 16 file CSV gốc")
    ap.add_argument("--dst", required=True, help="thư mục đầu ra (sẽ được tạo mới)")
    ap.add_argument("--factor", type=int, default=10, help="hệ số nhân (mặc định 10)")
    ap.add_argument("--verify", action="store_true", help="kiểm tra khoá ngoại/Id sau khi ghi")
    a = ap.parse_args()

    if os.path.abspath(a.src) == os.path.abspath(a.dst):
        sys.exit("LỖI: --dst không được trùng --src (không ghi đè dữ liệu gốc).")
    if a.factor < 1:
        sys.exit("LỖI: --factor phải >= 1.")
    os.makedirs(a.dst, exist_ok=True)

    total = 0
    for name in STATIC_TABLES:
        n = copy_static(a.src, a.dst, name)
        total += n
        print(f"{name:20s}{n:>12,}  (danh mục, chép nguyên)")
    for name, cols in SCALED_TABLES.items():
        n = scale_table(a.src, a.dst, name, cols, a.factor)
        total += n
        print(f"{name:20s}{n:>12,}")
    print(f"{'TỔNG':20s}{total:>12,} dòng")

    if a.verify:
        sys.exit(0 if verify(a.dst) else 1)


if __name__ == "__main__":
    main()
