/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_allineadocprotdef (
  enteproprietarioid integer,
  p_num_prot_def integer,
  p_anno_prot_def varchar,
  p_anno integer,
  p_ivareg_id integer,
  p_doc_numero varchar,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
declare
	dataElaborazione timestamp := now();

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';


    v_subdociva_id integer := 0;
    v_ivareg_id integer := 0;
    v_reg_tipo_id integer := 0;

    nAnomalie integer := 0;

begin
	strMessaggioFinale := 'Aggiornamento completato.';

	--if coalesce(migrRecord.storno_quiet_numero,NVL_STR)!=NVL_STR
  if (enteproprietarioid <1 OR p_num_prot_def <1 OR p_anno <1900 OR  p_doc_numero ='') then
	  codicerisultato := -1;
      messaggioRisultato:='un parametro tra enteproprietarioid - p_num_prot_def - p_anno - p_doc_numero è nullo';
      return;
  end if;		

  strMessaggio :='STEP 1. ';  
  
  if  p_ivareg_id >0 then 
      begin  
        
        select 
             A.subdociva_id
            ,A.ivareg_id
            ,A.reg_tipo_id  
		into
			v_subdociva_id
        	,v_ivareg_id
        	,v_reg_tipo_id        
		from
        ( 
          select 
           siva.subdociva_id
          ,siva.ivareg_id
          ,siva.reg_tipo_id     
          from 
           siac_t_doc doc 
          ,siac_r_doc_iva rdoc
          ,siac_t_subdoc_iva  siva
          where  
              doc.doc_id =  rdoc .doc_id
          and siva.dociva_r_id = rdoc.dociva_r_id
          and doc.ente_proprietario_id = enteproprietarioid
          and siva.ivareg_id = p_ivareg_id
          and doc.doc_anno = p_anno
          and trim(doc.doc_numero) = p_doc_numero
          and doc.data_cancellazione is null 
          and siva.data_cancellazione is null
          union
          select 
             siva.subdociva_id
            ,siva.ivareg_id
            ,siva.reg_tipo_id     
          from 
             siac_t_doc doc 
            ,siac_t_subdoc sdoc
            ,siac_r_subdoc_subdoc_iva ssdoc
            ,siac_t_subdoc_iva  siva
          where  
                
                doc.doc_id = sdoc.doc_id
            and sdoc.subdoc_id = ssdoc.subdoc_id
            and ssdoc.subdociva_id = siva.subdociva_id
            and doc.ente_proprietario_id = enteproprietarioid
            and siva.ivareg_id = p_ivareg_id
            and doc.doc_anno = p_anno
            and trim(doc.doc_numero) = p_doc_numero
            and doc.data_cancellazione is null 
            and siva.data_cancellazione is null
        ) A;
        
        /*
        
        
        
        
        select 
         siva.subdociva_id
        ,siva.ivareg_id
        ,siva.reg_tipo_id
        into
         v_subdociva_id
        ,v_ivareg_id
        ,v_reg_tipo_id           
        from 
         siac_t_doc doc 
		,siac_r_doc_iva rdoc
        ,siac_t_subdoc_iva  siva
        where  
            doc.doc_id =  rdoc .doc_id
		and siva.dociva_r_id = rdoc.dociva_r_id
        and doc.ente_proprietario_id = enteproprietarioid
        and siva.ivareg_id = p_ivareg_id
        and doc.doc_anno = p_anno
        and trim(doc.doc_numero) = p_doc_numero
        and doc.data_cancellazione is null 
        and siva.data_cancellazione is null;
        */
            
        exception
            when NO_DATA_FOUND then
            codicerisultato := -2;
            messaggioRisultato:='nessun subdocumento iva trovato';
            return;
            when others  THEN
                messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
                return;
        end;
	else
        begin  
        
          select 
               B.subdociva_id
              ,B.ivareg_id
              ,B.reg_tipo_id  
          into
               v_subdociva_id
              ,v_ivareg_id
              ,v_reg_tipo_id        
          from
          ( 
            select 
             siva.subdociva_id
            ,siva.ivareg_id
            ,siva.reg_tipo_id
            from 
             siac_t_doc doc 
            ,siac_r_doc_iva rdoc
            ,siac_t_subdoc_iva  siva
            where  
                doc.doc_id =  rdoc .doc_id
            and siva.dociva_r_id = rdoc.dociva_r_id
            and doc.ente_proprietario_id = enteproprietarioid
            and doc.doc_anno = p_anno
            and trim(doc.doc_numero) = p_doc_numero
            and doc.data_cancellazione is null 
            and siva.data_cancellazione is null
            union
            
            select 
             siva.subdociva_id
            ,siva.ivareg_id
            ,siva.reg_tipo_id
            from 
             siac_t_doc doc 
            ,siac_t_subdoc sdoc
            ,siac_r_subdoc_subdoc_iva ssdoc
            ,siac_t_subdoc_iva  siva
            where  
                doc.doc_id = sdoc.doc_id
            and sdoc.subdoc_id = ssdoc.subdoc_id
            and ssdoc.subdociva_id = siva.subdociva_id


            and doc.ente_proprietario_id = enteproprietarioid
            and doc.doc_anno = p_anno
            and trim(doc.doc_numero) = p_doc_numero
            and doc.data_cancellazione is null 
            and siva.data_cancellazione is null
          ) B;
        /*
        select 
         siva.subdociva_id
        ,siva.ivareg_id
        ,siva.reg_tipo_id
        into
         v_subdociva_id
        ,v_ivareg_id
        ,v_reg_tipo_id           
        from 
         siac_t_doc doc 
		,siac_r_doc_iva rdoc
        ,siac_t_subdoc_iva  siva
        where  
            doc.doc_id =  rdoc .doc_id
		and siva.dociva_r_id = rdoc.dociva_r_id
        and doc.ente_proprietario_id = enteproprietarioid
        and doc.doc_anno = p_anno
        and trim(doc.doc_numero) = p_doc_numero
        and doc.data_cancellazione is null 
        and siva.data_cancellazione is null;
 
*/
       exception
            when NO_DATA_FOUND then
            	codicerisultato := -2;
            	messaggioRisultato:='nessun subdocumento iva trovato';
            return;
            when others  THEN
                messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
                return;
        end;
    
    end if;


	strMessaggio :='STEP 2 aggiornamento numero . '; 
	if p_anno_prot_def is not null then
      update siac_t_subdoc_iva  set 
      subdociva_prot_def      =  p_num_prot_def,
      subdociva_data_prot_def =  to_timestamp(p_anno_prot_def,'yyyy-mm-dd'),
      data_modifica=now(),
      login_operazione ='batch_tr'
      where 
      subdociva_id = v_subdociva_id ;
	else
      update siac_t_subdoc_iva  set 
      subdociva_prot_def =p_num_prot_def,
      data_modifica=now(),
      login_operazione ='batch_tr'
      where 
      subdociva_id = v_subdociva_id ;
	end if; 

	codicerisultato:=-0;
    messaggioRisultato:=' aggiornamento effettuato Ok.';


exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % % ERRORE : %',strMessaggioFinale,strMessaggio, substring(upper(SQLERRM) from 1 for 1500);
        strMessaggioFinale:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codicerisultato:=-1;
        return;
	when others  THEN
		raise notice '% % % ERRORE DB: % %',strMessaggioFinale,rec,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
        strMessaggioFinale:=strMessaggioFinale||rec||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codicerisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

