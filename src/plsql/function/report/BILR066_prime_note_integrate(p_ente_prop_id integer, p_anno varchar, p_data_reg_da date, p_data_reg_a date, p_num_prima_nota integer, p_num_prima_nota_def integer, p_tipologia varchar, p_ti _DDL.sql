/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR066_prime_note_integrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_num_prima_nota integer,
  p_num_prima_nota_def integer,
  p_tipologia varchar,
  p_tipo_evento varchar,
  p_evento varchar
)
RETURNS TABLE (
  nome_ente varchar,
  num_movimento varchar,
  cod_beneficiario varchar,
  ragione_sociale varchar,
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  classif_bilancio varchar,
  imp_movimento numeric,
  descr_movimento varchar,
  num_prima_nota integer,
  data_registrazione date,
  stato_prima_nota varchar,
  descr_prima_nota varchar,
  cod_causale varchar,
  num_riga integer,
  cod_conto varchar,
  descr_riga varchar,
  importo_dare numeric,
  importo_avere numeric,
  key_movimento integer,
  evento_tipo_code varchar,
  evento_code varchar,
  causale_ep_tipo_code varchar,
  pnota_stato_code varchar,
  num_prima_nota_def integer,
  data_registrazione_def date,
  code_missione varchar,
  desc_missione varchar,
  code_programma varchar,
  desc_programma varchar,
  miss_prog_display varchar
) AS
$body$
DECLARE
elenco_prime_note record;
dati_movimento record;
elenco_tipo_classif record;
dati_classif	record;
idMacroAggreg	integer;
idProgramma		integer;
idCategoria		integer;
prec_num_prima_nota integer;
prec_num_movimento_key integer;
prec_num_movimento varchar;
prec_num_capitolo varchar;
prec_num_articolo varchar;
prec_ueb varchar;
prec_descr_movimento varchar;
prec_cod_beneficiario varchar;
prec_ragione_sociale varchar;
prec_imp_movimento numeric;
prec_classif_bilancio varchar;
elem_id_curr integer;
elem_id_prec integer;
code_missione_prec varchar;
desc_missione_prec varchar;
code_programma_prec varchar;
desc_programma_prec varchar;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
v_fam_missioneprogramma varchar;
v_fam_titolomacroaggregato varchar;
sub_impegno VARCHAR;
soggetto_code_mod VARCHAR;
soggetto_desc_mod VARCHAR;

BEGIN
	nome_ente='';
    num_movimento='';
    cod_beneficiario='';
    ragione_sociale='';
    num_capitolo='';
    num_articolo='';
    ueb='';
    classif_bilancio='';
    imp_movimento=0;
    descr_movimento='';
    num_prima_nota=0;
    num_prima_nota_def=0;
    data_registrazione=NULL;
    data_registrazione_def=NULL;
    stato_prima_nota='';
    descr_prima_nota='';
    cod_causale='';
    num_riga=0;
    cod_conto='';
    descr_riga='';
    importo_dare=0;
    importo_avere=0;
    key_movimento=0;
    evento_tipo_code='';
    evento_code='';
    causale_ep_tipo_code='';
    pnota_stato_code='';
    
    
    prec_num_prima_nota=0;
	prec_num_movimento_key =0;
	prec_num_movimento ='';
    prec_descr_movimento='';
    prec_num_capitolo='';
	prec_num_articolo='';
    prec_ueb='';
    prec_cod_beneficiario='';
    prec_ragione_sociale='';
    prec_imp_movimento=0;
    prec_classif_bilancio='';
    
	v_fam_missioneprogramma :='00001';
	v_fam_titolomacroaggregato := '00002';
    sub_impegno='';
    soggetto_code_mod='';
    soggetto_desc_mod='';
    
    code_missione:='';
    desc_missione:='';
    code_programma:='';
    desc_programma:='';
    miss_prog_display:='';
                
    elem_id_prec:=0;
    code_missione_prec :='';
	desc_missione_prec  :='';
	code_programma_prec  :='';
	desc_programma_prec  :='';

    select fnc_siac_random_user()
	into	user_table;
	

-- 05/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 02/09/2016: start filtro per mis-prog-macro*/
   -- , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 02/09/2016: start filtro per mis-prog-macro*/
 --AND programma.programma_id = progmacro.classif_a_id
-- AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 


    /* carico su una tabella temporanea i dati della struttura dei capitolo di entrata */
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

	/* estrazione dei dati delle prime note */
    

--if (p_data_reg_da is NULL OR p_data_reg_a is NULL)  THEN	    
    for elenco_prime_note IN
    select  ente_prop.ente_denominazione	nome_ente,
        r_ev_reg_movfin.campo_pk_id 	key_movimento,
        tipo_evento.evento_tipo_code, d_tipo_causale.causale_ep_tipo_code,  
        evento.evento_code,d_coll_tipo.collegamento_tipo_code,
        prima_nota.pnota_numero num_prima_nota, prima_nota.pnota_desc,prima_nota.pnota_data, 
        pnota_stato.pnota_stato_code, prima_nota.pnota_progressivogiornale num_prima_nota_def,
            pnota_stato.pnota_stato_desc,pdce_conto.pdce_conto_code codice_conto,
            pdce_conto.pdce_conto_desc descr_riga,
            prima_nota.pnota_dataregistrazionegiornale pnota_data_def,
             causale_ep.causale_ep_code cod_causale, causale_ep.causale_ep_desc, mov_ep.movep_code,
            mov_ep.movep_desc, mov_ep_det.movep_det_code num_riga, mov_ep_det.movep_det_desc,
            mov_ep_det.movep_det_segno, mov_ep_det.movep_det_importo,
            --INC000006526089 09/11/2022:
            --Missione e programma per le prime note libere sono 
            --gestite al fondo della procedura.
            prima_nota.pnota_id
          --  COALESCE(programmi.programma_code,'') programma_code_lib,
          --  COALESCE(programmi.programma_desc,'') programma_desc_lib,
          --  COALESCE(missioni.missione_code,'') missione_code_lib,
          --  COALESCE(missioni.missione_desc,'') missione_desc_lib
    from siac_t_ente_proprietario	ente_prop,
            siac_t_periodo	 		anno_eserc,	
            siac_t_bil	 			bilancio,
            siac_t_prima_nota prima_nota,
              --23/07/2021 SIAC-8295.
              -- Aggiunto il filtro sull'ambito FIN            
            siac_d_ambito amb,
            siac_t_mov_ep_det	mov_ep_det,
            --SIAC-8656 20/10/2022.
            --Aggiunta gestione di missione/programma per le prime
            --note libere.
            --INC000006526089 09/11/2022:
            --Missione e programma per le prime note libere sono 
            --gestite al fondo della procedura.
			/*	left join (select class_progr.classif_code programma_code,
                			class_progr.classif_desc programma_desc,
                            r_mov_ep_det_class_progr.movep_det_id
                          from siac_t_class class_progr,
                          	siac_d_class_tipo tipo_class_progr,
                            siac_r_mov_ep_det_class r_mov_ep_det_class_progr
                          where tipo_class_progr.classif_tipo_id=class_progr.classif_tipo_id
                          and r_mov_ep_det_class_progr.classif_id=class_progr.classif_id
                          and tipo_class_progr.ente_proprietario_id=p_ente_prop_id
                          and   tipo_class_progr.classif_tipo_code='PROGRAMMA'
                          and  r_mov_ep_det_class_progr.data_cancellazione IS NULL 
                          and class_progr.data_cancellazione IS NULL) programmi                          
                   on programmi.movep_det_id=mov_ep_det.movep_det_id
				left join (select class_miss.classif_code missione_code,
                			class_miss.classif_desc missione_desc,
                            r_mov_ep_det_class_miss.movep_det_id
                          from siac_t_class class_miss,
                          	siac_d_class_tipo tipo_class_miss,
                            siac_r_mov_ep_det_class r_mov_ep_det_class_miss
                          where tipo_class_miss.classif_tipo_id=class_miss.classif_tipo_id
                          and r_mov_ep_det_class_miss.classif_id=class_miss.classif_id
                          and tipo_class_miss.ente_proprietario_id=p_ente_prop_id
                          and   tipo_class_miss.classif_tipo_code='MISSIONE'
                          and  r_mov_ep_det_class_miss.data_cancellazione IS NULL 
                          and class_miss.data_cancellazione IS NULL) missioni                   
                  on missioni.movep_det_id=mov_ep_det.movep_det_id, */           
            siac_r_prima_nota_stato r_pnota_stato,
            siac_d_prima_nota_stato pnota_stato,
            siac_t_pdce_conto	pdce_conto,
            siac_t_causale_ep	causale_ep,
            siac_d_causale_ep_tipo d_tipo_causale,
            siac_t_mov_ep		mov_ep
            LEFT JOIN siac_t_reg_movfin	reg_movfin
            on (reg_movfin.regmovfin_id=mov_ep.regmovfin_id 
            	AND reg_movfin.data_cancellazione IS NULL) 
            LEFT JOIN siac_r_evento_reg_movfin  r_ev_reg_movfin        
            on (r_ev_reg_movfin.regmovfin_id=reg_movfin.regmovfin_id 
            	and r_ev_reg_movfin.data_cancellazione IS NULL)
            LEFT JOIN siac_d_evento		evento
            on (evento.evento_id=r_ev_reg_movfin.evento_id
            	AND evento.data_cancellazione IS NULL)
            LEFT JOIN siac_d_evento_tipo	tipo_evento
            on (tipo_evento.evento_tipo_id=evento.evento_tipo_id
            	AND tipo_evento.data_cancellazione IS NULL)  
            LEFT JOIN siac_d_collegamento_tipo    d_coll_tipo 
            on (d_coll_tipo.collegamento_tipo_id=evento.collegamento_tipo_id
            	and  d_coll_tipo.data_cancellazione is NULL) 
    where bilancio.periodo_id=anno_eserc.periodo_id
            and anno_eserc.ente_proprietario_id=ente_prop.ente_proprietario_id	
            and prima_nota.bil_id=bilancio.bil_id
            and prima_nota.ente_proprietario_id=ente_prop.ente_proprietario_id
            -- QUALE JOIN è corretto???
             and prima_nota.pnota_id=mov_ep.regep_id
            -- QUALE JOIN è corretto??? and prima_nota.pnota_id=mov_ep.regmovfin_id
            and mov_ep.movep_id=mov_ep_det.movep_id
            and r_pnota_stato.pnota_id=prima_nota.pnota_id
            and pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
            and pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
            and causale_ep.causale_ep_id=mov_ep.causale_ep_id
            and d_tipo_causale.causale_ep_tipo_id=causale_ep.causale_ep_tipo_id 
            and amb.ambito_id=prima_nota.ambito_id
            and ente_prop.ente_proprietario_id=p_ente_prop_id   
            and anno_eserc.anno=p_anno 
            AND (((p_data_reg_da is NULL OR p_data_reg_a is NULL) 
            	OR (p_data_reg_da is NOT NULL AND p_data_reg_a is NOT NULL 
                	AND prima_nota.pnota_data BETWEEN p_data_reg_da ::timestamp AND (p_data_reg_a+1) ::timestamp))
 			/* 30/01/2017: il filtro sulle date avviene anche sulla data definitiva */
              OR ((p_data_reg_da is NULL OR p_data_reg_a is NULL) 
            	OR (p_data_reg_da is NOT NULL AND p_data_reg_a is NOT NULL 
                	AND (prima_nota.pnota_dataregistrazionegiornale is not null 
                     AND prima_nota.pnota_dataregistrazionegiornale BETWEEN p_data_reg_da ::timestamp AND (p_data_reg_a+1) ::timestamp))))                    
            /* 24/01/2017: aggiunto filtro sul numero provvisorio della prima nota */
            AND (p_num_prima_nota IS NULL OR (p_num_prima_nota IS NOT NULL    
            					AND prima_nota.pnota_numero =  p_num_prima_nota)) 
 			/* 24/01/2017: aggiunto filtro sul numero definitivo della prima nota */
            AND (p_num_prima_nota_def IS NULL OR (p_num_prima_nota_def IS NOT NULL    
            					AND prima_nota.pnota_progressivogiornale =  p_num_prima_nota_def))                                                     
			/* 30/01/2017: spostati nella procedura i filtri che prima erano sul report */
            AND ((trim(p_tipologia) <> 'Tutte' AND d_tipo_causale.causale_ep_tipo_code =p_tipologia) OR
            	(trim(p_tipologia) = 'Tutte'))
            AND ((trim(p_tipo_evento) <> 'Tutti' AND tipo_evento.evento_tipo_code =p_tipo_evento) OR
            	(trim(p_tipo_evento) = 'Tutti'))                   
            AND ((trim(p_evento) <> 'Tutti' AND  evento.evento_code = p_evento)  OR
					(trim(p_evento) = 'Tutti' ))            
            AND pnota_stato.pnota_stato_code <> 'A'  
              --23/07/2021 SIAC-8295.
              -- Aggiunto il filtro sull'ambito FIN            
            and amb.ambito_code='AMBITO_FIN'     
            and ente_prop.data_cancellazione is NULL
            and bilancio.data_cancellazione is NULL
            and anno_eserc.data_cancellazione is NULL
            and prima_nota.data_cancellazione is NULL
            and mov_ep.data_cancellazione is NULL
            and mov_ep_det.data_cancellazione is NULL
            and r_pnota_stato.data_cancellazione is NULL
            and pnota_stato.data_cancellazione is NULL
            and pdce_conto.data_cancellazione is NULL
            and causale_ep.data_cancellazione is NULL
            and d_tipo_causale.data_cancellazione is NULL
            ORDER BY num_prima_nota,  num_riga

        
            loop
            
            nome_ente=elenco_prime_note.nome_ente;    	    	
            num_prima_nota=elenco_prime_note.num_prima_nota;
            num_prima_nota_def= COALESCE(elenco_prime_note.num_prima_nota_def,0);
            data_registrazione=elenco_prime_note.pnota_data;
            data_registrazione_def=elenco_prime_note.pnota_data_def;
            stato_prima_nota=elenco_prime_note.pnota_stato_desc;
            descr_prima_nota=elenco_prime_note.pnota_desc;
            cod_causale=elenco_prime_note.cod_causale;
            num_riga=elenco_prime_note.num_riga::INTEGER;
            cod_conto=elenco_prime_note.codice_conto;
            descr_riga=elenco_prime_note.descr_riga;
            key_movimento=elenco_prime_note.key_movimento;
            evento_tipo_code=elenco_prime_note.evento_tipo_code;
            evento_code=elenco_prime_note.evento_code;
            causale_ep_tipo_code=elenco_prime_note.causale_ep_tipo_code;
            pnota_stato_code=elenco_prime_note.pnota_stato_code;
            
            if upper(elenco_prime_note.movep_det_segno)='AVERE' THEN                
                  importo_dare=0;
                  importo_avere=elenco_prime_note.movep_det_importo;
                
            ELSE                
                  importo_dare=elenco_prime_note.movep_det_importo;
                  importo_avere=0;                            
            end if;
                        
                /* Tipo Impegno o Tipo Accertamento */
--raise notice 'Gestisco tipo_code = %, evento_code =%, collegamento_code =%',
--	           elenco_prime_note.evento_tipo_code, elenco_prime_note.evento_code,
--                elenco_prime_note.collegamento_tipo_code;  

--raise notice 'CHIAVE MOV = %, NUM PN PROVV = %',   elenco_prime_note.key_movimento,elenco_prime_note.num_prima_nota;                  
--raise notice 'Tipo: %. Num mov % (prec %). numPnota % (prec %)',elenco_prime_note.evento_tipo_code, elenco_prime_note.key_movimento,prec_num_movimento_key, elenco_prime_note.num_prima_nota,prec_num_prima_nota;               
            if elenco_prime_note.evento_tipo_code='I' OR
                    elenco_prime_note.evento_tipo_code='A' THEN				                 
                
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                                  
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;

                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE
                    	/* impegno o accertamento: devo andare sulla tabella
                        	siac_t_movgest 
                           Devo testare tutti i possibili codici!!*/	
                       -- raise notice 'Evento %', elenco_prime_note.evento_code;
                   /* if elenco_prime_note.evento_code = 'IMP-INS' OR
                    	elenco_prime_note.evento_code = 'MIM-INS-I' OR
                        elenco_prime_note.evento_code = 'MIM-INS-S' OR
                        elenco_prime_note.evento_code = 'IMP-PRG' OR
                    	elenco_prime_note.evento_code = 'ACC-INS' OR
                        elenco_prime_note.evento_code = 'MAC-ANN' OR
                        elenco_prime_note.evento_code = 'MAC-INS-I' OR
                        elenco_prime_note.evento_code = 'MAC-INS-S' THEN  */   
                  -- raise notice 'COLL_TIPO = %', elenco_prime_note.collegamento_tipo_code;
                  -- raise notice 'tipo_EVENTO = %', elenco_prime_note.evento_tipo_code;
                    if elenco_prime_note.collegamento_tipo_code in('I','A') THEN                                                                  
                        SELECT movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                            bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                            bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                            ts_det_movgest.movgest_ts_det_importo imp_movimento,
                            d_soggetto_classe.soggetto_classe_desc,
                            d_soggetto_classe.soggetto_classe_code
                            INTO dati_movimento 
                              from siac_t_movgest movgest,                         
                               siac_t_movgest_ts_det ts_det_movgest,
                               siac_r_movgest_bil_elem  r_movgest_bil_elem,
                               siac_t_bil_elem		bil_elem,
                               siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                                siac_t_movgest_ts	ts_movgest                      
                               LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                              on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id and r_mov_gest_ts_sog.data_cancellazione is NULL)  
                              LEFT join siac_t_soggetto		soggetto
                              on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id 
                              	and soggetto.data_cancellazione is NULL)  
                              LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL)
                              where ts_movgest.movgest_id=movgest.movgest_id
                              and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                              and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                              and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                              and movgest.movgest_id= elenco_prime_note.key_movimento
                              and bil_elem.ente_proprietario_id=p_ente_prop_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                              and movgest.data_cancellazione is null
                              and ts_movgest.data_cancellazione is null
                              and ts_det_movgest.data_cancellazione is null
                              and r_movgest_bil_elem.data_cancellazione is null
                              and bil_elem.data_cancellazione is null
                              and d_movgest_ts_det_tipo.data_cancellazione is null;                          
                        IF NOT FOUND THEN
                        	/* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                           -- RAISE EXCEPTION 'Impegno/accertamento senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                           -- return;
                        	descr_movimento='Non esiste il movimento';	                  
                        END IF;
                        sub_impegno='';
                        soggetto_code_mod='';
    					soggetto_desc_mod='';
                        	-- SubImpegno o SubAccertamento
                    ELSIF elenco_prime_note.collegamento_tipo_code in('SI','SA') THEN                     
						SELECT movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                            bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                            bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                            ts_det_movgest.movgest_ts_det_importo imp_movimento, ts_movgest.movgest_ts_code,
                            d_soggetto_classe.soggetto_classe_desc,
                            d_soggetto_classe.soggetto_classe_code
                            INTO dati_movimento 
                              from siac_t_movgest movgest,                         
                               siac_t_movgest_ts_det ts_det_movgest,
                               siac_r_movgest_bil_elem  r_movgest_bil_elem,
                               siac_t_bil_elem		bil_elem,
                               siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                                siac_t_movgest_ts	ts_movgest                      
                              LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                              on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id and r_mov_gest_ts_sog.data_cancellazione is NULL)  
                              LEFT join siac_t_soggetto		soggetto
                              on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id 
                              	and soggetto.data_cancellazione is NULL)  
                              LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL)
                              where ts_movgest.movgest_id=movgest.movgest_id
                              and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                              and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                              and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                              /* Accedo alla tabella della testata per
                              	sub-impegno e sub-accertamento */
                              --and movgest.movgest_id= elenco_prime_note.key_movimento
                              and ts_movgest.movgest_ts_id= elenco_prime_note.key_movimento
                              and bil_elem.ente_proprietario_id=p_ente_prop_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                              and movgest.data_cancellazione is null
                              and ts_movgest.data_cancellazione is null
                              and ts_det_movgest.data_cancellazione is null
                              and r_movgest_bil_elem.data_cancellazione is null
                              and bil_elem.data_cancellazione is null
                              and d_movgest_ts_det_tipo.data_cancellazione is null;                          
                        IF NOT FOUND THEN
                        /* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                           -- RAISE EXCEPTION 'Sub-Impegno/Sub-Accertamento senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                           -- return;
                           descr_movimento='Non esiste il movimento';
                        ELSE 
                        	sub_impegno= COALESCE(dati_movimento.movgest_ts_code,'');
                            soggetto_code_mod='';
    					    soggetto_desc_mod='';
                        END IF;     
                    ELSIF elenco_prime_note.collegamento_tipo_code in('MMGS','MMGE') THEN      
                    --raise notice 'TIPO_CODE = % - KEY = %', elenco_prime_note.collegamento_tipo_code,elenco_prime_note.key_movimento;
                                      
                  SELECT t_modifica.mod_id,r_modifica_stato.mod_stato_id, movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                          bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                          bil_elem.elem_code3 ueb, 
                          soggetto.soggetto_desc, soggetto.soggetto_code,
                          soggetto_mod.soggetto_desc desc_sogg_mod,
                          soggetto_mod.soggetto_code code_sogg_mod,
                          d_soggetto_classe.soggetto_classe_desc,
                          d_soggetto_classe.soggetto_classe_code,
                          ts_det_movgest.movgest_ts_det_importo imp_movimento, ts_movgest.movgest_ts_code
                            INTO dati_movimento
                            from siac_t_movgest movgest,                         
                             siac_t_movgest_ts_det ts_det_movgest,
                             siac_r_movgest_bil_elem  r_movgest_bil_elem,
                             siac_t_bil_elem		bil_elem,
                             siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,            
                             siac_t_movgest_ts	ts_movgest   
                             LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                            on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id 
                            and r_mov_gest_ts_sog.data_cancellazione is NULL) 
                            LEFT join siac_t_soggetto		soggetto
                            on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id         	
                             and soggetto.data_cancellazione is NULL) 
                             LEFT JOIN siac_r_movgest_ts_sog_mod r_movgest_ts_sog_mod
                             on (r_movgest_ts_sog_mod.movgest_ts_id=ts_movgest.movgest_ts_id
                              AND  r_movgest_ts_sog_mod.data_cancellazione IS NULL)  
                             LEFT join siac_t_soggetto		soggetto_mod
                            on (soggetto_mod.soggetto_id=r_movgest_ts_sog_mod.soggetto_id_new          	
                             and soggetto_mod.data_cancellazione is NULL)  
                            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL),
                             siac_t_movgest_ts_det_mod t_movgest_ts_det_mod    
                              LEFT join  siac_r_modifica_stato  r_modifica_stato           
                             ON (t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
                              and r_modifica_stato.data_cancellazione is null)
                             LEFT JOIN siac_t_modifica t_modifica 
                             on (t_modifica.mod_id=r_modifica_stato.mod_id
                              AND t_modifica.data_cancellazione IS NULL)                           
                  where ts_movgest.movgest_id=movgest.movgest_id
                            and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                            and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                            and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                            and bil_elem.elem_id=r_movgest_bil_elem.elem_id                   
                            and t_movgest_ts_det_mod.movgest_ts_id=  ts_movgest.movgest_ts_id       
                            and t_modifica.mod_id= elenco_prime_note.key_movimento
                            and bil_elem.ente_proprietario_id=p_ente_prop_id
                            and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and movgest.data_cancellazione is null
                            and ts_movgest.data_cancellazione is null
                            and ts_det_movgest.data_cancellazione is null
                            and r_movgest_bil_elem.data_cancellazione is null
                            and bil_elem.data_cancellazione is null
                            and d_movgest_ts_det_tipo.data_cancellazione is null; 
                  		 IF NOT FOUND THEN
                           descr_movimento='Non esiste il movimento';
                         ELSE 
                         	sub_impegno= COALESCE(dati_movimento.movgest_ts_code,'');
                           	soggetto_code_mod=COALESCE(dati_movimento.code_sogg_mod,'');
    						soggetto_desc_mod=COALESCE(dati_movimento.desc_sogg_mod,'');
                         END IF;
                    END IF;
--raise notice 'Sogg=%, Sogg_mod=%, Fam_sogg=%', dati_movimento.soggetto_code,  
		--soggetto_code_mod, dati_movimento.soggetto_classe_code; 
        
--if soggetto_code_mod <>''then
	--raise notice 'SOGGETTO MODIF= X%X',soggetto_code_mod;
--end if;
                     
                    	/* 25/02/2016: se non esiste il movimento non carico i dati */
                    if descr_movimento ='' THEN      
                    --raise notice 'SONO SUB-IMPEGNO %/%',dati_movimento.movgest_numero,dati_movimento.movgest_ts_code;             
                        if elenco_prime_note.evento_tipo_code='I' THEN
                            num_movimento=concat('IMP/',dati_movimento.movgest_numero);
                        else
                            num_movimento=concat('ACC/',dati_movimento.movgest_numero);
                        end if;
                        
                        --raise notice 'SUB=%',num_movimento;
                        if sub_impegno  <> '' THEN
                        	num_movimento= concat(num_movimento,'-',sub_impegno);
                        end if;
                        
                        -- raise notice 'SUB=%',num_movimento;
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.movgest_desc;
                        if soggetto_code_mod <> '' THEN
                        	cod_beneficiario=soggetto_code_mod;
                        else
                        	cod_beneficiario=COALESCE(dati_movimento.soggetto_code,COALESCE(dati_movimento.soggetto_classe_code,''));
                        end if;
                        if soggetto_desc_mod <> '' THEN
                        	ragione_sociale=dati_movimento.soggetto_desc;   
                        else
                        	ragione_sociale=COALESCE(dati_movimento.soggetto_desc,COALESCE(dati_movimento.soggetto_classe_desc,''));
                        end if;
                        imp_movimento=dati_movimento.imp_movimento;

                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                            
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;

                        
                        if elenco_prime_note.evento_tipo_code='I' THEN
                            /* nel caso degli impegni devo leggere la classificazione delle spese */
                          idProgramma=0;
                          idMacroAggreg=0;
                              /* cerco la classificazione del capitolo.
                                  mi servono solo MACROAGGREGATO e  PROGRAMMA */
                          for elenco_tipo_classif in
                              select class_tipo.classif_tipo_code, classif.classif_id
                              from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                  siac_r_bil_elem_class r_bil_class
                              where classif.classif_tipo_id=class_tipo.classif_tipo_id
                              and classif.classif_id=r_bil_class.classif_id
                              and r_bil_class.elem_id=dati_movimento.elem_id
                              and classif.ente_proprietario_id=p_ente_prop_id
                              and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                              and classif.data_cancellazione is NULL
                              and class_tipo.data_cancellazione is NULL
                              and r_bil_class.data_cancellazione is NULL
                          loop
                              --raise notice 'Estraggo %',dati_movimento.elem_id;
                              if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                  idMacroAggreg = elenco_tipo_classif.classif_id;
                              elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                  idProgramma = elenco_tipo_classif.classif_id;
                              end if;                                                          
                              
                          end loop;
                             
                          classif_bilancio='';
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                            SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                            INTO dati_classif
                            FROM siac_rep_mis_pro_tit_mac_riga_anni a
                            WHERE a.macroag_id = idMacroAggreg AND a.programma_id = idProgramma
                            	and a.ente_proprietario_id=p_ente_prop_id
                                and a.utente=user_table;
                            IF NOT FOUND THEN
                                RAISE notice 'Non esiste la classificazione del capitolo di spesa 1. Elem_id = %. Movimento %. TipoEvento = %. CodeEvento = %', dati_movimento.elem_id, elenco_prime_note.key_movimento, elenco_prime_note.evento_tipo_code, elenco_prime_note.evento_code;
                                --return;
                            ELSE
                                classif_bilancio=dati_classif.classificazione_bil;                    
                                prec_classif_bilancio=classif_bilancio;
                            END IF;
                          else
                            classif_bilancio='';                    
                            prec_classif_bilancio='';
                          end if;
                        else /* evento_code = 'A' */
                          idCategoria=0;
                              /* cerco la classificazione del capitolo.
                                  mi serve solo la CATEGORIA??? */
                          for elenco_tipo_classif in
                              select class_tipo.classif_tipo_code, classif.classif_id
                              from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                  siac_r_bil_elem_class r_bil_class
                              where classif.classif_tipo_id=class_tipo.classif_tipo_id
                              and classif.classif_id=r_bil_class.classif_id
                              and r_bil_class.elem_id=dati_movimento.elem_id
                              and classif.ente_proprietario_id=p_ente_prop_id
                              and class_tipo.classif_tipo_code IN('CATEGORIA')
                              and classif.data_cancellazione is NULL
                              and class_tipo.data_cancellazione is NULL
                              and r_bil_class.data_cancellazione is NULL
                          loop
                              --raise notice 'Estraggo %',dati_movimento.elem_id;
                              if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                                  idCategoria = elenco_tipo_classif.classif_id;                          
                              end if;                                                          
                              
                          end loop;
                             
                          classif_bilancio='';
                          if idCategoria is not null then
                                  /* cerco la classificazione del capitolo sulla tabella temporanea */
                              SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                              INTO dati_classif
                              FROM siac_rep_tit_tip_cat_riga_anni a
                              WHERE a.categoria_id = idCategoria
                              and a.ente_proprietario_id=p_ente_prop_id
                              and a.utente=user_table;
                              IF NOT FOUND THEN
                                   RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                                 -- return;
                              ELSE
                                  classif_bilancio=dati_classif.classificazione_bil;                    
                                  prec_classif_bilancio=classif_bilancio;
                              END IF;        
                          else
                            classif_bilancio='';                    
                            prec_classif_bilancio='';
                          end if;            
                           -- END IF;
                        END IF;
                        
                      end if; 
                  end if; --if descr_movimento ='' THEN
               
                /* evento = Liquidazione */
            elsif  elenco_prime_note.evento_tipo_code='L' THEN
                BEGIN
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                     
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                    SELECT liquidazione.liq_numero,   movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                        bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                        liquidazione.liq_importo imp_movimento      
                    INTO dati_movimento         
                    FROM siac_t_movgest		movgest,                                            
                        siac_r_liquidazione_movgest  r_liquid_movgest,       	
                        siac_r_movgest_bil_elem  r_movgest_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_t_movgest_ts	ts_movgest,
                        siac_t_liquidazione			liquidazione  
                        LEFT join siac_r_liquidazione_soggetto	r_liquid_ts_sog
                          on (r_liquid_ts_sog.liq_id=liquidazione.liq_id
                          		AND r_liquid_ts_sog.data_cancellazione IS NULL)  
                          LEFT join siac_t_soggetto		soggetto
                          on (soggetto.soggetto_id=r_liquid_ts_sog.soggetto_id
                          	and soggetto.data_cancellazione is NULL)                    
                        WHERE r_movgest_bil_elem.movgest_id=movgest.movgest_id
                          and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                          and liquidazione.liq_id=elenco_prime_note.key_movimento
                          and liquidazione.ente_proprietario_id=p_ente_prop_id
                          and ts_movgest.movgest_id=movgest.movgest_id      
                          and liquidazione.liq_id=r_liquid_movgest.liq_id
                          and r_liquid_movgest.movgest_ts_id=ts_movgest.movgest_ts_id                  
                          and r_movgest_bil_elem.data_cancellazione is NULL
                          and bil_elem.data_cancellazione is NULL
                          and ts_movgest.data_cancellazione is NULL
                          and movgest.data_cancellazione is NULL                                                
                          and liquidazione.data_cancellazione is NULL;
                         -- and r_liquid_movgest.data_cancellazione is NULL;            
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                       -- RAISE EXCEPTION 'Liquidazione senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                       -- return;
                       descr_movimento='Non esiste il movimento';
                    ELSE
                    --raise notice ' LIQUID = %', dati_movimento.liq_numero;
                    --raise notice 'MOV = %', elenco_prime_note.key_movimento;
                        num_movimento=concat('LIQ/',dati_movimento.liq_numero);
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.movgest_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
         
                      idProgramma=0;
                      idMacroAggreg=0;
                          /* cerco la classificazione del capitolo.
                              mi servono solo MACROAGGREGATO e  PROGRAMMA */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and classif.ente_proprietario_id=p_ente_prop_id
                          and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                              idMacroAggreg = elenco_tipo_classif.classif_id;
                          elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                              idProgramma = elenco_tipo_classif.classif_id;
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                          /* cerco la classificazione del capitolo sulla tabella temporanea */
                      IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN 
                        SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                        INTO dati_classif
                        FROM siac_rep_mis_pro_tit_mac_riga_anni a
                        WHERE macroag_id = idMacroAggreg AND programma_id = idProgramma
                        and a.ente_proprietario_id=p_ente_prop_id
                        and a.utente=user_table;
                        IF NOT FOUND THEN
                             RAISE notice 'Non esiste la classificazione del capitolo di spesa 2. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                           -- return;
                        ELSE
                            classif_bilancio=dati_classif.classificazione_bil;                    
                            prec_classif_bilancio=classif_bilancio;
                        END IF;
                      ELSE
                      	classif_bilancio='';                    
						prec_classif_bilancio='';
                      END IF;
                       -- else /* evento_code = 'A' */
                                         
                      --  END IF;
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if; 
                END;        
            elsif  elenco_prime_note.evento_tipo_code='OP' OR
            		elenco_prime_note.evento_tipo_code='OI' THEN /* Ordinativo */
                BEGIN
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                      
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                    SELECT ordinativo.ord_numero,
                    	ordinativo.ord_desc,
                        bil_elem.elem_code cod_capitolo, 
                        bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, 
                        ts_det_ordinativo.ord_ts_det_importo imp_movimento ,
                        t_soggetto.soggetto_desc,
                        t_soggetto.soggetto_code
                    INTO dati_movimento                                     
                    FROM    	
                        siac_r_ordinativo_bil_elem  r_ord_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_r_ordinativo_soggetto  r_ord_soggetto,
                        siac_t_soggetto  			t_soggetto,
                        siac_t_ordinativo			ordinativo ,                        
                        siac_t_ordinativo_ts		ts_ordinativo, 
                        siac_t_ordinativo_ts_det		ts_det_ordinativo,
                        siac_d_ordinativo_ts_det_tipo  d_ts_det_ord_tipo                   
                        WHERE r_ord_bil_elem.ord_id=ordinativo.ord_id
                          and bil_elem.elem_id=r_ord_bil_elem.elem_id
                          and ordinativo.ord_id=elenco_prime_note.key_movimento    
                          and  ordinativo.ente_proprietario_id=p_ente_prop_id                       
                          and ts_ordinativo.ord_id=ordinativo.ord_id   
                          and ts_det_ordinativo.ord_ts_id  =ts_ordinativo.ord_ts_id   
                          and d_ts_det_ord_tipo.ord_ts_det_tipo_id=ts_det_ordinativo.ord_ts_det_tipo_id
                          and r_ord_soggetto.ord_id=ordinativo.ord_id
                          and t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
                          and   d_ts_det_ord_tipo.ord_ts_det_tipo_code='A'
                          and bil_elem.data_cancellazione is NULL
                          and ordinativo.data_cancellazione is NULL
                          and ts_ordinativo.data_cancellazione is NULL
                          and ts_det_ordinativo.data_cancellazione is NULL
                          and d_ts_det_ord_tipo.data_cancellazione is NULL
                          and r_ord_soggetto.data_cancellazione is NULL
                          and t_soggetto.data_cancellazione is NULL
                          and r_ord_bil_elem.data_cancellazione is NULL;               
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste l'ordinativo non interrompo la procedura */
                        --RAISE EXCEPTION 'Non esiste l''ordinativo %', elenco_prime_note.key_movimento;
                       -- return;
                        descr_movimento='Non esiste l''ordinativo';
                    ELSE

                        num_movimento=concat('ORD/',dati_movimento.ord_numero);
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.ord_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
						/* ordinativo di pagamento */
                    if elenco_prime_note.evento_tipo_code='OP' THEN 
                        idProgramma=0;
                        idMacroAggreg=0;
                            /* cerco la classificazione del capitolo.
                                mi servono solo MACROAGGREGATO e  PROGRAMMA */
                        for elenco_tipo_classif in
                            select class_tipo.classif_tipo_code, classif.classif_id
                            from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                siac_r_bil_elem_class r_bil_class
                            where classif.classif_tipo_id=class_tipo.classif_tipo_id
                            and classif.classif_id=r_bil_class.classif_id
                            and r_bil_class.elem_id=dati_movimento.elem_id
                            and  classif.ente_proprietario_id=p_ente_prop_id 
                            and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                            and classif.data_cancellazione is NULL
                            and class_tipo.data_cancellazione is NULL
                            and r_bil_class.data_cancellazione is NULL
                        loop
                            --raise notice 'Estraggo %',dati_movimento.elem_id;
                            if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                idMacroAggreg = elenco_tipo_classif.classif_id;
                            elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                idProgramma = elenco_tipo_classif.classif_id;
                            end if;                                                          
                          
                        end loop;
                         
                        classif_bilancio='';
                            /* cerco la classificazione del capitolo sulla tabella temporanea */
                        IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                          SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_mis_pro_tit_mac_riga_anni a
                          WHERE a.macroag_id = idMacroAggreg 
                          AND a.programma_id = idProgramma
                          and a.ente_proprietario_id=p_ente_prop_id
                          and a.utente=user_table;
                          IF NOT FOUND THEN
                              RAISE notice 'Non esiste la classificazione del capitolo di spesa 3. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                              --return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;
						ELSE
                        	classif_bilancio='';                    
							prec_classif_bilancio='';
                        END IF;
                    ELSE
                    	idCategoria=0;
                          /* cerco la classificazione del capitolo.
                              mi serve solo la CATEGORIA??? */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and classif.ente_proprietario_id=p_ente_prop_id
                          and class_tipo.classif_tipo_code IN('CATEGORIA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                              idCategoria = elenco_tipo_classif.classif_id;                          
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                      if idCategoria is not null then
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_tit_tip_cat_riga_anni a
                          WHERE a.categoria_id = idCategoria
                          and a.ente_proprietario_id=p_ente_prop_id
                          and a.utente=user_table;
                          IF NOT FOUND THEN
                               RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                             -- return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;        
                      else
                      	classif_bilancio='';                    
                        prec_classif_bilancio='';
                      end if;            
                    END IF;
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if; 
                END;         
            elsif  elenco_prime_note.evento_tipo_code='DE' OR
            		elenco_prime_note.evento_tipo_code='DS' THEN /* Documento */                
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                      
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                           
           			 SELECT t_doc.doc_numero, t_subdoc.subdoc_numero,  t_doc.doc_desc,
                      movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                        bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                       t_doc.doc_importo imp_movimento, d_doc_tipo.doc_tipo_code 
                  	INTO dati_movimento           
                    FROM siac_t_movgest		movgest,                                            
                        siac_r_subdoc_movgest_ts  r_subdoc_movgest_ts,       	
                        siac_r_movgest_bil_elem  r_movgest_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_t_movgest_ts	ts_movgest,
                        siac_d_doc_tipo    d_doc_tipo,
                        siac_t_doc			t_doc
                        	LEFT JOIN siac_r_doc_sog r_doc_sog
                            	ON (r_doc_sog.doc_id=t_doc.doc_id
                                	AND r_doc_sog.data_cancellazione IS NULL)
                            LEFT JOIN siac_t_soggetto		soggetto
                        		ON (soggetto.soggetto_id=r_doc_sog.soggetto_id
                                	AND soggetto.data_cancellazione IS NULL), 
                        siac_t_subdoc		t_subdoc                      
                        WHERE r_movgest_bil_elem.movgest_id=movgest.movgest_id
                          and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                          and t_doc.doc_id=t_subdoc.doc_id
                          and t_subdoc.subdoc_id= elenco_prime_note.key_movimento
                          and t_doc.ente_proprietario_id=p_ente_prop_id
                          --and t_doc.doc_id=elenco_prime_note.key_movimento
                          and ts_movgest.movgest_id=movgest.movgest_id      
                          and t_subdoc.subdoc_id=r_subdoc_movgest_ts.subdoc_id
                          and r_subdoc_movgest_ts.movgest_ts_id=ts_movgest.movgest_ts_id  
                          and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id                
                          and r_movgest_bil_elem.data_cancellazione is NULL
                          and bil_elem.data_cancellazione is NULL
                          and ts_movgest.data_cancellazione is NULL
                          and movgest.data_cancellazione is NULL                      
                          AND t_doc.data_cancellazione IS NULL
                          and t_subdoc.data_cancellazione is NULL
                          and r_subdoc_movgest_ts.data_cancellazione IS NULL
                          AND d_doc_tipo.data_cancellazione IS NULL;               
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste la fattura non interrompo la procedura */
                        --RAISE EXCEPTION 'Non esiste la Fattura % per la Pnota %', elenco_prime_note.key_movimento, elenco_prime_note.num_prima_nota;
                       -- return;
                       descr_movimento='Non esiste la Fattura';
                    ELSE
                    		/* per le fatture, il numero di riga è
                            	il numero di quota!!! */
						num_riga=dati_movimento.subdoc_numero;
                        num_movimento=concat(dati_movimento.doc_tipo_code,'/',dati_movimento.doc_numero);
                    	/* per le fatture non stampo il capitolo, perchè potrebbero
                        	essere più di 1 */
                       -- num_capitolo=dati_movimento.cod_capitolo;
                       -- num_articolo=dati_movimento.num_articolo;
                       -- ueb=dati_movimento.ueb;
                        num_capitolo='';
                        num_articolo='';
                        ueb='';
                        descr_movimento=dati_movimento.doc_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
						
                      /* per le fatture non stampo la classificazione di bilancio */                       
                    classif_bilancio='';
                    /*if elenco_prime_note.evento_tipo_code='DS' THEN 
                  			 /* Documento di spesa */
                        idProgramma=0;
                        idMacroAggreg=0;
                            /* cerco la classificazione del capitolo.
                                mi servono solo MACROAGGREGATO e  PROGRAMMA */
                        for elenco_tipo_classif in
                            select class_tipo.classif_tipo_code, classif.classif_id
                            from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                siac_r_bil_elem_class r_bil_class
                            where classif.classif_tipo_id=class_tipo.classif_tipo_id
                            and classif.classif_id=r_bil_class.classif_id
                            and r_bil_class.elem_id=dati_movimento.elem_id
                            and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                            and classif.data_cancellazione is NULL
                            and class_tipo.data_cancellazione is NULL
                            and r_bil_class.data_cancellazione is NULL
                        loop
                            --raise notice 'Estraggo %',dati_movimento.elem_id;
                            if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                idMacroAggreg = elenco_tipo_classif.classif_id;
                            elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                idProgramma = elenco_tipo_classif.classif_id;
                            end if;                                                          
                          
                        end loop;
                         
                        classif_bilancio='';
                      
                            /* cerco la classificazione del capitolo sulla tabella temporanea */
                        IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                          SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_mis_pro_tit_mac_riga_anni
                          WHERE macroag_id = idMacroAggreg AND programma_id = idProgramma;
                          IF NOT FOUND THEN
                              RAISE notice 'Non esiste la classificazione del capitolo di spesa 3. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                              --return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;
						ELSE
                        	classif_bilancio='';                    
							prec_classif_bilancio='';
                        END IF;
                    ELSE /* documento di entrata */
                    	idCategoria=0;
                          /* cerco la classificazione del capitolo.
                              mi serve solo la CATEGORIA??? */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and class_tipo.classif_tipo_code IN('CATEGORIA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                              idCategoria = elenco_tipo_classif.classif_id;                          
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                      if idCategoria is not null then
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_tit_tip_cat_riga_anni
                          WHERE categoria_id = idCategoria;
                          IF NOT FOUND THEN
                               RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                             -- return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;        
                      else
                      	classif_bilancio='';                    
                        prec_classif_bilancio='';
                      end if;            
                    END IF;*/
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if;                                 
            end if;	/* fine IF su evento_tipo_code */
                    
--raise notice ' Tipo prima nota: %', elenco_prime_note.causale_ep_tipo_code;
--raise notice 'code_programma1 = %, code_programma_prec = %', 
	--code_programma, code_programma_prec;
    
--SIAC-8656 20/10/2022.
--Occorre visualizzare la missione e programma.
--Nel caso delle prime note libere sono lette nella prima query
--che estrae le prime note.
if elenco_prime_note.causale_ep_tipo_code = 'LIB' then
	/*
        --INC000006526089 09/11/2022:
        Missione e programma non possono essere lette in fase
        di estrazione delle prime note in quanto esistono solo
        per i movimenti "Dare".
        Invece devo caricare questi dati in entrambi i movimenti
        perche' nel report raggruppo per prima nota e se il record
        "Avere" e' il primo per una certa prima nota non visualizzo
        il dato di Missione/Programma.
    code_missione:=elenco_prime_note.missione_code_lib;
    desc_missione:=elenco_prime_note.missione_desc_lib;
    code_programma:=elenco_prime_note.programma_code_lib;
    desc_programma:=elenco_prime_note.programma_desc_lib;  
    
    */    
    select COALESCE(class_progr.classif_code,'') programma_code,
         	COALESCE(class_progr.classif_desc,'') programma_desc
  		into code_programma, desc_programma
        from siac_t_mov_ep		mov_ep,
            siac_t_mov_ep_det	mov_ep_det,
            siac_t_class class_progr,
            siac_d_class_tipo tipo_class_progr,
            siac_r_mov_ep_det_class r_mov_ep_det_class_progr
        where mov_ep.movep_id=mov_ep_det.movep_id     
        and tipo_class_progr.classif_tipo_id=class_progr.classif_tipo_id
        and r_mov_ep_det_class_progr.classif_id=class_progr.classif_id
        and r_mov_ep_det_class_progr.movep_det_id=mov_ep_det.movep_det_id
        and tipo_class_progr.ente_proprietario_id=p_ente_prop_id
        	--regep_id contiene l'id della prima nota
        and mov_ep.regep_id =elenco_prime_note.pnota_id 
        and tipo_class_progr.classif_tipo_code='PROGRAMMA'
        and r_mov_ep_det_class_progr.data_cancellazione IS NULL 
        and class_progr.data_cancellazione IS NULL  
        and mov_ep.data_cancellazione IS NULL   
        and mov_ep_det.data_cancellazione IS NULL;
          
        
        select COALESCE(class_progr.classif_code,'') missione_code,
               COALESCE(class_progr.classif_desc,'') missione_desc
          into code_missione, desc_missione
        from siac_t_mov_ep		mov_ep,
            siac_t_mov_ep_det	mov_ep_det,
            siac_t_class class_progr,
            siac_d_class_tipo tipo_class_progr,
            siac_r_mov_ep_det_class r_mov_ep_det_class_progr
        where mov_ep.movep_id=mov_ep_det.movep_id     
        and tipo_class_progr.classif_tipo_id=class_progr.classif_tipo_id
        and r_mov_ep_det_class_progr.classif_id=class_progr.classif_id
        and r_mov_ep_det_class_progr.movep_det_id=mov_ep_det.movep_det_id
        and tipo_class_progr.ente_proprietario_id=p_ente_prop_id
        	--regep_id contiene l'id della prima nota
        and mov_ep.regep_id =elenco_prime_note.pnota_id
        and tipo_class_progr.classif_tipo_code='MISSIONE'
        and r_mov_ep_det_class_progr.data_cancellazione IS NULL 
        and class_progr.data_cancellazione IS NULL  
        and mov_ep.data_cancellazione IS NULL   
        and mov_ep_det.data_cancellazione IS NULL;
else
	--nel caso delle prime note integrate occorre prendere la missione
    --e programma relative al capitolo.
    --Vale solo per i capitoli di spesa.
	--raise notice ' ELEM_ID = %, elem_id_prec = %', 
    	--dati_movimento.elem_id, elem_id_prec; 
        
    --eseguo la query solo se il capitolo e' diverso da quello del record
    --precedente in modo da appesantire meno la gestione.
    if elem_id_prec = dati_movimento.elem_id then     	        
        code_missione:=code_missione_prec;
		desc_missione:=desc_missione_prec;
		code_programma:=code_programma_prec;
		desc_programma:=desc_programma_prec;        
    else
      with capitoli as(
        select distinct programma.classif_id programma_id,
                macroaggr.classif_id macroaggregato_id,          
                capitolo.elem_id
        from siac_d_class_tipo programma_tipo,
             siac_t_class programma,
             siac_d_class_tipo macroaggr_tipo,
             siac_t_class macroaggr,
             siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_r_bil_elem_class r_capitolo_programma,
             siac_r_bil_elem_class r_capitolo_macroaggr, 
             siac_d_bil_elem_stato stato_capitolo, 
             siac_r_bil_elem_stato r_capitolo_stato,
             siac_d_bil_elem_categoria cat_del_capitolo,
             siac_r_bil_elem_categoria r_cat_capitolo 
        where 	
            programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
            and	programma.classif_id=r_capitolo_programma.classif_id			    
            and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
            and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
            and	capitolo.elem_id=r_capitolo_programma.elem_id					
            and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	   	
            and	capitolo.ente_proprietario_id=p_ente_prop_id 											 
            and	programma_tipo.classif_tipo_code='PROGRAMMA'							
            and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
            and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
            and	stato_capitolo.elem_stato_code	=	'VA'	
            and capitolo.elem_id = dati_movimento.elem_id					     							
            and	programma_tipo.data_cancellazione 			is null
            and	programma.data_cancellazione 				is null
            and	macroaggr_tipo.data_cancellazione 			is null
            and	macroaggr.data_cancellazione 				is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	r_capitolo_programma.data_cancellazione 	is null
            and	r_capitolo_macroaggr.data_cancellazione 	is null 
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and	cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null),
         strut_bilancio as(
              select *
              from siac_rep_mis_pro_tit_mac_riga_anni a
              where a.ente_proprietario_id=p_ente_prop_id
                  and a.utente=user_table)
        select COALESCE(strut_bilancio.missione_code,'') code_missione,
          COALESCE(strut_bilancio.missione_desc,'') desc_missione,
          COALESCE(strut_bilancio.programma_code,'') code_programma,
          COALESCE(strut_bilancio.programma_desc,'') desc_programma
        into code_missione, desc_missione, code_programma, desc_programma
        from capitoli  
          left JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
                          AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id);         
		IF NOT FOUND THEN
        	code_missione:='';
          	desc_missione:='';
          	code_programma:='';
          	desc_programma:='';
         end if;
         
        code_missione_prec:=code_missione;
        desc_missione_prec:=desc_missione;
        code_programma_prec:=code_programma;
        desc_programma_prec:=desc_programma;
        elem_id_prec = dati_movimento.elem_id;
        
        --raise notice 'code_programma2 = % ', code_programma;
    end if;
    
    
end if;   


--Nel campo miss_prog_display carico il dato di missione/programma da
--visualizzare nel report.
--In questo modo sara' piu' semplice modificarlo se si vuole in un
--formato diverso.
miss_prog_display := code_programma;
      
    return next;
        
        nome_ente='';
        num_movimento='';
        cod_beneficiario='';
        ragione_sociale='';
        num_capitolo='';
        num_articolo='';
        ueb='';
        classif_bilancio='';
        imp_movimento=0;
        descr_movimento='';
        num_prima_nota=0;
        num_prima_nota_def=0;
        data_registrazione=NULL;
        data_registrazione_def=NULL;
        stato_prima_nota='';
        descr_prima_nota='';
        cod_causale='';
        num_riga=0;
        cod_conto='';
        descr_riga='';
        importo_dare=0;
        importo_avere=0;
        key_movimento=0;
        sub_impegno='';
        soggetto_code_mod='';
    	soggetto_desc_mod='';
        code_missione:='';
    	desc_missione:='';
    	code_programma:='';
    	desc_programma:='';
        miss_prog_display:='';
        
        end loop;
  
    	/* cancello le strutture temporanee dei capitoli */
	delete from siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
  	delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
  
exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'PRIME NOTE',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR066_prime_note_integrate" (p_ente_prop_id integer, p_anno varchar, p_data_reg_da date, p_data_reg_a date, p_num_prima_nota integer, p_num_prima_nota_def integer, p_tipologia varchar, p_tipo_evento varchar, p_evento varchar)
  OWNER TO siac;