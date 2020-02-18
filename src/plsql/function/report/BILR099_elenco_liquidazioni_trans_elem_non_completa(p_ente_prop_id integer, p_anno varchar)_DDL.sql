/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR099_elenco_liquidazioni_trans_elem_non_completa" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  nome_ente varchar,
  bil_anno varchar,
  anno_capitolo integer,
  num_capitolo varchar,
  cod_articolo varchar,
  ueb varchar,
  descr_capitolo varchar,
  descr_articolo varchar,
  anno_liquidazione integer,
  num_liquidazione integer,
  stato_liquidazione varchar,
  descr_liquidazione varchar,
  importo_liquidazione numeric,
  emissione_liquidazione date,
  movgest_id integer,
  movgest_ts_id integer,
  pdc_finanziario_cap varchar,
  pdc_finanziario_movgest varchar,
  classif_id integer,
  classif_tipo_code varchar,
  cofog varchar,
  transaz_europea varchar,
  siope varchar,
  ricorrente varchar,
  perimetro_sanitario varchar,
  politiche_regionali varchar,
  cup varchar,
  elem_id integer,
  liq_id integer
) AS
$body$
DECLARE
 elencoLiquidazioniRec record;
 elencoAttrib record;
 elencoClass	record;
 annoCompetenza_int integer;
 sett_code varchar;
 sett_descr varchar;
 direz_code varchar;
 direz_descr varchar;
 classif_id_padre integer;
 conta_vincoli integer;
 user_table varchar;
 
BEGIN
 
nome_ente='';
bil_anno='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
descr_capitolo='';
descr_articolo='';
anno_liquidazione=0;
num_liquidazione=0;
stato_liquidazione='';
descr_liquidazione='';
importo_liquidazione=0;
emissione_liquidazione=NULL;
movgest_id=0;
movgest_ts_id=0;
pdc_finanziario_cap='';
pdc_finanziario_movgest='';
classif_tipo_code='';
cofog='';
transaz_europea='';
siope='';
ricorrente='';
perimetro_sanitario='';
politiche_regionali='';
cup='';
elem_id=0;
liq_id=0;

annoCompetenza_int =p_anno ::INTEGER;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati delle liquidazioni ';

for elencoLiquidazioniRec IN
	
select capitolo.elem_id,capitolo.elem_code,capitolo.elem_desc,
    	capitolo.elem_code2, capitolo.elem_desc2,capitolo.elem_code3,         
        t_mov_gest.movgest_id,anno_eserc.anno anno_bil,
        t_mov_gest.movgest_numero num_impegno,
        t_mov_gest.movgest_anno ANNO_COMP_impegno, 
        t_movgest_ts_det.movgest_ts_det_importo importo_impegno,
        t_liquidazione.liq_numero NUM_liquidazione,
        t_liquidazione.liq_anno ANNO_COMP_liquidazione, 
        t_liquidazione.liq_importo importo_liquidazione,
        t_liquidazione.liq_id, t_liquidazione.liq_desc,
        t_liquidazione.liq_emissione_data,                 
        t_movgest_ts.movgest_ts_scadenza_data scadenza_data,
        t_mov_gest.movgest_desc, anno_eserc.anno BIL_ANNO,
        t_ente_prop.ente_denominazione, d_liq_stato.liq_stato_code,
        d_liq_stato.liq_stato_desc,    
        t_mov_gest.movgest_id, t_movgest_ts.movgest_ts_id,              
        pdc.classif_code||' - '||pdc.classif_desc pdc_finanziario_cap
        from siac_t_movgest t_mov_gest,
            siac_d_movgest_tipo d_mov_gest_tipo,
            siac_t_movgest_ts_det t_movgest_ts_det,
            siac_d_movgest_ts_tipo   ts_mov_tipo, 
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,           
            siac_r_movgest_bil_elem r_movgest_bil_elem, 
            siac_d_liquidazione_stato 	d_liq_stato,
            siac_r_liquidazione_stato r_liq_stato,
            siac_t_bil			bilancio,
            siac_t_periodo      anno_eserc,
            siac_t_ente_proprietario	t_ente_prop,
            siac_t_bil_elem		capitolo,
            siac_r_bil_elem_class r_capitolo_pdc,
     		siac_t_class pdc,
     		siac_d_class_tipo pdc_tipo,
            siac_r_liquidazione_movgest r_liquidazione_movgest,           
            siac_t_movgest_ts t_movgest_ts,       
           siac_t_liquidazione   t_liquidazione         		          
        where d_mov_gest_tipo.movgest_tipo_id=t_mov_gest.movgest_tipo_id
                AND t_movgest_ts.movgest_id=t_mov_gest.movgest_id
                and t_movgest_ts.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id       
                AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id              
                AND r_movgest_bil_elem.elem_id=capitolo.elem_id
                AND r_movgest_bil_elem.movgest_id=t_mov_gest.movgest_id                                            
                AND bilancio.bil_id=capitolo.bil_id
                AND anno_eserc.periodo_id=bilancio.periodo_id
                and t_ente_prop.ente_proprietario_id=capitolo.ente_proprietario_id
                and r_liq_stato.liq_stato_id=d_liq_stato.liq_stato_id
                and r_liq_stato.liq_id=t_liquidazione.liq_id
				AND r_capitolo_pdc.classif_id 			= pdc.classif_id
  				AND pdc.classif_tipo_id 				= pdc_tipo.classif_tipo_id					
                AND capitolo.elem_id 					= 	r_capitolo_pdc.elem_id
                and r_liquidazione_movgest.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND r_liquidazione_movgest.liq_id=t_liquidazione.liq_id
				AND pdc_tipo.classif_tipo_code like 'PDC_%'			                												
                AND d_mov_gest_tipo.movgest_tipo_code = 'I'
                and anno_eserc.anno=p_anno
	/* 09/06/2016: tolto il legame con la testata perchè
    	non estrae tutte le liquidazioni */                
               -- and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
                and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                AND t_mov_gest.ente_proprietario_id=p_ente_prop_id            
                and t_mov_gest.data_cancellazione is NULL
                and d_mov_gest_tipo.data_cancellazione is NULL
                and t_movgest_ts.data_cancellazione is NULL
                and t_movgest_ts_det.data_cancellazione is NULL
                and r_movgest_bil_elem.data_cancellazione is NULL
                and bilancio.data_cancellazione is NULL
                and anno_eserc.data_cancellazione is NULL
                and ts_mov_tipo.data_cancellazione is NULL  
                and capitolo.data_cancellazione IS NULL
                and t_ente_prop.data_cancellazione is NULL 
                and d_movgest_ts_det_tipo.data_cancellazione IS NULL
                and r_liq_stato.data_cancellazione IS NULL
                and r_liq_stato.validita_fine is  null
                and d_liq_stato.data_cancellazione IS NULL
                and r_capitolo_pdc.data_cancellazione IS NULL
                and pdc.data_cancellazione IS NULL
                and pdc_tipo.data_cancellazione IS NULL
                and r_liquidazione_movgest.data_cancellazione IS NULL
                and t_liquidazione.data_cancellazione IS NULL
                --ORDER BY  t_mov_gest.movgest_anno, t_mov_gest.movgest_numero            
                
loop
	nome_ente=elencoLiquidazioniRec.ente_denominazione;
    bil_anno=elencoLiquidazioniRec.BIL_ANNO;
    anno_capitolo=elencoLiquidazioniRec.BIL_ANNO;
    num_capitolo=elencoLiquidazioniRec.elem_code;
    cod_articolo=elencoLiquidazioniRec.elem_code2;
    ueb=elencoLiquidazioniRec.elem_code3;
    descr_capitolo=COALESCE(elencoLiquidazioniRec.elem_desc,'');
    descr_articolo=COALESCE(elencoLiquidazioniRec.elem_desc2,'');

    pdc_finanziario_cap=COALESCE(elencoLiquidazioniRec.pdc_finanziario_cap,'');

    anno_liquidazione=elencoLiquidazioniRec.ANNO_COMP_liquidazione;
    num_liquidazione=elencoLiquidazioniRec.NUM_liquidazione;

   
    stato_liquidazione=elencoLiquidazioniRec.liq_stato_code||' - '||elencoLiquidazioniRec.liq_stato_desc;
    descr_liquidazione=COALESCE(elencoLiquidazioniRec.liq_desc,'');
    importo_liquidazione=elencoLiquidazioniRec.importo_liquidazione;
    emissione_liquidazione=elencoLiquidazioniRec.liq_emissione_data;      
    
    movgest_id=elencoLiquidazioniRec.movgest_id;
    movgest_ts_id=elencoLiquidazioniRec.movgest_ts_id;
    elem_id=elencoLiquidazioniRec.elem_id;
	liq_id=elencoLiquidazioniRec.liq_id;
   
    	/* cerco il CUP */
	BEGIN
    	SELECT  COALESCE(a.testo,'')
        INTO cup
		from siac_r_liquidazione_attr a,
  			siac_t_attr b
  		where a.attr_id=b.attr_id
  			and a.liq_id=elencoLiquidazioniRec.liq_id
            and b.attr_code='cup' 
            and a.data_cancellazione IS NULL
            and b.data_cancellazione IS NULL;
        IF NOT FOUND THEN
    		cup='';
    	END IF;  
    END;
  
        	/* cerco gli elementi di tipo classe */
    BEGIN
    	for elencoClass in 
          select distinct d_class_tipo.classif_tipo_code, 
          t_class.classif_code, t_class.classif_desc
          from 
           siac_t_class t_class,
           siac_d_class_tipo d_class_tipo,
           siac_r_liquidazione_class r_liq_class
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_liq_class.classif_id=t_class.classif_id
              and r_liq_class.liq_id=elencoLiquidazioniRec.liq_id
              and r_liq_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
              and t_class.data_cancellazione IS NULL
        loop
          IF elencoClass.classif_tipo_code ='GRUPPO_COFOG' THEN
          	cofog=elencoClass.classif_code||' - '||elencoClass.classif_desc;    		
          elsif substr(elencoClass.classif_tipo_code,1,11) ='SIOPE_SPESA' THEN
          	siope=elencoClass.classif_code||' - '||elencoClass.classif_desc;
          elsif substr(elencoClass.classif_tipo_code,1,4) ='PDC_' THEN
          	classif_tipo_code=elencoClass.classif_tipo_code;
            pdc_finanziario_movgest=elencoClass.classif_code||' - '||elencoClass.classif_desc;
           elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_SPESA' THEN
          	transaz_europea=elencoClass.classif_code||' - '||elencoClass.classif_desc;
           elsif elencoClass.classif_tipo_code ='RICORRENTE_SPESA' THEN
          	ricorrente=elencoClass.classif_code||' - '||elencoClass.classif_desc;
           elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_SPESA' THEN
           	perimetro_sanitario=elencoClass.classif_code||' - '||elencoClass.classif_desc;
           elsif elencoClass.classif_tipo_code ='POLITICHE_REGIONALI_UNITARIE' THEN
           	politiche_regionali=elencoClass.classif_code||' - '||elencoClass.classif_desc;           
          end if;
          

        end loop;
        
    END;    

--raise notice 'NUM LIQ. %, ANNO LIQ. %, PDC= %, SIOPE= %, TRANS_EU= %',num_liquidazione,  anno_liquidazione, classif_tipo_code, siope, transaz_europea;

    /* restituisco solo le liquidazioni che:
    	- Non hanno il Piano dei conti al 5° livello
        - non hanno il siope definito
        - non hanno la codifica transazione europea definita */
if classif_tipo_code<>'PDC_V' OR      
      siope='' OR
      transaz_europea='' THEN    
	return next;
end if;

--return next;

nome_ente='';
bil_anno='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
descr_capitolo='';
descr_articolo='';

anno_liquidazione=0;
num_liquidazione=0;
stato_liquidazione='';
descr_liquidazione='';
importo_liquidazione=0;
emissione_liquidazione=NULL;
movgest_id=0;
movgest_ts_id=0;
pdc_finanziario_cap='';
pdc_finanziario_movgest='';
classif_tipo_code='';
cofog='';
transaz_europea='';
siope='';
ricorrente='';
perimetro_sanitario='';
politiche_regionali='';
cup='';
elem_id=0;
liq_id=0;

end loop;


delete from   siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;

raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati delle liquidazioni non trovati.' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'LIQUIDAZIONI',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;