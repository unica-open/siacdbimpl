/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_variazioni_bozza (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar,
  p_contaparvarpeg integer,
  p_contaparvarbil integer,
  p_elemtipocode varchar
)
RETURNS TABLE (
  elem_id integer,
  imp_variazioni numeric,
  tipo_capitolo varchar,
  tipo_elem_det varchar,
  anno_variazioni varchar
) AS
$body$
DECLARE

sql_query VARCHAR;
elemTipoCode varchar;
elencoVariazioni record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN

IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 p_contaParVarPeg= 3 OR p_contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
     
    elemTipoCode := p_elemTipoCode; 
     
    sql_query='
    with variazioni as (
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo) imp_variazioni,
            cat_del_capitolo.elem_cat_code,
            tipo_elemento.elem_det_tipo_code,  ';
    
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_r_bil_elem_categoria 	r_cat_capitolo,      
	 		siac_d_bil_elem_categoria	cat_del_capitolo,     		      
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';     
                   
    IF p_contaParVarPeg = 3 THEN 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    END IF;
    
    IF p_contaParVarBil = 3 THEN 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    END IF;
    
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;
    
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id    
    and	    capitolo.elem_id				                    =	r_cat_capitolo.elem_id				
	and	    r_cat_capitolo.elem_cat_id		                    =	cat_del_capitolo.elem_cat_id    
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id '; 
    
    IF p_contaParVarPeg = 3 THEN 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    END IF;
    
    IF p_contaParVarBil = 3 THEN 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    END IF;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    
    sql_query=sql_query||' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    --10/10/2022 SIAC-8827  Aggiunto lo stato BD.
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'', ''BD'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    END IF;
    
    IF p_contaParVarPeg = 3 THEN 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    END IF;
    
    IF p_contaParVarBil = 3 THEN 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    END IF;
    
    IF p_code_sac_direz_peg <> '999' THEN
    
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
        
    END IF;
    
    IF p_code_sac_direz_bil <> '999' THEN
    
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
        
    END IF;
    
    sql_query=sql_query || ' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
 
    IF p_contaParVarPeg = 3 THEN 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    END IF;
    
    IF p_contaParVarBil = 3 THEN 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    END IF;
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                cat_del_capitolo.elem_cat_code,
                tipo_elemento.elem_det_tipo_code,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno
                )
                select variazioni.elem_id::integer,
                variazioni.imp_variazioni::numeric,
                variazioni.elem_cat_code::varchar,
                variazioni.elem_det_tipo_code::varchar,
                variazioni.anno::varchar
                from variazioni';                       
     
ELSE

sql_query = ' select
              null::integer as elem_id,
              null::numeric as imp_variazioni,
              null::varchar as tipo_capitolo,
              null::varchar as tipo_elem_det,
              null::varchar as anno_variazioni';    
     
END IF;    
       
raise notice 'Query: % ',  sql_query; 

return query execute sql_query;

raise notice 'fine OK';

exception     
	when others  THEN
        RTN_MESSAGGIO:='Errore Variazioni';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_variazioni_bozza (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_num_provv_var_peg integer, p_anno_provv_var_peg varchar, p_tipo_provv_var_peg varchar, p_num_provv_var_bil integer, p_anno_provv_var_bil varchar, p_tipo_provv_var_bil varchar, p_code_sac_direz_peg varchar, p_code_sac_sett_peg varchar, p_code_sac_direz_bil varchar, p_code_sac_sett_bil varchar, p_contaparvarpeg integer, p_contaparvarbil integer, p_elemtipocode varchar)
  OWNER TO siac;