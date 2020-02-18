/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR replace FUNCTION fnc_gen_lancia_td_INC000001182764( annobilancio       INTEGER,
                                                              loginoperazione    VARCHAR,
                                                              dataelaborazione   TIMESTAMP,
                                                              enteProprietarioId integer,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR )
returns RECORD
AS
  $body$
  DECLARE

  datainizioval       timestamp:=NULL;
  strmessaggio        VARCHAR(1500):='';
  strmessaggiofinale  VARCHAR(1500):='';
  codresult           INTEGER:=null;
  bilancioId          integer:=null;
  enteRec   record;


  BEGIN
  codicerisultato:=NULL;
  messaggiorisultato:=NULL;

  strmessaggiofinale:='Inizio trattamento dati GEN-Liquidazioni-INC000001182764';
  datainizioval:= clock_timestamp();

  for enteRec in
  ( select e.ente_proprietario_id
    from siac_t_ente_proprietario e
    where e.ente_proprietario_id not in (1,2,3,7,8,15)
    and   (enteProprietarioId is null or e.ente_proprietario_id=enteProprietarioId)
    order by e.ente_proprietario_id
  )
  loop
  strMessaggio:='Lettura bilancioId per annoBilancio='
                ||annoBilancio::varchar||' ente_proprietario_id='||enteRec.ente_proprietario_id||'.';
  select bil.bil_id into bilancioId
  from siac_t_bil bil , siac_t_periodo per
  where bil.ente_proprietario_id=enteRec.ente_proprietario_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::integer=annoBilancio;

  if bilancioId is null then
  	 raise exception ' Identificativo non reperito.';
  end if;

  -- (I2) ---------------------------------------------------------------------------------
  ------------- INSERT - UPDATE DATI IN TABELLA DI APPOGGIO PER L(1)
  -------------  T1 M1	M2	M5	M6	M7	M8	M9	M10
  strMessaggio:='Popolamento (L1) liquidazioni_non_contab per T1 M1	M2	M5	M6	M7	M8	M9	M10.';
  insert into gen_lancia_td_INC000001182764_log
  (ente_proprietario_id,bil_id,log_descrizione)
  values
  (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- INIZIO.');

  insert into liquidazioni_non_contab
  (liq_id,bil_id,liq_anno,liq_numero,
   evmovfin_liq_id,regmovfin_liq_id,
   movgest_id,movgest_ts_id,
   movgest_anno,movgest_numero,movgest_subnumero,
   movgest_macro,movgest_pdcfin,movgest_pdcfin_id, ente_proprietario_id )
   (with
    TitoliMacroaggregati as
   (select titolo.ente_proprietario_id,
           titolo.classif_id titolo_classif_id,
           titolo.classif_code titolo_classif_code, titolo.classif_desc titolo_classif_desc,
           macro.classif_id macro_classif_id,
           macro.classif_code macro_classif_code, macro.classif_desc macro_classif_desc,
           rfmt.livello
 	from  siac_t_class_fam_tree rtre, siac_t_class_fam_tree tre,
     	  siac_r_class_fam_tree rfmt,
	      siac_t_class titolo,siac_t_class macro
	where tre.ente_proprietario_id=enteRec.ente_proprietario_id
	and   tre.class_fam_code='Spesa - TitoliMacroaggregati'
	and   rtre.classif_fam_id=tre.classif_fam_id
	and   rfmt.classif_fam_tree_id=rtre.classif_fam_tree_id
	and   titolo.classif_id=rfmt.classif_id_padre
	and   macro.classif_id=rfmt.classif_id
	and   titolo.classif_code='1' --T1
	and   ( macro.classif_code like '101%' or -- M1
    	    macro.classif_code like '102%' or -- M2
        	macro.classif_code like '105%' or -- M5
	        macro.classif_code like '106%' or -- M6
    	    macro.classif_code like '107%' or -- M7
        	macro.classif_code like '108%' or -- M8
        	macro.classif_code like '109%' or -- M9
	        macro.classif_code like '110%'  -- M10
    	  )
	and   tre.data_cancellazione is null
	and   tre.validita_fine is null
	and   rtre.data_cancellazione is null
	and   rtre.validita_fine is null
	and   rfmt.data_cancellazione is null
	and   rfmt.validita_fine is null
	and   titolo.data_cancellazione is null
	and   titolo.validita_fine is null
	and   macro.data_cancellazione is null
	and   macro.validita_fine is null
	order by rfmt.livello
   ),
   pdcFin as
  (select tipo.ente_proprietario_id,
          pdcFin.classif_id pdcfin_classif_id,
    	  substring(regexp_replace(PdcFin.classif_code, '[\.]', '', 'gi') from 2 for 7) pdcfin_macro_code,
          pdcFin.classif_code pdcfin_classif_code,
          pdcFin.classif_desc pdcfin_classif_desc
          from siac_t_class PdcFin,siac_d_class_tipo tipo
   where tipo.ente_proprietario_id=enteRec.ente_proprietario_id
   and   tipo.classif_tipo_code like 'PDC_%'
   and   tipo.classif_tipo_id=PdcFin.classif_tipo_id
   and   substring(PdcFin.classif_code from 1 for 1)='U'
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null
   and   PdcFin.data_cancellazione is null
  ),
  pdcFinLiq as
  (select pdcFin.ente_proprietario_id,
          liq.liq_id  pdcFinLiq_liq_id,
          liq.bil_id  pdcFinLiq_bil_id,
          liq.liq_anno pdcFinLiq_liq_anno,
          liq.liq_numero pdcFinLiq_liq_numero,
          m.movgest_anno pdcFinLiq_liq_movgest_anno,
          m.movgest_numero pdcFinLiq_liq_movgest_numero,
         ts.movgest_ts_code pdcFinLiq_liq_movgest_subnum,
         m.movgest_id  pdcFinLiq_movgest_id,
        (case when tstipo.movgest_ts_tipo_code='T' then null
              else ts.movgest_ts_id end) pdcFinLiq_movgest_ts_id,
        pdcFin.classif_id pdcFinLiq_classif_id,
        substring(regexp_replace(PdcFin.classif_code, '[\.]', '', 'gi') from 2 for 7) pdcFinLiq_macro_code,
        pdcFin.classif_code pdcFinLiq_classif_code,
        pdcFin.classif_desc pdcFinLiq_classif_desc
  from siac_t_liquidazione liq,siac_t_bil bil, siac_t_periodo per,
       siac_r_liquidazione_movgest rm,
       siac_t_movgest m,
       siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
       siac_r_movgest_class r,
       siac_t_class pdcFin , siac_d_class_tipo tipo,
       siac_r_liquidazione_stato rstato, siac_d_liquidazione_stato stato
   where bil.ente_proprietario_id=enteRec.ente_proprietario_id
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio
   and   liq.bil_id=bil.bil_id
   and   rm.liq_id=liq.liq_id
   and   ts.movgest_ts_id=rm.movgest_ts_id
   and   m.movgest_id=ts.movgest_id
   and   r.movgest_ts_id=ts.movgest_ts_id
   and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
   and   pdcFin.classif_id=r.classif_id
   and   tipo.classif_tipo_id=pdcFin.classif_tipo_id
   and   tipo.classif_tipo_code like 'PDC_%'
   and   rstato.liq_id=liq.liq_id
   and   stato.liq_stato_id=rstato.liq_stato_id
   and   stato.liq_stato_code!='A'
   and   liq.data_cancellazione is null
   and   liq.validita_fine is null
   and   rm.data_cancellazione is null
   and   rm.validita_fine is null
   and   ts.data_cancellazione is null
   and   ts.validita_fine is null
   and   m.data_cancellazione is null
   and   m.validita_fine is null
   and   pdcFin.data_cancellazione is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null
   and   rstato.data_cancellazione is null
   and   rstato.validita_fine is null
  ),
  liqGen as
 (SELECT a.evmovfin_id  liqGen_evmovfin_id,
         a.regmovfin_id liqGen_regmovfin_id,
         a.campo_pk_id liqGen_liq_id,
         b.evento_code,b.evento_desc,
         c.evento_tipo_code,c.evento_tipo_desc,
         d.collegamento_tipo_code,d.collegamento_tipo_desc
  from  siac_r_evento_reg_movfin a, siac_d_evento b, siac_d_evento_tipo c,siac_d_collegamento_tipo d,
        siac_t_liquidazione l, siac_t_bil bil, siac_t_periodo per,
        siac_r_liquidazione_stato rstato, siac_d_liquidazione_stato stato,
      siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato regstato
  where bil.ente_proprietario_id=enteRec.ente_proprietario_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::integer=annoBilancio
  and   l.bil_id=bil.bil_id
  and   rstato.liq_id=l.liq_id
  and   stato.liq_stato_id=rstato.liq_stato_id
  and   stato.liq_stato_code!='A'
  and   a.campo_pk_id=l.liq_id
  and   rrstato.regmovfin_id=a.regmovfin_id
  and   regstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
  and   regstato.regmovfin_stato_code!='A'
  and   a.evento_id=b.evento_id
  and   b.evento_tipo_id=c.evento_tipo_id
  and   b.collegamento_tipo_id=d.collegamento_tipo_id
  and   d.collegamento_tipo_code='L'
  and   l.data_cancellazione is null
  and   l.validita_fine is null
  and   a.data_cancellazione is null
  and   a.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   rrstato.data_cancellazione is null
  and   rrstato.validita_fine is null
 )
 (select PdcFinLiq.pdcFinLiq_liq_id ,
         PdcFinLiq.pdcFinLiq_bil_id ,
         pdcFinLiq_liq_anno,pdcFinLiq_liq_numero,
         coalesce(liqGen.liqGen_evmovfin_id,0),
         coalesce(liqGen.liqGen_regmovfin_id,0),
         pdcFinLiq.pdcFinLiq_movgest_id,pdcFinLiq.pdcFinLiq_movgest_ts_id,
         pdcFinLiq_liq_movgest_anno,pdcFinLiq_liq_movgest_numero,pdcFinLiq_liq_movgest_subnum::integer,
         pdcFinLiq.pdcFinLiq_macro_code,
         pdcFinLiq.pdcFinLiq_classif_code,
         pdcFinLiq.pdcFinLiq_classif_id,
         TitoliMacroaggregati.ente_proprietario_id
   from PdcFin, TitoliMacroaggregati,
        pdcFinLiq left outer join liqGen on (liqGen.liqGen_liq_id=PdcFinLiq.pdcFinLiq_liq_id)
   where TitoliMacroaggregati.ente_proprietario_id=enteRec.ente_proprietario_id
   and   PdcFin.pdcfin_macro_code =TitoliMacroaggregati.macro_classif_code
   and   substring(pdcFinLiq.pdcFinLiq_macro_code from 1 for 3)=
         substring(PdcFin.pdcfin_macro_code from 1 for 3)
   and   liqGen.liqGen_liq_id is null
  order by TitoliMacroaggregati.livello
 ));
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
  values
  (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- FINE.');


 codResult:=null;
 select coalesce(count(*),0) into codResult
 from liquidazioni_non_contab l
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and    l.evmovfin_liq_id=0
 and    l.regmovfin_liq_id=0;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- inserite numLiq='||codResult||'.');



 -- (I3) --------------------------------------------------------------------------
 -----------  INSERT IN TABELLA APPOGGIO PER L(2)
 -----------   T1	M3 , T2   M2

 strMessaggio:='Popolamento (L2) liquidazioni_non_contab per T1 M3, T2 M2.';
 insert into gen_lancia_td_INC000001182764_log
 (ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- INIZIO.');

 insert into liquidazioni_non_contab
 (liq_id,bil_id,liq_anno,liq_numero,
  evmovfin_liq_id,regmovfin_liq_id,
  movgest_id,movgest_ts_id,
  movgest_anno,movgest_numero,movgest_subnumero,
  movgest_macro,movgest_pdcfin,movgest_pdcfin_id, ente_proprietario_id )
 (
  with
  TitoliMacroaggregati as
  (select titolo.ente_proprietario_id,
          titolo.classif_id titolo_classif_id,
          titolo.classif_code titolo_classif_code, titolo.classif_desc titolo_classif_desc,
          macro.classif_id macro_classif_id,
         macro.classif_code macro_classif_code, macro.classif_desc macro_classif_desc,
         rfmt.livello
  from  siac_t_class_fam_tree rtre, siac_t_class_fam_tree tre,
        siac_r_class_fam_tree rfmt,
        siac_t_class titolo,siac_t_class macro
  where tre.ente_proprietario_id=enteRec.ente_proprietario_id
  and   tre.class_fam_code='Spesa - TitoliMacroaggregati'
  and   rtre.classif_fam_id=tre.classif_fam_id
  and   rfmt.classif_fam_tree_id=rtre.classif_fam_tree_id
  and   titolo.classif_id=rfmt.classif_id_padre
  and   macro.classif_id=rfmt.classif_id
  and   (( titolo.classif_code='1' and macro.classif_code like '103%' ) or  --T1M3
		( titolo.classif_code='2' and macro.classif_code like '202%' )     --T2M2
       )
  and   tre.data_cancellazione is null
  and   tre.validita_fine is null
  and   rtre.data_cancellazione is null
  and   rtre.validita_fine is null
  and   rfmt.data_cancellazione is null
  and   rfmt.validita_fine is null
  and   titolo.data_cancellazione is null
  and   titolo.validita_fine is null
  and   macro.data_cancellazione is null
  and   macro.validita_fine is null
  order by rfmt.livello
 ),
 pdcFin as
 (select tipo.ente_proprietario_id,
         pdcFin.classif_id pdcfin_classif_id,
         substring(regexp_replace(PdcFin.classif_code, '[\.]', '', 'gi') from 2 for 7) pdcfin_macro_code,
         pdcFin.classif_code pdcfin_classif_code,
         pdcFin.classif_desc pdcfin_classif_desc
  from siac_t_class PdcFin,siac_d_class_tipo tipo
  where tipo.ente_proprietario_id=enteRec.ente_proprietario_id
  and   tipo.classif_tipo_code like 'PDC_%'
  and   tipo.classif_tipo_id=PdcFin.classif_tipo_id
  and   substring(PdcFin.classif_code from 1 for 1)='U'
  and   tipo.data_cancellazione is null
  and   tipo.validita_fine is null
  and   PdcFin.data_cancellazione is null
  and   PdcFin.validita_fine is null
 ),
 pdcFinLiq as
 (select pdcFin.ente_proprietario_id,
         liq.liq_id  pdcFinLiq_liq_id,
         liq.bil_id  pdcFinLiq_bil_id,
         liq.liq_anno pdcFinLiq_liq_anno,
         liq.liq_numero pdcFinLiq_liq_numero,
         m.movgest_anno pdcFinLiq_liq_movgest_anno,
         m.movgest_numero pdcFinLiq_liq_movgest_numero,
         ts.movgest_ts_code pdcFinLiq_liq_movgest_subnum,
         m.movgest_id  pdcFinLiq_movgest_id,
         (case when tstipo.movgest_ts_tipo_code='T' then null
              else ts.movgest_ts_id end) pdcFinLiq_movgest_ts_id,
         pdcFin.classif_id pdcFinLiq_classif_id,
         substring(regexp_replace(PdcFin.classif_code, '[\.]', '', 'gi') from 2 for 7) pdcFinLiq_macro_code,
         pdcFin.classif_code pdcFinLiq_classif_code,
         pdcFin.classif_desc pdcFinLiq_classif_desc
  from siac_t_liquidazione liq,
       siac_r_liquidazione_movgest rm,
       siac_t_movgest m,
       siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
       siac_r_movgest_class r,
       siac_t_class pdcFin , siac_d_class_tipo tipo,
       siac_t_bil bil, siac_t_periodo per,
       siac_r_liquidazione_stato rstato, siac_d_liquidazione_stato stato
  where bil.ente_proprietario_id=enteRec.ente_proprietario_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::integer=annoBilancio
  and   liq.bil_id=bil.bil_id
  and   rstato.liq_id=liq.liq_id
  and   stato.liq_stato_id=rstato.liq_stato_id
  and   stato.liq_stato_code!='A'
  and   rm.liq_id=liq.liq_id
  and   ts.movgest_ts_id=rm.movgest_ts_id
  and   m.movgest_id=ts.movgest_id
  and   r.movgest_ts_id=ts.movgest_ts_id
  and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
  and   pdcFin.classif_id=r.classif_id
  and   tipo.classif_tipo_id=pdcFin.classif_tipo_id
  and   tipo.classif_tipo_code like 'PDC_%'
  and   liq.data_cancellazione is null
  and   liq.validita_fine is null
  and   rm.data_cancellazione is null
  and   rm.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   m.data_cancellazione is null
  and   m.validita_fine is null
  and   pdcFin.data_cancellazione is null
  and   pdcFin.validita_fine is NULL
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   not exists
  (SELECT 1
   from siac_t_subdoc sub, siac_t_doc doc,siac_d_doc_tipo tipo,siac_d_doc_fam_tipo ftipo,
        siac_r_evento_reg_movfin a,siac_d_evento b,siac_d_collegamento_tipo d,siac_d_evento_tipo c,
        siac_r_subdoc_liquidazione rliq,
        siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato regstato
   where doc.ente_proprietario_id=liq.ente_proprietario_id
   and   tipo.doc_tipo_id=doc.doc_tipo_id
   and   ftipo.doc_fam_tipo_id=tipo.doc_fam_tipo_id
   and   ftipo.doc_fam_tipo_code in ('S','IS')
   and   sub.doc_id=doc.doc_id
   and   rliq.subdoc_id=sub.subdoc_id
   and   rliq.liq_id=liq.liq_id
   and   a.campo_pk_id=sub.subdoc_id
   and   rrstato.regmovfin_id=a.regmovfin_id
   and   regstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   regstato.regmovfin_stato_code!='A'
   and   b.evento_id=a.evento_id
   and   c.evento_tipo_id=b.evento_tipo_id
   and   d.collegamento_tipo_id= b.collegamento_tipo_id
   and   d.collegamento_tipo_code='SS'
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   a.data_cancellazione is null
   and   a.validita_fine is null
   and   rliq.data_cancellazione is null
   and   rliq.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
  )
 ),
 liqGen as
 (SELECT a.campo_pk_id liqGen_liq_id,
         a.evmovfin_id liqGen_evmovfin_id,
         a.regmovfin_id liqGen_regmovfin_id,
         b.evento_code,b.evento_desc,
         c.evento_tipo_code,c.evento_tipo_desc,
         d.collegamento_tipo_code,d.collegamento_tipo_desc
  from siac_r_evento_reg_movfin a, siac_d_evento b, siac_d_evento_tipo c,siac_d_collegamento_tipo d,
       siac_t_liquidazione l,siac_t_bil bil, siac_t_periodo per,
       siac_r_liquidazione_stato rstato, siac_d_liquidazione_Stato stato,
       siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato regstato
 where bil.ente_proprietario_id=enteRec.ente_proprietario_id
 and   per.periodo_id=bil.periodo_id
 and   per.anno::integer=annoBilancio
 and   l.bil_id=bil.bil_id
 and   rstato.liq_id=l.liq_id
 and   stato.liq_stato_id=rstato.liq_stato_id
 and   stato.liq_stato_code!='A'
 and   l.liq_id=a.campo_pk_id
 and   a.evento_id=b.evento_id
 and   rrstato.regmovfin_id=a.regmovfin_id
 and   regstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
 and   regstato.regmovfin_stato_code!='A'
 and   b.evento_tipo_id=c.evento_tipo_id
 and   b.collegamento_tipo_id=d.collegamento_tipo_id
 and   a.ente_proprietario_id=enteRec.ente_proprietario_id
 and   d.collegamento_tipo_code='L'
 and   l.data_cancellazione is null
 and   l.validita_fine is null
 and   a.data_cancellazione is null
 and   a.validita_fine is null
 and   rstato.data_cancellazione is null
 and   rstato.validita_fine is null
 and   rrstato.data_cancellazione is null
 and   rrstato.validita_fine is null
 )
 (select PdcFinLiq.pdcFinLiq_liq_id ,
  	     PdcFinLiq.pdcFinLiq_bil_id ,
         pdcFinLiq_liq_anno,pdcFinLiq_liq_numero,
         coalesce(liqGen.liqGen_evmovfin_id,0),coalesce(liqGen.liqGen_regmovfin_id,0),
         pdcFinLiq.pdcFinLiq_movgest_id,pdcFinLiq.pdcFinLiq_movgest_ts_id,
         pdcFinLiq_liq_movgest_anno,pdcFinLiq_liq_movgest_numero,pdcFinLiq_liq_movgest_subnum::integer,
         pdcFinLiq.pdcFinLiq_macro_code,
         pdcFinLiq.pdcFinLiq_classif_code,
         pdcFinLiq.pdcFinLiq_classif_id,
         TitoliMacroaggregati.ente_proprietario_id
 from PdcFin, TitoliMacroaggregati,
      pdcFinLiq left outer join liqGen on (liqGen.liqGen_liq_id=PdcFinLiq.pdcFinLiq_liq_id)
 where TitoliMacroaggregati.ente_proprietario_id=enteRec.ente_proprietario_id
 and   PdcFin.pdcfin_macro_code =TitoliMacroaggregati.macro_classif_code
 and   substring(pdcFinLiq.pdcFinLiq_macro_code from 1 for 3)=
       substring(PdcFin.pdcfin_macro_code from 1 for 3)
 and   liqGen.liqGen_liq_id is null
 order by TitoliMacroaggregati.livello)
 );
 insert into gen_lancia_td_INC000001182764_log
 (ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- FINE.');


 codResult:=null;
 select coalesce(count(*),0) into codResult
 from liquidazioni_non_contab l
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_liq_id=0;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- inserite numLiq='||codResult||'.');

 -- controlli liquidazioni da trattare tipo L1, L2 - INIZIO
 strMessaggio:='Popolamento (L1,L2) liquidazioni_non_contab.Verifica esistenza Liquidazioni da trattare.';
 codResult:=null;
 select count(*) into codResult
 from liquidazioni_non_contab l
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.regmovfin_liq_id=0;
 if codResult is null or codResult=0 then
    insert into gen_lancia_td_INC000001182764_log
    ( ente_proprietario_id,bil_id,log_descrizione)
    values
    (enteRec.ente_proprietario_id,bilancioId,strmessaggio||' Nessuna liquidazione da trattare.');
    continue;

 end if;

 strMessaggio:='Popolamento (L1,L2) liquidazioni_non_contab.Verifica esistenza rec multipli per Liquidazione.';
 codResult:=null;
 select count(*) into codResult
 from
 ( select count(*), l.liq_id
  from liquidazioni_non_contab l
  where l.ente_proprietario_id=enteRec.ente_proprietario_id
  and   l.bil_id=bilancioId
  and   l.regmovfin_liq_id=0
  group by l.liq_id
  having count(*)>1
 ) Q;
 if codResult is not null and codResult!=0 then
    insert into gen_lancia_td_INC000001182764_log
    ( ente_proprietario_id,bil_id,log_descrizione)
    values
    (enteRec.ente_proprietario_id,bilancioId,strmessaggio||' Multipli esistenti.');
    continue;

 end if;

 -- controlli liquidazioni da trattare tipo L1, L2 - FINE

 -- LIQUIDAZIONI (L1) T1 M1	M2	M5	M6	M7	M8	M9	M10

 --  update per regmovfin_imp_id per impegno/subimpegno o subdocumento
 --  impegno
 --  (L1) T1 M1	M2	M5	M6	M7	M8	M9	M10
 strMessaggio:='Popolamento (L1) liquidazioni_non_contab per T1 M1	M2	M5	M6	M7	M8	M9	M10. Aggiornamento id GEN impegno collegato liquidazione.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- INIZIO.');

 update liquidazioni_non_contab l
 set regmovfin_imp_id=a.regmovfin_id,
     evmovfin_imp_id=a.evmovfin_id
 from siac_r_evento_reg_movfin a, siac_d_evento b, siac_d_evento_tipo c,siac_d_collegamento_tipo d,
      siac_t_movgest m,siac_d_movgest_tipo tipo,
      siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato regstato
 where  l.ente_proprietario_id=enteRec.ente_proprietario_id
 and    l.bil_id=bilancioId
 and    l.movgest_ts_id is null
 and    l.evmovfin_liq_id=0
 and    l.regmovfin_liq_id=0
 and    m.ente_proprietario_id=l.ente_proprietario_id
 and    m.movgest_id=l.movgest_id
 and    tipo.movgest_tipo_id=m.movgest_tipo_id
 and    tipo.movgest_tipo_code='I'
 and    a.campo_pk_id=m.movgest_id
 and    a.evento_id=b.evento_id
 and    rrstato.regmovfin_id=a.regmovfin_id
 and    regstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
 and    regstato.regmovfin_stato_code!='A'
 and    b.evento_tipo_id=c.evento_tipo_id
 and    b.collegamento_tipo_id=d.collegamento_tipo_id
 and    a.ente_proprietario_id=m.ente_proprietario_id
 and    d.collegamento_tipo_code='I'
 and    a.data_cancellazione is null
 and    a.validita_fine is null
 and    rrstato.data_cancellazione is null
 and    rrstato.validita_fine is null;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- FINE.');

 --  update per regmovfin_imp_id per impegno/subimpegno o subdocumento
 --  subimpegno
 --  (L1) T1	M1	M2	M5	M6	M7	M8	M9	M10
 strMessaggio:='Popolamento (L1) liquidazioni_non_contab per T1 M1	M2	M5	M6	M7	M8	M9	M10. Aggiornamento id GEN subimpegno collegato liquidazione.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- INIZIO.');
 update liquidazioni_non_contab l
 set regmovfin_imp_id=a.regmovfin_id,
     evmovfin_imp_id=a.evmovfin_id
 from siac_r_evento_reg_movfin a, siac_d_evento b, siac_d_evento_tipo c,siac_d_collegamento_tipo d,
      siac_t_movgest_ts g, siac_d_movgest_ts_tipo tstipo,
      siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato regstato
 where  l.ente_proprietario_id=enteRec.ente_proprietario_id
 and    l.bil_id=bilancioId
 and    l.movgest_ts_id is not null
 and    l.evmovfin_liq_id=0
 and    l.regmovfin_liq_id=0
 and    g.movgest_ts_id=l.movgest_ts_id
 and    a.evento_id=b.evento_id
 and    rrstato.regmovfin_id=a.regmovfin_id
 and    regstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
 and    regstato.regmovfin_stato_code!='A'
 and    b.evento_tipo_id=c.evento_tipo_id
 and    b.collegamento_tipo_id=d.collegamento_tipo_id
 and    a.ente_proprietario_id=l.ente_proprietario_id
 and    d.collegamento_tipo_code='SI'
 and    g.movgest_ts_id=a.campo_pk_id
 and    tstipo.movgest_ts_tipo_id=g.movgest_ts_tipo_id
 and    tstipo.movgest_ts_tipo_code='S'
 and    a.data_cancellazione is null
 and    a.validita_fine is null
 and    rrstato.data_cancellazione is null
 and    rrstato.validita_fine is null;
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- FINE.');


 --  update per regmovfin_imp_id per impegno/subimpegno o subdocumento
 --  subdcoumento
 --  (L1) T1	M1	M2	M5	M6	M7	M8	M9	M10
 strMessaggio:='Popolamento (L1) liquidazioni_non_contab per T1 M1	M2	M5	M6	M7	M8	M9	M10. Aggiornamento id GEN subdocumento collegato liquidazione.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- INIZIO.');
 update liquidazioni_non_contab l
 set  doc_id=doc.doc_id,
      subdoc_id=sub.subdoc_id,
      regmovfin_subdoc_id=a.regmovfin_id,
      evmovfin_subdoc_id=a.evmovfin_id
 from siac_t_subdoc sub, siac_t_doc doc,siac_d_doc_tipo tipo,siac_d_doc_fam_tipo ftipo,
      siac_r_evento_reg_movfin a,siac_d_evento b,siac_d_collegamento_tipo d,siac_d_evento_tipo c,
      siac_r_subdoc_liquidazione rliq,
      siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato regstato
 where  l.ente_proprietario_id=enteRec.ente_proprietario_id
 and    l.bil_id=bilancioId
 and    l.evmovfin_liq_id=0
 and    l.regmovfin_liq_id=0
 and    doc.ente_proprietario_id=l.ente_proprietario_id
 and   tipo.doc_tipo_id=doc.doc_tipo_id
 and   ftipo.doc_fam_tipo_id=tipo.doc_fam_tipo_id
 and   ftipo.doc_fam_tipo_code in ('S','IS')
 and   sub.doc_id=doc.doc_id
 and   rliq.subdoc_id=sub.subdoc_id
 and   rliq.liq_id=l.liq_id
 and   a.campo_pk_id=sub.subdoc_id
 and   rrstato.regmovfin_id=a.regmovfin_id
 and   regstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
 and   regstato.regmovfin_stato_code!='A'
 and   b.evento_id=a.evento_id
 and   c.evento_tipo_id=b.evento_tipo_id
 and   d.collegamento_tipo_id= b.collegamento_tipo_id
 and   d.collegamento_tipo_code='SS'
 and   doc.data_cancellazione is null
 and   doc.validita_fine is null
 and   sub.data_cancellazione is null
 and   sub.validita_fine is null
 and   a.data_cancellazione is null
 and   a.validita_fine is null
 and   rliq.data_cancellazione is null
 and   rliq.validita_fine is null
 and    rrstato.data_cancellazione is null
 and    rrstato.validita_fine is null;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'- FINE.');






 --- inizio trattamento prime note e regmov_fin per
 --- impegni/subimpegni/documenti

 --- inizio trattamento dati per regmov_fin subdocumenti
 --- inizio trattamento dati per prime note


 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab in stato diverso da Notificato.Annullamento Prima Nota subdocumenti.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');

 -- inserimento stato A prima nota subdocumento
 insert into siac_r_prima_nota_stato
 (pnota_id,
  pnota_stato_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select  distinct pn.pnota_id,
         pnstatoA.pnota_stato_id,
         datainizioval,
         loginOperazione,
         pn.ente_proprietario_id
 from liquidazioni_non_contab l, siac_r_reg_movfin_stato r, siac_d_reg_movfin_stato stato,
      siac_t_mov_ep ep, siac_t_prima_nota pn, siac_r_prima_nota_stato rpn, siac_d_prima_nota_stato pnstato,
      siac_d_prima_nota_stato pnstatoA
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_subdoc_id is not null
 and   r.regmovfin_id=l.regmovfin_subdoc_id
 and   stato.regmovfin_stato_id=r.regmovfin_stato_id
 and   stato.regmovfin_stato_code!='N'
 and   ep.regmovfin_id=r.regmovfin_id
 and   pn.pnota_id=ep.regep_id
 and   rpn.pnota_id=pn.pnota_id
 and   pnstato.pnota_stato_id=rpn.pnota_stato_id
 and   pnstato.pnota_stato_code!='A'
 and   pnstatoA.ente_proprietario_id=l.ente_proprietario_id
 and   pnstatoA.pnota_stato_code='A'
 and   r.data_cancellazione is null
 and   r.validita_fine is null
 and   ep.data_cancellazione is null
 and   ep.validita_fine is null
 and   pn.data_cancellazione is null
 and   pn.validita_fine is null
 and   rpn.data_cancellazione is null
 and   rpn.validita_fine is null;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');


 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab in stato diverso da Notificato.Chiusura stato Prima Nota subdocumenti.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');

 -- chiusura stato !='A' per le prime note di registrazioni non Notificate
 update siac_r_prima_nota_stato rpn
 set    data_cancellazione=datainizioval,
        validita_fine=datainizioval,
        login_operazione=rpn.login_operazione||'-'||loginOperazione
 from liquidazioni_non_contab l, siac_r_reg_movfin_stato r, siac_d_reg_movfin_stato stato,
      siac_t_mov_ep ep, siac_t_prima_nota pn,  siac_d_prima_nota_stato pnstato
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_subdoc_id is not null
 and   r.regmovfin_id=l.regmovfin_subdoc_id
 and   stato.regmovfin_stato_id=r.regmovfin_stato_id
 and   stato.regmovfin_stato_code!='N'
 and   ep.regmovfin_id=r.regmovfin_id
 and   pn.pnota_id=ep.regep_id
 and   rpn.pnota_id=pn.pnota_id
 and   pnstato.pnota_stato_id=rpn.pnota_stato_id
 and   pnstato.pnota_stato_code!='A'
 and   r.data_cancellazione is null
 and   r.validita_fine is null
 and   ep.data_cancellazione is null
 and   ep.validita_fine is null
 and   pn.data_cancellazione is null
 and   pn.validita_fine is null
 and   rpn.data_cancellazione is null
 and   rpn.validita_fine is null;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');


 -- inizio trattamento gestione regmov_fin

 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab.Chiusura stato registro subdocumenti.Inserimento stato annullato.';
 -- inserimento stato A
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');
 insert into siac_r_reg_movfin_stato
 ( regmovfin_id,
   regmovfin_stato_id ,
   validita_inizio,
   login_operazione,
   ente_proprietario_id
 )
 select  l.regmovfin_subdoc_id,
         stato.regmovfin_stato_id,
         datainizioval,
         loginOperazione,
         stato.ente_proprietario_id
 from liquidazioni_non_contab l,  siac_d_reg_movfin_stato stato,
      siac_r_reg_movfin_stato r1, siac_d_reg_movfin_stato stato1
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_subdoc_id is not null
 and   stato.ente_proprietario_id=l.ente_proprietario_id
 and   stato.regmovfin_stato_code='A'
 and   r1.regmovfin_id=l.regmovfin_subdoc_id
 and   stato1.regmovfin_stato_id=r1.regmovfin_stato_id
 and   stato1.regmovfin_stato_code!='A'
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab.Chiusura stato registro subdocumenti.Chiusura stato notificato.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');
 -- chiusura stato N
 update  siac_r_reg_movfin_stato r
 set     data_cancellazione=datainizioval,
         validita_fine=datainizioval,
         login_operazione=r.login_operazione||'-'||loginOperazione
 from liquidazioni_non_contab l,  siac_d_reg_movfin_stato stato
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_subdoc_id is not null
 and   r.regmovfin_id=l.regmovfin_subdoc_id
 and   stato.regmovfin_stato_id=r.regmovfin_stato_id
 and   stato.regmovfin_stato_code='N'
 and   r.data_cancellazione is null
 and   r.validita_fine is null;
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab.Chiusura stato registro subdocumenti.Chiusura stato non notificato.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');
 -- chiusura stato !=N
 update  siac_r_reg_movfin_stato r
 set     data_cancellazione=datainizioval,
         validita_fine=datainizioval,
         login_operazione=r.login_operazione||'-'||loginOperazione
 from liquidazioni_non_contab l,  siac_d_reg_movfin_stato stato
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_subdoc_id is not null
 and   r.regmovfin_id=l.regmovfin_subdoc_id
 and   stato.regmovfin_stato_id=r.regmovfin_stato_id
 and   stato.regmovfin_stato_code not in ('N','A')
 and   r.data_cancellazione is null
 and   r.validita_fine is null;
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 --- fine subdocumenti

 --- inizio trattamento dati per regmov_fin impegni/subimpegni

 --- inizio trattamento dati per prime note


 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab in stato diverso da Notificato.Annullamento Prima Nota impegni/sub.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');

 -- inserimento stato A prima nota impegno/sub
 insert into siac_r_prima_nota_stato
 (pnota_id,
  pnota_stato_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 select  distinct pn.pnota_id,
         pnstatoA.pnota_stato_id,
         datainizioval,
         loginOperazione,
         pn.ente_proprietario_id
 from liquidazioni_non_contab l, siac_r_reg_movfin_stato r, siac_d_reg_movfin_stato stato,
      siac_t_mov_ep ep, siac_t_prima_nota pn, siac_r_prima_nota_stato rpn, siac_d_prima_nota_stato pnstato,
      siac_d_prima_nota_stato pnstatoA
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_imp_id is not null
 and   r.regmovfin_id=l.regmovfin_imp_id
 and   stato.regmovfin_stato_id=r.regmovfin_stato_id
 and   stato.regmovfin_stato_code!='N'
 and   ep.regmovfin_id=r.regmovfin_id
 and   pn.pnota_id=ep.regep_id
 and   rpn.pnota_id=pn.pnota_id
 and   pnstato.pnota_stato_id=rpn.pnota_stato_id
 and   pnstato.pnota_stato_code!='A'
 and   pnstatoA.ente_proprietario_id=l.ente_proprietario_id
 and   pnstatoA.pnota_stato_code='A'
 and   r.data_cancellazione is null
 and   r.validita_fine is null
 and   ep.data_cancellazione is null
 and   ep.validita_fine is null
 and   pn.data_cancellazione is null
 and   pn.validita_fine is null
 and   rpn.data_cancellazione is null
 and   rpn.validita_fine is null;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');


 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab in stato diverso da Notificato.Chiusura stato Prima Nota impegni/sub.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');

 -- chiusura stato !='A' per le prime note di registrazioni non Notificate
 update siac_r_prima_nota_stato rpn
 set    data_cancellazione=datainizioval,
        validita_fine=datainizioval,
        login_operazione=rpn.login_operazione||'-'||loginOperazione
 from liquidazioni_non_contab l, siac_r_reg_movfin_stato r, siac_d_reg_movfin_stato stato,
      siac_t_mov_ep ep, siac_t_prima_nota pn,  siac_d_prima_nota_stato pnstato
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_imp_id is not null
 and   r.regmovfin_id=l.regmovfin_imp_id
 and   stato.regmovfin_stato_id=r.regmovfin_stato_id
 and   stato.regmovfin_stato_code!='N'
 and   ep.regmovfin_id=r.regmovfin_id
 and   pn.pnota_id=ep.regep_id
 and   rpn.pnota_id=pn.pnota_id
 and   pnstato.pnota_stato_id=rpn.pnota_stato_id
 and   pnstato.pnota_stato_code!='A'
 and   r.data_cancellazione is null
 and   r.validita_fine is null
 and   ep.data_cancellazione is null
 and   ep.validita_fine is null
 and   pn.data_cancellazione is null
 and   pn.validita_fine is null
 and   rpn.data_cancellazione is null
 and   rpn.validita_fine is null;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 -- inizio trattamento gestione regmov_fin

 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab.Chiusura stato registro impegni/sub.Inserimento stato annullato.';
 -- inserimento stato A
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');
 insert into siac_r_reg_movfin_stato
 ( regmovfin_id,
   regmovfin_stato_id ,
   validita_inizio,
   login_operazione,
   ente_proprietario_id
 )
 select  l.regmovfin_imp_id,
         stato.regmovfin_stato_id,
         datainizioval,
         loginOperazione,
         stato.ente_proprietario_id
 from liquidazioni_non_contab l,  siac_d_reg_movfin_stato stato,
      siac_r_reg_movfin_stato r1, siac_d_reg_movfin_stato stato1
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_imp_id is not null
 and   stato.ente_proprietario_id=l.ente_proprietario_id
 and   stato.regmovfin_stato_code='A'
 and   r1.regmovfin_id=l.regmovfin_imp_id
 and   stato1.regmovfin_stato_id=r1.regmovfin_stato_id
 and   stato1.regmovfin_stato_code!='A'
 and   r1.data_cancellazione is null
 and   r1.validita_fine is null;

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab.Chiusura stato registro impegni/sub.Chiusura stato notificato.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');
 -- chiusura stato N
 update  siac_r_reg_movfin_stato r
 set     data_cancellazione=datainizioval,
         validita_fine=datainizioval,
         login_operazione=r.login_operazione||'-'||loginOperazione
 from liquidazioni_non_contab l,  siac_d_reg_movfin_stato stato
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_imp_id is not null
 and   r.regmovfin_id=l.regmovfin_imp_id
 and   stato.regmovfin_stato_id=r.regmovfin_stato_id
 and   stato.regmovfin_stato_code='N'
 and   r.data_cancellazione is null
 and   r.validita_fine is null;
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 strMessaggio:='Liquidazioni (L1) liquidazioni_non_contab.Chiusura stato registro impegni/sub.Chiusura stato non notificato.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');
 -- chiusura stato !=N
 update  siac_r_reg_movfin_stato r
 set     data_cancellazione=datainizioval,
         validita_fine=datainizioval,
         login_operazione=r.login_operazione||'-'||loginOperazione
 from liquidazioni_non_contab l,  siac_d_reg_movfin_stato stato
 where l.ente_proprietario_id=enteRec.ente_proprietario_id
 and   l.bil_id=bilancioId
 and   l.evmovfin_liq_id=0
 and   l.regmovfin_imp_id is not null
 and   r.regmovfin_id=l.regmovfin_imp_id
 and   stato.regmovfin_stato_id=r.regmovfin_stato_id
 and   stato.regmovfin_stato_code not in ('N','A')
 and   r.data_cancellazione is null
 and   r.validita_fine is null;
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 -- fine impegni



 --- inserimento Co.Ge per tutte le liquidazioni presenti in liquidazioni_non_contab L 1,2
 --- inserimento regmovfin per liquidazioni

 strMessaggio:='Liquidazioni (L1,L2) liquidazioni_non_contab.Inserimento registro GEN.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');
 -- siac_t_reg_movfin
 INSERT INTO siac_t_reg_movfin
 (
  classif_id_iniziale,
  classif_id_aggiornato,
  bil_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  ambito_id
 )
 (
  with
  cauev as
  (
   select distinct
   ev.evento_id,
   ev.evento_code,
   c.classif_id, c.classif_code,c.classif_desc,
   amb.ambito_id
   from siac_d_evento ev,siac_r_evento_causale revcau,siac_t_causale_ep cau,siac_r_causale_ep_class rcauclass,
        siac_t_class c, siac_d_ambito amb
   where ev.evento_code in ('LIQ-INS','LIQ-RES-INS')
   and   ev.ente_proprietario_id=enteRec.ente_proprietario_id
   and   revcau.evento_id=ev.evento_id
   and   cau.causale_ep_id=revcau.causale_ep_id
   and   rcauclass.causale_ep_id=cau.causale_ep_id
   and   c.classif_id=rcauclass.classif_id
   and   amb.ente_proprietario_id=ev.ente_proprietario_id
   and   amb.ambito_code='AMBITO_FIN'
   and   ev.data_cancellazione is null
   and   ev.validita_fine is null
   and   revcau.data_cancellazione is null
   and   revcau.validita_fine is null
   and   cau.data_cancellazione is null
   and   cau.validita_fine is null
   and   rcauclass.data_cancellazione is null
   and   rcauclass.validita_fine is null
   and   c.data_cancellazione is null
  ),
 liq_da_registrare as
 (
   SELECT l.liq_id, l.movgest_pdcfin_id classif_id, l.movgest_pdcfin,l.bil_id,l.movgest_anno,
          (case when per.anno::INTEGER=l.movgest_anno then 'LIQ-INS' else 'LIQ-RES-INS' end ) evento_code,
          l.ente_proprietario_id
   from liquidazioni_non_contab l, siac_t_periodo per, siac_t_bil bil
   where l.ente_proprietario_id=enteRec.ente_proprietario_id
   and   l.bil_id=bilancioId
   and   bil.bil_id=bilancioId
   and   per.periodo_id=bil.periodo_id
   and   l.evmovfin_liq_id=0
 )
(
 select
 cc.classif_id,
 cc.classif_id,
 lr.bil_id,
 datainizioval,
 lr.ente_proprietario_id,
 loginOperazione||'-'||cc.evento_id::varchar||'@'||lr.liq_id::varchar,
 cc.ambito_id
 From cauev cc , liq_da_registrare lr
 where cc.classif_id=lr.classif_id
 and   cc.evento_code=lr.evento_code) );
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 strMessaggio:='Liquidazioni (L1,L2) liquidazioni_non_contab.Inserimento registro stato GEN.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');
 INSERT INTO siac_r_reg_movfin_stato
 (
  regmovfin_id,
  regmovfin_stato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
 )
 select
  a.regmovfin_id,
  b.regmovfin_stato_id,
  datainizioval,
  b.ente_proprietario_id,
  loginOperazione
 from siac_t_reg_movfin a,siac_d_reg_movfin_stato b
 where a.ente_proprietario_id=enteRec.ente_proprietario_id
 and   a.login_operazione like loginOperazione||'%'
 and   a.bil_id=bilancioId
 and   b.ente_proprietario_id=a.ente_proprietario_id
 and   b.regmovfin_stato_code='N';

 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 strMessaggio:='Liquidazioni (L1,L2) liquidazioni_non_contab.Inserimento legame registro-evento-liq GEN.';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-INIZIO.');

 -- siac_r_evento_reg_movfin
 INSERT INTO
 siac_r_evento_reg_movfin
 (
  regmovfin_id,
  evento_id,
  campo_pk_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  campo_pk_id_2
 )
 select a.regmovfin_id,
 substring(a.login_operazione from strpos (a.login_operazione,'-')+1 for (strpos (a.login_operazione,'@')-strpos (a.login_operazione,'-')-1))::integer evento_id,
 substring(a.login_operazione from strpos (a.login_operazione,'@')+1)::integer campo_pk_id,
 datainizioval,
 a.ente_proprietario_id,
 loginOperazione,
 null
 from siac_t_reg_movfin a
 where a.ente_proprietario_id=enteRec.ente_proprietario_id
 and   a.bil_id=bilancioId
 and   a.login_operazione like loginOperazione||'%';
 insert into gen_lancia_td_INC000001182764_log
 ( ente_proprietario_id,bil_id,log_descrizione)
 values
 (enteRec.ente_proprietario_id,bilancioId,strmessaggio||'-FINE.');

 -- update siac_t_reg_movfin sul login_operazione per togliere eventi_id e liq_id

 end loop;

 strMessaggio:='Elaborazione terminata correttamente.';
 codicerisultato:=0;
 messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
 RETURN;


  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;