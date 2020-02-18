/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_cec_disponibilita_cassa_contanti (
  id_cassaecon_in integer
)
RETURNS numeric AS
$body$
DECLARE

disponibilita_cassa_contanti   numeric:=0;
strMessaggio varchar(1500):=null;
anno_in varchar :='2016';
BEGIN

/*with ope AS(
SELECT case when sum(c.cassaeconop_importo) is null then 0 else sum(c.cassaeconop_importo) end  
disponibilita_cassa_contanti
from siac_t_cassa_econ a, siac_t_cassa_econ_operaz c,siac_r_cassa_econ_operaz_tipo e,
siac_d_cassa_econ_operaz_tipo b,
siac_d_cassa_econ_modpag_tipo d
where 
c.cassaec_id=a.cassaecon_id
and e.cassaeconop_id=c.cassaeconop_id
and b.cassaeconop_tipo_id=e.cassaeconop_tipo_id
and c.cassamodpag_tipo_id=d.cassamodpag_tipo_id
and b.cassaeconop_tipo_entrataspesa='E'
and a.cassaecon_id=	id_cassaecon_in
and d.cassamodpag_tipo_code='CO'
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
and c.data_cancellazione is NULL
and d.data_cancellazione is NULL
and e.data_cancellazione is NULL)
, opu as (
SELECT case when sum(c.cassaeconop_importo) is null then 0 else sum(c.cassaeconop_importo) end  
disponibilita_cassa_contanti
from siac_t_cassa_econ a, siac_t_cassa_econ_operaz c,siac_r_cassa_econ_operaz_tipo e,
siac_d_cassa_econ_operaz_tipo b,
siac_d_cassa_econ_modpag_tipo d
where 
c.cassaec_id=a.cassaecon_id
and e.cassaeconop_id=c.cassaeconop_id
and b.cassaeconop_tipo_id=e.cassaeconop_tipo_id
and c.cassamodpag_tipo_id=d.cassamodpag_tipo_id
and b.cassaeconop_tipo_entrataspesa='U'
and a.cassaecon_id=	id_cassaecon_in
and d.cassamodpag_tipo_code='CO'
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
and c.data_cancellazione is NULL
and d.data_cancellazione is NULL
and e.data_cancellazione is NULL),
recon as ( 
select case when sum(tb.ricecon_importo) is null then 0 else sum(tb.ricecon_importo) end  
ricecon_importo 
from (
select distinct d.ricecon_id, d.ricecon_importo
   from 
   siac_d_cassa_econ_modpag_tipo a, 
   siac_t_cassa_econ c,
   siac_t_richiesta_econ d, 
   siac_t_movimento e,siac_d_richiesta_econ_tipo f
  where 
   a.cassamodpag_tipo_code='CO'
  and c.cassaecon_id=id_cassaecon_in
  and d.cassaecon_id=c.cassaecon_id
  and e.cassamodpag_tipo_id=a.cassamodpag_tipo_id
  and d.ricecon_id=e.ricecon_id
  and f.ricecon_tipo_id=d.ricecon_tipo_id
  and f.ricecon_tipo_code in ( 'RIMBORSO_SPESE','ANTICIPO_SPESE','ANTICIPO_SPESE_MISSIONE','ANTICIPO_TRASFERTA_DIPENDENTI',
  'PAGAMENTO_FATTURE')) tb),
  giu_r as (select case when sum(a.rend_importo_restituito) is null then 0 else sum(a.rend_importo_restituito) end 
rend_importo_restituito
from 
siac_t_giustificativo a, 
siac_t_richiesta_econ e, siac_t_bil f,siac_t_periodo g
where 
e.ricecon_id=a.ricecon_id
and f.bil_id=e.bil_id
and f.periodo_id=g.periodo_id
and g.anno=anno_in
and e.cassaecon_id=id_cassaecon_in)  
  ,
giu_i as (select case when sum(a.rend_importo_integrato) is null then 0 else sum(a.rend_importo_integrato) end 
rend_importo_integrato
from siac_t_giustificativo a, 
siac_t_richiesta_econ e, siac_t_bil f,siac_t_periodo g
where 
e.ricecon_id=a.ricecon_id
and f.bil_id=e.bil_id
and f.periodo_id=g.periodo_id
and g.anno=anno_in
and e.cassaecon_id=id_cassaecon_in)  
select 
ope.disponibilita_cassa_contanti+giu_r.rend_importo_restituito
-recon.ricecon_importo-giu_i.rend_importo_integrato-opu.disponibilita_cassa_contanti 
into disponibilita_cassa_contanti
from 
OPE, opu,recon,giu_i, giu_r
;*/

with ope AS(
SELECT case when sum(c.cassaeconop_importo) is null then 0 else sum(c.cassaeconop_importo) end  
disponibilita_cassa_contanti
from siac_t_cassa_econ a, siac_t_cassa_econ_operaz c,siac_r_cassa_econ_operaz_tipo e,
siac_d_cassa_econ_operaz_tipo b,
siac_d_cassa_econ_modpag_tipo d, siac_r_cassa_econ_bil f,siac_t_bil g ,siac_t_periodo h
where 
c.cassaec_id=a.cassaecon_id
and e.cassaeconop_id=c.cassaeconop_id
and b.cassaeconop_tipo_id=e.cassaeconop_tipo_id
and c.cassamodpag_tipo_id=d.cassamodpag_tipo_id
and b.cassaeconop_tipo_entrataspesa='E'
and a.cassaecon_id=	id_cassaecon_in
and d.cassamodpag_tipo_code='CO'
and f.cassaecon_id=a.cassaecon_id
and f.bil_id=g.bil_id
and h.periodo_id=g.periodo_id
and h.anno=anno_in
and c.bil_id=g.bil_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
and c.data_cancellazione is NULL
and d.data_cancellazione is NULL
and e.data_cancellazione is NULL
and f.data_cancellazione is null
and g.data_cancellazione is NULL
and h.data_cancellazione is null
)
, opu as (
SELECT case when sum(c.cassaeconop_importo) is null then 0 else sum(c.cassaeconop_importo) end  
disponibilita_cassa_contanti
from siac_t_cassa_econ a, siac_t_cassa_econ_operaz c,siac_r_cassa_econ_operaz_tipo e,
siac_d_cassa_econ_operaz_tipo b,
siac_d_cassa_econ_modpag_tipo d,
siac_r_cassa_econ_bil f,siac_t_bil g ,siac_t_periodo h
where 
c.cassaec_id=a.cassaecon_id
and e.cassaeconop_id=c.cassaeconop_id
and b.cassaeconop_tipo_id=e.cassaeconop_tipo_id
and c.cassamodpag_tipo_id=d.cassamodpag_tipo_id
and b.cassaeconop_tipo_entrataspesa='U'
and a.cassaecon_id=	id_cassaecon_in
and d.cassamodpag_tipo_code='CO'
and f.cassaecon_id=a.cassaecon_id
and f.bil_id=g.bil_id
and h.periodo_id=g.periodo_id
and h.anno=anno_in
and c.bil_id=g.bil_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
and c.data_cancellazione is NULL
and d.data_cancellazione is NULL
and e.data_cancellazione is NULL
and f.data_cancellazione is null
and g.data_cancellazione is NULL
and h.data_cancellazione is null
),
recon as ( 
select case when sum(tb.ricecon_importo) is null then 0 else sum(tb.ricecon_importo) end  
ricecon_importo 
from (
select distinct d.ricecon_id, d.ricecon_importo
   from 
   siac_d_cassa_econ_modpag_tipo a, 
   siac_t_cassa_econ c,
   siac_t_richiesta_econ d, 
   siac_t_movimento e,siac_d_richiesta_econ_tipo f,
siac_r_cassa_econ_bil f2,siac_t_bil g ,siac_t_periodo h
  where 
   a.cassamodpag_tipo_code='CO'
  and c.cassaecon_id=id_cassaecon_in
  and d.cassaecon_id=c.cassaecon_id
  and e.cassamodpag_tipo_id=a.cassamodpag_tipo_id
  and d.ricecon_id=e.ricecon_id
  and f.ricecon_tipo_id=d.ricecon_tipo_id
  and f2.cassaecon_id=c.cassaecon_id
and f2.bil_id=g.bil_id
and h.periodo_id=g.periodo_id
and h.anno=anno_in
and d.bil_id=g.bil_id
  and f.ricecon_tipo_code in ( 'RIMBORSO_SPESE','ANTICIPO_SPESE','ANTICIPO_SPESE_MISSIONE','ANTICIPO_TRASFERTA_DIPENDENTI',
  'PAGAMENTO_FATTURE')) tb),
  giu_r as (select case when sum(a.rend_importo_restituito) is null then 0 else sum(a.rend_importo_restituito) end 
rend_importo_restituito
from 
siac_t_giustificativo a, 
siac_t_richiesta_econ e, siac_t_bil f,siac_t_periodo g
where 
e.ricecon_id=a.ricecon_id
and f.bil_id=e.bil_id
and f.periodo_id=g.periodo_id
and g.anno=anno_in
and e.cassaecon_id=id_cassaecon_in
)  
  ,
giu_i as (select case when sum(a.rend_importo_integrato) is null then 0 else sum(a.rend_importo_integrato) end 
rend_importo_integrato
from siac_t_giustificativo a, 
siac_t_richiesta_econ e, siac_t_bil f,siac_t_periodo g
where 
e.ricecon_id=a.ricecon_id
and f.bil_id=e.bil_id
and f.periodo_id=g.periodo_id
and g.anno=anno_in
and e.bil_id=f.bil_id
and e.cassaecon_id=id_cassaecon_in
)  
select 
ope.disponibilita_cassa_contanti+giu_r.rend_importo_restituito
-recon.ricecon_importo-giu_i.rend_importo_integrato-opu.disponibilita_cassa_contanti 
into disponibilita_cassa_contanti
from 
OPE, opu,recon,giu_i, giu_r
;



return disponibilita_cassa_contanti;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return -1;
   when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return -1;
    when no_data_found then
			RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return -1;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return -1;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;