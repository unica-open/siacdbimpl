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
