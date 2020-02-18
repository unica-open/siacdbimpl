/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_annulla_registrazione_iva (
  p_subdociva_id integer,
  p_anno_bilancio varchar,
  p_enteproprietarioid integer,
  p_login_op varchar,
  out codresult integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
declare
    v_dataElaborazione    timestamp     := now();
    v_bil_id      		  integer       := 0 ;
    strMessaggio 		  VARCHAR(1500) :='Inizio elab.';
    v_subdociva_prot_def  varchar(200);
    v_ivareg_id           integer;
    v_subdociva_stato_id  integer;
    v_subdociva_prot_def_max varchar(200);
    v_subdociva_data_prot_def_max timestamp;     
begin
    strMessaggio := 'Inizio.';
    codresult := 0;  
    
    select siac_d_subdoc_iva_stato.subdociva_stato_id 
    into v_subdociva_stato_id
    from siac_d_subdoc_iva_stato
    where 
        siac_d_subdoc_iva_stato.ente_proprietario_id = p_enteproprietarioid
    and siac_d_subdoc_iva_stato.subdociva_stato_code = 'PR'
    and siac_d_subdoc_iva_stato.data_cancellazione is null;
    
    strMessaggio := 'estratto id di stato PR.';
    
    select ivareg_id,subdociva_prot_def
    into v_ivareg_id,v_subdociva_prot_def
    from siac_t_subdoc_iva
    where 
        siac_t_subdoc_iva.ente_proprietario_id = p_enteproprietarioid
    and siac_t_subdoc_iva.subdociva_id = p_subdociva_id;
    
    strMessaggio := 'estratto ivareg_id,subdociva_prot_def.';

    update  siac_r_subdoc_iva_stato set 
      data_cancellazione =now()
      ,data_modifica = now()
      ,login_operazione = p_login_op
	where     
         subdociva_id = p_subdociva_id
    and data_cancellazione is null;

    strMessaggio := 'cancellazione vecchio stato.';
    
    insert into siac_r_subdoc_iva_stato (
        subdociva_id
        ,subdociva_stato_id 
        ,validita_inizio 
        ,validita_fine
        ,ente_proprietario_id 
        ,data_cancellazione 
        ,login_operazione
    )values(
	     p_subdociva_id
        ,v_subdociva_stato_id 
        ,now() 
        ,null
        ,p_enteproprietarioid 
        ,null 
        ,p_login_op    
    );
    strMessaggio := 'inserimento nuovo stato.';
    
    update siac_t_subdoc_iva iva
    set    subdociva_prot_def=(iva.subdociva_prot_def::INTEGER)-1,
           data_modifica=now(),
           login_operazione=iva.login_operazione||p_login_op
    where iva.ivareg_id=v_ivareg_id
    and   iva.ente_proprietario_id=p_enteproprietarioid
    and   extract(year from iva.subdociva_data_prot_def)::varchar =p_anno_bilancio
    and   iva.subdociva_prot_def is not null
    and   iva.subdociva_prot_def::integer >= v_subdociva_prot_def::integer 
    and   iva.data_cancellazione is null
    and   iva.validita_fine is null;
    strMessaggio := 'allineamento registro IVA.';

    select 
      max(iva.subdociva_prot_def::integer) maxNum,
      max(iva.subdociva_data_prot_def) maxData
    into 
       v_subdociva_prot_def_max
      ,v_subdociva_data_prot_def_max           	
    from 
    	siac_t_subdoc_iva iva
    where 
            iva.ente_proprietario_id = p_enteproprietarioid
      and   iva.subdociva_anno = p_anno_bilancio
      and   iva.ivareg_id = v_ivareg_id
      and   iva.subdociva_data_prot_def is not null
      and   iva.data_cancellazione is null;
     strMessaggio := 'estrazione massimo numero e data per valorizzare il contatore def.';


	if v_subdociva_data_prot_def_max != null then
      update  siac_t_subdoc_iva_prot_def_num num
        set     subdociva_data_prot_def = v_subdociva_data_prot_def_max
               ,subdociva_prot_def = v_subdociva_prot_def_max::integer
               ,data_modifica=now()
               ,login_operazione=num.login_operazione||p_login_op
        from siac_v_bko_anno_bilancio anno
        where num.ente_proprietario_id=p_enteproprietarioid
        and   anno.ente_proprietario_id=p_enteproprietarioid
        and   num.periodo_id=anno.periodo_id
        and   anno.anno_bilancio=p_anno_bilancio::integer
        and   num.ivareg_id=v_ivareg_id;
	else
      update  siac_t_subdoc_iva_prot_def_num num
        set     data_cancellazione =now()
               ,data_modifica=now()
               ,login_operazione=num.login_operazione||p_login_op
        from siac_v_bko_anno_bilancio anno
        where num.ente_proprietario_id=p_enteproprietarioid
              and   anno.ente_proprietario_id=p_enteproprietarioid
              and   num.periodo_id=anno.periodo_id
              and   anno.anno_bilancio=p_anno_bilancio::integer
              and   num.ivareg_id=v_ivareg_id;
	end if;
    strMessaggio := 'siac_t_subdoc_iva_prot_def_num valorizzato';

	update siac_t_subdoc_iva set 
    	  subdociva_data_prot_def = NULL
        , subdociva_prot_def = NULL
        , subdociva_data_ordinativoadoc = NULL
        , subdociva_numordinativodoc = NULL
        , data_modifica = now()        
    where     
         subdociva_id = p_subdociva_id;

    strMessaggio := 'reset della quota iva';

	 messaggiorisultato := 'OK. '|| strMessaggio||'fine elaborazione.';
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% %  ERRORE : %',strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
    	codresult := -1;  
        return;
	when others  THEN
		raise notice ' % ERRORE DB: % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
    	codresult := -2;  
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


