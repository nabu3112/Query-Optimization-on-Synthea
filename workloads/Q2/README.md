# Workload Q2: loc benh nhan va lan kham co chan doan dang theo doi

Ket qua tham chieu: **985 dong** (586 benh nhan, 932 lan kham), tinh tren du lieu nap tu MySQL. Xac nhan lai tren PostgreSQL.

## Thu tu chay (moi he quan tri co thu muc rieng: `postgres/`, `mysql/`)

| Buoc | Chay | Do / quan sat |
| --- | --- | --- |
| 1 | `baseline.sql` | Moc chuan: thoi gian, so dong uoc luong va thuc te |
| 2 | `rewrite.sql` | Chi viet lai dieu kien `<> ''` thanh `> ''` |
| 3 | `index_setup.sql` -> `baseline.sql` -> `rewrite.sql` -> `index_teardown.sql` | Chi muc. Chay ca rewrite de thay chi muc chi dung duoc khi dieu kien o dang khoang (PostgreSQL) |
| 4 | `stats_setup.sql` -> `baseline.sql` -> `stats_teardown.sql` | Thong ke: sai so uoc luong so dong |
| 5 | `combined_setup.sql` -> `rewrite.sql` -> `combined_teardown.sql` | To hop: thong ke + chi muc + viet lai |

Sau moi ky thuat phai chay file `*_teardown.sql` de dua co so du lieu ve baseline truoc khi do ky thuat tiep theo.

## Luu y

- Cung mot cau viet lai (`rewrite.sql`) dung cho ca hai he de so sanh cong bang va kiem tra tuong duong ket qua (so dong, tong kiem).
- `combined_setup.sql` chua bo chi muc va thong ke duoc de xuat cho Q2; dieu chinh sau khi co ket qua tung ky thuat rieng le.
- MySQL khong co `DROP INDEX IF EXISTS` nen file teardown kiem tra `information_schema` truoc khi xoa.
- Ten doi tuong (`idx_q2_*`, `st_q2_*`) co tien to rieng de teardown khong xoa nham chi muc co san.
- Chua chay thu tren he quan tri that: kiem tra cu phap khi chay lan dau.
