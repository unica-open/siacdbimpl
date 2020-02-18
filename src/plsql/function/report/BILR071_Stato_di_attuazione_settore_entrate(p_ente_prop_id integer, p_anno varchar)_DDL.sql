/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR071_Stato_di_attuazione_settore_entrate" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  nome_ente varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  sett_code varchar,
  sett_descr varchar,
  stanz_attuale numeric,
  accertato numeric,
  reversali_emesse numeric,
  variazioni_provv numeric,
  esiste_vincolo varchar,
  tipo_finanziamento varchar
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
numCapitoli	integer;
ente_denominazione varchar;
num_vincoli integer;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;  

TipoImpstanzresidui='SRI'; -- stanziamento residuo iniziale (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

bil_anno='';
titoloe_tipo_code='';
titoloe_tipo_desc='';
titoloe_code='';
titoloe_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_code3='';
bil_ele_id=0;
bil_ele_id_padre=0;
sett_code='';
sett_descr='';
stanz_attuale=0;
accertato=0;
reversali_emesse=0;
variazioni_provv=0;
nome_ente='';
esiste_vincolo='';
tipo_finanziamento='';

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;




RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'inserimento tabella di comodo STRUTTURA DEL BILANCIO ';
/*
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;
*/

--05/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;
 
 
raise notice 'ora: % ',clock_timestamp()::varchar;

RTN_MESSAGGIO:='inserimento tabella di comodo dei capitoli ''.';
raise notice 'inserimento tabella di comodo dei capitoli ';

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


raise notice 'ora: % ',clock_timestamp()::varchar;



RTN_MESSAGGIO:='inserimento tabella di comodo degli importi per capitolo ''.';
raise notice 'inserimento tabella di comodo degli importi per capitolo ';

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente, 
            sum(capitolo_importi.elem_det_importo)     
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

raise notice 'ora: % ',clock_timestamp()::varchar;


RTN_MESSAGGIO:='inserimento tabella di comodo importi capitoli per riga ''.';

raise notice 'inserimento tabella di comodo importi capitoli per riga ';

insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		residui_attivi,
        coalesce (tb2.importo,0)   as 		previsioni_definitive_cassa, /* STA */
        coalesce (tb3.importo,0)   as 		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb3
	where			tb1.elem_id	=	tb2.elem_id													and			
        			tb2.elem_id	=	tb3.elem_id													and
        			tb1.periodo_anno = annoCapImp		AND	tb1.tipo_imp =	TipoImpstanzresidui	AND
        			tb2.periodo_anno = tb1.periodo_anno	AND	tb2.tipo_imp = 	TipoImpstanz		AND
        			tb3.periodo_anno = tb1.periodo_anno	AND	tb3.tipo_imp = 	TipoImpCassa;	

raise notice 'ora: % ',clock_timestamp()::varchar;

-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DELLE Reversali
-----------------------------------------------------------------------------------------------------------------------------------

RTN_MESSAGGIO:='inserimento tabella di comodo reversali  ''.';
raise notice 'inserimento tabella di comodo reversali  ';



insert into siac_rep_riscos_eg
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo),
            p_ente_prop_id,
            user_table utente
from 		siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
            siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
            siac_t_ordinativo				ordinativo,
            siac_d_ordinativo_tipo			tipo_ordinativo,
            siac_r_ordinativo_stato			r_stato_ordinativo,
            siac_d_ordinativo_stato			stato_ordinativo,
            siac_t_ordinativo_ts 			ordinativo_det,
			siac_t_ordinativo_ts_det 		ordinativo_imp,
        	siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
            siac_t_movgest     				movimento,
            siac_t_movgest_ts    			ts_movimento, 
            siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
    where 	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	bilancio.ente_proprietario_id	=	p_ente_prop_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	'I'		------ incasso
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    PRENDO GLI STATI "INSERITO" E "TRASMESSO"
		------------------------------------------------------------------------------------------		
        and	stato_ordinativo.ord_stato_code		IN	('I','T') --- 
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuale
        ---------------------------------------------------------------------------------------------------------------------
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        and	movimento.movgest_anno				=	annoCapImp_int	
        and movimento.bil_id					=	bilancio.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
        and	r_capitolo_ordinativo.data_cancellazione	is null
        and	ordinativo.data_cancellazione				is null
        AND	tipo_ordinativo.data_cancellazione			is null
        and	r_stato_ordinativo.data_cancellazione		is null
        AND	stato_ordinativo.data_cancellazione			is null
        AND ordinativo_det.data_cancellazione			is null
 	  	aND ordinativo_imp.data_cancellazione			is null
        and ordinativo_imp_tipo.data_cancellazione		is null
        and	movimento.data_cancellazione				is null
        and	ts_movimento.data_cancellazione				is null
        and	r_ordinativo_movgest.data_cancellazione		is null
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        ---and	now() between	r_capitolo_ordinativo.validita_inizio and coalesce (r_capitolo_ordinativo.validita_fine, now())
        ---and	now() between	r_stato_ordinativo.validita_inizio and coalesce (r_stato_ordinativo.validita_fine, now())
        ---and	now() between	r_ordinativo_movgest.validita_inizio and coalesce (r_ordinativo_movgest.validita_fine, now())
        group by r_capitolo_ordinativo.elem_id,r_capitolo_ordinativo.ente_proprietario_id;
raise notice 'ora: % ',clock_timestamp()::varchar;

BEGIN
	select 	ente_prop.ente_denominazione
    INTO ente_denominazione
	from  	siac_t_ente_proprietario	ente_prop			
		where     ente_prop.ente_proprietario_id = p_ente_prop_id;			
   IF NOT FOUND THEN
      RAISE EXCEPTION 'Non esiste l''ente %', p_ente_prop_id;
      return;   
    END IF;
END;



RTN_MESSAGGIO:='acquisizione degli accertamenti ''.'; 
  raise notice 'acquisizione degli accertamenti  ';  

  /*
insert into siac_rep_accertamenti
select 	tb2.elem_id,
		tb.importo,
		p_ente_prop_id,
		user_table utente
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
      and movimento.movgest_anno 		  	= 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())
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
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
group by capitolo.elem_id)
tb 
,
(select * from  siac_t_bil_elem    			capitolo_eg,
      			siac_d_bil_elem_tipo    	t_capitolo_eg
      where capitolo_eg.elem_tipo_id		=	t_capitolo_eg.elem_tipo_id 
      and 	t_capitolo_eg.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;
*/



insert into siac_rep_accertamenti
select 	tb2.elem_id,
		tb.importo,
		p_ente_prop_id,
		user_table utente
from 
(select capitolo.elem_id,
sum (dt_movimento.movgest_ts_det_importo) importo
 from siac_t_bil      bilancio, 
      siac_t_periodo     anno_eserc, 
      siac_t_bil_elem     capitolo,
      siac_d_bil_elem_tipo    t_capitolo,
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_t_movgest     movimento,
       siac_d_movgest_tipo    tipo_mov,
       siac_t_movgest_ts    ts_movimento,
        siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato,
      siac_t_movgest_ts_det   dt_movimento,
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo 
 where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id  
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and anno_eserc.anno       			=   p_anno 
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode    
      and movimento.movgest_anno 		  	= 	annoCapImp_int
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and tipo_mov.movgest_tipo_code    	= 'A'
      and anno_eserc.ente_proprietario_id   = p_ente_prop_id
      and tipo_stato.movgest_stato_code   in ('D','N')
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'     
	  and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
      and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
      and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
      and	now() between t_capitolo.validita_inizio and coalesce (t_capitolo.validita_fine, now())
      and	now() between movimento.validita_inizio and coalesce (movimento.validita_fine, now())
      and	now() between ts_movimento.validita_inizio and coalesce (ts_movimento.validita_fine, now())             
      and anno_eserc.data_cancellazione    	is null 
      and bilancio.data_cancellazione     	is null 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and ts_movimento.data_cancellazione	is null
      and r_movimento_stato.data_cancellazione	is null
      and tipo_stato.data_cancellazione	is null
      and dt_movimento.data_cancellazione is null
      and ts_mov_tipo.data_cancellazione is null
      and dt_mov_tipo.data_cancellazione is null
      group by capitolo.elem_id) tb, 
   (select * from  siac_t_bil_elem    			capitolo_eg,
      			siac_d_bil_elem_tipo    	t_capitolo_eg
      where capitolo_eg.elem_tipo_id		=	t_capitolo_eg.elem_tipo_id 
      and 	t_capitolo_eg.elem_tipo_code 	= 	elemTipoCode) tb2
where
 tb2.elem_id	=	tb.elem_id;
      
      
raise notice 'ora: % ',clock_timestamp()::varchar;

 RTN_MESSAGGIO:='acquisizione delle variazioni''.';   
   raise notice 'estrazione delle variazioni ';  

insert into siac_rep_var_entrate
select bil_elem_det_var.elem_id, sum(bil_elem_det_var.elem_det_importo) IMPORTO,
      bil_elem_det_tipo.elem_det_tipo_code, user_table utente, bil_elem_det_var.ente_proprietario_id
from siac_t_bil_elem_det_var bil_elem_det_var,
	 siac_r_variazione_stato r_variazione_stato,
     siac_d_variazione_stato variazione_stato ,
     siac_d_bil_elem_det_tipo bil_elem_det_tipo,
     siac_t_bil_elem		capitolo,
     siac_d_bil_elem_tipo    t_capitolo
where bil_elem_det_var.variazione_stato_id=r_variazione_stato.variazione_stato_id
	AND r_variazione_stato.variazione_stato_tipo_id=variazione_stato.variazione_stato_tipo_id   
    and bil_elem_det_var.elem_det_tipo_id= bil_elem_det_tipo.elem_det_tipo_id
    and capitolo.elem_id=bil_elem_det_var.elem_id
    AND  capitolo.elem_tipo_id     = 	t_capitolo.elem_tipo_id
    AND bil_elem_det_var.data_cancellazione IS NULL
    AND r_variazione_stato.data_cancellazione IS NULL
    AND variazione_stato.data_cancellazione IS NULL
    AND bil_elem_det_tipo.data_cancellazione IS NULL
    AND capitolo.data_cancellazione IS NULL
    	/* devo prendere le variazioni PROVVISORIE.
        	Quindi oltre a quelle ANNULLATE, escludo le DEFINITIVE */
    AND variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
    and bil_elem_det_tipo.elem_det_tipo_code='STA'
    and t_capitolo.elem_tipo_code    		= 	elemTipoCode
    AND bil_elem_det_var.ente_proprietario_id =p_ente_prop_id
       group by bil_elem_det_var.elem_id,  bil_elem_det_tipo.elem_det_tipo_code,
       UTENTE, bil_elem_det_var.ente_proprietario_id  ;

---------------------------------------------------------------------------------------------------------------------------------
raise notice 'ora: % ',clock_timestamp()::varchar;
 RTN_MESSAGGIO:='estrazione dei dati dalle tabelle di comodo e preparazione dati in output ''.';   
   raise notice 'estrazione dei dati dalle tabelle di comodo e preparazione dati in output ';  
 
for classifBilRec in
select 	
    	tb.anno_bilancio    			BIL_ANNO,
        v1.tipologia_code				TIPO_TITOLO_CODE,
        v1.tipologia_desc				TIPO_TITOLO_DESC,
        v1.titolo_code					TITOLO_CODE,
        v1.titolo_desc					TITOLO_DESC,
        tb.elem_id						ELEM_ID,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_code3     				BIL_ELE_CODE3,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,   
        COALESCE(tb3.accertamenti,0)	ACCERTAMENTI,
        COALESCE(tb1.previsioni_definitive_cassa,0)	previsioni_definitive_cassa,
        COALESCE(tb1.previsioni_definitive_comp,0)	previsioni_definitive_comp,
        COALESCE(tb1.residui_attivi	,0)				residui_attivi,
        COALESCE(tb2.riscossioni,0)					reversali,
        COALESCE(tb4.importo	,0)					variazioni_provv
from  	siac_rep_tit_tip_cat_riga_anni v1
			left  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                   and v1.utente=user_table)		                
           --------RIGHT	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
           left	join    siac_rep_cap_eg_imp_riga 	tb1  	on 	tb1.elem_id	=	tb.elem_id         
           LEFT join	siac_rep_riscos_eg 			tb2		on 	tb2.elem_id	=	tb.elem_id
          left join    siac_rep_accertamenti		tb3		on  tb3.elem_id	=	tb.elem_id   
          left join    siac_rep_var_entrate			tb4		on  tb4.elem_id	=	tb.elem_id         	      	
        WHERE tb.elem_id IS NOT NULL
        	AND tb.utente= user_table
            order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop

nome_ente = ente_denominazione;

bil_anno:=classifBilRec.bil_anno;
titoloe_tipo_code=classifBilRec.TIPO_TITOLO_CODE;
titoloe_tipo_desc=classifBilRec.TIPO_TITOLO_DESC;
titoloe_code=classifBilRec.TITOLO_CODE;
titoloe_desc=classifBilRec.TITOLO_DESC;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_code3:=classifBilRec.bil_ele_code3;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;

stanz_attuale=classifBilRec.previsioni_definitive_cassa;
accertato=classifBilRec.ACCERTAMENTI;
reversali_emesse=classifBilRec.reversali;
variazioni_provv=classifBilRec.variazioni_provv;


num_vincoli=0;

BEGIN
	SELECT  count(r_vinc_bil_elem.vincolo_elem_id)
        INTO num_vincoli
        from siac_r_vincolo_bil_elem  r_vinc_bil_elem          
    where 
        r_vinc_bil_elem.elem_id 			= 	classifBilRec.ELEM_ID
        AND r_vinc_bil_elem.data_cancellazione IS NULL;
   IF NOT FOUND THEN
      RAISE EXCEPTION 'Errore nella ricerca dei vincoli per %', classifBilRec.ELEM_ID;
      return;   
    END IF;
END;

IF num_vincoli>0 THEN
	esiste_vincolo='S';
ELSE
	esiste_vincolo='N';
END IF;



IF classifBilRec.ELEM_ID IS NOT NULL THEN
    BEGIN
          select c.classif_code
          into tipo_finanziamento
          from siac_t_class c, siac_d_class_tipo t, siac_r_bil_elem_class 	r
          where c.classif_tipo_id=t.classif_tipo_id
          and r.classif_id=c.classif_id
          and t.classif_tipo_code in('TIPO_FINANZIAMENTO')
          and c.ente_proprietario_id=p_ente_prop_id
          AND c.data_cancellazione IS NULL
          AND t.data_cancellazione IS NULL
          AND r.data_cancellazione IS NULL
          and r.elem_id=classifBilRec.ELEM_ID;
       IF NOT FOUND THEN
          --RAISE EXCEPTION 'Errore nella ricerca del tipo finanziamento %', classifBilRec.ELEM_ID;
          --return;   
          tipo_finanziamento='';
        END IF;
    END;
    
	BEGIN
        SELECT  t_class.classif_code, t_class.classif_desc
            INTO sett_code, sett_descr
            from siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo ,
                siac_t_bil_elem    		capitolo               
        where 
            r_bil_elem_class.elem_id 			= 	capitolo.elem_id
            and t_class.classif_id 					= 	r_bil_elem_class.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
            AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
            and capitolo.ente_proprietario_id=p_ente_prop_id
            and capitolo.elem_id=classifBilRec.ELEM_ID
             AND r_bil_elem_class.data_cancellazione is NULL
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL
             AND capitolo.data_cancellazione is NULL;	
       IF NOT FOUND THEN
         -- RAISE EXCEPTION 'Non esiste il Settore per  %', classifBilRec.ELEM_ID;
         -- return;   
        sett_code='';
		sett_descr='';
        END IF;
    END;    

ELSE

	sett_code='';
	sett_descr='';
END IF;

return next;

bil_anno='';
titoloe_tipo_code='';
titoloe_tipo_desc='';
titoloe_code='';
titoloe_desc='';

bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;

sett_code='';
sett_descr='';
    
stanz_attuale=0;
accertato=0;
reversali_emesse=0;
variazioni_provv=0;

tipo_finanziamento='';

end loop;
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati dalle tabelle di comodo e preparazione dati in output- cancellazione table ';  


delete from siac_rep_tit_tip_cat_riga_anni 	where utente=user_table;

delete from siac_rep_cap_eg 				where utente=user_table;

delete from siac_rep_cap_eg_imp				where utente=user_table;

delete from siac_rep_cap_eg_imp_riga 		where utente=user_table;

delete from siac_rep_riscos_eg				where utente=user_table;

delete from siac_rep_accertamenti			where utente=user_table;

delete from siac_rep_var_entrate 			where utente=user_table;

raise notice 'fine OK';
raise notice 'fine cancellazione table ';  
raise notice 'ora: % ',clock_timestamp()::varchar;
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
SECURITY DEFINER
COST 100 ROWS 1000;