/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_daregolarizzareprovvisorio (
  provc_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
number_out numeric;
BEGIN

number_out:=0.0;

with uno as ( 
--provvisorio.importo SEGNO PIU
select case when(a.provc_importo) is null then 0 else a.provc_importo end importo_provvisorio 
from siac_t_prov_cassa a where a.provc_id = provc_id_in
and a.data_cancellazione is null
)
, due as (
--sum( RegolarizzazioneProvvisiorio.importo) SEGNO MENO
SELECT 
case when(sum(b.ord_provc_importo)) is null then 0 else sum(b.ord_provc_importo) end importo_regolarizzazione_provvisorio 
from siac_t_prov_cassa a, siac_r_ordinativo_prov_cassa b, siac_t_ordinativo c,siac_r_ordinativo_stato d ,siac_d_ordinativo_stato e
where b.provc_id=a.provc_id
and  a.provc_id = provc_id_in
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and c.ord_id=b.ord_id 
and d.ord_id=c.ord_id
and e.ord_stato_id=d.ord_stato_id
and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
and e.ord_stato_code<>'A'
)
, tre AS(
--sum(Subdocumento.importo) SEGNO MENO
 select 
case when(sum(c.subdoc_importo)) is null then 0 else sum(c.subdoc_importo) end  importo_subdoc
from siac_t_prov_cassa a, siac_r_subdoc_prov_cassa b, siac_t_subdoc c, siac_r_doc_stato d ,siac_d_doc_stato e
 where b.provc_id=a.provc_id 
 and c.subdoc_id=b.subdoc_id
 and a.provc_id = provc_id_in
 and a.data_cancellazione is null
 and b.data_cancellazione is null
 and c.data_cancellazione is null
 and d.data_cancellazione is null
 and e.data_cancellazione is null
 and d.doc_id=c.doc_id
 and e.doc_stato_id=d.doc_stato_id
 and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine, now())
 and e.doc_stato_code<>'A'
 and Not exists 
 (
 select 1 from 
 siac_r_subdoc_ordinativo_ts z,
 siac_t_ordinativo_ts a1, siac_t_ordinativo b1,siac_r_ordinativo_stato c1,siac_d_ordinativo_stato d1
 where 
 z.ord_ts_id=a1.ord_ts_id and
 a1.ord_id=b1.ord_id and c1.ord_id=b1.ord_id and c1.ord_stato_id=d1.ord_stato_id and d1.ord_stato_code<>'A'
 and now() between c1.validita_inizio and coalesce(c1.validita_fine,now()) and a1.ord_ts_id=z.ord_ts_id
 and c.subdoc_id=z.subdoc_id
 and a1.data_cancellazione is null
 and b1.data_cancellazione is null
 and c1.data_cancellazione is null 
 and d1.data_cancellazione is null 
 and z.data_cancellazione is null 
 ) 
 )
/* select 
case when(sum(c.subdoc_importo)) is null then 0 else sum(c.subdoc_importo) end  importo_subdoc
from siac_t_prov_cassa a, siac_r_subdoc_prov_cassa b, siac_t_subdoc c
 where b.provc_id=a.provc_id 
 and c.subdoc_id=b.subdoc_id
 and a.provc_id = provc_id_in
 and a.data_cancellazione is null
 and b.data_cancellazione is null
 and c.data_cancellazione is null
 and not exists 
 (
 select  1 from siac_r_subdoc_ordinativo_ts z where z.subdoc_id=c.subdoc_id and z.data_cancellazione is null
 --l'ordinativo non deve essere annullato
 and not exists (select 1 from siac_t_ordinativo_ts a1, siac_t_ordinativo b1,siac_r_ordinativo_stato c1,siac_d_ordinativo_stato d1
 where a1.ord_id=b1.ord_id and c1.ord_id=b1.ord_id and c1.ord_stato_id=d1.ord_stato_id and d1.ord_stato_code<>'A'
 and now() between c1.validita_inizio and coalesce(c1.validita_fine,now()) and a1.ord_ts_id=z.ord_ts_id) 
 )
)*/
, quattro as (
-- sum(predocumento.importo) SEGNO MENO
select  
case when(sum(c.predoc_importo)) is null then 0 else sum(c.predoc_importo) end importo_predoc 
from siac_t_prov_cassa a, siac_r_predoc_prov_cassa b, siac_t_predoc c, siac_r_predoc_stato d, siac_d_predoc_stato e
where b.provc_id=a.provc_id
and c.predoc_id=b.predoc_id
and a.provc_id = provc_id_in
 and a.data_cancellazione is null
 and b.data_cancellazione is null
 and c.data_cancellazione is null
 and d.data_cancellazione is null
 and e.data_cancellazione is null
 and d.predoc_id=c.predoc_id
 and e.predoc_stato_id=d.predoc_stato_id
 and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine, now())
 and e.predoc_stato_code <>'A'
and not exists (select 1 from siac_r_predoc_subdoc zz  where zz.predoc_id=c.predoc_id and zz.data_cancellazione is null)
)
select uno.importo_provvisorio - due.importo_regolarizzazione_provvisorio - tre.importo_subdoc - quattro.importo_predoc into number_out
from uno,due,tre,quattro;



return number_out;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;