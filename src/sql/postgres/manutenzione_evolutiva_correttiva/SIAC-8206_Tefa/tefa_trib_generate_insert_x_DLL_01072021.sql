/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select tefa.tefa_trib_tipologia_code, tefa.tefa_trib_tipologia_desc,tefa.validita_inizio,tefa.login_operazione, tefa.ente_proprietario_id
from siac_d_tefa_trib_tipologia tefa ,siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   tefa.ente_proprietario_id=ente.ente_proprietario_id

select  tipo.tefa_trib_gruppo_tipo_code, tipo.tefa_trib_gruppo_tipo_desc,
        tipo.tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,
        
from siac_d_tefa_trib_gruppo_tipo tipo

select 
'insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '''||
 tipo.tefa_trib_gruppo_tipo_code
 ||''','''||
 tipo.tefa_trib_gruppo_tipo_desc
 ||''','||
 tefa_trib_gruppo_tipo_f1_id::varchar
 ||','||
 tefa_trib_gruppo_tipo_f2_id::varchar
 ||','||
 tefa_trib_gruppo_tipo_f3_id::varchar
 ||',now(),''SIAC-8206'','||
 ' ente.ente_proprietario_id
   from siac_t_ente_proprietario ente 
   where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
   and   not exists
   (
   select 1
   from siac_d_tefa_trib_gruppo_tipo tipo
   where tipo.ente_proprietario_id=ente.ente_proprietario_id
   and   tipo.tefa_trib_gruppo_tipo_code='''||tipo.tefa_trib_gruppo_tipo_code
||''' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );'
from siac_d_tefa_trib_gruppo_tipo tipo 



select tefa_trib_gruppo_code,tefa_trib_gruppo_desc, tefa_trib_gruppo_anno, gruppo.tefa_trib_tipologia_id,
       tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id, tefa_trib_gruppo_f3_id,
       gruppo.tefa_trib_gruppo_tipo_id,
       gruppo.ente_proprietario_id
      from siac_d_tefa_trib_gruppo gruppo, siac_d_tefa_trib_gruppo_tipo gr_tipo, siac_d_tefa_trib_tipologia  tipo
where gr_tipo.tefa_trib_gruppo_tipo_id=gruppo.tefa_trib_gruppo_tipo_id
and   tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
order by gruppo.tefa_trib_gruppo_id 

select 'insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) '
       ||'select '''
       ||gruppo.tefa_trib_gruppo_code||''','''
	   ||gruppo.tefa_trib_gruppo_desc||''','''
	   ||gruppo.tefa_trib_gruppo_anno||''','
	   ||tipo.tefa_trib_tipologia_id::varchar||','
	   ||gruppo.tefa_trib_gruppo_f1_id::varchar||','
	   ||gruppo.tefa_trib_gruppo_f2_id::varchar||','
	   ||gruppo.tefa_trib_gruppo_f3_id::varchar||','
	   ||gr_tipo.tefa_trib_gruppo_tipo_id::varchar||','
	   ||' ente.ente_proprietario_id,'
	   ||'now(),''SIAC-8206'' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='''||tipo.tefa_trib_tipologia_code||''' '
       ||' and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='''||gr_tipo.tefa_trib_gruppo_tipo_code||''' '
       ||' and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='''||gruppo.tefa_trib_gruppo_code||''''
        ||' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );'
from siac_d_tefa_trib_gruppo gruppo, siac_d_tefa_trib_gruppo_tipo gr_tipo, siac_d_tefa_trib_tipologia  tipo
where gr_tipo.tefa_trib_gruppo_tipo_id=gruppo.tefa_trib_gruppo_tipo_id
and   tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
order by gruppo.tefa_trib_gruppo_id




select  tefa.tefa_trib_code,tefa.tefa_trib_desc,*
from siac_d_tefa_tributo tefa


select 'insert into siac_d_tefa_tributo '
       ||' ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id ) '
       ||' select '''
       || tefa.tefa_trib_code||''','''
       ||tefa.tefa_trib_desc ||''','
       ||' now(), ''SIAC-8206'','
       ||' ente.ente_proprietario_id '
       ||' from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='''||  tefa.tefa_trib_code||''''
       ||' and tefa.data_cancellazione is null and tefa.validita_fine is null '     
       ||');'
 from   siac_d_tefa_tributo tefa  
 
 
           
 select 'insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id ) '
        ' select '''
		||replace(com.tefa_trib_comune_code,'''','''''')||''','''
		||replace(com.tefa_trib_comune_desc,'''','''''')||''','''
		||replace(com.tefa_trib_comune_cat_code,'''','''''')||''','''
		||replace(com.tefa_trib_comune_cat_desc,'''','''''')||''','
		||' now(), ''SIAC-8206'', '
		||' ente.ente_proprietario_id '
		||' from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='''||com.tefa_trib_comune_code||'''
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );'
from siac_d_tefa_trib_comune com 
 


select 'insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id ) '
       ||' select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),''SIAC-8206'',ente.ente_proprietario_id '
       ||' from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo  '
       ||' where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='''||trib.tefa_trib_code||''''
       ||' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='''||gruppo.tefa_trib_gruppo_code||''''
       ||' and   trib.data_cancellazione is null and trib.validita_fine is null '     
       ||' and   gruppo.data_cancellazione is null and gruppo.validita_fine is null '
       ||' and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );'
from siac_r_tefa_tributo_gruppo r ,siac_d_tefa_tributo trib , siac_d_tefa_trib_gruppo gruppo 
where trib.ente_proprietario_id=2
and   r.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r.tefa_trib_gruppo_id
order by r.tefa_trib_gruppo_r_id

insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  
   select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  
   from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   
   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3920' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' 
           and   trib.data_cancellazione is null 
           and trib.validita_fine is null  
           and   gruppo.data_cancellazione is null 
           and gruppo.validita_fine is null  
           and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );


