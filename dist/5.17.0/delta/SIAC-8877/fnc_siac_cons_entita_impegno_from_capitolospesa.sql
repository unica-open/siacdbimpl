/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop function if exists siac.fnc_siac_cons_entita_impegno_from_capitolospesa
(
 _uid_capitolospesa integer, 
 _anno varchar, 
 _filtro_crp varchar, 
 _limit integer, 
 _page integer
 );

CREATE OR REPLACE function  siac.fnc_siac_cons_entita_impegno_from_capitolospesa
(
 _uid_capitolospesa integer, 
 _anno varchar, 
 _filtro_crp varchar, 
 _limit integer, 
 _page integer
 )
 RETURNS table
 (
  uid                                              integer, 
  impegno_anno                          integer, 
  impegno_numero                     numeric, 
  impegno_desc                           varchar, 
  impegno_stato                          varchar, 
  impegno_importo                     numeric, 
  soggetto_code                            varchar, 
  soggetto_desc                             varchar, 
  attoamm_numero                     integer, 
  attoamm_anno                          varchar, 
  attoamm_oggetto                      varchar, 
  attoal_causale                            varchar, 
  attoamm_tipo_code                  varchar, 
  attoamm_tipo_desc                   varchar, 
  attoamm_stato_desc                 varchar, 
  attoamm_sac_code                   varchar, 
  attoamm_sac_desc                    varchar, 
  pdc_code                                     varchar, 
  pdc_desc                                      varchar, 
  impegno_anno_capitolo            integer, 
  impegno_nro_capitolo               integer, 
  impegno_nro_articolo                integer, 
  impegno_flag_prenotazione      varchar, 
  impegno_cup                              varchar, 
  impegno_cig                               varchar, 
  impegno_tipo_debito                 varchar, 
  impegno_motivo_assenza_cig varchar, 
  impegno_componente               varchar, 
  cap_sac_code                             varchar, 
  cap_sac_desc                             varchar, 
  imp_sac_code                            varchar, 
  imp_sac_desc                            varchar, 
  -- SIAC-8877 Paolo 17/05/2023
  programma                                varchar, 
  cronoprogramma                      varchar)
 AS
$body$


DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	raise notice 'STO LANCIANDO LA FNC GIUSTA ****';
	raise notice '_uid_capitolospesa=%',_uid_capitolospesa::varchar;
    raise notice '_anno=%',_anno;
    raise notice '_filtro_crp=%',_filtro_crp;
	RETURN QUERY 
		with imp_sogg_attoamm as 
		(
			with imp_sogg as (
				select distinct
					soggall.elem_id,
					soggall.uid,
					soggall.movgest_anno,
					soggall.movgest_numero,
					soggall.movgest_desc,
					soggall.movgest_stato_desc,
					soggall.movgest_ts_id,
					soggall.movgest_ts_det_importo,
					case when soggall.zzz_soggetto_code is null then soggall.zzzz_soggetto_code else soggall.zzz_soggetto_code end soggetto_code,
					case when soggall.zzz_soggetto_desc is null then soggall.zzzz_soggetto_desc else soggall.zzz_soggetto_desc end soggetto_desc,
					soggall.pdc_code,
					soggall.pdc_desc,
                    -- 29.06.2018 Sofia jira siac-6193
					soggall.impegno_nro_capitolo,
					soggall.impegno_nro_articolo,
					soggall.impegno_anno_capitolo,
                    soggall.impegno_flag_prenotazione,
                    soggall.impegno_cig,
  					soggall.impegno_cup,
                    soggall.impegno_motivo_assenza_cig,
            		soggall.impegno_tipo_debito,
                    -- 11.05.2020 SIAC-7349 SR210
                    soggall.impegno_componente,
                    -- SIAC-8877 Paolo 17/05/2023
                    soggall.programma_code,
                    soggall.cronop_code
				from (
					with za as (
						select
						    zzz.elem_id,
							zzz.uid,
							zzz.movgest_anno,
							zzz.movgest_numero,
							zzz.movgest_desc,
							zzz.movgest_stato_desc,
							zzz.movgest_ts_id,
							zzz.movgest_ts_det_importo,
							zzz.zzz_soggetto_code,
							zzz.zzz_soggetto_desc,
							zzz.pdc_code,
							zzz.pdc_desc,
                            -- 29.06.2018 Sofia jira siac-6193
                            zzz.impegno_nro_capitolo,
                            zzz.impegno_nro_articolo,
                            zzz.impegno_anno_capitolo,
                            zzz.impegno_flag_prenotazione,
                            zzz.impegno_cig,
  							zzz.impegno_cup,
                            zzz.impegno_motivo_assenza_cig,
            				zzz.impegno_tipo_debito,
                            --11/05/2020 SIAC-7349 SR210
                            zzz.impegno_componente,
                            -- SIAC-8877 Paolo 17/05/2023
                            zzz.programma_code,
                            zzz.cronop_code
						from (
							with impegno as (


								select
									bilelem.elem_id, 
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo,
									q.classif_code pdc_code,
									q.classif_desc pdc_desc,
                                    -- 29.06.2018 Sofia jira siac-6193
                                    bilelem.elem_code::integer impegno_nro_capitolo,
                                    bilelem.elem_code2::integer impegno_nro_articolo,
                                    t.anno::integer impegno_anno_capitolo,
                                    c.siope_assenza_motivazione_id,
                                    c.siope_tipo_debito_id,
                                    --11.05.2020 Mr SIAC-7349 SR210 tiro fuori l'id per la join con la tabella del tipo componente
                                    b.elem_det_comp_tipo_id
                                    --
								from
									siac_t_bil_elem bilelem,
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_r_movgest_class p,
									siac_t_class q,
									siac_d_class_tipo r,
									siac_t_bil s,
									siac_t_periodo t,
									siac_t_movgest_ts c
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and p.movgest_ts_id = c.movgest_ts_id
								and q.classif_id = p.classif_id
								and r.classif_tipo_id = q.classif_tipo_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and s.bil_id = a.bil_id
								and t.periodo_id = s.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and p.data_cancellazione is null
								and q.data_cancellazione is null
								and r.data_cancellazione is null
								and s.data_cancellazione is null
								and t.data_cancellazione is null
								and bilelem.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
								and b.elem_id=bilelem.elem_id
								and bilelem.elem_id=_uid_capitolospesa
                                and t.anno = _anno
							),
							siope_assenza_motivazione as
                            (
								select
									d.siope_assenza_motivazione_id,
									d.siope_assenza_motivazione_code,
									d.siope_assenza_motivazione_desc
								from siac_d_siope_assenza_motivazione d
								where d.data_cancellazione is null
							),
							siope_tipo_debito as
                            (
								select
									d.siope_tipo_debito_id,
									d.siope_tipo_debito_code,
									d.siope_tipo_debito_desc
								from siac_d_siope_tipo_debito d
								where d.data_cancellazione is null
							),
							soggetto as
                            (
								select
									g.soggetto_code,
									g.soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sog h
								where h.soggetto_id=g.soggetto_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
							),
							impegno_flag_prenotazione as
                            (
								select
									r.movgest_ts_id,
									r.boolean
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'flagPrenotazione'
							),
							impegno_cig as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cig'
							),
							impegno_cup as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cup'
							),
                            --11.05.2020 SIAC-7349 MR SR210 lista di tutte le componenti
                            componente_desc AS
                            (
                                select * from 
                                siac_d_bil_elem_det_comp_tipo tipo
                                --where tipo.data_cancellazione is NULL --da discuterne. in questo caso prende solo le componenti non cancellate
                            ),
                            -- SIAC-8877 Paolo 17/05/2023
							programma as
							(
								select stm.movgest_ts_id,
									       prog.programma_code
								from 	siac_t_movgest m,
											siac_t_movgest_ts stm, 
											siac_r_movgest_ts_programma r_prog,
											siac_t_programma prog,
											siac_t_bil stb,
											siac_t_periodo stp,
											siac_r_movgest_bil_elem re
								where  re.elem_id=_uid_capitolospesa
								and       m.movgest_id=re.movgest_id								
								and       stb.bil_id = m.bil_id 
								and       stb.periodo_id = stp.periodo_id 
							    and       stp.anno =_anno --anno bilancio
								and       stm.movgest_id = m.movgest_id 
								and       r_prog.movgest_ts_id = stm.movgest_ts_id
								and       prog.programma_id = r_prog.programma_id 
								and       r_prog.data_cancellazione  is null
								and       prog.data_cancellazione is null
								and       re.data_cancellazione is null 
								and       m.data_cancellazione is null
								and       stm.data_cancellazione is null
								and       now() between r_prog.validita_inizio and coalesce(r_prog.validita_fine, now())
								and       now() between prog.validita_inizio and coalesce(prog.validita_fine, now())
								and       now() between re.validita_inizio and coalesce(re.validita_fine, now())
								and       now() between m.validita_inizio and coalesce(m.validita_fine, now())
								and       now() between stm.validita_inizio and coalesce(stm.validita_fine, now())
								order by r_prog.data_creazione desc 
								--limit 1
							),
							-- SIAC-8877 Paolo 17/05/2023
							cronoprogramma as
							(
								select	stm.movgest_ts_id,
											prog.programma_code,
											cronop.cronop_code
								from 	siac_t_movgest m,
											siac_t_bil stb,
											siac_t_periodo stp,
											siac_t_movgest_ts stm, 
											siac_r_movgest_ts_cronop_elem srmtce,
											siac_t_cronop_elem crono,
											siac_t_programma prog,
											siac_r_movgest_bil_elem re,
											siac_t_cronop cronop 
								where re.elem_id=_uid_capitolospesa	
								and     m.movgest_id=re.movgest_id
								and     stb.bil_id = m.bil_id 
								and     stb.periodo_id = stp.periodo_id 
								and     stp.anno =_anno --anno bilancio
								and     m.movgest_id = stm.movgest_id 
								and     stm.movgest_ts_id = srmtce.movgest_ts_id
								and     srmtce.cronop_id = crono.cronop_id
								and     cronop.cronop_id= crono.cronop_id
								and     prog.programma_id = cronop.programma_id
								and     srmtce.data_cancellazione is null
								and     crono.data_cancellazione is null
								and     prog.data_cancellazione is null
								and     m.data_cancellazione is null
								and     re.data_cancellazione is null
								and     stm.data_cancellazione is null
								and     cronop.data_cancellazione is null
								and     now() between re.validita_inizio and coalesce(re.validita_fine, now())
								and     now() between srmtce.validita_inizio and coalesce(srmtce.validita_fine, now())
								and     now() between crono.validita_inizio and coalesce(crono.validita_fine, now())
								and     now() between prog.validita_inizio and coalesce(prog.validita_fine, now())
								and     now() between m.validita_inizio and coalesce(m.validita_fine, now())
								and     now() between stm.validita_inizio and coalesce(stm.validita_fine, now())
								and     now() between cronop.validita_inizio and coalesce(cronop.validita_fine, now())
							    order by srmtce.data_creazione desc 
							--	limit 1
							)
							select
							    impegno.elem_id,
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code zzz_soggetto_code,
								soggetto.soggetto_desc zzz_soggetto_desc,
								impegno.pdc_code,
								impegno.pdc_desc,
                                -- 29.06.2018 Sofia jira siac-6193
                                impegno.impegno_nro_capitolo,
                                impegno.impegno_nro_articolo,
                                impegno.impegno_anno_capitolo,
                                siope_assenza_motivazione.siope_assenza_motivazione_desc impegno_motivo_assenza_cig,
                                siope_tipo_debito.siope_tipo_debito_desc impegno_tipo_debito,
                                coalesce(impegno_flag_prenotazione.boolean,'N') impegno_flag_prenotazione,
                                impegno_cig.testo  impegno_cig,
                                impegno_cup.testo  impegno_cup,
                                --11.05.2020 MR SIAC-7349 SR210
                                componente_desc.elem_det_comp_tipo_desc impegno_componente,
                                -- SIAC-8877 Paolo 17/05/2023
                                (case when cronoprogramma.movgest_ts_id is not null then cronoprogramma.programma_code else programma.programma_code end ) programma_code,
                                (case when cronoprogramma.movgest_ts_id is not null then cronoprogramma.cronop_code          else null end ) cronop_code
							from impegno
                              left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
                              left outer join impegno_flag_prenotazione on impegno.movgest_ts_id=impegno_flag_prenotazione.movgest_ts_id
                              left outer join impegno_cig on impegno.movgest_ts_id=impegno_cig.movgest_ts_id
                              left outer join impegno_cup on impegno.movgest_ts_id=impegno_cup.movgest_ts_id
                              left outer join siope_assenza_motivazione on impegno.siope_assenza_motivazione_id=siope_assenza_motivazione.siope_assenza_motivazione_id
                              left outer join siope_tipo_debito on impegno.siope_tipo_debito_id=siope_tipo_debito.siope_tipo_debito_id
                              --11.05.2020 MR SIAC-7349 SR210
                              left outer join componente_desc on impegno.elem_det_comp_tipo_id=componente_desc.elem_det_comp_tipo_id
                              -- SIAC-8877 Paolo 17/05/2023
                              left outer join programma on (programma.movgest_ts_id=impegno.movgest_ts_id)
                              left outer join cronoprogramma on (cronoprogramma.movgest_ts_id=impegno.movgest_ts_id)
						) as zzz
					),
					zb as (
						select
							zzzz.elem_id,
							zzzz.uid,
							zzzz.movgest_anno,
							zzzz.movgest_numero,
							zzzz.movgest_desc,
							zzzz.movgest_stato_desc,
							zzzz.movgest_ts_id,
							zzzz.movgest_ts_det_importo,
							zzzz.soggetto_code zzzz_soggetto_code,
							zzzz.soggetto_desc zzzz_soggetto_desc
						from (
							with impegno as (
								select
									b.elem_id, 
								    a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_t_bil l,
									siac_t_periodo m
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and l.bil_id = a.bil_id
								and m.periodo_id = l.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and b.elem_id=_uid_capitolospesa
								and m.anno = _anno
							),
							soggetto as (
                                select
									l.soggetto_classe_code soggetto_code,
									l.soggetto_classe_desc soggetto_desc,
									h.movgest_ts_id
								from
									siac_r_movgest_ts_sogclasse h,
									siac_d_soggetto_classe l
								where
								    h.soggetto_classe_id=l.soggetto_classe_id
                                and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and h.data_cancellazione is null
							)
							select
								impegno.elem_id,
							    impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzzz
					)
					select
						za.*,
						zb.zzzz_soggetto_code,
						zb.zzzz_soggetto_desc
					from za
					left join zb on za.movgest_ts_id=zb.movgest_ts_id
				) soggall
			),

			attoamm as (
				select
					movgest_ts_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
                    --29.06.2018 Sofia jira siac-6193
                    n.attoamm_oggetto,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc,
					--SIAC-8188
					staa.attoal_causale
				from
					siac_r_movgest_ts_atto_amm m,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q,
					siac_t_atto_amm n
				--SIAC-8188 se ci sono corrisponsenze le ritorno
				left join siac_t_atto_allegato staa on n.attoamm_id = staa.attoamm_id 
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			)
			select
				imp_sogg.elem_id,
			    imp_sogg.uid,
				imp_sogg.movgest_anno,
				imp_sogg.movgest_numero,
				imp_sogg.movgest_desc,
				imp_sogg.movgest_stato_desc,
				imp_sogg.movgest_ts_det_importo,
				imp_sogg.soggetto_code,
				imp_sogg.soggetto_desc,
				attoamm.attoamm_id,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
                -- 29.06.2018 Sofia jira siac-6193
                attoamm.attoamm_oggetto,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				--SIAC-8188
				attoamm.attoal_causale,
				imp_sogg.pdc_code,
				imp_sogg.pdc_desc,
                -- 29.06.2018 Sofia jira siac-6193
                imp_sogg.impegno_nro_capitolo,
           		imp_sogg.impegno_nro_articolo,
           		imp_sogg.impegno_anno_capitolo,
                imp_sogg.impegno_flag_prenotazione,
                imp_sogg.impegno_cig,
                imp_sogg.impegno_cup,
                imp_sogg.impegno_motivo_assenza_cig,
                imp_sogg.impegno_tipo_debito,
                --11.05.2020 MR SIAC-7349 SR210
                imp_sogg.impegno_componente,
				-- SIAC-8877 Paolo 17/05/2023
				imp_sogg.programma_code,
				imp_sogg.cronop_code
			from imp_sogg

			 left outer join attoamm ON imp_sogg.movgest_ts_id=attoamm.movgest_ts_id
            where (case when coalesce(_filtro_crp,'X')='R' then imp_sogg.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then imp_sogg.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then imp_sogg.movgest_anno>_anno::integer
		                else true end ) -- 29.06.2018 Sofia jira siac-6193
		),
		sac_attoamm as (
			select
				y.classif_code,
				y.classif_desc,
				z.attoamm_id
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		),
      --  	SIAC-8351 Haitham 05/11/2021
		sac_capitolo as (
			select
				class_cap.classif_code,
				class_cap.classif_desc,
				r_class_cap.elem_id
			from
				siac_r_bil_elem_class r_class_cap,
				siac_t_class class_cap,
				siac_d_class_tipo tipo_class_cap
			where r_class_cap.classif_id=class_cap.classif_id
			and tipo_class_cap.classif_tipo_id=class_cap.classif_tipo_id
			and now() BETWEEN r_class_cap.validita_inizio and coalesce (r_class_cap.validita_fine,now())
			and tipo_class_cap.classif_tipo_code  IN ('CDC', 'CDR')
			and r_class_cap.data_cancellazione is NULL
			and tipo_class_cap.data_cancellazione is NULL
			and class_cap.data_cancellazione is NULL
		),	
      --  	SIAC-8351 Haitham 05/11/2021
        sac_impegno as (
		
			select
				class_imp.classif_code,
				class_imp.classif_desc,
				mov.movgest_id 
			from
				siac_r_movgest_class  r_class_imp,
				siac_t_class class_imp,
				siac_d_class_tipo tipo_class_imp,
				siac_t_movgest mov,
				siac_t_movgest_ts ts
			where r_class_imp.classif_id=class_imp.classif_id
			and tipo_class_imp.classif_tipo_id=class_imp.classif_tipo_id
			and now() BETWEEN r_class_imp.validita_inizio and coalesce (r_class_imp.validita_fine,now())
			and tipo_class_imp.classif_tipo_code  IN ('CDC', 'CDR')
			and ts.movgest_ts_id  = r_class_imp.movgest_ts_id 
			and mov.movgest_id = ts.movgest_id 
			and r_class_imp.data_cancellazione is NULL
			and tipo_class_imp.data_cancellazione is NULL
			and class_imp.data_cancellazione is null
			-- 25.02.2022 Sofia Jira SIAC-8648
			and now() BETWEEN ts.validita_inizio and COALESCE(ts.validita_fine,now())
			and ts.data_cancellazione is null
		)
		select
			imp_sogg_attoamm.uid,
			imp_sogg_attoamm.movgest_anno as impegno_anno,
			imp_sogg_attoamm.movgest_numero as impegno_numero,
			imp_sogg_attoamm.movgest_desc as impegno_desc,
			imp_sogg_attoamm.movgest_stato_desc as impegno_stato,
			imp_sogg_attoamm.movgest_ts_det_importo as impegno_importo,
			imp_sogg_attoamm.soggetto_code,
			imp_sogg_attoamm.soggetto_desc,
			imp_sogg_attoamm.attoamm_numero,
			imp_sogg_attoamm.attoamm_anno,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.attoamm_oggetto attoamm_oggetto, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
            imp_sogg_attoamm.attoal_causale attoal_causale, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
			imp_sogg_attoamm.attoamm_tipo_code,
			imp_sogg_attoamm.attoamm_tipo_desc,
			imp_sogg_attoamm.attoamm_stato_desc,
			sac_attoamm.classif_code as attoamm_sac_code,
			sac_attoamm.classif_desc as attoamm_sac_desc,
			imp_sogg_attoamm.pdc_code,
			imp_sogg_attoamm.pdc_desc,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.impegno_anno_capitolo,
            imp_sogg_attoamm.impegno_nro_capitolo,
            imp_sogg_attoamm.impegno_nro_articolo,
            imp_sogg_attoamm.impegno_flag_prenotazione::varchar,
			imp_sogg_attoamm.impegno_cup,
            imp_sogg_attoamm.impegno_cig,
            imp_sogg_attoamm.impegno_tipo_debito,
            imp_sogg_attoamm.impegno_motivo_assenza_cig,
            --11.05.2020 SIAC-7349 MR SR210
            imp_sogg_attoamm.impegno_componente,
   			sac_capitolo.classif_code as cap_sac_code,       --  	SIAC-8351 Haitham 05/11/2021
			sac_capitolo.classif_desc as cap_sac_desc,        --  	SIAC-8351 Haitham 05/11/2021
   			sac_impegno.classif_code as imp_sac_code,       --  	SIAC-8351 Haitham 05/11/2021
			sac_impegno.classif_desc as imp_sac_desc,        --  	SIAC-8351 Haitham 05/11/2021
			imp_sogg_attoamm.programma_code as programma,			--		SIAC-8877 Paolo 17/05/2023
			imp_sogg_attoamm.cronop_code as cronoprogramma	--		SIAC-8877 Paolo 17/05/2023
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		left outer join sac_capitolo on imp_sogg_attoamm.elem_id=sac_capitolo.elem_id
		left outer join sac_impegno on imp_sogg_attoamm.uid=sac_impegno.movgest_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero


		LIMIT _limit
		OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying, integer, integer)
    OWNER TO siac;
