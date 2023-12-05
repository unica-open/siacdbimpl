/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaincassaremovgest (
  movgest_ts_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
number_out numeric;
tot_imp_ts numeric;
tot_imp_ord numeric;
tot_imp_subdoc numeric;
tot_imp_ord_sudoc numeric;
tot_imp_predoc numeric;
tot_mod_prov numeric;

BEGIN

--number_out:=1000.3;
number_out:=0.0;
tot_imp_ts:=0.0;
tot_imp_ord:=0.0;
tot_imp_subdoc:=0.0;
tot_imp_ord_sudoc:=0.0;
tot_imp_predoc:=0.0;

--SET TIME ZONE 'CET';


  
    select sum(e.movgest_ts_det_importo)
    into tot_imp_ts
    from siac_t_movgest_ts a,
         siac_d_movgest_ts_tipo b,
         siac_t_movgest c,
         siac_d_movgest_tipo d,
         siac_t_movgest_ts_det e,
         siac_d_movgest_ts_det_tipo f
    where a.movgest_ts_id = movgest_ts_id_in and
          a.movgest_ts_tipo_id = b.movgest_ts_tipo_id and
          a.movgest_id = c.movgest_id and
          c.movgest_tipo_id = d.movgest_tipo_id and
          e.movgest_ts_id = a.movgest_ts_id and
          f.movgest_ts_det_tipo_id = e.movgest_ts_det_tipo_id and
          f.movgest_ts_det_tipo_code = 'A' and
          a.data_cancellazione is null and
          now() between a.validita_inizio and
          coalesce(a.validita_fine, now()) and
          b.data_cancellazione is null and
          now() between b.validita_inizio and
          coalesce(b.validita_fine, now()) and
          c.data_cancellazione is null and
          now() between c.validita_inizio and
          coalesce(c.validita_fine, now()) and
          d.data_cancellazione is null and
          now() between d.validita_inizio and
          coalesce(d.validita_fine, now()) and
          e.data_cancellazione is null and
          now() between e.validita_inizio and
          coalesce(e.validita_fine, now()) and
          f.data_cancellazione is null and
          now() between f.validita_inizio and
          coalesce(f.validita_fine, now());

-- somma importoAttuale ordinativi  : in stato <> ANNULLATO

 select coalesce(sum(c.ord_ts_det_importo), 0)
 into tot_imp_ord
 from siac_r_ordinativo_ts_movgest_ts a,
      siac_t_ordinativo_ts b,
      siac_t_ordinativo_ts_det c,
      siac_d_ordinativo_ts_det_tipo d,
      siac_t_ordinativo e,
      siac_d_ordinativo_stato f,
      siac_r_ordinativo_stato g,
      siac_t_movgest_ts h
 where 
       --a.movgest_ts_id = movgest_ts_id_in  and
       (
       h.movgest_ts_id = movgest_ts_id_in 
       or h.movgest_ts_id_padre = movgest_ts_id_in
       ) 
       AND
       a.movgest_ts_id=h.movgest_ts_id and
       a.ord_ts_id = b.ord_ts_id and
       c.ord_ts_id = b.ord_ts_id and
       c.ord_ts_det_tipo_id = d.ord_ts_det_tipo_id and
       d.ord_ts_det_tipo_code = 'A' and
       e.ord_id = b.ord_id and
       e.ord_id = g.ord_id and
       g.ord_stato_id = f.ord_stato_id and
       f.ord_stato_code != 'A' and
       a.data_cancellazione is null and
       now() between a.validita_inizio and
       coalesce(a.validita_fine, now()) and
       b.data_cancellazione is null and
       now() between b.validita_inizio and
       coalesce(b.validita_fine, now()) and
       c.data_cancellazione is null and
       now() between c.validita_inizio and
       coalesce(c.validita_fine, now()) and
       d.data_cancellazione is null and
       now() between d.validita_inizio and
       coalesce(d.validita_fine, now()) and
       e.data_cancellazione is null and
       now() between e.validita_inizio and
       coalesce(e.validita_fine, now()) and
       f.data_cancellazione is null and
       now() between f.validita_inizio and
       coalesce(f.validita_fine, now()) and
       g.data_cancellazione is null and
       now() between g.validita_inizio and
       coalesce(g.validita_fine, now());


-- somma (importo - importoDaDedurre) subdocumenti di entrata collegati al movgest:  in stato <> A

 select coalesce(sum(a1.subdoc_importo - coalesce(a1.subdoc_importo_da_dedurre,0)),0) into tot_imp_subdoc
 from
    siac_r_subdoc_movgest_ts a, siac_t_subdoc a1,  siac_t_doc a2, 
    siac_d_doc_stato a3, siac_r_doc_stato a4 , siac_d_doc_tipo a5
    where
    a.movgest_ts_id =  movgest_ts_id_in--172
    and a.subdoc_id = a1.subdoc_id
    and a1.doc_id = a2.doc_id
    and a4.doc_id = a2.doc_id
    and a4.doc_stato_id = a3.doc_stato_id
    and a3.doc_stato_code != 'A' and  a3.doc_stato_code != 'ST'
    and a2.doc_tipo_id=a5.doc_tipo_id
    and a5.doc_tipo_code <> 'NCV' 
    and a5.data_cancellazione is null
    and a.data_cancellazione is null
    and now() between  a.validita_inizio 
    and coalesce(a.validita_fine, now())
   	and a1.data_cancellazione is null
    and now() between  a1.validita_inizio 
    and coalesce(a1.validita_fine, now()) 
   	and a2.data_cancellazione is null
    and now() between  a2.validita_inizio 
    and coalesce(a2.validita_fine, now()) 
   	and a3.data_cancellazione is null
    and now() between  a3.validita_inizio
     and coalesce(a3.validita_fine, now()) 
       and a4.data_cancellazione is null
    and now() between  a4.validita_inizio 
    and coalesce(a4.validita_fine, now())
    ;

-- somma (importo) degli ordinativi collegate a subdocumenti di entrata collegati al movgest iniziale

select coalesce(sum(c.ord_ts_det_importo),0)  into tot_imp_ord_sudoc
    from
    siac_r_ordinativo_ts_movgest_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo_ts_det c,
    siac_r_subdoc_ordinativo_ts e,siac_d_ordinativo_ts_det_tipo f, siac_t_ordinativo g, 
    siac_d_ordinativo_stato h, 
    siac_r_ordinativo_stato i
    where
    a.movgest_ts_id =  movgest_ts_id_in--172
    and a.ord_ts_id = e.ord_ts_id
    and a.ord_ts_id = b.ord_ts_id
    and c.ord_ts_id = b.ord_ts_id
    and g.ord_id=b.ord_id
    and i.ord_id=g.ord_id
    and h.ord_stato_id=i.ord_stato_id
    and h.ord_stato_code<>'A'
    and f.ord_ts_det_tipo_id=c.ord_ts_det_tipo_id 
    and f.ord_ts_det_tipo_code='A'
    and now() between  i.validita_inizio and coalesce(i.validita_fine, now()) 
    and now() between  a.validita_inizio and coalesce(a.validita_fine, now()) 
    and now() between  b.validita_inizio and coalesce(b.validita_fine, now()) 
    and now() between  c.validita_inizio and coalesce(c.validita_fine, now()) 
    and now() between  e.validita_inizio and coalesce(e.validita_fine, now()) 
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and e.data_cancellazione is null
    and f.data_cancellazione is null
    and g.data_cancellazione is null
    and h.data_cancellazione is null
    and i.data_cancellazione is null
    ;


-- somma predoc collegati al movgest : in stato I o C
 select coalesce(sum (a1.predoc_importo),0)  into tot_imp_predoc
 from
    siac_r_predoc_movgest_ts a, siac_t_predoc a1, siac_d_predoc_stato a3, siac_r_predoc_stato a4
    where
    a.movgest_ts_id = movgest_ts_id_in
    and a.predoc_id = a1.predoc_id
    and a1.predoc_id = a4.predoc_id
    and a4.predoc_stato_id = a3.predoc_stato_id
    and (a3.predoc_stato_code 
    = 'I' or  a3.predoc_stato_code = 'C')
    and a.data_cancellazione is null
    and now() between  a.validita_inizio
    and coalesce(a.validita_fine, now()) 
   	and a1.data_cancellazione is null
    and now() between  a1.validita_inizio
    and coalesce(a1.validita_fine, now()) 
 	and a3.data_cancellazione is null
    and now() between  a3.validita_inizio
    and coalesce(a3.validita_fine, now()) 
    and a4.data_cancellazione is null
    and now() between  a4.validita_inizio
    and coalesce(a4.validita_fine, now()) 
    ;


--nuova sezione CR 740

select coalesce(sum(c.movgest_ts_det_importo),0) into tot_mod_prov
from siac_t_modifica a, siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, siac_t_movgest_ts_det d,
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i
where
e.movgest_ts_id = movgest_ts_id_in
and f.mod_stato_code = 'V' -- la modifica deve essere valida
and i.attoamm_stato_code = 'PROVVISORIO' -- atto provvisorio
and c.movgest_ts_det_importo > 0 -- importo positivo
--
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and d.movgest_ts_det_id = c.movgest_ts_det_id
and e.movgest_ts_id = d.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
-- date
and a.data_cancellazione is null
and now() between a.validita_inizio and coalesce(a.validita_fine, now())
and b.data_cancellazione is null
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and c.data_cancellazione is null
and now() between c.validita_inizio and coalesce(c.validita_fine, now())
and d.data_cancellazione is null
and now() between d.validita_inizio and coalesce(d.validita_fine, now())
and e.data_cancellazione is null
and now() between e.validita_inizio and coalesce(e.validita_fine, now())
and f.data_cancellazione is null
and now() between f.validita_inizio and coalesce(f.validita_fine, now())
and g.data_cancellazione is null
and now() between g.validita_inizio and coalesce(g.validita_fine, now())
and h.data_cancellazione is null
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and i.data_cancellazione is null;

raise notice 'tot_mod_prov:%',tot_mod_prov;  


--importoattuale

number_out:=tot_imp_ts -  tot_imp_ord  - (tot_imp_subdoc - tot_imp_ord_sudoc) - tot_imp_predoc   ;

number_out:=number_out - tot_mod_prov;
return number_out;



END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;