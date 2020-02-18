/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_data_protocollo varchar,
  p_ele_variazioni varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_fpv_anno numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_fpv numeric,
  variazione_diminuzione_fpv numeric,
  impegnato_anno numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImpInt integer;
tipoImpComp varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
v_data date;

strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN
	display_error:='';
    
	BEGIN
		v_data = to_date(p_data_protocollo, 'dd/MM/yyyy');        
    EXCEPTION
	when others  THEN
     display_error := 'CAMPO DATA PROTOCOLLO FORMALMENTE NON CORRETTO';
     return next;
     return;                         
    END;    

IF p_data_protocollo != '' AND p_data_protocollo IS NOT NULL THEN
  IF to_char(v_data,'dd/MM/yyyy') != p_data_protocollo THEN
     display_error := 'CAMPO DATA PROTOCOLLO FORMALMENTE NON CORRETTO';
     return next;
     return;
  END IF; 
END IF;
/*
IF p_numero_delibera IS NOT NULL 
   OR
   (p_anno_delibera IS NOT NULL AND p_anno_delibera != '')
   OR
   (p_tipo_delibera IS NOT NULL AND  p_tipo_delibera != '')
   THEN
   IF p_numero_delibera IS NULL THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;
   END IF;
   IF p_anno_delibera IS NULL OR p_anno_delibera = '' THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;      
   END IF; 
   IF p_tipo_delibera IS NULL OR  p_tipo_delibera = '' THEN
      display_error := 'CAMPI NUMERO, ANNO E TIPOLOGIA DEL PROVVEDIMENTO OBBLIGATORI';
      return next;
      return;      
   END IF;  
END IF;  */


--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN   
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


annoCapImp:= p_anno; 
annoCapImpInt:= p_anno::integer;

TipoImpComp='STA';  -- competenza

elemTipoCode:='CAP-UG';

bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_fpv_anno=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_fpv=0;
variazione_diminuzione_fpv=0;
impegnato_anno=0;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  

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
from missione, programma, titusc, macroag, 
     siac_r_class progmacro
where programma.missione_id=missione.missione_id
and titusc.titusc_id=macroag.titusc_id
and programma.programma_id = progmacro.classif_a_id
and titusc.titusc_id = progmacro.classif_b_id
and titusc.ente_proprietario_id=missione.ente_proprietario_id;

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.'; 


insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        cat_del_capitolo.elem_cat_code,
        --' ',
        user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
    stato_capitolo.elem_stato_code		in ('VA', 'PR')						and			
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    -- 06/09/2016: aggiunto FPVC
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp''.'; 
 
/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	--capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            cat_del_capitolo.elem_cat_code          TIPO_IMP,
            capitolo_importi.ente_proprietario_id,  
            user_table utente,            
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPVC
        and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi					
        --and capitolo_imp_periodo.anno = p_anno_competenza
        and capitolo_imp_periodo.anno =	p_anno							
        and	capitolo_imp_tipo.elem_det_tipo_code = 'STA'
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
    group by	capitolo_importi.elem_id,
    --capitolo_imp_tipo.elem_det_tipo_code,
    cat_del_capitolo.elem_cat_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
     
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp_riga STD''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
        from 
        siac_rep_cap_ug_imp tb1
        where tb1.periodo_anno = annoCapImp	
        and	tb1.tipo_imp in ('STD','FSC')
        -- and	tb1.tipo_imp =	TipoImpComp	
        -- and	tb1.tipo_capitolo in ('STD','FSC')
        and	tb1.utente	=	user_table;

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp_riga FPV''.'; 
      
insert into siac_rep_cap_ug_imp_riga
select  tb2.elem_id,      
    	0,
    	tb2.importo		as		stanziamento_fpv_anno,
    	0,
        tb2.ente_proprietario,
        user_table utente,
        tb2.periodo_anno 
        from siac_rep_cap_ug_imp tb2
        where tb2.periodo_anno = annoCapImp 
        and	tb2.tipo_imp in ('FPV','FPVC') 
        -- and	tb2.tipo_imp = 	TipoImpComp	
        -- and	tb2.tipo_capitolo	in ('FPV','FPVC')
        and	tb2.utente	=	user_table;
      
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.';  

insert into siac_rep_impegni_riga
select n.elem_id,
sum(c.movgest_ts_det_importo) importo,
  0,
  0,
  p_ente_prop_id,
  user_table utente
from 
siac_t_bil l, 
siac_t_periodo m, 
siac_t_bil_elem n,
siac_d_bil_elem_tipo t,
siac_r_movgest_bil_elem o, 
siac_t_movgest a, 
siac_t_movgest_ts b, 
siac_t_movgest_ts_det c, 
siac_d_movgest_ts_det_tipo d, 
siac_d_movgest_tipo e, 
siac_r_movgest_ts_atto_amm f,
siac_t_atto_amm g, 
siac_d_movgest_stato h, 
siac_r_movgest_ts_stato i
where l.periodo_id = m.periodo_id 
and m.anno = p_anno
and l.bil_id = n.bil_id
and t.elem_tipo_id = n.elem_tipo_id
and t.elem_tipo_code = elemTipoCode
and o.elem_id = n.elem_id
and o.movgest_id = a.movgest_id
and a.movgest_id = b.movgest_id
and b.movgest_ts_id_padre is null
and b.movgest_ts_id = c.movgest_ts_id
and c.movgest_ts_det_tipo_id = d.movgest_ts_det_tipo_id
and d.movgest_ts_det_tipo_code = 'I'
and a.movgest_anno = annoCapImpInt
and e.movgest_tipo_id = a.movgest_tipo_id
and e.movgest_tipo_code = 'I'
and f.movgest_ts_id = b.movgest_ts_id
and f.attoamm_id = g.attoamm_id
and g.attoamm_anno < p_anno
and h.movgest_stato_id = i.movgest_stato_id
and i.movgest_ts_id = b.movgest_ts_id
and i.data_cancellazione is null
and i.validita_fine is null
and h.movgest_stato_code in ('N', 'D')
and a.ente_proprietario_id = p_ente_prop_id
and a.parere_finanziario is true
and a.data_cancellazione is null
and b.validita_inizio <= to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
and (a.parere_finanziario_data_modifica < to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') or a.parere_finanziario_data_modifica is null)
and c.data_cancellazione is null
and c.validita_fine is null
and a.data_cancellazione is null
and a.validita_fine is null
and b.data_cancellazione is null
and b.validita_fine is null
and f.data_cancellazione is null
and f.validita_fine is null
and g.data_cancellazione is null
and g.validita_fine is null
and i.data_cancellazione is null
and i.validita_fine is null
group by  n.elem_id;
         
IF p_numero_delibera IS NOT NULL AND p_anno_delibera IS NOT NULL AND p_tipo_delibera IS NOT NULL THEN                

    RTN_MESSAGGIO:='insert tabella siac_rep_var_spese''.'; 
     
    insert into siac_rep_var_spese 
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id,
            anno_importo.anno	      	
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
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo ,
            siac_t_bil                  bilancio             
    where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    and		r_atto_stato.attoamm_id								=	atto.attoamm_id
    and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
    and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
              r_variazione_stato.attoamm_id_varbil 				=	atto.attoamm_id )
    and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id  
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and 	atto.ente_proprietario_id 							= 	p_ente_prop_id
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    and		anno_eserc.anno										= 	p_anno 																	
    and     anno_importo.anno                                   =   p_anno_competenza
    and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					= 'STA'
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
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                atto.ente_proprietario_id,
                anno_importo.anno;
else 
	strQuery := '
    insert into siac_rep_var_spese 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id,
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
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio             
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		testata_variazione.ente_proprietario_id				= '||p_ente_prop_id||'
and		anno_eserc.anno										=  '''||p_anno ||'''
and 	testata_variazione.variazione_num					in ('|| p_ele_variazioni||')											
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''
and		tipologia_stato_var.variazione_stato_tipo_code		in	(''B'',''G'', ''C'', ''P'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					= ''STA''
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
            anno_importo.anno';          
            
raise notice 'Query: %',strQuery;

execute strQuery;
              
/*
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id,
        anno_importo.anno	      	
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
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio             
where 	atto.ente_proprietario_id 							= 	p_ente_prop_id
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
          r_variazione_stato.attoamm_id_varbil 				=	atto.attoamm_id )
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_eserc.anno										= 	p_anno 												
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  					
and     anno_importo.anno                                   =   p_anno
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and		tipo_elemento.elem_det_tipo_code					= 'STA'
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
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	atto.ente_proprietario_id,
            anno_importo.anno;*/
     
END IF;     
     
RTN_MESSAGGIO:='insert tabella siac_rep_var_spese_riga''.';  

insert into siac_rep_var_spese_riga
select  tb0.elem_id,       
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as        variazione_aumento_fpv,
        tb4.importo   as        variazione_diminuzione_fpv,        
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id
        and tb0.codice_pdc in ('STD','FSC')
        -- and tb1.tipologia  	= 'STA'	
        and	tb1.importo >= 0	
        --and tb1.periodo_anno=p_anno_competenza        
        and tb1.utente = tb0.utente
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
        and tb0.codice_pdc in ('STD','FSC')
     	--and tb2.tipologia  	= 'STA'	
        and	tb2.importo < 0	
        --and     tb2.periodo_anno=p_anno_competenza
        and     tb2.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb3
    on (tb3.elem_id		=	tb0.elem_id
        and tb0.codice_pdc in ('FPV','FPVC')
     	-- and tb3.tipologia  	= 'STA'	
        and	tb3.importo >= 0	
        --and     tb3.periodo_anno=p_anno_competenza
        and     tb3.utente = tb0.utente 
        )
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
        and tb0.codice_pdc in ('FPV','FPVC')
     	-- and tb4.tipologia  	= 'STA'	
        and	tb4.importo < 0	
        --and     tb4.periodo_anno=p_anno_competenza
        and     tb4.utente = tb0.utente 
        )                          
where  tb0.utente = user_table;
  
     RTN_MESSAGGIO:='preparazione file output ''.'; 
      
for classifBilRec in
select v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.residui_passivi,0)                 stanziamento_prev_anno,
        COALESCE (tb1.previsioni_definitive_comp,0)     stanziamento_fpv_anno,
        COALESCE (tb2.variazione_aumento_stanziato,0)    variazione_aumento_stanziato, 
        COALESCE (tb2.variazione_diminuzione_stanziato* -1,0) variazione_diminuzione_stanziato,
        COALESCE (tb2.variazione_aumento_cassa,0)         variazione_aumento_fpv,
        COALESCE (tb2.variazione_diminuzione_cassa* -1,0)     variazione_diminuzione_fpv,
        COALESCE (tb3.impegnato_anno,0)                   impegnato_anno        
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
    left join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND tb.utente=v1.utente
                    and v1.utente=user_table)  
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		and tb.utente=tb1.utente
                    and tb.utente=user_table
                    )  
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb.elem_id
            		and tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    --and tb2.periodo_anno=tb1.periodo_anno
                    ) 
            left join siac_rep_impegni_riga tb3
            on (tb3.elem_id = tb.elem_id 
                and tb3.utente=tb2.utente
                and tb2.utente=user_table)                                       
where v1.utente = user_table 
    /*and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id                        
    )	*/
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop

missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_fpv:=classifBilRec.variazione_aumento_fpv;
variazione_diminuzione_fpv:=classifBilRec.variazione_diminuzione_fpv;
impegnato_anno:=classifBilRec.impegnato_anno;

return next;
bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_fpv_anno=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_fpv=0;
variazione_diminuzione_fpv=0;
impegnato_anno=0;

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;
delete from siac_rep_cap_ug_imp where utente=user_table;
delete from siac_rep_cap_ug_imp_riga where utente=user_table;
delete from siac_rep_impegni_riga where utente=user_table;
delete from	siac_rep_var_spese	where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when syntax_error THEN    
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN 
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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
COST 100 ROWS 1000;