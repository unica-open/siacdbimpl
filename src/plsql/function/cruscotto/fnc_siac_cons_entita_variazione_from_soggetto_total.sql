/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_variazione_from_soggetto_total (
  _uid_soggetto integer
)
RETURNS bigint AS
$body$
DECLARE total bigint;
BEGIN
	SELECT 
	coalesce(count(*),0) into total;
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;