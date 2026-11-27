CREATE STATISTICS IF NOT EXISTS st_q2_enc_class_reason (mcv)
    ON encounterclass, reasoncode
    FROM encounters;

ANALYZE encounters;


