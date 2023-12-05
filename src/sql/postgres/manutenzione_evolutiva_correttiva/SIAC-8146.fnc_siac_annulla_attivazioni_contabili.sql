/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION siac.fnc_siac_annulla_attivazioni_contabili
(
  id_ente integer,
  anno_bil integer,
  numero_ndc text,
  tipo_doc text,
  codice_soggetto text,
  codice_inc text
)
RETURNS text AS
$body$
DECLARE

tmp text;

-- 04.05.2021 Sofia Jira SIAC-8146
result integer:=null;
annoBilancioGen integer:=null;

BEGIN

	delete from siac_bko_regmovfin_prima_nota_documento bko
	where bko.ente_proprietario_id=id_ente;

   /* 04.05.2021 Sofia JIRA SIAC-8146
   insert into siac_bko_regmovfin_prima_nota_documento
    (
      anno_bilancio,
      doc_anno,
      doc_numero,
      doc_tipo_code,
      doc_soggetto_code,
      doc_subnumero,
      evento_code,
      collegamento_tipo_code,
      ente_proprietario_id,
      doc_genera,
      doc_genera_gsa
    )
    select  anno_bil,
            doc.doc_anno::integer,
            doc.doc_numero,
            tipo.doc_tipo_code,
            sog.soggetto_code,
            sub.subdoc_numero::integer,
            evento.evento_code,
            coll.collegamento_tipo_code,
            doc.ente_proprietario_id,
            false,
            false
    from siac_t_doc doc, siac_d_doc_tipo tipo,siac_t_subdoc sub,
         siac_r_evento_reg_movfin revento,siac_d_evento evento, siac_d_collegamento_tipo coll,
         siac_r_reg_movfin_stato rs, siac_d_reg_movfin_stato stato,siac_r_doc_sog rsog,siac_t_soggetto sog
    where tipo.ente_proprietario_id=id_ente
    and   doc.doc_tipo_id=tipo.doc_tipo_id
    and   doc.doc_anno::INTEGER=anno_bil
    and   doc.doc_numero=numero_ndc
    and   tipo.doc_tipo_code = tipo_doc
    and  sub.doc_id=doc.doc_id
    and  revento.campo_pk_id=sub.subdoc_id
    and  evento.evento_id=revento.evento_id
    and  coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and  coll.collegamento_tipo_code='SS'
    and  rs.regmovfin_id=revento.regmovfin_id
    and  stato.regmovfin_stato_id=rs.regmovfin_stato_id
    and  stato.regmovfin_stato_code!='A'
    and  rsog.doc_id=doc.doc_id
    and  sog.soggetto_id=rsog.soggetto_id
    and   sog.soggetto_code = codice_soggetto
    and  sub.data_cancellazione is null
    and  sub.validita_fine is null
    and  revento.data_cancellazione is null
    and  revento.validita_fine is null
    and  rs.data_cancellazione is null
    and  rs.validita_fine is null
    and  rsog.data_cancellazione is null
    and  rsog.validita_fine is null;*/

   raise notice '@@@ prima di insert @@@@';
   -- 04.05.2021 Sofia JIRA SIAC-8146
   insert into siac_bko_regmovfin_prima_nota_documento
   (
      anno_bilancio,
      doc_anno,
      doc_numero,
      doc_tipo_code,
      doc_soggetto_code,
      doc_subnumero,
      evento_code,
      collegamento_tipo_code,
      ente_proprietario_id,
      doc_genera,
      doc_genera_gsa,
      login_operazione
   )
   select   --distinct
            per.anno::integer,
            doc.doc_anno::integer,
            doc.doc_numero,
            tipo.doc_tipo_code,
            sog.soggetto_code,
            sub.subdoc_numero::integer,
            evento.evento_code,
            coll.collegamento_tipo_code,
            doc.ente_proprietario_id,
            false,
            false,
            codice_inc
    from siac_t_doc doc, siac_d_doc_tipo tipo,siac_t_subdoc sub,
         siac_r_evento_reg_movfin revento,siac_d_evento evento, siac_d_collegamento_tipo coll,
         siac_t_reg_movfin reg, siac_r_reg_movfin_stato rs, siac_d_reg_movfin_stato stato,siac_r_doc_sog rsog,siac_t_soggetto sog,
         siac_t_bil bil,siac_t_periodo per
    where tipo.ente_proprietario_id=id_ente
    and   tipo.doc_tipo_code = tipo_doc
    and   doc.doc_tipo_id=tipo.doc_tipo_id
    and   doc.doc_anno::INTEGER=anno_bil
    and   doc.doc_numero=numero_ndc
    and   rsog.doc_id=doc.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   sog.soggetto_code = codice_soggetto
    and   sub.doc_id=doc.doc_id
    and   revento.campo_pk_id=sub.subdoc_id
    and   evento.evento_id=revento.evento_id
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='SS'
    and   rs.regmovfin_id=revento.regmovfin_id
    and   stato.regmovfin_stato_id=rs.regmovfin_stato_id
    and   stato.regmovfin_stato_code!='A'
    and   reg.regmovfin_id=revento.regmovfin_id
    and   bil.bil_id=reg.bil_id
    and   per.periodo_id=bil.periodo_Id
    and   sub.data_cancellazione is null
    and   sub.validita_fine is null
    and   revento.data_cancellazione is null
    and   revento.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   rsog.data_cancellazione is null
    and   rsog.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null;


    -- 04.05.2021 Sofia JIRA SIAC-8146
    select bko.anno_bilancio into annoBilancioGen
    from siac_bko_regmovfin_prima_nota_documento bko
    where bko.ente_proprietario_id=id_ente
    and   bko.login_operazione=codice_inc
    limit 1;
    raise notice '@@@@annoBilancioGen=%@@@@@', annoBilancioGen::varchar;

/*	04.05.2021 Sofia JIRA SIAC-8146 - tutto fatto nella function richiamata successivamente


 -- inserire stato prima nota annullato, se esiste non annullata
 insert into siac_r_prima_nota_stato
  (
 	pnota_id,
    pnota_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select distinct pnota.pnota_id,
                  statoA.pnota_stato_id,
                  now(),
                  codice_inc,
                  tipo.ente_proprietario_id
  from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota,
       siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA
  where  tipo.ente_proprietario_id=id_ente
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=anno_bil
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnota.bil_id=anno.bil_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.pnota_stato_code='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null;





-- annullare prima nota, se presente non annullata
	 update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||codice_inc
 from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota,
       siac_d_prima_nota_stato pnstato
  where  tipo.ente_proprietario_id=id_ente
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=anno_bil
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnota.bil_id=anno.bil_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null;


-- inserire stato registro annullato, se esiste non annullato

 insert into siac_r_reg_movfin_stato
   (
  	 regmovfin_id,
     regmovfin_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
   )
   select REG.regmovfin_id,
          statoA.regmovfin_stato_id,
          now(),
          codice_inc,
	      statoA.ente_proprietario_id
   from siac_d_reg_movfin_stato statoA,
   (
   select distinct reg.regmovfin_id
   from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato
   where  tipo.ente_proprietario_id=id_ente
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=anno_bil
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   reg.bil_id = anno.bil_id
   ) REG
   where statoA.ente_proprietario_id=id_ente
   and   statoA.regmovfin_stato_code='A';




update siac_r_reg_movfin_stato rrstato
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstato.login_operazione||'-'||codice_inc
   from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_d_reg_movfin_stato rstato
  where  tipo.ente_proprietario_id=id_ente
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=anno_bil
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   reg.bil_id = anno.bil_id;	*/


  --   04.05.2021 Sofia JIRA SIAC-8146
  if annoBilancioGen is not null then

    select
    fnc_siac_bko_regmovfin_prima_nota_documento
    (
--     anno_bil,  04.05.2021 Sofia JIRA SIAC-8146
     annoBilancioGen,
     id_ente,
     codice_inc,
     true,
     false
    ) into tmp;
  end if;


  select
    fnc_siac_bko_aggiorna_doc_contabilizza_genpcc
    (
      doc.ente_proprietario_id,
      anno_bil,
      tipo.doc_tipo_code,
      doc.doc_anno::integer,
      doc.doc_numero,
      sog.soggetto_code,
      false,
      codice_inc
    ) into tmp
    from siac_t_doc doc, siac_d_doc_tipo tipo,siac_r_doc_sog rsog,siac_t_soggetto sog
    where tipo.ente_proprietario_id=id_ente
    and   doc.doc_tipo_id=tipo.doc_tipo_id
    and   doc.doc_anno::INTEGER=anno_bil
    and   doc.doc_numero=numero_ndc
    and   tipo.doc_tipo_code = tipo_doc
    and  rsog.doc_id=doc.doc_id
    and  sog.soggetto_id=rsog.soggetto_id
    and   sog.soggetto_code = codice_soggetto
    and  rsog.data_cancellazione is null
    and  rsog.validita_fine is null;


	delete from siac_bko_regmovfin_prima_nota_documento bko
    where bko.ente_proprietario_id=id_ente
    and   bko.login_operazione=codice_inc; -- 05.05.2021 Sofia Jira SIAC-8146


    return null;

exception
	when others  THEN
	    return SQLERRM;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;