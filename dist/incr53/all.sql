/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-6448 INIZIO
drop FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno ( _uid_impegno integer,  _anno varchar,  _limit integer,  _page integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_impegno (
  _uid_impegno integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  liq_anno integer,
  liq_numero numeric,
  liq_desc varchar,
  liq_stato varchar,
  uid_capitolo integer,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_ts_code varchar,
  liq_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_oggetto varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  ord_anno integer,
  ord_numero numeric,
  ord_stato_code varchar,
  ord_stato_desc varchar,
  -- 02.07.2018 Sofia siac-6193
  -- Il codice fiscale e la partita Iva del soggetto
  sog_codice_fiscale varchar,
  sog_partita_iva varchar,
  -- Soggetto avente carte contabili
  carte_contabili varchar,
  -- Data creazione dell atto contabile
  attoal_data_creazione timestamp,
  -- Data di scadenza dell atto contabile
  attoal_data_scadenza timestamp,
  -- Stato dell atto contabile
  attoal_stato_desc varchar,
  -- MDP - no cessione
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  iban VARCHAR,
  bic varchar,
  contocorrente varchar,
  contocorrente_intestazione varchar,
  banca_denominazione varchar,
  quietanzante varchar,
  quietanzante_codice_fiscale varchar,
  -- MDP - cessione
  -- Estremi soggetto cessione
  soggetto_cessione_code varchar,
  soggetto_cessione_desc varchar,
  -- Relazione soggetti CSI, CSC
  relaz_tipo_code   varchar,
  relaz_tipo_desc   varchar,
  -- MDP - in caso di cessione dati MDP di cessione
  accredito_tipo_code_cess varchar,
  accredito_tipo_desc_cess varchar,
  iban_cess VARCHAR,
  bic_cess varchar,
  contocorrente_cess varchar,
  contocorrente_intestazione_cess varchar,
  banca_denominazione_cess varchar,
  quietanzante_cess varchar,
  quietanzante_codice_fiscale_cess varchar,
  -- Indicazione se la liquidazione presenta split/ritenute - collegamento a documenti con oneri !=ES
  liq_esiste_split varchar,
  -- Ordinativo
  -- La data di emissione ordinativo
  ord_emissione_data timestamp,
  -- La data di quietanza ordinativo
  ord_quietanza_data timestamp,
  -- 12.07.2018 Sofia jira siac-6193
  -- estremi soggetto ordinativo
  ord_soggetto_code varchar,
  ord_soggetto_desc varchar,
  -- MDP - no cessione
  ord_accredito_tipo_code varchar,
  ord_accredito_tipo_desc varchar,
  ord_iban VARCHAR,
  ord_bic varchar,
  ord_contocorrente varchar,
  ord_contocorrente_intestazione varchar,
  ord_banca_denominazione varchar,
  ord_quietanzante varchar,
  ord_quietanzante_codice_fiscale varchar,
  -- MDP - cessione
  -- Estremi soggetto cessione
  ord_soggetto_cessione_code varchar,
  ord_soggetto_cessione_desc varchar,
  -- Relazione soggetti CSI, CSC
  ord_relaz_tipo_code   varchar,
  ord_relaz_tipo_desc   varchar,
  -- MDP - in caso di cessione dati MDP di cessione
  ord_accredito_tipo_code_cess varchar,
  ord_accredito_tipo_desc_cess varchar,
  ord_iban_cess VARCHAR,
  ord_bic_cess varchar,
  ord_contocorrente_cess varchar,
  ord_contocorrente_intestazione_cess varchar,
  ord_banca_denominazione_cess varchar,
  ord_quietanzante_cess varchar,
  ord_quietanzante_codice_fiscale_cess varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
    v_ente_proprietario_id INTEGER;
BEGIN

	select ente_proprietario_id into v_ente_proprietario_id from siac_t_movgest where siac_t_movgest.movgest_id = _uid_impegno	;

	RETURN QUERY
    with liq as (
		select
			a.liq_id,
			a.liq_anno,
			a.liq_numero,
			a.liq_desc,
			s.liq_stato_desc liq_stato,
			f.elem_id,
			h.anno,
			f.elem_code,
			f.elem_code2,
			f.elem_code3,
			d.movgest_anno,
			d.movgest_numero,
			c.movgest_ts_code,
			a.liq_importo,
			l.soggetto_code,
			l.soggetto_desc,
			n.attoamm_numero,
			n.attoamm_anno,
            n.attoamm_oggetto,
			o.attoamm_tipo_code,
			o.attoamm_tipo_desc,
			q.attoamm_stato_desc,
			n.attoamm_id,
            -- 02.07.2018 Sofia jira siac-6193
            l.soggetto_id,
            l.codice_fiscale::varchar sog_codice_fiscale,
            l.partita_iva sog_partita_iva
		from
			siac_t_liquidazione a,
			siac_r_liquidazione_movgest b,
			siac_t_movgest_ts c,
			siac_t_movgest d,
			siac_r_movgest_bil_elem e,
			siac_t_bil_elem f,
			siac_t_bil g,
			siac_t_periodo h,
			siac_r_liquidazione_soggetto i,
			siac_t_soggetto l,
			siac_r_liquidazione_atto_amm m,
			siac_t_atto_amm n,
			siac_d_atto_amm_tipo o,
			siac_r_atto_amm_stato p,
			siac_d_atto_amm_stato q,
			siac_r_liquidazione_stato r,
			siac_d_liquidazione_stato s
		where a.liq_id=b.liq_id
		and c.movgest_ts_id=b.movgest_ts_id
		and d.movgest_id=c.movgest_id
		and e.movgest_id=d.movgest_id
		and f.elem_id=e.elem_id
		and g.bil_id=f.bil_id
		and h.periodo_id=g.periodo_id
		and i.liq_id=a.liq_id
		and l.soggetto_id=i.soggetto_id
		and m.liq_id=a.liq_id
		and n.attoamm_id=m.attoamm_id
		and o.attoamm_tipo_id=n.attoamm_tipo_id
		and p.attoamm_id=n.attoamm_id
		and p.attoamm_stato_id=q.attoamm_stato_id
		and r.liq_id=a.liq_id
		and r.liq_stato_id=s.liq_stato_id
        and a.ente_proprietario_id = v_ente_proprietario_id
		and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
		and now() BETWEEN e.validita_inizio and coalesce (e.validita_fine,now())
		and now() BETWEEN i.validita_inizio and coalesce (i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
		and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
		and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
        and q.attoamm_stato_code<>'ANNULLATO'
		AND d.movgest_id=_uid_impegno
		and h.anno = _anno
		and a.data_cancellazione is null
		and b.data_cancellazione is null
		and c.data_cancellazione is null
		and d.data_cancellazione is null
		and e.data_cancellazione is null
		and f.data_cancellazione is null
		and g.data_cancellazione is null
		and h.data_cancellazione is null
		and i.data_cancellazione is null
		and l.data_cancellazione is null
		and m.data_cancellazione is null
		and n.data_cancellazione is null
		and o.data_cancellazione is null
		and p.data_cancellazione is null
		and q.data_cancellazione is null
		and r.data_cancellazione is null
		and s.data_cancellazione is null
	),
	sac as
    (
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
		and x.classif_tipo_code  IN ('CDC', 'CDR')
        and x.ente_proprietario_id = v_ente_proprietario_id
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and x.data_cancellazione is NULL
		and y.data_cancellazione is NULL
	),
    -- 02.07.2018 Sofia siac-6193
    cartecont as
    (
        select rcs.soggetto_id, count(*) esiste_carta
        from  siac_r_cartacont_det_soggetto rcs
        where rcs.data_cancellazione is null
        and   rcs.ente_proprietario_id = v_ente_proprietario_id
        and   rcs.validita_fine is null
        group by rcs.soggetto_id
    ),
    -- 02.07.2018 Sofia jira siac-6193
    split_liq as
    (
      select  rliq.liq_id, count(*) esiste_split
      from siac_r_subdoc_liquidazione rliq,siac_t_subdoc sub,siac_r_doc_onere ronere,
           siac_d_onere onere, siac_d_onere_tipo tipo
      where  tipo.onere_tipo_code!='ES'
      and     sub.ente_proprietario_id = v_ente_proprietario_id
      and    onere.onere_tipo_id=tipo.onere_tipo_id
      and    ronere.onere_id=onere.onere_id
      and    sub.doc_id=ronere.doc_id
      and    rliq.subdoc_id=sub.subdoc_id
      and    sub.data_cancellazione is null
      and    onere.data_cancellazione is null
      and    tipo.data_cancellazione is null
      and    ronere.data_cancellazione is null
      and    sub.data_cancellazione is null
      and    rliq.data_cancellazione is null
      and    now() between ronere.validita_inizio and coalesce(ronere.validita_fine,now())
      and    now() between sub.validita_inizio and coalesce(sub.validita_fine,now())
      and    now() between rliq.validita_inizio and coalesce(rliq.validita_fine,now())
      group by rliq.liq_id
    ),
    -- 02.07.2018 Sofia jira siac-6193
    attoallegato as
    (
    	select alg.attoal_id,
               alg.attoamm_id,
               alg.data_creazione attoal_data_creazione,
               alg.attoal_data_scadenza,
               stato.attoal_stato_desc
        from   siac_t_atto_allegato alg, siac_r_atto_allegato_stato rs,siac_d_atto_allegato_stato stato
        where alg.attoal_id  = rs.attoal_id
        and   stato.attoal_stato_id  =  rs.attoal_stato_id
		and   alg.ente_proprietario_id = v_ente_proprietario_id
		and   stato.attoal_stato_code in ('C', 'CV','PC')
        and   stato.data_cancellazione is null
        and   alg.data_cancellazione is null
        and   rs.data_cancellazione is null
    ),
    -- 02.07.2018 Sofia jira siac-6193
    modpag_cessione as
    (
        select
          liqCessione.liq_id,
          rrelaz.soggetto_relaz_id,
          sog_cessione.soggetto_code soggetto_cessione_code,
          sog_cessione.soggetto_desc soggetto_cessione_desc,
          dat.accredito_tipo_code,
          dat.accredito_tipo_desc,
          tmod.iban,
          tmod.bic,
          tmod.contocorrente,
          tmod.contocorrente_intestazione,
          tmod.banca_denominazione,
          tmod.quietanziante ,
          tmod.quietanziante_codice_fiscale::varchar,
          drt.relaz_tipo_code,
          drt.relaz_tipo_desc
        from  siac_t_liquidazione liqCessione,
              siac_r_soggetto_relaz rrelaz,
              siac_d_relaz_tipo drt,
              -- 13.07.2018 Sofia jira siac-6193
              siac_d_oil_relaz_tipo oil,
              siac_r_oil_relaz_tipo roil,
              siac_t_soggetto sog_cessione,
              siac_r_soggrel_modpag rsm,
              siac_t_modpag tmod,
              siac_d_accredito_tipo dat
	    where oil.oil_relaz_tipo_code ='CSI'  -- 13.07.2018 Sofia jira siac-6193
        and   liqCessione.ente_proprietario_id = v_ente_proprietario_id
        and   roil.oil_relaz_tipo_id=oil.oil_relaz_tipo_id
        and   drt.relaz_tipo_id=roil.relaz_tipo_id
        and   drt.relaz_tipo_id=rrelaz.relaz_tipo_id
        and   sog_cessione.soggetto_id=rrelaz.soggetto_id_a
        and   rsm.soggetto_relaz_id=rrelaz.soggetto_relaz_id
        and   tmod.modpag_id=rsm.modpag_id
        and   dat.accredito_tipo_id = tmod.accredito_tipo_id
        and   liqCessione.soggetto_relaz_id=rrelaz.soggetto_relaz_id

 		and liqCessione.data_cancellazione is null
        and rrelaz.data_cancellazione is null
        and drt.data_cancellazione is null
        and oil.data_cancellazione is null
        and roil.data_cancellazione is null
        and sog_cessione.data_cancellazione is null
        and rsm.data_cancellazione is null
        and tmod.data_cancellazione is null
        and dat.data_cancellazione is null
              
        and   liqCessione.validita_fine is null
        and   roil.validita_fine is null
        and   now()  BETWEEN rrelaz.validita_inizio and coalesce(rrelaz.validita_fine,now())
        and   now()  BETWEEN rsm.validita_inizio and coalesce(rsm.validita_fine,now())
        and   now()  BETWEEN tmod.validita_inizio and coalesce(tmod.validita_fine,now())
    ),
    -- 02.07.2018 Sofia jira siac-6193
    modpag_no_cessione as
    (
		select
            liqModpag.liq_id,
            tmod.modpag_id,
            tipo.accredito_tipo_code,
            tipo.accredito_tipo_desc,
            tmod.iban,
            tmod.bic,
            tmod.contocorrente,
            tmod.contocorrente_intestazione,
            tmod.banca_denominazione,
            tmod.quietanziante,
            tmod.quietanziante_codice_fiscale::varchar
        from  siac_t_liquidazione liqModpag, siac_t_modpag tmod,  siac_d_accredito_tipo tipo
		where tipo.accredito_tipo_id = tmod.accredito_tipo_id
        and   liqModpag.modpag_id=tmod.modpag_id
        and   liqModpag.data_cancellazione is null
        and   liqModpag.validita_fine is null
        and   tmod.data_cancellazione is null
        and   tipo.data_cancellazione is null        
        and   tipo.ente_proprietario_id = v_ente_proprietario_id
		and   now()  BETWEEN tmod.validita_inizio and coalesce(tmod.validita_fine,now())
    ),
    ordinativo as
    (
    with
    ordi as
    (
		-- SIAC-5164
		SELECT
			rlo.liq_id,
			tor.ord_anno,
			tor.ord_numero,
			dos.ord_stato_code,
			dos.ord_stato_desc,
            -- 02.07.2018 Sofia jira siac-6193
            -- La data di emissione ordinativo
			tor.ord_emissione_data,
            tor.ord_id,
            tor.ord_tipo_id
		FROM
			siac_r_liquidazione_ord rlo,
			siac_t_ordinativo_ts tot,
			siac_t_ordinativo tor,
			siac_r_ordinativo_stato ros,
			siac_d_ordinativo_stato dos
		WHERE rlo.sord_id = tot.ord_ts_id
		AND tot.ord_id = tor.ord_id
		AND ros.ord_id = tor.ord_id
		AND dos.ord_stato_id = ros.ord_stato_id
        and tot.ente_proprietario_id = v_ente_proprietario_id      
		AND now() BETWEEN rlo.validita_inizio AND COALESCE (rlo.validita_fine, now())
		AND now() BETWEEN ros.validita_inizio AND COALESCE (ros.validita_fine, now())
		AND rlo.data_cancellazione IS NULL
		AND tot.data_cancellazione IS NULL
		AND tor.data_cancellazione IS NULL
		AND ros.data_cancellazione IS NULL
		AND dos.data_cancellazione IS NULL
		AND dos.ord_stato_code <> 'A'
	),
    -- 02.07.2018 Sofia jira siac-6193
     ord_quietanza AS
     (
      SELECT r.ord_id, max(r.ord_quietanza_data) ord_quietanza_data
	  FROM siac_r_ordinativo_quietanza r
	  WHERE r.data_cancellazione  is null
      and   r.ente_proprietario_id = v_ente_proprietario_id
      and   now() between r.validita_inizio and coalesce(r.validita_fine, now())
      group by r.ord_id
     ),
     -- 02.07.2018 Sofia jira siac-6193
     ord_modpag_cessione as
     (
        select
          rmdp.ord_id,
          rrelaz.soggetto_relaz_id,
          sog_cessione.soggetto_code soggetto_cessione_code,
          sog_cessione.soggetto_desc soggetto_cessione_desc,
          dat.accredito_tipo_code,
          dat.accredito_tipo_desc,
          tmod.iban,
          tmod.bic,
          tmod.contocorrente,
          tmod.contocorrente_intestazione,
          tmod.banca_denominazione,
          tmod.quietanziante ,
          tmod.quietanziante_codice_fiscale::varchar,
          drt.relaz_tipo_code,
          drt.relaz_tipo_desc
        from  siac_r_soggetto_relaz rrelaz,
              siac_d_relaz_tipo drt,
              siac_d_oil_relaz_tipo oil, 
              siac_r_oil_relaz_tipo roil,  -- 13.07.2018 Sofia jira siac-6193
              siac_t_soggetto sog_cessione,
              siac_r_soggrel_modpag rsm,
              siac_t_modpag tmod,
              siac_d_accredito_tipo dat,
              siac_r_ordinativo_modpag rmdp
	    where oil.oil_relaz_tipo_code ='CSI'  -- 13.07.2018 Sofia jira siac-6193
        and   roil.oil_relaz_tipo_id=oil.oil_relaz_tipo_id
        and   drt.relaz_tipo_id=roil.relaz_tipo_id
        and   drt.relaz_tipo_id=rrelaz.relaz_tipo_id
        and   sog_cessione.soggetto_id=rrelaz.soggetto_id_a
        and   rsm.soggetto_relaz_id=rrelaz.soggetto_relaz_id
        and   tmod.modpag_id=rsm.modpag_id
        and   dat.accredito_tipo_id = tmod.accredito_tipo_id
        and   rmdp.soggetto_relaz_id=rrelaz.soggetto_relaz_id        
        and   tmod.ente_proprietario_id = v_ente_proprietario_id        
        and   drt.data_cancellazione is null 
        and   rmdp.data_cancellazione is null
        and   rmdp.validita_fine is null
        and   oil.validita_fine is null
        and   sog_cessione.data_cancellazione is null
        and   tmod.data_cancellazione is null
        and   dat.data_cancellazione is null       
        and   roil.data_cancellazione is null
        and   roil.validita_fine is null        
        and   rrelaz.data_cancellazione is null
        and   now()  BETWEEN rrelaz.validita_inizio and coalesce(rrelaz.validita_fine,now())
        and   rsm.data_cancellazione is null
        and   now()  BETWEEN rsm.validita_inizio and coalesce(rsm.validita_fine,now())
        and   tmod.data_cancellazione is null
        and   now()  BETWEEN tmod.validita_inizio and coalesce(tmod.validita_fine,now())
     ),
     -- 02.07.2018 Sofia jira siac-6193
     ord_modpag_no_cessione as
     (
		select
            rModpag.ord_id,
            tmod.modpag_id,
            tipo.accredito_tipo_code,
            tipo.accredito_tipo_desc,
            tmod.iban,
            tmod.bic,
            tmod.contocorrente,
            tmod.contocorrente_intestazione,
            tmod.banca_denominazione,
            tmod.quietanziante,
            tmod.quietanziante_codice_fiscale::varchar
        from  siac_r_ordinativo_modpag rModpag, siac_t_modpag tmod,  siac_d_accredito_tipo tipo
		where tipo.accredito_tipo_id = tmod.accredito_tipo_id
        and   rModpag.modpag_id=tmod.modpag_id        
        and   tmod.ente_proprietario_id = v_ente_proprietario_id        
        and   rModpag.data_cancellazione is null
        and   tmod.data_cancellazione is null
        and   tipo.data_cancellazione is null      
        and   rModpag.validita_fine is null
 		and   now()  BETWEEN tmod.validita_inizio and coalesce(tmod.validita_fine,now())
     ),
     -- 12.07.2018 Sofia jira siac-6193
     ord_soggetto_ord as
     (
     select rsog.ord_id,
            sog.soggetto_code ord_soggetto_code,
            sog.soggetto_desc ord_soggetto_desc
     from siac_r_ordinativo_soggetto rsog,
          siac_t_soggetto sog
     where sog.soggetto_id=rsog.soggetto_id
     and   sog.ente_proprietario_id = v_ente_proprietario_id
     and   sog.data_cancellazione is null
     and   rsog.data_cancellazione is null
     and   now()  BETWEEN rsog.validita_inizio and coalesce(rsog.validita_fine,now())
     )
     select ordi.*,
            ord_quietanza.ord_quietanza_data,
            -- 12.07.2018 Sofia jira siac-6193
            ord_soggetto_ord.ord_soggetto_code,
            ord_soggetto_ord.ord_soggetto_desc,
	        -- Accredito tipo - no cessione
    	    ord_modpag_no_cessione.accredito_tipo_code ord_accredito_tipo_code,
        	ord_modpag_no_cessione.accredito_tipo_desc ord_accredito_tipo_desc,
	        -- Modalita di pagamento
    	    -- IBAN
        	ord_modpag_no_cessione.iban ord_iban,
	        -- BIC
            ord_modpag_no_cessione.bic ord_bic,
	        -- contocorrente
            ord_modpag_no_cessione.contocorrente ord_contocorrente,
        	-- contocorrente_intestazione
            ord_modpag_no_cessione.contocorrente_intestazione ord_contocorrente_intestazione,
    	    -- banca_denominazione
        	ord_modpag_no_cessione.banca_denominazione ord_banca_denominazione,
	        -- quietanzante
    	    ord_modpag_no_cessione.quietanziante ord_quietanzante,
        	-- quietanzante_codice_fiscale
	        ord_modpag_no_cessione.quietanziante_codice_fiscale ord_quietanzante_codice_fiscale,
            -- MDP - cessione
            -- Estremi soggetto cessione
       		ord_modpag_cessione.soggetto_cessione_code ord_soggetto_cessione_code,
	        ord_modpag_cessione.soggetto_cessione_desc ord_soggetto_cessione_desc,
    	    -- Relazione Soggetto
	        ord_modpag_cessione.relaz_tipo_code ord_relaz_tipo_code,
        	ord_modpag_cessione.relaz_tipo_desc ord_relaz_tipo_desc,
            -- Accredito tipo -  CESSIONE
    	    ord_modpag_cessione.accredito_tipo_code ord_accredito_tipo_code_cess,
        	ord_modpag_cessione.accredito_tipo_desc ord_accredito_tipo_desc_cess,
	        -- Modalita di pagamento
    	    -- IBAN
        	ord_modpag_cessione.iban ord_iban_cess,
	        -- BIC
    	    ord_modpag_cessione.bic ord_bic_cess,
	        -- contocorrente
            ord_modpag_cessione.contocorrente ord_contocorrente_cess,
        	-- contocorrente_intestazione
            ord_modpag_cessione.contocorrente_intestazione ord_contocorrente_intestazione_cess,
    	    -- banca_denominazione
            ord_modpag_cessione.banca_denominazione ord_banca_denominazione_cess,
	        -- quietanzante
            ord_modpag_cessione.quietanziante ord_quietanzante_cess,
        	-- quietanzante_codice_fiscale
            ord_modpag_cessione.quietanziante_codice_fiscale ord_quietanzante_codice_fiscale_cess
     from siac_d_ordinativo_tipo tipo,
          ordi
          left join ord_quietanza on (ordi.ord_id=ord_quietanza.ord_id)
          left join ord_modpag_no_cessione on (ordi.ord_id=ord_modpag_no_cessione.ord_id)
          left join ord_modpag_cessione on (ordi.ord_id=ord_modpag_cessione.ord_id)
          -- 12.07.2018 Sofia jira siac-6193
          join ord_soggetto_ord on (ord_soggetto_ord.ord_id=ordi.ord_id)
     where tipo.ord_tipo_code='P'
     and   tipo.data_cancellazione is null
     and   ordi.ord_tipo_id=tipo.ord_tipo_id
     and   tipo.ente_proprietario_id = v_ente_proprietario_id
    )
	select
		liq.liq_id,
		liq.liq_anno,
		liq.liq_numero,
		liq.liq_desc,
		liq.liq_stato,
		liq.elem_id as uid_capitolo,
		liq.anno as capitolo_anno,
		liq.elem_code as capitolo_numero,
		liq.elem_code2 as capitolo_articolo,
		liq.elem_code3 as ueb_numero,
		liq.movgest_anno,
		liq.movgest_numero,
		liq.movgest_ts_code,
		liq.liq_importo,
		liq.soggetto_code,
		liq.soggetto_desc,
		liq.attoamm_numero,
		liq.attoamm_anno,
		liq.attoamm_oggetto,
		liq.attoamm_tipo_code,
		liq.attoamm_tipo_desc,
		liq.attoamm_stato_desc,
		sac.classif_code,
		sac.classif_desc,
        -- 02.07.2018 Sofia jira siac-6193
		ordinativo.ord_anno,
		ordinativo.ord_numero,
		ordinativo.ord_stato_code,
		ordinativo.ord_stato_desc,
        -- 02.07.2018 Sofia jira siac-6193
        liq.sog_codice_fiscale,
        liq.sog_partita_iva ,
        (CASE WHEN  coalesce(cartecont.esiste_carta,0)=0 THEN 'N'::varchar ELSE 'S'::varchar END )  carte_contabili ,
		-- Data di inserimento dell atto contabile (la medesima data che viene riportata in stampa dell'ALG)
        attoallegato.attoal_data_creazione,
        -- Data di scadenza dell atto contabile
        attoallegato.attoal_data_scadenza ,
        -- Stato dell atto contabile
		attoallegato.attoal_stato_desc,
        -- MDP non cessione
        -- Accredito tipo
		modpag_no_cessione.accredito_tipo_code,
        modpag_no_cessione.accredito_tipo_desc,
        -- Modalita di pagamento
        -- IBAN
        modpag_no_cessione.iban,
        -- BIC
        modpag_no_cessione.bic,
        -- contocorrente
        modpag_no_cessione.contocorrente,
        -- contocorrente_intestazione
        modpag_no_cessione.contocorrente_intestazione,
        -- banca_denominazione
        modpag_no_cessione.banca_denominazione,
        -- quietanzante
        modpag_no_cessione.quietanziante quietanzante,
        -- quietanzante_codice_fiscale
        modpag_no_cessione.quietanziante_codice_fiscale quietanzante_codice_fiscale,
        -- MDP cessione
        -- Estremi soggetto cessione
        modpag_cessione.soggetto_cessione_code,
        modpag_cessione.soggetto_cessione_desc,
        -- Relazione Soggetto
        modpag_cessione.relaz_tipo_code,
        modpag_cessione.relaz_tipo_desc,
        -- Accredito tipo -  CESSIONE
        modpag_cessione.accredito_tipo_code accredito_tipo_code_cess,
        modpag_cessione.accredito_tipo_desc accredito_tipo_desc_cess,
        -- Modalita di pagamento
        -- IBAN
        modpag_cessione.iban iban_cess,
        -- BIC
        modpag_cessione.bic bic_cess,
        -- contocorrente
        modpag_cessione.contocorrente contocorrente_cess,
        -- contocorrente_intestazione
        modpag_cessione.contocorrente_intestazione contocorrente_intestazione_cess,
        -- banca_denominazione
        modpag_cessione.banca_denominazione banca_denominazione_cess,
        -- quietanzante
        modpag_cessione.quietanziante quietanzante_cess,
        -- quietanzante_codice_fiscale
        modpag_cessione.quietanziante_codice_fiscale quietanzante_codice_fiscale_cess,
        (CASE WHEN  coalesce(split_liq.esiste_split,0)=0 THEN 'N'::varchar ELSE 'S'::varchar END )  liq_esiste_split ,
        -- Ordinativo
        -- La data di emissione ordinativo
        ordinativo.ord_emissione_data,
        -- La data di quietanza ordinativo
        ordinativo.ord_quietanza_data,
        -- 12.07.2018 Sofia jira siac-6193
        ordinativo.ord_soggetto_code,
        ordinativo.ord_soggetto_desc,
        -- MDP ordinativo - no cessione
        ordinativo.ord_accredito_tipo_code,
        ordinativo.ord_accredito_tipo_desc,
        ordinativo.ord_iban,
        ordinativo.ord_bic,
        ordinativo.ord_contocorrente,
        ordinativo.ord_contocorrente_intestazione,
        ordinativo.ord_banca_denominazione,
        ordinativo.ord_quietanzante,
        ordinativo.ord_quietanzante_codice_fiscale,
        -- MDP ordinativo - cessione
        -- Estremi soggetto cessione
        ordinativo.ord_soggetto_cessione_code,
        ordinativo.ord_soggetto_cessione_desc,
        -- Relazione soggetto cessione
        ordinativo.ord_relaz_tipo_code,
        ordinativo.ord_relaz_tipo_desc,
        -- MDP ordinativo
        ordinativo.ord_accredito_tipo_code_cess,
        ordinativo.ord_accredito_tipo_desc_cess,
        ordinativo.ord_iban_cess,
        ordinativo.ord_bic_cess,
        ordinativo.ord_contocorrente_cess,
        ordinativo.ord_contocorrente_intestazione_cess,
        ordinativo.ord_banca_denominazione_cess,
        ordinativo.ord_quietanzante_cess,
        ordinativo.ord_quietanzante_codice_fiscale_cess
	from liq
		 left outer join sac on liq.attoamm_id=sac.attoamm_id
	 	 left outer join ordinativo on ordinativo.liq_id = liq.liq_id
         -- 02.07.2018 Sofia jira siac-6193
         left outer join cartecont on liq.soggetto_id=cartecont.soggetto_id
         left outer join  split_liq on (liq.liq_id = split_liq.liq_id)
         left outer join  attoallegato on  (liq.attoamm_id = attoallegato.attoamm_id)
  	     left outer join  modpag_no_cessione on  (liq.liq_id =  modpag_no_cessione.liq_id)
         left outer join  modpag_cessione on ( liq.liq_id = modpag_cessione.liq_id)
	ORDER BY 2,3,5,7,8,9,10
	LIMIT _limit
	OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-6448 FINE

--SIAC-6433 inizio
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 
  tmp.azione_code,
  tmp.azione_desc,
  dat.azione_tipo_id,
  dga.gruppo_azioni_id,
  '/../siacbilapp/azioneRichiesta.do',
   FALSE,
    now(),
  dat.ente_proprietario_id,
  'admin'
FROM 
	 siac_d_azione_tipo dat
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = dat.ente_proprietario_id)
JOIN (VALUES
 ('OP-COM-StampaAttoAllegato', 'Stampa Atto Allegato', 'AZIONE_SECONDARIA', 'FIN_BASE1') 
) AS tmp(azione_code, azione_desc, azione_tipo_code, gruppo_azioni_code) ON (tmp.azione_tipo_code = dat.azione_tipo_code AND tmp.gruppo_azioni_code = dga.gruppo_azioni_code)
WHERE NOT EXISTS (
 SELECT 1
 FROM siac_t_azione ta
 WHERE ta.azione_code = tmp.azione_code
 AND ta.ente_proprietario_id = dat.ente_proprietario_id
 AND ta.data_cancellazione IS NULL
);
--SIAC-6433 fine

---CESPITI INIZIO
drop table if exists siac_t_cespiti_ammortamento_dett;
drop table if exists siac_t_cespiti_ammortamento;
CREATE TABLE IF NOT EXISTS siac_t_cespiti_ammortamento (
	ces_amm_id SERIAL,
	ces_id INTEGER NOT NULL,
	ces_amm_ultimo_anno_reg INTEGER,
	ces_amm_importo_tot_reg NUMERIC,
	ces_amm_completo boolean default false,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_ammortamento PRIMARY KEY(ces_amm_id),
	CONSTRAINT siac_t_cespiti_siac_t_cespiti_ammortamento FOREIGN KEY (ces_id)
		REFERENCES siac_t_cespiti(ces_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_ammortamento FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_ammortamento_fk_ente_proprietario_id_idx ON siac_t_cespiti_ammortamento
	USING btree (ente_proprietario_id);
CREATE INDEX siac_t_cespiti_ammortamento_fk_ces_id_idx ON siac_t_cespiti_ammortamento
	USING btree (ces_id);

CREATE TABLE IF NOT EXISTS siac_t_cespiti_ammortamento_dett (
	ces_amm_dett_id SERIAL,
	ces_amm_id INTEGER NOT NULL,
	ces_amm_dett_data TIMESTAMP NOT NULL,
	ces_amm_dett_anno INTEGER,
	ces_amm_dett_importo NUMERIC,
	pnota_id INTEGER,
	ente_proprietario_id INTEGER NOT NULL,
	validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
	validita_fine TIMESTAMP,
	data_creazione TIMESTAMP DEFAULT now() NOT NULL,
	data_modifica TIMESTAMP DEFAULT now() NOT NULL,
	data_cancellazione TIMESTAMP,
	login_operazione VARCHAR(200) NOT NULL,
	CONSTRAINT pk_siac_t_cespiti_ammortamento_dett PRIMARY KEY(ces_amm_dett_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_cespiti_ammortamento_dett FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_ammortamento_siac_t_cespiti_ammortamento_dett FOREIGN KEY (ces_amm_id)
		REFERENCES siac_t_cespiti_ammortamento(ces_amm_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE,
	CONSTRAINT siac_t_cespiti_ammortamento_dett_siac_t_prima_nota FOREIGN KEY (pnota_id)
		REFERENCES siac_t_prima_nota(pnota_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
		NOT DEFERRABLE
);

CREATE INDEX siac_t_cespiti_ammortamento_dett_fk_ente_proprietario_id_idx ON siac_t_cespiti_ammortamento_dett
	USING btree (ente_proprietario_id);
CREATE INDEX siac_t_cespiti_ammortamento_dett_fk_ces_amm_id_idx ON siac_t_cespiti_ammortamento_dett
	USING btree (ces_amm_id);
CREATE INDEX siac_t_cespiti_ammortamento_dett_fk_pnota_id_idx ON siac_t_cespiti_ammortamento_dett
	USING btree (pnota_id);

--CESPITI FINE


-- SIAC-6346 INIZIO

drop table if exists pagopa_bck_t_subdoc;

drop table if exists pagopa_bck_t_subdoc_attr;
drop table if exists pagopa_bck_t_subdoc_atto_amm;
drop table if exists pagopa_bck_t_subdoc_prov_cassa;
drop table if exists pagopa_bck_t_subdoc_movgest_ts;
drop table if exists pagopa_bck_t_doc_sog;
drop table if exists pagopa_bck_t_doc_stato;
drop table if exists pagopa_bck_t_doc_attr;
drop table if exists pagopa_bck_t_doc_class;
drop table if exists pagopa_bck_t_registrounico_doc;
drop table if exists pagopa_bck_t_subdoc_num;
drop table if exists pagopa_bck_t_doc;


drop table if exists pagopa_t_riconciliazione_doc;
drop table if exists pagopa_t_elaborazione_flusso;
drop table if exists pagopa_t_riconciliazione;
drop table if exists pagopa_r_elaborazione_file;
drop table if exists pagopa_t_elaborazione;
drop table if exists siac_t_file_pagopa;
drop table if exists pagopa_d_elaborazione_stato;
drop table if exists siac_d_file_pagopa_stato;
drop table if exists pagopa_d_riconciliazione_errore;

-- pagopa_d_riconciliazione_errore

CREATE TABLE pagopa_d_riconciliazione_errore (
  pagopa_ric_errore_id SERIAL,
  pagopa_ric_errore_code VARCHAR(200) NOT NULL,
  pagopa_ric_errore_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_d_ric_errore PRIMARY KEY(pagopa_ric_errore_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_d_ric_errore FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_pagopa_d_ric_errore_1 ON pagopa_d_riconciliazione_errore
  USING btree (pagopa_ric_errore_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX pagopa_d_ric_errore_stato_fk_ente_proprietario_id_idx ON pagopa_d_riconciliazione_errore
  USING btree (ente_proprietario_id);



-- siac_d_file_pagopo_stato
CREATE TABLE siac_d_file_pagopa_stato (
  file_pagopa_stato_id SERIAL,
  file_pagopa_stato_code VARCHAR(200) NOT NULL,
  file_pagopa_stato_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_file_pagopa_stato PRIMARY KEY(file_pagopa_stato_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_file_pagopa_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_siac_d_file_pagopa_stato_1 ON siac_d_file_pagopa_stato
  USING btree (file_pagopa_stato_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX siac_d_file_pagopa_stato_fk_ente_proprietario_id_idx ON siac_d_file_pagopa_stato
  USING btree (ente_proprietario_id);



-- siac_t_file_pagopa
CREATE TABLE siac_t_file_pagopa (
  file_pagopa_id SERIAL,
  file_pagopa_size NUMERIC NOT NULL,
  file_pagopa BYTEA,
  file_pagopa_code VARCHAR NOT NULL,
  file_pagopa_note VARCHAR,
  file_pagopa_anno integer not NULL,
  file_pagopa_stato_id INTEGER NOT NULL,
  file_pagopa_errore_id integer,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_t_file_pagopa PRIMARY KEY(file_pagopa_id),
  CONSTRAINT siac_d_file_pagopa_stato_siac_t_file_pagopa FOREIGN KEY (file_pagopa_stato_id)
    REFERENCES siac_d_file_pagopa_stato(file_pagopa_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconciliazione_errore_siac_t_file_pagopa FOREIGN KEY (file_pagopa_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_t_file_pagopa FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac_t_file_pagopa
IS 'Tabella di archivio file XML riconciliazione PAGOPA';

CREATE INDEX siac_t_file_pagopa_fk_ente_proprietario_id_idx ON siac_t_file_pagopa
  USING btree (ente_proprietario_id);

CREATE INDEX siac_t_file_pagopa_fk_file_pagopa_stato_id_idx ON siac_t_file_pagopa
  USING btree (file_pagopa_stato_id);

-- pagopa_d_elaborazione_stato
CREATE TABLE pagopa_d_elaborazione_stato (
  pagopa_elab_stato_id SERIAL,
  pagopa_elab_stato_code VARCHAR(200) NOT NULL,
  pagopa_elab_stato_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_d_elab_stato PRIMARY KEY(pagopa_elab_stato_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_d_elaborazione_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX idx_pagopa_d_elaborazione_stato_1 ON pagopa_d_elaborazione_stato
  USING btree (pagopa_elab_stato_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

CREATE INDEX pagopa_d_elaborazione_stato_fk_ente_proprietario_id_idx ON pagopa_d_elaborazione_stato
  USING btree (ente_proprietario_id);

-- pagopa_t_elaborazione

CREATE TABLE pagopa_t_elaborazione (
  pagopa_elab_id SERIAL,
  pagopa_elab_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_elab_stato_id INTEGER NOT NULL,
  pagopa_elab_note VARCHAR(1500) NOT NULL,
  pagopa_elab_file_id  varchar(250),
  pagopa_elab_file_ora varchar(250),
  pagopa_elab_file_ente varchar(250),
  pagopa_elab_file_fruitore varchar(250),
  file_pagopa_id   integer  null,
  pagopa_elab_errore_id integer,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_elaborazione PRIMARY KEY(pagopa_elab_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_t_elaborazione FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elaborazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_elaborazione_stato_pagopa_t_elaborazione FOREIGN KEY (pagopa_elab_stato_id)
    REFERENCES pagopa_d_elaborazione_stato(pagopa_elab_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconciliazione_errore_pagopa_t_elaborazione FOREIGN KEY (pagopa_elab_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_elaborazione
IS 'Tabella di elaborazione dei file XML riconciliazione PAGOPO';



COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_id
IS 'Identificativo file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_ora
IS 'Ora generazione file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_ente
IS 'Codice Ente file  XML';

COMMENT ON COLUMN pagopa_t_elaborazione.pagopa_elab_file_fruitore
IS 'Codice Fruitore file XML';

COMMENT ON COLUMN pagopa_t_elaborazione.file_pagopa_id
IS 'Identificativo file XML in siac_t_file_pagopa.';


CREATE INDEX pagopa_t_elaborazione_fk_ente_proprietario_id_idx ON pagopa_t_elaborazione
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_elaborazione_fk_pagopa_elab_stato_id_idx ON pagopa_t_elaborazione
  USING btree (pagopa_elab_stato_id);


CREATE INDEX pagopa_t_elaborazione_fk_siac_t_file_pagopa_idx ON pagopa_t_elaborazione
  USING btree (file_pagopa_id);


CREATE TABLE pagopa_r_elaborazione_file (
  pagopa_r_elab_id SERIAL,
  pagopa_elab_id integer not null,
  file_pagopa_id   integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_r_elaborazione_file PRIMARY KEY(pagopa_r_elab_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_r_elaborazione_file FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_r_elaborazione_file FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_r_elaborazione_file FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_r_elaborazione_file
IS 'Tabella di relazione tra PAGOPA file XML e PAGOPA elaborazione.';

COMMENT ON COLUMN pagopa_r_elaborazione_file.pagopa_elab_id
IS 'Identificativo elaborazione';

COMMENT ON COLUMN pagopa_r_elaborazione_file.file_pagopa_id
IS 'Identificativo file XML';


CREATE INDEX pagopa_r_elaborazione_file_fk_ente_proprietario_id_idx ON pagopa_r_elaborazione_file
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_r_elaborazione_file_fk_file_pagopa_id_idx ON pagopa_r_elaborazione_file
  USING btree (file_pagopa_id);



CREATE INDEX pagopa_r_elaborazione_file_fk_pagopa_elab_id_idx ON pagopa_r_elaborazione_file
USING btree (pagopa_elab_id); 

--pagopa_t_riconciliazione



CREATE TABLE pagopa_t_riconciliazione (
  pagopa_ric_id SERIAL,
  pagopa_ric_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  -- XML - inizio
  -- intestazione XML
  pagopa_ric_file_id  varchar,
  pagopa_ric_file_ora varchar,
  pagopa_ric_file_ente varchar,
  pagopa_ric_file_fruitore varchar,
  pagopa_ric_file_num_flussi integer,
  pagopa_ric_file_tot_flussi varchar,
  -- intestazione FLUSSO
  pagopa_ric_flusso_id  varchar,
  pagopa_ric_flusso_nome_mittente  varchar,
  pagopa_ric_flusso_data  varchar,
  pagopa_ric_flusso_tot_pagam  varchar,
  pagopa_ric_flusso_anno_esercizio  integer,
  pagopa_ric_flusso_anno_provvisorio  integer,
  pagopa_ric_flusso_num_provvisorio  integer,
  -- dettaglio flusso
  pagopa_ric_flusso_voce_code  varchar,
  pagopa_ric_flusso_voce_desc  varchar,
  pagopa_ric_flusso_tematica varchar,
  pagopa_ric_flusso_sottovoce_code  varchar,
  pagopa_ric_flusso_sottovoce_desc  varchar,
  pagopa_ric_flusso_sottovoce_importo  varchar,
  pagopa_ric_flusso_anno_accertamento  integer,
  pagopa_ric_flusso_num_accertamento  integer,
  pagopa_ric_flusso_num_capitolo  integer,
  pagopa_ric_flusso_num_articolo  integer,
  pagopa_ric_flusso_pdc_v_fin  varchar,
  pagopa_ric_flusso_titolo  varchar,
  pagopa_ric_flusso_tipologia varchar,
  pagopa_ric_flusso_categoria  varchar,
  pagopa_ric_flusso_codice_benef  varchar,
  pagopa_ric_flusso_str_amm  varchar,
  -- XML - fine
  file_pagopa_id integer not null,
  pagopa_ric_flusso_stato_elab varchar default 'N' not null ,
  pagopa_ric_errore_id integer, -- riferimento errore_id in caso di errore
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_riconciliazione PRIMARY KEY(pagopa_ric_id),
  CONSTRAINT siac_t_file_pagopa_pagopa_t_riconciliazione FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_ric_err_pagopa_t_riconciliazione FOREIGN KEY (pagopa_ric_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_riconciliazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_riconciliazione
IS 'Tabella di tracciatura piatta dati presenti in  file XML riconciliazione PAGOPO';



COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_id
IS 'Identificativo XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_ora
IS 'Ora generazione file complessivo XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_ente
IS 'Codice Ente file  XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_fruitore
IS 'Codice Fruitore file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_num_flussi
IS 'Numero di flussi contenuti in file XML';


COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_file_tot_flussi
IS 'Totale dei flussi contenuti in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_id
IS 'Identificativo flusso contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio
IS 'Anno esercizio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_provvisorio
IS 'Anno provvisorio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_num_provvisorio
IS 'Numero provvisorio di riferimento del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_voce_code
IS 'Codice voce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_sottovoce_code
IS 'Codice sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_sottovoce_importo
IS 'Importo dettaglio  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_anno_accertamento
IS 'Anno accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_num_accertamento
IS 'Numero accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';



COMMENT ON COLUMN pagopa_t_riconciliazione.file_pagopa_id
IS 'Identificativo file XML in siac_t_file_pagopa.';


COMMENT ON COLUMN pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab
IS 'Stato di elaborazione del singolo dettaglio  - dettaglio del singolo flusso  contenuto in file XML - [N-No S-Si E-Err X-Scarto]';


CREATE INDEX pagopa_t_riconciliazione_ric_file_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_file_id);

CREATE INDEX pagopa_t_riconciliazione_ric_flusso_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_provvisorio_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_anno_esercizio,pagopa_ric_flusso_anno_provvisorio,pagopa_ric_flusso_num_provvisorio,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_voce_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_voce_code,
  			   pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_sottovoce_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_sottovoce_code,
               pagopa_ric_flusso_voce_code,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_accertamento_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_flusso_anno_esercizio,pagopa_ric_flusso_anno_accertamento,pagopa_ric_flusso_num_accertamento,
               pagopa_ric_file_id,pagopa_ric_flusso_id);

CREATE INDEX pagopa_t_riconciliazione_fk_file_pagopa_id_idx ON pagopa_t_riconciliazione
  USING btree (file_pagopa_id);

CREATE INDEX pagopa_t_riconciliazione_fk_ente_proprietario_id_idx ON pagopa_t_riconciliazione
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_riconciliazione_ric_errore_id_idx ON pagopa_t_riconciliazione
  USING btree (pagopa_ric_errore_id);



-- pagopa_t_elaborazione_flusso
CREATE TABLE pagopa_t_elaborazione_flusso (
  pagopa_elab_flusso_id SERIAL,
  pagopa_elab_flusso_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_elab_flusso_stato_id INTEGER NOT NULL,
  pagopa_elab_flusso_note VARCHAR(750) NOT NULL,
  pagopa_elab_ric_flusso_id  varchar,
  pagopa_elab_flusso_nome_mittente  varchar,
  pagopa_elab_ric_flusso_data  varchar,
  pagopa_elab_flusso_tot_pagam  varchar,
  pagopa_elab_flusso_anno_esercizio  integer,
  pagopa_elab_flusso_anno_provvisorio  integer,
  pagopa_elab_flusso_num_provvisorio  integer,
  pagopa_elab_flusso_provc_id  integer,
  pagopa_elab_id  integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_elaborazione_flusso PRIMARY KEY(pagopa_elab_flusso_id),
  CONSTRAINT pagopa_t_elaborazione_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_flusso_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_elab_flusso FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_elaborazione_stato_pagopa_t_elab_flusso FOREIGN KEY (pagopa_elab_flusso_stato_id)
    REFERENCES pagopa_d_elaborazione_stato(pagopa_elab_stato_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_elaborazione_flusso
IS 'Tabella di elaborazione del singolo flusso riconciliazione PAGOPO contenuto nel file XML ';



COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_ric_flusso_id
IS 'Identificativo flusso riconciliazione PAGOPO nel file XML';

COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_ric_flusso_data
IS 'Ora generazione flusso riconciliazione PAGOPO nel file XML';

COMMENT ON COLUMN pagopa_t_elaborazione_flusso.pagopa_elab_id
IS 'Identificativo elaborazione file XML in pagopa_t_elaborazione.';


CREATE INDEX pagopa_t_elaborazione_flusso_fk_ente_proprietario_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (ente_proprietario_id);

CREATE INDEX pagopa_t_elaborazione_flusso_fk_pagopa_elab_stato_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_stato_id);


CREATE INDEX pagopa_t_elaborazione_flusso_fk_pagopa_t_elab_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_id);

CREATE INDEX pagopa_t_elaborazione_flusso_pagopa_elab_ric_flusso_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_ric_flusso_id);


CREATE INDEX pagopa_t_elaborazione_flusso_provvisorio_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_anno_esercizio,pagopa_elab_flusso_anno_provvisorio,pagopa_elab_flusso_num_provvisorio,
               pagopa_elab_ric_flusso_id);

CREATE INDEX pagopa_t_elaborazione_flusso_provvisorio_id_idx ON pagopa_t_elaborazione_flusso
  USING btree (pagopa_elab_flusso_provc_id);




-- pagopa_t_riconciliazione_doc
CREATE TABLE pagopa_t_riconciliazione_doc (
  pagopa_ric_doc_id SERIAL,
  pagopa_ric_doc_data TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  pagopa_ric_doc_voce_code  varchar,
  pagopa_ric_doc_voce_desc  varchar,
  pagopa_ric_doc_voce_tematica  varchar,
  pagopa_ric_doc_sottovoce_code  varchar,
  pagopa_ric_doc_sottovoce_desc  varchar,
  pagopa_ric_doc_sottovoce_importo  numeric,
  pagopa_ric_doc_anno_esercizio  integer,
  pagopa_ric_doc_anno_accertamento  integer,
  pagopa_ric_doc_num_accertamento  integer,
  pagopa_ric_doc_num_capitolo  integer,
  pagopa_ric_doc_num_articolo  integer,
  pagopa_ric_doc_pdc_v_fin  varchar,
  pagopa_ric_doc_titolo  varchar,
  pagopa_ric_doc_tipologia varchar,
  pagopa_ric_doc_categoria  varchar,
  pagopa_ric_doc_codice_benef  varchar,
  pagopa_ric_doc_str_amm  varchar,
  -- identificativi contabilia - associati dopo elaborazione
  pagopa_ric_doc_subdoc_id integer,
  pagopa_ric_doc_provc_id integer,
  pagopa_ric_doc_movgest_ts_id integer,
  pagopa_ric_doc_stato_elab varchar default 'N' not null ,
  pagopa_ric_errore_id integer, -- riferimento errore_id in caso di errore
  pagopa_ric_id  integer, -- riferimento t_riconciliazione
  pagopa_elab_flusso_id integer, -- riferimento t_elaborazione_flusso
    -- XML - fine
  file_pagopa_id integer not null,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_t_riconciliazione_doc PRIMARY KEY(pagopa_ric_doc_id),
  CONSTRAINT pagopa_t_elaborazione_flusso_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_elab_flusso_id)
    REFERENCES pagopa_t_elaborazione_flusso(pagopa_elab_flusso_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_riconciliazione_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_id)
    REFERENCES pagopa_t_riconciliazione(pagopa_ric_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
 CONSTRAINT siac_t_file_pagopa_pagopa_t_riconciliazione_doc FOREIGN KEY (file_pagopa_id)
    REFERENCES siac_t_file_pagopa(file_pagopa_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_movgest_ts_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_doc_movgest_ts_id)
    REFERENCES siac_t_movgest_ts(movgest_ts_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_doc_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_d_riconc_err_t_riconciliazione_doc FOREIGN KEY (pagopa_ric_errore_id)
    REFERENCES pagopa_d_riconciliazione_errore(pagopa_ric_errore_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_pagopa_t_riconciliazione_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_t_riconciliazione_doc
IS 'Tabella di elaborazione dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_id
IS 'Riferimento identificativo relativo dettaglio in pagopa_t_riconciliazione';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_elab_flusso_id
IS 'Riferimento identificativo elaborazione flusso in pagopa_t_elaborazione_flusso';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_subdoc_id
IS 'Riferimento identificativo subdocumento emesso in Contabilia';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_movgest_ts_id
IS 'Riferimento identificativo accertamento Contabilia collegato';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_provc_id
IS 'Riferimento identificativo provvisorio di cassa Contabilia collegato';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_anno_esercizio
IS 'Anno esercizio di riferimento';


COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_voce_code
IS 'Codice voce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_sottovoce_code
IS 'Codice sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_sottovoce_importo
IS 'Importo dettaglio  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_anno_accertamento
IS 'Anno accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_num_accertamento
IS 'Numero accertamento di riferimento della  sottovoce di pagamento - dettaglio del singolo flusso  contenuto in file XML';

COMMENT ON COLUMN pagopa_t_riconciliazione_doc.pagopa_ric_doc_stato_elab
IS 'Stato di elaborazione del singolo dettaglio  - dettaglio del singolo flusso  contenuto in file XML - [N-No S-Si E-Err X-Scarto]';


CREATE INDEX pagopa_t_riconciliazione_doc_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_id);

CREATE INDEX pagopa_t_riconciliazione_doc_flusso_elab_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_elab_flusso_id);


CREATE INDEX pagopa_t_riconciliazione_doc_sottovoce_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_sottovoce_code,
               pagopa_ric_doc_voce_code);

CREATE INDEX pagopa_t_riconciliazione_doc_accertamento_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_anno_esercizio,pagopa_ric_doc_anno_accertamento,pagopa_ric_doc_num_accertamento);

CREATE INDEX pagopa_t_riconciliazione_doc_subdoc_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_subdoc_id);

CREATE INDEX pagopa_t_riconciliazione_doc_movgest_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_movgest_ts_id);

CREATE INDEX pagopa_t_riconciliazione_doc_provc_idx ON pagopa_t_riconciliazione_doc
  USING btree (pagopa_ric_doc_provc_id);


CREATE INDEX pagopa_t_riconciliazione_doc_fk_ente_proprietario_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (ente_proprietario_id);


CREATE INDEX pagopa_t_riconciliazione_doc_fk_file_pagopa_id_idx ON pagopa_t_riconciliazione_doc
  USING btree (file_pagopa_id);

-------------------------- BACKUP



CREATE TABLE pagopa_bck_t_subdoc
(
  pagopa_bck_subdoc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_id integer,
  subdoc_numero INTEGER,
  subdoc_desc VARCHAR(500),
  subdoc_importo NUMERIC,
  subdoc_nreg_iva VARCHAR(500),
  subdoc_data_scadenza TIMESTAMP WITHOUT TIME ZONE,
  subdoc_convalida_manuale CHAR(1),
  subdoc_importo_da_dedurre NUMERIC,
  subdoc_splitreverse_importo NUMERIC,
  subdoc_pagato_cec BOOLEAN,
  subdoc_data_pagamento_cec TIMESTAMP WITHOUT TIME ZONE,
  contotes_id INTEGER,
  dist_id INTEGER,
  comm_tipo_id INTEGER,
  doc_id INTEGER NOT NULL,
  subdoc_tipo_id INTEGER NOT NULL,
  notetes_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  bck_login_creazione VARCHAR(200),
  bck_login_modifica VARCHAR(200),
  bck_login_cancellazione VARCHAR(200),
  siope_tipo_debito_id INTEGER,
  siope_assenza_motivazione_id INTEGER,
  siope_scadenza_motivo_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc PRIMARY KEY(pagopa_bck_subdoc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc
IS 'Tabella di backup siac_t_subdoc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_bck_subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_subdoc_id_idx ON pagopa_bck_t_subdoc
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_elab_id_idx ON pagopa_bck_t_subdoc
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_attr
(
  pagopa_bck_subdoc_attr_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_attr_id integer,
  subdoc_id INTEGER,
  attr_id INTEGER,
  tabella_id integer,
  "boolean" CHAR(1),
  percentuale NUMERIC,
  testo VARCHAR(500),
  numerico NUMERIC,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_attr PRIMARY KEY(pagopa_bck_subdoc_attr_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_attr FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_attr FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_attr FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_attr
IS 'Tabella di backup siac_r_subdoc_attr per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_attr.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_attr.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_attr_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_bck_subdoc_attr_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_subdoc_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_provc_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_attr_elab_id_idx ON pagopa_bck_t_subdoc_attr
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_atto_amm
(
  pagopa_bck_subdoc_attoamm_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  subdoc_atto_amm_id integer,
  subdoc_id INTEGER,
  attoamm_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_atto_amm PRIMARY KEY(pagopa_bck_subdoc_attoamm_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_attoamm FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_subdoc_atto_amm
IS 'Tabella di backup siac_r_subdoc_atto_amm per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_atto_amm.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_atto_amm.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_attoamm_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_bck_subdoc_attoamm_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_subdoc_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_provc_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_attoamm_elab_id_idx ON pagopa_bck_t_subdoc_atto_amm
  USING btree (pagopa_elab_id);

create table pagopa_bck_t_subdoc_prov_cassa
(
  pagopa_bck_subdoc_provc_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  subdoc_provc_id integer,
  subdoc_id INTEGER,
  provc_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_provc PRIMARY KEY(pagopa_bck_subdoc_provc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_provc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_provc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_provc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_prov_cassa
IS 'Tabella di backup siac_r_subdoc_prov_cassa per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_prov_cassa.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_prov_cassa.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_provc_subdoc_provc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_bck_subdoc_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_subdoc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_provc_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_provc_elab_id_idx ON pagopa_bck_t_subdoc_prov_cassa
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_subdoc_movgest_ts
(
  pagopa_bck_subdoc_movgest_ts_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  subdoc_movgest_ts_id integer,
  subdoc_id INTEGER,
  movgest_ts_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_subdoc_mov PRIMARY KEY(pagopa_bck_subdoc_movgest_ts_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_mov FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_subdoc_mov FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_mov FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_subdoc_movgest_ts
IS 'Tabella di backup siac_r_subdoc_movgest_ts per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_movgest_ts.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_movgest_ts.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_movgest_ts_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_bck_subdoc_movgest_ts_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_subdoc_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (subdoc_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_provc_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_mov_elab_id_idx ON pagopa_bck_t_subdoc_movgest_ts
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_sog
(
  pagopa_bck_doc_sog_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  doc_sog_id integer,
  doc_id INTEGER,
  soggetto_id INTEGER,
  ruolo_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_sog PRIMARY KEY(pagopa_bck_doc_sog_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_sog FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_sog FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_sog FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_sog
IS 'Tabella di backup siac_r_doc_sog per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_sog.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_sog.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_sog_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_bck_doc_sog_id);

CREATE INDEX pagopa_bck_t_doc_sog_doc_id_idx ON pagopa_bck_t_doc_sog
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_sog_provc_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_sog_elab_id_idx ON pagopa_bck_t_doc_sog
  USING btree (pagopa_elab_id);

create TABLE pagopa_bck_t_doc_stato
(
  pagopa_bck_doc_stato_r_id serial,
  pagopa_provc_id integer,
  pagopa_elab_id integer,
  doc_stato_r_id integer,
  doc_id INTEGER,
  doc_stato_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_stato PRIMARY KEY(pagopa_bck_doc_stato_r_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_stato FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_stato FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_stato FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_stato
IS 'Tabella di backup siac_r_doc_stato per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_stato.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_stato.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_stato_stato_r_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_bck_doc_stato_r_id);

CREATE INDEX pagopa_bck_t_doc_stato_doc_id_idx ON pagopa_bck_t_doc_stato
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_stato_provc_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_stato_elab_id_idx ON pagopa_bck_t_doc_stato
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_attr
(
  pagopa_bck_doc_attr_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_attr_id integer,
  doc_id INTEGER,
  attr_id INTEGER,
  tabella_id integer,
  "boolean" CHAR(1),
  percentuale NUMERIC,
  testo VARCHAR(500),
  numerico NUMERIC,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_attr PRIMARY KEY(pagopa_bck_doc_attr_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_attr FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_attr FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_attr FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_attr
IS 'Tabella di backup siac_r_doc_attr per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_attr.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_attr.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_attr_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_bck_doc_attr_id);

CREATE INDEX pagopa_bck_t_doc_attr_doc_id_idx ON pagopa_bck_t_doc_attr
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_attr_provc_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_attr_elab_id_idx ON pagopa_bck_t_doc_attr
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc_class
(
  pagopa_bck_doc_classif_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_classif_id integer,
  doc_id INTEGER,
  classif_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc_class PRIMARY KEY(pagopa_bck_doc_classif_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_doc_class FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc_class FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc_class FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


COMMENT ON TABLE pagopa_bck_t_doc_class
IS 'Tabella di backup siac_r_doc_class per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc_class.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc_Class.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_classif_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_bck_doc_classif_id);

CREATE INDEX pagopa_bck_t_doc_class_doc_id_idx ON pagopa_bck_t_doc_class
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_class_provc_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_class_elab_id_idx ON pagopa_bck_t_doc_class
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_registrounico_doc
(
  pagopa_bck_rudoc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  rudoc_id integer,
  rudoc_registrazione_anno INTEGER,
  rudoc_registrazione_numero INTEGER,
  rudoc_registrazione_data TIMESTAMP WITHOUT TIME ZONE,
  doc_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione  VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione  VARCHAR(200) NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_reg_doc PRIMARY KEY(pagopa_bck_rudoc_id),
  CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_reg_doc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_reg_doc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_reg_doc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE

)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_registrounico_doc
IS 'Tabella di backup siac_t_registrounico_doc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_registrounico_doc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_registrounico_doc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_reg_doc_rudoc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_bck_rudoc_id);

CREATE INDEX pagopa_bck_t_doc_reg_doc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_reg_doc_provc_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_reg_doc_elab_id_idx ON pagopa_bck_t_registrounico_doc
  USING btree (pagopa_elab_id);

create table pagopa_bck_t_subdoc_num
(
   pagopa_bck_subdoc_num_id	 serial,
   pagopa_provc_id integer not null,
   pagopa_elab_id integer not null,
   subdoc_num_id integer,
   doc_id INTEGER,
   subdoc_numero INTEGER,
   bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
   bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
   bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
   bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
   bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
   bck_login_operazione  VARCHAR(200),
   validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
   validita_fine TIMESTAMP WITHOUT TIME ZONE,
   ente_proprietario_id INTEGER NOT NULL,
   data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
   data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
   data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
   login_operazione  VARCHAR(200) NOT NULL,
   CONSTRAINT pk_pagopa_bck_t_subdoc_num PRIMARY KEY(pagopa_bck_subdoc_num_id),
   CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_num FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_sudoc_num FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_subdoc_num FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_subdoc_num
IS 'Tabella di backup pagopa_bck_t_subdoc_num per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_subdoc_num.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_subdoc_num.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_subdoc_num_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_bck_subdoc_num_id);

CREATE INDEX pagopa_bck_t_subdoc_num_doc_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_subdoc_num_provc_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_subdoc_num_elab_id_idx ON pagopa_bck_t_subdoc_num
  USING btree (pagopa_elab_id);


create table pagopa_bck_t_doc
(
  pagopa_bck_doc_id serial,
  pagopa_provc_id integer not null,
  pagopa_elab_id integer not null,
  doc_id integer,
  doc_anno INTEGER,
  doc_numero VARCHAR(200),
  doc_desc VARCHAR(500),
  doc_importo NUMERIC,
  doc_beneficiariomult BOOLEAN,
  doc_data_emissione TIMESTAMP WITHOUT TIME ZONE,
  doc_data_scadenza TIMESTAMP WITHOUT TIME ZONE,
  doc_tipo_id INTEGER,
  codbollo_id INTEGER,
  bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  bck_data_creazione TIMESTAMP WITHOUT TIME ZONE,
  bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  bck_data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  bck_login_operazione VARCHAR(200),
  bck_login_creazione VARCHAR(200),
  bck_login_modifica VARCHAR(200),
  bck_login_cancellazione VARCHAR,
  pcccod_id INTEGER,
  pccuff_id INTEGER,
  doc_collegato_cec BOOLEAN,
  doc_contabilizza_genpcc BOOLEAN,
  siope_documento_tipo_id INTEGER,
  siope_documento_tipo_analogico_id INTEGER,
  doc_sdi_lotto_siope VARCHAR(200),
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  ente_proprietario_id INTEGER NOT NULL,
  CONSTRAINT pk_pagopa_bck_t_doc PRIMARY KEY(pagopa_bck_doc_id),
   CONSTRAINT siac_t_ente_proprietario_pagopa_bck_t_subdoc_num FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT siac_t_prov_cassa_pagopa_bck_t_doc FOREIGN KEY (pagopa_provc_id)
    REFERENCES siac_t_prov_cassa(provc_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT pagopa_t_elaborazione_pagopa_bck_t_doc FOREIGN KEY (pagopa_elab_id)
    REFERENCES pagopa_t_elaborazione(pagopa_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE pagopa_bck_t_doc
IS 'Tabella di backup pagopa_bck_t_doc per elaborazione e provvisorio di cassa dati di riconciliazione PAGOPO';


COMMENT ON COLUMN pagopa_bck_t_doc.pagopa_provc_id
IS 'Riferimento identificativo relativo dettaglio provvisorio di cassa';


COMMENT ON COLUMN pagopa_bck_t_doc.pagopa_elab_id
IS 'Riferimento identificativo relativo dettaglio elaborazione id';


CREATE INDEX pagopa_bck_t_doc_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_bck_doc_id);

CREATE INDEX pagopa_bck_t_doc_doc_id_idx ON pagopa_bck_t_doc
  USING btree (doc_id);

CREATE INDEX pagopa_bck_t_doc_provc_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_provc_id);

CREATE INDEX pagopa_bck_t_doc_elab_id_idx ON pagopa_bck_t_doc
  USING btree (pagopa_elab_id);
  
/*ACQUISITO	ACQUISITO IN ATTESA DI ELABORAZIONE
ELBORATO_IN_CORSO ELABORIAZIONE IN CORSO - FLUSSI IN FASE DI ELABORAZIONE
RIFIUTATO	RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE
ELABORATO_OK	ELABORATO CON ESITO POSITIVO
ELABORATO_ERRATO	ELABORATO CON ESITO ERRATO
ELABORATO_SCARTATO	ELABORATO CON ESITO ERRATO - RIELABORABILE
ANNULLATO	ANNULLATO*/


-- pagopa_d_elaborazione_stato
insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ACQUISITO',
 'ACQUISITO IN ATTESA DI ELABORAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ACQUISITO');


insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'RIFIUTATO',
 'RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='RIFIUTATO');


insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO',
 'ELABORAZIONE IN CORSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_ER',
 'ELABORAZIONE IN CORSO CON ESITI ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO_ER');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_SC',
 'ELABORAZIONE IN CORSO CON ESITI SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_IN_CORSO_SC');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_OK',
 'ELABORATO CON ESITO POSITIVO - DOCUMENTI EMESSI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_OK');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_KO',
 'ELABORATO CON ESITO ERRATO -  DOCUMENTI EMESSI - PRESENZA ERRORI - SCARTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists    
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_KO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_ERRATO',
 'ELABORATO CON ESITO ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_ERRATO');


insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_SCARTATO',
 'ELABORATO CON ESITO SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ELABORATO_SCARTATO');

insert into pagopa_d_elaborazione_stato
(
 pagopa_elab_stato_code,
 pagopa_elab_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ANNULLATO',
 'ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_elaborazione_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.pagopa_elab_stato_code='ANNULLATO');

-- siac_d_file_pagopa_stato

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ACQUISITO',
 'ACQUISITO IN ATTESA DI ELABORAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ACQUISITO');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'RIFIUTATO',
 'RIFIUTATO PER ERRORI IN FASE DI ACQUISIZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='RIFIUTATO');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO',
 'ELABORAZIONE IN CORSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_ER',
 'ELABORAZIONE IN CORSO CON ESITI ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO_ER');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_IN_CORSO_SC',
 'ELABORAZIONE IN CORSO CON ESITI SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_IN_CORSO_SC');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_OK',
 'ELABORATO CON ESITO POSITIVO -  DOCUMENTI EMESSI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_OK');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_KO',
 'ELABORATO CON ESITO ERRATO -  DOCUMENTI EMESSI - PRESENZA ERRORI - SCARTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_KO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_ERRATO',
 'ELABORATO CON ESITO ERRATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_ERRATO');


insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ELABORATO_SCARTATO',
 'ELABORATO CON ESITO SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ELABORATO_SCARTATO');

insert into siac_d_file_pagopa_stato
(
 file_pagopa_stato_code,
 file_pagopa_stato_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 'ANNULLATO',
 'ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from siac_d_file_pagopa_stato stato
 where stato.ente_proprietario_id=ente.ente_proprietario_id and stato.file_pagopa_stato_code='ANNULLATO');


/*1	ANNULLATO
2	SCARTATO
3	ERRORE GENERICO
4	FILE NON ESISTENTE O STATO NON RICHIESTO
5	FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
6	DATI DI RICONCILIAZIONE NON PRESENTI
7	DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
8	DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
9	DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
10	DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
11	DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
12	DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
13	DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
14	DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
15	DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
16	DATI DI RICONCILIAZIONE SENZA IMPORTO
17	ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
18	ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
19	ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
20	DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
21	ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
22	DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
23	DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
24	TIPO DOCUMENTO IPA NON ESISTENTE*/


select *    from pagopa_d_riconciliazione_errore
where ente_proprietario_id=2;
 --- pagopa_d_riconciliazione_errore

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '1','ANNULLATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='1');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '2','SCARTATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='2');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '3','ERRORE GENERICO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='3');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '4','FILE NON ESISTENTE O STATO NON RICHIESTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='4');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '5','FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='5');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '6','DATI DI RICONCILIAZIONE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='6');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '7','DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='7');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '8','DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='8');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '9','DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='9');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '10','DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='10');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '11','DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='11');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '12','DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='12');



insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '13','DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='13');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '14','DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='14');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '15','DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='15');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '16','DATI DI RICONCILIAZIONE SENZA IMPORTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='16');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '17','ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='17');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '18','ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='18');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '19','ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='19');



insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '20','DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='20');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '21','ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='21');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '22','DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='22');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '23','DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='23');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '24','TIPO DOCUMENTO IPA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='24');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '25','BOLLO ESENTE NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='25');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '26','ERRORE IN LETTURA ID. STATO DOCUMENTO VALIDO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='26');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '27','ERRORE IN LETTURA ID. TIPO CDC-CDR',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='27');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '28','IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='28');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '29','IDENTIFICATIVI VARI INESISTENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='29');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '30','ERRORE IN FASE DI INSERIMENTO DOCUMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='30');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '31','ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='31');

 insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '32','ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='32');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '33','DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='33');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '34','DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='34');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '35','DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='35');

insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '36','DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='36');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '37','ERRORE IN LETTURA PROGRESSIVI DOCUMENTI',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='37');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '38','DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='38');


insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code,
 pagopa_ric_errore_desc,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select
 '39','PROVVISORIO DI CASSA REGOLARIZZATO',
 now(),
 'admin_pagoPA' ,
 ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where not exists
(select 1 from pagopa_d_riconciliazione_errore err
 where err.ente_proprietario_id=ente.ente_proprietario_id and err.pagopa_ric_errore_code='39');

--- siac_d_doc_tipo
insert into siac_d_doc_tipo
(
  doc_tipo_code,
  doc_tipo_desc,
  doc_fam_tipo_id,
  doc_gruppo_tipo_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select 'IPA',
       'INCASSI PAGOPA',
       tipo.doc_fam_tipo_id,
       tipo.doc_gruppo_tipo_id,
       now(),
       'admin_pagoPA',
       tipo.ente_proprietario_id
from siac_d_doc_tipo tipo,siac_t_ente_proprietario ente
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.doc_tipo_code='DSI'
and   not exists
(select 1 from siac_d_doc_tipo tipo1 where tipo1.ente_proprietario_id=ente.ente_proprietario_id and tipo1.doc_tipo_code='IPA');

insert into siac_r_doc_tipo_attr
(
  doc_tipo_id,
  attr_id,
  tabella_id,
  boolean,
  percentuale,
  testo,
  numerico,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select tipoipa.doc_tipo_id,
       r.attr_id,
       r.tabella_id,
       r.boolean,
       r.percentuale,
       r.testo,
       r.numerico,
       now(),
       'admin_pagoPA',
       tipoipa.ente_proprietario_id
from siac_r_doc_tipo_attr r, siac_d_doc_tipo tipo,siac_t_ente_proprietario ente,
     siac_d_doc_tipo tipoipa
where tipo.doc_tipo_code='DSI'
and   ente.ente_proprietario_id=tipo.ente_proprietario_id
and   tipoipa.ente_proprietario_id=ente.ente_proprietario_id
and   tipoipa.doc_tipo_code='IPA'
and   r.doc_tipo_id=tipo.doc_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   not exists
(
 select 1 from siac_r_doc_tipo_attr r1
 where r1.doc_tipo_id=tipoipa.doc_tipo_id
 and   r1.attr_id=r.attr_id
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null
);  
	
-- SIAC-6346 FINE
	
-- SIAC-6261, SIAC-6433 INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_dba_add_fk_constraint (
  table_in text,
  constraint_in text,
  column_in text,
  table_ref text,
  column_ref text
)


RETURNS text AS
$body$
declare
 
query_in text;
esito text;
begin
 
 select  'ALTER TABLE ' || table_in || ' ADD CONSTRAINT ' || constraint_in || ' FOREIGN KEY (' || column_in ||') ' ||
		 ' REFERENCES ' || table_ref || '(' || column_ref || ') ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE' 
		 into query_in
 where 
 not exists 
 (
 SELECT 1
	FROM information_schema.table_constraints tc
	WHERE tc.constraint_schema='siac'
	AND tc.table_schema='siac'
	AND tc.constraint_type='FOREIGN KEY' 
	AND tc.table_name=table_in
	AND tc.constraint_name=constraint_in
 );
 
if query_in is not null then
	esito:='fk constraint creato';
	execute query_in;
else
	esito:='fk constraint gia presente';
end if;
	return esito;
exception
    when RAISE_EXCEPTION THEN
    esito:=substring(upper(SQLERRM) from 1 for 2500);
        return esito;
	when others  THEN
	esito:=' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
        return esito;


end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


-- ######################################################



SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_tipo_fonte_durc', 'CHAR(1)');
SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_fine_validita_durc', 'DATE');
SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_fonte_durc_manuale_classif_id', 'INTEGER');
SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_fonte_durc_automatica', 'TEXT');
SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_note_durc', 'TEXT');

COMMENT ON COLUMN siac.siac_t_soggetto.soggetto_tipo_fonte_durc IS 'A: automatica, M: manuale';

SELECT * FROM fnc_dba_add_check_constraint(
	'siac_t_soggetto',
    'siac_t_soggetto_soggetto_tipo_fonte_durc_chk',
    'soggetto_tipo_fonte_durc IN (''A'', ''M'')'
);

SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_soggetto',
	'siac_t_class_siac_t_soggetto',
    'soggetto_fonte_durc_manuale_classif_id',
  	'siac_t_class',
    'classif_id'
);

-- 


SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_tipo_fonte_durc', 'CHAR(1)');
SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_fine_validita_durc', 'DATE');
SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_fonte_durc_manuale_classif_id', 'INTEGER');
SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_fonte_durc_automatica', 'TEXT');
SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_note_durc', 'TEXT');

COMMENT ON COLUMN siac_t_soggetto_mod.soggetto_tipo_fonte_durc IS 'A: automatica, M: manuale';

SELECT * FROM fnc_dba_add_check_constraint(
	'siac_t_soggetto_mod',
    'siac_t_soggetto_mod_soggetto_tipo_fonte_durc_chk',
    'soggetto_tipo_fonte_durc IN (''A'', ''M'')'
);

SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_soggetto_mod',
	'siac_t_class_siac_t_soggetto',
    'soggetto_fonte_durc_manuale_classif_id',
  	'siac_t_class',
    'classif_id'
);


-- SIAC-6261, SIAC-6433 FINE


