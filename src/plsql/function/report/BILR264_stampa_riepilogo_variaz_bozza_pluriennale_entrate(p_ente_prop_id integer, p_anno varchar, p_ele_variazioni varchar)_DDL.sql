/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR264_stampa_riepilogo_variaz_bozza_pluriennale_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
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
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  stanziamento_anno1 numeric,
  variazione_aumento_stanziato_anno1 numeric,
  variazione_diminuzione_stanziato_anno1 numeric,
  stanziamento_anno2 numeric,
  variazione_aumento_stanziato_anno2 numeric,
  variazione_diminuzione_stanziato_anno2 numeric,
  anno_riferimento varchar,
  ente_denominazione varchar,
  display_error varchar,
  tipo varchar
) AS
$body$
DECLARE

classifBilRec record;


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
sql_query varchar;
bilancio_id integer;
annoCapImp1 varchar;
annoCapImp2 varchar;
nome_ente varchar;

BEGIN

/* 
  30/05/2023 - Procedura nata per il report BILR264 per la SIAC-8857.
  Nasce come copia dela "BILR241_stampa_variazione_bozza_pluriennale_entrate" per estrarre i dati di entrata delle variazioni 
  in bozza fornite in input sui 3 anni.
  I dati che interessano al report sono solo gli stanziamenti per capitolo ma sono estratti anche i dati di cassa e residuo.
  Il report fornisce anche il campo "tipo" dove viene riportato se il capitolo e' tipo "Parte corrente" o "Parte capitale) 
  (valori: corrente/capitale).
  Le regole fornite per questa suddivisione sono:
  - Parte corrente = capitoli dei titoli 1, 2 e 3;
  - Parte capitale = capitoli del titolo 4.
  La procedura fornisce le informazioni anche dei capitoli degli altri titoli come "altro"; e' il report che si occupa di
  filtrare i dati di interesse.

*/

annoCapImp:= p_anno; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
annocapimp1:=(p_anno::INTEGER + 1)::varchar;
annocapimp2:=(p_anno::INTEGER + 2)::varchar;

elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;

bil_anno='';
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
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
ente_denominazione ='';
display_error='';

select fnc_siac_random_user()
into	user_table;

select bilancio.bil_id
	into bilancio_id
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc
where bilancio.periodo_id=anno_eserc.periodo_id
	and bilancio.ente_proprietario_id=p_ente_prop_id
    and anno_eserc.anno=p_anno
    and bilancio.data_cancellazione IS NULL    
    and anno_eserc.data_cancellazione IS NULL;
    

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;
    
select a.ente_denominazione
into nome_ente
from siac_t_ente_proprietario a
where a.ente_proprietario_id=p_ente_prop_id
    and a.data_cancellazione IS NULL;
        
 RTN_MESSAGGIO:='Estrazione delle variazioni.';  

sql_query='insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, '''; 
sql_query=sql_query ||user_table||''' utente, 
        testata_variazione.ente_proprietario_id	,
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
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id 
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id  
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id ';
sql_query=sql_query ||' and		tipo_capitolo.elem_tipo_code =	'''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||''''; 												
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';  
--10/10/2022 SIAC-8827  Aggiunto lo stato BD.
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''B'',''G'', ''C'', ''P'', ''BD'')
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno'  ;    
            
raise notice 'sql_query = %',sql_query;
                    
EXECUTE sql_query;

 RTN_MESSAGGIO:='Estrazione degli importi dei capitoli.'; 
 
 INSERT INTO siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,   
            sum(capitolo_importi.elem_det_importo)    importo_cap 
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
    	and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and capitolo_importi.ente_proprietario_id = p_ente_prop_id  																			
        and	capitolo.bil_id						=	bilancio_id 			  						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode        
		and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
    
 RTN_MESSAGGIO:='Return dei dati.';     
return QUERY
with strutt_bilancio as (select * 
		from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,'')),
capitoli as (select cl.classif_id,
          p_anno anno_bilancio,
          e.*
         from 	siac_r_bil_elem_class rc,
                siac_t_bil_elem e,
                siac_d_class_tipo ct,
                siac_t_class cl,
                siac_d_bil_elem_tipo tipo_elemento, 
                siac_d_bil_elem_stato stato_capitolo,
                siac_r_bil_elem_stato r_capitolo_stato,
                siac_d_bil_elem_categoria cat_del_capitolo,
                siac_r_bil_elem_categoria r_cat_capitolo
        where ct.classif_tipo_id				=	cl.classif_tipo_id
        and cl.classif_id					=	rc.classif_id 
        and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
        and e.elem_id						=	rc.elem_id 
        and	e.elem_id						=	r_capitolo_stato.elem_id
        and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
        and	e.elem_id						=	r_cat_capitolo.elem_id
        and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        and ct.classif_tipo_code			=	'CATEGORIA'
        and e.ente_proprietario_id=p_ente_prop_id
        and e.bil_id						=	bilancio_id 
        and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
        and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
        and e.data_cancellazione 				is null
        and	r_capitolo_stato.data_cancellazione	is null
        and	r_cat_capitolo.data_cancellazione	is null
        and	rc.data_cancellazione				is null
        and	ct.data_cancellazione 				is null
        and	cl.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione	is null
        and	stato_capitolo.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione	is null
   UNION  -- Unisco i capitoli senza struttura
    select null,
        p_anno anno_bilancio,
        e.*
       from 	
              siac_t_bil_elem e,              
              siac_d_bil_elem_tipo tipo_elemento, 
              siac_d_bil_elem_stato stato_capitolo,
              siac_r_bil_elem_stato r_capitolo_stato
      where e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
      and	e.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
      and e.ente_proprietario_id			= 	p_ente_prop_id
      and e.bil_id						=	bilancio_id       
      and tipo_elemento.elem_tipo_code 	= 	elemTipoCode      								
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
      and e.data_cancellazione 				is null
      and r_capitolo_stato.data_cancellazione	is null
      and tipo_elemento.data_cancellazione	is null
      and stato_capitolo.data_cancellazione 	is null
      and not EXISTS (select 1
      		from siac_d_class_tipo a,
     				siac_t_class b,
                     siac_r_bil_elem_class x
            where a.classif_tipo_id=b.classif_tipo_id
            	and b.classif_id=x.classif_id
            	and x.elem_id = e.elem_id
                and a.classif_tipo_code='CATEGORIA')),
		importi_stanz_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_cassa_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui_anno as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),   
         variaz_cassa_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario = p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_cassa_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_residui_pos_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id 
                        and a.periodo_anno=p_anno                       
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo > 0
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_residui_neg_anno as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo < 0
                        and a.utente=user_table
                        group by  a.elem_id) ,
		importi_stanz_anno1 as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),   
      	variaz_stanz_pos_anno1 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno1 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp1
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),     
		importi_stanz_anno2 as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),   
      	variaz_stanz_pos_anno2 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg_anno2 as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=annocapimp2
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id)    
select  p_anno::varchar bil_anno,
        ''::varchar titoloe_tipo_code,
        strutt_bilancio.classif_tipo_desc1::varchar titoloe_tipo_desc,
		strutt_bilancio.titolo_code::varchar titoloe_code,
        strutt_bilancio.titolo_desc::varchar titoloe_desc,
		''::varchar tipologia_tipo_code,
        strutt_bilancio.classif_tipo_desc2::varchar tipologia_tipo_desc,
        strutt_bilancio.tipologia_code::varchar tipologia_code,
        strutt_bilancio.tipologia_desc::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        strutt_bilancio.classif_tipo_desc3::varchar categoria_tipo_desc,
        strutt_bilancio.categoria_code::varchar categoria_code,
        strutt_bilancio.categoria_desc::varchar categoria_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre, 
		COALESCE(importi_stanz_anno.importo_cap,0)::numeric stanziamento,
        COALESCE(importi_cassa_anno.importo_cap,0)::numeric cassa_anno,
        COALESCE(importi_residui_anno.importo_cap,0)::numeric residuo_anno,
        COALESCE(variaz_stanz_pos_anno.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos_anno.importo_var,0)::numeric variazione_aumento_cassa,
        COALESCE(variaz_cassa_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos_anno.importo_var,0)::numeric variazione_aumento_residuo_anno,
        COALESCE(variaz_residui_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_residuo_anno,
        COALESCE(importi_stanz_anno1.importo_cap,0)::numeric stanziamento_anno1,
        COALESCE(variaz_stanz_pos_anno1.importo_var,0)::numeric variazione_aumento_stanziato_anno1,
        COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno1,
        COALESCE(importi_stanz_anno2.importo_cap,0)::numeric stanziamento_anno2,
        COALESCE(variaz_stanz_pos_anno2.importo_var,0)::numeric variazione_aumento_stanziato_anno2,
        COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno2,        
        p_anno::varchar  anno_riferimento,
        nome_ente::varchar ente_denominazione,
        ''::varchar display_error,                   
        case when strutt_bilancio.titolo_code in('1','2','3') 
        	then 'corrente'::varchar
            else case when strutt_bilancio.titolo_code in('4') 
            	then 'capitale'::varchar
                else 'altro'::varchar end 
            end tipo         
from strutt_bilancio
      LEFT JOIN capitoli
          ON strutt_bilancio.categoria_id = capitoli.classif_id
      LEFT JOIN importi_stanz_anno
          ON importi_stanz_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_cassa_anno
          ON importi_cassa_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_residui_anno
          ON importi_residui_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_pos_anno
          ON variaz_stanz_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno
          ON variaz_stanz_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_pos_anno
          ON variaz_cassa_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_neg_anno
          ON variaz_cassa_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_pos_anno
          ON variaz_residui_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_neg_anno
          ON variaz_residui_neg_anno.elem_id = capitoli.elem_id
	  LEFT JOIN importi_stanz_anno1
          ON importi_stanz_anno1.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno1
          ON variaz_stanz_pos_anno1.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno1
          ON variaz_stanz_neg_anno1.elem_id = capitoli.elem_id     
	  LEFT JOIN importi_stanz_anno2
          ON importi_stanz_anno2.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno2
          ON variaz_stanz_pos_anno2.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno2
          ON variaz_stanz_neg_anno2.elem_id = capitoli.elem_id            
where capitoli.elem_id is not null
 and exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb,
                        siac_rep_cap_eg_imp cc
        			where bb.elem_id =cc.elem_id
                    	and bb.classif_id = aa.classif_id
                 		--and aa.classif_id_padre = strutt_bilancio.titusc_id 
                      --  and bb.programma_id=strutt_bilancio.categoria_id
                        and cc.utente=user_table) 
UNION
select  p_anno::varchar bil_anno,
        ''::varchar titoloe_tipo_code,
        'Titolo'::varchar titoloe_tipo_desc,
		'0'::varchar titoloe_code,
        ' '::varchar titoloe_desc,
		''::varchar tipologia_tipo_code,
        'Tipologia'::varchar tipologia_tipo_desc,
        '0000000'::varchar tipologia_code,
        ' '::varchar tipologia_desc,
        ''::varchar categoria_tipo_code,
        'Categoria'::varchar categoria_tipo_desc,
        '0000000'::varchar categoria_code,
        ' '::varchar categoria_desc,
        capitoli.elem_code::varchar bil_ele_code ,
        capitoli.elem_desc::varchar bil_ele_desc,
        capitoli.elem_code2::varchar bil_ele_code2,
        capitoli.elem_desc2::varchar bil_ele_desc2,
        capitoli.elem_id::integer bil_ele_id,
        capitoli.elem_id_padre::integer bil_ele_id_padre, 
		COALESCE(importi_stanz_anno.importo_cap,0)::numeric stanziamento,
        COALESCE(importi_cassa_anno.importo_cap,0)::numeric cassa_anno,
        COALESCE(importi_residui_anno.importo_cap,0)::numeric residuo_anno,
        COALESCE(variaz_stanz_pos_anno.importo_var,0)::numeric variazione_aumento_stanziato,
        COALESCE(variaz_stanz_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
        COALESCE(variaz_cassa_pos_anno.importo_var,0)::numeric variazione_aumento_cassa,
        COALESCE(variaz_cassa_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
        COALESCE(variaz_residui_pos_anno.importo_var,0)::numeric variazione_aumento_residuo,
        COALESCE(variaz_residui_neg_anno.importo_var *-1,0)::numeric variazione_diminuzione_residuo_anno,
        COALESCE(importi_stanz_anno1.importo_cap,0)::numeric stanziamento_anno1,
        COALESCE(variaz_stanz_pos_anno1.importo_var,0)::numeric variazione_aumento_stanziato_anno1,
        COALESCE(variaz_stanz_neg_anno1.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno1,
        COALESCE(importi_stanz_anno2.importo_cap,0)::numeric stanziamento_anno2,
        COALESCE(variaz_stanz_pos_anno2.importo_var,0)::numeric variazione_aumento_stanziato_anno2,
        COALESCE(variaz_stanz_neg_anno2.importo_var *-1,0)::numeric variazione_diminuzione_stanziato_anno2,        
        p_anno::varchar  anno_riferimento,
        nome_ente::varchar ente_denominazione,
        ''::varchar display_error,                  
            'altro'::varchar tipo            
from capitoli
      LEFT JOIN importi_stanz_anno
          ON importi_stanz_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_cassa_anno
          ON importi_cassa_anno.elem_id = capitoli.elem_id
      LEFT JOIN importi_residui_anno
          ON importi_residui_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_pos_anno
          ON variaz_stanz_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno
          ON variaz_stanz_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_pos_anno
          ON variaz_cassa_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_cassa_neg_anno
          ON variaz_cassa_neg_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_pos_anno
          ON variaz_residui_pos_anno.elem_id = capitoli.elem_id
      LEFT JOIN variaz_residui_neg_anno
          ON variaz_residui_neg_anno.elem_id = capitoli.elem_id
	  LEFT JOIN importi_stanz_anno1
          ON importi_stanz_anno1.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno1
          ON variaz_stanz_pos_anno1.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno1
          ON variaz_stanz_neg_anno1.elem_id = capitoli.elem_id     
	  LEFT JOIN importi_stanz_anno2
          ON importi_stanz_anno2.elem_id = capitoli.elem_id	
      LEFT JOIN variaz_stanz_pos_anno2
          ON variaz_stanz_pos_anno2.elem_id = capitoli.elem_id
      LEFT JOIN variaz_stanz_neg_anno2
          ON variaz_stanz_neg_anno2.elem_id = capitoli.elem_id            
where capitoli.elem_id is not null
and not EXISTS (select 1
      		from siac_d_class_tipo a,
     				siac_t_class b,
                     siac_r_bil_elem_class x
            where a.classif_tipo_id=b.classif_tipo_id
            	and b.classif_id=x.classif_id
            	and x.elem_id = capitoli.elem_id
                and x.ente_proprietario_id = p_ente_prop_id
                and a.classif_tipo_code='CATEGORIA');                                               


delete from siac_rep_cap_eg_imp where utente=user_table;
delete from	siac_rep_var_entrate	where utente=user_table;




raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'Variazioni non trovate' ;
		--return next;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
	when others  THEN
		--raise notice 'errore nella lettura delle variazioni ';
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

ALTER FUNCTION siac."BILR264_stampa_riepilogo_variaz_bozza_pluriennale_entrate" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar)
  OWNER TO siac;