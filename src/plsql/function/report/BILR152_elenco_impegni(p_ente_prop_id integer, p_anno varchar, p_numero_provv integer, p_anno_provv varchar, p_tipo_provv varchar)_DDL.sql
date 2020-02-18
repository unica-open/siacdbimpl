/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR152_elenco_impegni" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  pdce_finanz_code varchar,
  pdce_finanz_descr varchar,
  num_impegno numeric,
  anno_impegno integer,
  num_subimpegno varchar,
  num_mov_origine varchar,
  anno_mov_origine varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  tipo varchar,
  tipo_finanz varchar,
  codice_progetto varchar,
  importo_impegno numeric,
  code_programma varchar,
  code_cofog varchar,
  cup varchar,
  cig varchar,
  desc_motiv_assenza_siope varchar,
  code_motiv_assenza_siope varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 
sqlQuery varchar;

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
pdce_finanz_code:='';
pdce_finanz_descr:='';
num_impegno:=0;
anno_impegno:=0;
num_subimpegno:='';
num_mov_origine:='';
anno_mov_origine:=0;
code_soggetto:='';
desc_soggetto:=0;
tipo:='';
tipo_finanz:='';
codice_progetto:=0;
importo_impegno:=0;
code_programma:='';
code_cofog:='';
cup:='';
cig:='';

anno_eser_int=p_anno ::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with impegni as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                 CASE WHEN d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'                 
                    THEN 'IMP'
                    ELSE 'SUB' end tipo_impegno,
                t_atto_amm.attoamm_numero,
                t_atto_amm.attoamm_anno,
                tipo_atto.attoamm_tipo_code,
                t_movgest_ts_det.movgest_ts_det_importo,
                d_siope_ass_motiv.siope_assenza_motivazione_desc,
                d_siope_ass_motiv.siope_assenza_motivazione_code
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts
                	LEFT JOIN siac_d_siope_assenza_motivazione d_siope_ass_motiv
                      ON (d_siope_ass_motiv.siope_assenza_motivazione_id =t_movgest_ts.siope_assenza_motivazione_id
                          AND d_siope_ass_motiv.data_cancellazione IS NULL),     
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_r_movgest_ts_atto_amm r_movgest_ts_atto,
                siac_t_atto_amm t_atto_amm  ,
                siac_d_atto_amm_tipo	tipo_atto,
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND r_movgest_ts_atto.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND t_atto_amm.attoamm_id=r_movgest_ts_atto.attoamm_id
               AND tipo_atto.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_atto_amm.attoamm_numero=p_numero_provv
                AND t_atto_amm.attoamm_anno=p_anno_provv
                AND tipo_atto.attoamm_tipo_code=p_tipo_provv
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='I'    --impegno  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND r_movgest_ts_atto.data_cancellazione IS NULL
                AND t_atto_amm.data_cancellazione IS NULL
                AND tipo_atto.data_cancellazione IS NULL
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL),
	soggetto_mov as (
    		SELECT r_movgest_ts_sog.movgest_ts_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_movgest_ts_sog r_movgest_ts_sog,
                siac_t_soggetto t_soggetto
            WHERE r_movgest_ts_sog.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_movgest_ts_sog.data_cancellazione IS NULL) ,     
    	soggetto_class as (
    		SELECT r_movgest_ts_sogclasse.movgest_ts_id,
                d_soggetto_classe.soggetto_classe_code,
                d_soggetto_classe.soggetto_classe_desc
            FROM siac_r_movgest_ts_sogclasse  r_movgest_ts_sogclasse,
                siac_d_soggetto_classe d_soggetto_classe
            WHERE r_movgest_ts_sogclasse.soggetto_classe_id=  d_soggetto_classe.soggetto_classe_id
                and r_movgest_ts_sogclasse.ente_proprietario_id=p_ente_prop_id
                AND d_soggetto_classe.data_cancellazione IS NULL  
                AND r_movgest_ts_sogclasse.data_cancellazione IS NULL  ) ,   
    	capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL),
    /* 08/06/2017: il pdce deve essere preso dall'impegno, non dal
    	capitolo */
elenco_pdce_finanz as (        
	SELECT  --r_bil_elem_class.elem_id,
			r_movgest_class.movgest_ts_id,
           COALESCE( t_class.classif_code,'') pdce_code, 
            COALESCE(t_class.classif_desc,'') pdce_desc 
        from --siac_r_bil_elem_class r_bil_elem_class,
        	siac_r_movgest_class r_movgest_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where --t_class.classif_id 					= 	r_bil_elem_class.classif_id
                 t_class.classif_id 					= 	r_movgest_class.classif_id
                 and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                  /* 08/06/2017: prendo solo il V livello */
                -- and d_class_tipo.classif_tipo_code like 'PDC_%'	
                 and d_class_tipo.classif_tipo_code = 'PDC_V'			
                 --and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                   and r_movgest_class.ente_proprietario_id=p_ente_prop_id
                   AND r_movgest_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL    )  ,
        elenco_attrib as(
        	select * from "fnc_bilr152_tab_attrib"(p_ente_prop_id))  ,
        programma as (
        	select t_programma.programma_code,
            	r_movgest_ts_prog.movgest_ts_id
            from siac_r_movgest_ts_programma     r_movgest_ts_prog,
            	siac_t_programma t_programma
            where r_movgest_ts_prog.programma_id= t_programma.programma_id
            	and r_movgest_ts_prog.ente_proprietario_id=p_ente_prop_id
            	and t_programma.data_cancellazione is null
                and r_movgest_ts_prog.data_cancellazione is null) ,
        tipo_finanz_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='TIPO_FINANZIAMENTO' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ),
        cofog_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='GRUPPO_COFOG' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ), 
        programma_cap as(        	     
                select r_bil_elem_class.elem_id,
                	t_class.classif_code, t_class.classif_desc
                from siac_t_class t_class,
                	siac_d_class_tipo d_class_tipo,
                    siac_r_bil_elem_class r_bil_elem_class
                where  t_class.classif_tipo_id= d_class_tipo.classif_tipo_id
                	and r_bil_elem_class.classif_id= t_class.classif_id
                    and d_class_tipo.classif_tipo_code='PROGRAMMA' 
                    and r_bil_elem_class.ente_proprietario_id=p_ente_prop_id
                    and t_class.data_cancellazione is null
                    and d_class_tipo.data_cancellazione is null
                    and r_bil_elem_class.data_cancellazione is null ),                                        
  elencocig as (
  				select  t_attr.attr_code attr_code_cig, 
                  r_movgest_ts_attr.testo testo_cig,
                  r_movgest_ts_attr.movgest_ts_id
                from siac_t_attr t_attr,
                    siac_r_movgest_ts_attr  r_movgest_ts_attr
                where  r_movgest_ts_attr.attr_id=t_attr.attr_id          
                    and t_attr.ente_proprietario_id=p_ente_prop_id        
                	AND upper(t_attr.attr_code) = 'CIG'          
                    and r_movgest_ts_attr.data_cancellazione IS NULL
                    and t_attr.data_cancellazione IS NULL),
    elencocup as (
    			select  t_attr.attr_code attr_code_cup, 
                  r_movgest_ts_attr.testo testo_cup,
                  r_movgest_ts_attr.movgest_ts_id
                from siac_t_attr t_attr,
                       siac_r_movgest_ts_attr  r_movgest_ts_attr
                where  r_movgest_ts_attr.attr_id=t_attr.attr_id          
                        and t_attr.ente_proprietario_id=p_ente_prop_id  
                        AND upper(t_attr.attr_code) = 'CUP'          
                        and r_movgest_ts_attr.data_cancellazione IS NULL
                        and t_attr.data_cancellazione IS NULL)                                           
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
	COALESCE(elenco_pdce_finanz.pdce_code,'')::varchar pdce_finanz_code,
    COALESCE(elenco_pdce_finanz.pdce_desc,'')::varchar pdce_finanz_descr,
    impegni.movgest_numero::numeric num_impegno,
    impegni.movgest_anno::integer anno_impegno,
    impegni.movgest_ts_code::varchar num_subimpegno,
    CASE WHEN COALESCE(elenco_attrib.numero_riaccertato,'') = '' 
    	THEN COALESCE(elenco_attrib.numero_origine_plur,'')
        ELSE COALESCE(elenco_attrib.numero_riaccertato,'') end num_mov_origine,
    CASE WHEN COALESCE(elenco_attrib.anno_riaccertato,'') = '' 
    	THEN COALESCE(elenco_attrib.anno_origine_plur,'')
        ELSE COALESCE(elenco_attrib.anno_riaccertato,'') end anno_mov_origine,
    CASE WHEN COALESCE(soggetto_mov.soggetto_code,'') =''
    	THEN COALESCE(soggetto_class.soggetto_classe_code,'')::varchar
        ELSE COALESCE(soggetto_mov.soggetto_code,'')::varchar end code_soggetto,
    CASE WHEN COALESCE(soggetto_mov.soggetto_desc,'') =''
    	THEN COALESCE(soggetto_class.soggetto_classe_desc,'')::varchar
        ELSE COALESCE(soggetto_mov.soggetto_desc,'')::varchar end desc_soggetto,
    CASE WHEN upper(COALESCE(elenco_attrib.flag_prenotazione,'')) = 'S'
    	THEN 'PR'::varchar 
        ELSE impegni.tipo_impegno::varchar  end tipo,
    COALESCE(tipo_finanz_cap.classif_code,'')::varchar tipo_finanz,
    COALESCE(programma.programma_code,'') codice_progetto,
	impegni.movgest_ts_det_importo::numeric importo_impegno,
    COALESCE(programma_cap.classif_code,'') code_programma,
    COALESCE(cofog_cap.classif_code,'') code_cofog,
    COALESCE(elencocup.testo_cup,'')::varchar cup,
    COALESCE(elencocig.testo_cig,'')::varchar cig,
    COALESCE(impegni.siope_assenza_motivazione_desc)::varchar desc_motiv_assenza_siope,
    COALESCE(impegni.siope_assenza_motivazione_code)::varchar code_motiv_assenza_siope
FROM impegni
	LEFT JOIN soggetto_mov on soggetto_mov.movgest_ts_id=impegni.movgest_ts_id
    LEFT JOIN soggetto_class on soggetto_class.movgest_ts_id=impegni.movgest_ts_id 
	LEFT JOIN capitoli on capitoli.movgest_id = impegni.movgest_id
    LEFT JOIN elenco_pdce_finanz on elenco_pdce_finanz.movgest_ts_id = impegni.movgest_ts_id 
    LEFT join elenco_attrib on elenco_attrib.movgest_ts_id = impegni.movgest_ts_id
    LEFT join programma on programma.movgest_ts_id = impegni.movgest_ts_id
    LEFT join tipo_finanz_cap on tipo_finanz_cap.elem_id = capitoli.elem_id 
    LEFT join elencocig on elencocig.movgest_ts_id=impegni.movgest_ts_id  
    LEFT join elencocup on elencocup.movgest_ts_id=impegni.movgest_ts_id  
    LEFT join cofog_cap on cofog_cap.elem_id = capitoli.elem_id
    LEFT join programma_cap on programma_cap.elem_id = capitoli.elem_id         
ORDER BY anno_impegno, num_impegno, tipo, num_subimpegno) query_totale;

RTN_MESSAGGIO:='Fine estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;