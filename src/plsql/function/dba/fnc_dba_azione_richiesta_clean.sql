/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_dba_azione_richiesta_clean (VARCHAR);
--SIAC-8793
CREATE OR REPLACE FUNCTION siac.fnc_dba_azione_richiesta_clean (
  p_clean_interval VARCHAR = NULL
)
RETURNS TABLE (
  esito VARCHAR,
  deleted_params BIGINT,
  deleted_rows BIGINT
) AS
$body$
DECLARE

BEGIN
	esito := 'ko';
	deleted_params := 0;
	deleted_rows := 0;

	IF p_clean_interval IS NULL THEN
		RETURN;
	END IF;

	-- task-112 integriamo nella function il salvataggio nello 'storico'. Seguira' richiamo da job
	-- p_clean_interval da job: '3 months' ?
	insert into  siac_s_azione_richiesta
	select * from siac_t_azione_richiesta
	where data_creazione < now() - p_clean_interval::interval;

	insert into  siac_s_parametro_azione_richiesta
	select * from siac_t_parametro_azione_richiesta p
	where p.azione_richiesta_id in (select a.azione_richiesta_id from siac_t_azione_richiesta a
	where a.data_creazione < now() -p_clean_interval::interval);


	DELETE FROM siac_t_parametro_azione_richiesta WHERE data_creazione < now() - p_clean_interval::INTERVAL;
	GET DIAGNOSTICS deleted_params = ROW_COUNT;
	
	DELETE FROM siac_t_azione_richiesta WHERE data_creazione < now() - p_clean_interval::INTERVAL;
	GET DIAGNOSTICS deleted_rows = ROW_COUNT;

	esito := 'ok';
	RETURN NEXT;
	
	EXCEPTION
	WHEN no_data_found THEN
		RAISE NOTICE 'nessun dato trovato';
	WHEN others THEN
		RAISE NOTICE 'errore : %  - stato: % ', SQLERRM, SQLSTATE;
	RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1;
