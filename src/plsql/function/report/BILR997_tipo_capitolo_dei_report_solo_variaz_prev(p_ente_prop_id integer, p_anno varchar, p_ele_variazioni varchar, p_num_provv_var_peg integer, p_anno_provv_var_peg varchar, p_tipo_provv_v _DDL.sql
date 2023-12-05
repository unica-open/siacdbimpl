/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR997_tipo_capitolo_dei_report_solo_variaz_prev" (
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
  p_code_sac_sett_bil varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar,
  tipo_capitolo_cod varchar
) AS
$body$
DECLARE

 /* 21/05/2021. SIAC-8000.
 	Questa funzione nasce come copia della BILR997_tipo_capitolo_dei_report_solo_variaz
    ma lavora sui capitoli di previsione.    
*/         
         
classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
tipoFpv varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';
sql_query VARCHAR;
user_table	varchar;
elemTipoCode VARCHAR;
elemCatCode  VARCHAR;
variazione_aumento_stanziato NUMERIC;
variazione_diminuzione_stanziato NUMERIC;
variazione_aumento_cassa NUMERIC;
variazione_diminuzione_cassa NUMERIC;
variazione_aumento_residuo NUMERIC;
variazione_diminuzione_residuo NUMERIC;


annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
contaParVarPeg integer;
contaParVarBil integer;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';
tipoFpv='FPV'; 
tipo_capitolo_cod='';


elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 


variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

contaParVarPeg:=0;
contaParVarBil:=0;

if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;
select fnc_siac_random_user()
into	user_table;


insert into siac_rep_cap_ep
select --cl.classif_id,
  NULL,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	
 		siac_t_bil_elem e,

        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCodeE
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());

IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;
    sql_query=sql_query||'  where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeE|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO''
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
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
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query Var Entrate: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
      union 
         select  tb0.elem_id,   
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
        union 
        select  tb0.elem_id,    
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);



insert into siac_rep_cap_ug 
select 	NULL, --programma.classif_id,
		NULL, --macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCodeS						     	and 
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	
    
    
sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;                      
    
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeS|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO''  
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    
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
    
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione	is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;


   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         )
        where  tb0.utente = user_table    ; 
        
        
end if;

    
for tipo_capitolo in
        select t0.*               
			from "BILR000_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno, 'P') t0
            	ORDER BY t0.anno_competenza
loop

importo:=0;

elemCatCode= tipo_capitolo.codice_importo;

IF tipo_capitolo.tipo_capitolo_cod =elemTipoCodeE THEN  
	--Cerco i dati delle eventuali variazioni di entrata
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;      
	
--16/03/2017: nel caso di capitoli FPV di entrata devo sommare gli importi
--	dei capitoli FPVSC e FPVCC.
		if tipo_capitolo.codice_importo = 'FPV' then
              --raise notice 'tipo_capitolo.codice_importo=%', variazione_diminuzione_stanziato;
              select      'FPV' elem_cat_code , 
                  coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                  coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                  coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                  coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                  coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                  coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
              into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                  variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
              variazione_diminuzione_residuo 
              from siac_rep_var_entrate_riga t1,
                  siac_r_bil_elem_categoria r_cat_capitolo,
                  siac_d_bil_elem_categoria cat_del_capitolo            
              WHERE  r_cat_capitolo.elem_id=t1.elem_id
                  AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                  AND t1.utente=user_table
                  AND cat_del_capitolo.elem_cat_code in (tipoFpvcc, tipoFpvsc)
                  AND r_cat_capitolo.data_cancellazione IS NULL
                  AND cat_del_capitolo.data_cancellazione IS NULL
                  AND t1.periodo_anno = tipo_capitolo.anno_competenza
             -- 17/07/2017: commentata la group by per jira SIAC-5105
             	--group by  elem_cat_code  
             ;             
            IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
            end if;
            
            raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
            raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
              /* 
                  SIAC-7211 e SIAC-7212.
                  L'importo restituito deve contenere solo l'importo dei capitoli variati.
              */
            --importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            else 


               select      cat_del_capitolo.elem_cat_code,
                    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                    coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                    coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                    coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                    coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                    coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
                into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                    variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
                variazione_diminuzione_residuo 
                from siac_rep_var_entrate_riga t1,
                    siac_r_bil_elem_categoria r_cat_capitolo,
                    siac_d_bil_elem_categoria cat_del_capitolo            
                WHERE  r_cat_capitolo.elem_id=t1.elem_id
                    AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                    AND t1.utente=user_table
                    AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                    AND r_cat_capitolo.data_cancellazione IS NULL
                    AND cat_del_capitolo.data_cancellazione IS NULL
                    AND t1.periodo_anno = tipo_capitolo.anno_competenza
                group by cat_del_capitolo.elem_cat_code   ; 
                
                IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
                ELSE                
                  
              /* 
                  SIAC-7211 e SIAC-7212.
                  L'importo restituito deve contenere solo l'importo dei capitoli variati.
              */                   
                  IF elemCatCode = tipoFCassaIni THEN                 
                      --importo =tipo_capitolo.importo+variazione_aumento_cassa+variazione_diminuzione_cassa;  
                      importo =variazione_aumento_cassa+variazione_diminuzione_cassa;  
                  ELSE         
                      --importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                      importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                  END IF;
              
            end if;  
                  
            END IF;     
            
ELSE  --Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;
	select      cat_del_capitolo.elem_cat_code,
			    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                               
			into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
            	variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
			variazione_diminuzione_residuo 
            from siac_rep_var_spese_riga t1,
            	siac_r_bil_elem_categoria r_cat_capitolo,
                siac_d_bil_elem_categoria cat_del_capitolo            
            WHERE  r_cat_capitolo.elem_id=t1.elem_id
            	AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	AND t1.utente=user_table
                AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                AND r_cat_capitolo.data_cancellazione IS NULL
                AND cat_del_capitolo.data_cancellazione IS NULL
                AND t1.periodo_anno = tipo_capitolo.anno_competenza
            group by cat_del_capitolo.elem_cat_code   ; 
            IF NOT FOUND THEN
              variazione_aumento_stanziato=0;
              variazione_diminuzione_stanziato=0;
              variazione_aumento_cassa=0;
              variazione_diminuzione_cassa=0;
              variazione_aumento_residuo=0;
              variazione_diminuzione_residuo=0;
            ELSE
            	importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato;               
            END IF;                    
END IF;
            
--raise notice 'anno_competenza=%', tipo_capitolo.anno_competenza;
--raise notice 'codice_importo=%', tipo_capitolo.codice_importo;
--raise notice 'importo=%', tipo_capitolo.importo;
--raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
--raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
--raise notice 'variazione_aumento_cassa=%', variazione_aumento_cassa;
--raise notice 'variazione_diminuzione_cassa=%', variazione_diminuzione_cassa;
--raise notice 'variazione_aumento_residuo=%', variazione_aumento_residuo;
--raise notice 'variazione_diminuzione_residuo=%', variazione_diminuzione_residuo;


anno_competenza = tipo_capitolo.anno_competenza;
descrizione = tipo_capitolo.descrizione;
posizione_nel_report = tipo_capitolo.posizione_nel_report;
codice_importo = tipo_capitolo.codice_importo;
tipo_capitolo_cod = tipo_capitolo.tipo_capitolo_cod;

return next;

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_competenza = '';
descrizione = '';
posizione_nel_report = 0;
codice_importo = '';
tipo_capitolo_cod = '';
importo=0;

end loop;


delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

delete from siac_rep_var_spese where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;