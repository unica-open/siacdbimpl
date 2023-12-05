/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_siac_provvisorio_associa_sac
(
  enteProprietarioId integer,
  nomeTabella varchar,
  fileId integer,
  codiceAssociazione varchar,
  loginOperazione varchar, 
  dataElaborazione timestamp, 
  OUT codiceRisultato integer, 
  OUT messaggioRisultato varchar
);
CREATE OR REPLACE FUNCTION siac.fnc_siac_provvisorio_associa_sac
(
  enteProprietarioId integer,
  nomeTabella varchar,
  fileId integer,
  codiceAssociazione varchar,
  loginOperazione varchar, 
  dataElaborazione timestamp, 
  OUT codiceRisultato integer, 
  OUT messaggioRisultato varchar)
 RETURNS record
 AS $body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioBck  VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
	strMessaggioLog VARCHAR(2500):='';

	codResult integer:=null;

    n_timestamp varchar:=null;
   
    elabRec record;
    elabResRec record;
    annoRec record;
    elabEsecResRec record;

    sacDefault CONSTANT  varchar :='QA3';
	sacDaAssociare varchar(10):=null;
    sql_insert varchar(5000):=null;
   
BEGIN

	codiceRisultato:=0;
    messaggioRisultato:='';
   
	strMessaggioFinale:='Provvisori di cassa - associazione SAC.';
    strMessaggioLog:='Inizio fnc_siac_provvisorio_associa_sac - '||strMessaggioFinale;
    raise notice '%',strMessaggioLog;
   
    if coalesce(nomeTabella,'')='' and fileId is null  then
    	messaggioRisultato:=upper(strMessaggioFinale||' Nome tabella o FileId non specificati.');
        strMessaggioLog:='Uscita fnc_siac_provvisorio_associa_sac - '||messaggioRisultato;
        raise notice '%',strMessaggioLog;
        codiceRisultato:=-1;
        return;
   end if;
   
   if coalesce(codiceAssociazione,'')!='' then
       strMessaggioFinale:='Provvisori di cassa - associazione SAC.';
       strMessaggio:='Lettura SAC associata per codice '||codiceAssociazione||'.';
       strMessaggioLog:='Continua fnc_siac_provvisorio_associa_sac - '||strMessaggioFinale||strMessaggio;
       raise notice '%',strMessaggioLog;
       select c.classif_code into sacDaAssociare
	   from pagopa_r_iqs2_configura_sac r ,siac_t_class c
       where r.ente_proprietario_id =enteProprietarioId 
       and     r.pagopa_iqs2_conf_sac_code=codiceAssociazione
       and     c.classif_id=r.classif_id
       and     r.data_cancellazione  is null 
       and     r.validita_fine  is null
       and     c.data_cancellazione  is null 
       and     c.validita_fine  is null;
   end if;
   raise notice 'sacDaAssociare=%',sacDaAssociare;
  
   if coalesce(sacDaAssociare,'')=''  and fileId is null then
   		sacDaAssociare:=sacDefault;
   end if;
   
  SELECT  to_char(current_timestamp, 'YYYYMMDDHH24MISSMS') into n_timestamp;
  
  loginOperazione:=loginOperazione||'_ASS_SAC_' ||n_timestamp;
  raise notice  'loginOperazione=%',loginOperazione ;

   if coalesce(nomeTabella,'')!='' then
         strMessaggio :='Verifica esistenza tabella '||nomeTabella;
         messaggioRisultato:=upper(strMessaggioFinale||strMessaggio);

   	     codResult:=null;
         select 1 into codResult
	     from pg_tables
	     where upper(tablename)=upper(nomeTabella);
	      
	     if not FOUND or codResult is null then
            strMessaggioLog:='Uscita fnc_siac_provvisorio_associa_sac - '||messaggioRisultato||' Tabella non esistente';
	     --   raise notice '%',strMessaggioLog; 
	      	raise exception ' Tabella=% non esistente',nomeTabella;
	     end if;
	    
         strMessaggio :='Aggiornamento provvisori di cassa per data invio servizio SAC='||sacDaAssociare||'. ';
         messaggioRisultato:=upper(strMessaggioFinale||strMessaggio);
         strMessaggioLog:='Uscita fnc_siac_provvisorio_associa_sac - '||messaggioRisultato;
 	     sql_insert:=
	     'update siac_t_prov_cassa p 
          set      provc_data_invio_servizio =clock_timestamp(),
                    provc_data_presa_in_carico_servizio =clock_timestamp(),
                    provc_accettato =true,
                    data_modifica=clock_timestamp(),
                    login_operazione =p.login_operazione||''-'||loginOperazione
       ||''' from  siac_d_prov_cassa_tipo  tipo, '||nomeTabella||' prov_elab'
       ||' where  tipo.ente_proprietario_id ='||enteProprietarioId::varchar
       ||' and tipo.provc_tipo_code=''E''
           and p.provc_tipo_id=tipo.provc_tipo_id 
           and p.provc_anno::integer=prov_elab.provc_anno 
           and p.provc_numero::integer=prov_elab.provc_numero 
           and not exists 
           (
              select 1
              from siac_r_prov_cassa_class rc,siac_t_class c,siac_d_class_tipo tipo_c
              where rc.provc_id=p.provc_id 
              and     c.classif_id=rc.classif_id 
              and     tipo_c.classif_tipo_id=c.classif_tipo_id 
              and     tipo_c.classif_tipo_code in (''CDC'',''CDR'')
              and     rc.data_cancellazione  is null 
              and     rc.validita_fine  is null 
          )
         and p.data_cancellazione is null 
         and p.validita_fine is null;';             

              
         raise notice 'sql_insert=%', sql_insert;         
         execute sql_insert;
        
         strMessaggio :='Verifica aggiornamento provvisori di cassa per data invio servizio SAC='||sacDaAssociare||'. ';
         messaggioRisultato:=upper(strMessaggioFinale||strMessaggio);
         strMessaggioLog:='Uscita fnc_siac_provvisorio_associa_sac - '||messaggioRisultato;
        
 		 codResult:=null;
 		 select count(*) into codResult
 		 from siac_t_prov_cassa p,siac_d_prov_cassa_tipo tipo
 		 where tipo.ente_proprietario_id =enteProprietarioId 
   	     and     tipo.provc_tipo_code ='E'
 	     and     p.provc_tipo_id=tipo.provc_tipo_id
         and not exists 
         (
              select 1
              from siac_r_prov_cassa_class rc,siac_t_class c,siac_d_class_tipo tipo_c
              where rc.provc_id=p.provc_id 
              and     c.classif_id=rc.classif_id 
              and     tipo_c.classif_tipo_id=c.classif_tipo_id 
              and     tipo_c.classif_tipo_code in ('CDC','CDR')
              and     rc.data_cancellazione  is null 
              and     rc.validita_fine  is null 
         )
         and p.login_operazione like '%'||loginOperazione
         and p.data_cancellazione is null 
         and p.validita_fine is null; 	
         raise notice '% Provvisori aggiornati %', messaggioRisultato,codResult::varchar;
         
        
         strMessaggio :='Aggiornamento provvisori di cassa per inserimento SAC='||sacDaAssociare||'.';
         messaggioRisultato:=upper(strMessaggioFinale||strMessaggio);
         strMessaggioLog:='Uscita fnc_siac_provvisorio_associa_sac - '||messaggioRisultato;
        
        if coalesce(sacDaAssociare,'')!='' then 
         sql_insert:=
        'insert into siac_r_prov_cassa_class
         (
           provc_id,
           classif_id,
           validita_inizio,
           login_operazione ,
           ente_proprietario_id
         )
        select p.provc_id,
                  cNew.classif_id,
                  clock_timestamp(),
                  '''||loginOperazione||''' ,
                  cNew.ente_proprietario_id
        from '||nomeTabella|| ' prov_elab ,siac_t_prov_cassa p,siac_d_prov_cassa_tipo  tipo ,siac_d_class_tipo tipo_c,
                   siac_t_class cNew
        where tipo.ente_proprietario_id ='||enteProprietarioId::varchar||' 
         and    tipo.provc_tipo_code=''E''
         and     p.provc_tipo_id=tipo.provc_tipo_id
         and     p.provc_anno::integer=prov_elab.provc_anno
         and     p.provc_numero::integer=prov_elab.provc_numero
         and     tipo_c.ente_proprietario_id =tipo.ente_proprietario_id
         and     tipo_c.classif_tipo_code in (''CDC'',''CDR'')
         and     cNew.classif_tipo_id =tipo_c.classif_tipo_id
         and     cNew.classif_code ='''||sacDaAssociare||'''
         and     not exists
         (
          select 1
          from siac_r_prov_cassa_class rc,siac_t_class c
          where rc.provc_id=p.provc_id 
          and     c.classif_id=rc.classif_id 
          and     tipo_c.classif_tipo_id=c.classif_tipo_id
          and     rc.data_cancellazione  is null 
          and     rc.validita_fine  is null 
        )
        and p.login_operazione like ''%'||loginOperazione||
        ''' and p.data_cancellazione is null
        and p.validita_fine is null;';
     else 
        sql_insert:=
        'insert into siac_r_prov_cassa_class
         (
           provc_id,
           classif_id,
           validita_inizio,
           login_operazione ,
           ente_proprietario_id
         )
        select p.provc_id,
                  cNew.classif_id,
                  clock_timestamp(),
                  '''||loginOperazione||''' ,
                  cNew.ente_proprietario_id
        from '||nomeTabella|| ' prov_elab ,siac_t_prov_cassa p,siac_d_prov_cassa_tipo  tipo ,
                   siac_t_class cNew, pagopa_r_iqs2_configura_sac r
        where tipo.ente_proprietario_id ='||enteProprietarioId::varchar||' 
         and    tipo.provc_tipo_code=''E''
         and     p.provc_tipo_id=tipo.provc_tipo_id
         and     p.provc_anno::integer=prov_elab.provc_anno
         and     p.provc_numero::integer=prov_elab.provc_numero
         and     r.ente_proprietario_id=p.ente_proprietario_id
         and     r.pagopa_iqs2_conf_sac_code= prov_elab.associa_sac_code 
         and     cNew.classif_id=r.classif_id
         and     not exists
         (
          select 1
          from siac_r_prov_cassa_class rc,siac_t_class c
          where rc.provc_id=p.provc_id 
          and     c.classif_id=rc.classif_id 
          and     cNew.classif_tipo_id=c.classif_tipo_id
          and     rc.data_cancellazione  is null 
          and     rc.validita_fine  is null 
        )
        and p.login_operazione like ''%'||loginOperazione||
        ''' and p.data_cancellazione is null
        and p.validita_fine is null
        and r.data_cancellazione is null 
        and r.validita_fine is null
        and cNew.data_cancellazione is null 
        and cNew.validita_fine is null;';
     end if;
    
     raise notice 'sql_insert=%', sql_insert;         
     execute sql_insert;
        
       strMessaggio :='Verifica aggiornamento provvisori di cassa per associazione SAC='||coalesce(sacDaAssociare,'')||'. ';
       messaggioRisultato:=upper(strMessaggioFinale||strMessaggio);
       strMessaggioLog:='Uscita fnc_siac_provvisorio_associa_sac - '||messaggioRisultato;
        
   	   codResult:=null;
 	   select count(*) into codResult
 	   from siac_t_prov_cassa p,siac_d_prov_cassa_tipo tipo,siac_r_prov_cassa_class rc,siac_t_class c,siac_d_class_tipo tipo_c
 	   where tipo.ente_proprietario_id =enteProprietarioId 
 	   and     tipo.provc_tipo_code ='E'
 	   and     p.provc_tipo_id=tipo.provc_tipo_id 
 	   and     rc.provc_id=p.provc_id 
       and     c.classif_id=rc.classif_id 
       and     tipo_c.classif_tipo_id=c.classif_tipo_id 
       and     tipo_c.classif_tipo_code in ('CDC','CDR')
       and     rc.data_cancellazione  is null 
       and     rc.validita_fine  is null
       and     rc.login_operazione =loginOperazione
       and p.data_cancellazione is null 
       and p.validita_fine is null; 	
       raise notice '% Provvisori aggiornati %', messaggioRisultato,codResult::varchar;
        
   end if;
  
  	  
   if codiceRisultato=0 then
      	messaggioRisultato:=upper(strMessaggioLog||' Provvisori aggiornati '||coalesce(codResult::varchar,'0')||' TERMINE OK.');
   else
    	messaggioRisultato:=upper(strMessaggioLog||' Provvisori aggiornati '||coalesce(codResult::varchar,'0')||' TERMINE KO.');
   end if;
   raise notice '%',messaggioRisultato;

   
   return;
exception
    when RAISE_EXCEPTION then
        raise notice '%',strMessaggioLog;
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND then
        raise notice '%',strMessaggioLog;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
     when TOO_MANY_ROWS then
        raise notice '%',strMessaggioLog;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
	when others  then
        raise notice '%',strMessaggioLog;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function
siac.fnc_siac_provvisorio_associa_sac
(
  integer,
  varchar,
  integer,
  varchar,
  varchar, 
  timestamp, 
  OUT  integer, 
  OUT  varchar)
 OWNER to siac;