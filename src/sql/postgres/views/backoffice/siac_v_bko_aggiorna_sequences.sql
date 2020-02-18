/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_aggiorna_sequences (
    testo)
AS
SELECT DISTINCT tb.testo
FROM (
    SELECT ((((('
        SELECT SETVAL('::character varying::text || quote_literal(s.relname::character varying::text)) || ',
            COALESCE(MAX('::character varying::text) || quote_ident(c.attname::character varying::text)) || '
        ),0)+1,false )
    FROM
        '::character varying::text) || quote_ident(t.relname::character varying::text)) || ';'::character varying::text AS testo
    FROM pg_class s, pg_depend d, pg_class t, pg_attribute c
    WHERE s.relkind = 'S'::"char" AND s.oid = d.objid AND d.refobjid = t.oid
        AND d.refobjid = c.attrelid AND d.refobjsubid = c.attnum AND (EXISTS (
        SELECT 1
        FROM information_schema.tables it
        WHERE it.table_schema::character varying::text = 'siac'::character
            varying::text AND it.table_name::name = t.relname
        ))
    ORDER BY s.relname
    ) tb
ORDER BY tb.testo;