/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza_txt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  attoamm_id integer,
  attoamm_anno varchar,
  attoamm_numero integer,
  tipo_atto varchar,
  attoamm_oggetto varchar,
  data_provv_var timestamp,
  data_approvazione_provv timestamp,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  tipo_capitolo varchar
) AS
$body$
DECLARE

DataSetAtti record;
contaRec integer;

annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione


titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;

    
/* Funzione nata per la SIAC-7195 per la gestione dei file in formato testo 
	per Unicredit.
    La funzione estrae i dati delle variazioni di entata del report BILR149 
    e del relativo atto.
    Resituisce solo i dati di stanziamento e le variazioni sono 
    quelle in bozza.

  SIAC-8217 31/05/2021.
   Tolto il filtro sulla tipologia del capitolo perche' i dati dei 
   capitoli devono essere sempre estratti in modo da fare match con i 
   capitoli coinvolti nella variazione.
   Inoltre la tipologia di capitolo e' stata aggiunta ai dati di output.    
*/


select a.bil_id 
	into bilancio_id 
from siac_t_bil a,
		siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno
    and a.data_cancellazione IS NULL
    and b.data_cancellazione IS NULL;
    
raise notice '1 - %' , clock_timestamp()::text;

	--preparo la query
strQuery:='          
with atti as(select	atto.attoamm_anno, atto.attoamm_numero,
			tipo_atto.attoamm_tipo_code, atto.attoamm_oggetto,
			dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo) importo_var,        
            tipo_elemento.elem_det_tipo_code tipo_importo,            
            '''||p_anno_competenza||''',
            atto.attoamm_id, atto.data_creazione data_provv_var,
            r_atto_stato.data_creazione data_approvazione_provv	      	
    from 	siac_t_atto_amm 			atto,
            siac_d_atto_amm_tipo		tipo_atto,
            siac_r_atto_amm_stato 		r_atto_stato,
            siac_d_atto_amm_stato 		stato_atto,
            siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_importi
    where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    and		r_atto_stato.attoamm_id								=	atto.attoamm_id
    and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
    and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
                r_variazione_stato.attoamm_id_varbil   				=	atto.attoamm_id )
    and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	atto.ente_proprietario_id 							= 	'||p_ente_prop_id ||'
    and 	testata_variazione.bil_id							=   '||bilancio_id;
    if p_numero_delibera IS NOT NULL THEN
    	strQuery:=strQuery|| ' and	atto.attoamm_numero 	= 	'||p_numero_delibera||'
    		and		atto.attoamm_anno						=	'''||p_anno_delibera||'''
    		and		tipo_atto.attoamm_tipo_code				=	'''||p_tipo_delibera||'''';
   else
    	strQuery:=strQuery|| ' and		testata_variazione.variazione_num		in('||p_ele_variazioni||') ';
    end if;
       
    strQuery:=strQuery|| ' and		anno_importi.anno		= 	'''||p_anno_competenza||'''					
 	--10/10/2022 SIAC-8827  Aggiunto lo stato BD.
    and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'',''BD'')
    and		tipo_capitolo.elem_tipo_code					=	'''||elemTipoCode||'''
    and		tipo_elemento.elem_det_tipo_code				in (''STA'')
    and		atto.data_cancellazione						is null
    and		tipo_atto.data_cancellazione				is null
    and		r_atto_stato.data_cancellazione				is null
    and		stato_atto.data_cancellazione				is null
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    group by 	atto.attoamm_anno, atto.attoamm_numero,tipo_atto.attoamm_tipo_code,
    			atto.attoamm_oggetto, dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
            	atto.attoamm_id, atto.data_creazione, r_atto_stato.data_creazione),
 capitoli as (select cl.classif_id categoria_id,
              '''||p_anno||''' anno_bilancio,
              capitolo.elem_code, capitolo.elem_code2,
              capitolo.elem_desc, capitolo.elem_desc2,
              capitolo.elem_id, capitolo.elem_id_padre,
              cat_del_capitolo.elem_cat_code
             from 	siac_r_bil_elem_class rc,
                    siac_t_bil_elem capitolo,
                    siac_d_class_tipo ct,
                    siac_t_class cl,
                    siac_d_bil_elem_tipo tipo_elemento, 
                    siac_d_bil_elem_stato stato_capitolo,
                    siac_r_bil_elem_stato r_capitolo_stato,
                    siac_d_bil_elem_categoria cat_del_capitolo,
                    siac_r_bil_elem_categoria r_cat_capitolo
            where ct.classif_tipo_id				=	cl.classif_tipo_id
            and cl.classif_id					=	rc.classif_id 
            and capitolo.elem_tipo_id			=	tipo_elemento.elem_tipo_id 
            and capitolo.elem_id				=	rc.elem_id 
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo.ente_proprietario_id	=	'||p_ente_prop_id||'
            and capitolo.bil_id					=   '||bilancio_id||'
            and ct.classif_tipo_code				=	''CATEGORIA''           
            and tipo_elemento.elem_tipo_code 	=	'''||elemTipoCode||'''    
            and	stato_capitolo.elem_stato_code	=	''VA'' 
            --SIAC-8217: tolto il filtro.        
            --and	cat_del_capitolo.elem_cat_code	=	''STD''
            and capitolo.data_cancellazione 		is null
            and	r_capitolo_stato.data_cancellazione	is null
            and	r_cat_capitolo.data_cancellazione	is null
            and	rc.data_cancellazione				is null
            and	ct.data_cancellazione 				is null
            and	cl.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione	is null
            and	stato_capitolo.data_cancellazione 	is null
            and	cat_del_capitolo.data_cancellazione	is null),               
	strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_entrate"('||p_ente_prop_id||',
                				'''||p_anno||''',''''))
    select atti.attoamm_id::integer attoamm_id, 
    	  atti.attoamm_anno::varchar attoamm_anno,
    	  atti.attoamm_numero::integer attoamm_numero,
          atti.attoamm_tipo_code::varchar tipo_atto,
          atti.attoamm_oggetto::varchar attoamm_oggetto,
          atti.data_provv_var::timestamp data_provv_var,
          atti.data_approvazione_provv::timestamp data_approvazione_provv,
          ''''::varchar titoloe_tipo_code ,
          strutt_bilancio.classif_tipo_desc1::varchar titoloe_tipo_desc,
          strutt_bilancio.titolo_code::varchar titoloe_code,
          strutt_bilancio.titolo_desc::varchar titoloe_desc,
          ''''::varchar tipologia_tipo_code,
          strutt_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
          strutt_bilancio.tipologia_code::varchar tipologia_code,
          strutt_bilancio.tipologia_desc::varchar tipologia_desc,
          ''''::varchar categoria_tipo_code,
          strutt_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
          strutt_bilancio.categoria_code::varchar categoria_code,
          strutt_bilancio.categoria_desc::varchar categoria_desc,
          capitoli.elem_code::varchar bil_ele_code,
          capitoli.elem_desc::varchar bil_ele_desc,
          capitoli.elem_code2::varchar bil_ele_code2,
          capitoli.elem_desc2::varchar bil_ele_desc2,
          capitoli.elem_id::integer bil_ele_id,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.importo_var >= 0 then
                	COALESCE(atti.importo_var, 0)::numeric
                else 0::numeric end variazione_aumento_stanziato,
          case when atti.tipo_importo = '''||TipoImpComp||''' --STA
          		and atti.importo_var <0 then
                	COALESCE(atti.importo_var *-1, 0)::numeric
                else 0::numeric end  variazione_diminuzione_stanziato,
          COALESCE(capitoli.elem_cat_code,'''')         
    from atti
    	LEFT JOIN capitoli
        	ON atti.elem_id = capitoli.elem_id
        LEFT JOIN strutt_bilancio
        	ON strutt_bilancio.categoria_id = capitoli.categoria_id ';

raise notice 'strQuery = % ', strQuery;     

return query execute strQuery ;

raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'nessun atto trovato' ;
        attoamm_id := NULL;
        return next;
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza_txt" (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar)
  OWNER TO siac;