/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_random_user (
)
RETURNS varchar AS
$body$
 /*SELECT CAST(
     regexp_replace(
       encode(
         gen_random_bytes(6), 'base64'),
         '[/=+]',
         '-', 'g'
   ) AS text)||to_char(current_timestamp, 'YYYYMMDDHH24MISSMS') ;*/
   SELECT md5(random()::varchar)||to_char(current_timestamp, 'YYYYMMDDHH24MISSMS')
$body$
LANGUAGE 'sql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;