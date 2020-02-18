/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR097_elenco_accertamenti_trans_elem_non_completa" (
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
  anno_accertamento integer,
  num_accertamento varchar,
  tipo_accertamento varchar,
  stato_accertamento varchar,
  descr_accertamento varchar,
  importo_accertamento numeric,
  scadenza_accertamento date,
  movgest_id integer,
  movgest_ts_id integer,
  pdc_finanziario_cap varchar,
  pdc_finanziario_movgest varchar,
  classif_id integer,
  classif_tipo_code varchar,
  transaz_europea varchar,
  siope varchar,
  ricorrente varchar,
  perimetro_sanitario varchar,
  elem_id integer
) AS
$body$
DECLARE
 elencoImpegniRec record;
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
anno_accertamento=0;
num_accertamento='';
tipo_accertamento='';
stato_accertamento='';
descr_accertamento='';
importo_accertamento=0;
scadenza_accertamento=NULL;
movgest_id=0;
movgest_ts_id=0;
pdc_finanziario_cap='';
pdc_finanziario_movgest='';
classif_tipo_code='';
transaz_europea='';
siope='';
ricorrente='';
perimetro_sanitario='';
elem_id=0;

annoCompetenza_int =p_anno ::INTEGER;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati degli accertamenti ';

for elencoImpegniRec IN
	select capitolo.elem_id,capitolo.elem_code,capitolo.elem_desc,
    	capitolo.elem_code2, capitolo.elem_desc2,capitolo.elem_code3,         
        t_mov_gest.movgest_id,anno_eserc.anno anno_bil,
        t_mov_gest.movgest_numero NUM_accertamento,t_mov_gest.movgest_anno ANNO_COMP_accertamento,  
        t_movgest_ts_det.movgest_ts_det_importo importo_accertamento, 
        t_movgest_ts.movgest_ts_scadenza_data scadenza_data,
        t_mov_gest.movgest_desc, anno_eserc.anno BIL_ANNO,
        t_ente_prop.ente_denominazione, d_movgest_stato.movgest_stato_code,
        d_movgest_stato.movgest_stato_desc,    
        t_mov_gest.movgest_id, t_movgest_ts.movgest_ts_id,              
        pdc.classif_code||' - '||pdc.classif_desc pdc_finanziario_cap
        from siac_t_movgest t_mov_gest,
            siac_d_movgest_tipo d_mov_gest_tipo,
            siac_t_movgest_ts_det t_movgest_ts_det,
            siac_d_movgest_ts_tipo   ts_mov_tipo, 
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,           
            siac_r_movgest_bil_elem r_movgest_bil_elem, 
            siac_d_movgest_stato 	d_movgest_stato,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_t_bil			bilancio,
            siac_t_periodo      anno_eserc,
            siac_t_ente_proprietario	t_ente_prop,
            siac_t_bil_elem		capitolo,
            siac_r_bil_elem_class r_capitolo_pdc,
     		siac_t_class pdc,
     		siac_d_class_tipo pdc_tipo,
            siac_t_movgest_ts t_movgest_ts               	                        
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
                and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
				AND r_capitolo_pdc.classif_id 			= pdc.classif_id
  				AND pdc.classif_tipo_id 				= pdc_tipo.classif_tipo_id					
                AND capitolo.elem_id 					= 	r_capitolo_pdc.elem_id
				AND pdc_tipo.classif_tipo_code like 'PDC_%'			                												
                AND d_mov_gest_tipo.movgest_tipo_code = 'A'
                and anno_eserc.anno=p_anno
                and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
                and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
               -- and t_mov_gest.movgest_anno =annoCompetenza_int
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
                and r_movgest_ts_stato.data_cancellazione IS NULL
                and r_movgest_ts_stato.validita_fine is  null
                and d_movgest_stato.data_cancellazione IS NULL
                and r_capitolo_pdc.data_cancellazione IS NULL
                and pdc.data_cancellazione IS NULL
                and pdc_tipo.data_cancellazione IS NULL
                ORDER BY  t_mov_gest.movgest_anno, t_mov_gest.movgest_numero
                --capitolo.elem_code, capitolo.elem_code2
loop
	nome_ente=elencoImpegniRec.ente_denominazione;
    bil_anno=elencoImpegniRec.BIL_ANNO;
    anno_capitolo=elencoImpegniRec.BIL_ANNO;
    num_capitolo=elencoImpegniRec.elem_code;
    cod_articolo=elencoImpegniRec.elem_code2;
    ueb=elencoImpegniRec.elem_code3;
    descr_capitolo=COALESCE(elencoImpegniRec.elem_desc,'');
    descr_articolo=COALESCE(elencoImpegniRec.elem_desc2,'');

    pdc_finanziario_cap=COALESCE(elencoImpegniRec.pdc_finanziario_cap,'');

    anno_accertamento=elencoImpegniRec.ANNO_COMP_accertamento;
    num_accertamento=elencoImpegniRec.NUM_accertamento;
    
    stato_accertamento=elencoImpegniRec.movgest_stato_code||' - '||elencoImpegniRec.movgest_stato_desc;
    descr_accertamento=COALESCE(elencoImpegniRec.movgest_desc,'');
    importo_accertamento=elencoImpegniRec.importo_accertamento;
    scadenza_accertamento=elencoImpegniRec.scadenza_data;      
    
    movgest_id=elencoImpegniRec.movgest_id;
    movgest_ts_id=elencoImpegniRec.movgest_ts_id;
    elem_id=elencoImpegniRec.elem_id;

    
    
  
        	/* cerco gli elementi di tipo classe */
    BEGIN
    	for elencoClass in 
          select distinct d_class_tipo.classif_tipo_code, 
          t_class.classif_code, t_class.classif_desc
          from 
           siac_t_class t_class,
           siac_d_class_tipo d_class_tipo,
           siac_r_movgest_class r_movgest_class
          where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
              and r_movgest_class.classif_id=t_class.classif_id
              and r_movgest_class.movgest_ts_id=elencoImpegniRec.movgest_ts_id
              and r_movgest_class.data_cancellazione IS NULL
              and d_class_tipo.data_cancellazione IS NULL
              and t_class.data_cancellazione IS NULL
        loop          
          IF substr(elencoClass.classif_tipo_code,1,13) ='SIOPE_ENTRATA' THEN
          	siope=elencoClass.classif_code||' - '||elencoClass.classif_desc;
          elsif substr(elencoClass.classif_tipo_code,1,4) ='PDC_' THEN
          	classif_tipo_code=elencoClass.classif_tipo_code;
            pdc_finanziario_movgest=elencoClass.classif_code||' - '||elencoClass.classif_desc;
           elsif elencoClass.classif_tipo_code ='TRANSAZIONE_UE_ENTRATA' THEN
          	transaz_europea=elencoClass.classif_code||' - '||elencoClass.classif_desc;
           elsif elencoClass.classif_tipo_code ='RICORRENTE_ENTRATA' THEN
          	ricorrente=elencoClass.classif_code||' - '||elencoClass.classif_desc;
           elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_ENTRATA' THEN
           	perimetro_sanitario=elencoClass.classif_code||' - '||elencoClass.classif_desc;           
          end if;
          

        end loop;
        
    END;
        

    /* restituisco solo gli accertamenti che:
    	- Non hanno il Piano dei conti al 5° livello
        - non hanno il siope definito
        - non hanno la codifica transazione europea definita
        - non hanno il campo ricorrente definito 
        - non hanno il campo capitoli perimetro sanitario definito */
if classif_tipo_code<>'PDC_V' OR 
      siope='' OR
      transaz_europea='' OR
      ricorrente='' OR
      perimetro_sanitario ='' THEN     
	return next;
end if;

nome_ente='';
bil_anno='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
descr_capitolo='';
descr_articolo='';

anno_accertamento=0;
num_accertamento='';
tipo_accertamento='';
stato_accertamento='';
descr_accertamento='';
importo_accertamento=0;
scadenza_accertamento=NULL;
movgest_id=0;
movgest_ts_id=0;
pdc_finanziario_cap='';
pdc_finanziario_movgest='';
classif_tipo_code='';
transaz_europea='';
siope='';
ricorrente='';
perimetro_sanitario='';
elem_id=0;

end loop;


raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati degli accertamenti non trovati.' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'IMPEGNI',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;