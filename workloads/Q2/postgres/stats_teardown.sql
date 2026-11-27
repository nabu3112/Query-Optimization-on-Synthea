DROP INDEX IF EXISTS idx_q2_enc_cover;
DROP INDEX IF EXISTS idx_q2_cond_active;
DROP STATISTICS IF EXISTS st_q2_enc_class_reason;

ANALYZE encounters;
ANALYZE conditions;