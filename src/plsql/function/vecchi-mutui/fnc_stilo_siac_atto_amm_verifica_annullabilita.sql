/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE FUNCTION siac.fnc_stilo_siac_atto_amm_verifica_annullabilita(attoamm_id_in integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

annullabile boolean;
codResult integer:=null;


test_data timestamp;

begin
test_data:=now();
annullabile:= true;



  select 1 into codResult
  from siac_r_atto_amm_stato rsAtto, siac_d_atto_amm_stato stato
  where rsAtto.attoamm_id=attoamm_id_in
  and   stato.attoamm_stato_id=rsatto.attoamm_stato_id
  and   stato.attoamm_stato_code='ANNULLATO'
  and   test_data between rsAtto.validita_inizio and coalesce(rsAtto.validita_fine, test_data)
  and   rsAtto.data_cancellazione is null
  limit 1;
  if codResult is not null  then annullabile:=false; end if;
  raise notice ' Atto annullabile : atto annullato %',(not annullabile);

  if annullabile=true then


    select 1  into codResult
    from siac_r_bil_stato_op_atto_amm
    where attoamm_id=attoamm_id_in
    and data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste bil_stato_op %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_causale_atto_amm rAtto
    where rAtto.attoamm_id=attoamm_id_in
    and test_data between rAtto.validita_inizio and coalesce(rAtto.validita_fine,test_data)
    and rAtto.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;   end if;
    raise notice ' Atto annullabile : esiste causale_atto_amm %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_liquidazione_atto_amm  rAtto, siac_t_liquidazione liq
    where rAtto.attoamm_id=attoamm_id_in
    and   liq.liq_id=rAtto.liq_id
    and   test_data between rAtto.validita_inizio and coalesce(rAtto.validita_fine,test_data)
    and   rAtto.data_cancellazione is null
    and   liq.data_cancellazione is null
    limit 1;
    if codResult is not null  then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste liquidazione_atto_amm  %',(not annullabile);

  end if;


  if annullabile = true THEN


    -- solo impegni-accertamenti definitivi
    select 1 into codResult
    from siac_r_movgest_ts_atto_amm rAtto ,siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
    where rAtto.attoamm_id=attoamm_id_in
    and   ts.movgest_ts_id=ratto.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
    and   test_data between rAtto.validita_inizio and coalesce(ratto.validita_fine,test_data)
    and   rs.data_cancellazione is null
    and   rAtto.data_cancellazione is null
    and   ts.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste movgest_ts_atto_amm  %',(not annullabile);
  end if;



  if annullabile = true THEN



    select 1 into codResult
    from siac_r_ordinativo_atto_amm ra, siac_t_ordinativo o
    where ra.attoamm_id=attoamm_id_in
    and   o.ord_id=ra.ord_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   o.data_cancellazione is null
    limit 1;
    if codResult is not null  then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste ordinativo_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_predoc_atto_amm ra, siac_t_predoc p
    where  ra.attoamm_id=attoamm_id_in
    and    p.predoc_id=ra.predoc_id
    and    test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and    ra.data_cancellazione is null
    and    p.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste predoc_atto_amm  %',(not annullabile);

  end if;


  if annullabile = true THEN



	select 1 into codResult
    from siac_r_programma_atto_amm ra, siac_t_programma p
    where ra.attoamm_id=attoamm_id_in
    and   p.programma_id=ra.programma_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   p.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste programma_atto_amm  %',(not annullabile);


  end if;


  if annullabile = true THEN


    select 1 into codResult
    from siac_r_subdoc_atto_amm ra, siac_t_subdoc sub, siac_t_doc doc
    where ra.attoamm_id=attoamm_id_in
    and   sub.subdoc_id=ra.subdoc_id
    and   doc.doc_id=sub.doc_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   sub.data_cancellazione is null
    and   doc.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste subdoc_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN


    select 1  into codResult
    from siac_r_variazione_stato ra, siac_t_bil_elem_det_var dvar,siac_t_variazione var
    where ra.attoamm_id=attoamm_id_in
    and   dvar.variazione_stato_id=ra.variazione_stato_id
    and   var.variazione_id=ra.variazione_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   dvar.data_cancellazione is null
    and   var.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste variazione_atto_amm  %',(not annullabile);



  end if;

  if annullabile = true THEN


    select 1 into codResult
    from siac_t_atto_allegato ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste atto_allegato_atto_amm  %',(not annullabile);



  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_t_cartacont ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste cartacont_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_t_cassa_econ_operaz ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste cassa_econ_operaz_atto_amm  %',(not annullabile);


  end if;

  if annullabile = true THEN

    select 1 into codResult
    from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta
    where ra.attoamm_id=attoamm_id_in
    and   st.mod_id=ra.mod_id
    and   sta.mod_stato_id=st.mod_stato_id
    and   sta.mod_stato_code<>'A'
    and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
    and   st.data_cancellazione is null
    and   ra.data_cancellazione is null limit 1;
    /* 31.03.2020 Sofia jira siac-7491
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste modifica_atto_amm  %',(not annullabile);*/

    --- 31.03.2020 Sofia jira siac-7491
    raise notice ' Atto annullabile : esiste modifica_atto_amm  %',coalesce(codResult,0)::boolean;
    if codResult is not null then
     codResult :=null;
     select 1 into codResult
     from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta,
          siac_t_movgest_ts_det_mod dmod,siac_t_movgest_ts ts,siac_t_movgest mov,
          siac_r_bil_fase_operativa rfase,siac_d_fase_operativa fase
     where ra.attoamm_id=attoamm_id_in
     and   st.mod_id=ra.mod_id
     and   sta.mod_stato_id=st.mod_stato_id
     and   sta.mod_stato_code<>'A'
     and   dmod.mod_stato_r_id=st.mod_stato_r_id
     and   ts.movgest_ts_id=dmod.movgest_ts_id
     and   mov.movgest_id=ts.movgest_id
     and   rfase.bil_id=mov.bil_Id
     and   fase.fase_operativa_id=rfase.fase_operativa_id
     and   fase.fase_operativa_code='O'
     and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
     and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
     and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
     and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
     and   test_data between mov.validita_inizio and coalesce(mov.validita_fine,test_data)
     and   test_data between rfase.validita_inizio and coalesce(rfase.validita_fine,test_data)
     and   st.data_cancellazione is null
     and   ra.data_cancellazione is null
     and   dmod.data_cancellazione is null
     and   ts.data_cancellazione is null
     and   mov.data_cancellazione is null
     and   rfase.data_cancellazione is null
     limit 1;
     if codResult is not null then annullabile:=false; end if;
     raise notice ' Atto annullabile : esiste modifica_atto_amm su esercizio pred.consuntivo %',(not annullabile);

     if annullabile=true then
       codResult :=null;
       select 1 into codResult
       from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta,
            siac_t_movgest_ts_det_mod dmod
       where ra.attoamm_id=attoamm_id_in
       and   st.mod_id=ra.mod_id
       and   sta.mod_stato_id=st.mod_stato_id
       and   sta.mod_stato_code<>'A'
       and   dmod.mod_stato_r_id=st.mod_stato_r_id
       and   exists
       (
       select 1
       from siac_t_movgest_ts_det_mod dmod_prec,siac_r_modifica_stato  rs_prec,
            siac_d_modifica_Stato stato_prec,siac_t_modifica modif_prec
       where dmod_prec.movgest_ts_id=dmod.movgest_ts_id
       and   rs_Prec.mod_stato_r_id=dmod_prec.mod_stato_r_id
       and   stato_prec.mod_stato_id=rs_Prec.mod_Stato_id
       and   stato_prec.mod_stato_Code!='A'
       and   modif_prec.mod_id=rs_Prec.mod_id
       and   modif_prec.mod_id<ra.mod_id
  --     and   modif_prec.attoamm_Id=ra.attoamm_id
       and   test_data between dmod_prec.validita_inizio and coalesce(dmod_prec.validita_fine,test_data)
       and   test_data between rs_Prec.validita_inizio and coalesce(rs_Prec.validita_fine,test_data)
       and   test_data between modif_prec.validita_inizio and coalesce(modif_prec.validita_fine,test_data)
       and   dmod_prec.data_cancellazione is null
       and   rs_Prec.data_cancellazione is null
       and   modif_prec.data_cancellazione is null
       )
       and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
       and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
       and   test_data between dmod.validita_inizio and coalesce(dmod.validita_fine,test_data)
       and   st.data_cancellazione is null
       and   ra.data_cancellazione is null
       and   dmod.data_cancellazione is null
       limit 1;
       if codResult is not null then annullabile:=false; end if;
       raise notice ' Atto annullabile : esiste modifica_atto_amm non ultima %',(not annullabile);
     end if;
    end if;

    --- 31.03.2020 Sofia jira siac-7491
    raise notice ' Atto annullabile : esiste modifica_atto_amm annullabile %', annullabile;
  end if;


  raise notice ' Atto annullabile : %',annullabile::varchar;
return annullabile;

exception
    when no_data_found then
        return false;
 	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
END;
$function$

