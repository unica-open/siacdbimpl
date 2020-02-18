/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*
select fnc_siac_cons_entita_liquidazione_from_soggetto (
  138171,
  '2018',
  1000,
  0
);
*/

--select fnc_siac_cons_entita_liquidazione_from_soggetto_total (138171,  '2018');

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_soggetto_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_soggetto_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_soggetto_total (
  _uid_soggetto integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
    v_ente_proprietario_id integer;    
BEGIN

    select ente_proprietario_id into v_ente_proprietario_id from  siac_t_soggetto where soggetto_id = _uid_soggetto;  

	SELECT 
	coalesce(count(*),0) into total
	from (
		    with liq as
    (
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
		and q.attoamm_stato_code<>'ANNULLATO'
		AND l.soggetto_id=_uid_soggetto
		and h.anno = _anno
	),
	sac as
    (
	select
			y.classif_code,
			y.classif_desc,
			z.attoamm_id
		from
			siac_t_class y,
			siac_d_class_tipo x,
			siac_r_atto_amm_class z
		where x.classif_tipo_id=y.classif_tipo_id
        and y.classif_id=z.classif_id
        and y.ente_proprietario_id = v_ente_proprietario_id
		and x.classif_tipo_code  IN ('CDC', 'CDR')
		and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
		and z.data_cancellazione is NULL
		and y.data_cancellazione is NULL
		and x.data_cancellazione is NULL
	),
    -- 02.07.2018 Sofia siac-6193
    cartecont as
    (
        select rcs.soggetto_id, count(*) esiste_carta
        from  siac_r_cartacont_det_soggetto rcs
        where
        	rcs.ente_proprietario_id = v_ente_proprietario_id 
        and rcs.data_cancellazione is null
        and rcs.validita_fine is null
        group by rcs.soggetto_id
    ),
    -- 02.07.2018 Sofia jira siac-6193
    split_liq as
    (
      select  rliq.liq_id, count(*) esiste_split
      from siac_r_subdoc_liquidazione rliq,siac_t_subdoc sub,siac_r_doc_onere ronere,
           siac_d_onere onere, siac_d_onere_tipo tipo
      where  tipo.onere_tipo_code!='ES'
      and    onere.onere_tipo_id=tipo.onere_tipo_id
      and    ronere.onere_id=onere.onere_id
      and    sub.doc_id=ronere.doc_id
      and    rliq.subdoc_id=sub.subdoc_id
      and    onere.ente_proprietario_id = v_ente_proprietario_id
      and    ronere.data_cancellazione is null
      and    now() between ronere.validita_inizio and coalesce(ronere.validita_fine,now())
      and    sub.data_cancellazione is null
      and    now() between sub.validita_inizio and coalesce(sub.validita_fine,now())
      and    rliq.data_cancellazione is null
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
        and   alg.data_cancellazione is null
        and   rs.data_cancellazione is null
        and   stato.data_cancellazione is null
        
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
              siac_d_oil_relaz_tipo oil, siac_r_oil_relaz_tipo roil, -- 13.07.2018 Sofia jira siac-6193
              siac_t_soggetto sog_cessione,
              siac_r_soggrel_modpag rsm,
              siac_t_modpag tmod,
              siac_d_accredito_tipo dat
	    where oil.oil_relaz_tipo_code ='CSI' -- 13.07.2018 Sofia jira siac-6193
        and   roil.oil_relaz_tipo_id=oil.oil_relaz_tipo_id
        and   drt.relaz_tipo_id=roil.relaz_tipo_id
        and   drt.relaz_tipo_id=rrelaz.relaz_tipo_id
        and   sog_cessione.soggetto_id=rrelaz.soggetto_id_a
        and   rrelaz.soggetto_id_da=_uid_soggetto
        and   rsm.soggetto_relaz_id=rrelaz.soggetto_relaz_id
        and   tmod.modpag_id=rsm.modpag_id
        and   dat.accredito_tipo_id = tmod.accredito_tipo_id
        and   liqCessione.soggetto_relaz_id=rrelaz.soggetto_relaz_id
        and   liqCessione.ente_proprietario_id = v_ente_proprietario_id
        and   liqCessione.data_cancellazione is null
        and   liqCessione.validita_fine is null
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
        and   tmod.soggetto_id = _uid_soggetto
        and   liqModpag.data_cancellazione is null
        and   tmod.data_cancellazione is null
        and   tipo.data_cancellazione is null
        and   liqModpag.validita_fine is null
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
        and tor.ente_proprietario_id = v_ente_proprietario_id
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
      and r.ente_proprietario_id = v_ente_proprietario_id
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
              siac_d_oil_relaz_tipo oil, siac_r_oil_relaz_tipo roil, -- 13.07.2018 Sofia jira siac-6193
              siac_t_soggetto sog_cessione,
              siac_r_soggrel_modpag rsm,
              siac_t_modpag tmod,
              siac_d_accredito_tipo dat,
              siac_r_ordinativo_modpag rmdp
	    where oil.oil_relaz_tipo_code ='CSI' -- 13.07.2018 Sofia jira siac-6193
        and   roil.oil_relaz_tipo_id=oil.oil_relaz_tipo_id
        and   drt.relaz_tipo_id=roil.relaz_tipo_id
        and   drt.relaz_tipo_id=rrelaz.relaz_tipo_id
        and   sog_cessione.soggetto_id=rrelaz.soggetto_id_a
        and   rsm.soggetto_relaz_id=rrelaz.soggetto_relaz_id
        and   tmod.modpag_id=rsm.modpag_id
        and   dat.accredito_tipo_id = tmod.accredito_tipo_id
        and   rmdp.soggetto_relaz_id=rrelaz.soggetto_relaz_id
        and   sog_Cessione.ente_proprietario_id = v_ente_proprietario_id
        and   rmdp.data_cancellazione is null
        and   rmdp.validita_fine is null
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
        and   rModpag.validita_fine is null
        and   tmod.data_cancellazione is null
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
     and   rsog.data_cancellazione is null
     and   now()  BETWEEN rsog.validita_inizio and coalesce(rsog.validita_fine,now())
     )
    select ordi.*,
            ord_quietanza.ord_quietanza_data,
            -- 12.07.2018 Sofia jira siac-6193
            ord_soggetto_ord.ord_soggetto_code,
            ord_soggetto_ord.ord_soggetto_desc,
			-- Accredito tipo - no CESSIONE
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
            -- Estremi soggetto cessione
       		ord_modpag_cessione.soggetto_cessione_code ord_soggetto_cessione_code,
	        ord_modpag_cessione.soggetto_cessione_desc ord_soggetto_cessione_desc,
    	    -- Relazione Soggetto
	        ord_modpag_cessione.relaz_tipo_code ord_relaz_tipo_code,
        	ord_modpag_cessione.relaz_tipo_desc ord_relaz_tipo_desc,
	        -- Accredito tipo - CESSIONE
            ord_modpag_cessione.accredito_tipo_code ord_accredito_tipo_code_cess,
        	ord_modpag_cessione.accredito_tipo_desc ord_accredito_tipo_desc_cess,
	        -- Modalita di pagamento cessione
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
     and   tipo.ente_proprietario_id = v_ente_proprietario_id
     and   ordi.ord_tipo_id=tipo.ord_tipo_id
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
		-- Data di inserimento dell atto contabile (la medesima data che viene riportata in stampa dell’ALG)
        attoallegato.attoal_data_creazione,
        -- Data di scadenza dell atto contabile
        attoallegato.attoal_data_scadenza ,
        -- Stato dell atto contabile
		attoallegato.attoal_stato_desc,
        -- Modalita di pagamento - no cessione
        modpag_no_cessione.accredito_tipo_code,
        modpag_no_cessione.accredito_tipo_desc,
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
        -- Estremi soggetto cessione
        modpag_cessione.soggetto_cessione_code,
        modpag_cessione.soggetto_cessione_desc,
        -- Relazione Soggetto
        modpag_cessione.relaz_tipo_code,
        modpag_cessione.relaz_tipo_desc,
        -- Accredito tipo - cessione
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
        -- MDP ordinativo
        ordinativo.ord_accredito_tipo_code,
        ordinativo.ord_accredito_tipo_desc,
        ordinativo.ord_iban,
        ordinativo.ord_bic,
        ordinativo.ord_contocorrente,
        ordinativo.ord_contocorrente_intestazione,
        ordinativo.ord_banca_denominazione,
        ordinativo.ord_quietanzante,
        ordinativo.ord_quietanzante_codice_fiscale,
        -- Estremi soggetto cessione
        ordinativo.ord_soggetto_cessione_code,
        ordinativo.ord_soggetto_cessione_desc,
        -- Relazione soggetto cessione
        ordinativo.ord_relaz_tipo_code,
        ordinativo.ord_relaz_tipo_desc,
        -- MDP ordinativo - cessione
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
	) as liq_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;