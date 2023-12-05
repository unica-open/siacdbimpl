/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 04.12.2019 Sofia SIAC-7140 
drop VIEW if exists siac_v_dwh_bil_elem_comp_cap;
drop VIEW if exists siac_v_dwh_bil_elem_comp_tipo;

CREATE OR REPLACE VIEW siac_v_dwh_bil_elem_comp_cap
(
	   ente_proprietario_id,
       ente_denominazione,
     --012345678901234567890123456789
	   elem_anno_bilancio            ,
	   elem_tipo_code_capitolo       ,
       elem_tipo_desc_capitolo       ,
	   elem_code_capitolo            ,
       elem_code_articolo            ,
       elem_code_ueb                 ,
       elem_stato_code_capitolo      ,
       elem_stato_desc_capitolo      ,
       elem_det_anno                 ,
       elem_det_importo              ,
       elem_det_comp_importo         ,
	   elem_det_comp_tipo_code       ,
	   elem_det_comp_tipo_desc       ,
       elem_det_comp_macro_tipo_code ,
 	   elem_det_comp_macro_tipo_desc ,
	   elem_det_comp_sotto_tipo_code ,
	   elem_det_comp_sotto_tipo_desc ,
	   elem_det_comp_tipo_ambito_code,
	   elem_det_comp_tipo_ambito_desc,
	   elem_det_comp_tipo_fonte_code ,
	   elem_det_comp_tipo_fonte_desc ,
	   elem_det_comp_tipo_fase_code  ,
	   elem_det_comp_tipo_fase_desc  ,
	   elem_det_comp_tipo_def_code   ,
	   elem_det_comp_tipo_def_desc   ,
	   elem_det_comp_tipo_gest_aut   ,
	   elem_det_comp_tipo_anno
)
as
select ente.ente_proprietario_id,
       ente.ente_denominazione,
       query.elem_anno_bilancio,
	   query.elem_tipo_code_capitolo,
       query.elem_tipo_desc_capitolo,
	   query.elem_code_capitolo,
       query.elem_code_articolo,
       query.elem_code_ueb,
       query.elem_stato_code_capitolo,
       query.elem_stato_desc_capitolo,
       query.elem_det_anno,
       query.elem_det_importo,
       query.elem_det_comp_importo,
	   query.elem_det_comp_tipo_code,
	   query.elem_det_comp_tipo_desc,
	   query.elem_det_comp_macro_tipo_code,
 	   query.elem_det_comp_macro_tipo_desc,
	   query.elem_det_comp_sotto_tipo_code,
	   query.elem_det_comp_sotto_tipo_desc,
	   query.elem_det_comp_tipo_ambito_code,
	   query.elem_det_comp_tipo_ambito_desc,
	   query.elem_det_comp_tipo_fonte_code,
	   query.elem_det_comp_tipo_fonte_desc,
	   query.elem_det_comp_tipo_fase_code,
	   query.elem_det_comp_tipo_fase_desc,
	   query.elem_det_comp_tipo_def_code,
	   query.elem_det_comp_tipo_def_desc,
	   query.elem_det_comp_tipo_gest_aut,
	   query.elem_det_comp_tipo_anno
from
(
with
comp_tipo as
(
select
  macro.elem_det_comp_macro_tipo_code,
  macro.elem_det_comp_macro_tipo_desc,
  sotto_tipo.elem_det_comp_sotto_tipo_code,
  sotto_tipo.elem_det_comp_sotto_tipo_desc,
  tipo.elem_det_comp_tipo_code,
  tipo.elem_det_comp_tipo_desc,
  ambito_tipo.elem_det_comp_tipo_ambito_code,
  ambito_tipo.elem_det_comp_tipo_ambito_desc,
  fonte_tipo.elem_det_comp_tipo_fonte_code,
  fonte_tipo.elem_det_comp_tipo_fonte_desc,
  fase_tipo.elem_det_comp_tipo_fase_code,
  fase_tipo.elem_det_comp_tipo_fase_desc,
  def_tipo.elem_det_comp_tipo_def_code,
  def_tipo.elem_det_comp_tipo_def_desc,
  (case when tipo.elem_det_comp_tipo_gest_aut=true then 'Solo automatica'
        else 'Manuale' end)::varchar(50) elem_det_comp_tipo_gest_aut,
  per.anno::integer elem_det_comp_tipo_anno,
  tipo.elem_det_comp_tipo_id,
  per.periodo_id elem_det_comp_periodo_id
from siac_d_bil_elem_det_comp_tipo_stato stato, siac_d_bil_elem_det_comp_macro_tipo macro,
     siac_d_bil_elem_det_comp_tipo tipo
        left join siac_d_bil_elem_det_comp_sotto_tipo  sotto_tipo  on (tipo.elem_det_comp_sotto_tipo_id  =sotto_tipo.elem_det_comp_sotto_tipo_id)
        left join siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo on (tipo.elem_det_comp_tipo_ambito_id =ambito_tipo.elem_det_comp_tipo_ambito_id)
        left join siac_d_bil_elem_det_comp_tipo_fonte  fonte_tipo  on (tipo.elem_det_comp_tipo_fonte_id  =fonte_tipo.elem_det_comp_tipo_fonte_id)
        left join siac_d_bil_elem_det_comp_tipo_fase   fase_tipo   on (tipo.elem_det_comp_tipo_fase_id   =fase_tipo.elem_det_comp_tipo_fase_id)
        left join siac_d_bil_elem_det_comp_tipo_def    def_tipo    on (tipo.elem_det_comp_tipo_def_id    =def_tipo.elem_det_comp_tipo_def_id)
        left join siac_t_periodo per                               on (tipo.periodo_id                   =per.periodo_id)
where stato.elem_det_comp_tipo_stato_id=tipo.elem_det_comp_tipo_stato_id
and   macro.elem_det_comp_macro_tipo_id=tipo.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
),
capitolo as
(
select e.elem_code, e.elem_code2, e.elem_code3,
       tipo.elem_tipo_code, tipo.elem_tipo_desc,
       stato.elem_stato_code, stato.elem_stato_desc,
       per.anno elem_anno_bilancio,
       per_det.anno elem_det_anno,
       det.elem_det_importo,
       e.elem_id,
       det.elem_det_id,
       det.elem_det_tipo_id,
       bil.bil_id,
       per.periodo_id,
       per_det.periodo_id periodo_det_id,
       e.ente_proprietario_id
from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
     siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato,
     siac_t_bil bil,siac_t_periodo per,
     siac_t_bil_elem_det det,siac_d_bil_elem_det_tipo tipo_det,
     siac_t_periodo per_det
where tipo.elem_tipo_code in ('CAP-UG','CAP-UP')
and   e.elem_tipo_id=tipo.elem_tipo_id
and   rs.elem_id=e.elem_id
and   stato.elem_stato_id=rs.elem_stato_id
and   bil.bil_id=e.bil_id
and   per.periodo_id=bil.periodo_id
and   det.elem_id=e.elem_id
and   tipo_det.elem_det_tipo_id=det.elem_det_tipo_id
and   tipo_det.elem_det_tipo_code='STA'
and   per_det.periodo_id=det.periodo_id
and   e.data_cancellazione is null
and   det.data_cancellazione is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
),
capitolo_det_comp as
(
select comp.*
from siac_t_bil_elem_det_comp comp
where comp.data_cancellazione is null
)
select capitolo.elem_code  elem_code_capitolo,
       capitolo.elem_code2 elem_code_articolo,
       capitolo.elem_code3 elem_code_ueb,
       capitolo.elem_tipo_code  elem_tipo_code_capitolo,
       capitolo.elem_tipo_desc  elem_tipo_desc_capitolo,
       capitolo.elem_stato_code elem_stato_code_capitolo,
       capitolo.elem_stato_desc elem_stato_desc_capitolo,
       capitolo.elem_anno_bilancio,
       capitolo.elem_det_anno,
       capitolo.elem_det_importo,
       capitolo.elem_id,
       capitolo.elem_det_id,
       capitolo.elem_det_tipo_id,
       capitolo.bil_id,
       capitolo.periodo_id,
       capitolo.periodo_det_id,
       capitolo.ente_proprietario_id,
       capitolo_det_comp.elem_det_importo elem_det_comp_importo,
       comp_tipo.elem_det_comp_macro_tipo_code,
 	   comp_tipo.elem_det_comp_macro_tipo_desc,
	   comp_tipo.elem_det_comp_sotto_tipo_code,
	   comp_tipo.elem_det_comp_sotto_tipo_desc,
	   comp_tipo.elem_det_comp_tipo_code,
	   comp_tipo.elem_det_comp_tipo_desc,
	   comp_tipo.elem_det_comp_tipo_ambito_code,
	   comp_tipo.elem_det_comp_tipo_ambito_desc,
	   comp_tipo.elem_det_comp_tipo_fonte_code,
	   comp_tipo.elem_det_comp_tipo_fonte_desc,
	   comp_tipo.elem_det_comp_tipo_fase_code,
	   comp_tipo.elem_det_comp_tipo_fase_desc,
	   comp_tipo.elem_det_comp_tipo_def_code,
	   comp_tipo.elem_det_comp_tipo_def_desc,
	   comp_tipo.elem_det_comp_tipo_gest_aut,
	   comp_tipo.elem_det_comp_tipo_anno,
       comp_tipo.elem_det_comp_periodo_id
from capitolo, capitolo_det_comp,comp_tipo
where capitolo.elem_det_id=capitolo_det_comp.elem_det_id
and   comp_tipo.elem_det_comp_tipo_id=capitolo_det_comp.elem_det_comp_tipo_id
) query, siac_t_ente_proprietario ente
where query.ente_proprietario_id=ente.ente_proprietario_id;

CREATE OR REPLACE VIEW siac_v_dwh_bil_elem_comp_tipo
(

  ente_proprietario_id,
  ente_denominazione,
--012345678901234567890123456789
  elem_det_comp_tipo_code       ,
  elem_det_comp_tipo_desc       ,
  elem_det_comp_macro_tipo_code ,
  elem_det_comp_macro_tipo_desc ,
  elem_det_comp_sotto_tipo_code ,
  elem_det_comp_sotto_tipo_desc ,
  elem_det_comp_tipo_ambito_code,
  elem_det_comp_tipo_ambito_desc,
  elem_det_comp_tipo_fonte_code ,
  elem_det_comp_tipo_fonte_desc ,
  elem_det_comp_tipo_fase_code  ,
  elem_det_comp_tipo_fase_desc  ,
  elem_det_comp_tipo_def_code   ,
  elem_det_comp_tipo_def_desc   ,
  elem_det_comp_tipo_gest_aut   ,
  elem_det_comp_tipo_anno       ,
  elem_det_comp_tipo_stato_code ,
  elem_det_comp_tipo_stato_desc ,
  validita_inizio,
  validita_fine
)
as
select
  ente.ente_proprietario_id,
  ente.ente_denominazione,
  tipo.elem_det_comp_tipo_code,
  tipo.elem_det_comp_tipo_desc,
  macro.elem_det_comp_macro_tipo_code,
  macro.elem_det_comp_macro_tipo_desc,
  sotto_tipo.elem_det_comp_sotto_tipo_code,
  sotto_tipo.elem_det_comp_sotto_tipo_desc,
  ambito_tipo.elem_det_comp_tipo_ambito_code,
  ambito_tipo.elem_det_comp_tipo_ambito_desc,
  fonte_tipo.elem_det_comp_tipo_fonte_code,
  fonte_tipo.elem_det_comp_tipo_fonte_desc,
  fase_tipo.elem_det_comp_tipo_fase_code,
  fase_tipo.elem_det_comp_tipo_fase_desc,
  def_tipo.elem_det_comp_tipo_def_code,
  def_tipo.elem_det_comp_tipo_def_desc,
  (case when tipo.elem_det_comp_tipo_gest_aut=true then 'Solo automatica'
        else 'Manuale' end)::varchar(50) elem_det_comp_tipo_gest_aut,
  per.anno::integer elem_det_comp_tipo_anno,
  stato.elem_det_comp_tipo_stato_code,
  stato.elem_det_comp_tipo_stato_desc,
  tipo.validita_inizio,
  tipo.validita_fine
from siac_t_ente_proprietario ente,
     siac_d_bil_elem_det_comp_tipo_stato stato, siac_d_bil_elem_det_comp_macro_tipo macro,
     siac_d_bil_elem_det_comp_tipo tipo
        left join siac_d_bil_elem_det_comp_sotto_tipo  sotto_tipo  on (tipo.elem_det_comp_sotto_tipo_id  =sotto_tipo.elem_det_comp_sotto_tipo_id)
        left join siac_d_bil_elem_det_comp_tipo_ambito ambito_tipo on (tipo.elem_det_comp_tipo_ambito_id =ambito_tipo.elem_det_comp_tipo_ambito_id)
        left join siac_d_bil_elem_det_comp_tipo_fonte  fonte_tipo  on (tipo.elem_det_comp_tipo_fonte_id  =fonte_tipo.elem_det_comp_tipo_fonte_id)
        left join siac_d_bil_elem_det_comp_tipo_fase   fase_tipo   on (tipo.elem_det_comp_tipo_fase_id   =fase_tipo.elem_det_comp_tipo_fase_id)
        left join siac_d_bil_elem_det_comp_tipo_def    def_tipo    on (tipo.elem_det_comp_tipo_def_id    =def_tipo.elem_det_comp_tipo_def_id)
        left join siac_t_periodo per                               on (tipo.periodo_id                   =per.periodo_id)
where stato.ente_proprietario_id=ente.ente_proprietario_id
and   stato.elem_det_comp_tipo_stato_id=tipo.elem_det_comp_tipo_stato_id
and   macro.elem_det_comp_macro_tipo_id=tipo.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null;



-- 04.12.2019 Sofia SIAC-7140 



-- 05.12.2019 Haitham  SIAC-7244   ---> INIZIO
CREATE OR REPLACE FUNCTION siac."BILR236_entrate_riepilogo_titoli_tipologie_titoli_tipologie"(p_ente_prop_id integer, p_anno character varying, p_ele_variazioni character varying)
 RETURNS TABLE(bil_anno character varying, titoloe_tipo_code character varying, titoloe_tipo_desc character varying, titoloe_code character varying, titoloe_desc character varying, tipologia_tipo_code character varying, tipologia_tipo_desc character varying, tipologia_code character varying, tipologia_desc character varying, categoria_tipo_code character varying, categoria_tipo_desc character varying, categoria_code character varying, categoria_desc character varying, bil_ele_code character varying, bil_ele_desc character varying, bil_ele_code2 character varying, bil_ele_desc2 character varying, bil_ele_id integer, bil_ele_id_padre integer, stanziamento_prev_cassa_anno numeric, stanziamento_prev_anno numeric, stanziamento_prev_anno1 numeric, stanziamento_prev_anno2 numeric, residui_presunti numeric, previsioni_anno_prec numeric,  display_error character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
classifBilRec record;
elencoVarRec  record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec VARCHAR;
importo_cassa_app numeric;
importo_competenza_app numeric;
intApp INTEGER;
strApp VARCHAR;
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';
-- ALESSANDRO - SIAC-5208 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- ALESSANDRO - SIAC-5208 - FINE



BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

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
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

select fnc_siac_random_user()
into	user_table;



--06/09/2016: cambiata la query che carica la struttura di bilancio
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

insert into siac_rep_cap_ep
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
and e.ente_proprietario_id=p_ente_prop_id
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
--and	cat_del_capitolo.elem_cat_code	=	'STD'
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


insert into siac_rep_cap_ep             
with prec as (       
select * From siac_t_cap_e_importi_anno_prec a
where a.anno=annoPrec       
and a.ente_proprietario_id=p_ente_prop_id
)
, categ as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'CATEGORIA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)  
select categ.classif_id classif_id_categ,  p_anno,
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, user_table utente
 from prec
join categ on prec.categoria_code=categ.classif_code
and not exists (select 1 from siac_rep_cap_ep ep
                      where ep.elem_code=prec.elem_code
                        AND ep.elem_code2=prec.elem_code2
                        and ep.elem_code3=prec.elem_code3
                        and ep.classif_id = categ.classif_id
                        and ep.utente=user_table
                        and ep.ente_proprietario_id=p_ente_prop_id);                        
  
--------------



insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
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
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
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


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, 
	siac_rep_cap_ep_imp tb2, 
	siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, 
	siac_rep_cap_ep_imp tb5, 
	siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    


-------------------------------------
 
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
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
            siac_t_bil                  bilancio ';            
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
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
        
    sql_query=sql_query||' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    
      
    sql_query=sql_query || ' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
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
end if;

-------------------------------------



for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_code3					BIL_ELE_CODE3,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
        
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
           --------RIGHT	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
           left	join    siac_rep_cap_ep_imp_riga tb1  
           			on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
			left	join  siac_rep_var_entrate_riga var_anno
           			on (var_anno.elem_id	=	tb.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	tb.utente=user_table
                        and var_anno.utente	=	tb.utente)         
			left	join  siac_rep_var_entrate_riga var_anno1
           			on (var_anno1.elem_id	=	tb.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	tb.utente=user_table
                        and var_anno1.utente	=	tb.utente)  
			left	join  siac_rep_var_entrate_riga var_anno2
           			on (var_anno2.elem_id	=	tb.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	tb.utente=user_table
                        and var_anno2.utente	=	tb.utente)                                                                        
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop



/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;

/* non servono piu' gli stanziamenti dei capitoli, ma non si smonta tutto  
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;
previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;
*/

--25/10/2019: sommo solo i valori delle variazioni

stanziamento_prev_anno=stanziamento_prev_anno+
                       classifBilRec.variazione_aumento_stanziato+
            		   classifBilRec.variazione_diminuzione_stanziato;
            		  
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+
                             classifBilRec.variazione_aumento_cassa+
            				 classifBilRec.variazione_diminuzione_cassa;
            				
stanziamento_prev_anno1=stanziamento_prev_anno1+
                        classifBilRec.variazione_aumento_stanziato1+
            			classifBilRec.variazione_diminuzione_stanziato1;
            		
stanziamento_prev_anno2=stanziamento_prev_anno2+
                        classifBilRec.variazione_aumento_stanziato2+
            			classifBilRec.variazione_diminuzione_stanziato2;
            		
residui_presunti=residui_presunti+
                 classifBilRec.variazione_aumento_residuo+
            	 classifBilRec.variazione_diminuzione_residuo;

    	
            	
            	
           
            	
            	
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Tipologia %', bil_ele_code, bil_ele_id, tipologia_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;    
    

raise notice 'Cap %, ID = %, Tipologia %', bil_ele_code, bil_ele_id, tipologia_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;


/*raise notice 'record';*/
return next;
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
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

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
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$function$
;


CREATE OR REPLACE FUNCTION siac."BILR238_spese_riepilogo_missione_programma" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
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
  bil_ele_code3 varchar,
  bil_ele_id integer,
  imp_variaz_stanz_anno numeric,
  imp_variaz_stanz_anno1 numeric,
  imp_variaz_stanz_anno2 numeric,
  imp_variaz_cassa_anno numeric,
  imp_variaz_stanz_fpv_anno numeric,
  imp_variaz_stanz_fpv_anno1 numeric,
  imp_variaz_stanz_fpv_anno2 numeric,
  imp_variaz_residui_anno numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;
ImpegniRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec VARCHAR;
annobilint integer :=0;
previsioni_anno_prec_cassa_app NUMERIC;
previsioni_anno_prec_comp_app NUMERIC;
tipo_categ_capitolo VARCHAR;
stanziamento_fpv_anno_prec_app NUMERIC;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
v_importo_imp   NUMERIC :=0;
v_importo_imp1  NUMERIC :=0;
v_importo_imp2  NUMERIC :=0;
v_conta_rec INTEGER :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
x_array VARCHAR [];

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

/*
	28/10/2019.
	Funzione creata per la richiesta SIAC-7041 usata dai report BILR238, BILR239, BILR240.
    La funzione si basa sul comportamento della funzione "BILR111_Allegato_9_bil_gest_spesa_mpt" 
    ma riceve in input, oltre all'ente ed all'anno bilancio, solo un elenco di variazioni 
    obbligatorio.
    La funzione fornisce in output solo i dati delle variazioni raggruppati per:
    - missione
    - programma
    - titolo
	- macroaggregato
    - capitolo.
    E' compito di ciascun report raggruppare ulteriormente i dati secondo le necessita'.
    Gli importi delle variazioni riguardano:
    - competenza anno bilancio, annobilancio + 1 e anno bilancio + 2;
    - cassa anno bilancio;
    - residui anno bilancio;
    - stanziamento fpv anno bilancio, annobilancio + 1 e anno bilancio + 2.
    
    Gli importi degli impegni sono impostati a 0 perche' nei report esistono i campi ma non
    devono essere valorizzati.
    
    ATTENZIONE: 
    Gli importi delle variazioni riguardano solo i capitoli di tipo ('STD','FSC','FPV','FPVC'),
    cosi' come fatto dalla procedura "BILR111_Allegato_9_bil_gest_spesa_mpt".
    Per questo modivo se si confrontano i totali delle variazioni da applicativo con i totali 
    estratti da questa procedura potrebbero esserci delle differenze, in quanto le variazioni
    potrebbero coinvolgere anche altri tipi di capitoli.    
    
*/

annobilint := p_anno::INTEGER;
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP-UG';	--- Capitolo gestione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;

-- verifico che il parametro con l'elenco delle variazioni abbia solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;



select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
-- raise notice 'user  %',user_table;

bil_anno='';

missione_code='';
missione_desc='';

programma_code='';
programma_desc='';

titusc_code='';
titusc_desc='';

macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
imp_variaz_stanz_anno=0;
imp_variaz_stanz_anno1=0;
imp_variaz_stanz_anno2=0;
imp_variaz_cassa_anno=0;
imp_variaz_stanz_fpv_anno=0;
imp_variaz_stanz_fpv_anno1=0;
imp_variaz_stanz_fpv_anno2=0;
   
display_error:='';

--uso una tabella di appoggio per le varizioni perche' la query e' di tipo dinamico
--in quanto il parametro con l'elenco delle variazioni e' variabile.

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
  
    sql_query=sql_query || ' and testata_variazione.ente_proprietario_id	=  ' || p_ente_prop_id ||'     
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code != ''A''              --SIAC-7244   in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';

    sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
       
    sql_query=sql_query||'
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	    

raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;                
                
return query 
with struttura as (
	select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,user_table)),
capitoli as (   
    select 	programma.classif_id classif_id_programma,
            macroaggr.classif_id classif_id_macroaggregato,
            anno_eserc.anno anno_bilancio,
            capitolo.elem_code, 
            capitolo.elem_code2,
            capitolo.elem_code3,
            capitolo.elem_desc,
            capitolo.elem_id,
            capitolo.elem_desc2
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
        programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
        programma.classif_id=r_capitolo_programma.classif_id					and
        macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
        macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
        bilancio.periodo_id=anno_eserc.periodo_id 								and
        capitolo.bil_id=bilancio.bil_id 										and
        capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
        tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
        capitolo.elem_id=r_capitolo_programma.elem_id							and
        capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
        capitolo.elem_id				=	r_capitolo_stato.elem_id			and
        r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
        capitolo.elem_id				=	r_cat_capitolo.elem_id				and
        r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and                
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        anno_eserc.anno= p_anno 												and
        programma_tipo.classif_tipo_code='PROGRAMMA' 							and
        macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
        stato_capitolo.elem_stato_code	=	'VA'								and
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
        and	r_cat_capitolo.data_cancellazione 	 		is null),
	variaz_stanz_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_cassa_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpCassa  --'SCA' -- cassa
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
      variaz_stanz_fpv_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_fpv_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_fpv_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
    variaz_residui_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpRes --'STR'  residui
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )              		                                    
select 
  p_anno::varchar bil_anno,
  struttura.missione_tipo_desc::varchar missione_tipo_desc,
  struttura.missione_code::varchar missione_code,
  struttura.missione_desc:: varchar missione_desc,
  struttura.programma_tipo_desc:: varchar programma_tipo_desc,
  struttura.programma_code::varchar programma_code,
  struttura.programma_desc::varchar programma_desc,
  struttura.titusc_tipo_desc::varchar titusc_tipo_desc,
  struttura.titusc_code::varchar titusc_code,
  struttura.titusc_desc::varchar titusc_desc,
  struttura.macroag_tipo_desc::varchar macroag_tipo_desc,
  struttura.macroag_code::varchar macroag_code,
  struttura.macroag_desc::varchar macroag_desc,
  capitoli.elem_code::varchar bil_ele_code,
  capitoli.elem_desc::varchar bil_ele_desc,
  capitoli.elem_code2::varchar bil_ele_code2,
  capitoli.elem_desc2::varchar bil_ele_desc2,
  capitoli.elem_code3::varchar bil_ele_code3,
  capitoli.elem_id::integer bil_ele_id,
  COALESCE(variaz_stanz_anno.importo_variaz,0)::numeric imp_variaz_stanz_anno,
  COALESCE(variaz_stanz_anno1.importo_variaz,0)::numeric imp_variaz_stanz_anno1,
  COALESCE(variaz_stanz_anno2.importo_variaz,0)::numeric imp_variaz_stanz_anno2,
  COALESCE(variaz_cassa_anno.importo_variaz,0)::numeric imp_variaz_cassa_anno,
  COALESCE(variaz_stanz_fpv_anno.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno,
  COALESCE(variaz_stanz_fpv_anno1.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno1,
  COALESCE(variaz_stanz_fpv_anno2.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno2,
  COALESCE(variaz_residui_anno.importo_variaz,0)::numeric imp_variaz_residui_anno,  
  0::numeric impegnato_anno,
  0::numeric impegnato_anno1,
  0::numeric impegnato_anno2,
  ''::varchar display_error  
from struttura 
	left join capitoli
    	on (struttura.programma_id = capitoli.classif_id_programma    
           	and	struttura.macroag_id = capitoli.classif_id_macroaggregato)
    left join variaz_stanz_anno
      on variaz_stanz_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_anno1
      on variaz_stanz_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_anno2
      on variaz_stanz_anno2.elem_id = capitoli.elem_id 
    left join variaz_cassa_anno
      on variaz_cassa_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno
      on variaz_stanz_fpv_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno1
      on variaz_stanz_fpv_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno2
      on variaz_stanz_fpv_anno2.elem_id = capitoli.elem_id
    left join variaz_residui_anno
      on variaz_residui_anno.elem_id = capitoli.elem_id;
                    
       
                          
delete from siac_rep_var_spese  where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'Nessun dato trovato riguardo la struttura di bilancio.';
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



CREATE OR REPLACE FUNCTION siac."BILR997_tipo_capitolo_dei_report_solo_variaz" (
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

 /* 26/11/2019.
 	Questa funzione nasce come copia della BILR997_tipo_capitolo_dei_report_variaz
    per risolvere i problemi segnalati dalle SIAC-7211 e SIAC-7212.
	L'importo restutitito dalla funzione per ogni "codice_importo" deve contenere solo 
    gli importi delle variazioni e non tutto il contenuto dei capitoli di quel tipo
    importo.
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

--fase_bilancio varchar;

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


elemTipoCodeE:='CAP-EG'; -- tipo capitolo gestione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo gestione

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

contaParVarPeg:=0;
contaParVarBil:=0;

  /* 22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
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

-------------------------------------
--22/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori


insert into siac_rep_cap_ep
select --cl.classif_id,
  NULL,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	--siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        --siac_d_class_tipo ct,
		--siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where-- ct.classif_tipo_code			=	'CATEGORIA'
--and ct.classif_tipo_id				=	cl.classif_tipo_id
--and cl.classif_id					=	rc.classif_id 
--and 
e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCodeE
--and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
--and	rc.data_cancellazione				is null
--and	ct.data_cancellazione 				is null
--and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
--and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
--and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
--and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


/* 05/10/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
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
     --siac_d_class_tipo programma_tipo,
     --siac_t_class programma,
    -- siac_d_class_tipo macroaggr_tipo,
     --siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     --siac_r_bil_elem_class r_capitolo_programma,
     --siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	--programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    --programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
   -- programma.classif_id=r_capitolo_programma.classif_id					and
    --macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    --macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    --macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCodeS						     	and 
    --capitolo.elem_id=r_capitolo_programma.elem_id							and
    --capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
	--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	--and	programma_tipo.data_cancellazione 			is null
    --and	programma.data_cancellazione 				is null
    --and	macroaggr_tipo.data_cancellazione 			is null
    --and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    --and	r_capitolo_programma.data_cancellazione 	is null
   	--and	r_capitolo_macroaggr.data_cancellazione 	is null 
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
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
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
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
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
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
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
        where  tb0.utente = user_table    ; 
        
        
end if;

    
-------------------------------------
/*
for tipo_capitolo in
        select t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod,
                sum (t1.variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum (t1.variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum (t1.variazione_aumento_cassa) variazione_aumento_cassa,
                sum (t1.variazione_diminuzione_cassa) variazione_diminuzione_cassa,
                sum (t1.variazione_aumento_residuo) variazione_aumento_residuo,
                sum (t1.variazione_diminuzione_residuo)   variazione_diminuzione_residuo                                                                                              
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0,
            	siac_rep_var_entrate_riga t1,
                siac_d_bil_elem_categoria cat_del_capitolo,
    			siac_r_bil_elem_categoria r_cat_capitolo
        	where r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	and r_cat_capitolo.elem_id=t1.elem_id
                and cat_del_capitolo.elem_cat_code=t0.codice_importo
                and t1.periodo_anno=t0.anno_competenza
                and t1.utente=user_table
            group by t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod
                */
-- INC000001599997 Inizio
/*for tipo_capitolo in
        select t0.*               
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0
            	ORDER BY t0.anno_competenza
loop*/
for tipo_capitolo in
        select t0.*               
			from "BILR000_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno, 'G') t0
            	ORDER BY t0.anno_competenza
loop
-- INC000001599997 Fine

/* 
	SIAC-7211 e SIAC-7212.
    L'importo restituito deve contenere solo l'importo dei capitoli variati.
*/
--importo = tipo_capitolo.importo;
importo:=0;

elemCatCode= tipo_capitolo.codice_importo;

IF tipo_capitolo.tipo_capitolo_cod ='CAP-EG' THEN  
	--Cerco i dati delle eventuali variazioni di spesa
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
                 -- raise notice 'elemCatCode=%', elemCatCode;
                
                  
                  /*IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                      elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc  THEN            
                          importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
                  ELSIF elemCatCode = tipoFCassaIni THEN
                      importo =importo+variazione_aumento_cassa+variazione_diminuzione_cassa;              	
                  END IF;    */ 
                  
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
            --raise notice 'elemCatCode=%', elemCatCode;
             /* IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                  elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc OR 
                  elemCatCode= tipoFpvcc OR elemCatCode =tipoFpvsc THEN            
                      importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
              ELSIF elemCatCode = tipoFCassaIni THEN
                  importo = importo+variazione_aumento_cassa+variazione_diminuzione_cassa;
              END IF; */  
              
              /* 
                  SIAC-7211 e SIAC-7212.
                  L'importo restituito deve contenere solo l'importo dei capitoli variati.
              */                
              --importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;               
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

-- 05.12.2019 Haitham  SIAC-7244   <--- FINE

-- 06.12.2019 Sofia SIAC-7251 - inizio
drop function if exists fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioBck VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;




    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO


	-- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
	PAGOPA_ERR_42   CONSTANT  varchar :='42';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE
	PAGOPA_ERR_43   CONSTANT  varchar :='43';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO
 	PAGOPA_ERR_44   CONSTANT  varchar :='44';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO COD.FISC.
 	PAGOPA_ERR_45   CONSTANT  varchar :='45';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO PIVA
 	PAGOPA_ERR_46   CONSTANT  varchar :='46';--DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO
    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    PAGOPA_ERR_50   CONSTANT  varchar :='50';--DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO

    -- 22.07.2019 Sofia siac-6963 - inizio
	PAGOPA_ERR_51   CONSTANT  varchar :='51';--DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    --- 12.06.2019 SIAC-6720
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;

    --- 12.06.2019 Siac-6720
    docTipoFatId integer:=null;
    docTipoCorId integer:=null;
    docTipoCorNumAutom integer:=null;
    docTipoFatNumAutom integer:=null;
    nProgressivoFat integer:=null;
    nProgressivoCor integer:=null;
    nProgressivoTemp integer:=null;
	isDocIPA boolean:=false;

    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    -- 11.06.2019 SIAC-6720
	numModifica  integer:=null;
    attoAmmId    integer:=null;
    modificaTipoId integer:=null;
    modifId       integer:=null;
    modifStatoId  integer:=null;
    modStatoRId   integer:=Null;

	-- 13.09.2019 Sofia SIAC-7034
    numeroFattura varchar(250):=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

	-- 12.08.2019 Sofia SIAC-6978 - fine
    docIUV varchar(150):=null;
BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
--    raise notice '%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
--    raise notice '2222%',strMessaggioLog;
--    raise notice '2222-codResult- %',codResult;
    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;
--    raise notice '2222strMessaggio%',strMessaggio;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoFatId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_FAT
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';
      if docTipoFatId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
	      select 1 into docTipoFatNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoFatId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;
      end if;

  end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoCorId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_COR
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';

      if docTipoCorId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
   	      select 1 into docTipoCorNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoCorId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;

      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docStatoValId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
--    raise notice '2222@@%',strMessaggio;

     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
--         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   --- 12.06.2019 Sofia SIAC-6720
   if codResult is null and
      (docTipoCorNumAutom is not null or docTipoFatNumAutom is not null ) then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num ['
                   ||DOC_TIPO_FAT||'-'
                   ||DOC_TIPO_COR
                   ||'] per anno='||annoBilancio::varchar||'.';

      nProgressivoFat:=0;
      nProgressivoCor:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivoFat,
             tipo.doc_tipo_id,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil,siac_d_doc_tipo tipo
      where bil.bil_id=bilancioId
      --and   tipo.doc_tipo_id in (docTipoFatId,docTipoCorId)
      and   tipo.doc_tipo_id in
      (select docTipoCorId doc_tipo_id where  docTipoCorNumAutom is not null
       union
       select docTipoFatId doc_tipo_id where  docTipoFatNumAutom is not null
      )
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=tipo.doc_tipo_id
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

	  codResult:=null;
      --if codResult is null then
      if docTipoCorNumAutom is not null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoCorId;

          if codResult is not null then
              nProgressivoCor:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;

      if docTipoFatNumAutom is not null and codResult is null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoFatId;

          if codResult is not null then
              nProgressivoFat:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;
--    else codResult:=null;
--    end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     --     26.07.2019 Sofia questo controllo causa
     --     nelle update successive il non aggiornamento del motivo di scarto
     --     sulle righe dello stesso flusso ma con motivi diversi
     --     gli step successivi ( update successivi ) lasciano elab='N'
     --     in questo modo il flusso non viene elaborato
     --     in quanto la stessa condizione compare nel query del loop di elaborazione
     --     ma non tutti i dettagli in scarto vengono trattati ed eventualmente associati
     --     a un motivo di scarto
     --     bisogna tenerne conto quando un  flusso non viene elaborato
     --     e non tutti i dettagli hanno un motivo di scarto segnalato
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	   pagopa_ric_errore_id=err.pagopa_ric_errore_id,
               data_modifica=clock_timestamp(),
               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_23 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- siac-6720 31.05.2019 controlli - inizio


   -- dettagli con codice fiscale non indicato
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_41||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_41
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_41;
        strErrore:=' Estremi soggetto non indicati per dati di dettaglio-fatt.';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_42||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_42
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_42;
        strErrore:=' Soggetto inesistente per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente ma non valido
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_43||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_43
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_43;
        strErrore:=' Soggetto esistente non VALIDO per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente valido ma non univoco (diversi soggetti per stesso codice fiscale)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_44||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.codice_fiscale
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_44
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_44;
        strErrore:=' Soggetto esistente VALIDO non univoco (cod.fisc) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   --  soggetto esistente valido ma non univoco (diversi soggetti per stessa partita iva)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_45||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.partita_iva
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_45
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_45;
        strErrore:=' Soggetto esistente VALIDO non univoco (p.iva) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;


   -- aggiornare tutti i dettagli con il soggetto_id
   -- (anche il codice del soggetto !! adesso funziona gia' tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     codResult:=null;
     strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per partita iva [pagopa_t_riconciliazione_doc].';
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     codResult:=null;
   end if;

   --  soggetto_id non aggiornato su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_46||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_46
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_46;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza estremi soggetto aggiornato. ';
     end if;
     codResult:=null;
   end if;

   --  importo non valorizzato  su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_50||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_sottovoce_importo,0)=0
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_50
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_50;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza importo valorizzato. ';
     end if;
     codResult:=null;
   end if;

   -- siac-6720 31.05.2019 controlli - fine

   -- siac-6720 31.05.2019 controlli commentare il seguente
   -- soggetto indicato non esistente non esistente
   /*if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_34 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;*/

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_35 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;

   -- 22.07.2019 Sofia siac-6963 - inizio
   -- accertamento indicato per IPA,COR senza soggetto o soggetto  non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_51||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_51 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=false
     and    not exists
     (
      select 1
      from siac_t_movgest mov, siac_d_movgest_tipo tipo,
           siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
           siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
           siac_r_movgest_ts_sog rsog,siac_t_soggetto sog
      where tipo.ente_proprietario_id=doc.ente_proprietario_id
      and   tipo.movgest_tipo_code='A'
      and   mov.movgest_tipo_id=tipo.movgest_tipo_id
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipots.movgest_ts_tipo_code='T'
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code='D'
      and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
      and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
      and   rsog.movgest_ts_id=ts.movgest_ts_id
      and   sog.soggetto_id=rsog.soggetto_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rsog.data_cancellazione is null
      and   rsog.validita_fine is null
      and   sog.data_cancellazione is null
      and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_51
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_51;
        strErrore:=' Soggetto non indicato su accertamento o non esistente.';
     end if;
     codResult:=null;
   end if;
   -- 22.07.2019 Sofia siac-6963 - fine

--raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
--raise notice 'codResult   %',codResult;
  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';
--   raise notice '2222@@strMessaggio   %',strMessaggio;
--   raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
--    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
--      raise notice 'strMessaggio=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
		    pagopa_elab_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500), -- 09.10.2019 Sofia
            login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
     from  pagopa_r_elaborazione_file r,
           siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      codiceRisultato:=-1;
      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

--  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
   		  coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
          doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id -- siac-6720
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   --     26.07.2019 Sofia questo controllo causa
   --     la non elaborazione di flussi che hanno dettagli in scarto
   --     righe dello stesso flusso ma con motivi diversi
   --     possono esserci righe con scarto='X' e scarto='N'
   --     per le update a step successivi che hanno la stessa condizione
   --     in questo modo il flusso non viene elaborato
   --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
   --     a un motivo di scarto
   --     bisogna tenerne conto quando un  flusso non viene elaborato
   --     e non tutti i dettagli hanno un motivo di scarto segnalato
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
            coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento,
            doc.pagopa_ric_doc_tipo_code, -- siac-6720
            doc.pagopa_ric_doc_tipo_id -- siac-6720
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
        left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
          left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id -- siac-6720
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
             pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720

  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;
		docIUV:=null;

		-- 12.08.2019 Sofia SIAC-6978 - inizio
		if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT then
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                        ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                        ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].'
                        ||' Lettura codice IUV.';
          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

          insert into pagopa_t_elaborazione_log
          (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
          )
          values
          (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
          );

          select distinct query.pagopa_ric_doc_iuv into docIUV
          from
          (
             with
             pagopa_sogg as
             (
             with
             pagopa as
             (
             select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
                    coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
                    doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
                    doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
                    doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                    doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                    doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
                    doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id, -- siac-6720
                    doc.pagopa_ric_doc_iuv pagopa_ric_doc_iuv
             from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
             where flusso.pagopa_elab_id=filePagoPaElabId
             and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
             and   doc.pagopa_ric_doc_stato_elab='N'
             and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
             and   doc.pagopa_ric_doc_subdoc_id is null
             --     26.07.2019 Sofia questo controllo causa
             --     la non elaborazione di flussi che hanno dettagli in scarto
             --     righe dello stesso flusso ma con motivi diversi
             --     possono esserci righe con scarto='X' e scarto='N'
             --     per le update a step successivi che hanno la stessa condizione
             --     in questo modo il flusso non viene elaborato
             --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
             --     a un motivo di scarto
             --     bisogna tenerne conto quando un  flusso non viene elaborato
             --     e non tutti i dettagli hanno un motivo di scarto segnalato
             -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione e poi scarto
            /* and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
             (
               select 1
               from pagopa_t_riconciliazione_doc doc1
               where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
               and   doc1.pagopa_ric_doc_stato_elab!='N'
               and   doc1.data_cancellazione is null
               and   doc1.validita_fine is null
             )*/
             and   doc.data_cancellazione is null
             and   doc.validita_fine is null
             and   flusso.data_cancellazione is null
             and   flusso.validita_fine is null
             group by doc.pagopa_ric_doc_codice_benef,
                      coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
                      doc.pagopa_ric_doc_str_amm,
                      doc.pagopa_ric_doc_voce_tematica,
                      doc.pagopa_ric_doc_voce_code,
                      doc.pagopa_ric_doc_voce_desc,
                      doc.pagopa_ric_doc_anno_accertamento,
                      doc.pagopa_ric_doc_num_accertamento,
                      doc.pagopa_ric_doc_tipo_code, -- siac-6720
                      doc.pagopa_ric_doc_tipo_id, -- siac-6720
                      doc.pagopa_ric_doc_iuv
             ),
             sogg as
             (
             select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
             from siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   sog.data_cancellazione is null
             and   sog.validita_fine is null
             )
             select pagopa.*,
                    sogg.soggetto_id,
                    sogg.soggetto_desc
             from pagopa
          ---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
                  left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
             ),
             accertamenti_sogg as
             (
             with
             accertamenti as
             (
              select mov.movgest_anno::integer, mov.movgest_numero::integer,
                     mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov , siac_d_movgest_tipo tipo,
                   siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
              where tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.movgest_tipo_code='A'
              and   mov.movgest_tipo_id=tipo.movgest_tipo_id
              and   mov.bil_id=bilancioId
              and   ts.movgest_id=mov.movgest_id
              and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
              and   tipots.movgest_ts_tipo_code='T'
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   stato.movgest_stato_id=rs.movgest_stato_id
              and   stato.movgest_stato_code='D'
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
             ),
             soggetto_acc as
             (
             select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
             from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   rsog.soggetto_id=sog.soggetto_id
             and   rsog.data_cancellazione is null
             and   rsog.validita_fine is null
             )
             select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
             from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
                    left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
          --   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
             )
             select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                     pagopa_sogg.pagopa_str_amm,
                     pagopa_sogg.pagopa_voce_tematica,
                     pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                     pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720,
                     pagopa_sogg.pagopa_ric_doc_iuv
             from  pagopa_sogg, accertamenti_sogg
             where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
             and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
             group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
                      pagopa_sogg.pagopa_str_amm,
                      pagopa_sogg.pagopa_voce_tematica,
                      pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                      pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
                      pagopa_sogg.pagopa_ric_doc_iuv
             order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                       pagopa_sogg.pagopa_str_amm,
                       pagopa_sogg.pagopa_voce_tematica,
                       pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                       pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id
          )
          query
          where query.pagopa_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id
          and   coalesce(query.pagopa_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(query.pagopa_voce_tematica,''))
          and   query.pagopa_voce_code=pagoPaFlussoRec.pagopa_voce_code
          and   coalesce(query.pagopa_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(query.pagopa_voce_desc,''))
          and   coalesce(query.pagopa_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(query.pagopa_str_amm,''))
          and   query.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id;
raise notice 'IUUUUUUUUUV docIUV=%',docIUV;
       	if coalesce(docIUV,'')='' or docIUV is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Lettura non riuscita.';
        end if;

       end if;
 	   -- 12.08.2019 Sofia SIAC-6978 - fine


       if bErrore=false then
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		docId:=null;

        -- 12.06.2019 SIAC-6720
--        nProgressivo:=nProgressivo+1;
        nProgressivoTemp:=null;
        isDocIPA:=false;
        -- 13.09.2019 Sofia SIAC-7034
        numeroFattura:=null;

        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
            -- 13.09.2019 Sofia SIAC-7034
            numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||'-'||nProgressivoTemp::varchar;
        end if;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_COR and docTipoCorNumAutom is not null then
        	nProgressivoCor:=nProgressivoCor+1;
            nProgressivoTemp:=nProgressivoCor;
        end if;
        if nProgressivoTemp is null then
	          nProgressivo:=nProgressivo+1;
              nProgressivoTemp:=nProgressivo;
              isDocIPA:=true;
        end if;

        -- 13.09.2019 Sofia SIAC-7034
        if numeroFattura is null then
           numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||' '
                          ||extract ( day from dataElaborazione)||'-'||lpad(extract ( month from dataElaborazione)::varchar,2,'0')||'-'||extract ( year from dataElaborazione)||' '
                          ||' '||nProgressivoTemp::varchar;
        end if;



--        raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
--        raise notice 'isDocIPA=%',isDocIPA;
--		raise notice 'nProgressivo=%',nProgressivo;
--        raise notice 'nProgressivoCor=%',nProgressivoCor;
--        raise notice 'nProgressivoFat=%',nProgressivoFat;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id,
            IUV -- null ??  -- 12.08.2019 Sofia SIAC-6978 - fine
        )
        select annoBilancio,
--               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               numeroFattura,-- 13.09.2019 Sofia SIAC-7034
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
--			   docTipoId, siac-6720 28.05.2019 Sofia
               pagoPaFlussoRec.pagopa_doc_tipo_id, -- siac-6720 28.05.2019 Sofia
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null,
               docIUV   -- 12.08.2019 Sofia SIAC-6978 - fine
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;
       end if;


	   if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         --- 12.06.2019 Siac-6720
--         raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code2=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
         if isDocIPA=true then
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id=docTipoId
           returning num.doc_num_id into codResult;
         else
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id =pagoPaFlussoRec.pagopa_doc_tipo_id
           returning num.doc_num_id into codResult;
         end if;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
--        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );
raise notice 'prima di quote berrore=%',berrore;
        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
           and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti -- , soggetto_acc -- 22.07.2019 siac-6963
                  left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
--        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', --- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
--        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
--		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica. Calcolo numero.';


                    numModifica:=null;
                    codResult:=null;
                    select coalesce(max(query.mod_num),0) into numModifica
                    from
                    (
					select  modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_t_movgest_ts_det_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sog_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sogclasse_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    ) query;

                    if numModifica is null then
                     numModifica:=0;
                    end if;

                    strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica.';
                    attoAmmId:=null;
                    select ratto.attoamm_id into attoAmmId
                    from siac_r_movgest_ts_atto_amm ratto
                    where ratto.movgest_ts_id=movgestTsId
                    and   ratto.data_cancellazione is null
                    and   ratto.validita_fine is null;
					if attoAmmId is null then
                    	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in lettura atto amministrativo.';
                    end if;

                    if codResult is null and modificaTipoId is null then
                    	select tipo.mod_tipo_id into modificaTipoId
                        from siac_d_modifica_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.mod_tipo_code='ALT';
                        if modificaTipoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura modifica tipo.';
                        end if;
                    end if;

                    if codResult is null then
                      modifId:=null;
                      insert into siac_t_modifica
                      (
                          mod_num,
                          mod_desc,
                          mod_data,
                          mod_tipo_id,
                          attoamm_id,
                          login_operazione,
                          validita_inizio,
                          ente_proprietario_id
                      )
                      values
                      (
                          numModifica+1,
                          'Modifica automatica per predisposizione di incasso',
                          dataElaborazione,
                          modificaTipoId,
                          attoAmmId,
                          loginOperazione,
                          clock_timestamp(),
                          enteProprietarioId
                      )
                      returning mod_id into modifId;
                      if modifId is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_modifica.';
                      end if;
					end if;

                    if codResult is null and modifStatoId is null then
	                    select stato.mod_stato_id into modifStatoId
                        from siac_d_modifica_stato stato
                        where stato.ente_proprietario_id=enteProprietarioId
                        and   stato.mod_stato_code='V';
                        if modifStatoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura stato modifica.';
                        end if;
                    end if;
                    if codResult is null then
                      modStatoRId:=null;
                      insert into siac_r_modifica_stato
                      (
                          mod_id,
                          mod_stato_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          modifId,
                          modifStatoId,
                          clock_timestamp(),
                          loginOperazione,
                          enteProprietarioId
                      )
                      returning mod_stato_r_id into modStatoRId;
                      if modStatoRId is  null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_r_modifica_stato.';
                      end if;
                    end if;
                    if codResult is null then
                      insert into siac_t_movgest_ts_det_mod
                      (
                          mod_stato_r_id,
                          movgest_ts_det_id,
                          movgest_ts_id,
                          movgest_ts_det_tipo_id,
                          movgest_ts_det_importo,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      select modStatoRId,
                             det.movgest_ts_det_id,
                             det.movgest_ts_id,
                             det.movgest_ts_det_tipo_id,
                             pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                             clock_timestamp(),
                             loginOperazione,
                             det.ente_proprietario_id
                      from siac_t_movgest_ts_det det
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      returning movgest_ts_det_mod_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_movgest_ts_det_mod.';
                      else
                        codResult:=null;
                      end if;
                	end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';
                      update siac_t_movgest_ts_det det
                      set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                             data_modifica=clock_timestamp(),
                             login_operazione=det.login_operazione||'-'||loginOperazione
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in aggiornamento siac_t_movgest_ts_det.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento pagopa_t_modifica_elab.';
                      insert into pagopa_t_modifica_elab
                      (
                          pagopa_modifica_elab_importo,
                          pagopa_elab_id,
                          subdoc_id,
                          mod_id,
                          movgest_ts_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                          filePagoPaElabId,
                          subDocId,
                          modifId,
                          movgestTsId,
                          clock_timestamp(),
                          loginOperazione,
                          enteProprietarioId
                      )
                      returning pagopa_modifica_elab_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento pagopa_t_modifica_elab.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is not null then
                        --bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggioBck:=strMessaggio||' PAGOPA_ERR_31='||PAGOPA_ERR_31||' .';
--                        raise notice '%', strMessaggioBck;
                        strMessaggio:=' ';
                        raise exception '%', strMessaggioBck;
                    end if;
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
--        raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;

        -- siac-6720 30.05.2019 - per i corrispettivi non collegare atto_amm
--        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then -- Jira SIAC-7089 14.10.2019 Sofia
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_IPA  then    -- Jira SIAC-7089 14.10.2019 Sofia


          -- siac_r_subdoc_atto_amm
          codResult:=null;
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
          insert into siac_r_subdoc_atto_amm
          (
              subdoc_id,
              attoamm_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select subdocId,
                 atto.attoamm_id,
                 clock_timestamp(),
                 loginOperazione,
                 atto.ente_proprietario_id
          from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
          where rts.subdoc_movgest_ts_id=subdocMovgestTsId
          and   atto.movgest_ts_id=rts.movgest_ts_id
          and   atto.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
          returning subdoc_atto_amm_id into codResult;
          if codResult is null then
              bErrore:=true;
              strMessaggio:=strMessaggio||' Errore in inserimento.';
              continue;
          end if;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
--        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
--            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
--            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
               clock_timestamp(),
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
---        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
			and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
              select ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=movgestTipoId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_tipo_id=movgestTsTipoId
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id=movgestStatoId
              and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
              and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
              and   mov.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
              and   ts.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
              and   rs.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
              select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
              from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
              where sog.ente_proprietario_id=enteProprietarioId
              and   rsog.soggetto_id=sog.soggetto_id
              and   sog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
              and   rsog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))

           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id
          from --pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog ,-- 22.07.2019 siac-6963
               pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code)
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );


        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
            insert into pagopa_t_elaborazione_log
            (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
            )
            values
            (
            filePagoPaElabId,
            null,
            strMessaggioLog,
            enteProprietarioId,
            loginOperazione,
            clock_timestamp()
            );


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;
		raise notice 'dnumQuote %',dnumQuote;
	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
 	    insert into siac_t_subdoc_num
        (
         doc_id,
         subdoc_numero,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         docId,
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
--                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
         )
         values
         (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
        --    and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
        --    and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
        --           coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
        --    and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
        --    and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
        --    and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        --    and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        --   and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        --	 and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     	/*	and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog AS
          (
           with
           accertamenti as
           (
                select ts.movgest_ts_id
                from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
                where mov.bil_id=bilancioId
                and   mov.movgest_tipo_id=movgestTipoId
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_tipo_id=movgestTsTipoId
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   rs.movgest_stato_id=movgestStatoId
            --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
             --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
                and   mov.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
                and   ts.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
                and   rs.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
	           select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
    		   from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
	           where sog.ente_proprietario_id=enteProprietarioId
               and   rsog.soggetto_id=sog.soggetto_id
	           and   sog.data_cancellazione is null
	           and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
               and   rsog.data_cancellazione is null
               and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--                accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );




         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
--            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
--            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
--                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
--            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
--            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
--            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
--            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
--            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
            and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
  /*   		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
            select ts.movgest_ts_id
            from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
            where mov.bil_id=bilancioID
            and   mov.movgest_tipo_id=movgestTipoId
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_tipo_id=movgestTsTipoId
            and   rs.movgest_ts_id=ts.movgest_ts_id
            and   rs.movgest_stato_id=movgestStatoId
--            and   rsog.movgest_ts_id=ts.movgest_ts_id -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione
  --          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
  --          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and   mov.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
            and   ts.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
            and   rs.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
            select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
            from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
            where sog.ente_proprietario_id=enteProprietarioId
            and   rsog.soggetto_id=sog.soggetto_id
            and   sog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
            and   rsog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
---               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963

         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         -- 11.06.2019 SIAC-6720
         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_modifica_elab].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_modifica_elab r
         set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN ESEGUI PER pagoPaCodeErr='||pagoPaCodeErr||' ',
                subdoc_id=null
         from 	siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
--  raise notice 'strMessaggioLog=%',strMessaggioLog;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp(),
         login_operazione=num.login_operazione||'-'||loginOperazione
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=
            substr(
             (
              'AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
              ||elab.pagopa_elab_note
             ),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=
                  substr(
                    ('AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
                     ||file.file_pagopa_note
                    ),1,1500), -- 09.10.2019 Sofia
           login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
--  raise notice 'strMessaggio=%',strMessaggio;

  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';

  --  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
  strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
  --    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
    --  and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
   --   and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';

--       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
       strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
              login_operazione=file.login_operazione||'-'||loginOperazione
       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);
-- raise notice 'messaggioRisultato=%',messaggioRisultato;
  return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
-- 06.12.2019 Sofia SIAC-7251 - fine

--SIAC-7226 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);
DROP FUNCTION if exists siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_spese"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
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
  display_error varchar
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
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

/* 06/12/2019. SIAC-7226.
	Procedura rivista nell'ottica di ottimizzarla.
    Sono usate 2 tabelle di appoggio per il calcolo degli importi dei capitoli
    (siac_rep_cap_eg_imp) e per l'elenco dell variazioni (siac_rep_var_entrate)
    perche' i parametri in input cambiano e le query devono essere cosatruite
    dinamicamente.
    In particolare la query dei capitoli e' piu' complessa perche' nel calcolo
    degli importi deve tenere conto delle variazioni definitive che sono state inserite
    in momenti successivi alle variazioni in input.
    Gli importi delle variazioni successive devono essere decrementati dagli importi
    di stanziamento, cassa e residuo.

*/

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


select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno;
    
raise notice '1 - %' , clock_timestamp()::text;

/* carico sulla tabella di appoggio siac_rep_cap_ug_imp gli importi dei capitoli
    	decrementando gli importi delle varizioni successive a quelle 
        specificate in input. */
strQuery:= 'with cap as (
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
     where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno  =  '''||p_anno_competenza||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	''VA''								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code		in (''STD'')
        and capitolo_imp_tipo.elem_det_tipo_code in (''STA'',''SCA'',''STR'')						
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
        -- SIAC-7200 nella query che estrae le variazioni successive, aggiunto
        --  il test sull''anno (periodo_id) che lega la variazione corrente
        --  (siac_t_variazione avar) a quelle successive (siac_t_variazione avarsucc).
 importi_variaz as(    with varcurr as (              
      select dvar.elem_id elem_id_var, bvar.validita_inizio, dvar.periodo_id,
          dvar.elem_det_tipo_id
      from 
      siac_t_variazione avar, siac_r_variazione_stato bvar,
      siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvar
      where avar.variazione_id=bvar.variazione_id
      and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
      and dvar.variazione_stato_id=bvar.variazione_stato_id         
      and cvar.variazione_stato_tipo_code=''D''                            
      and bvar.data_cancellazione is null
      and bvar.variazione_stato_id in (';
if p_numero_delibera IS NOT NULL THEN  --specifico un atto.
strQuery:=strQuery||'                      
            select max(var_stato.variazione_stato_id)
            from siac_t_atto_amm             atto,
              siac_d_atto_amm_tipo        tipo_atto,
              siac_r_atto_amm_stato         r_atto_stato,
              siac_d_atto_amm_stato         stato_atto,
              siac_r_variazione_stato     var_stato
            where
              (var_stato.attoamm_id = atto.attoamm_id 
                 or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
              and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
              and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
              and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
              and     atto.attoamm_numero=  '||p_numero_delibera||'
              and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                 
              and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
              and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') ';
else        -- specificato l'elenco delle variazione.          
      	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )';                
end if;                
		
strQuery:=strQuery||'),
      varsuccess as (select dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
          dvarsucc.periodo_id, bvarsucc.validita_inizio,
          COALESCE(dvarsucc.elem_det_importo,0) importo_var
          from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,              
          siac_d_variazione_stato cvarsucc,
          siac_t_bil_elem_det_var dvarsucc,
          siac_d_bil_elem_det_tipo tipoimp
          where avarsucc.variazione_id= bvarsucc.variazione_id
          and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
          and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
          and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
          and dvarsucc.ente_proprietario_id= '||p_ente_prop_id||'                            
          and cvarsucc.variazione_stato_tipo_code=''D''                                          
          and bvarsucc.data_cancellazione is null
          and dvarsucc.data_cancellazione IS NULL)
      select  varsuccess.elem_id_var, varsuccess.elem_det_tipo_id,
              sum(varsuccess.importo_var) totale_var_succ
      from varcurr
            JOIN varsuccess
              on (varcurr.elem_det_tipo_id = varsuccess.elem_det_tipo_id
                    and varcurr.periodo_id = varsuccess.periodo_id
                    and varsuccess.validita_inizio > varcurr.validita_inizio) 
      group by varsuccess.elem_id_var, varsuccess.elem_det_tipo_id  )    
                    INSERT INTO siac_rep_cap_eg_imp
                    select 	cap.elem_id, 
                              cap.BIL_ELE_IMP_ANNO, 
                              cap.TIPO_IMP,
                              cap.ente_proprietario_id, 
                              '''||user_table||''' utente,               
                              (cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
                    from cap LEFT  JOIN importi_variaz 
                    ON (cap.elem_id = importi_variaz.elem_id_var
                      and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id);';
raise notice 'Query1 = %', strQuery;                

raise notice 'Inizio query importi capitoli - %' , clock_timestamp()::text;

execute  strQuery;

raise notice 'Fine query importi capitoli - % - Inizio query variazioni' , clock_timestamp()::text;

--Caricamento degli importi delle variazioni. 
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id	      	
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
            siac_t_bil					t_bil,
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
    and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
    and 	t_bil.bil_id 										= testata_variazione.bil_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	atto.ente_proprietario_id 							= 	p_ente_prop_id 
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
    and		anno_importi.anno									= 	annoCapImp
    and		anno_eserc.anno	= 	p_anno										
 	and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
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
    and		t_bil.data_cancellazione					is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                atto.ente_proprietario_id;
else 
	strQuery:='
    insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
and 	t_bil.bil_id 										= testata_variazione.bil_id
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id		
	-- 27/04:2017 l''anno di esercizio deve essere collegato a siac_t_bil									
	--and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
and 	testata_variazione.ente_proprietario_id	=	'||p_ente_prop_id||'
and		anno_eserc.anno	= 	'''||p_anno||''' 										
and 	testata_variazione.variazione_num in('||p_ele_variazioni||')
and		anno_importi.anno									= 	'''||annoCapImp||'''
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		t_bil.data_cancellazione					is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
            utente,
        	testata_variazione.ente_proprietario_id';

raise notice 'query variazioni: %', strQuery;      

execute  strQuery;       
     
end if;     
           
return query 
with strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id,p_anno,'')),
		capitoli as (select cl.classif_id categoria_id,
              p_anno anno_bilancio,
              capitolo.elem_code, capitolo.elem_code2,
              capitolo.elem_desc, capitolo.elem_desc2,
              capitolo.elem_id, capitolo.elem_id_padre
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
            and capitolo.ente_proprietario_id	=	p_ente_prop_id
            and capitolo.bil_id					=   bilancio_id
            and ct.classif_tipo_code				=	'CATEGORIA'           
            and tipo_elemento.elem_tipo_code 	= 	elemTipoCode       
            and	stato_capitolo.elem_stato_code	=	'VA'         
            and	cat_del_capitolo.elem_cat_code	=	'STD'
            and capitolo.data_cancellazione 		is null
            and	r_capitolo_stato.data_cancellazione	is null
            and	r_cat_capitolo.data_cancellazione	is null
            and	rc.data_cancellazione				is null
            and	ct.data_cancellazione 				is null
            and	cl.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione	is null
            and	stato_capitolo.data_cancellazione 	is null
            and	cat_del_capitolo.data_cancellazione	is null),
    	importi_stanz as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp= TipoImpComp -- ''STA''
                        and a.utente= user_table
                        group by  a.elem_id),
         importi_cassa as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_eg_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),   
         variaz_cassa_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_cassa_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_residui_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo > 0
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_residui_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_entrate a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo < 0
                        and a.utente=user_table
                        group by  a.elem_id)     
	select capitoli.anno_bilancio::varchar bil_anno,
          ''::varchar titoloe_tipo_code ,
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
          capitoli.elem_code::varchar bil_ele_code,
          capitoli.elem_desc::varchar bil_ele_desc,
          capitoli.elem_code2::varchar bil_ele_code2,
          capitoli.elem_desc2::varchar bil_ele_desc2,
          capitoli.elem_id::integer bil_ele_id,
          capitoli.elem_id_padre::integer bil_ele_id_padre,
          COALESCE(importi_stanz.importo_cap,0)::numeric stanziamento,
          COALESCE(importi_cassa.importo_cap,0)::numeric cassa,
          COALESCE(importi_residui.importo_cap,0)::numeric residuo,
            COALESCE(variaz_stanz_pos.importo_var,0)::numeric variazione_aumento_stanziato,
          COALESCE(variaz_stanz_neg.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
          COALESCE(variaz_cassa_pos.importo_var,0)::numeric variazione_aumento_cassa,
          COALESCE(variaz_cassa_neg.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
          COALESCE(variaz_residui_pos.importo_var,0)::numeric variazione_aumento_residuo,
          COALESCE(variaz_residui_neg.importo_var *-1,0)::numeric variazione_diminuzione_residuo,
           /*       
          1::numeric variazione_aumento_stanziato,
          2::numeric variazione_diminuzione_stanziato,
          3::numeric variazione_aumento_cassa,
          4::numeric variazione_diminuzione_cassa,
          5::numeric variazione_aumento_residuo,
          6::numeric variazione_diminuzione_residuo,*/
          ''::varchar display_error
     from strutt_bilancio
     	LEFT JOIN capitoli 
        	ON strutt_bilancio.categoria_id = capitoli.categoria_id  
        LEFT JOIN importi_stanz
            ON importi_stanz.elem_id = capitoli.elem_id
        LEFT JOIN importi_cassa
            ON importi_cassa.elem_id = capitoli.elem_id
        LEFT JOIN importi_residui
            	ON importi_residui.elem_id = capitoli.elem_id 
        LEFT JOIN variaz_stanz_pos
            ON variaz_stanz_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_stanz_neg
            ON variaz_stanz_neg.elem_id = capitoli.elem_id
        LEFT JOIN variaz_cassa_pos
            ON variaz_cassa_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_cassa_neg
            ON variaz_cassa_neg.elem_id = capitoli.elem_id
        LEFT JOIN variaz_residui_pos
            ON variaz_residui_pos.elem_id = capitoli.elem_id
        LEFT JOIN variaz_residui_neg
            ON variaz_residui_neg.elem_id = capitoli.elem_id         
        where exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb,
                        siac_rep_cap_eg_imp cc
        			where bb.elem_id =cc.elem_id
                    	and bb.categoria_id = aa.classif_id
                 		and aa.classif_id_padre = strutt_bilancio.tipologia_id                         
                        and cc.utente=user_table);
              
        
    delete from siac_rep_cap_eg_imp where utente=user_table;
	delete from siac_rep_var_entrate where utente=user_table;
    


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

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
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
  display_error varchar
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
v_fam_missioneprogramma  varchar;
v_fam_titolomacroaggregato varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;


raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

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
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

/* 06/12/2019. SIAC-7226.
	Procedura rivista nell'ottica di ottimizzarla.
    Sono usate 2 tabelle di appoggio per il calcolo degli importi dei capitoli
    (siac_rep_cap_ug_imp) e per l'elenco dell variazioni (siac_rep_var_spese)
    perche' i parametri in input cambiano e le query devono essere cosatruite
    dinamicamente.
    In particolare la query dei capitoli e' piu' complessa perche' nel calcolo
    degli importi deve tenere conto delle variazioni definitive che sono state inserite
    in momenti successivi alle variazioni in input.
    Gli importi delle variazioni successive devono essere decrementati dagli importi
    di stanziamento, cassa e residuo.

*/

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

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


select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno;
    
    /* carico sulla tabella di appoggio siac_rep_cap_ug_imp gli importi dei capitoli
    	decrementando gli importi delle varizioni successive a quelle 
        specificate in input. */
strQuery:= 'with cap as (
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
     where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id||' 
        and	anno_eserc.anno						= 	'''||p_anno||'''												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno  =  '''||p_anno_competenza||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	''VA''								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')
        and capitolo_imp_tipo.elem_det_tipo_code in (''STA'',''SCA'',''STR'')						
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
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
        -- SIAC-7200 nella query che estrae le variazioni successive, aggiunto
        --  il test sull''anno (periodo_id) che lega la variazione corrente
        --  (siac_t_variazione avar) a quelle successive (siac_t_variazione avarsucc).
 importi_variaz as(    with varcurr as (              
      select dvar.elem_id elem_id_var, bvar.validita_inizio, dvar.periodo_id,
          dvar.elem_det_tipo_id
      from 
      siac_t_variazione avar, siac_r_variazione_stato bvar,
      siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvar
      where avar.variazione_id=bvar.variazione_id
      and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
      and dvar.variazione_stato_id=bvar.variazione_stato_id         
      and cvar.variazione_stato_tipo_code=''D''                            
      and bvar.data_cancellazione is null
      and bvar.variazione_stato_id in (';
if p_numero_delibera IS NOT NULL THEN  --specifico un atto.
strQuery:=strQuery||'                      
            select max(var_stato.variazione_stato_id)
            from siac_t_atto_amm             atto,
              siac_d_atto_amm_tipo        tipo_atto,
              siac_r_atto_amm_stato         r_atto_stato,
              siac_d_atto_amm_stato         stato_atto,
              siac_r_variazione_stato     var_stato
            where
              (var_stato.attoamm_id = atto.attoamm_id 
                 or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
              and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
              and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
              and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
              and     atto.attoamm_numero=  '||p_numero_delibera||'
              and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                 
              and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
              and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') ';
else        -- specificato l'elenco delle variazione.          
      	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )';                
end if;                
		
strQuery:=strQuery||'),
      varsuccess as (select dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
          dvarsucc.periodo_id, bvarsucc.validita_inizio,
          COALESCE(dvarsucc.elem_det_importo,0) importo_var
          from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,              
          siac_d_variazione_stato cvarsucc,
          siac_t_bil_elem_det_var dvarsucc,
          siac_d_bil_elem_det_tipo tipoimp
          where avarsucc.variazione_id= bvarsucc.variazione_id
          and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
          and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
          and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
          and dvarsucc.ente_proprietario_id= '||p_ente_prop_id||'                            
          and cvarsucc.variazione_stato_tipo_code=''D''                                          
          and bvarsucc.data_cancellazione is null
          and dvarsucc.data_cancellazione IS NULL)
      select  varsuccess.elem_id_var, varsuccess.elem_det_tipo_id,
              sum(varsuccess.importo_var) totale_var_succ
      from varcurr
            JOIN varsuccess
              on (varcurr.elem_det_tipo_id = varsuccess.elem_det_tipo_id
                    and varcurr.periodo_id = varsuccess.periodo_id
                    and varsuccess.validita_inizio > varcurr.validita_inizio) 
      group by varsuccess.elem_id_var, varsuccess.elem_det_tipo_id  )    
                    INSERT INTO siac_rep_cap_ug_imp
                    select 	cap.elem_id, 
                              cap.BIL_ELE_IMP_ANNO, 
                              cap.TIPO_IMP,
                              cap.ente_proprietario_id, 
                              '''||user_table||''' utente,               
                              (cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
                    from cap LEFT  JOIN importi_variaz 
                    ON (cap.elem_id = importi_variaz.elem_id_var
                      and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id);';
raise notice 'Query1 = %', strQuery;                

raise notice 'Inizio query importi capitoli - %' , clock_timestamp()::text;
execute  strQuery;
raise notice 'Fine query importi capitoli - % - Inizio query variazioni' , clock_timestamp()::text;
-----------------------------

--Caricamento degli importi delle variazioni.  
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.            
--Parametro specificato: atto di variazione.
if p_numero_delibera is not null THEN        
    insert into siac_rep_var_spese    
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id	      	
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
            siac_t_bil					t_bil,
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
    and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
    and 	t_bil.bil_id 										= testata_variazione.bil_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	atto.ente_proprietario_id 							= 	p_ente_prop_id 
    and		anno_eserc.anno										= 	p_anno				 	
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
        -- 27/04:2017 l'anno di esercizio deve essere collegato a siac_t_bil									
        --and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
    and		anno_importi.anno									= 	annoCapImp 									
     -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
    -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
    and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
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
    and		t_bil.data_cancellazione					is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                atto.ente_proprietario_id   ;
ELSE  --specificata la variazione
	strQuery:= '
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
        from 	siac_r_variazione_stato		r_variazione_stato,
                siac_t_variazione 			testata_variazione,
                siac_d_variazione_tipo		tipologia_variazione,
                siac_d_variazione_stato 	tipologia_stato_var,
                siac_t_bil_elem_det_var 	dettaglio_variazione,
                siac_t_bil_elem				capitolo,
                siac_d_bil_elem_tipo 		tipo_capitolo,
                siac_d_bil_elem_det_tipo	tipo_elemento,
                siac_t_periodo 				anno_eserc ,
                siac_t_bil					t_bil,
                siac_t_periodo 				anno_importi
        where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
        and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
        and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
        and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
        and		dettaglio_variazione.elem_id						=	capitolo.elem_id
        and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
        and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
        and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
        and 	t_bil.bil_id 										= testata_variazione.bil_id
        and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
        and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id ||'
        and		anno_eserc.anno										= 	'''||p_anno||''' 
        and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
        and		anno_importi.anno									= 	'''||annoCapImp||'''									
        and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
        and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
        and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
        and		r_variazione_stato.data_cancellazione		is null
        and		testata_variazione.data_cancellazione		is null
        and		tipologia_variazione.data_cancellazione		is null
        and		tipologia_stato_var.data_cancellazione		is null
        and 	dettaglio_variazione.data_cancellazione		is null
        and 	capitolo.data_cancellazione					is null
        and		tipo_capitolo.data_cancellazione			is null
        and		tipo_elemento.data_cancellazione			is null
        and		t_bil.data_cancellazione					is null
        group by 	dettaglio_variazione.elem_id,
                    tipo_elemento.elem_det_tipo_code, 
                    utente,
                    testata_variazione.ente_proprietario_id';                    

	raise notice 'Query2 = %', strQuery;
    execute  strQuery;
    
end if;    
raise notice 'Fine query Variazioni - % - inizio query finale' , clock_timestamp()::text;


return query 
with strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
		capitoli as (select programma.classif_id programma_id,
						macroaggr.classif_id macroaggregato_id,        				
       					capitolo.elem_code, capitolo.elem_code2,
                        capitolo.elem_desc, capitolo.elem_desc2,
                        capitolo.elem_id, capitolo.elem_id_padre
                from siac_d_class_tipo programma_tipo,
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
                where programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
                    and programma.classif_id=r_capitolo_programma.classif_id	
                    and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 
                    and macroaggr.classif_id=r_capitolo_macroaggr.classif_id								
                    and capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                    and capitolo.elem_id=r_capitolo_programma.elem_id		
                    and capitolo.elem_id=r_capitolo_macroaggr.elem_id	
                    and capitolo.elem_id		=	r_capitolo_stato.elem_id	
                    and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                    and capitolo.elem_id				=	r_cat_capitolo.elem_id	
                    and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
                    and capitolo.ente_proprietario_id=p_ente_prop_id   		
                    and capitolo.bil_id= bilancio_id		
                    and programma_tipo.classif_tipo_code='PROGRAMMA'	
                    and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'	                     							                    	
                    and tipo_elemento.elem_tipo_code = elemTipoCode			                     			                    
                    and stato_capitolo.elem_stato_code	=	'VA'				
                    and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')                    
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
                    and	r_cat_capitolo.data_cancellazione 			is null),
         importi_stanz as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_cassa as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno_competenza
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_stanz_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpComp -- ''STA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id),   
         variaz_cassa_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario = p_ente_prop_id
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo > 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_cassa_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpCassa -- ''SCA''
                        and a.importo < 0 
                        and a.utente=user_table
                        group by  a.elem_id), 
         variaz_residui_pos as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id                        and a.tipologia='''||TipoImpRes||''' -- ''STR''
                        and a.importo > 0
                        and a.utente=user_table
                        group by  a.elem_id),
         variaz_residui_neg as (select a.elem_id, sum(a.importo) importo_var
                        from siac_rep_var_spese a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.tipologia=TipoImpRes -- ''STR''
                        and a.importo < 0
                        and a.utente=user_table
                        group by  a.elem_id)                     
		select p_anno::varchar bil_anno,
  			strutt_bilancio.missione_tipo_desc::varchar missione_tipo_desc ,
  			strutt_bilancio.missione_code::varchar missione_code,
            strutt_bilancio.missione_desc::varchar missione_desc,
            strutt_bilancio.programma_tipo_desc::varchar programma_tipo_desc,
            strutt_bilancio.programma_code::varchar programma_code,
            strutt_bilancio.programma_desc::varchar programma_desc,
            strutt_bilancio.titusc_tipo_desc::varchar titusc_tipo_desc,
            strutt_bilancio.titusc_code::varchar titusc_code,
            strutt_bilancio.titusc_desc::varchar titusc_desc,
            strutt_bilancio.macroag_tipo_desc::varchar macroag_tipo_desc,
            strutt_bilancio.macroag_code::varchar macroag_code,
            strutt_bilancio.macroag_desc::varchar macroag_desc,
            capitoli.elem_code::varchar bil_ele_code ,
            capitoli.elem_desc::varchar bil_ele_desc,
            capitoli.elem_code2::varchar bil_ele_code2,
            capitoli.elem_desc2::varchar bil_ele_desc2,
            capitoli.elem_id::integer bil_ele_id,
            capitoli.elem_id_padre::integer bil_ele_id_padre,
            COALESCE(importi_stanz.importo_cap,0)::numeric stanziamento,
            COALESCE(importi_cassa.importo_cap,0)::numeric cassa,
            COALESCE(importi_residui.importo_cap,0)::numeric residuo,
            COALESCE(variaz_stanz_pos.importo_var,0)::numeric variazione_aumento_stanziato,
            COALESCE(variaz_stanz_neg.importo_var *-1,0)::numeric variazione_diminuzione_stanziato,
            COALESCE(variaz_cassa_pos.importo_var,0)::numeric variazione_aumento_cassa,
            COALESCE(variaz_cassa_neg.importo_var *-1,0)::numeric variazione_diminuzione_cassa,
            COALESCE(variaz_residui_pos.importo_var,0)::numeric variazione_aumento_residuo,
            COALESCE(variaz_residui_neg.importo_var *-1,0)::numeric variazione_diminuzione_residuo,
            ''::varchar display_error		                                        
         from strutt_bilancio
         	LEFT JOIN capitoli
            	ON (strutt_bilancio.programma_id = capitoli.programma_id
                	and strutt_bilancio.macroag_id = capitoli.macroaggregato_id)
            LEFT JOIN importi_stanz
            	ON importi_stanz.elem_id = capitoli.elem_id
            LEFT JOIN importi_cassa
            	ON importi_cassa.elem_id = capitoli.elem_id
            LEFT JOIN importi_residui
            	ON importi_residui.elem_id = capitoli.elem_id
            LEFT JOIN variaz_stanz_pos
            	ON variaz_stanz_pos.elem_id = capitoli.elem_id
            LEFT JOIN variaz_stanz_neg
            	ON variaz_stanz_neg.elem_id = capitoli.elem_id
            LEFT JOIN variaz_cassa_pos
            	ON variaz_cassa_pos.elem_id = capitoli.elem_id
            LEFT JOIN variaz_cassa_neg
            	ON variaz_cassa_neg.elem_id = capitoli.elem_id
            LEFT JOIN variaz_residui_pos
            	ON variaz_residui_pos.elem_id = capitoli.elem_id
            LEFT JOIN variaz_residui_neg
            	ON variaz_residui_neg.elem_id = capitoli.elem_id
          where exists (select 1 from siac_r_class_fam_tree aa,
        				capitoli bb,
                        siac_rep_cap_ug_imp cc
        			where bb.elem_id =cc.elem_id
                    	and bb.macroaggregato_id = aa.classif_id
                 		and aa.classif_id_padre = strutt_bilancio.titusc_id 
                        and bb.programma_id=strutt_bilancio.programma_id
                        and cc.utente=user_table);
                	
    
raise notice 'Fine query finale - %' , clock_timestamp()::text;

delete from siac_rep_cap_ug_imp where utente=user_table;
delete from siac_rep_var_spese where utente=user_table;



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

--SIAC-7226 - Maurizio - FINE


--SIAC-7268 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR093_elenco_capitoli_entrate" (
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
  cod_titolo varchar,
  descr_titolo varchar,
  cod_tipologia varchar,
  descr_tipologia varchar,
  cod_categoria varchar,
  descr_categoria varchar,
  siope varchar,
  descr_strutt_amm varchar,
  tipo_capitolo varchar,
  accertabile varchar,
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
elencoDispon  record;

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
v_fam_titolotipologiacategoria varchar:='00003';

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
    cod_tipologia='';
    descr_tipologia='';
    cod_categoria='';
    descr_categoria='';
    cod_titolo='';
    descr_titolo='';
    siope='';

    descr_strutt_amm='';
    tipo_capitolo='';
    accertabile='';
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
        Nel caso siano richieste solo le spese, questa procedura non
        esegue alcuna estrazione, visto che la relativa tabella
        nel report non sara' visualizzata */
    if p_tipo = 'S' THEN
    	return;
    end if;
    
    select fnc_siac_random_user()
	into	user_table;
	


RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';

raise notice 'Caricamento struttura dei capitoli' ;
/*insert into  siac_rep_tit_tip_cat_riga_anni
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


--06/09/2016: cambiata la query che carica la struttura di bilancio
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
 
raise notice 'Caricamento dati dei capitoli' ;
insert into siac_rep_cap_entrata_completo
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente, pdc.classif_code||' - '||pdc.classif_desc,
  tipo_elemento.elem_tipo_code
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
AND r_capitolo_pdc.classif_id 			= pdc.classif_id
AND pdc.classif_tipo_id 				= pdc_tipo.classif_tipo_id	
and e.elem_id 					= 	r_capitolo_pdc.elem_id	
AND	pdc_tipo.classif_tipo_code like 'PDC_%'		
AND (p_tipo_capitolo ='T' 
     	AND tipo_elemento.elem_tipo_code in ('CAP-EG','CAP-EP') OR
     p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-EP' OR
     p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-EG')  
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



RTN_MESSAGGIO:='Caricamento importi dei capitoli ''.';

raise notice 'Caricamento importi dei capitoli' ;
insert into siac_rep_cap_ep_imp 
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
        --SIAC-7268: per errore erano caricati gli importi dei capitoli di spesa.
     	AND tipo_elemento.elem_tipo_code in ('CAP-EG','CAP-EP')) OR
     (p_tipo_capitolo ='P' AND tipo_elemento.elem_tipo_code ='CAP-EP') OR
     (p_tipo_capitolo ='G' AND tipo_elemento.elem_tipo_code ='CAP-EG'))         
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


/* TipoImpstanz='STA'; 		-- stanziamento  (CP)
    TipoImpCassa ='SCA'; 		----- cassa	(CS)
    TipoImpResiduo='STR';	-- stanziamento residuo
        
    TipoImpstanzresiduiIniz='SRI'; 	-- stanziamento residuo iniziale (RS)
    tipoImpCassaIniz='SCI';			--Stanziamento Cassa Iniziale
    TipoImpstanzIniz='STI';			--Stanziamento  Iniziale  */   
    
raise notice 'Caricamento importi per riga dei capitoli' ;    
insert into siac_rep_cap_entrata_imp_completo_riga
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
       --SIAC-7268 per la tabella tb1 era erroneamente usata la siac_rep_cap_up_imp
from 	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
		siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6,
        siac_rep_cap_ep_imp tb7, siac_rep_cap_ep_imp tb8, siac_rep_cap_ep_imp tb9,
        siac_rep_cap_ep_imp tb10, siac_rep_cap_ep_imp tb11, siac_rep_cap_ep_imp tb12,
        siac_rep_cap_ep_imp tb13, siac_rep_cap_ep_imp tb14, siac_rep_cap_ep_imp tb15,
        siac_rep_cap_ep_imp tb16, siac_rep_cap_ep_imp tb17, siac_rep_cap_ep_imp tb18        
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
 raise notice 'estrazione dei dati dalle tabelle di comodo e preparazione dati in output' ;
for classifBilRec in
  select 	v1.categoria_code		categoria_code,
  			v1.categoria_desc		categoria_desc,
            v1.tipologia_code		tipologia_code,
            v1.tipologia_desc		tipologia_desc,
            v1.titolo_code			titolo_code,
            v1.titolo_desc			titolo_desc,
          tb.anno_bilancio 				BIL_ANNO,
          tb.elem_code     				BIL_ELE_CODE,
          tb.elem_code2     			BIL_ELE_CODE2,
          tb.elem_code3					BIL_ELE_CODE3,
          tb.elem_desc     				BIL_ELE_DESC,
          tb.elem_desc2     			BIL_ELE_DESC2,
          tb.elem_id      				BIL_ELE_ID,
          tb.elem_id_padre    			BIL_ELE_ID_PADRE,
          tb.pdc						pdc_finanziario,
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
          d_categoria.elem_cat_code, d_categoria.elem_cat_desc,
          ente_prop.ente_denominazione ente_prop_denom,
          tb.tipo_capitolo
   from   
      siac_rep_tit_tip_cat_riga_anni v1,    
      siac_t_ente_proprietario  ente_prop,  
      siac_r_bil_elem_categoria  r_categoria,
      siac_d_bil_elem_categoria  d_categoria,
      siac_rep_cap_entrata_completo tb
              left	join    siac_rep_cap_entrata_imp_completo_riga 	tb1  
           			on tb1.elem_id	=	tb.elem_id 	
 where              v1.categoria_id = tb.classif_id                          
                      and v1.ente_proprietario_id=p_ente_prop_id
                      AND TB.utente=V1.utente
                      and v1.utente=user_table 
                      and tb.elem_code IS NOT NULL 
                      and tb.elem_id=r_categoria.elem_id    
                      and tb.ente_proprietario_id=ente_prop.ente_proprietario_id
                      and r_categoria.elem_cat_id=  d_categoria.elem_cat_id              
                      and d_categoria.data_cancellazione IS NULL
                      And r_categoria.data_cancellazione IS NULL
                      and ente_prop.data_cancellazione IS NULL
  order by v1.titolo_code,v1.tipologia_code,v1.categoria_code,tb.elem_code::INTEGER,tb.elem_code2::INTEGER            

        
    loop
         
    nome_ente=classifBilRec.ente_prop_denom;
    bil_anno=classifBilRec.BIL_ANNO;
    tipo_capitolo_pg=classifBilRec.tipo_capitolo;
    anno_capitolo=classifBilRec.BIL_ANNO;
    cod_capitolo=classifBilRec.BIL_ELE_CODE;
    cod_articolo=classifBilRec.BIL_ELE_CODE2;
    ueb=classifBilRec.BIL_ELE_CODE3;
    descr_capitolo=classifBilRec.BIL_ELE_DESC;
    descr_articolo=classifBilRec.BIL_ELE_DESC2;
	cod_tipologia=classifBilRec.tipologia_code;
    descr_tipologia=classifBilRec.tipologia_desc;
    cod_categoria=classifBilRec.categoria_code;
    descr_categoria=classifBilRec.categoria_desc;
    cod_titolo=classifBilRec.titolo_code;
    descr_titolo=classifBilRec.titolo_desc;
    
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
    
    	/* cerco gli attributi.
        	Al momento cerco solo 'FlagImpegnabile', ma e' gia'
            predisposto per cercare eventuali altri attributi. */
    BEGIN
    	for elencoAttrib IN
        	SELECT b.attr_code, a.boolean
    			from siac_r_bil_elem_attr a,
    			siac_t_attr b
   			 where a.attr_id=b.attr_id
              and a.elem_id=classifBilRec.BIL_ELE_ID
              and b.attr_code='FlagImpegnabile'
              and a.data_cancellazione IS NULL
              and b.data_cancellazione IS NULL 
        loop
        	IF elencoAttrib.attr_code='FlagImpegnabile' THEN
        		accertabile=elencoAttrib.boolean;
            end if;
        end loop;
    END;
    
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
              and r_bil_elem_class.elem_id=classifBilRec.BIL_ELE_ID
        loop
          if substr(elencoClass.classif_tipo_code,1,11) ='SIOPE_SPESA' THEN
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
     
     IF tipo_capitolo_pg = 'CAP-EG' THEN
     -- raise notice 'ora: % ',clock_timestamp()::varchar;
     --raise notice 'ricerca della disponibilita' per ID capitolo % ',classifBilRec.BIL_ELE_ID;		
      BEGIN
        for elencoDispon in
            SELECT * 
            FROM fnc_siac_disponibilitaaccertareeg_3anni(classifBilRec.BIL_ELE_ID)
        loop
            IF elencoDispon.annocompetenza = annoCapImp  THEN
                disp_stanz_anno=elencoDispon.dispaccertare;
            elsif elencoDispon.annocompetenza = annoCapImp1 THEN
                disp_stanz_anno1=elencoDispon.dispaccertare;
            elsif elencoDispon.annocompetenza = annoCapImp2 THEN
                disp_stanz_anno2=elencoDispon.dispaccertare;
            end if;
            
        end loop;
      END;
          
     -- raise notice 'ora: % ',clock_timestamp()::varchar;
    else
        disp_stanz_anno=0;
    	disp_stanz_anno1=0;
    	disp_stanz_anno2=0;
    end if;           
      
      
      
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
    cod_tipologia='';
    descr_tipologia='';
    cod_categoria='';
    descr_categoria='';
    cod_titolo='';
    descr_titolo='';
    siope='';
    descr_strutt_amm='';
    tipo_capitolo='';
    accertabile='';
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

  
  delete from   siac_rep_tit_tip_cat_riga_anni 	where utente=user_table;
  delete from  siac_rep_cap_entrata_completo				where utente=user_table;
  delete from siac_rep_cap_ep_imp where utente=user_table;
  delete from siac_rep_cap_entrata_imp_completo_riga where utente=user_table;	
   
exception
	when no_data_found THEN
		raise notice 'Dati dei capitoli di entrata non trovati.' ;
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

--SIAC-7268 - Maurizio - FINE

--SIAC-7204 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR040_progetti_per_capitolo_dati_cronop"(p_ente_prop_id integer, p_capitolo varchar, p_articolo varchar, p_ueb varchar, p_tipologia_capitolo varchar, p_anno_bilancio varchar);

CREATE OR REPLACE FUNCTION siac."BILR040_progetti_per_capitolo_dati_cronop" (
  p_ente_prop_id integer,
  p_capitolo varchar,
  p_articolo varchar,
  p_ueb varchar,
  p_tipologia_capitolo varchar,
  p_anno_bilancio varchar
)
RETURNS TABLE (
  tipo_liv1 varchar,
  codice_liv1 varchar,
  descr_liv1 varchar,
  tipo_liv2 varchar,
  codice_liv2 varchar,
  descr_liv2 varchar,
  tipo_liv3 varchar,
  codice_liv3 varchar,
  descr_liv3 varchar,
  tipo_liv4 varchar,
  codice_liv4 varchar,
  descr_liv4 varchar,
  id_progetto integer,
  capitolo varchar,
  articolo varchar,
  ueb varchar,
  anno_competenza_stanziamento varchar,
  anno_entrata_rif_spesa varchar,
  stanziato numeric,
  descrizione1_attivita varchar,
  descrizione2_attivita varchar,
  cronoprogramma_id integer,
  cronoprogramma_codice varchar,
  cronoprogramma_descrizione varchar,
  stato varchar,
  note_cronoprogramma varchar,
  cronop_id_elem integer,
  anno_bilancio varchar,
  tipologia_capitolo varchar,
  codice_classificatore varchar,
  descrizione_classificatore varchar,
  descrizione_tipo_classificatore varchar
) AS
$body$
DECLARE
datistrutturaRec record;
progettoRec record;
datiCronoprogrammaRec record;


tipo_capitolo_P varchar;
tipo_capitolo_G varchar;
descrizione_classificatore varchar;
codice_classificatore	varchar;
descrizione_tipo_classificatore	varchar;
tipologia_capitolo	varchar;
DEF_NULL	constant varchar:='';
def_spazio	constant varchar:=' ';  
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;



BEGIN

	tipo_capitolo_G='';
	tipo_capitolo_P='';
	tipo_liv1='';
    codice_liv1='';
  	descr_liv1='';
  	tipo_liv2='';
    codice_liv2='';
  	descr_liv2='';
  	tipo_liv3='';
    codice_liv3='';
  	descr_liv3='';
  	tipo_liv4='';
    codice_liv4='';
  	descr_liv4='';
  	id_progetto=0;
    capitolo='';
  	articolo='';
  	ueb='';
  	anno_competenza_stanziamento='';
  	anno_entrata_rif_spesa='';
  	stanziato=0;
    descrizione1_attivita='';
    descrizione2_attivita='';


---  ricercare la tipologia di capitolo partendo dal parametro indicato dall'operatore 

if p_tipologia_capitolo = 'E' THEN
	tipo_capitolo_P='CAP-EP';
	tipo_capitolo_G='CAP-EG';
else
	tipo_capitolo_P='CAP-UP';
	tipo_capitolo_G='CAP-UG';
end if;


select fnc_siac_random_user()
into	user_table;

--SIAC-7204: effettuate modifiche per problemi di prestazioni.

----------------------------------------------------------------------------------------------------------------------
if	((coalesce(trim(p_articolo),'')='' and coalesce(trim(p_ueb),'')='')	
    and coalesce(trim(p_anno_bilancio),'')='') THEN    
    raise notice 'passo 1';
      insert into siac_rep_prog_cronop
          select 	a.programma_id,
          			b.cronop_id,
                    periodo.anno,
                    user_table
          from 	siac_t_programma a, 
          		siac_t_cronop b, 
                siac_t_cronop_elem c, 
                siac_d_bil_elem_tipo d,
                siac_t_bil	bil,
                siac_t_periodo periodo
          where 	c.cronop_elem_code 				= 	p_capitolo
          -----and		c.cronop_elem_code2				is null
          ------and 		c.cronop_elem_code3 			is null
          and 		c.elem_tipo_id 					= 	d.elem_tipo_id
          and		d.elem_tipo_code in (tipo_capitolo_P, tipo_capitolo_G)
          and 		c.cronop_id 					= 	b.cronop_id
          and 		b.programma_id 					= 	a.programma_id
          and		b.bil_id						=	bil.bil_id
          and		bil.periodo_id					=	periodo.periodo_id
          and 		c.ente_proprietario_id 			= 	p_ente_prop_id
          and 		b.ente_proprietario_id 			= 	c.ente_proprietario_id
          and 		a.ente_proprietario_id			=	c.ente_proprietario_id
          and 		d.ente_proprietario_id			=	c.ente_proprietario_id
          and		bil.ente_proprietario_id		= 	c.ente_proprietario_id
          and		periodo.ente_proprietario_id	= 	c.ente_proprietario_id
          group by a.programma_id, b.cronop_id,periodo.anno;
else
      if (coalesce(trim(p_articolo),'')='' and coalesce(trim(p_ueb),'')='')
          and p_anno_bilancio > '0'
          THEN 
              raise notice 'passo 2';
          insert into  siac_rep_prog_cronop
            select 	a.programma_id,
          			b.cronop_id,
                    periodo.anno,
                    user_table
                  from 	siac_t_programma a, 
                          siac_t_cronop b, 
                          siac_t_cronop_elem c, 
                          siac_t_bil	bil,
                          siac_t_periodo periodo,
                          siac_d_bil_elem_tipo d
                  where 	b.bil_id				=	bil.bil_id
                  and		bil.periodo_id			=	periodo.periodo_id
                  and		periodo.anno			=	p_anno_bilancio
                  and		c.cronop_elem_code 		= 	p_capitolo
                  ----and		c.cronop_elem_code2			is null
                  ------and 		c.cronop_elem_code3 		is null
                  and 		c.elem_tipo_id 			= 	d.elem_tipo_id
                  and		d.elem_tipo_code in (tipo_capitolo_P, tipo_capitolo_G)
                  and 		c.cronop_id 			= 	b.cronop_id
                  and 		b.programma_id 			= 	a.programma_id
                  and 		c.ente_proprietario_id 	= 	p_ente_prop_id
                  and 		b.ente_proprietario_id 	= 	c.ente_proprietario_id
                  and 		a.ente_proprietario_id	=	c.ente_proprietario_id
                  and 		d.ente_proprietario_id	=	c.ente_proprietario_id
                  group by  a.programma_id, b.cronop_id,periodo.anno;        
         else
        	if	(coalesce(p_anno_bilancio,'')='' ) THEN          			 
                        raise notice 'passo 3';
                  	insert into siac_rep_prog_cronop
                       select 	a.programma_id,
          						b.cronop_id,
                                periodo.anno,
                                user_table
                      from 		siac_t_programma a, 
                              	siac_t_cronop b, 
                              	siac_t_cronop_elem c, 
                              	siac_d_bil_elem_tipo d,
                                siac_t_bil	bil,
                				siac_t_periodo periodo
                      where 	c.cronop_elem_code 		= 	p_capitolo
                      and		(c.cronop_elem_code2		= 	p_articolo OR 
                      				coalesce(trim(p_articolo),'')='')
                      and 		(c.cronop_elem_code3 	= 	p_ueb OR
                      				coalesce(trim(p_ueb),'')='')
                      and 		c.elem_tipo_id 			= 	d.elem_tipo_id
                      and		d.elem_tipo_code in (tipo_capitolo_P, tipo_capitolo_G)
                      and 		c.cronop_id 			= 	b.cronop_id
                      and 		b.programma_id 			= 	a.programma_id
                      and		b.bil_id				=	bil.bil_id
          			  and		bil.periodo_id			=	periodo.periodo_id
                      and 		c.ente_proprietario_id 	= 	p_ente_prop_id
                      and 		b.ente_proprietario_id 	= 	c.ente_proprietario_id
                      and 		a.ente_proprietario_id	=	c.ente_proprietario_id
                      and 		d.ente_proprietario_id	=	c.ente_proprietario_id
                      and		bil.ente_proprietario_id		= 	c.ente_proprietario_id
          			  and		periodo.ente_proprietario_id	= 	c.ente_proprietario_id
                      group by a.programma_id, b.cronop_id,periodo.anno;
			ELSE
					     raise notice 'passo 4';
                    insert into siac_rep_prog_cronop
           			 select 	a.programma_id,
                     			b.cronop_id,
                                periodo.anno,
                                user_table
                      from 		siac_t_programma a, 
                              	siac_t_cronop b, 
                              	siac_t_cronop_elem c, 
                              	siac_t_bil	bil,
                              	siac_t_periodo periodo,
                              	siac_d_bil_elem_tipo d
                      where 	b.bil_id				=	bil.bil_id
                      and		bil.periodo_id			=	periodo.periodo_id
                      and		periodo.anno			=	p_anno_bilancio
                      and		c.cronop_elem_code 		= 	p_capitolo
                      and		(c.cronop_elem_code2		= 	p_articolo OR 
                      				coalesce(trim(p_articolo),'')='')                      
                   	  and 		(c.cronop_elem_code3 	= 	p_ueb OR
                      				coalesce(trim(p_ueb),'')='')
                      and 		c.elem_tipo_id 			= 	d.elem_tipo_id
                      and		d.elem_tipo_code in (tipo_capitolo_P, tipo_capitolo_G)
                      and 		c.cronop_id 			= 	b.cronop_id
                      and 		b.programma_id 			= 	a.programma_id
                      and 		c.ente_proprietario_id 	= 	p_ente_prop_id
                      and 		b.ente_proprietario_id 	= 	c.ente_proprietario_id
                      and 		a.ente_proprietario_id	=	c.ente_proprietario_id
                      and 		d.ente_proprietario_id	=	c.ente_proprietario_id
                      and		bil.ente_proprietario_id		= 	c.ente_proprietario_id
          			  and		periodo.ente_proprietario_id	= 	c.ente_proprietario_id
                      group by  a.programma_id, b.cronop_id,periodo.anno;
			end if; 
      end if;
end if;  
-------------------------------------------------------------------------------------------------------------

for progettoRec in
    select 	id_programma		id_progetto,
    		id_cronoprogramma	cronoprogramma_id,
            anno_del_bilancio	anno_bilancio
    from 	siac_rep_prog_cronop a 
    where 	a.utente	=	user_table
loop
	id_progetto:=progettoRec.id_progetto; 
    cronoprogramma_id:=progettoRec.cronoprogramma_id; 
    anno_bilancio:=progettoRec.anno_bilancio;
raise notice 'id_progetto = % - cronoprogramma_id = %', id_progetto, cronoprogramma_id;

    BEGIN
    for datiCronoprogrammaRec in
        select 		a.programma_id, 
                  	a.cronop_id					cronoprogramma_id, 
                  	a.cronop_code				cronoprogramma_codice, 
                  	a.cronop_desc				cronoprogramma_descrizione, 
                    COALESCE (c.anno_entrata,' ')	anno_entrata_rif_spesa, 
                  	c.periodo_id, 
                    COALESCE (d.anno,' ')		anno_competenza_stanziamento, 
                  	----c.cronop_elem_det_id		cronop_id_elem,
                    b.cronop_elem_id			cronop_id_elem,
                    k.elem_tipo_code			tipologia_capitolo,
                    b.elem_tipo_id,
                  	c.cronop_elem_det_importo	stanziato, 
                  	b.cronop_elem_desc			descrizione1_attivita, 
                  	b.cronop_elem_desc2			descrizione2_attivita,
                    COALESCE (b.cronop_elem_code,' ')	capitolo, 	
                    COALESCE (b.cronop_elem_code2,' ')	articolo, 	
                    COALESCE (b.cronop_elem_code3,' ')	ueb, 	
                  	f.cronop_stato_code, 
                  	f.cronop_stato_desc			stato,
                     (select 	r.testo
                  from  	siac_t_cronop a1,
                            siac_r_cronop_attr r,
                            siac_t_attr ta, 
                            siac_d_attr_tipo i    
                  where		a1.cronop_id	=	a.cronop_id
                  and		a1.cronop_id	=	r.cronop_id
                  and		ta.attr_id			=	r.attr_id
                  and		ta.attr_tipo_id		=	i.attr_tipo_id
                  and 		i.attr_tipo_code	=	'X'
                  --SIAC-6821 16/05/2019.
                  --Mancava il filtro sul nome dell'attributo da estrarre.
                  and 		upper(ta.attr_code)='NOTE'
                  and		r.data_cancellazione	is null
                  and		ta.data_cancellazione	is null
                  and		a.ente_proprietario_id	= p_ente_prop_id)  note_cronoprogramma
          from  	siac_r_cronop_stato e,
                  	siac_d_cronop_stato f,
                  	siac_t_cronop a,
                  	siac_t_cronop_elem b,
                    siac_d_bil_elem_tipo	k, 
                  	siac_t_cronop_elem_det c
                  FULL join  siac_t_periodo d
                  on (c.periodo_id		=	d.periodo_id)       
          where		a.programma_id			=	progettoRec.id_progetto 
          and		a.cronop_id				=	progettoRec.cronoprogramma_id	
          and		c.cronop_elem_id		=	b.cronop_elem_id
          and		b.cronop_id				=	a.cronop_id	
          and		a.ente_proprietario_id 	= 	p_ente_prop_id
          and 		b.ente_proprietario_id	=	a.ente_proprietario_id
          and		c.ente_proprietario_id	=	a.ente_proprietario_id
          and		e.cronop_id				=	a.cronop_id
          and		e.cronop_stato_id		=	f.cronop_stato_id
          and 		b.elem_tipo_id 			= 	k.elem_tipo_id
          and		d.ente_proprietario_id	=	a.ente_proprietario_id
          and		e.ente_proprietario_id	=	a.ente_proprietario_id
          and		f.ente_proprietario_id	=	a.ente_proprietario_id
          and		a.data_cancellazione is null
          and		b.data_cancellazione is null 
          and		c.data_cancellazione is null 
          and		d.data_cancellazione is null 
          and		e.data_cancellazione is null 
          and		f.data_cancellazione is null 
          order by a.programma_id,a.cronop_id,c.anno_entrata,d.anno 
		loop
        	cronoprogramma_codice:=datiCronoprogrammaRec.cronoprogramma_codice;
            cronoprogramma_id:=datiCronoprogrammaRec.cronoprogramma_id;  
            cronoprogramma_descrizione:=datiCronoprogrammaRec.cronoprogramma_descrizione;
            note_cronoprogramma:=datiCronoprogrammaRec.note_cronoprogramma; 
            anno_entrata_rif_spesa:=datiCronoprogrammaRec.anno_entrata_rif_spesa; 
            anno_competenza_stanziamento:=datiCronoprogrammaRec.anno_competenza_stanziamento; 
            stanziato:=datiCronoprogrammaRec.stanziato; 
            descrizione1_attivita:=datiCronoprogrammaRec.descrizione1_attivita;
            descrizione2_attivita:=datiCronoprogrammaRec.descrizione2_attivita;
            capitolo:=datiCronoprogrammaRec.capitolo; 
            articolo:=datiCronoprogrammaRec.articolo;
            ueb:=datiCronoprogrammaRec.ueb; 
            stato:=datiCronoprogrammaRec.stato;
            cronop_id_elem:=datiCronoprogrammaRec.cronop_id_elem;
            tipologia_capitolo:=datiCronoprogrammaRec.tipologia_capitolo;
raise notice 'datiCronoprogrammaRec.cronop_id_elem = %', datiCronoprogrammaRec.cronop_id_elem;

        if  datiCronoprogrammaRec.tipologia_capitolo in ('CAP-EP', 'CAP-EG') then -- or datiCronoprogrammaRec.tipologia_capitolo =  THEN
    			if	coalesce(datiCronoprogrammaRec.articolo ,DEF_spazio)=DEF_spazio and coalesce(datiCronoprogrammaRec.ueb,DEF_spazio)=DEF_spazio	
                THEN     	 		
    	 			BEGIN
    				for datistrutturaRec in
                     select distinct titolo_tipo.classif_tipo_desc  		tipo_liv1,
                             titolo.classif_code            				codice_liv1,
                             titolo.classif_desc            				descr_liv1,
                             tipologia_tipo.classif_tipo_desc				tipo_liv2,
                             tipologia.classif_code           			codice_liv2,
                             tipologia.classif_desc           			descr_liv2
                      from siac_t_class_fam_tree 			titolo_tree,
                           siac_d_class_fam 				titolo_fam,
                           siac_r_class_fam_tree 			titolo_r_cft,
                           siac_t_class 					titolo,
                           siac_d_class_tipo 				titolo_tipo,
                           siac_d_class_tipo 				tipologia_tipo,
                           siac_t_class 					tipologia,
                           siac_r_cronop_elem_class		r_cronp_class,
                           siac_t_cronop_elem_det			cronop_elem
                      where titolo_tree.classif_fam_id					=	titolo_fam.classif_fam_id
                            and 	titolo_r_cft.classif_fam_tree_id	=	titolo_tree.classif_fam_tree_id
                            and 	titolo.classif_id					=	titolo_r_cft.classif_id_padre
                            and 	titolo.classif_tipo_id				=	titolo_tipo.classif_tipo_id
                            and 	tipologia.classif_tipo_id			=	tipologia_tipo.classif_tipo_id
                            and 	titolo_r_cft.classif_id				=	tipologia.classif_id
                            and 	r_cronp_class.classif_id			=	tipologia.classif_id
                            and   titolo_fam.classif_fam_desc			=	'Entrata - TitoliTipologieCategorie'      
                            and 	titolo_tipo.classif_tipo_code		=	'TITOLO_ENTRATA'
                            and 	tipologia_tipo.classif_tipo_code	=	'TIPOLOGIA'
                            and	r_cronp_class.cronop_elem_id			=	datiCronoprogrammaRec.cronop_id_elem
                            and 	titolo.ente_proprietario_id			=	p_ente_prop_id
                             and 	titolo.data_cancellazione			is null
                            and 	tipologia.data_cancellazione		is null
                            and	r_cronp_class.data_cancellazione		is null
                            and 	titolo_tree.data_cancellazione		is null
                            and 	titolo_fam.data_cancellazione		is null
                            and 	titolo_r_cft.data_cancellazione		is null
                            and 	titolo_tipo.data_cancellazione		is null
                            and 	tipologia_tipo.data_cancellazione	is null
                            and 	cronop_elem.data_cancellazione		is null                    
                      	loop
                        	tipo_liv1:=datistrutturaRec.tipo_liv1;
                                descr_liv1:=datistrutturaRec.descr_liv1;
                                codice_liv1:=datistrutturaRec.codice_liv1;
                                tipo_liv2:=datistrutturaRec.tipo_liv2;
                                descr_liv2:=datistrutturaRec.descr_liv2;
                                codice_liv2:=datistrutturaRec.codice_liv2;
                                                                
                        end loop;
                        exception
                          when no_data_found THEN
                          raise notice 'nessuna struttura collegata' ;
                          return;
                          when others  THEN
                          RTN_MESSAGGIO:='ricerca struttura nuovo capitolo entrata oppure senza capitolo entrata';
                          RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                          return;
                    end;
    			else --ci sono articolo/UEB
    ------------------------------------------------------------------------------------------------------------------------
                    BEGIN
                    for datistrutturaRec in
                        select distinct titolo_tipo.classif_tipo_desc  		tipo_liv1,
                               titolo.classif_code            				codice_liv1,
                               titolo.classif_desc            				descr_liv1,
                               tipologia_tipo.classif_tipo_desc				tipo_liv2,
                               tipologia.classif_code           			codice_liv2,
                               tipologia.classif_desc           			descr_liv2,
                               categoria_tipo.classif_tipo_desc  			tipo_liv3,
                               categoria.classif_code              			codice_liv3,
                               categoria.classif_desc               		descr_liv3
                        from siac_t_class_fam_tree 			titolo_tree,
                             siac_d_class_fam 				titolo_fam,
                             siac_r_class_fam_tree 			titolo_r_cft,
                             siac_r_class_fam_tree 			tipologia_r_cft,
                             siac_t_class 					titolo,
                             siac_d_class_tipo 				titolo_tipo,
                             siac_d_class_tipo 				tipologia_tipo,
                             siac_t_class 					tipologia,
                             siac_d_class_tipo 				categoria_tipo,
                             siac_t_class 					categoria,
                             siac_r_bil_elem_class 			r_capitolo_categoria,
                             siac_r_cronop_elem_bil_elem	r_cronop_elem,
                             siac_t_cronop_elem_det			cronop_elem
                        where 		titolo_fam.classif_fam_desc					=	'Entrata - TitoliTipologieCategorie'
                              and 	titolo_tree.classif_fam_id					=	titolo_fam.classif_fam_id
                              and 	titolo_r_cft.classif_fam_tree_id			=	titolo_tree.classif_fam_tree_id
                              and 	titolo.classif_id							=	titolo_r_cft.classif_id_padre
                              and 	titolo_tipo.classif_tipo_code				=	'TITOLO_ENTRATA'
                              and 	titolo.classif_tipo_id						=	titolo_tipo.classif_tipo_id
                              and 	tipologia_tipo.classif_tipo_code			=	'TIPOLOGIA'
                              and 	tipologia.classif_tipo_id					=	tipologia_tipo.classif_tipo_id
                              and 	titolo_r_cft.classif_id						=	tipologia.classif_id
                              and 	tipologia.classif_id						=	tipologia_r_cft.classif_id_padre
                              and 	categoria_tipo.classif_tipo_code			=	'CATEGORIA'
                              and 	categoria.classif_tipo_id					=	categoria_tipo.classif_tipo_id
                              and 	tipologia_r_cft.classif_id					=	categoria.classif_id
                              and	tipologia_r_cft.classif_id					=	r_capitolo_categoria.classif_id
                              and	r_capitolo_categoria.elem_id				=	r_cronop_elem.elem_id
                              and	r_cronop_elem.cronop_elem_id				=	datiCronoprogrammaRec.cronop_id_elem
                              and 	titolo.ente_proprietario_id					=	p_ente_prop_id
                              and 	tipologia.ente_proprietario_id				=	titolo.ente_proprietario_id
                              and 	categoria.ente_proprietario_id				=	titolo.ente_proprietario_id
                              and 	titolo_tree.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	titolo_fam.ente_proprietario_id				=	titolo.ente_proprietario_id
                              and 	titolo_r_cft.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	tipologia_r_cft.ente_proprietario_id		=	titolo.ente_proprietario_id
                              and 	titolo_tipo.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	tipologia_tipo.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	categoria_tipo.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	r_capitolo_categoria.ente_proprietario_id	=	titolo.ente_proprietario_id
                              and 	r_cronop_elem.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	cronop_elem.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	titolo.data_cancellazione					is null
                              and 	tipologia.data_cancellazione				is null
                              and 	categoria.data_cancellazione				is null
                              and 	titolo_tree.data_cancellazione				is null
                              and 	titolo_fam.data_cancellazione				is null
                              and 	titolo_r_cft.data_cancellazione				is null
                              and 	tipologia_r_cft.data_cancellazione			is null
                              and 	titolo_tipo.data_cancellazione				is null
                              and 	tipologia_tipo.data_cancellazione			is null
                              and 	categoria_tipo.data_cancellazione			is null
                              and 	r_capitolo_categoria.data_cancellazione		is null
                              and 	r_cronop_elem.data_cancellazione			is null
                              and 	cronop_elem.data_cancellazione				is null
                            loop
                                tipo_liv1:=datistrutturaRec.tipo_liv1;
                                descr_liv1:=datistrutturaRec.descr_liv1;
                                codice_liv1:=datistrutturaRec.codice_liv1;
                                tipo_liv2:=datistrutturaRec.tipo_liv2;
                                descr_liv2:=datistrutturaRec.descr_liv2;
                                codice_liv2:=datistrutturaRec.codice_liv2;
                                tipo_liv3:=datistrutturaRec.tipo_liv3;
                                descr_liv3:=datistrutturaRec.descr_liv3;
                                codice_liv3:=datistrutturaRec.codice_liv3;
                                
                            end loop;
                                exception
                                  when no_data_found THEN
                                  raise notice 'nessuna struttura collegata' ;
                                  return;
                                  when others  THEN
                                  RTN_MESSAGGIO:='ricerca struttura capitolo entrata esistente';
                                  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                                  return;
                    end;      
    			end if; 
		else
    		if	coalesce(datiCronoprogrammaRec.articolo ,DEF_spazio)=DEF_spazio and coalesce(datiCronoprogrammaRec.ueb,DEF_spazio)=DEF_spazio	THEN            	
                BEGIN
    			for datistrutturaRec in
                 select  distinct missione_tipo.classif_tipo_desc 		tipo_liv1,
                    missione.classif_code 					codice_liv1,
                    missione.classif_desc 					descr_liv1,
                    programma_tipo.classif_tipo_desc 		tipo_liv2,
                    programma.classif_code 					codice_liv2,
                    programma.classif_desc 					descr_liv2,
                    titusc_tipo.classif_tipo_desc 			tipo_liv3,
                    titusc.classif_code 					codice_liv3,
                    titusc.classif_desc 					descr_liv3
                from siac_t_class_fam_tree 			missione_tree,
                     siac_d_class_fam 				missione_fam,
                     siac_r_class_fam_tree 			missione_r_cft,
                     siac_t_class 					missione,
                     siac_d_class_tipo 				missione_tipo ,
                     siac_d_class_tipo 				programma_tipo,
                     siac_t_class 					programma,
                     siac_t_class_fam_tree 			titusc_tree,
                     siac_d_class_fam 				titusc_fam,
                     siac_r_class_fam_tree 			titusc_r_cft,
                     siac_t_class 					titusc,
                     siac_d_class_tipo 				titusc_tipo,
                     siac_r_cronop_elem_class		r_cronp_class_programma,
                     siac_r_cronop_elem_class		r_cronp_class_titolo
                where missione_tree.classif_fam_id				=	missione_fam.classif_fam_id 
                      and	missione_r_cft.classif_fam_tree_id			=	missione_tree.classif_fam_tree_id 
                      and	missione.classif_id							=	missione_r_cft.classif_id_padre 
                      and	missione.classif_tipo_id					=	missione_tipo.classif_tipo_id
                      and	programma.classif_tipo_id					=	programma_tipo.classif_tipo_id  
                      and	missione_r_cft.classif_id					=	programma.classif_id  
                      and	programma.classif_id						=	r_cronp_class_programma.classif_id
                      and	titusc_tree.classif_fam_id					=	titusc_fam.classif_fam_id 
                      and	titusc_r_cft.classif_fam_tree_id			=	titusc_tree.classif_fam_tree_id 
                      and	titusc.classif_id							=	titusc_r_cft.classif_id_padre 
                      and	r_cronp_class_titolo.ente_proprietario_id	=	missione_tree.ente_proprietario_id            
                      and missione_fam.classif_fam_desc				=	'Spesa - MissioniProgrammi'
                      and	missione_tipo.classif_tipo_code				=	'MISSIONE' 
                      and	titusc.classif_tipo_id						=	titusc_tipo.classif_tipo_id
                      and	titusc.classif_id							=	r_cronp_class_titolo.classif_id            
                      and missione_tree.ente_proprietario_id			=	p_ente_prop_id
                      and	programma_tipo.classif_tipo_code			=	'PROGRAMMA'  
                      and	r_cronp_class_programma.cronop_elem_id		=	cronop_id_elem	
                      and	titusc_fam.classif_fam_desc					=	'Spesa - TitoliMacroaggregati'      
                      and	titusc_tipo.classif_tipo_code				=	'TITOLO_SPESA' 
                      and	r_cronp_class_titolo.cronop_elem_id			=	cronop_id_elem		            
                      and missione_tree.data_cancellazione			is null
                      and missione_fam.data_cancellazione				is null
                      AND missione_r_cft.data_cancellazione			is null
                      and missione.data_cancellazione					is null
                      AND missione_tipo.data_cancellazione			is null
                      AND programma_tipo.data_cancellazione			is null
                      AND programma.data_cancellazione				is null
                      and titusc_tree.data_cancellazione				is null
                      AND titusc_fam.data_cancellazione				is null
                      and titusc_r_cft.data_cancellazione				is null
                      and titusc.data_cancellazione					is null
                      AND titusc_tipo.data_cancellazione				is null
                      and	r_cronp_class_titolo.data_cancellazione		is null
                      	loop
                        	tipo_liv1:=datistrutturaRec.tipo_liv1;
                            descr_liv1:=datistrutturaRec.descr_liv1;
                            codice_liv1:=datistrutturaRec.codice_liv1;
                            tipo_liv2:=datistrutturaRec.tipo_liv2;
                            descr_liv2:=datistrutturaRec.descr_liv2;
                            codice_liv2:=datistrutturaRec.codice_liv2;
                            tipo_liv3:=datistrutturaRec.tipo_liv3;
                            descr_liv3:=datistrutturaRec.descr_liv3;
                            codice_liv3:=datistrutturaRec.codice_liv3;    
                        end loop;
                        exception
                          when no_data_found THEN
                          raise notice 'nessuna struttura collegata' ;
                          return;
                          when others  THEN
                          RTN_MESSAGGIO:='ricerca struttura nuovo capitolo spesa o senza capitolo di spesa';
                          RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                          return;
                    end;
            else
            BEGIN
    			for datistrutturaRec in
            
            	select  distinct 	missione_tipo.classif_tipo_desc 		tipo_liv1,
                                    missione.classif_code 					codice_liv1,
                                    missione.classif_desc 					descr_liv1,
                                    programma_tipo.classif_tipo_desc 		tipo_liv2,
                                    programma.classif_code 					codice_liv2,
                                    programma.classif_desc 					descr_liv2,
                                    titusc_tipo.classif_tipo_desc 			tipo_liv3,
                                    titusc.classif_code 					codice_liv3,
                                    titusc.classif_desc 					descr_liv3,
                                    macroaggr_tipo.classif_tipo_desc 		tipo_liv4,
                                    macroaggr.classif_code 					codice_liv4,
                                    macroaggr.classif_desc 					descr_liv4
                from siac_t_class_fam_tree 			missione_tree,
                     siac_d_class_fam 				missione_fam,
                     siac_r_class_fam_tree 			missione_r_cft,
                     siac_t_class 					missione,
                     siac_d_class_tipo 				missione_tipo ,
                     siac_d_class_tipo 				programma_tipo,
                     siac_t_class 					programma,
                     siac_t_class_fam_tree 			titusc_tree,
                     siac_d_class_fam 				titusc_fam,
                     siac_r_class_fam_tree 			titusc_r_cft,
                     siac_t_class 					titusc,
                     siac_d_class_tipo 				titusc_tipo ,
                     siac_d_class_tipo 				macroaggr_tipo,
                     siac_t_class 					macroaggr,
                     siac_r_bil_elem_class 			r_capitolo_programma,
                     siac_r_cronop_elem_bil_elem	r_cronop_elem,
                     siac_r_bil_elem_class 			r_capitolo_macroaggr
                where missione_fam.classif_fam_desc						=	'Spesa - MissioniProgrammi'      
                      and	missione_tree.classif_fam_id				=	missione_fam.classif_fam_id 
                        and	missione_r_cft.classif_fam_tree_id			=	missione_tree.classif_fam_tree_id 
                      and	missione.classif_id							=	missione_r_cft.classif_id_padre 
                      and	missione_tipo.classif_tipo_code				=	'MISSIONE' 
                      and	missione.classif_tipo_id					=	missione_tipo.classif_tipo_id 
                      and	programma_tipo.classif_tipo_code			=	'PROGRAMMA'  
                      and	programma.classif_tipo_id					=	programma_tipo.classif_tipo_id  
                      and	missione_r_cft.classif_id					=	programma.classif_id  
                      and	missione_r_cft.classif_id					=	r_capitolo_programma.classif_id		
                      and	r_capitolo_programma.elem_id				=	r_cronop_elem.elem_id		
                      and	r_cronop_elem.cronop_elem_id				=	datiCronoprogrammaRec.cronop_id_elem	
                      and	titusc_fam.classif_fam_desc					=	'Spesa - TitoliMacroaggregati'      
                      and	titusc_tree.classif_fam_id					=	titusc_fam.classif_fam_id 
                      and	titusc_r_cft.classif_fam_tree_id			=	titusc_tree.classif_fam_tree_id 
                      and	titusc.classif_id							=	titusc_r_cft.classif_id_padre 
                      and	titusc_tipo.classif_tipo_code				=	'TITOLO_SPESA' 
                      and	titusc.classif_tipo_id						=	titusc_tipo.classif_tipo_id 
                      and	macroaggr_tipo.classif_tipo_code			=	'MACROAGGREGATO' 
                      and	macroaggr.classif_tipo_id					=	macroaggr_tipo.classif_tipo_id 
                      and	titusc_r_cft.classif_id						=	macroaggr.classif_id 
                      and	titusc_r_cft.classif_id						=	r_capitolo_macroaggr.classif_id 
                      and	r_capitolo_macroaggr.elem_id				=	r_cronop_elem.elem_id		 
                      and	r_cronop_elem.cronop_elem_id				=	datiCronoprogrammaRec.cronop_id_elem
                      and 	missione_tree.ente_proprietario_id			=	p_ente_prop_id
                      and 	missione_fam.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	missione_r_cft.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	missione.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      AND 	missione_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	programma_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	programma.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      and 	titusc_tree.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	titusc_fam.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      and 	titusc_r_cft.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	titusc.ente_proprietario_id					=	missione_tree.ente_proprietario_id
                      AND 	titusc_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	macroaggr_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	macroaggr.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      and 	r_capitolo_programma.ente_proprietario_id	=	missione_tree.ente_proprietario_id
                      AND	r_cronop_elem.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	r_capitolo_macroaggr.ente_proprietario_id	=	missione_tree.ente_proprietario_id     
                      and 	missione_tree.data_cancellazione			is null
                      and 	missione_fam.data_cancellazione				is null
                      AND 	missione_r_cft.data_cancellazione			is null
                      and 	missione.data_cancellazione					is null
                      AND 	missione_tipo.data_cancellazione			is null
                      AND 	programma_tipo.data_cancellazione			is null
                      AND 	programma.data_cancellazione				is null
                      and 	titusc_tree.data_cancellazione				is null
                      AND 	titusc_fam.data_cancellazione				is null
                      and 	titusc_r_cft.data_cancellazione				is null
                      and 	titusc.data_cancellazione					is null
                      AND 	titusc_tipo.data_cancellazione				is null
                      AND 	macroaggr_tipo.data_cancellazione			is null
                      AND 	macroaggr.data_cancellazione				is null
                      and 	r_capitolo_programma.data_cancellazione		is null
                      AND	r_cronop_elem.data_cancellazione			is null
                      and 	r_capitolo_macroaggr.data_cancellazione		is null
                      
            		loop
                                tipo_liv1:=datistrutturaRec.tipo_liv1;
                                descr_liv1:=datistrutturaRec.descr_liv1;
                                codice_liv1:=datistrutturaRec.codice_liv1;
                                tipo_liv2:=datistrutturaRec.tipo_liv2;
                                descr_liv2:=datistrutturaRec.descr_liv2;
                                codice_liv2:=datistrutturaRec.codice_liv2;
                                tipo_liv3:=datistrutturaRec.tipo_liv3;
                                descr_liv3:=datistrutturaRec.descr_liv3;
                                codice_liv3:=datistrutturaRec.codice_liv3;
                                tipo_liv3:=datistrutturaRec.tipo_liv4;
                                descr_liv3:=datistrutturaRec.descr_liv4;
                                codice_liv3:=datistrutturaRec.codice_liv4;
            		 end loop;
                                exception
                                  when no_data_found THEN
                                  raise notice 'nessuna struttura collegata' ;
                                  return;
                                  when others  THEN
                                  RTN_MESSAGGIO:='ricerca struttura capitolo spesa esistente';
                                  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                                  return;
                end;      
            end if; 
        end if;
            return next;
            tipo_liv1='';
            descr_liv1='';
            codice_liv1='';
            tipo_liv2='';
            descr_liv2='';
            codice_liv2='';
            tipo_liv3='';
            descr_liv3='';
            codice_liv3='';
            tipo_liv4='';
            descr_liv4='';
            codice_liv4='';
            capitolo='';
            articolo='';
            ueb='';
            anno_competenza_stanziamento='';
            anno_entrata_rif_spesa='';
            stanziato=0;
            cronoprogramma_id=0;
            descrizione1_attivita='';
            descrizione2_attivita='';
            cronoprogramma_codice='';
            cronoprogramma_descrizione='';
            note_cronoprogramma='';
            cronop_id_elem=0;
        end loop;
        exception
          when no_data_found THEN
          raise notice 'nessun cronoprogramma trovato' ;
          return;
          when others  THEN
          RTN_MESSAGGIO:='ricerca cronoprogrammi';
          RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
          return;
    end;
    id_progetto=0;
end loop;

delete from siac_rep_prog_cronop where utente=user_table;

exception
	when no_data_found THEN
		raise notice 'nessun programma/progetto trovato' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='ricerca programmi/progetti';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
raise notice 'fine OK';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-7204 - Maurizio - FINE


--SIAC-6868 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR240_mov_cas_econ"(p_ente_prop_id integer, p_anno varchar, p_data_da date, p_data_a date, p_cassaecon_id integer, p_num_impegno numeric, p_ant_spese_missione varchar);

CREATE OR REPLACE FUNCTION siac."BILR240_mov_cas_econ" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_da date,
  p_data_a date,
  p_cassaecon_id integer,
  p_num_impegno numeric,
  p_ant_spese_missione varchar
)
RETURNS TABLE (
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  anno_impegno integer,
  num_imp varchar,
  num_sub_impegno varchar,
  descr_impegno varchar,
  num_movimento varchar,
  tipo_richiesta varchar,
  num_sospeso varchar,
  data_movimento date,
  num_fattura varchar,
  num_quota integer,
  data_emis_fattura date,
  cod_benefic_fattura varchar,
  descr_benefic_fattura varchar,
  descr_richiesta varchar,
  imp_richiesta numeric,
  rendicontazione varchar,
  code_tipo_richiesta varchar,
  rendicontato varchar,
  importo_attuale_impegno numeric,
  num_carte_non_reg integer,
  imp_carte_non_reg numeric,
  num_predoc_non_liq integer,
  imp_predoc_non_liq numeric,
  num_doc_non_liq integer,
  imp_doc_non_liq numeric,
  imp_pagam_economali numeric,
  num_liquidazioni integer,
  imp_liquidazioni numeric,
  imp_totale_movimenti numeric,
  imp_disp_liquid numeric,
  imp_disp_pagare numeric,
  imp_disp_vincolare numeric
) AS
$body$
DECLARE

dati_movimenti record;
dati_giustif record;
bilancio_id integer;
contaProgRilevanteFPV integer;
contaVincolTrasfVincolati integer;

BEGIN
  num_capitolo='';
  num_articolo='';
  ueb='';
  anno_impegno=0;
  num_imp='';
  descr_impegno='';
  num_movimento='';
  tipo_richiesta='';
  num_sospeso='';
  data_movimento=NULL;
  num_fattura='';
  num_quota=0;
  data_emis_fattura=NULL;
  cod_benefic_fattura='';
  descr_benefic_fattura='';
  descr_richiesta='';
  imp_richiesta=0;   
  rendicontazione ='';
  code_tipo_richiesta='';
  num_sub_impegno='';
  rendicontato:='';
  importo_attuale_impegno:=0; 
  num_carte_non_reg:=0;
  imp_carte_non_reg:=0;
  num_predoc_non_liq:=0;
  imp_predoc_non_liq:=0;
  num_doc_non_liq:=0;
  imp_doc_non_liq:=0;
  imp_pagam_economali:=0;
  num_liquidazioni:=0;
  imp_liquidazioni :=0; 
  imp_disp_liquid :=0;
  imp_disp_pagare :=0;
  imp_disp_vincolare :=0;
  imp_totale_movimenti:=0;  
  
   select t_bil.bil_id
   	into bilancio_id 
   from siac_t_bil t_bil,
   	siac_t_periodo t_periodo
   where t_bil.periodo_id =t_periodo.periodo_id
   	and t_bil.ente_proprietario_id=p_ente_prop_id
    and t_periodo.anno =p_anno
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
    
   
for dati_movimenti in
    with elenco_movimenti as (
            select movimento.movt_numero num_movimento,
            	richiesta_econ_tipo.ricecon_tipo_code,
                richiesta_econ_tipo.ricecon_tipo_desc tipo_richiesta,
                COALESCE(richiesta_econ_sospesa.ricecons_numero::varchar,'') num_sospeso,
                movimento.movt_data data_movimento,
                documento.doc_numero num_fattura,
                sub_documento.subdoc_numero num_quota,
                documento.doc_data_emissione data_emis_fattura,
                soggetto.soggetto_code cod_benefic_fattura,
                soggetto.soggetto_desc descr_benefic_fattura,
                richiesta_econ.ricecon_desc descr_richiesta,
                /* se esiste un giustificativo, devo prendere il suo importo e non quello
                    del movimento */
                case when movimento.gst_id is not NULL 
                    then case when t_giustiv.rend_importo_restituito > 0
                        then -t_giustiv.rend_importo_restituito 
                        else case when t_giustiv.rend_importo_integrato > 0 
                            then t_giustiv.rend_importo_integrato 
                            else 0  end
                        end
                    else richiesta_econ.ricecon_importo end	imp_richiesta,
                case when movimento.gst_id is not NULL 
                    then 'S'::varchar else ''::varchar end 		rendicontazione,
                richiesta_econ_tipo.ricecon_tipo_code code_tipo_richiesta,
                case when mov_rend.movt_id IS NULL
                    then 'N' else 'S' end  	rendicontato,
                r_richiesta_movgest.movgest_ts_id
            from 	siac_t_movimento			movimento
                LEFT JOIN siac_t_giustificativo t_giustiv
                    ON (t_giustiv.gst_id = movimento.gst_id
                        and t_giustiv.data_cancellazione IS NULL)
                   --verifico se il movimento e' rendicontato
                LEFT JOIN (select movimento.movt_id
                           from siac_t_movimento		movimento,
                                siac_t_richiesta_econ	richiesta_econ,
                                siac_r_movimento_stampa	 r_movimento_sta,
                                siac_t_cassa_econ_stampa	cassa_stampa,
                                siac_t_cassa_econ_stampa_valore	cassa_stampa_val,
                                siac_d_cassa_econ_stampa_tipo	tipo_stampa,
                                siac_r_cassa_econ_stampa_stato  r_stato_stampa,
                                siac_d_cassa_econ_stampa_stato	stato_stampa
                           where movimento.ricecon_id=richiesta_econ.ricecon_id
                            and movimento.movt_id=r_movimento_sta.movt_id
                            and  r_movimento_sta.cest_id=cassa_stampa.cest_id
                            and  cassa_stampa.cest_id=cassa_stampa_val.cest_id
                            and  cassa_stampa.cest_tipo_id=tipo_stampa.cest_tipo_id
                            and  cassa_stampa.cest_id=r_stato_stampa.cest_id
                            and  r_stato_stampa.cest_stato_id=stato_stampa.cest_stato_id                                                                   
                            and movimento.ente_proprietario_id=p_ente_prop_id
                            and richiesta_econ.cassaecon_id=p_cassaecon_id
                            and richiesta_econ.bil_id=bilancio_id
                            and tipo_stampa.cest_tipo_code='REN'
                            and stato_stampa.cest_stato_code='D'
                            and  movimento.data_cancellazione is  NULL 
                            and  r_movimento_sta.data_cancellazione is  NULL
                            and  cassa_stampa.data_cancellazione is  NULL
                            and  cassa_stampa_val.data_cancellazione is  NULL
                            and  tipo_stampa.data_cancellazione is  NULL
                            and  r_stato_stampa.data_cancellazione is  NULL
                            and  stato_stampa.data_cancellazione is  NULL) mov_rend 
                     ON mov_rend.movt_id = movimento.movt_id,
                siac_t_richiesta_econ					richiesta_econ
                  LEFT join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
                      on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
                          and richiesta_econ_sospesa.data_cancellazione is null)
                  LEFT join siac_r_richiesta_econ_subdoc	r_richiesta_econ_subdoc
                      on (richiesta_econ.ricecon_id=r_richiesta_econ_subdoc.ricecon_id
                          and r_richiesta_econ_subdoc.data_cancellazione is null)            
                  LEFT join siac_t_subdoc	sub_documento
                      on (r_richiesta_econ_subdoc.subdoc_id=sub_documento.subdoc_id
                          and sub_documento.data_cancellazione is null)
                  LEFT join siac_t_doc				documento
                      on (sub_documento.doc_id=documento.doc_id
                          and documento.data_cancellazione is null  )            
                  LEFT join siac_r_subdoc_sog	sub_doc_sog
                      on (sub_documento.subdoc_id=sub_doc_sog.subdoc_id
                          and sub_doc_sog.data_cancellazione is null)
                  LEFT join siac_t_soggetto	soggetto
                      on (sub_doc_sog.soggetto_id=soggetto.soggetto_id
                          and soggetto.data_cancellazione is null ),
                siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
                siac_t_cassa_econ						cassa_econ,
                siac_r_richiesta_econ_stato				r_richiesta_stato,
                siac_d_richiesta_econ_stato				richiesta_stato,
                siac_r_richiesta_econ_movgest			r_richiesta_movgest
           where movimento.ricecon_id=richiesta_econ.ricecon_id
            and richiesta_econ.ricecon_tipo_id=richiesta_econ_tipo.ricecon_tipo_id
            and cassa_econ.cassaecon_id= richiesta_econ.cassaecon_id
            and richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id
            and r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id     
            and r_richiesta_movgest.ricecon_id= richiesta_econ.ricecon_id
            and movimento.ente_proprietario_id = p_ente_prop_id
            and richiesta_econ.bil_id=bilancio_id
            and richiesta_econ.cassaecon_id=p_cassaecon_id      			
            and richiesta_stato.ricecon_stato_code <> 'AN'  
            and movimento.data_cancellazione IS NULL
            and richiesta_econ.data_cancellazione IS NULL
            and richiesta_econ_tipo.data_cancellazione IS NULL
            and cassa_econ.data_cancellazione IS NULL
            and r_richiesta_stato.data_cancellazione IS NULL
            and richiesta_stato.data_cancellazione IS NULL
            and r_richiesta_movgest.data_cancellazione IS NULL),
    elenco_impegni_capitoli as (select movgest.movgest_anno anno_impegno, 
                    movgest.movgest_numero num_imp,
                    movgest.movgest_desc descr_impegno,
                    movgest_ts.movgest_ts_code num_sub_impegno,
                    bil_elem.elem_code num_capitolo,
                    bil_elem.elem_code2 num_articolo,
                    bil_elem.elem_code3 UEB,
                    t_movgest_ts_det.movgest_ts_det_importo importo_attuale_impegno,
                    movgest_ts.movgest_ts_id,
                    COALESCE(d_assenza_motiv.siope_assenza_motivazione_code,'') assenza_cig_code,
                    COALESCE(d_assenza_motiv.siope_assenza_motivazione_desc ,'') assenza_cig_desc,
                    d_movgest_stato.movgest_stato_code,
                    COALESCE(r_movgest_ts.movgest_ts_importo,0) importo_vincoli,
                    movgest.parere_finanziario,
                    bil_elem.elem_id
                from 	siac_t_movgest				movgest,
                        siac_d_movgest_tipo 		d_movgest_tipo,
                        siac_t_movgest_ts			movgest_ts
                        	LEFT JOIN siac_d_siope_assenza_motivazione d_assenza_motiv
                            	ON (d_assenza_motiv.siope_assenza_motivazione_id=movgest_ts.siope_assenza_motivazione_id
                                	and d_assenza_motiv.data_cancellazione IS NULL)
                            LEFT JOIN siac_r_movgest_ts r_movgest_ts
                            	ON (r_movgest_ts.movgest_ts_b_id=movgest_ts.movgest_ts_id
                                	and r_movgest_ts.data_cancellazione IS NULL),                    	
                        siac_t_movgest_ts_det		t_movgest_ts_det,                    
                        siac_d_movgest_ts_det_tipo 	d_movgest_ts_det_tipo,
                        siac_r_movgest_ts_stato		r_movgest_ts_stato,
                        siac_d_movgest_stato		d_movgest_stato,
                        siac_r_movgest_bil_elem		r_mov_gest_bil_elem,
                        siac_t_bil_elem				bil_elem
                where movgest.movgest_tipo_id= d_movgest_tipo.movgest_tipo_id
                    and movgest.movgest_id= movgest_ts.movgest_id
                    and movgest_ts.movgest_ts_id= t_movgest_ts_det.movgest_ts_id
                    and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                    and r_movgest_ts_stato.movgest_ts_id = movgest_ts.movgest_ts_id
                    and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id
                    and r_mov_gest_bil_elem.movgest_id= movgest.movgest_id   
                    and bil_elem.elem_id = r_mov_gest_bil_elem.elem_id
                    and movgest.ente_proprietario_id = p_ente_prop_id
                    and d_movgest_tipo.movgest_tipo_code ='I'
                    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code ='A'
                    and movgest.data_cancellazione IS NULL  
                    and d_movgest_tipo.data_cancellazione IS NULL
                    and movgest_ts.data_cancellazione IS NULL
                    and t_movgest_ts_det.data_cancellazione IS NULL
                    and d_movgest_ts_det_tipo.data_cancellazione IS NULL
                    and d_movgest_stato.data_cancellazione IS NULL
                    and r_movgest_ts_stato.data_cancellazione IS NULL
                    and r_mov_gest_bil_elem.data_cancellazione IS NULL
                    and bil_elem.data_cancellazione IS NULL)
    select elenco_impegni_capitoli.num_capitolo,
      elenco_impegni_capitoli.num_articolo,
      elenco_impegni_capitoli.UEB,
      elenco_impegni_capitoli.anno_impegno,
      elenco_impegni_capitoli.num_imp,
      elenco_impegni_capitoli.descr_impegno,
      elenco_movimenti.num_movimento,
      elenco_movimenti.tipo_richiesta,
      elenco_movimenti.num_sospeso,
      elenco_movimenti.data_movimento,
      elenco_movimenti.num_fattura,
      elenco_movimenti.num_quota,
      elenco_movimenti.data_emis_fattura,
      elenco_movimenti.cod_benefic_fattura,
      elenco_movimenti.descr_benefic_fattura,
      elenco_movimenti.descr_richiesta,
      elenco_movimenti.imp_richiesta,
      elenco_movimenti.rendicontazione,
      elenco_movimenti.code_tipo_richiesta,
      elenco_impegni_capitoli.num_sub_impegno,
      elenco_movimenti.rendicontato,
      elenco_impegni_capitoli.importo_attuale_impegno,
      elenco_impegni_capitoli.movgest_ts_id,
      elenco_impegni_capitoli.assenza_cig_code,
      elenco_impegni_capitoli.assenza_cig_desc,
      elenco_impegni_capitoli.movgest_stato_code,
      elenco_impegni_capitoli.importo_vincoli,
      elenco_impegni_capitoli.parere_finanziario,
      elenco_impegni_capitoli.elem_id
    from elenco_movimenti
        LEFT JOIN elenco_impegni_capitoli
            ON elenco_impegni_capitoli.movgest_ts_id = elenco_movimenti.movgest_ts_id 
    where ((p_data_da is NULL OR p_data_a is NULL) OR
        	 (p_data_da is NOT NULL AND p_data_a is NOT NULL
              AND elenco_movimenti.data_movimento between p_data_da and p_data_a))  
        AND ((p_num_impegno is NOT NULL and  elenco_impegni_capitoli.num_imp=p_num_impegno)
           	OR (p_num_impegno is NULL))      
         and ((p_ant_spese_missione = 'N' 
         		AND elenco_movimenti.ricecon_tipo_code<>'ANTICIPO_SPESE_MISSIONE')              
              OR (p_ant_spese_missione = 'S'))
    ORDER BY num_capitolo, num_articolo, ueb, anno_impegno, num_imp, num_sub_impegno
loop 
	num_capitolo:=dati_movimenti.num_capitolo;
    num_articolo:=dati_movimenti.num_articolo;
    ueb:=dati_movimenti.ueb;
    anno_impegno:=dati_movimenti.anno_impegno;
    num_imp:=dati_movimenti.num_imp;
    num_sub_impegno:=dati_movimenti.num_sub_impegno;
    descr_impegno:=dati_movimenti.descr_impegno;
    num_movimento:=dati_movimenti.num_movimento;
    tipo_richiesta:=dati_movimenti.tipo_richiesta;
    num_sospeso:=dati_movimenti.num_sospeso;
    data_movimento:=dati_movimenti.data_movimento;
    num_fattura:=dati_movimenti.num_fattura;
    num_quota:=dati_movimenti.num_quota;
    data_emis_fattura:=dati_movimenti.data_emis_fattura;
    cod_benefic_fattura:=dati_movimenti.cod_benefic_fattura;
    descr_benefic_fattura:=dati_movimenti.descr_benefic_fattura;
    descr_richiesta:=dati_movimenti.descr_richiesta;
    imp_richiesta:=dati_movimenti.imp_richiesta;   
    rendicontazione :=dati_movimenti.rendicontazione;
    code_tipo_richiesta:=dati_movimenti.code_tipo_richiesta;    
    rendicontato:=dati_movimenti.rendicontato;
    importo_attuale_impegno:=dati_movimenti.importo_attuale_impegno;    
    
    	--Estraggo i dati di riepilogo
    select dett_imp.n_carte_non_reg, dett_imp.tot_carte_non_reg, dett_imp.n_imp_predoc,
    	dett_imp.tot_imp_predoc, dett_imp.n_doc_non_liq, dett_imp.tot_doc_non_liq,
        (dett_imp.tot_imp_cec_fattura+dett_imp.tot_imp_cec_no_giust+dett_imp.tot_imp_cec_paf_fatt),
        dett_imp.n_doc_liq, dett_imp.tot_imp_liq    	
    into num_carte_non_reg, imp_carte_non_reg,  num_predoc_non_liq,
  		imp_predoc_non_liq, num_doc_non_liq,   imp_doc_non_liq,
  		imp_pagam_economali, num_liquidazioni, imp_liquidazioni
    from "fnc_siac_consultadettaglioimpegno"(dati_movimenti.movgest_ts_id) dett_imp;
    
    imp_totale_movimenti:= imp_carte_non_reg+imp_predoc_non_liq+imp_doc_non_liq+
    	imp_pagam_economali+imp_liquidazioni;

    
    --l'importo della disponibilita' a vincolare e' dato dall'importo
    -- attuale dell'impegno meno l'importo dei vincoli.
    imp_disp_vincolare:=dati_movimenti.importo_attuale_impegno-
    	dati_movimenti.importo_vincoli;

    --verifico se esitono progetti collegati all'impegno con FlagRilevanteFPV=true.
    contaProgRilevanteFPV:=0;
    select count(*)
	into contaProgRilevanteFPV    
    from siac_r_movgest_ts_programma r_mov_programma,
        siac_t_programma t_prog,
        siac_r_programma_attr r_prog_attr,
        siac_t_attr t_attr, 
        siac_d_attr_tipo d_attr_tipo   
    where t_prog.programma_id = r_mov_programma.programma_id
    and	t_prog.programma_id	= r_prog_attr.programma_id
    and	t_attr.attr_id			= r_prog_attr.attr_id
    and	t_attr.attr_tipo_id		= d_attr_tipo.attr_tipo_id
    and	r_mov_programma.ente_proprietario_id	= p_ente_prop_id
    and d_attr_tipo.attr_tipo_code	='B'
    and	t_attr.attr_code		= 	'FlagRilevanteFPV'
    and r_prog_attr."boolean" ='S'
    and r_mov_programma.movgest_ts_id = dati_movimenti.movgest_ts_id
    and t_prog.data_cancellazione is null
    and	r_mov_programma.data_cancellazione	is null
    and	t_attr.data_cancellazione	is null
    and r_prog_attr.data_cancellazione is null
    and d_attr_tipo.data_cancellazione IS NULL;
    
    -- verifico se esistono dei voncoli collegati al capitolo con 
    -- FlagTrasferimentiVincolati = true.
    contaVincolTrasfVincolati := 0;
    select count(*)
    into contaVincolTrasfVincolati
    from siac_r_vincolo_bil_elem r_vinc_bil_elem,
      siac_t_vincolo t_vincolo,
      siac_t_attr t_attr,
      siac_r_vincolo_attr r_vincolo_attr
    where r_vinc_bil_elem.vincolo_id=t_vincolo.vincolo_id
		and r_vincolo_attr.vincolo_id=t_vincolo.vincolo_id
     	and r_vincolo_attr.attr_id = t_attr.attr_id
        and r_vinc_bil_elem.elem_id = dati_movimenti.elem_id
        and t_attr.attr_code ='FlagTrasferimentiVincolati'
        and r_vincolo_attr."boolean" ='S'
        and r_vinc_bil_elem.data_cancellazione IS NULL 
        and t_vincolo.data_cancellazione IS NULL
        and t_attr.data_cancellazione IS NULL
        and r_vincolo_attr.data_cancellazione IS NULL;
        



		-- Per quanto riguarda l'importo "Disponibilita' a Vincolare" occorre
        -- fare le seguenti verifiche:
    	-- 1. se Motivo Assenza CIG dell'impegno = 'ID' - 'CIG in corso di definizione'.
        -- 2. se lo stato dell'impegno non e' DEFINITIVO.
        -- 3. se l'anno dell'impegno e' maggiore di quello del bilancio.
        -- 4. Se l'impegno non e' validato (flag parere finanziario non a TRUE).
        -- 5. Se l'impegno e' parzialmente vincolato (disponibilitaVincolare > 0 e 
		--    disponibilitaVincolare < importoAttuale.
        -- 6. Se l'impegno e' residuo e legato a un progetto rilevante fondo 
		--    (disponibilitaVincolare > 0 e Progetto.RilevanteFPV = TRUE.
        -- 7. Se l'impegno e' residuo e legato ad un Capitolo con un vincolo di 
        --    trasferimento (disponibilitaVincolare > 0 ed esiste almeno 1
		--    Capitolo.ListaVincoli.Vincolo.flagTrasferimpentiVincolati = TRUE ). 
        -- Se una delle precedenti verifiche ha dato esito positivo l'importo
        -- "Disponibilita' a Vincolare" deve essere impostato a 0.
        
        
    if dati_movimenti.assenza_cig_code = 'ID' OR
    	dati_movimenti.movgest_stato_code <> 'D' OR
        dati_movimenti.anno_impegno > p_anno::integer OR
        dati_movimenti.parere_finanziario = false OR
        (imp_disp_vincolare > 0 and 
         imp_disp_vincolare < dati_movimenti.importo_attuale_impegno) OR
        (imp_disp_vincolare > 0 and contaProgRilevanteFPV > 0) OR
        (imp_disp_vincolare > 0 and contaVincolTrasfVincolati > 0)
          then
    		raise notice 'L''impegno % ha: - assenza_cig_code = %', 
            	dati_movimenti.anno_impegno||'/'||dati_movimenti.num_imp||'/'||dati_movimenti.num_sub_impegno,
                dati_movimenti.assenza_cig_code;
            raise notice '             - stato = %', dati_movimenti.movgest_stato_code;
            raise notice '             - anno = %', dati_movimenti.anno_impegno;
            raise notice '             - parere finanziario = %', dati_movimenti.parere_finanziario;
            raise notice '             - importo disp a vincolare = %', imp_disp_vincolare;
            raise notice '             - parere finanziario = %', dati_movimenti.parere_finanziario;
            raise notice '             - progetti collegati con flag rilevante FPV a true = %', contaProgRilevanteFPV;
            raise notice '             - vincoli collegati con flag trasferimenti vincolati a true = %', contaVincolTrasfVincolati;
            raise notice '  L''importo disponibilita'' a liquidare e'' impostato a 0';
             
    	imp_disp_liquid:=0;
    else
		select disp_liq.val2
    	into imp_disp_liquid
    	from "fnc_siac_disponibilitaliquidaremovgest_rec"(dati_movimenti.movgest_ts_id::varchar) disp_liq;    
    end if;
    
    
    select disp_pag.val2
    into imp_disp_pagare
    from "fnc_siac_disponibileapagaremovgest_rec"(dati_movimenti.movgest_ts_id::varchar) disp_pag;    
        
return next; 

end loop;

  num_capitolo='';
  num_articolo='';
  ueb='';
  anno_impegno=0;
  num_imp='';
  descr_impegno='';
  num_movimento='';
  tipo_richiesta='';
  num_sospeso='';
  data_movimento=NULL;
  num_fattura='';
  num_quota=0;
  data_emis_fattura=NULL;
  cod_benefic_fattura='';
  descr_benefic_fattura='';
  descr_richiesta='';
  imp_richiesta=0;   
  rendicontazione ='';
  code_tipo_richiesta='';
  num_sub_impegno='';
  rendicontato:=''; 
  importo_attuale_impegno:=0;                                               
  num_carte_non_reg:=0;
  imp_carte_non_reg:=0;
  num_predoc_non_liq:=0;
  imp_predoc_non_liq:=0;
  num_doc_non_liq:=0;
  imp_doc_non_liq:=0;
  imp_pagam_economali:=0;
  num_liquidazioni:=0;
  imp_liquidazioni :=0;  
  imp_disp_liquid :=0;
  imp_disp_pagare :=0;
  imp_disp_vincolare :=0;                  
  imp_totale_movimenti:=0;  
  
exception
	when no_data_found THEN
		raise notice 'movimenti non trovati' ;
		--return next;
--	when others  THEN
	--	raise notice 'errore nella lettura dei movimenti. ';
  --      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-6868 - Maurizio - FINE


-- SIAC-7219 - Sofia - Inizio
drop function if exists fnc_stilo_siac_atto_amm_verifica_annullabilita
(
  attoamm_id_in integer
);

drop function if exists fnc_stilo_siac_atto_amm_annulla_movgest_collegati
(
  attoamm_id_in integer,
  login_operazione_in varchar
);

CREATE OR REPLACE FUNCTION fnc_stilo_siac_atto_amm_verifica_annullabilita
(
  attoamm_id_in integer
)
RETURNS boolean AS
$body$
DECLARE

annullabile boolean;
codResult integer:=null;


test_data timestamp;

begin
test_data:=now();
annullabile:= true;



  select 1 into codResult
  from siac_r_atto_amm_stato rsAtto, siac_d_atto_amm_stato stato
  where rsAtto.attoamm_id=attoamm_id_in
  and   stato.attoamm_stato_id=rsatto.attoamm_stato_id
  and   stato.attoamm_stato_code='ANNULLATO'
  and   test_data between rsAtto.validita_inizio and coalesce(rsAtto.validita_fine, test_data)
  and   rsAtto.data_cancellazione is null
  limit 1;
  if codResult is not null  then annullabile:=false; end if;
  raise notice ' Atto annullabile : atto annullato %',(not annullabile);

  if annullabile=true then


    select 1  into codResult
    from siac_r_bil_stato_op_atto_amm
    where attoamm_id=attoamm_id_in
    and data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste bil_stato_op %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_causale_atto_amm rAtto
    where rAtto.attoamm_id=attoamm_id_in
    and test_data between rAtto.validita_inizio and coalesce(rAtto.validita_fine,test_data)
    and rAtto.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;   end if;
    raise notice ' Atto annullabile : esiste causale_atto_amm %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_liquidazione_atto_amm  rAtto, siac_t_liquidazione liq
    where rAtto.attoamm_id=attoamm_id_in
    and   liq.liq_id=rAtto.liq_id
    and   test_data between rAtto.validita_inizio and coalesce(rAtto.validita_fine,test_data)
    and   rAtto.data_cancellazione is null
    and   liq.data_cancellazione is null
    limit 1;
    if codResult is not null  then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste liquidazione_atto_amm  %',(not annullabile);

  end if;


  if annullabile = true THEN


    -- solo impegni-accertamenti definitivi
    select 1 into codResult
    from siac_r_movgest_ts_atto_amm rAtto ,siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
    where rAtto.attoamm_id=attoamm_id_in
    and   ts.movgest_ts_id=ratto.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
    and   test_data between rAtto.validita_inizio and coalesce(ratto.validita_fine,test_data)
    and   rs.data_cancellazione is null
    and   rAtto.data_cancellazione is null
    and   ts.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste movgest_ts_atto_amm  %',(not annullabile);
  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_mutuo_atto_amm rAtto, siac_t_mutuo m
    where rAtto.attoamm_id=attoamm_id_in
    and   m.mut_id=rAtto.mut_id
    and   test_data between rAtto.validita_inizio and coalesce(rAtto.validita_fine,test_data)
    and   rAtto.data_cancellazione is null
    and   m.data_cancellazione is null
    limit 1;
    if codResult is not null  then annullabile:=false;    end if;
    raise notice ' Atto annullabile : esiste mutuo_atto_amm  %',(not annullabile);

  end if;


  if annullabile = true THEN



    select 1 into codResult
    from siac_r_ordinativo_atto_amm ra, siac_t_ordinativo o
    where ra.attoamm_id=attoamm_id_in
    and   o.ord_id=ra.ord_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   o.data_cancellazione is null
    limit 1;
    if codResult is not null  then annullabile:=false;  end if;
    raise notice ' Atto annullabile : esiste ordinativo_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_r_predoc_atto_amm ra, siac_t_predoc p
    where  ra.attoamm_id=attoamm_id_in
    and    p.predoc_id=ra.predoc_id
    and    test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and    ra.data_cancellazione is null
    and    p.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste predoc_atto_amm  %',(not annullabile);

  end if;


  if annullabile = true THEN



	select 1 into codResult
    from siac_r_programma_atto_amm ra, siac_t_programma p
    where ra.attoamm_id=attoamm_id_in
    and   p.programma_id=ra.programma_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   p.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste programma_atto_amm  %',(not annullabile);


  end if;


  if annullabile = true THEN


    select 1 into codResult
    from siac_r_subdoc_atto_amm ra, siac_t_subdoc sub, siac_t_doc doc
    where ra.attoamm_id=attoamm_id_in
    and   sub.subdoc_id=ra.subdoc_id
    and   doc.doc_id=sub.doc_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   sub.data_cancellazione is null
    and   doc.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste subdoc_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN


    select 1  into codResult
    from siac_r_variazione_stato ra, siac_t_bil_elem_det_var dvar,siac_t_variazione var
    where ra.attoamm_id=attoamm_id_in
    and   dvar.variazione_stato_id=ra.variazione_stato_id
    and   var.variazione_id=ra.variazione_id
    and   test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and   ra.data_cancellazione is null
    and   dvar.data_cancellazione is null
    and   var.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste variazione_atto_amm  %',(not annullabile);



  end if;

  if annullabile = true THEN


    select 1 into codResult
    from siac_t_atto_allegato ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null
    limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste atto_allegato_atto_amm  %',(not annullabile);



  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_t_cartacont ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste cartacont_atto_amm  %',(not annullabile);

  end if;

  if annullabile = true THEN



    select 1 into codResult
    from siac_t_cassa_econ_operaz ra
    where ra.attoamm_id=attoamm_id_in
    and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
    and ra.data_cancellazione is null limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste cassa_econ_operaz_atto_amm  %',(not annullabile);


  end if;

  if annullabile = true THEN




    select 1 into codResult
    from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta
    where ra.attoamm_id=attoamm_id_in
    and   st.mod_id=ra.mod_id
    and   sta.mod_stato_id=st.mod_stato_id
    and   sta.mod_stato_code<>'A'
    and   test_data between st.validita_inizio and coalesce(st.validita_fine,test_data)
    and   st.data_cancellazione is null
    and   ra.data_cancellazione is null limit 1;
    if codResult is not null then annullabile:=false; end if;
    raise notice ' Atto annullabile : esiste modifica_atto_amm  %',(not annullabile);
  end if;

return annullabile;

exception
    when no_data_found then
        return false;
 	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


CREATE OR REPLACE FUNCTION fnc_stilo_siac_atto_amm_annulla_movgest_collegati
(
  attoamm_id_in integer,
  login_operazione_in varchar
)
RETURNS boolean AS
$body$
DECLARE

test_data timestamp:=null;
codResult integer:=null;

login_oper VARCHAR:=null;
esito boolean:=true;

begin

test_data:=now();

login_oper:= login_operazione_in||' - '||'stilo_annulla_movgest_coll';

select 1 into codResult
from siac_r_movgest_ts_atto_amm ratto, siac_t_movgest_ts ts,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
where ratto.attoamm_id=attoamm_id_in
and   ts.movgest_ts_id=ratto.movgest_ts_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code not in ('A','N','D')
and   test_data between ratto.validita_inizio and coalesce(ratto.validita_fine,test_data)
and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
and   rs.data_cancellazione is null
and   ts.data_cancellazione is null
and   ratto.data_cancellazione is null limit 1;
raise notice 'esiste mov. da annullare %',codResult;

if codResult is not null then
	codResult:=null;
	insert into siac_r_movgest_ts_stato
    (
    	movgest_ts_id,
        movgest_stato_id,
        login_operazione,
        validita_inizio,
        ente_proprietario_id
    )
    select ts.movgest_ts_id,
           statoA.movgest_stato_id,
           login_oper,
           clock_timestamp(),
           stato.ente_proprietario_id
    from siac_r_movgest_ts_atto_amm ratto, siac_t_movgest_ts ts,
	     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_stato statoA
	where ratto.attoamm_id=attoamm_id_in
	and   ts.movgest_ts_id=ratto.movgest_ts_id
	and   rs.movgest_ts_id=ts.movgest_ts_id
	and   stato.movgest_stato_id=rs.movgest_stato_id
	and   stato.movgest_stato_code not in ('A','N','D')
    and   statoA.ente_proprietario_id=stato.ente_proprietario_id
    and   statoA.movgest_stato_code='A'
	and   test_data between ratto.validita_inizio and coalesce(ratto.validita_fine,test_data)
	and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
	and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
	and   rs.data_cancellazione is null
	and   ts.data_cancellazione is null
	and   ratto.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;

    if codResult is not null then

      codResult:=null;
      update siac_r_movgest_ts_stato rs
      set    data_cancellazione=clock_timestamp(),
             validita_fine=clock_timestamp(),
             login_operazione=rs.login_operazione||' - '||login_oper
      from siac_r_movgest_ts_atto_amm ratto, siac_t_movgest_ts ts,
           siac_d_movgest_stato stato
      where ratto.attoamm_id=attoamm_id_in
      and   ts.movgest_ts_id=ratto.movgest_ts_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code not in ('A','N','D')
      and   test_data between ratto.validita_inizio and coalesce(ratto.validita_fine,test_data)
      and   test_data between rs.validita_inizio and coalesce(rs.validita_fine,test_data)
      and   test_data between ts.validita_inizio and coalesce(ts.validita_fine,test_data)
      and   rs.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   ratto.data_cancellazione is null;
      GET DIAGNOSTICS codResult = ROW_COUNT;

    end if;

end if;


return esito;

exception
     when others  THEN
         RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-7219 - Sofia - Fine


--- SIAC-6884 INIZIO
--Inserimento azione GESC001-insVarDecentrato e relazione con ruolo
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC001-insVarDecentrato','Inserisci Variazione di Bilancio',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac.siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'BIL_ALTRO'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-GESC001-insVarDecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

--Inserimento azione OP-GESC002-aggVarDecentrato
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT 'OP-GESC002-aggVarDecentrato','Aggiorna Variazione Decentrata',a.azione_tipo_id,b.gruppo_azioni_id,'/../siacbilapp/azioneRichiesta.do',now(),a.ente_proprietario_id,'admin'
FROM siac_d_azione_tipo a JOIN siac.siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = ''
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-GESC002-aggVarDecentrato'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

/*
INSERT INTO siac_r_ruolo_op_azione (ruolo_op_id, azione_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dro.ruolo_op_id, ta.azione_id, now(), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_ruolo_op dro ON dro.ente_proprietario_id = tep.ente_proprietario_id
JOIN siac_t_azione ta ON ta.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('OP-GESC001-insVarDecentrato', 'ruolo op decentrato', '')) AS tmp(azione, ruolo, ente)
WHERE dro.ruolo_op_code = tmp.ruolo AND tep.ente_proprietario_id = 2
AND ta.azione_code = tmp.azione
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_ruolo_op_azione rroa
	WHERE rroa.ente_proprietario_id = tep.ente_proprietario_id
	AND rroa.ruolo_op_id = dro.ruolo_op_id
	AND rroa.azione_id = ta.azione_id
	AND rroa.data_cancellazione IS NULL
);*/
---
--update desc Classificatore3
update siac_d_class_tipo set classif_tipo_desc='Capitolo Budget' 
where classif_tipo_code='CLASSIFICATORE_3' and ente_proprietario_id in 
(select ente_proprietario_id from siac_t_ente_proprietario)
and not exists (select 1 from siac_d_class_tipo z where z.classif_tipo_desc='Capitolo Budget');

--insert values for Capitolo Budget
insert into siac_t_class
(classif_code,  classif_desc,  classif_tipo_id, validita_inizio,  ente_proprietario_id, data_creazione,login_operazione)
select '01','SI', tipo.classif_tipo_id, now(), e.ente_proprietario_id, now(), 'SIAC-6884'
  from siac_d_class_tipo tipo,  siac_t_ente_proprietario e
  where  tipo.ente_proprietario_id = e.ente_proprietario_id
  and tipo.classif_tipo_code='CLASSIFICATORE_3'
  and not exists (
    select 1
    from siac_t_class z
	where z.classif_tipo_id=tipo.classif_tipo_id and z.classif_code='01'
  );


insert into siac_t_class
(classif_code,  classif_desc,  classif_tipo_id, validita_inizio,  ente_proprietario_id, data_creazione,login_operazione)
select '02','NO', tipo.classif_tipo_id, now(), e.ente_proprietario_id, now(), 'SIAC-6884'
  from siac_d_class_tipo tipo,  siac_t_ente_proprietario e
  where  tipo.ente_proprietario_id = e.ente_proprietario_id
  and tipo.classif_tipo_code='CLASSIFICATORE_3'
  and not exists (
    select 1
    from siac_t_class z
	where z.classif_tipo_id=tipo.classif_tipo_id and z.classif_code='02'
  );

 --Alter table con nuove colonne
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'data_apertura_proposta' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'classif_id' , 'INTEGER');
SELECT * FROM fnc_dba_add_fk_constraint('siac_t_variazione', 'siac_t_class_siac_t_variazione', 'classif_id', 'siac.siac_t_class', 'classif_id');

SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'data_chiusura_proposta' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'data_definitiva' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'flag_consiglio', 'BOOLEAN DEFAULT false NOT NULL');
SELECT * FROM fnc_dba_add_column_params ('siac_t_variazione', 'flag_giunta', 'BOOLEAN DEFAULT false NOT NULL');
----


INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2019-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('REGIONE_PIEMONTE_INS_CAP_VAR_DEC', 'Regione Piemonte Inserimento capitolo in variazione decentrata')) AS tmp(code, descr)
WHERE tep.ente_denominazione ='Regione Piemonte' AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;
-------------------------------
INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('TRUE', 'TRUE', 'REGIONE_PIEMONTE_INS_CAP_VAR_DEC')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo AND tep.ente_denominazione ='Regione Piemonte'
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	AND dgt.gestione_tipo_code = tmp.tipo
)
ORDER BY tep.ente_proprietario_id, tmp.code;
-----
INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2017-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('TRUE', 'Regione Piemonte')) AS tmp(livello, ente)
WHERE tep.ente_denominazione = tmp.ente
AND dgl.gestione_livello_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);
-- SIAC-6684 FINE

-- SIAC-6883 INIZIO
DROP FUNCTION fnc_siac_capitoli_from_variazioni(integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_capitoli_from_variazioni (
  p_uid_variazione integer
)
RETURNS TABLE (
  stato_variazione varchar,
  anno_capitolo varchar,
  numero_capitolo varchar,
  numero_articolo varchar,
  numero_ueb varchar,
  tipo_capitolo varchar,
  descrizione_capitolo varchar,
  descrizione_articolo varchar,
  missione varchar,
  programma varchar,
  titolo_uscita varchar,
  macroaggregato varchar,
  titolo_entrata varchar,
  tipologia varchar,
  categoria varchar,
  var_competenza numeric,
  var_residuo numeric,
  var_cassa numeric,
  var_competenza1 numeric,
  var_residuo1 numeric,
  var_cassa1 numeric,
  var_competenza2 numeric,
  var_residuo2 numeric,
  var_cassa2 numeric,
  cap_competenza numeric,
  cap_residuo numeric,
  cap_cassa numeric,
  cap_competenza1 numeric,
  cap_residuo1 numeric,
  cap_cassa1 numeric,
  cap_competenza2 numeric,
  cap_residuo2 numeric,
  cap_cassa2 numeric,
  tipologiaFinanziamento varchar,
  sac varchar,
  variazione_num integer
) AS
$body$
DECLARE
	v_ente_proprietario_id INTEGER;
BEGIN

	-- Utilizzo l'ente per migliorare la performance delle CTE nella query successiva
	SELECT ente_proprietario_id
	INTO v_ente_proprietario_id
	FROM siac_t_variazione
	WHERE siac_t_variazione.variazione_id = p_uid_variazione;
	
	RETURN QUERY
		-- CTE per uscita
		WITH missione AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc missione_tipo_desc,
				siac_t_class.classif_id missione_id,
				siac_t_class.classif_code missione_code,
				siac_t_class.classif_desc missione_desc,
				siac_t_class.validita_inizio missione_validita_inizio,
				siac_t_class.validita_fine missione_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR missione_code_desc
			FROM siac_t_class
			JOIN siac_d_class_tipo ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'MISSIONE'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		programma AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc programma_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre missione_id,
				siac_t_class.classif_id programma_id,
				siac_t_class.classif_code programma_code,
				siac_t_class.classif_desc programma_desc,
				siac_t_class.validita_inizio programma_validita_inizio,
				siac_t_class.validita_fine programma_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR programma_code_desc,
				siac_r_bil_elem_class.elem_id programma_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id       AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione is null)
			WHERE siac_d_class_tipo.classif_tipo_code = 'PROGRAMMA'
			AND siac_t_class.data_cancellazione is null
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		titusc AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titusc_tipo_desc,
				siac_t_class.classif_id titusc_id,
				siac_t_class.classif_code titusc_code,
				siac_t_class.classif_desc titusc_desc,
				siac_t_class.validita_inizio titusc_validita_inizio,
				siac_t_class.validita_fine titusc_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titusc_code_desc
			FROM siac_t_class
			JOIN siac_d_class_tipo ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'TITOLO_SPESA'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		macroag AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc macroag_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titusc_id,
				siac_t_class.classif_id macroag_id,
				siac_t_class.classif_code macroag_code,
				siac_t_class.classif_desc macroag_desc,
				siac_t_class.validita_inizio macroag_validita_inizio,
				siac_t_class.validita_fine macroag_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR macroag_code_desc,
				siac_r_bil_elem_class.elem_id macroag_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id       AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'MACROAGGREGATO'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE per entrata
		titent AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titent_tipo_desc,
				siac_t_class.classif_id titent_id,
				siac_t_class.classif_code titent_code,
				siac_t_class.classif_desc titent_desc,
				siac_t_class.validita_inizio titent_validita_inizio,
				siac_t_class.validita_fine titent_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_d_class_tipo ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'TITOLO_ENTRATA'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titent_id,
				siac_t_class.classif_id tipologia_id,
				siac_t_class.classif_code tipologia_code,
				siac_t_class.classif_desc tipologia_desc,
				siac_t_class.validita_inizio tipologia_validita_inizio,
				siac_t_class.validita_fine tipologia_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id       AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'TIPOLOGIA'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre tipologia_id,
				siac_t_class.classif_id categoria_id,
				siac_t_class.classif_code categoria_code,
				siac_t_class.classif_desc categoria_desc,
				siac_t_class.validita_inizio categoria_validita_inizio,
				siac_t_class.validita_fine categoria_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc,
				siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id       AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'CATEGORIA'
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipofinanziamento AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipofinanziamento_tipo_desc,
				siac_t_class.classif_id tipofinanziamento_id,
				siac_t_class.classif_code tipofinanziamento_code,
				siac_t_class.classif_desc tipofinanziamento_desc,
				siac_t_class.validita_inizio tipofinanziamento_validita_inizio,
				siac_t_class.validita_fine tipofinanziamento_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipofinanziamento_code_desc,
				siac_r_bil_elem_class.elem_id tipofinanziamento_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id  AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id        AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code = 'TIPO_FINANZIAMENTO'
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc sar_tipo_desc,
				siac_t_class.classif_id sac_id,
				siac_t_class.classif_code sac_code,
				siac_t_class.classif_desc sac_desc,
				siac_t_class.validita_inizio sac_validita_inizio,
				siac_t_class.validita_fine sac_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc,
				siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id  AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id        AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code in ('CDC','CDR')
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE importi variazione
		comp_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			-- SIAC-6883
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                            AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		residuo_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impRes,
				siac_t_periodo.anno::integer
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione  IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			-- SIAC-6883
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                            AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		cassa_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			-- SIAC-6883
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                            AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		-- CTE importi capitolo
		comp_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		residuo_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impRes,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		cassa_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		)
		SELECT
			 siac_d_variazione_stato.variazione_stato_tipo_desc stato_variazione
			,siac_t_periodo.anno                               anno_capitolo
			,siac_t_bil_elem.elem_code                         numero_capitolo
			,siac_t_bil_elem.elem_code2                        numero_articolo
			,siac_t_bil_elem.elem_code3                        numero_ueb
			,siac_d_bil_elem_tipo.elem_tipo_code               tipo_capitolo
			,siac_t_bil_elem.elem_desc                         descrizione_capitolo
			,siac_t_bil_elem.elem_desc2                        descrizione_articolo
			-- Dati uscita
			,missione.missione_code_desc   missione
			,programma.programma_code_desc programma
			
			,titusc.titusc_code_desc       titolo_uscita
			,macroag.macroag_code_desc     macroaggregato
			-- Dati entrata
			,titent.titent_code_desc       titolo_entrata
			,tipologia.tipologia_code_desc tipologia
			,categoria.categoria_code_desc categoria
			-- Importi variazione
			,comp_variaz.impSta     var_competenza
			,residuo_variaz.impRes  var_residuo
			,cassa_variaz.impSca    var_cassa
			
			,comp_variaz1.impSta    var_competenza1
			,residuo_variaz1.impRes var_residuo1
			,cassa_variaz1.impSca   var_cassa1
			,comp_variaz2.impSta    var_competenza2
			,residuo_variaz2.impRes var_residuo2
			,cassa_variaz2.impSca   var_cassa2
			-- Importi capitolo
			,comp_capitolo.impSta     cap_competenza
			,residuo_capitolo.impRes  cap_residuo
			,cassa_capitolo.impSca    cap_cassa
			,comp_capitolo1.impSta    cap_competenza1
			
			,residuo_capitolo1.impRes cap_residuo1
			,cassa_capitolo1.impSca   cap_cassa1
			,comp_capitolo2.impSta    cap_competenza2
			,residuo_capitolo2.impRes cap_residuo2 
			,cassa_capitolo2.impSca   cap_cassa2
			,tipofinanziamento.tipofinanziamento_code_desc tipologiaFinanziamento
			,sac.sac_code_desc sac
			,siac_t_variazione.variazione_num

		FROM siac_t_variazione
		JOIN siac_r_variazione_stato           ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                             AND siac_r_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_d_variazione_stato           ON (siac_r_variazione_stato.variazione_stato_tipo_id = siac_d_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem_det_var           ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem                   ON (siac_t_bil_elem_det_var.elem_id = siac_t_bil_elem.elem_id                                           AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                        ON (siac_t_bil_elem.bil_id = siac_t_bil.bil_id                                                          AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                    ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                                   AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_tipo              ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id                                    AND siac_d_bil_elem_tipo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_det_tipo          ON (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
		
		--JOIN siac_t_bil     bil_variazione     ON (bil_variazione.bil_id = siac_t_variazione.bil_id                                                    AND bil_variazione.data_cancellazione IS NULL)
		--JOIN siac_t_periodo periodo_variazione ON (bil_variazione.periodo_id = periodo_variazione.periodo_id                                           AND periodo_variazione.data_cancellazione IS NULL)
		-- SIAC-6883
		--JOIN siac_t_periodo periodo_variazione ON (siac_t_variazione.periodo_id = periodo_variazione.periodo_id                                          AND periodo_variazione.data_cancellazione IS NULL)
		
		-- Importi variazione, anno 0
		JOIN comp_variaz    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz.elem_id    AND comp_variaz.anno = siac_t_periodo.anno::INTEGER)
		JOIN residuo_variaz ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz.elem_id AND residuo_variaz.anno = siac_t_periodo.anno::INTEGER)
		JOIN cassa_variaz   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz.elem_id   AND cassa_variaz.anno = siac_t_periodo.anno::INTEGER)
		-- Importi variazione, anno +1
		JOIN comp_variaz    comp_variaz1    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz1.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz1.elem_id    AND comp_variaz1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_variaz residuo_variaz1 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz1.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz1.elem_id AND residuo_variaz1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz1   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz1.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz1.elem_id   AND cassa_variaz1.anno = siac_t_periodo.anno::INTEGER + 1)
		-- Importi variazione, anno +2
		JOIN comp_variaz    comp_variaz2    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz2.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz2.elem_id    AND comp_variaz2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_variaz residuo_variaz2 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz2.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz2.elem_id AND residuo_variaz2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz2   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz2.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz2.elem_id   AND cassa_variaz2.anno = siac_t_periodo.anno::INTEGER + 2)
		-- Importi capitolo, anno 0
		JOIN comp_capitolo    ON (siac_t_bil_elem.elem_id = comp_capitolo.elem_id    AND comp_capitolo.anno = siac_t_periodo.anno::INTEGER)
		JOIN residuo_capitolo ON (siac_t_bil_elem.elem_id = residuo_capitolo.elem_id AND residuo_capitolo.anno = siac_t_periodo.anno::INTEGER)
		JOIN cassa_capitolo   ON (siac_t_bil_elem.elem_id = cassa_capitolo.elem_id   AND cassa_capitolo.anno = siac_t_periodo.anno::INTEGER)
		-- Importi capitolo, anno +1
		JOIN comp_capitolo    comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id    AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		JOIN residuo_capitolo residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id AND residuo_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		JOIN cassa_capitolo   cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id   AND cassa_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		-- Importi capitolo, anno +2
		JOIN comp_capitolo    comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id    AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		JOIN residuo_capitolo residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id AND residuo_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		JOIN cassa_capitolo   cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id   AND cassa_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		-- Classificatori
		LEFT OUTER JOIN macroag   ON (macroag.macroag_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN programma ON (programma.programma_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN missione  ON (missione.missione_id = programma.missione_id)
		LEFT OUTER JOIN titusc    ON (titusc.titusc_id = macroag.titusc_id)
		LEFT OUTER JOIN categoria ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN tipologia ON (tipologia.tipologia_id = categoria.tipologia_id)
		LEFT OUTER JOIN titent    ON (tipologia.titent_id = titent.titent_id)
		-- SIAC-6468
		LEFT OUTER JOIN tipofinanziamento ON (tipofinanziamento.tipofinanziamento_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN sac ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		
		-- WHERE clause
		WHERE siac_t_variazione.variazione_id = p_uid_variazione
		AND siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		AND siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id
		ORDER BY tipo_capitolo DESC, anno_capitolo, siac_t_bil_elem.elem_code::integer, siac_t_bil_elem.elem_code2::integer, siac_t_bil_elem.elem_code3::integer;
		
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

DROP FUNCTION fnc_siac_inserisci_det_variazione_assestamento(integer,character varying,character varying);

CREATE OR REPLACE FUNCTION siac.fnc_siac_inserisci_det_variazione_assestamento (
  variazione_id_in integer,
  anno_bilancio varchar,
  login_operazione_in varchar
)
RETURNS TABLE (
  _elem_id integer,
  _elem_det_var_id integer,
  _elem_det_var_tipo_code varchar,
  _anno varchar,
  _elem_det_importo numeric
) AS
$body$
DECLARE

periodo_id_piu_zero integer;
periodo_id_piu_uno integer;
periodo_id_piu_due integer;

BEGIN
	
	-- Ottengo periodo per anno, anno + 1 e anno + 2
	select siac_t_periodo_var.periodo_id, siac_t_periodo1.periodo_id, siac_t_periodo2.periodo_id
	into periodo_id_piu_zero, periodo_id_piu_uno, periodo_id_piu_due
	from siac_t_periodo siac_t_periodo1
	join siac_t_periodo siac_t_periodo2 on (siac_t_periodo2.ente_proprietario_id = siac_t_periodo1.ente_proprietario_id and siac_t_periodo2.data_cancellazione is null)
	join siac_t_variazione on (siac_t_variazione.ente_proprietario_id = siac_t_periodo1.ente_proprietario_id and siac_t_variazione.data_cancellazione is null)
	join siac_t_bil on (siac_t_bil.bil_id = siac_t_variazione.bil_id and siac_t_bil.data_cancellazione is null)
	join siac_t_periodo siac_t_periodo_var on (siac_t_periodo_var.periodo_id = siac_t_bil.periodo_id and siac_t_periodo_var.data_cancellazione is null)
	join siac_d_periodo_tipo siac_d_periodo_tipo1 on (siac_d_periodo_tipo1.periodo_tipo_id = siac_t_periodo1.periodo_tipo_id AND siac_d_periodo_tipo1.data_cancellazione is null)
	join siac_d_periodo_tipo siac_d_periodo_tipo2 on (siac_d_periodo_tipo2.periodo_tipo_id = siac_t_periodo2.periodo_tipo_id AND siac_d_periodo_tipo2.data_cancellazione is null)
	where siac_t_periodo1.data_cancellazione is null
	and siac_t_variazione.variazione_id = variazione_id_in
	and siac_t_periodo1.anno = cast(cast(siac_t_periodo_var.anno as integer) + 1 as character varying)
	and siac_t_periodo2.anno = cast(cast(siac_t_periodo_var.anno as integer) + 2 as character varying)
	and siac_d_periodo_tipo1.periodo_tipo_code = 'SY'
	and siac_d_periodo_tipo2.periodo_tipo_code = 'SY';
	
	insert into siac.siac_t_bil_elem_det_var (
		variazione_stato_id,
		elem_id,
		elem_det_importo,
		elem_det_flag,
		elem_det_tipo_id,
		periodo_id,
		validita_inizio,
		ente_proprietario_id,
		login_operazione)
	select
		temp.variazione_stato_id,
		temp.elemid,
		-sum(temp.rescap) + sum(temp.resmv) as var_st_res,
		null,
		siac_d_bil_elem_det_tipo.elem_det_tipo_id,
		siac_t_periodo.periodo_id,
		now(),
		temp.ente_proprietario_id,
		login_operazione_in
	from (
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			sum(siac_t_bil_elem_det.elem_det_importo) as rescap,
			0 as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine, now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-UG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			0 as rescap,
			0 as resmv,
			sum(siac_t_bil_elem_det.elem_det_importo) as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem_det.elem_id = siac_t_bil_elem.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine, now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-UG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			0 as rescap,
			0 as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine, now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-UG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_r_movgest_bil_elem.ente_proprietario_id,
			siac_r_movgest_bil_elem.elem_id as elemid,
			0 as rescap,
			sum(siac_t_movgest_ts_det.movgest_ts_det_importo) as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_movgest_ts
		join siac_r_movgest_bil_elem on (siac_t_movgest_ts.movgest_id = siac_r_movgest_bil_elem.movgest_id and siac_r_movgest_bil_elem.data_cancellazione is null and now() between siac_r_movgest_bil_elem.validita_inizio and COALESCE(siac_r_movgest_bil_elem.validita_fine,now()))
		join siac_t_movgest_ts_det on (siac_t_movgest_ts_det.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id and siac_t_movgest_ts_det.data_cancellazione is null)
		join siac_d_movgest_ts_det_tipo on (siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_id = siac_t_movgest_ts_det.movgest_ts_det_tipo_id and siac_d_movgest_ts_det_tipo.data_cancellazione is null)
		join siac_t_movgest on (siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id and siac_t_movgest.data_cancellazione is null)
		join siac_d_movgest_tipo on (siac_d_movgest_tipo.movgest_tipo_id = siac_t_movgest.movgest_tipo_id and siac_d_movgest_tipo.data_cancellazione is null)
		join siac_d_movgest_ts_tipo on (siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id and siac_d_movgest_ts_tipo.data_cancellazione is null)
		join siac_r_movgest_ts_stato on (siac_r_movgest_ts_stato.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id and siac_r_movgest_ts_stato.data_cancellazione is null and now() between siac_r_movgest_ts_stato.validita_inizio and COALESCE(siac_r_movgest_ts_stato.validita_fine,now()))
		join siac_d_movgest_stato on (siac_r_movgest_ts_stato.movgest_stato_id = siac_d_movgest_stato.movgest_stato_id and siac_d_movgest_stato.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_movgest_ts_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() between siac_r_variazione_stato.validita_inizio and COALESCE(siac_r_variazione_stato.validita_fine,now()))
		join siac_t_bil on (siac_t_bil.bil_id = siac_t_movgest.bil_id and siac_t_bil.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil.periodo_id and siac_t_periodo.data_cancellazione is null)
		where siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'I'
		and siac_d_movgest_tipo.movgest_tipo_code = 'I'
		and siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'
		and siac_t_movgest.movgest_anno < anno_bilancio::integer
		and siac_d_movgest_stato.movgest_stato_code in ('N', 'D')
		and siac_t_movgest_ts.data_cancellazione is null
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_periodo.anno = anno_bilancio
		group by siac_r_variazione_stato.variazione_stato_id, siac_r_movgest_bil_elem.ente_proprietario_id, siac_r_movgest_bil_elem.elem_id
	) as temp
	join siac_d_bil_elem_det_tipo on (siac_d_bil_elem_det_tipo.ente_proprietario_id = temp.ente_proprietario_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
	join siac_t_periodo on (siac_t_periodo.ente_proprietario_id = siac_d_bil_elem_det_tipo.ente_proprietario_id and siac_t_periodo.data_cancellazione is null)
	join siac_d_periodo_tipo on (siac_d_periodo_tipo.periodo_tipo_id = siac_t_periodo.periodo_tipo_id and siac_d_periodo_tipo.data_cancellazione is null)
	where siac_d_bil_elem_det_tipo.elem_det_tipo_code in ('STR', 'SCA')
	and siac_t_periodo.anno = anno_bilancio
	and siac_d_periodo_tipo.periodo_tipo_code = 'SY'
	group by temp.variazione_stato_id, temp.elemid, siac_d_bil_elem_det_tipo.elem_det_tipo_id, siac_t_periodo.periodo_id, temp.ente_proprietario_id
	having -sum(temp.rescap) + sum(temp.resmv) <> 0;
	
	insert into siac.siac_t_bil_elem_det_var (
		variazione_stato_id,
		elem_id,
		elem_det_importo,
		elem_det_flag,
		elem_det_tipo_id,
		periodo_id,
		validita_inizio,
		ente_proprietario_id,
		login_operazione)
	select
		temp.variazione_stato_id,
		temp.elemid,
		-sum(temp.rescap) + sum(temp.resmv) as var_st_res,
		null,
		siac_d_bil_elem_det_tipo.elem_det_tipo_id,
		siac_t_periodo.periodo_id,
		now(),
		temp.ente_proprietario_id,
		login_operazione_in
	from (
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			sum(siac_t_bil_elem_det.elem_det_importo) as rescap,
			0 as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine,now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-EG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			0 as rescap,
			0 as resmv,
			sum(siac_t_bil_elem_det.elem_det_importo) as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine,now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-EG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			0 as rescap,
			0 as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine,now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-EG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_r_movgest_bil_elem.ente_proprietario_id,
			siac_r_movgest_bil_elem.elem_id as elemid,
			0 as rescap,
			sum(siac_t_movgest_ts_det.movgest_ts_det_importo) as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_movgest_ts
		join siac_r_movgest_bil_elem on (siac_t_movgest_ts.movgest_id = siac_r_movgest_bil_elem.movgest_id and siac_r_movgest_bil_elem.data_cancellazione is null and now() between siac_r_movgest_bil_elem.validita_inizio and COALESCE(siac_r_movgest_bil_elem.validita_fine, now()))
		join siac_t_movgest_ts_det on (siac_t_movgest_ts_det.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id and siac_t_movgest_ts_det.data_cancellazione is null)
		join siac_d_movgest_ts_det_tipo on (siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_id = siac_t_movgest_ts_det.movgest_ts_det_tipo_id and siac_d_movgest_ts_det_tipo.data_cancellazione is null)
		join siac_t_movgest on (siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id and siac_t_movgest.data_cancellazione is null)
		join siac_d_movgest_tipo on (siac_d_movgest_tipo.movgest_tipo_id = siac_t_movgest.movgest_tipo_id and siac_d_movgest_tipo.data_cancellazione is null)
		join siac_d_movgest_ts_tipo on (siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id and siac_d_movgest_ts_tipo.data_cancellazione is null)
		join siac_r_movgest_ts_stato on (siac_r_movgest_ts_stato.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id and siac_r_movgest_ts_stato.data_cancellazione is null and now() between siac_r_movgest_ts_stato.validita_inizio and COALESCE(siac_r_movgest_ts_stato.validita_fine, now()))
		join siac_d_movgest_stato on (siac_r_movgest_ts_stato.movgest_stato_id = siac_d_movgest_stato.movgest_stato_id and siac_d_movgest_stato.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_movgest_ts_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() between siac_r_variazione_stato.validita_inizio and COALESCE(siac_r_variazione_stato.validita_fine, now()))
		join siac_t_bil on (siac_t_bil.bil_id = siac_t_movgest.bil_id and siac_t_bil.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil.periodo_id and siac_t_periodo.data_cancellazione is null)
		where siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'I'
		and siac_d_movgest_tipo.movgest_tipo_code = 'A'
		and siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'
		and siac_t_movgest.movgest_anno < anno_bilancio::integer
		and siac_d_movgest_stato.movgest_stato_code in ('N', 'D')
		and siac_t_movgest_ts.data_cancellazione is null
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		group by siac_r_variazione_stato.variazione_stato_id, siac_r_movgest_bil_elem.ente_proprietario_id, siac_r_movgest_bil_elem.elem_id
	) as temp
	join siac_d_bil_elem_det_tipo on (siac_d_bil_elem_det_tipo.ente_proprietario_id = temp.ente_proprietario_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
	join siac_t_periodo on (siac_t_periodo.ente_proprietario_id = siac_d_bil_elem_det_tipo.ente_proprietario_id and siac_t_periodo.data_cancellazione is null)
	join siac_d_periodo_tipo on (siac_d_periodo_tipo.periodo_tipo_id = siac_t_periodo.periodo_tipo_id and siac_d_periodo_tipo.data_cancellazione is null)
	where siac_d_bil_elem_det_tipo.elem_det_tipo_code in ('STR', 'SCA')
	and siac_t_periodo.anno = anno_bilancio
	and siac_d_periodo_tipo.periodo_tipo_code = 'SY'
	group by temp.variazione_stato_id, temp.elemid, siac_d_bil_elem_det_tipo.elem_det_tipo_id, siac_t_periodo.periodo_id, temp.ente_proprietario_id
	having -sum(temp.rescap) + sum(temp.resmv) <> 0;
	
	insert into siac.siac_t_bil_elem_det_var (
		variazione_stato_id,
		elem_id,
		elem_det_importo,
		elem_det_flag,
		elem_det_tipo_id,
		periodo_id,
		validita_inizio,
		ente_proprietario_id,
		login_operazione
	)
	select
		siac_t_bil_elem_det_var.variazione_stato_id,
		siac_t_bil_elem_det_var.elem_id,
		0,
		null,
		siac_d_bil_elem_det_tipo.elem_det_tipo_id,
		tmp.periodo_id,
		now(),
		siac_t_bil_elem_det_var.ente_proprietario_id,
		login_operazione_in
	from siac_t_bil_elem_det_var
	join siac_d_bil_elem_det_tipo siac_d_bil_elem_det_tipo_var on (siac_d_bil_elem_det_tipo_var.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id and siac_d_bil_elem_det_tipo_var.data_cancellazione is null)
	join siac_d_bil_elem_det_tipo on (siac_d_bil_elem_det_tipo.ente_proprietario_id = siac_t_bil_elem_det_var.ente_proprietario_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
	join siac_r_variazione_stato on (siac_t_bil_elem_det_var.variazione_stato_id = siac_r_variazione_stato.variazione_stato_id and siac_r_variazione_stato.data_cancellazione is null)
	cross join (values
		(periodo_id_piu_zero),
		(periodo_id_piu_uno),
		(periodo_id_piu_due)
	) as tmp(periodo_id)
	where siac_t_bil_elem_det_var.data_cancellazione is null
	and siac_r_variazione_stato.variazione_id = variazione_id_in
	and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
	and siac_d_bil_elem_det_tipo_var.elem_det_tipo_code = 'STR'
	and siac_t_bil_elem_det_var.login_operazione = login_operazione_in;
	
	RETURN QUERY
	select
		siac_t_bil_elem_det_var.elem_id,
		siac_t_bil_elem_det_var.elem_det_var_id,
		siac_d_bil_elem_det_tipo.elem_det_tipo_code,
		siac_t_periodo.anno,
		siac_t_bil_elem_det_var.elem_det_importo
	from siac_t_bil_elem_det_var
	join siac_d_bil_elem_det_tipo on (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
	join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det_var.periodo_id and siac_t_periodo.data_cancellazione is null)
	join siac_r_variazione_stato on (siac_t_bil_elem_det_var.variazione_stato_id = siac_r_variazione_stato.variazione_stato_id and siac_r_variazione_stato.data_cancellazione is null)
	where siac_t_bil_elem_det_var.data_cancellazione is null
	and siac_r_variazione_stato.variazione_id = variazione_id_in
	and siac_t_bil_elem_det_var.login_operazione = login_operazione_in
	order by
		siac_t_bil_elem_det_var.elem_id,
		siac_t_periodo.anno,
		case
			when siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA' then 1
			when siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR' then 2
			when siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA' then 3
			else 4
		end;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-6883 FINE

