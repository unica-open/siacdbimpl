/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac_for.pg_schema_size (
  text
)
RETURNS bigint AS
$body$
SELECT sum(pg_relation_size(schemaname || '.' || tablename))::bigint FROM pg_tables WHERE schemaname = $1
$body$
LANGUAGE 'sql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;