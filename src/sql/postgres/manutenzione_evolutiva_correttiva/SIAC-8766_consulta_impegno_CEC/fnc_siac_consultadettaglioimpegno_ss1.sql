/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_siac_consultadettaglioimpegno  (
  movgest_ts_id_in integer,
  out tot_imp_liq numeric,
  out n_liq integer,
  out tot_imp_subdoc numeric,
  out n_imp_doc integer,
  out tot_imp_liq_sudoc numeric,
  out n_doc_liq integer,
  out tot_doc_non_liq numeric,
  out n_doc_non_liq integer,
  out tot_imp_predoc numeric,
  out n_imp_predoc integer,
  out tot_imp_cartac numeric,
  out n_cartac integer,
  out tot_imp_cartac_subdoc numeric,
  out n_cartac_subdoc integer,
  out tot_carte_non_reg numeric,
  out n_carte_non_reg integer,
  out tot_mod_prov numeric,
  out tot_imp_cec_no_giust numeric,
  out tot_imp2_no_giust numeric,
  out tot_imp2_giust_integrato numeric,
  out tot_imp2_giust_restituito numeric,
  out tot_imp_cec_fattura numeric,
  out tot_imp_cec_paf_fatt numeric,
  out tot_cec numeric
);
CREATE OR REPLACE FUNCTION siac.fnc_siac_consultadettaglioimpegno (
  movgest_ts_id_in integer,
  out tot_imp_liq numeric,
  out n_liq integer,
  out tot_imp_subdoc numeric,
  out n_imp_doc integer,
  out tot_imp_liq_sudoc numeric,
  out n_doc_liq integer,
  out tot_doc_non_liq numeric,
  out n_doc_non_liq integer,
  out tot_imp_predoc numeric,
  out n_imp_predoc integer,
  out tot_imp_cartac numeric,
  out n_cartac integer,
  out tot_imp_cartac_subdoc numeric,
  out n_cartac_subdoc integer,
  out tot_carte_non_reg numeric,
  out n_carte_non_reg integer,
  out tot_mod_prov numeric,
  out tot_imp_cec_no_giust numeric,
  out tot_imp2_no_giust numeric,
  out tot_imp2_giust_integrato numeric,
  out tot_imp2_giust_restituito numeric,
  out tot_imp_cec_fattura numeric,
  out tot_imp_cec_paf_fatt numeric,
  out tot_cec numeric
)
RETURNS record AS
$body$
BEGIN



tot_imp_liq :=0.0; 
n_liq :=0;
tot_imp_subdoc :=0.0;
n_imp_doc :=0;
tot_imp_liq_sudoc :=0.0;
n_doc_liq :=0;
tot_doc_non_liq :=0.0;
n_doc_non_liq :=0;
tot_imp_predoc :=0.0;
n_imp_predoc :=0;
tot_imp_cartac:=0.0;
n_cartac :=0;
tot_imp_cartac_subdoc :=0.0; 
n_cartac_subdoc :=0;
tot_carte_non_reg:=0.0;
n_carte_non_reg:=0;
tot_mod_prov:=0.0;
tot_imp_cec_no_giust:=0.0;
tot_imp2_no_giust:=0.0;
tot_imp2_giust_integrato :=0.0;
tot_imp2_giust_restituito :=0.0;
tot_imp_cec_fattura:=0.0;
tot_imp_cec_paf_fatt :=0.0;
tot_cec :=0.0;



/* ===================================> LIQUIDAZIONI  <================================ */
select coalesce(sum(b.liq_importo),0), coalesce(count(*),0)  into tot_imp_liq , n_liq
from
siac_r_liquidazione_movgest a, siac_t_liquidazione b, siac_d_liquidazione_stato c,
siac_r_liquidazione_stato d
where
a.movgest_ts_id = movgest_ts_id_in
and a.liq_id = b.liq_id
and a.data_cancellazione is null
and now() between  a.validita_inizio  and coalesce(a.validita_fine, now()) 
and b.data_cancellazione is null
and now() between  b.validita_inizio  and coalesce(b.validita_fine, now())
and c.data_cancellazione is null
and now() between  c.validita_inizio  and coalesce(c.validita_fine, now())
and d.data_cancellazione is null
and now() between  d.validita_inizio  and coalesce(d.validita_fine, now())
and b.liq_id = d.liq_id
and d.liq_stato_id = c.liq_stato_id
and c.liq_stato_code <> 'A';
/* ================================> tot_imp_liq => totLiq, n_liq => nLiq  <============================== */

/* ****************************************************************************************** */

/* ==================================> DOCUMENTI NON LIQUIDATI <============================= */
-- somma (importo - importoDaDedurre) subdocumenti di spesa collegati al movgest:  in stato <> A
-- SOMMA IMPORTO DOCUMENTI (al netto di varie deduzioni)
--- SIAC-8766 escludere i pagati_CEC
 select coalesce(sum(a1.subdoc_importo - coalesce(a1.subdoc_importo_da_dedurre,0)),0), count(distinct a1.doc_id) 
 into tot_imp_subdoc, n_imp_doc
 from
    siac_r_subdoc_movgest_ts a, siac_t_subdoc a1,  siac_t_doc a2, siac_d_doc_stato a3, siac_r_doc_stato a4,
    siac_d_doc_tipo a5
    where
    a.movgest_ts_id =  movgest_ts_id_in
    and a.subdoc_id = a1.subdoc_id
    and a1.doc_id = a2.doc_id
    and a4.doc_id = a2.doc_id
    and a4.doc_stato_id = a3.doc_stato_id
    and a3.doc_stato_code != 'A' and  a3.doc_stato_code != 'ST'
	and a2.doc_tipo_id=a5.doc_tipo_id
    and a5.doc_tipo_code <> 'NCD' -- non le note di credito
    -- 16.08.2022 Sofia Jira SIAC-8766 - inizio 
    and ( a1.subdoc_pagato_cec =false 
               or not exists 
                   (select 1 
                    from siac_r_richiesta_econ_subdoc rsub,siac_r_richiesta_econ_movgest ric_mov,
                                 siac_t_movimento mov , siac_r_movimento_stampa rstampa,
                               siac_T_CASSA_ECON_STAMPA st
                    where rsub.subdoc_id=a1.subdoc_id
                    and      ric_mov.ricecon_id =rsub.ricecon_id 
                    and      ric_mov.movgest_ts_id =a.movgest_ts_id
					and      mov.ricecon_id=rsub.ricecon_id 
					and      rstampa.movt_id =mov.movt_id 
                    and      st.cest_id=rstampa.cest_id
                    and      st.attoal_id  is not null 
                    and      rsub.data_cancellazione is null 
                    and      rsub.validita_fine is null 
                    and      ric_mov.data_cancellazione is null 
                    and      ric_mov.validita_fine is null 
                    and      rstampa.data_cancellazione is null 
                    and      rstampa.validita_fine is null 
                    and      st.data_cancellazione is null 
                    and      st.validita_fine is null 
                    and      mov.data_cancellazione is null 
                    and      mov.validita_fine is null 
                    )
               ) 
    -- 16.08.2022 Sofia Jira SIAC-8766 - fine               
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
    
-- LIQUIDATO SU SUBDOCUMENTI con COUNT
  select coalesce(sum(b.liq_importo),0), count(distinct s.doc_id)  into tot_imp_liq_sudoc, n_doc_liq
from
siac_r_liquidazione_movgest a, siac_t_liquidazione b,
siac_r_subdoc_liquidazione e,
siac_r_liquidazione_stato c,siac_d_liquidazione_stato d, siac_t_subdoc s
where
a.movgest_ts_id = movgest_ts_id_in
and s.subdoc_id = e.subdoc_id
and a.liq_id = e.liq_id
and a.liq_id = b.liq_id
and a.data_cancellazione is null
and now() between  a.validita_inizio 
and coalesce(a.validita_fine, now()) 
and b.data_cancellazione is null
and now() between  b.validita_inizio 
and coalesce(b.validita_fine, now())
and e.data_cancellazione is null
and now() between  e.validita_inizio 
and coalesce(e.validita_fine, now()) 
and c.liq_id=a.liq_id 
and c.liq_stato_id=d.liq_stato_id
and d.liq_stato_code<>'A'
and now() between  c.validita_inizio 
and coalesce(c.validita_fine, now()); 

-- ==> TOTALE DOCUMENTI NON LIQUIDATI <==
tot_doc_non_liq := tot_imp_subdoc - tot_imp_liq_sudoc;
n_doc_non_liq := n_imp_doc - n_doc_liq;
/* =========================> tot_doc_non_liq => totDoc , n_doc_non_liq => nDoc <===================== */

/* ****************************************************************************************** */

/* ===================================> PREDOC NON LIQUIDATI <=============================== */
select coalesce(sum (a1.predoc_importo),0), coalesce(count (*),0)  into tot_imp_predoc, n_imp_predoc
from
siac_r_predoc_movgest_ts a, siac_t_predoc a1, siac_d_predoc_stato a3, siac_r_predoc_stato a4
where
a.movgest_ts_id = movgest_ts_id_in
and a.predoc_id = a1.predoc_id
and a1.predoc_id = a4.predoc_id
and a4.predoc_stato_id = a3.predoc_stato_id
and (a3.predoc_stato_code = 'I' or  a3.predoc_stato_code = 'C')
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

/* ===================================> CARTE NON LIQUIDATE <=============================== */
-- somma righe carta contabile collegate al movgest : carta in stato <> A
select  coalesce(sum(a1.cartac_det_importo),0), coalesce(count(*),0)  into tot_imp_cartac, n_cartac
from
siac_r_cartacont_det_movgest_ts a, siac_t_cartacont_det a1, siac_t_cartacont a2 ,
siac_d_cartacont_stato a3, siac_r_cartacont_stato a4
where
a.movgest_ts_id =  movgest_ts_id_in
and a.cartac_det_id = a1.cartac_det_id
and a1.cartac_id = a2.cartac_id
and a2.cartac_id = a4.cartac_id
and a3.cartac_stato_id = a4.cartac_stato_id
and a3.cartac_stato_code != 'A'
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
-- somma subdoc della carta
select coalesce(sum(b1.subdoc_importo - b1.subdoc_importo_da_dedurre),0), coalesce(count(*),0) into tot_imp_cartac_subdoc, n_cartac_subdoc
from
siac_r_cartacont_det_movgest_ts a, siac_t_cartacont_det a1, siac_t_cartacont a2, siac_d_cartacont_stato a3, siac_r_cartacont_stato a4,
siac_r_cartacont_det_subdoc b, siac_t_subdoc b1
where
a.movgest_ts_id =  movgest_ts_id_in
and a.cartac_det_id = a1.cartac_det_id
and a1.cartac_det_id = b.cartac_det_id
and b.subdoc_id = b1.subdoc_id
and a1.cartac_id = a2.cartac_id
and a2.cartac_id = a4.cartac_id
and a3.cartac_stato_id = a4.cartac_stato_id
and a3.cartac_stato_code != 'A' 
and a1.cartac_det_id = b.cartac_det_id
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
and b.data_cancellazione is null
and now() between  b.validita_inizio
 and coalesce(b.validita_fine, now()) 
 and b1.data_cancellazione is null
and now() between  b1.validita_inizio
 and coalesce(b1.validita_fine, now()) 
;
-- ==> TOTALE CARTE NON REGOLARIZZATE
tot_carte_non_reg := tot_imp_cartac - tot_imp_cartac_subdoc;
n_carte_non_reg := n_cartac - n_cartac_subdoc;
/* =====================> tot_carte_non_reg => totCarte, n_carte_non_reg => nCarte <======================== */

/* *************************************************************************** */

/* ===================================> MODIFICHE POSITIVE PROVVISORIE <=============================== */
-- somma modifiche positive Valide ma con provvedimento provvisorio
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

/* *************************************************************************** */

/* ==================================>  CEC <=============================================== */

select sum (ricecon_importo) into 
tot_imp_cec_no_giust
from siac_t_richiesta_econ ec 
, siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=ec.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
ec.ricecon_id in (
select distinct b.ricecon_id
 from siac_r_richiesta_econ_movgest a, 
 siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d
WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('RIMBORSO_SPESE',
'ANTICIPO_TRASFERTA_DIPENDENTI',
'PAGAMENTO',
-- 17.08.2022 Sofia Jira SIAC-8766
'PAGAMENTO_FATTURE')
and a.movgest_ts_id=movgest_ts_id_in
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and not exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null)
and not exists (
select 1 from  siac_t_subdoc x,siac_r_richiesta_econ_subdoc y, siac_t_movimento u
where x.subdoc_id=y.subdoc_id and 
y.ricecon_id=u.ricecon_id and 
c.movt_id=u.movt_id
 )
)
and st.data_cancellazione is null
and ds.data_cancellazione is null
and ec.data_cancellazione is null
;

if tot_imp_cec_no_giust is null THEN
tot_imp_cec_no_giust:=0.0;
end if;

raise notice 'cec tot_imp_cec_no_giust:%',tot_imp_cec_no_giust; 


select sum (ricecon_importo) into 
tot_imp2_no_giust
from siac_t_richiesta_econ ec 
, siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=ec.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
ec.ricecon_id in (
select distinct b.ricecon_id
 from siac_r_richiesta_econ_movgest a, siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d
WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('ANTICIPO_SPESE','ANTICIPO_SPESE_MISSIONE')
and a.movgest_ts_id=movgest_ts_id_in
and not exists (select 1 from siac_t_giustificativo z where z.gst_id=c.gst_id and 
  (z.rend_importo_integrato > 0 or z.rend_importo_restituito>0))
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null  
and not exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null)
)
and st.data_cancellazione is null
and ds.data_cancellazione is null
and ec.data_cancellazione is null
;

if tot_imp2_no_giust is null THEN
tot_imp2_no_giust:=0.0;
end if;

raise notice 'cec tot_imp2_no_giust:%',tot_imp2_no_giust; 

 select 
sum(e.rend_importo_integrato) into 
tot_imp2_giust_integrato
 from siac_r_richiesta_econ_movgest a, siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d,
 siac_t_giustificativo e,
 siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=b.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
--WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('ANTICIPO_SPESE','ANTICIPO_SPESE_MISSIONE')
and a.movgest_ts_id=movgest_ts_id_in
and e.gst_id=c.gst_id and e.rend_importo_integrato>0
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and st.data_cancellazione is null
and ds.data_cancellazione is null
and not exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null);


  
if tot_imp2_giust_integrato is null THEN
tot_imp2_giust_integrato:=0.0;
end if;  

raise notice 'cec tot_imp2_giust_integrato:%',tot_imp2_giust_integrato; 

select 
sum(e.rend_importo_restituito) into 
tot_imp2_giust_restituito
 from siac_r_richiesta_econ_movgest a, siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d,
 siac_t_giustificativo e,
 siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=b.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
--WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('ANTICIPO_SPESE','ANTICIPO_SPESE_MISSIONE')
and a.movgest_ts_id=movgest_ts_id_in
and e.gst_id=c.gst_id and e.rend_importo_restituito>0
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null 
and e.data_cancellazione is null
and st.data_cancellazione is null
and ds.data_cancellazione is null
and not exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null);

if tot_imp2_giust_restituito is null THEN
tot_imp2_giust_restituito:=0.0;
end if;  

raise notice 'cec tot_imp2_giust_restituito:%',tot_imp2_giust_restituito; 

------pagamento fatture
-- 29.06.2022 Sofia 
-- per remedy INC000006251415
-- puo essere conteggiato solo se  non esiste documento collegato
-- se esiste documento viene conteggiato o nei documenti o nelle liquidazioni 
-- con la generazione dell''atto di liquidazione
select sum (ricecon_importo) into 
tot_imp_cec_fattura
from siac_t_richiesta_econ ec, siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=ec.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
ec.ricecon_id in (
      select distinct b.ricecon_id
      from siac_r_richiesta_econ_movgest a, 
      siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d
      WHERE
      b.ricecon_id=a.ricecon_id
      and c.ricecon_id=b.ricecon_id
      and d.ricecon_tipo_id=b.ricecon_tipo_id
      AND d.ricecon_tipo_code IN
      ('PAGAMENTO_FATTURE')
      and a.movgest_ts_id=movgest_ts_id_in
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      and c.data_cancellazione is null
      and d.data_cancellazione is null			
      and exists 
--      (select 1 from siac_r_movimento_stampa z where  z.movt_id=c.movt_id and z.data_cancellazione is null) 17.08.2022 Sofia Jira SIAC-8766
      -- 17.08.2022 Sofia Jira SIAC-8766 - inizio 
      (select 1 from siac_r_movimento_stampa z where  z.movt_id=c.movt_id and z.data_cancellazione is null      
         and not exists  
                   (select 1 
                    from     siac_T_CASSA_ECON_STAMPA st
                    where  st.cest_id=z.cest_id
                    and        st.attoal_id  is not null 
                    and        st.data_cancellazione is null 
                    and        st.validita_fine is null 
                    )
       )     
      -- 17.08.2022 Sofia Jira SIAC-8766 - fine
      -- 16.08.2022 Sofia JIRA SIAC-8766
      -- vedasi commento  per remedy INC000006251415
      and not exists 
      (
		select 1 
		from  siac_t_subdoc sub,siac_r_richiesta_econ_subdoc rsub
		where 	rsub.ricecon_id=b.ricecon_id
		and       rsub.subdoc_id=sub.subdoc_id 
		and       rsub.data_cancellazione is null 
		and       rsub.validita_fine  is null 
 	 )
 )
and st.data_cancellazione is null
and ds.data_cancellazione is null
and ec.data_cancellazione is null
;

if tot_imp_cec_fattura is null THEN
tot_imp_cec_fattura:=0.0;
end if;

raise notice 'cec tot_imp_cec_fattura:%',tot_imp_cec_fattura; 



---

select sum (ricecon_importo) into 
tot_imp_cec_paf_fatt
from siac_t_richiesta_econ ec 
, siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=ec.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
ec.ricecon_id in 
(
select distinct b.ricecon_id
 from siac_r_richiesta_econ_movgest a, 
 siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d
WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('PAGAMENTO')
and a.movgest_ts_id=movgest_ts_id_in
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
-- 29.06.2022 Sofia 
-- per remedy INC000006251415
-- se il movimento è collegato a fattura 
-- se è stato stampato in DEFINITIVO è conteggiato nelle liq
-- se è stato stampato ma non in DEF , se è collegato a documento è conteggiato nei doc 
-- se non è stampato e non è collegato a doc è conteggiato nei mov di cassa
-- quindi questa parte si puo omettere a mio parere come consultazione
-- 17.08.2022 Sofia vedi quanto fatto sotto per Jira SIAC-8766
and exists 
-- (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null) -- 17.08.2022 Sofia Jira SIAC-8766
-- -- 17.08.2022 Sofia Jira SIAC-8766 inizio 
 (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null
   and not exists  -- 17.08.2022 Sofia Jira SIAC-8766
                   (select 1 
                    from     siac_T_CASSA_ECON_STAMPA st
                    where  st.cest_id=z.cest_id
                    and        st.attoal_id  is not null 
                    and        st.data_cancellazione is null 
                    and        st.validita_fine is null 
                    )
 )   -- -- 17.08.2022 Sofia Jira SIAC-8766 fine               
 and exists 
 ( 
  select 1 
  from  siac_t_subdoc x,siac_r_richiesta_econ_subdoc y, siac_t_movimento u 
  where x.subdoc_id=y.subdoc_id and 
  y.ricecon_id=u.ricecon_id and 
  c.movt_id=u.movt_id
 )
)
and st.data_cancellazione is null
and ds.data_cancellazione is null
and ec.data_cancellazione is null
;

if tot_imp_cec_paf_fatt is null THEN
tot_imp_cec_paf_fatt:=0.0;
end if;

raise notice 'cec tot_imp_cec_paf_fatt:%',tot_imp_cec_paf_fatt; 


tot_cec := tot_imp_cec_no_giust-tot_imp2_no_giust-tot_imp2_giust_integrato +tot_imp2_giust_restituito+tot_imp_cec_fattura+tot_imp_cec_paf_fatt;

/* ========================================> tot_cec => totCEC <============================= */

return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;