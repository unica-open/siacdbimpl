/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- OK MA LENTE
--- OK estrazione per comune, tributo
--  Q1 senza dettaglio anno di riferimento
select query.codice_comune,
       upd.tefa_trib_gruppo_upload raggruppamento_codice_tributo,
       query.importo_a_debito_versato,
       query.importo_a_credito_compensato,
       query.anno_di_riferimento_str,
       query.ente,
       query.tipologia,
       query.importo_tefa_lordo,
       query.importo_credito,
       query.importo_comm,
       query.importo_tefa_netto
from
(

select
    tefa.tefa_trib_upload_id,
    tefa.tefa_trib_comune_code codice_comune,
    gruppo.tefa_trib_gruppo_id ,
    sum(tefa.tefa_trib_importo_versato_deb) importo_a_debito_versato,
    sum(tefa.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '''=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end ) anno_di_riferimento_str,
   com.tefa_trib_comune_cat_desc ente,
   tipo.tefa_trib_tipologia_desc tipologia,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo, --1
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                  ) importo_credito, --2
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa.tefa_trib_importo_versato_deb))
                                )  importo_comm, -- 3
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb)) - -- 1
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_compensato_cred)) - -- 2
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb) ) --1
                                  ) importo_tefa_netto -- 3
from siac_t_tefa_trib_importi tefa,siac_d_tefa_trib_comune com,
     siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
where tefa.ente_proprietario_id=2
and   tefa.tefa_trib_upload_id=3
and   com.ente_proprietario_id=2
and   com.tefa_trib_comune_code=tefa.tefa_trib_comune_code
and   trib.ente_proprietario_id=2
and   trib.tefa_trib_code=tefa.tefa_trib_tributo_code
and   r_gruppo.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
and   gruppo.tefa_trib_gruppo_anno=
       ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end )
and   tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
and   r_gruppo.data_cancellazione is null
and   r_gruppo.validita_fine is null
group by tefa.tefa_trib_upload_id,
	     tefa.tefa_trib_comune_code,
         gruppo.tefa_trib_gruppo_id,
         gruppo.tefa_trib_gruppo_f1_id,gruppo.tefa_trib_gruppo_f2_id,gruppo.tefa_trib_gruppo_f3_id,
		 ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '''=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end ),
         com.tefa_trib_comune_cat_desc,
         tipo.tefa_trib_tipologia_desc
order by 2,3
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_upload_id=query.tefa_trib_upload_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
order by 1,query.tefa_trib_gruppo_id

--  Q2 con dettaglio anno di riferimento per >=2021
select query.codice_comune,
       upd.tefa_trib_gruppo_upload raggruppamento_codice_tributo,
       query.importo_a_debito_versato,
       query.importo_a_credito_compensato,
       query.anno_di_riferimento_str,
       query.ente,
       query.anno_di_riferimento,
       query.tipologia,
       query.importo_tefa_lordo,
       query.importo_credito,
       query.importo_comm,
       query.importo_tefa_netto
from
(

select
    tefa.tefa_trib_upload_id,
    tefa.tefa_trib_comune_code codice_comune,
    gruppo.tefa_trib_gruppo_id ,
   ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '''=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end ) anno_di_riferimento_str,
   com.tefa_trib_comune_cat_desc ente,
   (case when tefa.tefa_trib_anno_rif::integer<=2019 then 2019
   	     when tefa.tefa_trib_anno_rif::integer=2020 then tefa.tefa_trib_anno_rif::integer
         when tefa.tefa_trib_anno_rif::integer>=2021 then tefa.tefa_trib_anno_rif::integer else null end ) anno_di_riferimento,
   tipo.tefa_trib_tipologia_desc tipologia,
   sum(tefa.tefa_trib_importo_versato_deb) importo_a_debito_versato,
   sum(tefa.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo, --1
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                  ) importo_credito, --2
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa.tefa_trib_importo_versato_deb))
                                )  importo_comm, -- 3
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb)) - -- 1
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_compensato_cred)) - -- 2
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb) ) --1
                                  ) importo_tefa_netto -- 3
from siac_t_tefa_trib_importi tefa,siac_d_tefa_trib_comune com,
     siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
where tefa.ente_proprietario_id=2
and   tefa.tefa_trib_upload_id=2
and   com.ente_proprietario_id=2
and   com.tefa_trib_comune_code=tefa.tefa_trib_comune_code
and   trib.ente_proprietario_id=2
and   trib.tefa_trib_code=tefa.tefa_trib_tributo_code
and   r_gruppo.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
and   gruppo.tefa_trib_gruppo_anno=
      ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end )
and   tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
and   r_gruppo.data_cancellazione is null
and   r_gruppo.validita_fine is null
group by tefa.tefa_trib_upload_id,
	     tefa.tefa_trib_comune_code,
         gruppo.tefa_trib_gruppo_id,
         gruppo.tefa_trib_gruppo_f1_id,gruppo.tefa_trib_gruppo_f2_id,gruppo.tefa_trib_gruppo_f3_id,
	     ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '''=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end ),
          com.tefa_trib_comune_cat_desc,
         (case when tefa.tefa_trib_anno_rif::integer<=2019 then 2019
   	           when tefa.tefa_trib_anno_rif::integer=2020 then tefa.tefa_trib_anno_rif::integer
               when tefa.tefa_trib_anno_rif::integer>=2021 then tefa.tefa_trib_anno_rif::integer else null end ),
          tipo.tefa_trib_tipologia_desc
order by 2,3

) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_upload_id=query.tefa_trib_upload_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
order by 1,query.tefa_trib_gruppo_id


-- OK per date
-- Q3 per date
  select query.data_ripartizione,
         query.data_bonifico,
         upd.tefa_trib_gruppo_upload raggruppamento_codice_tributo,
         query.importo_a_debito_versato,
         query.importo_a_credito_compensato,
         query.anno_di_riferimento_str,
         query.importo_tefa_lordo,
         query.importo_credito,
         query.importo_comm,
         query.importo_tefa_netto
  from
  (


  select
   tefa.tefa_trib_upload_id,
   (case when tefa.tefa_trib_data_ripart like '%-%' then
              tefa.tefa_trib_data_ripart
          else
             substring(tefa.tefa_trib_data_ripart,7,4)||'-'||substring(tefa.tefa_trib_data_ripart,4,2)||'-'||substring(tefa.tefa_trib_data_ripart,1,2)
    end)::timestamp  data_ripartizione_dt,
   (case when tefa.tefa_trib_data_bonifico like '%-%' then
              tefa.tefa_trib_data_bonifico
          else
             substring(tefa.tefa_trib_data_bonifico,7,4)||'-'||substring(tefa.tefa_trib_data_bonifico,4,2)||'-'||substring(tefa.tefa_trib_data_bonifico,1,2)
    end)::timestamp  data_bonifico_dt,
   (case when tefa.tefa_trib_data_ripart like '%-%' then
         substring(tefa.tefa_trib_data_ripart,9,2)||'/'||substring(tefa.tefa_trib_data_ripart,6,2)||'/'||substring(tefa.tefa_trib_data_ripart,1,4)
         else      tefa.tefa_trib_data_ripart end)  data_ripartizione,
   (case when tefa.tefa_trib_data_bonifico like '%-%' then
         substring(tefa.tefa_trib_data_bonifico,9,2)||'/'||substring(tefa.tefa_trib_data_bonifico,6,2)||'/'||substring(tefa.tefa_trib_data_bonifico,1,4)
         else      tefa.tefa_trib_data_bonifico end)  data_bonifico,
   gruppo.tefa_trib_gruppo_tipo_id,
  ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '''=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end ) anno_di_riferimento_str,
   sum(tefa.tefa_trib_importo_versato_deb) importo_a_debito_versato ,
   sum(tefa.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo , --1
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                 ) importo_credito, --2
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f3_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) -- 1
                                 ) importo_comm, --3
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) - --1
  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                 ) -  --2
 (
 fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f3_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) -- 1
                                 ) --3
 ) importo_tefa_netto                             -- 4
from siac_t_tefa_trib_importi tefa,
     siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_gruppo_tipo tipo
where tefa.ente_proprietario_id=2
and   tefa.tefa_trib_upload_id=2
and   trib.ente_proprietario_id=2
and   trib.tefa_trib_code=tefa.tefa_trib_tributo_code
and   r_gruppo.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
and   gruppo.tefa_trib_gruppo_anno=
      ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end )
and   tipo.tefa_trib_gruppo_tipo_id=gruppo.tefa_trib_gruppo_tipo_id
and   tefa.data_cancellazione is null
and   tefa.validita_fine  is null
and   r_gruppo.data_cancellazione is null
and   r_gruppo.validita_fine  is null

group by tefa.tefa_trib_upload_id,
	     tefa.tefa_trib_data_ripart,
         tefa.tefa_trib_data_bonifico,
         gruppo.tefa_trib_gruppo_tipo_id,
         tipo.tefa_trib_gruppo_tipo_f1_id,tipo.tefa_trib_gruppo_tipo_f2_id,tipo.tefa_trib_gruppo_tipo_f3_id,
	     ( case when tefa.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
          when tefa.tefa_trib_anno_rif::INTEGER=2020 then '''=2020'
          when tefa.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end )
order by 2,3,gruppo.tefa_trib_gruppo_tipo_id
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_upload_id=query.tefa_trib_upload_id
and   upd.tefa_trib_gruppo_tipo_id=query.tefa_trib_gruppo_tipo_id
order by query.data_ripartizione_dt,query.data_bonifico_dt,
         query.tefa_trib_gruppo_tipo_id