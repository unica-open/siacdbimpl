/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_delete_ente (
    ordine,
    table_name,
    query,
    ente_proprietario_id)
AS
SELECT tb.ordine, tb.table_name,
    ((('delete
from '::text || tb.table_name::text) || '
where ente_proprietario_id='::text) || e.ente_proprietario_id) || ';'::text AS query,
    e.ente_proprietario_id
FROM (        (        (        (        (        (        (
    SELECT 6 AS ordine,
                                                                    tc.table_name
    FROM information_schema.table_constraints tc,
                                                                    information_schema.constraint_column_usage
                                                                        cu
    WHERE tc.constraint_name::text = cu.constraint_name::text AND
        cu.column_name::text = 'ente_proprietario_id'::text AND tc.table_name::text ~~ 'siac_d%'::text
    EXCEPT
    SELECT 6 AS ordine,
                                                                    tc.table_name
    FROM information_schema.table_constraints tc
                                                              JOIN
                                                                  information_schema.key_column_usage kcu ON tc.constraint_name::text = kcu.constraint_name::text
                                                         JOIN
                                                             information_schema.constraint_column_usage ccu ON ccu.constraint_name::text = tc.constraint_name::text
    WHERE tc.constraint_type::text = 'FOREIGN KEY'::text AND
        ccu.table_name::text <> 'siac_t_ente_proprietario'::text AND tc.constraint_schema::text = 'siac'::text AND tc.table_name::text ~~ 'siac_d%'::text AND ccu.table_name::text ~~ 'siac_d%'::text
    )
UNION
SELECT 5 AS ordine,
                                                            tc.table_name
FROM information_schema.table_constraints tc
                                                      JOIN
                                                          information_schema.key_column_usage kcu ON tc.constraint_name::text = kcu.constraint_name::text
                                                 JOIN
                                                     information_schema.constraint_column_usage ccu ON ccu.constraint_name::text = tc.constraint_name::text
WHERE tc.constraint_type::text = 'FOREIGN KEY'::text AND ccu.table_name::text
    <> 'siac_t_ente_proprietario'::text AND tc.constraint_schema::text = 'siac'::text AND tc.table_name::text ~~ 'siac_d%'::text AND ccu.table_name::text ~~ 'siac_d%'::text)
UNION
                                                (
SELECT 2 AS ordine,
                                                            tc.table_name
FROM information_schema.table_constraints tc,
                                                            information_schema.constraint_column_usage
                                                                cu
WHERE tc.constraint_name::text = cu.constraint_name::text AND
    cu.column_name::text = 'ente_proprietario_id'::text AND tc.table_name::text ~~ 'siac_r%'::text
EXCEPT
SELECT 2 AS ordine,
                                                            tc.table_name
FROM information_schema.table_constraints tc
                                                      JOIN
                                                          information_schema.key_column_usage kcu ON tc.constraint_name::text = kcu.constraint_name::text
                                                 JOIN
                                                     information_schema.constraint_column_usage ccu ON ccu.constraint_name::text = tc.constraint_name::text
WHERE tc.constraint_type::text = 'FOREIGN KEY'::text AND ccu.table_name::text
    <> 'siac_t_ente_proprietario'::text AND tc.constraint_schema::text = 'siac'::text AND tc.table_name::text ~~ 'siac_r%'::text AND ccu.table_name::text ~~ 'siac_r%'::text))
UNION
SELECT 1 AS ordine, tc.table_name
FROM information_schema.table_constraints tc
                                      JOIN information_schema.key_column_usage
                                          kcu ON tc.constraint_name::text = kcu.constraint_name::text
                                 JOIN
                                     information_schema.constraint_column_usage ccu ON ccu.constraint_name::text = tc.constraint_name::text
WHERE tc.constraint_type::text = 'FOREIGN KEY'::text AND ccu.table_name::text
    <> 'siac_t_ente_proprietario'::text AND tc.constraint_schema::text = 'siac'::text AND tc.table_name::text ~~ 'siac_r%'::text AND ccu.table_name::text ~~ 'siac_r%'::text)
UNION
                                (
SELECT 4 AS ordine, tc.table_name
FROM information_schema.table_constraints tc,
                                            information_schema.constraint_column_usage
                                                cu
WHERE tc.constraint_name::text = cu.constraint_name::text AND
    cu.column_name::text = 'ente_proprietario_id'::text AND tc.table_name::text ~~ 'siac_t%'::text AND tc.table_name::text <> 'siac_t_ente_proprietario'::text
EXCEPT
SELECT 4 AS ordine, tc.table_name
FROM information_schema.table_constraints tc
                                      JOIN information_schema.key_column_usage
                                          kcu ON tc.constraint_name::text = kcu.constraint_name::text
                                 JOIN
                                     information_schema.constraint_column_usage ccu ON ccu.constraint_name::text = tc.constraint_name::text
WHERE tc.constraint_type::text = 'FOREIGN KEY'::text AND ccu.table_name::text
    <> 'siac_t_ente_proprietario'::text AND tc.constraint_schema::text = 'siac'::text AND tc.table_name::text ~~ 'siac_t%'::text AND ccu.table_name::text ~~ 'siac_t%'::text))
UNION
SELECT 3 AS ordine, tc.table_name
FROM information_schema.table_constraints tc
                      JOIN information_schema.key_column_usage kcu ON
                          tc.constraint_name::text = kcu.constraint_name::text
                 JOIN information_schema.constraint_column_usage ccu ON
                     ccu.constraint_name::text = tc.constraint_name::text
WHERE tc.constraint_type::text = 'FOREIGN KEY'::text AND ccu.table_name::text
    <> 'siac_t_ente_proprietario'::text AND tc.constraint_schema::text = 'siac'::text AND tc.table_name::text ~~ 'siac_t%'::text AND ccu.table_name::text ~~ 'siac_t%'::text)
UNION
SELECT 7 AS ordine,
                    'siac_t_ente_proprietario'::character varying) tb,
    siac_t_ente_proprietario e
ORDER BY tb.ordine, tb.table_name;