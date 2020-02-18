/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR209_stampa_variazione_spese_def" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_anno_variazione varchar
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
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp varchar;
annoCapImp2 varchar;
annoCapImp3 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:='';
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
sql_query varchar;
strApp varchar;
intApp numeric;

BEGIN

annoCapImp:= p_anno;
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 --intApp= strApp ::numeric/ 1;
 intApp = strApp::numeric;
END IF;


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
display_error='';

---------------------------------------------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';


-- carico struttura del bilancio
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
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';
insert into siac_rep_cap_ug
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
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
	-- INC000001570761 stato_capitolo.elem_stato_code	=	'VA'								and
    stato_capitolo.elem_stato_code	in ('VA', 'PR')							and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
    ------cat_del_capitolo.elem_cat_code	=	'STD'
    -- 06/09/2016: aggiunto FPVC
	--and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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


    insert into siac_rep_cap_ug
      select null, null,
        anno_eserc.anno anno_bilancio,
        e.*, ' ', user_table utente
       from
              siac_t_bil_elem e,
              siac_t_bil bilancio,
              siac_t_periodo anno_eserc,
              siac_d_bil_elem_tipo tipo_elemento,
              siac_d_bil_elem_stato stato_capitolo,
              siac_r_bil_elem_stato r_capitolo_stato
      where e.ente_proprietario_id=p_ente_prop_id
      and anno_eserc.anno					= 	p_anno
      and bilancio.periodo_id				=	anno_eserc.periodo_id
      and e.bil_id						=	bilancio.bil_id
      and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id
      and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
      and	e.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
	  -- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')
      and e.data_cancellazione 				is null
      and	r_capitolo_stato.data_cancellazione	is null
      and	bilancio.data_cancellazione 		is null
      and	anno_eserc.data_cancellazione 		is null
      and	tipo_elemento.data_cancellazione	is null
      and	stato_capitolo.data_cancellazione 	is null
      and not EXISTS
      (
         select 1 from siac_rep_cap_ug x
         where x.elem_id = e.elem_id
         and x.utente=user_table
    );

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';


/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare
    l'importo del capitolo.
*/
/*  10/12/2018    modificata lettura degli importi siac_6498
INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
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
        and	capitolo_imp_periodo.anno = p_anno_variazione
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
	 	-- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'
        and stato_capitolo.elem_stato_code	in ('VA', 'PR')
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_imp_tipo.elem_det_tipo_code in ('STA', 'SCA','STR')
        -- 06/09/2016: aggiunto FPVC
        --and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
 *****************/
 sql_query:='
with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            capitolo_imp_tipo.elem_det_tipo_id,
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
    where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id ||'
        and	anno_eserc.anno						= '''||p_anno ||'''
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	capitolo.bil_id						=	bilancio.bil_id
        and	capitolo.elem_id					=	capitolo_importi.elem_id
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
        and	capitolo_imp_periodo.anno = '''||p_anno_variazione||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
	 	-- INC000001570761 and stato_capitolo.elem_stato_code	=	''VA''
        and stato_capitolo.elem_stato_code	in (''VA'', ''PR'')
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_imp_tipo.elem_det_tipo_code in (''STA'', ''SCA'',''STR'')
        -- 06/09/2016: aggiunto FPVC
        --and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')
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
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id,
    capitolo_imp_tipo.elem_det_tipo_id),
importi_variaz as (
		select
              dvarsucc.elem_id elem_id_var,
			  tipoimp.elem_det_tipo_id,
              sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
          from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
              siac_t_variazione avar, siac_r_variazione_stato bvar,
              siac_d_variazione_stato cvarsucc,
              siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
              siac_d_bil_elem_det_tipo tipoimp
          where bvarsucc.validita_inizio >= bvar.validita_inizio
              and avar.ente_proprietario_id=avarsucc.ente_proprietario_id
              and avarsucc.variazione_id= bvarsucc.variazione_id
              and avar.variazione_id=bvar.variazione_id
              and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
              and cvarsucc.variazione_stato_tipo_code=''D''
              and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
              and cvar.variazione_stato_tipo_code=''D''
              and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
              and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
              and bvarsucc.data_cancellazione is null
              --03/07/2019: SIAC-6956. Aggiunto test su data_cancellazione
              and dvarsucc.data_cancellazione is null
              and bvar.variazione_stato_id in (
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id  	='||p_ente_prop_id ||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
			group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ' ;


sql_query:=sql_query||'
              INSERT INTO siac_rep_cap_ug_imp
              select 	cap.elem_id,
              			cap.BIL_ELE_IMP_ANNO,
                		cap.TIPO_IMP,
              			cap.ente_proprietario_id,
                        '''||user_table||''' utente,
                		(cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
              from cap LEFT  JOIN importi_variaz
              ON (cap.elem_id = importi_variaz.elem_id_var
              	and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id)';

raise notice 'query: %', sql_query;

execute  sql_query;

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id,
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente ,
        tb1.periodo_anno
from
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		tb1.periodo_anno 		= p_anno_variazione	AND
                tb1.tipo_imp 	=	tipoImpComp		        AND
        		tb2.periodo_anno		= tb1.periodo_anno	AND
                tb2.tipo_imp 	= 	tipoImpCassa	        and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND
                tb4.tipo_imp 	= 	TipoImpRes		        and
                tb1.ente_proprietario 	=	p_ente_prop_id						and
                tb2.ente_proprietario	=	tb1.ente_proprietario				and
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and
                tb4.utente				=	tb1.utente;

     RTN_MESSAGGIO:='preparazione tabella variazioni''.';


sql_query='insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, ''';
sql_query=sql_query ||user_table||''' utente,
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
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
sql_query=sql_query ||'and		tipo_capitolo.elem_tipo_code						= '''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||'''';
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 = ''D''
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
            anno_importo.anno';

raise notice 'sql_query = % ', sql_query;

EXECUTE sql_query;


     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';

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
        p_anno_variazione
from
	siac_rep_cap_ug tb0
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0
        and     tb1.periodo_anno=p_anno_variazione
        and     tb1.utente = tb0.utente
        -- and tb0.tipo_imp =  tb1.tipologia
        )
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0
        and     tb2.periodo_anno=p_anno_variazione
        and     tb2.utente = tb0.utente
        -- and tb0.tipo_imp =  tb2.tipologia
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0
        and     tb3.periodo_anno=p_anno_variazione
        and     tb3.utente = tb0.utente
        -- and tb0.tipo_imp =  tb3.tipologia
          )
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0
        and     tb4.periodo_anno=p_anno_variazione
        and     tb4.utente = tb0.utente
        -- and tb0.tipo_imp =  tb4.tipologia
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno_variazione
        and     tb5.utente = tb0.utente
         --and tb0.tipo_imp =  tb5.tipologia
          )
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno_variazione
        and     tb6.utente = tb0.utente
         --and tb0.tipo_imp =  tb6.tipologia
         )
        where  tb0.utente = user_table
   /*
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
        -- and tb0.tipo_imp =  tb1.tipologia
        )
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente
        -- and tb0.tipo_imp =  tb2.tipologia
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente
        -- and tb0.tipo_imp =  tb3.tipologia
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
         --and tb0.tipo_imp =  tb5.tipologia
          )
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente
         --and tb0.tipo_imp =  tb6.tipologia
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
        annocapimp3
from
	siac_rep_cap_ug tb0
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0
        and     tb1.periodo_anno=annocapimp3
        and     tb1.utente = tb0.utente
        -- and tb0.tipo_imp =  tb1.tipologia
        )
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0
        and     tb2.periodo_anno=annocapimp3
        and     tb2.utente = tb0.utente
        -- and tb0.tipo_imp =  tb2.tipologia
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0
        and     tb3.periodo_anno=annocapimp3
        and     tb3.utente = tb0.utente
        -- and tb0.tipo_imp =  tb3.tipologia
          )
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0
        and     tb4.periodo_anno=annocapimp3
        and     tb4.utente = tb0.utente
        -- and tb0.tipo_imp =  tb4.tipologia
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp3
        and     tb5.utente = tb0.utente
         --and tb0.tipo_imp =  tb5.tipologia
          )
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp3
        and     tb6.utente = tb0.utente
         --and tb0.tipo_imp =  tb6.tipologia
         )
        where  tb0.utente = user_table   */ ;


     RTN_MESSAGGIO:='preparazione file output ''.';

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/
for classifBilRec in
select	v1.macroag_code						macroag_code,
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
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ug_imp_riga tb1
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table
                    )
            left	join    siac_rep_var_spese_riga tb2
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)
    where v1.utente = user_table
    	and tb1.periodo_anno = p_anno_variazione
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y,
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/

    )
    union
    select
    	'0000000'							macroag_code,
      	' '									macroag_desc,
        'Macroaggregato'					macroag_tipo_desc,
        '00'								missione_code,
        ' '									missione_desc,
        'Missione'							missione_tipo_desc,
        '0000'								programma_code,
        ' '									programma_desc,
        'Programma'							programma_tipo_desc,
        '0'									titusc_code,
        ' '									titusc_desc,
        'Titolo Spesa'						titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_ug tb
            left	join    siac_rep_cap_ug_imp_riga tb1
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_spese_riga tb2
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table
    and  tb1.periodo_anno=p_anno_variazione
   and (tb.programma_id is null or tb.macroaggregato_id is NULL)


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
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;

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

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;



raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
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