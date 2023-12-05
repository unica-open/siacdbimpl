/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


with
doc as
(
 with doc1 as
 (
  with
  doc_totale as /* OTT */
  (
      select distinct
      --h.subdoc_id,a.doc_id,b.doc_tipo_id,c.doc_fam_tipo_id,d.doc_gruppo_tipo_id,e.doc_stato_r_id,f.doc_stato_id,
      b.doc_gruppo_tipo_id,
      g.ente_proprietario_id, g.ente_denominazione,
      a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
      case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
      a.doc_data_emissione, a.doc_data_scadenza,
      case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
      f.doc_stato_code, f.doc_stato_desc,
      c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
      a.doc_id, a.pcccod_id, a.pccuff_id,
      case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
      h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
      h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
      case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
      h.subdoc_data_pagamento_cec,
      a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
      h.notetes_id,h.dist_id,h.contotes_id,
      a.doc_sdi_lotto_siope,
      n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
      o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
      i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
      l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
      m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
      from  siac_t_ente_proprietario g,
            siac_d_doc_fam_tipo c,siac_d_doc_tipo b,
            siac_t_doc a
            left join siac_d_siope_documento_tipo n
                 on ( n.siope_documento_tipo_id = a.siope_documento_tipo_id
                  and n.data_cancellazione is null
                  and n.validita_fine is null )
            left join siac_d_siope_documento_tipo_analogico o
                 on ( o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                  and o.data_cancellazione is null
                  and o.validita_fine is null ),
            siac_r_doc_stato e, siac_d_doc_stato f,
            siac_t_subdoc h
            left join siac_d_siope_tipo_debito i
                 on ( i.siope_tipo_debito_id = h.siope_tipo_debito_id
                  and i.data_cancellazione is null
                  and i.validita_fine is null )
            left join siac_d_siope_assenza_motivazione l
                 on ( l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                  and l.data_cancellazione is null
                  and l.validita_fine is null )
            left join siac_d_siope_scadenza_motivo m
                 on ( m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                  and m.data_cancellazione is null
                  and m.validita_fine is null )
      where  g.ente_proprietario_id=2
      and    c.ente_proprietario_id=g.ente_proprietario_id
      and    c.doc_fam_tipo_code in ('S','IS')
      and    b.doc_fam_tipo_id=c.doc_fam_tipo_id
      and    a.doc_tipo_id=b.doc_tipo_id
      and    e.doc_id=a.doc_id
      and    now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
      and    f.doc_stato_id=e.doc_stato_id
      and    h.doc_id=a.doc_id
      -- 19.01.2021 Sofia Jira SIAC_7966 - inizio
      -- and date_trunc('DAY',a.data_creazione)=date_trunc('DAY',now())
      -- 26.01.2021 Sofia JIRA SIAC-7518 - inizio
      -- 1 esclusione pagamenti su mandato antecedente annoStorico
      and  not exists
      (
       select 1
       from  siac_t_bil anno,siac_t_periodo per,
             siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
             siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
             siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub
       where f.doc_stato_code='EM'
       and   rsub.subdoc_id=h.subdoc_id
       and   ts.ord_ts_id=rsub.ord_ts_id
       and   ord.ord_id=ts.ord_id
       and   tipo.ord_tipo_id=ord.ord_tipo_id
       and   tipo.ord_tipo_code='P'
       and   anno.bil_id=ord.bil_id
       and   per.periodo_id=anno.periodo_id
       and   per.anno::integer<=2020
       and   rs.ord_id=ord.ord_id
       and   stato.ord_stato_id=rs.ord_stato_id
       and   stato.ord_stato_code!='A'
       and   not exists
       (
        select 1
        from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
             siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,
             siac_t_bil anno1,siac_t_periodo per1
        where sub1.doc_id=a.doc_id
        and   rsub1.subdoc_id=sub1.subdoc_id
        and   ts1.ord_ts_id=rsub1.ord_ts_id
        and   ord1.ord_id=ts1.ord_id
        and   anno1.bil_id=ord1.bil_id
        and   per1.periodo_id=anno1.bil_id
        and   per1.anno::integer>=2020+1
        and   rsub1.data_cancellazione is null
        and   rsub1.validita_fine is null
       )
       and   rsub.data_cancellazione is null
       and   rsub.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
      )
      -- 2 esclusione pagamenti manuali dataOperazionePagamentoIncasso antecedente annoStorico
      and not exists
      (
        with
        doc_paga_man as
        (
        select rattr.doc_id,
               substring(coalesce(rattrDataPAga.testo,'01/01/'||(2020+1)::varchar||''),7,4)::integer annoDataPaga
        from siac_r_doc_attr rattr,siac_t_attr attr,
             siac_r_doc_Stato rs,siac_d_doc_Stato stato,
             siac_r_doc_attr rattrDataPaga,siac_t_attr attrDataPaga
        where rattr.doc_id=a.doc_id
        and   attr.attr_id=rattr.attr_id
        and   attr.attr_code='flagPagataIncassata'
        and   rattr.boolean='S'
        and   rs.doc_id=a.doc_id
        and   stato.doc_stato_id=rs.doc_stato_id
        and   stato.doc_stato_code='EM'
        and   rattrDataPaga.doc_id=a.doc_id
        and   attrDataPaga.attr_id=rattrDataPaga.attr_id
        and   attrdatapaga.attr_code='dataOperazionePagamentoIncasso'
        and   rattr.data_cancellazione is null
        and   rs.data_cancellazione is null
        and   rs.validita_fine is null
        )
        select query_doc_paga_man.*
        from doc_paga_man  query_doc_paga_man
        where query_doc_paga_man.annoDataPaga<=2020
      )
      -- 3 - esclusione documenti ANNULLATI IN ANNI ANTECEDENTI annoStorico
      and not exists
      (
         select 1
         where f.doc_stato_code='A'
         and  extract (year from e.validita_inizio)::integer<=2020
      )
      -- 4 - esclusione documenti STORNATI IN ANNI ANTECEDENTI annoStorico
      and not exists
      (
         select 1
         where f.doc_stato_code='ST'
         and  extract (year from e.validita_inizio)::integer<=2020
      )
      -- 19.01.2021 Sofia Jira SIAC_7966 - fine
      -- 26.01.2021 Sofia JIRA SIAC-7518 - fine
      AND a.data_cancellazione IS NULL
      AND b.data_cancellazione IS NULL
      AND c.data_cancellazione IS NULL
      AND e.data_cancellazione IS NULL
      AND f.data_cancellazione IS NULL
      AND g.data_cancellazione IS NULL
      AND h.data_cancellazione IS NULL
   )
   select doc_tot.*
   from doc_totale doc_tot
   limit 100
 ),
 docgru as
 (
   select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
   from siac_d_doc_gruppo a
   where a.ente_proprietario_id=2
   and a.data_cancellazione is null
 )
 select doc1.*, docgru.*
 from doc1 left join docgru on docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
),
bollo as
(
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc
  from siac_d_codicebollo a
  where a.ente_proprietario_id=2
  and a.data_cancellazione is null
),
sogg as
(
  with sogg1 as
  (
   select distinct
         a.doc_id,b.soggetto_code,
	     f.soggetto_stato_desc,
	     b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
	     b.soggetto_id
   from  siac_r_doc_sog a, siac_t_soggetto b ,
         siac_r_soggetto_stato e ,siac_d_soggetto_stato f
   where a.ente_proprietario_id=2
   and   b.soggetto_id=a.soggetto_id
   and   e.soggetto_id=b.soggetto_id
   and   f.soggetto_stato_id=e.soggetto_stato_id
   and   now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
   and a.data_cancellazione IS NULL
   and b.data_cancellazione IS NULL
   and e.data_cancellazione IS NULL
   and f.data_cancellazione IS NULL
  ),
  sogg2 as
  (
   select g.soggetto_id, g.ragione_sociale,g.validita_fine from  siac_t_persona_giuridica g
   where  g.ente_proprietario_id=2 and g.data_cancellazione is null
  ),
  sogg3 as
  (
   select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
   where  h.ente_proprietario_id=2 and h.data_cancellazione is null
  ),
  sogg5 as  /* OTT */
  (
   select c.soggetto_id,d.soggetto_tipo_desc
   from siac_d_soggetto_tipo d ,siac_r_soggetto_tipo c
   where d.ente_proprietario_id=2
   and   c.soggetto_tipo_id=d.soggetto_tipo_id
   and   c.data_cancellazione is null
   and   d.data_cancellazione is NULL
   AND   now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
  )
  select sogg1.*, sogg2.ragione_sociale, sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1
  left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
),
reguni as
(
 select a.doc_id,a.rudoc_registrazione_anno,
        a.rudoc_registrazione_numero,a.rudoc_registrazione_data
 from siac_t_registrounico_doc a where a.ente_proprietario_id=2 and a.data_cancellazione is null
),
cdr as  /** OTT **/
(
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
	     null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where c.ente_proprietario_id=2
  and   c.classif_tipo_code='CDR'
  and   b.classif_tipo_id=c.classif_tipo_id
  and   a.classif_id=b.classif_id
  and   now() BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, now())
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  AND  c.data_cancellazione IS NULL
),
cdc as /** OTT **/
( --4,953 sec;
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
	     d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where c.ente_proprietario_id=2
  and   c.classif_tipo_code='CDC'
  and   b.classif_tipo_id=c.classif_tipo_id
  and   a.classif_id=b.classif_id
  and   e.classif_id=b.classif_id
  and   d.classif_id=e.classif_id_padre
  and   now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
  and   now() BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, now())
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
),
pcccod as
(
  select a.pcccod_id,a.pcccod_code,a.pcccod_desc
  from   siac_d_pcc_codice  a where a.ente_proprietario_id=2 and a.data_cancellazione is null
),
pccuff as
(
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from  siac_d_pcc_ufficio  a where a.ente_proprietario_id=2 and a.data_cancellazione is null
),
attoamm as  -- subdoc_id
(
  with
  attoamm1 as /** OTT **/
  (
    select
    b.attoamm_id,
    a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
    d.attoamm_stato_code, d.attoamm_stato_desc,
    e.attoamm_tipo_code, e.attoamm_tipo_desc
    from siac_d_atto_amm_tipo e, siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
         siac_r_subdoc_atto_amm a
    where e.ente_proprietario_id=2
    and   b.attoamm_tipo_id=e.attoamm_tipo_id
    and   c.attoamm_id=b.attoamm_id
    and   a.attoamm_id=b.attoamm_id
    and   now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
    and   d.attoamm_stato_id=c.attoamm_stato_id
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
 ),
 cdr as  /** OTT **/
 (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_d_class_tipo c, siac_t_class b, siac_r_atto_amm_class a
  where c.ente_proprietario_id=2
  and   c.classif_tipo_code='CDR'
  and   b.classif_tipo_id=c.classif_tipo_id
  and   a.classif_id=b.classif_id
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
 ),
 cdc as  /** OTT **/
 (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from  siac_d_class_tipo c, siac_t_class b, siac_t_class d,siac_r_class_fam_tree e, siac_r_atto_amm_class a
  where c.ente_proprietario_id=2
  and   c.classif_tipo_code='CDC'
  and   b.classif_tipo_id=c.classif_tipo_id
  and   a.classif_id=b.classif_id
  and   e.classif_id=b.classif_id
  and   d.classif_id=e.classif_id_padre
  -- and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data) -- SIAC-5494
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
),
commt as  -- subdoc
(
 select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
 from siac_d_commissione_tipo a where a.ente_proprietario_id=2 and a.data_cancellazione is null
),
eldocattall as
(
  with
  eldoc as  /** OTT **/
  (
    select a.subdoc_id,a.eldoc_id,
           b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
           b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
           d.eldoc_stato_code, d.eldoc_stato_desc
     from siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
          siac_d_elenco_doc_stato d, siac_r_elenco_doc_subdoc a
    where b.ente_proprietario_id=2
    and   c.eldoc_id=b.eldoc_id
    and   d.eldoc_stato_id=c.eldoc_stato_id
    and   a.eldoc_id=b.eldoc_id
    and   now() BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, now())
    and   now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
    and   a.data_cancellazione is null
    and   b.data_cancellazione is null
    and   c.data_cancellazione is null
    and   d.data_cancellazione is null
  ),
  attoal as
  (
   with
   attoall as /** OTT **/
   (
	select
         distinct
  	     a.eldoc_id,b.attoal_id,
	     b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc,
         b.data_creazione data_ins_atto_allegato,   -- 15.05.2018 Sofia siac-6124
	     fnc_siac_attoal_getDataStato(b.attoal_id,'C') data_completa_atto_allegato, -- 22.05.2018 Sofia siac-6124
         fnc_siac_attoal_getDataStato(b.attoal_id,'CV') data_convalida_atto_allegato  -- 22.05.2018 Sofia siac-6124
   from  siac_t_atto_allegato b, siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d, siac_r_atto_allegato_elenco_doc a
   where b.ente_proprietario_id=2
   and   c.attoal_id=b.attoal_id
   and   d.attoal_stato_id=c.attoal_stato_id
   and   a.attoal_id=b.attoal_id
   and   now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
   and   now() BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, now())
   and   a.data_cancellazione is null
   and   b.data_cancellazione is null
   and   c.data_cancellazione is null
   and   d.data_cancellazione is null
  ),
  soggattoall as
  (
    with
    sogg1 as /** OTT **/
    (
      select
       distinct
       a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
       f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
       b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
       b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
       b.soggetto_id soggetto_id_atto_allegato,
       -- 16.05.2018 Sofia siac-6124
       a.attoal_sog_data_sosp data_sosp_atto_allegato,
       a.attoal_sog_causale_sosp causale_sosp_atto_allegato,
       a.attoal_sog_data_riatt data_riattiva_atto_allegato
      from  siac_t_soggetto b , siac_r_soggetto_stato e ,siac_d_soggetto_stato f,
            siac_r_atto_allegato_sog a
      where  b.ente_proprietario_id=2
      and    e.soggetto_id=b.soggetto_id
      and    f.soggetto_stato_id=e.soggetto_stato_id
      and    a.soggetto_id=b.soggetto_id
      and    now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
      AND    a.data_cancellazione IS NULL
      AND    b.data_cancellazione IS NULL
      AND    e.data_cancellazione IS NULL
      AND    f.data_cancellazione IS NULL
   ),
   sogg2 as
   (
    select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
    where g.ente_proprietario_id=2 and g.data_cancellazione is null
   ),
   sogg3 as
   (
    select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
    where h.ente_proprietario_id=2 and h.data_cancellazione is null
   ),
   sogg5 as /** OTT **/
   (
    select  c.soggetto_id,d.soggetto_tipo_desc
    from    siac_d_soggetto_tipo d , siac_r_soggetto_tipo c
    where   d.ente_proprietario_id=2
    and     c.soggetto_tipo_id=d.soggetto_tipo_id
    and     c.data_cancellazione is null
    and     d.data_cancellazione is NULL
    AND     now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
   )
   select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
   sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
   from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
   left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
   left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato ,
  -- 16.05.2018 Sofia siac-6124
  soggattoall.data_sosp_atto_allegato,
  soggattoall.causale_sosp_atto_allegato,
  soggattoall.data_riattiva_atto_allegato
  from attoall left join soggattoall on attoall.attoal_id=soggattoall.attoal_id
  )
  select
         distinct
         eldoc.*,
         attoal.attoal_id,
         attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
         attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
         attoal.soggetto_code_atto_allegato,
         attoal.soggetto_tipo_desc_atto_allegato,
         attoal.soggetto_stato_desc_atto_allegato,
  	     attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
         attoal.codice_fiscale_estero_atto_allegato,
         attoal.soggetto_id_atto_allegato,
         -- 15.05.2018 Sofia siac-6124
         attoal.data_ins_atto_allegato,
         attoal.data_sosp_atto_allegato,
         attoal.causale_sosp_atto_allegato,
         attoal.data_riattiva_atto_allegato,
         attoal.data_completa_atto_allegato,
        attoal.data_convalida_atto_allegato
  from eldoc left join attoal  on eldoc.eldoc_id=attoal.eldoc_id
)
select  --doc.doc_id,doc.subdoc_id, count(*)
        doc.*, bollo.*,sogg.*,
        reguni.*,cdc.*,cdr.*,
        pcccod.*,pccuff.*,
        attoamm.*,
        commt.*,
        eldocattall.*
from doc
left join bollo on doc.codbollo_id=bollo.codbollo_id
left join sogg  on doc.doc_id=sogg.doc_id
left join reguni on doc.doc_id=reguni.doc_id
left join cdc on doc.doc_id=cdc.doc_id
left join cdr on doc.doc_id=cdr.doc_id
left join pcccod on doc.pcccod_id=pcccod.pcccod_id
left join pccuff on doc.pccuff_id=pccuff.pccuff_id
left join attoamm on doc.subdoc_id=attoamm.subdoc_id -- subdoc_id
left join commt on doc.comm_tipo_id=commt.comm_tipo_id --subdoc_id
left join eldocattall on doc.subdoc_id=eldocattall.subdoc_id --subdoc_id
--where doc.doc_id in (137363, 27551, 36251)
--group by doc.doc_id,doc.subdoc_id
--having count(*)>1
-- 100 rows returned (execution time: 17,000 sec; total time: 17,141 sec)
-- 112 rows returned (execution time: 15,000 sec; total time: 15,172 sec) con sogg
-- 112 rows returned (execution time: 14,078 sec; total time: 14,235 sec) con cdc,cdr

-- RADDOPPIO
-- 112 rows returned (execution time: 37,094 sec; total time: 37,250 sec) con attoamm su subdoc
-- 112 rows returned (execution time: 38,359 sec; total time: 38,687 sec)
-- 112 rows returned (execution time: 37,828 sec; total time: 38,016 sec)

-- RADDOPPIO
-- 112 rows returned (execution time: 00:01:19; total time: 00:01:19) con commt su sudoc

-- RADDOPPIO con atti allegati
-- 112 rows returned (execution time: 00:02:42; total time: 00:02:42) con eldocattall su subdoc
-- 112 rows returned (execution time: 00:02:19; total time: 00:02:20)
-- 112 rows returned (execution time: 00:02:38; total time: 00:02:39)

-- dati da sistemare

/* record aperti multipli
select *
from siac_t_persona_giuridica p
where p.soggetto_id=137145

doc.doc_id in (137363, 27551, 36251)*/


-- ottimizza su subdoc
with
doc as
(
 with doc1 as
 (
  with
  doc_totale as /* OTT */
  (
      select distinct
      --h.subdoc_id,a.doc_id,b.doc_tipo_id,c.doc_fam_tipo_id,d.doc_gruppo_tipo_id,e.doc_stato_r_id,f.doc_stato_id,
      b.doc_gruppo_tipo_id,
      g.ente_proprietario_id, g.ente_denominazione,
      a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
      case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
      a.doc_data_emissione, a.doc_data_scadenza,
      case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
      f.doc_stato_code, f.doc_stato_desc,
      c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
      a.doc_id, a.pcccod_id, a.pccuff_id,
      case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
      a.codbollo_id,
      a.doc_sdi_lotto_siope,
      n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
      o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit
      from  siac_t_ente_proprietario g,
            siac_d_doc_fam_tipo c,siac_d_doc_tipo b,
            siac_t_doc a
            left join siac_d_siope_documento_tipo n
                 on ( n.siope_documento_tipo_id = a.siope_documento_tipo_id
                  and n.data_cancellazione is null
                  and n.validita_fine is null )
            left join siac_d_siope_documento_tipo_analogico o
                 on ( o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                  and o.data_cancellazione is null
                  and o.validita_fine is null ),
            siac_r_doc_stato e, siac_d_doc_stato f

      where  g.ente_proprietario_id=2
      and    c.ente_proprietario_id=g.ente_proprietario_id
      and    c.doc_fam_tipo_code in ('S','IS')
      and    b.doc_fam_tipo_id=c.doc_fam_tipo_id
      and    a.doc_tipo_id=b.doc_tipo_id
      and    e.doc_id=a.doc_id
      and    now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
      and    f.doc_stato_id=e.doc_stato_id
      -- and date_trunc('DAY',a.data_creazione)=date_trunc('DAY',now())
      -- 1 esclusione pagamenti su mandato antecedente annoStorico
      and  not exists
      (
       select 1
       from  siac_t_bil anno,siac_t_periodo per,
             siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
             siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
             siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
             siac_t_subdoc sub
       where f.doc_stato_code='EM'
       and   sub.doc_id=a.doc_id
       and   rsub.subdoc_id=sub.subdoc_id
       and   ts.ord_ts_id=rsub.ord_ts_id
       and   ord.ord_id=ts.ord_id
       and   tipo.ord_tipo_id=ord.ord_tipo_id
       and   tipo.ord_tipo_code='P'
       and   anno.bil_id=ord.bil_id
       and   per.periodo_id=anno.periodo_id
       and   per.anno::integer<=2020
       and   rs.ord_id=ord.ord_id
       and   stato.ord_stato_id=rs.ord_stato_id
       and   stato.ord_stato_code!='A'
       and   not exists
       (
        select 1
        from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
             siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,
             siac_t_bil anno1,siac_t_periodo per1
        where sub1.doc_id=a.doc_id
        and   rsub1.subdoc_id=sub1.subdoc_id
        and   ts1.ord_ts_id=rsub1.ord_ts_id
        and   ord1.ord_id=ts1.ord_id
        and   anno1.bil_id=ord1.bil_id
        and   per1.periodo_id=anno1.bil_id
        and   per1.anno::integer>=2020+1
        and   rsub1.data_cancellazione is null
        and   rsub1.validita_fine is null
       )
       and   rsub.data_cancellazione is null
       and   rsub.validita_fine is null
       and   ts.data_cancellazione is null
       and   ts.validita_fine is null
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
      )
      -- 2 esclusione pagamenti manuali dataOperazionePagamentoIncasso antecedente annoStorico
      and not exists
      (
        with
        doc_paga_man as
        (
        select rattr.doc_id,
               substring(coalesce(rattrDataPAga.testo,'01/01/'||(2020+1)::varchar||''),7,4)::integer annoDataPaga
        from siac_r_doc_attr rattr,siac_t_attr attr,
             siac_r_doc_Stato rs,siac_d_doc_Stato stato,
             siac_r_doc_attr rattrDataPaga,siac_t_attr attrDataPaga
        where rattr.doc_id=a.doc_id
        and   attr.attr_id=rattr.attr_id
        and   attr.attr_code='flagPagataIncassata'
        and   rattr.boolean='S'
        and   rs.doc_id=a.doc_id
        and   stato.doc_stato_id=rs.doc_stato_id
        and   stato.doc_stato_code='EM'
        and   rattrDataPaga.doc_id=a.doc_id
        and   attrDataPaga.attr_id=rattrDataPaga.attr_id
        and   attrdatapaga.attr_code='dataOperazionePagamentoIncasso'
        and   rattr.data_cancellazione is null
        and   rs.data_cancellazione is null
        and   rs.validita_fine is null
        )
        select query_doc_paga_man.*
        from doc_paga_man  query_doc_paga_man
        where query_doc_paga_man.annoDataPaga<=2020
      )
      -- 3 - esclusione documenti ANNULLATI IN ANNI ANTECEDENTI annoStorico
      and not exists
      (
         select 1
         where f.doc_stato_code='A'
         and  extract (year from e.validita_inizio)::integer<=2020
      )
      -- 4 - esclusione documenti STORNATI IN ANNI ANTECEDENTI annoStorico
      and not exists
      (
         select 1
         where f.doc_stato_code='ST'
         and  extract (year from e.validita_inizio)::integer<=2020
      )
      -- 19.01.2021 Sofia Jira SIAC_7966 - fine
      -- 26.01.2021 Sofia JIRA SIAC-7518 - fine
      AND a.data_cancellazione IS NULL
      AND b.data_cancellazione IS NULL
      AND c.data_cancellazione IS NULL
      AND e.data_cancellazione IS NULL
      AND f.data_cancellazione IS NULL
      AND g.data_cancellazione IS NULL
   )
   select doc_tot.*
   from doc_totale doc_tot
   limit 100
 ),
 docgru as
 (
   select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
   from siac_d_doc_gruppo a
   where a.ente_proprietario_id=2
   and a.data_cancellazione is null
 )
 select doc1.*, docgru.*
 from doc1 left join docgru on docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
),
bollo as
(
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc
  from siac_d_codicebollo a
  where a.ente_proprietario_id=2
  and a.data_cancellazione is null
),
sogg as
(
  with sogg1 as
  (
   select distinct
         a.doc_id,b.soggetto_code,
	     f.soggetto_stato_desc,
	     b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
	     b.soggetto_id
   from  siac_r_doc_sog a, siac_t_soggetto b ,
         siac_r_soggetto_stato e ,siac_d_soggetto_stato f
   where a.ente_proprietario_id=2
   and   b.soggetto_id=a.soggetto_id
   and   e.soggetto_id=b.soggetto_id
   and   f.soggetto_stato_id=e.soggetto_stato_id
   and   now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
   and a.data_cancellazione IS NULL
   and b.data_cancellazione IS NULL
   and e.data_cancellazione IS NULL
   and f.data_cancellazione IS NULL
  ),
  sogg2 as
  (
   select g.soggetto_id, g.ragione_sociale,g.validita_fine from  siac_t_persona_giuridica g
   where  g.ente_proprietario_id=2 and g.data_cancellazione is null
  ),
  sogg3 as
  (
   select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
   where  h.ente_proprietario_id=2 and h.data_cancellazione is null
  ),
  sogg5 as  /* OTT */
  (
   select c.soggetto_id,d.soggetto_tipo_desc
   from siac_d_soggetto_tipo d ,siac_r_soggetto_tipo c
   where d.ente_proprietario_id=2
   and   c.soggetto_tipo_id=d.soggetto_tipo_id
   and   c.data_cancellazione is null
   and   d.data_cancellazione is NULL
   AND   now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
  )
  select sogg1.*, sogg2.ragione_sociale, sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1
  left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
),
reguni as
(
 select a.doc_id,a.rudoc_registrazione_anno,
        a.rudoc_registrazione_numero,a.rudoc_registrazione_data
 from siac_t_registrounico_doc a where a.ente_proprietario_id=2 and a.data_cancellazione is null
),
cdr as  /** OTT **/
(
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
	     null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where c.ente_proprietario_id=2
  and   c.classif_tipo_code='CDR'
  and   b.classif_tipo_id=c.classif_tipo_id
  and   a.classif_id=b.classif_id
  and   now() BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, now())
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  AND  c.data_cancellazione IS NULL
),
cdc as /** OTT **/
( --4,953 sec;
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
	     d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where c.ente_proprietario_id=2
  and   c.classif_tipo_code='CDC'
  and   b.classif_tipo_id=c.classif_tipo_id
  and   a.classif_id=b.classif_id
  and   e.classif_id=b.classif_id
  and   d.classif_id=e.classif_id_padre
  and   now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
  and   now() BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, now())
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  AND   c.data_cancellazione IS NULL
  AND   d.data_cancellazione IS NULL
  AND   e.data_cancellazione IS NULL
),
pcccod as
(
  select a.pcccod_id,a.pcccod_code,a.pcccod_desc
  from   siac_d_pcc_codice  a where a.ente_proprietario_id=2 and a.data_cancellazione is null
),
pccuff as
(
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from  siac_d_pcc_ufficio  a where a.ente_proprietario_id=2 and a.data_cancellazione is null
),
-- subdoc
subdoc as
 (
 select
      h.doc_id, h.subdoc_id,
      h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
      h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
      case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
      h.subdoc_data_pagamento_cec,
      h.comm_tipo_id,
      h.notetes_id,h.dist_id,h.contotes_id,
      i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
      l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
      m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
from siac_t_subdoc h
            left join siac_d_siope_tipo_debito i
                 on ( i.siope_tipo_debito_id = h.siope_tipo_debito_id
                  and i.data_cancellazione is null
                  and i.validita_fine is null )
            left join siac_d_siope_assenza_motivazione l
                 on ( l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                  and l.data_cancellazione is null
                  and l.validita_fine is null )
            left join siac_d_siope_scadenza_motivo m
                 on ( m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                  and m.data_cancellazione is null
                  and m.validita_fine is null )
where h.ente_proprietario_id=2
and   h.data_cancellazione is null
 ),
attoamm as  -- subdoc_id
(
  with
  attoamm1 as /** OTT **/
  (
    select
    b.attoamm_id,
    a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
    d.attoamm_stato_code, d.attoamm_stato_desc,
    e.attoamm_tipo_code, e.attoamm_tipo_desc
    from siac_d_atto_amm_tipo e, siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
         siac_r_subdoc_atto_amm a
    where e.ente_proprietario_id=2
    and   b.attoamm_tipo_id=e.attoamm_tipo_id
    and   c.attoamm_id=b.attoamm_id
    and   a.attoamm_id=b.attoamm_id
    and   now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
    and   d.attoamm_stato_id=c.attoamm_stato_id
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
 ),
 cdr as  /** OTT **/
 (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_d_class_tipo c, siac_t_class b, siac_r_atto_amm_class a
  where c.ente_proprietario_id=2
  and   c.classif_tipo_code='CDR'
  and   b.classif_tipo_id=c.classif_tipo_id
  and   a.classif_id=b.classif_id
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
 ),
 cdc as  /** OTT **/
 (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from  siac_d_class_tipo c, siac_t_class b, siac_t_class d,siac_r_class_fam_tree e, siac_r_atto_amm_class a
  where c.ente_proprietario_id=2
  and   c.classif_tipo_code='CDC'
  and   b.classif_tipo_id=c.classif_tipo_id
  and   a.classif_id=b.classif_id
  and   e.classif_id=b.classif_id
  and   d.classif_id=e.classif_id_padre
  -- and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data) -- SIAC-5494
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
),
commt as
(
 select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
 from siac_d_commissione_tipo a where a.ente_proprietario_id=2 and a.data_cancellazione is null
),
eldocattall as
(
  with
  eldoc as  /** OTT **/
  (
    select a.subdoc_id,a.eldoc_id,
           b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
           b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
           d.eldoc_stato_code, d.eldoc_stato_desc
     from siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
          siac_d_elenco_doc_stato d, siac_r_elenco_doc_subdoc a
    where b.ente_proprietario_id=2
    and   c.eldoc_id=b.eldoc_id
    and   d.eldoc_stato_id=c.eldoc_stato_id
    and   a.eldoc_id=b.eldoc_id
    and   now() BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, now())
    and   now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
    and   a.data_cancellazione is null
    and   b.data_cancellazione is null
    and   c.data_cancellazione is null
    and   d.data_cancellazione is null
  ),
  attoal as
  (
   with
   attoall as /** OTT **/
   (
	select
         distinct
  	     a.eldoc_id,b.attoal_id,
	     b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc,
         b.data_creazione data_ins_atto_allegato,   -- 15.05.2018 Sofia siac-6124
	     fnc_siac_attoal_getDataStato(b.attoal_id,'C') data_completa_atto_allegato, -- 22.05.2018 Sofia siac-6124
         fnc_siac_attoal_getDataStato(b.attoal_id,'CV') data_convalida_atto_allegato  -- 22.05.2018 Sofia siac-6124
   from  siac_t_atto_allegato b, siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d, siac_r_atto_allegato_elenco_doc a
   where b.ente_proprietario_id=2
   and   c.attoal_id=b.attoal_id
   and   d.attoal_stato_id=c.attoal_stato_id
   and   a.attoal_id=b.attoal_id
   and   now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
   and   now() BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, now())
   and   a.data_cancellazione is null
   and   b.data_cancellazione is null
   and   c.data_cancellazione is null
   and   d.data_cancellazione is null
  ),
  soggattoall as
  (
    with
    sogg1 as /** OTT **/
    (
      select
       distinct
       a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
       f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
       b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
       b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
       b.soggetto_id soggetto_id_atto_allegato,
       -- 16.05.2018 Sofia siac-6124
       a.attoal_sog_data_sosp data_sosp_atto_allegato,
       a.attoal_sog_causale_sosp causale_sosp_atto_allegato,
       a.attoal_sog_data_riatt data_riattiva_atto_allegato
      from  siac_t_soggetto b , siac_r_soggetto_stato e ,siac_d_soggetto_stato f,
            siac_r_atto_allegato_sog a
      where  b.ente_proprietario_id=2
      and    e.soggetto_id=b.soggetto_id
      and    f.soggetto_stato_id=e.soggetto_stato_id
      and    a.soggetto_id=b.soggetto_id
      and    now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
      AND    a.data_cancellazione IS NULL
      AND    b.data_cancellazione IS NULL
      AND    e.data_cancellazione IS NULL
      AND    f.data_cancellazione IS NULL
   ),
   sogg2 as
   (
    select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
    where g.ente_proprietario_id=2 and g.data_cancellazione is null
   ),
   sogg3 as
   (
    select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
    where h.ente_proprietario_id=2 and h.data_cancellazione is null
   ),
   sogg5 as /** OTT **/
   (
    select  c.soggetto_id,d.soggetto_tipo_desc
    from    siac_d_soggetto_tipo d , siac_r_soggetto_tipo c
    where   d.ente_proprietario_id=2
    and     c.soggetto_tipo_id=d.soggetto_tipo_id
    and     c.data_cancellazione is null
    and     d.data_cancellazione is NULL
    AND     now() BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, now())
   )
   select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
   sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
   from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
   left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
   left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato ,
  -- 16.05.2018 Sofia siac-6124
  soggattoall.data_sosp_atto_allegato,
  soggattoall.causale_sosp_atto_allegato,
  soggattoall.data_riattiva_atto_allegato
  from attoall left join soggattoall on attoall.attoal_id=soggattoall.attoal_id
  )
  select
         distinct
         eldoc.*,
         attoal.attoal_id,
         attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
         attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
         attoal.soggetto_code_atto_allegato,
         attoal.soggetto_tipo_desc_atto_allegato,
         attoal.soggetto_stato_desc_atto_allegato,
  	     attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
         attoal.codice_fiscale_estero_atto_allegato,
         attoal.soggetto_id_atto_allegato,
         -- 15.05.2018 Sofia siac-6124
         attoal.data_ins_atto_allegato,
         attoal.data_sosp_atto_allegato,
         attoal.causale_sosp_atto_allegato,
         attoal.data_riattiva_atto_allegato,
         attoal.data_completa_atto_allegato,
        attoal.data_convalida_atto_allegato
  from eldoc left join attoal  on eldoc.eldoc_id=attoal.eldoc_id
)
select  doc.doc_id,subdoc.subdoc_id, count(*)
        /*doc.*, bollo.*,sogg.*,
        reguni.*,cdc.*,cdr.*,
        pcccod.*,pccuff.*,
        subdoc.*,
        commt.*,
        attoamm.*,
        eldocattall.**/
from doc
     left join bollo on doc.codbollo_id=bollo.codbollo_id
	 left join sogg  on doc.doc_id=sogg.doc_id
	 left join reguni on doc.doc_id=reguni.doc_id
	 left join cdc on doc.doc_id=cdc.doc_id
	 left join cdr on doc.doc_id=cdr.doc_id
	 left join pcccod on doc.pcccod_id=pcccod.pcccod_id
	 left join pccuff on doc.pccuff_id=pccuff.pccuff_id,
     subdoc
  	 left join commt on subdoc.comm_tipo_id=commt.comm_tipo_id
	 left join attoamm on subdoc.subdoc_id=attoamm.subdoc_id -- subdoc_id
	 left join eldocattall on subdoc.subdoc_id=eldocattall.subdoc_id
where doc.doc_id=subdoc.doc_id
group by doc.doc_id,subdoc.subdoc_id
having count(*)>1
-- 123 rows returned (execution time: 00:01:03; total time: 00:01:03)