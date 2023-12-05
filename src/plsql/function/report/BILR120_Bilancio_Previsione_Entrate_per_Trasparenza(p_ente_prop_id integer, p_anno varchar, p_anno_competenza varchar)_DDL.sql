/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR120_Bilancio_Previsione_Entrate_per_Trasparenza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_id integer,
  stanziamento_prev_anno numeric,
  cassa_prev_anno numeric,
  entrata_gest_sanitaria_anno_stanz numeric,
  entrata_gest_sanitaria_anno_cassa numeric,
  categoria_id numeric,
  denom_ente varchar
) AS
$body$
DECLARE
classifBilRec record;



annoCapImp varchar;
tipoImpComp varchar;
TipoImpstanzresidui varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno_competenza;   

TipoImpComp='STA';  -- competenza
TipoImpresidui='SRI'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa

elemTipoCode:='CAP-EP';

bil_anno='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_code='';
tipologia_desc='';
categoria_code='';
categoria_desc='';
bil_ele_id=0;

stanziamento_prev_anno=0;
cassa_prev_anno=0;
entrata_gest_sanitaria_anno_stanz=0;
entrata_gest_sanitaria_anno_cassa=0;
denom_ente='';

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
where ct.classif_tipo_code='CATEGORIA'
and ct.classif_tipo_id=cl.classif_tipo_id
and cl.classif_id=rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno= p_anno
and bilancio.periodo_id=anno_eserc.periodo_id 
and e.bil_id=bilancio.bil_id 
and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code = elemTipoCode
and e.elem_id=rc.elem_id 
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
and	cat_del_capitolo.data_cancellazione	is null;


insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det 			capitolo_importi,
         	siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
         	siac_t_periodo 					capitolo_imp_periodo,
            siac_t_bil_elem 				capitolo,
            siac_d_bil_elem_tipo 			tipo_elemento,
            siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
			siac_d_bil_elem_stato 			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
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
 	group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	--tb2.importo 	as		stanziamento_prev_anno1,
    	--tb3.importo		as		stanziamento_prev_anno2,
        0, 0,
   	 	tb4.importo		as		residui_presunti,
    	tb5.importo		as		previsioni_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1,-- siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb4.elem_id								and	
        			--tb2.elem_id	=	tb3.elem_id								and
        			--tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp		AND	tb1.tipo_imp =	TipoImpComp	AND
        			--tb2.periodo_anno = annoCapImp1		AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			--tb3.periodo_anno = annoCapImp2		AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa
                    and tb1.utente 	= 	tb4.utente	
        			--and	tb2.utente	=	tb3.utente
        			--and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;                 


insert into siac_rep_ep_imp_gest_sanit
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det 			capitolo_importi,
         	siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
         	siac_t_periodo 					capitolo_imp_periodo,
            siac_t_bil_elem 				capitolo,
            siac_d_bil_elem_tipo 			tipo_elemento,
            siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc,
            siac_d_bil_elem_stato 			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno= p_anno 												
    	and	bilancio.periodo_id=anno_eserc.periodo_id 								
        and	capitolo.bil_id=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_importi.elem_id     in
        (select r_class.elem_id   
        from  	siac_r_bil_elem_class	r_class,
				siac_t_class 			b,
        		siac_d_class_tipo 		c
		where 	b.classif_id 		= 	r_class.classif_id
		and 	b.classif_tipo_id 	= 	c.classif_tipo_id
		and 	c.classif_tipo_code  = 'PERIMETRO_SANITARIO_ENTRATA'
       -- and		b.classif_desc	=	'Ricorrente'
        and	r_class.data_cancellazione				is null
        and	b.data_cancellazione					is null
        and c.data_cancellazione					is null
        --12/07/2021 SIAC-8285
        --Occorre prendere solo i capitolo che per l'attributo
        --PERIMETRO_SANITARIO_ENTRATA hanno il valore '2'.
        --and b.classif_code <> 'XX')
        and b.classif_code ='2')
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
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_ep_imp_gest_sanit_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		entrata_gest_sanit_comp_anno,
        0, 0,
    	tb2.importo 	as		entrata_gest_sanit_cassa_anno,
        0, 0,
    	tb3.importo		as		entrata_gest_sanit_resid_anno,
        0, 0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_ep_imp_gest_sanit tb1, siac_rep_ep_imp_gest_sanit tb2, siac_rep_ep_imp_gest_sanit tb3
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp		AND
        			tb2.periodo_anno = annoCapImp	AND	tb2.tipo_imp =	TipoImpCassa	AND
        			tb3.periodo_anno = annoCapImp	AND	tb3.tipo_imp =	TipoImpstanzresidui
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	user_table;
    

for classifBilRec in
select 	t_ente_prop.ente_denominazione	denom_ente,
		v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
       	tb.elem_id   					bil_ele_id,
       	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
        COALESCE (tb1.stanziamento_prev_cassa_anno,0) cassa_prev_anno,
		--COALESCE (tb1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
    	--COALESCE (tb1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
        COALESCE (tb2.entrata_gest_sanit_comp_anno,0)	entrata_gest_sanit_comp_anno,
		COALESCE (tb2.entrata_gest_sanit_cassa_anno,0)	entrata_gest_sanit_cassa_anno
from	 siac_t_ente_proprietario t_ente_prop,
		 siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					-----and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 	
            	and	tb.utente=user_table
                and tb1.utente	=	tb.utente)
            left 	join	siac_rep_ep_imp_gest_sanit_riga	tb2	
            on	(tb2.elem_id	=	tb.elem_id
            		and	tb1.utente=user_table
                    and tb1.utente	=	tb2.utente)
    where t_ente_prop.ente_proprietario_id= v1.ente_proprietario_id
    	and v1.utente = user_table 	
        and t_ente_prop.data_cancellazione IS NULL
			order by titoloe_CODE,tipologia_CODE,categoria_CODE                  
loop
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
categoria_id := classifBilRec.categoria_id;
bil_ele_id := classifBilRec.bil_ele_id;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
cassa_prev_anno=classifBilRec.cassa_prev_anno;
entrata_gest_sanitaria_anno_stanz=classifBilRec.entrata_gest_sanit_comp_anno;
entrata_gest_sanitaria_anno_cassa=classifBilRec.entrata_gest_sanit_cassa_anno;

denom_ente=classifBilRec.denom_ente;

return next;

bil_anno='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_code='';
tipologia_desc='';
categoria_code='';
categoria_desc='';
bil_ele_id=0;
stanziamento_prev_anno=0;
cassa_prev_anno=0;
entrata_gest_sanitaria_anno_stanz=0;
entrata_gest_sanitaria_anno_cassa=0;
denom_ente='';

end loop;

raise notice 'fine OK';

delete from siac_rep_tit_tip_cat_riga_anni		where utente=user_table;
delete from siac_rep_cap_ep 					where utente=user_table;
delete from siac_rep_cap_ep_imp 				where utente=user_table;
delete from siac_rep_cap_ep_imp_riga 			where utente=user_table;
delete from siac_rep_ep_imp_gest_sanit 			where utente=user_table;
delete from siac_rep_ep_imp_gest_sanit_riga 	where utente=user_table;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RTN_MESSAGGIO:='struttura bilancio altro errore';
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;