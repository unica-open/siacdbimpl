/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR124_gestione_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  residui_passivi numeric,
  previsioni_definitive_comp numeric,
  previsioni_definitive_cassa numeric,
  pagamenti_residui numeric,
  pagamenti_competenza numeric,
  riaccertamenti_residui numeric,
  impegni numeric,
  fondo_pluriennale_vincolato numeric,
  bil_ele_code3 varchar
) AS
$body$
DECLARE

classifBilRec record;

sql_query varchar;
sql_query_agg1 varchar; 
annoCapImp 			varchar;
annoCapImp_int integer;
tipoImpCassa 		varchar;
TipoImpstanz		varchar;
elemTipoCode 		varchar;
TipoImpstanzresidui varchar;
tipo_capitolo		varchar;
importo 			integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
v_fam_missioneprogramma varchar;
v_fam_titolomacroaggregato varchar;
v_det_tipo_importo_attuale varchar;
v_det_tipo_importo_iniziale varchar;
v_movgest_ts_tipo varchar;
v_movgest_tipo varchar;
v_ord_stato_code_annullato varchar;
v_ord_tipo_code_pagato	varchar;
BEGIN

annoCapImp:= p_anno; 
annoCapImp_int:= p_anno::integer;  

TipoImpstanzresidui='SRI'; 	-- stanziamento residuo iniziale (RS)
TipoImpstanz='STA'; 		-- stanziamento  (CP)
TipoImpCassa ='SCA'; 		----- cassa	(CS)
elemTipoCode:='CAP-UG'; 	-- tipo capitolo gestione
v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';
v_det_tipo_importo_attuale :='A';
v_det_tipo_importo_iniziale :='I';
v_movgest_ts_tipo:='T';
v_ord_stato_code_annullato:='A';
v_ord_tipo_code_pagato:='P';
v_movgest_tipo:='I';

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;

previsioni_definitive_cassa=0;
previsioni_definitive_comp=0;
residui_passivi=0;
pagamenti_residui=0;
pagamenti_competenza=0;
riaccertamenti_residui=0;
impegni=0;
fondo_pluriennale_vincolato=0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;
--da 6 secondi a 105 ms
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
    /* 07/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 07/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;

RTN_MESSAGGIO:='inserimento tabella di comodo dei capitoli ''.';
raise notice '2 - %' , clock_timestamp()::text;
/*-- da 395 ms a 78 ms	
with programma as (
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
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id),
macroag as (
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
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))--and now() between b.validita_inizio and coalesce (b.validita_fine,now())
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
cap as (
select 
c.*
from 
siac_t_bil a,
siac_t_periodo b,         
siac_t_bil_elem c,
siac_d_bil_elem_tipo d,
siac_r_bil_elem_stato e,
siac_d_bil_elem_stato f,
siac_r_bil_elem_categoria g,
siac_d_bil_elem_categoria h
where 
a.ente_proprietario_id=p_ente_prop_id
and a.periodo_id=b.periodo_id
and b.anno= p_anno 
and c.bil_id=a.bil_id
and d.elem_tipo_id=c.elem_tipo_id
and d.elem_tipo_code=elemTipoCode
and e.elem_id=c.elem_id
and e.elem_stato_id=f.elem_stato_id
and f.elem_stato_code	=	'VA'	
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between e.validita_inizio and COALESCE(e.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))and g.elem_id=c.elem_id
and h.elem_cat_id=g.elem_cat_id
and h.elem_cat_code	in	('STD','FPV', 'FSC')
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between g.validita_inizio and COALESCE(g.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
)
insert into siac_rep_cap_ug
select
programma.programma_id,
		macroag.macroag_id , 
        p_anno anno_bilancio,
        cap.* ,
        ' ',
        user_table utente
        from 
        programma, macroag, cap, 
siac_r_bil_elem_class i,
siac_r_bil_elem_class l
where  i.elem_id=cap.elem_id
        and i.classif_id=programma.programma_id
       and l.elem_id=cap.elem_id
and l.classif_id=macroag.macroag_id
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between i.validita_inizio and COALESCE(i.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between l.validita_inizio and COALESCE(l.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))and i.data_cancellazione is null
and l.data_cancellazione is null;*/

-- 21/03/2017: cambiati i codici dei classificatori per semplificare attività
-- 	per il report in formato XBRL
--IF p_classificatori = 'POLITICHE_REGIONALI_UNITARIE' THEN 
IF p_classificatori = 'PRU' THEN 
   sql_query_agg1 := 'and c.elem_id in (select rbec.elem_id
                      from siac_r_bil_elem_class rbec, siac_t_class tc, siac_d_class_tipo dct
                      where rbec.classif_id = tc.classif_id
                      and   tc.classif_tipo_id = dct.classif_tipo_id
                      and   dct.classif_tipo_code = ''POLITICHE_REGIONALI_UNITARIE''
                      and   tc.classif_code <> ''XX''
                      and   rbec.ente_proprietario_id='||p_ente_prop_id||'
                      and   rbec.data_cancellazione is null
                      and   tc.data_cancellazione is null
                      and   dct.data_cancellazione is null
                      and   to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between rbec.validita_inizio and COALESCE(rbec.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))
                     )';           
--ELSIF p_classificatori = 'TRANSAZIONE_UE_SPESA' THEN 
ELSIF p_classificatori = 'UE' THEN 
   sql_query_agg1 := 'and c.elem_id in (select rbec.elem_id
                      from siac_r_bil_elem_class rbec, siac_t_class tc, siac_d_class_tipo dct
                      where rbec.classif_id = tc.classif_id
                      and   tc.classif_tipo_id = dct.classif_tipo_id
                      and   dct.classif_tipo_code = ''TRANSAZIONE_UE_SPESA''
                      and   tc.classif_code <> ''8''
                      and   rbec.ente_proprietario_id='||p_ente_prop_id||'
                      and   rbec.data_cancellazione is null
                      and   tc.data_cancellazione is null
                      and   dct.data_cancellazione is null
                      and   to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between rbec.validita_inizio and COALESCE(rbec.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))
                     )';
--ELSIF p_classificatori = 'FlagFunzioniDelegate' THEN 
ELSIF p_classificatori = 'FD' THEN 
   sql_query_agg1 := 'and c.elem_id in (select rbea.elem_id
                    from siac_r_bil_elem_attr rbea, siac.siac_t_attr ta
                    where rbea.attr_id = ta.attr_id
                    and   ta.attr_code = ''FlagFunzioniDelegate''
                    and   rbea."boolean" = ''S''
                    and   rbea.ente_proprietario_id='||p_ente_prop_id||'
                    and   rbea.data_cancellazione is null
                    and   ta.data_cancellazione is null
                    and   to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between rbea.validita_inizio and COALESCE(rbea.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))
                   )';  
ELSE
   sql_query_agg1 := '';
END IF;   

	--07/09/2016: aggiunto FPVC nella query
sql_query := 'with programma as (
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
where a.ente_proprietario_id='||p_ente_prop_id||'
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '''||v_fam_missioneprogramma||'''
and to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id),
macroag as (
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
where a.ente_proprietario_id='||p_ente_prop_id||'
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = '''||v_fam_titolomacroaggregato||'''
and to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))--and now() between b.validita_inizio and coalesce (b.validita_fine,now())
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
cap as (
select 
c.*
from 
siac_t_bil a,
siac_t_periodo b,         
siac_t_bil_elem c,
siac_d_bil_elem_tipo d,
siac_r_bil_elem_stato e,
siac_d_bil_elem_stato f,
siac_r_bil_elem_categoria g,
siac_d_bil_elem_categoria h
where 
a.ente_proprietario_id='||p_ente_prop_id||'
and a.periodo_id=b.periodo_id
and b.anno='''||p_anno||'''
and c.bil_id=a.bil_id
and d.elem_tipo_id=c.elem_tipo_id
and d.elem_tipo_code='''||elemTipoCode||'''
and e.elem_id=c.elem_id
and e.elem_stato_id=f.elem_stato_id
and f.elem_stato_code	=	''VA''	
and to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between e.validita_inizio and COALESCE(e.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))and g.elem_id=c.elem_id
and h.elem_cat_id=g.elem_cat_id
and h.elem_cat_code	in	(''STD'',''FPV'',''FSC'',''FPVC'')
and to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between g.validita_inizio and COALESCE(g.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))and a.data_cancellazione is null
'||sql_query_agg1||'
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
)
insert into siac_rep_cap_ug
select
programma.programma_id,
		macroag.macroag_id , 
        '''||p_anno||''' anno_bilancio,
        cap.* ,
        '' '',
        '''||user_table||''' utente
        from 
        programma, macroag, cap, 
siac_r_bil_elem_class i,
siac_r_bil_elem_class l
where  i.elem_id=cap.elem_id
        and i.classif_id=programma.programma_id
       and l.elem_id=cap.elem_id
and l.classif_id=macroag.macroag_id
and to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between i.validita_inizio and COALESCE(i.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))
and to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy'') between l.validita_inizio and COALESCE(l.validita_fine,to_timestamp(''31/12/'||p_anno||''',''dd/mm/yyyy''))and i.data_cancellazione is null
and l.data_cancellazione is null';
--raise notice 'QUERY - %' , sql_query;
EXECUTE sql_query;

RTN_MESSAGGIO:='inserimento tabella di comodo degli importi per capitolo ''.';
raise notice '3 - %' , clock_timestamp()::text;
--da 530 ms  a 234 ms
insert into siac_rep_cap_ug_imp 
select 
a.elem_id,
d.anno BIL_ELE_IMP_ANNO,
c.elem_det_tipo_code 	TIPO_IMP,
a.ente_proprietario_id,
user_table utente,
sum(b.elem_det_importo)  
 from siac_rep_cap_ug a
, siac_t_bil_elem_det b, 
siac_d_bil_elem_det_tipo c,
siac_t_periodo d
where 
a.ente_proprietario_id=p_ente_prop_id
and a.elem_id=b.elem_id
and c.elem_det_tipo_id=b.elem_det_tipo_id
and d.periodo_id=b.periodo_id
and d.anno=annoCapImp
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and a.utente=user_table
group by	a.elem_id,
c.elem_det_tipo_code,
d.anno,a.ente_proprietario_id, utente
order by c.elem_det_tipo_code, d.anno; 
/*insert into siac_rep_cap_ug_imp 
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
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		and	cat_del_capitolo.elem_cat_code	in	('STD','FPV','FSC')	  -- ANNA 2206 FSC										
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
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;*/

RTN_MESSAGGIO:='inserimento tabella di comodo importi capitoli per riga ''.';

raise notice '4 - %' , clock_timestamp()::text;
 --inserimento degli importi x i capitolo STD
insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id,      
    	coalesce (tb1.importo,0)   as 		residui_passivi,
        coalesce (tb2.importo,0)   as 		previsioni_definitive_comp,
        coalesce (tb3.importo,0)   as 		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente
from 	siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb3,
        siac_r_bil_elem_categoria b, siac_d_bil_elem_categoria c
         where		tb1.elem_id = b.elem_id and
                    b.elem_cat_id = c.elem_cat_id and
                    --c.elem_cat_code = 'STD'       and
                    c.elem_cat_code in ('STD','FSC')       and -- ANNA 2206 FSC		
                    b.data_cancellazione is null  and
                    c.data_cancellazione is null  and
                    tb1.elem_id	=	tb2.elem_id	  and	
        			tb2.elem_id	=	tb3.elem_id	  and
                    tb1.utente = user_table       and
                    tb1.utente = tb2.utente       and
                    tb2.utente = tb3.utente       and
        			tb1.periodo_anno = annoCapImp		AND	tb1.tipo_imp =	TipoImpstanzresidui	AND
        			tb2.periodo_anno = tb1.periodo_anno	AND	tb2.tipo_imp = 	TipoImpstanz		AND
        			tb3.periodo_anno = tb1.periodo_anno	AND	tb3.tipo_imp = 	TipoImpCassa;            

raise notice '5 - %' , clock_timestamp()::text;
--inserimento degli importi x i capitolo FPV
insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id,      
    	0,
        coalesce (tb1.importo,0)   as fondo,
        0,
        tb1.ente_proprietario,
        user_table utente
from 	siac_rep_cap_ug_imp tb1,
        siac_r_bil_elem_categoria b, siac_d_bil_elem_categoria c
         where		tb1.elem_id = b.elem_id and
                    b.elem_cat_id = c.elem_cat_id and
                    --07/09/2016: aggiunto FPVC
                    c.elem_cat_code in ('FPV','FPVC')      and
                    b.data_cancellazione is null  and
                    c.data_cancellazione is null  and  
                    tb1.utente = user_table       and       
        			tb1.periodo_anno = annoCapImp		AND	tb1.tipo_imp = TipoImpstanz;

------------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEI PAGAMENTI IN CONTO RESIDUI (riferimento report PR)
------------------------------------------------------------------------------------------------------------------------------------

RTN_MESSAGGIO:='inserimento tabella di comodo pagamento residui ''.';
raise notice '6 - %' , clock_timestamp()::text;

with t_ord AS(
select 
m.elem_id,
h.ord_ts_id,
i.ord_ts_det_importo
 from siac_t_ordinativo a , siac_t_bil b,siac_t_periodo c,
 siac_d_ordinativo_tipo d,siac_r_ordinativo_stato f, siac_d_ordinativo_stato g,
  siac_t_ordinativo_ts h, siac_t_ordinativo_ts_det i, siac_d_ordinativo_ts_det_tipo 	l,
  siac_r_ordinativo_bil_elem m
 where 
a.ente_proprietario_id=p_ente_prop_id
and b.bil_id=a.bil_id
and c.periodo_id=b.periodo_id
and d.ord_tipo_id=a.ord_tipo_id
and d.ord_tipo_code		= 	v_ord_tipo_code_pagato
and f.ord_id=a.ord_id
and g.ord_stato_id=f.ord_stato_id
/* modifica INC000001498612
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between f.validita_inizio and COALESCE(f.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
*/
and now() between f.validita_inizio and COALESCE(f.validita_fine,now())
and c.anno = p_anno
-- modifica INC000001498612
and g.ord_stato_code <>v_ord_stato_code_annullato
and h.ord_id=a.ord_id
and i.ord_ts_id=h.ord_ts_id
and l.ord_ts_det_tipo_id=i.ord_ts_det_tipo_id
and l.ord_ts_det_tipo_code=v_det_tipo_importo_attuale
and m.ord_id=a.ord_id
and	a.data_cancellazione is null
and	b.data_cancellazione is null
and	c.data_cancellazione is null
and	d.data_cancellazione is null
and	f.data_cancellazione is null
AND	g.data_cancellazione is null
AND h.data_cancellazione is null
aND i.data_cancellazione is null
and l.data_cancellazione is null
and	m.data_cancellazione is null
),
t_liq AS(
SELECT 
d.sord_id
 from siac_T_movgest a, siac_t_movgest_ts b,siac_r_liquidazione_movgest c,
siac_r_liquidazione_ord d
--  modifica INC000001498612
, siac_t_bil e,siac_t_periodo f
--  modifica INC000001498612
where 
a.ente_proprietario_id=p_ente_prop_id
and b.movgest_id=a.movgest_id
and a.movgest_anno<annoCapImp_int
and c.movgest_ts_id=b.movgest_ts_id
-- modifica INC000001498612
and e.periodo_id=f.periodo_id
and f.anno = p_anno
and a.bil_id = e.bil_id
-- modifica INC000001498612
/* modifica INC000001498612
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between c.validita_inizio and COALESCE(c.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
*/
and now() between c.validita_inizio and COALESCE(c.validita_fine,now())
--- modifica INC000001498612
and d.liq_id=c.liq_id
/* modifica INC000001498612
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between d.validita_inizio and COALESCE(d.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy')) 
*/
and now() between d.validita_inizio and COALESCE(d.validita_fine,now()) 
--- modifica INC000001498612
and	a.data_cancellazione is null
and	b.data_cancellazione is null
and	c.data_cancellazione is null
and	d.data_cancellazione is null
)
insert into siac_rep_pagam_residui_ug
select 
z.elem_id,
sum(z.ord_ts_det_importo),
p_ente_prop_id,
user_table utente
 from t_ord z,t_liq x
where z.ord_ts_id=x.sord_id
group by z.elem_id;
/*
insert into siac_rep_pagam_residui_ug
select 		c.elem_id,
            sum(i.ord_ts_det_importo),
          p_ente_prop_id,
            user_table utente
from 		siac_t_bil 						a,
	 		siac_t_periodo 					b, 
            siac_r_ordinativo_bil_elem		c,
            siac_t_ordinativo				d,
            siac_d_ordinativo_tipo			e,
            siac_r_ordinativo_stato			f,
            siac_d_ordinativo_stato			g,
            siac_t_ordinativo_ts 			h,
			siac_t_ordinativo_ts_det 		i,
        	siac_d_ordinativo_ts_det_tipo 	l,
            siac_t_movgest     				m,
            siac_t_movgest_ts    			n, 
            siac_r_liquidazione_movgest     o,
            siac_r_liquidazione_ord         p     
    where 	b.anno						= 	p_anno											
    	and	a.periodo_id					=	b.periodo_id
        and	a.ente_proprietario_id	=	p_ente_prop_id
        and	c.ord_id		=	d.ord_id
        and	d.ord_tipo_id				=	e.ord_tipo_id
		and	e.ord_tipo_code		= 	v_ord_tipo_code_pagato
        and	d.ord_id					=	f.ord_id
        and	f.ord_stato_id		=	g.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    si prendono gli stati Q, F, T
        ----------------------	  da verificare se è giusto.
        -- Q= QUIETANZATO, F= FIRMATO, T= TRASMESSO
        -- I= INSERITO, A= ANNULLATO
        and	g.ord_stato_code		<> v_ord_stato_code_annullato
        -----------------------------------------------------------------------------------------------
        and	d.bil_id					=	a.bil_id
        and	d.ord_id					=	h.ord_id
        and	h.ord_ts_id			=	i.ord_ts_id
        and	i.ord_ts_det_tipo_id	=	l.ord_ts_det_tipo_id
        and	l.ord_ts_det_tipo_code	=	v_det_tipo_importo_attuale	---- importo attuale
        ---------------------------------------------------------------------------------------------------------------------
        and p.sord_id                    =   h.ord_ts_id
        and	p.liq_id		                =	o.liq_id
        and	o.movgest_ts_id	        =	n.movgest_ts_id
        and	n.movgest_id				=	m.movgest_id
        and	m.movgest_anno				<	annoCapImp_int	
        and m.bil_id					=	a.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	a.data_cancellazione 				is null
        and	b.data_cancellazione 				is null
        and	c.data_cancellazione	is null
        and	d.data_cancellazione				is null
        AND	e.data_cancellazione			is null
        and	f.data_cancellazione		is null
        AND	g.data_cancellazione			is null
        AND h.data_cancellazione			is null
 	  	aND i.data_cancellazione			is null
        and l.data_cancellazione		is null
        and	m.data_cancellazione				is null
        and	n.data_cancellazione				is null
        and	p.data_cancellazione		            is null
        and	o.data_cancellazione		        is null
  and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between c.validita_inizio and COALESCE(c.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
        and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between f.validita_inizio and COALESCE(f.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
        and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between o.validita_inizio and COALESCE(o.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
        and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between p.validita_inizio and COALESCE(p.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
group by c.elem_id,c.ente_proprietario_id;

*/
RTN_MESSAGGIO:='inserimento tabella di comodo pagamento  ''.';

-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEI PAGAMENTI IN CONTO COMPETENZA (riferimento report PC)
-----------------------------------------------------------------------------------------------------------------------------------

raise notice '7 - %' , clock_timestamp()::text;
insert into siac_rep_pagam_ug
select 		c.elem_id,
            sum(i.ord_ts_det_importo),
            p_ente_prop_id,
           user_table utente
from 		siac_t_bil 						a,
	 		siac_t_periodo 					b, 
            siac_r_ordinativo_bil_elem		c,
            siac_t_ordinativo				d,
            siac_d_ordinativo_tipo			e,
            siac_r_ordinativo_stato			f,
            siac_d_ordinativo_stato			g,
            siac_t_ordinativo_ts 			h,
			siac_t_ordinativo_ts_det 		i,
        	siac_d_ordinativo_ts_det_tipo 	l,
            siac_t_movgest     				m,
            siac_t_movgest_ts    			n, 
            siac_r_liquidazione_movgest     o,
            siac_r_liquidazione_ord         p     
    where 	b.anno						= 	p_anno											
    	and	a.periodo_id					=	b.periodo_id
        and	a.ente_proprietario_id	=	p_ente_prop_id
        and	c.ord_id		=	d.ord_id
        and	d.ord_tipo_id				=	e.ord_tipo_id
		and	e.ord_tipo_code		= v_ord_tipo_code_pagato
        and	d.ord_id					=	f.ord_id
        and	f.ord_stato_id		=	g.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    si prendono gli stati Q, F, T
        ----------------------	  da verificare se è giusto.
        -- Q= QUIETANZATO, F= FIRMATO, T= TRASMESSO
        -- I= INSERITO, A= ANNULLATO
        and	g.ord_stato_code		<> v_ord_stato_code_annullato
        -----------------------------------------------------------------------------------------------
        and	d.bil_id					=	a.bil_id
        and	d.ord_id					=	h.ord_id
        and	h.ord_ts_id			=	i.ord_ts_id
        and	i.ord_ts_det_tipo_id	=	l.ord_ts_det_tipo_id
        and	l.ord_ts_det_tipo_code	=	v_det_tipo_importo_attuale	---- importo attuale
        ---------------------------------------------------------------------------------------------------------------------
        and p.sord_id                    =   h.ord_ts_id
        and	p.liq_id		                =	o.liq_id
        and	o.movgest_ts_id	        =	n.movgest_ts_id
        and	n.movgest_id				=	m.movgest_id
        and	m.movgest_anno				=	annoCapImp_int	
        and m.bil_id					=	a.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	a.data_cancellazione 				is null
        and	b.data_cancellazione 				is null
        and	c.data_cancellazione	is null
        and	d.data_cancellazione				is null
        AND	e.data_cancellazione			is null
        and	f.data_cancellazione		is null
        AND	g.data_cancellazione			is null
        AND h.data_cancellazione			is null
 	  	aND i.data_cancellazione			is null
        and l.data_cancellazione		is null
        and	m.data_cancellazione				is null
        and	n.data_cancellazione				is null
        and	p.data_cancellazione		            is null
        and	o.data_cancellazione		        is null
  		/*  modifica INC000001498612
        and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between c.validita_inizio and COALESCE(c.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
        and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between f.validita_inizio and COALESCE(f.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
        and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between o.validita_inizio and COALESCE(o.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
        and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between p.validita_inizio and COALESCE(p.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
		*/
        and now() between c.validita_inizio and COALESCE(c.validita_fine,now())
        and now() between f.validita_inizio and COALESCE(f.validita_fine,now())
        and now() between o.validita_inizio and COALESCE(o.validita_fine,now())
        and now() between p.validita_inizio and COALESCE(p.validita_fine,now())
		---  modifica INC000001498612
group by c.elem_id,c.ente_proprietario_id;



--------------------------------------------------------------------------------------------------------------------------------
--- 10/06/2016: inserita l'acquisizione dei riaccertamenti residui, cioè
---		degli impegni che sono stati modificati.
-------		ACQUISIZIONE RIACCERTAMENTI RESIDUI (riferimento report R) 
------    riporto la nota presente sul foglio excel di ARCONET relativa al conto del bilancio - gestione entrate
/*Indicare l'ammontare complessivo derivante dal riaccertamento dei residui (sia l'importo dei debiti  
definitivamente cancellati dalle scritture, sia,  l'importo dei debitii cancellati e reimputati agli 
esercizi successivi effettuato in occasione del riaccertamento straordinario dei residui). Non riguarda 
il riaccertamento di impegni di competenza dell'esercizio cui si riferisce il rendiconto. In sede di 
riaccertamento dei residui non può essere effettuata una rettifica in aumento dei residui passivi se 
non nei casi espressamente consentiti  (Principio contabile applicato della contabilità finanziaria 9.1  
di cui all'Allegato n. 4-2). Le rettifiche in aumento sono indicate con il segno "+", 
le rettifiche in riduzione sono indicate con il segno "-".   */ 
-----------------------------------------------------------------------------------------------------------------------------------

RTN_MESSAGGIO:='inserimento tabella di comodo riaccertamenti residui ''.';
raise notice '8 - %' , clock_timestamp()::text;
INSERT INTO siac_rep_ug_riacc_residui
select  
a.elem_id,
       sum (q.movgest_ts_det_importo) importo,
       p_ente_prop_id,
       user_table utente
from siac_rep_cap_ug a,
siac_r_movgest_bil_elem   b, --r_mov_capitolo, 
 siac_t_movgest    c,-- movimento, 
      siac_d_movgest_tipo  d,--  tipo_mov, 
      siac_t_movgest_ts  e,--  ts_movimento, 
      siac_r_movgest_ts_stato f,--  r_movimento_stato, 
      siac_d_movgest_stato   g,-- tipo_stato, 
      siac_t_movgest_ts_det h,--  dt_movimento, 
      siac_d_movgest_ts_tipo i,--  ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo l,-- dt_mov_tipo ,
      -- modifiche
      siac_t_modifica m,--t_modifica,
      siac_r_modifica_stato o,--r_mod_stato,
      siac_d_modifica_stato p,--d_mod_stato,
      siac_t_movgest_ts_det_mod q--t_movgest_ts_det_mod
where a.ente_proprietario_id=p_ente_prop_id
      and a.elem_id	= b.elem_id
	  and b.movgest_id = c.movgest_id 
--      and c.bil_id	= a.bil_id
       and c.movgest_anno < p_anno::integer
	   and c.movgest_tipo_id = d.movgest_tipo_id 
	   and d.movgest_tipo_code = v_movgest_tipo
      and c.movgest_id = e.movgest_id 
      and e.movgest_ts_id  = f.movgest_ts_id 
      and f.movgest_stato_id  = g.movgest_stato_id 
     /* modifica INC000001498612
     and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between f.validita_inizio and COALESCE(f.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))  
     */
      and now() between f.validita_inizio and COALESCE(f.validita_fine,now())  
	--  modifica INC000001498612   
     and g.movgest_stato_code   in ('D','N') 
      and h.movgest_ts_id    	= e.movgest_ts_id
      and i.movgest_ts_tipo_id  = e.movgest_ts_tipo_id 
      and i.movgest_ts_tipo_code  = v_movgest_ts_tipo 
      and l.movgest_ts_det_tipo_id  = h.movgest_ts_det_tipo_id 
      and l.movgest_ts_det_tipo_code = v_det_tipo_importo_attuale ----- importo attuale 
      and q.movgest_ts_id=e.movgest_ts_id      
      and q.mod_stato_r_id=o.mod_stato_r_id
 	  /* modifica INC000001498612
   	  and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between o.validita_inizio and COALESCE(o.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))  
      */
      and now() between o.validita_inizio and COALESCE(o.validita_fine,now())  
      --- modifica INC000001498612
      and p.mod_stato_id=o.mod_stato_id  
      and p.mod_stato_code='V'
      and o.mod_id=m.mod_id
     	 -- 05/01/2017: tolto il legame con la tabella che definisce la tipologia di modifica
      --and m.mod_tipo_id=n.mod_tipo_id  
      and b.data_cancellazione is null 
      and c.data_cancellazione     	is null 
      and d.data_cancellazione     	is null 
      and f.data_cancellazione   is null 
      and e.data_cancellazione   is null 
      and g.data_cancellazione    	is null 
      and h.data_cancellazione   is null 
      and i.data_cancellazione    is null 
      and l.data_cancellazione    is null
      and m.data_cancellazione    is null
      --and n.data_cancellazione is null
      and o.data_cancellazione    is null
      and p.data_cancellazione is null
      and q.data_cancellazione    is null
group by a.elem_id;       

/*INSERT INTO siac_rep_ug_riacc_residui
	SELECT capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) importo,
       p_ente_prop_id,
       user_table utente
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      -- modifiche
      siac_t_modifica t_modifica,
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno ::text  	< 	p_anno
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'I' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id
      and t_modifica.mod_tipo_id=d_modif_tipo.mod_tipo_id  
      and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      and   now() between t_movgest_ts_det_mod.validita_inizio and coalesce (t_movgest_ts_det_mod.validita_fine, now())
      --and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      ---and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id, p_ente_prop_id;                   */ 

--------------------------------------------------------------------------------------------------------------------------------
-------		 ACQUISIZIONE IMPEGNI (riferimento report I) 
------    riporto la nota presente sul foglio excel di ARCONET relativa al conto del bilancio - gestione entrate
/*Indicare gli impegni imputati contabilmente  all'esercizio cui il rendiconto si riferisce  al netto 
dei debiti che, in occasione del riaccertamento ordinario dei residui effettuato ai sensi dell'articolo 3, 
comma 4, risultassero non esigibili  e reimputati agli esercizi in cui le obbligazioni risultano esigibili. 
Nel primo esercizio di applicazione del titolo primo del decreto legislativo n. 118 del 2011, la voce 
comprende i debiti  che sono stati cancellati nell'ambito del riaccertamento straordinario dei residui con imputazione all'esercizio. */
-----------------------------------------------------------------------------------------------------------------------------------

RTN_MESSAGGIO:='inserimento tabella di comodo impegnato ''.';
raise notice '9 - %' , clock_timestamp()::text;
insert into siac_rep_impegni
WITH t_bil_elem as (
 select a.elem_id,e.movgest_id from siac_t_bil_elem a, siac_t_bil b, siac_t_periodo c, siac_d_bil_elem_tipo d,
 siac_r_movgest_bil_elem   e
 where 
 a.ente_proprietario_id=p_ente_prop_id
 and b.bil_id=a.bil_id
 and c.periodo_id=b.periodo_id
 and c.anno=p_anno
 and d.elem_tipo_id=a.elem_tipo_id
 and d.elem_tipo_code=elemTipoCode
 and a.elem_id=e.elem_id
 /* modifica INC000001498612
 and to_timestamp('31/12/'||'2016','dd/mm/yyyy') between e.validita_inizio and COALESCE(e.validita_fine,to_timestamp('31/12/'||'2016','dd/mm/yyyy'))
 */
 and now() between e.validita_inizio and COALESCE(e.validita_fine,now())
 -- modifica INC000001498612
),
 t_movgest as (
select f.movgest_id, m.movgest_ts_det_importo From 
 siac_t_movgest f, siac_d_movgest_tipo g,siac_t_movgest_ts h,siac_d_movgest_ts_tipo j, 
 siac_r_movgest_ts_stato i, siac_d_movgest_stato l, siac_t_movgest_ts_det m,
 siac_d_movgest_ts_det_tipo o
 --- modifica INC000001498612
 ,siac_t_bil q, siac_t_periodo r
 ---
where f.ente_proprietario_id=p_ente_prop_id
and f.movgest_anno=p_anno::integer
and f.movgest_tipo_id=g.movgest_tipo_id
and g.movgest_tipo_code=v_movgest_tipo
and h.movgest_id=f.movgest_id
and i.movgest_ts_id=h.movgest_ts_id
and i.movgest_stato_id=l.movgest_stato_id
/* modifica INC000001498612
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between i.validita_inizio and COALESCE(i.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
*/
and q.periodo_id = r.periodo_id
and r.anno=p_anno 
and q.bil_id=f.bil_id
and now() between i.validita_inizio and COALESCE(i.validita_fine,now())
-- modifica INC000001498612
and l.movgest_stato_code   in ('D','N')
and m.movgest_ts_id=h.movgest_ts_id
and j.movgest_ts_tipo_id=h.movgest_ts_tipo_id
and j.movgest_ts_tipo_code=v_movgest_ts_tipo
and m.movgest_ts_id=h.movgest_ts_id
and m.movgest_ts_det_tipo_id=o.movgest_ts_det_tipo_id
and o.movgest_ts_det_tipo_code=v_det_tipo_importo_attuale)
select z.elem_id,
p_anno,
		p_ente_prop_id,
		user_table utente,
sum (x.movgest_ts_det_importo) importo from t_bil_elem z,t_movgest x
where z.movgest_id=x.movgest_id
group by z.elem_id;

/*select 	tb2.elem_id,
		p_anno,
		p_ente_prop_id,
		user_table utente,
        tb.importo
from (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno ::text  	= 	p_anno
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= v_movgest_tipo
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      -- D= DEFINITIVO, N= DEFINITIVO NON LIQUIDABILE
      -- P=PROVVISORIO, A= ANNULLATO
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = v_movgest_ts_tipo 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = v_det_tipo_importo_attuale ----- importo attuale 
      and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)
tb 
,
(select * from  siac_t_bil_elem    			capitolo_ug,
      			siac_d_bil_elem_tipo    	t_capitolo_ug
      where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
      and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;*/

-- 16/06/2016: calcolato in modo diverso l'importo degli impegni residui
--  introdotta nuova tabella
raise notice '10 - %' , clock_timestamp()::text;
insert into siac_rep_impegni_residui
select 	tb.elem_id,
p_anno,
p_ente_prop_id,
user_table utente,
tb.importo
from (
select    
c.elem_id,
sum (m.movgest_ts_det_importo) importo
from 
siac_t_bil      a,--bilancio, 
siac_t_periodo   b,--  anno_eserc, 
siac_t_bil_elem  c,--  capitolo , 
siac_r_movgest_bil_elem d,--r_mov_capitolo, 
siac_d_bil_elem_tipo   e,-- t_capitolo, 
siac_t_movgest    f,-- movimento, 
siac_d_movgest_tipo g,--   tipo_mov, 
siac_t_movgest_ts  h,-- ts_movimento, 
siac_r_movgest_ts_stato  i,-- r_movimento_stato, 
siac_d_movgest_stato   l,-- tipo_stato, 
siac_t_movgest_ts_det  m,-- dt_movimento, 
siac_d_movgest_ts_tipo  n,-- ts_mov_tipo, 
siac_d_movgest_ts_det_tipo o --dt_mov_tipo 
where a.periodo_id = b.periodo_id 
and b.anno = p_anno 
and a.bil_id = c.bil_id 
and d.elem_id =	c.elem_id
and c.elem_tipo_id = e.elem_tipo_id
and e.elem_tipo_code = 	elemTipoCode
and f.movgest_anno < p_anno::integer
and f.bil_id = a.bil_id
and d.movgest_id = f.movgest_id 
/* modifica INC000001498612
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between d.validita_inizio and COALESCE(d.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
*/
and now() between d.validita_inizio and COALESCE(d.validita_fine,now())
-- modifica INC000001498612
and g.movgest_tipo_code = v_movgest_tipo 
and f.movgest_id = h.movgest_id 
and h.movgest_ts_id = i.movgest_ts_id 
/* modifica INC000001498612
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between i.validita_inizio and COALESCE(i.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
*/
and now() between i.validita_inizio and COALESCE(i.validita_fine,now())
-- modifica INC000001498612
and i.movgest_stato_id  = l.movgest_stato_id 
-- D= DEFINITIVO, N= DEFINITIVO NON LIQUIDABILE
-- P=PROVVISORIO, A= ANNULLATO
and l.movgest_stato_code in ('D','N') ------ P,A,N 
and h.movgest_ts_tipo_id = n.movgest_ts_tipo_id 
and n.movgest_ts_tipo_code = v_movgest_ts_tipo 
and h.movgest_ts_id = m.movgest_ts_id 
and m.movgest_ts_det_tipo_id  = o.movgest_ts_det_tipo_id 
and o.movgest_ts_det_tipo_code = v_det_tipo_importo_iniziale ----- importo iniziale 
and a.data_cancellazione is null 
and b.data_cancellazione is null      
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null
and b.ente_proprietario_id = p_ente_prop_id
group by c.elem_id)
tb ;
/*select 	tb2.elem_id,
		p_anno,
		p_ente_prop_id,
		user_table utente,
        tb.importo
from (
select    
capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo
    from 
      siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno ::text  	< 	p_anno
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'I' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      -- D= DEFINITIVO, N= DEFINITIVO NON LIQUIDABILE
      -- P=PROVVISORIO, A= ANNULLATO
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'I' ----- importo iniziale 
      and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
      and	now() between r_mov_capitolo.validita_inizio and coalesce (r_mov_capitolo.validita_fine, now())
      and	now() between r_movimento_stato.validita_inizio and coalesce (r_movimento_stato.validita_fine, now())
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)
tb 
,
(select * from  siac_t_bil_elem    			capitolo_ug,
      			siac_d_bil_elem_tipo    	t_capitolo_ug
      where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
      and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;*/
 
--------------------------------------------------------------------------------------------------------------------------------
-------		MANCA ACQUISIZIONE FONDO PLURIENNALE VINCOLATO (riferimento report FPV) 
------    riporto la nota presente sul foglio excel di ARCONET relativa al conto del bilancio - gestione entrate
/*Indicare l'importo corrispondente agli impegni imputati agli esercizi successivi finanziati con il fondo pluriennale vincolato */
-----------------------------------------------------------------------------------------------------------------------------------

 RTN_MESSAGGIO:='estrazione dei dati dalle tabelle di comodo e preparazione dati in output ''.';                
raise notice '11 - %' , clock_timestamp()::text;
for classifBilRec in
select 	v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
		v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        tb.elem_code     				BIL_ELE_CODE,
        tb.elem_code2     				BIL_ELE_CODE2,
        tb.elem_code3					BIL_ELE_CODE3,
		tb.elem_desc     				BIL_ELE_DESC,
        tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
    	--COALESCE(tb1.residui_passivi,0)				residui_passivi,
        COALESCE(tb7.importo,0)						residui_passivi,
    	COALESCE(tb1.previsioni_definitive_comp,0)	previsioni_definitive_comp,
    	COALESCE(tb1.previsioni_definitive_cassa,0)	previsioni_definitive_cassa,
   	 	COALESCE(tb2.pagamenti_residui,0)			pagamenti_residui,
    	COALESCE(tb3.pagamenti_competenza,0)		pagamenti_competenza,
        COALESCE(tb4.importo,0)						impegni,
        COALESCE(tb5.fondo,0)	                    fondo,
        COALESCE(tb6.riaccertamenti_residui,0)		riaccertamenti_residui
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
			left  join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga 	tb1  	on tb1.elem_id	=	tb.elem_id 	
			left    join	siac_rep_pagam_residui_ug 	tb2		on tb2.elem_id	=	tb.elem_id 
            left 	join	siac_rep_pagam_ug			tb3		on tb3.elem_id	=	tb.elem_id
            left    join 	siac_rep_impegni			tb4		on tb4.elem_id	=	tb.elem_id		
            left    join    ( select  a.elem_id, coalesce (a.previsioni_definitive_comp,0)   as fondo          
                              from    siac_rep_cap_ug_imp_riga a,  siac_rep_cap_ug_imp b,
                                      siac_r_bil_elem_categoria c, siac_d_bil_elem_categoria d
                              where   a.elem_id = b.elem_id
                              and     b.elem_id = c.elem_id
                              and     a.utente = b.utente
                              and     c.elem_cat_id = d.elem_cat_id
                              --07/09/2016: aggiunto FPVC
                              and     d.elem_cat_code in ('FPV','FPVC') 
                              and     c.data_cancellazione is null     
                              and     d.data_cancellazione is null    
                              and     b.periodo_anno = annoCapImp
                              and     b.tipo_imp = TipoImpstanz
                             )    tb5     on tb5.elem_id	=	tb.elem_id
            left 	join 	siac_rep_ug_riacc_residui 	tb6 		on tb6.elem_id	=	tb.elem_id		
            left 	join 	siac_rep_impegni_residui 	tb7 		on tb7.elem_id	=	tb.elem_id		
           
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop

missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc:= classifBilRec.programma_tipo_desc;
programma_code:= classifBilRec.programma_code;
programma_desc:= classifBilRec.programma_desc;
titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
titusc_code:= classifBilRec.titusc_code;
titusc_desc:= classifBilRec.titusc_desc;
macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
macroag_code:= classifBilRec.macroag_code;
macroag_desc:= classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
bil_anno:=p_anno;
previsioni_definitive_cassa:=classifBilRec.previsioni_definitive_cassa;
previsioni_definitive_comp:=classifBilRec.previsioni_definitive_comp;
residui_passivi:=classifBilRec.residui_passivi;
pagamenti_residui:=classifBilRec.pagamenti_residui;
pagamenti_competenza:=classifBilRec.pagamenti_competenza;
impegni:=classifBilRec.impegni;
fondo_pluriennale_vincolato:=classifBilRec.fondo;
riaccertamenti_residui:=classifBilRec.riaccertamenti_residui;

return next;
bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
previsioni_definitive_cassa=0;
previsioni_definitive_comp=0;
residui_passivi=0;
pagamenti_residui=0;
pagamenti_competenza=0;
riaccertamenti_residui=0;
impegni=0;
fondo_pluriennale_vincolato=0;
end loop;
raise notice '12 - %' , clock_timestamp()::text;

delete from siac_rep_mis_pro_tit_mac_riga_anni 		where utente=user_table;
delete from siac_rep_cap_ug 						where utente=user_table;
delete from siac_rep_cap_ug_imp 					where utente=user_table;
delete from siac_rep_cap_ug_imp_riga				where utente=user_table;
delete from	siac_rep_pagam_residui_ug				where utente=user_table;
delete from	siac_rep_pagam_ug						where utente=user_table;
delete from	siac_rep_impegni						where utente=user_table;
delete from	siac_rep_ug_riacc_residui				where utente=user_table;
delete from	siac_rep_impegni_residui				where utente=user_table;
raise notice '13 - %' , clock_timestamp()::text;
raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
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