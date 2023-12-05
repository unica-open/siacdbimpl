/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR093_elenco_capitoli_spesa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_tipo_capitolo varchar,
  p_tipo varchar
)
RETURNS TABLE (
  nome_ente varchar,
  bil_anno varchar,
  tipo_capitolo_pg varchar,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  ueb varchar,
  descr_capitolo varchar,
  descr_articolo varchar,
  cod_missione varchar,
  descr_missione varchar,
  cod_programma varchar,
  descr_programma varchar,
  cod_titolo varchar,
  descr_titolo varchar,
  cod_cofog varchar,
  descr_cofog varchar,
  cod_macroaggr varchar,
  descr_macroaggr varchar,
  siope varchar,
  descr_strutt_amm varchar,
  tipo_capitolo varchar,
  impegnabile varchar,
  cassa_anno numeric,
  cassa_anno1 numeric,
  cassa_anno2 numeric,
  cassa_iniz_anno numeric,
  cassa_iniz_anno1 numeric,
  cassa_iniz_anno2 numeric,
  residuo_anno numeric,
  residuo_anno1 numeric,
  residuo_anno2 numeric,
  residuo_iniz_anno numeric,
  residuo_iniz_anno1 numeric,
  residuo_iniz_anno2 numeric,
  stanziamento_anno numeric,
  stanziamento_anno1 numeric,
  stanziamento_anno2 numeric,
  stanziamento_iniz_anno numeric,
  stanziamento_iniz_anno1 numeric,
  stanziamento_iniz_anno2 numeric,
  pdc_finanziario varchar,
  disp_stanz_anno numeric,
  disp_stanz_anno1 numeric,
  disp_stanz_anno2 numeric
) AS
$body$
DECLARE
classifBilRec record;
elencoAttrib	record;
elencoClass	record;
elencoDispon record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;

annoCapImp_int integer;

TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpResiduo varchar;

TipoImpstanzresiduiIniz varchar;
tipoImpCassaIniz varchar;
TipoImpstanzIniz varchar;	

sett_code varchar;
sett_descr varchar;
classif_id_padre integer;
direz_code	varchar;
direz_descr varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
ente_prop varchar;
bilancio_id integer;

BEGIN

  annoCapImp_int:= p_anno::integer; 
  annoCapImp:= p_anno;
  annoCapImp1:= (annoCapImp_int+1) ::varchar;
  annoCapImp2:= (annoCapImp_int+2) ::varchar;
   
/* METTERE ANCHE GLI IMPORTI GIA' SPESI (DA CALCOLARE)

*/

	TipoImpstanz='STA'; 		-- stanziamento  (CP)
    TipoImpCassa ='SCA'; 		----- cassa	(CS)
    TipoImpResiduo='STR';	-- stanziamento residuo
    
    
    TipoImpstanzresiduiIniz='SRI'; 	-- stanziamento residuo iniziale (RS)
    tipoImpCassaIniz='SCI';			--Stanziamento Cassa Iniziale
    TipoImpstanzIniz='STI';			--Stanziamento  Iniziale

	nome_ente='';
    bil_anno='';
    tipo_capitolo_pg='';    
    anno_capitolo=0;
    cod_capitolo='';
    cod_articolo='';
    ueb='';
    descr_capitolo='';
    descr_articolo='';
    cod_missione='';
    descr_missione='';
    cod_programma='';
    descr_programma='';
    cod_titolo='';
    descr_titolo='';
    cod_cofog='';
    descr_cofog='';
    cod_macroaggr='';
    descr_macroaggr='';
    siope='';

    descr_strutt_amm='';
    tipo_capitolo='';
    impegnabile='';
	cassa_anno=0;
    cassa_anno1=0;
    cassa_anno2=0;
    cassa_iniz_anno=0;	
    cassa_iniz_anno1=0;		
    cassa_iniz_anno2=0;	
    residuo_anno=0;	
    residuo_anno1=0;
    residuo_anno2=0;
    residuo_iniz_anno=0;
    residuo_iniz_anno1=0;
    residuo_iniz_anno2=0;
    stanziamento_anno=0;
    stanziamento_anno1=0;
    stanziamento_anno2=0;
    stanziamento_iniz_anno=0;
    stanziamento_iniz_anno1=0;
    stanziamento_iniz_anno2=0;
    pdc_finanziario='';
    disp_stanz_anno=0;
    disp_stanz_anno1=0;
    disp_stanz_anno2=0;
        
    
    /* il parametro p_tipo indica se dal report e' stata richiesta la
    	visualizzazione di:
        - S - Spese;
        - E - Entrate;
        - T - Tutti.
        Nel caso siano richieste solo le entrate, questa procedura non
        esegue alcuna estrazione, visto che la relativa tabella
        nel report non sara' visualizzata */
    if p_tipo = 'E' THEN
    	return;
    end if;
        
    select fnc_siac_random_user()
	into	user_table;
	
SELECT a.ente_denominazione
	into ente_prop
from siac_t_ente_proprietario a
where a.ente_proprietario_id = p_ente_prop_id
	and a.data_cancellazione IS NULL;
    
select bilancio.bil_id 
	into bilancio_id 
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc
where bilancio.periodo_id=anno_eserc.periodo_id
	and bilancio.ente_proprietario_id= p_ente_prop_id
    and anno_eserc.anno = p_anno 
    and bilancio.data_cancellazione IS NULL
    and anno_eserc.data_cancellazione IS NULL;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo STRUTTURA DEL BILANCIO ';


-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
/* 28/09/2016: nei report di utilita' non deve essere inserito 
    	questo filtro */      
 -- , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 --AND programma.programma_id = progmacro.classif_a_id
--AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 
RTN_MESSAGGIO:='inserimento tabella di comodo dei capitoli ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo dei capitoli  ';

insert into   siac_rep_cap_uscita_completo --siac_rep_cap_up --siac_rep_cap_ug
select 	programma.classif_id,
		macroaggr.classif_id,
        p_anno anno_bilancio,
       	capitolo.*,
        pdc.classif_code||' - '||pdc.classif_desc,
       	user_table utente,
        tipo_elemento.elem_tipo_code
from siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr,
     siac_r_bil_elem_class r_capitolo_pdc,
     siac_t_class pdc,
     siac_d_class_tipo pdc_tipo,
     siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	
    and programma.classif_tipo_id	=programma_tipo.classif_tipo_id 			
    and programma.classif_id	=r_capitolo_programma.classif_id		
    and macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id	=r_capitolo_macroaggr.classif_id	
    and capitolo.elem_id=r_capitolo_programma.elem_id							
    and capitolo.elem_id=r_capitolo_macroaggr.elem_id							
    and capitolo.elem_id				=	r_capitolo_stato.elem_id			
	and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
    and capitolo.elem_id				=	r_cat_capitolo.elem_id				
	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	
    and r_capitolo_pdc.classif_id 			= pdc.classif_id						
  	and pdc.classif_tipo_id 				= pdc_tipo.classif_tipo_id	
    and capitolo.elem_id 					= 	r_capitolo_pdc.elem_id					
    and capitolo.ente_proprietario_id	=	p_ente_prop_id
    and capitolo.bil_id = bilancio_id	  					
 	and ((p_tipo_capitolo ='T' 
        	AND tipo_elemento.elem_tipo_code in ('CAP-UG','CAP-UP')) OR  
  		(p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-UP') OR 
  		(p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-UG'))  								
	and programma_tipo.classif_tipo_code	='PROGRAMMA' 									    
    and macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO'						
	and stato_capitolo.elem_stato_code	=	'VA'								    		
    --and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC')				
	--and cat_del_capitolo.elem_cat_code	=	'STD'							    					
	and pdc_tipo.classif_tipo_code like 'PDC_%'																		  	
	and programma_tipo.data_cancellazione			is null 	
    and programma.data_cancellazione 				is null 	
    and macroaggr_tipo.data_cancellazione	 		is null 	
    and macroaggr.data_cancellazione 				is null 	
    and tipo_elemento.data_cancellazione 			is null 	
    and r_capitolo_programma.data_cancellazione 	is null 	
    and r_capitolo_macroaggr.data_cancellazione 	is null 	
    and r_capitolo_pdc.data_cancellazione 			is null 	
    and pdc.data_cancellazione 						is null 	
    and pdc_tipo.data_cancellazione 				is null 	
    and stato_capitolo.data_cancellazione 			is null 	 
    and r_capitolo_stato.data_cancellazione 		is null 	
	and cat_del_capitolo.data_cancellazione 		is null 	
    and r_cat_capitolo.data_cancellazione 			is null 	
	and capitolo.data_cancellazione 				is null;    

-- SIAC-7278: 14/01/2020.
--	Aggiunti anche i capitoli che non hanno la classificazione.
insert into   siac_rep_cap_uscita_completo
select  NULL, 
		NULL,
        p_anno anno_bilancio,
       	capitolo.*,
        case when COALESCE(classif_pdce.classif_code,'') = '' then ''
  			else classif_pdce.classif_code||' - '||classif_pdce.classif_desc end,
       	user_table utente,
        tipo_elemento.elem_tipo_code
from siac_t_bil_elem capitolo
        left join (select r_capitolo_pdc.elem_id,
            pdc.classif_code, pdc.classif_desc
          from siac_r_bil_elem_class r_capitolo_pdc,
            siac_t_class pdc,
            siac_d_class_tipo pdc_tipo
          where r_capitolo_pdc.classif_id = pdc.classif_id
                AND pdc.classif_tipo_id  = pdc_tipo.classif_tipo_id	
                and r_capitolo_pdc.ente_proprietario_id = p_ente_prop_id
                AND	pdc_tipo.classif_tipo_code like 'PDC_%'	
                and r_capitolo_pdc.data_cancellazione IS NULL
                and pdc.data_cancellazione IS NULL
                and pdc_tipo.data_cancellazione IS NULL) classif_pdce                        
    	on capitolo.elem_id = classif_pdce.elem_id ,
	 siac_d_bil_elem_tipo tipo_elemento,     
     siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
    and capitolo.elem_id				=	r_capitolo_stato.elem_id
    and capitolo.elem_id				=	r_cat_capitolo.elem_id				
	and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
    and stato_capitolo.elem_stato_id 	= 	r_capitolo_stato.elem_stato_id											
    and capitolo.ente_proprietario_id	=	p_ente_prop_id
    and capitolo.bil_id = bilancio_id									 				
 	and (
		(p_tipo_capitolo ='T' 
        	AND tipo_elemento.elem_tipo_code in ('CAP-UG','CAP-UP')) OR  
  		(p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-UP') OR 
  		(p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-UG'))  														
	and stato_capitolo.elem_stato_code	=	'VA'								  															
    and tipo_elemento.data_cancellazione 			is null 	
    and stato_capitolo.data_cancellazione 			is null 	 
    and r_capitolo_stato.data_cancellazione 		is null 	
	and cat_del_capitolo.data_cancellazione 		is null 	
    and r_cat_capitolo.data_cancellazione 			is null 	
	and capitolo.data_cancellazione 				is null
    and capitolo.elem_id not in (select a.elem_id
    		from siac_rep_cap_uscita_completo a
            where a.ente_proprietario_id=p_ente_prop_id
            	and a.utente= user_table);   
    
RTN_MESSAGGIO:='inserimento tabella di comodo degli importi per capitolo ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo degli importi per capitolo ';

insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)                    
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=	p_ente_prop_id  
        and	anno_eserc.anno							= 	p_anno 												
    	and	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						            
      	and ((p_tipo_capitolo ='T' 
          	AND tipo_elemento.elem_tipo_code in ('CAP-UG','CAP-UP')) OR
     		(p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-UP') OR
     		(p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-UG'))     
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp,annoCapImp1,annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		--and	cat_del_capitolo.elem_cat_code	=	'STD'								
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;
    

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo degli importi per capitolo per riga';    
insert into siac_rep_cap_uscita_imp_completo_riga
select  tb1.elem_id,      
    	coalesce (tb1.importo,0)   as 		residuo_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_anno,
        coalesce (tb3.importo,0)   as 		cassa_anno,
        coalesce (tb4.importo,0)   as 		residuo_anno_ini,
        coalesce (tb5.importo,0)   as 		residuo_iniz_anno,
        coalesce (tb6.importo,0)   as 		cassa_iniz_anno,
        coalesce (tb7.importo,0)   as 		residuo_anno1,
        coalesce (tb8.importo,0)   as 		stanziamento_anno1,
        coalesce (tb9.importo,0)   as 		cassa_anno1,
        coalesce (tb10.importo,0)   as 		residuo_anno_ini1,
        coalesce (tb11.importo,0)   as 		residuo_iniz_anno1,
        coalesce (tb12.importo,0)   as 		cassa_iniz_anno1,
        coalesce (tb13.importo,0)   as 		residuo_anno2,
        coalesce (tb14.importo,0)   as 		stanziamento_anno2,
        coalesce (tb15.importo,0)   as 		cassa_anno2,
        coalesce (tb16.importo,0)   as 		residuo_anno_ini2,
        coalesce (tb17.importo,0)   as 		residuo_iniz_anno2,
        coalesce (tb18.importo,0)   as 		cassa_iniz_anno2,
        tb1.ente_proprietario,
       user_table utente 
from 	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6,
        siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10, siac_rep_cap_up_imp tb11, siac_rep_cap_up_imp tb12,
        siac_rep_cap_up_imp tb13, siac_rep_cap_up_imp tb14, siac_rep_cap_up_imp tb15,
        siac_rep_cap_up_imp tb16, siac_rep_cap_up_imp tb17, siac_rep_cap_up_imp tb18        
         where		tb1.elem_id	=	tb2.elem_id	and
        			tb2.elem_id	=	tb3.elem_id AND
                    tb3.elem_id	=	tb4.elem_id AND
                    tb4.elem_id	=	tb5.elem_id AND
                    tb5.elem_id	=	tb6.elem_id AND
                    tb6.elem_id	=	tb7.elem_id	and
        			tb7.elem_id	=	tb8.elem_id AND
                    tb8.elem_id	=	tb9.elem_id AND
                    tb9.elem_id	=	tb10.elem_id AND
                    tb10.elem_id	=	tb11.elem_id AND
                    tb11.elem_id	=	tb12.elem_id AND
                    tb12.elem_id	=	tb13.elem_id AND
                    tb13.elem_id	=	tb14.elem_id AND
                    tb14.elem_id	=	tb15.elem_id AND
                    tb15.elem_id	=	tb16.elem_id AND
                    tb16.elem_id	=	tb17.elem_id AND
                    tb17.elem_id	=	tb18.elem_id AND                                  
        			tb1.periodo_anno in (annoCapImp)		AND	tb1.tipo_imp =	TipoImpResiduo	AND
        			tb2.periodo_anno = tb1.periodo_anno	AND	tb2.tipo_imp = 	TipoImpstanz		AND
        			tb3.periodo_anno = tb1.periodo_anno	AND	tb3.tipo_imp = 	TipoImpCassa AND
                    tb4.periodo_anno = tb1.periodo_anno		AND	tb4.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzIniz	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	tipoImpCassaIniz AND
                    tb7.periodo_anno in (annoCapImp1)		AND	tb7.tipo_imp =	TipoImpResiduo	AND
        			tb8.periodo_anno = tb7.periodo_anno	AND	tb8.tipo_imp = 	TipoImpstanz		AND
        			tb9.periodo_anno = tb7.periodo_anno	AND	tb9.tipo_imp = 	TipoImpCassa AND
                    tb10.periodo_anno = tb7.periodo_anno	AND	tb10.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb11.periodo_anno = tb7.periodo_anno	AND	tb11.tipo_imp = 	TipoImpstanzIniz	AND
        			tb12.periodo_anno = tb7.periodo_anno	AND	tb12.tipo_imp = 	tipoImpCassaIniz	AND
                    tb13.periodo_anno in(annoCapImp2)		AND	tb13.tipo_imp =	TipoImpResiduo	AND
        			tb14.periodo_anno = tb13.periodo_anno	AND	tb14.tipo_imp = 	TipoImpstanz		AND
        			tb15.periodo_anno = tb13.periodo_anno	AND	tb15.tipo_imp = 	TipoImpCassa AND
                    tb16.periodo_anno = tb13.periodo_anno	AND	tb16.tipo_imp =	TipoImpstanzresiduiIniz AND
        			tb17.periodo_anno = tb13.periodo_anno	AND	tb17.tipo_imp = 	TipoImpstanzIniz	AND
        			tb18.periodo_anno = tb13.periodo_anno	AND	tb18.tipo_imp = 	tipoImpCassaIniz AND
                    tb1.utente=user_table;


/* estrazione dei dati dei capitoli */

 RTN_MESSAGGIO:='estrazione dei dati dalle tabelle di comodo e preparazione dati in output ''.';                
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'estrazione dei dati dalle tabelle di comodo e preparazione dati in output ';

-- SIAC-7278: 14/01/2020.
--	Query rivista per poter estrarre anche i capitoli che non 
-- hanno la classificazione.
for classifBilRec in
  select 	v1.missione_tipo_desc		missione_tipo_desc,
          v1.missione_code				missione_code,
          v1.missione_desc				missione_desc,
          v1.programma_tipo_desc		programma_tipo_desc,
          v1.programma_code				programma_code,
          v1.programma_desc				programma_desc,
          v1.titusc_tipo_desc			titusc_tipo_desc,
          v1.titusc_code				titusc_code,
          v1.titusc_desc				titusc_desc,
          v1.macroag_tipo_desc			macroag_tipo_desc,
          v1.macroag_code				macroag_code,
          v1.macroag_desc				macroag_desc,
          tb.bil_anno   				BIL_ANNO,
          tb.elem_code     				BIL_ELE_CODE,
          tb.elem_code2     			BIL_ELE_CODE2,
          tb.elem_code3					BIL_ELE_CODE3,
          tb.elem_desc     				BIL_ELE_DESC,
          tb.elem_desc2     			BIL_ELE_DESC2,
          tb.elem_id      				BIL_ELE_ID,
          tb.elem_id_padre    			BIL_ELE_ID_PADRE,
          tb.codice_pdc 				pdc_finanziario,
          COALESCE(tb1.cassa_anno,0)	cassa_anno,
          COALESCE(tb1.cassa_anno1,0)	cassa_anno1,
          COALESCE(tb1.cassa_anno2,0)	cassa_anno2,
          COALESCE(tb1.cassa_iniz_anno,0)	cassa_iniz_anno,	
          COALESCE(tb1.cassa_iniz_anno1,0)	cassa_iniz_anno1,		
          COALESCE(tb1.cassa_iniz_anno2,0)	cassa_iniz_anno2,	
          COALESCE(tb1.residuo_anno,0)		residuo_anno,	
          COALESCE(tb1.residuo_anno1,0)	residuo_anno1,
          COALESCE(tb1.residuo_anno2,0)	residuo_anno2,
          COALESCE(tb1.residuo_iniz_anno,0)	residuo_iniz_anno,
          COALESCE(tb1.residuo_iniz_anno1,0)	residuo_iniz_anno1,
          COALESCE(tb1.residuo_iniz_anno2,0)	residuo_iniz_anno2,
          COALESCE(tb1.stanziamento_anno,0)	stanziamento_anno,
          COALESCE(tb1.stanziamento_anno1,0)	stanziamento_anno1,
          COALESCE(tb1.stanziamento_anno2,0)	stanziamento_anno2,
          COALESCE(tb1.stanziamento_iniz_anno,0)	stanziamento_iniz_anno,
          COALESCE(tb1.stanziamento_iniz_anno1,0)	stanziamento_iniz_anno1,
          COALESCE(tb1.stanziamento_iniz_anno2,0)	stanziamento_iniz_anno2,          
          categ.elem_cat_code, categ.elem_cat_desc,
          ente_prop ente_prop_denom,
          tb.tipo_capitolo, attrib_impegn."boolean"
   from   
      siac_rep_mis_pro_tit_mac_riga_anni v1
      	full join siac_rep_cap_uscita_completo tb
        	on (v1.programma_id = tb.programma_id
            	and v1.macroag_id	= tb.macroaggregato_id
                AND TB.utente=V1.utente
                and tb.elem_code IS NOT NULL)
         left	join    siac_rep_cap_uscita_imp_completo_riga 	tb1  
           			on tb1.elem_id	=	tb.elem_id
          join (select r_categoria.elem_id,
          			d_categoria.elem_cat_code, d_categoria.elem_cat_desc
          		from  siac_r_bil_elem_categoria  r_categoria,
                	  siac_d_bil_elem_categoria  d_categoria
                where r_categoria.elem_cat_id=  d_categoria.elem_cat_id
                	and r_categoria.ente_proprietario_id = p_ente_prop_id   
                    and r_categoria.data_cancellazione IS NULL
                    and d_categoria.data_cancellazione IS NULL) categ  
              on tb.elem_id=categ.elem_id   
         left join (SELECT a.elem_id, b.attr_code, a.boolean
                    from siac_r_bil_elem_attr a,
                    	siac_t_attr b
                   where a.attr_id=b.attr_id
                    and a.ente_proprietario_id = p_ente_prop_id
                    and b.attr_code='FlagImpegnabile'
                    and a.data_cancellazione IS NULL
                    and b.data_cancellazione IS NULL) attrib_impegn  
             on attrib_impegn.elem_id= tb.elem_id                     
 	where  tb.ente_proprietario_id=p_ente_prop_id
           and tb.utente=user_table 
  order by missione_code,programma_code,titusc_code,macroag_code, BIL_ELE_ID

        
    loop
         
    nome_ente=classifBilRec.ente_prop_denom;
    bil_anno=classifBilRec.BIL_ANNO;
    tipo_capitolo_pg=classifBilRec.tipo_capitolo;
    anno_capitolo=classifBilRec.BIL_ANNO;
    cod_capitolo=classifBilRec.BIL_ELE_CODE;
    cod_articolo=classifBilRec.BIL_ELE_CODE2;
    ueb=classifBilRec.BIL_ELE_CODE3;
    descr_capitolo=classifBilRec.BIL_ELE_DESC;
    descr_articolo=COALESCE(classifBilRec.BIL_ELE_DESC2,'');
    cod_missione=COALESCE(classifBilRec.missione_code,'');
    descr_missione=COALESCE(classifBilRec.missione_desc,'');
    cod_programma=COALESCE(classifBilRec.programma_code,'');
    descr_programma=COALESCE(classifBilRec.programma_desc,'');
    cod_titolo=COALESCE(classifBilRec.titusc_code,'');
    descr_titolo=COALESCE(classifBilRec.titusc_desc,'');

    cod_macroaggr=COALESCE(classifBilRec.macroag_code,'');
    descr_macroaggr=COALESCE(classifBilRec.macroag_desc,'');
    
    tipo_capitolo=classifBilRec.elem_cat_code||' - '||classifBilRec.elem_cat_desc;
    
    cassa_anno=classifBilRec.cassa_anno;
    cassa_anno1=classifBilRec.cassa_anno1;
    cassa_anno2=classifBilRec.cassa_anno2;
    cassa_iniz_anno=classifBilRec.cassa_iniz_anno;	
    cassa_iniz_anno1=classifBilRec.cassa_iniz_anno1;		
    cassa_iniz_anno2=classifBilRec.cassa_iniz_anno2;	
    residuo_anno=classifBilRec.residuo_anno;	
    residuo_anno1=classifBilRec.residuo_anno1;
    residuo_anno2=classifBilRec.residuo_anno2;
    residuo_iniz_anno=classifBilRec.residuo_iniz_anno;
    residuo_iniz_anno1=classifBilRec.residuo_iniz_anno1;
    residuo_iniz_anno2=classifBilRec.residuo_iniz_anno2;
    stanziamento_anno=classifBilRec.stanziamento_anno;
    stanziamento_anno1=classifBilRec.stanziamento_anno1;
    stanziamento_anno2=classifBilRec.stanziamento_anno2;
    stanziamento_iniz_anno=classifBilRec.stanziamento_iniz_anno;
    stanziamento_iniz_anno1=classifBilRec.stanziamento_iniz_anno1;
    stanziamento_iniz_anno2=classifBilRec.stanziamento_iniz_anno2;
    pdc_finanziario=classifBilRec.pdc_finanziario;
    impegnabile:=COALESCE(classifBilRec."boolean",'');   
    
    	/* cerco gli elementi di tipo classe */
    BEGIN
    	for elencoClass in 
          select distinct d_class_tipo.*, t_class.*
          from 
           siac_t_class t_class,
           siac_d_class_tipo d_class_tipo,
           siac_r_bil_elem_class r_bil_elem_class
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_bil_elem_class.classif_id=t_class.classif_id
              and r_bil_elem_class.ente_proprietario_id = p_ente_prop_id
              and r_bil_elem_class.elem_id=classifBilRec.BIL_ELE_ID
              and (d_class_tipo.classif_tipo_code ='GRUPPO_COFOG' OR
              		substr(d_class_tipo.classif_tipo_code,1,11) ='SIOPE_SPESA')
              and r_bil_elem_class.data_cancellazione IS NULL
              and t_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
        loop
          IF elencoClass.classif_tipo_code ='GRUPPO_COFOG' THEN
          	cod_cofog=elencoClass.classif_code;
    		descr_cofog=elencoClass.classif_desc;
          else  --SIOPE_SPESA
          	siope=elencoClass.classif_code||' - '||elencoClass.classif_desc;
          end if;
          
        end loop;
            
    END;
        
    /* cerco la struttura amministrativa */
	BEGIN    
          SELECT   t_class.classif_code, t_class.classif_desc, r_class_fam_tree.classif_id_padre 
          INTO sett_code, sett_descr, classif_id_padre      
              from siac_r_bil_elem_class r_bil_elem_class,
                  siac_r_class_fam_tree r_class_fam_tree,
                  siac_t_class			t_class,
                  siac_d_class_tipo		d_class_tipo ,
                  siac_t_bil_elem    		capitolo               
          where 
              r_bil_elem_class.elem_id 			= 	capitolo.elem_id
              and t_class.classif_id 					= 	r_bil_elem_class.classif_id
              and t_class.classif_id 					= 	r_class_fam_tree.classif_id
              and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
             AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
              and capitolo.elem_id=classifBilRec.BIL_ELE_ID
               AND r_bil_elem_class.data_cancellazione is NULL
               AND t_class.data_cancellazione is NULL
               AND d_class_tipo.data_cancellazione is NULL
               AND capitolo.data_cancellazione is NULL
               and r_class_fam_tree.data_cancellazione is NULL;    
                                
              IF NOT FOUND THEN
                  /* se il settore non esiste restituisco un codice fittizio
                      e cerco se esiste la direzione */
                  sett_code='';
                  sett_descr='';
              
                BEGIN
                SELECT  t_class.classif_code, t_class.classif_desc
                    INTO direz_code, direz_descr
                    from siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class			t_class,
                        siac_d_class_tipo		d_class_tipo ,
                        siac_t_bil_elem    		capitolo               
                where 
                    r_bil_elem_class.elem_id 			= 	capitolo.elem_id
                    and t_class.classif_id 					= 	r_bil_elem_class.classif_id
                    and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id          
                   and d_class_tipo.classif_tipo_code='CDR'
                    and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                     AND r_bil_elem_class.data_cancellazione is NULL
                     AND t_class.data_cancellazione is NULL
                     AND d_class_tipo.data_cancellazione is NULL
                     AND capitolo.data_cancellazione is NULL;	
               IF NOT FOUND THEN
                  /* se non esiste la direzione restituisco un codice fittizio */
                direz_code='';
                direz_descr='';         
                END IF;
            END;
              
         ELSE
              /* cerco la direzione con l'ID padre del settore */
           BEGIN
            SELECT  t_class.classif_code, t_class.classif_desc
                INTO direz_code, direz_descr
            from siac_t_class t_class
            where t_class.classif_id= classif_id_padre;
            IF NOT FOUND THEN
              direz_code='';
              direz_descr='';  
            END IF;
            END;
              
          END IF;
       if direz_code <> '' THEN
          descr_strutt_amm = direz_code||' - ' ||direz_descr;
        else 
          descr_strutt_amm='';
        end if;
        
        if sett_code <> '' THEN
          descr_strutt_amm = descr_strutt_amm || ' - ' || sett_code ||' - ' ||sett_descr;
        end if;

      END;   
      
    disp_stanz_anno=0;
    disp_stanz_anno1=0;
    disp_stanz_anno2=0;
      
    return next;
    
    nome_ente='';
    bil_anno='';
    tipo_capitolo_pg='';
    anno_capitolo=0;
    cod_capitolo='';
    cod_articolo='';
    ueb='';
    descr_capitolo='';
    descr_articolo='';
    cod_missione='';
    descr_missione='';
    cod_programma='';
    descr_programma='';
    cod_titolo='';
    descr_titolo='';
    cod_cofog='';
    descr_cofog='';
    cod_macroaggr='';
    descr_macroaggr='';
    siope='';
    descr_strutt_amm='';
    tipo_capitolo='';
    impegnabile='';
	cassa_anno=0;
    cassa_anno1=0;
    cassa_anno2=0;
    cassa_iniz_anno=0;	
    cassa_iniz_anno1=0;		
    cassa_iniz_anno2=0;	
    residuo_anno=0;	
    residuo_anno1=0;
    residuo_anno2=0;
    residuo_iniz_anno=0;
    residuo_iniz_anno1=0;
    residuo_iniz_anno2=0;
    stanziamento_anno=0;
    stanziamento_anno1=0;
    stanziamento_anno2=0;
    stanziamento_iniz_anno=0;
    stanziamento_iniz_anno1=0;
    stanziamento_iniz_anno2=0;
    pdc_finanziario='';
    disp_stanz_anno=0;
    disp_stanz_anno1=0;
    disp_stanz_anno2=0;
    
end loop;            
raise notice 'ora: % ',clock_timestamp()::varchar;            

  
  delete from siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
  delete from  siac_rep_cap_uscita_completo				where utente=user_table;
  delete from siac_rep_cap_up_imp where utente=user_table;
  delete from siac_rep_cap_uscita_imp_completo_riga where utente=user_table;	
   
exception
	when no_data_found THEN
		raise notice 'Dati dei capitoli non trovati.' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'CAPITOLI',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;