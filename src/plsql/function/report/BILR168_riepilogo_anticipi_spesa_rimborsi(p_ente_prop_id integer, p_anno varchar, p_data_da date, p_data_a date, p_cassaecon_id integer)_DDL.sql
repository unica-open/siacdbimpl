/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR168_riepilogo_anticipi_spesa_rimborsi" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_da date,
  p_data_a date,
  p_cassaecon_id integer
)
RETURNS TABLE (
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  anno_impegno integer,
  num_impegno varchar,
  descr_impegno varchar,
  num_sub_impegno varchar,
  num_movimento integer,
  tipo_richiesta varchar,
  num_sospeso integer,
  data_movimento date,
  data_richiesta date,
  matricola varchar,
  nominativo varchar,
  descr_richiesta varchar,
  imp_richiesta numeric,
  code_tipo_richiesta varchar,
  tipo varchar,
  rendicontato varchar
) AS
$body$
DECLARE
elenco_movimenti record;
dati_giustif record;
sql_query VARCHAR;
num_date INTEGER;
RTN_MESSAGGIO text;

BEGIN   
   num_capitolo='';
   num_articolo='';
   ueb='';
   anno_impegno=0;
   num_impegno='';
   descr_impegno='';
   num_movimento=0;
   tipo_richiesta='';
   num_sospeso=0;
   data_movimento=NULL;

   matricola='';
   nominativo='';
   descr_richiesta='';
   imp_richiesta=0;   
   code_tipo_richiesta='';
   num_sub_impegno='';
   

        
RTN_MESSAGGIO:='esecuzione della query. ';   
 
sql_query:='with ele_movimenti_cassa as(
select richiesta_econ.ricecon_id,
		movimento.movt_numero 					num_movimento,
        movimento.gst_id,
        richiesta_econ.ricecon_desc				descr_richiesta,
        richiesta_econ.ricecon_importo			imp_richiesta,
        richiesta_econ_tipo.ricecon_tipo_desc	tipo_richiesta,            
        richiesta_econ_tipo.ricecon_tipo_code  	code_tipo_richiesta,
        movimento.movt_data				data_movimento,
        richiesta_econ_sospesa.ricecons_numero	num_sospeso,
        richiesta_econ.ricecon_matricola		matricola,
        CASE WHEN  richiesta_econ.ricecon_nome = richiesta_econ.ricecon_cognome 
            THEN richiesta_econ.ricecon_nome
            ELSE richiesta_econ.ricecon_cognome||'' ''||
                richiesta_econ.ricecon_nome end nominativo,
        date_trunc(''day'', richiesta_econ.data_creazione) 	data_richiesta,
        t_giustif.rend_importo_restituito, 
        t_giustif.rend_importo_integrato
 from 	siac_t_movimento						movimento
 			LEFT JOIN siac_t_giustificativo 	t_giustif
            	on (t_giustif.gst_id = movimento.gst_id
                	AND t_giustif.data_cancellazione is null),
 		siac_t_richiesta_econ					richiesta_econ
        	LEFT join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
            	on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
            		and richiesta_econ_sospesa.data_cancellazione is null),
        siac_t_cassa_econ						cassa_econ,
 		siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
        siac_r_richiesta_econ_stato				r_richiesta_stato,
        siac_d_richiesta_econ_stato				richiesta_stato,
        siac_t_periodo 							anno_eserc,
        siac_t_bil 								bilancio
where   movimento.ricecon_id=richiesta_econ.ricecon_id	    
    AND cassa_econ.cassaecon_id= richiesta_econ.cassaecon_id
    AND richiesta_econ.ricecon_tipo_id=richiesta_econ_tipo.ricecon_tipo_id 
    AND richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id 
    AND r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id
    and richiesta_econ.bil_id=bilancio.bil_id
    and bilancio.periodo_id=anno_eserc.periodo_id
    and movimento.ente_proprietario_id ='||p_ente_prop_id||'
    and richiesta_econ.cassaecon_id='||p_cassaecon_id||'
    and anno_eserc.anno='''||p_anno||'''
    and richiesta_stato.ricecon_stato_code <> ''AN'' ';
    if p_data_da is NOT NULL AND p_data_a is NOT NULL THEN
    	sql_query:=sql_query||'
        	AND date_trunc(''day'', richiesta_econ.data_creazione) between '''||p_data_da||''' and '''|| p_data_a||'''';
    end if;
    sql_query:=sql_query||'
    AND richiesta_econ_tipo.ricecon_tipo_code in(
    	''ANTICIPO_SPESE'',
    	--''ANTICIPO_SPESE_MISSIONE'', 
       -- ''ANTICIPO_SPESE_MISSIONE_RENDICONTO'',
        ''ANTICIPO_SPESE_RENDICONTO'', 
      --  ''ANTICIPO_TRASFERTA_DIPENDENTI'',
        ''RIMBORSO_SPESE'')
    AND movimento.data_cancellazione IS NULL
    AND richiesta_econ.data_cancellazione IS NULL
    AND cassa_econ.data_cancellazione IS NULL
    AND richiesta_econ_tipo.data_cancellazione IS NULL
    AND r_richiesta_stato.data_cancellazione IS NULL
    AND richiesta_stato.data_cancellazione IS NULL
    AND anno_eserc.data_cancellazione IS NULL
    AND bilancio.data_cancellazione IS NULL ),
ele_movimenti_cap as(
	select r_richiesta_movgest.ricecon_id, movgest.movgest_anno anno_impegno,
    	movgest.movgest_numero num_impegno, movgest_ts.movgest_ts_code num_sub_impegno,
        bil_elem.elem_code num_capitolo,
        bil_elem.elem_code2 num_articolo, bil_elem.elem_code3 UEB,
        movgest.movgest_desc					descr_impegno
    from siac_r_richiesta_econ_movgest			r_richiesta_movgest,
    	siac_t_movgest							movgest,
    	siac_t_movgest_ts						movgest_ts,
        siac_r_movgest_bil_elem					r_mov_gest_bil_elem,
        siac_t_bil_elem							bil_elem
    where movgest_ts.movgest_id=movgest.movgest_id
    	and movgest_ts.movgest_ts_id=r_richiesta_movgest.movgest_ts_id
        and r_mov_gest_bil_elem.movgest_id=movgest.movgest_id
        and bil_elem.elem_id=r_mov_gest_bil_elem.elem_id
        and r_richiesta_movgest.ente_proprietario_id ='||p_ente_prop_id||'
        AND r_richiesta_movgest.data_cancellazione IS NULL  
        AND movgest.data_cancellazione IS NULL    
        AND movgest_ts.data_cancellazione IS NULL    
        AND r_mov_gest_bil_elem.data_cancellazione IS NULL    
        AND bil_elem.data_cancellazione IS NULL)  
select num_capitolo::varchar, 
		num_articolo::varchar, 
        ueb::varchar, 
        anno_impegno::integer, 
        num_impegno::varchar,
        descr_impegno::varchar,
		num_sub_impegno::varchar, 
        num_movimento::integer,
        tipo_richiesta::varchar, 
        num_sospeso::integer,
        --COALESCE(num_sospeso::varchar,'''')::varchar num_sospeso,
        data_movimento::date,
        data_richiesta::date, 
        COALESCE(matricola,'''')::varchar matricola,      
        nominativo::varchar nominativo,           
        COALESCE(descr_richiesta,'''')::varchar descr_richiesta,
        CASE WHEN gst_id IS NULL 
        	THEN imp_richiesta::numeric
            ELSE
            	CASE WHEN rend_importo_restituito > 0
                	THEN -rend_importo_restituito::numeric
                    ELSE rend_importo_integrato::numeric end
                end imp_richiesta, 
        code_tipo_richiesta::varchar ,
        CASE WHEN code_tipo_richiesta = ''RIMBORSO_SPESE'' 
        	THEN ''R''::varchar
            ELSE ''A''::varchar end tipo,
        CASE WHEN gst_id IS NULL 
        	THEN ''''::varchar
            ELSE ''R''::varchar end rendicontato
	from ele_movimenti_cassa
    	left join ele_movimenti_cap on ele_movimenti_cap.ricecon_id = ele_movimenti_cassa.ricecon_id        
    ORDER BY num_capitolo, num_articolo, ueb, anno_impegno, num_impegno';  

raise notice '%', sql_query;
return query execute sql_query;


exception
	when no_data_found THEN
		raise notice 'movimenti non trovati' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura dei movimenti non rendicontati ';
        RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;