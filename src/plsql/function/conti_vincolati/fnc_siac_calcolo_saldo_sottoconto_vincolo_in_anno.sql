/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists siac.fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno
(
  enteproprietarioid   integer,
  annoBilancio         integer
);



CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno
(
  enteproprietarioid   integer,
  annoBilancio         integer
)
RETURNS table 
(
contotes_code character varying,
contotes_desc character varying,
contotes_disp_id integer,
vincolo_code character varying,
vincolo_id   integer,
ripiano_vincolo_conto numeric,
saldo_vincolo_conto numeric
) 
AS $body$
 
DECLARE


BEGIN
	
raise notice 'fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno in annoBilancio=%',annoBilancio::varchar;

return query	
select vincoli_ordinativi_finale.contotes_code as contotes_code, 
       vincoli_ordinativi_finale.contotes_desc as contotes_desc,  
       vincoli_ordinativi_finale.contotes_disp_id as contotes_disp_id,
       vincoli_ordinativi_finale.vincolo_code as vincolo_code,
       vincoli_ordinativi_finale.vincolo_id as vincolo_id ,
       sum(vincoli_ordinativi_finale.ord_ts_det_importo_ripiano) as ripiano_vincolo_conto, -- sommatoria finale di ripiano
       sum(vincoli_ordinativi_finale.ord_ts_det_importo) as saldo_vincolo_conto -- sommatoria finale  di saldo
from         
(
select vincoli_ordinativi_sommati.contotes_code, 
       vincoli_ordinativi_sommati.contotes_desc, 
       vincoli_ordinativi_sommati.contotes_disp_id,
       vincoli_ordinativi_sommati.vincolo_code,
       vincoli_ordinativi_sommati.vincolo_id,
       vincoli_ordinativi_sommati.ord_tipo_code,
       -- inverti segno pagamenti
       ( case when vincoli_ordinativi_sommati.ord_tipo_code='P' then -vincoli_ordinativi_sommati.ord_ts_det_importo_ripiano else vincoli_ordinativi_sommati.ord_ts_det_importo_ripiano end ) ord_ts_det_importo_ripiano, 
       ( case when vincoli_ordinativi_sommati.ord_tipo_code='P' then -vincoli_ordinativi_sommati.ord_ts_det_importo else vincoli_ordinativi_sommati.ord_ts_det_importo end ) ord_ts_det_importo
       
from 
(
select vincoli_ordinativi.contotes_code, 
       vincoli_ordinativi.contotes_desc, 
       vincoli_ordinativi.contotes_disp_id,
       vincoli_ordinativi.vincolo_code,
       vincoli_ordinativi.vincolo_id,
       vincoli_ordinativi.ord_tipo_code, 
       vincoli_ordinativi.ord_tipo_id,
       sum((case when contotes_nodisp_id is not null then det.ord_ts_det_importo else 0 end)) ord_ts_det_importo_ripiano,
       sum((case when contotes_nodisp_id is null     then det.ord_ts_det_importo else 0 end)) ord_ts_det_importo
    --   sum(det.ord_ts_det_importo) ord_ts_det_importo -- somma per conto , vincolo, pagamenti-incassi
from 
(
    with 
    vincoli as 
    (
    select vinc.vincolo_code,  
           tipo_e.elem_tipo_code, e.elem_code,
           vinc.vincolo_id, e.elem_id 
    from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo,siac_t_periodo per,siac_t_bil bil,
         siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,siac_r_vincolo_bil_elem r,
         siac_t_bil_elem e,siac_d_bil_elem_tipo tipo_e
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.vincolo_tipo_code='G'
    and   vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
    and   per.periodo_id=vinc.periodo_id 
    and   bil.periodo_id=per.periodo_id 
    and   per.anno::integer=annoBilancio
    and   rs.vincolo_id=vinc.vincolo_id 
    and   stato.vincolo_stato_id=rs.vincolo_stato_id 
    and   stato.vincolo_stato_code!='A'
    and   r.vincolo_id=vinc.vincolo_id 
    and   e.elem_id=r.elem_id 
    and   tipo_e.elem_tipo_id=e.elem_tipo_id 
    and   tipo_e.elem_tipo_code in ('CAP-UG','CAP-EG')
    and   r.data_cancellazione is null 
    and   r.validita_fine is null 
    and   rs.data_cancellazione is null 
    and   rs.validita_fine is null 
    order by 1, 2,3
   ),
   ordinativi as
   (
   with 
   ord_conti as 
   (
   select tipo.ord_tipo_code, tipo.ord_tipo_id,ord.ord_numero,
          conto.contotes_code,
          re.elem_id, ord.ord_id , 
          conto.contotes_id,
          --(case when estraiRipiano=true then rconto.contotes_id  else null end) contotes_nodisp_id, 
          rconto.contotes_id contotes_nodisp_id,
          coalesce(conto.per_ripianamento,false) per_ripianamento
   from siac_t_bil bil,siac_t_periodo per,
	    siac_d_ordinativo_tipo tipo, 
        siac_t_ordinativo ord left join siac_r_ordinativo_contotes_nodisp rconto on (rconto.ord_id=ord.ord_id and rconto.data_cancellazione is null and  rconto.validita_fine is null),
        siac_r_ordinativo_stato rs,siac_d_ordinativo_stato stato ,
        siac_d_contotesoreria conto,
        siac_r_ordinativo_bil_elem re
   where tipo.ente_proprietario_id=enteProprietarioId
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   rs.ord_id=ord.ord_id 
   and   stato.ord_stato_id=rs.ord_Stato_id 
--   and   stato.ord_stato_code!='A'
   and   stato.ord_stato_code='Q'
   and   conto.contotes_id=ord.contotes_id
   and   ( conto.vincolato=true or conto.per_ripianamento=true )
   and   re.ord_id=ord.ord_id 
   and   bil.bil_id=ord.bil_id 
   and   per.periodo_id=bil.periodo_id 
   and   per.anno::integer=annoBilancio
   and   rs.data_cancellazione is null 
   and   rs.validita_fine is null 
   and   re.data_cancellazione is null 
   and   re.validita_fine is null 
   )
   select ord_conti.ord_tipo_code,ord_conti.ord_tipo_id,ord_conti.ord_numero,
          ord_conti.contotes_code,
          ord_conti.elem_id, ord_conti.ord_id , 
          ord_conti.contotes_id,
          ord_conti.contotes_nodisp_id, 
          ord_conti.per_ripianamento,
--          (case  when ord_conti.contotes_nodisp_id is not null  then ord_conti.contotes_nodisp_id
--                 when estraiRipiano=false and ord_conti.per_ripianamento=false and ord_conti.contotes_nodisp_id is null  then ord_conti.contotes_id
--                 else null end ) contotes_disp_id
          (case  when ord_conti.contotes_nodisp_id is not null  then ord_conti.contotes_nodisp_id
                 when ord_conti.contotes_nodisp_id is null and ord_conti.per_ripianamento=false  then ord_conti.contotes_id
                 else null end ) contotes_disp_id       
   from ord_conti 
   )
   select conto.contotes_code,         -- contotes_code da utilizzare per calcolo disp
          conto.contotes_desc,         -- contotes_desc da utilizzare per calcolo disp  
          ordinativi.contotes_disp_id, -- contotes_id   da utilizzare per calcolo disp
          vincoli.vincolo_code,
          vincoli.vincolo_id,
          ordinativi.ord_tipo_code, 
          ordinativi.ord_tipo_id,
          ordinativi.ord_numero,
          ordinativi.elem_id, 
          ordinativi.ord_id , 
          ordinativi.contotes_code ord_contotes_code, -- contotes diretto su ordinativo 
          ordinativi.contotes_id   ord_contotes_id,   -- contotes diretto su ordinativo
          ordinativi.contotes_nodisp_id,              -- contotes indiretto attraverso ripianamento
          ordinativi.per_ripianamento
   from  vincoli , ordinativi ,siac_d_contotesoreria conto
   where vincoli.elem_id=ordinativi.elem_id 
   and   conto.contotes_id=ordinativi.contotes_disp_id 
) vincoli_ordinativi , siac_t_ordinativo_ts ts,siac_t_ordinativo_ts_det det,siac_d_ordinativo_ts_det_tipo tipo 
where vincoli_ordinativi.ord_id=ts.ord_id 
and   det.ord_ts_id=ts.ord_ts_id 
and   tipo.ord_ts_det_tipo_id=det.ord_ts_Det_tipo_id
and   tipo.ord_ts_det_tipo_code='A'
and   det.data_cancellazione is null 
and   det.validita_fine is null 
-- somma per conto , vincolo, pagamenti-incassi
group by vincoli_ordinativi.contotes_code, 
         vincoli_ordinativi.contotes_desc, 
        vincoli_ordinativi.contotes_disp_id,
        vincoli_ordinativi.vincolo_code,
        vincoli_ordinativi.vincolo_id,
        vincoli_ordinativi.ord_tipo_code,
        vincoli_ordinativi.ord_tipo_id
) vincoli_ordinativi_sommati
) vincoli_ordinativi_finale 
-- sommatoria finale 
group by vincoli_ordinativi_finale.contotes_code, 
       vincoli_ordinativi_finale.contotes_desc, 
       vincoli_ordinativi_finale.contotes_disp_id,
       vincoli_ordinativi_finale.vincolo_code,
       vincoli_ordinativi_finale.vincolo_id;
     
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno(integer, integer ) OWNER TO siac;
