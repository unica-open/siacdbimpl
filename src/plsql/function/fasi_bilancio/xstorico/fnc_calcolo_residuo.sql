/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_sposta_impegno_da_capitolo (
   p_elem_tipo_code       varchar--  'CAP-UG'
  ,p_annoBilancio         integer--  2016
  ,p_ente_proprietario_id integer
  ,p_login_operazione     varchar
  ,out messaggiorisultato varchar
)
RETURNS varchar AS
$body$
declare
    v_dataElaborazione  	timestamp := now();
    v_movgest_id  			integer  := 0 ;
    v_bil_id      			integer  := 0 ;
    v_bil_id_prec      		integer  := 0 ;
    v_movgest_ts_id 		integer  := 0 ;
    strMessaggio 			VARCHAR  :='Inizio elab.';
    strCapTmp 		    	VARCHAR;
    strImpTmp 		    	VARCHAR;
    v_annoBilancio      	varchar;
    v_annoBilancioPrec  	varchar;
    recCap   				record;
    recMovgest 				record;
    recliq					record; 
    v_impegnatoXcapitolo 	numeric :=0;
    v_spesoXcapitolo     	numeric :=0;
    v_resXCapitolo		 	numeric :=0;
    v_tot_impacc 			numeric :=0;
    v_stanziamento 			numeric :=0;
    v_stanziamento_cassa 	numeric :=0;
    v_faseBilElabId         integer :=0;
begin
   v_annoBilancio = p_annoBilancio::varchar;
   v_annoBilancioPrec = (p_annoBilancio-1)::varchar;
   	
   
   
    strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE CALCOLO RESIDUO IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code='APE_CAP_CALC_RES'
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into v_faseBilElabId;

    if v_faseBilElabId is null then
      raise exception ' Inserimento non effettuato.';
    end if;
   
   
   select bil_id into v_bil_id from siac_t_bil 
   where siac_t_periodo.anno = v_annoBilancio
   and ente_proprietario_id = p_ente_proprietario_id;

   select bil_id into v_bil_id_prec from siac_t_bil 
   where siac_t_periodo.anno = v_annoBilancioPrec
   and ente_proprietario_id = p_ente_proprietario_id;
    
   strMessaggio :=strMessaggio||'estratto id biancio '||v_bil_id::varchar||' biancio precedente '||v_bil_id_prec::VARCHAR||'.';
   
   
    for recCap IN(select 
                     siac_t_bil_elem.elem_code
                    ,siac_t_bil_elem.elem_code2
                    ,siac_t_bil_elem.elem_code3
                    ,siac_t_bil_elem.elem_id 
          			,siac_t_bil_elem.elem_tipo_id
                    ,siac_t_bil_elem_det.elem_det_importo
                  from 
                    siac_t_bil_elem ,
                    siac_d_bil_elem_tipo,
                    siac_t_bil,
                    siac_r_bil_elem_stato,
                    siac_d_bil_elem_stato,
                    siac_t_bil_elem_det,
                    siac_d_bil_elem_det_tipo
                    
                  where 
                        siac_t_bil.bil_id = siac_t_bil_elem.bil_id
                    and	siac_t_bil_elem.elem_tipo_id =  siac_d_bil_elem_tipo.elem_tipo_id
                    and siac_t_bil_elem.elem_id = siac_r_bil_elem_stato.elem_id
                    and siac_r_bil_elem_stato.elem_stato_id = siac_d_bil_elem_stato.elem_stato_id
                    and siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id
                    and siac_t_bil_elem_det.elem_det_tipo_id=siac_d_bil_elem_det_tipo.elem_det_tipo_id
					and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA' 
                    and siac_d_bil_elem_tipo.elem_tipo_code = p_elem_tipo_code--'CAP-UG'
                    and siac_t_bil.bil_id = v_bil_id
                    and siac_t_bil_elem.ente_proprietario_id = p_ente_proprietario_id
                    and siac_t_bil_elem.data_cancellazione is null
                    and siac_r_bil_elem_stato.data_cancellazione is null
                    and siac_d_bil_elem_stato in ('PR','VA')
    ) LOOP    
    strCapTmp    := 'CAPITOLO elem_code-->'||recCap.elem_code||' elem_code2-->'||recCap.elem_code2||' elem_code3-->'||recCap.elem_code3||'.';
    strMessaggio := strCapTmp;

    v_impegnatoXcapitolo :=0;
    v_spesoXcapitolo     :=0;
    	for recMovgest IN(select 
                             siac_t_movgest_ts.movgest_ts_id
                             ,siac_d_movgest_ts_tipo.movgest_ts_tipo_code
                             ,siac_t_movgest_ts_det.movgest_ts_det_importo
                          from 
                             siac_t_bil_elem
                            ,siac_r_movgest_bil_elem
                            ,siac_t_movgest
                            ,siac_t_movgest_ts                             
                            ,siac_t_movgest_ts_det                                          
                            ,siac_d_movgest_stato
                            ,siac_d_movgest_tipo
                            
                            ,siac_r_movgest_ts_stato
                            
                            ,siac_d_movgest_ts_tipo
                            ,siac_d_movgest_ts_det_tipo  
                          where 
                                siac_t_bil_elem.elem_id             	   			= siac_r_movgest_bil_elem.bil_id
                            and siac_r_movgest_bil_elem.movgest_id  	   			= siac_t_movgest.movgest_id
                            and siac_t_movgest.movgest_id           	  		 	= siac_t_movgest_ts.movgest_id                                                                                
                            and siac_t_movgest_ts.movgest_ts_id            			= siac_r_movgest_ts_stato.movgest_ts_id
                            and siac_r_movgest_ts_stato.movgest_stato_id   			= siac_d_movgest_stato.movgest_stato_id                                
                            and siac_t_movgest_ts.movgest_ts_id            			= siac_t_movgest_ts_det.movgest_ts_id                         
                            and siac_t_movgest.movgest_tipo_id             			= siac_d_movgest_tipo.movgest_tipo_id
                            and siac_t_movgest_ts.movgest_ts_tipo_id       			= siac_d_movgest_ts_tipo.movgest_ts_tipo_id 
                            and siac_t_movgest_ts_det.movgest_ts_det_tipo_id 		= siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
							and siac_d_movgest_tipo.movgest_tipo_code      			= 'I'
							and siac_d_movgest_stato.movgest_stato_code    			in ('D','N','P')
							-- faccio la if dopo
                            --and siac_d_movgest_ts_tipo.movgest_ts_tipo_code	    = 'T'
							and siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_code!= 'A'
                            and siac_t_bil_elem.elem_code  				   			= recCap.elem_code	
                            and siac_t_bil_elem.elem_code2 				   			= recCap.elem_code2
                            and siac_t_bil_elem.elem_code3 				   			= recCap.elem_code3	
                            and siac_t_bil_elem.bil_id     				   			= v_bil_id_prec
                            and siac_t_movgest.ente_proprietario_id        			= p_ente_proprietario_id
                            and siac_r_movgest_bil_elem.data_cancellazione 			is null
                            and siac_r_movgest_bil_elem.data_cancellazione 			is null)loop
                            
            if recMovgest.movgest_ts_tipo_code = 'T' THEN
                v_impegnatoXcapitolo := v_impegnatoXcapitolo + recMovgest.movgest_ts_det_importo;
            end if;
            
            for recliq IN(select siac_t_liquidazione.liq_id,
                                 siac_t_liquidazione.liq_importo
                      from 
                        siac_r_liquidazione_movgest,
                        siac_t_liquidazione,
                        siac_r_liquidazione_stato,
                        siac_d_liquidazione_stato 
                      where
                        siac_r_liquidazione_movgest.liq_id        = siac_t_liquidazione.liq_id and 
                        siac_t_liquidazione.liq_id                = siac_r_liquidazione_stato.liq_id AND
                        siac_r_liquidazione_stato.liq_stato_id    = siac_d_liquidazione_stato.liq_stato_id and 
                        siac_d_liquidazione_stato.liq_stato_code !='A' and
                        siac_r_liquidazione_movgest.movgest_ts_id = recMovgest.movgest_ts_id and 
                        siac_r_liquidazione_movgest.data_cancellazione is null and
                        siac_r_liquidazione_movgest.ente_proprietario_id = p_ente_proprietario_id )   loop 
                    
            v_spesoXcapitolo = v_spesoXcapitolo + recliq.liq_importo;                
    		end loop;--fine loop recMovgest associati al movimento
    	end loop;--fine loop movGest associati al capitolo in questione

		
        v_tot_impacc :=v_impegnatoXcapitolo - v_spesoXcapitolo;
        v_stanziamento := recCap.elem_det_importo;
        v_stanziamento_cassa =v_tot_impacc + v_stanziamento;


		insert into fase_bil_t_cap_calcolo_res (fase_bil_elab_id,elem_code ,elem_code2 ,elem_code3,bil_id ,elem_id,elem_tipo_id ,tot_impacc,stanziamento,stanziamento_cassa ,validita_inizio,validita_fine,data_cancellazione ,ente_proprietario_id ,login_operazione )
        values(v_faseBilElabId,recCap.elem_code,recCap.elem_code2,recCap.elem_code3 ,v_bil_id ,recCap.elem_id ,recCap.elem_tipo_id   ,v_tot_impacc,v_stanziamento ,v_stanziamento_cassa ,now(),null,null,p_ente_proprietario_id,p_login_operazione );

    end loop;--fine loop capitolo
    
    
    
    
     strMessaggio:='Aggiornamento fase elaborazione [fase_bil_t_elaborazione].';
     update fase_bil_t_elaborazione set
          fase_bil_elab_esito='OK',
          fase_bil_elab_esito_msg='ELABORAZIONE CALCOLO RESIDUO  COMPLETATA.',
          validita_fine=now()
     where fase_bil_elab_id=v_faseBilElabId;



    messaggiorisultato := 'OK. '|| strMessaggio||'fine elaborazione.';
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% %  ERRORE : %',strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return;
	when others  THEN
		raise notice ' % ERRORE DB: % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;