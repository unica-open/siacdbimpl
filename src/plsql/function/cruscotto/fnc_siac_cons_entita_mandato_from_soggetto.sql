/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--DROP FUNCTION if exists fnc_siac_cons_entita_mandato_from_soggetto_total (integer);
--DROP FUNCTION if exists fnc_siac_cons_entita_reversale_from_soggetto (integer,  integer, integer);
--DROP FUNCTION if exists fnc_siac_cons_entita_reversale_from_soggetto_total (integer);
--select * from fnc_siac_cons_entita_mandato_from_soggetto (234,'2018',100,0);

DROP FUNCTION if exists fnc_siac_cons_entita_mandato_from_soggetto (integer,  varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_soggetto (
  _uid_soggetto integer,
  _annoesercizio varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  -- 11.07.2018 Sofia siac-6193
  ord_soggetto_code varchar,
  ord_soggetto_desc varchar,
  -- 11.07.2018 Sofia siac-6193
  --  accredito_tipo_code varchar,
  --  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  uid_capitolo integer,
  num_capitolo varchar,
  num_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp,
  ord_quietanza_data timestamp,
  -- 11.07.2018 Sofia jira siac-6193
  sog_codice_fiscale varchar,
  sog_partita_iva varchar,
  -- MDP - no cessione
  ord_accredito_tipo_code varchar,
  ord_accredito_tipo_desc varchar,
  ord_iban varchar,
  ord_bic varchar,
  ord_contocorrente varchar,
  ord_contocorrente_intestazione varchar,
  ord_banca_denominazione varchar,
  ord_quietanzante varchar,
  ord_quietanzante_codice_fiscale varchar,
  -- Estremi Cessione
  ord_soggetto_cessione_code varchar,
  ord_soggetto_cessione_desc varchar,
  ord_relaz_tipo_code varchar,
  ord_relaz_tipo_desc varchar,
  -- MDP - Cessione
  ord_accredito_tipo_code_cess varchar,
  ord_accredito_tipo_desc_cess varchar,
  ord_iban_cess varchar,
  ord_bic_cess varchar,
  ord_contocorrente_cess varchar,
  ord_contocorrente_intestazione_cess varchar,
  ord_banca_denominazione_cess varchar,
  ord_quietanzante_cess varchar,
  ord_quietanzante_codice_fiscale_cess varchar,
  liq_attoamm_desc varchar,
  liq_attoalg_data_inserimento timestamp,
  liq_attoalg_data_scad timestamp,
  liq_attoalg_stato_desc varchar,
  ord_split varchar,
  ord_split_importo numeric,
  ord_ritenute varchar,
  ord_ritenute_importo numeric,
  carte_contabili varchar,
  ord_copertura varchar,
  ord_conto_tesoreria varchar,
  ord_distinta_codice varchar,
  ord_distinta_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;

    enteProprietarioId integer=null;

BEGIN

	-- 11.07.2018 Sofia jira siac-6193
    select s.ente_proprietario_id into enteProprietarioId
    from siac_t_soggetto s
    where s.soggetto_id=_uid_soggetto;

	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
            	--8,7 sec --> 4,7
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code,
                    -- 11.07.2018 Sofia jira siac-6193
                    f.ord_ts_id,
                    a.contotes_id,
                    a.dist_id
				from
					 siac_t_ordinativo a
					,siac_r_ordinativo_stato d
					,siac_d_ordinativo_stato e
					,siac_t_ordinativo_ts f
					,siac_t_ordinativo_ts_det g
					,siac_d_ordinativo_ts_det_tipo h
					,siac_d_ordinativo_tipo i
                    ,siac_t_bil tbil
					,siac_t_periodo tper

				where d.ord_id=a.ord_id
                    and d.ord_stato_id=e.ord_stato_id
                    and f.ord_id=a.ord_id
                    and g.ord_ts_id=f.ord_ts_id
                    and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
                    and a.bil_id = tbil.bil_id
                    and tbil.periodo_id	= tper.periodo_id
                    and i.ord_tipo_id=a.ord_tipo_id
					and tbil.ente_proprietario_id = enteProprietarioId                    
                    and tper.anno = _annoEsercizio
                    and h.ord_ts_det_tipo_code = 'A'
                    and i.ord_tipo_code='P'
                    and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
                    and a.data_cancellazione is null
                    and d.data_cancellazione is null
                    and e.data_cancellazione is null
                    and f.data_cancellazione is null
                    and g.data_cancellazione is null
                    and h.data_cancellazione is null
                    and i.data_cancellazione is null
                    and tbil.data_cancellazione is null
                    and tper.data_cancellazione is null

			),
			soggetto as (--ok
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc,
                    -- 11.07.2018 Sofia jira siac-6193
                    c.codice_fiscale::varchar sog_codice_fiscale,
				    c.partita_iva    sog_partita_iva,
                    c.soggetto_id
				from
					siac_t_soggetto c,
					siac_r_ordinativo_soggetto b
				where c.soggetto_id=b.soggetto_id
				and c.soggetto_id=_uid_soggetto
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
            --40 sec -->11
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q,
					siac_r_ordinativo_atto_amm m
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
                and n.ente_proprietario_id = enteProprietarioId
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE (m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
            --56 sec -->18
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc
				from
					siac_t_bil_elem s,
					siac_r_ordinativo_bil_elem r
				where s.elem_id=r.elem_id
                and s.ente_proprietario_id = enteProprietarioId
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as
            (
				with modpag_noncessione as
                (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc,
                        -- 11.07.2018 Sofia jira siac-6193
                        null::varchar soggetto_cessione_code,
                        null::varchar soggetto_cessione_desc,
                        null::varchar relaz_tipo_code,
                        null::varchar relaz_tipo_desc,
                        d2.iban,
                        d2.bic,
                        d2.contocorrente,
                        d2.contocorrente_intestazione,
                        d2.banca_denominazione,
                        d2.quietanziante,
                        d2.quietanziante_codice_fiscale::varchar
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
                    and d2.ente_proprietario_id = enteProprietarioId                    
                    and d2.soggetto_id = _uid_soggetto					
                    and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null--??forse da commentare siac-5670
					and e2.data_cancellazione is null
				),
				modpag_cessione as --ok
                (
					select
						c2.ord_id,
						-- 11.07.2018 Sofia jira siac-6193
                        accre.accredito_tipo_code,
                        accre.accredito_tipo_desc,
                        sog.soggetto_code soggetto_cessione_code,
                        sog.soggetto_desc soggetto_cessione_desc,
						e2.relaz_tipo_code,
						e2.relaz_tipo_desc,
                        -- 11.07.2018 Sofia jira siac-6193
                        mdp.iban,
                        mdp.bic,
                        mdp.contocorrente,
                        mdp.contocorrente_intestazione,
                        mdp.banca_denominazione,
                        mdp.quietanziante,
                        mdp.quietanziante_codice_fiscale::varchar
					from
						siac_r_ordinativo_modpag c2,
						siac_r_soggetto_relaz d2,
                        siac_t_soggetto sog,
						siac_d_relaz_tipo e2,
                        siac_d_oil_relaz_tipo oil, 
                        siac_r_oil_relaz_tipo roil, -- 13.07.2018 Sofia jira siac-6193
                        siac_r_soggrel_modpag rel,
                        siac_t_modpag mdp,
                        siac_d_accredito_tipo accre
					where d2.soggetto_relaz_id = c2.soggetto_relaz_id
					and   e2.relaz_tipo_id = d2.relaz_tipo_id
                    -- 13.07.2017 Sofia jira siac-6193
                    and   roil.relaz_tipo_id=e2.relaz_tipo_id
                    and   oil.oil_relaz_tipo_id=roil.oil_relaz_tipo_id
                    and   oil.oil_relaz_tipo_code='CSI'
                    and   rel.soggetto_relaz_id=d2.soggetto_relaz_id
                    and   mdp.modpag_id=rel.modpag_id
                    and   accre.accredito_tipo_id=mdp.accredito_tipo_id
                    and   sog.soggetto_id=d2.soggetto_id_a  
                    
                    and   d2.soggetto_id_da = _uid_soggetto
                  
                    and   sog.ente_proprietario_id = enteProprietarioId        
                    and   mdp.soggetto_id = _uid_soggetto                    
                    -- 13.07.2017 Sofia jira siac-6193
					and   c2.data_cancellazione is null
					and   d2.data_cancellazione is null
                    and   sog.data_cancellazione is null
					and   e2.data_cancellazione is null
                    and   oil.data_cancellazione is null
                    and   roil.data_cancellazione is null
                    and   rel.data_cancellazione is null
                    and   mdp.data_cancellazione is null
                    and   accre.data_cancellazione is null
                    and   roil.validita_fine is null
					and   now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
                    and   now() BETWEEN d2.validita_inizio and coalesce (d2.validita_fine,now())
                    and   now() BETWEEN rel.validita_inizio and coalesce (rel.validita_fine,now())
                    and   now() BETWEEN mdp.validita_inizio and coalesce (mdp.validita_fine,now())
				)
				select *
				from modpag_noncessione
				UNION ALL
				select *
				from modpag_cessione
			),
            -- 11.07.2018 Sofia jira siac-6193
            liquidazione as
            (
              with
              liq as
              (
				select r.sord_id ord_ts_id,
					   r.liq_id
				from  siac_r_liquidazione_ord r
				where r.ente_proprietario_id=enteProprietarioId
                and   r.data_cancellazione is null
				and   now() BETWEEN r.validita_inizio and COALESCE(r.validita_fine,now())
              ),
              liq_atto as --15 sec
              (
              	select rliq.liq_id,
                       coalesce(alg.attoal_causale , atto.attoamm_oggetto) liq_attoamm_desc,
                  	   alg.data_creazione liq_attoalg_data_inserimento,
                       alg.attoal_data_scadenza liq_attoalg_data_scad,
                       algstato.attoal_stato_desc liq_attoalg_stato_desc
        	    from siac_r_liquidazione_atto_amm rliq,
            	     siac_t_atto_amm atto
                	 left join siac_t_atto_allegato alg
                     join siac_r_atto_allegato_stato rsalg
                     join siac_d_atto_allegato_stato algstato on (algstato.attoal_stato_id=rsalg.attoal_stato_id and algstato.attoal_stato_code!='A')
                     on (rsalg.attoal_id=alg.attoal_id and rsalg.data_cancellazione is null and now() between rsalg.validita_inizio and coalesce(rsalg.validita_fine, now()))
                     on ( alg.attoamm_id=atto.attoamm_id )
	             where atto.ente_proprietario_id= enteProprietarioId
                 and   rliq.attoamm_id=atto.attoamm_id
	             and   rliq.data_cancellazione is null
     		     and   rliq.validita_fine is null
            	 and   atto.data_cancellazione is null
	             and   now() between atto.validita_inizio and coalesce(atto.validita_fine, now())
              )
              select liq.*,
                     liq_atto.liq_attoamm_desc,
                     liq_atto.liq_attoalg_data_inserimento,
                     liq_atto.liq_attoalg_data_scad,
                     liq_atto.liq_attoalg_stato_desc
              from liq left join liq_atto on (liq.liq_id=liq_atto.liq_id)
			),
            -- 11.07.2018 Sofia jira siac-6193
            split as
            (
              select distinct
                     rsub.ord_ts_id
              from 	siac_r_subdoc_ordinativo_ts rsub,
                    siac_t_subdoc sub,siac_r_subdoc_splitreverse_iva_tipo rsplit,
                    siac_d_splitreverse_iva_tipo tipo
              where tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.sriva_tipo_code!='ES'
              and   rsplit.sriva_tipo_id=tipo.sriva_tipo_id
              and   sub.subdoc_id=rsplit.subdoc_id
              and   rsub.subdoc_id=sub.subdoc_id
              and   rsub.data_cancellazione is null
              and   rsub.validita_fine is null
              and   sub.data_cancellazione is null
              and   sub.validita_fine is null
              and   rsplit.data_cancellazione is null
              and   rsplit.validita_fine is null
            ),
            -- 11.07.2018 Sofia jira siac-6193
            split_importo as
            (
            	select rord.ord_id_da ord_id,
                	   coalesce(sum(coalesce(det.ord_ts_det_importo,0)),0) importo
                from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                     siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato,
                     siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod
				where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.relaz_tipo_code='SPR'
                and   tipo.relaz_tipo_id=rord.relaz_tipo_id
			    and   rstato.ord_id=rOrd.ord_id_a
                and   stato.ord_stato_id=rstato.ord_stato_id
				and   stato.ord_stato_code!='A'
                and   ts.ord_id=rstato.ord_id
                and   det.ord_ts_id=ts.ord_ts_id
       	        and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
                and   tipod.ord_ts_det_tipo_code='A'
                and   rord.data_cancellazione is null
			    and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   				and   rstato.data_cancellazione is null
				and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
   				and   ts.data_cancellazione is null
                and   ts.validita_fine is null
   				and   det.data_cancellazione is null
                and   det.validita_fine is null
                group by rord.ord_id_da
            ),
            -- 11.07.2018 Sofia jira siac-6193
            ritenute as
            (
             select distinct ts.ord_ts_id
             from siac_r_doc_onere  rdoc, siac_t_subdoc doc, siac_r_subdoc_ordinativo_ts ts,
                  siac_d_onere_tipo tipo,siac_d_onere onere
	  		 where   tipo.ente_proprietario_id=enteProprietarioId
               and   tipo.onere_tipo_code not in ('SP','ES')
               and   onere.onere_tipo_id=tipo.onere_tipo_id
               and   rdoc.onere_id=onere.onere_id
               and   doc.doc_id=rdoc.doc_id
               and   ts.subdoc_id=doc.subdoc_id
			   and   rdoc.data_cancellazione is null
               and   now() between rdoc.validita_inizio and coalesce(rdoc.validita_fine, now())
               and   doc.data_cancellazione is null
	     	   and   doc.validita_fine is null
               and   ts.data_cancellazione is null
               and   now() between ts.validita_inizio and coalesce(ts.validita_fine, now())
            ),
            -- 11.07.2018 Sofia jira siac-6193
            ritenute_importo as --ok
            (
             select rOrd.ord_id_da ord_id,coalesce(sum(coalesce(det.ord_ts_det_importo,0)),0)  importo
             from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                  siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato,
  	              siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod
			 where  tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.relaz_tipo_code='RIT_ORD'
			  and   tipo.relaz_tipo_id=rord.relaz_tipo_id
			  and   rstato.ord_id=rOrd.ord_id_a
	          and   stato.ord_stato_id=rstato.ord_stato_id
	    	  and   stato.ord_stato_code!='A'
	          and   ts.ord_id=rstato.ord_id
    	      and   det.ord_ts_id=ts.ord_ts_id
        	  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
              and   tipod.ord_ts_det_tipo_code='A'
	          and   rord.data_cancellazione is null
 		  	  and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   			  and   rstato.data_cancellazione is null
			  and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
	   		  and   ts.data_cancellazione is null
    	      and   ts.validita_fine is null
   			  and   det.data_cancellazione is null
              and   det.validita_fine is null
              group by rOrd.ord_id_da
            ),
            -- 11.07.2018 Sofia jira siac-6193
            conto_tesoreria as
            (
             select d.contotes_id, d.contotes_code
             from siac_d_contotesoreria d
             where d.ente_proprietario_id=enteProprietarioId
            ),
            -- 11.07.2018 Sofia jira siac-6193
            distinta as
            (
             select dist.dist_id,
                    dist.dist_code,
                    dist.dist_desc
             from siac_d_distinta dist
             where dist.ente_proprietario_id=enteProprietarioId
            )
			select ordinativo.*,
                   soggetto.*,
                   attoamm.*,
                   capitolo.*,
                   modpag.*,
                   liquidazione.*,
                   -- 11.07.2018 Sofia jira siac-6193
                   ( case when split.ord_ts_id is not null then 'S' else 'N' end)::varchar ord_split,
                   split_importo.importo ord_split_importo,
                   -- 11.07.2018 Sofia jira siac-6193
                   ( case when ritenute.ord_ts_id is not null then 'S' else 'N' end)::varchar ord_ritenute,
                   ritenute_importo.importo ord_ritenute_importo,
                   conto_tesoreria.contotes_code ord_conto_tesoreria,
                   distinta.dist_code ord_distinta_codice,
                   distinta.dist_desc ord_distinta_desc
			from
				           ordinativo
				CROSS JOIN soggetto
				CROSS JOIN attoamm
				CROSS JOIN capitolo
				LEFT OUTER JOIN modpag on  (ordinativo.uid=modpag.ord_id)
                -- 11.07.2018 Sofia jira siac-6193
                left join liquidazione on (ordinativo.ord_ts_id=liquidazione.ord_ts_id)
                left join split on (ordinativo.ord_ts_id=split.ord_ts_id)
                left join split_importo on (ordinativo.uid=split_importo.ord_id)
                left join ritenute on (ordinativo.ord_ts_id=ritenute.ord_ts_id)
                left join ritenute_importo on (ordinativo.uid=ritenute_importo.ord_id)
                left join  conto_tesoreria on (conto_tesoreria.contotes_id=ordinativo.contotes_id)
                left join  distinta on (distinta.dist_id=ordinativo.dist_id)
			where ordinativo.uid=soggetto.ord_id
			and ordinativo.uid=attoamm.ord_id
			and ordinativo.uid=capitolo.ord_id
			--and ordinativo.uid=modpag.ord_id
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
            and y.ente_proprietario_id = enteProprietarioId
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		),
        -- 11.07.2018 Sofia jira siac-6193
        carte_contabili as
        (
           select  distinct rcs.soggetto_id
           from  siac_r_cartacont_det_soggetto rcs,
                 siac_t_cartacont_det det, siac_t_cartacont carta,
                 siac_r_cartacont_stato rs,siac_d_cartacont_stato stato
	       where   det.ente_proprietario_id=enteProprietarioId
             and   det.cartac_det_id=rcs.cartac_det_id
             and   carta.cartac_id=det.cartac_id
             and   rs.cartac_id=carta.cartac_id
             and   stato.cartac_stato_id=rs.cartac_stato_id
             and   stato.cartac_stato_code!='A'
             and   rcs.data_cancellazione is null
             and   now() between rcs.validita_inizio and coalesce(rcs.validita_fine, now())
             and   rs.data_cancellazione is null
             and   now() between rs.validita_inizio and coalesce(rs.validita_fine, now())
             and   carta.data_cancellazione is null
             and   carta.validita_fine is null
             and   det.data_cancellazione is null
             and   det.validita_fine is null
        )
		select ord_join.*,
        	   sac_attoamm.*,
               (case when carte_contabili.soggetto_id is not null then 'S' else 'N' end ) sog_carte_contabili
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
        -- 11.07.2018 Sofia jira siac-6193
        left outer join carte_contabili on ord_join.soggetto_id=carte_contabili.soggetto_id
	),
	provv_cassa as (
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
        and b2.ente_proprietario_id = enteProprietarioId
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	),quietanza AS(
     --SIAC-5899
      SELECT
          siac_T_Ordinativo.ord_id,
          siac_r_ordinativo_quietanza.ord_quietanza_data
      FROM
          siac_t_oil_ricevuta
          ,siac_T_Ordinativo
          ,siac_d_oil_ricevuta_tipo
          ,siac_r_ordinativo_quietanza
      WHERE
              siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
          AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id
          AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
          and siac_T_Ordinativo.ente_proprietario_id = enteProprietarioId
          AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'
          AND siac_t_oil_ricevuta.data_cancellazione is null
          AND siac_T_Ordinativo.data_cancellazione is null
          AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
          AND siac_r_ordinativo_quietanza.data_cancellazione is null
    )
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
        -- 12.07.2018 Sofia siac-6193
		ord_join_outer.soggetto_code ord_soggetto_code,
		ord_join_outer.soggetto_desc ord_soggetto_desc,
        -- 11.07.2018 Sofia jira siac-6193
        --		ord_join_outer.accredito_tipo_code,
        --		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as num_capitolo,
		ord_join_outer.elem_code2 as num_articolo,
		ord_join_outer.elem_code3 as num_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida,
		quietanza.ord_quietanza_data,
        -- 11.07.2018 Sofia jira siac-6193
        ord_join_outer.sog_codice_fiscale,
  		ord_join_outer.sog_partita_iva,
        -- MDP  - no cessione
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.accredito_tipo_code else null end ) ord_accredito_tipo_code,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.accredito_tipo_desc else null end ) ord_accredito_tipo_desc,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.iban else null end ) ord_iban,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.bic else null end ) ord_bic,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.contocorrente else null end ) ord_contocorrente,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.contocorrente_intestazione else null end ) ord_contocorrente_intestazione,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.banca_denominazione else null end ) ord_banca_denominazione,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.quietanziante else null end ) ord_quietanzante,
        (case when ord_join_outer.relaz_tipo_code is null then ord_join_outer.quietanziante_codice_fiscale else null end ) ord_quietanzante_codice_fiscale,
        -- estremi cessione
	    ord_join_outer.soggetto_cessione_code ord_soggetto_cessione_code,
        ord_join_outer.soggetto_cessione_desc ord_soggetto_cessione_desc,
        ord_join_outer.relaz_tipo_code ord_relaz_tipo_code,
        ord_join_outer.relaz_tipo_desc ord_relaz_tipo_desc,
        -- MDP - cessione
		(case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.accredito_tipo_code else null end ) ord_accredito_tipo_code_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.accredito_tipo_desc else null end ) ord_accredito_tipo_desc_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.iban else null end ) ord_iban_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.bic else null end ) ord_bic_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.contocorrente else null end ) ord_contocorrente_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.contocorrente_intestazione else null end ) ord_contocorrente_intestazione_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.banca_denominazione else null end ) ord_banca_denominazione_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.quietanziante else null end ) ord_quietanzante_cess,
        (case when ord_join_outer.relaz_tipo_code is not null then ord_join_outer.quietanziante_codice_fiscale else null end ) ord_quietanzante_codice_fiscale_cess,
		ord_join_outer.liq_attoamm_desc,
        ord_join_outer.liq_attoalg_data_inserimento,
        ord_join_outer.liq_attoalg_data_scad,
        ord_join_outer.liq_attoalg_stato_desc,
        ord_join_outer.ord_split,
        ord_join_outer.ord_split_importo,
        ord_join_outer.ord_ritenute,
        ord_join_outer.ord_ritenute_importo,
        ord_join_outer.sog_carte_contabili::varchar carte_contabili,
        (case when provv_cassa.provc_numero is not null then 'S' else 'N' end )::varchar ord_copertura,
        ord_join_outer.ord_conto_tesoreria,
        ord_join_outer.ord_distinta_codice,
        ord_join_outer.ord_distinta_desc


	from ord_join_outer
		left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
    	left outer join quietanza on ord_join_outer.uid=quietanza.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--select * from  fnc_siac_cons_entita_mandato_from_soggetto (28771,  '2018',100000,  0);
