/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


select * from fnc_tefa_trib_versamenti_estrai(2, 344198, 2021)
select * from fnc_tefa_trib_comune_anno_rif_estrai_new(2, 344198, 2021)
select * from fnc_tefa_trib_comune_anno_rif_estrai(2, 344198, 2021)
select * from fnc_tefa_trib_comune_estrai(2, 344198, 2021);


select  *
from siac_t_tefa_trib_gruppo_upload upd
where upd.ente_proprietario_id=2
and  upd.tefa_trib_file_id=344198
select *
from siac_d_tefa_trib_comune 


select  count(*), tefa.tefa_trib_file_id
from siac_t_tefa_trib_importi tefa
where tefa.ente_proprietario_id=2
group by tefa.tefa_trib_file_id

758901

select distinct gruppo.tefa_trib_gruppo_code
from siac_t_tefa_trib_gruppo_upload upd ,siac_d_tefa_trib_gruppo gruppo 
where upd.ente_proprietario_id=2
and   gruppo.tefa_trib_gruppo_id=upd.tefa_trib_gruppo_id

select  distinct gruppo.tefa_trib_gruppo_code
from siac_t_tefa_trib_importi tefa ,siac_d_tefa_tributo trib , siac_d_tefa_trib_gruppo gruppo,
     siac_r_tefa_tributo_gruppo r
where tefa.tefa_trib_tributo_code=trib.tefa_trib_code
and   r.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r.tefa_trib_gruppo_id
and   gruppo.tefa_trib_gruppo_anno=tefa.tefa_trib_anno_rif_str


select     tefa.tefa_trib_anno_rif, tefa.tefa_trib_anno_rif_str,count(*)
from siac_t_tefa_trib_importi tefa
where tefa.ente_proprietario_id=2
group by tefa.tefa_trib_anno_rif, tefa.tefa_trib_anno_rif_str

select    tefa.tefa_nome_file,count(*)
from siac_t_tefa_trib_importi tefa
where tefa.ente_proprietario_id=2
group by tefa.tefa_nome_file
order by 1 desc 

select *
from siac_t_tefa_trib_gruppo_upload
where tefa_trib_file_id=344198


-- Q1
select query.data_ripartizione::varchar,
          query.data_bonifico::varchar,
          upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,
          query.importo_a_debito_versato::numeric,
          query.importo_a_credito_compensato::numeric,
          query.anno_di_riferimento_str::varchar,
          query.importo_tefa_lordo::numeric,
          query.importo_credito::numeric,
          query.importo_comm::numeric,
          query.importo_tefa_netto::numeric
  from
  (

  with
raggruppa_sel as 
(select trib.tefa_trib_code, trib.tefa_trib_desc,
       gruppo.tefa_trib_gruppo_code,
       gruppo.tefa_trib_gruppo_desc,
       gruppo.tefa_trib_gruppo_f1_id,
       gruppo.tefa_trib_gruppo_f2_id,
       gruppo.tefa_trib_gruppo_f3_id,
       gruppo.tefa_trib_gruppo_anno,
	   tipo.tefa_trib_gruppo_tipo_code,
	   tipo.tefa_trib_gruppo_tipo_desc, 
	   tipo.tefa_trib_gruppo_tipo_f1_id,
	   tipo.tefa_trib_gruppo_tipo_f2_id,
	   tipo.tefa_trib_gruppo_tipo_f3_id	,
	   trib.tefa_trib_id,
	   gruppo.tefa_trib_gruppo_id,
	   gruppo.tefa_trib_gruppo_tipo_id
from siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_gruppo_tipo tipo
where  trib.ente_proprietario_id=2
  and  r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and  gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and  tipo.tefa_trib_gruppo_tipo_id=gruppo.tefa_trib_gruppo_tipo_id
  and  trib.data_cancellazione is null
  and  trib.validita_fine is null
  and  gruppo.data_cancellazione is null 
  and  gruppo.validita_fine is null 
  and  tipo.data_cancellazione is null 
  and  tipo.validita_fine is null 
  and  r_gruppo.data_cancellazione is null
  and  r_gruppo.validita_fine  is null
 ),
 tefa_sel as 
 (
 select tefa.tefa_trib_file_id ,tefa.tefa_trib_tributo_code,tefa.tefa_trib_data_ripart,tefa.tefa_trib_data_bonifico,tefa.tefa_trib_anno_rif,tefa.tefa_trib_anno_rif_str,
        tefa.tefa_trib_importo_versato_deb,tefa.tefa_trib_importo_compensato_cred
 from  siac_t_tefa_trib_importi tefa
 where tefa.ente_proprietario_id=2 
 and   tefa.tefa_trib_file_id=344198
 and   tefa.tefa_trib_tipo_record='D'
 and   tefa.data_cancellazione is null 
 and   tefa.validita_fine is null 
 ) 
 select
   tefa_sel.tefa_trib_file_id,
   (case when tefa_sel.tefa_trib_data_ripart like '%-%' then
              tefa_sel.tefa_trib_data_ripart
          else
             substring(tefa_sel.tefa_trib_data_ripart,7,4)||'/'||substring(tefa_sel.tefa_trib_data_ripart,4,2)||'/'||substring(tefa_sel.tefa_trib_data_ripart,1,2)
    end)::timestamp  data_ripartizione_dt,
   (case when tefa_sel.tefa_trib_data_bonifico like '%-%' then
              tefa_sel.tefa_trib_data_bonifico
          else
             substring(tefa_sel.tefa_trib_data_bonifico,7,4)||'/'||substring(tefa_sel.tefa_trib_data_bonifico,4,2)||'/'||substring(tefa_sel.tefa_trib_data_bonifico,1,2)
    end)::timestamp  data_bonifico_dt,
   (case when tefa_sel.tefa_trib_data_ripart like '%-%' then
         substring(tefa_sel.tefa_trib_data_ripart,9,2)||'/'||substring(tefa_sel.tefa_trib_data_ripart,6,2)||'/'||substring(tefa_sel.tefa_trib_data_ripart,1,4)
         else      tefa_sel.tefa_trib_data_ripart end)  data_ripartizione,
   (case when tefa_sel.tefa_trib_data_bonifico like '%-%' then
         substring(tefa_sel.tefa_trib_data_bonifico,9,2)||'/'||substring(tefa_sel.tefa_trib_data_bonifico,6,2)||'/'||substring(tefa_sel.tefa_trib_data_bonifico,1,4)
         else      tefa_sel.tefa_trib_data_bonifico end)  data_bonifico,
   raggruppa_sel.tefa_trib_gruppo_tipo_id,
   tefa_sel.tefa_trib_anno_rif_str anno_di_riferimento_str,
   sum(tefa_sel.tefa_trib_importo_versato_deb) importo_a_debito_versato ,
   sum(tefa_sel.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo ,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_compensato_cred)
                                 ) importo_credito,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_versato_deb)
                                 )
                                 ) importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_versato_deb)
                                 ) -
  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_compensato_cred)
                                 ) -
 (
 fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_versato_deb)
                                 )
                                 )
 ) importo_tefa_netto
from raggruppa_sel , tefa_sel 
where   raggruppa_sel.tefa_trib_code=tefa_sel.tefa_trib_tributo_code
  and   raggruppa_sel.tefa_trib_gruppo_anno=tefa_sel.tefa_trib_anno_rif_str
group by tefa_sel.tefa_trib_file_id,
	     tefa_sel.tefa_trib_data_ripart,
         tefa_sel.tefa_trib_data_bonifico,
         raggruppa_sel.tefa_trib_gruppo_tipo_id,
         raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,
         tefa_sel.tefa_trib_anno_rif_str
order by 2,3,raggruppa_sel.tefa_trib_gruppo_tipo_id
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_tipo_id=query.tefa_trib_gruppo_tipo_id -- index
and   upd.data_cancellazione is null 
and   upd.validita_fine is null 
order by query.data_ripartizione_dt,query.data_bonifico_dt,
         query.tefa_trib_gruppo_tipo_id;

        
 --- Q2
 select query.codice_comune::varchar,
       upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,
       query.importo_a_debito_versato::numeric,
       query.importo_a_credito_compensato::numeric,
       query.anno_di_riferimento_str::varchar,
       query.ente::varchar,
       query.anno_di_riferimento::varchar,
       query.tipologia::varchar,
       query.importo_tefa_lordo::numeric,
       query.importo_credito::numeric,
       query.importo_comm::numeric,
       query.importo_tefa_netto::numeric
 from
 (
 with 
 raggruppa_sel as
 (
 select tipo.tefa_trib_tipologia_id,
        tipo.tefa_trib_tipologia_code,
        tipo.tefa_trib_tipologia_desc,
        gruppo.tefa_trib_gruppo_code,
        gruppo.tefa_trib_gruppo_desc,
        gruppo.tefa_trib_gruppo_anno,
        gruppo.tefa_trib_gruppo_f1_id,
        gruppo.tefa_trib_gruppo_f2_id,
        gruppo.tefa_trib_gruppo_f3_id,
        trib.tefa_trib_code,
        trib.tefa_trib_desc,
        trib.tefa_trib_id,
        gruppo.tefa_trib_gruppo_id,        
        tipo.tefa_trib_tipologia_id
 from  siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
       siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
 where trib.ente_proprietario_id=2
  and  r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and  gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and  tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
  and  trib.data_cancellazione is null
  and  trib.validita_fine is null
  and  gruppo.data_cancellazione is null
  and  gruppo.validita_fine is null
  and  tipo.data_cancellazione is null
  and  tipo.validita_fine is null
  and  r_gruppo.data_cancellazione is null
  and  r_gruppo.validita_fine is null
 ),
 tefa_sel as 
 (
 select tefa.tefa_trib_file_id,
        tefa.tefa_trib_tributo_code,
        tefa.tefa_trib_comune_code,
        tefa.tefa_trib_importo_versato_deb,
        tefa.tefa_trib_importo_compensato_cred,
        tefa.tefa_trib_anno_rif_str,
        com.tefa_trib_comune_cat_desc
 from siac_t_tefa_trib_importi tefa 
      left join siac_d_tefa_trib_comune com on (com.ente_proprietario_id=tefa.ente_proprietario_id and com.tefa_trib_comune_code=tefa.tefa_trib_comune_code and com.data_cancellazione is null )
 where tefa.ente_proprietario_id=2      
 and   tefa.tefa_trib_file_id=344198
 and   tefa.tefa_trib_tipo_record='D'
 and   tefa.data_cancellazione is null
 and   tefa.validita_fine is null

 )
 select
   tefa_sel.tefa_trib_file_id,
   tefa_sel.tefa_trib_comune_code codice_comune,
   raggruppa_sel.tefa_trib_gruppo_id ,
   sum(tefa_sel.tefa_trib_importo_versato_deb) importo_a_debito_versato,
   sum(tefa_sel.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   tefa_sel.tefa_trib_anno_rif_str anno_di_riferimento_str,
   tefa_sel.tefa_trib_comune_cat_desc ente,
   tefa_sel.tefa_trib_anno_rif_str anno_di_riferimento,
   raggruppa_sel.tefa_trib_tipologia_desc tipologia,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_compensato_cred)
                                  ) importo_credito,
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa_sel.tefa_trib_importo_versato_deb))
                                )  importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_versato_deb)) -
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_compensato_cred)) -
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_versato_deb) )
                                  ) importo_tefa_netto
from  raggruppa_sel , tefa_sel
where raggruppa_sel.tefa_trib_code=tefa_sel.tefa_trib_tributo_code
  and raggruppa_sel.tefa_trib_gruppo_anno=tefa_sel.tefa_trib_anno_rif_str
group by tefa_sel.tefa_trib_file_id,
	     tefa_sel.tefa_trib_comune_code,
         raggruppa_sel.tefa_trib_gruppo_id,
         raggruppa_sel.tefa_trib_gruppo_f1_id,raggruppa_sel.tefa_trib_gruppo_f2_id,raggruppa_sel.tefa_trib_gruppo_f3_id,
         tefa_sel.tefa_trib_comune_cat_desc,
         tefa_sel.tefa_trib_anno_rif_str,
         raggruppa_sel.tefa_trib_tipologia_desc
order by 2,3
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
and   upd.data_cancellazione is null 
and   upd.validita_fine is null
order by 1,query.tefa_trib_gruppo_id;




select  *
from siac_t_tefa_trib_gruppo_upload upd
where upd.ente_proprietario_id=2
and  upd.tefa_trib_file_id=344198
select * from fnc_tefa_trib_comune_anno_rif_estrai(2, 344198, 2021)

delete 
from siac_t_tefa_trib_gruppo_upload upd
where upd.ente_proprietario_id=2
and  upd.tefa_trib_file_id=344198


insert into siac_t_tefa_trib_gruppo_upload
(
	tefa_trib_file_id,
	tefa_trib_gruppo_tipo_id,
	tefa_trib_gruppo_upload,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select 344198,
       gruppo.tefa_trib_gruppo_tipo_id,
	   fnc_tefa_trib_raggruppamento( gruppo.tefa_trib_gruppo_tipo_id,null ,344198),
       now(),
       'admin',
       gruppo.ente_proprietario_id
from siac_d_tefa_trib_gruppo_tipo gruppo
where gruppo.ente_proprietario_id=2;


insert into siac_t_tefa_trib_gruppo_upload
(
	tefa_trib_file_id,
	tefa_trib_gruppo_id,
	tefa_trib_gruppo_upload,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select 344198,
       gruppo.tefa_trib_gruppo_id,
	   fnc_tefa_trib_raggruppamento( null,gruppo.tefa_trib_gruppo_id ,344198),
       now(),
       'admin',
       gruppo.ente_proprietario_id
from siac_d_tefa_trib_gruppo gruppo
where gruppo.ente_proprietario_id=2;



select distinct trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo,
     siac_t_tefa_trib_importi trib_imp
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(1,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(2,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and   trib_imp.ente_proprietario_id=gruppo.ente_proprietario_id
and   trib_imp.tefa_trib_file_id=344198
and   trib_imp.tefa_trib_tributo_code=trib.tefa_trib_code
and   trib_imp.tefa_trib_tipo_record='D'
and   gruppo.tefa_trib_gruppo_anno=trib_imp.tefa_trib_anno_rif_str
and  trib.data_cancellazione is null
and  trib.validita_fine is null
and  trib_imp.data_cancellazione is null
and  trib_imp.validita_fine is null
and  gruppo.data_cancellazione is null
and  gruppo.validita_fine is null
and  r_tefa.data_cancellazione is null
and  r_tefa.validita_fine is null
order by 1 desc


with 
raggruppa_sel as
(
select gruppo.tefa_trib_gruppo_anno, trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(1,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(2,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and  trib.data_cancellazione is null
and  trib.validita_fine is null
and  gruppo.data_cancellazione is null
and  gruppo.validita_fine is null
and  r_tefa.data_cancellazione is null
and  r_tefa.validita_fine is null
),
tefa_sel as
(
select trib_imp.tefa_trib_tributo_code, trib_imp.tefa_trib_anno_rif_str
from siac_t_tefa_trib_importi trib_imp
where trib_imp.tefa_trib_file_id=344198
and   trib_imp.tefa_trib_tipo_record='D'
and   trib_imp.data_cancellazione is null
and   trib_imp.validita_fine is null
)
select  distinct raggruppa_sel.tefa_trib_code 
from raggruppa_sel, tefa_sel 
where tefa_sel.tefa_trib_tributo_code=raggruppa_sel.tefa_trib_code
and   tefa_sel.tefa_trib_anno_rif_str=raggruppa_sel.tefa_trib_gruppo_anno



        
        select *
        from siac_d_tefa_trib_tipologia 
        
          select *
        from siac_d_tefa_trib_gruppo_tipo
        
        
INSERT INTO siac_d_tefa_trib_gruppo 
(tefa_trib_gruppo_code,tefa_trib_gruppo_desc,validita_inizio,validita_fine,data_creazione,data_modifica,data_cancellazione,
login_operazione,ente_proprietario_id,tefa_trib_gruppo_anno,
tefa_trib_tipologia_id,tefa_trib_gruppo_f3_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f1_id,tefa_trib_gruppo_tipo_id)
VALUES
('16','>=2021 TARI','2021-05-19 16:45:15.896867',NULL,'2021-05-19 16:45:15.896867',NULL,NULL,'admin',2,'>=2021'
,4,NULL,2,2,5);
INSERT INTO siac_d_tefa_trib_gruppo 
(tefa_trib_gruppo_code,tefa_trib_gruppo_desc,validita_inizio,validita_fine,data_creazione,data_modifica,data_cancellazione,login_operazione,ente_proprietario_id,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,tefa_trib_gruppo_f3_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f1_id,tefa_trib_gruppo_tipo_id)
VALUES
('17','>=2021 TARI INTERESSI','2021-05-19 16:45:16.02943',NULL,'2021-05-19 16:45:16.02943',NULL,NULL,'admin',2,'>=2021',
5,NULL,2,2,5);
INSERT INTO siac_d_tefa_trib_gruppo 
(tefa_trib_gruppo_code,tefa_trib_gruppo_desc,validita_inizio,validita_fine,data_creazione,data_modifica,data_cancellazione,login_operazione,ente_proprietario_id,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,tefa_trib_gruppo_f3_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f1_id,tefa_trib_gruppo_tipo_id)
values ('18','>=2021 TARI SANZIONE','2021-05-19 16:45:16.165641',NULL,'2021-05-19 16:45:16.165641',NULL,NULL,'admin',2,'>=2021',
6,NULL,2,2,5);



 
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '16','>=2021 TARI','>=2021',4,2,2,NULL,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='16' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );


insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '17','>=2021 TARI INTERESSI','>=2021',5,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='17' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
			
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '18','>=2021 TARI SANZIONE','>=2021',6,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='18' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
			




insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3920' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3944' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3950' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='365E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='368E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3921' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3945' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3951' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='366E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='369E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3922' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3946' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3952' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='367E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='370E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );