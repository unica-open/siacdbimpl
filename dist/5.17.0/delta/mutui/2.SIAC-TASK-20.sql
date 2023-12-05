/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-TASK-20  Sofia 16.05.2023 inizio 

drop view if exists siac.siac_v_dwh_mutuo;
create or replace view siac.siac_v_dwh_mutuo
(
    ente_proprietario_id,
    mutuo_numero,
    mutuo_oggetto,
	mutuo_stato_code,
	mutuo_stato_desc,
	mutuo_tipo_tasso_code,
	mutuo_tipo_tasso_desc,
	mutuo_data_atto,
	mutuo_soggetto_id,
	mutuo_soggetto_code,
	mutuo_soggetto_desc,
	mutuo_soggetto_codice_fiscale,
	mutuo_soggetto_partiva,
	mutuo_somma_iniziale,
	mutuo_somma_effettiva,
	mutuo_tasso,	
	mutuo_tasso_euribor,	
	mutuo_tasso_spread,	
	mutuo_durata_anni,	
	mutuo_anno_inizio,	
	mutuo_anno_fine,	
	mutuo_periodo_rimborso_code,
	mutuo_periodo_rimborso_desc,
	mutuo_periodo_rimborso_mesi,
	mutuo_data_scadenza_prima_rata,
	mutuo_data_scad_ultima_rata,
	mutuo_annualita,
	mutuo_preammortamento,
	mutuo_data_inizio_piano_amm,
	mutuo_contotes_code,
	mutuo_contotes_desc,
	mutuo_attoamm_anno,
	mutuo_attoamm_numero,
	mutuo_attoamm_tipo_code,
	mutuo_attoamm_tipo_desc,
	mutuo_attoamm_sac_tipo_code,
	mutuo_attoamm_sac_tipo_desc,
	mutuo_attoamm_sac_code,
	mutuo_validita_inizio,
	mutuo_validita_fine
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
	mutuo.mutuo_oggetto,
	stato.mutuo_stato_code,
	stato.mutuo_stato_desc,
	tasso_tipo.mutuo_tipo_tasso_code mutuo_tipo_tasso_code,
	tasso_tipo.mutuo_tipo_tasso_desc mutuo_tipo_tasso_desc,
	mutuo.mutuo_data_atto,
	sog.soggetto_id mutuo_soggetto_id,
	sog.soggetto_code mutuo_soggetto_code,
	sog.soggetto_desc mutuo_soggetto_desc,
	sog.codice_fiscale mutuo_soggetto_codice_fiscale,
	sog.partita_iva mutuo_soggetto_partiva,
	mutuo.mutuo_somma_iniziale,
	mutuo.mutuo_somma_effettiva,
	mutuo.mutuo_tasso,	
	mutuo.mutuo_tasso_euribor,	
	mutuo.mutuo_tasso_spread,	
	mutuo.mutuo_durata_anni,	
	mutuo.mutuo_anno_inizio,	
	mutuo.mutuo_anno_fine,	
	per_rimborso.mutuo_periodo_rimborso_code  mutuo_periodo_rimborso_code,
	per_rimborso.mutuo_periodo_rimborso_desc   mutuo_periodo_rimborso_desc,
	per_rimborso.mutuo_periodo_numero_mesi    mutuo_periodo_rimborso_mesi,
	mutuo.mutuo_data_scadenza_prima_rata,
	mutuo.mutuo_data_scadenza_ultima_rata mutuo_data_scad_ultima_rata,
	mutuo.mutuo_annualita,
	mutuo.mutuo_preammortamento,
	mutuo.mutuo_data_inizio_piano_ammortamento mutuo_data_inizio_piano_amm,
	conto.contotes_code  mutuo_contotes_code,
	conto.contotes_desc   mutuo_contotes_desc,
	atto.attoamm_anno mutuo_attoamm_anno,
	atto.attoamm_numero mutuo_attoamm_numero,
	tipo_atto.attoamm_tipo_code mutuo_attoamm_tipo_code,
	tipo_atto.attoamm_tipo_desc mutuo_attoamm_tipo_desc,
	(case when rc.classif_id is not null then tipo_class.classif_tipo_code else ''  end )::varchar(200) mutuo_attoamm_sac_tipo_code,
    (case when rc.classif_id is not null then tipo_class.classif_tipo_desc  else ''  end )::varchar(500) mutuo_attoamm_sac_tipo_desc,
    (case when rc.classif_id is not null then c.classif_code  else ''  end )::varchar(500) mutuo_attoamm_sac_code,
    mutuo.validita_inizio  mutuo_validita_inizio,
    mutuo.validita_fine     mutuo_validita_fine
FROM siac_d_mutuo_Stato stato,
             siac_t_mutuo mutuo 
              left join siac_d_mutuo_tipo_tasso  tasso_tipo on ( mutuo.mutuo_tipo_tasso_id=tasso_tipo.mutuo_tipo_tasso_id)
              left join siac_t_atto_amm atto  
                     join siac_d_atto_amm_tipo tipo_atto on ( tipo_atto.attoamm_tipo_id=atto.attoamm_tipo_id)
                     left join siac_r_atto_amm_class rc 
                            join siac_t_class c join siac_d_class_tipo tipo_class on ( tipo_class.classif_tipo_id=c.classif_tipo_id and tipo_class.classif_tipo_code in ('CDC','CDR'))
                             on (c.classif_id=rc.classif_id)
                     on (rc.attoamm_id=atto.attoamm_id
                            and  rc.data_cancellazione is null 
                            and  rc.validita_fine is null ) 
                on ( mutuo.mutuo_attoamm_id=atto.attoamm_id)
              left join siac_t_soggetto sog on ( mutuo.mutuo_soggetto_id=sog.soggetto_id )
              left join siac_d_contotesoreria  conto on (mutuo.mutuo_contotes_id=conto.contotes_id)
              left join siac_d_mutuo_periodo_rimborso per_rimborso on (mutuo.mutuo_periodo_rimborso_id=per_rimborso.mutuo_periodo_rimborso_id) 
where stato.mutuo_stato_id =mutuo.mutuo_stato_id 
and     mutuo.data_cancellazione  is null
--and     now() >= mutuo.validita_inizio 
--and     now() <= COALESCE(mutuo.validita_fine, now())
);

alter view siac.siac_v_dwh_mutuo owner to siac;


drop view if exists siac.siac_v_dwh_mutuo_movgest_ts;
create or replace view siac.siac_v_dwh_mutuo_movgest_ts
(
    ente_proprietario_id,
    anno_bilancio,
    mutuo_numero,
    mutuo_movgest_tipo,
    mutuo_movgest_anno,
    mutuo_movgest_numero,
    mutuo_movgest_subnumero ,
    mutuo_movgest_importo_iniziale,
    mutuo_movgest_importo_finale
 )
AS
(
SELECT 
    per.ente_proprietario_id,
    per.anno::integer anno_bilancio,
    mutuo.mutuo_numero,
    tipo.movgest_tipo_code mutuo_movgest_tipo,
    mov.movgest_anno mutuo_movgest_anno,
    mov.movgest_numero::integer movgest_numero,
    (case when tipo_ts.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)::integer mutuo_movgest_subnumero,
    rmov.mutuo_movgest_ts_importo_iniziale mutuo_movgest_importo_iniziale,
    rmov.mutuo_movgest_ts_importo_finale mutuo_movgest_importo_finale
FROM siac_t_bil bil,siac_t_periodo per,
             siac_t_movgest mov,siac_d_movgest_tipo tipo,
             siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipo_ts,
             siac_t_mutuo mutuo ,siac_r_mutuo_movgest_ts  rmov
where bil.periodo_id=per.periodo_id 
and     mov.bil_id=bil.bil_id 
and     tipo.movgest_tipo_id=mov.movgest_tipo_id 
and     ts.movgest_id=mov.movgest_id 
and     tipo_ts.movgest_ts_tipo_id=ts.movgest_ts_tipo_id 
and     rmov.movgest_ts_id =ts.movgest_ts_id 
and     mutuo.mutuo_id=rmov.mutuo_id 
and     rmov.data_cancellazione  is null 
and     mutuo.data_cancellazione  is null
and     mov.data_cancellazione  is null
and     ts.data_cancellazione  is null
--and     now() >= mutuo.validita_inizio 
--and     now() <= COALESCE(mutuo.validita_fine, now())
);

alter view siac.siac_v_dwh_mutuo_movgest_ts owner to siac;


drop view if exists siac.siac_v_dwh_mutuo_programma;
create or replace view siac.siac_v_dwh_mutuo_programma
(
    ente_proprietario_id,
    anno_bilancio,
    mutuo_numero,
    mutuo_programma_tipo,
    mutuo_programma_code,
    mutuo_movgest_importo_iniziale,
    mutuo_movgest_importo_finale
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

drop view if exists siac.siac_v_dwh_mutuo_rata;
create or replace view siac.siac_v_dwh_mutuo_rata
(
    ente_proprietario_id,
    mutuo_numero,
    mutuo_rata_anno,
	mutuo_rata_num_rata_piano,
	mutuo_rata_num_rata_anno,
	mutuo_rata_data_scadenza,
	mutuo_rata_importo,
	mutuo_rata_importo_q_interessi,
	mutuo_rata_importo_q_capitale,
	mutuo_rata_importo_q_oneri,
	mutuo_rata_debito_residuo,
	mutuo_rata_debito_iniziale
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
    rata.mutuo_rata_anno,
	rata.mutuo_rata_num_rata_piano,
	rata.mutuo_rata_num_rata_anno,
	rata.mutuo_rata_data_scadenza,
	rata.mutuo_rata_importo,
	rata.mutuo_rata_importo_quota_interessi mutuo_rata_importo_q_interessi,
	rata.mutuo_rata_importo_quota_capitale  mutuo_rata_importo_q_capitale ,
	rata.mutuo_rata_importo_quota_oneri     mutuo_rata_importo_q_oneri,
	rata.mutuo_rata_debito_residuo,
	rata.mutuo_rata_debito_iniziale
FROM siac_t_mutuo mutuo ,siac_t_mutuo_rata rata 
where  mutuo.mutuo_id=rata.mutuo_id 
and      mutuo.data_cancellazione  is null
and      rata.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_rata owner to siac;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_mutuo_variazione;
create or replace view siac.siac_v_dwh_mutuo_variazione
(
    ente_proprietario_id,
	mutuo_variazione_anno,
	mutuo_variazione_num_rata,
   	mutuo_variazione_tipo_code,
   	mutuo_variazione_tipo_desc,
    mutuo_numero,   	
	mutuo_var_anno_fine_piano_amm,
	mutuo_variazione_num_rata_fin,
	mutuo_variazione_importo_rata,
	mutuo_variazione_tasso_euribor
 )
AS
(
SELECT 
    var.ente_proprietario_id,
    var.mutuo_variazione_anno ,
    var.mutuo_variazione_num_rata ,
    tipo.mutuo_variazione_tipo_code ,
    tipo.mutuo_variazione_tipo_desc ,
    mutuo.mutuo_numero,
    var.mutuo_variazione_anno_fine_piano_ammortamento mutuo_var_anno_fine_piano_amm,
    var.mutuo_variazione_num_rata_finale mutuo_variazione_num_rata_fin,
	var.mutuo_variazione_importo_rata,
	var.mutuo_variazione_tasso_euribor
FROM  siac_t_mutuo mutuo ,siac_t_mutuo_variazione  var,siac_d_mutuo_variazione_tipo  tipo 
where tipo.mutuo_variazione_tipo_id =var.mutuo_variazione_id 
and      mutuo.mutuo_id=var.mutuo_id 
and      mutuo.data_cancellazione  is null
and      var.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_variazione owner to siac;


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_storico_mutuo;
create or replace view siac.siac_v_dwh_storico_mutuo
(
    ente_proprietario_id,
    mutuo_numero,
	mutuo_oggetto,
	mutuo_stato_code,
	mutuo_stato_desc,
	mutuo_tipo_tasso_code,
	mutuo_tipo_tasso_desc,
	mutuo_data_atto,
	mutuo_soggetto_id,
	mutuo_soggetto_code,
	mutuo_soggetto_desc,
	mutuo_soggetto_codice_fiscale,
	mutuo_soggetto_partiva,
	mutuo_somma_iniziale,
	mutuo_somma_effettiva,
	mutuo_tasso,	
	mutuo_tasso_euribor,	
	mutuo_tasso_spread,	
	mutuo_durata_anni,	
	mutuo_anno_inizio,	
	mutuo_anno_fine,	
	mutuo_periodo_rimborso_code,
	mutuo_periodo_rimborso_desc,
	mutuo_periodo_rimborso_mesi,
	mutuo_data_scadenza_prima_rata,
	mutuo_data_scad_ultima_rata,
	mutuo_annualita,
	mutuo_preammortamento,
	mutuo_data_inizio_piano_amm,
	mutuo_contotes_code,
	mutuo_contotes_desc,
	mutuo_attoamm_anno,
	mutuo_attoamm_numero,
	mutuo_attoamm_tipo_code,
	mutuo_attoamm_tipo_desc,
	mutuo_attoamm_sac_tipo_code,
	mutuo_attoamm_sac_tipo_desc,
	mutuo_attoamm_sac_code,
	mutuo_st_validita_inizio,
	mutuo_st_validita_fine,
	mutuo_st_data_creazione
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
	mutuo.mutuo_oggetto,
	stato.mutuo_stato_code,
	stato.mutuo_stato_desc,
	tasso_tipo.mutuo_tipo_tasso_code mutuo_tipo_tasso_code,
	tasso_tipo.mutuo_tipo_tasso_desc mutuo_tipo_tasso_desc,
	mutuo.mutuo_data_atto,
	sog.soggetto_id mutuo_soggetto_id,
	sog.soggetto_code mutuo_soggetto_code,
	sog.soggetto_desc mutuo_soggetto_desc,
	sog.codice_fiscale mutuo_soggetto_codice_fiscale,
	sog.partita_iva mutuo_soggetto_partiva,
	mutuo.mutuo_somma_iniziale,
	mutuo.mutuo_somma_effettiva,
	mutuo.mutuo_tasso,	
	mutuo.mutuo_tasso_euribor,	
	mutuo.mutuo_tasso_spread,	
	mutuo.mutuo_durata_anni,	
	mutuo.mutuo_anno_inizio,	
	mutuo.mutuo_anno_fine,	
	per_rimborso.mutuo_periodo_rimborso_code  mutuo_periodo_rimborso_code,
	per_rimborso.mutuo_periodo_rimborso_desc   mutuo_periodo_rimborso_desc,
	per_rimborso.mutuo_periodo_numero_mesi    mutuo_periodo_rimborso_mesi,
	mutuo.mutuo_data_scadenza_prima_rata,
	mutuo.mutuo_data_scadenza_ultima_rata mutuo_data_scad_ultima_rata,
	mutuo.mutuo_annualita,
	mutuo.mutuo_preammortamento,
	mutuo.mutuo_data_inizio_piano_ammortamento mutuo_data_inizio_piano_amm,
	conto.contotes_code  mutuo_contotes_code,
	conto.contotes_desc   mutuo_contotes_desc,
	atto.attoamm_anno mutuo_attoamm_anno,
	atto.attoamm_numero mutuo_attoamm_numero,
	tipo_atto.attoamm_tipo_code mutuo_attoamm_tipo_code,
	tipo_atto.attoamm_tipo_desc mutuo_attoamm_tipo_desc,
	(case when rc.classif_id is not null then tipo_class.classif_tipo_code else ''  end )::varchar(200) mutuo_attoamm_sac_tipo_code,
    (case when rc.classif_id is not null then tipo_class.classif_tipo_desc  else ''  end )::varchar(500) mutuo_attoamm_sac_tipo_desc,
    (case when rc.classif_id is not null then c.classif_code  else ''  end )::varchar(500) mutuo_attoamm_sac_code,
    mutuo.validita_inizio     mutuo_st_validita_inizio,
    mutuo.validita_fine        mutuo_st_validita_fine,
    mutuo.data_creazione    mutuo_st_data_creazione
    
FROM siac_d_mutuo_Stato stato,
             siac_s_mutuo_storico mutuo 
              left join siac_d_mutuo_tipo_tasso  tasso_tipo on ( mutuo.mutuo_tipo_tasso_id=tasso_tipo.mutuo_tipo_tasso_id)
              left join siac_t_atto_amm atto  
                     join siac_d_atto_amm_tipo tipo_atto on ( tipo_atto.attoamm_tipo_id=atto.attoamm_tipo_id)
                     left join siac_r_atto_amm_class rc 
                            join siac_t_class c join siac_d_class_tipo tipo_class on ( tipo_class.classif_tipo_id=c.classif_tipo_id and tipo_class.classif_tipo_code in ('CDC','CDR'))
                             on (c.classif_id=rc.classif_id)
                     on (rc.attoamm_id=atto.attoamm_id
                            and  rc.data_cancellazione is null 
                            and  rc.validita_fine is null ) 
                on ( mutuo.mutuo_attoamm_id=atto.attoamm_id)
              left join siac_t_soggetto sog on ( mutuo.mutuo_soggetto_id=sog.soggetto_id )
              left join siac_d_contotesoreria  conto on (mutuo.mutuo_contotes_id=conto.contotes_id)
              left join siac_d_mutuo_periodo_rimborso per_rimborso on (mutuo.mutuo_periodo_rimborso_id=per_rimborso.mutuo_periodo_rimborso_id) 
where stato.mutuo_stato_id =mutuo.mutuo_stato_id 
and     mutuo.data_cancellazione  is null
--and     now() >= mutuo.validita_inizio 
--and     now() <= COALESCE(mutuo.validita_fine, now())
);

alter view siac.siac_v_dwh_storico_mutuo owner to siac;




-- SIAC-TASK-20  Sofia 16.05.2023 fine 