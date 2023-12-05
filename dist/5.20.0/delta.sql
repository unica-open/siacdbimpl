/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- INIZIO fnc_siac_bko_mutui_caricamento_massivo.sql



\echo fnc_siac_bko_mutui_caricamento_massivo.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop function if exists siac.fnc_siac_bko_mutui_caricamento_massivo (offset_mutuo_numero integer,p_ente_code varchar);
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_mutui_caricamento_massivo (
  offset_mutuo_numero integer,
  p_ente_code varchar
)
RETURNS VOID
AS
$body$
DECLARE

BEGIN
	
	if offset_mutuo_numero is null then
		raise notice 'offset_mutuo_numero is null';
		return;
	end if;
	if p_ente_code is null then
		raise notice 'p_ente_code is null';
		return;
	end if;
	
	raise notice 'insert into siac_t_mutuo D';
	
	INSERT INTO siac.siac_t_mutuo
	(mutuo_numero, mutuo_oggetto, mutuo_stato_id, mutuo_tipo_tasso_id, mutuo_data_atto, mutuo_somma_iniziale, mutuo_somma_effettiva, mutuo_tasso, mutuo_tasso_euribor,mutuo_tasso_spread,mutuo_durata_anni, mutuo_anno_inizio, mutuo_anno_fine, mutuo_periodo_rimborso_id
	, mutuo_data_scadenza_prima_rata, mutuo_annualita, mutuo_preammortamento, mutuo_contotes_id, mutuo_attoamm_id, ente_proprietario_id, validita_inizio, data_creazione, data_modifica, login_operazione, login_creazione, login_modifica)
	select 
		offset_mutuo_numero+sbtm.bko_mutuo_numero,
		bko_mutuo_oggetto,
		sdms.mutuo_stato_id,
		sdmtt.mutuo_tipo_tasso_id,
		bko_mutuo_data_atto,
		bko_mutuo_somma_mutuata,
		bko_mutuo_somma_mutuata,
		bko_mutuo_tasso,
		bko_mutuo_tasso_euribor,
		bko_mutuo_tasso_spread,
		bko_mutuo_durata_anni,
		bko_mutuo_anno_inizio,
		bko_mutuo_anno_fine,
		sdmpr.mutuo_periodo_rimborso_id,
		to_date(bko_mutuo_scadenza_giorono||'/'||bko_mutuo_scadenza_mese||'/'||bko_mutuo_anno_inizio, 'dd/MM/yyyy'), -- data scadenza prima rata
		bko_t_mutuo_rata_group.importo_diviso_nrrate * (12/sdmpr.mutuo_periodo_numero_mesi), -- mutuo_annualita
		null, -- mutuo_preammortamento
		null, --mutuo_contotes_id
		null, --mutuo_attoamm_id
		step.ente_proprietario_id,
		now(),
		now(),
		now(), 
		'migrazione_mutui', 
		'migrazione_mutui', 
		'migrazione_mutui'
	from siac_bko_t_mutuo sbtm
	, siac_d_mutuo_stato sdms 
	, siac_d_mutuo_tipo_tasso sdmtt 
	, siac_d_mutuo_periodo_rimborso sdmpr 
	, siac_t_ente_proprietario step
	, (select
		sbtmr .bko_mutuo_numero,
		(sum(sbtmr .bko_mutuo_rata_importo_quota_capitale) + sum(sbtmr .bko_mutuo_rata_importo_quota_interessi) + sum(sbtmr .bko_mutuo_rata_importo_quota_oneri))
			/ count(*) as importo_diviso_nrrate  
		from siac_bko_t_mutuo_rata sbtmr
		group by sbtmr .bko_mutuo_numero) as  bko_t_mutuo_rata_group
	where sdms .mutuo_stato_code = 'D'
	and sdmtt.mutuo_tipo_tasso_code = sbtm.bko_mutuo_tipo_tasso
	and sdmpr.mutuo_periodo_numero_mesi = sbtm.bko_mutuo_periodo_rimborso
	and step.ente_code = p_ente_code
	and step.in_uso
	and not exists (
		select 1 from siac_t_mutuo, siac_t_ente_proprietario e
		where mutuo_numero = offset_mutuo_numero+sbtm.bko_mutuo_numero
		and e.ente_proprietario_id = step.ente_proprietario_id 
	)
	and bko_t_mutuo_rata_group.bko_mutuo_numero = sbtm.bko_mutuo_numero;
	
	raise notice 'insert into siac_t_mutuo B';
	
	INSERT INTO siac.siac_t_mutuo
	(mutuo_numero, mutuo_oggetto, mutuo_stato_id, mutuo_tipo_tasso_id, mutuo_data_atto, mutuo_somma_iniziale, mutuo_somma_effettiva, mutuo_tasso, mutuo_tasso_euribor,mutuo_tasso_spread,mutuo_durata_anni, mutuo_anno_inizio, mutuo_anno_fine, mutuo_periodo_rimborso_id
	, mutuo_data_scadenza_prima_rata, mutuo_annualita, mutuo_preammortamento, mutuo_contotes_id, mutuo_attoamm_id, ente_proprietario_id, validita_inizio, data_creazione, data_modifica, login_operazione, login_creazione, login_modifica)
	select 
		offset_mutuo_numero+sbtm.bko_mutuo_numero,
		bko_mutuo_oggetto,
		sdms.mutuo_stato_id,
		sdmtt.mutuo_tipo_tasso_id,
		bko_mutuo_data_atto,
		bko_mutuo_somma_mutuata,
		bko_mutuo_somma_mutuata,
		bko_mutuo_tasso,
		bko_mutuo_tasso_euribor,
		bko_mutuo_tasso_spread,
		bko_mutuo_durata_anni,
		bko_mutuo_anno_inizio,
		bko_mutuo_anno_fine,
		sdmpr.mutuo_periodo_rimborso_id,
		to_date(bko_mutuo_scadenza_giorono||'/'||bko_mutuo_scadenza_mese||'/'||bko_mutuo_anno_inizio, 'dd/MM/yyyy'), -- data scadenza prima rata
		0, -- mutuo_annualita
		null, -- mutuo_preammortamento
		null, --mutuo_contotes_id
		null, --mutuo_attoamm_id
		step.ente_proprietario_id,
		now(),
		now(),
		now(), 
		'migrazione_mutui', 
		'migrazione_mutui', 
		'migrazione_mutui'
	from siac_bko_t_mutuo sbtm
	, siac_d_mutuo_stato sdms 
	, siac_d_mutuo_tipo_tasso sdmtt 
	, siac_d_mutuo_periodo_rimborso sdmpr 
	, siac_t_ente_proprietario step
	where sdms .mutuo_stato_code = 'B'
	and sdmtt.mutuo_tipo_tasso_code = sbtm.bko_mutuo_tipo_tasso
	and sdmpr.mutuo_periodo_numero_mesi = sbtm.bko_mutuo_periodo_rimborso
	and step.ente_code = p_ente_code
	and step.in_uso
	and not exists (
		select 1 from siac_t_mutuo, siac_t_ente_proprietario e
		where mutuo_numero = offset_mutuo_numero+sbtm.bko_mutuo_numero
		and e.ente_proprietario_id = step.ente_proprietario_id 
	)
	and not exists (
		select 1 from siac_bko_t_mutuo_rata sbtmr
		where sbtmr.bko_mutuo_numero = sbtm.bko_mutuo_numero
	);
	

 	raise notice 'update siac_t_mutuo_num';
 	
	update siac_t_mutuo_num 
	set mutuo_numero = (select max(mutuo_numero) from siac_t_mutuo stm , siac_t_ente_proprietario step 
		where stm.ente_proprietario_id = step.ente_proprietario_id 
		and step.ente_code = p_ente_code
		and step.in_uso)
	, login_operazione = 'migrazione_mutui'
	, data_modifica = now()
	where ente_proprietario_id = (select ente_proprietario_id from siac_t_ente_proprietario step 
		where step.ente_code = p_ente_code
		and step.in_uso);
	
	raise notice 'bonifica soggetti siac_t_mutuo';
	
	update siac_t_mutuo stm
	set mutuo_soggetto_id = sts.soggetto_id
	from 
	siac_t_soggetto sts
	, (select distinct bko_mutuo_istituto_codice , bko_mutuo_istituto from siac_bko_t_mutuo sbtm ) as istituto_distinc
	, siac_bko_t_mutuo a
	where upper(sts.soggetto_desc ) like upper('%'||istituto_distinc.bko_mutuo_istituto||'%')
	and a.bko_mutuo_istituto_codice = istituto_distinc.bko_mutuo_istituto_codice
	and offset_mutuo_numero+a.bko_mutuo_numero = stm.mutuo_numero
	and stm.ente_proprietario_id=sts.ente_proprietario_id;	

	raise notice 'insert into siac.siac_t_mutuo_rata';
	
	INSERT INTO siac.siac_t_mutuo_rata
	(mutuo_id, mutuo_rata_anno, mutuo_rata_num_rata_piano, mutuo_rata_num_rata_anno, mutuo_rata_data_scadenza, mutuo_rata_importo, mutuo_rata_importo_quota_interessi, mutuo_rata_importo_quota_capitale, mutuo_rata_importo_quota_oneri
	, mutuo_rata_debito_residuo, mutuo_rata_debito_iniziale, ente_proprietario_id, validita_inizio, data_creazione, data_modifica, login_operazione, login_creazione, login_modifica)
	select 
		stm.mutuo_id,
		stbmr.bko_mutuo_rata_anno,
		(stbmr.bko_mutuo_rata_anno - stm.mutuo_anno_inizio ) * (12/sdmpr.mutuo_periodo_numero_mesi) + stbmr.bko_mutuo_rata_num_rata as numero_rata_piano,
		stbmr.bko_mutuo_rata_num_rata
		,stm.mutuo_data_scadenza_prima_rata + ((stbmr.bko_mutuo_rata_anno - stm.mutuo_anno_inizio - 1) *  (12/sdmpr.mutuo_periodo_numero_mesi) + stbmr.bko_mutuo_rata_num_rata + floor((12 - date_part('month', stm.mutuo_data_scadenza_prima_rata)) / sdmpr.mutuo_periodo_numero_mesi + 1) - 1) * CAST(sdmpr.mutuo_periodo_numero_mesi||' month' AS Interval) as  mutuo_rata_data_scadenza,
		bko_mutuo_rata_importo_quota_interessi+bko_mutuo_rata_importo_quota_capitale+bko_mutuo_rata_importo_quota_oneri as mutuo_rata_importo,
		bko_mutuo_rata_importo_quota_interessi,
		bko_mutuo_rata_importo_quota_capitale,
		bko_mutuo_rata_importo_quota_oneri,
		bko_mutuo_rata_debito_residuo,
		bko_mutuo_rata_debito_iniziale,
		step.ente_proprietario_id,
		now(),
		now(),
		now(), 
		'migrazione_mutui', 
		'migrazione_mutui', 
		'migrazione_mutui'
	from siac_bko_t_mutuo_rata stbmr
	, siac_t_mutuo stm
	, siac_t_ente_proprietario step
	, siac_d_mutuo_periodo_rimborso sdmpr 
	where stm.mutuo_numero = offset_mutuo_numero + stbmr .bko_mutuo_numero
	and step.ente_code = p_ente_code
	and step.in_uso
	and sdmpr.mutuo_periodo_rimborso_id = stm.mutuo_periodo_rimborso_id
	and not exists (
		select 1 from siac_t_mutuo_rata, siac_t_ente_proprietario e
		where siac_t_mutuo_rata.mutuo_id = stm.mutuo_id 
		and siac_t_mutuo_rata.mutuo_rata_num_rata_anno = bko_mutuo_rata_num_rata
		and siac_t_mutuo_rata.mutuo_rata_anno = bko_mutuo_rata_anno
		and e.ente_proprietario_id  = step.ente_proprietario_id
	);
	
exception
/*    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;*/
    when others  THEN
     RAISE EXCEPTION '% Errore : %-%.',' altro errore',SQLSTATE,SQLERRM;
	
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;




-- INIZIO task-125.sql



\echo task-125.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--task-125 - Paolo - INIZIO
/*per iqs2*/
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-CRUSCOTTO-IQS2','Consultazione Rendicontazione incassi indiretti IQS2',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac.siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'FUN_ACCESSORIE'
AND NOT EXISTS (
  SELECT 1
  FROM siac.siac_t_azione z
  WHERE z.azione_code = 'OP-CRUSCOTTO-IQS2'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);
--task-125 - Paolo - FINE




-- INIZIO task-142.sql



\echo task-142.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--siac-tasks-Issues #142 - MAURIZIO - INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil (
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
  incasso_conto_competenza numeric,
  accertato_conto_competenza numeric,
  percentuale_incasso_gestione numeric,
  percentuale_accantonamento numeric,
  tipo_precedente varchar,
  percentuale_precedente numeric,
  percentuale_minima numeric,
  percentuale_effettiva numeric,
  stanziamento_0 numeric,
  stanziamento_1 numeric,
  stanziamento_2 numeric,
  accantonamento_fcde_0 numeric,
  accantonamento_fcde_1 numeric,
  accantonamento_fcde_2 numeric,
  accantonamento_graduale numeric,
  stanz_senza_var_0 numeric,
  stanz_senza_var_1 numeric,
  stanz_senza_var_2 numeric,
  delta_var_0 numeric,
  delta_var_1 numeric,
  delta_var_2 numeric
) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
    v_media_utilizzo 		   NUMERIC;
    v_perc_accantonamento	   NUMERIC;
    v_accertamenti_0		   NUMERIC;
    v_accertamenti_1		   NUMERIC;
    v_accertamenti_2		   NUMERIC;
    
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
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
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
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				--SIAC-8513 la gestione ha subito delle modifiche, attualmente se non e' presente la media utente
				WHEN 'UTENTE'   THEN 
					v_componente_cento - COALESCE(
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente,
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali,
						--TODO ci sarebbe da mettere la percentuale sullo stanziamento
						siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto,
						0
					)
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			--SIAC-8768
			, COALESCE(comp_capitolo0.impSta, 0) AS stanz_senza_var_0
			, COALESCE(var_capitolo0.impSta, 0) AS delta_var_0
			, COALESCE(comp_capitolo1.impSta, 0) AS stanz_senza_var_1
			, COALESCE(var_capitolo1.impSta, 0) AS delta_var_1
			, COALESCE(comp_capitolo2.impSta, 0) AS stanz_senza_var_2
			, COALESCE(var_capitolo2.impSta, 0) AS delta_var_2
            --SIAC-8792 26/08/2022
            --Estraggo altri campi che servono per i calcoli successivi.
            , COALESCE(siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code, '') afde_tipo_media_code
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente, 0) acc_fde_media_utente
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto, 0) acc_fde_media_confronto
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali, 0) acc_fde_media_semplice_totali
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore, 0) acc_fde_numeratore
            --21/07/2023 siac-tasks-Issues #142 
            --Leggo anche i campi denominatore dove sono contenuti i valori degli accertamenti per anno che
            --servono per il calcolo dell'accantonamento FCDE.
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore, 0) acc_fde_denominatore
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_1, 0) acc_fde_denominatore_1
            , COALESCE(siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_2, 0) acc_fde_denominatore_2
			--, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS stanziamento_0
			--, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS stanziamento_1
			--, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS stanziamento_2
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
        --SIAC-8792 26/08/2022 la percentuale effettiva e' calcolata successivamente
		--percentuale_effettiva := v_loop_var.acc_fde_media;
		--stanziamento_0        := v_loop_var.stanziamento_0;
		--stanziamento_1        := v_loop_var.stanziamento_1;
		--stanziamento_2        := v_loop_var.stanziamento_2;
		stanz_senza_var_0     := v_loop_var.stanz_senza_var_0;
		stanz_senza_var_1     := v_loop_var.stanz_senza_var_1;
		stanz_senza_var_2     := v_loop_var.stanz_senza_var_2;
		delta_var_0           := v_loop_var.delta_var_0;
		delta_var_1           := v_loop_var.delta_var_1;
		delta_var_2           := v_loop_var.delta_var_2;
 
		--SIAC-8768
		
		stanziamento_0 := v_loop_var.stanz_senza_var_0 + v_loop_var.delta_var_0;
		stanziamento_1 := v_loop_var.stanz_senza_var_1 + v_loop_var.delta_var_1;
		stanziamento_2 := v_loop_var.stanz_senza_var_2 + v_loop_var.delta_var_2;
        
         --21/07/2023 siac-tasks-Issues #142 
         --Valori degli accertamenti per anno.
        v_accertamenti_0 := COALESCE(v_loop_var.acc_fde_denominatore, 0);
        v_accertamenti_1 := COALESCE(v_loop_var.acc_fde_denominatore_1, 0);
        v_accertamenti_2 := COALESCE(v_loop_var.acc_fde_denominatore_2, 0);
/*
se media utente != null -> 100 - media utente
altrimenti
100 - [max(media_confronto, min(%acc, %stanziamento))]
*/       		
		-- /10000 perche' ho due percentuali per cui moltiplico (v_loop_var.acc_fde_media e accantonamento_graduale)
		-- SIAC-8446: arrotondo gli importi a due cifre decimali
/*		SIAC-8792 26/08/2022
        --Il calcolo dell'accantonamento FCDE prvede il seguente algoritmo:
        
        se media utente != null -> 100 - media utente
		altrimenti
		100 - [max(media_confronto, min(%acc, %stanziamento))]
*/        
        --accantonamento_fcde_0 := ROUND(stanziamento_0 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		--accantonamento_fcde_1 := ROUND(stanziamento_1 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		--accantonamento_fcde_2 := ROUND(stanziamento_2 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		
        if v_loop_var.afde_tipo_media_code = 'UTENTE' THEN
        	v_media_utilizzo:= v_loop_var.acc_fde_media_utente;
        else
              --12/10/2023 siac-tasks-issue #142.
              --Se lo stanziamento e' 0 occorre impostare la percentuale di accantonamento per non far fallire il rapporto
              --(v_loop_var.acc_fde_numeratore * 100 / stanziamento_0. Prima era:     
              --v_perc_accantonamento:=COALESCE((v_loop_var.acc_fde_numeratore * 100 / stanziamento_0), 0);   
        	if stanziamento_0 = 0 then
            	v_perc_accantonamento:= 0;
            else
        		v_perc_accantonamento:=COALESCE((v_loop_var.acc_fde_numeratore * 100 / stanziamento_0), 0);
            end if;
            
            v_media_utilizzo:= GREATEST (v_loop_var.acc_fde_media_confronto,
            	LEAST(v_perc_accantonamento, v_loop_var.acc_fde_media_semplice_totali));
        end if;
        
        raise notice 'capitolo = % - numeratore = % - stanziamento = %', 
        	capitolo, v_loop_var.acc_fde_numeratore, stanziamento_0;
		raise notice 'capitolo % - tipo media = % - media_confronto = % - perc_accantonamento = % - acc_fde_media_semplice_totali = % v_media_utilizzo = %', 
        	capitolo, v_loop_var.afde_tipo_media_code, v_loop_var.acc_fde_media_confronto,
            v_perc_accantonamento, v_loop_var.acc_fde_media_semplice_totali, v_media_utilizzo;
        raise notice 'capitolo % - v_accertamenti_0 = % - v_accertamenti_1 = % - v_accertamenti_2 = %',
        	capitolo, v_accertamenti_0, v_accertamenti_1, v_accertamenti_2;
            
             --21/07/2023 siac-tasks-Issues #142 
             --Per calcolare l'accantonamento FCDE devo usare il valore maggiore tra stanziamento e accertamento.
        --accantonamento_fcde_0 := ROUND(stanziamento_0 * (100 - v_media_utilizzo) / 100, 2);
		--accantonamento_fcde_1 := ROUND(stanziamento_1 * (100 - v_media_utilizzo) / 100, 2);
		--accantonamento_fcde_2 := ROUND(stanziamento_2 * (100 - v_media_utilizzo) / 100, 2);
		accantonamento_fcde_0 := ROUND(GREATEST(stanziamento_0, v_accertamenti_0)  * (100 - v_media_utilizzo) / 100, 2);
		accantonamento_fcde_1 := ROUND(GREATEST(stanziamento_1, v_accertamenti_1) * (100 - v_media_utilizzo) / 100, 2);
		accantonamento_fcde_2 := ROUND(GREATEST(stanziamento_2, v_accertamenti_2) * (100 - v_media_utilizzo) / 100, 2);
        
        raise notice 'accantonamento_fcde_0 = % - accantonamento_fcde_1 = % - accantonamento_fcde_2 = %',
        	accantonamento_fcde_0, accantonamento_fcde_1, accantonamento_fcde_2;
            
		--SIAC-8792 26/08/2022
        --La percentuale effettiva e' il complemento a 100 della media utilizzata.
        percentuale_effettiva := ROUND(100 - v_media_utilizzo, 2); 
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
            --SIAC-8792 26/08/2022
            --Il campo percentuale_accantonamento e' calcolato e non e' la
            --media utente.
			--, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
            , --17/11/2023 siac-tasks-Issues #290
              --se lo stanziamento e' 0, come percentuale_accantonamento si restituisce 0.
              --aggiunto anche COALESCE se manca la media di confronto
            case when stanziamento_0 = 0 then 0
            else round(COALESCE((siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore * 100 / stanziamento_0), 0), 2) end
			, COALESCE(siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_desc, '')			
            , siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
--				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
--				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
		INTO
			  incasso_conto_competenza
			, accertato_conto_competenza
			, percentuale_incasso_gestione
			, percentuale_accantonamento
			, tipo_precedente
			, percentuale_precedente
			, percentuale_minima
		FROM siac_t_acc_fondi_dubbia_esig
         --17/11/2023 siac-tasks-Issues #290
         --per alcuni capitoli non c'e' la percentuale di confronto e quindi manca il join con la tabella siac_d_acc_fondi_dubbia_esig_tipo_media_confronto
         --Si deve accedere con LEFT JOIN
		LEFT JOIN siac_d_acc_fondi_dubbia_esig_tipo_media_confronto ON (siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_conf_id AND siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.data_cancellazione IS NULL)
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

ALTER FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil (p_afde_bil_id integer)
  OWNER TO siac;
  
  
CREATE OR REPLACE FUNCTION siac."BILR262_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_assest" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar,
  p_afde_bil_id integer
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImpVar varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
fde_media_utente  numeric;
fde_media_semplice_totali numeric;
fde_media_semplice_rapporti  numeric;
fde_media_ponderata_totali  numeric;
fde_media_ponderata_rapporti  numeric;

perc_delta numeric;
perc_media numeric;
afde_bilancioId integer;
perc_massima numeric;

h_count integer :=0;

accertamento_cap numeric;
incassi_conto_competenza numeric;
accertamento_cap1 numeric;
incassi_conto_competenza1 numeric;
accertamento_cap2 numeric;
incassi_conto_competenza2 numeric;
accertamento_cap_utilizzato numeric;

perc_accantonamento numeric;
media_confronto numeric;

BEGIN

annoCapImp:= p_anno; 
annoCapImpVar:= p_anno_competenza;

flag_acc_cassa:= true;

/*
Funzione creata per la SIAC-8664 - 06/10/2022.
Parte come copia della "BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita"
ma e' modificata per gestire i dati dell'assestamento invece che della 
previsione.


*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
    and fondi_bil.ente_proprietario_id = p_ente_prop_id
    and fondi_bil.afde_bil_id = p_afde_bil_id
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione.

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';
accertamento_cap_utilizzato:=0;

select fnc_siac_random_user()
into	user_table;


insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, user_table);
 

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and ct.classif_tipo_code			=	'CATEGORIA' 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo--,
         --22/12/2021 SIAC-8254
         --I capitoli devono essere presi tutti e non solo quelli
         --coinvolti in FCDE per avere l'importo effettivo dello stanziato
         --nella colonna (a).
            --siac_t_acc_fondi_dubbia_esig fcde
    where 	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and   fcde.elem_id						= capitolo.elem_id
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno				
        --and   fcde.afde_bil_id				=  afde_bilancioId
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        --leggo solo gli importi dell'anno di competenza.
        and	capitolo_imp_periodo.anno 				in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		--and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null 
       -- and fcde.data_cancellazione IS NULL     
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               
--21/07/2023 siac-tasks-issu #142.
--Nel calcolo dello stanziamento occorre considerare le eventuali variazioni in BOZZA sul capitolo.     
 insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            testata_variazione.ente_proprietario_id	      	
    from 	siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_r_variazione_stato		r_variazione_stato,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_bil					t_bil,
            siac_t_periodo 				anno_importi
    where 	testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
    and 	t_bil.bil_id 										= 	testata_variazione.bil_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	testata_variazione.variazione_id					=  	r_variazione_stato.variazione_id
    and 	testata_variazione.ente_proprietario_id 			= 	p_ente_prop_id 
    and		anno_eserc.anno										= 	p_anno	   
    and		anno_importi.anno									= 	annoCapImpVar    									 	
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					= 'STA'
    and		tipologia_stato_var.variazione_stato_tipo_code		NOT IN ('A', 'D')
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    and		t_bil.data_cancellazione					is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
               utente,
                testata_variazione.ente_proprietario_id;
                    
for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
        COALESCE (var_ent.importo,0)		imp_var
from  	siac_rep_tit_tip_cat_riga_anni v1
		FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
         left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
        left join siac_rep_var_entrate var_ent
                  on (var_ent.elem_id	=	tb.elem_id
                          and	tb.utente=user_table
                          and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
--21/07/2023 siac-tasks-issu #142.
--Nel calcolo dello stanziamento occorre considerare le eventuali variazioni in BOZZA sul capitolo.  
--Poiche' il report viene eseguito su uno specifico anno di competenza, il campo valorizzato su stanziamento_prev_anno
--e' gia' quello dell'anno di competenza.
--stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno + classifBilRec.imp_var;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;


-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
  AND    ta.ente_proprietario_id = p_ente_prop_id
  AND    rbea.elem_id = classifBilRec.bil_ele_id
  AND    ta.attr_code = 'FlagAccertatoPerCassa'

  AND    rbea."boolean" = 'S'
  AND    rbea.data_cancellazione IS NULL
  AND    ta.data_cancellazione IS NULL;

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE


raise notice 'bil_ele_id = %', classifBilRec.bil_ele_id;

fde_media_utente:=0;
fde_media_semplice_totali:=0; 
fde_media_semplice_rapporti:=0;
fde_media_ponderata_totali:=0; 
fde_media_ponderata_rapporti:=0;
perc_delta:=0;
perc_media:=0;
tipomedia:='';
accertamento_cap:=0;

if classifBilRec.bil_ele_id IS NOT NULL then
  select  datifcd.perc_delta, 1, tipo_media.afde_tipo_media_code,
    COALESCE(datifcd.acc_fde_media_utente,0), 
    COALESCE(datifcd.acc_fde_media_semplice_totali,0),
    COALESCE(datifcd.acc_fde_media_semplice_rapporti,0), 
    COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
    COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0),
    greatest (COALESCE(datifcd.acc_fde_media_semplice_totali,0),
       		  COALESCE(datifcd.acc_fde_media_semplice_rapporti,0),
    COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
    COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0)),
    COALESCE(datifcd.acc_fde_denominatore, 0) accert,
    COALESCE(datifcd.acc_fde_numeratore, 0) incassi_conto_comp,
    COALESCE(datifcd.acc_fde_denominatore_1, 0) accert1,
    COALESCE(datifcd.acc_fde_numeratore_1, 0) incassi_conto_comp1,
    COALESCE(datifcd.acc_fde_denominatore_2, 0) accert2,
    COALESCE(datifcd.acc_fde_numeratore_2, 0) incassi_conto_comp2,
    COALESCE(datifcd.acc_fde_media_confronto, 0) media_confr
  into perc_delta, h_count, tipomedia,
      fde_media_utente, fde_media_semplice_totali, fde_media_semplice_rapporti,
      fde_media_ponderata_totali, fde_media_ponderata_rapporti, perc_massima, accertamento_cap, incassi_conto_competenza,
      accertamento_cap1, incassi_conto_competenza1, accertamento_cap2, incassi_conto_competenza2, media_confronto
   FROM siac_t_acc_fondi_dubbia_esig datifcd, 
      siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
  where tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
    and datifcd.elem_id=classifBilRec.bil_ele_id 
    and datifcd.afde_bil_id  = afde_bilancioId
    and datifcd.data_cancellazione is null
    and tipo_media.data_cancellazione is null;

--28/07/2023: il valore dell'accertamento usato per i calcoli dipende dall'anno di competenza.
if p_anno_competenza =  p_anno then
	accertamento_cap_utilizzato:= accertamento_cap;
elsif p_anno_competenza::integer = p_anno::integer +1 then
	accertamento_cap_utilizzato:= accertamento_cap1;
elsif p_anno_competenza::integer = p_anno::integer +2 then
	accertamento_cap_utilizzato:= accertamento_cap2;
else 
	accertamento_cap_utilizzato:=0;
end if;
    
/*
if tipomedia = 'SEMP_RAP' then
    perc_media = fde_media_semplice_rapporti;         
elsif tipomedia = 'SEMP_TOT' then
    perc_media = fde_media_semplice_totali;        
elsif tipomedia = 'POND_RAP' then
      perc_media = fde_media_ponderata_rapporti;  
elsif tipomedia = 'POND_TOT' then
      perc_media = fde_media_ponderata_totali;    
elsif tipomedia = 'UTENTE' then  --Media utente
      perc_media = fde_media_utente;   
end if;
*/


if tipomedia = 'UTENTE' THEN
    perc_media:= fde_media_utente;
else
		--12/10/2023 siac-tasks-issue #142.
        --Se lo stanziamento e' 0 occorre impostare la percentuale di accantonamento per non far fallire il rapporto
        --(incassi_conto_competenza * 100 / stanziamento_prev_anno). Prima era:
        --perc_accantonamento:=COALESCE((incassi_conto_competenza * 100 / stanziamento_prev_anno), 0);
	if stanziamento_prev_anno = 0 then
    	raise notice 'formula per perc_accantonamento:perc_accantonamento:= 0';
    	perc_accantonamento:= 0;
    else 
    	raise notice 'formula per perc_accantonamento:
        	COALESCE((% * 100 / %), 0)', incassi_conto_competenza, stanziamento_prev_anno;
    	perc_accantonamento:=COALESCE((incassi_conto_competenza * 100 / stanziamento_prev_anno), 0);
    end if;
    
    raise notice 'formula per perc_media: 
    	GREATEST (%, LEAST(%, %))', media_confronto, perc_accantonamento, fde_media_semplice_totali;
        
        --10/11/2023: nell'ambito dei test della siac-tasks-issue #142 ci si e' accorti che non e' corretto usare la
        --media fde_media_ponderata_totali ma occorre usare la fde_media_semplice_totali come nell'export Excel ed a video.
    perc_media:= GREATEST (media_confronto, LEAST(perc_accantonamento, fde_media_semplice_totali));--fde_media_ponderata_totali));
end if;
               
raise notice 'Capitolo = % - tipomedia % - perc_accantonamento= % - perc_media: % - delta: % - massima %', 
	bil_ele_code, tipomedia , perc_accantonamento, perc_media, perc_delta, perc_massima ;
raise notice '      stanziamento = % - accertamento = %', classifBilRec.stanziamento_prev_anno, accertamento_cap;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

--SIAC-8154 14/10/2021
--la colonna C diventa quello che prima era la colonna B
--la colonna B invece della percentuale media deve usa la percentuale 
--che ha il valore massimo (esclusa quella utente).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
--importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);   

--SIAC-8579 17/01/2022 l'accantonamento obbligatorio (Colonna B) diventa uguale
--all'accantonamento effettivo (Colonna C).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_massima/100) * percAccantonamento/100,2);
--importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);

raise notice 'Applicata formula: ROUND(GREATEST(%, %)  * (100 - %) / 100, 2)',
	stanziamento_prev_anno, accertamento_cap_utilizzato, perc_media;
    
--21/07/2023 siac-tasks-issu #142.
--La formaula usata per il calcoo dell'accantonamento FCDE viene adeguata a quella usata dalla procedura
--fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil per l'export in Excel.    
importo_collc := ROUND(GREATEST(stanziamento_prev_anno, accertamento_cap_utilizzato)  * (100 - perc_media) / 100, 2);
importo_collb:=importo_collc;
else
	importo_collc:=0;
    importo_collb:=0;
end if;

raise notice '      importo_collb %',  importo_collb;

if h_count is null or flag_acc_cassa = true then
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

return next;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR262_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_assest" (p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar, p_afde_bil_id integer)
  OWNER TO siac;
  
--siac-tasks-Issues #142 - MAURIZIO - FINE

  




-- INIZIO task-162.sql



\echo task-162.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--task-162 - Paolo - INIZIO
/*per il parametro INSERISCI_ORDINATIVO_PAGAMENTO_DEFAULT_COMMISSIONI*/
insert into siac_t_parametro_config_ente (
	ente_proprietario_id,
	parametro_nome,
	parametro_valore,
	parametro_note,
	validita_inizio,
	login_operazione 
) select 
	e.ente_proprietario_id ,
	x.nome,
	true,
	x.note,
	now(),
	'admin'
 from siac_t_ente_proprietario e, 
(values 
	('ordinativo.pagamento.inserisci.default.commissioni', 'Inserisci ordinativo pagamento dafault commissioni') 
) as x (nome, note) 
where not exists ( select 1 from siac_t_parametro_config_ente p where parametro_nome = x.nome and e.ente_proprietario_id = p.ente_proprietario_id)
and e.ente_code = 'REGP'
and e.in_uso
; 
--task-162 - Paolo - FINE




-- INIZIO task-172.sql



\echo task-172.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW siac.siac_v_dwh_fattura_sirfel;

CREATE OR REPLACE VIEW siac.siac_v_dwh_fattura_sirfel (
    ente_proprietario_id,
    fornitore_cod,
    fornitore_desc,
    data_emissione,
    data_ricezione,
    numero_documento,
    documento_fel_tipo_cod,
    documento_fel_tipo_desc,
    data_acquisizione,
    stato_acquisizione,
    importo_lordo,
    arrotondamento_fel,
    importo_netto,
    codice_destinatario,
    tipo_ritenuta,
    aliquota_ritenuta,
    importo_ritenuta,
    anno_protocollo,
    numero_protocollo,
    registro_protocollo,
    data_reg_protocollo,
    modpag_cod,
    modpag_desc,
    aliquota_iva,
    imponibile,
    imposta,
    arrotondamento_onere,
    spese_accessorie,
    doc_id,
    anno_doc,
    num_doc,
    data_emissione_doc,
    cod_tipo_doc,
    cod_sogg_doc,
    esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
    data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
    stato_sdi , -- SIAC-6565
    lotto_sdi -- 02.10.2023 Sofia SIAC-TASK-172
    ) 
AS
SELECT tab.ente_proprietario_id, tab.fornitore_cod, tab.fornitore_desc,
    tab.data_emissione, tab.data_ricezione, tab.numero_documento,
    tab.documento_fel_tipo_cod, tab.documento_fel_tipo_desc,
    tab.data_acquisizione, tab.stato_acquisizione, tab.importo_lordo,
    tab.arrotondamento_fel, tab.importo_netto, tab.codice_destinatario,
    tab.tipo_ritenuta, tab.aliquota_ritenuta, tab.importo_ritenuta,
    tab.anno_protocollo, tab.numero_protocollo, tab.registro_protocollo,
    tab.data_reg_protocollo, tab.modpag_cod, tab.modpag_desc, tab.aliquota_iva,
    tab.imponibile, tab.imposta, tab.arrotondamento_onere, tab.spese_accessorie,
    tab.doc_id, tab.anno_doc, tab.num_doc, tab.data_emissione_doc,
    tab.cod_tipo_doc, tab.cod_sogg_doc,
    tab.esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
    tab.data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
    tab.stato_sdi, -- SIAC-6565
    tab.lotto_sdi -- 02.10.2023 Sofia SIAC-TASK-172
FROM ( WITH dati_sirfel AS (
    SELECT tf.ente_proprietario_id,
                    tp.codice_prestatore AS fornitore_cod,
                        CASE
                            WHEN tp.denominazione_prestatore IS NULL THEN
                                ((tp.nome_prestatore::text || ' '::text) || tp.cognome_prestatore::text)::character varying
                            ELSE tp.denominazione_prestatore
                        END AS fornitore_desc,
                    tf.data AS data_emissione, tpf.data_ricezione,
                    tf.numero AS numero_documento,
                    dtd.codice AS documento_fel_tipo_cod,
                    dtd.descrizione AS documento_fel_tipo_desc,
                    tf.data_caricamento AS data_acquisizione,
                        CASE
                            WHEN tf.stato_fattura = 'S'::bpchar THEN 'IMPORTATA'::text
                            ELSE
                            CASE
                                WHEN tf.stato_fattura = 'N'::bpchar THEN
                                    'DA ACQUISIRE'::text
                                ELSE 'SOSPESA'::text
                            END
                        END AS stato_acquisizione,
                    tf.importo_totale_documento AS importo_lordo,
                    tf.arrotondamento AS arrotondamento_fel,
                    tf.importo_totale_netto AS importo_netto,
                    tf.codice_destinatario, tf.tipo_ritenuta,
                    tf.aliquota_ritenuta, tf.importo_ritenuta,
                    tpro.anno_protocollo, tpro.numero_protocollo,
                    tpro.registro_protocollo, tpro.data_reg_protocollo,
                    tpagdett.modalita_pagamento AS modpag_cod,
                    dmodpag.descrizione AS modpag_desc, trb.aliquota_iva,
                    trb.imponibile_importo AS imponibile, trb.imposta,
                    trb.arrotondamento AS arrotondamento_onere,
                    trb.spese_accessorie, tf.id_fattura,
                    tpf.esito_stato_fattura esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
                    tpagdett.data_scadenza_pagamento data_scadenza_pagamento_pcc -- siac-6125 Sofia 23.05.2018
    FROM sirfel_t_fattura tf
              JOIN sirfel_t_prestatore tp ON tf.id_prestatore =
                  tp.id_prestatore AND tf.ente_proprietario_id = tp.ente_proprietario_id
         LEFT JOIN sirfel_t_portale_fatture tpf ON tf.id_fattura =
             tpf.id_fattura AND tf.ente_proprietario_id = tpf.ente_proprietario_id
    LEFT JOIN sirfel_d_tipo_documento dtd ON tf.tipo_documento::text =
        dtd.codice::text AND tf.ente_proprietario_id = dtd.ente_proprietario_id
   LEFT JOIN sirfel_t_riepilogo_beni trb ON tf.id_fattura = trb.id_fattura AND
       tf.ente_proprietario_id = trb.ente_proprietario_id
   LEFT JOIN sirfel_t_protocollo tpro ON tf.id_fattura = tpro.id_fattura AND
       tf.ente_proprietario_id = tpro.ente_proprietario_id
   LEFT JOIN sirfel_t_pagamento tpag ON tf.id_fattura = tpag.id_fattura AND
       tf.ente_proprietario_id = tpag.ente_proprietario_id
   LEFT JOIN sirfel_t_dettaglio_pagamento tpagdett ON tpag.id_fattura =
       tpagdett.id_fattura AND tpag.progressivo = tpagdett.progressivo_pagamento AND tpag.ente_proprietario_id = tpagdett.ente_proprietario_id
   LEFT JOIN sirfel_d_modalita_pagamento dmodpag ON
       tpagdett.modalita_pagamento::text = dmodpag.codice::text AND tpagdett.ente_proprietario_id = dmodpag.ente_proprietario_id
    ), dati_fattura AS (
    SELECT rdoc.ente_proprietario_id, rdoc.id_fattura, tdoc.doc_id,
                    tdoc.doc_anno AS anno_doc, tdoc.doc_numero AS num_doc,
                    tdoc.doc_data_emissione AS data_emissione_doc,
                    ddoctipo.doc_tipo_code AS cod_tipo_doc,
                    tdoc.stato_sdi as stato_sdi, -- SIAC-6565
                    tdoc.doc_sdi_lotto_siope lotto_sdi, -- 02.10.2023 Sofia SIAC-TASK-172
                    tsogg.soggetto_code AS cod_sogg_doc
    FROM siac_r_doc_sirfel rdoc
              JOIN siac_t_doc tdoc ON tdoc.doc_id = rdoc.doc_id
         JOIN siac_d_doc_tipo ddoctipo ON tdoc.doc_tipo_id = ddoctipo.doc_tipo_id
    LEFT JOIN siac_r_doc_sog rdocsog ON tdoc.doc_id = rdocsog.doc_id AND
        rdocsog.data_cancellazione IS NULL AND now() >= rdocsog.validita_inizio AND now() <= COALESCE(rdocsog.validita_fine::timestamp with time zone, now())
   LEFT JOIN siac_t_soggetto tsogg ON rdocsog.soggetto_id = tsogg.soggetto_id
       AND tsogg.data_cancellazione IS NULL
    WHERE rdoc.data_cancellazione IS NULL AND tdoc.data_cancellazione IS NULL
        AND now() >= rdoc.validita_inizio AND now() <= COALESCE(rdoc.validita_fine::timestamp with time zone, now())
    )
    SELECT dati_sirfel.ente_proprietario_id, dati_sirfel.fornitore_cod,
            dati_sirfel.fornitore_desc, dati_sirfel.data_emissione,
            dati_sirfel.data_ricezione, dati_sirfel.numero_documento,
            dati_sirfel.documento_fel_tipo_cod,
            dati_sirfel.documento_fel_tipo_desc, dati_sirfel.data_acquisizione,
            dati_sirfel.stato_acquisizione, dati_sirfel.importo_lordo,
            dati_sirfel.arrotondamento_fel, dati_sirfel.importo_netto,
            dati_sirfel.codice_destinatario, dati_sirfel.tipo_ritenuta,
            dati_sirfel.aliquota_ritenuta, dati_sirfel.importo_ritenuta,
            dati_sirfel.anno_protocollo, dati_sirfel.numero_protocollo,
            dati_sirfel.registro_protocollo, dati_sirfel.data_reg_protocollo,
            dati_sirfel.modpag_cod, dati_sirfel.modpag_desc,
            dati_sirfel.aliquota_iva, dati_sirfel.imponibile,
            dati_sirfel.imposta, dati_sirfel.arrotondamento_onere,
            dati_sirfel.spese_accessorie, dati_sirfel.id_fattura,
            dati_fattura.doc_id, dati_fattura.anno_doc, dati_fattura.num_doc,
            dati_fattura.data_emissione_doc, dati_fattura.cod_tipo_doc,
            dati_fattura.cod_sogg_doc,
            dati_sirfel.esito_stato_fattura_fel, -- siac-6125 Sofia 23.05.2018
            dati_sirfel.data_scadenza_pagamento_pcc, -- siac-6125 Sofia 23.05.2018
            dati_fattura.stato_sdi, -- SIAC-6565
            dati_fattura.lotto_sdi -- 10.02.2023 Sofia SIAC-TASK-172
    FROM dati_sirfel
      LEFT JOIN dati_fattura ON dati_sirfel.id_fattura =
          dati_fattura.id_fattura AND dati_sirfel.ente_proprietario_id = dati_fattura.ente_proprietario_id
    ) tab;
    
   
   
   alter view siac.siac_v_dwh_fattura_sirfel owner to siac;

   





-- INIZIO task-178.sql



\echo task-178.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--task-178 - Alessandra - INIZIO
DROP INDEX IF EXISTS idx_siac_t_subdoc_iva_1;

CREATE UNIQUE INDEX idx_siac_t_subdoc_iva_1 ON siac.siac_t_subdoc_iva
USING btree (subdociva_anno, subdociva_numero, subdociva_data_emissione, ente_proprietario_id) WHERE (data_cancellazione IS NULL); 
--task-178 - Alessandra - FINE




-- INIZIO task-184.sql



\echo task-184.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out pagopaBckSubdoc             BOOLEAN,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out pagopaBckSubdoc             BOOLEAN,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):='';
	strMessaggioBck VARCHAR(2500):='';
    strMessaggioLog VARCHAR(2500):='';
	strMessaggioFinale VARCHAR(2500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(10):='';
	codResult integer:=null;


	PagoPaRecClean record;
    AggRec record;

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA


begin

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' Pulizia documenti creati per provvisori in errore-non completi.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale;
   raise notice '@@@@ Inizio fnc_pagopa_t_elaborazione_riconc_esegui_clean - @@@@@';
	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
--	raise notice 'strMessaggioFinale=%',strMessaggioFinale;
    codiceRisultato:=0;
    messaggioRisultato:='';
    pagopaBckSubdoc:=false;

    strMessaggio:='Inizio ciclo su pagopa_t_riconciliazione_doc.';
  --        raise notice 'strMessaggio=%',strMessaggio;

    for PagoPaRecClean in
    (
     select doc.pagopa_ric_doc_provc_id pagopa_provc_id,
            flusso.pagopa_elab_flusso_anno_esercizio pagopa_anno_esercizio,
            flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
            flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio
     from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
	 and   doc.pagopa_ric_doc_subdoc_id is not null
	 and   doc.pagopa_ric_doc_stato_elab='S'
	 and   exists
	 (
      select 1
	  from  pagopa_t_elaborazione_flusso flusso1, pagopa_t_riconciliazione_doc doc1,
            pagopa_t_riconciliazione ric1
	  where flusso1.pagopa_elab_id=flusso.pagopa_elab_id
	  and   flusso1.pagopa_elab_flusso_anno_esercizio=flusso.pagopa_elab_flusso_anno_esercizio
	  and   flusso1.pagopa_elab_flusso_anno_provvisorio=flusso.pagopa_elab_flusso_anno_provvisorio
	  and   flusso1.pagopa_elab_flusso_num_provvisorio=flusso.pagopa_elab_flusso_num_provvisorio
	  and   doc1.pagopa_elab_flusso_id=flusso1.pagopa_elab_flusso_id
      and   ric1.pagopa_ric_id=doc1.pagopa_ric_id
	  and   doc1.pagopa_ric_doc_subdoc_id is null
      -- 07.06.2019 SIAC-6720
	  and   ((doc1.pagopa_ric_doc_stato_elab!='S' and doc1.pagopa_ric_doc_flag_con_dett=false ) or
              ric1.pagopa_ric_flusso_stato_elab!='S'
            )
	  and   flusso1.data_cancellazione is null
	  and   flusso1.validita_fine is null
	  and   doc1.data_cancellazione is null
	  and   doc1.validita_fine is null
      and   ric1.data_cancellazione is null
      and   ric1.validita_fine is null

	 ) -- per provvisorio scarti,non elaborati o errori
     and flusso.data_cancellazione is null
	 and flusso.validita_fine is null
	 and doc.data_cancellazione is null
	 and doc.validita_fine is null
	 order by 2,3,4
	)
    loop

	  codResult:=null;
      -- tabelle backup
      -- pagopa_bck_t_subdoc
      --  raise notice '@@@@@@@@@@@@@@@@@@@@ strMessaggio=%',strMessaggio;
      strMessaggio:='In ciclo su pagopa_t_riconciliazione_doc. Per provvisorio di cassa Prov. '
                  ||PagoPaRecClean.pagopa_anno_provvisorio::varchar||'/'||PagoPaRecClean.pagopa_num_provvisorio::varchar
                  ||' provcId='||PagoPaRecClean.pagopa_provc_id::varchar||'.';
      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
	  insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      strMessaggioBck:=strMessaggio;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc.';
      insert into pagopa_bck_t_subdoc
      (
        pagopa_provc_id,
        pagopa_elab_id,
        subdoc_id,
        subdoc_numero,
        subdoc_desc,
        subdoc_importo,
        subdoc_nreg_iva,
        subdoc_data_scadenza,
        subdoc_convalida_manuale,
        subdoc_importo_da_dedurre,
        subdoc_splitreverse_importo,
        subdoc_pagato_cec,
        subdoc_data_pagamento_cec,
        contotes_id,
        dist_id,
        comm_tipo_id,
        doc_id,
        subdoc_tipo_id,
        notetes_id,
        bck_validita_inizio,
        bck_validita_fine,
        bck_data_creazione,
        bck_data_modifica,
        bck_data_cancellazione,
        bck_login_operazione,
        bck_login_creazione,
        bck_login_modifica,
        bck_login_cancellazione,
        siope_tipo_debito_id,
        siope_assenza_motivazione_id,
        siope_scadenza_motivo_id,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
      )
      select
        PagoPaRecClean.pagopa_provc_id,
        filePagoPaElabId,
        sub.subdoc_id,
        sub.subdoc_numero,
        sub.subdoc_desc,
        sub.subdoc_importo,
        sub.subdoc_nreg_iva,
        sub.subdoc_data_scadenza,
        sub.subdoc_convalida_manuale,
        sub.subdoc_importo_da_dedurre,
        sub.subdoc_splitreverse_importo,
        sub.subdoc_pagato_cec,
        sub.subdoc_data_pagamento_cec,
        sub.contotes_id,
        sub.dist_id,
        sub.comm_tipo_id,
        sub.doc_id,
        sub.subdoc_tipo_id,
        sub.notetes_id,
        sub.validita_inizio,
        sub.validita_fine,
        sub.data_creazione,
        sub.data_modifica,
        sub.data_cancellazione,
        sub.login_operazione,
        sub.login_creazione,
        sub.login_modifica,
        sub.login_cancellazione,
        sub.siope_tipo_debito_id,
        sub.siope_assenza_motivazione_id,
        sub.siope_scadenza_motivo_id,
        clock_timestamp(),
        sub.ente_proprietario_id,
        loginOperazione
      from siac_t_subdoc sub,siac_r_doc_stato rs, siac_d_doc_stato stato,
	   	   pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc ric
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   ric.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   ric.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   ric.pagopa_ric_doc_stato_elab='S'
      and   sub.subdoc_id=ric.pagopa_ric_doc_subdoc_id
      and   rs.doc_id=sub.doc_id
      and   stato.doc_stato_id=rs.doc_stato_id
      and   stato.doc_stato_code not in ('A','ST','EM')
      and   not exists
      (
        select 1
        from siac_r_subdoc_ordinativo_ts rsub
        where rsub.subdoc_id=sub.subdoc_id
        and   rsub.data_cancellazione is null
        and   rsub.validita_fine is null
      )
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null
     -- and   sub.data_cancellazione is null
     -- and   sub.validita_fine is null
      and   rs.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())));
      GET DIAGNOSTICS codResult = ROW_COUNT;

      if pagopaBckSubdoc=false and coalesce(codResult,0) !=0 then
      	pagopaBckSubdoc:=true;
      end if;

	  -- pagopa_bck_t_subdoc_attr
      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_attr.';
      insert into pagopa_bck_t_subdoc_attr
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_attr_id,
          subdoc_id,
          attr_id,
          tabella_id,
          boolean,
          percentuale,
          testo,
          numerico,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_attr_id,
          r.subdoc_id,
          r.attr_id,
          r.tabella_id,
          r.boolean,
          r.percentuale,
          r.testo,
          r.numerico,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          r.ente_proprietario_id,
          loginOperazione
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_attr r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_atto_amm
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_atto_amm.';
      insert into pagopa_bck_t_subdoc_atto_amm
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_atto_amm_id,
          subdoc_id,
          attoamm_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_atto_amm_id,
          r.subdoc_id,
          r.attoamm_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_atto_amm r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_prov_cassa
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_prov_cassa.';

      insert into pagopa_bck_t_subdoc_prov_cassa
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_provc_id,
          subdoc_id,
          provc_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_provc_id,
          r.subdoc_id,
          r.provc_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_prov_cassa r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_movgest_ts
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_movgest_ts.';

      insert into pagopa_bck_t_subdoc_movgest_ts
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_movgest_ts_id,
          subdoc_id,
          movgest_ts_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_movgest_ts_id,
          r.subdoc_id,
          r.movgest_ts_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_movgest_ts r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc.';
      insert into pagopa_bck_t_doc
      (
          pagopa_provc_id,
          pagopa_elab_id,
          doc_id,
          doc_anno,
          doc_numero,
          doc_desc,
          doc_importo,
          doc_beneficiariomult,
          doc_data_emissione,
          doc_data_scadenza,
          doc_tipo_id,
          codbollo_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          bck_login_creazione,
          bck_login_modifica,
          bck_login_cancellazione,
          pcccod_id,
          pccuff_id,
          doc_collegato_cec,
          doc_contabilizza_genpcc,
          siope_documento_tipo_id,
          siope_documento_tipo_analogico_id,
          doc_sdi_lotto_siope,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select distinct
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.doc_id,
          r.doc_anno,
          r.doc_numero,
          r.doc_desc,
          r.doc_importo,
          r.doc_beneficiariomult,
          r.doc_data_emissione,
          r.doc_data_scadenza,
          r.doc_tipo_id,
          r.codbollo_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          r.login_creazione,
          r.login_modifica,
          r.login_cancellazione,
          r.pcccod_id,
          r.pccuff_id,
          r.doc_collegato_cec,
          r.doc_contabilizza_genpcc,
          r.siope_documento_tipo_id,
          r.siope_documento_tipo_analogico_id,
          r.doc_sdi_lotto_siope,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_t_doc r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=sub.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


	  -- pagopa_bck_t_doc_stato
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_stato.';
      insert into pagopa_bck_t_doc_stato
      (
          pagopa_provc_id,
          pagopa_elab_id,
          doc_stato_r_id,
          doc_id,
          doc_stato_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_stato_r_id,
          r.doc_id,
          r.doc_stato_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_stato r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


	  -- pagopa_bck_t_subdoc_num
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_num.';
      insert into pagopa_bck_t_subdoc_num
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_num_id,
          doc_id,
          subdoc_numero,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.subdoc_num_id,
          r.doc_id,
          r.subdoc_numero,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_t_subdoc_num r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


      -- pagopa_bck_t_doc_sog
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_sog.';
      insert into pagopa_bck_t_doc_sog
      (
         pagopa_provc_id,
         pagopa_elab_id,
         doc_sog_id,
         doc_id,
         soggetto_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_sog_id,
          r.doc_id,
          r.soggetto_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_sog r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc_attr
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_attr.';

      insert into pagopa_bck_t_doc_attr
      (
         pagopa_provc_id,
         pagopa_elab_id,
         doc_attr_id,
         doc_id,
         attr_id,
         tabella_id,
         boolean,
         percentuale,
         testo,
         numerico,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_attr_id,
          r.doc_id,
          r.attr_id,
          r.tabella_id,
          r.boolean,
          r.percentuale,
          r.testo,
          r.numerico,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_attr r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc_class
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_class.';

      insert into pagopa_bck_t_doc_class
      (
      	 pagopa_provc_id,
         pagopa_elab_id,
         doc_classif_id,
         doc_id,
         classif_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_classif_id,
          r.doc_id,
          r.classif_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_class r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_registrounico_doc
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_registrounico_doc.';

      insert into pagopa_bck_t_registrounico_doc
      (
         pagopa_provc_id,
         pagopa_elab_id,
         rudoc_id,
         rudoc_registrazione_anno,
         rudoc_registrazione_numero,
         rudoc_registrazione_data,
         doc_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.rudoc_id,
          r.rudoc_registrazione_anno,
          r.rudoc_registrazione_numero,
          r.rudoc_registrazione_data,
          r.doc_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_t_registrounico_doc r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

   	  -- aggiornare importo documenti collegati
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento importo documenti.';

      update siac_t_doc doc
      set    doc_importo=doc.doc_importo-coalesce(query.subdoc_importo,0),
               data_modifica=clock_timestamp(),
               -- login_operazione=doc.login_operazione||'-'||loginOperazione -- 07.07.2021 Sofia Jira SIAC-8221 
			   login_operazione=loginOperazione||'@ELAB_ID='||filePagoPaElabId::varchar -- 07.07.2021 Sofia Jira SIAC-8221 
      from
      (
      select sub.doc_id,coalesce(sum(sub.subdoc_importo),0) subdoc_importo
      from siac_t_subdoc sub, pagopa_bck_t_doc pagodoc, pagopa_bck_t_subdoc pagosubdoc
      where pagodoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc.pagopa_elab_id=filePagoPaElabId
      and   pagosubdoc.pagopa_provc_id=pagodoc.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=pagodoc.pagopa_elab_id
      and   pagosubdoc.doc_id=pagodoc.doc_id
      and   sub.subdoc_id=pagosubdoc.subdoc_id
      and   pagodoc.data_cancellazione is null
      and   pagodoc.validita_fine is null
      and   pagosubdoc.data_cancellazione is null
      and   pagosubdoc.validita_fine is null
      and   sub.data_cancellazione is null
      and   sub.validita_fine is null
      group by sub.doc_id
      ) query
      where doc.ente_proprietario_id=enteProprietarioId
      and   doc.doc_id=query.doc_id
      and   exists
      (
      select 1
      from pagopa_bck_t_doc pagodoc1, pagopa_bck_t_subdoc pagosubdoc1
      where pagodoc1.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc1.pagopa_elab_id=filePagoPaElabId
      and   pagodoc1.doc_id=doc.doc_id
      and   pagosubdoc1.pagopa_provc_id=pagodoc1.pagopa_provc_id
      and   pagosubdoc1.pagopa_elab_id=pagodoc1.pagopa_elab_id
      and   pagosubdoc1.doc_id=pagodoc1.doc_id
      and   pagodoc1.data_cancellazione is null
      and   pagodoc1.validita_fine is null
      and   pagosubdoc1.data_cancellazione is null
      and   pagosubdoc1.validita_fine is null
      )
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;


      -- cancellare quote documenti collegati
  	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_attr].';

      -- siac_r_subdoc_attr
      delete from siac_r_subdoc_attr r
      using pagopa_bck_t_subdoc_attr pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_attr_id=pagosubdoc.subdoc_attr_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
 --     and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_atto_amm].';
      -- siac_r_subdoc_atto_amm
      delete from siac_r_subdoc_atto_amm r
      using pagopa_bck_t_subdoc_atto_amm pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_atto_amm_id=pagosubdoc.subdoc_atto_amm_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_prov_cassa].';

      -- siac_r_subdoc_prov_cassa
      delete from siac_r_subdoc_prov_cassa r
      using pagopa_bck_t_subdoc_prov_cassa pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_provc_id=pagosubdoc.subdoc_provc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_movgest_ts].';

      -- siac_r_subdoc_movgest_ts
      delete from siac_r_subdoc_movgest_ts r
      using pagopa_bck_t_subdoc_movgest_ts pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_movgest_ts_id=pagosubdoc.subdoc_movgest_ts_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione-pulizia [pagopa_t_modifica_elab].';
      update pagopa_t_modifica_elab r
      set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN CLEAN PER pagoPaCodeErr='||PAGOPA_ERR_36||' ',
             subdoc_id=null
      from 	pagopa_bck_t_subdoc pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_id=pagosubdoc.subdoc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_t_subdoc].';

      -- siac_t_subdoc
      delete from siac_t_subdoc r
      using pagopa_bck_t_subdoc pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_id=pagosubdoc.subdoc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;


	  -- cancellazione su documenti senza quote
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_sog].';

      -- siac_r_doc_sog

      delete from siac_r_doc_sog r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_sog pagopaDel
      where r.doc_sog_id=pagopaDel.doc_sog_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
     -- and   sub.data_cancellazione is null
     -- and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_stato].';

      -- siac_r_doc_stato
      delete from siac_r_doc_stato r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_stato pagopaDel
      where r.doc_stato_r_id=pagopaDel.doc_stato_r_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
   --   and   sub.data_cancellazione is null
--      and   sub.validita_fine is null
      );


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_attr].';

      -- siac_r_doc_attr
      delete from siac_r_doc_attr r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_attr pagopaDel
      where r.doc_attr_id=pagopaDel.doc_attr_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
    --  and   sub.data_cancellazione is null
    --  and   sub.validita_fine is null
      );


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_class].';

      -- siac_r_doc_class
      delete from siac_r_doc_class r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_class pagopaDel
      where r.doc_classif_id=pagopaDel.doc_classif_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
    --  and   sub.data_cancellazione is null
    --  and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_registrounico_doc].';

      -- siac_t_registrounico_doc
      delete from siac_t_registrounico_doc r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_registrounico_doc pagopaDel
      where r.rudoc_id=pagopaDel.rudoc_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
   --   and   sub.data_cancellazione is null
   --   and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_subdoc_num].';

      -- siac_t_subdoc_num
      delete from siac_t_subdoc_num r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_subdoc_num pagopaDel
      where r.subdoc_num_id=pagopaDel.subdoc_num_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
  --    and   sub.data_cancellazione is null
  --    and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_doc].';

      -- siac_t_doc
      delete from siac_t_doc r
      using pagopa_bck_t_doc pagopaDel
      where r.doc_id=pagopaDel.doc_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopaDel.doc_id
  --    and   sub.data_cancellazione is null
  --    and   sub.validita_fine is null
      );

      raise notice '@@@ prima di update importo doc @@@@@';

      -- 25.10.2023 Sofia SIAC-TASK-184
      -- aggiornamento importo documenti per rimanenti in vita con quote  
      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento importo documenti/quote rimanenti in vita.';
      update siac_t_doc doc
      set    doc_importo=coalesce(query.subdoc_importo,0),
               data_modifica=clock_timestamp(),
               login_operazione=loginOperazione||'@@ELAB_ID='||filePagoPaElabId::varchar 
      from
      (
      select sub.doc_id,coalesce(sum(sub.subdoc_importo),0) subdoc_importo
      from siac_t_subdoc sub
      WHERE sub.ente_proprietario_id =enteProprietarioId 
	  and exists 
 	  (
      select 1
      from pagopa_bck_t_doc pagodoc1
      where pagodoc1.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc1.pagopa_elab_id=filePagoPaElabId
      and   pagodoc1.doc_id=sub.doc_id
      and   pagodoc1.data_cancellazione is null
      and   pagodoc1.validita_fine is null
	  )
      and          sub.data_cancellazione is null
      and          sub.validita_fine is null
      group by sub.doc_id
      ) query
      where doc.ente_proprietario_id=enteProprietarioId
      and     doc.doc_id=query.doc_id
      and   exists
      (
      select 1
      from pagopa_bck_t_doc pagodoc1
      where pagodoc1.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc1.pagopa_elab_id=filePagoPaElabId
      and   pagodoc1.doc_id=doc.doc_id
      and   pagodoc1.data_cancellazione is null
      and   pagodoc1.validita_fine is null
      )
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;

     
      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento stato documenti rimanenti in vita.';
      -- aggiornamento stato documenti per rimanenti in vita con quote
      -- esecuzione fnc per
      select
       fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc
	   (
		pagopadoc.doc_id,
        filePagoPaElabId,
		enteProprietarioId,
		loginOperazione
		) into AggRec
	  from pagopa_bck_t_doc pagopadoc, pagopa_bck_t_subdoc pagopasub
      where pagopadoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopadoc.pagopa_elab_id=filePagoPaElabId
      and   pagopasub.pagopa_provc_id=pagopadoc.pagopa_provc_id
      and   pagopasub.pagopa_elab_id=pagopadoc.pagopa_elab_id
      and   pagopasub.doc_id=pagopadoc.doc_id
      and   pagopadoc.data_cancellazione is null
      and   pagopadoc.validita_fine is null
      and   pagopasub.data_cancellazione is null
      and   pagopasub.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - Fine cancellazione doc. - '||strMessaggioFinale;
	  insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||'Aggiornamento  pagopa_t_riconciliazione.';

      -- aggiornare pagopa_t_riconciliazione
      update pagopa_t_riconciliazione ric
      set    pagopa_ric_flusso_stato_elab='X',
             data_modifica=clock_timestamp(),
             pagopa_ric_errore_id=errore.pagopa_ric_errore_id
      from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc,
           pagopa_d_riconciliazione_errore errore, pagopa_bck_t_subdoc pagopa
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.pagopa_ric_doc_stato_elab='S'
      and   doc.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.subdoc_id=doc.pagopa_ric_doc_subdoc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   ric.pagopa_ric_id=doc.pagopa_ric_id
      and   errore.ente_proprietario_id=flusso.ente_proprietario_id
      and   errore.pagopa_ric_errore_code=PAGOPA_ERR_36
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
	  insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||'Aggiornamento  pagopa_t_riconciliazione_doc.';
      -- aggiornare pagopa_t_riconciliazione_doc
      update pagopa_t_riconciliazione_doc doc
      set    pagopa_ric_doc_stato_elab='X',
             pagopa_ric_doc_subdoc_id=null,
             pagopa_ric_doc_provc_id=null,
             pagopa_ric_doc_movgest_ts_id=null,
             data_modifica=clock_timestamp(),
             pagopa_ric_errore_id=errore.pagopa_ric_errore_id
      from pagopa_t_elaborazione_flusso flusso,
           pagopa_d_riconciliazione_errore errore, pagopa_bck_t_subdoc pagopa
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.pagopa_ric_doc_stato_elab='S'
      and   doc.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.subdoc_id=doc.pagopa_ric_doc_subdoc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   errore.ente_proprietario_id=flusso.ente_proprietario_id
      and   errore.pagopa_ric_errore_code=PAGOPA_ERR_36
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
	  insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

  end loop;

  /* sostituito con diagnostic dopo insert tabella
  strMessaggio:=' Verifica esistenza in pagopa_bck_t_subdoc a termine aggiornamento.';
  select (case when count(*)!=0 then true else false end ) into pagopaBckSubdoc
  from pagopa_bck_t_subdoc bck
  where bck.pagopa_elab_id=filePagoPaElabId
  and   bck.data_cancellazione is null
  and   bck.validita_fine is null;*/



  messaggioRisultato:='OK - '||upper(strMessaggioFinale);

  strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||messaggioRisultato;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  integer,integer,integer,varchar,timestamp,
  out BOOLEAN,out integer,out varchar
)  OWNER to siac;




-- INIZIO task-186.sql



\echo task-186.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--siac-tasks Issue #186 - Maurizio - INIZIO
--Configurazione delle cartelle per i report di Previsione 2024.

--Enti locali
insert into siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP1-BilPrev-2024', 'Reportistica Bilancio di Previsione 2024 (Enti Locali)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_PREV'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'siac-tasks Issues #186'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP1-BilPrev-2024');  

-- Regione.
insert into siac_t_azione (
  azione_code,  azione_desc,
  azione_tipo_id,  
  gruppo_azioni_id,  
  urlapplicazione,  nomeprocesso,  nometask ,  verificauo,
  validita_inizio,  validita_fine,  ente_proprietario_id,
  data_creazione,  data_modifica,  data_cancellazione,  login_operazione)
select 'OP-GESREP2-BilPrev-2024', 'Reportistica Bilancio di Previsione 2024 (Regione)',
	(select a.azione_tipo_id from siac_d_azione_tipo a
    	where a.azione_tipo_code='ATTIVITA_SINGOLA'
        	and a.ente_proprietario_id=ente.ente_proprietario_id
            and a.data_cancellazione IS NULL),
    (select b.gruppo_azioni_id from siac_d_gruppo_azioni b
    	where b.gruppo_azioni_code='BIL_CAP_PREV'
        	and b.ente_proprietario_id=ente.ente_proprietario_id
            and b.data_cancellazione IS NULL),
    '/../siacrepapp/azioneRichiesta.do', NULL, NULL , FALSE, 
    now(), NULL, ente.ente_proprietario_id,
    now(), now(), NULL, 'siac-tasks Issues #186'
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_azione az
        where az.ente_proprietario_id=ente.ente_proprietario_id
        	and az.azione_code='OP-GESREP2-BilPrev-2024');  
			
			
--INSERIMENTO DELLA CONFIGURAZIONE DEI RUOLI COPIANDOLI DALLE CARTELLE 2023.	
--Enti Locali.
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP1-BilPrev-2024'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'siac-tasks Issues #186'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP1-BilPrev-2023'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP1-BilPrev-2024');		

--Regione
insert into siac_r_ruolo_op_azione (
ruolo_op_id ,  azione_id ,  validita_inizio,  validita_fine ,
  ente_proprietario_id ,  data_creazione,  data_modifica ,
  data_cancellazione,  login_operazione )
select ruolo.ruolo_op_id, (select azione_id from siac_t_azione a  
				where a.azione_code='OP-GESREP2-BilPrev-2024'
                	and a.ente_proprietario_id=ruolo.ente_proprietario_id
                    and a.data_cancellazione IS NULL), now(), NULL,
       ruolo.ente_proprietario_id, now(), now(),
       NULL, 'siac-tasks Issues #186'
from siac_r_ruolo_op_azione ruolo, 
	siac_t_azione az,
    siac_t_ente_proprietario ente
where ruolo.azione_id=az.azione_id
	and ente.ente_proprietario_id=az.ente_proprietario_id
	and az.azione_code='OP-GESREP2-BilPrev-2023'
    and ruolo.data_cancellazione IS NULL
    and ruolo.validita_fine IS NULL
    and az.data_cancellazione IS NULL
    and az.validita_fine IS NULL
    and ente.data_cancellazione IS NULL
    and ente.validita_fine IS NULL 
    and not exists (select 1
    	from siac_r_ruolo_op_azione ruolo1, 
			siac_t_azione az1
		where ruolo1.azione_id=az1.azione_id
        	and az1.azione_code='OP-GESREP2-BilPrev-2024');		

--siac-tasks Issue #186 - Maurizio - FINE






-- INIZIO task-212.sql



\echo task-212.sql


--siac-task-issue #212 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR131_saldo_economico_patrimoniale" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar,
  p_liv_aggiuntivi varchar,
  p_tipo_stampa integer
)
RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  tipo_pnota varchar,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  cod_bil0 varchar,
  cod_bil1 varchar,
  cod_bil2 varchar,
  cod_bil3 varchar,
  cod_bil4 varchar,
  cod_bil5 varchar,
  cod_bil6 varchar,
  cod_bil7 varchar,
  cod_bil8 varchar
) AS
$body$
DECLARE
elenco_prime_note record;
sql_query varchar;
sql_query_add varchar;
sql_query_add1 varchar;
v_pdce_conto_id integer; 
v_classif_id integer;
v_classif_id_padre integer;
v_classif_id_part integer;
v_conta_ciclo_classif integer;
v_classif_code_app varchar;
v_livello integer;
v_ordine varchar;
v_conta_rec integer;
v_cod_bil_parziale varchar;
v_posiz_punto integer;
v_classificatori varchar;
v_classificatori1 varchar;
v_classificatori2 varchar;
v_anno_int integer; -- SIAC-5487

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		 varchar(1000):=DEF_NULL;
user_table			 varchar;

BEGIN

/* Parametri: 

- p_classificatori: 
	1 = Piano dei conti patrimoniale - Report BILR136;
    2 = Piano dei conti patrimoniale - Report BILR131.
- p_liv_aggiuntivi: S/N.
- p_tipo_stampa: Stampare tutti gli importi:
	1 = No;
    2 = Si.
	

*/ 

nome_ente='';
id_pdce0=0;
codice_pdce0='';
descr_pdce0='';
id_pdce1=0;
codice_pdce1='';
descr_pdce1='';
id_pdce2=0;
codice_pdce2='';
descr_pdce2='';
id_pdce3=0;
codice_pdce3='';
descr_pdce3='';        
id_pdce4=0;
codice_pdce4='';
descr_pdce4='';   
id_pdce5=0;
codice_pdce5='';
descr_pdce5='';   
id_pdce6=0;
codice_pdce6='';
descr_pdce6='';   
id_pdce7=0;
codice_pdce7='';
descr_pdce7='';    
id_pdce8=0;
codice_pdce8='';
descr_pdce8='';         
tipo_pnota='';
importo_dare=0;
importo_avere=0;
livello=0;
saldo_prec_dare=0;
saldo_prec_avere=0;
saldo_ini_dare=0;
saldo_ini_avere=0;
cod_bil0='';
cod_bil1='';
cod_bil2='';
cod_bil3='';
cod_bil4='';
cod_bil5='';
cod_bil6='';
cod_bil7='';
cod_bil8='';  

SELECT fnc_siac_random_user()
INTO   user_table;
	
v_anno_int := p_anno::integer; -- SIAC-5487

/* carico l'intera struttura PDCE */
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';
raise notice 'ora: % ',clock_timestamp()::varchar;

SELECT a.ente_denominazione
INTO  nome_ente
FROM  siac_t_ente_proprietario a
WHERE a.ente_proprietario_id = p_ente_prop_id;

INSERT INTO siac_rep_struttura_pdce
SELECT v.*, user_table FROM
(SELECT t_pdce_conto0.pdce_conto_id pdce_liv0_id, t_pdce_conto0.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto0.pdce_conto_code pdce_liv0_code, t_pdce_conto0.pdce_conto_desc pdce_liv0_desc,
		t_pdce_conto1.pdce_conto_id pdce_liv1_id, t_pdce_conto1.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto1.pdce_conto_code pdce_liv1_code, t_pdce_conto1.pdce_conto_desc pdce_liv1_desc,
		t_pdce_conto2.pdce_conto_id pdce_liv2_id, t_pdce_conto2.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto2.pdce_conto_code pdce_liv2_code, t_pdce_conto2.pdce_conto_desc pdce_liv2_desc,
		t_pdce_conto3.pdce_conto_id pdce_liv3_id, t_pdce_conto3.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto3.pdce_conto_code pdce_liv3_code, t_pdce_conto3.pdce_conto_desc pdce_liv3_desc,
		t_pdce_conto4.pdce_conto_id pdce_liv4_id, t_pdce_conto4.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto4.pdce_conto_code pdce_liv4_code, t_pdce_conto4.pdce_conto_desc pdce_liv4_desc,
		t_pdce_conto5.pdce_conto_id pdce_liv5_id, t_pdce_conto5.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto5.pdce_conto_code pdce_liv5_code, t_pdce_conto5.pdce_conto_desc pdce_liv5_desc,
		t_pdce_conto6.pdce_conto_id pdce_liv6_id, t_pdce_conto6.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto6.pdce_conto_code pdce_liv6_code, t_pdce_conto6.pdce_conto_desc pdce_liv6_desc,
		t_pdce_conto7.pdce_conto_id pdce_liv7_id, t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto7.pdce_conto_code pdce_liv7_code, t_pdce_conto7.pdce_conto_desc pdce_liv7_desc,
		t_pdce_conto8.pdce_conto_id pdce_liv8_id, t_pdce_conto8.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto8.pdce_conto_code pdce_liv8_code, t_pdce_conto8.pdce_conto_desc pdce_liv8_desc
 FROM siac_t_pdce_conto t_pdce_conto0, siac_t_pdce_conto t_pdce_conto1
 LEFT JOIN siac_t_pdce_conto t_pdce_conto2
      ON (t_pdce_conto1.pdce_conto_id=t_pdce_conto2.pdce_conto_id_padre
          AND t_pdce_conto2.livello=2 and t_pdce_conto2.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto2.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto2.validita_fine,now())) -- SIAC-5487
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto3
      ON (t_pdce_conto2.pdce_conto_id=t_pdce_conto3.pdce_conto_id_padre
    	  AND t_pdce_conto3.livello=3 and t_pdce_conto3.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto3.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto3.validita_fine,now())) -- SIAC-5487
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto4
      ON (t_pdce_conto3.pdce_conto_id=t_pdce_conto4.pdce_conto_id_padre
    	  AND t_pdce_conto4.livello=4 and t_pdce_conto4.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto4.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto4.validita_fine,now())) -- SIAC-5487
         )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto5
      ON (t_pdce_conto4.pdce_conto_id=t_pdce_conto5.pdce_conto_id_padre
          AND t_pdce_conto5.livello=5 and t_pdce_conto5.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto5.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto5.validita_fine,now())) -- SIAC-5487
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto6
      ON (t_pdce_conto5.pdce_conto_id=t_pdce_conto6.pdce_conto_id_padre
          AND t_pdce_conto6.livello=6 and t_pdce_conto6.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto6.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto6.validita_fine,now())) -- SIAC-5487
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto7
      ON (t_pdce_conto6.pdce_conto_id=t_pdce_conto7.pdce_conto_id_padre
          AND t_pdce_conto7.livello=7 and t_pdce_conto7.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto7.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto7.validita_fine,now())) -- SIAC-5487
          )         
 LEFT JOIN siac_t_pdce_conto t_pdce_conto8
      ON (t_pdce_conto7.pdce_conto_id=t_pdce_conto8.pdce_conto_id_padre
          AND t_pdce_conto8.livello=8 and t_pdce_conto8.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto8.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto8.validita_fine,now())) -- SIAC-5487
          )                           
 WHERE t_pdce_conto0.pdce_conto_id=t_pdce_conto1.pdce_conto_id_padre
 AND t_pdce_conto0.livello=0
 AND t_pdce_conto1.livello=1
 AND t_pdce_conto0.ente_proprietario_id=p_ente_prop_id
 AND t_pdce_conto0.data_cancellazione is NULL
 AND t_pdce_conto1.data_cancellazione is NULL
 ORDER BY t_pdce_conto0.pdce_conto_code,
          t_pdce_conto1.pdce_conto_code, t_pdce_conto2.pdce_conto_code,
          t_pdce_conto3.pdce_conto_code, t_pdce_conto4.pdce_conto_code,
		  t_pdce_conto5.pdce_conto_code, t_pdce_conto6.pdce_conto_code,
		  t_pdce_conto7.pdce_conto_code, t_pdce_conto8.pdce_conto_code) v;

raise notice 'ora: % ',clock_timestamp()::varchar;

--siac-task issue #212 04/10/2023.
--Inserisco gli eventuali livelli 7 che hanno al di sotto dei livelli 8 e che potrebbero avere delle prime note associate.
insert into siac_rep_struttura_pdce(
pdce_liv0_id ,  pdce_liv0_id_padre ,  pdce_liv0_code ,  pdce_liv0_desc ,
  pdce_liv1_id ,  pdce_liv1_id_padre ,  pdce_liv1_code ,  pdce_liv1_desc ,
  pdce_liv2_id ,  pdce_liv2_id_padre ,  pdce_liv2_code ,  pdce_liv2_desc ,
  pdce_liv3_id ,  pdce_liv3_id_padre ,  pdce_liv3_code ,  pdce_liv3_desc ,
  pdce_liv4_id ,  pdce_liv4_id_padre ,  pdce_liv4_code ,  pdce_liv4_desc ,
  pdce_liv5_id ,  pdce_liv5_id_padre ,  pdce_liv5_code ,  pdce_liv5_desc ,
  pdce_liv6_id ,  pdce_liv6_id_padre ,  pdce_liv6_code ,  pdce_liv6_desc ,
  pdce_liv7_id ,  pdce_liv7_id_padre ,  pdce_liv7_code ,  pdce_liv7_desc ,
  pdce_liv8_id ,  pdce_liv8_id_padre ,  pdce_liv8_code ,  pdce_liv8_desc, utente)
select distinct pdce_liv0_id ,  pdce_liv0_id_padre ,  pdce_liv0_code ,  pdce_liv0_desc ,
  pdce_liv1_id ,  pdce_liv1_id_padre ,  pdce_liv1_code ,  pdce_liv1_desc ,
  pdce_liv2_id ,  pdce_liv2_id_padre ,  pdce_liv2_code ,  pdce_liv2_desc ,
  pdce_liv3_id ,  pdce_liv3_id_padre ,  pdce_liv3_code ,  pdce_liv3_desc ,
  pdce_liv4_id ,  pdce_liv4_id_padre ,  pdce_liv4_code ,  pdce_liv4_desc ,
  pdce_liv5_id ,  pdce_liv5_id_padre ,  pdce_liv5_code ,  pdce_liv5_desc ,
  pdce_liv6_id ,  pdce_liv6_id_padre ,  pdce_liv6_code ,  pdce_liv6_desc ,
  pdce_liv7_id ,  pdce_liv7_id_padre ,  pdce_liv7_code ,  pdce_liv7_desc ,
  0 ,  0 ,  '' ,  '', utente
from siac_rep_struttura_pdce
where pdce_liv8_id_padre in(select distinct pdce_liv7_id
from siac_rep_struttura_pdce
where utente=user_table);

RTN_MESSAGGIO:='Estrazione dei dati codice bilancio''.';
raise notice 'Estrazione dei dati codice bilancio';

v_classificatori  := '';
v_classificatori1 := '';
v_classificatori2 := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL'; 
   v_classificatori1 := '00022'; -- 'SPP_CODBIL';
   v_classificatori2 := '00023'; -- 'CO_CODBIL';
END IF;

INSERT INTO siac_rep_raccordo_pdce_bil
SELECT a.ente_proprietario_id,
       null,
       a.classif_id,
       0,
       0,
       a.ordine, 
       user_table
FROM   siac_r_class_fam_tree a, siac_t_class_fam_tree b, siac_d_class_fam c
WHERE a.classif_fam_tree_id = b.classif_fam_tree_id
AND   c.classif_fam_id = b.classif_fam_id
AND   a.ente_proprietario_id = p_ente_prop_id
AND   (c.classif_fam_code = v_classificatori OR c.classif_fam_code = v_classificatori1 OR c.classif_fam_code = v_classificatori2)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL 
AND   c.data_cancellazione IS NULL;
/*SELECT  
       tb.ente_proprietario_id, 
       t1.classif_code,
       tb.classif_id, 
       tb.classif_id_padre,
       tb.level,
       tb.ordine, 
       user_table
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                             classif_fam_tree_id, 
                             classif_id, 
                             classif_id_padre, 
                             ente_proprietario_id, 
                             ordine, 
                             livello, 
                             level, arrhierarchy) AS (
       SELECT rt1.classif_classif_fam_tree_id,
              rt1.classif_fam_tree_id,
              rt1.classif_id,
              rt1.classif_id_padre,
              rt1.ente_proprietario_id,
              rt1.ordine,
              rt1.livello, 1,
              ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
       FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
       WHERE cf.classif_fam_id = tt1.classif_fam_id 
       AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
       AND   rt1.classif_id_padre IS NULL 
       AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1 OR cf.classif_fam_code = v_classificatori2)
       AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
       AND date_trunc('day'::text, now()) > tt1.validita_inizio 
       AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
       UNION ALL
       SELECT tn.classif_classif_fam_tree_id,
              tn.classif_fam_tree_id,
              tn.classif_id,
              tn.classif_id_padre,
              tn.ente_proprietario_id,
              tn.ordine,
              tn.livello,
              tp.level + 1,
              tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre 
    AND tn.ente_proprietario_id = tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id,
           rqname.classif_fam_tree_id,
           rqname.classif_id,
           rqname.classif_id_padre,
           rqname.ente_proprietario_id,
           rqname.ordine, rqname.livello,
           rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb,
    siac_t_class t1, siac_d_class_tipo ti1
WHERE tb.ente_proprietario_id  = p_ente_prop_id
AND  t1.classif_id = tb.classif_id           
AND  ti1.classif_tipo_id = t1.classif_tipo_id 
AND  t1.ente_proprietario_id = tb.ente_proprietario_id 
AND  ti1.ente_proprietario_id = t1.ente_proprietario_id;*/

raise notice 'ora: % ',clock_timestamp()::varchar;

RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

/* estrazione dei dati delle prime note */
IF p_classificatori = '1' THEN --BILR136
   sql_query_add := ' AND pdce_fam.pdce_fam_code IN (''CE'',''RE'') ';
   sql_query_add1 := ' AND strutt_pdce.pdce_liv0_code IN (''CE'',''RE'') ';
ELSIF p_classificatori = '2' THEN   --BILR131
   sql_query_add := ' AND pdce_fam.pdce_fam_code IN (''AP'',''PP'',''OP'',''OA'') '; 
   sql_query_add1 := ' AND strutt_pdce.pdce_liv0_code IN (''AP'',''PP'',''OP'',''OA'') ';
END IF;      

IF p_tipo_stampa = 1 THEN -- Stampo solo i piani dei conti legati ad importi
    
    sql_query := 
    'SELECT pdce_conto.pdce_conto_id,
            pdce_conto.livello,
            d_tipo_causale.causale_ep_tipo_code,                
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo,
            pdce_fam.pdce_fam_code,
            strutt_pdce.*          
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_d_causale_ep_tipo   d_tipo_causale,
           siac_rep_struttura_pdce  strutt_pdce,
           siac_t_mov_ep		    mov_ep     
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND    d_tipo_causale.causale_ep_tipo_id=causale_ep.causale_ep_tipo_id 
    AND   ((pdce_conto.livello=0 
                AND strutt_pdce.pdce_liv0_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=1 
                AND strutt_pdce.pdce_liv1_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=2 
                AND strutt_pdce.pdce_liv2_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=3 
                AND strutt_pdce.pdce_liv3_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=4 
                AND strutt_pdce.pdce_liv4_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=5 
                AND strutt_pdce.pdce_liv5_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=6 
                AND strutt_pdce.pdce_liv6_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=7 
                AND strutt_pdce.pdce_liv7_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=8 
                AND strutt_pdce.pdce_liv8_id=pdce_conto.pdce_conto_id))
    AND prima_nota.ente_proprietario_id='||p_ente_prop_id||'   
    AND anno_eserc.anno='''||p_anno||'''
    AND pnota_stato.pnota_stato_code=''D'''
    ||sql_query_add||' 
    AND strutt_pdce.utente='''||user_table||'''
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND (causale_ep.data_cancellazione is NULL
         OR 
         causale_ep.data_cancellazione BETWEEN to_timestamp(''01/01/'||p_anno||''', ''dd/mm/yyyy'') AND now()
         ) 
    AND d_tipo_causale.data_cancellazione is NULL';
    
ELSIF p_tipo_stampa = 2 THEN  -- Stampo tutti i piani dei conti legati o meno ad importi

 sql_query := 
 'WITH a AS(SELECT 
  strutt_pdce.pdce_liv0_id,
  strutt_pdce.pdce_liv0_id_padre,
  strutt_pdce.pdce_liv0_code,
  strutt_pdce.pdce_liv0_desc,
  strutt_pdce.pdce_liv1_id,
  strutt_pdce.pdce_liv1_id_padre,
  strutt_pdce.pdce_liv1_code,
  strutt_pdce.pdce_liv1_desc,
  strutt_pdce.pdce_liv2_id,
  strutt_pdce.pdce_liv2_id_padre,
  strutt_pdce.pdce_liv2_code,
  strutt_pdce.pdce_liv2_desc,
  strutt_pdce.pdce_liv3_id,
  strutt_pdce.pdce_liv3_id_padre,
  strutt_pdce.pdce_liv3_code,
  strutt_pdce.pdce_liv3_desc,
  strutt_pdce.pdce_liv4_id,
  strutt_pdce.pdce_liv4_id_padre,
  strutt_pdce.pdce_liv4_code,
  strutt_pdce.pdce_liv4_desc,
  strutt_pdce.pdce_liv5_id,
  strutt_pdce.pdce_liv5_id_padre,
  strutt_pdce.pdce_liv5_code,
  strutt_pdce.pdce_liv5_desc,
  strutt_pdce.pdce_liv6_id,
  strutt_pdce.pdce_liv6_id_padre,
  strutt_pdce.pdce_liv6_code,
  strutt_pdce.pdce_liv6_desc,
  strutt_pdce.pdce_liv7_id ,
  strutt_pdce.pdce_liv7_id_padre,
  strutt_pdce.pdce_liv7_code,
  strutt_pdce.pdce_liv7_desc,
  strutt_pdce.pdce_liv8_id,
  strutt_pdce.pdce_liv8_id_padre,
  strutt_pdce.pdce_liv8_code,
  strutt_pdce.pdce_liv8_desc,
  strutt_pdce.utente
FROM siac_rep_struttura_pdce strutt_pdce
WHERE strutt_pdce.utente='''||user_table||'''
'||sql_query_add1||'
)
, b AS (SELECT pdce_conto.pdce_conto_id,
               pdce_conto.livello,
               d_tipo_causale.causale_ep_tipo_code,                
               mov_ep_det.movep_det_segno, 
               mov_ep_det.movep_det_importo,
               pdce_fam.pdce_fam_code               
FROM   siac_t_periodo	 		anno_eserc,	
       siac_t_bil	 			bilancio,
       siac_t_prima_nota        prima_nota,
       siac_t_mov_ep_det	    mov_ep_det,
       siac_r_prima_nota_stato  r_pnota_stato,
       siac_d_prima_nota_stato  pnota_stato,
       siac_t_pdce_conto	    pdce_conto,
       siac_t_pdce_fam_tree     pdce_fam_tree,
       siac_d_pdce_fam          pdce_fam,
       siac_t_causale_ep	    causale_ep,
       siac_d_causale_ep_tipo   d_tipo_causale,
       siac_t_mov_ep		    mov_ep     
WHERE  bilancio.periodo_id=anno_eserc.periodo_id
AND    prima_nota.bil_id=bilancio.bil_id
AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
AND    prima_nota.pnota_id=mov_ep.regep_id
AND    mov_ep.movep_id=mov_ep_det.movep_id
AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
AND    d_tipo_causale.causale_ep_tipo_id=causale_ep.causale_ep_tipo_id 
AND prima_nota.ente_proprietario_id='||p_ente_prop_id||'   
AND anno_eserc.anno='''||p_anno||'''
AND pnota_stato.pnota_stato_code=''D'''
||sql_query_add||'
AND bilancio.data_cancellazione is NULL
AND anno_eserc.data_cancellazione is NULL
AND prima_nota.data_cancellazione is NULL
AND mov_ep.data_cancellazione is NULL
AND mov_ep_det.data_cancellazione is NULL
AND r_pnota_stato.data_cancellazione is NULL
AND pnota_stato.data_cancellazione is NULL
AND pdce_conto.data_cancellazione is NULL
AND pdce_fam_tree.data_cancellazione is NULL
AND pdce_fam.data_cancellazione is NULL
AND (causale_ep.data_cancellazione is NULL
     OR 
     causale_ep.data_cancellazione BETWEEN to_timestamp(''01/01/'||p_anno||''', ''dd/mm/yyyy'') AND now()
     ) 
AND d_tipo_causale.data_cancellazione is NULL
)
SELECT a.*,
b.pdce_conto_id,
b.livello,
b.causale_ep_tipo_code,                
b.movep_det_segno, 
b.movep_det_importo,
b.pdce_fam_code
FROM a
LEFT JOIN b ON
((b.livello=0 AND a.pdce_liv0_id=b.pdce_conto_id)
  OR (b.livello=1 
      AND a.pdce_liv1_id=b.pdce_conto_id)
  OR (b.livello=2 
      AND a.pdce_liv2_id=b.pdce_conto_id)
  OR (b.livello=3 
      AND a.pdce_liv3_id=b.pdce_conto_id)
  OR (b.livello=4 
      AND a.pdce_liv4_id=b.pdce_conto_id)
  OR (b.livello=5 
      AND a.pdce_liv5_id=b.pdce_conto_id)
  OR (b.livello=6 
      AND a.pdce_liv6_id=b.pdce_conto_id)
  OR (b.livello=7 
      AND a.pdce_liv7_id=b.pdce_conto_id)
  OR (b.livello=8 
      AND a.pdce_liv8_id=b.pdce_conto_id))';

END IF;

raise notice 'SQL % ',sql_query;

FOR elenco_prime_note IN
EXECUTE sql_query
        
LOOP
    
    saldo_prec_dare=0;
	saldo_prec_avere=0;
	saldo_ini_dare=0;
    saldo_ini_avere=0;
     
    tipo_pnota=elenco_prime_note.causale_ep_tipo_code;
    id_pdce0=COALESCE(elenco_prime_note.pdce_liv0_id,0);
    codice_pdce0=COALESCE(elenco_prime_note.pdce_liv0_code,'');
    descr_pdce0=COALESCE(elenco_prime_note.pdce_liv0_desc,'');
    
    id_pdce1=COALESCE(elenco_prime_note.pdce_liv1_id,0);
    codice_pdce1=COALESCE(elenco_prime_note.pdce_liv1_code,'');
    descr_pdce1=COALESCE(elenco_prime_note.pdce_liv1_desc,'');
    
    id_pdce2=COALESCE(elenco_prime_note.pdce_liv2_id,0);
    codice_pdce2=COALESCE(elenco_prime_note.pdce_liv2_code,'');
    descr_pdce2=COALESCE(elenco_prime_note.pdce_liv2_desc,'');
    
    id_pdce3=COALESCE(elenco_prime_note.pdce_liv3_id,0);
    codice_pdce3=COALESCE(elenco_prime_note.pdce_liv3_code,'');
    descr_pdce3=COALESCE(elenco_prime_note.pdce_liv3_desc,'');  
          
    id_pdce4=COALESCE(elenco_prime_note.pdce_liv4_id,0);
    codice_pdce4=COALESCE(elenco_prime_note.pdce_liv4_code,'');
    descr_pdce4=COALESCE(elenco_prime_note.pdce_liv4_desc,''); 
      
    id_pdce5=COALESCE(elenco_prime_note.pdce_liv5_id,0);
    codice_pdce5=COALESCE(elenco_prime_note.pdce_liv5_code,'');
    descr_pdce5=COALESCE(elenco_prime_note.pdce_liv5_desc,'');  
     
    id_pdce6=COALESCE(elenco_prime_note.pdce_liv6_id,0);
    codice_pdce6=COALESCE(elenco_prime_note.pdce_liv6_code,'');
    descr_pdce6=COALESCE(elenco_prime_note.pdce_liv6_desc,''); 
      
    IF p_liv_aggiuntivi = 'N' AND p_classificatori = '1' THEN    
       id_pdce7=0;
       codice_pdce7='';
       descr_pdce7='';         
    ELSE   
       id_pdce7=COALESCE(elenco_prime_note.pdce_liv7_id,0);
       codice_pdce7=COALESCE(elenco_prime_note.pdce_liv7_code,'');
       descr_pdce7=COALESCE(elenco_prime_note.pdce_liv7_desc,'');
    END IF;
    
    --SIAC-8580 01/08/2023. Gestione del livello 8.
    IF p_liv_aggiuntivi = 'N' AND p_classificatori <> '1' and elenco_prime_note.livello <> 8 THEN     
       id_pdce8=0;
       codice_pdce8='';
       descr_pdce8='';          
    ELSE         
    	--raise notice 'Livello 8 = %', elenco_prime_note.pdce_liv8_id;
        
       id_pdce8=COALESCE(elenco_prime_note.pdce_liv8_id,0);
       codice_pdce8=COALESCE(elenco_prime_note.pdce_liv8_code,'');
       descr_pdce8=COALESCE(elenco_prime_note.pdce_liv8_desc,'');      
    END IF;
    
    livello=elenco_prime_note.livello;
    
	if livello = 7 and id_pdce8 <> 0 then
    	importo_dare=0;
        importo_avere=0;
    else 
      IF upper(elenco_prime_note.movep_det_segno)='AVERE' THEN               
              importo_dare=0;
              importo_avere=COALESCE(elenco_prime_note.movep_det_importo,0);               
      ELSE                
              importo_dare=COALESCE(elenco_prime_note.movep_det_importo,0);
              importo_avere=0;                          
      END IF; 
    end if;
    
    v_pdce_conto_id := null;
   
    /* siac-task issue #212 04/10/2023.
       Cambio il modo in cui viene scelto il pdce_conto_id utilizzato.
       
    IF elenco_prime_note.pdce_liv8_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv8_id;
    ELSIF  elenco_prime_note.pdce_liv7_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv7_id;
    ELSIF  elenco_prime_note.pdce_liv6_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv6_id; 
    ELSIF  elenco_prime_note.pdce_liv5_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv5_id; 
    ELSIF  elenco_prime_note.pdce_liv4_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv4_id; 
    ELSIF  elenco_prime_note.pdce_liv3_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv3_id; 
    ELSIF  elenco_prime_note.pdce_liv2_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv2_id; 
    ELSIF  elenco_prime_note.pdce_liv1_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv1_id; 
    ELSIF  elenco_prime_note.pdce_liv0_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv0_id; 
    END IF;               
   
                                                    
            */
 	
     
    IF codice_pdce8 <> '' THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv8_id;
    ELSIF codice_pdce7 <> '' THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv7_id;
    ELSIF  elenco_prime_note.pdce_liv6_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv6_id; 
    ELSIF  elenco_prime_note.pdce_liv5_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv5_id; 
    ELSIF  elenco_prime_note.pdce_liv4_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv4_id; 
    ELSIF  elenco_prime_note.pdce_liv3_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv3_id; 
    ELSIF  elenco_prime_note.pdce_liv2_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv2_id; 
    ELSIF  elenco_prime_note.pdce_liv1_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv1_id; 
    ELSIF  elenco_prime_note.pdce_liv0_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv0_id; 
    END IF;       

            
    --siac-task issue #212 04/10/2023.
    --la gestione del classif_id viene spostata dopo l'assegnazione del v_pdce_conto_id.
               
    v_classif_id := null;
            
    SELECT rpcc.classif_id
    INTO   v_classif_id
    FROM   siac_r_pdce_conto_class rpcc
    WHERE  rpcc.pdce_conto_id = v_pdce_conto_id
    AND    rpcc.data_cancellazione IS NULL
    AND    v_anno_int BETWEEN date_part('year',rpcc.validita_inizio) AND date_part('year',COALESCE(rpcc.validita_fine,now())); -- SIAC-5487

    v_conta_ciclo_classif :=0;   
    v_classif_id_padre := null;
    cod_bil0='';
    cod_bil1='';
    cod_bil2='';
    cod_bil3='';
    cod_bil4='';
    cod_bil5='';
    cod_bil6='';
    cod_bil7='';
    cod_bil8='';  

    v_ordine := '';

    SELECT a.ordine
    INTO   v_ordine
    FROM siac_rep_raccordo_pdce_bil a
    WHERE a.classif_id = v_classif_id
    AND   a.utente = user_table;
            
    cod_bil0 := replace(v_ordine,'.','  ');
    
    -- Da ripristinare nel caso si voglia scomporre il valore di v_ordine
    -- per ripartirlo su piu' colonne
/*    v_conta_rec := 1;
    v_cod_bil_parziale := null;
    v_posiz_punto := 0;
    
   LOOP
    
        v_posiz_punto := POSITION('.' in COALESCE(v_cod_bil_parziale,v_ordine));
        
        IF v_conta_rec = 1 THEN
           IF v_posiz_punto <> 0 THEN
              cod_bil1 := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);     
           ELSE
              cod_bil1 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;   
        ELSIF v_conta_rec = 2 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil2 := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);        
           ELSE
              cod_bil2 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;          ELSIF v_conta_rec = 3 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil3 := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);
           ELSE
              cod_bil3 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;                  
        ELSIF v_conta_rec = 4 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil4 := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);   
           ELSE
              cod_bil4 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;                
        ELSIF v_conta_rec = 5 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil5:= SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);   
           ELSE
              cod_bil5 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;                
        ELSIF v_conta_rec = 6 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil6:= SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);  
           ELSE
              cod_bil6 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;                
        END IF;           
        
        v_cod_bil_parziale := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from position('.' in COALESCE(v_cod_bil_parziale,v_ordine))+1);
                     
        v_conta_rec := v_conta_rec + 1;
        
    	EXIT WHEN v_posiz_punto = 0;
    
    END LOOP;*/                  
    
      
    --raise notice 'importo dare = %, importo avere = %',importo_dare,importo_avere;
--	raise notice 'codice_pdce7 = % - codice_pdce8 = % - livello = % - id_pdce7 = % - id_pdce8 = % - Dare = % - Avere = %',
  --  	codice_pdce7, codice_pdce8, livello, id_pdce7, id_pdce8, importo_dare, importo_avere;
        

    return next;
    
    nome_ente='';
    id_pdce0=0;
    codice_pdce0='';
    descr_pdce0='';
    id_pdce1=0;
    codice_pdce1='';
    descr_pdce1='';
    id_pdce2=0;
    codice_pdce2='';
    descr_pdce2='';
    id_pdce3=0;
    codice_pdce3='';
    descr_pdce3='';        
    id_pdce4=0;
    codice_pdce4='';
    descr_pdce4='';   
    id_pdce5=0;
    codice_pdce5='';
    descr_pdce5='';   
    id_pdce6=0;
    codice_pdce6='';
    descr_pdce6='';   
    id_pdce7=0;
    codice_pdce7='';
    descr_pdce7='';    
    id_pdce8=0;
    codice_pdce8='';
    descr_pdce8='';   
    tipo_pnota='';
    importo_dare=0;
    importo_avere=0;
    livello=0;
    cod_bil0='';
    cod_bil1='';
    cod_bil2='';
    cod_bil3='';
    cod_bil4='';
    cod_bil5='';
    cod_bil6='';
    cod_bil7='';
    cod_bil8='';     
 
END LOOP;  
          
raise notice 'ora: % ',clock_timestamp()::varchar;            

delete from siac_rep_struttura_pdce where utente=user_table;
delete from siac_rep_raccordo_pdce_bil where utente=user_table;
  
EXCEPTION
	when no_data_found THEN
		 raise notice 'Dati non trovati' ;
	when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'SALDO PDCE',substring(SQLERRM from 1 for 500);
         return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR131_saldo_economico_patrimoniale" (p_ente_prop_id integer, p_anno varchar, p_classificatori varchar, p_liv_aggiuntivi varchar, p_tipo_stampa integer)
  OWNER TO siac;
  
--siac-task-issue #212 - Maurizio - FINE

  




-- INIZIO task-221.sql



\echo task-221.sql


--siac-task-issue #221 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR240_mov_cas_econ" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_da date,
  p_data_a date,
  p_cassaecon_id integer,
  p_num_impegno numeric,
  p_ant_spese_missione varchar
)
RETURNS TABLE (
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  anno_impegno integer,
  num_imp varchar,
  num_sub_impegno varchar,
  descr_impegno varchar,
  num_movimento varchar,
  tipo_richiesta varchar,
  num_sospeso varchar,
  data_movimento date,
  num_fattura varchar,
  num_quota integer,
  data_emis_fattura date,
  cod_benefic_fattura varchar,
  descr_benefic_fattura varchar,
  descr_richiesta varchar,
  imp_richiesta numeric,
  rendicontazione varchar,
  code_tipo_richiesta varchar,
  rendicontato varchar,
  importo_attuale_impegno numeric,
  num_carte_non_reg integer,
  imp_carte_non_reg numeric,
  num_predoc_non_liq integer,
  imp_predoc_non_liq numeric,
  num_doc_non_liq integer,
  imp_doc_non_liq numeric,
  imp_pagam_economali numeric,
  num_liquidazioni integer,
  imp_liquidazioni numeric,
  imp_totale_movimenti numeric,
  imp_disp_liquid numeric,
  imp_disp_pagare numeric,
  imp_disp_vincolare numeric
) AS
$body$
DECLARE

dati_movimenti record;
dati_giustif record;
bilancio_id integer;
contaProgRilevanteFPV integer;
contaVincolTrasfVincolati integer;

BEGIN
  num_capitolo='';
  num_articolo='';
  ueb='';
  anno_impegno=0;
  num_imp='';
  descr_impegno='';
  num_movimento='';
  tipo_richiesta='';
  num_sospeso='';
  data_movimento=NULL;
  num_fattura='';
  num_quota=0;
  data_emis_fattura=NULL;
  cod_benefic_fattura='';
  descr_benefic_fattura='';
  descr_richiesta='';
  imp_richiesta=0;   
  rendicontazione ='';
  code_tipo_richiesta='';
  num_sub_impegno='';
  rendicontato:='';
  importo_attuale_impegno:=0; 
  num_carte_non_reg:=0;
  imp_carte_non_reg:=0;
  num_predoc_non_liq:=0;
  imp_predoc_non_liq:=0;
  num_doc_non_liq:=0;
  imp_doc_non_liq:=0;
  imp_pagam_economali:=0;
  num_liquidazioni:=0;
  imp_liquidazioni :=0; 
  imp_disp_liquid :=0;
  imp_disp_pagare :=0;
  imp_disp_vincolare :=0;
  imp_totale_movimenti:=0;  
  
   select t_bil.bil_id
   	into bilancio_id 
   from siac_t_bil t_bil,
   	siac_t_periodo t_periodo
   where t_bil.periodo_id =t_periodo.periodo_id
   	and t_bil.ente_proprietario_id=p_ente_prop_id
    and t_periodo.anno =p_anno
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
    
   
for dati_movimenti in
    with elenco_movimenti as (
            select movimento.movt_numero num_movimento,
            	richiesta_econ_tipo.ricecon_tipo_code,
                richiesta_econ_tipo.ricecon_tipo_desc tipo_richiesta,
                COALESCE(richiesta_econ_sospesa.ricecons_numero::varchar,'') num_sospeso,
                movimento.movt_data data_movimento,
                documento.doc_numero num_fattura,
                sub_documento.subdoc_numero num_quota,
                documento.doc_data_emissione data_emis_fattura,
                soggetto.soggetto_code cod_benefic_fattura,
                soggetto.soggetto_desc descr_benefic_fattura,
                richiesta_econ.ricecon_desc descr_richiesta,
                /* se esiste un giustificativo, devo prendere il suo importo e non quello
                    del movimento */
                case when movimento.gst_id is not NULL 
                    then case when t_giustiv.rend_importo_restituito > 0
                        then -t_giustiv.rend_importo_restituito 
                        else case when t_giustiv.rend_importo_integrato > 0 
                            then t_giustiv.rend_importo_integrato 
                            else 0  end
                        end
                    else richiesta_econ.ricecon_importo end	imp_richiesta,
                case when movimento.gst_id is not NULL 
                    then 'S'::varchar else ''::varchar end 		rendicontazione,
                richiesta_econ_tipo.ricecon_tipo_code code_tipo_richiesta,
                case when mov_rend.movt_id IS NULL
                    then 'N' else 'S' end  	rendicontato,
                r_richiesta_movgest.movgest_ts_id
            from 	siac_t_movimento			movimento
                LEFT JOIN siac_t_giustificativo t_giustiv
                    ON (t_giustiv.gst_id = movimento.gst_id
                        and t_giustiv.data_cancellazione IS NULL)
                   --verifico se il movimento e' rendicontato
                LEFT JOIN (select movimento.movt_id
                           from siac_t_movimento		movimento,
                                siac_t_richiesta_econ	richiesta_econ,
                                siac_r_movimento_stampa	 r_movimento_sta,
                                siac_t_cassa_econ_stampa	cassa_stampa,
                                siac_t_cassa_econ_stampa_valore	cassa_stampa_val,
                                siac_d_cassa_econ_stampa_tipo	tipo_stampa,
                                siac_r_cassa_econ_stampa_stato  r_stato_stampa,
                                siac_d_cassa_econ_stampa_stato	stato_stampa
                           where movimento.ricecon_id=richiesta_econ.ricecon_id
                            and movimento.movt_id=r_movimento_sta.movt_id
                            and  r_movimento_sta.cest_id=cassa_stampa.cest_id
                            and  cassa_stampa.cest_id=cassa_stampa_val.cest_id
                            and  cassa_stampa.cest_tipo_id=tipo_stampa.cest_tipo_id
                            and  cassa_stampa.cest_id=r_stato_stampa.cest_id
                            and  r_stato_stampa.cest_stato_id=stato_stampa.cest_stato_id                                                                   
                            and movimento.ente_proprietario_id=p_ente_prop_id
                            and richiesta_econ.cassaecon_id=p_cassaecon_id
                            and richiesta_econ.bil_id=bilancio_id
                            and tipo_stampa.cest_tipo_code='REN'
                            and stato_stampa.cest_stato_code='D'
                            and  movimento.data_cancellazione is  NULL 
                            and  r_movimento_sta.data_cancellazione is  NULL
                            and  cassa_stampa.data_cancellazione is  NULL
                            and  cassa_stampa_val.data_cancellazione is  NULL
                            and  tipo_stampa.data_cancellazione is  NULL
                            and  r_stato_stampa.data_cancellazione is  NULL
                            and  stato_stampa.data_cancellazione is  NULL) mov_rend 
                     ON mov_rend.movt_id = movimento.movt_id,
                siac_t_richiesta_econ					richiesta_econ
                  LEFT join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
                      on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
                          and richiesta_econ_sospesa.data_cancellazione is null)
                  LEFT join siac_r_richiesta_econ_subdoc	r_richiesta_econ_subdoc
                      on (richiesta_econ.ricecon_id=r_richiesta_econ_subdoc.ricecon_id
                          and r_richiesta_econ_subdoc.data_cancellazione is null)            
                  LEFT join siac_t_subdoc	sub_documento
                      on (r_richiesta_econ_subdoc.subdoc_id=sub_documento.subdoc_id
                          and sub_documento.data_cancellazione is null)
                  LEFT join siac_t_doc				documento
                      on (sub_documento.doc_id=documento.doc_id
                          and documento.data_cancellazione is null  )            
                  LEFT join siac_r_subdoc_sog	sub_doc_sog
                      on (sub_documento.subdoc_id=sub_doc_sog.subdoc_id
                          and sub_doc_sog.data_cancellazione is null)
                  LEFT join siac_t_soggetto	soggetto
                      on (sub_doc_sog.soggetto_id=soggetto.soggetto_id
                          and soggetto.data_cancellazione is null ),
                siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
                siac_t_cassa_econ						cassa_econ,
                siac_r_richiesta_econ_stato				r_richiesta_stato,
                siac_d_richiesta_econ_stato				richiesta_stato,
                siac_r_richiesta_econ_movgest			r_richiesta_movgest
           where movimento.ricecon_id=richiesta_econ.ricecon_id
            and richiesta_econ.ricecon_tipo_id=richiesta_econ_tipo.ricecon_tipo_id
            and cassa_econ.cassaecon_id= richiesta_econ.cassaecon_id
            and richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id
            and r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id     
            and r_richiesta_movgest.ricecon_id= richiesta_econ.ricecon_id
            and movimento.ente_proprietario_id = p_ente_prop_id
            and richiesta_econ.bil_id=bilancio_id
            and richiesta_econ.cassaecon_id=p_cassaecon_id      			
            and richiesta_stato.ricecon_stato_code <> 'AN'  
            and movimento.data_cancellazione IS NULL
            and richiesta_econ.data_cancellazione IS NULL
            and richiesta_econ_tipo.data_cancellazione IS NULL
            and cassa_econ.data_cancellazione IS NULL
            and r_richiesta_stato.data_cancellazione IS NULL
            and richiesta_stato.data_cancellazione IS NULL
            and r_richiesta_movgest.data_cancellazione IS NULL),
    elenco_impegni_capitoli as (select movgest.movgest_anno anno_impegno, 
                    movgest.movgest_numero num_imp,
                    movgest.movgest_desc descr_impegno,
                    movgest_ts.movgest_ts_code num_sub_impegno,
                    bil_elem.elem_code num_capitolo,
                    bil_elem.elem_code2 num_articolo,
                    bil_elem.elem_code3 UEB,
                    t_movgest_ts_det.movgest_ts_det_importo importo_attuale_impegno,
                    movgest_ts.movgest_ts_id,
                    COALESCE(d_assenza_motiv.siope_assenza_motivazione_code,'') assenza_cig_code,
                    COALESCE(d_assenza_motiv.siope_assenza_motivazione_desc ,'') assenza_cig_desc,
                    d_movgest_stato.movgest_stato_code,
                    COALESCE(r_movgest_ts.movgest_ts_importo,0) importo_vincoli,
                    movgest.parere_finanziario,
                    bil_elem.elem_id
                from 	siac_t_movgest				movgest,
                        siac_d_movgest_tipo 		d_movgest_tipo,
                        siac_t_movgest_ts			movgest_ts
                        	LEFT JOIN siac_d_siope_assenza_motivazione d_assenza_motiv
                            	ON (d_assenza_motiv.siope_assenza_motivazione_id=movgest_ts.siope_assenza_motivazione_id
                                	and d_assenza_motiv.data_cancellazione IS NULL)
                            LEFT JOIN siac_r_movgest_ts r_movgest_ts
                            	ON (r_movgest_ts.movgest_ts_b_id=movgest_ts.movgest_ts_id
                                	and r_movgest_ts.data_cancellazione IS NULL
                                    --06/10/2023 siac-task-issue #221:
                                    --aggiunto controllo sulla data fine validita perche' l'applicativo non imposta
                                    --la data cancellazione ma solo quella di fine validita'
                                    and r_movgest_ts.validita_fine IS NULL),                    	
                        siac_t_movgest_ts_det		t_movgest_ts_det,                    
                        siac_d_movgest_ts_det_tipo 	d_movgest_ts_det_tipo,
                        siac_r_movgest_ts_stato		r_movgest_ts_stato,
                        siac_d_movgest_stato		d_movgest_stato,
                        siac_r_movgest_bil_elem		r_mov_gest_bil_elem,
                        siac_t_bil_elem				bil_elem
                where movgest.movgest_tipo_id= d_movgest_tipo.movgest_tipo_id
                    and movgest.movgest_id= movgest_ts.movgest_id
                    and movgest_ts.movgest_ts_id= t_movgest_ts_det.movgest_ts_id
                    and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                    and r_movgest_ts_stato.movgest_ts_id = movgest_ts.movgest_ts_id
                    and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id
                    and r_mov_gest_bil_elem.movgest_id= movgest.movgest_id   
                    and bil_elem.elem_id = r_mov_gest_bil_elem.elem_id
                    and movgest.ente_proprietario_id = p_ente_prop_id
                    and d_movgest_tipo.movgest_tipo_code ='I'
                    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code ='A'
                    and movgest.data_cancellazione IS NULL  
                    and d_movgest_tipo.data_cancellazione IS NULL
                    and movgest_ts.data_cancellazione IS NULL
                    and t_movgest_ts_det.data_cancellazione IS NULL
                    and d_movgest_ts_det_tipo.data_cancellazione IS NULL
                    and d_movgest_stato.data_cancellazione IS NULL
                    and r_movgest_ts_stato.data_cancellazione IS NULL
                    and r_mov_gest_bil_elem.data_cancellazione IS NULL
                    and bil_elem.data_cancellazione IS NULL)
    select elenco_impegni_capitoli.num_capitolo,
      elenco_impegni_capitoli.num_articolo,
      elenco_impegni_capitoli.UEB,
      elenco_impegni_capitoli.anno_impegno,
      elenco_impegni_capitoli.num_imp,
      elenco_impegni_capitoli.descr_impegno,
      elenco_movimenti.num_movimento,
      elenco_movimenti.tipo_richiesta,
      elenco_movimenti.num_sospeso,
      elenco_movimenti.data_movimento,
      elenco_movimenti.num_fattura,
      elenco_movimenti.num_quota,
      elenco_movimenti.data_emis_fattura,
      elenco_movimenti.cod_benefic_fattura,
      elenco_movimenti.descr_benefic_fattura,
      elenco_movimenti.descr_richiesta,
      elenco_movimenti.imp_richiesta,
      elenco_movimenti.rendicontazione,
      elenco_movimenti.code_tipo_richiesta,
      elenco_impegni_capitoli.num_sub_impegno,
      elenco_movimenti.rendicontato,
      elenco_impegni_capitoli.importo_attuale_impegno,
      elenco_impegni_capitoli.movgest_ts_id,
      elenco_impegni_capitoli.assenza_cig_code,
      elenco_impegni_capitoli.assenza_cig_desc,
      elenco_impegni_capitoli.movgest_stato_code,
      elenco_impegni_capitoli.importo_vincoli,
      elenco_impegni_capitoli.parere_finanziario,
      elenco_impegni_capitoli.elem_id
    from elenco_movimenti
        LEFT JOIN elenco_impegni_capitoli
            ON elenco_impegni_capitoli.movgest_ts_id = elenco_movimenti.movgest_ts_id 
    where ((p_data_da is NULL OR p_data_a is NULL) OR
        	 (p_data_da is NOT NULL AND p_data_a is NOT NULL
              AND elenco_movimenti.data_movimento between p_data_da and p_data_a))  
        AND ((p_num_impegno is NOT NULL and  elenco_impegni_capitoli.num_imp=p_num_impegno)
           	OR (p_num_impegno is NULL))      
         and ((p_ant_spese_missione = 'N' 
         		AND elenco_movimenti.ricecon_tipo_code<>'ANTICIPO_SPESE_MISSIONE')              
              OR (p_ant_spese_missione = 'S'))
    ORDER BY num_capitolo, num_articolo, ueb, anno_impegno, num_imp, num_sub_impegno
loop 
	num_capitolo:=dati_movimenti.num_capitolo;
    num_articolo:=dati_movimenti.num_articolo;
    ueb:=dati_movimenti.ueb;
    anno_impegno:=dati_movimenti.anno_impegno;
    num_imp:=dati_movimenti.num_imp;
    num_sub_impegno:=dati_movimenti.num_sub_impegno;
    descr_impegno:=dati_movimenti.descr_impegno;
    num_movimento:=dati_movimenti.num_movimento;
    tipo_richiesta:=dati_movimenti.tipo_richiesta;
    num_sospeso:=dati_movimenti.num_sospeso;
    data_movimento:=dati_movimenti.data_movimento;
    num_fattura:=dati_movimenti.num_fattura;
    num_quota:=dati_movimenti.num_quota;
    data_emis_fattura:=dati_movimenti.data_emis_fattura;
    cod_benefic_fattura:=dati_movimenti.cod_benefic_fattura;
    descr_benefic_fattura:=dati_movimenti.descr_benefic_fattura;
    descr_richiesta:=dati_movimenti.descr_richiesta;
    imp_richiesta:=dati_movimenti.imp_richiesta;   
    rendicontazione :=dati_movimenti.rendicontazione;
    code_tipo_richiesta:=dati_movimenti.code_tipo_richiesta;    
    rendicontato:=dati_movimenti.rendicontato;
    importo_attuale_impegno:=dati_movimenti.importo_attuale_impegno;    
    
    	--Estraggo i dati di riepilogo
    select dett_imp.n_carte_non_reg, dett_imp.tot_carte_non_reg, dett_imp.n_imp_predoc,
    	dett_imp.tot_imp_predoc, dett_imp.n_doc_non_liq, dett_imp.tot_doc_non_liq,
        (dett_imp.tot_imp_cec_fattura+dett_imp.tot_imp_cec_no_giust+dett_imp.tot_imp_cec_paf_fatt),
        dett_imp.n_doc_liq, dett_imp.tot_imp_liq    	
    into num_carte_non_reg, imp_carte_non_reg,  num_predoc_non_liq,
  		imp_predoc_non_liq, num_doc_non_liq,   imp_doc_non_liq,
  		imp_pagam_economali, num_liquidazioni, imp_liquidazioni
    from "fnc_siac_consultadettaglioimpegno"(dati_movimenti.movgest_ts_id) dett_imp;
    
    imp_totale_movimenti:= imp_carte_non_reg+imp_predoc_non_liq+imp_doc_non_liq+
    	imp_pagam_economali+imp_liquidazioni;

    
    --l'importo della disponibilita' a vincolare e' dato dall'importo
    -- attuale dell'impegno meno l'importo dei vincoli.
    imp_disp_vincolare:=dati_movimenti.importo_attuale_impegno-
    	dati_movimenti.importo_vincoli;

    --verifico se esitono progetti collegati all'impegno con FlagRilevanteFPV=true.
    contaProgRilevanteFPV:=0;
    select count(*)
	into contaProgRilevanteFPV    
    from siac_r_movgest_ts_programma r_mov_programma,
        siac_t_programma t_prog,
        siac_r_programma_attr r_prog_attr,
        siac_t_attr t_attr, 
        siac_d_attr_tipo d_attr_tipo   
    where t_prog.programma_id = r_mov_programma.programma_id
    and	t_prog.programma_id	= r_prog_attr.programma_id
    and	t_attr.attr_id			= r_prog_attr.attr_id
    and	t_attr.attr_tipo_id		= d_attr_tipo.attr_tipo_id
    and	r_mov_programma.ente_proprietario_id	= p_ente_prop_id
    and d_attr_tipo.attr_tipo_code	='B'
    and	t_attr.attr_code		= 	'FlagRilevanteFPV'
    and r_prog_attr."boolean" ='S'
    and r_mov_programma.movgest_ts_id = dati_movimenti.movgest_ts_id
    and t_prog.data_cancellazione is null
    and	r_mov_programma.data_cancellazione	is null
    and	t_attr.data_cancellazione	is null
    and r_prog_attr.data_cancellazione is null
    and d_attr_tipo.data_cancellazione IS NULL;
    
    -- verifico se esistono dei voncoli collegati al capitolo con 
    -- FlagTrasferimentiVincolati = true.
    contaVincolTrasfVincolati := 0;
    select count(*)
    into contaVincolTrasfVincolati
    from siac_r_vincolo_bil_elem r_vinc_bil_elem,
      siac_t_vincolo t_vincolo,
      siac_t_attr t_attr,
      siac_r_vincolo_attr r_vincolo_attr
    where r_vinc_bil_elem.vincolo_id=t_vincolo.vincolo_id
		and r_vincolo_attr.vincolo_id=t_vincolo.vincolo_id
     	and r_vincolo_attr.attr_id = t_attr.attr_id
        and r_vinc_bil_elem.elem_id = dati_movimenti.elem_id
        and t_attr.attr_code ='FlagTrasferimentiVincolati'
        and r_vincolo_attr."boolean" ='S'
        and r_vinc_bil_elem.data_cancellazione IS NULL 
        and t_vincolo.data_cancellazione IS NULL
        and t_attr.data_cancellazione IS NULL
        and r_vincolo_attr.data_cancellazione IS NULL;
        



		-- Per quanto riguarda l'importo "Disponibilita' a Vincolare" occorre
        -- fare le seguenti verifiche:
    	-- 1. se Motivo Assenza CIG dell'impegno = 'ID' - 'CIG in corso di definizione'.
        -- 2. se lo stato dell'impegno non e' DEFINITIVO.
        -- 3. se l'anno dell'impegno e' maggiore di quello del bilancio.
        -- 4. Se l'impegno non e' validato (flag parere finanziario non a TRUE).
        -- 5. Se l'impegno e' parzialmente vincolato (disponibilitaVincolare > 0 e 
		--    disponibilitaVincolare < importoAttuale.
        -- 6. Se l'impegno e' residuo e legato a un progetto rilevante fondo 
		--    (disponibilitaVincolare > 0 e Progetto.RilevanteFPV = TRUE.
        -- 7. Se l'impegno e' residuo e legato ad un Capitolo con un vincolo di 
        --    trasferimento (disponibilitaVincolare > 0 ed esiste almeno 1
		--    Capitolo.ListaVincoli.Vincolo.flagTrasferimpentiVincolati = TRUE ). 
        -- Se una delle precedenti verifiche ha dato esito positivo l'importo
        -- "Disponibilita' a Vincolare" deve essere impostato a 0.
        
        
    if dati_movimenti.assenza_cig_code = 'ID' OR
    	dati_movimenti.movgest_stato_code <> 'D' OR
        dati_movimenti.anno_impegno > p_anno::integer OR
        dati_movimenti.parere_finanziario = false OR
        (imp_disp_vincolare > 0 and 
         imp_disp_vincolare < dati_movimenti.importo_attuale_impegno) OR
        (imp_disp_vincolare > 0 and contaProgRilevanteFPV > 0) OR
        (imp_disp_vincolare > 0 and contaVincolTrasfVincolati > 0)
          then
    		raise notice 'L''impegno % ha: - assenza_cig_code = %', 
            	dati_movimenti.anno_impegno||'/'||dati_movimenti.num_imp||'/'||dati_movimenti.num_sub_impegno,
                dati_movimenti.assenza_cig_code;
            raise notice '             - stato = %', dati_movimenti.movgest_stato_code;
            raise notice '             - anno = %', dati_movimenti.anno_impegno;
            raise notice '             - parere finanziario = %', dati_movimenti.parere_finanziario;
            raise notice '             - importo disp a vincolare = %', imp_disp_vincolare;
            raise notice '             - parere finanziario = %', dati_movimenti.parere_finanziario;
            raise notice '             - progetti collegati con flag rilevante FPV a true = %', contaProgRilevanteFPV;
            raise notice '             - vincoli collegati con flag trasferimenti vincolati a true = %', contaVincolTrasfVincolati;
            raise notice '  L''importo disponibilita'' a liquidare e'' impostato a 0';
             
    	imp_disp_liquid:=0;
    else
		select disp_liq.val2
    	into imp_disp_liquid
    	from "fnc_siac_disponibilitaliquidaremovgest_rec"(dati_movimenti.movgest_ts_id::varchar) disp_liq;    
    end if;
    
    
    select disp_pag.val2
    into imp_disp_pagare
    from "fnc_siac_disponibileapagaremovgest_rec"(dati_movimenti.movgest_ts_id::varchar) disp_pag;    
        
return next; 

end loop;

  num_capitolo='';
  num_articolo='';
  ueb='';
  anno_impegno=0;
  num_imp='';
  descr_impegno='';
  num_movimento='';
  tipo_richiesta='';
  num_sospeso='';
  data_movimento=NULL;
  num_fattura='';
  num_quota=0;
  data_emis_fattura=NULL;
  cod_benefic_fattura='';
  descr_benefic_fattura='';
  descr_richiesta='';
  imp_richiesta=0;   
  rendicontazione ='';
  code_tipo_richiesta='';
  num_sub_impegno='';
  rendicontato:=''; 
  importo_attuale_impegno:=0;                                               
  num_carte_non_reg:=0;
  imp_carte_non_reg:=0;
  num_predoc_non_liq:=0;
  imp_predoc_non_liq:=0;
  num_doc_non_liq:=0;
  imp_doc_non_liq:=0;
  imp_pagam_economali:=0;
  num_liquidazioni:=0;
  imp_liquidazioni :=0;  
  imp_disp_liquid :=0;
  imp_disp_pagare :=0;
  imp_disp_vincolare :=0;                  
  imp_totale_movimenti:=0;  
  
exception
	when no_data_found THEN
		raise notice 'movimenti non trovati' ;
		--return next;
--	when others  THEN
	--	raise notice 'errore nella lettura dei movimenti. ';
  --      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR240_mov_cas_econ" (p_ente_prop_id integer, p_anno varchar, p_data_da date, p_data_a date, p_cassaecon_id integer, p_num_impegno numeric, p_ant_spese_missione varchar)
  OWNER TO siac;
  
--siac-task-issue #221 - Maurizio - FINE.
  




-- INIZIO task-229.sql



\echo task-229.sql


--siac-task issue #229 - Maurizio - INIZIO.

CREATE OR REPLACE FUNCTION siac."BILR116_Stampa_riepilogo_iva" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_mese varchar
)
RETURNS TABLE (
  bil_anno varchar,
  desc_ente varchar,
  data_registrazione date,
  cod_fisc_ente varchar,
  desc_periodo varchar,
  cod_tipo_registro varchar,
  desc_tipo_registro varchar,
  cod_registro varchar,
  desc_registro varchar,
  cod_aliquota_iva varchar,
  desc_aliquota_iva varchar,
  importo_iva_imponibile numeric,
  importo_iva_imposta numeric,
  importo_iva_totale numeric,
  tipo_reg_completa varchar,
  cod_reg_completa varchar,
  aliquota_completa varchar,
  tipo_registro varchar,
  data_emissione date,
  data_prot_def date,
  importo_iva_detraibile numeric,
  importo_iva_indetraibile numeric,
  importo_esente numeric,
  importo_split numeric,
  importo_fuori_campo numeric,
  percent_indetr numeric,
  pro_rata numeric,
  aliquota_perc numeric,
  importo_iva_split numeric,
  importo_detraibile numeric,
  importo_indetraibile numeric
) AS
$body$
DECLARE
classifBilRec record;
elencoRegistriIva record;

mese1 varchar;
anno1 varchar;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
ricorrente varchar;
v_id_doc integer;
v_tipo_doc varchar;

BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;   

TipoImpstanzresidui='SRI'; -- stanziamento residuo iniziale (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
desc_ente='';
data_registrazione=NULL;
cod_fisc_ente='';
desc_periodo='';
cod_tipo_registro='';
desc_tipo_registro='';
cod_registro='';
desc_registro='';
cod_aliquota_iva='';
desc_aliquota_iva='';
importo_iva_imponibile=0;
importo_iva_imposta=0;
importo_iva_totale=0;
tipo_reg_completa='';
cod_reg_completa='';
aliquota_completa='';
tipo_registro='';
data_emissione=NULL;
data_prot_def=NULL;
importo_iva_detraibile=0;
importo_iva_indetraibile=0;
importo_esente=0;
importo_split=0;
importo_fuori_campo=0;
importo_iva_split=0;
percent_indetr=0;
pro_rata=0;
aliquota_perc=0;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;

if p_mese = '12' THEN
	mese1='01';
    anno1=(p_anno ::integer +1) ::varchar;
else 
	mese1=(p_mese ::integer +1) ::varchar;
    anno1=p_anno;
end if;
raise notice 'mese = %, anno = %', mese1,anno1;
raise notice 'DATA A = %', to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy');
--raise notice 'DATA A meno uno = %', to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')-1;
 
RTN_MESSAGGIO:='Estrazione dei dati Registri IVA ''.';

/*
	24/08/2023: Procedura modificata per siac-task issues #153.
    L'estrazione principale e' stata spezzata in 2 parti, una per i documenti di Entrata e l'altra per quelli di Spesa.
    Per le entrate la ricerca oltre che per la data operazione (subdociva_data_prot_def) deve essere effettuata anche
    per la data fattura (doc_data_emissione); entrambe devono rientrare nel mese scelto dall'utente.
    Per le spese la ricerca deve avvenire per la data di quietanza.
*/

FOR elencoRegistriIva IN   
	--collegati a quote documento - ENTRATA   
  select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
  from siac_t_iva_registro t_reg_iva,
          siac_d_iva_registro_tipo d_iva_reg_tipo,
          siac_t_subdoc_iva t_subdoc_iva,
          siac_r_ivamov r_ivamov,
          siac_t_ivamov t_ivamov,
          siac_t_iva_aliquota t_iva_aliquota,
          siac_t_ente_proprietario ente_prop,
          siac_d_iva_operazione_tipo tipo_oper,
          siac_t_iva_gruppo iva_gruppo,
          siac_r_iva_registro_gruppo riva_gruppo,
          siac_r_iva_gruppo_prorata rprorata,
          siac_t_iva_prorata prorata,
          siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts,
          siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo
  where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
          AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
          AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
          AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
          AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
          AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
          AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
          AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
          AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
          AND rprorata.ivagru_id = iva_gruppo.ivagru_id
          AND prorata.ivapro_id=rprorata.ivapro_id
                  --- AGGIUNTO DA QUI
          AND    rssi.subdociva_id = t_subdoc_iva.subdociva_id
          AND    td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
          AND    rssi.subdoc_id = ts.subdoc_id
          AND    ts.doc_id = td.doc_id
          and td.doc_tipo_id=doc_tipo.doc_tipo_id
          and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id
          AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
          AND rprorata.ivagrupro_anno = p_anno::integer
          and doc_fam_tipo.doc_fam_tipo_code ='E' --documenti di entrata
         --AND t_subdoc_iva.subdociva_data_prot_def between  
        -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --aggiunto anche il test sulla data di emissione della fattura.
        --13/10/2023: siac-task issues #229:
        --cambio di requisito nel bilr116 per la parte delle fatture attive: deve riportare le fatture attive, riepilogate per 
        --registri, la cui data operazione (e non data fattura come e' ora) ricada nel mese per cui si sta producendo il report.
         AND /*((t_subdoc_iva.subdociva_data_prot_def >=  
       		 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
            t_subdoc_iva.subdociva_data_prot_def < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  OR
        	(td.doc_data_emissione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_emissione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))) */ 
             (td.doc_data_operazione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_operazione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))           
         --03/07/2018 SIAC-6275: occorre escludere i registri IVA
         -- con ivareg_flagliquidazioneiva = false
          AND t_reg_iva.ivareg_flagliquidazioneiva = true
          AND t_reg_iva.data_cancellazione IS NULL
          AND d_iva_reg_tipo.data_cancellazione IS NULL    
          AND t_subdoc_iva.data_cancellazione IS NULL 
          AND r_ivamov.data_cancellazione IS NULL
          AND t_ivamov.data_cancellazione IS NULL
          AND riva_gruppo.data_cancellazione is NULL
          AND t_iva_aliquota.data_cancellazione IS NULL
          AND rprorata.data_cancellazione is null
          AND    rssi.data_cancellazione IS NULL
          AND    ts.data_cancellazione IS NULL
          AND    td.data_cancellazione IS NULL
          --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
          --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
          --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
          --AND    t_subdoc_iva.dociva_r_id IS NULL
          /*AND not exists 
          (select 1 from siac_r_doc_iva b
              where b.doc_id = td.doc_id 
              and b.data_cancellazione is null )   */
  /*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
              t_iva_aliquota.ivaaliquota_code   */       
UNION
	--collegati al documento - ENTRATA
select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
from siac_t_iva_registro t_reg_iva,
		siac_d_iva_registro_tipo d_iva_reg_tipo,
        siac_t_subdoc_iva t_subdoc_iva,
        siac_r_ivamov r_ivamov,
        siac_t_ivamov t_ivamov,
        siac_t_iva_aliquota t_iva_aliquota,
        siac_t_ente_proprietario ente_prop,
        siac_d_iva_operazione_tipo tipo_oper,
        siac_t_iva_gruppo iva_gruppo,
        siac_r_iva_registro_gruppo riva_gruppo,
        siac_r_iva_gruppo_prorata rprorata,
        siac_t_iva_prorata prorata,
        siac_r_doc_iva rdi, siac_t_doc td,
        siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo
where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
		AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
        AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
        AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
        AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
        AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
        AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
        AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
        AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
        AND rprorata.ivagru_id = iva_gruppo.ivagru_id
        AND prorata.ivapro_id=rprorata.ivapro_id
                ---- DA QUI
        AND rdi.dociva_r_id = t_subdoc_iva.dociva_r_id
        AND td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
        AND rdi.doc_id = td.doc_id
        and td.doc_tipo_id=doc_tipo.doc_tipo_id
        and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id	
        AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
        AND rprorata.ivagrupro_anno = p_anno::integer
       --AND t_subdoc_iva.subdociva_data_prot_def between  
      -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
      --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
      	--24/08/2023: siac-task issues #153:
        --aggiunto anche il test sulla data di emissione della fattura.
		--13/10/2023: siac-task issues #229:
        --cambio di requisito nel bilr116 per la parte delle fatture attive: deve riportare le fatture attive, riepilogate per 
        --registri, la cui data operazione (e non data fattura come e' ora) ricada nel mese per cui si sta producendo il report.        
       AND /* ((t_subdoc_iva.subdociva_data_prot_def >=  
       		 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
            t_subdoc_iva.subdociva_data_prot_def < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  OR
       	(td.doc_data_emissione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_emissione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')))  */
              (td.doc_data_operazione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_operazione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))            
       --03/07/2018 SIAC-6275: occorre escludere i registri IVA
       -- con ivareg_flagliquidazioneiva = false
        AND t_reg_iva.ivareg_flagliquidazioneiva = true
        and doc_fam_tipo.doc_fam_tipo_code ='E' --documenti di entrata
        AND t_reg_iva.data_cancellazione IS NULL
        AND d_iva_reg_tipo.data_cancellazione IS NULL    
        AND t_subdoc_iva.data_cancellazione IS NULL 
        AND r_ivamov.data_cancellazione IS NULL
        AND t_ivamov.data_cancellazione IS NULL
        AND riva_gruppo.data_cancellazione is NULL
        AND t_iva_aliquota.data_cancellazione IS NULL
        AND rprorata.data_cancellazione is null
        AND    rdi.data_cancellazione IS NULL
        AND    td.data_cancellazione IS NULL
        --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
        --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
        --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
        AND    t_subdoc_iva.dociva_r_id  IS NOT NULL
        and not exists (select 1 from siac_r_subdoc_subdoc_iva x
   			 where x.data_cancellazione is null and x.validita_fine is null 
             --and x.subdociva_id = t_subdoc_iva.subdociva_id
             and exists   (
             select y.subdoc_id from siac_t_subdoc y
             where y.doc_id=td.doc_id
             and x.subdoc_id = y.subdoc_id
             and y.data_cancellazione is null
  		) )
UNION        
	--collegati a quote documento - SPESA   
  select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
  from siac_t_iva_registro t_reg_iva,
          siac_d_iva_registro_tipo d_iva_reg_tipo,
          siac_t_subdoc_iva t_subdoc_iva,
          siac_r_ivamov r_ivamov,
          siac_t_ivamov t_ivamov,
          siac_t_iva_aliquota t_iva_aliquota,
          siac_t_ente_proprietario ente_prop,
          siac_d_iva_operazione_tipo tipo_oper,
          siac_t_iva_gruppo iva_gruppo,
          siac_r_iva_registro_gruppo riva_gruppo,
          siac_r_iva_gruppo_prorata rprorata,
          siac_t_iva_prorata prorata,
          siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts,
          siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo,
          siac_r_subdoc_ordinativo_ts r_sub_ord_ts, 
          siac_t_ordinativo ord, siac_t_ordinativo_ts ord_ts, siac_t_ordinativo_ts_det ord_ts_det,
          siac_d_ordinativo_ts_det_tipo ord_ts_det_tipo, siac_r_ordinativo_stato r_ord_stato,
          siac_d_ordinativo_stato ord_stato 
  where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
          AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
          AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
          AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
          AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
          AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
          AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
          AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
          AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
          AND rprorata.ivagru_id = iva_gruppo.ivagru_id
          AND prorata.ivapro_id=rprorata.ivapro_id
                  --- AGGIUNTO DA QUI
          AND    rssi.subdociva_id = t_subdoc_iva.subdociva_id
          AND    td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
          AND    rssi.subdoc_id = ts.subdoc_id
          AND    ts.doc_id = td.doc_id
          and td.doc_tipo_id=doc_tipo.doc_tipo_id
          and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id
          and r_sub_ord_ts.subdoc_id=ts.subdoc_id
          and ts.doc_id=td.doc_id
          and ord_ts.ord_ts_id=r_sub_ord_ts.ord_ts_id
          and ord_ts.ord_id=ord.ord_id
          and ord_ts_det.ord_ts_id=ord_ts.ord_ts_id
          and ord_ts_det_tipo.ord_ts_det_tipo_id=ord_ts_det.ord_ts_det_tipo_id
          and r_ord_stato.ord_id=ord.ord_id
          and r_ord_stato.ord_stato_id=ord_stato.ord_stato_id
          AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
          AND rprorata.ivagrupro_anno = p_anno::integer
          and doc_fam_tipo.doc_fam_tipo_code ='S' --documenti di spesa
         --AND t_subdoc_iva.subdociva_data_prot_def between  
        -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --Cambiato il test: non subdociva_data_prot_def ma la data di quietanza che è quella in cui e' stato inserito lo stato
        --quietanziato.
        /* AND (t_subdoc_iva.subdociva_data_prot_def >=  
          to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
          t_subdoc_iva.subdociva_data_prot_def <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  */         
         AND (r_ord_stato.validita_inizio >=  
       	 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
         r_ord_stato.validita_inizio <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))
         --24/08/2023: siac-task issues #153:
         --solo quelli Quietanziati
         and ord_stato.ord_stato_code = 'Q'
         --03/07/2018 SIAC-6275: occorre escludere i registri IVA
         -- con ivareg_flagliquidazioneiva = false
          AND t_reg_iva.ivareg_flagliquidazioneiva = true
          AND t_reg_iva.data_cancellazione IS NULL
          AND d_iva_reg_tipo.data_cancellazione IS NULL    
          AND t_subdoc_iva.data_cancellazione IS NULL 
          AND r_ivamov.data_cancellazione IS NULL
          AND t_ivamov.data_cancellazione IS NULL
          AND riva_gruppo.data_cancellazione is NULL
          AND t_iva_aliquota.data_cancellazione IS NULL
          AND rprorata.data_cancellazione is null
          AND    rssi.data_cancellazione IS NULL
          AND    ts.data_cancellazione IS NULL
          AND    td.data_cancellazione IS NULL
          --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
          --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
          --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
          --AND    t_subdoc_iva.dociva_r_id IS NULL
          /*AND not exists 
          (select 1 from siac_r_doc_iva b
              where b.doc_id = td.doc_id 
              and b.data_cancellazione is null )   */
  /*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
              t_iva_aliquota.ivaaliquota_code   */       
UNION
	--collegati al documento - SPESA
select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
from siac_t_iva_registro t_reg_iva,
		siac_d_iva_registro_tipo d_iva_reg_tipo,
        siac_t_subdoc_iva t_subdoc_iva,
        siac_r_ivamov r_ivamov,
        siac_t_ivamov t_ivamov,
        siac_t_iva_aliquota t_iva_aliquota,
        siac_t_ente_proprietario ente_prop,
        siac_d_iva_operazione_tipo tipo_oper,
        siac_t_iva_gruppo iva_gruppo,
        siac_r_iva_registro_gruppo riva_gruppo,
        siac_r_iva_gruppo_prorata rprorata,
        siac_t_iva_prorata prorata,
        siac_r_doc_iva rdi, siac_t_doc td,
        siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_sub_ord_ts, siac_t_subdoc subdoc,
        siac_t_ordinativo ord, siac_t_ordinativo_ts ord_ts, siac_t_ordinativo_ts_det ord_ts_det,
        siac_d_ordinativo_ts_det_tipo ord_ts_det_tipo, siac_r_ordinativo_stato r_ord_stato,
        siac_d_ordinativo_stato ord_stato 
where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
		AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
        AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
        AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
        AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
        AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
        AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
        AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
        AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
        AND rprorata.ivagru_id = iva_gruppo.ivagru_id
        AND prorata.ivapro_id=rprorata.ivapro_id
                ---- DA QUI
        AND rdi.dociva_r_id = t_subdoc_iva.dociva_r_id
        AND td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
        AND rdi.doc_id = td.doc_id
        and td.doc_tipo_id=doc_tipo.doc_tipo_id
        and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id	
        and r_sub_ord_ts.subdoc_id=subdoc.subdoc_id
        and subdoc.doc_id=td.doc_id
        and ord_ts.ord_ts_id=r_sub_ord_ts.ord_ts_id
        and ord_ts.ord_id=ord.ord_id
        and ord_ts_det.ord_ts_id=ord_ts.ord_ts_id
        and ord_ts_det_tipo.ord_ts_det_tipo_id=ord_ts_det.ord_ts_det_tipo_id
        and r_ord_stato.ord_id=ord.ord_id
        and r_ord_stato.ord_stato_id=ord_stato.ord_stato_id
        AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
        AND rprorata.ivagrupro_anno = p_anno::integer
       --AND t_subdoc_iva.subdociva_data_prot_def between  
      -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
      --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --Cambiato il test: non subdociva_data_prot_def ma la data di quietanza che è quella in cui e' stato inserito lo stato
        --quietanziato.
    /*   AND (t_subdoc_iva.subdociva_data_prot_def >=  
       	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        t_subdoc_iva.subdociva_data_prot_def <  
       to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  */
        AND (r_ord_stato.validita_inizio >=  
       	 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
         r_ord_stato.validita_inizio <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  
         --24/08/2023: siac-task issues #153:
         --solo quelli Quietanziati
       and ord_stato.ord_stato_code = 'Q'
       --03/07/2018 SIAC-6275: occorre escludere i registri IVA
       -- con ivareg_flagliquidazioneiva = false
        AND t_reg_iva.ivareg_flagliquidazioneiva = true
        and doc_fam_tipo.doc_fam_tipo_code ='S' --documenti di spesa
        AND t_reg_iva.data_cancellazione IS NULL
        AND d_iva_reg_tipo.data_cancellazione IS NULL    
        AND t_subdoc_iva.data_cancellazione IS NULL 
        AND r_ivamov.data_cancellazione IS NULL
        AND t_ivamov.data_cancellazione IS NULL
        AND riva_gruppo.data_cancellazione is NULL
        AND t_iva_aliquota.data_cancellazione IS NULL
        AND rprorata.data_cancellazione is null
        AND    rdi.data_cancellazione IS NULL
        AND    td.data_cancellazione IS NULL
        --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
        --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
        --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
        AND    t_subdoc_iva.dociva_r_id  IS NOT NULL
        and subdoc.data_cancellazione IS NULL
        and r_sub_ord_ts.data_cancellazione IS NULL
        and ord.data_cancellazione IS NULL
        and ord_ts.data_cancellazione IS NULL
        and r_ord_stato.data_cancellazione IS NULL
        and r_ord_stato.validita_fine IS NULL
        and not exists (select 1 from siac_r_subdoc_subdoc_iva x
   			 where x.data_cancellazione is null and x.validita_fine is null 
             --and x.subdociva_id = t_subdoc_iva.subdociva_id
             and exists   (
             select y.subdoc_id from siac_t_subdoc y
             where y.doc_id=td.doc_id
             and x.subdoc_id = y.subdoc_id
             and y.data_cancellazione is null
  		) )        
/*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
			t_iva_aliquota.ivaaliquota_code     */     
loop

--COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))

select x.* 
into v_id_doc , v_tipo_doc  from (
  SELECT distinct td.doc_id, tipo.doc_tipo_code
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts, siac_d_doc_tipo tipo
  WHERE  rssi.subdociva_id = elencoRegistriIva.subdociva_id
  AND    td.ente_proprietario_id = p_ente_prop_id
  AND    rssi.subdoc_id = ts.subdoc_id
  AND    ts.doc_id = td.doc_id
  AND	 tipo.doc_tipo_id= td.doc_tipo_id
  AND    rssi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
  --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    elencoRegistriIva.dociva_r_id IS NULL
  UNION 
  SELECT distinct td.doc_id,  tipo.doc_tipo_code
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_doc_iva rdi, siac_t_doc td, siac_t_subdoc ts, siac_d_doc_tipo tipo
  WHERE  rdi.dociva_r_id = elencoRegistriIva.dociva_r_id 
  AND    td.ente_proprietario_id = p_ente_prop_id
  AND    rdi.doc_id = td.doc_id
  AND    ts.doc_id = td.doc_id
  AND	 tipo.doc_tipo_id= td.doc_tipo_id
  AND    rdi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
  --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    elencoRegistriIva.dociva_r_id  IS NOT NULL
  ) x;

raise notice 'v_id_doc - v_tipo_doc % - %', v_id_doc , v_tipo_doc ; 



bil_anno='';
desc_ente=elencoRegistriIva.ente_denominazione;
data_registrazione=elencoRegistriIva.subdociva_data_emissione;
cod_fisc_ente=elencoRegistriIva.codice_fiscale;
desc_periodo='';
cod_tipo_registro=elencoRegistriIva.ivareg_tipo_code;
desc_tipo_registro=elencoRegistriIva.ivareg_tipo_desc;
cod_registro=elencoRegistriIva.ivareg_code;
desc_registro=elencoRegistriIva.ivareg_desc;
cod_aliquota_iva=elencoRegistriIva.ivaaliquota_code;
desc_aliquota_iva=elencoRegistriIva.ivaaliquota_desc;
importo_iva_imponibile=elencoRegistriIva.ivamov_imponibile;
importo_iva_imposta=elencoRegistriIva.ivamov_imposta;
importo_iva_totale=elencoRegistriIva.ivamov_totale;

tipo_reg_completa=desc_tipo_registro;
cod_reg_completa=desc_registro;
aliquota_completa= desc_aliquota_iva;
data_emissione=elencoRegistriIva.data_emissione;
data_prot_def=elencoRegistriIva.data_prot_def; 


-- CI = CORRISPETTIVI
-- VI = VENDITE IVA IMMEDIATA
-- VD = VENDITE IVA DIFFERITA
-- AI = ACQUISTI IVA IMMEDIATA
-- AD = ACQUISTI IVA DIFFERITA
if cod_tipo_registro = 'CI' OR cod_tipo_registro = 'VI' OR cod_tipo_registro = 'VD' THEN
	tipo_registro='V'; --VENDITE
ELSE
	tipo_registro='A'; --ACQUISTI
END IF;



if v_tipo_doc in ('NCD', 'NCV') and elencoRegistriIva.ivamov_imponibile > 0 
then 
   	importo_iva_imponibile= importo_iva_imponibile*-1;
	importo_iva_imposta=importo_iva_imposta*-1;
	importo_iva_totale=importo_iva_totale*-1;
end if;
       

importo_iva_indetraibile=round((coalesce(importo_iva_imposta,0)/100)*coalesce(elencoRegistriIva.ivaaliquota_perc_indetr,0),2);
importo_iva_detraibile=coalesce(importo_iva_imposta,0) - importo_iva_indetraibile;

importo_indetraibile=round((coalesce(importo_iva_imponibile,0)/100)*coalesce(elencoRegistriIva.ivaaliquota_perc_indetr,0),2);
importo_detraibile=coalesce(importo_iva_imponibile,0) - importo_indetraibile;

importo_esente=0;

if elencoRegistriIva.ivaop_tipo_code = 'ES' then
	importo_esente=importo_iva_imponibile;
end if;

importo_fuori_campo=0;

if elencoRegistriIva.ivaop_tipo_code = 'FCI' then
	importo_fuori_campo=importo_iva_imponibile;
end if;

importo_split=0;
if elencoRegistriIva.ivaaliquota_split = true then
	importo_split=importo_detraibile;
    importo_iva_split=importo_iva_detraibile;
end if;



percent_indetr= elencoRegistriIva.ivaaliquota_perc_indetr;
pro_rata=elencoRegistriIva.ivapro_perc;
aliquota_perc=elencoRegistriIva.ivaaliquota_perc;


return next;

bil_anno='';
desc_ente='';
data_registrazione=NULL;
cod_fisc_ente='';
desc_periodo='';
cod_tipo_registro='';
desc_tipo_registro='';
cod_registro='';
desc_registro='';
cod_aliquota_iva='';
desc_aliquota_iva='';
importo_iva_imponibile=0;
importo_iva_imposta=0;
importo_iva_totale=0;
tipo_reg_completa='';
cod_reg_completa='';
aliquota_completa='';
tipo_registro='';
data_emissione=NULL;
data_prot_def=NULL;
importo_iva_detraibile=0;
importo_iva_indetraibile=0;
importo_esente=0;
importo_split=0;
importo_iva_split=0;
importo_fuori_campo=0;
percent_indetr=0;
pro_rata=0;
aliquota_perc=0;
end loop;




raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato per i registri IVA' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR116_Stampa_riepilogo_iva" (p_ente_prop_id integer, p_anno varchar, p_mese varchar)
  OWNER TO siac;


--siac-task issue #229 - Maurizio - FINE.





-- INIZIO task-251.sql



\echo task-251.sql


-- siac-task-251 Sofia - 19.10.2023

DROP INDEX IF EXISTS idx_siac_t_avanzovincolo_anno;
CREATE UNIQUE index if not exists idx_siac_t_avanzovincolo_anno ON siac.siac_t_avanzovincolo 
USING btree (avav_tipo_id,extract(year from  validita_inizio));




-- INIZIO task-272.sql



\echo task-272.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_mutuo_programma;
create or replace view siac.siac_v_dwh_mutuo_programma
(
    ente_proprietario_id,
    anno_bilancio,
    mutuo_numero,
    mutuo_programma_tipo,
    mutuo_programma_code,
    mutuo_programma_importo_iniz,
    mutuo_programma_importo_fin
 )
AS
(
SELECT 
    per.ente_proprietario_id,
    per.anno::integer anno_bilancio,
    mutuo.mutuo_numero,
    tipo.programma_tipo_code mutuo_programma_tipo,
    prog.programma_code  mutuo_programma_code,
    rp.mutuo_programma_importo_iniziale ,
    rp.mutuo_programma_importo_finale 
FROM siac_t_bil bil,siac_t_periodo per,
             siac_t_programma prog,siac_d_programma_tipo tipo,
             siac_t_mutuo mutuo ,siac_r_mutuo_programma  rp 
where bil.periodo_id=per.periodo_id 
and      prog.bil_id=bil.bil_id 
and      tipo.programma_tipo_id=prog.programma_tipo_id  
and      rp.programma_id=prog.programma_id  
and      mutuo.mutuo_id=rp.mutuo_id 
and      rp.data_cancellazione  is null 
and      mutuo.data_cancellazione  is null
and      prog.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_programma owner to siac;







-- INIZIO task-277.sql



\echo task-277.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/




insert into siac_d_commissione_tipo  
(
comm_tipo_code,
comm_tipo_desc,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select 'ES1',
           'AMMPUBB',
           now(),
           'SIAC-TASK-277',
           ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =2
and      not exists 
(
select 1 
from siac_d_commissione_tipo  tipo1 
where tipo1.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo1.comm_tipo_code ='ES1'
and      tipo1.data_cancellazione  is null 
and      tipo1.validita_fine is null 
);

insert into siac_r_commissione_tipo_plus 
(
comm_tipo_id,
comm_tipo_plus_id ,
validita_inizio ,
login_operazione ,
ente_proprietario_id 
)
select tipo.comm_tipo_id,
           plus.comm_tipo_plus_id ,
           now(),
           'SIAC-TASK-277',
           tipo.ente_proprietario_id 
from siac_t_ente_proprietario  ente ,siac_d_commissione_tipo  tipo,siac_d_commissione_tipo_plus  plus
where ente.ente_proprietario_id =2
and      tipo.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo.comm_tipo_code ='ES1'
and      plus.ente_proprietario_id =2
and      plus.comm_tipo_plus_code ='ES'
and      plus.comm_tipo_plus_esente =true
and      not exists 
(
select 1 
from siac_r_commissione_tipo_plus  r  
where r.ente_proprietario_id =ente.ente_proprietario_id  
and     r.comm_tipo_plus_id =plus.comm_tipo_plus_id 
and     r.comm_tipo_id =tipo.comm_tipo_id 
and     r.data_cancellazione  is null 
and    r.validita_fine  is null 
);




-- INIZIO task.216.sql



\echo task.216.sql


--siac-task issue #216 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR228_parametri_obiettivi_per_comuni" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_code_report varchar
)
RETURNS TABLE (
  importo_p1 numeric,
  importo_p2 numeric,
  importo_p3 numeric,
  importo_p4 numeric,
  importo_p5 numeric,
  importo_p6 numeric,
  importo_p7 numeric,
  importo_p8 numeric,
  nome_ente varchar,
  sigla_prov varchar,
  provincia varchar,
  display_error varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
denom_ente varchar;

variabiliRendiconto record;
entrataRendiconto record;
spesaRendiconto record;
fpvAnnoPrecRendiconto record;

ripiano_disav_rnd numeric;
anticip_tesoreria_rnd numeric;
max_previsto_norma_rnd numeric;
impegni_estinz_anticip_rnd numeric;
disav_iscrit_spesa_rnd numeric;
importo_debiti_fuori_bil_ricon_rnd numeric;
importo_debiti_fuori_bil_corso_ricon_rnd numeric;
importo_debiti_fuori_bil_ricon_corso_finanz_rnd numeric;

rend_accert_A_titoli_123 numeric; 
rend_prev_def_cassa_CS_titoli_123 numeric; 
rend_risc_conto_comp_RC_pdce_E_1_01 numeric;
rend_risc_conto_res_RR_pdce_E_1_01 numeric;
rend_risc_conto_comp_RC_pdce_E_1_01_04 numeric;
rend_risc_conto_res_RR_pdce_E_1_01_04 numeric;
rend_risc_conto_comp_RC_pdce_E_3 numeric;
rend_risc_conto_res_RR_pdce_E_3 numeric;
rend_accert_A_pdce_E_4_02_06 numeric;
rend_accert_A_pdce_E_4_03_01 numeric;
rend_accert_A_pdce_E_4_03_04 numeric;
TotaleRiscossioniTR numeric;
TotaleAccertatoA numeric;
TotaleResAttiviRS numeric;

rend_impegni_I_macroagg101 numeric;
rend_FPV_macroagg_101 numeric;
rend_impegni_I_macroagg107 numeric;
rend_impegni_I_titolo_4 numeric;
rend_impegni_I_pdce_U_1_02_01_01 numeric;
rend_FPV_anno_prec_macroagg101 numeric;
rend_impegni_i_pdce_U_1_07_06_02 numeric;
rend_impegni_i_pdce_U_1_07_06_04 numeric;
rend_impegni_I_titoli_1_2 numeric;

indic_13_2_app numeric;
indic_13_3_app numeric;

id_report_config integer;

rend_accert_A_pdce_E_4_03_07 numeric;
rend_accert_A_pdce_E_4_03_08 numeric;
rend_accert_A_pdce_E_4_03_09 numeric;

denominatore NUMERIC;

BEGIN

/*
	Questa procedura e' utilizzata dai report BILR228, BILR229, BILR330, BILR331,
    BILR332, BILR333, BILR334 e BILR335 per estrarre i dati che servono per il 
    calcolo dei paramentri obiettivi.
    I dati sono quelli estratti per gli indicatori di rendiconto.
    Sono estratti i dati delle variabili e per farlo sono richiamate le seguenti 
    procedure usate nei report degli indicatori:
    - BILR186_indic_sint_ent_rend_org_er; per le entrate;
    - BILR186_indic_sint_spe_rend_org_er; per le spese;
    - BILR186_indic_sint_spe_rend_FPV_anno_prec; per l'FPV anno precedente.
    
    La procedura effettua il calcolo dei singoli valori usati per il calcolo
    applicando gli algoritmi che per gli indicatori sono utilizzati all'interno 
    dei report.
    In questo modo la procedura restiruisce i valori degli indicatori gia' calcolati
    ed il report deve solo mostrarne il valore ed eventualmente cambiare il colore
    della cella se il dato e' fuori soglia.
    
*/

importo_p1:=0;
importo_p2:=0;
importo_p3:=0;
importo_p4:=0;
importo_p5:=0;
importo_p6:=0;
importo_p7:=0;
importo_p8:=0;
nome_ente:='';
sigla_prov:='';
provincia:='';
display_error:='';

select ente_denominazione
	into denom_ente
from siac_t_ente_proprietario
where ente_proprietario_id = p_ente_prop_id
	and data_cancellazione IS NULL;

if denom_ente IS NULL THEN
	denom_ente :='';
end if;
    
raise notice 'Ente = %', denom_ente;

--verifico se l'ente e' abilitato all'utilizzo del report.
id_report_config:=NULL;
select a.report_param_def_id, a.nome_ente, a.sigla_prov, a.provincia
into id_report_config, nome_ente, sigla_prov, provincia
from siac_t_config_ente_report_param_def a
where a.ente_proprietario_id = p_ente_prop_id
	and a.rep_codice = p_code_report
    and a.data_cancellazione IS NULL
    and a.validita_fine IS NULL;
 
raise notice 'id_report_config = %', id_report_config;

if id_report_config IS NULL THEN
	display_error := 'L''ENTE ''' || denom_ente || ''' NON E'' ABILITATO ALL''UTILIZZO DEL REPORT '||p_code_report;
    nome_ente:=denom_ente;
    return next;
    return;
end if;


  
--variabili
ripiano_disav_rnd:=0;
anticip_tesoreria_rnd:=0;
max_previsto_norma_rnd:=0;
impegni_estinz_anticip_rnd:=0;
disav_iscrit_spesa_rnd:=0;
importo_debiti_fuori_bil_ricon_rnd:=0;
importo_debiti_fuori_bil_corso_ricon_rnd:=0;
importo_debiti_fuori_bil_ricon_corso_finanz_rnd:=0;
indic_13_2_app:=0;
indic_13_3_app:=0;


--entrate importo_accertato_a titoli 1,2,3
rend_accert_A_titoli_123:=0;
--entrate importo_prev_def_cassa_cs titoli 1,2,3
rend_prev_def_cassa_CS_titoli_123:=0;
--entrate importo_risc_conto_comp_rc pdce 'E.1.01'
rend_risc_conto_comp_RC_pdce_E_1_01 :=0;
--entrate importo_risc_conto_comp_rc pdce  'E.1.01.04'
rend_risc_conto_comp_RC_pdce_E_1_01_04:=0;
--entrate importo_risc_conto_comp_rc pdce   'E.3'
rend_risc_conto_comp_RC_pdce_E_3:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.1.01'
rend_risc_conto_res_RR_pdce_E_1_01:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.1.01.04'
rend_risc_conto_res_RR_pdce_E_1_01_04:=0;
--entrate "importo_risc_conto_res_rr pdce   'E.3'
rend_risc_conto_res_RR_pdce_E_3:=0;
--entrate importo_accertato_a pdce   'E.4.02.06'
rend_accert_A_pdce_E_4_02_06:=0;
--entrate importo_accertato_a pdce   'E.4.03.01'
rend_accert_A_pdce_E_4_03_01:=0;
--entrate importo_accertato_a pdce   'E.4.03.04'
rend_accert_A_pdce_E_4_03_04:=0;
--entrate totale RISCOSSIONI 
TotaleRiscossioniTR:=0;
--entrate totale ACCERTATO
TotaleAccertatoA:=0;
--entrate totale RSIDUI ATTIVI
TotaleResAttiviRS:=0;

--spese imp_impegnato_i macroagg '101'
rend_impegni_I_macroagg101:=0;
--spese imp_impegnato_i FPV macroagg '101'
rend_FPV_macroagg_101:=0;
--spese imp_impegnato_i macroagg '107'
rend_impegni_I_macroagg107:=0;
--spese imp_impegnato_i titolo '4'
rend_impegni_I_titolo_4:=0;
--spese imp_impegnato_i pdce 'U.1.02.01.01'
rend_impegni_I_pdce_U_1_02_01_01:=0;
--spese anno_prec spese_fpv_anni_prec macroagg '101'
rend_FPV_anno_prec_macroagg101:=0;
--spese imp_impegnato_i pdce 'U.1.07.06.02'
rend_impegni_i_pdce_U_1_07_06_02:=0;
--spese imp_impegnato_i pdce 'U.1.07.06.04'
rend_impegni_i_pdce_U_1_07_06_04:=0;
--spese imp_impegnato_i titoli '1', '2'
rend_impegni_I_titoli_1_2:=0;

--entrate importo_accertato_a pdce   'E.4.03.07'
rend_accert_A_pdce_E_4_03_07 :=0;
--entrate importo_accertato_a pdce   'E.4.03.08'
rend_accert_A_pdce_E_4_03_08 :=0;
--entrate importo_accertato_a pdce   'E.4.03.09'
rend_accert_A_pdce_E_4_03_09 :=0;

	-- estraggo la parte relativa alle variabili.
for variabiliRendiconto IN
  select t_voce_conf_indicatori_sint.voce_conf_ind_codice,
      t_voce_conf_indicatori_sint.voce_conf_ind_desc,
      t_conf_indicatori_sint.conf_ind_valore_anno,
      t_conf_indicatori_sint.conf_ind_valore_anno_1,
      t_conf_indicatori_sint.conf_ind_valore_anno_2
  from siac_t_conf_indicatori_sint t_conf_indicatori_sint,
      siac_t_voce_conf_indicatori_sint t_voce_conf_indicatori_sint,
      siac_t_bil t_bil,
      siac_t_periodo t_periodo
  where t_conf_indicatori_sint.bil_id=t_bil.bil_id
      and t_bil.periodo_id=t_periodo.periodo_id
      and t_voce_conf_indicatori_sint.voce_conf_ind_id=t_conf_indicatori_sint.voce_conf_ind_id
      and t_conf_indicatori_sint.ente_proprietario_id =p_ente_prop_id
      and t_periodo.anno=p_anno
      and t_voce_conf_indicatori_sint.voce_conf_ind_tipo='R'
      and t_voce_conf_indicatori_sint.voce_conf_ind_codice in ('ripiano_disav_rnd',
      	'anticip_tesoreria_rnd', 'max_previsto_norma_rnd','impegni_estinz_anticip_rnd',
        'importo_debiti_fuori_bil_ricon_rnd','importo_debiti_fuori_bil_corso_ricon_rnd',
        'importo_debiti_fuori_bil_ricon_corso_finanz_rnd')
      and t_conf_indicatori_sint.data_cancellazione IS NULL
      and t_bil.data_cancellazione IS NULL
      and t_periodo.data_cancellazione IS NULL
      and t_voce_conf_indicatori_sint.data_cancellazione IS NULL
loop
      if variabiliRendiconto.voce_conf_ind_codice = 'ripiano_disav_rnd' THEN
      	ripiano_disav_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'anticip_tesoreria_rnd' THEN
      	anticip_tesoreria_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'max_previsto_norma_rnd' THEN
      	max_previsto_norma_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;
      if variabiliRendiconto.voce_conf_ind_codice = 'impegni_estinz_anticip_rnd' THEN
      	impegni_estinz_anticip_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;           
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_ricon_rnd' THEN
      	importo_debiti_fuori_bil_ricon_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;   
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_corso_ricon_rnd' THEN
      	importo_debiti_fuori_bil_corso_ricon_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;  
      if variabiliRendiconto.voce_conf_ind_codice = 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd' THEN
      	importo_debiti_fuori_bil_ricon_corso_finanz_rnd := COALESCE(variabiliRendiconto.conf_ind_valore_anno,0);
      end if;        
end loop;


	-- estraggo la parte relativa al rendiconto di ENTRATA e calcolo
    -- i singoli valori.
for entrataRendiconto in  
  select code_titolo, pdce_code,
      sum(importo_accertato_a) importo_accertato_a, 
      sum(importo_prev_def_cassa_cs) importo_prev_def_cassa_cs, 
      sum(importo_risc_conto_comp_rc) importo_risc_conto_comp_rc,
      sum(importo_risc_conto_res_rr) importo_risc_conto_res_rr,
      sum(importo_tot_risc_tr) importo_tot_risc_tr   ,
      sum(importo_res_attivi_rs) importo_res_attivi_rs
  from "BILR186_indic_sint_ent_rend_org_er"(p_ente_prop_id, p_anno)
  group by code_titolo, pdce_code
loop 
	TotaleRiscossioniTR:= TotaleRiscossioniTR +
    	COALESCE(entrataRendiconto.importo_tot_risc_tr,0);
    TotaleAccertatoA:=TotaleAccertatoA +
    	COALESCE(entrataRendiconto.importo_accertato_a,0);   
    TotaleResAttiviRS:= TotaleResAttiviRS +
    	COALESCE(entrataRendiconto.importo_res_attivi_rs,0);      

	if entrataRendiconto.code_titolo in ('1','2','3') THEN
    	rend_accert_A_titoli_123:=rend_accert_A_titoli_123 +
        	COALESCE(entrataRendiconto.importo_accertato_a,0);
        rend_prev_def_cassa_CS_titoli_123:=rend_prev_def_cassa_CS_titoli_123 +
        	COALESCE(entrataRendiconto.importo_prev_def_cassa_cs,0);
    end if;
    if left(entrataRendiconto.pdce_code,6) = 'E.1.01' then
    	rend_risc_conto_comp_RC_pdce_E_1_01:=rend_risc_conto_comp_RC_pdce_E_1_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_1_01:=rend_risc_conto_res_RR_pdce_E_1_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;
    if left(entrataRendiconto.pdce_code,9) = 'E.1.01.04' then
    	rend_risc_conto_comp_RC_pdce_E_1_01_04:=rend_risc_conto_comp_RC_pdce_E_1_01_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_1_01_04:=rend_risc_conto_res_RR_pdce_E_1_01_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;
    if left(entrataRendiconto.pdce_code,3) = 'E.3' then
    	rend_risc_conto_comp_RC_pdce_E_3:=rend_risc_conto_comp_RC_pdce_E_3 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
        rend_risc_conto_res_RR_pdce_E_3:=rend_risc_conto_res_RR_pdce_E_3 +
        	COALESCE(entrataRendiconto.importo_risc_conto_res_rr,0);
    end if;    
    if left(entrataRendiconto.pdce_code,9) = 'E.4.02.06' then
    	rend_accert_A_pdce_E_4_02_06:=rend_accert_A_pdce_E_4_02_06 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;       
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.01' then
    	rend_accert_A_pdce_E_4_03_01:=rend_accert_A_pdce_E_4_03_01 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;        
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.04' then
    	rend_accert_A_pdce_E_4_03_04:=rend_accert_A_pdce_E_4_03_04 +
        	COALESCE(entrataRendiconto.importo_risc_conto_comp_rc,0);
    end if;            

	--13/10/2023 - siac-task issue #216.
    --Aggiunti rend_accert_A_pdce_E_4_03_07, rend_accert_A_pdce_E_4_03_08 e rend_accert_A_pdce_E_4_03_09.
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.07' then
    	rend_accert_A_pdce_E_4_03_07:=rend_accert_A_pdce_E_4_03_07+
        	COALESCE(entrataRendiconto.importo_accertato_a,0);            
    end if;
    
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.08' then
    	rend_accert_A_pdce_E_4_03_08:=rend_accert_A_pdce_E_4_03_08+
        	COALESCE(entrataRendiconto.importo_accertato_a,0);            
    end if;    
    
    if left(entrataRendiconto.pdce_code,9) = 'E.4.03.09' then
    	rend_accert_A_pdce_E_4_03_09:=rend_accert_A_pdce_E_4_03_09+
        	COALESCE(entrataRendiconto.importo_accertato_a,0);            
    end if;      
    
end loop;

--rend_accert_A_pdce_E_4_03_07:=100000000;
--rend_accert_A_pdce_E_4_03_08:=100000001;
--rend_accert_A_pdce_E_4_03_09:=100000002;

--raise notice 'rend_accert_A_pdce_E_4_03_07 = % - rend_accert_A_pdce_E_4_03_08 = % - rend_accert_A_pdce_E_4_03_09 = %',
--	rend_accert_A_pdce_E_4_03_07, rend_accert_A_pdce_E_4_03_08, rend_accert_A_pdce_E_4_03_09;
    

	-- estraggo la parte relativa al rendiconto di SPESA e calcolo
    -- i singoli valori.
for spesaRendiconto in  
  select code_titolo, code_macroagg, tipo_capitolo, pdce_code,
      sum(imp_impegnato_i) imp_impegnato_i 
  from "BILR186_indic_sint_spe_rend_org_er"(p_ente_prop_id, p_anno)
  group by code_titolo, code_macroagg, tipo_capitolo, pdce_code
loop 
	if left(spesaRendiconto.code_macroagg,3) = '101' then
    	rend_impegni_I_macroagg101:=rend_impegni_I_macroagg101+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
        if spesaRendiconto.tipo_capitolo = 'FPV' then
        	rend_FPV_macroagg_101:=rend_FPV_macroagg_101+
            	COALESCE(spesaRendiconto.imp_impegnato_i,0);
        end if;
    end if;
    if left(spesaRendiconto.code_macroagg,3) = '107' then
		rend_impegni_I_macroagg107:=rend_impegni_I_macroagg107+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;
    if  spesaRendiconto.code_titolo = '4' then
		rend_impegni_I_titolo_4:=rend_impegni_I_titolo_4+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;    
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.02.01.01' then
		rend_impegni_I_pdce_U_1_02_01_01:=rend_impegni_I_pdce_U_1_02_01_01+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.07.06.02' then
		rend_impegni_i_pdce_U_1_07_06_02:=rend_impegni_i_pdce_U_1_07_06_02+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  left(spesaRendiconto.pdce_code,12) = 'U.1.07.06.04' then
		rend_impegni_i_pdce_U_1_07_06_04:=rend_impegni_i_pdce_U_1_07_06_04+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  
    if  spesaRendiconto.code_titolo in ('1','2') then
		rend_impegni_I_titoli_1_2:=rend_impegni_I_titoli_1_2+
        	COALESCE(spesaRendiconto.imp_impegnato_i,0);
    end if;  

end loop;

	--estraggo il valore FPV anno precedente per macroaggreagato 101.
select COALESCE(sum(spese_fpv_anni_prec),0) 
	into rend_FPV_anno_prec_macroagg101
   from "BILR186_indic_sint_spe_rend_FPV_anno_prec"(p_ente_prop_id, p_anno)
   where left(code_macroagg,3) = '101';

/* I commenti riportati nel seguito per ogni variabile sono i calcoli che
	vengono effettuati all'interno dei report degli indicatori.
*/    

/* IMPORTO P1 = Indicatore 1.1 = 
	var Denom = row._outer["rend_accert_A_titoli_123"];

	(dataSetRow["ripiano_disav_rnd"]+
	 row._outer._outer._outer["rend_impegni_I_macroagg101"] +
	 row._outer._outer._outer["rend_impegni_I_pdce_U.1.02.01.01"] -
	 row._outer._outer["rend_FPV_anno_prec_macroagg101"] +
 	 row._outer._outer._outer["rend_FPV_macroagg_101"] +
 	 row._outer._outer._outer["rend_impegni_I_macroagg107"] +
 	 row._outer._outer._outer["rend_impegni_I_titolo_4"]) /
 	 Denom;
*/
/*
--13/10/2023 - siac-task issue #216.
--Al denominatore devono essere aggiunti gli stanziamenti di competenza Categorie 4.03.07, 4.03.08, 4.03.09
var Denom = 0;
if(row._outer["rend_accert_A_titoli_123"] != null)  Denom = Denom + row._outer["rend_accert_A_titoli_123"];
if(row._outer["rend_accert_A_pdce_E.4.03.07"] != null) Denom = Denom + row._outer["rend_accert_A_pdce_E.4.03.07"];
if(row._outer["rend_accert_A_pdce_E.4.03.08"] != null) Denom = Denom + row._outer["rend_accert_A_pdce_E.4.03.08"];
if(row._outer["rend_accert_A_pdce_E.4.03.09"] != null) Denom = Denom + row._outer["rend_accert_A_pdce_E.4.03.09"];

Prima era:
if rend_accert_A_titoli_123 != 0 then
	importo_p1 :=
		(ripiano_disav_rnd + rend_impegni_I_macroagg101
        + rend_impegni_I_pdce_U_1_02_01_01 
        - rend_FPV_anno_prec_macroagg101 + rend_FPV_macroagg_101
        + rend_impegni_I_macroagg107 + rend_impegni_I_titolo_4) /
        rend_accert_A_titoli_123;
end if;

*/

denominatore:=0;
denominatore:=COALESCE(rend_accert_A_titoli_123,0) + COALESCE(rend_accert_A_pdce_E_4_03_07, 0) +
	COALESCE(rend_accert_A_pdce_E_4_03_08,0) + COALESCE(rend_accert_A_pdce_E_4_03_09, 0);

if denominatore != 0 then
	importo_p1 :=
		(ripiano_disav_rnd + rend_impegni_I_macroagg101
        + rend_impegni_I_pdce_U_1_02_01_01 
        - rend_FPV_anno_prec_macroagg101 + rend_FPV_macroagg_101
        + rend_impegni_I_macroagg107 + rend_impegni_I_titolo_4) /
        denominatore;
end if;

/* IMPORTO P2 = Indicatore 2.8 = 
	(dataSetRow["rend_risc_conto_comp_RC_pdce_E.1.01"] + dataSetRow["rend_risc_conto_res_RR_pdce_E.1.01"]
	 - dataSetRow["rend_risc_conto_comp_RC_pdce_E.1.01.04"] - dataSetRow["rend_risc_conto_res_RR_pdce_E.1.01.04"]
	 +dataSetRow["rend_risc_conto_comp_RC_pdce_E.3"] +dataSetRow["rend_risc_conto_res_RR_pdce_E.3"]) /
	dataSetRow["rend_prev_def_cassa_CS_titoli_123"]
*/    
if rend_prev_def_cassa_CS_titoli_123 != 0 then
	importo_p2 := 
	(rend_risc_conto_comp_RC_pdce_E_1_01+rend_risc_conto_res_RR_pdce_E_1_01
     - rend_risc_conto_comp_RC_pdce_E_1_01_04 - rend_risc_conto_res_RR_pdce_E_1_01_04 
     + rend_risc_conto_comp_RC_pdce_E_3 + rend_risc_conto_res_RR_pdce_E_3) /
	rend_prev_def_cassa_CS_titoli_123;
end if;

/* IMPORTO P3 = Indicatore 3.2 = 
	dataSetRow["anticip_tesoreria_rnd"] /
	dataSetRow["max_previsto_norma_rnd"];
*/
if max_previsto_norma_rnd != 0 then
	importo_p3 := anticip_tesoreria_rnd / max_previsto_norma_rnd;
end if;

/* IMPORTO P4 = Indicatore 10.3 =
(row._outer._outer["rend_impegni_I_macroagg107"] -
	 row._outer._outer["rend_impegni_I_pdce_U.1.07.06.02"] -
	 row._outer._outer["rend_impegni_I_pdce_U.1.07.06.04"] +
	 row._outer._outer["rend_impegni_I_titolo_4"] -
	 row["impegni_estinz_anticip_rnd"] -
	 (row._outer["rend_accert_A_pdce_E.4.02.06"] +
	  row._outer["rend_accert_A_pdce_E.4.03.01"] +
	  row._outer["rend_accert_A_pdce_E.4.03.04"])) /
	  row._outer["rend_accert_A_titoli_123"];
*/
/*
--13/10/2023 - siac-task issue #216.
--Al denominatore devono essere aggiunti gli stanziamenti di competenza Categorie 4.03.07, 4.03.08, 4.03.09
var Denom = 0;
if(row._outer["rend_accert_A_titoli_123"] != null)  Denom = Denom + row._outer["rend_accert_A_titoli_123"];
if(row._outer["rend_accert_A_pdce_E.4.03.07"] != null) Denom = Denom + row._outer["rend_accert_A_pdce_E.4.03.07"];
if(row._outer["rend_accert_A_pdce_E.4.03.08"] != null) Denom = Denom + row._outer["rend_accert_A_pdce_E.4.03.08"];
if(row._outer["rend_accert_A_pdce_E.4.03.09"] != null) Denom = Denom + row._outer["rend_accert_A_pdce_E.4.03.09"];

Prima era:

if rend_accert_A_titoli_123 != 0 then
	importo_p4 := 
    (rend_impegni_I_macroagg107 - rend_impegni_i_pdce_U_1_07_06_02
     - rend_impegni_i_pdce_U_1_07_06_04 + rend_impegni_I_titolo_4
     - impegni_estinz_anticip_rnd
     - (rend_accert_A_pdce_E_4_02_06 + rend_accert_A_pdce_E_4_03_01
        + rend_accert_A_pdce_E_4_03_04)) /
    rend_accert_A_titoli_123;
end if;

*/
denominatore:=0;
denominatore:=COALESCE(rend_accert_A_titoli_123,0) + COALESCE(rend_accert_A_pdce_E_4_03_07, 0) +
	COALESCE(rend_accert_A_pdce_E_4_03_08,0) + COALESCE(rend_accert_A_pdce_E_4_03_09, 0);
    
if denominatore != 0 then
	importo_p4 := 
    (rend_impegni_I_macroagg107 - rend_impegni_i_pdce_U_1_07_06_02
     - rend_impegni_i_pdce_U_1_07_06_04 + rend_impegni_I_titolo_4
     - impegni_estinz_anticip_rnd
     - (rend_accert_A_pdce_E_4_02_06 + rend_accert_A_pdce_E_4_03_01
        + rend_accert_A_pdce_E_4_03_04)) /
    denominatore;
end if;

/* IMPORTO P5 = Indicatore 12.4 =
	dataSetRow["disav_iscrit_spesa_rnd"] /
	row._outer["rend_accert_A_titoli_123"];
    
*/

if rend_accert_A_titoli_123 != 0 then
	importo_p5 := disav_iscrit_spesa_rnd / rend_accert_A_titoli_123;
end if;    

/* IMPORTO P6 = Indicatore 13.1 =
    	dataSetRow["importo_debiti_fuori_bil_ricon_rnd"] /
	row._outer["rend_impegni_I_titoli_1_2"];
    
*/

if rend_impegni_I_titoli_1_2 != 0 then
	importo_p6 := 
    	importo_debiti_fuori_bil_ricon_rnd/ rend_impegni_I_titoli_1_2;
end if;



/* IMPORTO P7 = Indicatore 13.2 + 13.3 =
	13.2
		dataSetRow["importo_debiti_fuori_bil_corso_ricon_rnd"] /
		row._outer["rend_accert_A_titoli_123"];
    13.3
    dataSetRow["importo_debiti_fuori_bil_ricon_corso_finanz_rnd"] /
		row._outer["rend_accert_A_titoli_123"] ;
*/    
if rend_accert_A_titoli_123 != 0 then
	importo_p7 :=
    	(importo_debiti_fuori_bil_corso_ricon_rnd / rend_accert_A_titoli_123) +
        (importo_debiti_fuori_bil_ricon_corso_finanz_rnd / rend_accert_A_titoli_123);
end if;

/* IMPORTO P8 = Indicatore Analitico report BILR191, colonna
% di riscossione complessiva: (Riscossioni c/comp+ Riscossioni c/residui)/ 
	(Accertamenti + residui definitivi iniziali)
    
    Poiche' la procedura BILR181_indic_ana_ent_rend_org_er (usata nel report BILR91)
    estrae gli stessi dati della BILR186_indic_sint_ent_rend_org_er solo raggruppati
    in modo diverso evito di chiamare la BILR181_indic_ana_ent_rend_org_er in quanto
    serve solo il dato toale.
    
	row._outer["TotaleRiscossioniTR"] / 
	(row._outer["TotaleAccertatoA"] + row._outer["TotaleResAttiviRS"]);    

*/
if TotaleAccertatoA + TotaleResAttiviRS != 0 then	
	importo_p8 :=
		TotaleRiscossioniTR /
		(TotaleAccertatoA + TotaleResAttiviRS);
end if;
        
raise notice '';
raise notice '               IMPORTI VARIABILI';
raise notice 'ripiano_disav_rnd = %', ripiano_disav_rnd;
raise notice 'anticip_tesoreria_rnd = %', anticip_tesoreria_rnd;
raise notice 'max_previsto_norma_rnd = %', max_previsto_norma_rnd;
raise notice 'impegni_estinz_anticip_rnd = %', impegni_estinz_anticip_rnd;
raise notice 'importo_debiti_fuori_bil_ricon_rnd = %', importo_debiti_fuori_bil_ricon_rnd;
raise notice 'importo_debiti_fuori_bil_corso_ricon_rnd = %', importo_debiti_fuori_bil_corso_ricon_rnd;
raise notice 'importo_debiti_fuori_bil_ricon_corso_finanz_rnd = %', importo_debiti_fuori_bil_ricon_corso_finanz_rnd;

raise notice '';
raise notice '               IMPORTI ENTRATE'; 
raise notice 'rend_accert_A_titoli_123 = %', rend_accert_A_titoli_123;
raise notice 'rend_prev_def_cassa_CS_titoli_123 = %', rend_prev_def_cassa_CS_titoli_123;
raise notice 'rend_risc_conto_comp_RC_pdce_E_1_01 = %', rend_risc_conto_comp_RC_pdce_E_1_01;
raise notice 'rend_risc_conto_res_RR_pdce_E_1_01 = %', rend_risc_conto_res_RR_pdce_E_1_01;
raise notice 'rend_risc_conto_comp_RC_pdce_E_1_01_04 = %', rend_risc_conto_comp_RC_pdce_E_1_01_04;
raise notice 'rend_risc_conto_res_RR_pdce_E_1_01_04 = %', rend_risc_conto_res_RR_pdce_E_1_01_04;
raise notice 'rend_risc_conto_comp_RC_pdce_E_3 = %', rend_risc_conto_comp_RC_pdce_E_3;
raise notice 'rend_risc_conto_res_RR_pdce_E_3 = %', rend_risc_conto_res_RR_pdce_E_3;  
raise notice 'rend_accert_A_pdce_E_4_02_06 = %', rend_accert_A_pdce_E_4_02_06;
raise notice 'rend_accert_A_pdce_E_4_03_01 = %', rend_accert_A_pdce_E_4_03_01;
raise notice 'rend_accert_A_pdce_E_4_03_04 = %', rend_accert_A_pdce_E_4_03_04;  
raise notice 'TotaleRiscossioniTR = %', TotaleRiscossioniTR;
raise notice 'TotaleAccertatoA = %', TotaleAccertatoA;
raise notice 'TotaleResAttiviRS = %', TotaleResAttiviRS;
        
raise notice '';
raise notice '               IMPORTI SPESE';   
raise notice 'rend_impegni_I_macroagg101 = %', rend_impegni_I_macroagg101;    
raise notice 'rend_FPV_macroagg_101 = %', rend_FPV_macroagg_101;    
raise notice 'rend_impegni_I_macroagg107 = %', rend_impegni_I_macroagg107; 
raise notice 'rend_impegni_I_titolo_4 = %', rend_impegni_I_titolo_4;
raise notice 'rend_impegni_I_pdce_U_1_02_01_01 = %', rend_impegni_I_pdce_U_1_02_01_01;
raise notice 'rend_FPV_anno_prec_macroagg101 = %', rend_FPV_anno_prec_macroagg101;
raise notice 'rend_impegni_i_pdce_U_1_07_06_02 = %', rend_impegni_i_pdce_U_1_07_06_02;
raise notice 'rend_impegni_i_pdce_U_1_07_06_04 = %', rend_impegni_i_pdce_U_1_07_06_04;
raise notice 'rend_impegni_I_titoli_1_2 = %', rend_impegni_I_titoli_1_2;
raise notice 'rend_accert_A_pdce_E_4_03_07 = %', rend_accert_A_pdce_E_4_03_07;
raise notice 'rend_accert_A_pdce_E_4_03_08 = %', rend_accert_A_pdce_E_4_03_08;
raise notice 'rend_accert_A_pdce_E_4_03_09 = %', rend_accert_A_pdce_E_4_03_09;



return next;

exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato';
		return;
	when others  THEN
		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
		return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR228_parametri_obiettivi_per_comuni" (p_ente_prop_id integer, p_anno varchar, p_code_report varchar)
  OWNER TO siac;

--siac-task issue #216 - Maurizio - FINE






