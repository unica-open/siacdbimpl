/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR155_struttura_dca_entrate" (
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
  code_transaz_ue varchar,
  pdc_iv varchar,
  perim_sanitario_entrata varchar,
  ord_id integer,
  ord_importo numeric,
  movgest_id integer,
  anno_movgest integer,
  movgest_importo numeric,
  ricorrente_entrata varchar
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
bilancio_id integer;


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

code_transaz_ue:='';
pdc_iv:='';
perim_sanitario_entrata:='';
ricorrente_entrata:='';

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;


RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL BILANCIO';

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

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
elenco_movgest as (
select distinct
r.elem_id, a.movgest_id,b.movgest_ts_id,
a.movgest_anno,
coalesce(o.movgest_ts_det_importo,0) movgest_importo
 from  siac_t_movgest a, 
 	siac_t_movgest_ts b,  
 	siac_t_movgest_ts_det o,
	siac_d_movgest_ts_det_tipo p,
    siac_d_movgest_tipo q,
    siac_r_movgest_bil_elem r ,
    siac_r_movgest_ts_stato s,
    siac_d_movgest_stato t,
    siac_d_movgest_ts_tipo u
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bilancio_id
and b.movgest_id=a.movgest_id
and o.movgest_ts_id=b.movgest_ts_id
and p.movgest_ts_det_tipo_id=o.movgest_ts_det_tipo_id
and q.movgest_tipo_id=a.movgest_tipo_id
and r.movgest_id=a.movgest_id
and s.movgest_ts_id=b.movgest_ts_id
and t.movgest_stato_id=s.movgest_stato_id
and u.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and q.movgest_tipo_code='A' --Accertamenti
and p.movgest_ts_det_tipo_code='A' -- importo attuale
and t.movgest_stato_code in ('D','N') 
and u.movgest_ts_tipo_code='T' 
and	a.movgest_anno	<=	annoCapImp_int	
and a.data_cancellazione is null
and b.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null
and s.data_cancellazione is null
and t.data_cancellazione is null
and u.data_cancellazione is null
and s.validita_fine is NULL
and r.validita_fine is null
),
elenco_ord as (
select 		r_capitolo_ordinativo.elem_id,
			ordinativo.ord_id,
            movimento.movgest_id,
            movimento.movgest_anno,            
            sum(coalesce(ordinativo_imp.ord_ts_det_importo,0)) ord_importo
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
        --and	movimento.movgest_anno				<=	annoCapImp_int	
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
        and r_capitolo_ordinativo.validita_fine         is null
        and r_stato_ordinativo.validita_fine            is null
        and r_ordinativo_movgest.validita_fine          is null
        group by r_capitolo_ordinativo.elem_id,
			ordinativo.ord_id,
            movimento.movgest_id,
            movimento.movgest_anno      
),
elenco_class_capitoli as (
	select * from "fnc_bilr153_tab_class_capitoli"  (p_ente_prop_id)),
elenco_class_movgest as (
	select * from "fnc_bilr153_tab_class_movgest"  (p_ente_prop_id)),
elenco_class_ord as (
	select * from "fnc_bilr153_tab_class_ord"  (p_ente_prop_id)) ,
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
          t_class.classif_code classif_code_cap,
  substring(t_class.classif_code from 1 for length(t_class.classif_code)-3) ||
          '000' pdc_v
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
    CASE WHEN COALESCE(elenco_class_capitoli.code_transaz_ue_entrata,'') = ''
    	THEN CASE WHEN COALESCE(elenco_class_movgest.code_transaz_ue_entrata,'') = ''
    			THEN COALESCE(elenco_class_ord.code_transaz_ue_entrata,'')::varchar
        		ELSE elenco_class_movgest.code_transaz_ue_entrata::varchar 
                END
        ELSE elenco_class_capitoli.code_transaz_ue_entrata::varchar  end code_transaz_ue, 	
    /*CASE WHEN  trim(COALESCE(elenco_pdci_IV.pdc_iv,'')) = ''
    THEN elenco_pdci_V.pdc_v ::varchar 
    ELSE elenco_pdci_IV.pdc_iv ::varchar end pdc_iv,*/
    CASE WHEN  trim(COALESCE(elenco_class_movgest.pdc_v,'')) = ''
        THEN elenco_pdci_IV.pdc_iv ::varchar 
        ELSE elenco_class_movgest.pdc_v ::varchar end pdc_iv,
    CASE WHEN COALESCE(elenco_class_capitoli.perim_sanitario_entrata,'') = ''
           OR COALESCE(elenco_class_capitoli.perim_sanitario_entrata,'') = 'XX'    
    	THEN 
            CASE WHEN COALESCE(elenco_class_movgest.perim_sanitario_entrata,'') = ''
                    OR COALESCE(elenco_class_movgest.perim_sanitario_entrata,'') = 'XX'
    			 THEN 
                     CASE WHEN COALESCE(elenco_class_ord.perim_sanitario_entrata,'') <> 'XX'
                     then 
                          COALESCE(elenco_class_ord.perim_sanitario_entrata,'')::varchar
                 ELSE '' END      
        ELSE elenco_class_movgest.perim_sanitario_entrata::varchar  END
    ELSE elenco_class_capitoli.perim_sanitario_entrata::varchar  end perim_sanitario_entrata, 
    COALESCE(elenco_ord.ord_id,0)::integer ord_id,
    COALESCE(elenco_ord.ord_importo,0)::numeric ord_importo ,
  	COALESCE(elenco_movgest.movgest_id,0)::integer movgest_id ,
  	COALESCE(elenco_movgest.movgest_anno,0)::integer anno_movgest ,
  	COALESCE(elenco_movgest.movgest_importo,0)::numeric movgest_importo,
    -- 07/08/2017: aggiunto campo ricorrente_entrata
    CASE WHEN COALESCE(elenco_class_capitoli.ricorrente_entrata,'') = ''   
    	THEN 
            CASE WHEN COALESCE(elenco_class_movgest.ricorrente_entrata,'') = ''
    			 THEN COALESCE(elenco_class_ord.perim_sanitario_entrata,'')::varchar                                
        		 ELSE elenco_class_movgest.ricorrente_entrata::varchar END
        ELSE elenco_class_movgest.ricorrente_entrata::varchar  END ricorrente_entrata
	from capitoli  
      left join classif on classif.categoria_id = capitoli.classif_id  
      full join elenco_movgest on elenco_movgest.elem_id =capitoli.elem_id
      left join elenco_ord on elenco_ord.movgest_id=elenco_movgest.movgest_id    
      left join elenco_class_movgest on elenco_class_movgest.movgest_id=elenco_movgest.movgest_id
  	  left join elenco_class_ord on elenco_class_ord.ord_id=elenco_ord.ord_id   
      left join elenco_pdci_IV on elenco_pdci_IV.elem_id=capitoli.elem_id 
  	  left join elenco_pdci_V on elenco_pdci_V.elem_id=capitoli.elem_id
      left join elenco_class_capitoli on elenco_class_capitoli.elem_id =capitoli.elem_id      
    where --elenco_movgest.movgest_id is not null 
          capitoli.elem_id is not null
          and (coalesce(elenco_ord.ord_importo,0) > 0 or
          (coalesce(elenco_movgest.movgest_importo,0)> 0 and coalesce(elenco_movgest.movgest_anno,0)=p_anno::integer))             
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