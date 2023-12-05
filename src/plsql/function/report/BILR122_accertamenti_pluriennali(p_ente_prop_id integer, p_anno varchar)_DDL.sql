/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR122_accertamenti_pluriennali" (
  p_ente_prop_id integer,
  p_anno varchar
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
  categoria_id numeric,
  denom_ente varchar,
  prev_comp_anno1 numeric,
  prev_comp_anno2 numeric,
  prev_comp_anno_succ numeric,
  accertato_anno1 numeric,
  accertato_anno2 numeric,
  accertato_anno_succ numeric
) AS
$body$
DECLARE

classifBilRec record;
AccertamentiRec record;

annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;

v_importo_acc1   NUMERIC :=0;
v_importo_acc2  NUMERIC :=0;
v_importo_acc_succ  NUMERIC :=0;

var_id_elem  integer :=0;
v_fam_titolotipologiacategoria varchar:='00003';

BEGIN

annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
raise notice 'user  %',user_table;
 
bil_anno='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_code='';
tipologia_desc='';
categoria_code='';
categoria_desc='';
bil_ele_id=0;
denom_ente='';
--stanziamento_prev_anno=0;
--cassa_prev_anno=0;
--entrata_gest_sanitaria_anno_stanz=0;
--entrata_gest_sanitaria_anno_cassa=0;
prev_comp_anno1=0;
prev_comp_anno2=0;
prev_comp_anno_succ=0;
accertato_anno1=0;
accertato_anno2=0;
accertato_anno_succ=0; 
     
RTN_MESSAGGIO:='lettura struttura del bilancio''.';  
raise notice '2: %', clock_timestamp()::varchar;  


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
 -- INC000001814415 - elimiare titolo 7 dal report
 and titent.titent_code <> '7'
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;
 
raise notice '3: %', clock_timestamp()::varchar; 
RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

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

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp standard''.';  
raise notice '4: %', clock_timestamp()::varchar; 

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
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo_imp_periodo.anno >= annoCapImp1
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

raise notice '6: %', clock_timestamp()::varchar; 

insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,         
        tb1.importo 	as 		prev_comp_anno1, -- stanziamento_prev_anno,
        tb2.importo 	as		prev_comp_anno2,
        0,
        0,
        0,
        0,  
        tb1.ente_proprietario,      
        user_table utente 
from    siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2
where	tb1.elem_id	=	tb2.elem_id     
and     tb1.periodo_anno = annoCapImp1	
and	    tb1.tipo_imp =	TipoImpComp			
--and	    tb1.tipo_capitolo in ('STD','FSC')
and     tb2.periodo_anno = annoCapImp2 
and	    tb1.tipo_imp =	tb2.tipo_imp 		
--and	    tb2.tipo_capitolo in ('STD','FSC')		   
and 	tb1.utente 	= 	tb2.utente	
and		tb1.utente	=	user_table;

raise notice '7: %', clock_timestamp()::varchar; 
 
-- Gestione accertamwenti
for AccertamentiRec in
  select tb2.elem_id,
  tb.movgest_anno,
  p_ente_prop_id,
  user_table utente,
  tb.importo
  from (select    
  m.movgest_anno::VARCHAR, 
  e.elem_id,
  sum (tsd.movgest_ts_det_importo) importo
      from 
          siac_t_bil b, 
          siac_t_periodo p, 
          siac_t_bil_elem e,
          siac_d_bil_elem_tipo et,
          siac_r_movgest_bil_elem rm, 
          siac_t_movgest m,
          siac_d_movgest_tipo mt,
          siac_t_movgest_ts ts  ,
          siac_d_movgest_ts_tipo   tsti, 
          siac_r_movgest_ts_stato tsrs,
          siac_d_movgest_stato mst, 
          siac_t_movgest_ts_det   tsd ,
          siac_d_movgest_ts_det_tipo  tsdt
        where 
        b.periodo_id					=	p.periodo_id 
        and p.ente_proprietario_id   	= 	p_ente_prop_id
        and p.anno          			=   p_anno 
        and b.bil_id 					= 	e.bil_id
        and e.elem_tipo_id			=	et.elem_tipo_id
        and et.elem_tipo_code      	=  	elemTipoCode
        and rm.elem_id      			= 	e.elem_id
        and rm.movgest_id      		=  	m.movgest_id 
        and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
        --and m.movgest_anno::VARCHAR   			 in (annoCapImp, annoCapImp1, annoCapImp2)
        and m.movgest_anno::VARCHAR   	>= annoCapImp1
        and m.movgest_tipo_id			= 	mt.movgest_tipo_id 
        and mt.movgest_tipo_code		='A' 
        and m.movgest_id				=	ts.movgest_id
        and ts.movgest_ts_id			=	tsrs.movgest_ts_id 
        and tsrs.movgest_stato_id  	= 	mst.movgest_stato_id 
        and tsti.movgest_ts_tipo_code  = 'T' 
        and mst.movgest_stato_code   in ('D','N') -- Definitivo e definitivo non liquidabile
        and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
        and ts.movgest_ts_tipo_id  	= 	tsti.movgest_ts_tipo_id 
        and ts.movgest_ts_id     		= 	tsd.movgest_ts_id 
        and tsd.movgest_ts_det_tipo_id  = tsdt.movgest_ts_det_tipo_id 
        and tsdt.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and now() between b.validita_inizio and coalesce (b.validita_fine, now())
        and now() between p.validita_inizio and coalesce (p.validita_fine, now())
        and now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and now() between et.validita_inizio and coalesce (et.validita_fine, now())
        and now() between m.validita_inizio and coalesce (m.validita_fine, now())
        and now() between ts.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between mt.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between tsti.validita_inizio and coalesce (tsti.validita_fine, now())
        and now() between mst.validita_inizio and coalesce (mst.validita_fine, now())
        and now() between tsd.validita_inizio and coalesce (tsd.validita_fine, now())
        and now() between tsdt.validita_inizio and coalesce (tsdt.validita_fine, now())
        and p.data_cancellazione     	is null 
        and b.data_cancellazione      is null 
        and e.data_cancellazione      is null     
        and et.data_cancellazione     is null 
        and rm.data_cancellazione 	is null 
        and m.data_cancellazione      is null 
        and mt.data_cancellazione     is null 
        and ts.data_cancellazione   	is null 
        and tsti.data_cancellazione   is null 
        and tsrs.data_cancellazione   is null 
        and mst.data_cancellazione    is null 
        and tsd.data_cancellazione   	is null 
        and tsdt.data_cancellazione   is null      
  group by m.movgest_anno, e.elem_id )
  tb 
  ,
  (select * from  siac_t_bil_elem    			capitolo_ug,
                  siac_d_bil_elem_tipo    	t_capitolo_ug
        where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
        and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
  where
   tb2.elem_id	=	tb.elem_id
   
  LOOP
    
    v_importo_acc_succ  :=0;
    v_importo_acc1 :=0;
    v_importo_acc2 :=0;
    
           
    var_id_elem := 0;  
   
-- nella tabella SIAC_REP_ACCERTAMENTI_RIGA sono inseriti i dati degli
-- accertamenti per capitolo.
  
    SELECT rep_acc_riga.elem_id
    INTO var_id_elem
    FROM SIAC_REP_ACCERTAMENTI_RIGA rep_acc_riga
    WHERE rep_acc_riga.elem_id=AccertamentiRec.elem_id;
   
    IF var_id_elem IS NULL OR var_id_elem = 0 THEN
           -- il record per il capitolo non e' ancora stato inserito,
           -- viene fatta una INSERT.
           
        IF AccertamentiRec.movgest_anno = annoCapImp1 THEN
           v_importo_acc1 := AccertamentiRec.importo;
        ELSIF AccertamentiRec.movgest_anno = annoCapImp2 THEN
           v_importo_acc2 := AccertamentiRec.importo;
        ELSIF AccertamentiRec.movgest_anno > annoCapImp2 THEN  
           v_importo_acc_succ := AccertamentiRec.importo;
        END IF;     
             
          INSERT INTO SIAC_REP_ACCERTAMENTI_RIGA
              (elem_id,
               accertato_anno,
               accertato_anno1,
               accertato_anno2,
               ente_proprietario,
               utente)
          VALUES
              (AccertamentiRec.elem_id,
               v_importo_acc1,
               v_importo_acc2,
               v_importo_acc_succ,
               p_ente_prop_id,
               AccertamentiRec.utente
              );   
    
    ELSE -- capitolo gia' esistente: e' fatto un UPDATE.
  
        IF AccertamentiRec.movgest_anno = annoCapImp1 THEN
           v_importo_acc1 := AccertamentiRec.importo;
                                                     
            UPDATE 
              siac.siac_rep_accertamenti_riga 
            SET 
-- 11/06/2020  SIAC-7671.
-- l'importo deve essere aggiornato tenendo conto del valore gia' esistente
-- in tabella, in quanto un capitolo potrebbe avere piu' accertamenti e
-- l'importo deve essere la somma di tutti questi.                
              --accertato_anno = v_importo_acc1
              accertato_anno = siac_rep_accertamenti_riga.accertato_anno +
              	v_importo_acc1
            WHERE 
                elem_id = AccertamentiRec.elem_id AND
                ente_proprietario = p_ente_prop_id AND
 				utente = AccertamentiRec.utente;
                       
        ELSIF AccertamentiRec.movgest_anno = annoCapImp2 THEN
           v_importo_acc2 := AccertamentiRec.importo;
           
            UPDATE 
              siac.siac_rep_accertamenti_riga 
            SET 
              --accertato_anno1 = v_importo_acc2
              accertato_anno1 = siac_rep_accertamenti_riga.accertato_anno1 + 
              		v_importo_acc2
            WHERE 
                elem_id = AccertamentiRec.elem_id AND
                ente_proprietario = p_ente_prop_id AND
 				utente = AccertamentiRec.utente;
                      
        ELSIF AccertamentiRec.movgest_anno > annoCapImp2 THEN  
           v_importo_acc_succ := AccertamentiRec.importo;
           
            UPDATE 
              siac.siac_rep_accertamenti_riga 
            SET 
              --accertato_anno2 = v_importo_acc_succ
              accertato_anno2 = siac_rep_accertamenti_riga.accertato_anno2 + 
              		v_importo_acc_succ
            WHERE 
                elem_id = AccertamentiRec.elem_id AND
                ente_proprietario = p_ente_prop_id AND
 				utente = AccertamentiRec.utente;           
           
        END IF;    
    
    END IF;
            
  
  
  
  
    
    /*
    IF AccertamentiRec.movgest_anno = annoCapImp1 THEN
       v_importo_acc1 := AccertamentiRec.importo;
    ELSIF AccertamentiRec.movgest_anno = annoCapImp2 THEN
       v_importo_acc2 := AccertamentiRec.importo;
    ELSIF AccertamentiRec.movgest_anno > annoCapImp2 THEN  
       v_importo_acc_succ := AccertamentiRec.importo;
    END IF;     
       
        
    INSERT INTO SIAC_REP_ACCERTAMENTI_RIGA
    	(elem_id,
  		 accertato_anno,
         accertato_anno1,
         accertato_anno2,
         ente_proprietario,
         utente)
    VALUES
        (AccertamentiRec.elem_id,
         v_importo_acc1,
         v_importo_acc2,
         v_importo_acc_succ,
         p_ente_prop_id,
         AccertamentiRec.utente
        );     
  */
  END LOOP; 
   
 RTN_MESSAGGIO:='preparazione file output''.'; 
 
FOR classifBilRec IN
SELECT 	t_ente_prop.ente_denominazione	denom_ente,
		v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
       	tb.elem_id   					bil_ele_id,
        COALESCE(tb4.stanziamento_prev_anno,0)	  prev_comp_anno1,
        COALESCE(tb4.stanziamento_prev_anno1,0)	  prev_comp_anno2,
        --COALESCE(tb4.stanziamento_prev_anno2,0)	  prev_comp_anno_succ,
        COALESCE(tb5.accertato_anno,0) accertato_anno1,
        COALESCE(tb5.accertato_anno1,0) accertato_anno2,
        COALESCE(tb5.accertato_anno2,0) accertato_anno_succ
FROM  	siac_t_ente_proprietario t_ente_prop, siac_rep_tit_tip_cat_riga_anni v1
LEFT JOIN siac_rep_cap_ep tb ON ( v1.categoria_id = tb.classif_id
                                  AND v1.ente_proprietario_id = p_ente_prop_id
					              AND tb.utente = v1.utente
                                  AND v1.utente = user_table)	
LEFT JOIN  siac_rep_cap_ep_imp_riga tb4 ON tb4.elem_id = tb.elem_id
                                        AND tb.utente=user_table
                                        AND tb4.utente = tb.utente
LEFT JOIN  siac_rep_accertamenti_riga tb5 ON tb5.elem_id = tb.elem_id 
                                          AND tb.utente=user_table
                                          AND tb5.utente = tb.utente 	
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
--stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
--cassa_prev_anno=classifBilRec.cassa_prev_anno;
--entrata_gest_sanitaria_anno_stanz=classifBilRec.entrata_gest_sanit_comp_anno;
--entrata_gest_sanitaria_anno_cassa=classifBilRec.entrata_gest_sanit_cassa_anno;

denom_ente=classifBilRec.denom_ente;

prev_comp_anno1:=classifBilRec.prev_comp_anno1;
prev_comp_anno2:=classifBilRec.prev_comp_anno2;
--prev_comp_anno_succ:=classifBilRec.prev_comp_anno_succ;
--prev_fpv_anno_succ:=classifBilRec.prev_fpv_anno_succ;
accertato_anno1:=classifBilRec.accertato_anno1;
accertato_anno2:=classifBilRec.accertato_anno2;
accertato_anno_succ=classifBilRec.accertato_anno_succ;

	return next;
    bil_anno='';
    titoloe_CODE='';
    titoloe_DESC='';
    tipologia_code='';
    tipologia_desc='';
    categoria_code='';
    categoria_desc='';
    bil_ele_id=0;
    --stanziamento_prev_anno=0;
    --cassa_prev_anno=0;
    --entrata_gest_sanitaria_anno_stanz=0;
    --entrata_gest_sanitaria_anno_cassa=0;
    denom_ente='';

    prev_comp_anno1=0;
    prev_comp_anno2=0;
    prev_comp_anno_succ=0;
    accertato_anno1=0;
    accertato_anno2=0;
    accertato_anno_succ=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni		where utente=user_table;
delete from siac_rep_cap_ep 					where utente=user_table;
delete from siac_rep_cap_ep_imp 				where utente=user_table;
delete from siac_rep_cap_ep_imp_riga 			where utente=user_table;
delete from siac_rep_accertamenti_riga  		where utente=user_table;

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