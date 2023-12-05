/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_siac_dwh_programma_cronop
(
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_programma_cronop
(
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE


v_user_table varchar;
params varchar;
fnc_eseguita integer;
interval_esec integer:=1;

BEGIN

esito:='fnc_siac_dwh_programma_cronop : inizio - '||clock_timestamp()||'.';
return next;

IF p_ente_proprietario_id IS NULL THEN
	   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo.';
END IF;

IF p_anno_bilancio IS NULL THEN
	   RAISE EXCEPTION 'Errore: Parametro Anno Bilancio nullo.';
END IF;


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni log
where log.ente_proprietario_id=p_ente_proprietario_id
and	  log.fnc_elaborazione_inizio >= (now() - interval '13 hours' )::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and   log.fnc_name='fnc_siac_dwh_programma_cronop';

-- 22.07.2019 Sofia siac-6973
fnc_eseguita:=0;
if fnc_eseguita<= 0 then
	esito:= 'fnc_siac_dwh_programma_cronop : continue - eseguita da piu'' di '|| interval_esec::varchar||' ore - '||clock_timestamp()||'.';
	return next;


	/* 20.06.2019 Sofia siac-6933
     IF p_data IS NULL THEN
	   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
    	  p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
	   ELSE
    	  p_data := now();
	   END IF;
	END IF;*/

	-- 22.07.2019 Sofia siac-6973
    p_data := now();

	select fnc_siac_random_user() into	v_user_table;

	params := p_ente_proprietario_id::varchar||' - '||p_anno_bilancio||' - '||p_data::varchar;


	insert into	siac_dwh_log_elaborazioni
    (
		ente_proprietario_id,
		fnc_name ,
		fnc_parameters ,
		fnc_elaborazione_inizio ,
		fnc_user
	)
	values
    (
		p_ente_proprietario_id,
		'fnc_siac_dwh_programma_cronop',
		params,
		clock_timestamp(),
		v_user_table
	);


	esito:= 'fnc_siac_dwh_programma_cronop : continue - inizio eliminazione dati pregressi (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	return next;
	DELETE FROM siac_dwh_programma_cronop
    WHERE ente_proprietario_id = p_ente_proprietario_id;
--    and   programma_cronop_bil_anno=p_anno_bilancio; -- 20.06.2019 SIAC-6933
	esito:= 'fnc_siac_dwh_programma_cronop : continue - fine eliminazione dati pregressi (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	return next;

	esito:= 'fnc_siac_dwh_programma_cronop : continue - inizio caricamento programmi-cronop (siac_dwh_programma_cronop) - '||clock_timestamp()||'.';
	RETURN NEXT;

    insert into siac_dwh_programma_cronop
    (
      ente_proprietario_id,
      ente_denominazione,
      programma_code,
      programma_desc,
      programma_stato_code,
      programma_stato_desc,
      programma_ambito_code,
      programma_ambito_desc,
      programma_rilevante_fpv,
      programma_valore_complessivo,
      programma_gara_data_indizione,
      programma_gara_data_aggiudic,
      programma_investimento_in_def,
      programma_note,
      programma_anno_atto_amm,
      programma_num_atto_amm,
      programma_oggetto_atto_amm,
      programma_note_atto_amm,
      programma_code_tipo_atto_amm,
      programma_desc_tipo_atto_amm,
      programma_code_stato_atto_amm,
      programma_desc_stato_atto_amm,
      programma_code_cdr_atto_amm,
      programma_desc_cdr_atto_amm,
      programma_code_cdc_atto_amm,
      programma_desc_cdc_atto_amm,
      programma_cronop_bil_anno,
      programma_cronop_tipo,
      programma_cronop_versione,
      programma_cronop_desc,
      programma_cronop_anno_comp,
      programma_cronop_cap_tipo,
      programma_cronop_cap_articolo,
      programma_cronop_classif_bil,
      programma_cronop_anno_entrata,
      programma_cronop_valore_prev,
      -- 29.04.2019 Sofia jira siac-6255
      -- siac_t_programma
      programma_responsabile_unico,
      programma_spazi_finanziari,
      programma_tipo_code,
      programma_tipo_desc,
      programma_affidamento_code,
      programma_affidamento_desc,
      programma_anno_bilancio,
      -- 20.06.2019 Sofia siac-6933
      programma_sac_tipo,
      programma_sac_code,
      programma_sac_desc,
      programma_cup,
      -- 29.04.2019 Sofia siac-6255
      -- siac_t_cronop
      programma_cronop_data_appfat,
      programma_cronop_data_appdef,
      programma_cronop_data_appesec,
      programma_cronop_data_avviopr,
      programma_cronop_data_agglav,
      programma_cronop_data_inizlav,
      programma_cronop_data_finelav,
      programma_cronop_giorni_dur,
      programma_cronop_data_coll,
      programma_cronop_gest_quad_eco,
      programma_cronop_us_per_fpv_pr,
      programma_cronop_ann_atto_amm,
      programma_cronop_num_atto_amm,
      programma_cronop_ogg_atto_amm,
      programma_cronop_nte_atto_amm,
      programma_cronop_tpc_atto_amm,
      programma_cronop_tpd_atto_amm,
      programma_cronop_stc_atto_amm,
      programma_cronop_std_atto_amm,
      programma_cronop_crc_atto_amm,
      programma_cronop_crd_atto_amm,
      programma_cronop_cdc_atto_amm,
      programma_cronop_cdd_atto_amm,
      -- 20.06.2019 Sofia siac-6933
      entrata_prevista_cronop_entrata,
      programma_cronop_descr_spesa,
      programma_cronop_descr_entrata,
      -- siac-7320 sofia 17.01.2020
      programma_cronop_stato_code,
      programma_cronop_stato_desc,
      -- siac-8603 Sofia 26.05.2022
      programma_cronop_note
    )
    select
      ente.ente_proprietario_id,
      ente.ente_denominazione,
      query.programma_code,
      query.programma_desc,
      query.programma_stato_code,
      query.programma_stato_desc,
      query.programma_ambito_code,
      query.programma_ambito_desc,
      query.programma_rilevante_fpv,
      query.programma_valore_complessivo,
      query.programma_gara_data_indizione,
      query.programma_gara_data_aggiudic,
      query.programma_investimento_in_def,
      query.programma_note,
      query.programma_anno_atto_amm,
      query.programma_num_atto_amm,
      query.programma_oggetto_atto_amm,
      query.programma_note_atto_amm,
      query.programma_code_tipo_atto_amm,
      query.programma_desc_tipo_atto_amm,
      query.programma_code_stato_atto_amm,
      query.programma_desc_stato_atto_amm,
      query.programma_code_cdr_atto_amm,
      query.programma_desc_cdr_atto_amm,
      query.programma_code_cdc_atto_amm,
      query.programma_desc_cdc_atto_amm,
      query.programma_cronop_bil_anno,
      query.programma_cronop_tipo,
      query.programma_cronop_versione,
      query.programma_cronop_desc,
      query.programma_cronop_anno_comp,
      query.programma_cronop_cap_tipo,
      query.programma_cronop_cap_articolo,
      query.programma_cronop_classif_bil,
      query.programma_cronop_anno_entrata,
      query.programma_cronop_valore_prev,
      -- 29.04.2019 Sofia jira siac-6255
      -- siac_t_programma
      query.programma_responsabile_unico,
      query.programma_spazi_finanziari,
      query.programma_tipo_code,
      query.programma_tipo_desc,
      query.programma_affidamento_code,
      query.programma_affidamento_desc,
      query.programma_anno_bilancio,
      -- 20.06.2019 Sofia siac-6933
      query.programma_sac_tipo,
      query.programma_sac_code,
      query.programma_sac_desc,
      query.programma_cup,
      -- 29.04.2019 Sofia siac-6255
      -- siac_t_cronop
      query.cronop_data_approvazione_fattibilita,
      query.cronop_data_approvazione_programma_def,
      query.cronop_data_approvazione_programma_esec,
      query.cronop_data_avvio_procedura,
      query.cronop_data_aggiudicazione_lavori,
      query.cronop_data_inizio_lavori,
      query.cronop_data_fine_lavori,
      query.cronop_giorni_durata,
      query.cronop_data_collaudo,
      query.cronop_gestione_quadro_economico,
      query.cronop_usato_per_fpv_prov,
      query.cronop_anno_atto_amm,
      query.cronop_num_atto_amm,
      query.cronop_oggetto_atto_amm,
      query.cronop_note_atto_amm,
      query.cronop_code_tipo_atto_amm,
      query.cronop_desc_tipo_atto_amm,
      query.cronop_code_stato_atto_amm,
      query.cronop_desc_stato_atto_amm,
      query.cronop_code_cdr_atto_amm,
      query.cronop_desc_cdr_atto_amm,
      query.cronop_code_cdc_atto_amm,
      query.cronop_desc_cdc_atto_amm,
      -- 20.06.2019 Sofia siac-6933
      ''::varchar entrata_prevista_cronop_entrata,
--      (case when query.programma_cronop_tipo='U' then query.programma_cronop_desc -- 24.07.2019 Sofia SIAC-6979
      (case when query.programma_cronop_tipo='U' then query.programma_cronop_cap_desc  -- 24.07.2019 Sofia SIAC-6979
        else ''::varchar end) programma_cronop_descr_spesa,
--      (case when query.programma_cronop_tipo='E' then query.programma_cronop_desc  -- 24.07.2019 Sofia SIAC-6979
      (case when query.programma_cronop_tipo='E' then query.programma_cronop_cap_desc   -- 24.07.2019 Sofia SIAC-6979
        else ''::varchar end) programma_cronop_descr_entrata,
      -- siac-7320 sofia 17.01.2020
      query.programma_cronop_stato_code,
      query.programma_cronop_stato_desc,
      -- siac-8603 Sofia 26.05.2022
      query.programma_cronop_note
    from
    (
    with
    programma as
    (
      select progr.ente_proprietario_id,
             progr.programma_id,
             progr.programma_code,
             progr.programma_desc,
             stato.programma_stato_code,
             stato.programma_stato_desc,
             progr.programma_data_gara_indizione programma_gara_data_indizione,
		     progr.programma_data_gara_aggiudicazione programma_gara_data_aggiudic,
		     progr.investimento_in_definizione programma_investimento_in_def,
             -- 29.04.2019 Sofia siac-6255
             progr.programma_responsabile_unico,
             progr.programma_spazi_finanziari,
             progr.programma_affidamento_id,
             progr.bil_id,
             tipo.programma_tipo_code,
             tipo.programma_tipo_desc
      from siac_t_programma progr, siac_r_programma_stato rs, siac_d_programma_stato stato,
           siac_d_programma_tipo tipo              -- 29.04.2019 Sofia siac-6255
      where stato.ente_proprietario_id=p_ente_proprietario_id
      and   rs.programma_stato_id=stato.programma_stato_id
      and   progr.programma_id=rs.programma_id
      -- 29.04.2019 Sofia siac-6255
      and   tipo.programma_tipo_id=progr.programma_tipo_id
      and   p_data BETWEEN progr.validita_inizio AND COALESCE(progr.validita_fine, p_data)
      and   progr.data_cancellazione is null
      AND   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
      and   rs.data_cancellazione  is null
    ),
    progr_ambito_class as
    (
    select rc.programma_id,
           c.classif_code programma_ambito_code,
           c.classif_desc  programma_ambito_desc
    from siac_r_programma_class rc, siac_t_class c, siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.classif_tipo_code='TIPO_AMBITO'
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
    and   rc.data_cancellazione is null
    and   c.data_cancellazione is null
    ),
    -- 20.06.2019 Sofia siac-6933 - inizio
    progr_sac as
    (
    select rc.programma_id,
           tipo.classif_tipo_code programma_sac_tipo,
           c.classif_code programma_sac_code,
           c.classif_desc  programma_sac_desc
    from siac_r_programma_class rc, siac_t_class c, siac_d_class_tipo tipo
    where tipo.ente_proprietario_id=p_ente_proprietario_id
    and   tipo.classif_tipo_code in ('CDC','CDR')
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
    and   rc.data_cancellazione is null
    and   c.data_cancellazione is null
    ),
    progr_cup as
    (
    select rattr.programma_id,
           rattr.testo programma_cup
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='cup'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    -- 20.06.2019 Sofia siac-6933 - fine
    progr_note_attr_ril_fpv as
    (
    select rattr.programma_id,
           rattr.boolean programma_rilevante_fpv
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='FlagRilevanteFPV'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_note_attr_note as
    (
    select rattr.programma_id,
           rattr.boolean programma_note
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='Note'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_note_attr_val_compl as
    (
    select rattr.programma_id,
           rattr.numerico programma_valore_complessivo
    from siac_r_programma_attr rattr,siac_t_attr attr
    where attr.ente_proprietario_id=p_ente_proprietario_id
    and   attr.attr_code='ValoreComplessivoProgramma'
    and   rattr.attr_id=attr.attr_id
    and   p_data BETWEEN rattr.validita_inizio AND COALESCE(rattr.validita_fine, p_data)
    and   rattr.data_cancellazione is null
    ),
    progr_atto_amm as
    (
     with
     progr_atto as
     (
      select ratto.programma_id,
             ratto.attoamm_id,
             atto.attoamm_anno        programma_anno_atto_amm,
             atto.attoamm_numero      programma_num_atto_amm,
             atto.attoamm_oggetto     programma_oggetto_atto_amm,
             atto.attoamm_note        programma_note_atto_amm,
             tipo.attoamm_tipo_code   programma_code_tipo_atto_amm,
             tipo.attoamm_tipo_desc   programma_desc_tipo_atto_amm,
             stato.attoamm_stato_code programma_code_stato_atto_amm,
             stato.attoamm_stato_desc programma_desc_stato_atto_amm
      from siac_r_programma_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
           siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
      where ratto.ente_proprietario_id=p_ente_proprietario_id
      and   atto.attoamm_id=ratto.attoamm_id
      and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
      and   rs.attoamm_id=atto.attoamm_id
      and   stato.attoamm_stato_id=rs.attoamm_stato_id
      and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
      and   ratto.data_cancellazione is null
      and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
      and   atto.data_cancellazione is null
      and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
      and   rs.data_cancellazione is null
     ),
     atto_cdr as
     (
     select rc.attoamm_id,
            c.classif_code programma_code_cdr_atto_amm,
            c.classif_desc programma_desc_cdr_atto_amm
     from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=p_ente_proprietario_id
     and   tipo.classif_tipo_code='CDR'
     and   c.classif_tipo_id=tipo.classif_tipo_id
     and   rc.classif_id=c.classif_id
     and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
     and   rc.data_cancellazione is null
     and   c.data_cancellazione is null
     ),
     atto_cdc as
     (
     select rc.attoamm_id,
            c.classif_code programma_code_cdc_atto_amm,
            c.classif_desc programma_desc_cdc_atto_amm
     from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=p_ente_proprietario_id
     and   tipo.classif_tipo_code='CDC'
     and   c.classif_tipo_id=tipo.classif_tipo_id
     and   rc.classif_id=c.classif_id
     and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
     and   rc.data_cancellazione is null
     and   c.data_cancellazione is null
     )
     select progr_atto.*,
            atto_cdr.programma_code_cdr_atto_amm,
            atto_cdr.programma_desc_cdr_atto_amm,
            atto_cdc.programma_code_cdc_atto_amm,
            atto_cdc.programma_desc_cdc_atto_amm
     from progr_atto
           left join atto_cdr on (progr_atto.attoamm_id=atto_cdr.attoamm_id)
           left join atto_cdc on (progr_atto.attoamm_id=atto_cdc.attoamm_id)
    ),
    -- 29.04.2019 Sofia siac-6255
    progr_affid as
    (
     select aff.programma_affidamento_code,
            aff.programma_affidamento_desc,
            aff.programma_affidamento_id
     from  siac_d_programma_affidamento aff
     where aff.ente_proprietario_id=p_ente_proprietario_id
    ),
    progr_bil_anno as
    (
    select bil.bil_id, per.anno anno_bilancio
    from siac_t_bil bil,siac_t_periodo per
    where bil.ente_proprietario_id=p_ente_proprietario_id
    and   per.periodo_id=bil.periodo_id
    ),
    cronop_progr as
    (
    with
     cronop_entrata as
     (
       with
         ce as
         (
           select cronop.programma_id,
                  per_bil.anno::varchar programma_cronop_bil_anno,
                  'E'::varchar programma_cronop_tipo,
                  cronop.cronop_code programma_cronop_versione,
                  cronop.cronop_desc programma_cronop_desc,
                  -- 29.04.2019 Sofia jira siac-6255
                  cronop.cronop_id,
                  cronop.cronop_data_approvazione_fattibilita,
                  cronop.cronop_data_approvazione_programma_def,
                  cronop.cronop_data_approvazione_programma_esec,
                  cronop.cronop_data_avvio_procedura,
                  cronop.cronop_data_aggiudicazione_lavori,
                  cronop.cronop_data_inizio_lavori,
                  cronop.cronop_data_fine_lavori,
                  cronop.cronop_giorni_durata,
                  cronop.cronop_data_collaudo,
                  cronop.gestione_quadro_economico,
                  cronop.usato_per_fpv_prov,
                  -- 29.04.2019 Sofia jira siac-6255
                  per.anno::varchar  programma_cronop_anno_comp,
                  tipo.elem_tipo_code programma_cronop_cap_tipo,
                  cronop_elem.cronop_elem_code||'/'||cronop_elem.cronop_elem_code2 programma_cronop_cap_articolo,
                  cronop_elem.cronop_elem_desc programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
                  ''::varchar programma_cronop_anno_entrata,
                  cronop_elem_det.cronop_elem_det_importo programma_cronop_valore_prev,
                  cronop_elem.cronop_elem_id,
                  stato.cronop_stato_code programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
                  stato.cronop_stato_desc  programma_cronop_stato_desc  -- 14.01.2020 Sofia SIAC-7320
           from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
                siac_t_bil bil, siac_t_periodo per_bil,
                siac_t_periodo per,
                siac_t_cronop_elem cronop_elem,
                siac_d_bil_elem_tipo tipo,
                siac_t_cronop_elem_det cronop_elem_det
           where stato.ente_proprietario_id=p_ente_proprietario_id
--           and   stato.cronop_stato_code='VA' 14.01.2020 Sofia jira siac-7320
           and   rs.cronop_stato_id=stato.cronop_stato_id
           and   cronop.cronop_id=rs.cronop_id
           and   bil.bil_id=cronop.bil_id
           and   per_bil.periodo_id=bil.periodo_id
--           and   per_bil.anno::integer=p_anno_bilancio::integer
--           and   per_bil.anno::integer<=p_anno_bilancio::integer           --- 20.06.2019 Sofia siac-6933
           and   cronop_elem.cronop_id=cronop.cronop_id
           and   tipo.elem_tipo_id=cronop_elem.elem_tipo_id
           and   tipo.elem_tipo_code in ('CAP-EP','CAP-EG')
           and   cronop_elem_det.cronop_elem_id=cronop_elem.cronop_elem_id
           and   per.periodo_id=cronop_elem_det.periodo_id
           and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
           and   rs.data_cancellazione is null
           and   p_data BETWEEN cronop.validita_inizio AND COALESCE(cronop.validita_fine, p_data)
           and   cronop.data_cancellazione is null
           and   p_data BETWEEN cronop_elem.validita_inizio AND COALESCE(cronop_elem.validita_fine, p_data)
           and   cronop_elem.data_cancellazione is null
           and   p_data BETWEEN cronop_elem_det.validita_inizio AND COALESCE(cronop_elem_det.validita_fine, p_data)
           and   cronop_elem_det.data_cancellazione is null
         ),
         classif_bil as
         (
            select distinct
                   r_cronp_class.cronop_elem_id,
		           titolo.classif_code            				titolo_code ,
	               titolo.classif_desc            				titolo_desc,
	               tipologia.classif_code           			tipologia_code,
	               tipologia.classif_desc           			tipologia_desc
            from siac_t_class_fam_tree 			titolo_tree,
            	 siac_d_class_fam 				titolo_fam,
	             siac_r_class_fam_tree 			titolo_r_cft,
	             siac_t_class 					titolo,
	             siac_d_class_tipo 				titolo_tipo,
	             siac_d_class_tipo 				tipologia_tipo,
     	         siac_t_class 					tipologia,
	             siac_r_cronop_elem_class		r_cronp_class
            where 	titolo_fam.classif_fam_desc					=	'Entrata - TitoliTipologieCategorie'
            and 	titolo_tree.classif_fam_id					=	titolo_fam.classif_fam_id
            and 	titolo_r_cft.classif_fam_tree_id			=	titolo_tree.classif_fam_tree_id
            and 	titolo.classif_id							=	titolo_r_cft.classif_id_padre
            and 	titolo_tipo.classif_tipo_code				=	'TITOLO_ENTRATA'
            and 	titolo.classif_tipo_id						=	titolo_tipo.classif_tipo_id
            and 	tipologia_tipo.classif_tipo_code			=	'TIPOLOGIA'
            and 	tipologia.classif_tipo_id					=	tipologia_tipo.classif_tipo_id
            and 	titolo_r_cft.classif_id						=	tipologia.classif_id
            and 	r_cronp_class.classif_id					=	tipologia.classif_id
            and 	titolo.ente_proprietario_id					=	p_ente_proprietario_id
            and 	titolo.data_cancellazione					is null
            and 	tipologia.data_cancellazione				is null
            and		r_cronp_class.data_cancellazione			is null
            and 	titolo_tree.data_cancellazione				is null
            and 	titolo_fam.data_cancellazione				is null
            and 	titolo_r_cft.data_cancellazione				is null
            and 	titolo_tipo.data_cancellazione				is null
            and 	tipologia_tipo.data_cancellazione			is null
          ),
          -- 29.04.2019 Sofia jira siac-6255
          cronop_atto_amm as
          (
           with
           cronop_atto as
           (
            select ratto.cronop_id,
                   ratto.attoamm_id,
                   atto.attoamm_anno        cronop_anno_atto_amm,
                   atto.attoamm_numero      cronop_num_atto_amm,
                   atto.attoamm_oggetto     cronop_oggetto_atto_amm,
                   atto.attoamm_note        cronop_note_atto_amm,
                   tipo.attoamm_tipo_code   cronop_code_tipo_atto_amm,
                   tipo.attoamm_tipo_desc   cronop_desc_tipo_atto_amm,
                   stato.attoamm_stato_code cronop_code_stato_atto_amm,
                   stato.attoamm_stato_desc cronop_desc_stato_atto_amm
            from siac_r_cronop_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
                 siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
            where ratto.ente_proprietario_id=p_ente_proprietario_id
            and   atto.attoamm_id=ratto.attoamm_id
            and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
            and   rs.attoamm_id=atto.attoamm_id
            and   stato.attoamm_stato_id=rs.attoamm_stato_id
            and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
            and   ratto.data_cancellazione is null
            and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
            and   atto.data_cancellazione is null
            and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
            and   rs.data_cancellazione is null
           ),
           cronop_atto_cdr as
           (
           select rc.attoamm_id,
                  c.classif_code cronop_code_cdr_atto_amm,
                  c.classif_desc cronop_desc_cdr_atto_amm
           from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
           where tipo.ente_proprietario_id=p_ente_proprietario_id
           and   tipo.classif_tipo_code='CDR'
           and   c.classif_tipo_id=tipo.classif_tipo_id
           and   rc.classif_id=c.classif_id
           and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
           and   rc.data_cancellazione is null
           and   c.data_cancellazione is null
           ),
           cronop_atto_cdc as
           (
           select rc.attoamm_id,
                  c.classif_code cronop_code_cdc_atto_amm,
                  c.classif_desc cronop_desc_cdc_atto_amm
           from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
           where tipo.ente_proprietario_id=p_ente_proprietario_id
           and   tipo.classif_tipo_code='CDC'
           and   c.classif_tipo_id=tipo.classif_tipo_id
           and   rc.classif_id=c.classif_id
           and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
           and   rc.data_cancellazione is null
           and   c.data_cancellazione is null
           )
           select cronop_atto.*,
                  cronop_atto_cdr.cronop_code_cdr_atto_amm,
                  cronop_atto_cdr.cronop_desc_cdr_atto_amm,
                  cronop_atto_cdc.cronop_code_cdc_atto_amm,
                  cronop_atto_cdc.cronop_desc_cdc_atto_amm
           from cronop_atto
                 left join cronop_atto_cdr on (cronop_atto.attoamm_id=cronop_atto_cdr.attoamm_id)
                 left join cronop_atto_cdc on (cronop_atto.attoamm_id=cronop_atto_cdc.attoamm_id)
          ),
          -- siac-8603 Sofia 26.05.2022
          cronop_note_attr AS 
          (
          select rattr.cronop_id, rattr.testo programma_cronop_note
          from siac_r_cronop_attr rattr,siac_t_attr attr 
          where attr.ente_proprietario_id =p_ente_proprietario_id 
          and   attr.attr_code='Note'
          and   rattr.attr_id=attr.attr_id 
          and   coalesce(rattr.testo ,'')!=''
          and   rattr.data_cancellazione  is null 
          and   rattr.validita_fine  is null 
	      ) 
          select ce.programma_id,
                 ce.programma_cronop_bil_anno,
                 ce.programma_cronop_tipo,
                 ce.programma_cronop_versione,
                 ce.programma_cronop_desc,
                 ce.programma_cronop_anno_comp,
                 ce.programma_cronop_cap_tipo,
                 ce.programma_cronop_cap_articolo,
                 ce.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
                 (coalesce(classif_bil.titolo_code,' ') ||' - ' ||coalesce(classif_bil.tipologia_code,' '))::varchar programma_cronop_classif_bil,
                 ce.programma_cronop_anno_entrata,
                 ce.programma_cronop_valore_prev,
                 -- 29.04.2019 Sofia jira siac-6255
                 ce.cronop_id,
                 ce.cronop_data_approvazione_fattibilita,
                 ce.cronop_data_approvazione_programma_def,
                 ce.cronop_data_approvazione_programma_esec,
                 ce.cronop_data_avvio_procedura,
                 ce.cronop_data_aggiudicazione_lavori,
                 ce.cronop_data_inizio_lavori,
                 ce.cronop_data_fine_lavori,
                 ce.cronop_giorni_durata,
                 ce.cronop_data_collaudo,
                 ce.gestione_quadro_economico cronop_gestione_quadro_economico,
                 ce.usato_per_fpv_prov cronop_usato_per_fpv_prov,
                 cronop_atto_amm.cronop_anno_atto_amm,
		         cronop_atto_amm.cronop_num_atto_amm,
                 cronop_atto_amm.cronop_oggetto_atto_amm,
                 cronop_atto_amm.cronop_note_atto_amm,
                 cronop_atto_amm.cronop_code_tipo_atto_amm,
                 cronop_atto_amm.cronop_desc_tipo_atto_amm,
                 cronop_atto_amm.cronop_code_stato_atto_amm,
                 cronop_atto_amm.cronop_desc_stato_atto_amm,
                 cronop_atto_amm.cronop_code_cdr_atto_amm,
                 cronop_atto_amm.cronop_desc_cdr_atto_amm,
                 cronop_atto_amm.cronop_code_cdc_atto_amm,
                 cronop_atto_amm.cronop_desc_cdc_atto_amm,
                 ce.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
                 ce.programma_cronop_stato_desc,  -- 14.01.2020 Sofia SIAC-7320,
                 -- 26.05.2022 Sofia Jira SIAC-8603
                 cronop_note_attr.programma_cronop_note
          from ce
               left join classif_bil on (ce.cronop_elem_id=classif_bil.cronop_elem_id)
               -- 29.04.2019 Sofia jira siac-6255
               left join cronop_atto_amm  on (ce.cronop_id=cronop_atto_amm.cronop_id)
               -- 26.05.2022 Sofia SIAC-8603
               left join cronop_note_attr on (ce.cronop_id=cronop_note_attr.cronop_id)

     ),
     cronop_uscita as
     (
     with
     ce as
     (
       select cronop.programma_id,
              per_bil.anno::varchar programma_cronop_bil_anno,
              'U'::varchar programma_cronop_tipo,
              cronop.cronop_code programma_cronop_versione,
              cronop.cronop_desc programma_cronop_desc,
              -- 29.04.2019 Sofia jira siac-6255
              cronop.cronop_id,
              cronop.cronop_data_approvazione_fattibilita,
              cronop.cronop_data_approvazione_programma_def,
              cronop.cronop_data_approvazione_programma_esec,
              cronop.cronop_data_avvio_procedura,
              cronop.cronop_data_aggiudicazione_lavori,
              cronop.cronop_data_inizio_lavori,
              cronop.cronop_data_fine_lavori,
              cronop.cronop_giorni_durata,
              cronop.cronop_data_collaudo,
              cronop.gestione_quadro_economico,
              cronop.usato_per_fpv_prov,
              -- 29.04.2019 Sofia jira siac-6255
              per.anno::varchar  programma_cronop_anno_comp,
              tipo.elem_tipo_code programma_cronop_cap_tipo,
              cronop_elem.cronop_elem_code||'/'||cronop_elem.cronop_elem_code2 programma_cronop_cap_articolo,
              cronop_elem.cronop_elem_desc programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
              cronop_elem_det.anno_entrata::varchar programma_cronop_anno_entrata,
              cronop_elem_det.cronop_elem_det_importo programma_cronop_valore_prev,
              cronop_elem.cronop_elem_id,
              stato.cronop_stato_code programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
              stato.cronop_stato_desc  programma_cronop_stato_desc  -- 14.01.2020 Sofia SIAC-7320
       from siac_t_cronop cronop,siac_r_cronop_stato rs, siac_d_cronop_stato stato,
            siac_t_bil bil, siac_t_periodo per_bil,
            siac_t_periodo per,
            siac_t_cronop_elem cronop_elem,
            siac_d_bil_elem_tipo tipo,
            siac_t_cronop_elem_det cronop_elem_det
       where stato.ente_proprietario_id=p_ente_proprietario_id
--       and   stato.cronop_stato_code='VA'  14.01.2020 Sofia jira siac-7320
       and   rs.cronop_stato_id=stato.cronop_stato_id
       and   cronop.cronop_id=rs.cronop_id
       and   bil.bil_id=cronop.bil_id
       and   per_bil.periodo_id=bil.periodo_id
 --      and   per_bil.anno::integer=p_anno_bilancio::integer
 --      and   per_bil.anno::integer<=p_anno_bilancio::integer           --- 20.06.2019 Sofia siac-6933

       and   cronop_elem.cronop_id=cronop.cronop_id
       and   tipo.elem_tipo_id=cronop_elem.elem_tipo_id
       and   tipo.elem_tipo_code in ('CAP-UP','CAP-UG')
       and   cronop_elem_det.cronop_elem_id=cronop_elem.cronop_elem_id
       and   per.periodo_id=cronop_elem_det.periodo_id
       and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
       and   rs.data_cancellazione is null
       and   p_data BETWEEN cronop.validita_inizio AND COALESCE(cronop.validita_fine, p_data)
       and   cronop.data_cancellazione is null
       and   p_data BETWEEN cronop_elem.validita_inizio AND COALESCE(cronop_elem.validita_fine, p_data)
       and   cronop_elem.data_cancellazione is null
       and   p_data BETWEEN cronop_elem_det.validita_inizio AND COALESCE(cronop_elem_det.validita_fine, p_data)
       and   cronop_elem_det.data_cancellazione is null
     ),
     classif_bil as
     (
        select  distinct
        		r_cronp_class_titolo.cronop_elem_id,
		        missione.classif_code 					missione_code,
		        missione.classif_desc 					missione_desc,
		        programma.classif_code 					programma_code,
		        programma.classif_desc 					programma_desc,
		        titusc.classif_code 					titolo_code,
		        titusc.classif_desc 					titolo_desc
        from siac_t_class_fam_tree 			missione_tree,
             siac_d_class_fam 				missione_fam,
	         siac_r_class_fam_tree 			missione_r_cft,
	         siac_t_class 					missione,
	         siac_d_class_tipo 				missione_tipo ,
     	     siac_d_class_tipo 				programma_tipo,
	         siac_t_class 					programma,
      	     siac_t_class_fam_tree 			titusc_tree,
	         siac_d_class_fam 				titusc_fam,
	         siac_r_class_fam_tree 			titusc_r_cft,
	         siac_t_class 					titusc,
	         siac_d_class_tipo 				titusc_tipo,
	         siac_r_cronop_elem_class		r_cronp_class_programma,
	         siac_r_cronop_elem_class		r_cronp_class_titolo
        where missione_fam.classif_fam_desc						=	'Spesa - MissioniProgrammi'
        and	  missione_tree.classif_fam_id				=	missione_fam.classif_fam_id
        and	  missione_r_cft.classif_fam_tree_id			=	missione_tree.classif_fam_tree_id
        and	  missione.classif_id							=	missione_r_cft.classif_id_padre
        and	  missione_tipo.classif_tipo_code				=	'MISSIONE'
        and	  missione.classif_tipo_id					=	missione_tipo.classif_tipo_id
        and	  programma_tipo.classif_tipo_code			=	'PROGRAMMA'
        and	  programma.classif_tipo_id					=	programma_tipo.classif_tipo_id
        and	  missione_r_cft.classif_id					=	programma.classif_id
        and	  programma.classif_id						=	r_cronp_class_programma.classif_id
        and	  titusc_fam.classif_fam_desc					=	'Spesa - TitoliMacroaggregati'
        and	  titusc_tree.classif_fam_id					=	titusc_fam.classif_fam_id
        and	  titusc_r_cft.classif_fam_tree_id			=	titusc_tree.classif_fam_tree_id
        and	  titusc.classif_id							=	titusc_r_cft.classif_id_padre
        and	  titusc_tipo.classif_tipo_code				=	'TITOLO_SPESA'
        and	  titusc.classif_tipo_id						=	titusc_tipo.classif_tipo_id
        and	  titusc.classif_id							=	r_cronp_class_titolo.classif_id
        and   r_cronp_class_programma.cronop_elem_id		= 	r_cronp_class_titolo.cronop_elem_id
        and   missione_tree.ente_proprietario_id			=	p_ente_proprietario_id
        and   missione_tree.data_cancellazione			is null
        and   missione_fam.data_cancellazione			is null
        AND   missione_r_cft.data_cancellazione			is null
        and   missione.data_cancellazione				is null
        AND   missione_tipo.data_cancellazione			is null
        AND   programma_tipo.data_cancellazione			is null
        AND   programma.data_cancellazione				is null
        and   titusc_tree.data_cancellazione			is null
        AND   titusc_fam.data_cancellazione				is null
        and   titusc_r_cft.data_cancellazione			is null
        and   titusc.data_cancellazione					is null
        AND   titusc_tipo.data_cancellazione			is null
        and	  r_cronp_class_titolo.data_cancellazione	is null
     ),
     -- 29.04.2019 Sofia jira siac-6255
     cronop_atto_amm as
     (
       with
       cronop_atto as
       (
        select ratto.cronop_id,
               ratto.attoamm_id,
               atto.attoamm_anno        cronop_anno_atto_amm,
               atto.attoamm_numero      cronop_num_atto_amm,
               atto.attoamm_oggetto     cronop_oggetto_atto_amm,
               atto.attoamm_note        cronop_note_atto_amm,
               tipo.attoamm_tipo_code   cronop_code_tipo_atto_amm,
               tipo.attoamm_tipo_desc   cronop_desc_tipo_atto_amm,
               stato.attoamm_stato_code cronop_code_stato_atto_amm,
               stato.attoamm_stato_desc cronop_desc_stato_atto_amm
        from siac_r_cronop_atto_amm ratto , siac_t_atto_amm atto,siac_d_atto_amm_tipo tipo,
             siac_r_atto_amm_stato rs, siac_d_atto_amm_stato stato
        where ratto.ente_proprietario_id=p_ente_proprietario_id
        and   atto.attoamm_id=ratto.attoamm_id
        and   tipo.attoamm_tipo_id=atto.attoamm_tipo_id
        and   rs.attoamm_id=atto.attoamm_id
        and   stato.attoamm_stato_id=rs.attoamm_stato_id
        and   p_data BETWEEN ratto.validita_inizio AND COALESCE(ratto.validita_fine, p_data)
        and   ratto.data_cancellazione is null
        and   p_data BETWEEN atto.validita_inizio AND COALESCE(atto.validita_fine, p_data)
        and   atto.data_cancellazione is null
        and   p_data BETWEEN rs.validita_inizio AND COALESCE(rs.validita_fine, p_data)
        and   rs.data_cancellazione is null
       ),
       cronop_atto_cdr as
       (
       select rc.attoamm_id,
              c.classif_code cronop_code_cdr_atto_amm,
              c.classif_desc cronop_desc_cdr_atto_amm
       from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
       where tipo.ente_proprietario_id=p_ente_proprietario_id
       and   tipo.classif_tipo_code='CDR'
       and   c.classif_tipo_id=tipo.classif_tipo_id
       and   rc.classif_id=c.classif_id
       and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
       and   rc.data_cancellazione is null
       and   c.data_cancellazione is null
       ),
       cronop_atto_cdc as
       (
       select rc.attoamm_id,
              c.classif_code cronop_code_cdc_atto_amm,
              c.classif_desc cronop_desc_cdc_atto_amm
       from siac_r_atto_amm_class rc, siac_t_class c , siac_d_class_tipo tipo
       where tipo.ente_proprietario_id=p_ente_proprietario_id
       and   tipo.classif_tipo_code='CDC'
       and   c.classif_tipo_id=tipo.classif_tipo_id
       and   rc.classif_id=c.classif_id
       and   p_data BETWEEN rc.validita_inizio AND COALESCE(rc.validita_fine, p_data)
       and   rc.data_cancellazione is null
       and   c.data_cancellazione is null
       )
       select cronop_atto.*,
              cronop_atto_cdr.cronop_code_cdr_atto_amm,
              cronop_atto_cdr.cronop_desc_cdr_atto_amm,
              cronop_atto_cdc.cronop_code_cdc_atto_amm,
              cronop_atto_cdc.cronop_desc_cdc_atto_amm
       from cronop_atto
             left join cronop_atto_cdr on (cronop_atto.attoamm_id=cronop_atto_cdr.attoamm_id)
             left join cronop_atto_cdc on (cronop_atto.attoamm_id=cronop_atto_cdc.attoamm_id)
     ),
     -- siac-8603 Sofia 26.05.2022
     cronop_note_attr AS 
     (
          select rattr.cronop_id, rattr.testo programma_cronop_note
          from siac_r_cronop_attr rattr,siac_t_attr attr 
          where attr.ente_proprietario_id =p_ente_proprietario_id 
          and   attr.attr_code='Note'
          and   rattr.attr_id=attr.attr_id 
          and   coalesce(rattr.testo ,'')!=''
          and   rattr.data_cancellazione  is null 
          and   rattr.validita_fine  is null 
	 ) 
     select ce.programma_id,
            ce.programma_cronop_bil_anno,
            ce.programma_cronop_tipo,
            ce.programma_cronop_versione,
            ce.programma_cronop_desc,
            ce.programma_cronop_anno_comp,
            ce.programma_cronop_cap_tipo,
            ce.programma_cronop_cap_articolo,
            ce.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
            (coalesce(classif_bil.missione_code,' ')||
             ' - '||coalesce(classif_bil.programma_code,' ')||
             ' - '||coalesce(classif_bil.titolo_code,' '))::varchar programma_cronop_classif_bil,
            ce.programma_cronop_anno_entrata,
            ce.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            ce.cronop_id,
            ce.cronop_data_approvazione_fattibilita,
            ce.cronop_data_approvazione_programma_def,
            ce.cronop_data_approvazione_programma_esec,
            ce.cronop_data_avvio_procedura,
            ce.cronop_data_aggiudicazione_lavori,
            ce.cronop_data_inizio_lavori,
            ce.cronop_data_fine_lavori,
            ce.cronop_giorni_durata,
            ce.cronop_data_collaudo,
            ce.gestione_quadro_economico cronop_gestione_quadro_economico,
            ce.usato_per_fpv_prov cronop_usato_per_fpv_prov,
            cronop_atto_amm.cronop_anno_atto_amm,
            cronop_atto_amm.cronop_num_atto_amm,
            cronop_atto_amm.cronop_oggetto_atto_amm,
            cronop_atto_amm.cronop_note_atto_amm,
            cronop_atto_amm.cronop_code_tipo_atto_amm,
            cronop_atto_amm.cronop_desc_tipo_atto_amm,
            cronop_atto_amm.cronop_code_stato_atto_amm,
            cronop_atto_amm.cronop_desc_stato_atto_amm,
            cronop_atto_amm.cronop_code_cdr_atto_amm,
            cronop_atto_amm.cronop_desc_cdr_atto_amm,
            cronop_atto_amm.cronop_code_cdc_atto_amm,
            cronop_atto_amm.cronop_desc_cdc_atto_amm,
            ce.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
            ce.programma_cronop_stato_desc, -- 14.01.2020 Sofia SIAC-7320
            -- 26.05.2022 Sofia Jira SIAC-8603
            cronop_note_attr.programma_cronop_note
     from ce
          left join classif_bil on (ce.cronop_elem_id=classif_bil.cronop_elem_id)
          -- 29.04.2019 Sofia jira siac-6255
          left join cronop_atto_amm on ( ce.cronop_id=cronop_atto_amm.cronop_id)
          -- 26.05.2022 Sofia SIAC-8603
          left join cronop_note_attr on (ce.cronop_id=cronop_note_attr.cronop_id)
     )
     select cronop_entrata.programma_id,
     	    cronop_entrata.programma_cronop_bil_anno,
            cronop_entrata.programma_cronop_tipo,
            cronop_entrata.programma_cronop_versione,
            cronop_entrata.programma_cronop_desc,
	        cronop_entrata.programma_cronop_anno_comp,
            cronop_entrata.programma_cronop_cap_tipo,
	        cronop_entrata.programma_cronop_cap_articolo,
            cronop_entrata.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
	        cronop_entrata.programma_cronop_classif_bil,
	        cronop_entrata.programma_cronop_anno_entrata,
            cronop_entrata.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            cronop_entrata.cronop_id,
            cronop_entrata.cronop_data_approvazione_fattibilita,
            cronop_entrata.cronop_data_approvazione_programma_def,
            cronop_entrata.cronop_data_approvazione_programma_esec,
            cronop_entrata.cronop_data_avvio_procedura,
            cronop_entrata.cronop_data_aggiudicazione_lavori,
            cronop_entrata.cronop_data_inizio_lavori,
            cronop_entrata.cronop_data_fine_lavori,
            cronop_entrata.cronop_giorni_durata,
            cronop_entrata.cronop_data_collaudo,
            cronop_entrata.cronop_gestione_quadro_economico,
            cronop_entrata.cronop_usato_per_fpv_prov,
            cronop_entrata.cronop_anno_atto_amm,
            cronop_entrata.cronop_num_atto_amm,
            cronop_entrata.cronop_oggetto_atto_amm,
            cronop_entrata.cronop_note_atto_amm,
            cronop_entrata.cronop_code_tipo_atto_amm,
            cronop_entrata.cronop_desc_tipo_atto_amm,
            cronop_entrata.cronop_code_stato_atto_amm,
            cronop_entrata.cronop_desc_stato_atto_amm,
            cronop_entrata.cronop_code_cdr_atto_amm,
            cronop_entrata.cronop_desc_cdr_atto_amm,
            cronop_entrata.cronop_code_cdc_atto_amm,
            cronop_entrata.cronop_desc_cdc_atto_amm,
            cronop_entrata.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
            cronop_entrata.programma_cronop_stato_desc, -- 14.01.2020 Sofia SIAC-7320
            -- 26.05.2022 Sofia Jira SIAC-8603
            cronop_entrata.programma_cronop_note
     from cronop_entrata
     union
     select cronop_uscita.programma_id,
     	    cronop_uscita.programma_cronop_bil_anno,
            cronop_uscita.programma_cronop_tipo,
            cronop_uscita.programma_cronop_versione,
            cronop_uscita.programma_cronop_desc,
	        cronop_uscita.programma_cronop_anno_comp,
            cronop_uscita.programma_cronop_cap_tipo,
	        cronop_uscita.programma_cronop_cap_articolo,
            cronop_uscita.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
	        cronop_uscita.programma_cronop_classif_bil,
	        cronop_uscita.programma_cronop_anno_entrata,
            cronop_uscita.programma_cronop_valore_prev,
            -- 29.04.2019 Sofia jira siac-6255
            cronop_uscita.cronop_id,
            cronop_uscita.cronop_data_approvazione_fattibilita,
            cronop_uscita.cronop_data_approvazione_programma_def,
            cronop_uscita.cronop_data_approvazione_programma_esec,
            cronop_uscita.cronop_data_avvio_procedura,
            cronop_uscita.cronop_data_aggiudicazione_lavori,
            cronop_uscita.cronop_data_inizio_lavori,
            cronop_uscita.cronop_data_fine_lavori,
            cronop_uscita.cronop_giorni_durata,
            cronop_uscita.cronop_data_collaudo,
            cronop_uscita.cronop_gestione_quadro_economico,
            cronop_uscita.cronop_usato_per_fpv_prov,
            cronop_uscita.cronop_anno_atto_amm,
            cronop_uscita.cronop_num_atto_amm,
            cronop_uscita.cronop_oggetto_atto_amm,
            cronop_uscita.cronop_note_atto_amm,
            cronop_uscita.cronop_code_tipo_atto_amm,
            cronop_uscita.cronop_desc_tipo_atto_amm,
            cronop_uscita.cronop_code_stato_atto_amm,
            cronop_uscita.cronop_desc_stato_atto_amm,
            cronop_uscita.cronop_code_cdr_atto_amm,
            cronop_uscita.cronop_desc_cdr_atto_amm,
            cronop_uscita.cronop_code_cdc_atto_amm,
            cronop_uscita.cronop_desc_cdc_atto_amm,
            cronop_uscita.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
            cronop_uscita.programma_cronop_stato_desc, -- 14.01.2020 Sofia SIAC-7320
            -- 26.05.2022 Sofia Jira SIAC-8603
            cronop_uscita.programma_cronop_note
     from cronop_uscita
    )
    select programma.*,
           progr_ambito_class.programma_ambito_code,
           progr_ambito_class.programma_ambito_desc,
           progr_note_attr_ril_fpv.programma_rilevante_fpv,
           progr_note_attr_note.programma_note,
           progr_note_attr_val_compl.programma_valore_complessivo,
           progr_atto_amm.programma_anno_atto_amm,
           progr_atto_amm.programma_num_atto_amm,
           progr_atto_amm.programma_oggetto_atto_amm,
           progr_atto_amm.programma_note_atto_amm,
           progr_atto_amm.programma_code_tipo_atto_amm,
           progr_atto_amm.programma_desc_tipo_atto_amm,
           progr_atto_amm.programma_code_stato_atto_amm,
           progr_atto_amm.programma_desc_stato_atto_amm,
           progr_atto_amm.programma_code_cdr_atto_amm,
           progr_atto_amm.programma_desc_cdr_atto_amm,
           progr_atto_amm.programma_code_cdc_atto_amm,
           progr_atto_amm.programma_desc_cdc_atto_amm,
           -- 29.04.2019 Sofia siac-6255
           progr_affid.programma_affidamento_code,
           progr_affid.programma_affidamento_desc,
           progr_bil_anno.anno_bilancio programma_anno_bilancio,
           -- 20.06.2019 Sofia siac-6933
           progr_sac.programma_sac_tipo,
           progr_sac.programma_sac_code,
           progr_sac.programma_sac_desc,
           progr_cup.programma_cup,
           -- 29.04.2019 Sofia siac-6255
	       cronop_progr.programma_cronop_bil_anno,
           cronop_progr.programma_cronop_tipo,
           cronop_progr.programma_cronop_versione,
      	   cronop_progr.programma_cronop_desc,
	       cronop_progr.programma_cronop_anno_comp,
	       cronop_progr.programma_cronop_cap_tipo,
	       cronop_progr.programma_cronop_cap_articolo,
	       cronop_progr.programma_cronop_cap_desc, -- 24.07.2019 Sofia SIAC-6979
	       cronop_progr.programma_cronop_classif_bil,
		   cronop_progr.programma_cronop_anno_entrata,
	       cronop_progr.programma_cronop_valore_prev,
           -- 29.04.2019 Sofia siac-6255
           cronop_progr.cronop_data_approvazione_fattibilita,
           cronop_progr.cronop_data_approvazione_programma_def,
           cronop_progr.cronop_data_approvazione_programma_esec,
           cronop_progr.cronop_data_avvio_procedura,
           cronop_progr.cronop_data_aggiudicazione_lavori,
           cronop_progr.cronop_data_inizio_lavori,
           cronop_progr.cronop_data_fine_lavori,
           cronop_progr.cronop_giorni_durata,
           cronop_progr.cronop_data_collaudo,
           cronop_progr.cronop_gestione_quadro_economico,
           cronop_progr.cronop_usato_per_fpv_prov,
           cronop_progr.cronop_anno_atto_amm,
           cronop_progr.cronop_num_atto_amm,
           cronop_progr.cronop_oggetto_atto_amm,
           cronop_progr.cronop_note_atto_amm,
           cronop_progr.cronop_code_tipo_atto_amm,
           cronop_progr.cronop_desc_tipo_atto_amm,
           cronop_progr.cronop_code_stato_atto_amm,
           cronop_progr.cronop_desc_stato_atto_amm,
           cronop_progr.cronop_code_cdr_atto_amm,
           cronop_progr.cronop_desc_cdr_atto_amm,
           cronop_progr.cronop_code_cdc_atto_amm,
           cronop_progr.cronop_desc_cdc_atto_amm,
           cronop_progr.programma_cronop_stato_code, -- 14.01.2020 Sofia SIAC-7320
           cronop_progr.programma_cronop_stato_desc, -- 14.01.2020 Sofia SIAC-7320
           -- 26.05.2022 Sofia Jira SIAC-8603
           cronop_progr.programma_cronop_note
    from cronop_progr,
         programma
          left join progr_ambito_class           on (programma.programma_id=progr_ambito_class.programma_id)
          left join progr_note_attr_ril_fpv      on (programma.programma_id=progr_note_attr_ril_fpv.programma_id)
          left join progr_note_attr_note         on (programma.programma_id=progr_note_attr_note.programma_id)
          left join progr_note_attr_val_compl    on (programma.programma_id=progr_note_attr_val_compl.programma_id)
          left join progr_atto_amm               on (programma.programma_id=progr_atto_amm.programma_id)
          -- 20.06.2019 Sofia siac-6933
          left join progr_sac					 on (programma.programma_id=progr_sac.programma_id)
          left join progr_cup					 on (programma.programma_id=progr_cup.programma_id)
          -- 29.04.2019 Sofia jira siac-6255
          left join  progr_affid                 on (programma.programma_affidamento_id=progr_affid.programma_affidamento_id)
          left  join  progr_bil_anno              on (programma.bil_id=progr_bil_anno.bil_id)
    where programma.programma_id=cronop_progr.programma_id
    ) query,siac_t_ente_proprietario ente
    where ente.ente_proprietario_id=p_ente_proprietario_id
    and   query.ente_proprietario_id=ente.ente_proprietario_id;


	esito:= 'fnc_siac_dwh_programma_cronop : continue - aggiornamento durata su  siac_dwh_log_elaborazioni - '||clock_timestamp()||'.';
	update siac_dwh_log_elaborazioni
    set    fnc_elaborazione_fine = clock_timestamp(),
	       fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
	where  fnc_user=v_user_table;
	return next;

    esito:= 'fnc_siac_dwh_programma_cronop : fine - esito OK  - '||clock_timestamp()||'.';
    return next;
else
	esito:= 'fnc_siac_dwh_programma_cronop : fine - eseguita da meno di '|| interval_esec::varchar||' ore - '||clock_timestamp()||'.';

	return next;

end if;

return;

EXCEPTION
 WHEN RAISE_EXCEPTION THEN
  esito:='fnc_siac_dwh_programma_cronop : fine con errori - '||clock_timestamp();
  esito:=esito||' - '||SQLSTATE||'-'||substring(upper(SQLERRM) from 1 for 2500)||'.';
  RAISE NOTICE '%',esito;
  RETURN next;
  return;
 WHEN others THEN
  esito:='fnc_siac_dwh_programma_cronop : fine con errori - '||clock_timestamp();
  esito:=esito||' - '||SQLSTATE||'-'||substring(upper(SQLERRM) from 1 for 2500)||'.';
  RAISE NOTICE '%',esito;
  RETURN next;
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

ALTER FUNCTION siac.fnc_siac_dwh_programma_cronop(integer,varchar,timestamp) OWNER TO siac;
