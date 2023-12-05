/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_aggiorna_abi (
  codice varchar,
  descrizione varchar,
  login_oper varchar
)
RETURNS varchar AS
$body$
DECLARE
	
	TM_FMT CONSTANT varchar := 'DD-MM_HH24.MI.SS,MS';
    start_tm timestamp;
	abi_rec siac_t_abi_master%rowtype;    
    diag_message_text text;
    diag_exception_detail text;
    diag_exception_hint text;
    ret text;
    
BEGIN

  start_tm = clock_timestamp();

  SELECT * INTO abi_rec FROM siac_t_abi_master 
      WHERE abi_code=codice;
      
  IF abi_rec IS NULL THEN
      	INSERT INTO siac_t_abi_master (
            abi_code,
            abi_desc,
            validita_inizio,
            data_creazione,
            data_modifica,
            login_operazione) 
            VALUES (
            codice,
            descrizione,
            NOW(),
            NOW(),
            NOW(),
            login_oper
      	);
        
        ret := 'INS ABI ' || codice;
        
  ELSIF (abi_rec.abi_desc <> descrizione) THEN
		UPDATE siac_t_abi_master 
          SET abi_desc=descrizione,
          data_modifica=NOW(),
          login_operazione=login_oper
          WHERE abi_code=codice;
          
        ret := 'UPD ABI ' || codice;

  ELSE
      ret := '*** ABI ' || codice;
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