/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*
mi sono accorta, come mi ha fatto notare il mio collega Florjan, che forse è più corretto, nella estrazione per versamenti, tracciare i codici 39200-3921-3922 come un raggruppamento a se' per l'anno 2020.

Si tratterebbe di aggiungere un terzo raggruppamento per l'anno 2020. I raggruppamento dovrebbero diventare quindi:

TEFZ-TEFN-TEFA
3944 - 3950 - 365/E - 368/E 3945 - 3951 - 366/E - 369/E 3946 - 3952 - 367/E - 370/E
3920 - 3921 - 3922*/



select trib.tefa_trib_code, trib.tefa_trib_desc,
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
   where trib.ente_proprietario_id=3
   and   r_gruppo.tefa_trib_id=trib.tefa_trib_id
   and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
   and   tipo.tefa_trib_gruppo_tipo_id=gruppo.tefa_trib_gruppo_tipo_id
   and   trib.data_cancellazione is null
   and   trib.validita_fine is null
   and   gruppo.data_cancellazione is null 
   and   gruppo.validita_fine is null 
   and   tipo.data_cancellazione is null 
   and   tipo.validita_fine is null 
   and   r_gruppo.data_cancellazione is null
   and   r_gruppo.validita_fine  is null
   order by tipo.tefa_trib_gruppo_tipo_code::integer
   
select *
from siac_d_tefa_trib_comune  tefa 
where tefa.ente_proprietario_id =3
select * from siac_d_tefa_trib_gruppo_tipo tipo order by tefa_trib_gruppo_tipo_code 
select * from siac_r_tefa_tributo_gruppo r_gruppo
select * from siac_d_tefa_trib_gruppo  gruppo 
--3	3	7-12 10-12
--4	4	13-14-15


create table  siac_bck_tefa_trib_gruppo_tipo as select * from siac_d_tefa_trib_gruppo_tipo
create table  siac_bck_tefa_trib_gruppo as select * from siac_d_tefa_trib_gruppo

select * from siac_bck_tefa_trib_gruppo_tipo
select * from siac_bck_tefa_trib_gruppo


-- per raggruppare i gruppi  7,8,9 per 
-- 3920 - 3921 - 3922
insert into siac_d_tefa_trib_gruppo_tipo
(
	tefa_trib_gruppo_tipo_code,
	tefa_trib_gruppo_tipo_desc,
	tefa_trib_gruppo_tipo_f1_id,
	tefa_trib_gruppo_tipo_f2_id,
	tefa_trib_gruppo_tipo_f3_id,
	validita_inizio,
	login_operazione ,
	ente_proprietario_id 
)
select '7',
       '7-8-9',
       tipo.tefa_trib_gruppo_tipo_f1_id ,
       tipo.tefa_trib_gruppo_tipo_f2_id ,
       tipo.tefa_trib_gruppo_tipo_f3_id ,
       now(),
       'SIAC-8613',
       tipo.ente_proprietario_id 
from siac_d_tefa_trib_gruppo_tipo  tipo 
where tipo.ente_proprietario_id =3
and   tipo.tefa_trib_gruppo_tipo_id =3
and   not exists 
(
select 1
from siac_d_tefa_trib_gruppo_tipo  tipo1
where tipo1.ente_proprietario_id =tipo.ente_proprietario_id 
and   tipo1.tefa_trib_gruppo_tipo_code ='7'
and   tipo1.data_cancellazione  is null 
and   tipo1.validita_fine  is null
)
and  tipo.data_cancellazione  is null 
and  tipo.validita_fine is null;

update siac_d_tefa_trib_gruppo gruppo 
set    tefa_trib_gruppo_tipo_id =tipo.tefa_trib_gruppo_tipo_id ,
       data_modifica=now(),
       login_operazione =gruppo.login_operazione ||'-SIAC-8613'
from siac_d_tefa_trib_gruppo_tipo  tipo 
where tipo.ente_proprietario_id =3
and   tipo.tefa_trib_gruppo_tipo_code='7'
and   gruppo.ente_proprietario_id =3
and   gruppo.tefa_trib_gruppo_code  in ('7','8','9')
and   gruppo.login_operazione not like '%SIAC-8613'
and   gruppo.data_cancellazione  is null 
and   gruppo.validita_fine  is null 
and   tipo.data_cancellazione is null 
and   tipo.validita_fine is null; 



-- 3944 - 3950 - 365/E - 368/E 3945 - 3951 - 366/E - 369/E 3946 - 3952 - 367/E - 370/E
update siac_d_tefa_trib_gruppo_tipo  tipo 
set    tefa_trib_gruppo_tipo_desc ='10-12',
       data_modifica=now(),
       login_operazione =tipo.login_operazione ||'-SIAC-8613'
where tipo.ente_proprietario_id =3
and   tipo.tefa_trib_gruppo_tipo_id =3
and   tipo.login_operazione  not like '%SIAC-8613'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null;

update siac_d_tefa_trib_gruppo_tipo  tipo 
set    tefa_trib_gruppo_tipo_code =tipo.tefa_trib_gruppo_tipo_code ::integer+1,
       data_modifica=now(),
       login_operazione =tipo.login_operazione ||'-SIAC-8613-BIS'
where tipo.ente_proprietario_id =3
and   tipo.tefa_trib_gruppo_tipo_code::integer between 4 and 6
and   tipo.login_operazione not like '%SIAC-8613-BIS'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine  is null;


update siac_d_tefa_trib_gruppo_tipo  tipo 
set    tefa_trib_gruppo_tipo_code =4,
       data_modifica=now(),
       login_operazione =tipo.login_operazione ||'-SIAC-8613-BIS'
where tipo.ente_proprietario_id =3
and   tipo.tefa_trib_gruppo_tipo_code::integer=7
and   tipo.login_operazione='SIAC-8613'
and   tipo.login_operazione not like '%SIAC-8613-BIS'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine  is null;




select tipo.tefa_trib_gruppo_tipo_code , upd.*
from siac_t_tefa_trib_gruppo_upload upd ,siac_d_tefa_trib_gruppo_tipo  tipo 
where upd.tefa_trib_gruppo_tipo_id =tipo.tefa_trib_gruppo_tipo_id 
order by  upd.tefa_trib_file_id  desc, tipo.tefa_trib_gruppo_tipo_code::integer 

select tipo.tefa_trib_gruppo_code , upd.*
from siac_t_tefa_trib_gruppo_upload upd ,siac_d_tefa_trib_gruppo  tipo 
where upd.tefa_trib_gruppo_id =tipo.tefa_trib_gruppo_id 
order by  upd.tefa_trib_file_id  desc, tipo.tefa_trib_gruppo_code::integer 



select
tipo.tefa_trib_gruppo_tipo_code , tipo.tefa_trib_gruppo_tipo_desc ,
fnc_tefa_trib_raggruppamento( tipo.tefa_trib_gruppo_tipo_id,null ,63385)
from siac_d_tefa_trib_gruppo_tipo  tipo 
order by 1 

select distinct tefa.tefa_trib_anno_rif , tefa.tefa_trib_anno_rif_str ,tefa.tefa_trib_tributo_code
from siac_t_tefa_trib_importi tefa
where tefa.tefa_trib_file_id =63385

select distinct tefa.tefa_trib_anno_rif , tefa.tefa_trib_anno_rif_str ,tefa.tefa_trib_tributo_code, 
                gruppo.tefa_trib_gruppo_id ,gruppo.tefa_trib_gruppo_code,
                tipo.tefa_trib_gruppo_tipo_code ,tipo.tefa_trib_gruppo_tipo_code , tipo.tefa_trib_gruppo_tipo_desc 
from siac_t_tefa_trib_importi tefa ,siac_d_tefa_tributo  trib ,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_bck_tefa_trib_gruppo gruppo ,siac_bck_tefa_trib_gruppo_tipo  tipo 
where tefa.tefa_trib_file_id =63385
and   trib.tefa_trib_code=tefa.tefa_trib_tributo_code 
and   r_gruppo.tefa_trib_id =trib.tefa_trib_id 
and   r_gruppo.tefa_trib_gruppo_id =gruppo.tefa_trib_gruppo_id 
and   tipo.tefa_trib_gruppo_tipo_id =gruppo.tefa_trib_gruppo_tipo_id 
and   r_gruppo.data_cancellazione  is null 
and   r_gruppo.validita_fine  is null 

select tipo.gestione_tipo_code , tipo.gestione_tipo_desc , liv.*
from siac_d_gestione_livello  liv ,siac_d_gestione_tipo  tipo
where liv.ente_proprietario_id =3
and   tipo.gestione_tipo_id =liv.gestione_tipo_id 




select distinct tefa.tefa_trib_data_ripart , tefa.tefa_trib_data_bonifico ,
                tipo.tefa_trib_gruppo_tipo_code::integer , tipo.tefa_trib_gruppo_tipo_desc ,
                gruppo.tefa_trib_gruppo_code , gruppo.tefa_trib_gruppo_code , gruppo.tefa_trib_gruppo_anno ,
                trib.tefa_trib_code  
from siac_d_tefa_trib_gruppo_tipo  tipo ,siac_d_tefa_trib_gruppo  gruppo ,siac_r_tefa_tributo_gruppo r,
siac_d_tefa_tributo  trib,siac_t_tefa_trib_importi tefa
where tipo.ente_proprietario_id =3
and   gruppo.tefa_trib_gruppo_tipo_id =tipo.tefa_trib_gruppo_tipo_id 
and   r.tefa_trib_gruppo_id =gruppo.tefa_trib_gruppo_id 
and   r.tefa_trib_id =r.tefa_trib_id 
and   tefa.tefa_trib_tributo_code =trib.tefa_trib_code 
and   tefa.tefa_trib_anno_rif_str = gruppo.tefa_trib_gruppo_anno 
and   tefa.tefa_trib_file_id =63389
and   tefa.tefa_trib_tributo_code in ('3922','3921','3920')
and   r.data_cancellazione  is null 
and   r.validita_fine  is null 
order by tefa.tefa_trib_data_ripart , tefa.tefa_trib_data_bonifico, tipo.tefa_trib_gruppo_tipo_code ::integer,gruppo.tefa_trib_gruppo_anno



with 
raggruppa_sel as
(
select gruppo.tefa_trib_gruppo_anno, trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(7,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(null,gruppo.tefa_trib_gruppo_id)
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
where trib_imp.tefa_trib_file_id=63389
and   trib_imp.tefa_trib_tipo_record='D'
and   trib_imp.data_cancellazione is null
and   trib_imp.validita_fine is null
)
select  distinct raggruppa_sel.tefa_trib_code ,tefa_sel.tefa_trib_anno_rif_str
from raggruppa_sel, tefa_sel 
where tefa_sel.tefa_trib_tributo_code=raggruppa_sel.tefa_trib_code
and   tefa_sel.tefa_trib_anno_rif_str=raggruppa_sel.tefa_trib_gruppo_anno
order by 1 DESC