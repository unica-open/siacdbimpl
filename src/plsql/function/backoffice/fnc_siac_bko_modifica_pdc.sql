/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_modifica_pdc(
    p_loginOperazione character varying, 
    p_enteProprietarioId integer, 
    p_ordTipoCode character varying, 
    p_annoBilancio character varying, 
    p_ordNumero integer, 
    p_eventoCode character varying, 
	p_eventoTipoCode character varying,
    p_pdcOrdinativoCode character varying,
    p_modificaAccertamento integer,
    p_aggiornaGenerale integer,
    p_aggiornaGeneraleGSA integer,
    p_inserisciGenerale integer,
    p_inserisciGeneraleGSA integer
)
RETURNS VARCHAR
AS $body$
DECLARE
	v_messaggiorisultato VARCHAR:= NULL;
	v_id_r_class INTEGER:=NULL;
	v_result INTEGER:=NULL;
	v_ord_id INTEGER:=NULL;
	v_ord_anno INTEGER:=NULL;
	v_pdc_ord INTEGER:=NULL;
    v_login_operazione VARCHAR:='BackofficeModificaPianoDeiContiOrdinativo';
   	v_ambito VARCHAR:=NULL;
BEGIN
	
  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc] MODIFICA PDC: [INIZIO].';

	v_ord_anno:= CAST( p_annoBilancio AS INTEGER );

	SELECT stc.classif_id INTO v_pdc_ord
	FROM siac_t_class stc 
	JOIN siac_t_ente_proprietario step ON stc.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId 
	JOIN siac_d_class_tipo sdct ON stc.classif_tipo_id = sdct.classif_tipo_id 
	WHERE stc.classif_code = p_pdcOrdinativoCode
	AND sdct.classif_tipo_code = 'PDC_V'
	AND stc.data_cancellazione IS NULL 
	AND ( stc.validita_fine IS  NULL OR stc.validita_fine < current_timestamp );

    IF v_pdc_ord IS NULL THEN
        RAISE EXCEPTION ' NESSUN CLASSIFICATORE TROVATO ';
	ELSE
		v_messaggiorisultato:=' TROVATO CLASSIFICATORE con id: '||v_pdc_ord||'. ';
    END IF;

    RAISE NOTICE '[fnc_siac_bko_modifica_pdc] MODIFICA PDC: % ', v_messaggiorisultato;

    v_result:= (
    	SELECT siac.fnc_siac_bko_modifica_pdc_ordinativo(
	        p_loginOperazione, 
	        p_enteProprietarioId, 
	        p_ordTipoCode, 
	        p_annoBilancio, 
	        v_ord_anno, 
	        p_ordNumero, 
	        v_pdc_ord
	    )
   	);

    IF v_result <> 0 THEN
        RAISE EXCEPTION ' EXCEPTION: fnc_siac_bko_modifica_pdc_ordinativo  ';
    END IF;

-- ENTRATA
    IF p_modificaAccertamento != 0 THEN 
        v_result:= (
        	SELECT siac.fnc_siac_bko_modifica_pdc_ordinativo_accertamento(
	            p_loginOperazione, 
	            p_enteProprietarioId, 
	            p_ordTipoCode, 
	            p_annoBilancio, 
	            v_ord_anno, 
	            p_ordNumero, 
	            v_pdc_ord
        	)
       	);

        IF v_result <> 0 THEN
            RAISE EXCEPTION ' EXCEPTION: fnc_siac_bko_modifica_pdc_ordinativo_accertamento  ';
        END IF;
    END IF;

-- AGG GENERALE
    IF p_aggiornaGenerale != 0 THEN 
        v_result:= (
        	SELECT siac.fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita(
	            p_loginOperazione, 
	            p_enteProprietarioId, 
	            p_ordTipoCode, 
	            p_annoBilancio, 
	            v_ord_anno, 
	            p_ordNumero, 
	            'AMBITO_FIN'
        	)
       	);

        IF v_result <> 0 THEN
            RAISE EXCEPTION ' EXCEPTION: fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita  ';
        END IF;
    END IF;

-- INS GENERALE
    IF p_inserisciGenerale != 0 THEN 
        v_result:= (
        	SELECT siac.fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita(
	            p_loginOperazione, 
	            p_enteProprietarioId, 
	            p_ordTipoCode, 
	            p_annoBilancio, 
	            v_ord_anno, 
	            p_ordNumero, 
	            'AMBITO_FIN', 
	            p_eventoCode, 
	            p_eventoTipoCode, 
	            v_pdc_ord
        	)
        );

        IF v_result <> 0 THEN
            RAISE EXCEPTION ' EXCEPTION: fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita  ';
        END IF;
    END IF;

-- AGG GSA
    IF p_aggiornaGeneraleGSA != 0 THEN 
        v_result:= (
        	SELECT siac.fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita(
	            p_loginOperazione, 
	            p_enteProprietarioId, 
	            p_ordTipoCode, 
	            p_annoBilancio, 
	            v_ord_anno, 
	            p_ordNumero, 
	            'AMBITO_GSA'
	        )
		);
		
        IF v_result <> 0 THEN
            RAISE EXCEPTION ' EXCEPTION: fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita [GSA] ';
        END IF;
    END IF;

-- INS GSA
    IF p_inserisciGeneraleGSA != 0 THEN 
        v_result:=(
	         SELECT siac.fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita(
	            p_loginOperazione, 
	            p_enteProprietarioId, 
	            p_ordTipoCode, 
	            p_annoBilancio, 
	            v_ord_anno, 
	            p_ordNumero, 
	            'AMBITO_GSA', 
	            p_eventoCode, 
	            p_eventoTipoCode, 
	            v_pdc_ord
	        )
	    );

        IF v_result <> 0 THEN
            RAISE EXCEPTION ' EXCEPTION: fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita [GSA] ';
        END IF;
    END IF;

  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc] MODIFICA PDC: [FINE].';

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