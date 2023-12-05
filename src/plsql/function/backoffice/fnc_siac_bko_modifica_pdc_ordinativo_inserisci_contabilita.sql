/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS  siac.fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita(
	p_loginoperazione character varying, 
	p_enteproprietarioid integer, 
	p_ordtipocode character varying, 
	p_annobilancio character varying, 
	p_ord_anno integer, 
	p_ordnumero integer, 
	p_ambito character varying, 
	p_eventocode character varying, 
	p_eventotipocode character varying, 
	p_pdcordinativo integer
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita(
	p_loginoperazione character varying, 
	p_enteproprietarioid integer, 
	p_ordtipocode character varying, 
	p_annobilancio character varying, 
	p_ord_anno integer, 
	p_ordnumero integer, 
	p_ambito character varying, 
	p_eventocode character varying, 
	p_eventotipocode character varying, 
	p_pdcordinativo integer
)
RETURNS VARCHAR
AS $body$
DECLARE
	v_messaggiorisultato VARCHAR:= NULL;
	v_id INTEGER:=NULL;
	v_id_stato INTEGER:=NULL;
	v_id_evento INTEGER:=NULL;
	v_result INTEGER:=NULL;
    v_login_operazione VARCHAR:='BackofficeModificaPianoDeiContiOrdinativo';
   	v_ambito VARCHAR:=NULL;
BEGIN
	
	v_messaggiorisultato:= ' INSERIMENTO REGISTRO ';
	--   raise notice '@@@QUI QUI QUI QUI  p_pdcOrdinativo %****', p_pdcOrdinativo::varchar;
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
--   raise notice '@@@QUI QUI QUI QUI  p_pdcOrdinativo %****', p_pdcOrdinativo::varchar;
 --  raise notice '@@@QUI QUI QUI QUI  p_enteproprietarioid %****', p_enteproprietarioid::varchar;
  -- raise notice '@@@QUI QUI QUI QUI  p_ordtipocode %****', p_ordtipocode::varchar;
--   raise notice '@@@QUI QUI QUI QUI  p_annobilancio %****', p_annobilancio::varchar;
--   raise notice '@@@QUI QUI QUI QUI  p_ord_anno %****', p_ord_anno::varchar;
 --  raise notice '@@@QUI QUI QUI QUI  p_ordnumero %****', p_ordnumero::varchar;
 --   raise notice '@@@QUI QUI QUI QUI  p_ambito %****', p_ambito::varchar;
  	INSERT INTO siac_t_reg_movfin 
	(
	    classif_id_iniziale,
	    classif_id_aggiornato,
	    bil_id,
	    ambito_id,
	    validita_inizio,
	    login_operazione,
	    ente_proprietario_id
	)
	SELECT DISTINCT
	(
		SELECT DISTINCT stc.classif_id 
		FROM siac_t_class stc
		JOIN siac_t_ente_proprietario step ON stc.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
		JOIN siac_r_ordinativo_class sroc ON sroc.classif_id = stc.classif_id
		JOIN siac.siac_r_class_fam_tree srcft ON ( srcft.classif_id = stc.classif_id ) 
		JOIN siac.siac_t_class_fam_tree stcft ON ( stcft.classif_fam_tree_id = srcft.classif_fam_tree_id AND stcft.class_fam_code = 'Piano dei Conti' ) 
		JOIN siac_t_ordinativo sto ON sto.ord_id = sroc.ord_id 
		JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
		JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
		JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id
		WHERE stp.anno = p_annoBilancio
		AND sto.ord_numero = p_ordNumero
		AND sto.ord_anno = p_ord_anno
		AND sdot.ord_tipo_code = p_ordTipoCode
		AND sto.data_cancellazione is NULL
		AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
		AND sdot.data_cancellazione is NULL
		AND ( sdot.validita_fine is NULL OR sdot.validita_fine < CURRENT_TIMESTAMP )
		AND sroc.data_cancellazione is NULL
		AND ( sroc.validita_fine is NULL OR sroc.validita_fine < CURRENT_TIMESTAMP )
		AND stc.data_cancellazione is NULL
		AND ( stc.validita_fine is NULL OR stc.validita_fine < CURRENT_TIMESTAMP )
		AND srcft.data_cancellazione is NULL
		AND ( srcft.validita_fine is NULL OR srcft.validita_fine < CURRENT_TIMESTAMP )
	),
	p_pdcOrdinativo,
	(
		SELECT DISTINCT stb.bil_id   -- 30.06.2023 Sofia SIAC-TASK-136
		FROM siac_t_ordinativo sto, siac_d_ordinativo_tipo sdot ,siac_t_bil stb,siac_t_periodo stp
		WHERE   stp.ente_proprietario_id =p_enteProprietarioId
		and            stp.anno = p_annoBilancio
		and            stb.periodo_id = stp.periodo_id 
		and            sto.bil_id = stb.bil_id
		and            sto.ord_tipo_id = sdot.ord_tipo_id
		AND          sdot.ord_tipo_code = p_ordTipoCode		
		AND          sto.ord_numero = p_ordNumero
		AND          sto.ord_anno = p_ord_anno
		AND sto.data_cancellazione is NULL
		AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
		AND sdot.data_cancellazione is NULL
		AND ( sdot.validita_fine is NULL OR sdot.validita_fine < CURRENT_TIMESTAMP )
		AND stp.data_cancellazione is NULL
		AND ( stp.validita_fine is NULL OR stp.validita_fine < CURRENT_TIMESTAMP )
		AND stb.data_cancellazione is NULL
		AND ( stb.validita_fine is NULL OR stp.validita_fine < CURRENT_TIMESTAMP )
	),
	(
		SELECT DISTINCT sda.ambito_id
		FROM siac_d_ambito sda 
		JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = sda.ente_proprietario_id and step.ente_proprietario_id = p_enteProprietarioId
		WHERE sda.ambito_code = p_ambito
		AND sda.data_cancellazione is NULL
		AND ( sda.validita_fine is NULL OR sda.validita_fine < CURRENT_TIMESTAMP ) 
	),
	now(),
	p_loginOperazione,
	p_enteProprietarioId
	RETURNING regmovfin_id INTO v_id;
	 --raise notice '2 @@@ QUI QUI QUI QUI ****';
	  
	  
	IF v_id IS NOT NULL THEN
		v_messaggiorisultato:=' INSERITO REGISTRO con id: '||v_id||'.';
	ELSE
		RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
	END IF;

  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
	
  	v_messaggiorisultato:= ' ASSOCIAZIONE REGISTRO con id: '||v_id||' A STATO: [NOTIFICATO] ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
    
  	INSERT INTO siac_r_reg_movfin_stato
	(
	    regmovfin_id,
	    regmovfin_stato_id,
	    validita_inizio,
	    login_operazione,
	    ente_proprietario_id
	)
	SELECT v_id,
		sdrms.regmovfin_stato_id,
		now(),
		p_loginOperazione,
		p_enteProprietarioId
	FROM siac_t_ordinativo sto
	JOIN siac_t_ente_proprietario step on sto.ente_proprietario_id = step.ente_proprietario_id and step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_d_ordinativo_tipo sdot on sto.ord_tipo_id = sdot.ord_tipo_id 
	JOIN siac_t_bil stb on sto.bil_id = stb.bil_id 
	JOIN siac_t_periodo stp on stp.periodo_id = stb.periodo_id 
	JOIN siac_d_reg_movfin_stato sdrms on sdrms.ente_proprietario_id = step.ente_proprietario_id
	WHERE stp.anno = p_annoBilancio
	AND sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND sdrms.regmovfin_stato_code = 'N'
	RETURNING regmovfin_stato_r_id INTO v_id_stato;

	IF v_id_stato IS NOT NULL THEN
		v_messaggiorisultato:=' ASSOCIATO REGISTRO con id: '||v_id||' A STATO: [NOTIFICATO] ';
	ELSE
		RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
	END IF;

  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
  
  	v_messaggiorisultato:= ' ASSOCIAZIONE REGISTRO con id: '||v_id||' AD EVENTO: ['||p_eventoCode||']';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
    
  	INSERT INTO siac_r_evento_reg_movfin 
	(
		regmovfin_id,
		evento_id,
		campo_pk_id,
		validita_inizio,
		login_operazione,
		ente_proprietario_id
	)
	SELECT DISTINCT
	    v_id,
	    sde.evento_id,
	    sto.ord_id,
	    now(),
	    p_loginOperazione,
	    sto.ente_proprietario_id
	FROM siac_t_ordinativo sto 
	JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
	JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
	JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
	JOIN siac_r_evento_reg_movfin srerm ON sto.ord_id = srerm.campo_pk_id
	JOIN siac_d_evento sde ON step.ente_proprietario_id = sde.ente_proprietario_id 
	JOIN siac_d_evento_tipo sdet ON sde.evento_tipo_id = sdet.evento_tipo_id 
	JOIN siac_t_reg_movfin strm ON srerm.regmovfin_id = strm.regmovfin_id 
	WHERE stp.anno = p_annoBilancio
	AND sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND sde.evento_code = p_eventoCode
	AND sdet.evento_tipo_code = p_eventoTipoCode
	-- controllare lo stesso anno di bilancio sulla r
	AND strm.bil_id = stb.bil_id 
	AND sto.data_cancellazione is NULL
	AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
	AND srerm.data_cancellazione is NULL
	AND ( srerm.validita_fine is NULL OR srerm.validita_fine < CURRENT_TIMESTAMP )
	RETURNING evmovfin_id INTO v_id_evento;
  
	IF v_id_evento IS NOT NULL THEN
		v_messaggiorisultato:=' ASSOCIATO REGISTRO con id: '||v_id||' AD EVENTO: ['||p_eventoCode||']';
	ELSE
		RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
	END IF;

  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
--  
  	v_messaggiorisultato:= ' INVALIDAMENTO RECORD PRECEDENTE ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;

	UPDATE siac_r_evento_reg_movfin srerm
	SET data_cancellazione = now(),
		validita_fine = now(),
		login_operazione = srerm.login_operazione||' - '||p_loginOperazione
	FROM siac_t_reg_movfin strm , siac_d_ambito sda , siac_t_ordinativo sto 
	JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
	JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
	JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
	WHERE srerm.regmovfin_id = strm.regmovfin_id
	AND sda.ambito_id = strm.ambito_id
	AND sto.ord_id = srerm.campo_pk_id
	-- controllare lo stesso anno di bilancio sulla r
	AND strm.bil_id = stb.bil_id 
	AND stp.anno = p_annoBilancio
	AND sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND srerm.evmovfin_id != v_id_evento
	AND sda.ambito_code = p_ambito
	AND sto.data_cancellazione is NULL
	AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
	AND srerm.data_cancellazione is NULL
	AND ( srerm.validita_fine is NULL OR srerm.validita_fine < CURRENT_TIMESTAMP );
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;
	
	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
  
  	v_result:= 0;
  	v_ambito:= p_ambito;
  
  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] INSERIMENTO CONTABILITA % COMPLETATO.', v_ambito;
  	
  	RETURN v_result;
  
EXCEPTION
    WHEN RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||SUBSTRING(UPPER(SQLERRM) from 1 for 2500);
    RAISE NOTICE '%',v_messaggiorisultato;
        v_result = v_messaggiorisultato;
   		RETURN v_result;
	WHEN OTHERS THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' OTHERS - ' ||SUBSTRING(UPPER(SQLERRM) from 1 for 2500);
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

alter function  siac.fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita  ( character varying,  integer,  character varying,  character varying,  integer,  integer,  character varying,  character varying, character varying,  integer )  owner to siac;