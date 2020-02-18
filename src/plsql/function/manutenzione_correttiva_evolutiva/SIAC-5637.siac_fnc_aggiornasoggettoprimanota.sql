/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*
create or replace function siac_fnc_aggiornasoggettoprimanotatotal (
   p_ente_proprietario_id integer
)RETURNS varchar AS
$body$
DECLARE
	strMessaggio    			varchar; 
    v_messaggiorisultato        varchar;
    rec							record;
    v_id						integer;

BEGIN
    v_messaggiorisultato :='Inizio.';
    strMessaggio:= 'Inizio.';

	for rec in (
    	select pnota_id from siac_t_prima_nota where ente_proprietario_id = p_ente_proprietario_id and data_cancellazione is null
    )loop
		select messaggiorisultato into v_messaggiorisultato from siac_fnc_aggiornasoggettoprimanota (rec.pnota_id) ; 
    end loop;

    return v_messaggiorisultato;
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% %  ERRORE : %',strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
        v_messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
	when others  THEN
		raise notice ' % ERRORE DB: % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        v_messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
*/
 

--drop function siac_fnc_aggiornasoggettoprimanota (integer);



create or replace function siac_fnc_aggiornasoggettoprimanota (
   p_pnota_id integer
)RETURNS varchar AS
$body$
DECLARE
	strMessaggio    			varchar; 
    v_collegamento_tipo_code	varchar; 
    v_id						integer;
    v_soggetto_id               integer = NULL;
    codicerisultato 			integer;
    messaggiorisultato 			varchar;
	v_soggetto_id_pn            integer;
    v_pnota_id_con_anomalia     integer;
BEGIN
     codicerisultato :=0;
    messaggiorisultato :='Inizio.';
    strMessaggio:= 'Inizio.';
    
    -- -2 errore gestito (nessun record prima query/collegamento DE/DS)
    -- -1 errore generico
    --  0 ok


    SELECT
         siac_d_collegamento_tipo.collegamento_tipo_code 
        ,siac_r_evento_reg_movfin.campo_pk_id
        ,siac_t_prima_nota.soggetto_id
    into 
        v_collegamento_tipo_code
        ,v_id
        ,v_soggetto_id_pn
    FROM      
        siac_t_prima_nota     
        ,siac_d_ambito    
        ,siac_d_causale_ep_tipo      
        ,siac_r_prima_nota_stato      
        ,siac_d_prima_nota_stato     
        ,siac_t_mov_ep  
        ,siac_r_evento_reg_movfin      
        ,siac_d_evento    
        ,siac_d_collegamento_tipo 
    WHERE 
          siac_t_prima_nota.ambito_id = siac_d_ambito.ambito_id  
      AND siac_t_prima_nota.causale_ep_tipo_id = siac_d_causale_ep_tipo.causale_ep_tipo_id  
      AND siac_r_prima_nota_stato.pnota_id = siac_t_prima_nota.pnota_id  
      AND siac_r_prima_nota_stato.pnota_stato_id = siac_d_prima_nota_stato.pnota_stato_id  
      AND siac_t_prima_nota.pnota_id = siac_t_mov_ep.regep_id  
      AND siac_r_evento_reg_movfin.regmovfin_id = siac_t_mov_ep.regmovfin_id
      AND siac_r_evento_reg_movfin.evento_id = siac_d_evento.evento_id  
      AND siac_d_evento.collegamento_tipo_id = siac_d_collegamento_tipo.collegamento_tipo_id  
      AND siac_t_prima_nota.pnota_id = p_pnota_id
      AND siac_d_prima_nota_stato.pnota_stato_code <>'A'
      AND siac_t_prima_nota.data_cancellazione is null      
      AND siac_d_ambito.data_cancellazione is null  
      AND siac_d_causale_ep_tipo.data_cancellazione is null   
      AND siac_r_prima_nota_stato.data_cancellazione is null
      AND siac_d_prima_nota_stato.data_cancellazione is null 
      AND siac_t_mov_ep.data_cancellazione is null
      AND siac_r_evento_reg_movfin.data_cancellazione is null
      AND siac_d_evento.data_cancellazione is null 
      AND siac_d_collegamento_tipo.data_cancellazione is null
      LIMIT 1; 



      if v_collegamento_tipo_code = 'I' OR v_collegamento_tipo_code = 'A' THEN
      strMessaggio:= 'Impegno Accertamento.';      
		select siac_t_soggetto.soggetto_id 
        into v_soggetto_id
        from	      
           siac_t_movgest
          ,siac_t_movgest_ts
          ,siac_r_movgest_ts_sog
          ,siac_t_soggetto
		where 
        	siac_t_movgest.movgest_id       = siac_t_movgest_ts.movgest_id
          	AND siac_t_movgest_ts.movgest_ts_id   =  siac_r_movgest_ts_sog.movgest_ts_id
          	AND siac_r_movgest_ts_sog.soggetto_id =  siac_t_soggetto.soggetto_id
          	AND siac_r_movgest_ts_sog.data_cancellazione IS NULL
          	AND siac_r_movgest_ts_sog.validita_fine IS NULL
			AND siac_t_movgest.movgest_id  = v_id  ;    
      end if;
       
      if v_collegamento_tipo_code = 'SI' OR v_collegamento_tipo_code = 'SA' THEN
      	strMessaggio:= 'subImpegno subAccertamento.';
		select siac_t_soggetto.soggetto_id 
        into strict  v_soggetto_id
        from	      
          siac_t_movgest_ts
          ,siac_r_movgest_ts_sog
          ,siac_t_soggetto
		where 
        	    siac_t_movgest_ts.movgest_ts_id   =  siac_r_movgest_ts_sog.movgest_ts_id
          	AND siac_r_movgest_ts_sog.soggetto_id =  siac_t_soggetto.soggetto_id
          	AND siac_r_movgest_ts_sog.data_cancellazione IS NULL
          	AND siac_r_movgest_ts_sog.validita_fine IS NULL
			AND siac_t_movgest_ts.movgest_ts_id  = v_id  ;    
      end if;
   
    
      if v_collegamento_tipo_code = 'L' THEN
      	strMessaggio:= 'Liquidazione.';
        
        select siac_t_soggetto.soggetto_id 
        into strict  v_soggetto_id
        from	      
          siac_t_liquidazione
          ,siac_r_liquidazione_soggetto
          ,siac_t_soggetto
		where 
        	    siac_t_liquidazione.liq_id   =  siac_r_liquidazione_soggetto.liq_id
          	AND siac_r_liquidazione_soggetto.soggetto_id =  siac_t_soggetto.soggetto_id
          	AND siac_r_liquidazione_soggetto.data_cancellazione IS NULL
          	AND siac_r_liquidazione_soggetto.validita_fine IS NULL
			AND siac_t_liquidazione.liq_id  = v_id  ;  
            
      end if;
      
      
      if v_collegamento_tipo_code = 'DE' OR v_collegamento_tipo_code = 'DS' THEN
      		strMessaggio:= 'Documento spesa entrata.';
            codicerisultato    := -2;
      		messaggiorisultato :='Elaborazione richiesta documento spesa entrata non prevista v_id '||v_id::varchar;
            return codicerisultato::varchar ||'-'||messaggiorisultato;
            /*  
                  select distinct siac_t_soggetto.soggetto_id 
                  into strict  v_soggetto_id
                  from	      
                    siac_t_doc
                    ,siac_r_doc_sog
                    ,siac_t_soggetto
                  where 
                        siac_t_doc.doc_id   =  siac_r_doc_sog.doc_id
                    AND siac_r_doc_sog.soggetto_id =  siac_t_soggetto.soggetto_id	
                    AND siac_t_doc.doc_id  = v_id  ;  
             */       
      end if;
	  
    	
      if v_collegamento_tipo_code = 'SE' OR v_collegamento_tipo_code = 'SS' THEN
      	strMessaggio:= 'subDocumento spesa entrata.';

        select distinct siac_t_soggetto.soggetto_id 
        into strict  v_soggetto_id
        from	      
          siac_t_doc
          ,siac_t_subdoc
          ,siac_r_doc_sog
          ,siac_t_soggetto
        where 
              siac_t_doc.doc_id = siac_t_subdoc.doc_id
          AND siac_t_doc.doc_id =  siac_r_doc_sog.doc_id
          AND siac_r_doc_sog.soggetto_id =  siac_t_soggetto.soggetto_id
          AND siac_r_doc_sog.data_cancellazione IS NULL
          AND siac_r_doc_sog.validita_fine IS NULL
          AND siac_t_subdoc.subdoc_id  = v_id  ;  

      end if;
      
      
      if v_collegamento_tipo_code = 'OI' OR v_collegamento_tipo_code = 'OP' THEN
      	strMessaggio:= 'ordinativi.';
        select distinct siac_t_soggetto.soggetto_id 
        into strict  v_soggetto_id
        from	      
           siac_t_ordinativo
          ,siac_r_ordinativo_soggetto
          ,siac_t_soggetto
        where 
              siac_t_ordinativo.ord_id =  siac_r_ordinativo_soggetto.ord_id
          AND siac_r_ordinativo_soggetto.soggetto_id =  siac_t_soggetto.soggetto_id
          AND siac_r_ordinativo_soggetto.data_cancellazione IS NULL
          AND siac_r_ordinativo_soggetto.validita_fine IS NULL
          AND siac_t_ordinativo.ord_id  = v_id  ;  

      end if;

      if v_collegamento_tipo_code = 'MMGS' OR v_collegamento_tipo_code = 'MMGE' THEN
        
        select pippo.sog_id
		into v_soggetto_id   
        FROM
        (     
          select distinct siac_r_movgest_ts_sog_mod.soggetto_id_new sog_id        
          from
             siac_t_modifica
            ,siac_r_modifica_stato
            ,siac_r_movgest_ts_sog_mod
          where 
            siac_t_modifica.mod_id = siac_r_modifica_stato.mod_id
            AND siac_r_modifica_stato.mod_stato_r_id =  siac_r_movgest_ts_sog_mod.mod_stato_r_id
            AND siac_r_modifica_stato.data_cancellazione IS NULL
            AND siac_r_modifica_stato.validita_fine IS NULL
            AND siac_r_movgest_ts_sog_mod.data_cancellazione IS NULL
            AND siac_r_movgest_ts_sog_mod.validita_fine IS NULL
            AND siac_t_modifica.mod_id = v_id
          UNION 

          /* Potrebbe avere una classe al posto del soggetto
          select distinct  siac_r_movgest_ts_sog.soggetto_id sog_id        
          from
             siac_t_modifica
            ,siac_r_modifica_stato
            ,siac_r_movgest_ts_sogclasse_mod
            ,siac_t_movgest_ts
            ,siac_r_movgest_ts_sog
          where 
                siac_t_modifica.mod_id = siac_r_modifica_stato.mod_id
            AND siac_r_modifica_stato.mod_stato_r_id =  siac_r_movgest_ts_sogclasse_mod.mod_stato_r_id
            AND siac_r_movgest_ts_sogclasse_mod.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id
            AND siac_t_movgest_ts.movgest_ts_id = siac_r_movgest_ts_sog.movgest_ts_id
            AND siac_t_modifica.mod_id = v_id
			AND siac_t_modifica.data_cancellazione is null
            AND siac_r_modifica_stato.data_cancellazione is null
            AND siac_r_movgest_ts_sogclasse_mod.data_cancellazione is null
            AND siac_t_movgest_ts.data_cancellazione is null
            AND siac_r_movgest_ts_sog.data_cancellazione is null
		  UNION 
		  */
          	
          select distinct siac_r_movgest_ts_sog.soggetto_id sog_id        
          from
             siac_t_modifica
            ,siac_r_modifica_stato
            ,siac_t_movgest_ts_det_mod
            ,siac_t_movgest_ts
            ,siac_r_movgest_ts_sog
          where 
                siac_t_modifica.mod_id = siac_r_modifica_stato.mod_id
            AND siac_r_modifica_stato.mod_stato_r_id =  siac_t_movgest_ts_det_mod.mod_stato_r_id
            AND siac_t_movgest_ts_det_mod.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id
            AND siac_t_movgest_ts.movgest_ts_id = siac_r_movgest_ts_sog.movgest_ts_id
            AND siac_t_modifica.mod_id = v_id
            AND siac_r_modifica_stato.data_cancellazione is null
            AND siac_r_modifica_stato.validita_fine IS NULL
            AND siac_r_movgest_ts_sog.data_cancellazione IS NULL
            AND siac_r_movgest_ts_sog.validita_fine IS NULL

        ) as pippo;  
          
      end if;


      if v_collegamento_tipo_code = 'RE' THEN
      	strMessaggio:= 'Richiesta Economale.';
        select distinct siac_t_soggetto.soggetto_id 
        into   v_soggetto_id
        from
           siac_t_richiesta_econ
          ,siac_r_richiesta_econ_sog
          ,siac_t_soggetto
        where 
            siac_t_richiesta_econ.ricecon_id =  siac_r_richiesta_econ_sog.ricecon_id
        and siac_r_richiesta_econ_sog.soggetto_id =  siac_t_soggetto.soggetto_id
        AND siac_r_richiesta_econ_sog.data_cancellazione IS NULL
        AND siac_r_richiesta_econ_sog.validita_fine IS NULL
        and siac_t_richiesta_econ.ricecon_id = v_id;
      end if;


      if v_collegamento_tipo_code = 'RR' THEN
      	strMessaggio:= 'Rendiconto Richiesta Economale.';      
        select distinct siac_t_soggetto.soggetto_id 
        into   v_soggetto_id
        from
           siac_t_giustificativo
          ,siac_t_richiesta_econ
          ,siac_r_richiesta_econ_sog
          ,siac_t_soggetto
        where 
            siac_t_giustificativo.ricecon_id = siac_t_richiesta_econ.ricecon_id
        and siac_t_richiesta_econ.ricecon_id =  siac_r_richiesta_econ_sog.ricecon_id
        and siac_r_richiesta_econ_sog.soggetto_id =  siac_t_soggetto.soggetto_id
        AND siac_r_richiesta_econ_sog.data_cancellazione IS NULL
        AND siac_r_richiesta_econ_sog.validita_fine IS NULL
        and siac_t_giustificativo.gst_id = v_id;
              
      end if;


      if v_collegamento_tipo_code = 'RT' THEN
      	strMessaggio:= 'Ratei.';
		select distinct siac_t_soggetto.soggetto_id 
        into   v_soggetto_id
        from
            siac_t_prima_nota_ratei_risconti
        	,siac_t_prima_nota
            ,siac_t_soggetto
		where
				siac_t_prima_nota_ratei_risconti.pnota_id = siac_t_prima_nota.pnota_id
            AND siac_t_prima_nota.soggetto_id = siac_t_soggetto.soggetto_id
        	AND siac_t_prima_nota.pnota_id = v_id;
      end if;


      if v_collegamento_tipo_code = 'RS' THEN
      	strMessaggio:= 'Risconti.';       
        select distinct siac_t_soggetto.soggetto_id 
        into   v_soggetto_id
        from
             siac_t_prima_nota_ratei_risconti
        	,siac_t_prima_nota
            ,siac_t_soggetto
		where
                siac_t_prima_nota_ratei_risconti.pnota_id = siac_t_prima_nota.pnota_id
            AND siac_t_prima_nota.soggetto_id = siac_t_soggetto.soggetto_id
        	AND siac_t_prima_nota_ratei_risconti.pnotarr_id = v_id;
      end if;

      v_soggetto_id := COALESCE(v_soggetto_id, -1);
	  strMessaggio:= 'aggiornamento del soggetto v_soggetto_id-->'||v_soggetto_id::VARCHAR||'.'; 
      
      
      	
      if coalesce(v_soggetto_id_pn, -1) <> v_soggetto_id then
        messaggiorisultato := p_pnota_id::varchar||',' ;       
        --raise notice 'v_soggetto_id_pn %', coalesce(v_soggetto_id_pn, -1)::varchar;
        --raise notice 'v_soggetto_id %', v_soggetto_id::varchar;
        --raise notice 'DA TRATTARE %', p_pnota_id;
		
        update  siac_t_prima_nota 
        set soggetto_id = v_soggetto_id
        ,data_modifica = now()
        ,login_operazione = '_'||login_operazione
        where   siac_t_prima_nota.pnota_id = p_pnota_id;
        
         messaggiorisultato := 'OK - DATO TRATTATO';
      else
        --raise notice 'DA NON TRATTARE %', p_pnota_id::varchar;
        messaggiorisultato := 'OK - NON TRATTATO';      	
      end if;  

      return codicerisultato::varchar ||'-'||messaggiorisultato;
exception
    when RAISE_EXCEPTION THEN
    	--raise notice '% %  ERRORE : %',strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=-1;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato||'-PRIMA NOTA IN ESECUZIONE:'||p_pnota_id::varchar;
	when others  THEN
		--raise notice ' % ERRORE DB: % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=-1;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato||'-PRIMA NOTA IN ESECUZIONE:'||p_pnota_id::varchar;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
