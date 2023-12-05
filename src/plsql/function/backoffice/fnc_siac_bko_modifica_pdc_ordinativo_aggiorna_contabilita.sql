/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita(
	p_loginoperazione character varying, 
	p_enteproprietarioid integer, 
	p_ordtipocode character varying, 
	p_annobilancio character varying, 
	p_ord_anno integer, 
	p_ordnumero integer, 
	p_ambito character varying
)
RETURNS VARCHAR
AS $body$
DECLARE
	v_messaggiorisultato VARCHAR:= NULL;
	v_pnota_id_stato INTEGER[]:=NULL;
	v_id_stato INTEGER:=NULL;
	v_result INTEGER:=NULL;
    v_login_operazione VARCHAR:='BackofficeModificaPianoDeiContiOrdinativo';
   	v_ambito VARCHAR:=NULL;
BEGIN
	
	v_messaggiorisultato:= ' INSERIMENTO PRIMA NOTA ANNULLATA ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
	
	INSERT INTO siac_r_prima_nota_stato
	(
		 pnota_id,
		 pnota_stato_id,
		 validita_inizio,
		 login_operazione,
		 ente_proprietario_id
	)
	SELECT DISTINCT
		stpn.pnota_id,
		statoDaAtribuire.pnota_stato_id,
		now(),
		p_loginOperazione,
		sto.ente_proprietario_id
	FROM siac_t_ordinativo sto
	JOIN siac_d_ordinativo_tipo sdo ON sto.ord_tipo_id = sdo.ord_tipo_id
	JOIN siac_t_bil stb ON stb.bil_id = sto.bil_id 
	JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
	JOIN siac_r_evento_reg_movfin srerm ON srerm.campo_pk_id = sto.ord_id 
	JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = srerm.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_t_reg_movfin strm ON srerm.regmovfin_id = strm.regmovfin_id 
	JOIN siac_t_mov_ep stme ON stme.regmovfin_id = strm.regmovfin_id 
	JOIN siac_t_prima_nota stpn ON stpn.pnota_id = stme.regep_id 
	JOIN siac_r_prima_nota_stato srpns ON srpns.pnota_id = stpn.pnota_id 
	JOIN siac_d_prima_nota_stato sdpns ON sdpns.pnota_stato_id = srpns.pnota_stato_id
	JOIN siac_d_prima_nota_stato statoDaAtribuire ON step.ente_proprietario_id = statoDaAtribuire.ente_proprietario_id 
	JOIN siac_d_ambito sda ON sda.ambito_id = stpn.ambito_id 
	WHERE sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND stp.anno = p_annoBilancio
	AND sdo.ord_tipo_code = p_ordTipoCode
	AND sda.ambito_code = p_ambito
	AND sdpns.pnota_stato_code != 'A'
	AND statoDaAtribuire.pnota_stato_code = 'A'
	AND sto.data_cancellazione is NULL 
	AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
	AND sdo.data_cancellazione is NULL 
	AND ( sdo.validita_fine is NULL OR sdo.validita_fine < CURRENT_TIMESTAMP )
	AND strm.data_cancellazione is NULL 
	AND ( strm.validita_fine is NULL OR strm.validita_fine < CURRENT_TIMESTAMP )
	AND stpn.data_cancellazione is NULL 
	AND ( stpn.validita_fine is NULL OR stpn.validita_fine < CURRENT_TIMESTAMP )
	AND statoDaAtribuire.data_cancellazione is NULL 
	AND ( statoDaAtribuire.validita_fine is NULL OR statoDaAtribuire.validita_fine < CURRENT_TIMESTAMP )
	AND srpns.data_cancellazione is NULL 
	AND ( srpns.validita_fine is null OR srpns.validita_fine < CURRENT_TIMESTAMP )
	AND statoDaAtribuire.data_cancellazione is NULL 
	AND ( statoDaAtribuire.validita_fine is NULL OR statoDaAtribuire.validita_fine < CURRENT_TIMESTAMP );
--	RETURNING pnota_stato_r_id INTO v_id_stato;
--
--	IF v_id_stato IS NOT NULL THEN
--		v_messaggiorisultato:=' INSERIMENTO PRIMA NOTA ANNULLATA con id: '||v_id_stato||'.';
--	ELSE
--		RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
--	END IF;

  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
  
	v_messaggiorisultato:= ' CANCELLAMENTO PRIME NOTE NON ANNULLATE ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
	
	UPDATE siac_r_prima_nota_stato srpns
	SET data_cancellazione = now(),
		validita_fine = now(),
		login_operazione = srpns.login_operazione||' - '||p_loginOperazione
	FROM siac_d_prima_nota_stato sdpns, siac_t_ordinativo sto
	JOIN siac_d_ordinativo_tipo sdo ON sto.ord_tipo_id = sdo.ord_tipo_id
	JOIN siac_t_bil stb ON stb.bil_id = sto.bil_id
	JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id
	JOIN siac_r_evento_reg_movfin srerm ON srerm.campo_pk_id = sto.ord_id
	JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = srerm.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_t_reg_movfin strm ON srerm.regmovfin_id = strm.regmovfin_id
	JOIN siac_t_mov_ep stme ON stme.regmovfin_id = strm.regmovfin_id
	JOIN siac_t_prima_nota stpn ON stpn.pnota_id = stme.regep_id
	JOIN siac_d_ambito sda ON sda.ambito_id = stpn.ambito_id
	WHERE sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND stp.anno = p_annoBilancio
	AND sdo.ord_tipo_code = p_ordTipoCode
	AND stpn.pnota_id = srpns.pnota_id
	AND sdpns.pnota_stato_id = srpns.pnota_stato_id
	AND sda.ambito_code = p_ambito
	AND sdpns.pnota_stato_code != 'A'
	AND sto.data_cancellazione is NULL
	AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
	AND sdo.data_cancellazione is NULL
	AND ( sdo.validita_fine is NULL OR sdo.validita_fine < CURRENT_TIMESTAMP )
	AND srpns.data_cancellazione is NULL
	AND ( srpns.validita_fine is NULL OR srpns.validita_fine < CURRENT_TIMESTAMP )
	AND sdpns.data_cancellazione is NULL
	AND ( sdpns.validita_fine is NULL OR sdpns.validita_fine < CURRENT_TIMESTAMP );
	
	v_messaggiorisultato:= ' CANCELLAMENTO PRIME NOTE NON ANNULLATE ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;
	
	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;

	v_messaggiorisultato:= ' INSERIMENTO REGISTRO ANNULLATO ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;

	INSERT INTO siac_r_reg_movfin_stato
	(
		regmovfin_id,
		regmovfin_stato_id,
		validita_inizio,
		login_operazione,
		ente_proprietario_id
	)
	SELECT DISTINCT
		srerm.regmovfin_id,
		stato.regmovfin_stato_id,
		now(),
		p_loginOperazione,
		step.ente_proprietario_id
	FROM siac.siac_t_ordinativo sto
	JOIN siac.siac_t_ente_proprietario step ON step.ente_proprietario_id = sto.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac.siac_d_ordinativo_tipo sdot ON sdot.ord_tipo_id = sto.ord_tipo_id 
	JOIN siac.siac_t_bil stb ON stb.bil_id = sto.bil_id
	JOIN siac.siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
	JOIN siac.siac_r_evento_reg_movfin srerm ON srerm.campo_pk_id = sto.ord_id
	JOIN siac.siac_t_reg_movfin strm ON strm.regmovfin_id = srerm.regmovfin_id 
	JOIN siac.siac_r_reg_movfin_stato srrms ON srrms.regmovfin_id = strm.regmovfin_id 
	JOIN siac.siac_d_reg_movfin_stato sdrms ON sdrms.regmovfin_stato_id = srrms.regmovfin_stato_id 
	JOIN siac_d_reg_movfin_stato stato ON stato.ente_proprietario_id = step.ente_proprietario_id 
	JOIN siac_d_ambito sda ON sda.ambito_id = strm.ambito_id 
	WHERE stp.anno = p_annoBilancio
	AND sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND sda.ambito_code = p_ambito
	AND sdrms.regmovfin_stato_code != 'A'
	AND stato.regmovfin_stato_code = 'A'
	-- controllare lo stesso anno di bilancio sulla r
	AND strm.bil_id = stb.bil_id 
	AND sto.data_cancellazione is  NULL 
	AND ( sto.validita_fine is  NULL OR sto.validita_fine < current_timestamp )
	AND sdot.data_cancellazione is  NULL 
	AND ( sdot.validita_fine is  NULL OR sdot.validita_fine < current_timestamp )
	AND strm.data_cancellazione is  NULL 
	AND ( strm.validita_fine is  NULL OR strm.validita_fine < current_timestamp )
	AND srerm.data_cancellazione is  NULL 
	AND ( srerm.validita_fine is  NULL OR srerm.validita_fine < current_timestamp )
	AND srrms.data_cancellazione is NULL 
	AND ( srrms.validita_fine is NULL OR srrms.validita_fine < current_timestamp )
	AND sdrms.data_cancellazione is  NULL 
	AND ( sdrms.validita_fine is  NULL OR sdrms.validita_fine < current_timestamp )
	AND stato.data_cancellazione is  NULL 
	AND ( stato.validita_fine is  NULL OR stato.validita_fine < current_timestamp );
--	RETURNING regmovfin_stato_r_id INTO v_id_stato;
--
--	IF v_id_stato IS NOT NULL THEN
--		v_messaggiorisultato:= ' INSERIMENTO REGISTRO ANNULLATO con id: '||v_id_stato||'.';
--	ELSE
--		RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
--	END IF;

	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;
	
	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;

	v_messaggiorisultato:= ' CANCELLAMENTO REGISTRI NON ANNULLATI ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;

	UPDATE siac_r_reg_movfin_stato srrms
	SET data_cancellazione = now(),
		validita_fine = now(),
		login_operazione = srrms.login_operazione||' - '||p_loginOperazione
	FROM siac_d_reg_movfin_stato sdrms,siac.siac_t_ordinativo sto
	JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = sto.ente_proprietario_id and step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_d_ordinativo_tipo sdot ON sdot.ord_tipo_id = sto.ord_tipo_id 
	JOIN siac_t_bil stb ON stb.bil_id = sto.bil_id
	JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
	JOIN siac_r_evento_reg_movfin srerm ON srerm.campo_pk_id = sto.ord_id
	JOIN siac_t_reg_movfin strm ON strm.regmovfin_id = srerm.regmovfin_id 
	JOIN siac_d_ambito sda ON sda.ambito_id = strm.ambito_id 
	WHERE sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND stp.anno = p_annoBilancio
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND sda.ambito_code = p_ambito
	AND sdrms.regmovfin_stato_id = srrms.regmovfin_stato_id 
	AND srrms.regmovfin_id = strm.regmovfin_id
	AND sdrms.regmovfin_stato_code != 'A'
	-- controllare lo stesso anno di bilancio sulla r
	AND strm.bil_id = stb.bil_id 
	AND sto.data_cancellazione is NULL 
	AND ( sto.validita_fine is NULL OR sto.validita_fine < current_timestamp )
	AND sdot.data_cancellazione is NULL 
	AND ( sdot.validita_fine is NULL OR sdot.validita_fine < current_timestamp )
	AND strm.data_cancellazione is NULL 
	AND ( strm.validita_fine is NULL OR strm.validita_fine < current_timestamp )
	AND srerm.data_cancellazione is NULL 
	AND ( srerm.validita_fine is NULL OR srerm.validita_fine < current_timestamp )
	AND srrms.data_cancellazione is NULL 
	AND ( srrms.validita_fine is NULL OR srrms.validita_fine < current_timestamp )
	AND sdrms.data_cancellazione is NULL 
	AND ( sdrms.validita_fine is NULL OR sdrms.validita_fine < current_timestamp );

	v_messaggiorisultato:= ' CANCELLAMENTO REGISTRI NON ANNULLATI ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;
	
	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;

  	v_result:= 0;
  	v_ambito:= p_ambito;
  
  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] AGGIORNAMENTO CONTABILITA % COMPLETATO.', v_ambito;
  	
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