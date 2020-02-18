/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR127_fatture_scadute_non_pagate_PCC" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_utente varchar,
  p_data_fattura date
)
RETURNS TABLE (
  nome_ente varchar,
  bil_anno varchar,
  cod_fisc_ente_dest varchar,
  cod_ufficio varchar,
  cod_fiscale_fornitore varchar,
  piva_fornitore varchar,
  cod_tipo_operazione varchar,
  desc_tipo_operazione varchar,
  identificativo2 varchar,
  data_emissione date,
  importo_totale numeric,
  numero_quota integer,
  importo_quota numeric,
  natura_spesa varchar,
  anno_capitolo integer,
  num_capitolo varchar,
  cod_articolo varchar,
  ueb varchar,
  cod_stato_debito varchar,
  cod_causale_mov varchar,
  descr_quota varchar,
  data_emissione_impegno date,
  num_impegno varchar,
  anno_impegno integer,
  cig_documento varchar,
  cig_impegno varchar,
  cup_documento varchar,
  cup_impegno varchar,
  doc_id integer,
  subdoc_id integer,
  v_rpcc_id integer,
  movgest_ts_id integer,
  titolo_code varchar,
  titolo_desc varchar,
  importo_pagato numeric,
  num_ordinativo integer,
  data_ordinativo date,
  cod_fiscale_ordinativo varchar,
  piva_ordinativo varchar,
  estremi_impegno varchar,
  cod_fisc_utente_collegato varchar,
  data_scadenza date,
  importo_quietanza numeric,
  esito_code varchar,
  esito_desc varchar,
  dt_crea_reg_pcc date
) AS
$body$
DECLARE
 elencoRegistriRec record;

 elencoAttrib record;
 elencoClass	record;
 annoCompetenza_int integer;
 DEF_NULL	constant varchar:=''; 
 RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
 user_table varchar;
 cod_fisc VARCHAR;
 elencoRcpp_id VARCHAR;
 v_fam_missioneprogramma varchar :='00001';
 v_fam_titolomacroaggregato varchar := '00002';

BEGIN
 
nome_ente='';
bil_anno='';
cod_fisc_ente_dest='';
cod_ufficio='';
cod_fiscale_fornitore='';
piva_fornitore='';
cod_tipo_operazione='';
desc_tipo_operazione='';
identificativo2='';
data_emissione=NULL;
importo_totale=0;
importo_quota=0;
natura_spesa='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
cod_stato_debito='';
cod_causale_mov='';
descr_quota='';
data_emissione_impegno=NULL;
num_impegno='';
anno_impegno=0;
cig_documento='';
cig_impegno='';
cup_documento='';
cup_impegno='';
doc_id=0;
subdoc_id=0;
v_rpcc_id=0;
movgest_ts_id=0;
numero_quota=0;
importo_pagato=0;
num_ordinativo =0;
data_ordinativo=NULL;
cod_fiscale_ordinativo='';
piva_ordinativo='';
estremi_impegno='';
data_scadenza=NULL;
importo_quietanza=0;
dt_crea_reg_pcc=NULL;

annoCompetenza_int =p_anno ::INTEGER;

select fnc_siac_random_user()
into	user_table;



raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice  'inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';


-- caricamento struttura del bilancio
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
  --, siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
 --AND programma.programma_id = progmacro.classif_a_id
 --AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;

 /*
 insert into siac_rep_mis_pro_tit_mac_riga_anni
 select * from "fnc_struttura_bilancio_spese_utilita" (p_ente_prop_id, p_anno, user_table);
 */
 
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Fine caricamento struttura bilancio.';

RTN_MESSAGGIO:='inserimento tabella di comodo dei capitoli ''.';
raise notice 'inserimento tabella di comodo dei capitoli';

insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
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
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code in('CAP-UG','CAP-UP')		     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	cat_del_capitolo.elem_cat_code	=	'STD'								
    and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
	and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
    and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
    and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
    and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
    and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
    and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
    and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
    and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
    and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
    and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
    and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
    and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
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
    and	r_cat_capitolo.data_cancellazione 			is null;	

	BEGIN
      SELECT distinct soggetto.codice_fiscale
          INTO cod_fisc
      FROM siac_t_account acc,
          siac_r_soggetto_ruolo sog_ruolo,
          siac_t_soggetto soggetto
      where sog_ruolo.soggeto_ruolo_id=acc.soggeto_ruolo_id
        and sog_ruolo.soggetto_id=soggetto.soggetto_id
        and acc.ente_proprietario_id=p_ente_prop_id
        and acc.account_code=p_utente
        and soggetto.data_cancellazione IS NULL
        and sog_ruolo.data_cancellazione IS NULL
        and acc.data_cancellazione IS NULL;
       IF NOT FOUND THEN
       		cod_fisc='';
       END IF;
     END;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati Dati del Registro PCC ';
elencoRcpp_id='';

for elencoRegistriRec IN
	
select t_ente.codice_fiscale cod_fisc_ente_dest, t_ente.ente_denominazione,
	d_pcc_codice.pcccod_code cod_ufficio, d_pcc_codice.pcccod_desc,
    d_pcc_oper_tipo.pccop_tipo_code cod_tipo_operazione,
    d_pcc_oper_tipo.pccop_tipo_desc desc_tipo_operazione,
    d_pcc_debito_stato.pccdeb_stato_code cod_debito, 
    d_pcc_debito_stato.pccdeb_stato_desc desc_debito,
    d_pcc_causale.pcccau_code cod_causale_pcc,
    d_pcc_causale.pcccau_desc desc_causale_pcc, 
    t_doc.doc_numero identificativo2, 
    t_doc.doc_data_emissione data_emissione,
    t_doc.doc_importo importo_totale_doc,t_doc.data_creazione data_emissione_imp,
    t_doc.doc_id,t_registro_pcc.rpcc_id,t_subdoc.subdoc_id,
    t_subdoc.subdoc_numero, t_subdoc.subdoc_importo importo_quota,
    t_subdoc.subdoc_desc desc_quota, 
    t_registro_pcc.rpcc_quietanza_importo importo_quietanza,
    t_registro_pcc.ordinativo_numero, t_registro_pcc.ordinativo_data_emissione,
    t_registro_pcc.data_scadenza,
    t_bil_elem.elem_code num_capitolo, t_bil_elem.elem_code2 num_articolo, 
    t_bil_elem.elem_code3 ueb, anno_eserc.anno BIL_ANNO,
    t_movgest.movgest_anno anno_impegno,    
    t_movgest.movgest_numero numero_impegno, t_movgest_ts.movgest_ts_id,
    t_bil_elem.elem_id, t_soggetto.soggetto_code, t_soggetto.soggetto_desc,
    t_soggetto.codice_fiscale, t_soggetto.partita_iva,
    t_sog_pcc.codice_fiscale cod_fisc_ordinativo, 
    t_sog_pcc.partita_iva piva_ordinativo, t_movgest.movgest_id,
    t_registro_pcc.rpcc_esito_code , t_registro_pcc.rpcc_esito_desc,
    t_registro_pcc.rpcc_registrazione_data,
    t_subdoc.subdoc_data_scadenza, t_doc.doc_data_scadenza,
    t_subdoc.subdoc_pagato_cec, t_registro_pcc.data_creazione dt_crea_reg_pcc,
    COALESCE(t_subdoc.subdoc_splitreverse_importo,0) importo_splitreverse
from siac_t_registro_pcc t_registro_pcc 
	LEFT JOIN siac_d_pcc_debito_stato d_pcc_debito_stato
    	ON (d_pcc_debito_stato.pccdeb_stato_id=t_registro_pcc.pccdeb_stato_id
        	AND d_pcc_debito_stato.data_cancellazione IS NULL)
    LEFT JOIN siac_d_pcc_causale 	d_pcc_causale
    	ON (d_pcc_causale.pcccau_id=t_registro_pcc.pcccau_id
        	AND d_pcc_causale.data_cancellazione IS NULL)
    LEFT JOIN siac_t_soggetto t_sog_pcc
    	ON (t_sog_pcc.soggetto_id=t_registro_pcc.soggetto_id
        	AND t_sog_pcc.data_cancellazione IS NULL),
	siac_t_ente_proprietario t_ente,    
    siac_d_pcc_codice d_pcc_codice,
    siac_d_pcc_operazione_tipo d_pcc_oper_tipo,
    siac_t_doc t_doc
    LEFT JOIN siac_r_doc_sog r_doc_sog
    	ON (r_doc_sog.doc_id=t_doc.doc_id
        	AND r_doc_sog.data_cancellazione IS NULL)
    LEFT JOIN siac_t_soggetto t_soggetto
    	ON (t_soggetto.soggetto_id= r_doc_sog.soggetto_id
        	AND t_soggetto.data_cancellazione IS NULL),
    siac_t_subdoc t_subdoc    	
    LEFT JOIN  siac_r_subdoc_movgest_ts r_subdoc_movgest_ts
    	ON (r_subdoc_movgest_ts.subdoc_id=t_subdoc.subdoc_id
        	AND r_subdoc_movgest_ts.data_cancellazione IS NULL)
    LEFT JOIN  siac_t_movgest_ts t_movgest_ts
    	ON (t_movgest_ts.movgest_ts_id= r_subdoc_movgest_ts.movgest_ts_id
        	AND t_movgest_ts.data_cancellazione IS NULL)
    LEFT JOIN  siac_t_movgest t_movgest
    	ON (t_movgest.movgest_id= t_movgest_ts.movgest_id
        	AND t_movgest_ts.data_cancellazione IS NULL)   
    LEFT JOIN siac_r_movgest_bil_elem r_movgest_bil_elem
    	ON (r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
        	AND r_movgest_bil_elem.data_cancellazione IS NULL)
    LEFT JOIN siac_t_bil_elem t_bil_elem
         ON (t_bil_elem.elem_id=r_movgest_bil_elem.elem_id
         	 AND t_bil_elem.data_cancellazione IS NULL)
	LEFT JOIN siac_t_bil			bilancio
    	ON (bilancio.bil_id=t_bil_elem.bil_id
        	AND bilancio.data_cancellazione IS NULL)
    LEFT JOIN siac_t_periodo      anno_eserc
    	ON (anno_eserc.periodo_id=bilancio.periodo_id
        	AND anno_eserc.data_cancellazione IS NULL)            
where t_ente.ente_proprietario_id=t_registro_pcc.ente_proprietario_id
	AND t_doc.doc_id=t_registro_pcc.doc_id
    AND t_subdoc.subdoc_id=t_registro_pcc.subdoc_id
    AND d_pcc_codice.pcccod_id=t_doc.pcccod_id
    AND d_pcc_oper_tipo.pccop_tipo_id=t_registro_pcc.pccop_tipo_id
	AND t_ente.ente_proprietario_id=p_ente_prop_id   
    	/* devo estrarre solo le tipologie CO e CS.  
   			Per CO si devono escludere gli stati del debito SOSP e NOLIQ */
	 AND ((d_pcc_oper_tipo.pccop_tipo_code =  'CO' 
     		AND d_pcc_debito_stato.pccdeb_stato_code <> 'SOSP' 
            AND d_pcc_debito_stato.pccdeb_stato_code <> 'NOLIQ' ) OR
     	  (d_pcc_oper_tipo.pccop_tipo_code =  'CS'))
    AND (p_data_fattura IS NOT NULL 
    	AND (date_trunc ('day',t_subdoc.subdoc_data_scadenza) <=
        	 p_data_fattura ))
        /* estraggo solo i dati che hanno delle quote fattura NON pagate */
    AND t_subdoc.subdoc_id NOT IN (select r_subdoc_ordinativo_ts.subdoc_id 
    		FROM siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts   
            WHERE r_subdoc_ordinativo_ts.data_cancellazione IS NULL)
    AND t_doc.data_cancellazione IS NULL
    AND t_subdoc.data_cancellazione IS NULL
    AND t_registro_pcc.data_cancellazione IS NULL
    AND t_ente.data_cancellazione IS NULL
    AND d_pcc_codice.data_cancellazione IS NULL
    AND d_pcc_oper_tipo.data_cancellazione IS NULL 
ORDER BY t_doc.doc_anno, t_doc.doc_numero, t_registro_pcc.data_creazione

loop

--raise notice 'DATA REG = %', elencoRegistriRec.rpcc_registrazione_data;
--raise notice 'DATA SCAD DOC= %', elencoRegistriRec.doc_data_scadenza;
--raise notice 'DATA SCAD SUBDOC= %', elencoRegistriRec.subdoc_data_scadenza;
--raise notice 'PAGAM SUBDOC= %', elencoRegistriRec.subdoc_pagato_cec;
/*raise notice 'ID_FAT = %, NUM_FAT = %, NUM_QUOTA = %,TIPO = %, DEBITO = % DATA CREAZ PCC = %', 
	elencoRegistriRec.doc_id,elencoRegistriRec.identificativo2,
    elencoRegistriRec.subdoc_numero,
	elencoRegistriRec.cod_tipo_operazione,elencoRegistriRec.cod_debito,
    elencoRegistriRec.dt_crea_reg_pcc;
raise notice '';*/

	nome_ente=elencoRegistriRec.ente_denominazione;
    bil_anno=elencoRegistriRec.BIL_ANNO;
	cod_fisc_utente_collegato=cod_fisc;
    
    cod_fisc_ente_dest=elencoRegistriRec.cod_fisc_ente_dest;
    cod_ufficio=elencoRegistriRec.cod_ufficio;
    cod_fiscale_fornitore=COALESCE(elencoRegistriRec.codice_fiscale,'');
    piva_fornitore=COALESCE(elencoRegistriRec.partita_iva,'');
    cod_tipo_operazione=elencoRegistriRec.cod_tipo_operazione;
    desc_tipo_operazione=elencoRegistriRec.desc_tipo_operazione;
    identificativo2=elencoRegistriRec.identificativo2;
    data_emissione=elencoRegistriRec.data_emissione ::DATE;
    importo_totale=elencoRegistriRec.importo_totale_doc;
    numero_quota=elencoRegistriRec.subdoc_numero;
    importo_quota=elencoRegistriRec.importo_quota-elencoRegistriRec.importo_splitreverse;    
    --raise notice 'importo_quota=%, importo_quota_con_split=%',elencoRegistriRec.importo_quota,importo_quota;
    anno_capitolo=elencoRegistriRec.BIL_ANNO;
    num_capitolo=elencoRegistriRec.num_capitolo;
    cod_articolo=elencoRegistriRec.num_articolo;
    ueb=COALESCE(elencoRegistriRec.ueb,'');
    cod_stato_debito=COALESCE(elencoRegistriRec.cod_debito,'');
    cod_causale_mov=COALESCE(elencoRegistriRec.cod_causale_pcc,'');
    	/* la descrizione della quotra non deve superare i 100 caratteri */
    descr_quota=substr( COALESCE(elencoRegistriRec.desc_quota,''),1,100);
    data_emissione_impegno=elencoRegistriRec.data_emissione_imp ::DATE;
    num_impegno=elencoRegistriRec.numero_impegno;
    anno_impegno=elencoRegistriRec.anno_impegno;
    doc_id=elencoRegistriRec.doc_id;
    subdoc_id=elencoRegistriRec.subdoc_id;
    v_rpcc_id=elencoRegistriRec.rpcc_id;
    movgest_ts_id=elencoRegistriRec.movgest_ts_id;
    importo_pagato=elencoRegistriRec.importo_quietanza;
	num_ordinativo=elencoRegistriRec.ordinativo_numero;
	data_ordinativo=elencoRegistriRec.ordinativo_data_emissione;
   	cod_fiscale_ordinativo=COALESCE(elencoRegistriRec.cod_fisc_ordinativo,'');
	piva_ordinativo=COALESCE(elencoRegistriRec.piva_ordinativo,'');
    estremi_impegno=to_char(elencoRegistriRec.data_emissione_imp ,'dd/mm/yyyy') ||'-'||elencoRegistriRec.anno_impegno ::VARCHAR ||'-'||elencoRegistriRec.numero_impegno ::VARCHAR;
    data_scadenza=elencoRegistriRec.data_scadenza;
	importo_quietanza=elencoRegistriRec.importo_quietanza;
    
    esito_code=elencoRegistriRec.rpcc_esito_code;
    esito_desc=elencoRegistriRec.rpcc_esito_desc;
    
    	/* cerco il CUP ed il CIG del sub-documento */
    for elencoAttrib IN
      SELECT  b.attr_code, a.testo
      from siac_r_subdoc_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.subdoc_id=elencoRegistriRec.subdoc_id
          and b.attr_code in('cup','cig') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL
      loop          
        if upper(elencoAttrib.attr_code)='CIG' THEN
            cig_documento=COALESCE(elencoAttrib.testo,'');
        elsif upper(elencoAttrib.attr_code)='CUP' THEN
            cup_documento=COALESCE(elencoAttrib.testo,'');
        end if;	
      end loop; 
    
    	/* se non ho trovato il CIG o il CUP del sub-documento,
        	cerco quelli dell'impegno */
    if cig_documento='' OR cup_documento='' THEN
      for elencoAttrib IN
        SELECT  b.attr_code, a.testo
          from siac_r_movgest_ts_attr a,
              siac_t_attr b
          where a.attr_id=b.attr_id
              and a.movgest_ts_id=elencoRegistriRec.movgest_ts_id
              and upper(b.attr_code) in('CUP','CIG') 
              and a.data_cancellazione IS NULL
              and b.data_cancellazione IS NULL
        loop          
          if upper(elencoAttrib.attr_code)='CIG' THEN
              cig_impegno=COALESCE(elencoAttrib.testo,'');
          elsif upper(elencoAttrib.attr_code)='CUP' THEN
              cup_impegno=COALESCE(elencoAttrib.testo,'');
          end if;	
        end loop; 
    END IF;
  
		--data di creazione del record nel registro PCC
	dt_crea_reg_pcc=elencoRegistriRec.dt_crea_reg_pcc;
    
		/* cerco il titolo del capitolo */
      SELECT COALESCE(v1.titusc_code,''), COALESCE(v1.titusc_desc,'')
      INTO titolo_code, titolo_desc
      FROM siac_rep_cap_ug tb,
      	siac_rep_mis_pro_tit_mac_riga_anni v1           
      WHERE v1.programma_id = tb.programma_id    
      		and	v1.macroag_id	= tb.macroaggregato_id
            AND TB.utente=V1.utente
            and v1.ente_proprietario_id=p_ente_prop_id
            and tb.elem_id=elencoRegistriRec.elem_id            
            and v1.utente=user_table;
      IF NOT FOUND THEN
          titolo_code='';
          titolo_desc='';
      END IF;
    
    	/* se il titolo è 1, la natura spesa è CO,
        	se è 2 la natura spesa è CA */
    if titolo_code= '1' THEN
    	natura_spesa='CO';
    elsif titolo_code= '2' THEN
    	natura_spesa='CA';
    else
    	natura_spesa='';
    end if;
    
    
return next;


nome_ente='';
bil_anno='';
cod_fisc_ente_dest='';
cod_ufficio='';
cod_fiscale_fornitore='';
piva_fornitore='';
cod_tipo_operazione='';
desc_tipo_operazione='';
identificativo2='';
data_emissione=NULL;
importo_totale=0;
importo_quota=0;
natura_spesa='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
cod_stato_debito='';
cod_causale_mov='';
descr_quota='';
data_emissione_impegno=NULL;
num_impegno='';
anno_impegno=0;
cig_documento='';
cig_impegno='';
cup_documento='';
cup_impegno='';
doc_id=0;
subdoc_id=0;
v_rpcc_id=0;
movgest_ts_id=0;
numero_quota=0;
importo_pagato=0;
num_ordinativo =0;
data_ordinativo=NULL;
cod_fiscale_ordinativo='';
piva_ordinativo='';
estremi_impegno='';
data_scadenza=NULL;
importo_quietanza=0;
dt_crea_reg_pcc=NULL;
numero_quota=0;

end loop;

--raise notice 'Elenco ID = %', elencoRcpp_id;
delete from   siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;

raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati del Registro PCC non trovati.' ;
	when others  THEN		
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'REGISTRO-PCC',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;