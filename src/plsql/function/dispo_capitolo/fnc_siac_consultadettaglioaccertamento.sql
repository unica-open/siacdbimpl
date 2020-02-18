/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_consultadettaglioaccertamento (
  movgest_ts_id_in integer,
  out tot_imp_ord numeric,
  out n_ord integer,
  out tot_imp_subdoc numeric,
  out n_imp_doc integer,
  out tot_imp_ord_sudoc numeric,
  out n_doc_ord integer,
  out tot_doc_non_inc numeric,
  out n_doc_non_inc integer,
  out tot_imp_predoc numeric,
  out n_imp_predoc integer,
  out tot_mod_prov numeric
)
RETURNS record AS
$body$
BEGIN


tot_imp_ord :=0.0;
n_ord :=0;
tot_imp_subdoc :=0.0;
n_imp_doc :=0;
tot_imp_ord_sudoc :=0.0;
n_doc_ord :=0;
tot_doc_non_inc :=0.0;
n_doc_non_inc :=0;  
tot_imp_predoc :=0.0;
n_imp_predoc :=0;  
tot_mod_prov :=0.0;


 /* ===================================> ORDINATIVI (Reversali)  <================================ 88684 */

	select coalesce(sum(c.ord_ts_det_importo),0), coalesce(count(*),0)  into tot_imp_ord, n_ord
    from siac_r_ordinativo_ts_movgest_ts a, siac_t_ordinativo_ts b,
	siac_t_ordinativo_ts_det c, siac_d_ordinativo_ts_det_tipo d,
    siac_t_ordinativo e, siac_d_ordinativo_stato f, siac_r_ordinativo_stato g
    where
    a.movgest_ts_id = movgest_ts_id_in 
    and a.ord_ts_id = b.ord_ts_id
    and c.ord_ts_id = b.ord_ts_id
    and c.ord_ts_det_tipo_id = d.ord_ts_det_tipo_id
    and d.ord_ts_det_tipo_code = 'A'
    and e.ord_id = b.ord_id
    and e.ord_id = g.ord_id
    and g.ord_stato_id = f.ord_stato_id
    and f.ord_stato_code != 'A'
 	and a.data_cancellazione is null
    and now() between  a.validita_inizio 
    and coalesce(a.validita_fine, now()) 
  	and b.data_cancellazione is null
    and now() between  b.validita_inizio 
    and coalesce(b.validita_fine, now()) 
    and c.data_cancellazione is null
    and now() between  c.validita_inizio
      and coalesce(c.validita_fine, now()) 
  	and d.data_cancellazione is null
    and now() between  d.validita_inizio 
    and coalesce(d.validita_fine, now()) 
  	and e.data_cancellazione is null
    and now() between  e.validita_inizio 
    and coalesce(e.validita_fine, now()) 
  	and f.data_cancellazione is null
    and now() between  f.validita_inizio 
    and coalesce(f.validita_fine, now()) 
	and g.data_cancellazione is null
    and now() between  g.validita_inizio 
    and coalesce(g.validita_fine, now());

/* ================================> tot_imp_ord => totOrd, n_ord => nOrd  <============================ */

/* ****************************************************************************************** */

/* ==================================> DOCUMENTI NON INCASSATI <============================= */

 select coalesce(sum(a1.subdoc_importo - coalesce(a1.subdoc_importo_da_dedurre,0)),0), count(distinct a1.doc_id)
 into tot_imp_subdoc, n_imp_doc
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

select coalesce(sum(c.ord_ts_det_importo),0), count(distinct g.doc_id)
into tot_imp_ord_sudoc, n_doc_ord
    from
    siac_r_ordinativo_ts_movgest_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo_ts_det c,
    siac_r_subdoc_ordinativo_ts e,siac_d_ordinativo_ts_det_tipo f,
	siac_t_subdoc g,
     siac_t_ordinativo g2, 
    siac_d_ordinativo_stato h2, 
    siac_r_ordinativo_stato i2
    where
    a.movgest_ts_id =   movgest_ts_id_in--172
    and a.ord_ts_id = e.ord_ts_id
    and a.ord_ts_id = b.ord_ts_id
    and c.ord_ts_id = b.ord_ts_id
	and e.subdoc_id = g.subdoc_id
    and g2.ord_id=b.ord_id
    and i2.ord_id=g2.ord_id
    and h2.ord_stato_id=i2.ord_stato_id
    and h2.ord_stato_code<>'A'
    and now() between  i2.validita_inizio and coalesce(i2.validita_fine, now()) 
    and f.ord_ts_det_tipo_id=c.ord_ts_det_tipo_id 
    and f.ord_ts_det_tipo_code='A'
    and a.data_cancellazione is null
    and now() between  a.validita_inizio
    and coalesce(a.validita_fine, now()) 
    and b.data_cancellazione is null
    and now() between  b.validita_inizio
    and coalesce(b.validita_fine, now()) 
    and c.data_cancellazione is null
    and now() between  c.validita_inizio
    and coalesce(c.validita_fine, now()) 
    and e.data_cancellazione is null
    and now() between  e.validita_inizio
    and coalesce(e.validita_fine, now()) 
    and f.ord_ts_det_tipo_id=c.ord_ts_det_tipo_id
    and f.ord_ts_det_tipo_code='A'
    and g2.data_cancellazione is null
    and h2.data_cancellazione is null
    and i2.data_cancellazione is null
    ;

-- ==> TOTALE DOCUMENTI NON INCASSATI <==
tot_doc_non_inc := tot_imp_subdoc - tot_imp_ord_sudoc;
n_doc_non_inc := n_imp_doc - n_doc_ord;
/* =========================> tot_doc_non_inc => totDoc , n_doc_non_inc => nDoc <===================== */

/* ****************************************************************************************** */

/* ===================================> PREDOC NON INCASSATI <=============================== */
-- somma predoc collegati al movgest : in stato I o C
 select coalesce(sum (a1.predoc_importo),0), coalesce(count (*),0)
 into tot_imp_predoc, n_imp_predoc
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
/* ========================> tot_imp_predoc => totPredoc , n_imp_predoc => nPredoc <=========================== */

/* *************************************************************************** */

/* ===================================> MODIFICHE POSITIVE PROVVISORIE <=============================== */
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

/* =========================> tot_mod_prov => totMod <===================== */

return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;