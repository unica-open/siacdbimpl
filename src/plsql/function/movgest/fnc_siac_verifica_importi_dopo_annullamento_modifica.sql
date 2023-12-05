/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--drop function siac.fnc_siac_verifica_importi_dopo_annullamento_modifica();



CREATE OR REPLACE FUNCTION siac.fnc_siac_verifica_importi_dopo_annullamento_modifica(idente integer, idbilancio integer, codicetipomovimento character varying, annomovimento integer, numeromovimento numeric)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE

siac_t_movgest_ts_det_A_row siac_t_movgest_ts_det%ROWTYPE;
movgest_ts_det_importo_I siac_t_movgest_ts_det.movgest_ts_det_importo%type;
movgest_ts_det_importo_sum siac_t_movgest_ts_det.movgest_ts_det_importo%type;

begin
	
  --return 'MANUTENZIONE IN CORSO';


	-- importo attuale	
	select stmtdm.* into siac_t_movgest_ts_det_A_row
	from siac_t_movgest_ts_det stmtdm, siac_t_movgest_ts stmt, siac_d_movgest_tipo sdmt,
	siac_t_movgest stm, siac_d_movgest_ts_det_tipo sdmtdt, siac_d_movgest_ts_tipo sdmtt 
	where 
	--
	stm.movgest_anno = annoMovimento 
	and stm.movgest_numero = numeroMovimento
	and stm.bil_id = idBilancio 
	and stm.ente_proprietario_id = idEnte
	--
	and stm.movgest_tipo_id = sdmt.movgest_tipo_id 
	and sdmt.movgest_tipo_code = codiceTipoMovimento
	and sdmt.ente_proprietario_id = stm.ente_proprietario_id 
	and	stmt.movgest_id = stm.movgest_id 
	and stmtdm.movgest_ts_id = stmt.movgest_ts_id 
	and stmtdm.movgest_ts_det_tipo_id = sdmtdt.movgest_ts_det_tipo_id 
	and sdmtdt.movgest_ts_det_tipo_code = 'A'
	and sdmtt.movgest_ts_tipo_id = stmt.movgest_ts_tipo_id 
	and sdmtt.movgest_ts_tipo_code = 'T'
	and sdmtt.ente_proprietario_id = stm.ente_proprietario_id
	and stmtdm.data_cancellazione is NULL
	AND stmtdm.validita_inizio < CURRENT_TIMESTAMP    
	AND (stmtdm.validita_fine IS NULL OR stmtdm.validita_fine > CURRENT_TIMESTAMP)
	;

	-- importo iniziale
	select movgest_ts_det_importo into movgest_ts_det_importo_I
	from siac_t_movgest_ts_det stmtdm, siac_t_movgest_ts stmt, siac_d_movgest_tipo sdmt,
	siac_t_movgest stm, siac_d_movgest_ts_det_tipo sdmtdt, siac_d_movgest_ts_tipo sdmtt 
	where 
	--
	stm.movgest_anno = annoMovimento 
	and stm.movgest_numero = numeroMovimento
	and stm.bil_id = idBilancio 
	and stm.ente_proprietario_id = idEnte
	--
	and stm.movgest_tipo_id = sdmt.movgest_tipo_id 
	and sdmt.movgest_tipo_code = codiceTipoMovimento
	and sdmt.ente_proprietario_id = stm.ente_proprietario_id 
	and	stmt.movgest_id = stm.movgest_id 
	and stmtdm.movgest_ts_id = stmt.movgest_ts_id 
	and stmtdm.movgest_ts_det_tipo_id = sdmtdt.movgest_ts_det_tipo_id 
	and sdmtdt.movgest_ts_det_tipo_code = 'I'
	and sdmtt.movgest_ts_tipo_id = stmt.movgest_ts_tipo_id 
	and sdmtt.movgest_ts_tipo_code = 'T'
	and sdmtt.ente_proprietario_id = stm.ente_proprietario_id
	and stmtdm.data_cancellazione is NULL
	AND stmtdm.validita_inizio < CURRENT_TIMESTAMP    
	AND (stmtdm.validita_fine IS NULL OR stmtdm.validita_fine > CURRENT_TIMESTAMP)  
    ;
	
	-- somma delle modifiche
	select coalesce(sum(stmtdm.movgest_ts_det_importo), 0) into movgest_ts_det_importo_sum
	from siac_t_movgest_ts_det_mod stmtdm, siac_r_modifica_stato srms , siac_d_modifica_stato sdms ,
	siac_t_movgest_ts stmt, siac_d_movgest_ts_tipo sdmtt, siac_t_movgest stm, siac_d_movgest_tipo sdmt, siac_d_movgest_ts_det_tipo sdmtdt
	where  
	--
	stm.movgest_anno = annoMovimento 
	and stm.movgest_numero = numeroMovimento
	and stm.bil_id = idBilancio 
	and stm.ente_proprietario_id = idEnte
	--
	and stm.movgest_tipo_id = sdmt.movgest_tipo_id 
	and sdmt.movgest_tipo_code = codiceTipoMovimento
	and sdmt.ente_proprietario_id = stm.ente_proprietario_id 
	and srms.mod_stato_r_id = stmtdm.mod_stato_r_id
	and sdms.mod_stato_id = srms.mod_stato_id 
	and sdms.mod_stato_code != 'A' 
	and stmt.movgest_id =stm.movgest_id 
	and stmtdm.movgest_ts_id = stmt.movgest_ts_id 
	and sdmtt.movgest_ts_tipo_id = stmt.movgest_ts_tipo_id 
	and sdmtt.movgest_ts_tipo_code = 'T'
	and sdmtt.ente_proprietario_id = stm.ente_proprietario_id 
	and	stmt.movgest_id = stm.movgest_id 
	and sdmtdt.movgest_ts_det_tipo_id=stmtdm.movgest_ts_det_tipo_id
	and sdmtdt.movgest_ts_det_tipo_code = 'A' 
	and sdmtdt.ente_proprietario_id = stm.ente_proprietario_id
	and stmtdm.data_cancellazione is NULL
	AND stmtdm.validita_inizio < CURRENT_TIMESTAMP    
	AND (stmtdm.validita_fine IS NULL OR stmtdm.validita_fine > CURRENT_TIMESTAMP)  
	and srms.data_cancellazione is NULL
	AND srms.validita_inizio < CURRENT_TIMESTAMP    
	AND (srms.validita_fine IS NULL OR srms.validita_fine > CURRENT_TIMESTAMP)  
	;

	if siac_t_movgest_ts_det_A_row.movgest_ts_det_importo != movgest_ts_det_importo_I + movgest_ts_det_importo_sum    
	then
		update siac_t_movgest_ts_det set
		movgest_ts_det_importo=movgest_ts_det_importo_I + movgest_ts_det_importo_sum,
		login_operazione = concat('fnc_siac_verifica_importi - ', login_operazione) 
		where movgest_ts_det_id=siac_t_movgest_ts_det_A_row.movgest_ts_det_id;	
	
		return  'fnc_siac_verifica_importi_dopo_annullamento_modifica: presente incongruenza - '||
				annoMovimento||'/'||numeroMovimento||
				'/idBilancio:'||idBilancio||
				'/movgest_ts_det_id:'||siac_t_movgest_ts_det_A_row.movgest_ts_det_id||
				'/importo_attuale:'||coalesce(siac_t_movgest_ts_det_A_row.movgest_ts_det_importo::text,'')||
				'/importo_iniziale:'||coalesce(movgest_ts_det_importo_I::text,'')||
				'/somma_importi_modifiche:'||coalesce(movgest_ts_det_importo_sum::text,'')
		;
/*	else
		return  'fnc_siac_verifica_importi_dopo_annullamento_modifica: OK - '||
				annoMovimento||'/'||numeroMovimento||
				'/idBilancio:'||idBilancio||
				'/movgest_ts_det_id:'||siac_t_movgest_ts_det_A_row.movgest_ts_det_id||
				'/importo_attuale:'||coalesce(siac_t_movgest_ts_det_A_row.movgest_ts_det_importo::text,'')||
				'/importo_iniziale:'||coalesce(movgest_ts_det_importo_I::text,'')||
				'/somma_importi_modifiche:'||coalesce(movgest_ts_det_importo_sum::text,'')
		; */
	end if;
	
	
    return null;

exception
        when others  THEN
            return 'ERR: ' || SQLERRM;
END;
$function$
;

