/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- la vista estrae impegni riaccertati e non (residui e pluriennali da anni passati) che abbiano un vincolo originario 
-- quindi impegni che derivano da impegni derivanti da anni passati ( o corrente se riaccDaReanno) il cui impegno di origine
-- nel suo anno primo anno di esistenza in bilancio aveva un vincolo appunto di origine

drop MATERIALIZED VIEW  if exists siac.siac_v_dwh_vincoli_originari;
CREATE MATERIALIZED VIEW siac.siac_v_dwh_vincoli_originari 
(
ente_proprietario_id,
anno_bilancio,
anno_impegno,
numero_impegno,
flag_riacc,
anno_bilancio_orig,
anno_impegno_orig,
numero_impegno_orig,
tipo_vincolo,
anno_bilancio_acc,
anno_acc,
numero_acc,
somme_importi_riacc
)
TABLESPACE pg_default
as 
with  
query_totale as  
(
select query_noriacc.*
from 
(
select query.ente_proprietario_id ,query.anno_bilancio, query.movgest_anno anno_impegno, query.movgest_numero numero_impegno, 'N'::varchar flag_riacc, 
           query.anno_bilancio_prec anno_bilancio_orig, query.movgest_anno anno_impegno_orig, query.movgest_numero numero_impegno_orig,
          (case when  tipo.avav_tipo_code is not null then tipo.avav_tipo_code else 'ACC' end )::varchar tipo_vincolo, 
          perAcc.anno::integer anno_bilancio_acc , movAcc.movgest_anno::integer anno_acc, movAcc.movgest_numero::integer numero_acc,
          r.movgest_ts_r_id , r.movgest_ts_b_id 
from 
(
with 
impegno as 
(
  	      select tipo.ente_proprietario_id ,per.anno::integer anno_bilancio , mov.movgest_anno::integer movgest_anno, mov.movgest_numero::integer movgest_numero, ts.movgest_ts_id 
		  from  siac_d_movgest_tipo tipo,siac_t_movgest_ts ts,siac_t_movgest mov,siac_t_bil bil,siac_t_periodo per ,
		               siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
		  where tipo.movgest_tipo_code ='I'
		  and      mov.movgest_tipo_id=tipo.movgest_tipo_id
		  and      bil.bil_id=mov.bil_id
		  and      per.periodo_id=bil.periodo_id
          and      ts.movgest_id=mov.movgest_id
          and      rs.movgest_ts_id=ts.movgest_ts_id
          and      stato.movgest_stato_id=rs.movgest_Stato_id 
          and      stato.movgest_Stato_code!='A'
	     and        not exists 
	     (
	     select 1
	     from siac_r_movgest_ts_attr rattr,siac_t_attr attr
	     where rattr.movgest_ts_id =ts.movgest_ts_id 
	     and     attr.attr_id=rattr.attr_id 
	     and     attr.attr_code in ('flagDaRiaccertamento','flagDaReanno') 
	     and     rattr."boolean" ='S'
	     and     rattr.validita_fine is null 
	     and     rattr.validita_fine is null
	     )
         and       mov.data_cancellazione  is null 
         and       mov.validita_fine  is null 
         and       ts.data_cancellazione  is null 
         and       ts.validita_fine  is null 
         and       rs.data_cancellazione  is null 
         and       rs.validita_fine  is null 
),
impegno_prec as 
(
  	      select tipo.ente_proprietario_id ,per.anno::integer anno_bilancio , mov.movgest_anno::integer movgest_anno , mov.movgest_numero::integer movgest_numero, ts.movgest_ts_id 
		  from  siac_d_movgest_tipo tipo,siac_t_movgest_ts ts,siac_t_movgest mov,siac_t_bil bil,siac_t_periodo per,
		               siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
		  where  tipo.movgest_tipo_code ='I'
		  and      mov.movgest_tipo_id=tipo.movgest_tipo_id
		  and      bil.bil_id=mov.bil_id
		  and      per.periodo_id=bil.periodo_id
          and      ts.movgest_id=mov.movgest_id
          and      rs.movgest_ts_id=ts.movgest_ts_id
          and      stato.movgest_stato_id=rs.movgest_Stato_id 
          and      stato.movgest_Stato_code!='A'
          and      mov.data_cancellazione  is null 
          and      mov.validita_fine  is null 
          and      ts.data_cancellazione  is null 
          and      ts.validita_fine  is null 
          and      rs.data_cancellazione  is null 
          and      rs.validita_fine  is null 
)
select impegno.*, impegno_prec.anno_bilancio anno_bilancio_prec, coalesce(impegno_prec.movgest_ts_id,-1) movgest_ts_id_prec
from impegno 
            left join impegno_prec on 
            (  impegno_prec.ente_proprietario_id =impegno.ente_proprietario_id     
           and impegno_prec.movgest_anno=impegno.movgest_anno
           and impegno_prec.movgest_numero=impegno.movgest_numero
           and impegno_prec.anno_bilancio<impegno.anno_bilancio
           )
) query 
 left join siac_r_movgest_ts r 
       left join siac_t_avanzovincolo  av join siac_d_avanzovincolo_tipo  tipo on ( tipo.avav_tipo_id=av.avav_tipo_id)
            on ( r.avav_id=av.avav_id )
       left join siac_t_movgest_ts acc join  siac_t_movgest movAcc 
                               join  siac_t_bil bilAcc join siac_t_periodo perAcc on (perAcc.periodo_id=bilAcc.periodo_id) 
                        on ( bilAcc.bil_id=movAcc.bil_id)
                    on ( movAcc.movgest_id=acc.movgest_id)
                 on ( acc.movgest_ts_id=r.movgest_ts_a_id)
 on ( query.movgest_ts_id_prec=r.movgest_ts_b_id and r.data_cancellazione is null  and   r.validita_fine is null )
where query.movgest_ts_id_prec<>-1 
and     r.movgest_ts_r_id  is not null 
and  not exists
           (
             select 1 
             from siac_d_movgest_tipo tipo,siac_t_movgest_ts ts, siac_t_movgest mov ,siac_t_bil bil,siac_t_periodo per,
                         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato 
             where  tipo.ente_proprietario_id =query.ente_proprietario_id 
             and       tipo.movgest_tipo_code ='I'
             and       mov.movgest_tipo_id=tipo.movgest_tipo_id 
             and       bil.bil_id=mov.bil_id 
             and       per.periodo_id=bil.periodo_id
             and       per.anno::integer <query.anno_bilancio_prec
             and       mov.movgest_anno::integer=query.movgest_anno::integer 
             and       mov.movgest_numero::integer=query.movgest_Numero::integer
             and       ts.movgest_Id=mov.movgest_id
             and       rs.movgest_ts_id=ts.movgest_ts_id
             and       stato.movgest_stato_id=rs.movgest_Stato_id 
             and       stato.movgest_Stato_code!='A'
             and       mov.data_cancellazione  is null 
             and       mov.validita_fine  is null 
             and       ts.data_cancellazione  is null 
             and       ts.validita_fine  is null 
             and       rs.data_cancellazione  is null 
             and       rs.validita_fine  is null 
           )
) query_noriacc           
union 
select query_riacc.*
from 
(
select distinct 
           perRiacc.ente_proprietario_id , perRiacc.anno::integer anno_bilancio , movRiacc.movgest_anno::integer anno_impegno, movRiacc.movgest_numero::integer numero_impegno, 
           'S'::varchar flag_riacc, per.anno::integer  anno_bilancio_orig,  mov.movgest_anno::integer anno_impegno_orig, mov.movgest_numero::integer numero_impegno_orig,
           ( case when tipo_av.avav_tipo_code is not null then tipo_av.avav_tipo_code else 'ACC' end )::varchar tipo_vincolo,
           perAcc.anno::integer anno_bilancio_acc , movAcc.movgest_anno::integer anno_acc, movAcc.movgest_numero::integer numero_acc,
           rvinc.movgest_ts_r_id , rvinc.movgest_ts_b_id 
from 
(
with recursive 
rqname (ente_proprietario_id,annoBilancioRiacc, anno_bilancio, movgest_anno, movgest_numero,movgest_ts_id,arrhierarchy,arrhierarchy_id,
               flagRiacc,annoRiacc, numeroRiacc, movgest_ts_id_riacc,livello_impegno) as 
(
	select query1.ente_proprietario_id,query1.annoBilancioRiacc, query1.anno_bilancio, query1.movgest_anno, query1.movgest_numero,query1.movgest_ts_id,query1.arrhierarchy,query1.arrhierarchy_id,query1.flagRiacc,
	           query1.annoRiacc, query1.numeroRiacc, query1.movgest_ts_id_riacc,
	           query1.livello_impegno
	from  
	(
	 select query.ente_proprietario_id,query.annoBilancioRiacc, query.anno_bilancio, query.movgest_anno, query.movgest_numero,query.movgest_ts_id,query.arrhierarchy,query.arrhierarchy_id,
	            query.flagRiacc,query.annoRiacc, query.numeroRiacc, 
	            query.movgest_ts_id_riacc,
	            query.livello_impegno 
	 from 
	 (
	  with 
	  impegno as 
	  (
	  with 
	  impegno as 
	  (
  	      select tipo.ente_proprietario_id ,per.anno::integer anno_bilancio , mov.movgest_anno::integer  movgest_anno, mov.movgest_numero::integer movgest_numero, ts.movgest_ts_id 
		  from  siac_d_movgest_tipo tipo,siac_t_movgest_ts ts,siac_t_movgest mov,siac_t_bil bil,siac_t_periodo per ,
		                siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
		  where tipo.movgest_tipo_code ='I'
		  and      mov.movgest_tipo_id=tipo.movgest_tipo_id
		  and      bil.bil_id=mov.bil_id
		  and      per.periodo_id=bil.periodo_id
          and      ts.movgest_id=mov.movgest_id
          and      rs.movgest_ts_id=ts.movgest_ts_id 
          and      stato.movgest_stato_id=rs.movgest_stato_id 
          and      stato.movgest_stato_code !='A'
          and      mov.data_cancellazione  is null 
          and      mov.validita_fine  is null 
          and      ts.data_cancellazione  is null 
          and      ts.validita_fine  is null 
          and      rs.data_cancellazione  is null 
          and      rs.validita_fine  is null 
	  ) ,
	  flagRiaccReanno as 
	  (
		  select rattr.movgest_ts_id, rattr.boolean flagRiacc
		  from siac_r_movgest_ts_attr rattr,siac_t_attr attr
		  where attr.attr_code='flagDaReanno'
 		  and      rattr.attr_id=attr.attr_id 
 		  and      rattr.data_cancellazione  is null 
 		  and      rattr.validita_fine  is null
	  ),
  	  flagRiacc as 
	  (
		  select rattr.movgest_ts_id, rattr.boolean flagRiacc
		  from siac_r_movgest_ts_attr rattr,siac_t_attr attr
		  where attr.attr_code= 'flagDaRiaccertamento'
 		  and      rattr.attr_id=attr.attr_id 
 		  and      rattr.data_cancellazione  is null 
 		  and      rattr.validita_fine  is null
	  ),
	  annoRiacc as 
	  (
		  select rattr.movgest_ts_id, rattr.testo annoRiacc
		  from  siac_r_movgest_ts_attr rattr,siac_t_attr attr
		  where attr.attr_code ='annoRiaccertato'
 		  and      rattr.attr_id=attr.attr_id 
 		  and      rattr.data_cancellazione  is null 
 		  and      rattr.validita_fine  is null
	  ),
 	  numeroRiacc as 
	  (
		  select rattr.movgest_ts_id, rattr.testo numeroRiacc
		  from siac_r_movgest_ts_attr rattr,siac_t_attr attr
		  where attr.attr_code ='numeroRiaccertato'
 		  and      rattr.attr_id=attr.attr_id 
 		  and      rattr.data_cancellazione  is null 
 		  and      rattr.validita_fine  is null
	  )
	  select  distinct 
	                  impegno.ente_proprietario_id ,
	                  impegno.anno_bilancio , impegno.movgest_anno, impegno.movgest_numero, impegno.movgest_ts_id ,
                      ARRAY[((case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccReanno.flagRiacc,'N') else flagRiacc.flagRiacc end)::varchar ||'|'||
                                          ( case when (case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccReanno.flagRiacc,'N') else flagRiacc.flagRiacc end)::varchar='S'  
                                              then annoRiacc.annoRiacc else impegno.movgest_anno::varchar end)::varchar||'|'||
                                         ( case when (case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccReanno.flagRiacc,'N') else flagRiacc.flagRiacc end)::varchar='S' 
                                             then numeroRiacc.numeroRiacc else impegno.movgest_numero::varchar end)::varchar)::varchar] AS arrhierarchy,           
                      ARRAY[impegno.movgest_ts_id] AS arrhierarchy_id,                
                      (case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccReanno.flagRiacc,'N') else flagRiacc.flagRiacc end)::varchar  flagRiacc, 
 					  ( case when (case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccReanno.flagRiacc,'N') else flagRiacc.flagRiacc end)::varchar='S'  
                                              then annoRiacc.annoRiacc else impegno.movgest_anno::varchar end)::varchar  as annoRiacc,
 				       ( case when (case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccReanno.flagRiacc,'N') else flagRiacc.flagRiacc end)::varchar='S' 
                                             then numeroRiacc.numeroRiacc else impegno.movgest_numero::varchar end)::varchar as numeroRiacc,
                       1::integer as livello_impegno
	  from   impegno
	                  left join flagRiacc on ( impegno.movgest_ts_id=flagRiacc.movgest_ts_id)
	                  left join flagRiaccReanno on ( impegno.movgest_ts_id=flagRiaccReanno.movgest_ts_id)
	                  left join annoRiacc on (impegno.movgest_ts_id=annoRiacc.movgest_ts_id)
	                  left join numeroRiacc on (impegno.movgest_ts_id=numeroRiacc.movgest_ts_id)
      ),
      impRiacc as 
      (
        select tipo.ente_proprietario_id ,per.anno::integer anno_bilancio , mov.movgest_anno::integer movgest_anno, mov.movgest_numero::integer movgest_numero, ts.movgest_ts_id 
		  from  siac_d_movgest_tipo tipo,siac_t_movgest_ts ts,siac_t_movgest mov,siac_t_bil bil,siac_t_periodo per  
		  where tipo.movgest_tipo_code ='I'
		  and      mov.movgest_tipo_id=tipo.movgest_tipo_id
		  and      bil.bil_id=mov.bil_id
		  and      per.periodo_id=bil.periodo_id
          and      ts.movgest_id=mov.movgest_id
          and      mov.data_cancellazione  is null 
          and      mov.validita_fine  is null 
          and      ts.data_cancellazione  is null 
          and      ts.validita_fine  is null 
      )
      select  impegno.ente_proprietario_id,impRiacc.anno_bilancio annoBilancioRiacc, impegno.anno_bilancio, impegno.movgest_anno, impegno.movgest_numero,impegno.movgest_ts_id,
                   impegno.arrhierarchy,impegno.arrhierarchy_id,
	               impegno.flagRiacc,impegno.annoRiacc, impegno.numeroRiacc, 
	               (case when coalesce(impRiacc.movgest_ts_id::varchar,'')='' then '-1' else impRiacc.movgest_ts_id::varchar end)::integer movgest_ts_id_riacc,
	               impegno.livello_impegno 
      from impegno 
           left join  impRiacc on          
	      ( impRiacc.ente_proprietario_id=impegno.ente_proprietario_id
	        and          impRiacc.movgest_anno::integer=(( case when coalesce(impegno.flagRiacc,'N')='S' then impegno.annoRiacc else '-1'::varchar end)::varchar)::integer 
	        and          impRiacc.movgest_numero::integer=(( case when coalesce(impegno.flagRiacc,'N')='S' then impegno.numeroRiacc  else '-1'::varchar end)::varchar)::integer
		    and          impRiacc.anno_bilancio<=impegno.anno_bilancio 
		    and          impRiacc.movgest_ts_id<>impegno.movgest_ts_id
		  )
      ) query 
--      order by 1, 2 desc ,3 desc
	) query1	
	where query1.flagRiacc='S'
	union all 
		 select   distinct 
		             query1.ente_proprietario_id,query1.annoBilancioRiacc,query1.anno_bilancio, query1.movgest_anno, query1.movgest_numero,query1.movgest_ts_id,
		             RQ.arrhierarchy||(query1.flagRiacc||'|'||query1.annoRiacc||'|'||query1.numeroRiacc)::varchar as arrhierarchy ,
                     RQ.arrhierarchy_id||query1.movgest_ts_id as arrhierarchy_id,
		             query1.flagRiacc,query1.annoRiacc, query1.numeroRiacc, 
		             query1.movgest_ts_id_riacc,
		             RQ.livello_impegno::integer+1 as livello_impegno  
		 from 
		 (
		 select     query.ente_proprietario_id, query.annoBilancioRiacc,query.anno_bilancio, query.movgest_anno, query.movgest_numero,query.movgest_ts_id,
		                query.flagRiacc,query.annoRiacc, query.numeroRiacc, 
 		                query.movgest_ts_id_riacc
		 from 
		 (
		 with 
		 impegno as  
		 (
		 with 
		 impegno as   
		 (
		  select tipo.ente_proprietario_id, per.anno::integer anno_bilancio , mov.movgest_anno::integer movgest_anno , mov.movgest_numero::integer movgest_numero, ts.movgest_ts_id 
		  from  siac_d_movgest_tipo tipo,siac_t_movgest_ts ts,siac_t_movgest mov,siac_t_bil bil,siac_t_periodo per ,
		               siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
		  where tipo.movgest_tipo_code ='I'
		  and      mov.movgest_tipo_id=tipo.movgest_tipo_id
		  and      bil.bil_id=mov.bil_id
		  and      per.periodo_id=bil.periodo_id
          and      ts.movgest_id=mov.movgest_id
          and      rs.movgest_ts_id=ts.movgest_ts_id 
          and      stato.movgest_stato_id=rs.movgest_stato_id 
          and      stato.movgest_stato_code !='A'
          and      mov.data_cancellazione  is null 
          and      mov.validita_fine  is null 
          and      ts.data_cancellazione  is null 
          and      ts.validita_fine  is null 
          and      rs.data_cancellazione  is null 
          and      rs.validita_fine  is null 
		 ),
		 flagRiacc as 
		 (
		  select rattr.movgest_ts_id, rattr.boolean flagRiacc
		  from siac_r_movgest_ts_attr rattr,siac_t_attr attr
		  where attr.attr_code ='flagDaRiaccertamento'
 		  and     rattr.attr_id=attr.attr_id 
 		  and     rattr.data_cancellazione  is null 
 		  and     rattr.validita_fine  is null
		 ),
		 flagRiaccreanno as 
		 (
		  select rattr.movgest_ts_id, rattr.boolean flagRiacc
		  from siac_r_movgest_ts_attr rattr,siac_t_attr attr
		  where attr.attr_code ='flagDaReanno'
 		  and      rattr.attr_id=attr.attr_id 
 		  and      rattr.data_cancellazione  is null 
 		  and      rattr.validita_fine  is null
		 ),
		 annoRiacc as 
		 (
		  select rattr.movgest_ts_id, rattr.testo annoRiacc
		  from  siac_r_movgest_ts_attr rattr,siac_t_attr attr
		  where  attr.attr_code ='annoRiaccertato'
 		  and       rattr.attr_id=attr.attr_id 
 		  and       rattr.data_cancellazione  is null 
 		  and       rattr.validita_fine  is null
		 ),
 		 numeroRiacc as 
		 (
		  select rattr.movgest_ts_id, rattr.testo numeroRiacc
		  from siac_r_movgest_ts_attr rattr,siac_t_attr attr
		  where attr.attr_code ='numeroRiaccertato'
 		  and      rattr.attr_id=attr.attr_id 
 		  and      rattr.data_cancellazione  is null 
 		  and      rattr.validita_fine  is null
		 )
         select distinct 
                         impegno.ente_proprietario_id, impegno.anno_bilancio, impegno.movgest_anno, impegno.movgest_numero, impegno.movgest_ts_id,
        				( case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccreanno.flagRiacc,'N') else flagRiacc.flagRiacc end )::varchar flagRiacc,
                        (case when ( case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccreanno.flagRiacc,'N') else flagRiacc.flagRiacc end )::varchar='S' 
                                 then annoRiacc.annoRiacc else impegno.movgest_anno::varchar end )::varchar annoRiacc ,
                          (case when ( case when coalesce(flagRiacc.flagRiacc,'N')='N' then coalesce(flagRiaccreanno.flagRiacc,'N') else flagRiacc.flagRiacc end )::varchar='S' 
                          then numeroRiacc.numeroRiacc else impegno.movgest_numero::varchar end )::varchar numeroRiacc
         from impegno
                       left join flagRiacc on (impegno.movgest_ts_id=flagRiacc.movgest_ts_id)
                       left join flagRiaccReanno on (impegno.movgest_ts_id=flagRiaccReanno.movgest_ts_id)
                       left join annoRiacc on (impegno.movgest_ts_id=annoRiacc.movgest_ts_id)
                       left join numeroRiacc on (impegno.movgest_ts_id=numeroRiacc.movgest_ts_id)
         ) ,
         impRiacc as 
	     (
  	       select tipo.ente_proprietario_id , per.anno::integer anno_bilancio , mov.movgest_anno::integer movgest_anno, mov.movgest_numero::integer movgest_numero, ts.movgest_ts_id 
		   from  siac_d_movgest_tipo tipo,siac_t_movgest_ts ts,siac_t_movgest mov,siac_t_bil bil,siac_t_periodo per 
		   where   tipo.movgest_tipo_code ='I'
		   and       mov.movgest_tipo_id=tipo.movgest_tipo_id
		   and       bil.bil_id=mov.bil_id
		   and       per.periodo_id=bil.periodo_id
           and       ts.movgest_id=mov.movgest_id
           and       mov.data_cancellazione  is null 
           and       mov.validita_fine  is null 
           and       ts.data_cancellazione  is null 
           and       ts.validita_fine  is null 
	    ) 
	    select   impegno.ente_proprietario_id, impRiacc.anno_bilancio annoBilancioRiacc,impegno.anno_bilancio, impegno.movgest_anno, impegno.movgest_numero,impegno.movgest_ts_id,
		              impegno.flagRiacc,impegno.annoRiacc, impegno.numeroRiacc, 
 		             (case when coalesce(impRiacc.movgest_ts_id::varchar,'')='' then '-1' else impRiacc.movgest_ts_id::varchar end)::integer movgest_ts_id_riacc
	    from impegno left join impRiacc on
	    (  impRiacc.ente_proprietario_id =impegno.ente_proprietario_id 
	        and          impRiacc.movgest_anno::integer=(( case when coalesce(impegno.flagRiacc,'N')='S' then impegno.annoRiacc else '-1'::varchar end )::varchar)::integer  
	        and          impRiacc.movgest_numero::integer=(( case when coalesce(impegno.flagRiacc,'N')='S' then impegno.numeroRiacc else '-1'::varchar end )::varchar)::integer
		    and          impRiacc.anno_bilancio<=impegno.anno_bilancio 
		    and    impRiacc.movgest_ts_id<>impegno.movgest_ts_id
		 )
	  ) query
--      order by 1,10,6
 	) query1,siac_t_movgest_ts ts, rqname RQ
	where RQ.movgest_ts_id_riacc<>-1  -- escludo il  primo della catena, ovvero impegno originario non ancora oggetto di riaccertamento per fermare la ricorsione
	   and ts.movgest_ts_id=RQ.movgest_ts_id_riacc -- impegno precedente in catena riacc 
	   and   query1.movgest_ts_id=ts.movgest_ts_id
	   and  query1.movgest_ts_id!=query1.movgest_ts_id_riacc
)		
select rqname.ente_proprietario_id,rqname.annoBilancioRiacc, rqname.anno_bilancio, rqname.movgest_anno, rqname.movgest_numero,rqname.movgest_ts_id,rqname.movgest_ts_id_riacc,
           rqname.arrhierarchy,rqname.arrhierarchy_id,
            rqname.flagRiacc,rqname.annoRiacc, rqname.numeroRiacc, 
            rqname.livello_impegno 
from  rqname 
where rqname.movgest_ts_id_riacc=-1 -- filtrando per -1 prendo l'ultimo in catena che non ha altri riacc precedenti 
order by rqname.ente_proprietario_id, rqname.movgest_ts_id,rqname.movgest_ts_id_riacc
) 
--- sulla query finale ricavo il primo impegno del 2023 da cui partire che deve essere un riaccertato e ricavo 
--  mentre sull impegno originario  ricavo annoBilancio e verifico di prendere proprio quello che non ha precedenti posizioni in bilancio
--  per escludere doppioni dovuti al fatto di non poter impostare il limit 1 sulla query di partenza 
--  di questo impegno ricavo il vincolo 
query_RQ,siac_t_movgest mov,siac_t_bil bil,siac_t_periodo per,
siac_t_movgest movRiacc, siac_t_bil bilRiacc,siac_t_periodo perRiacc ,
siac_t_movgest_ts impRiacc,
  siac_t_movgest_ts ts 
     left join siac_r_movgest_ts rvinc 
 --        left join siac_v_bko_accertamento_valido acc  on (acc.movgest_ts_id=rvinc.movgest_ts_a_id )
         left join siac_t_movgest_ts acc 
                   join  siac_t_movgest movAcc 
                             join  siac_t_bil bilAcc join siac_t_periodo perAcc on (perAcc.periodo_id=bilAcc.periodo_id) 
                            on ( bilAcc.bil_id=movAcc.bil_id)
                    on ( movAcc.movgest_id=acc.movgest_id)
            on ( acc.movgest_ts_id=rvinc.movgest_ts_a_id)
         left join siac_t_avanzovincolo  av join siac_d_avanzovincolo_tipo tipo_av on (tipo_av.avav_tipo_id=av.avav_tipo_id )
          on (av.avav_id=rvinc.avav_id)
      on (rvinc.movgest_ts_b_id=ts.movgest_ts_id and rvinc.data_cancellazione  is null and rvinc.validita_fine  is null )
where ts.movgest_ts_id=query_RQ.movgest_ts_id -- impegno originario
and      mov.movgest_id=ts.movgest_id 
and      bil.bil_id=mov.bil_id 
and      per.periodo_id=bil.periodo_id
and     impRiacc.movgest_ts_id=query_RQ.arrhierarchy_id[1] -- impegno di partenza sul 2023 che deve essere un riaccertato 
and     movRiacc.movgest_id=impRiacc.movgest_id 
and     bilRiacc.bil_id=movRiacc.bil_id 
and     perRiacc.periodo_id=bilRiacc.periodo_id
--and     annoRiacc.anno_bilancio=2023 
and    not exists 
(
select 1 from siac_t_movgest mov_prec,siac_t_bil bilPrec,siac_t_periodo perPrec
where mov_prec.ente_proprietario_id =mov.ente_proprietario_id 
and     mov_prec.movgest_tipo_id=mov.movgest_tipo_id 
and     mov_prec.movgest_anno=mov.movgest_anno
and     mov_prec.movgest_numero=mov.movgest_numero 
and     bilPrec.bil_id=mov_prec.bil_id 
and     perPrec.periodo_id=bilPrec.periodo_id
and     perPrec.anno::integer<per.anno::integer
and     mov_prec.data_cancellazione  is null 
and     mov_prec.validita_fine is null 
)
and    rvinc.movgest_ts_r_id is not null 
) query_riacc
), 
vincoli_totali   as 
( 
select r.movgest_ts_b_id , r.movgest_ts_r_id , abs(coalesce(sum(rvinc.importo_delta),0)) somme_importi_riacc
from siac_r_movgest_ts r , siac_r_modifica_vincolo rvinc, 
	      siac_t_modifica modif,siac_d_modifica_tipo tipo,siac_r_modifica_stato rs,siac_d_modifica_stato stato,
	      siac_t_movgest_ts_det_mod dmod
where tipo.mod_tipo_code in ('REIMP','REANNO')
and     modif.mod_tipo_id=tipo.mod_tipo_id 
and     rs.mod_id=modif.mod_id 
and     stato.mod_stato_id=rs.mod_stato_id 
and     stato.mod_stato_code !='A'
and     dmod.mod_stato_r_id =rs.mod_stato_r_id 
and     dmod.mtdm_reimputazione_flag =true 
and     dmod.mtdm_reimputazione_anno  is not null 
and     rvinc.mod_id=modif.mod_id     
and     rvinc.modvinc_tipo_operazione='INSERIMENTO'
and     r.movgest_ts_r_id = rvinc.movgest_ts_r_id
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null 
and     modif.data_cancellazione  is null 
and     modif.validita_fine  is null 
and     dmod.data_cancellazione  is null 
and     dmod.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     rvinc.data_cancellazione  is null 
group by r.movgest_ts_b_id , r.movgest_ts_r_id 
)
select query_totale.ente_proprietario_id,
			query_totale.anno_bilancio,
            query_totale.anno_impegno,
            query_totale.numero_impegno,
	        query_totale.flag_riacc,
			query_totale.anno_bilancio_orig,
			query_totale.anno_impegno_orig,
			query_totale.numero_impegno_orig,
			query_totale.tipo_vincolo,
			query_totale.anno_bilancio_acc,
			query_totale.anno_acc,
			query_totale.numero_acc,
			coalesce(vincoli_totali.somme_importi_riacc ,0) somme_importi_riacc
from query_totale 
           left join vincoli_totali on (vincoli_totali.movgest_ts_b_id=query_totale.movgest_ts_b_id and  vincoli_totali.movgest_ts_r_id=query_totale.movgest_ts_r_id)
WITH DATA;


alter MATERIALIZED VIEW  siac.siac_v_dwh_vincoli_originari OWNER to siac;