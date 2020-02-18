/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR096_elenco_impegni_spesa_non_completi" (
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
  anno_impegno integer,
  num_impegno varchar,
  tipo_impegno varchar,
  stato_impegno varchar,
  descr_impegno varchar,
  importo_impegno numeric,
  scadenza_impegno date,
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
  missione varchar,
  programma varchar,
  perimetro_sanitario varchar,
  politiche_regionali varchar,
  cup varchar,
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
 v_fam_missioneprogramma varchar :='00001';
 v_fam_titolomacroaggregato varchar := '00002';

BEGIN
 
nome_ente='';
bil_anno='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
descr_capitolo='';
descr_articolo='';
anno_impegno=0;
num_impegno='';
tipo_impegno='';
stato_impegno='';
descr_impegno='';
importo_impegno=0;
scadenza_impegno=NULL;
movgest_id=0;
movgest_ts_id=0;
pdc_finanziario_cap='';
pdc_finanziario_movgest='';
classif_tipo_code='';
cofog='';
transaz_europea='';
siope='';
ricorrente='';
missione='';
programma='';
perimetro_sanitario='';
politiche_regionali='';
cup='';
elem_id=0;

annoCompetenza_int =p_anno ::INTEGER;

  
    select fnc_siac_random_user()
	into	user_table;
	

raise notice 'Caricamento struttura dei capitoli' ;
/* insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
--------siac_v_mis_pro_tit_macr_anni 
 where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/

-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_mis_pro_tit_mac_riga_anni
select  missione.missione_tipo_desc,
missione.missione_id,
missione.missione_code,
missione.missione_desc,
missione.missione_validita_inizio,
missione.missione_validita_fine,
programma.programma_tipo_desc,
programma.programma_id,
programma.programma_code,
programma.programma_desc,
programma.programma_validita_inizio,
programma.programma_validita_fine,
titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
titusc.titusc_validita_inizio,
titusc.titusc_validita_fine,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
macroag.macroag_validita_inizio,
macroag.macroag_validita_fine,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 06/09/2016: start filtro per mis-prog-macro*/
/* 28/09/2016: nei report di utilità non deve essere inserito 
    	questo filtro */         
  --, siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 --AND programma.programma_id = progmacro.classif_a_id
-- AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati degli impegni ';

for elencoImpegniRec IN
	select capitolo.elem_id,capitolo.elem_code,capitolo.elem_desc,
    	capitolo.elem_code2, capitolo.elem_desc2,capitolo.elem_code3,         
        t_mov_gest.movgest_id,anno_eserc.anno anno_bil,
        t_mov_gest.movgest_numero NUM_IMPEGNO,t_mov_gest.movgest_anno ANNO_COMP_IMPEGNO,  
        t_movgest_ts_det.movgest_ts_det_importo importo_impegno, 
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
                AND d_mov_gest_tipo.movgest_tipo_code = 'I'
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

    anno_impegno=elencoImpegniRec.ANNO_COMP_IMPEGNO;
    num_impegno=elencoImpegniRec.NUM_IMPEGNO;
    
    stato_impegno=elencoImpegniRec.movgest_stato_code||' - '||elencoImpegniRec.movgest_stato_desc;
    descr_impegno=COALESCE(elencoImpegniRec.movgest_desc,'');
    importo_impegno=elencoImpegniRec.importo_impegno;
    scadenza_impegno=elencoImpegniRec.scadenza_data;      
    
    movgest_id=elencoImpegniRec.movgest_id;
    movgest_ts_id=elencoImpegniRec.movgest_ts_id;
    elem_id=elencoImpegniRec.elem_id;

    
    	/* cerco il CUP */
      SELECT a.testo
      INTO cup
      from siac_r_movgest_ts_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.movgest_ts_id=elencoImpegniRec.movgest_ts_id
          and b.attr_code='cup' 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL;
      IF NOT FOUND THEN
          cup='';
      END IF;  

  
        	/* cerco gli elementi di tipo classe */
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
     --    elsif elencoClass.classif_tipo_code ='MISSIONE' THEN
     --   	 missione=elencoClass.classif_code||' - '||elencoClass.classif_desc;
    --    elsif elencoClass.classif_tipo_code ='PROGRAMMA' THEN
     --    	 programma=elencoClass.classif_code||' - '||elencoClass.classif_desc;
         elsif elencoClass.classif_tipo_code ='PERIMETRO_SANITARIO_SPESA' THEN
          perimetro_sanitario=elencoClass.classif_code||' - '||elencoClass.classif_desc;
         elsif elencoClass.classif_tipo_code ='POLITICHE_REGIONALI_UNITARIE' THEN
          politiche_regionali=elencoClass.classif_code||' - '||elencoClass.classif_desc;          
         elsif elencoClass.classif_tipo_code = 'TIPO_IMPEGNO' THEN
          tipo_impegno=elencoClass.classif_desc;
        end if;
          

      end loop;        

    
      select distinct d_class_tipo.classif_tipo_code|| ' - ' || t_class.classif_code, 
      strutt_capitoli.missione_code|| ' - ' || strutt_capitoli.missione_desc missione
      into programma, missione            
      from 
       siac_t_class t_class,
       siac_d_class_tipo d_class_tipo,
       siac_r_bil_elem_class r_bil_elem_class,
       siac_rep_mis_pro_tit_mac_riga_anni strutt_capitoli
      where  d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
          and r_bil_elem_class.classif_id=t_class.classif_id
          and r_bil_elem_class.elem_id=elencoImpegniRec.elem_id
          and strutt_capitoli.programma_id=t_class.classif_id
          and d_class_tipo.classif_tipo_code in ('PROGRAMMA')
          and r_bil_elem_class.data_cancellazione IS NULL
          and d_class_tipo.data_cancellazione IS NULL
          and t_class.data_cancellazione IS NULL;
     IF NOT FOUND THEN
      missione='';
      programma='';
     end if;    	
    

    /* restituisco solo gli impegni che:
    	- Non hanno il Piano dei conti al 5° livello
        - non hanno il cofog definito
        - non hanno il siope definito
        - non hanno la codifica transazione europea definita
        - non hanno il campo ricorrente definito */
if classif_tipo_code<>'PDC_V' OR 
      cofog='' OR
      siope='' OR
      transaz_europea='' OR
      ricorrente='' THEN     
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

anno_impegno=0;
num_impegno='';
tipo_impegno='';
stato_impegno='';
descr_impegno='';
importo_impegno=0;
scadenza_impegno=NULL;
movgest_id=0;
movgest_ts_id=0;
pdc_finanziario_cap='';
pdc_finanziario_movgest='';
classif_tipo_code='';
cofog='';
transaz_europea='';
siope='';
ricorrente='';
missione='';
programma='';
perimetro_sanitario='';
politiche_regionali='';
cup='';
elem_id=0;

end loop;


delete from   siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;

raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati degli impegni non trovati.' ;
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