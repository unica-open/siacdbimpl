/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac_v_dwh_registrazioni
(
    ente_proprietario_id,
    anno_bilancio,
    cod_tipo_evento,
    desc_tipo_evento,
    cod_tipo_mov_finanziario,
    desc_tipo_mov_finanziario,
    cod_evento,
    desc_evento,
    data_creazione_registrazione,
    cod_stato_registrazione,
    desc_stato_registrazione,
    ambito,
    validita_inizio,
    validita_fine,
    cod_pdc_fin_orig,
    desc_pdc_fin_orig,
    cod_pdc_fin_agg,
    desc_pdc_fin_agg,
    anno_movimento_mod,
    numero_movimento_mod,
    cod_submovimento_mod,
    anno_movimento,
    numero_movimento,
    cod_submovimento,
    doc_id,
    anno_doc,
    num_doc,
    cod_tipo_doc,
    data_emissione_doc,
    num_subdoc,
    cod_sogg_doc,
    anno_ordinativo,
    numero_ordinativo,
    anno_liquidazione,
    numero_liquidazione,
    numero_ricecon,
    anno_rateo_risconto,
    numero_pn_rateo_risconto,
    anno_pn_rateo_risconto
)
AS
WITH
registrazioni AS
(
    SELECT
      reg.ente_proprietario_id,
      per.anno,
      tipo.evento_tipo_code,
      tipo.evento_tipo_desc,
      coll.collegamento_tipo_code,
      coll.collegamento_tipo_desc,
      evento.evento_code,
      evento.evento_desc,
      reg.data_creazione,
      stato.regmovfin_stato_code,
      stato.regmovfin_stato_desc,
      ambito.ambito_code,
      reg.validita_inizio,
      reg.validita_fine,
      reg.classif_id_iniziale, reg.classif_id_aggiornato,
      revento.campo_pk_id, revento.campo_pk_id_2,
      revento.regmovfin_id
    FROM  siac_t_reg_movfin reg, siac_r_reg_movfin_stato rs, siac_d_reg_movfin_stato stato,
          siac_r_evento_reg_movfin revento,
          siac_d_evento evento, siac_d_collegamento_tipo coll,
          siac_d_evento_tipo tipo,
          siac_t_bil bil, siac_t_periodo per, siac_d_ambito ambito
    WHERE reg.regmovfin_id = rs.regmovfin_id
    AND   stato.regmovfin_stato_id = rs.regmovfin_stato_id
    AND   revento.regmovfin_id = reg.regmovfin_id
    AND   evento.evento_id = revento.evento_id
    AND   coll.collegamento_tipo_id = evento.collegamento_tipo_id
    AND   tipo.evento_tipo_id = evento.evento_tipo_id
    AND   bil.bil_id = reg.bil_id
    AND   per.periodo_id = bil.periodo_id
    AND   ambito.ambito_id = reg.ambito_id
    AND   reg.data_cancellazione IS NULL
    AND   rs.data_cancellazione IS NULL
    AND   revento.data_cancellazione IS NULL
    AND   evento.data_cancellazione IS NULL
    AND   stato.data_cancellazione IS NULL
    AND   tipo.data_cancellazione IS NULL
    AND   coll.data_cancellazione IS NULL
    AND   bil.data_cancellazione IS NULL
    AND   per.data_cancellazione IS NULL
    AND   ambito.data_cancellazione IS NULL
),
collegamento_I_A AS
(
SELECT a.movgest_id, a.movgest_anno, a.movgest_numero,revento.regmovfin_id
FROM   siac_t_movgest a,siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE  coll.collegamento_tipo_code in ('A','I')
and    evento.collegamento_tipo_id=coll.collegamento_tipo_id
and    revento.evento_id=evento.evento_id
and    a.movgest_id=revento.regmovfin_id
and    a.data_cancellazione IS NULL
),
collegamento_OP_OI AS
(
  SELECT a.ord_id, a.ord_anno, a.ord_numero, revento.regmovfin_id
  FROM   siac_t_ordinativo a,siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
  WHERE  coll.collegamento_tipo_code in ('OP','OI')
  and    evento.collegamento_tipo_id=coll.collegamento_tipo_id
  and    revento.evento_id=evento.evento_id
  and    a.ord_id=revento.campo_pk_id
  and    a.data_cancellazione IS NULL
  and    revento.data_cancellazione is null
),
collegamento_SI_SA AS
(
SELECT a.movgest_ts_id, b.movgest_anno, b.movgest_numero, a.movgest_ts_code,  revento.regmovfin_id
FROM  siac_t_movgest_ts a, siac_t_movgest b, siac_d_movgest_ts_tipo tipo,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE tipo.movgest_ts_tipo_code='S'
and   a.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
and   b.movgest_id = a.movgest_id
and   revento.campo_pk_id=a.movgest_ts_id
and   evento.evento_id=revento.evento_id
and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
and   coll.collegamento_tipo_code in ('SI','SA')
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
and   revento.data_cancellazione is null
),
collegamento_L AS
(
SELECT a.liq_id, a.liq_anno, a.liq_numero, revento.regmovfin_id
FROM   siac_t_liquidazione a,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE  coll.collegamento_tipo_code='L'
and    evento.collegamento_tipo_id=coll.collegamento_tipo_id
and    revento.evento_id=evento.evento_id
and    a.liq_id=revento.campo_pk_id
and    a.data_cancellazione IS NULL
and    revento.data_cancellazione is null
),
collegamento_MMGS_MMGE_a AS
(
SELECT DISTINCT tm.mod_id, tmov.movgest_anno, tmov.movgest_numero, tmt.movgest_ts_code,revento.regmovfin_id
FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
	  siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt, siac_t_movgest tmov,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE tm.mod_id = rms.mod_id
AND   rms.mod_stato_id = dms.mod_stato_id
AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
AND   tmov.movgest_id = tmt.movgest_id
AND   dms.mod_stato_code = 'V'
and   revento.campo_pk_id=tm.mod_id
and   evento.evento_id=revento.evento_id
and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
and   coll.collegamento_tipo_code in ('MMGS','MMGE')
AND   tm.data_cancellazione IS NULL
AND   rms.data_cancellazione IS NULL
AND   dms.data_cancellazione IS NULL
AND   tmtdm.data_cancellazione IS NULL
AND   tmt.data_cancellazione IS NULL
AND   tmov.data_cancellazione IS NULL
and    revento.data_cancellazione is null
),
collegamento_MMGS_MMGE_b AS
(
SELECT DISTINCT tm.mod_id, tmov.movgest_anno, tmov.movgest_numero, tmt.movgest_ts_code,revento.regmovfin_id
FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
      siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt, siac_t_movgest tmov,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE tm.mod_id = rms.mod_id
AND   rms.mod_stato_id = dms.mod_stato_id
AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
AND   tmov.movgest_id = tmt.movgest_id
AND   dms.mod_stato_code = 'V'
and   revento.campo_pk_id=tm.mod_id
and   evento.evento_id=revento.evento_id
and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
and   coll.collegamento_tipo_code in ('MMGS','MMGE')
AND   tm.data_cancellazione IS NULL
AND   rms.data_cancellazione IS NULL
AND   dms.data_cancellazione IS NULL
AND   rmtsm.data_cancellazione IS NULL
AND   tmt.data_cancellazione IS NULL
AND   tmov.data_cancellazione IS NULL
and   revento.data_cancellazione is null
),
collegamento_SS_SE AS
(

SELECT a.subdoc_id, b.doc_id, b.doc_anno, b.doc_numero, b.doc_data_emissione, a.subdoc_numero,
       c.doc_tipo_code, sog.soggetto_code,
       revento.regmovfin_id
FROM   siac_t_subdoc a, siac_t_doc b, siac_d_doc_tipo c ,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_r_doc_sog rsog, siac_t_soggetto sog
WHERE  a.doc_id = b.doc_id
AND    c.doc_tipo_id = b.doc_tipo_id
and    revento.campo_pk_id=a.subdoc_id
and    evento.evento_id=revento.evento_id
and    coll.collegamento_tipo_id=evento.collegamento_tipo_id
and    coll.collegamento_tipo_code in ('SS','SE')
and    rsog.doc_id=b.doc_id
and    sog.soggetto_id=rsog.soggetto_id
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL
and    revento.data_cancellazione is null
and    rsog.validita_fine is null
and    rsog.data_cancellazione is null
and    revento.data_cancellazione is null
),
collegamento_RT_RS AS
(
with
collegamento_RT as
(
SELECT revento.regmovfin_id,
       coll.collegamento_tipo_code,
	   pnrts.anno as anno_rateo_risconto,
       pn.pnota_progressivogiornale as numero_pn_rateo_risconto,
	   per.anno as anno_pn_rateo_risconto
FROM  siac_t_prima_nota pn,  siac_t_prima_nota_ratei_risconti pnrts, siac_t_bil bil, siac_t_periodo per,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE coll.collegamento_tipo_code='RT'
and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
and   revento.evento_id=evento.evento_id
and   pnrts.pnotarr_id=revento.campo_pk_id
and   pn.pnota_id=pnrts.pnota_id
and   bil.bil_id=pn.bil_id
and   per.periodo_id=bil.periodo_id
AND   pn.data_cancellazione IS NULL
AND   pnrts.data_cancellazione IS NULL
and   revento.data_cancellazione is null
),
collegamento_RS as
(
SELECT revento.regmovfin_id,
       coll.collegamento_tipo_code,
	   pnrts.anno as anno_rateo_risconto,
       pn.pnota_progressivogiornale as numero_pn_rateo_risconto,
	   per.anno as anno_pn_rateo_risconto
FROM  siac_t_prima_nota pn,  siac_t_prima_nota_ratei_risconti pnrts, siac_t_bil bil, siac_t_periodo per,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE coll.collegamento_tipo_code='RS'
and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
and   revento.evento_id=evento.evento_id
and   pnrts.pnotarr_id=revento.campo_pk_id
and   pn.pnota_id=pnrts.pnota_id
and   bil.bil_id=pn.bil_id
and   per.periodo_id=bil.periodo_id
AND   pn.data_cancellazione IS NULL
AND   pnrts.data_cancellazione IS NULL
and   revento.data_cancellazione is null
)
SELECT collegamento_RT.regmovfin_id,
       collegamento_RT.collegamento_tipo_code,
	   collegamento_RT.anno_rateo_risconto,
       collegamento_RT.numero_pn_rateo_risconto,
	   collegamento_RT.anno_pn_rateo_risconto
FROM  collegamento_RT
union
SELECT collegamento_RS.regmovfin_id,
       collegamento_RS.collegamento_tipo_code,
	   collegamento_RS.anno_rateo_risconto,
       collegamento_RS.numero_pn_rateo_risconto,
	   collegamento_RS.anno_pn_rateo_risconto
FROM  collegamento_RS
),
collegamento_RR_RE as
(
with
collegamento_RR AS
(
SELECT revento.regmovfin_id,
       coll.collegamento_tipo_code,
       ric_econ.ricecon_numero
FROM  siac_t_giustificativo giust, siac_t_richiesta_econ ric_econ,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE giust.ricecon_id = ric_econ.ricecon_id
and   revento.campo_pk_id=giust.gst_id
and   evento.evento_id=revento.evento_id
and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
and   coll.collegamento_tipo_code='RR'
AND   giust.data_cancellazione  IS NULL
AND   ric_econ.data_cancellazione  IS NULL
and   revento.data_cancellazione is null
),
collegamento_RE AS
(
SELECT revento.regmovfin_id,
       coll.collegamento_tipo_code,
       a.ricecon_numero
FROM  siac_t_richiesta_econ a,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll
WHERE coll.collegamento_tipo_code='RE'
and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
and   revento.evento_id=evento.evento_id
and   a.ricecon_id=revento.campo_pk_id
and   a.data_cancellazione  IS NULL
and   revento.data_cancellazione is null
)
select collegamento_RR.regmovfin_id,
       collegamento_RR.collegamento_tipo_code,
       collegamento_RR.ricecon_numero
from collegamento_RR
union
select collegamento_RE.regmovfin_id,
       collegamento_RE.collegamento_tipo_code,
       collegamento_RE.ricecon_numero
from collegamento_RE
),
pdcFin as
(
select c.classif_id, c.classif_code,c.classif_desc
from siac_d_class_tipo tipo,siac_t_class c
where tipo.classif_tipo_code='PDC_V'
and   c.classif_tipo_id=tipo.classif_tipo_id
and   c.data_cancellazione is null
)
select
    registrazioni.ente_proprietario_id,
    registrazioni.anno as anno_bilancio,
    registrazioni.evento_tipo_code as cod_tipo_evento,
    registrazioni.evento_tipo_desc as desc_tipo_evento,
    registrazioni.collegamento_tipo_code as cod_tipo_mov_finanziario,
    registrazioni.collegamento_tipo_desc as desc_tipo_mov_finanziario,
    registrazioni.evento_code as cod_evento,
    registrazioni.evento_desc as desc_evento,
    registrazioni.data_creazione as data_creazione_registrazione,
    registrazioni.regmovfin_stato_code as cod_stato_registrazione,
    registrazioni.regmovfin_stato_desc as desc_stato_registrazione,
    registrazioni.ambito_code as ambito,
    registrazioni.validita_inizio,
    registrazioni.validita_fine,
    pdcFinOrig.classif_code as cod_pdc_fin_orig,
    pdcFinOrig.classif_desc as desc_pdc_fin_orig,
    pdcFinAgg.classif_code as cod_pdc_fin_agg,
    pdcFinAgg.classif_desc as desc_pdc_fin_agg,
    COALESCE(collegamento_MMGS_MMGE_a.movgest_anno,collegamento_MMGS_MMGE_b.movgest_anno) as anno_movimento_mod,
    COALESCE(collegamento_MMGS_MMGE_a.movgest_numero,collegamento_MMGS_MMGE_b.movgest_numero) as numero_movimento_mod,
    COALESCE(collegamento_MMGS_MMGE_a.movgest_ts_code,collegamento_MMGS_MMGE_b.movgest_ts_code) as cod_submovimento_mod,
    COALESCE(collegamento_I_A.movgest_anno,collegamento_SI_SA.movgest_anno) as anno_movimento,
    COALESCE(collegamento_I_A.movgest_numero,collegamento_SI_SA.movgest_numero) as numero_movimento,
    collegamento_SI_SA.movgest_ts_code as cod_submovimento,
    collegamento_SS_SE.doc_id,
    collegamento_SS_SE.doc_anno as anno_doc,
    collegamento_SS_SE.doc_numero as num_doc,
    collegamento_SS_SE.doc_tipo_code as cod_tipo_doc,
    collegamento_SS_SE.doc_data_emissione as data_emissione_doc,
    collegamento_SS_SE.subdoc_numero as num_subdoc,
    collegamento_SS_SE.soggetto_code as cod_sogg_doc,
    collegamento_OP_OI.ord_anno as anno_ordinativo,
    collegamento_OP_OI.ord_numero as numero_ordinativo,
    collegamento_L.liq_anno as anno_liquidazione,
    collegamento_L.liq_numero as numero_liquidazione,
    collegamento_RR_RE.ricecon_numero as numero_ricecon,
    collegamento_RT_RS.anno_rateo_risconto,
    collegamento_RT_RS.numero_pn_rateo_risconto,
    collegamento_RT_RS.anno_pn_rateo_risconto
FROM registrazioni
	  left join  collegamento_OP_OI on
        (collegamento_OP_OI.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_I_A on
        (collegamento_I_A.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_SI_SA on
        (collegamento_SI_SA.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_L on
        (collegamento_L.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_MMGS_MMGE_a on
        (collegamento_MMGS_MMGE_a.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_MMGS_MMGE_b on
        (collegamento_MMGS_MMGE_b.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_SS_SE on
        (collegamento_SS_SE.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_RT_RS on
        (collegamento_RT_RS.regmovfin_id = registrazioni.regmovfin_id)
      left join collegamento_RR_RE on
         (collegamento_RR_RE.regmovfin_id = registrazioni.regmovfin_id)
      left join pdcFin pdcFinOrig on (pdcFinOrig.classif_id=registrazioni.classif_id_iniziale)
      left join pdcFin pdcFinAgg on (pdcFinAgg.classif_id=registrazioni.classif_id_aggiornato);