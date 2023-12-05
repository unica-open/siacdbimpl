/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_modifica_pdc_ordinativo_accertamento(
	p_loginoperazione character varying, 
	p_enteproprietarioid integer, 
	p_ordtipocode character varying, 
	p_annobilancio character varying, 
	p_ord_anno integer, 
	p_ordnumero integer, 
	p_pdcordinativo integer
)
RETURNS VARCHAR
AS $body$
DECLARE
	v_messaggiorisultato VARCHAR:= NULL;
	v_id_r_class INTEGER:=NULL;
	v_result INTEGER:=NULL;
    v_login_operazione VARCHAR:='BackofficeModificaPianoDeiContiOrdinativo';
   	v_ambito VARCHAR:=NULL;
BEGIN
	
  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_accertamento] MODIFICA PDC MOVIMENTO DI ENTRATA: [INIZIO].';
	
	v_messaggiorisultato:= ' INSERIMENTO RELAZIONE CLASSIFICATORE ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_accertamento] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;

	INSERT INTO siac_r_movgest_class
	(
		movgest_ts_id,
		classif_id,
		validita_inizio,
		ente_proprietario_id,
		login_operazione
	)
	SELECT DISTINCT srmc.movgest_ts_id,
		p_pdcOrdinativo,
		now(),
		stmt.ente_proprietario_id,
		p_loginOperazione
	FROM siac_t_ordinativo sto
	JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId 
	JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
	JOIN siac_t_ordinativo_ts stot ON sto.ord_id = stot.ord_id 
	JOIN siac_r_ordinativo_ts_movgest_ts srotmt ON stot.ord_ts_id = srotmt.ord_ts_id 
	JOIN siac_t_movgest_ts stmt ON stmt.movgest_ts_id = srotmt.movgest_ts_id 
	JOIN siac_t_movgest stm ON stmt.movgest_id = stm.movgest_id 
	JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
	JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
	JOIN siac_r_movgest_class srmc ON stmt.movgest_ts_id = srmc.movgest_ts_id 
	JOIN siac_t_class stc ON srmc.classif_id = stc.classif_id 
	WHERE stp.anno = p_annoBilancio
	AND sto.ord_anno = p_ord_anno
	AND sto.ord_numero = p_ordNumero
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND NOT EXISTS (
		SELECT 1
		FROM siac_t_ordinativo sto
		JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId 
		JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
		JOIN siac_r_ordinativo_ts_movgest_ts srotmt ON stot.ord_ts_id = srotmt.ord_ts_id 
		JOIN siac_t_movgest_ts stmt ON stmt.movgest_ts_id = srotmt.movgest_ts_id 
		JOIN siac_t_movgest stm ON stmt.movgest_id = stm.movgest_id 
		JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
		JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
		JOIN siac_r_movgest_class srmc ON stmt.movgest_ts_id = srmc.movgest_ts_id 
		JOIN siac_t_class stc ON srmc.classif_id = stc.classif_id 
		WHERE stp.anno = p_annoBilancio
		AND sto.ord_anno = p_ord_anno
		AND sto.ord_numero = p_ordNumero
		AND sdot.ord_tipo_code = p_ordTipoCode
		AND srmc.classif_id = p_pdcordinativo
		AND stm.data_cancellazione IS  NULL 
		AND ( stm.validita_fine IS  NULL OR stm.validita_fine < current_timestamp )
		AND stmt.data_cancellazione IS  NULL 
		AND ( stmt.validita_fine IS  NULL OR stmt.validita_fine < current_timestamp )
		AND srmc.data_cancellazione IS  NULL 
		AND ( srmc.validita_fine IS  NULL OR srmc.validita_fine < current_timestamp )
		AND srotmt.data_cancellazione IS  NULL 
		AND ( srotmt.validita_fine IS  NULL OR srotmt.validita_fine < current_timestamp )
	)
	AND stm.movgest_id IN (	
		SELECT DISTINCT stm.movgest_id 
		FROM siac_t_ordinativo sto
		JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId 
		JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
		JOIN siac_t_ordinativo_ts stot ON sto.ord_id = stot.ord_id 
		JOIN siac_r_ordinativo_ts_movgest_ts srotmt ON stot.ord_ts_id = srotmt.ord_ts_id 
		JOIN siac_t_movgest_ts stmt ON stmt.movgest_ts_id = srotmt.movgest_ts_id 
		JOIN siac_t_movgest stm ON stmt.movgest_id = stm.movgest_id 
		JOIN siac_d_movgest_ts_tipo sdmtt ON sdmtt.movgest_ts_tipo_id = stmt.movgest_ts_tipo_id 
		JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
		JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
		JOIN siac_r_movgest_class srmc ON stmt.movgest_ts_id = srmc.movgest_ts_id 
		JOIN siac_t_class stc ON srmc.classif_id = stc.classif_id 
		WHERE stp.anno = p_annoBilancio
		AND sto.ord_anno = p_ord_anno
		AND sto.ord_numero = p_ordNumero
		AND sdot.ord_tipo_code = p_ordTipoCode
		--AND sdmtt.movgest_ts_tipo_code = 'T'
		AND stm.data_cancellazione IS  NULL 
		AND ( stm.validita_fine IS  NULL OR stm.validita_fine < current_timestamp )
		AND stmt.data_cancellazione IS  NULL 
		AND ( stmt.validita_fine IS  NULL OR stmt.validita_fine < current_timestamp )
		AND srmc.data_cancellazione IS  NULL 
		AND ( srmc.validita_fine IS  NULL OR srmc.validita_fine < current_timestamp )
		AND srotmt.data_cancellazione IS  NULL 
		AND ( srotmt.validita_fine IS  NULL OR srotmt.validita_fine < current_timestamp )
	)
	AND srmc.data_cancellazione IS  NULL 
	AND ( srmc.validita_fine IS  NULL OR srmc.validita_fine < current_timestamp )
	AND srotmt.data_cancellazione IS  NULL 
	AND ( srotmt.validita_fine IS  NULL OR srotmt.validita_fine < current_timestamp )
	RETURNING movgest_classif_id INTO v_id_r_class;

	IF v_id_r_class IS NOT NULL THEN
		v_messaggiorisultato:=' NUOVA RELAZIONE CLASSIFICATORE con id: '||v_id_r_class||'.';
	-- in caso di pdc uguale non inserisco nulla
	--ELSE
	--	RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
	--END IF;

	  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_accertamento] v_messaggiorisultato=% FINE',v_messaggiorisultato;
	  
	  	v_messaggiorisultato:= ' INVALIDAZIONE CLASSIFICATORE PRECEDENTE ';
	
		IF p_loginOperazione != '' THEN
			v_login_operazione:= p_loginOperazione;
			v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
		END IF;
	
		RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_accertamento] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
		
		UPDATE siac_r_movgest_class srmc
		SET data_cancellazione = now(),
			validita_fine = now(),
			login_operazione = srmc.login_operazione||' - '||p_loginOperazione
		FROM siac_t_class stc, siac_d_class_tipo sdct, siac_t_ordinativo sto
		JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId 
		JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
		JOIN siac_t_ordinativo_ts stot ON sto.ord_id = stot.ord_id 
		JOIN siac_r_ordinativo_ts_movgest_ts srotmt ON stot.ord_ts_id = srotmt.ord_ts_id 
		JOIN siac_t_movgest_ts stmt ON stmt.movgest_ts_id = srotmt.movgest_ts_id 
		JOIN siac_t_movgest stm ON stmt.movgest_id = stm.movgest_id 
		JOIN siac_d_movgest_ts_tipo sdmtt ON sdmtt.movgest_ts_tipo_id = stmt.movgest_ts_tipo_id 
		JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
		JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
		WHERE stp.anno = p_annoBilancio
		AND sto.ord_anno = p_ord_anno
		AND sto.ord_numero = p_ordNumero
		AND sdot.ord_tipo_code = p_ordTipoCode
		AND stmt.movgest_ts_id = srmc.movgest_ts_id 
		AND stc.classif_id = srmc.classif_id 
		AND stc.classif_tipo_id = sdct.classif_tipo_id
		AND sdct.classif_tipo_code = 'PDC_V'
		AND sdmtt.movgest_ts_tipo_code = 'T'
		AND stc.classif_id != p_pdcOrdinativo
		AND srmc.data_cancellazione IS  NULL 
		AND ( srmc.validita_fine IS NULL OR srmc.validita_fine < current_timestamp );
	
	  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_accertamento] v_messaggiorisultato=% FINE',v_messaggiorisultato;
  
	END IF;
	
	v_result:= 0;
  
  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_accertamento] MODIFICA PDC MOVIMENTO DI ENTRATA: [COMPLETATO].';
  	
  	RETURN v_result;

EXCEPTION
    WHEN RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||SUBSTRING(UPPER(SQLERRM) from 1 for 2500);
    RAISE NOTICE '%',v_messaggiorisultato;
        v_result = v_messaggiorisultato;
   		RETURN v_result;
	WHEN OTHERS THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||SUBSTRING(UPPER(SQLERRM) from 1 for 2500);
    RAISE NOTICE '%',v_messaggiorisultato;
		v_result = v_messaggiorisultato;
   		RETURN v_result;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;