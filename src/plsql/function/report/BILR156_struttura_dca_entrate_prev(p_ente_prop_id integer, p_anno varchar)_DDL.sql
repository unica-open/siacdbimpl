/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR156_struttura_dca_entrate_prev" (
  p_ente_prop_id integer,
  p_anno varchar
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
  previsioni_definitive_comp numeric,
  previsioni_definitive_cassa numeric,
  riaccertamenti_residui numeric,
  pdc_iv varchar,
  residui_attivi numeric
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
v_movgest_tipo varchar:='A';
v_movgest_ts_tipo varchar :='T';

v_det_tipo_importo_attuale varchar:='A';
v_det_tipo_importo_iniziale varchar:='I';
v_ord_stato_code_annullato varchar:='A';
v_ord_tipo_code_incasso varchar:='I';
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;  

TipoImpstanzresidui='SRI'; -- stanziamento residuo post (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
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
previsioni_definitive_cassa=0;
previsioni_definitive_comp=0;
riaccertamenti_residui=0;
pdc_iv:='';



RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;


RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL BILANCIO';


raise notice '1 - %' , clock_timestamp()::text;

return query
select zz.* from (
with classif as (
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
--insert into  siac_rep_tit_tip_cat_riga_anni
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
categoria.ente_proprietario_id
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id) ,
capitoli as (select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*
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
and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
),
importi_residui as(
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) imp_residuo
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
		and	tipo_ordinativo.ord_tipo_code		= 	v_ord_tipo_code_incasso		------ incasso
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
    
        and	stato_ordinativo.ord_stato_code			<> v_ord_stato_code_annullato --- 
    
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	v_det_tipo_importo_attuale 	---- importo attuala        
        and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
        and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id
        and	movimento.movgest_anno				<	annoCapImp_int	
        and movimento.bil_id					=	bilancio.bil_id	
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
    and now()
between r_capitolo_ordinativo.validita_inizio 
    and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now()
between r_stato_ordinativo.validita_inizio 
    and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now()
between r_ordinativo_movgest.validita_inizio 
    and COALESCE(r_ordinativo_movgest.validita_fine,now())
        group by r_capitolo_ordinativo.elem_id,r_capitolo_ordinativo.ente_proprietario_id
),        
importi_riacc_residui  as (
select    
   capitolo.elem_id,
   sum (t_movgest_ts_det_mod.movgest_ts_det_importo) importo_riacc_residui
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
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno 
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	elemTipoCode
      and movimento.movgest_anno 		  	< 	annoCapImp_int
      and movimento.bil_id					=	bilancio.bil_id
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and tipo_mov.movgest_tipo_code    	= v_movgest_tipo 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_mov_tipo.movgest_ts_tipo_code  = v_movgest_ts_tipo
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
      and dt_mov_tipo.movgest_ts_det_tipo_code = v_det_tipo_importo_attuale ----- importo attuale 
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id
      and now() 
		between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() 
 		between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now()
 		between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
group by capitolo.elem_id, p_ente_prop_id
) ,
  prev_def_comp as (select 		capitolo_importi.elem_id,			
            sum(capitolo_importi.elem_det_importo)     importo_prev_def_comp
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
        and capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanz
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
and now() between r_capitolo_stato.validita_inizio and COALESCE(r_capitolo_stato.validita_fine,now())        
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
  group by capitolo_importi.elem_id
  ),
  prev_def_cassa as (select 		capitolo_importi.elem_id,			
            sum(capitolo_importi.elem_det_importo)     importo_prev_def_cassa
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
        and capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa
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
and now() between r_capitolo_stato.validita_inizio and COALESCE(r_capitolo_stato.validita_fine,now())        
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
  group by capitolo_importi.elem_id
  ),
  elenco_pdci_IV as (
  select d_class_tipo.classif_tipo_code classif_tipo_code_cap,
          r_bil_elem_class.elem_id ,
          t_class.classif_code pdc_iv 
              from siac_t_class t_class,
                          siac_d_class_tipo d_class_tipo,
                          siac_r_bil_elem_class r_bil_elem_class
              where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                    and r_bil_elem_class.classif_id= t_class.classif_id
                  and d_class_tipo.classif_tipo_code = 'PDC_IV'
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null),
elenco_pdci_V as (
  select d_class_tipo.classif_tipo_code classif_tipo_code_cap,
          r_bil_elem_class.elem_id ,
          t_class.classif_code pdc_v,
  substring(t_class.classif_code from 1 for length(t_class.classif_code)-3) ||
          '000' classif_code_cap2
              from siac_t_class t_class,
                          siac_d_class_tipo d_class_tipo,
                          siac_r_bil_elem_class r_bil_elem_class
              where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                    and r_bil_elem_class.classif_id= t_class.classif_id
                  and d_class_tipo.classif_tipo_code = 'PDC_V'
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null)
select p_anno::varchar bil_anno,
	''::varchar titoloe_tipo_code,
    classif.titent_tipo_desc::varchar titoloe_tipo_desc,
    classif.titent_code::varchar  titoloe_code,
    classif.titent_desc::varchar  titoloe_desc,
    ''::varchar  tipologia_tipo_code,
    classif.tipologia_tipo_desc::varchar  tipologia_tipo_desc,
    classif.tipologia_code::varchar  tipologia_code,
    classif.tipologia_desc::varchar  tipologia_desc,
	''::varchar  categoria_tipo_code,
    classif.categoria_tipo_desc::varchar  categoria_tipo_desc,
    classif.categoria_code::varchar  categoria_code,
    classif.categoria_desc::varchar  categoria_desc,
	capitoli.elem_code::varchar  bil_ele_code,
    capitoli.elem_desc::varchar  bil_ele_desc,
    capitoli.elem_code2::varchar  bil_ele_code2,
    capitoli.elem_desc2::varchar  bil_ele_desc2,
    capitoli.elem_id::integer  bil_ele_id,
    capitoli.elem_id_padre::integer  bil_ele_id_padre,	
    COALESCE(prev_def_comp.importo_prev_def_comp,0)::numeric  previsioni_definitive_comp,
    COALESCE(prev_def_cassa.importo_prev_def_cassa,0)::numeric  previsioni_definitive_cassa,
    COALESCE(importi_riacc_residui.importo_riacc_residui,0)::numeric  riaccertamenti_residui,
    CASE WHEN  trim(COALESCE(elenco_pdci_IV.pdc_iv,'')) = ''
    	THEN elenco_pdci_V.pdc_v::varchar 
    	ELSE elenco_pdci_IV.pdc_iv::varchar end pdc_iv,
    COALESCE(importi_residui.imp_residuo,0)::numeric  residui_attivi    
	from capitoli
      left join classif on (classif.categoria_id = capitoli.classif_id  )      
      left join importi_riacc_residui on importi_riacc_residui.elem_id =capitoli.elem_id      
      left join prev_def_comp on prev_def_comp.elem_id =capitoli.elem_id
      left join prev_def_cassa on prev_def_cassa.elem_id =capitoli.elem_id 
      left join elenco_pdci_IV on elenco_pdci_IV.elem_id =capitoli.elem_id          
      left join elenco_pdci_V on elenco_pdci_V.elem_id =capitoli.elem_id       
      left join importi_residui on importi_residui.elem_id =capitoli.elem_id            
	) zz ;
 

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