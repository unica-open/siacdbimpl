/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_aggiorna_cab (
  codice varchar,
  codice_abi varchar,
  descrizione varchar,
  indirizzo varchar,
  cap varchar,
  citta varchar,
  provincia varchar,
  login_oper varchar
)
RETURNS varchar AS
$body$
DECLARE
	
	TM_FMT CONSTANT varchar := 'DD-MM_HH24.MI.SS,MS';
    start_tm timestamp;
	cab_rec siac_t_cab_master%rowtype;    
    diag_message_text text;
    diag_exception_detail text;
    diag_exception_hint text;
    ret text;
    
BEGIN

  start_tm = clock_timestamp();
  
  SELECT * INTO cab_rec FROM siac_t_cab_master  
      WHERE cab_abi=codice_abi
      AND cab_code=codice;
  
  IF cab_rec IS NULL THEN
        INSERT INTO siac_t_cab_master (
            cab_abi,
            cab_code,
            cab_citta,
            cab_indirizzo,
            cab_cap,
            cab_desc,
            cab_provincia,
            validita_inizio,
            data_creazione,
            data_modifica,
            login_operazione)
            VALUES (
              codice_abi,
              codice,
              citta,
              indirizzo,
              cap,
              descrizione,
              provincia,
              NOW(),
              NOW(),
              NOW(),
              login_oper
            );

        ret := 'INS ABI/CAB ' || codice_abi || '/' || codice;

  ELSIF (cab_rec.cab_citta<>citta OR
         cab_rec.cab_indirizzo<>indirizzo OR
         cab_rec.cab_cap::varchar<>cap OR
		 cab_rec.cab_desc<>descrizione OR
  		 cab_rec.cab_provincia<>provincia) THEN
 
 	 UPDATE siac_t_cab_master 
            SET cab_citta=citta,
            cab_indirizzo=indirizzo,
            cab_cap=cap,
            cab_desc=descrizione,
            cab_provincia=provincia,
            login_operazione=login_oper,
            data_modifica=NOW()
            WHERE cab_abi=codice_abi
            AND cab_code=codice;
        
      ret := 'UPD ABI/CAB ' || codice_abi || '/' || codice;

  ELSE
      ret := '*** ABI/CAB ' || codice_abi || '/' || codice;
  END IF;

  RETURN FORMAT('OK: %s [%s %s %s]',
  				ret, 
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