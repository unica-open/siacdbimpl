/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_replica_abicab_ente (
  id_ente integer
)
RETURNS varchar AS
$body$
DECLARE
	
	TM_FMT CONSTANT varchar := 'DD-MM_HH24.MI.SS,MS';
    start_tm timestamp;
 	id_nazione integer;
    diag_message_text text;
    diag_exception_detail text;
    diag_exception_hint text;
    ret text;
    sql_seq_upd varchar;
    
BEGIN

  start_tm = clock_timestamp();

  SELECT n.nazione_id INTO id_nazione FROM siac_t_nazione n 
          WHERE n.nazione_code='1' AND n.ente_proprietario_id=id_ente;

  EXECUTE 'TRUNCATE TABLE siac_t_cab_'||id_ente;
  DELETE FROM siac_t_abi WHERE ente_proprietario_id=id_ente;
  
  
  sql_seq_upd:='SELECT SETVAL(''siac_t_abi_abi_id_seq'', COALESCE(MAX(abi_id),0)+1,false ) FROM siac_t_abi';
  EXECUTE sql_seq_upd;
  
  sql_seq_upd:='SELECT SETVAL(''siac_t_cab_cab_id_seq'', COALESCE(MAX(cab_id),0)+1,false ) FROM siac_t_cab';
  EXECUTE sql_seq_upd;
  
    
  INSERT INTO siac_t_abi
  (
    abi_code,
    abi_desc ,
    validita_inizio ,
    validita_fine ,
    nazione_id ,
    ente_proprietario_id ,
    data_creazione ,
    data_modifica ,
    data_cancellazione ,
    login_operazione 
  ) 
  SELECT 
    abi_code,
    abi_desc,
    validita_inizio,
    validita_fine,
    id_nazione,
    id_ente,
    data_creazione,
    data_modifica,
    data_cancellazione,
    login_operazione 
    FROM siac_t_abi_master;

 
    
  EXECUTE 'INSERT INTO siac_t_cab_'||id_ente||'
  (
    cab_abi,
    cab_code ,
    cab_citta,
    cab_indirizzo,
    cab_cap,
    cab_desc,
    cab_provincia,
    abi_id,
    validita_inizio,
    validita_fine,
    nazione_id,
    ente_proprietario_id,
    data_creazione,
    data_modifica,
    data_cancellazione,
    login_operazione     
  )
  SELECT 
    cab_abi,
    cab_code ,
    cab_citta,
    cab_indirizzo,
    cab_cap,
    cab_desc,
    cab_provincia,
    (SELECT abi_id FROM siac_t_abi
      WHERE ente_proprietario_id='||id_ente||'
      AND  abi_code=c.cab_abi
    ),
    validita_inizio,
    validita_fine,
    '||id_nazione||',
    '||id_ente||',
    data_creazione,
    data_modifica,
    data_cancellazione,
    login_operazione FROM siac_t_cab_master c;';


  RETURN FORMAT('OK: ente %s [%s %s %s]',
  				id_ente,
                to_char(start_tm, TM_FMT), 
                to_char(clock_timestamp(), TM_FMT), 
                round(extract(epoch from (clock_timestamp() - start_tm))::numeric, 3)
  );

EXCEPTION
	WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS diag_message_text = MESSAGE_TEXT,
  			diag_exception_detail = PG_EXCEPTION_DETAIL,
            diag_exception_hint = PG_EXCEPTION_HINT;

    ret := diag_message_text || ' - ' 
        || diag_exception_detail || ' - '  
        || diag_exception_hint;
        
    RAISE NOTICE '%', ret;
    
  RETURN FORMAT('ERR: %s [%s %s %s]',
  				ret, 
                to_char(start_tm, TM_FMT), 
                to_char(clock_timestamp(), TM_FMT), 
                round(extract(epoch from (clock_timestamp() - start_tm))::numeric, 3)
  );

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;