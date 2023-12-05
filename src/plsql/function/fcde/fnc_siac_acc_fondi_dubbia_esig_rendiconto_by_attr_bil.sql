/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil (
  p_afde_bil_id integer
)
RETURNS TABLE (
  versione integer,
  fase_attributi_bilancio varchar,
  stato_attributi_bilancio varchar,
  data_ora_elaborazione timestamp,
  anni_esercizio varchar,
  riscossione_virtuosa boolean,
  quinquennio_riferimento varchar,
  capitolo varchar,
  articolo varchar,
  ueb varchar,
  titolo_entrata varchar,
  tipologia varchar,
  categoria varchar,
  sac varchar,
  residui_4 numeric,
  incassi_conto_residui_4 numeric,
  residui_3 numeric,
  incassi_conto_residui_3 numeric,
  residui_2 numeric,
  incassi_conto_residui_2 numeric,
  residui_1 numeric,
  incassi_conto_residui_1 numeric,
  residui_0 numeric,
  incassi_conto_residui_0 numeric,
  media_semplice_totali numeric,
  media_semplice_rapporti numeric,
  media_ponderata_totali numeric,
  media_ponderata_rapporti numeric,
  media_utente numeric,
  percentuale_minima numeric,
  percentuale_effettiva numeric,
  residui_finali numeric,
  accantonamento_fcde numeric,
  accantonamento_graduale numeric
) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
    v_anno_bil				   VARCHAR;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
        --SIAC-8706 25/05/2022.
        --Aggiunto l'anno del bilancio che serve per le nuove query inserite per
        --il calcolo dei residui finali.
        , siac_t_periodo.anno        
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
        , v_anno_bil
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			-- TODO: aggiungere i dati delle variazioni non definitive e non annullate
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		),
--SIAC-8706 25/05/2022.
--Cambia il calcolo dei resudui finali che deve essere calcolato come nel 
--report BILR203 - campo "TOTALE RESIDUI ATTIVI DA RIPORTARE (TR=EP+EC)".
--Di seguito sono introdotte le query che concorrono al calcolo nel report BILR203
-- Applicando la formula : (A-RC) + (RS-RR+R)  .   
        residui_attivi_RS as (        	
        select capitolo.elem_id, 
                sum (dt_movimento.movgest_ts_det_importo) imp_residui_attivi_RS
            from 
              siac_t_bil      bilancio, 
              siac_t_periodo     anno_eserc, 
              siac_t_bil_elem     capitolo , 
              siac_r_movgest_bil_elem   r_mov_capitolo, 
              siac_d_bil_elem_tipo    t_capitolo, 
              siac_t_movgest     movimento, 
              siac_d_movgest_tipo    tipo_mov, 
              siac_t_movgest_ts    ts_movimento, 
              siac_r_movgest_ts_stato   r_movimento_stato, 
              siac_d_movgest_stato    tipo_stato, 
              siac_t_movgest_ts_det   dt_movimento, 
              siac_d_movgest_ts_tipo   ts_mov_tipo, 
              siac_d_movgest_ts_det_tipo  dt_mov_tipo 
              where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
              and bilancio.bil_id      				=	capitolo.bil_id
              and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
              and movimento.bil_id					=	bilancio.bil_id
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
               and anno_eserc.ente_proprietario_id   = v_ente_proprietario_id 
              and anno_eserc.anno       			=   v_anno_bil
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
                and movimento.movgest_anno  	< 	v_anno_bil::integer
              and tipo_mov.movgest_tipo_code    	= 'A'
               and tipo_stato.movgest_stato_code   in ('D','N')       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'I'--'A' 
              and now() between r_mov_capitolo.validita_inizio 
                and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() between r_movimento_stato.validita_inizio 
                and COALESCE(r_movimento_stato.validita_fine,now())
              and anno_eserc.data_cancellazione    	is null 
              and bilancio.data_cancellazione     	is null 
              and capitolo.data_cancellazione     	is null 
              and r_mov_capitolo.data_cancellazione is null 
              and t_capitolo.data_cancellazione    	is null 
              and movimento.data_cancellazione     	is null 
              and tipo_mov.data_cancellazione     	is null 
              and r_movimento_stato.data_cancellazione   is null 
              and ts_movimento.data_cancellazione   is null 
              and tipo_stato.data_cancellazione    	is null 
              and dt_movimento.data_cancellazione   is null 
              and ts_mov_tipo.data_cancellazione    is null 
              and dt_mov_tipo.data_cancellazione    is null              
			group by capitolo.elem_id),
	accertamenti_A as (        	
        select capitolo.elem_id, 
                sum (dt_movimento.movgest_ts_det_importo) imp_accertamenti_A
            from 
              siac_t_bil      bilancio, 
              siac_t_periodo     anno_eserc, 
              siac_t_bil_elem     capitolo , 
              siac_r_movgest_bil_elem   r_mov_capitolo, 
              siac_d_bil_elem_tipo    t_capitolo, 
              siac_t_movgest     movimento, 
              siac_d_movgest_tipo    tipo_mov, 
              siac_t_movgest_ts    ts_movimento, 
              siac_r_movgest_ts_stato   r_movimento_stato, 
              siac_d_movgest_stato    tipo_stato, 
              siac_t_movgest_ts_det   dt_movimento, 
              siac_d_movgest_ts_tipo   ts_mov_tipo, 
              siac_d_movgest_ts_det_tipo  dt_mov_tipo 
              where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
              and bilancio.bil_id      				=	capitolo.bil_id
              and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
              and movimento.bil_id					=	bilancio.bil_id
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
               and anno_eserc.ente_proprietario_id   = v_ente_proprietario_id 
              and anno_eserc.anno       			=   v_anno_bil 
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
                and movimento.movgest_anno  	= 	v_anno_bil::integer
              and tipo_mov.movgest_tipo_code    	= 'A'
               and tipo_stato.movgest_stato_code   in ('D','N')       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' 
              and now() between r_mov_capitolo.validita_inizio 
                and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() between r_movimento_stato.validita_inizio 
                and COALESCE(r_movimento_stato.validita_fine,now())
              and anno_eserc.data_cancellazione    	is null 
              and bilancio.data_cancellazione     	is null 
              and capitolo.data_cancellazione     	is null 
              and r_mov_capitolo.data_cancellazione is null 
              and t_capitolo.data_cancellazione    	is null 
              and movimento.data_cancellazione     	is null 
              and tipo_mov.data_cancellazione     	is null 
              and r_movimento_stato.data_cancellazione   is null 
              and ts_movimento.data_cancellazione   is null 
              and tipo_stato.data_cancellazione    	is null 
              and dt_movimento.data_cancellazione   is null 
              and ts_mov_tipo.data_cancellazione    is null 
              and dt_mov_tipo.data_cancellazione    is null              
			group by capitolo.elem_id),
      risc_conto_comp_RC as(
       select 		r_capitolo_ordinativo.elem_id,
             sum(ordinativo_imp.ord_ts_det_importo) imp_risc_conto_comp_RC
            from siac_t_bil 						bilancio,
                 siac_t_periodo 					anno_eserc, 
                 siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
                 siac_t_ordinativo				ordinativo,
                 siac_d_ordinativo_tipo			tipo_ordinativo,
                 siac_r_ordinativo_stato			r_stato_ordinativo,
                 siac_d_ordinativo_stato			stato_ordinativo,
                 siac_t_ordinativo_ts 			ordinativo_det,
                 siac_t_ordinativo_ts_det 		ordinativo_imp,
                 siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
                 siac_t_movgest     				movimento,
                 siac_t_movgest_ts    			ts_movimento, 
                 siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
        where 	bilancio.periodo_id					=	anno_eserc.periodo_id
            and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
            and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
            and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
            and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
            and	ordinativo.bil_id					=	bilancio.bil_id
            and	ordinativo.ord_id					=	ordinativo_det.ord_id
            and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
            and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
            and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
            and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
            and	ts_movimento.movgest_id				=	movimento.movgest_id
            and movimento.bil_id					=	bilancio.bil_id								   		
            and	bilancio.ente_proprietario_id	=	v_ente_proprietario_id
            and	anno_eserc.anno						= 	v_anno_bil
            and	tipo_ordinativo.ord_tipo_code		= 	'I'	--Ordnativo di incasso
            and	stato_ordinativo.ord_stato_code		<> 'A'
            and	ordinativo_imp_tipo.ord_ts_det_tipo_code	= 'A' -- importo attuala
            and	movimento.movgest_anno				=	v_anno_bil::integer	        	
            and	bilancio.data_cancellazione 				is null
            and	anno_eserc.data_cancellazione 				is null
            and	r_capitolo_ordinativo.data_cancellazione	is null
            and	ordinativo.data_cancellazione				is null
            AND	tipo_ordinativo.data_cancellazione			is null
            and	r_stato_ordinativo.data_cancellazione		is null
            AND	stato_ordinativo.data_cancellazione			is null
            AND ordinativo_det.data_cancellazione			is null
            aND ordinativo_imp.data_cancellazione			is null
            and ordinativo_imp_tipo.data_cancellazione		is null
            and	movimento.data_cancellazione				is null
            and	ts_movimento.data_cancellazione				is null
            and	r_ordinativo_movgest.data_cancellazione		is null
            and now() between r_capitolo_ordinativo.validita_inizio 
                and COALESCE(r_capitolo_ordinativo.validita_fine,now())
            and now() between r_stato_ordinativo.validita_inizio 
                and COALESCE(r_stato_ordinativo.validita_fine,now())
            and now() between r_ordinativo_movgest.validita_inizio
             and COALESCE(r_ordinativo_movgest.validita_fine,now())  
         group by r_capitolo_ordinativo.elem_id),
	risc_conto_residui_RR as(
       select 		r_capitolo_ordinativo.elem_id,
             sum(ordinativo_imp.ord_ts_det_importo) risc_conto_residui_RR
            from siac_t_bil 						bilancio,
                 siac_t_periodo 					anno_eserc, 
                 siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
                 siac_t_ordinativo				ordinativo,
                 siac_d_ordinativo_tipo			tipo_ordinativo,
                 siac_r_ordinativo_stato			r_stato_ordinativo,
                 siac_d_ordinativo_stato			stato_ordinativo,
                 siac_t_ordinativo_ts 			ordinativo_det,
                 siac_t_ordinativo_ts_det 		ordinativo_imp,
                 siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
                 siac_t_movgest     				movimento,
                 siac_t_movgest_ts    			ts_movimento, 
                 siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
        where 	bilancio.periodo_id					=	anno_eserc.periodo_id
            and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
            and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
            and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
            and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
            and	ordinativo.bil_id					=	bilancio.bil_id
            and	ordinativo.ord_id					=	ordinativo_det.ord_id
            and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
            and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
            and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
            and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
            and	ts_movimento.movgest_id				=	movimento.movgest_id
            and movimento.bil_id					=	bilancio.bil_id								   		
            and	bilancio.ente_proprietario_id	=	v_ente_proprietario_id
            and	anno_eserc.anno						= 	v_anno_bil
            and	tipo_ordinativo.ord_tipo_code		= 	'I'	--Ordnativo di incasso
            and	stato_ordinativo.ord_stato_code		<> 'A'
            and	ordinativo_imp_tipo.ord_ts_det_tipo_code	= 'A' -- importo attuala
            and	movimento.movgest_anno				<	v_anno_bil::integer	        	
            and	bilancio.data_cancellazione 				is null
            and	anno_eserc.data_cancellazione 				is null
            and	r_capitolo_ordinativo.data_cancellazione	is null
            and	ordinativo.data_cancellazione				is null
            AND	tipo_ordinativo.data_cancellazione			is null
            and	r_stato_ordinativo.data_cancellazione		is null
            AND	stato_ordinativo.data_cancellazione			is null
            AND ordinativo_det.data_cancellazione			is null
            aND ordinativo_imp.data_cancellazione			is null
            and ordinativo_imp_tipo.data_cancellazione		is null
            and	movimento.data_cancellazione				is null
            and	ts_movimento.data_cancellazione				is null
            and	r_ordinativo_movgest.data_cancellazione		is null
            and now() between r_capitolo_ordinativo.validita_inizio 
                and COALESCE(r_capitolo_ordinativo.validita_fine,now())
            and now() between r_stato_ordinativo.validita_inizio 
                and COALESCE(r_stato_ordinativo.validita_fine,now())
            and now() between r_ordinativo_movgest.validita_inizio
             and COALESCE(r_ordinativo_movgest.validita_fine,now())  
         group by r_capitolo_ordinativo.elem_id),
	riaccertamenti_residui_R as (
        select capitolo.elem_id,
           sum (t_movgest_ts_det_mod.movgest_ts_det_importo) imp_riaccertamenti_residui_R
            from 
              siac_t_bil      bilancio, 
              siac_t_periodo     anno_eserc, 
              siac_t_bil_elem     capitolo , 
              siac_r_movgest_bil_elem   r_mov_capitolo, 
              siac_d_bil_elem_tipo    t_capitolo, 
              siac_t_movgest     movimento, 
              siac_d_movgest_tipo    tipo_mov, 
              siac_t_movgest_ts    ts_movimento, 
              siac_r_movgest_ts_stato   r_movimento_stato, 
              siac_d_movgest_stato    tipo_stato, 
              siac_t_movgest_ts_det   dt_movimento, 
              siac_d_movgest_ts_tipo   ts_mov_tipo, 
              siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
              siac_t_modifica t_modifica,
              siac_r_modifica_stato r_mod_stato,
              siac_d_modifica_stato d_mod_stato,
              siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
              where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id
              and bilancio.bil_id      				=	capitolo.bil_id
              and movimento.bil_id					=	bilancio.bil_id
              and r_mov_capitolo.elem_id    		=	capitolo.elem_id
              and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
              and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
              and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
              and movimento.movgest_id      		= 	ts_movimento.movgest_id 
              and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
              and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
              and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id
              and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
              and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
              and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
              and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
              and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
              and r_mod_stato.mod_id=t_modifica.mod_id      
              and anno_eserc.ente_proprietario_id   = v_ente_proprietario_id        
              and anno_eserc.anno       			=   v_anno_bil 
              and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
              and movimento.movgest_anno   			< 	v_anno_bil::integer
              and tipo_mov.movgest_tipo_code    	= 'A' --Accertamento 
              and tipo_stato.movgest_stato_code   in ('D','N')       
              and ts_mov_tipo.movgest_ts_tipo_code  = 'T' --Testata
              and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' --importo attuale 
              and d_mod_stato.mod_stato_code='V'            
              and now() between r_mov_capitolo.validita_inizio 
                and COALESCE(r_mov_capitolo.validita_fine,now())
              and now() between r_movimento_stato.validita_inizio 
                and COALESCE(r_movimento_stato.validita_fine,now())
              and now()between r_mod_stato.validita_inizio 
                and COALESCE(r_mod_stato.validita_fine,now())
              and anno_eserc.data_cancellazione    	is null 
              and bilancio.data_cancellazione     	is null 
              and capitolo.data_cancellazione     	is null 
              and r_mov_capitolo.data_cancellazione is null 
              and t_capitolo.data_cancellazione    	is null 
              and movimento.data_cancellazione     	is null 
              and tipo_mov.data_cancellazione     	is null 
              and r_movimento_stato.data_cancellazione   is null 
              and ts_movimento.data_cancellazione   is null 
              and tipo_stato.data_cancellazione    	is null 
              and dt_movimento.data_cancellazione   is null 
              and ts_mov_tipo.data_cancellazione    is null 
              and dt_mov_tipo.data_cancellazione    is null
              and t_movgest_ts_det_mod.data_cancellazione    is null
              and r_mod_stato.data_cancellazione    is null
              and t_modifica.data_cancellazione    is null    
        group by capitolo.elem_id)                               
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				WHEN 'SEMP_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				WHEN 'POND_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				WHEN 'POND_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
				WHEN 'UTENTE'   THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			--SIAC-8706 25/05/2022.
            --Cambia la formula per i residui finali
            --, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS residui_finali
            , COALESCE(res_att_RS.imp_residui_attivi_RS, 0) AS imp_residui_attivi_RS
			, COALESCE(accert_A.imp_accertamenti_A, 0) AS imp_accertamenti_A
            , COALESCE(risc_cc_RC.imp_risc_conto_comp_RC, 0) as imp_risc_conto_comp_RC
            , COALESCE(risc_cres_RR.risc_conto_residui_RR, 0) as risc_conto_residui_RR
            , COALESCE(riacc_res_R.imp_riaccertamenti_residui_R, 0) as imp_riaccertamenti_residui_R           
            --, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS residui_finali_1
			--, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS residui_finali_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		--SIAC-8706 25/05/2022.
        --Aggiunte le tabelle per il calcolo dei residui finali.
        LEFT OUTER JOIN residui_attivi_RS AS res_att_RS ON (siac_t_bil_elem.elem_id = res_att_RS.elem_id)
        LEFT OUTER JOIN accertamenti_A AS accert_A ON (siac_t_bil_elem.elem_id = accert_A.elem_id)        
        LEFT OUTER JOIN risc_conto_comp_RC AS risc_cc_RC ON (siac_t_bil_elem.elem_id = risc_cc_RC.elem_id)        
        LEFT OUTER JOIN risc_conto_residui_RR AS risc_cres_RR ON (siac_t_bil_elem.elem_id = risc_cres_RR.elem_id)       
        LEFT OUTER JOIN riaccertamenti_residui_R AS riacc_res_R ON (siac_t_bil_elem.elem_id = riacc_res_R.elem_id)        
        WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
			--SIAC-8706 25/05/2022.
            --Cambia la formula per i residui finali:
            --Residui finali = (A-RC) + (RS-RR+R)        
		--residui_finali        := v_loop_var.residui_finali;        
        residui_finali		  := (v_loop_var.imp_accertamenti_A-v_loop_var.imp_risc_conto_comp_RC)+ 
        	(v_loop_var.imp_residui_attivi_RS-v_loop_var.risc_conto_residui_RR +
             v_loop_var.imp_riaccertamenti_residui_R) ;
		--residui_finali_1      := v_loop_var.residui_finali_1;		
		--residui_finali_2      := v_loop_var.residui_finali_2;
		-- /100 perche' ho una percentuale per cui moltiplico (v_loop_var.acc_fde_media)
			--SIAC-8706 25/05/2022.
            --Cambia la formula per i residui finali
        --accantonamento_fcde   := v_loop_var.residui_finali * v_loop_var.acc_fde_media / 100;
		accantonamento_fcde   := residui_finali * v_loop_var.acc_fde_media / 100;
raise notice 'Capitolo: % - Percentuale: % - Residui finali: % - Accontonamento: %',
	        capitolo, v_loop_var.acc_fde_media, residui_finali, accantonamento_fcde;
            
        --accantonamento_fcde_1 := v_loop_var.residui_finali_1 * v_loop_var.acc_fde_media / 100;
		--accantonamento_fcde_2 := v_loop_var.residui_finali_2 * v_loop_var.acc_fde_media / 100;
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
			-- SIAC-8446 - lettura del dato da DB
			 
            --23/08/2022 SIAC-8787.
            --Nell'Excel occorre arrotondare il valore dell'accantonamento FCDE 
            --a 2 cifre decimali per evitare valori errati nei totali.
            --, siac_t_acc_fondi_dubbia_esig.acc_fde_accantonamento_anno
            , ROUND(siac_t_acc_fondi_dubbia_esig.acc_fde_accantonamento_anno,2)
		INTO
			incassi_conto_residui_4
			, residui_4
			, incassi_conto_residui_3
			, residui_3
			, incassi_conto_residui_2
			, residui_2
			, incassi_conto_residui_1
			, residui_1
			, incassi_conto_residui_0
			, residui_0
			, media_semplice_totali
			, media_semplice_rapporti
			, media_ponderata_totali
			, media_ponderata_rapporti
			, media_utente
			, percentuale_minima
			, accantonamento_fcde
		FROM siac_t_acc_fondi_dubbia_esig
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil (p_afde_bil_id integer)
  OWNER TO siac;