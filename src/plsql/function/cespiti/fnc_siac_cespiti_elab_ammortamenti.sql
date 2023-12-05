/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_cespiti_elab_ammortamenti(
   integer,
   varchar,
   integer
);


CREATE OR REPLACE FUNCTION fnc_siac_cespiti_elab_ammortamenti (
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_anno integer,
  out numcespiti INTEGER,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
declare
    dataElaborazione timestamp 	:= now();
    strMessaggio VARCHAR(1500)	:='Inizio elab.';
    rec_elab_ammortamenti 		record;
    rec_elab_x_cespite    		record;
    v_elab_id 					INTEGER;        
    v_ces_id 					INTEGER;
    v_elab_dett_id_dare 		INTEGER;
    v_elab_dett_id_avere 		INTEGER;
    v_pnota_id 					INTEGER;
    v_ces_amm_dett_id			INTEGER;
begin
    numcespiti:=0;
    select elab_id into v_elab_id from siac_t_cespiti_elab_ammortamenti 
    where anno = p_anno and ente_proprietario_id = p_enteproprietarioid and data_cancellazione is null;
    
    if v_elab_id is not null then
    
      update  siac_r_cespiti_cespiti_elab_ammortamenti set data_cancellazione = now() ,validita_fine = now() ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
      update  siac_t_cespiti_elab_ammortamenti_dett    set data_cancellazione = now() ,validita_fine = now() ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
      update  siac_t_cespiti_elab_ammortamenti         set data_cancellazione = now() ,validita_fine = now() ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
	
    end if;

    insert into siac_t_cespiti_elab_ammortamenti (anno,stato_elaborazione,data_elaborazione,validita_inizio,validita_fine ,ente_proprietario_id,data_cancellazione,login_operazione) 
    values(p_anno,'AVVIATO',now(),now(),null, p_enteproprietarioid ,null,p_loginoperazione) RETURNING elab_id INTO v_elab_id;


    for rec_elab_ammortamenti in (	
         select 
        dct.pdce_conto_ammortamento_id, 
        dct.pdce_conto_ammortamento_code, 
        dct.pdce_conto_ammortamento_desc,
        dct.pdce_conto_fondo_ammortamento_id, 
        dct.pdce_conto_fondo_ammortamento_code, 
        dct.pdce_conto_fondo_ammortamento_desc,
        COALESCE(count(*),0) numero_cespiti,
        coalesce(sum(tamd.ces_amm_dett_importo), 0) importo
        from siac_t_cespiti tc
        , siac_d_cespiti_bene_tipo dct 
        , siac_t_cespiti_ammortamento tam 
        , siac_t_cespiti_ammortamento_dett tamd 
        where (tc.data_cessazione is null OR (EXTRACT(YEAR FROM tc.data_cessazione))::INTEGER = p_anno)
        and dct.ces_bene_tipo_id = tc.ces_bene_tipo_id
        and tam.ces_id = tc.ces_id and tam.data_cancellazione is null
        and tamd.ces_amm_id = tam.ces_amm_id 
        and tamd.data_cancellazione is null 
        and tamd.num_reg_def_ammortamento is null
        and dct.pdce_conto_ammortamento_id is not null 
        and dct.pdce_conto_fondo_ammortamento_id is not null
        and tamd.ces_amm_dett_anno = p_anno 
        and tamd.ente_proprietario_id = p_enteproprietarioid  
        group by 
        dct.pdce_conto_ammortamento_id, 
        dct.pdce_conto_ammortamento_code, 
        dct.pdce_conto_ammortamento_desc,
        dct.pdce_conto_fondo_ammortamento_id,
        dct.pdce_conto_fondo_ammortamento_code,
        dct.pdce_conto_fondo_ammortamento_desc
     ) loop
	
	strMessaggio :='inserimento in siac_t_cespiti_elab_ammortamenti_dett.';

    insert into siac_t_cespiti_elab_ammortamenti_dett (
    	elab_id
        ,pdce_conto_id
        ,pdce_conto_code
        ,pdce_conto_desc
        ,elab_det_importo
        ,elab_det_segno
        ,numero_cespiti
        ,pnota_id
        ,validita_inizio
        ,validita_fine
        ,ente_proprietario_id 
        ,data_cancellazione
        ,login_operazione
    )values(
         v_elab_id
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_id
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_code 
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_desc
        ,rec_elab_ammortamenti.importo
        ,'Dare'        
        ,rec_elab_ammortamenti.numero_cespiti        
        ,null--TODO pnota_id  inizializzato da altro sistema,
        ,now()
        ,null
        ,p_enteproprietarioid
        ,null
        ,p_loginoperazione
    ) returning elab_dett_id into v_elab_dett_id_dare ;



   insert into siac_t_cespiti_elab_ammortamenti_dett (
    	elab_id
        ,pdce_conto_id
        ,pdce_conto_code
        ,pdce_conto_desc
        ,elab_det_importo
        ,elab_det_segno
        ,numero_cespiti
        ,pnota_id
        ,validita_inizio
        ,validita_fine
        ,ente_proprietario_id 
        ,data_cancellazione
        ,login_operazione
    )values(
         v_elab_id
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_id 
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_code 
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_desc
        ,rec_elab_ammortamenti.importo
        ,'Avere'        
        ,rec_elab_ammortamenti.numero_cespiti      
        ,null--TODO pnota_id  inizializzato da altro sistema,
        ,now()
        ,null
        ,p_enteproprietarioid
        ,null
        ,p_loginoperazione
    )returning elab_dett_id into v_elab_dett_id_avere ;

      for rec_elab_ammortamenti in (	
          select         	
              tc.ces_id   
              ,tamd.ces_amm_dett_id         
          from 
            siac_t_cespiti tc
          , siac_d_cespiti_bene_tipo dct 
          , siac_t_cespiti_ammortamento tam 
          , siac_t_cespiti_ammortamento_dett tamd 
          where (tc.data_cessazione is null OR (EXTRACT(YEAR FROM tc.data_cessazione))::INTEGER = p_anno)
          and dct.ces_bene_tipo_id = tc.ces_bene_tipo_id
          and tam.ces_id = tc.ces_id and tam.data_cancellazione is null
          and tamd.ces_amm_id = tam.ces_amm_id 
          and tamd.data_cancellazione is null 
          and tamd.num_reg_def_ammortamento is null
          and dct.pdce_conto_ammortamento_id  = rec_elab_ammortamenti.pdce_conto_ammortamento_id
          and dct.pdce_conto_fondo_ammortamento_id = rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_id
          and tamd.ces_amm_dett_anno = p_anno::integer
          and tamd.ente_proprietario_id = p_enteproprietarioid       
          
      ) loop


          insert into siac_r_cespiti_cespiti_elab_ammortamenti(
               ces_id
              ,elab_id
              ,elab_dett_id_dare
              ,elab_dett_id_avere
              ,ente_proprietario_id
              ,pnota_id
              ,validita_inizio
              ,validita_fine
              ,data_cancellazione
              ,login_operazione  
              ,ces_amm_dett_id  
          )values(
               rec_elab_ammortamenti.ces_id
              ,v_elab_id
              ,v_elab_dett_id_dare
              ,v_elab_dett_id_avere
              ,p_enteproprietarioid
              ,null--v_pnota_id,
              ,now()
              ,null
              ,null
              ,p_loginoperazione
              ,rec_elab_ammortamenti.ces_amm_dett_id
          );

			numcespiti := numcespiti + 1;
      end loop;

	end loop;	
    

	if numcespiti > 0 then
    	update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = 'CONCLUSO'  ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
	else
    	update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = 'CONCLUSO SENZA CESPITI' , data_cancellazione = now()  ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
 	end if;

    messaggiorisultato := 'OK. Fine Elaborazione.';
    
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
    	--update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = messaggiorisultato , data_cancellazione = now() where elab_id = v_elab_id;

        return;
	when others  THEN
		raise notice ' %  % ERRORE DB: %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        --update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = messaggiorisultato , data_cancellazione = now() where elab_id = v_elab_id;
        
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--select * from fnc_siac_cespiti_elab_ammortamenti(2,'admin',2018);
