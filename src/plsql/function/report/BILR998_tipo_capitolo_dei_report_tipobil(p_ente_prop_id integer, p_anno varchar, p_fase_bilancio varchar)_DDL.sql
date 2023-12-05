/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR998_tipo_capitolo_dei_report_tipobil" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_fase_bilancio varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar
) AS
$body$
DECLARE

classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';

fase_bilancio varchar;
tipoDisavanzoDanc varchar;

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
--SIAC-7192 10/02/2020.
--  Introdotta la categoria capitolo DDANC - DISAVANZO DERIVANTE DA DEBITO AUTORIZZATO E NON CONTRATTO 
tipoDisavanzoDanc='DDANC';

/* funzione creata per il report BILR064 per permettere di leggere i valori
   di Previsione / Gestione in base ad un paramentro di input */
   
if p_fase_bilancio = 'P'  then
      elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
      elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione
else
      elemTipoCodeE:='CAP-EG'; -- tipo capitolo previsione
      elemTipoCodeS:='CAP-UG'; -- tipo capitolo previsione
end if;


for tipo_capitolo in 
  select 		
      capitolo_imp_periodo.anno          anno_competenza,
      cat_del_capitolo.elem_cat_code	   codice_importo,
      sum(coalesce(capitolo_importi.elem_det_importo,0)) importo  
  from 		
      siac_t_bil_elem_det capitolo_importi,
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
  and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
  and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
  and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
  and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
  and	capitolo_imp_periodo.anno           = p_anno
  and	capitolo.elem_id					=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
  and	stato_capitolo.elem_stato_code		=	'VA'
  and	capitolo.elem_id					=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
--		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFCassaIni)	
          	-- SIAC-7192 10/02/2020.
			--  Introdotta la categoria capitolo DDANC - 
            --  DISAVANZO DERIVANTE DA DEBITO AUTORIZZATO E NON CONTRATTO 
  and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,
  				tipoFpvcc,tipoFpvsc,tipoDisavanzoDanc)	
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
  group by cat_del_capitolo.elem_cat_code, capitolo_imp_periodo.anno
  union
  select 		
      capitolo_imp_periodo.anno          anno_competenza,
      cat_del_capitolo.elem_cat_code	   codice_importo,
      sum(coalesce(capitolo_importi.elem_det_importo,0)) importo  
  from 		
      siac_t_bil_elem_det capitolo_importi,
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
  and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
  and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
  and	capitolo_imp_tipo.elem_det_tipo_code	=	'SCA' 		
  and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
  and	capitolo_imp_periodo.anno           = p_anno
  and	capitolo.elem_id					=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
  and	stato_capitolo.elem_stato_code		=	'VA'
  and	capitolo.elem_id					=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
--		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFCassaIni)	
  and	cat_del_capitolo.elem_cat_code		in (tipoFCassaIni)	
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
  group by cat_del_capitolo.elem_cat_code, capitolo_imp_periodo.anno
        
loop
     
       anno_competenza := tipo_capitolo.anno_competenza;
       codice_importo := tipo_capitolo.codice_importo;
       importo := tipo_capitolo.importo;

       descrizione := '';
       posizione_nel_report := 0;

       return next;

       anno_competenza='';
       importo=0;
       descrizione='';
       posizione_nel_report=0;
       codice_importo='';

end loop;

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