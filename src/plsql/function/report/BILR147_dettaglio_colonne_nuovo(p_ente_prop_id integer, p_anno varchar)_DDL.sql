/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR147_dettaglio_colonne_nuovo" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  colonna varchar,
  missione_programma varchar,
  capitolo varchar,
  anno_impegno integer,
  numero_impegno numeric,
  numero_modifica varchar,
  motivo_modifica_code varchar,
  motivo_modifica_desc varchar,
  importo numeric
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
bilancio_id integer;
bilancio_id_anno1 integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

annoBilInt=p_anno::INTEGER;


missione_programma:='';
colonna:='';
capitolo:='';
anno_impegno:=0;
numero_impegno:=0;
numero_modifica:='';
motivo_modifica_code:='';
motivo_modifica_desc:='';
importo=0;

--Leggo l'id dell'anno bilancio
select bil.bil_id
into bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;    

--Leggo l'id dell'anno bilancio +1
select bil.bil_id
into bilancio_id_anno1
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = annoCapImp1
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;   
            
raise notice 'Id bilancio anno % = % - Id bilancio anno % = %',
	p_anno, bilancio_id, annoCapImp1, bilancio_id_anno1;
        
/*
	15/02/2022. 
Questa funzione serve per estrarre il dettaglio degli impegni che popolano
le colonne del report BILR147.
Serve per soddisfare le richieste di dettaglio che arrivano dal CSI.
Per ora le colonne estratte sono: B, D, E, X e Y.

Le query eseguite sono quelle del report BILR147 nuovo, attualmente presente 
nel menu' 7.
    
*/        

return query 
--Dati della Colonna B.
select 'colonna_B'::VARCHAR, class.classif_code missione_programma,
  bil_elem.elem_code capitolo, mov.movgest_anno anno_impegno, 
  mov.movgest_numero numero_impegno, 
  ''::varchar numero_modifica,
  ''::varchar motivo_modif_code,
  ''::varchar motivo_modif_desc,
	sum(coalesce( r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec
          from siac_t_movgest mov,              
            siac_t_movgest_ts mov_ts, 
            siac_t_movgest_ts_det mov_ts_det,
            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
            siac_t_bil_elem bil_elem, 
            siac_r_movgest_bil_elem r_mov_bil_elem,
            siac_r_movgest_ts_stato r_mov_ts_stato, 
            siac_d_movgest_stato d_mov_stato,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class class, 
            siac_d_class_tipo d_class_tipo, 
            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
            siac_t_atto_amm atto,
            siac_d_movgest_tipo d_mov_tipo,
            siac_r_movgest_ts r_movgest_ts, 
            siac_t_avanzovincolo av_vincolo, 
            siac_d_avanzovincolo_tipo av_vincolo_tipo
          where mov.movgest_id = mov_ts.movgest_id  
          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = class.classif_id
          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
          and bil_elem.elem_id=r_mov_bil_elem.elem_id
          and r_mov_bil_elem.movgest_id=mov.movgest_id 
          and r_movgest_ts.avav_id=av_vincolo.avav_id     
          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id            
          and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and mov.ente_proprietario_id= p_ente_prop_id    
          and mov.bil_id = bilancio_id            
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and mov.movgest_anno = annoBilInt 
          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_mov_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and av_vincolo_tipo.avav_tipo_code like'FPV%'
          and mov_ts.movgest_ts_id_padre is NULL  
          and r_mov_bil_elem.data_cancellazione is null
          and r_mov_bil_elem.validita_fine is NULL          
          and r_mov_ts_stato.data_cancellazione is null
          and r_mov_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and r_mov_ts_atto.data_cancellazione is null
          and r_mov_ts_atto.validita_fine is null          
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null            
          and mov.data_cancellazione is null
          and mov.validita_fine is NULL
          and mov_ts.data_cancellazione is null
          and mov_ts.validita_fine is NULL   
          and mov_ts_det.data_cancellazione is null
          and mov_ts_det.validita_fine is NULL   
          and d_mov_ts_det_tipo.data_cancellazione is null
          and d_mov_ts_det_tipo.validita_fine is NULL   
          and bil_elem.data_cancellazione is null
          and bil_elem.validita_fine is NULL   
          and d_mov_stato.data_cancellazione is null
          and d_mov_stato.validita_fine is NULL   
          and class.data_cancellazione is null
          and class.validita_fine is NULL   
          and d_class_tipo.data_cancellazione is null
          and d_class_tipo.validita_fine is NULL   
          and atto.data_cancellazione is null
          and atto.validita_fine is NULL   
          and av_vincolo.data_cancellazione is null
          and av_vincolo_tipo.data_cancellazione is null
          and av_vincolo_tipo.validita_fine is NULL              
        group by class.classif_code ,bil_elem.elem_code , 
        	mov.movgest_anno , mov.movgest_numero,
            numero_modifica,
            motivo_modif_code, motivo_modif_desc
union
--Colonna X		
select 'colonna_X'::varchar,  class.classif_code programma_code, 
		t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
        modif.mod_num::varchar numero_modifica,
        d_modif_tipo.mod_tipo_code || ' - '|| d_modif_tipo.mod_tipo_desc motivo_modif_code,
        modif.mod_desc motivo_modif_desc, 
	--sum(COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x
        (sum((COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_x
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         mov_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */      
      	left join (select r_mod_vinc.mod_id,
                    sum(r_mod_vinc.importo_delta) importo_delta 
              from siac_r_movgest_ts r_mov_ts,
                  siac_r_modifica_vincolo r_mod_vinc
              where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                and r_mov_ts.data_cancellazione IS NULL
                and r_mod_vinc.data_cancellazione IS NULL
              group by r_mod_vinc.mod_id) vincoli_acc
            on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      	siac_t_movgest_ts_det_mod mov_ts_det_mod,
      	siac_t_movgest_ts mov_ts, 
      	siac_d_modifica_stato d_mod_stato,
        siac_t_movgest mov, 
        siac_d_movgest_tipo d_mov_tipo,       
        siac_t_modifica modif, 
        siac_d_modifica_tipo d_modif_tipo,
        siac_d_modifica_stato d_modif_stato, 
        siac_t_bil_elem t_bil_elem, 
        siac_r_movgest_bil_elem r_mov_bil_elem,
        siac_r_bil_elem_class r_bil_elem_class, 
        siac_t_class class, 
        siac_d_class_tipo d_class_tipo,
        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
        siac_t_atto_amm atto_amm ,
        siac_r_movgest_ts_stato r_mov_ts_stato, 
        siac_d_movgest_stato d_mov_stato    
      where mov_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and mov_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_modif_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_movgest_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_movgest_ts_atto_amm.attoamm_id = atto_amm.attoamm_id
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mov_ts_stato.movgest_ts_id = mov_ts_det_mod.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id        
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno = anno del bilancio
        and mov.movgest_anno = annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I' 
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione 
      /*  and 
        ( d_modif_tipo.mod_tipo_code like  'ECON%'
           or d_modif_tipo.mod_tipo_desc like  'ROR%'
        )      
        and d_modif_tipo.mod_tipo_code <> 'REIMP' */                  
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM') 
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and mov_ts_det_mod.data_cancellazione is null
        and mov_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_modif_tipo.data_cancellazione is null
        and d_modif_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_movgest_ts_atto_amm.data_cancellazione is null
        and r_movgest_ts_atto_amm.validita_fine is null
        and d_mov_stato.data_cancellazione is null
        and d_mov_stato.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                      siac_t_avanzovincolo av_vincolo, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id                                 
                  and mov_ts_det_mod.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%' 
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null 
                 )        
      group by class.classif_code ,t_bil_elem.elem_code , 
      mov.movgest_anno , mov.movgest_numero,
      modif.mod_num,
      motivo_modif_code,
      motivo_modif_desc
union    
--colonna Y
select 'colonna_Y'::varchar, class.classif_code programma_code, 
	t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
    modif.mod_num::varchar numero_modifica,
    d_mod_tipo.mod_tipo_code || ' - '|| d_mod_tipo.mod_tipo_desc motivo_modif_code,
    modif.mod_desc motivo_modif_desc, 
	--sum(COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y
    (sum((COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_y  
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         movgest_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */      
      	left join (select r_mod_vinc.mod_id,
            				sum(r_mod_vinc.importo_delta) importo_delta 
                      from siac_r_movgest_ts r_mov_ts,
                          siac_r_modifica_vincolo r_mod_vinc
                      where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                        and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                        and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                        and r_mov_ts.data_cancellazione IS NULL
                        and r_mod_vinc.data_cancellazione IS NULL
                      group by r_mod_vinc.mod_id) vincoli_acc
            on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      siac_t_movgest_ts_det_mod movgest_ts_det_mod,
      siac_t_movgest_ts mov_ts, 
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest mov, 
      siac_d_movgest_tipo d_mov_tipo, 
      siac_t_modifica modif, 
      siac_d_modifica_tipo d_mod_tipo,
      siac_d_modifica_stato d_modif_stato, 
      siac_t_bil_elem t_bil_elem, 
      siac_r_movgest_bil_elem r_mov_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class class, 
      siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_mov_ts_atto_amm, 
      siac_t_atto_amm atto_amm ,
      siac_r_movgest_ts_stato r_mov_ts_stato, 
      siac_d_movgest_stato d_mov_stato    
      where movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and movgest_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_mod_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_mov_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_mov_ts_atto_amm.attoamm_id = atto_amm.attoamm_id        
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno > anno del bilancio
        and mov.movgest_anno > annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I'
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione         
  /*      and 
        ( d_mod_tipo.mod_tipo_code like  'ECON%'
           or d_mod_tipo.mod_tipo_desc like  'ROR%'
        )
        and d_mod_tipo.mod_tipo_code <> 'REIMP' */
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM')       
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and r_mov_ts_stato.movgest_ts_id = mov_ts.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and movgest_ts_det_mod.data_cancellazione is null
        and movgest_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_mod_tipo.data_cancellazione is null
        and d_mod_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_mov_ts_atto_amm.data_cancellazione is null
        and r_mov_ts_atto_amm.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                  siac_t_avanzovincolo av_vincolo, 
                  siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                  and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%'                                      
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null )
      group by class.classif_code ,t_bil_elem.elem_code , 
      	mov.movgest_anno , mov.movgest_numero,
        modif.mod_num,
        motivo_modif_code,
        motivo_modif_desc        
union
--colonna D		
select 'colonna_D'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno, 
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
  		''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,        
		sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 1
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code ,t_bil_elem.elem_code , 
                           mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              	mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_d
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 1
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = '2021'   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code ,t_bil_elem.elem_code , 
                      	mov.movgest_anno , mov.movgest_numero
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_d
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 1
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                    		--16/03/2022: corretto id del bilancio.
                        --and reimp.bil_id=147  --anno bilancio 
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                              --SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)                              
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id = NULL
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                  --SIAC-8682 - 07/04/2022.
                                  --il legame e' con l'impegno e non quello origine del riaccertamento.
                                --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure esiste con un vincolo con accertamento anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL)))
								   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +1).
                              AND  not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +1
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)
				--SIAC-8690 12/04/2022
                --devo escludere gli impegni riaccertati il cui impegno origine
                --l'anno precedente era vincolato verso FPV. 
                --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null                                      
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                          
                             )) AND
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                      (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code ,t_bil_elem.elem_code , 
              mov.movgest_anno , mov.movgest_numero)    
              ) as x
     group by x.programma_code ,x.elem_code, 
     	x.movgest_anno,x.movgest_numero,
        numero_modifica,
        motivo_modif_code, motivo_modif_desc      
union
--colonna E		
select 'colonna_E'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno,         
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
        ''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,
		sum(x.spese_da_impeg_anno1_e) as spese_da_impeg_anno1_e from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_e
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 2
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code ,t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_e
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = '2021'   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code ,t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  .
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.            
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_e
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null    
                  	--impegni che arrivano da reimputazione    
                  and ((mov_ts.movgest_ts_id in  (                          
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL 
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure l'impegno riaccertato ha un vincolo 
                               --di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                 --SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                     --SIAC-8682 - 07/04/2022.
                                     --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
                                   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL) 
          --SIAC-8690 12/04/2022
          --devo escludere gli impegni riaccertati il cui impegno origine
          --l'anno precedente era vincolato verso FPV. 
          --AAM e' accettato.                                       
              AND  not exists (select 1                          
                    from siac_t_movgest_ts t_mov_ts1                                                            
                     join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                            from siac_r_movgest_ts_attr r_mov_attr1,
                             siac_t_attr attr1
                            where r_mov_attr1.attr_id=attr1.attr_id
                                and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                and upper(r_mov_attr1.testo) <> 'NULL'                                
                                and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                            on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                      join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                            from siac_r_movgest_ts_attr r_mov_attr2,
                             siac_t_attr attr2
                            where r_mov_attr2.attr_id=attr2.attr_id
                                and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                and upper(r_mov_attr2.testo) <> 'NULL'                                
                                and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                          on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                      siac_r_movgest_ts r_mov_ts1,
                      siac_t_movgest_ts imp_ts1,
                      siac_t_movgest imp1,
                      siac_t_avanzovincolo av_vincolo1, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                     where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                     and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                      and imp_ts1.movgest_id=imp1.movgest_id
                      and r_mov_ts1.avav_id=av_vincolo1.avav_id
                      and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                      and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                      and imp1.bil_id=bilancio_id --anno bilancio
                      and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                      and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                      and av_vincolo_tipo1.avav_tipo_code<>'AAM'
                          --se movgest_ts_a_id = NULL
                          --il vincolo non e' verso accertamento.
                      and r_mov_ts1.movgest_ts_a_id IS NULL
                      and r_mov_ts1.data_cancellazione IS NULL   
                      and imp_ts1.data_cancellazione IS NULL 
                      and imp1.data_cancellazione IS NULL
                      and av_vincolo1.data_cancellazione IS NULL)                                                                                      
                  )))--fine impegni che arrivano da reimputazione  
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                    AND  (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL))                                                                                                          
              group by class.classif_code ,t_bil_elem.elem_code , 
              	mov.movgest_anno , mov.movgest_numero)    
              ) as x
        group by x.programma_code ,x.elem_code, x.movgest_anno,
            x.movgest_numero,
            numero_modifica,
            motivo_modif_code,
            motivo_modif_desc   
union                   
--Colonna F
select 'colonna_F'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno,         
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
        ''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,
		sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f from (
               (
 				 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio               
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      		as spese_da_impeg_anni_succ_f
                        from siac_t_movgest mov,  
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_movgest_ts acc_ts,
                          siac_t_movgest acc,
                          siac_r_movgest_ts_stato r_acc_ts_stato,
                          siac_d_movgest_stato d_acc_stato
                        where mov.movgest_id = mov_ts.movgest_id  
                            and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                            and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                            and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                            and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                            and r_bil_elem_class.classif_id = class.classif_id
                            and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                            and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                            and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                            and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                            and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id
                            and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                            and acc_ts.movgest_id = acc.movgest_id
                            and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                            and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id
                            and r_mov_bil_elem.movgest_id=mov.movgest_id 
                            and mov.ente_proprietario_id= p_ente_prop_id 
                            and mov.bil_id = bilancio_id     
                            and d_class_tipo.classif_tipo_code='PROGRAMMA'
                            and mov.movgest_anno > annoBilInt + 2
                            and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and d_mov_stato.movgest_stato_code in ('D', 'N')
                            and d_mov_tipo.movgest_tipo_code='I' 
                            and acc.movgest_anno = annoBilInt
                            and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                            --and atto.attoamm_anno = p_anno   
                            and mov_ts.movgest_ts_id_padre is NULL  
                            and mov_ts.data_cancellazione is null
                            and mov_ts.validita_fine is NULL                           
                            and r_mov_bil_elem.data_cancellazione is null
                            and r_mov_bil_elem.validita_fine is NULL          
                            and r_mov_ts_stato.data_cancellazione is null
                            and r_mov_ts_stato.validita_fine is null
                            and mov_ts_det.data_cancellazione is null
                            and mov_ts_det.validita_fine is null
                            and d_mov_tipo.data_cancellazione is null
                            and d_mov_tipo.validita_fine is null              
                            and r_bil_elem_class.data_cancellazione is null
                            and r_bil_elem_class.validita_fine is null
                            and r_mov_ts_atto.data_cancellazione is null
                            and r_mov_ts_atto.validita_fine is null                         
                            and r_mov_ts.data_cancellazione is null
                            and r_mov_ts.validita_fine is null                         
                            and acc_ts.movgest_ts_id_padre is null                        
                            and acc.validita_fine is null
                            and acc.data_cancellazione is null
                            and acc_ts.validita_fine is null
                            and acc_ts.data_cancellazione is null                                                
                            and r_acc_ts_stato.validita_fine is null
                            and r_acc_ts_stato.data_cancellazione is null                                                
                                --21/05/2020 SIAC-7643 
                                --aggiunti i test sulle date che mancavano                        
                            and mov.validita_fine is null
                            and mov.data_cancellazione is null
                            and d_mov_ts_det_tipo.validita_fine is null
                            and d_mov_ts_det_tipo.data_cancellazione is null
                            and t_bil_elem.validita_fine is null
                            and t_bil_elem.data_cancellazione is null
                            and d_mov_stato.validita_fine is null
                            and d_mov_stato.data_cancellazione is null
                            and class.validita_fine is null
                            and class.data_cancellazione is null
                            and d_class_tipo.validita_fine is null
                            and d_class_tipo.data_cancellazione is null 
                            and atto.validita_fine is null
                            and atto.data_cancellazione is null                                                                                                                                                   
                           group by class.classif_code,
                             t_bil_elem.elem_code , 
                              mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anni_succ_f
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
						  siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 	
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id  
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id    
                          and mov.bil_id = bilancio_id   
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno > annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM' 
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL    
                          and mov_ts.data_cancellazione is null
                          and mov_ts.validita_fine is NULL   
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null   
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                       
                  group by class.classif_code,
                  	t_bil_elem.elem_code , 
              				mov.movgest_anno , mov.movgest_numero)
              union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno > anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                  
             select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
             sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anni_succ_f
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno > annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                     --impegni che arrivano da reimputazione 
                  and ((mov_ts.movgest_ts_id in  (
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL 
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure l'impegno riaccertato ha un vincolo 
                               --di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                  --SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                     --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
                                  --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con anno > dell'anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno > annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)  
                  --SIAC-8690 12/04/2022
                  --devo escludere gli impegni riaccertati il cui impegno origine
                  --l'anno precedente era vincolato verso FPV. 
                  --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr1.testo) <> 'NULL'                                      
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr2.testo) <> 'NULL'                                      
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                        
                 ))--fine impegni che arrivano da reimputazione 
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                  AND    (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code,
              	t_bil_elem.elem_code, mov.movgest_anno,
              	mov.movgest_numero)   
            ) as x
        group by x.programma_code ,x.elem_code, x.movgest_anno,
            x.movgest_numero, numero_modifica,
            motivo_modif_code, motivo_modif_desc                                 
order by 1,2,3,4,5;          

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato ';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR147_dettaglio_colonne_nuovo" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;