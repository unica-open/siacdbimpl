/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER);

CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER)
RETURNS SETOF VARCHAR AS 
$body$
DECLARE
    v_messaggiorisultato VARCHAR;
    v_perc_media_confronto NUMERIC;
    v_tipo_media_confronto VARCHAR;
    v_uid_capitolo_previsione INTEGER;
    v_elem_code VARCHAR;
    v_elem_code2 VARCHAR;
BEGIN

	SELECT stbe.elem_code, stbe.elem_code2 
	FROM siac_t_bil_elem stbe 
	WHERE stbe.elem_id = p_uid_elem_gestione
	AND stbe.data_cancellazione IS NULL INTO v_elem_code, v_elem_code2;

	v_messaggiorisultato := 'Ricerca per capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di GESTIONE';
	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	
    v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti defintivi precedenti in GESTIONE';
    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

    v_tipo_media_confronto := 'GESTIONE';

    -- GESTIONE DEFINITIVA
    SELECT 
    CASE 
	/*  SIAC-8890
		WHEN tipomedia.afde_tipo_media_code = 'SEMP_TOT' THEN tafdeEquiv.acc_fde_media_semplice_totali 
		ELSE case WHEN tipomedia.afde_tipo_media_code = 'SEMP_RAP' then tafdeEquiv.acc_fde_media_semplice_rapporti
		ELSE case WHEN tipomedia.afde_tipo_media_code = 'POND_TOT' then tafdeEquiv.acc_fde_media_ponderata_totali  
		else case WHEN tipomedia.afde_tipo_media_code = 'POND_RAP' then tafdeEquiv.acc_fde_media_ponderata_rapporti  
		ELSE case WHEN tipomedia.afde_tipo_media_code = 'UTENTE' then tafdeEquiv.acc_fde_media_utente  */
	    when tipomedia.afde_tipo_media_code != 'UTENTE' then tafdeEquiv.acc_fde_media_confronto
	    else tafdeEquiv.acc_fde_media_utente end
    FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
    JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
    JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
    JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
    JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
    JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
    JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
    JOIN siac_d_acc_fondi_dubbia_esig_tipo_media tipomedia on tipomedia.afde_tipo_media_id  = tafdeEquiv.afde_tipo_media_id
    WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
    AND tafdeEquiv.elem_id = p_uid_elem_gestione
    AND step.ente_proprietario_id = p_uid_ente_proprietario
    AND sdafdes.afde_stato_code = 'DEFINITIVA'
    AND tafdeEquiv.data_cancellazione IS NULL 
    AND tafdeEquiv.validita_fine IS NULL 
    ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    -- PREVISIONE DEFINITIVA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO DEFINITIVA - GESTIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco uid del capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT stbe.elem_id
        FROM siac_t_bil_elem stbe 
        JOIN siac_t_bil stb ON stbe.bil_id = stb.bil_id 
        JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
        JOIN siac_d_bil_elem_tipo sdbet ON stbe.elem_tipo_id = sdbet.elem_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = stbe.ente_proprietario_id 
        WHERE stbe.elem_code = v_elem_code 
        AND stbe.elem_code2 = v_elem_code2
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND stp.anno = p_anno_bilancio::VARCHAR
        AND sdbet.elem_tipo_code = 'CAP-EP'
        AND stbe.data_cancellazione IS NULL INTO v_uid_capitolo_previsione;
        
        IF v_uid_capitolo_previsione IS NOT NULL THEN
            v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - UID: [' || v_uid_capitolo_previsione || '] TROVATO.';
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	    END IF;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti DEFINTIVI precedenti in PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'PREVISIONE';

        SELECT 
            CASE 
				WHEN tipomedia.afde_tipo_media_code = 'SEMP_TOT' THEN tafdeEquiv.acc_fde_media_semplice_totali 
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'SEMP_RAP' then tafdeEquiv.acc_fde_media_semplice_rapporti
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'POND_TOT' then tafdeEquiv.acc_fde_media_ponderata_totali  
				else case WHEN tipomedia.afde_tipo_media_code = 'POND_RAP' then tafdeEquiv.acc_fde_media_ponderata_rapporti  
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'UTENTE' then tafdeEquiv.acc_fde_media_utente  
			end end end end end
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo_media tipomedia on tipomedia.afde_tipo_media_id  = tafdeEquiv.afde_tipo_media_id
        WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
        AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'DEFINITIVA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;
    
    END IF;

    -- PREVISIONE BOZZA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO DEFINITIVA - PREVISIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti in BOZZA in PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT 
         CASE 
				WHEN tipomedia.afde_tipo_media_code = 'SEMP_TOT' THEN tafdeEquiv.acc_fde_media_semplice_totali 
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'SEMP_RAP' then tafdeEquiv.acc_fde_media_semplice_rapporti
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'POND_TOT' then tafdeEquiv.acc_fde_media_ponderata_totali  
				else case WHEN tipomedia.afde_tipo_media_code = 'POND_RAP' then tafdeEquiv.acc_fde_media_ponderata_rapporti  
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'UTENTE' then tafdeEquiv.acc_fde_media_utente  
			end end end end end
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo_media tipomedia on tipomedia.afde_tipo_media_id  = tafdeEquiv.afde_tipo_media_id
        WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
        AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'BOZZA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    END IF;   

    -- GESTIONE BOZZA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO BOZZA - PREVISIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti in BOZZA in GESTIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'GESTIONE';

        SELECT 
        CASE 
				WHEN tipomedia.afde_tipo_media_code = 'SEMP_TOT' THEN tafdeEquiv.acc_fde_media_semplice_totali 
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'SEMP_RAP' then tafdeEquiv.acc_fde_media_semplice_rapporti
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'POND_TOT' then tafdeEquiv.acc_fde_media_ponderata_totali  
				else case WHEN tipomedia.afde_tipo_media_code = 'POND_RAP' then tafdeEquiv.acc_fde_media_ponderata_rapporti  
				ELSE case WHEN tipomedia.afde_tipo_media_code = 'UTENTE' then tafdeEquiv.acc_fde_media_utente  
			end end end end end
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo_media tipomedia on tipomedia.afde_tipo_media_id  = tafdeEquiv.afde_tipo_media_id
        WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
        AND tafdeEquiv.elem_id = p_uid_elem_gestione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'BOZZA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    END IF;   

    IF v_perc_media_confronto IS NULL THEN
        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO BOZZA - GESTIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
    END IF;

    IF v_perc_media_confronto IS NOT NULL THEN
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - MEDIA DI CONFRONTO: [' || v_perc_media_confronto || ' - ' || v_tipo_media_confronto || ' ]';
--	ELSE 
--		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA';
    END IF;

    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

	-- [0, 1] => [0] percentuale incasso precedente, [1] => tipoMedia
    RETURN QUERY VALUES (v_perc_media_confronto::VARCHAR), (v_tipo_media_confronto);

    EXCEPTION
        WHEN RAISE_EXCEPTION THEN
            v_messaggiorisultato := v_messaggiorisultato || ' - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;
        WHEN others THEN
            v_messaggiorisultato := v_messaggiorisultato || ' others - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;