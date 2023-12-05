/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
  fondo_dubbia_esig numeric,
  afde_bil_crediti_stralciati numeric,
  afde_bil_crediti_stralciati_fcde numeric,
  afde_bil_accertamenti_anni_successivi numeric,
  afde_bil_accertamenti_anni_successivi_fcde numeric,
  colonna_e numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
afde_bilancioId integer;
var_afde_bil_crediti_stralciati numeric;
var_afde_bil_crediti_stralciati_fcde numeric;
var_afde_bil_accertamenti_anni_successivi numeric;
var_afde_bil_accertamenti_anni_successivi_fcde numeric;
  
BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

/*
	SIAC-8154 13/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    
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

*/

--SIAC-8154 21/07/2021
--devo leggere afde_bil_id che serve per l'accesso alla tabella 
--siac.siac_t_acc_fondi_dubbia_esig 
select 	fondi_bil.afde_bil_id, 
	COALESCE(fondi_bil.afde_bil_crediti_stralciati,0),
	COALESCE(fondi_bil.afde_bil_crediti_stralciati_fcde,0),
    COALESCE(fondi_bil.afde_bil_accertamenti_anni_successivi,0),
    COALESCE(fondi_bil.afde_bil_accertamenti_anni_successivi_fcde,0)    
	into afde_bilancioId, var_afde_bil_crediti_stralciati,
    var_afde_bil_crediti_stralciati_fcde, var_afde_bil_accertamenti_anni_successivi,
    var_afde_bil_accertamenti_anni_successivi_fcde    
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='RENDICONTO' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
--    var_afde_bil_crediti_stralciati:=100;
--    var_afde_bil_crediti_stralciati_fcde:=200;
--    var_afde_bil_accertamenti_anni_successivi:=300;
--    var_afde_bil_accertamenti_anni_successivi_fcde:=400;
    
return query
select zz.* from (
with clas as (
	select classif_tipo_desc1 titent_tipo_desc, titolo_code titent_code,
    	 titolo_desc titent_desc, titolo_validita_inizio titent_validita_inizio,
         titolo_validita_fine titent_validita_fine, 
         classif_tipo_desc2 tipologia_tipo_desc,
         tipologia_id, strutt.tipologia_code tipologia_code, 
         strutt.tipologia_desc tipologia_desc,
         tipologia_validita_inizio, tipologia_validita_fine,
         classif_tipo_desc3 categoria_tipo_desc,
         categoria_id, strutt.categoria_code categoria_code, 
         strutt.categoria_desc categoria_desc,
         categoria_validita_inizio, categoria_validita_fine,
         ente_proprietario_id
    from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
    											   p_anno,'') strutt 
),
capall as (
with
cap as (
select bil_elem.elem_id,bil_elem.elem_code,bil_elem.elem_desc,
  bil_elem.elem_code2,bil_elem.elem_desc2,bil_elem.elem_id_padre,
  bil_elem.elem_code3,class.classif_id , 
  fcde.acc_fde_denominatore,fcde.acc_fde_denominatore_1,
  fcde.acc_fde_denominatore_2,
  fcde.acc_fde_denominatore_3,fcde.acc_fde_denominatore_4,
  fcde.acc_fde_numeratore,fcde.acc_fde_numeratore_1,
  fcde.acc_fde_numeratore_2,
  fcde.acc_fde_numeratore_3,fcde.acc_fde_numeratore_4,
  case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
        COALESCE(fcde.acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(fcde.acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
        COALESCE(fcde.acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
        COALESCE(fcde.acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
        COALESCE(fcde.acc_fde_media_utente, 0)      
    end end end end end perc_media_applicata
from siac_t_bil_elem bil_elem,	
--SIAC-8154 07/10/2021.
--aggiunto legame con la tabella dell'fcde perche' si devono
--estrarre solo i capitoli coinvolti.
	 siac_t_acc_fondi_dubbia_esig fcde
     	left join siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
        	on tipo_media.afde_tipo_media_id=fcde.afde_tipo_media_id,
     siac_d_bil_elem_tipo bil_elem_tipo,
     siac_r_bil_elem_class r_bil_elem_class,
 	 siac_t_class class,	
     siac_d_class_tipo d_class_tipo,
	 siac_r_bil_elem_categoria r_bil_elem_categ,	
     siac_d_bil_elem_categoria d_bil_elem_categ, 
     siac_r_bil_elem_stato r_bil_elem_stato, 
     siac_d_bil_elem_stato d_bil_elem_stato 
where bil_elem.elem_tipo_id		 = bil_elem_tipo.elem_tipo_id 
and   r_bil_elem_class.elem_id   = bil_elem.elem_id
and   class.classif_id           = r_bil_elem_class.classif_id
and   d_class_tipo.classif_tipo_id      = class.classif_tipo_id
and   d_bil_elem_categ.elem_cat_id          = r_bil_elem_categ.elem_cat_id
and   r_bil_elem_categ.elem_id              = bil_elem.elem_id
and   r_bil_elem_stato.elem_id              = bil_elem.elem_id
and   d_bil_elem_stato.elem_stato_id        = r_bil_elem_stato.elem_stato_id
and   fcde.elem_id						= bil_elem.elem_id
and   bil_elem.ente_proprietario_id = p_ente_prop_id
and   bil_elem.bil_id               = bilancio_id
and   fcde.afde_bil_id				=  afde_bilancioId
and   bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'
and   d_class_tipo.classif_tipo_code	 = 'CATEGORIA'
and	  d_bil_elem_categ.elem_cat_code	     = 'STD'
and	  d_bil_elem_stato.elem_stato_code	     = 'VA'
and   bil_elem.data_cancellazione   is null
and	  bil_elem_tipo.data_cancellazione   is null
and	  r_bil_elem_class.data_cancellazione	 is null
and	  class.data_cancellazione	 is null
and	  d_class_tipo.data_cancellazione 	 is null
and	  r_bil_elem_categ.data_cancellazione 	 is null
and	  d_bil_elem_categ.data_cancellazione	 is null
and	  r_bil_elem_stato.data_cancellazione   is null
and	  d_bil_elem_stato.data_cancellazione   is null
and   fcde.data_cancellazione is null
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
from  siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
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
where r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
    and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
    and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
    and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
    and	ordinativo.ord_id					=	ordinativo_det.ord_id
    and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
    and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
    and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
    and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
    and	ts_movimento.movgest_id				=	movimento.movgest_id
    and ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
    and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
    ------------------------------------------------------------------------------------------		
    ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
    and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
    -----------------------------------------------------------------------------------------------
    and	ordinativo.bil_id					=	bilancio_id
    and movimento.bil_id					=	bilancio_id	
    and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
    and	movimento.movgest_anno				<=	annoCapImp_int	
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
from siac_t_bil_elem     capitolo , 
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
     where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
       and r_mov_capitolo.elem_id    		=	capitolo.elem_id
       and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
       and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
       and movimento.movgest_id      		= 	ts_movimento.movgest_id 
       and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
       and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
       and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
       and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
       and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
       and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
       and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
       and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id 
       and r_mod_stato.mod_id=t_modifica.mod_id              
       and capitolo.ente_proprietario_id   = p_ente_prop_id           
       and capitolo.bil_id      				=	bilancio_id
       and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
       and movimento.movgest_anno 	< 	annoCapImp_int
       and movimento.bil_id					=	bilancio_id
       and tipo_mov.movgest_tipo_code    	= 'A' 
       and tipo_stato.movgest_stato_code   in ('D','N')
       and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
       and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
       and d_mod_stato.mod_stato_code='V'    
       and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
       and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
       and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
     group by capitolo.elem_id	
),
/*
	SIAC-8154 13/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/      
/*
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
), */
minfondo as ( -- Importo minimo del fondo
SELECT
 datifcd.elem_id,   
 case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
    	COALESCE(acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
    	COALESCE(acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
    	COALESCE(acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
    	COALESCE(acc_fde_media_utente, 0)      
    end end end end end perc_media,        
 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, 
    siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
 WHERE tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
   AND datifcd.ente_proprietario_id = p_ente_prop_id 
   and datifcd.afde_bil_id  = afde_bilancioId
   AND datifcd.data_cancellazione is null
   AND tipo_media.data_cancellazione is null
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
       --sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
       sum (dt_movimento.movgest_ts_det_importo) accertamenti_succ
from siac_t_bil_elem     capitolo , 
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
     where capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id     
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     and movimento.bil_id					=	bilancio_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int      
     and tipo_mov.movgest_tipo_code    	= 'A'       
     and tipo_stato.movgest_stato_code   in ('D','N')      
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'          
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
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
     group by capitolo.elem_id	
),
cred_stra as ( -- Crediti stralciati
 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
    from siac_t_bil_elem     capitolo , 
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
      where r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 	        <= 	annoCapImp_int      
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      /*and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) */
      and d_modif_tipo.mod_tipo_code in ('CROR','ECON')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
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
group by capitolo.elem_id),
--SIAC-8154.
--Le query seguenti so no quelle utilizzate per il calcolo dei residui.
stanz_residuo_capitolo as(
  select bil_elem.elem_id, 
      sum(bil_elem_det.elem_det_importo) importo_residui   
  from siac_t_bil_elem bil_elem,	
       siac_t_acc_fondi_dubbia_esig fcde,
       siac_d_bil_elem_tipo bil_elem_tipo,
       siac_t_bil_elem_det bil_elem_det,
       siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
       siac_t_periodo per
  where bil_elem.elem_id = fcde.elem_id
  and bil_elem.elem_tipo_id = bil_elem_tipo.elem_tipo_id
  and bil_elem.elem_id=bil_elem_det.elem_id
  and bil_elem_det.elem_det_tipo_id=d_bil_elem_det_tipo.elem_det_tipo_id
  and per.periodo_id=bil_elem_det.periodo_id
  and bil_elem.ente_proprietario_id= p_ente_prop_id
  and fcde.afde_bil_id				=  afde_bilancioId
  and bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'    
  and d_bil_elem_det_tipo.elem_det_tipo_code='STR'
  and per.anno			= p_anno
  and bil_elem.data_cancellazione IS NULL
  and fcde.data_cancellazione IS NULL
  and bil_elem_tipo.data_cancellazione IS NULL
  and bil_elem_det.data_cancellazione IS NULL
  and d_bil_elem_det_tipo.data_cancellazione IS NULL  
  and bil_elem_det.validita_inizio < CURRENT_TIMESTAMP
  and (bil_elem_det.validita_fine IS NULL OR
       bil_elem_det.validita_fine > CURRENT_TIMESTAMP)
  group by bil_elem.elem_id),
stanz_residuo_capitolo_mod as (
  select bil_elem.elem_id, 
  sum(bil_elem_det_var.elem_det_importo) importo_residui_mod    
  from siac_t_bil_elem bil_elem,	
       siac_t_acc_fondi_dubbia_esig fcde,
       siac_d_bil_elem_tipo bil_elem_tipo,
       siac_t_bil_elem_det bil_elem_det,
       siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
       siac_t_periodo per,
       siac_t_bil_elem_det_var bil_elem_det_var,
       siac_r_variazione_stato r_var_stato,
       siac_d_variazione_stato d_var_stato
  where bil_elem.elem_id = fcde.elem_id
  and bil_elem.elem_tipo_id = bil_elem_tipo.elem_tipo_id
  and bil_elem.elem_id=bil_elem_det.elem_id
  and bil_elem_det.elem_det_tipo_id=d_bil_elem_det_tipo.elem_det_tipo_id
  and per.periodo_id=bil_elem_det.periodo_id
  and bil_elem_det_var.elem_det_id=bil_elem_det.elem_det_id
  and bil_elem_det_var.variazione_stato_id=r_var_stato.variazione_stato_id
  and r_var_stato.variazione_stato_tipo_id=d_var_stato.variazione_stato_tipo_id
  and bil_elem.ente_proprietario_id= p_ente_prop_id
  and fcde.afde_bil_id				=  afde_bilancioId
  and bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'    
  and d_bil_elem_det_tipo.elem_det_tipo_code='STR'
  and per.anno 						= p_anno
  and d_var_stato.variazione_stato_tipo_code not in ('A','D')
  and bil_elem.data_cancellazione IS NULL
  and fcde.data_cancellazione IS NULL
  and bil_elem_tipo.data_cancellazione IS NULL
  and bil_elem_det.data_cancellazione IS NULL
  and bil_elem_det_var.data_cancellazione IS NULL
  and r_var_stato.data_cancellazione IS NULL
  and d_var_stato.data_cancellazione IS NULL
  and d_bil_elem_det_tipo.data_cancellazione IS NULL  
  and bil_elem_det.validita_inizio < CURRENT_TIMESTAMP
  and (bil_elem_det.validita_fine IS NULL OR
       bil_elem_det.validita_fine > CURRENT_TIMESTAMP)
  group by bil_elem.elem_id)
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
--SIAC-8154 07/10/2021.
--i residui dell'anno precedente devono essere presi dalla tabella
--dell'fcde.
/*
(coalesce(resatt1.residui_accertamenti,0) -
	coalesce(resrisc1.importo_residui,0) +
	coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,*/
(+COALESCE(cap.acc_fde_denominatore,0)+
COALESCE(cap.acc_fde_denominatore_1,0)+COALESCE(cap.acc_fde_denominatore_2,0)+
COALESCE(cap.acc_fde_denominatore_3,0)+COALESCE(cap.acc_fde_denominatore_4,0))residui_attivi_prec,           
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
--(coalesce(resatt2.residui_accertamenti,0) -
-- coalesce(resrisc2.importo_residui,0)) importo_finale
coalesce(stanz_residuo_capitolo.importo_residui,0) importo_residui,
COALESCE(stanz_residuo_capitolo_mod.importo_residui_mod,0) importo_residui_mod,
cap.perc_media_applicata
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
left join stanz_residuo_capitolo
	on cap.elem_id=stanz_residuo_capitolo.elem_id
left join stanz_residuo_capitolo_mod
	on cap.elem_id=stanz_residuo_capitolo_mod.elem_id
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
where   bilancio.periodo_id				=	anno_eserc.periodo_id 		
and     importi.bil_id					=	bilancio.bil_id 			
and     r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id			
and     importi.periodo_id 				=	anno_comp.periodo_id
   				
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		anno_eserc.anno					=	p_anno 						
and 	report.rep_codice				=	'BILR148'
  --24/05/2021 SIAC-8212.
  --Cambiato il codice che identifica le variabili per aggiungere una nota utile
  --all'utente per la compilazione degli importi.
  --and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
and 	importi.repimp_codice like 'Colonna E Allegato c) FCDE Rendiconto%'
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_eserc.data_cancellazione is null
and     anno_comp.data_cancellazione is null
and     importi.repimp_desc <> ''
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
COALESCE(capall.importo_residui::numeric,0) + 
	COALESCE(capall.importo_residui_mod::numeric,0) residui_attivi,
COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
COALESCE(capall.importo_residui::numeric + capall.importo_residui_mod +
 capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_residui::numeric + 
  capall.importo_residui_mod::numeric +
  capall.residui_attivi_prec::numeric) * (1 - perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig,
var_afde_bil_crediti_stralciati,
var_afde_bil_crediti_stralciati_fcde,
var_afde_bil_accertamenti_anni_successivi,
var_afde_bil_accertamenti_anni_successivi_fcde,
(COALESCE(capall.importo_residui::numeric,0) + 
	COALESCE(capall.importo_residui_mod::numeric,0)) * 
    (100 - capall.perc_media_applicata) / 100
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