/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_tables_pk_fk (
    table_fk,
    column_fk,
    column_oid_fk,
    name_fk,
    table_pk,
    column_pk,
    column_oid_pk,
    name_pk)
AS
SELECT tc.table_name AS table_fk, a.attname AS column_fk,
    a.attrelid AS column_oid_fk, tc.constraint_name AS name_fk,
    tc2.table_name AS table_pk, a2.attname AS column_pk,
    a2.attrelid AS column_oid_pk, rc.unique_constraint_name AS name_pk
FROM information_schema.constraint_column_usage cu, pg_class c,
    pg_attribute a, pg_class c2, pg_attribute a2,
    information_schema.table_constraints tc,
    information_schema.referential_constraints rc,
    information_schema.table_constraints tc2,
    information_schema.constraint_column_usage cu2
WHERE c.relname = tc.table_name::name AND a.attname = cu.column_name::name AND
    tc.constraint_name::text = cu.constraint_name::text AND a.attnum > 0 AND a.attrelid = c.oid AND c2.relname = tc2.table_name::name AND a2.attname = cu2.column_name::name AND tc2.constraint_name::text = cu2.constraint_name::text AND a2.attnum > 0 AND a2.attrelid = c2.oid AND rc.constraint_name::text = tc.constraint_name::text AND tc2.constraint_name::text = rc.unique_constraint_name::text AND tc.table_schema::text = 'siac'::text AND tc.constraint_type::text = 'FOREIGN KEY'::text;