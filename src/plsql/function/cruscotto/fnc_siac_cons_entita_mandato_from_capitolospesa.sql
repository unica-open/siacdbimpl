/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION if exists fnc_siac_cons_entita_mandato_from_capitolospesa (integer,  integer, integer);
DROP FUNCTION if exists fnc_siac_cons_entita_mandato_from_capitolospesa (integer,  integer, integer,integer);
DROP FUNCTION if exists fnc_siac_cons_entita_mandato_from_capitolospesa (integer,  varchar,integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_capitolospesa (
  _uid_capitolospesa integer,
  _filtro_crp varchar, -- 12.07.2018 Sofia jira siac-6193 C,R,altro per tutto
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  -- 12.07.2018 Sofia siac-6193
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
  -- 02.07.2018 Sofia jira siac-6193
  sog_codice_fiscale varchar,
  sog_partita_iva varchar,
  -- 11.07.2018 Sofia siac-6193
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
  -- 11.07.2018 Sofia jira siac-6193 estremi cessione
  ord_soggetto_cessione_code varchar,
  ord_soggetto_cessione_desc varchar,
  ord_relaz_tipo_code varchar,
  ord_relaz_tipo_desc varchar,
  -- MDP - cessione
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
 rec record;
 rec2 record;
 attoamm_uid integer;

 -- 03.07.2018 Sofia jira siac-6193
 soggettoId integer:=null;

BEGIN
	

	for rec in
     WITH
     movimenti as
     (
     	select re.elem_id, rord.sord_id ord_ts_id, mov.movgest_anno::integer
		from  siac_r_movgest_bil_elem re,
		      siac_t_movgest_ts ts,
              siac_t_movgest mov,
              siac_r_liquidazione_movgest rmov,
		      siac_r_liquidazione_ord rord
		where re.elem_id=_uid_capitolospesa
		and   mov.movgest_id=re.movgest_id
		and   ts.movgest_id=mov.movgest_id
		and   rmov.movgest_ts_id=ts.movgest_ts_id
		and   rord.liq_id=rmov.liq_id
		and   re.data_cancellazione is null
		and   re.validita_fine  is null
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   mov.data_cancellazione is null
		and   mov.validita_fine is NULL
		and   rmov.data_cancellazione is null
		and   rmov.validita_fine is NULL
		and   rord.data_cancellazione is null
		and   rord.validita_fine is NULL
      ),
      ordinativi as
      (
		select
			siac_r_ordinativo_bil_elem.ord_id,
			siac_t_ordinativo.ord_numero,
			siac_t_ordinativo.ord_emissione_data,
            siac_t_ordinativo.ord_anno::INTEGER,
			siac_t_bil_elem.elem_id,
			siac_t_bil_elem.elem_code,
			siac_t_bil_elem.elem_code2,
			siac_t_bil_elem.elem_code3,
			siac_t_bil_elem.elem_desc,
            siac_t_ordinativo.ord_desc,
            siac_d_ordinativo_stato.ord_stato_desc,
            siac_t_ordinativo_ts_det.ord_ts_det_importo as importo,
            siac_t_ordinativo_ts.ord_ts_code,
			-- 03.07.2018 Sofia jira siac-6193
            siac_t_ordinativo_ts.ord_ts_id ,
            conto.contotes_code,
            dist.dist_code,
            dist.dist_desc
		from
			 siac_r_ordinativo_bil_elem --r
			,siac_t_bil_elem --s
			,siac_d_ordinativo_tipo --i
            ,siac_r_ordinativo_stato --d,
            ,siac_d_ordinativo_stato --e,
            ,siac_t_ordinativo_ts --f,
            ,siac_t_ordinativo_ts_det --g,
            ,siac_d_ordinativo_ts_det_tipo --h
			,siac_t_ordinativo --y
             left join siac_d_contotesoreria conto on (conto.contotes_id=siac_t_ordinativo.contotes_id and conto.data_cancellazione is null)
             left join siac_d_distinta dist on (dist.dist_id=siac_t_ordinativo.dist_id and dist.data_cancellazione is null)

		where siac_t_bil_elem.elem_id=siac_r_ordinativo_bil_elem.elem_id
		and siac_t_ordinativo.ord_id=siac_r_ordinativo_bil_elem.ord_id
		and siac_t_bil_elem.elem_id=_uid_capitolospesa
		and siac_d_ordinativo_tipo.ord_tipo_id=siac_t_ordinativo.ord_tipo_id
		and siac_d_ordinativo_tipo.ord_tipo_code='P'
		and siac_r_ordinativo_bil_elem.data_cancellazione is null
		and siac_t_bil_elem.data_cancellazione is null
		and siac_d_ordinativo_tipo.data_cancellazione is null
		and now() BETWEEN siac_r_ordinativo_bil_elem.validita_inizio and coalesce (siac_r_ordinativo_bil_elem.validita_fine,now())
		and siac_t_ordinativo.data_cancellazione is null
        and siac_r_ordinativo_stato.ord_id=siac_t_ordinativo.ord_id
        and siac_r_ordinativo_stato.ord_stato_id=siac_d_ordinativo_stato.ord_stato_id
        and now() BETWEEN siac_r_ordinativo_stato.validita_inizio and COALESCE(siac_r_ordinativo_stato.validita_fine,now())
        and siac_t_ordinativo_ts.ord_id=siac_t_ordinativo.ord_id
        and siac_t_ordinativo_ts_det.ord_ts_id=siac_t_ordinativo_ts.ord_ts_id
        and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_id=siac_t_ordinativo_ts_det.ord_ts_det_tipo_id
        and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code = 'A'
        and siac_t_ordinativo.data_cancellazione is null
        and siac_r_ordinativo_stato.data_cancellazione is null
        and siac_d_ordinativo_stato.data_cancellazione is null
        and siac_t_ordinativo_ts.data_cancellazione is null
        and siac_t_ordinativo_ts_det.data_cancellazione is null
	  )
      -- 03.07.2018 Sofia jira siac-6193
      select ordinativi.*
      from ordinativi, movimenti
      where ordinativi.ord_ts_id=movimenti.ord_ts_id
      -- 03.07.2018 Sofia jira siac-6193
      and   ( case when coalesce(_filtro_crp,'')='C' then ordinativi.ord_anno=movimenti.movgest_anno
      			   when coalesce(_filtro_crp,'')='R' then movimenti.movgest_anno<ordinativi.ord_anno
                   else true end )
	  order by 2,3
	  LIMIT _limit
	  OFFSET _offset

	loop
		uid:=rec.ord_id;
		uid_capitolo:=rec.elem_id;
		num_capitolo:=rec.elem_code;
		num_articolo:=rec.elem_code2;
		num_ueb:=rec.elem_code3;
		capitolo_desc:=rec.elem_desc;

        uid := rec.ord_id;
        ord_numero := rec.ord_numero;

        ord_desc := rec.ord_desc;
        ord_emissione_data := rec.ord_emissione_data;
        ord_stato_desc := rec.ord_stato_desc;
        importo := rec.importo;
        ord_ts_code := rec.ord_ts_code;

        -- 03.07.2018 Sofia jira siac-6193
        ord_conto_tesoreria:=rec.contotes_code;
        ord_distinta_codice:=rec.dist_code;
        ord_distinta_desc:=rec.dist_desc;


        -- 03.07.2018 Sofia jira siac-6193
        soggettoId:=null;

              select
                  siac_t_soggetto.soggetto_code,
                  siac_t_soggetto.soggetto_desc,
                  -- 02.07.2018 Sofia jira siac-6193
                  siac_t_soggetto.codice_fiscale::varchar,
                  siac_t_soggetto.partita_iva,
                  siac_t_soggetto.soggetto_id -- 03.07.2018 Sofia jira siac-6193
              into
                  -- 12.07.2018 Sofia jira siac-6193
                  ord_soggetto_code,
                  ord_soggetto_desc,
                  -- 02.07.2018 Sofia jira siac-6193
                  sog_codice_fiscale,
                  sog_partita_iva,
                  soggettoId -- 03.07.2018 Sofia jira siac-6193
              from
                  siac_r_ordinativo_soggetto --b,
                  ,siac_t_soggetto --c
              where siac_r_ordinativo_soggetto.ord_id=uid
              and siac_r_ordinativo_soggetto.soggetto_id=siac_t_soggetto.soggetto_id
              and now() BETWEEN siac_r_ordinativo_soggetto.validita_inizio and COALESCE(siac_r_ordinativo_soggetto.validita_fine,now())
              and siac_r_ordinativo_soggetto.data_cancellazione is null
              and siac_t_soggetto.data_cancellazione is null;

              select
                  siac_t_atto_amm.attoamm_id,
                  siac_t_atto_amm.attoamm_numero,
                  siac_t_atto_amm.attoamm_anno,
                  siac_d_atto_amm_stato.attoamm_stato_desc,
                  siac_d_atto_amm_tipo.attoamm_tipo_code,
                  siac_d_atto_amm_tipo.attoamm_tipo_desc
              into
                  attoamm_uid,
                  attoamm_numero,
                  attoamm_anno,
                  attoamm_stato_desc,
                  attoamm_tipo_code,
                  attoamm_tipo_desc
              from
                  siac_r_ordinativo_atto_amm --m
                  ,siac_t_atto_amm --n
                  ,siac_d_atto_amm_tipo --o
                  ,siac_r_atto_amm_stato --p
                  ,siac_d_atto_amm_stato --q
              where siac_r_ordinativo_atto_amm.ord_id=uid
              and siac_t_atto_amm.attoamm_id=siac_r_ordinativo_atto_amm.attoamm_id
              and siac_d_atto_amm_tipo.attoamm_tipo_id=siac_t_atto_amm.attoamm_tipo_id
              and siac_r_atto_amm_stato.attoamm_id=siac_t_atto_amm.attoamm_id
              and siac_r_atto_amm_stato.attoamm_stato_id=siac_d_atto_amm_stato.attoamm_stato_id
              and now() BETWEEN siac_r_atto_amm_stato.validita_inizio and coalesce (siac_r_atto_amm_stato.validita_fine,now())
              and now() BETWEEN siac_r_ordinativo_atto_amm.validita_inizio and COALESCE(siac_r_ordinativo_atto_amm.validita_fine,now())
              and siac_d_atto_amm_stato.attoamm_stato_code<>'ANNULLATO'
              and siac_r_ordinativo_atto_amm.data_cancellazione is null
              and siac_t_atto_amm.data_cancellazione is null
              and siac_d_atto_amm_tipo.data_cancellazione is null
              and siac_r_atto_amm_stato.data_cancellazione is null
              and siac_d_atto_amm_stato.data_cancellazione is null;

        	  -- 11.07.2018 Sofia jira siac-6193
              ord_accredito_tipo_code := null;
              ord_accredito_tipo_desc := null;
 	          ord_iban:=null;
	          ord_bic:=null;
	          ord_contocorrente:=null;
	          ord_contocorrente_intestazione:=null;
	          ord_banca_denominazione:=null;
	          ord_quietanzante:=null;
	          ord_quietanzante_codice_fiscale:=null;


          	  ord_soggetto_cessione_code:=null;
 	          ord_soggetto_cessione_desc:=null;
   	          ord_relaz_tipo_code:=null;
	          ord_relaz_tipo_desc:=null;
 	          ord_iban_cess:=null;
	          ord_bic_cess:=null;
	          ord_contocorrente_cess:=null;
	          ord_contocorrente_intestazione_cess:=null;
	          ord_banca_denominazione_cess:=null;
	          ord_quietanzante_cess:=null;
	          ord_quietanzante_codice_fiscale_cess:=null;

              /* -- 02.07.2018 Sofia jira siac-6193
              select
                  siac_d_accredito_tipo.accredito_tipo_code,
                  siac_d_accredito_tipo.accredito_tipo_desc
              into
                  accredito_tipo_code,
                  accredito_tipo_desc
              FROM
                  siac_r_ordinativo_modpag --c2,
                  ,siac_t_modpag --d2,
                  ,siac_d_accredito_tipo --e2
              where siac_r_ordinativo_modpag.ord_id=uid
                and siac_r_ordinativo_modpag.modpag_id=siac_t_modpag.modpag_id
                and siac_d_accredito_tipo.accredito_tipo_id=siac_t_modpag.accredito_tipo_id
                and now() BETWEEN siac_r_ordinativo_modpag.validita_inizio and coalesce (siac_r_ordinativo_modpag.validita_fine,now())
                and siac_r_ordinativo_modpag.data_cancellazione is null
                and siac_t_modpag.data_cancellazione is null
                and siac_d_accredito_tipo.data_cancellazione is null;

              IF accredito_tipo_code IS NULL THEN
                  SELECT
                      drt.relaz_tipo_code,
                      drt.relaz_tipo_desc
                  into
                      accredito_tipo_code,
                      accredito_tipo_desc
                  FROM
                      siac_r_ordinativo_modpag rom,
                      siac_r_soggetto_relaz rsr,
                      siac_d_relaz_tipo drt
                  where rom.ord_id=uid
                    and rsr.soggetto_relaz_id = rom.soggetto_relaz_id
                    and drt.relaz_tipo_id = rsr.relaz_tipo_id
                    and now() BETWEEN rom.validita_inizio and coalesce (rom.validita_fine,now())
                    and now() BETWEEN rsr.validita_inizio and coalesce (rsr.validita_fine,now())
                    and rom.data_cancellazione is null
                    and rsr.data_cancellazione is null
                    and drt.data_cancellazione is null;
              END IF;
      		 */

             -- 11.07.2018 Sofia jira siac-6193
			  select
			         (case when query.relaz_tipo_code is  null then query.accredito_tipo_code else null end) ord_accredito_tipo_code,
			         (case when query.relaz_tipo_code is  null then query.accredito_tipo_desc else null end) ord_accredito_tipo_desc,
			         (case when query.relaz_tipo_code is  null then query.iban else null end) ord_iban,
			         (case when query.relaz_tipo_code is  null then query.bic else null end) ord_bic,
			         (case when query.relaz_tipo_code is  null then query.contocorrente else null end) ord_contocorrente,
			         (case when query.relaz_tipo_code is  null then query.contocorrente_intestazione else null end) ord_contocorrente_intestazione,
			         (case when query.relaz_tipo_code is  null then query.banca_denominazione else null end) ord_banca_denominazione,
			         (case when query.relaz_tipo_code is  null then query.quietanziante else null end) ord_quietanzante,
			         (case when query.relaz_tipo_code is  null then query.quietanziante_codice_fiscale else null end)::varchar ord_quietanzante_codice_fiscale,
			         query.soggetto_cessione_code,
                     query.soggetto_cessione_desc,
			         query.relaz_tipo_code,
			         query.relaz_tipo_desc,
			         (case when query.relaz_tipo_code is not null then query.accredito_tipo_code else null end) ord_accredito_tipo_code_cess,
			         (case when query.relaz_tipo_code is not null then query.accredito_tipo_desc else null end) ord_accredito_tipo_desc,
			         (case when query.relaz_tipo_code is not null then query.iban else null end) ord_iban_cess,
			         (case when query.relaz_tipo_code is not null then query.bic else null end) ord_bic_cess,
			         (case when query.relaz_tipo_code is not null then query.contocorrente else null end) ord_contocorrente_cess,
			         (case when query.relaz_tipo_code is not null then query.contocorrente_intestazione else null end) ord_contocorrente_intestazione_cess,
			         (case when query.relaz_tipo_code is not null then query.banca_denominazione else null end) ord_banca_denominazione_cess,
			         (case when query.relaz_tipo_code is not null then query.quietanziante else null end) ord_quietanzante_cess,
			         (case when query.relaz_tipo_code is not null then query.quietanziante_codice_fiscale else null end)::varchar ord_quietanzante_codice_fiscale_cess
              into
			         ord_accredito_tipo_code,
		             ord_accredito_tipo_desc,
			         ord_iban,
			         ord_bic,
			         ord_contocorrente,
			         ord_contocorrente_intestazione,
			         ord_banca_denominazione,
			         ord_quietanzante ,
			         ord_quietanzante_codice_fiscale,
			         ord_soggetto_cessione_code,
			         ord_soggetto_cessione_desc,
			         ord_relaz_tipo_code,
			         ord_relaz_tipo_desc,
   			         ord_accredito_tipo_code_cess,
		             ord_accredito_tipo_desc_cess,
			         ord_iban_cess,
			         ord_bic_cess,
			         ord_contocorrente_cess,
			         ord_contocorrente_intestazione_cess,
			         ord_banca_denominazione_cess,
			         ord_quietanzante_cess ,
			         ord_quietanzante_codice_fiscale_cess
              from
              (
        		select
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
		        from  siac_r_ordinativo_modpag rmdp,
                      siac_r_soggetto_relaz rrelaz,
                      siac_r_soggrel_modpag rsm,
        		      siac_d_relaz_tipo drt,
		              siac_t_soggetto sog_cessione,
		              siac_t_modpag tmod,
		              siac_d_accredito_tipo dat
			    where rmdp.ord_id=uid
                and   rrelaz.soggetto_relaz_id=rmdp.soggetto_relaz_id
                and   rsm.soggetto_relaz_id=rrelaz.soggetto_relaz_id
                and   drt.relaz_tipo_id=rrelaz.relaz_tipo_id
                and   drt.relaz_tipo_code ='CSI'
		        and   tmod.modpag_id=rsm.modpag_id
   		        and   dat.accredito_tipo_id = tmod.accredito_tipo_id
		        and   sog_cessione.soggetto_id=rrelaz.soggetto_id_a
		        and   rmdp.data_cancellazione is null
		        and   rmdp.validita_fine is null
		        and   rrelaz.data_cancellazione is null
		        and   now()  BETWEEN rrelaz.validita_inizio and coalesce(rrelaz.validita_fine,now())
		        and   rsm.data_cancellazione is null
		        and   now()  BETWEEN rsm.validita_inizio and coalesce(rsm.validita_fine,now())
		        and   tmod.data_cancellazione is null
		        and   now()  BETWEEN tmod.validita_inizio and coalesce(tmod.validita_fine,now())
	 		 union
				select
                    null soggetto_cessione_code,
                    null soggetto_cessione_desc,
		            tipo.accredito_tipo_code,
		            tipo.accredito_tipo_desc,
        		    tmod.iban,
		            tmod.bic,
        		    tmod.contocorrente,
		            tmod.contocorrente_intestazione,
        		    tmod.banca_denominazione,
		            tmod.quietanziante,
		            tmod.quietanziante_codice_fiscale::varchar,
                    null relaz_tipo_code,
			        null relaz_tipo_desc
		        from  siac_r_ordinativo_modpag rModpag, siac_t_modpag tmod,  siac_d_accredito_tipo tipo
				where rModpag.ord_id=uid
                and   tmod.modpag_id=rModpag.modpag_id
                and   tipo.accredito_tipo_id = tmod.accredito_tipo_id
		        and   rModpag.data_cancellazione is null
		        and   rModpag.validita_fine is null
		        and   tmod.data_cancellazione is null
				and   now()  BETWEEN tmod.validita_inizio and coalesce(tmod.validita_fine,now())
             ) query;

              attoamm_sac_code:=null;
              attoamm_sac_desc:=null;

              select
                  siac_t_class.classif_code,
                  siac_t_class.classif_desc
              into
                  attoamm_sac_code,
                  attoamm_sac_desc
              from
                  siac_r_atto_amm_class --z,
                  ,siac_t_class --y,
                  ,siac_d_class_tipo --x
              where siac_r_atto_amm_class.attoamm_id=attoamm_uid
              and siac_r_atto_amm_class.classif_id=siac_t_class.classif_id
              and siac_d_class_tipo.classif_tipo_id=siac_t_class.classif_tipo_id
              and now() BETWEEN siac_r_atto_amm_class.validita_inizio and coalesce (siac_r_atto_amm_class.validita_fine,now())
              and siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
              and siac_r_atto_amm_class.data_cancellazione is NULL
              and siac_d_class_tipo.data_cancellazione is NULL
              and siac_t_class.data_cancellazione is NULL;

              select
                  siac_t_prov_cassa.provc_anno,
                  siac_t_prov_cassa.provc_numero,
                  siac_t_prov_cassa.provc_data_convalida
              into
                  provc_anno,
                  provc_numero,
                  provc_data_convalida
              from
                  siac_r_ordinativo_prov_cassa --a2,
                  ,siac_t_prov_cassa --b2
              where siac_r_ordinativo_prov_cassa.ord_id=uid
              and siac_t_prov_cassa.provc_id=siac_r_ordinativo_prov_cassa.provc_id
              and now() BETWEEN siac_r_ordinativo_prov_cassa.validita_inizio and coalesce (siac_r_ordinativo_prov_cassa.validita_fine,now())
              and siac_r_ordinativo_prov_cassa.data_cancellazione is NULL
              and siac_t_prov_cassa.data_cancellazione is NULL;

        	  -- 03.07.2018 Sofia jira siac-6193
        	  ord_copertura:='N';
              if provc_numero is not null then
              	ord_copertura:='S';
              end if;

        	  --SIAC-5899
              SELECT
                  siac_r_ordinativo_quietanza.ord_quietanza_data
              INTO
                  ord_quietanza_data
              FROM
                  siac_t_oil_ricevuta
                  ,siac_T_Ordinativo
                  ,siac_d_oil_ricevuta_tipo
                  ,siac_r_ordinativo_quietanza
              WHERE
                      siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
                  AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id
                  AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
                  AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'
                  AND siac_T_Ordinativo.ord_Id = uid
                  AND siac_t_oil_ricevuta.data_cancellazione is null
                  AND siac_T_Ordinativo.data_cancellazione is null
                  AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
                  AND siac_r_ordinativo_quietanza.data_cancellazione is null;


              -- 03.07.2018 Sofia jira siac-6193
              liq_attoamm_desc:=null;
              liq_attoalg_data_inserimento:=null;
              liq_attoalg_data_scad:=null;
              liq_attoalg_stato_desc:=null;
              select coalesce(alg.attoal_causale , atto.attoamm_oggetto),
                     alg.data_creazione, alg.attoal_data_scadenza,algstato.attoal_stato_desc
                     into liq_attoamm_desc,liq_attoalg_data_inserimento, liq_attoalg_data_scad,liq_attoalg_stato_desc
              from siac_r_liquidazione_ord rord,
                   siac_r_liquidazione_atto_amm rliq,
                   siac_r_liquidazione_stato rs, siac_d_liquidazione_stato stato,
                   siac_t_atto_amm atto
                   left join siac_t_atto_allegato alg
                         join siac_r_atto_allegato_stato rsalg
                          join siac_d_atto_allegato_stato algstato
                          on (algstato.attoal_stato_id=rsalg.attoal_stato_id and algstato.attoal_stato_code!='A')
                         on (rsalg.attoal_id=alg.attoal_id and
                             rsalg.data_cancellazione is null and
                             now() between rsalg.validita_inizio and coalesce(rsalg.validita_fine, now()))
                        on ( alg.attoamm_id=atto.attoamm_id )
              where rord.sord_id=rec.ord_ts_id
              and   rliq.liq_id=rord.liq_id
              and   rs.liq_id=rliq.liq_id
              and   stato.liq_stato_id=rs.liq_stato_id
              and   stato.liq_stato_code!='A'
              and   atto.attoamm_id=rliq.attoamm_id
              and   rord.data_cancellazione is null
              and   rord.validita_fine is null
              and   rs.data_cancellazione is null
              and   now() between rs.validita_inizio and coalesce(rs.validita_fine, now())
              and   rliq.data_cancellazione is null
              and   rliq.validita_fine is null
              and   atto.data_cancellazione is null
              and   now() between atto.validita_inizio and coalesce(atto.validita_fine, now());

			  -- 03.07.2018 Sofia jira siac-6193
              -- split si/no
              ord_split:=null;
              ord_split_importo:=null;
              select tipo.sriva_tipo_code into ord_split
              from 	siac_r_subdoc_ordinativo_ts rsub, siac_t_ordinativo_ts ts,
                    siac_t_subdoc sub,siac_r_subdoc_splitreverse_iva_tipo rsplit,
                    siac_d_splitreverse_iva_tipo tipo
              where ts.ord_id=uid
              and   rsub.ord_ts_id=ts.ord_ts_id
              and   sub.subdoc_id=rsub.subdoc_id
              and   rsplit.subdoc_id=sub.subdoc_id
              and   tipo.sriva_tipo_id=rsplit.sriva_tipo_id
              and   tipo.sriva_tipo_code!='ES'
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
              and   rsub.data_cancellazione is null
              and   rsub.validita_fine is null
              and   sub.data_cancellazione is null
              and   sub.validita_fine is null
              and   rsplit.data_cancellazione is null
              and   rsplit.validita_fine is null
              limit 1;

              if ord_split is not null then
                ord_split:='S';

              	select coalesce(sum(coalesce(det.ord_ts_det_importo,0)),0) into ord_split_importo
  				from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                     siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato,
                     siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod
				where rord.ord_id_da=uid
				and   tipo.relaz_tipo_id=rord.relaz_tipo_id
				and   tipo.relaz_tipo_code='SPR'
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
                and   det.validita_fine is null;
              else
                ord_split:='N';
              end if;

              -- 03.07.2018 Sofia jira siac-6193
              -- ritenute si/no
			  ord_ritenute:=null;
              ord_ritenute_importo:=null;
			  select tipo.onere_tipo_code into ord_ritenute
			  from siac_t_ordinativo_ts ordts, siac_r_doc_onere  rdoc, siac_t_subdoc doc, siac_r_subdoc_ordinativo_ts ts,
                   siac_d_onere_tipo tipo,siac_d_onere onere
	  		  where ordts.ord_id=uid
              and   ts.ord_ts_id=ordts.ord_ts_id
              and   doc.subdoc_id=ts.subdoc_id
              and   rdoc.doc_id=doc.doc_id
              and   onere.onere_id=rdoc.onere_id
              and   tipo.onere_tipo_id=onere.onere_tipo_id
              and   tipo.onere_tipo_code not in ('SP','ES')
        	  and   ordts.data_cancellazione is null
	     	  and   ordts.validita_fine is null
			  and   rdoc.data_cancellazione is null
              and   now() between rdoc.validita_inizio and coalesce(rdoc.validita_fine, now())
              and   doc.data_cancellazione is null
	     	  and   doc.validita_fine is null
              and   ts.data_cancellazione is null
              and   now() between ts.validita_inizio and coalesce(ts.validita_fine, now())
              limit 1;

              if ord_ritenute is not null then
              	  ord_ritenute:='S';

	              select coalesce(sum(coalesce(det.ord_ts_det_importo,0)),0) into ord_ritenute_importo
  				  from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                       siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato,
    	               siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod
				  where rord.ord_id_da=uid
				  and   tipo.relaz_tipo_id=rord.relaz_tipo_id
				  and   tipo.relaz_tipo_code='RIT_ORD'
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
            	  and   det.validita_fine is null;
               else
                  ord_ritenute:='N';
               end if;


               -- 28.06.2018 Sofia siac-6193
               carte_contabili:=null;
		       select stato.cartac_stato_code into carte_contabili
        	   from  siac_r_cartacont_det_soggetto rcs,
                     siac_t_cartacont_det det, siac_t_cartacont carta,
                     siac_r_cartacont_stato rs,siac_d_cartacont_stato stato
		       where rcs.soggetto_id=soggettoId
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
               limit 1;
			   if carte_contabili is not null then
               		carte_contabili:='S';
               else  carte_contabili:='N';
               end if;

              return next;

		--end loop;
	end loop;

	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*

select * from 
siac_t_bil_elem 
,siac_d_bil_elem_tipo 
where 
siac_t_bil_elem.elem_tipo_id =   siac_d_bil_elem_tipo.elem_tipo_id  
and siac_t_bil_elem.elem_code = '113114'
and siac_d_bil_elem_tipo.elem_tipo_id = 16;
 
93900
*/


--select * from fnc_siac_cons_entita_mandato_from_capitolospesa (93900,'X',  1000,0);
