/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaliquidaremovgest (
  movgest_ts_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
number_out numeric;
tot_imp_ts numeric;
tot_imp_liq numeric;
tot_imp_subdoc numeric;
tot_imp_liq_sudoc numeric;
tot_imp_cartac numeric;
tot_imp_cartac_subdoc numeric;
tot_imp_predoc numeric;
tot_imp_cec_no_giust numeric;
tot_imp2_no_giust numeric;
tot_imp2_giust_restituito numeric;
tot_imp2_giust_integrato numeric;
tot_imp_cec_fattura numeric;
tot_imp_cec_paf_fatt numeric;
tot_mod_prov numeric;
esiste_rendiconto boolean;

BEGIN

--SET TIME ZONE 'CET';

--number_out:=1000.3;
number_out:=0.0;
tot_imp_ts:=0.0;
tot_imp_liq:=0.0;
tot_imp_subdoc:=0.0;
tot_imp_liq_sudoc:=0.0;
tot_imp_cartac:=0.0;
tot_imp_cartac_subdoc:=0.0;
tot_imp_predoc:=0.0;
tot_imp_cec_no_giust:=0.0;
tot_imp2_no_giust:=0.0;
tot_imp2_giust_restituito:=0.0;
tot_imp2_giust_integrato:=0.0;
tot_imp_cec_fattura:=0.0;
tot_imp_cec_paf_fatt:=0.0;
esiste_rendiconto:=false;



-- somma importoAttuale liquidazione  : in stato <> ANNULLATO


--new
select sum(e.movgest_ts_det_importo) into 
tot_imp_ts 
from siac_t_movgest c, siac_t_movgest_ts a, 
siac_t_movgest_ts_det e, 
siac_d_movgest_ts_det_tipo f,
siac_d_movgest_stato g,
siac_r_movgest_ts_stato h
where 
c.movgest_id=a.movgest_id
and a.movgest_ts_id = movgest_ts_id_in 
and a.movgest_ts_id=e.movgest_ts_id
and e.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
and f.movgest_ts_det_tipo_code = 'A'
and h.movgest_ts_id=a.movgest_ts_id
and g.movgest_stato_id=h.movgest_stato_id
and g.movgest_stato_code<>'A'
and c.data_cancellazione is null
and a.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and now() between a.validita_inizio 
and COALESCE(a.validita_fine, now())
and c.data_cancellazione is null
and now() between c.validita_inizio 
and COALESCE(c.validita_fine, now())
and e.data_cancellazione is null
and now() between e.validita_inizio 
and COALESCE(e.validita_fine, now())
and now() between f.validita_inizio 
and COALESCE(f.validita_fine, now())
and now() between h.validita_inizio 
and COALESCE(h.validita_fine, now());

raise notice 'tot_imp_ts:%',tot_imp_ts;

select coalesce(sum(b.liq_importo),0)  into tot_imp_liq
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

raise notice 'tot_imp_liq:%',tot_imp_liq;

-- somma (importo - importoDaDedurre) subdocumenti di spesa collegati al movgest:  in stato <> A

 select coalesce(sum(a1.subdoc_importo - coalesce(a1.subdoc_importo_da_dedurre,0)),0) into tot_imp_subdoc
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
    and a5.doc_tipo_code <> 'NCD' 
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
    
raise notice 'tot_imp_subdoc:%',tot_imp_subdoc;    

-- somma (importo) delle liquidazioni collegate a subdocumenti di spesa collegati al movgest iniziale

/*select coalesce(sum(b.liq_importo),0)  into tot_imp_liq_sudoc
from
siac_r_liquidazione_movgest a, siac_t_liquidazione b,
siac_r_subdoc_liquidazione e
where
a.movgest_ts_id = movgest_ts_id_in
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
;*/
  select coalesce(sum(b.liq_importo),0)  into tot_imp_liq_sudoc
from
siac_r_liquidazione_movgest a, siac_t_liquidazione b,
siac_r_subdoc_liquidazione e,
siac_r_liquidazione_stato c,siac_d_liquidazione_stato d
where
a.movgest_ts_id = movgest_ts_id_in
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

raise notice 'tot_imp_liq_sudoc:%',tot_imp_liq_sudoc;    


-- somma predoc collegati al movgest : in stato I o C
select coalesce(sum (a1.predoc_importo),0)  into tot_imp_predoc
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

raise notice 'tot_imp_predoc:%',tot_imp_predoc;    

-- somma righe carta contabile collegate al movgest : carta in stato <> A

select  coalesce(sum(a1.cartac_det_importo),0)  into tot_imp_cartac
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

raise notice 'tot_imp_cartac:%',tot_imp_cartac;   

-- somma subdoc della carta

select coalesce(sum(b1.subdoc_importo - b1.subdoc_importo_da_dedurre),0) into tot_imp_cartac_subdoc
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

raise notice 'tot_imp_cartac_subdoc:%',tot_imp_cartac_subdoc;   

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


-- importoattuale  
number_out:= tot_imp_ts - tot_imp_liq  - (tot_imp_subdoc - tot_imp_liq_sudoc) - tot_imp_predoc - (tot_imp_cartac - tot_imp_cartac_subdoc);

raise notice 'tot_imp_ts - tot_imp_liq  - (tot_imp_subdoc - tot_imp_liq_sudoc) - tot_imp_predoc - (tot_imp_cartac - tot_imp_cartac_subdoc) ------ % - %  - (% - %) - % - (% - %)', tot_imp_ts,tot_imp_liq ,tot_imp_subdoc ,tot_imp_liq_sudoc,tot_imp_predoc ,tot_imp_cartac,tot_imp_cartac_subdoc;
   
raise notice 'prima di cec %',number_out;

--nuova CR 740 
raise notice 'number_out=number_out-tot_mod_prov = %-%',number_out,tot_mod_prov;
number_out:=number_out-tot_mod_prov;



--nuova sezione cec

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
'PAGAMENTO')
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
and a.movgest_ts_id=movgest_ts_id_in--18235
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
and a.movgest_ts_id=movgest_ts_id_in--18235
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
and a.movgest_ts_id=movgest_ts_id_in--18235
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
      and exists (select 1 from siac_r_movimento_stampa z where 
      z.movt_id=c.movt_id and z.data_cancellazione is null)
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
ec.ricecon_id in (
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
and exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null)
and exists (
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

if tot_imp_cec_paf_fatt is null THEN
tot_imp_cec_paf_fatt:=0.0;
end if;

raise notice 'cec tot_imp_cec_paf_fatt:%',tot_imp_cec_paf_fatt; 


number_out:=number_out-tot_imp_cec_no_giust-tot_imp2_no_giust-tot_imp2_giust_integrato +tot_imp2_giust_restituito+tot_imp_cec_fattura+tot_imp_cec_paf_fatt;

--end if;

return number_out;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;