/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_modifica_pdc_ordinativo(
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
	v_ord_id INTEGER:=NULL;
    v_login_operazione VARCHAR:='BackofficeModificaPianoDeiContiOrdinativo';
   	v_ambito VARCHAR:=NULL;
BEGIN
	
  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo] MODIFICA PDC ORDINATIVO: [INIZIO].';

  	v_messaggiorisultato:= ' SPOSTAMENTO PIANO DEI CONTI ORDINATIVO ';

	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_impegno] v_messaggiorisultato=% INIZIO', v_messaggiorisultato;

 	INSERT INTO siac_r_ordinativo_class
	(
		ord_id,
		classif_id,
		validita_inizio,
		login_operazione,
		ente_proprietario_id
	)
	SELECT DISTINCT sroc.ord_id,
		p_pdcordinativo,
		now(),
		p_loginOperazione,
		step.ente_proprietario_id
	FROM siac_t_ordinativo sto 
	JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId 
	JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
	JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
	JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
	JOIN siac_r_ordinativo_class sroc ON sroc.ord_id = sto.ord_id 
	WHERE sdot.ord_tipo_code= p_ordTipoCode
	AND stp.anno = p_annoBilancio
	AND sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND NOT EXISTS (
		SELECT 1
		FROM siac_t_ordinativo sto
		JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId 
		JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
		JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
		JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
		JOIN siac_r_ordinativo_class sroc ON sroc.ord_id = sto.ord_id 
		WHERE sdot.ord_tipo_code = p_ordTipoCode
		AND stp.anno = p_annoBilancio
		AND sto.ord_numero = p_ordNumero
		AND sto.ord_anno = p_ord_anno
		AND sroc.classif_id = p_pdcordinativo
		AND sroc.data_cancellazione IS NULL 
		AND ( sroc.validita_fine IS  NULL OR sroc.validita_fine < current_timestamp )
		AND sto.data_cancellazione IS NULL 
		AND ( sto.validita_fine IS  NULL OR sto.validita_fine < current_timestamp )
	)
	AND sroc.data_cancellazione IS NULL 
	AND ( sroc.validita_fine IS  NULL OR sroc.validita_fine < current_timestamp )
	AND sto.data_cancellazione IS NULL 
	AND ( sto.validita_fine IS  NULL OR sto.validita_fine < current_timestamp )
	RETURNING ord_classif_id INTO v_id_r_class;

	IF v_id_r_class IS NOT NULL THEN
		v_messaggiorisultato:=' NUOVA RELAZIONE CLASSIFICATORE con id: '||v_id_r_class||'.';
	-- in caso di pdc uguale non inserisco nulla
	--ELSE
	--	RAISE EXCEPTION ' NESSUN RECORD INSERITO ';
	--END IF; 

	  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
	
		v_messaggiorisultato:= ' INVALIDAZIONE PIANO DEI CONTI PRECEDENTE ';
	
		IF p_loginOperazione != '' THEN
			v_login_operazione:= p_loginOperazione;
			v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
		END IF;
	
		RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_impegno] v_messaggiorisultato=% INIZIO', v_messaggiorisultato;
	
		UPDATE siac_r_ordinativo_class sroc
		SET data_cancellazione = now(),
			validita_fine = now(),
			login_operazione = sroc.login_operazione||' - '||p_loginOperazione
		FROM siac_t_class stc, siac_d_class_tipo sdct, siac_t_ordinativo sto
		JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId 
		JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
		JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
		JOIN siac_t_periodo stp ON stp.periodo_id = stb.periodo_id 
		WHERE sto.ord_id = sroc.ord_id 
		AND sroc.classif_id = stc.classif_id 
		AND stc.classif_tipo_id = sdct.classif_tipo_id 
		AND sdot.ord_tipo_code = p_ordTipoCode
		AND stp.anno = p_annoBilancio
		AND sto.ord_numero = p_ordNumero
		AND sto.ord_anno = p_ord_anno
		AND sroc.classif_id != p_pdcordinativo
		AND sdct.classif_tipo_code = 'PDC_V'
		AND sroc.data_cancellazione IS NULL 
		AND ( sroc.validita_fine IS  NULL OR sroc.validita_fine < current_timestamp );
	
	  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
	  
	END IF;

    v_result:= 0;
  
  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo] MODIFICA PDC ORDINATIVO: [COMPLETATO].';
  	
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