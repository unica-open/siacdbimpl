/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR999_variabili_dei_report" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_nome_report varchar
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
variabili_report record;

BEGIN
	anno_competenza='';
    importo=0;
    descrizione='';
	posizione_nel_report=0;
    codice_importo='';
    
    
	
for variabili_report in
select  Anno_comp.anno							anno_competenza,
        importi.repimp_importo					importo,
		importi.repimp_desc						descrizione,
        r_report_importi.posizione_stampa		posizione_nel_report,					 
        importi.repimp_codice					codice_importo         
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where 	report.rep_codice				=	p_nome_report				and
      	report.ente_proprietario_id		=	p_ente_prop_id				and
		anno_eserc.anno					=	p_anno 						and
      	bilancio.periodo_id				=	anno_eserc.periodo_id 		and
      	importi.bil_id					=	bilancio.bil_id 			and
        r_report_importi.rep_id			=	report.rep_id				and
        r_report_importi.repimp_id		=	importi.repimp_id			and
        importi.periodo_id 				=	anno_comp.periodo_id		and
        importi.ente_proprietario_id	=	p_ente_prop_id				and
        bilancio.ente_proprietario_id	=	p_ente_prop_id				and
        anno_eserc.ente_proprietario_id	=	p_ente_prop_id				and
		anno_comp.ente_proprietario_id	=	p_ente_prop_id
        and report.data_cancellazione IS NULL
        and importi.data_cancellazione IS NULL
        and r_report_importi.data_cancellazione IS NULL
        and anno_eserc.data_cancellazione IS NULL
        and anno_comp.data_cancellazione IS NULL
	loop
	
    
    
	anno_competenza:=variabili_report.anno_competenza;
    importo:=variabili_report.importo;
   	descrizione:=variabili_report.descrizione;
    posizione_nel_report:=variabili_report.posizione_nel_report;
    codice_importo:=variabili_report.codice_importo;
    
    IF   p_anno != '2016' then
      
      IF variabili_report.codice_importo = 'fpv_sc_prec' then 
          select COALESCE ( sum( imp_prec.importo_competenza), 0)
          into importo
          from siac_t_cap_e_importi_anno_prec imp_prec
          where 
          imp_prec.ente_proprietario_id=p_ente_prop_id and
          imp_prec.anno = ((p_anno::INTEGER)-1)::VARCHAR and
          imp_prec.elem_cat_code =  'FPVSC'; 
     
      elseif  variabili_report.codice_importo = 'fpv_scc_prec'  then 
          select COALESCE ( sum( imp_prec.importo_competenza), 0)
          into importo
          from siac_t_cap_e_importi_anno_prec imp_prec
          where 
          imp_prec.ente_proprietario_id=p_ente_prop_id and
          imp_prec.anno = ((p_anno::INTEGER)-1)::VARCHAR and
          imp_prec.elem_cat_code =  'FPVCC'; 
    
      elseif  variabili_report.codice_importo = 'ut_av_amm_prec'  then 
          select COALESCE ( sum( imp_prec.importo_competenza), 0)
          into importo
          from siac_t_cap_e_importi_anno_prec imp_prec
          where 
          imp_prec.ente_proprietario_id=p_ente_prop_id and
          imp_prec.anno = ((p_anno::INTEGER)-1)::VARCHAR and
          imp_prec.elem_cat_code =  'AAM'; 
    
      elseif  variabili_report.codice_importo = 'fondo_cassa_prec'  then 
          select COALESCE ( sum( imp_prec.importo_cassa), 0)
          into importo
          from siac_t_cap_e_importi_anno_prec imp_prec
          where 
          imp_prec.ente_proprietario_id=p_ente_prop_id and
          imp_prec.anno = ((p_anno::INTEGER)-1)::VARCHAR and
          imp_prec.elem_cat_code =  'FCI'; 
      
      elseif  variabili_report.codice_importo = 'dis_amm_prec'  then 
          select COALESCE ( sum( imp_prec.importo_competenza), 0)
          into importo
          from siac_t_cap_u_importi_anno_prec imp_prec
          where 
          imp_prec.ente_proprietario_id=p_ente_prop_id and
          imp_prec.anno = ((p_anno::INTEGER)-1)::VARCHAR and
          imp_prec.elem_cat_code =  'DAM'; 

       
      end if;     
    
    end if;
    
    return next;
    end loop;

exception
	when no_data_found THEN
		raise notice 'importi non trovati' ;
		--return next;
	when others  THEN
		raise notice 'errore nella lettura variabili ';
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;