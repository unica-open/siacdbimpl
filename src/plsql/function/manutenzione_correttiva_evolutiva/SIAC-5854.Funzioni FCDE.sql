/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5854 Integrazione INIZIO
CREATE OR REPLACE FUNCTION siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons" (
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
  residui_attivi numeric,
  residui_attivi_prec numeric,
  totale_residui_attivi numeric,
  importo_minimo_fondo numeric,
  bil_ele_code3 varchar,
  flag_cassa integer,
  accertamenti_succ numeric,
  crediti_stralciati numeric,
  fondo_dubbia_esig numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

if tipomedia is null then
   tipomedia = 'SEMPLICE';
end if;

return query
select zz.* from (
with clas as (
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
and d.classif_fam_code = '00003'
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
and d.classif_fam_code = '00003'
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
and d.classif_fam_code = '00003'
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
where titent.titent_id=tipologia.titent_id
and tipologia.tipologia_id=categoria.tipologia_id
),
capall as (
with
cap as (
select
a.elem_id,
a.elem_code,
a.elem_desc,
a.elem_code2,
a.elem_desc2,
a.elem_id_padre,
a.elem_code3,
d.classif_id
from siac_t_bil_elem a,	
     siac_d_bil_elem_tipo b,
     siac_r_bil_elem_class c,
 	 siac_t_class d,	
     siac_d_class_tipo e,
	 siac_r_bil_elem_categoria f,	
     siac_d_bil_elem_categoria g, 
     siac_r_bil_elem_stato h, 
     siac_d_bil_elem_stato i 
where a.ente_proprietario_id = p_ente_prop_id
and   a.bil_id               = bilancio_id
and   a.elem_tipo_id		 = b.elem_tipo_id 
and   b.elem_tipo_code 	     = 'CAP-EG'
and   c.elem_id              = a.elem_id
and   d.classif_id           = c.classif_id
and   e.classif_tipo_id      = d.classif_tipo_id
and   e.classif_tipo_code	 = 'CATEGORIA'
and   g.elem_cat_id          = f.elem_cat_id
and   f.elem_id              = a.elem_id
and	  g.elem_cat_code	     = 'STD'
and   h.elem_id              = a.elem_id
and   i.elem_stato_id        = h.elem_stato_id
and	  i.elem_stato_code	     = 'VA'
and   a.data_cancellazione   is null
and	  b.data_cancellazione   is null
and	  c.data_cancellazione	 is null
and	  d.data_cancellazione	 is null
and	  e.data_cancellazione 	 is null
and	  f.data_cancellazione 	 is null
and	  g.data_cancellazione	 is null
and	  h.data_cancellazione   is null
and	  i.data_cancellazione   is null
), 
resatt as ( -- Residui Attivi 
select capitolo.elem_id,
       sum (dt_movimento.movgest_ts_det_importo) residui_accertamenti,
       CASE 
         WHEN movimento.movgest_anno < annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'I' THEN
            'RESATT' 
         WHEN movimento.movgest_anno = annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' THEN  
            'ACCERT' 
         ELSE
            'ALTRO'
       END tipo_importo         
from siac_t_bil_elem                  capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id 
inner join siac_d_movgest_tipo        tipo_mov on movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id 
inner join siac_r_movgest_ts_stato    r_movimento_stato on ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
inner join siac_d_movgest_stato       tipo_stato on r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id
inner join siac_t_movgest_ts_det      dt_movimento on ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
inner join siac_d_movgest_ts_tipo     ts_mov_tipo on ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id
inner join siac_d_movgest_ts_det_tipo dt_mov_tipo on dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
where capitolo.ente_proprietario_id     =   p_ente_prop_id
and   capitolo.bil_id      				=	bilancio_id
and   t_capitolo.elem_tipo_code    		= 	'CAP-EG'
and   movimento.movgest_anno 	        <= 	annoCapImp_int
and   movimento.bil_id					=	bilancio_id
and   tipo_mov.movgest_tipo_code    	=   'A' 
and   tipo_stato.movgest_stato_code     in  ('D','N')
and   ts_mov_tipo.movgest_ts_tipo_code  =   'T'
and   dt_mov_tipo.movgest_ts_det_tipo_code in ('I','A')
and   capitolo.data_cancellazione     	is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione    	is null 
and   movimento.data_cancellazione     	is null 
and   tipo_mov.data_cancellazione     	is null 
and   r_movimento_stato.data_cancellazione is null 
and   ts_movimento.data_cancellazione   is null 
and   tipo_stato.data_cancellazione    	is null 
and   dt_movimento.data_cancellazione   is null 
and   ts_mov_tipo.data_cancellazione    is null 
and   dt_mov_tipo.data_cancellazione    is null
and   now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and   now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
group by tipo_importo, capitolo.elem_id
),
resrisc as ( -- Riscossione residui
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_residui,
            CASE 
             WHEN movimento.movgest_anno < annoCapImp_int THEN
                'RISRES'
             ELSE
                'RISCOMP'
             END tipo_importo                    
from  --siac_t_bil 						bilancio,
      --siac_t_periodo 					anno_eserc, 
      siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
      siac_t_ordinativo				    ordinativo,
      siac_d_ordinativo_tipo			tipo_ordinativo,
      siac_r_ordinativo_stato			r_stato_ordinativo,
      siac_d_ordinativo_stato			stato_ordinativo,
      siac_t_ordinativo_ts 			    ordinativo_det,
      siac_t_ordinativo_ts_det 		    ordinativo_imp,
      siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
      siac_t_movgest     				movimento,
      siac_t_movgest_ts    			    ts_movimento, 
      siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
where 	--anno_eserc.anno					= 	p_anno											
--and	bilancio.periodo_id					=	anno_eserc.periodo_id
--and	bilancio.ente_proprietario_id	    =	p_ente_prop_id
ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
------------------------------------------------------------------------------------------		
----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
-----------------------------------------------------------------------------------------------
--and	ordinativo.bil_id					=	bilancio.bil_id
and	ordinativo.bil_id					=	bilancio_id
and	ordinativo.ord_id					=	ordinativo_det.ord_id
and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
---------------------------------------------------------------------------------------------------------------------
and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
and	ts_movimento.movgest_id				=	movimento.movgest_id
and	movimento.movgest_anno				<=	annoCapImp_int	
--and movimento.bil_id					=	bilancio.bil_id	
and movimento.bil_id					=	bilancio_id	
--------------------------------------------------------------------------------------------------------------------		
--and	bilancio.data_cancellazione 				is null
--and	anno_eserc.data_cancellazione 				is null
and	r_capitolo_ordinativo.data_cancellazione	is null
and	ordinativo.data_cancellazione				is null
and	tipo_ordinativo.data_cancellazione			is null
and	r_stato_ordinativo.data_cancellazione		is null
and	stato_ordinativo.data_cancellazione			is null
and ordinativo_det.data_cancellazione			is null
and ordinativo_imp.data_cancellazione			is null
and ordinativo_imp_tipo.data_cancellazione		is null
and	movimento.data_cancellazione				is null
and	ts_movimento.data_cancellazione				is null
and	r_ordinativo_movgest.data_cancellazione		is null
and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())
group by tipo_importo, r_capitolo_ordinativo.elem_id
),
resriacc as ( -- Riaccertamenti residui
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riaccertamenti_residui
from --siac_t_bil      bilancio, 
     --siac_t_periodo     anno_eserc, 
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
     siac_t_modifica t_modifica,
     siac_r_modifica_stato r_mod_stato,
     siac_d_modifica_stato d_mod_stato,
     siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
     where --bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
     --and anno_eserc.anno       			=   p_anno
     --and bilancio.bil_id      				=	capitolo.bil_id
     capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	< 	annoCapImp_int
     --and movimento.bil_id					=	bilancio.bil_id
     and movimento.bil_id					=	bilancio_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
     and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
     and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
     and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
     and d_mod_stato.mod_stato_code='V'
     and r_mod_stato.mod_id=t_modifica.mod_id
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
     --and anno_eserc.data_cancellazione    	is null 
     --and bilancio.data_cancellazione     	is null 
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
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     group by capitolo.elem_id	
),
minfondo as ( -- Importo minimo del fondo
SELECT
 rbilelem.elem_id, 
 CASE 
   WHEN tipomedia = 'SEMPLICE' THEN
        round((COALESCE(datifcd.perc_acc_fondi,0)+
        COALESCE(datifcd.perc_acc_fondi_1,0)+
        COALESCE(datifcd.perc_acc_fondi_2,0)+
        COALESCE(datifcd.perc_acc_fondi_3,0)+
        COALESCE(datifcd.perc_acc_fondi_4,0))/5,2)
   ELSE
        round((COALESCE(datifcd.perc_acc_fondi,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_1,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_2,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_3,0)*0.35+
        COALESCE(datifcd.perc_acc_fondi_4,0)*0.35),2)
 END perc_media
 -- ,1 flag_cassa -- SIAC-5854
 , 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
 WHERE rbilelem.acc_fde_id = datifcd.acc_fde_id 
 AND   datifcd.ente_proprietario_id = p_ente_prop_id 
 AND   rbilelem.data_cancellazione is null
),
accertcassa as ( -- Accertato per cassa -- SIAC-5854
SELECT rbea.elem_id, 0 flag_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.data_cancellazione is null
AND    ta.data_cancellazione is null
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S'
),
acc_succ as ( -- Accertamenti imputati agli esercizi successivi a quello cui il rendiconto si riferisce
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
from --siac_t_bil      bilancio, 
     --siac_t_periodo     anno_eserc, 
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
     siac_t_modifica t_modifica,
     siac_r_modifica_stato r_mod_stato,
     siac_d_modifica_stato d_mod_stato,
     siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
     siac_r_movgest_ts_attr r_movgest_ts_attr,
     siac_t_attr t_attr 
     where --bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
     --and anno_eserc.anno       			=   p_anno
     --and bilancio.bil_id      				=	capitolo.bil_id
     capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int
     --and movimento.bil_id					=	bilancio.bil_id
     and movimento.bil_id					=	bilancio_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
     and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
     and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
     and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
     and d_mod_stato.mod_stato_code='V'
     and r_mod_stato.mod_id=t_modifica.mod_id
     and r_movgest_ts_attr.movgest_ts_id = ts_movimento.movgest_ts_id
     and r_movgest_ts_attr.attr_id = t_attr.attr_id
     and t_attr.attr_code = 'annoOriginePlur'
     and r_movgest_ts_attr.testo <= p_anno
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
     --and anno_eserc.data_cancellazione    	is null 
     --and bilancio.data_cancellazione     	is null 
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
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     group by capitolo.elem_id	
),
cred_stra as ( -- Crediti stralciati
 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
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
      siac_t_modifica t_modifica,
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where bilancio.periodo_id    		 	= 	anno_eserc.periodo_id 
      and anno_eserc.anno       			=   p_anno
      and bilancio.bil_id      				=	capitolo.bil_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and t_capitolo.elem_tipo_code    		= 	'CAP_EG'
      and movimento.movgest_anno 	        < 	annoCapImp_int
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
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
      and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) 
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
group by capitolo.elem_id
)
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.classif_id categoria_id,
coalesce(resatt1.residui_accertamenti,0) residui_attivi,
(coalesce(resatt1.residui_accertamenti,0) -
coalesce(resrisc1.importo_residui,0) +
coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
(coalesce(resatt2.residui_accertamenti,0) -
 coalesce(resrisc2.importo_residui,0)) importo_finale
from cap
left join resatt resatt1
on cap.elem_id=resatt1.elem_id and resatt1.tipo_importo = 'RESATT'
left join resatt resatt2
on cap.elem_id=resatt2.elem_id and resatt2.tipo_importo = 'ACCERT'
left join resrisc resrisc1
on cap.elem_id=resrisc1.elem_id and resrisc1.tipo_importo = 'RISRES'
left join resrisc resrisc2
on cap.elem_id=resrisc2.elem_id and resrisc2.tipo_importo = 'RISCOMP'
left join resriacc
on cap.elem_id=resriacc.elem_id
left join minfondo
on cap.elem_id=minfondo.elem_id
left join accertcassa
on cap.elem_id=accertcassa.elem_id
left join acc_succ
on cap.elem_id=acc_succ.elem_id
left join cred_stra
on cap.elem_id=cred_stra.elem_id
),
fondo_dubbia_esig as (
select  importi.repimp_desc programma_code,
        coalesce(importi.repimp_importo,0) imp_fondo_dubbia_esig
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where 	report.rep_codice				=	'BILR148'   				
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		anno_eserc.anno					=	p_anno 						
and     bilancio.periodo_id				=	anno_eserc.periodo_id 		
and     importi.bil_id					=	bilancio.bil_id 			
and     r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id			
and     importi.periodo_id 				=	anno_comp.periodo_id
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_eserc.data_cancellazione is null
and     anno_comp.data_cancellazione is null
and     importi.repimp_desc <> ''
and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
)
select 
p_anno::varchar bil_anno,
''::varchar titent_tipo_code,
clas.titent_tipo_desc::varchar,
clas.titent_code::varchar,
clas.titent_desc::varchar,
''::varchar tipologia_tipo_code,
clas.tipologia_tipo_desc::varchar,
clas.tipologia_code::varchar,
clas.tipologia_desc::varchar,
''::varchar	categoria_tipo_code,
clas.categoria_tipo_desc::varchar,
clas.categoria_code::varchar,
clas.categoria_desc::varchar,
capall.bil_ele_code::varchar,
capall.bil_ele_desc::varchar,
capall.bil_ele_code2::varchar,
capall.bil_ele_desc2::varchar,
capall.bil_ele_id::integer,
capall.bil_ele_id_padre::integer,
COALESCE(capall.importo_finale::numeric,0) residui_attivi,
COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
COALESCE(capall.importo_finale::numeric + capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_finale::numeric + capall.residui_attivi_prec::numeric) * (1 - perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig
from clas 
left join capall on clas.categoria_id = capall.categoria_id  
left join fondo_dubbia_esig on fondo_dubbia_esig.programma_code = clas.tipologia_code   
) as zz;

/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/

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

CREATE OR REPLACE FUNCTION siac."BILR170_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dettaglio" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
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
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean,
  perc_delta numeric,
  perc_media numeric,
  percaccantonamento numeric
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
--percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
--perc_delta numeric;
--perc_media numeric;

h_count integer :=0;



BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

flag_acc_cassa:= true;

-- percentuale accantonamento bilancio
if p_anno_competenza = annoCapImp then
   	strpercAccantonamento = 'percentualeAccantonamentoAnno';
elseif  p_anno_competenza = annoCapImp1 then
	strpercAccantonamento = 'percentualeAccantonamentoAnno1';
else 
	strpercAccantonamento = 'percentualeAccantonamentoAnno2';
end if;




select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

select attr_bilancio."boolean"
into flagAccantGrad  from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'accantonamentoGraduale' and 
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;


if flagAccantGrad = 'N' then
   percAccantonamento = 100;
else  
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
    siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where 
    bilancio.periodo_id = anno_eserc.periodo_id and
    anno_eserc.anno = 	p_anno and
    bilancio.bil_id =  attr_bilancio.bil_id and
    attr_bilancio.attr_id= attr.attr_id and
    attr.attr_code = strpercAccantonamento and 
    attr_bilancio.data_cancellazione is null and
    attr_bilancio.ente_proprietario_id=p_ente_prop_id;
end if;

if tipomedia is null then
	tipomedia = 'SEMPLICE';
end if;


TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

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
codice_pdc='';

select fnc_siac_random_user()
into	user_table;


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

-- 31/08/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
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
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code
 ;
 

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo--,
       -- siac_r_bil_elem_acc_fondi_dubbia_esig r_cap_fcd
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
/*and e.ente_proprietario_id			= 	bilancio.ente_proprietario_id
and e.ente_proprietario_id			= 	tipo_elemento.ente_proprietario_id
and e.ente_proprietario_id			= 	anno_eserc.ente_proprietario_id
and e.ente_proprietario_id			= 	rc.ente_proprietario_id
and e.ente_proprietario_id			= 	ct.ente_proprietario_id
and e.ente_proprietario_id			= 	cl.ente_proprietario_id
and e.ente_proprietario_id			= 	r_capitolo_pdc.ente_proprietario_id
and e.ente_proprietario_id			= 	pdc.ente_proprietario_id
and e.ente_proprietario_id			= 	pdc_tipo.ente_proprietario_id
and e.ente_proprietario_id			= 	stato_capitolo.ente_proprietario_id
and e.ente_proprietario_id			= 	r_capitolo_stato.ente_proprietario_id
and e.ente_proprietario_id			= 	cat_del_capitolo.ente_proprietario_id
and e.ente_proprietario_id			= 	r_cat_capitolo.ente_proprietario_id*/
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id
--and r_cap_fcd.elem_id= e.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and pdc_tipo.classif_tipo_code like 'PDC_%'
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null
--and r_cap_fcd.data_cancellazione 		is null
/*and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/;

insert into siac_rep_cap_ep_imp
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
    where 	capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=	capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=	capitolo_imp_periodo.ente_proprietario_id
        and capitolo_importi.ente_proprietario_id	=	capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=	bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=	anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=	tipo_elemento.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=	stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=	r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=	cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=	r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno							= 	p_anno 												
    	and	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (p_anno_competenza)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
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
        /*and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               



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
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


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
codice_pdc:=classifBilRec.codice_pdc;

-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.elem_id = classifBilRec.bil_ele_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S';

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE

select COALESCE(datifcd.perc_acc_fondi,0), 
COALESCE(datifcd.perc_acc_fondi_1,0), COALESCE(datifcd.perc_acc_fondi_2,0),
COALESCE(datifcd.perc_acc_fondi_3,0), COALESCE(datifcd.perc_acc_fondi_4,0), 
COALESCE(datifcd.perc_delta,0), 
-- false -- SIAC-5854
1
into perc1, perc2, perc3, perc4, perc5, perc_delta
-- , flag_acc_cassa -- SIAC-5854
, h_count
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
where
  rbilelem.elem_id=classifBilRec.bil_ele_id and  
  rbilelem.acc_fde_id = datifcd.acc_fde_id and
  rbilelem.data_cancellazione is null;

if tipomedia = 'SEMPLICE' then
    perc_media = round((perc1+perc2+perc3+perc4+perc5)/5,2);
else 
    perc_media = round((perc1*0.10+perc2*0.10+perc3*0.10+perc4*0.35+perc5*0.35),2);
end if;

if perc_media is null then
   perc_media := 0;
end if;

if perc_delta is null then
   perc_delta := 0;
end if;

raise notice 'tipomedia % - %', classifBilRec.bil_ele_code , perc_media ;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

---if p_anno_competenza = annoCapImp then
   	importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
    importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);
--elseif  p_anno_competenza = annoCapImp1 then
--	importo_collb:= round(classifBilRec.stanziamento_prev_anno1 * (perc_media/100) * percAccantonamento/100,2);
--    importo_collc:= round(classifBilRec.stanziamento_prev_anno1 * perc_delta/100,2);
--else 
--	importo_collb:= round(classifBilRec.stanziamento_prev_anno2 * (perc_media/100) * percAccantonamento/100,2);
--    importo_collc:= round(classifBilRec.stanziamento_prev_anno2 * perc_delta/100,2);
--end if;

raise notice 'importo_collb % - %', classifBilRec.bil_ele_id , importo_collb;

raise notice 'percAccantonamento % - %', classifBilRec.bil_ele_id , percAccantonamento ;

if h_count is null or flag_acc_cassa = true then  -- SIAC-5854
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

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
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;
perc_delta:=0;
perc_media:=0;
--percAccantonamento:=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5854 Integrazione FINE