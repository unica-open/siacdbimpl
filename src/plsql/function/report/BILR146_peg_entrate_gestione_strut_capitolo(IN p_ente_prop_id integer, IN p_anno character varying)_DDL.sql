/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Function: "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying)

-- DROP FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying);

CREATE OR REPLACE FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(IN p_ente_prop_id integer, IN p_anno character varying)
  RETURNS TABLE(bil_anno character varying, titoloe_tipo_code character varying, titoloe_tipo_desc character varying, titoloe_code character varying, titoloe_desc character varying, tipologia_tipo_code character varying, tipologia_tipo_desc character varying, tipologia_code character varying, tipologia_desc character varying, categoria_tipo_code character varying, categoria_tipo_desc character varying, categoria_code character varying, categoria_desc character varying, bil_ele_code character varying, bil_ele_desc character varying, bil_ele_code2 character varying, bil_ele_desc2 character varying, bil_ele_id integer, bil_ele_id_padre integer, stanziamento_prev_cassa_anno numeric, stanziamento_prev_anno numeric, stanziamento_prev_anno1 numeric, stanziamento_prev_anno2 numeric, direz_code character varying, direz_descr character varying, sett_code character varying, sett_descr character varying, codice_conto_finanz character varying, stanziamento_prev_res_anno numeric) AS
$BODY$
DECLARE
classifBilRec record;

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
classif_id_padre integer;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN


annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa

elemTipoCode:='CAP-EG'; -- tipo capitolo Gestione

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
stanziamento_prev_res_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
stanziamento_prev_cassa_anno:=0;

direz_code='';
direz_descr='';
sett_code='';
sett_descr='';
classif_id_padre=0;

select fnc_siac_random_user()
into	user_table;




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
 

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente,
   (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
            	class_upb.classif_tipo_code in('PDC_V' , 'PDC_IV')	and
                --class_upb.classif_tipo_code='CLASSIFICATORE_36' 							and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                e.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	)
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
--and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code in ('VA', 'PR')
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

/* inserisco i capitoli che non hanno una struttura */
insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente,
  (select t_class_upb.classif_code
        	from 
                siac_d_class_tipo	class_upb,
                siac_t_class		t_class_upb,
                siac_r_bil_elem_class r_capitolo_upb
        	where 
            	class_upb.classif_tipo_code in('PDC_V' , 'PDC_IV')	and
                --class_upb.classif_tipo_code='CLASSIFICATORE_36' 							and		
                t_class_upb.classif_tipo_id=class_upb.classif_tipo_id 				and
                t_class_upb.classif_id=r_capitolo_upb.classif_id					AND
                e.elem_id=r_capitolo_upb.elem_id
                and	class_upb.data_cancellazione 			is null
                and t_class_upb.data_cancellazione 			is null
                and r_capitolo_upb.data_cancellazione 			is null	)
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
-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and not EXISTS
(
   select 1 from siac_rep_cap_eg x
   where x.elem_id = e.elem_id
   and x.utente=user_table
);


insert into siac_rep_cap_eg_imp
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
		--and	stato_capitolo.elem_stato_code		=	'VA'
        and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and	cat_del_capitolo.elem_cat_code		=	'STD'
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
        coalesce (tb4.importo,0)   as 		stanziamento_prev_res_anno,
        0,
       -- coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb3,
	siac_rep_cap_eg_imp tb4,
    --, siac_rep_cap_eg_imp tb5, 
    siac_rep_cap_eg_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			--tb4.elem_id	=	tb5.elem_id								and
        			--tb5.elem_id	=	tb6.elem_id								and
                    tb3.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			--tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    

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
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)		stanziamento_prev_res_anno,
    	--COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(tb.pdc,' ') codice_conto_finanz
from  	siac_rep_tit_tip_cat_riga_anni v1
		 join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id 	
                    	and tb1.utente=user_table)
         where 
         	   	COALESCE (tb1.stanziamento_prev_anno,0)			> 0 or
				COALESCE (tb1.stanziamento_prev_anno1,0)		> 0 or
    			COALESCE (tb1.stanziamento_prev_anno2,0)		> 0 or
   	 			COALESCE (tb1.residui_presunti,0)				> 0 or
     			COALESCE (tb1.stanziamento_prev_cassa_anno,0)	> 0       
 union
    select 	
		'Titolo'    			titoloe_TIPO_DESC,
       	NULL              		titoloe_ID,
       	'0'            			titoloe_CODE,
       	' '             	titoloe_DESC,
       	'Tipologia'	  			tipologia_TIPO_DESC,
       	null	              	tipologia_ID,
       	'0000000'            	tipologia_CODE,
       	' '           tipologia_DESC,
       	'Categoria'     		categoria_TIPO_DESC,
      	null	              	categoria_ID,
       	'0000000'            	categoria_CODE,
       	' '           categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
        COALESCE (tb1.residui_presunti,0)			stanziamento_prev_res_anno,        
        COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(tb.pdc,' ') codice_conto_finanz
from  	siac_rep_cap_eg tb
            left	join    siac_rep_cap_ep_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)            
    where  tb.utente = user_table    	
    and tb.ente_proprietario_id=p_ente_prop_id
   and tb.classif_id is null 
   and (
	COALESCE (tb1.stanziamento_prev_anno,0)			> 0 or
	COALESCE (tb1.stanziamento_prev_anno1,0)		> 0 or
    COALESCE (tb1.stanziamento_prev_anno2,0)		> 0 or
   	COALESCE (tb1.residui_presunti,0)				> 0 or
    COALESCE (tb1.stanziamento_prev_cassa_anno,0)	> 0   )    

   		--order by titoloe_CODE,tipologia_CODE,categoria_CODE                    
		--	order by v1.titolo_code,v1.tipologia_code,v1.categoria_code,tb.elem_code::INTEGER,tb.elem_code2::INTEGER            

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
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
--previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;
codice_conto_finanz=classifBilRec.codice_conto_finanz;


IF classifBilRec.BIL_ELE_ID IS NOT NULL THEN
		/* Cerco il settore e prendo anche l'ID dell'elemento padre per cercare poi
        	la direzione */
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
     			sett_code='999';
				sett_descr='SETTORE NON CONFIGURATO';
        
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
                 -- AND d_class_tipo.classif_tipo_desc='Centro di Respondabilità (Direzione)'
                 and d_class_tipo.classif_tipo_code='CDR'
                  and capitolo.elem_id=classifBilRec.BIL_ELE_ID
                   AND r_bil_elem_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL
                   AND capitolo.data_cancellazione is NULL;	
             IF NOT FOUND THEN
             	/* se non esiste la direzione restituisco un codice fittizio */
              direz_code='999';
              direz_descr='DIREZIONE NON CONFIGURATA';         
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
          	direz_code='999';
			direz_descr='DIREZIONE NON CONFIGURATA';  
          END IF;
          END;
        
        END IF;
    END;    

ELSE
		/* se non c'è l'ID capitolo restituisco i campi vuoti */
	direz_code='';
	direz_descr='';
	sett_code='';
	sett_descr='';
END IF;
--direz_code='PPPP';
--sett_code='999';

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
stanziamento_prev_cassa_anno:=0;
stanziamento_prev_res_anno:=0;
direz_code='';
direz_descr='';
sett_code='';
sett_descr='';
classif_id_padre=0;


end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying)
  OWNER TO siac;
GRANT EXECUTE ON FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying) TO public;
GRANT EXECUTE ON FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying) TO siac;
GRANT EXECUTE ON FUNCTION "BILR146_peg_entrate_gestione_strut_capitolo"(integer, character varying) TO siac_rw;
