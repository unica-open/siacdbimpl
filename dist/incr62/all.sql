/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 17.12.2018 SIAC-6604 - Sofia - Inizio
drop FUNCTION if exists siac."BILR101_registro_operaz_pcc" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_utente varchar,
  p_data_reg_da date,
  p_data_reg_a date
);

CREATE OR REPLACE FUNCTION siac."BILR101_registro_operaz_pcc" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_utente varchar,
  p_data_reg_da date,
  p_data_reg_a date
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
  rpcc_registrazione_data date,
  display_error varchar
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
 sql_query VARCHAR;
 eseguiEstrOld boolean;
 contaParamDate integer;
 
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
rpcc_registrazione_data:=NULL;
display_error:='';

annoCompetenza_int =p_anno ::INTEGER;

select fnc_siac_random_user()
into	user_table;

/* 09/10/2017: SIAC-5352.
	gestiti i nuovi parametri per estrarre i dati gia' inviati */
contaParamDate:=0;
if p_data_reg_da is not null then
	contaParamDate:=contaParamDate+1;
end if;
if p_data_reg_a is not null then
	contaParamDate:=contaParamDate+1;
end if;

if contaParamDate = 1 then
	display_error:='INSERIRE ENTRAMBE LE DATE DI REGISTRAZIONE DELL''INTERVALLO PER ESTRARRE I DATI GIA'' INVIATI';
    return next;
    return;
end if;

eseguiEstrOld:=false;
if contaParamDate = 2 then
	eseguiEstrOld:=true;
end if;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice  'inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';

/*
insert into siac_rep_mis_pro_tit_mac_riga_anni
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
  --, siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 06/09/2016: start filtro per mis-prog-macro*/
-- AND programma.programma_id = progmacro.classif_a_id
--AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
raise notice 'ora: % ',clock_timestamp()::varchar;
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
    --20/07/2017: devo estrarre tutti i capitoli, perche' possono esserci capitoli
    --   di anni di bilancio precedenti.
   	--anno_eserc.anno= p_anno 												and
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

	
    SELECT distinct soggetto.codice_fiscale
        INTO cod_fisc
    FROM siac_t_account acc,
        siac_r_soggetto_ruolo sog_ruolo,
        siac_t_soggetto soggetto
    where sog_ruolo.soggeto_ruolo_id=acc.soggeto_ruolo_id
      and sog_ruolo.soggetto_id=soggetto.soggetto_id
      and acc.ente_proprietario_id=p_ente_prop_id
      /* 09/03/2016: nel campo account passato in input al report non c'e' piu'
          il nome ma l'account_code */
      --and acc.nome=p_utente
      and acc.account_code=p_utente
      and soggetto.data_cancellazione IS NULL
      and sog_ruolo.data_cancellazione IS NULL
      and acc.data_cancellazione IS NULL;
     IF NOT FOUND THEN
          cod_fisc='';
     END IF;
     

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati Dati del Registro PCC ';
elencoRcpp_id='';

/* 09/10/2017:  SIAC-5352.
	Query resa dinamica x gestire i nuovi parametri:
	- p_data_reg_da date,
  	- p_data_reg_a date
	che servono per estrarre i dati gia' inviati in precedenza */
sql_query='
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
   -- t_subdoc.subdoc_desc desc_quota, 
    replace (replace (t_subdoc.subdoc_desc,chr(10),'' ''),chr(13),'''') desc_quota, 
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
    t_registro_pcc.rpcc_registrazione_data
from siac_t_registro_pcc t_registro_pcc 
	LEFT JOIN siac_d_pcc_debito_stato d_pcc_debito_stato
    	ON (d_pcc_debito_stato.pccdeb_stato_id=t_registro_pcc.pccdeb_stato_id
        	AND d_pcc_debito_stato.data_cancellazione IS NULL)
    LEFT JOIN siac_d_pcc_causale 	d_pcc_causale
    	ON (d_pcc_causale.pcccau_id=t_registro_pcc.pcccau_id
        	AND d_pcc_causale.data_cancellazione IS NULL)
   /* LEFT JOIN siac_t_ordinativo t_ordinativo
    	ON (t_ordinativo.ord_numero =t_registro_pcc.ordinativo_numero
        	AND t_ordinativo.ord_emissione_data=  t_registro_pcc.ordinativo_data_emissione
            AND t_ordinativo.data_cancellazione IS NULL)
    LEFT JOIN siac_r_ordinativo_soggetto r_ord_soggetto
    	ON (r_ord_soggetto.ord_id=t_ordinativo.ord_id
        	AND r_ord_soggetto.data_cancellazione IS NULL)*/
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
	AND t_ente.ente_proprietario_id='||p_ente_prop_id   ||'
    	/* devo estrarre solo il tipo CP */ 
    AND d_pcc_oper_tipo.pccop_tipo_code=''CP''
    --AND d_pcc_oper_tipo.pccop_tipo_code=''CO''
    AND t_doc.data_cancellazione IS NULL
    AND t_subdoc.data_cancellazione IS NULL
    AND t_registro_pcc.data_cancellazione IS NULL
    AND t_ente.data_cancellazione IS NULL
    AND d_pcc_codice.data_cancellazione IS NULL
    AND d_pcc_oper_tipo.data_cancellazione IS NULL ';
    if eseguiEstrOld = true THEN
    	sql_query=sql_query|| ' AND date_trunc(''day'',t_registro_pcc.rpcc_registrazione_data) between '''||p_data_reg_da||''' and '''||p_data_reg_a||''' ';
    ELSE
    	sql_query=sql_query|| ' AND t_registro_pcc.rpcc_registrazione_data IS NULL ';
    end if;
   -- AND t_registro_pcc.rpcc_registrazione_data IS NULL
    --AND to_char (t_registro_pcc.rpcc_registrazione_data,''dd/mm/yyyy'')=''05/08/2016''
sql_query=sql_query|| ' ORDER BY t_doc.doc_data_emissione, t_doc.doc_numero, t_subdoc.subdoc_numero';
raise notice 'sql_query = %', sql_query;

for elencoRegistriRec IN
	execute sql_query 
loop
	/*if elencoRcpp_id = '' THEN
    	elencoRcpp_id= elencoRegistriRec.rpcc_id;
    else 
    	elencoRcpp_id=elencoRcpp_id||', '||elencoRegistriRec.rpcc_id;
    end if;*/
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
    importo_quota=elencoRegistriRec.importo_quota;    
    anno_capitolo=elencoRegistriRec.BIL_ANNO;
    num_capitolo=elencoRegistriRec.num_capitolo;
    cod_articolo=elencoRegistriRec.num_articolo;
    ueb=COALESCE(elencoRegistriRec.ueb,'');
    cod_stato_debito=COALESCE(elencoRegistriRec.cod_debito,'');
    cod_causale_mov=COALESCE(elencoRegistriRec.cod_causale_pcc,'');
    	/* 16/03/2016: la descrizione della quotra non deve superare i 100 caratteri */
    --descr_quota=elencoRegistriRec.desc_quota;
    descr_quota=substr( COALESCE(elencoRegistriRec.desc_quota,''),1,100);
    --data_emissione_impegno=to_date(elencoRegistriRec.data_emissione_imp ::VARCHAR,'yyyy/MM/dd');
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
--    estremi_impegno=to_date(elencoRegistriRec.data_emissione_imp ::VARCHAR,'dd/MM/yyyy') ||'-'||elencoRegistriRec.anno_impegno ::VARCHAR ||'-'||elencoRegistriRec.numero_impegno ::VARCHAR;
    estremi_impegno=to_char(elencoRegistriRec.data_emissione_imp ,'dd/mm/yyyy') ||'-'||elencoRegistriRec.anno_impegno ::VARCHAR ||'-'||elencoRegistriRec.numero_impegno ::VARCHAR;
    data_scadenza=elencoRegistriRec.data_scadenza;
	importo_quietanza=elencoRegistriRec.importo_quietanza;
    rpcc_registrazione_data:=elencoRegistriRec.rpcc_registrazione_data;
    
    	/* cerco il CUP ed il CIG del sub-documento */
	
    for elencoAttrib IN
      SELECT  b.attr_code, a.testo
      from siac_r_subdoc_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.subdoc_id=elencoRegistriRec.subdoc_id
          and upper(b.attr_code) in('CUP','CIG') 
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
  
		
--raise notice 'Elem_id = %', elencoRegistriRec.elem_id;	
--raise notice 'Capitolo = %', elencoRegistriRec.num_capitolo;	

		/* cerco il titolo del capitolo */
/* 13/09/2016: corretta la query che cerca il titolo del capitolo
	perche' estraeva tanti record invece che uno solo */
     /* SELECT v1.titusc_code, v1.titusc_desc
      INTO titolo_code, titolo_desc
      FROM siac_rep_mis_pro_tit_mac_riga_anni v1
           LEFT JOIN siac_rep_cap_ug tb
              ON 	(v1.programma_id = tb.programma_id    
                  and	v1.macroag_id	= tb.macroaggregato_id
                  and v1.ente_proprietario_id=p_ente_prop_id
                  and tb.elem_id=elencoRegistriRec.elem_id
                  AND TB.utente=V1.utente
                  and v1.utente=user_table);*/
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
    
--raise notice 'Titolo = %',titolo_code;     
    	/* se il titolo e' 1, la natura spesa e' CO,
        	se e' 2 la natura spesa e' CA */
    if titolo_code= '1' THEN
    	natura_spesa='CO';
    elsif titolo_code= '2' THEN
    	natura_spesa='CA';
    else
    -- 07/07/2017: messo NA se il titolo e' diverso da 1 e 2.
    	--natura_spesa='';
        natura_spesa='NA';
    end if;
    
--raise notice 'natura_spesa = %',natura_spesa;      
 
/* e' eseguito l'aggiornamento della data registrazione in modo che i record
	siano estratti una volta sola */
/* 03/03/2016: modificato anche il login_operazione concatenando il nome dell'utente
	al valore contenuto 
    Sostituita clock_timestamp() con now() per avere la stessa data/ora per tuttii i 
    record. */
/* 09/10/2017:  SIAC-5352.
	L'update della data e' eseguita solo se non e' stata richiesta la
	riestrazione dei dati */
if eseguiEstrOld = false then
  update siac_t_registro_pcc  set rpcc_registrazione_data = now(),
      login_operazione = login_operazione||' - '||p_utente
  where rpcc_id=elencoRegistriRec.rpcc_id;    
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
rpcc_registrazione_data:=NULL;

end loop;

--raise notice 'Elenco ID = %', elencoRcpp_id;

delete from   siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
delete from   siac_rep_cap_ug where utente=user_table;

raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati del Registro PCC non trovati.' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'REGISTRO-PCC',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


-- 17.12.2018 SIAC-6604 - Sofia - Inizio

-- 20.12.2018 SIAC-6613 - Sofia - Inizio

drop FUNCTION if exists siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend" (
  p_ente_prop_id integer,
  p_anno varchar
);

CREATE OR REPLACE FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric
) AS
$body$
DECLARE

classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
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


BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;


select fnc_siac_random_user()
into	user_table;

-- 07/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 07/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 07/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id
 /* ANNA 31-05 inizio */
 and missione.missione_code::integer <= 19
 /* ANNA 31-05 fine */
 ;
 
		var_fondo_plur_anno_prec_a:=0;
		var_spese_impe_anni_prec_b=0;
        quota_fond_plur_anni_prec_c=0;
        spese_da_impeg_anno1_d=0;
        spese_da_impeg_anno2_e=0;  
        spese_da_impeg_anni_succ_f=0;
        
        
return query           
with tbclass as (select 	
v1.missione_tipo_desc			missione_tipo_desc,
		v1.missione_code				missione_code,
		v1.missione_desc				missione_desc,
		v1.programma_tipo_desc			programma_tipo_desc,
		v1.programma_code				programma_code,
		v1.programma_desc				programma_desc,
        v1.programma_id					programma_id,
        v1.ente_proprietario_id,
        v1.utente
from   
	siac_rep_mis_pro_tit_mac_riga_anni v1
    where utente=user_table
            group by v1.missione_tipo_desc, v1.missione_code, v1.missione_desc, 
            	v1.programma_tipo_desc, v1.programma_code, v1.programma_desc,
                v1.programma_id,
                v1.ente_proprietario_id, utente 
            order by missione_code,programma_code
           ),
tbfpvprec as (
select  
  importi.repimp_desc programma_code,
 sum(coalesce(importi.repimp_importo,0)) spese_fpv_anni_prec     
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where 	report.rep_codice				=	'BILR147'   				and
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
        group by importi.repimp_desc
        
        /*
        select a.programma_code as programma_code, 
        sum(a.importo_competenza) as spese_fpv_anni_prec from siac_t_cap_u_importi_anno_prec a
        where a.anno::INTEGER=annoBilInt-1
        and a.ente_proprietario_id=p_ente_prop_id
        and a.elem_cat_code like 'FPV%'
        group by a.programma_code*/
        ),
tbimpaprec as (
select 
--sum(coalesce(f.movgest_ts_det_importo,0)) spese_impe_anni_prec
--Spese impegnate negli esercizi precedenti e imputate all'esercizio N e coperte dal fondo pluriennale vincolato
-- si prendono le quote di impegni di competenza   
-- gli impegni considerati devono inoltre essere vincolati a fondo
-- l'importo considerato e' quello attuale
sum(coalesce( aa.movgest_ts_importo ,0)) spese_impe_anni_prec
, o.classif_code programma_code
          from siac_t_movgest a,  
          siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
          siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
          siac_r_movgest_ts_stato l, siac_d_movgest_stato m
          , siac_r_bil_elem_class n,
          siac_t_class o, siac_d_class_tipo p, 
          siac_r_movgest_ts_atto_amm q,
          siac_t_atto_amm r,
          --- 
           siac_d_movgest_tipo d_mov_tipo,
           siac_r_movgest_ts aa, 
           siac_t_avanzovincolo v, 
           siac_d_avanzovincolo_tipo vt
          where 
          a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and a.movgest_id = e.movgest_id  
          and e.movgest_ts_id = f.movgest_ts_id
          and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
          and l.movgest_ts_id=e.movgest_ts_id
          and l.movgest_stato_id=m.movgest_stato_id
          and n.classif_id = o.classif_id
          and o.classif_tipo_id=p.classif_tipo_id
          and n.elem_id = i.elem_id
          and q.movgest_ts_id=e.movgest_ts_id
          and q.attoamm_id = r.attoamm_id
          and a.bil_id = b.bil_id
          and h.elem_id=i.elem_id
          and a.ente_proprietario_id= p_ente_prop_id      
          and c.anno = p_anno -- anno bilancio p_anno
          and p.classif_tipo_code='PROGRAMMA'
--          and o.classif_code = classifBilRec.programma_code
          and a.movgest_anno = annoBilInt -- annoBilInt
          and g.movgest_ts_det_tipo_code='I'
          and m.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          --and r.attoamm_anno::integer < annoBilInt    
          --and r.attoamm_anno < p_anno --p_anno   
          and e.movgest_ts_id_padre is NULL    
          and i.movgest_id=a.movgest_id 
          and i.data_cancellazione is null
          and i.validita_fine is NULL          
          and l.data_cancellazione is null
          and l.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and n.data_cancellazione is null
          and n.validita_fine is null
          and q.data_cancellazione is null
          and q.validita_fine is null
          and f.data_cancellazione is null
          and f.validita_fine is null
          ---
          and aa.avav_id=v.avav_id     
          and v.avav_tipo_id=vt.avav_tipo_id 
          and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
          and e.movgest_ts_id = aa.movgest_ts_b_id 
          and aa.data_cancellazione is null
          and aa.validita_fine is null
          /*and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and e.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null ) */ 
          group by o.classif_code
          ),
tbriaccx as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
                (
                select sum(COALESCE(b.movgest_ts_det_importo,0)*-1) riacc_colonna_x,
                 s.classif_code programma_code
      from siac_r_modifica_stato a, siac_t_movgest_ts_det_mod b,
      siac_t_movgest_ts c, siac_d_modifica_stato d,
      siac_t_movgest e, siac_d_movgest_tipo f, siac_t_bil g,
      siac_t_periodo h, siac_t_modifica i, siac_d_modifica_tipo l,
      siac_d_modifica_stato m, 
      siac_t_bil_elem p, siac_r_movgest_bil_elem q,
      siac_r_bil_elem_class r, siac_t_class s, siac_d_class_tipo t,
      siac_r_movgest_ts_atto_amm qa,
          siac_t_atto_amm ra ,
      siac_r_movgest_ts_stato sti, siac_d_movgest_stato tipstimp    
      where b.mod_stato_r_id=a.mod_stato_r_id
      and b.movgest_ts_id = c.movgest_ts_id
      and e.movgest_tipo_id=f.movgest_tipo_id
      and d.mod_stato_id=a.mod_stato_id
      and e.movgest_id=c.movgest_id
      and g.bil_id=e.bil_id
      and i.mod_id=a.mod_id
      and i.mod_tipo_id=l.mod_tipo_id
      and m.mod_stato_id=a.mod_stato_id
      and g.periodo_id=h.periodo_id
      and qa.movgest_ts_id=c.movgest_ts_id
      and qa.attoamm_id = ra.attoamm_id
      --and ra.attoamm_anno < p_anno
       and e.movgest_anno = annoBilInt 
      --and c.movgest_ts_id=n.movgest_ts_id
      --and o.programma_id=n.programma_id
      and p.elem_id=q.elem_id
      and q.movgest_id=e.movgest_id
      and r.elem_id=p.elem_id
      and r.classif_id=s.classif_id
      and s.classif_tipo_id=t.classif_tipo_id
      and a.ente_proprietario_id=p_ente_prop_id
      and d.mod_stato_code='V'
      and f.movgest_tipo_code='I'
      --and e.movgest_anno = annoBilInt
      and h.anno=p_anno
      and m.mod_stato_code='V'
      --and l.mod_tipo_code in  ('ECON' , 'ECONB')
      and 
      ( l.mod_tipo_code like  'ECON%'
         or l.mod_tipo_desc like  'ROR%'
      )
      and l.mod_tipo_code <> 'REIMP'
      and t.classif_tipo_code='PROGRAMMA'
      --and s.classif_code = classifBilRec.programma_code
      --and b.movgest_ts_det_importo < 0
      and sti.movgest_ts_id = c.movgest_ts_id
      and sti.movgest_stato_id = tipstimp.movgest_stato_id
      and tipstimp.movgest_stato_code in ('D', 'N')
      and sti.data_cancellazione is NULL
      and sti.validita_fine is null
      and c.movgest_ts_id_padre is null
      and a.data_cancellazione is null
      and a.validita_fine is null
      and b.data_cancellazione is null
      and b.validita_fine is null
      and c.data_cancellazione is null
      and c.validita_fine is null
      and d.data_cancellazione is null
      and d.validita_fine is null
      and e.data_cancellazione is null
      and e.validita_fine is null
      and f.data_cancellazione is null
      and f.validita_fine is null
      and g.data_cancellazione is null
      and g.validita_fine is null
      and h.data_cancellazione is null
      and h.validita_fine is null
      and i.data_cancellazione is null
      and i.validita_fine is null
      and l.data_cancellazione is null
      and l.validita_fine is null
      and m.data_cancellazione is null
      and m.validita_fine is null
      and p.data_cancellazione is null
      and p.validita_fine is null
      and q.data_cancellazione is null
      and q.validita_fine is null
      and r.data_cancellazione is null
      and r.validita_fine is null
      and s.data_cancellazione is null
      and s.validita_fine is null
      and t.data_cancellazione is null
      and t.validita_fine is null
      and qa.data_cancellazione is null
      and qa.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and c.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null 
               )
      group by s.classif_code
      ),
tbriaccy as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
( select sum(COALESCE(b.movgest_ts_det_importo,0)*-1) riacc_colonna_y,
s.classif_code programma_code
      from siac_r_modifica_stato a, siac_t_movgest_ts_det_mod b,
      siac_t_movgest_ts c, siac_d_modifica_stato d,
      siac_t_movgest e, siac_d_movgest_tipo f, siac_t_bil g,
      siac_t_periodo h, siac_t_modifica i, siac_d_modifica_tipo l,
      siac_d_modifica_stato m, 
      siac_t_bil_elem p, siac_r_movgest_bil_elem q,
      siac_r_bil_elem_class r, siac_t_class s, siac_d_class_tipo t,
      siac_r_movgest_ts_atto_amm qa,
          siac_t_atto_amm ra ,
      siac_r_movgest_ts_stato sti, siac_d_movgest_stato tipstimp    
      where b.mod_stato_r_id=a.mod_stato_r_id
      and b.movgest_ts_id = c.movgest_ts_id
      and e.movgest_tipo_id=f.movgest_tipo_id
      and d.mod_stato_id=a.mod_stato_id
      and e.movgest_id=c.movgest_id
      and g.bil_id=e.bil_id
      and i.mod_id=a.mod_id
      and i.mod_tipo_id=l.mod_tipo_id
      and m.mod_stato_id=a.mod_stato_id
      and g.periodo_id=h.periodo_id
      and qa.movgest_ts_id=c.movgest_ts_id
      and qa.attoamm_id = ra.attoamm_id
      --and ra.attoamm_anno < p_anno
       and e.movgest_anno > annoBilInt 
      and p.elem_id=q.elem_id
      and q.movgest_id=e.movgest_id
      and r.elem_id=p.elem_id
      and r.classif_id=s.classif_id
      and s.classif_tipo_id=t.classif_tipo_id
      and a.ente_proprietario_id=p_ente_prop_id
      and d.mod_stato_code='V'
      and f.movgest_tipo_code='I'
      and h.anno=p_anno
      and m.mod_stato_code='V'
      --and l.mod_tipo_code in  ('ECON' , 'ECONB')
      and 
      ( l.mod_tipo_code like  'ECON%'
         or l.mod_tipo_desc like  'ROR%'
      )
      and l.mod_tipo_code <> 'REIMP'
      and t.classif_tipo_code='PROGRAMMA'
      --and b.movgest_ts_det_importo < 0
      and sti.movgest_ts_id = c.movgest_ts_id
      and sti.movgest_stato_id = tipstimp.movgest_stato_id
      and tipstimp.movgest_stato_code in ('D', 'N')
      and sti.data_cancellazione is NULL
      and sti.validita_fine is null
      and c.movgest_ts_id_padre is null
      and a.data_cancellazione is null
      and a.validita_fine is null
      and b.data_cancellazione is null
      and b.validita_fine is null
      and c.data_cancellazione is null
      and c.validita_fine is null
      and d.data_cancellazione is null
      and d.validita_fine is null
      and e.data_cancellazione is null
      and e.validita_fine is null
      and f.data_cancellazione is null
      and f.validita_fine is null
      and g.data_cancellazione is null
      and g.validita_fine is null
      and h.data_cancellazione is null
      and h.validita_fine is null
      and i.data_cancellazione is null
      and i.validita_fine is null
      and l.data_cancellazione is null
      and l.validita_fine is null
      and m.data_cancellazione is null
      and m.validita_fine is null
      and p.data_cancellazione is null
      and p.validita_fine is null
      and q.data_cancellazione is null
      and q.validita_fine is null
      and r.data_cancellazione is null
      and r.validita_fine is null
      and s.data_cancellazione is null
      and s.validita_fine is null
      and t.data_cancellazione is null
      and t.validita_fine is null
      and qa.data_cancellazione is null
      and qa.validita_fine is null
      and exists (select 
          		1 
                from siac_r_movgest_ts aa, 
            	siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
			where aa.avav_id=v.avav_id     
                and v.avav_tipo_id=vt.avav_tipo_id 
                and vt.avav_tipo_code like'FPV%' 
                --and aa.ente_proprietario_id=p_ente_prop_id
                and c.movgest_ts_id = aa.movgest_ts_b_id 
                and aa.data_cancellazione is null
                and aa.validita_fine is null )
      group by s.classif_code
      ),
      tbimpanno1 as 
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
      (
      select sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                           group by o.classif_code
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
                        --siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 1
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              )    
              ) as x
                group by x.programma_code 
            ),
tbimpanno2 as (
      select sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anno2_e, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno2_e, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                           group by o.classif_code
              )  
               union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
              			--siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno = annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                        and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              ) 
              ) as x
                group by x.programma_code 
                ),
tbimpannisuc as (
      select sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f , x.programma_code as programma_code from (
               (
              select sum(COALESCE(aa.movgest_ts_importo,0))
                      as spese_da_impeg_anni_succ_f, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                         siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                         siac_t_movgest acc,
                         siac_r_movgest_ts_stato rstacc,
                         siac_d_movgest_stato dstacc
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_ts_id_padre is null
                        and acc_ts.movgest_id = acc.movgest_id
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and acc.movgest_anno = annoBilInt
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id
                        and dstacc.movgest_stato_code in ('D', 'N')
                        /*and ( exists (select 
                              1 
                              from siac_r_movgest_ts aa, siac_t_movgest_ts acc_ts,
                              siac_t_movgest acc
                          where 
                               e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null 
                              and aa.movgest_ts_a_id = acc_ts.movgest_ts_id
                              and acc_ts.movgest_ts_id_padre is null
                              and acc_ts.movgest_id = acc.movgest_id
                              and acc.validita_fine is null
                              and acc.data_cancellazione is null
                              and acc_ts.validita_fine is null
                              and acc_ts.data_cancellazione is null
                              and acc.movgest_anno = 2017 --annoBilInt 
                              ) 
                        or exists 
                        (select 
                              1 
                              from siac_r_movgest_ts aa, 
                              siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt
                          where aa.avav_id=v.avav_id     
                              and v.avav_tipo_id=vt.avav_tipo_id 
                              and vt.avav_tipo_code = 'AAM' 
                              and e.movgest_ts_id = aa.movgest_ts_b_id 
                              and aa.data_cancellazione is null
                              and aa.validita_fine is null )  
                          )*/
                           group by o.classif_code)
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anni_succ_f, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        siac_r_movgest_ts_atto_amm q,
                        siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        and q.movgest_ts_id=e.movgest_ts_id
                        and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  p_anno 
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        and q.data_cancellazione is null
                        and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code = 'AAM' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                           group by o.classif_code
              )
              union(
              select sum(COALESCE(aa.movgest_ts_importo,0)) AS
                      spese_da_impeg_anno1_d, o.classif_code as programma_code
                        from siac_t_movgest a,  
                        siac_t_bil b, siac_t_periodo c, siac_t_movgest_ts e, siac_t_movgest_ts_det f,
                        siac_d_movgest_ts_det_tipo g, siac_t_bil_elem h, siac_r_movgest_bil_elem i,
                        siac_r_movgest_ts_stato l, siac_d_movgest_stato m
                        , siac_r_bil_elem_class n,
                        siac_t_class o, siac_d_class_tipo p, 
                        --siac_r_movgest_ts_atto_amm q,
                        --siac_t_atto_amm r, 
                         siac_d_movgest_tipo d_mov_tipo,
                        -- 
                        siac_r_movgest_ts aa, 
                        siac_t_avanzovincolo v, siac_d_avanzovincolo_tipo vt 
                        where 
                        a.bil_id = b.bil_id
                        and b.periodo_id=c.periodo_id
                        and a.movgest_id = e.movgest_id  
                        and e.movgest_ts_id = f.movgest_ts_id
                        and f.movgest_ts_det_tipo_id =g.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=a.movgest_tipo_id
                        and l.movgest_ts_id=e.movgest_ts_id
                        and l.movgest_stato_id=m.movgest_stato_id
                        and n.classif_id = o.classif_id
                        and o.classif_tipo_id=p.classif_tipo_id
                        and n.elem_id = i.elem_id
                        --and q.movgest_ts_id=e.movgest_ts_id
                        --and q.attoamm_id = r.attoamm_id
                        and a.bil_id = b.bil_id
                        and h.elem_id=i.elem_id
                        and a.ente_proprietario_id= p_ente_prop_id      
                        and c.anno =  (annoBilInt + 1)::varchar  
                        and p.classif_tipo_code='PROGRAMMA'
                        and a.movgest_anno > annoBilInt + 2
                        and g.movgest_ts_det_tipo_code='A'
                        and m.movgest_stato_code <> 'A'
                        and d_mov_tipo.movgest_tipo_code='I' 
                        --and r.attoamm_anno = p_anno   
                        and e.movgest_ts_id_padre is NULL    
                        and i.movgest_id=a.movgest_id 
                        and i.data_cancellazione is null
                        and i.validita_fine is NULL          
                        and l.data_cancellazione is null
                        and l.validita_fine is null
                        and f.data_cancellazione is null
                        and f.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and n.data_cancellazione is null
                        and n.validita_fine is null
                        --and q.data_cancellazione is null
                        --and q.validita_fine is null
                        and aa.avav_id=v.avav_id     
                        and v.avav_tipo_id=vt.avav_tipo_id 
                        and vt.avav_tipo_code like'FPV%' 
                        and e.movgest_ts_id = aa.movgest_ts_b_id 
                        and aa.data_cancellazione is null
                        and aa.validita_fine is null 
                        and exists (
                        	select 1
                            from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
                                 fase_bil_t_reimputazione fasereimp, siac_t_bil bilprec, siac_t_periodo pprec
                            where tipo.ente_proprietario_id= a.ente_proprietario_id 
                            and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP'
                            and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
                            and   fase.fase_bil_elab_esito='OK'
                            and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
                            and   fasereimp.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
                            and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
                            and   fasereimp.bil_id=bilprec.bil_id
                            and   bilprec.periodo_id = pprec.periodo_id
                            and   pprec.anno=p_anno
                            and   fasereimp.movgestnew_id = a.movgest_id
                            and   fase.data_cancellazione is null
                            and   fase.validita_fine is null
                            and   tipo.data_cancellazione is null
                            and   tipo.validita_fine is null
                        )
                       and not exists 
                        (
                           select 
                             1
                             from fase_bil_t_reimputazione_vincoli vreimp, siac_r_movgest_ts rold,
                             siac_r_movgest_ts rnew, siac_t_avanzovincolo avold, siac_d_avanzovincolo_tipo davold
                             where 
                             vreimp.movgest_ts_r_new_id =  aa.movgest_ts_r_id 
                             and vreimp.movgest_ts_r_id=rold.movgest_ts_r_id
                             and vreimp.movgest_ts_r_new_id = rnew.movgest_ts_r_id
                             and avold.avav_id=rold.avav_id
                             and avold.avav_tipo_id = davold.avav_tipo_id
                             and davold.avav_tipo_code like '%FPV%'
                        )
                        group by o.classif_code
              )   
              ) as x
                group by x.programma_code 
                )                               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
tbclass.missione_tipo_desc ,
tbclass.missione_code ,
tbclass.missione_desc ,
''::varchar programma_tipo_code ,
tbclass.programma_tipo_desc ,
tbclass.programma_code ,
tbclass.programma_desc ,
coalesce(tbfpvprec.spese_fpv_anni_prec,0) as fondo_plur_anno_prec_a,
--coalesce(var_spese_impe_anni_prec_b,0) as spese_impe_anni_prec_b,
coalesce(tbimpaprec.spese_impe_anni_prec,0) as spese_impe_anni_prec_b,
coalesce(tbfpvprec.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) spese_da_impeg_anno1_d,
coalesce(tbimpanno2.spese_da_impeg_anno2_e,0) spese_da_impeg_anno2_e,
coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0) spese_da_impeg_anni_succ_f,
coalesce(tbriaccx.riacc_colonna_x,0) riacc_colonna_x,
coalesce(tbriaccy.riacc_colonna_y,0) riacc_colonna_y,
coalesce(tbfpvprec.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
coalesce(tbimpanno1.spese_da_impeg_anno1_d,0) + coalesce(tbimpanno2.spese_da_impeg_anno2_e,0)+coalesce(tbimpannisuc.spese_da_impeg_anni_succ_f,0)
as fondo_plur_anno_g 
from tbclass left join tbimpaprec     
on tbclass.programma_code=tbimpaprec.programma_code
left join tbfpvprec 
on tbclass.programma_code=tbfpvprec.programma_code
left join tbriaccx     
on tbclass.programma_code=tbriaccx.programma_code
left join tbriaccy   
on tbclass.programma_code=tbriaccy.programma_code
left join tbimpanno1   
on tbclass.programma_code=tbimpanno1.programma_code
left join tbimpanno2   
on tbclass.programma_code=tbimpanno2.programma_code
left join tbimpannisuc   
on tbclass.programma_code=tbimpannisuc.programma_code;

          
      
    
delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;




raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='struttura bilancio altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- 20.12.2018 SIAC-6613 - Sofia - Fine 


-- 18.12.2018 Sofia - SIAC-6608 - inizio

SELECT * from fnc_dba_add_column_params ('siac_dwh_capitolo_fpv', 'data_elaborazione' , 'TIMESTAMP WITHOUT TIME ZONE DEFAULT now()');

-- 18.12.2018 Sofia - SIAC-6608 - fine

-- 22.12.2018 Alessandro - SIAC-6467 - inizio
DROP FUNCTION IF EXISTS siac.fnc_siac_capitoli_from_variazioni(INTEGER);
CREATE OR REPLACE FUNCTION fnc_siac_capitoli_from_variazioni(p_uid_variazione INTEGER)
	RETURNS TABLE(
		stato_variazione     VARCHAR,
		anno_capitolo        VARCHAR,
		numero_capitolo      VARCHAR,
		numero_articolo      VARCHAR,
		numero_ueb           VARCHAR,
		tipo_capitolo        VARCHAR,
		descrizione_capitolo VARCHAR,
		descrizione_articolo VARCHAR,
		-- Dati uscita
		missione       VARCHAR,
		programma      VARCHAR,
		titolo_uscita  VARCHAR,
		macroaggregato VARCHAR,
		-- Dati entrata
		titolo_entrata VARCHAR,
		tipologia      VARCHAR,
		categoria      VARCHAR,
		-- Importi
		var_competenza  NUMERIC,
		var_residuo     NUMERIC,
		var_cassa       NUMERIC,
		var_competenza1 NUMERIC,
		var_residuo1    NUMERIC,
		var_cassa1      NUMERIC,
		var_competenza2 NUMERIC,
		var_residuo2    NUMERIC,
		var_cassa2      NUMERIC,
		cap_competenza  NUMERIC,
		cap_residuo     NUMERIC,
		cap_cassa       NUMERIC,
		cap_competenza1 NUMERIC,
		cap_residuo1    NUMERIC,
		cap_cassa1      NUMERIC,
		cap_competenza2 NUMERIC,
		cap_residuo2    NUMERIC,
		cap_cassa2      NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id INTEGER;
BEGIN

	-- Utilizzo l'ente per migliorare la performance delle CTE nella query successiva
	SELECT ente_proprietario_id
	INTO v_ente_proprietario_id
	FROM siac_t_variazione
	WHERE siac_t_variazione.variazione_id = p_uid_variazione;

	RETURN QUERY
		-- CTE per uscita
		WITH missione AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc missione_tipo_desc,
				siac_t_class.classif_id missione_id,
				siac_t_class.classif_code missione_code,
				siac_t_class.classif_desc missione_desc,
				siac_t_class.validita_inizio missione_validita_inizio,
				siac_t_class.validita_fine missione_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR missione_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id_padre                      AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		programma AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc programma_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre missione_id,
				siac_t_class.classif_id programma_id,
				siac_t_class.classif_code programma_code,
				siac_t_class.classif_desc programma_desc,
				siac_t_class.validita_inizio programma_validita_inizio,
				siac_t_class.validita_fine programma_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR programma_code_desc,
				siac_r_bil_elem_class.elem_id programma_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione is null)
			WHERE siac_d_class_fam.classif_fam_code = '00001'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre is not null
			AND siac_t_class.data_cancellazione is null
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		titusc AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titusc_tipo_desc,
				siac_t_class.classif_id titusc_id,
				siac_t_class.classif_code titusc_code,
				siac_t_class.classif_desc titusc_desc,
				siac_t_class.validita_inizio titusc_validita_inizio,
				siac_t_class.validita_fine titusc_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titusc_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine,to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		macroag AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc macroag_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titusc_id,
				siac_t_class.classif_id macroag_id,
				siac_t_class.classif_code macroag_code,
				siac_t_class.classif_desc macroag_desc,
				siac_t_class.validita_inizio macroag_validita_inizio,
				siac_t_class.validita_fine macroag_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR macroag_code_desc,
				siac_r_bil_elem_class.elem_id macroag_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00002'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE per entrata
		titent AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc titent_tipo_desc,
				siac_t_class.classif_id titent_id,
				siac_t_class.classif_code titent_code,
				siac_t_class.classif_desc titent_desc,
				siac_t_class.validita_inizio titent_validita_inizio,
				siac_t_class.validita_fine titent_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre titent_id,
				siac_t_class.classif_id tipologia_id,
				siac_t_class.classif_code tipologia_code,
				siac_t_class.classif_desc tipologia_desc,
				siac_t_class.validita_inizio tipologia_validita_inizio,
				siac_t_class.validita_fine tipologia_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc,
				siac_r_class_fam_tree.classif_id_padre tipologia_id,
				siac_t_class.classif_id categoria_id,
				siac_t_class.classif_code categoria_code,
				siac_t_class.classif_desc categoria_desc,
				siac_t_class.validita_inizio categoria_validita_inizio,
				siac_t_class.validita_fine categoria_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc,
				siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		-- CTE importi variazione
		comp_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		residuo_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impRes,
				siac_t_periodo.anno::integer
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione  IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		cassa_variaz AS (
			SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil
			JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil.data_cancellazione IS NULL
			AND siac_t_variazione.variazione_id = p_uid_variazione
		),
		-- CTE importi capitolo
		comp_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		residuo_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impRes,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		cassa_capitolo AS (
			SELECT
				siac_t_bil_elem.elem_id,
				siac_t_bil_elem_det.elem_det_importo impSca,
				siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		)
		SELECT
			siac_d_variazione_stato.variazione_stato_tipo_desc stato_variazione
			,siac_t_periodo.anno                               anno_capitolo
			,siac_t_bil_elem.elem_code                         numero_capitolo
			,siac_t_bil_elem.elem_code2                        numero_articolo
			,siac_t_bil_elem.elem_code3                        numero_ueb
			,siac_d_bil_elem_tipo.elem_tipo_code               tipo_capitolo
			,siac_t_bil_elem.elem_desc                         descrizione_capitolo
			,siac_t_bil_elem.elem_desc2                        descrizione_articolo
			-- Dati uscita
			,missione.missione_code_desc   missione
			,programma.programma_code_desc programma
			,titusc.titusc_code_desc       titolo_uscita
			,macroag.macroag_code_desc     macroaggregato
			-- Dati entrata
			,titent.titent_code_desc       titolo_entrata
			,tipologia.tipologia_code_desc tipologia
			,categoria.categoria_code_desc categoria
			-- Importi variazione
			,comp_variaz.impSta     var_competenza
			,residuo_variaz.impRes  var_residuo
			,cassa_variaz.impSca    var_cassa
			,comp_variaz1.impSta    var_competenza1
			,residuo_variaz1.impRes var_residuo1
			,cassa_variaz1.impSca   var_cassa1
			,comp_variaz2.impSta    var_competenza2
			,residuo_variaz2.impRes var_residuo2
			,cassa_variaz2.impSca   var_cassa2
			-- Importi capitolo
			,comp_capitolo.impSta     cap_competenza
			,residuo_capitolo.impRes  cap_residuo
			,cassa_capitolo.impSca    cap_cassa
			,comp_capitolo1.impSta    cap_competenza1
			,residuo_capitolo1.impRes cap_residuo1
			,cassa_capitolo1.impSca   cap_cassa1
			,comp_capitolo2.impSta    cap_competenza2
			,residuo_capitolo2.impRes cap_residuo2 
			,cassa_capitolo2.impSca   cap_cassa2
		FROM siac_t_variazione
		JOIN siac_r_variazione_stato           ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                             AND siac_r_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_d_variazione_stato           ON (siac_r_variazione_stato.variazione_stato_tipo_id = siac_d_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem_det_var           ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem                   ON (siac_t_bil_elem_det_var.elem_id = siac_t_bil_elem.elem_id                                           AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                        ON (siac_t_bil_elem.bil_id = siac_t_bil.bil_id                                                          AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                    ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                                   AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_tipo              ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id                                    AND siac_d_bil_elem_tipo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_det_tipo          ON (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
		JOIN siac_t_bil     bil_variazione     ON (bil_variazione.bil_id = siac_t_variazione.bil_id                                                    AND bil_variazione.data_cancellazione IS NULL)
		JOIN siac_t_periodo periodo_variazione ON (bil_variazione.periodo_id = periodo_variazione.periodo_id                                           AND periodo_variazione.data_cancellazione IS NULL)
		-- Importi variazione, anno 0
		LEFT OUTER JOIN comp_variaz    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz.elem_id    AND comp_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_variaz ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz.elem_id AND residuo_variaz.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_variaz   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz.elem_id   AND cassa_variaz.anno = periodo_variazione.anno::INTEGER)
		-- Importi variazione, anno +1
		LEFT OUTER JOIN comp_variaz    comp_variaz1    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz1.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz1.elem_id    AND comp_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_variaz residuo_variaz1 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz1.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz1.elem_id AND residuo_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz1   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz1.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz1.elem_id   AND cassa_variaz1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi variazione, anno +2
		LEFT OUTER JOIN comp_variaz    comp_variaz2    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz2.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz2.elem_id    AND comp_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_variaz residuo_variaz2 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz2.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz2.elem_id AND residuo_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz2   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz2.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz2.elem_id   AND cassa_variaz2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Importi capitolo, anno 0
		LEFT OUTER JOIN comp_capitolo    ON (siac_t_bil_elem.elem_id = comp_capitolo.elem_id    AND comp_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN residuo_capitolo ON (siac_t_bil_elem.elem_id = residuo_capitolo.elem_id AND residuo_capitolo.anno = periodo_variazione.anno::INTEGER)
		LEFT OUTER JOIN cassa_capitolo   ON (siac_t_bil_elem.elem_id = cassa_capitolo.elem_id   AND cassa_capitolo.anno = periodo_variazione.anno::INTEGER)
		-- Importi capitolo, anno +1
		LEFT OUTER JOIN comp_capitolo    comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id    AND comp_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id AND residuo_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id   AND cassa_capitolo1.anno = periodo_variazione.anno::INTEGER + 1)
		-- Importi capitolo, anno +2
		LEFT OUTER JOIN comp_capitolo    comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id    AND comp_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id AND residuo_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id   AND cassa_capitolo2.anno = periodo_variazione.anno::INTEGER + 2)
		-- Classificatori
		LEFT OUTER JOIN macroag   ON (macroag.macroag_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN programma ON (programma.programma_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN missione  ON (missione.missione_id = programma.missione_id)
		LEFT OUTER JOIN titusc    ON (titusc.titusc_id = macroag.titusc_id)
		LEFT OUTER JOIN categoria ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN tipologia ON (tipologia.tipologia_id = categoria.tipologia_id)
		LEFT OUTER JOIN titent    ON (tipologia.titent_id = titent.titent_id)
		-- WHERE clause
		WHERE siac_t_variazione.variazione_id = p_uid_variazione
		AND siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		ORDER BY tipo_capitolo DESC, anno_capitolo, siac_t_bil_elem.elem_code::integer, siac_t_bil_elem.elem_code2::integer, siac_t_bil_elem.elem_code3::integer;
		
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- 22.12.2018 Alessandro - SIAC-6467 - fine

--  	SIAC-6365

CREATE OR REPLACE FUNCTION fnc_siac_annulla_registrazione_iva (
  p_subdociva_id integer,
  p_anno_bilancio varchar,
  p_enteproprietarioid integer,
  p_login_op varchar,
  out codresult integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
declare
    v_dataElaborazione    timestamp     := now();
    v_bil_id      		  integer       := 0 ;
    strMessaggio 		  VARCHAR(1500) :='Inizio elab.';
    v_subdociva_prot_def  varchar(200);
    v_ivareg_id           integer;
    v_subdociva_stato_id  integer;
    v_subdociva_prot_def_max varchar(200);
    v_subdociva_data_prot_def_max timestamp;     
begin
    strMessaggio := 'Inizio.';
    codresult := 0;  
    
    select siac_d_subdoc_iva_stato.subdociva_stato_id 
    into v_subdociva_stato_id
    from siac_d_subdoc_iva_stato
    where 
        siac_d_subdoc_iva_stato.ente_proprietario_id = p_enteproprietarioid
    and siac_d_subdoc_iva_stato.subdociva_stato_code = 'PR'
    and siac_d_subdoc_iva_stato.data_cancellazione is null;
    
    strMessaggio := 'estratto id di stato PR.';
    
    select ivareg_id,subdociva_prot_def
    into v_ivareg_id,v_subdociva_prot_def
    from siac_t_subdoc_iva
    where 
        siac_t_subdoc_iva.ente_proprietario_id = p_enteproprietarioid
    and siac_t_subdoc_iva.subdociva_id = p_subdociva_id;
    
    strMessaggio := 'estratto ivareg_id,subdociva_prot_def.';

    update  siac_r_subdoc_iva_stato set 
      data_cancellazione =now()
      ,data_modifica = now()
      ,login_operazione = p_login_op
	where     
         subdociva_id = p_subdociva_id
    and data_cancellazione is null;

    strMessaggio := 'cancellazione vecchio stato.';
    
    insert into siac_r_subdoc_iva_stato (
        subdociva_id
        ,subdociva_stato_id 
        ,validita_inizio 
        ,validita_fine
        ,ente_proprietario_id 
        ,data_cancellazione 
        ,login_operazione
    )values(
	     p_subdociva_id
        ,v_subdociva_stato_id 
        ,now() 
        ,null
        ,p_enteproprietarioid 
        ,null 
        ,p_login_op    
    );
    strMessaggio := 'inserimento nuovo stato.';
    
    update siac_t_subdoc_iva iva
    set    subdociva_prot_def=(iva.subdociva_prot_def::INTEGER)-1,
           data_modifica=now(),
           login_operazione=iva.login_operazione||p_login_op
    where iva.ivareg_id=v_ivareg_id
    and   iva.ente_proprietario_id=p_enteproprietarioid
    and   extract(year from iva.subdociva_data_prot_def)::varchar =p_anno_bilancio
    and   iva.subdociva_prot_def is not null
    and   iva.subdociva_prot_def::integer >= v_subdociva_prot_def::integer 
    and   iva.data_cancellazione is null
    and   iva.validita_fine is null;
    strMessaggio := 'allineamento registro IVA.';

    select 
      max(iva.subdociva_prot_def::integer) maxNum,
      max(iva.subdociva_data_prot_def) maxData
    into 
       v_subdociva_prot_def_max
      ,v_subdociva_data_prot_def_max           	
    from 
    	siac_t_subdoc_iva iva
    where 
            iva.ente_proprietario_id = p_enteproprietarioid
      and   iva.subdociva_anno = p_anno_bilancio
      and   iva.ivareg_id = v_ivareg_id
      and   iva.subdociva_data_prot_def is not null
      and   iva.data_cancellazione is null;
     strMessaggio := 'estrazione massimo numero e data per valorizzare il contatore def.';


	if v_subdociva_data_prot_def_max != null then
      update  siac_t_subdoc_iva_prot_def_num num
        set     subdociva_data_prot_def = v_subdociva_data_prot_def_max
               ,subdociva_prot_def = v_subdociva_prot_def_max::integer
               ,data_modifica=now()
               ,login_operazione=num.login_operazione||p_login_op
        from siac_v_bko_anno_bilancio anno
        where num.ente_proprietario_id=p_enteproprietarioid
        and   anno.ente_proprietario_id=p_enteproprietarioid
        and   num.periodo_id=anno.periodo_id
        and   anno.anno_bilancio=p_anno_bilancio::integer
        and   num.ivareg_id=v_ivareg_id;
	else
      update  siac_t_subdoc_iva_prot_def_num num
        set     data_cancellazione =now()
               ,data_modifica=now()
               ,login_operazione=num.login_operazione||p_login_op
        from siac_v_bko_anno_bilancio anno
        where num.ente_proprietario_id=p_enteproprietarioid
              and   anno.ente_proprietario_id=p_enteproprietarioid
              and   num.periodo_id=anno.periodo_id
              and   anno.anno_bilancio=p_anno_bilancio::integer
              and   num.ivareg_id=v_ivareg_id;
	end if;
    strMessaggio := 'siac_t_subdoc_iva_prot_def_num valorizzato';

	update siac_t_subdoc_iva set 
    	  subdociva_data_prot_def = NULL
        , subdociva_prot_def = NULL
        , subdociva_data_ordinativoadoc = NULL
        , subdociva_numordinativodoc = NULL
        , data_modifica = now()        
    where     
         subdociva_id = p_subdociva_id;

    strMessaggio := 'reset della quota iva';

	 messaggiorisultato := 'OK. '|| strMessaggio||'fine elaborazione.';
exception
    when RAISE_EXCEPTION THEN
    	raise notice '%   ERRORE : %',strMessaggio,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
    	codresult := -1;  
        return;
	when others  THEN
		raise notice ' % ERRORE DB: % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
    	codresult := -2;  
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--  	SIAC-6365

--SIAC-6466
DROP FUNCTION IF EXISTS fnc_siac_cespiti_elab_ammortamenti(
   integer,
   varchar,
   integer
);


CREATE OR REPLACE FUNCTION fnc_siac_cespiti_elab_ammortamenti (
  p_enteproprietarioid integer,
  p_loginoperazione varchar,
  p_anno integer,
  out numcespiti INTEGER,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
declare
    dataElaborazione timestamp 	:= now();
    strMessaggio VARCHAR(1500)	:='Inizio elab.';
    rec_elab_ammortamenti 		record;
    rec_elab_x_cespite    		record;
    v_elab_id 					INTEGER;        
    v_ces_id 					INTEGER;
    v_elab_dett_id_dare 		INTEGER;
    v_elab_dett_id_avere 		INTEGER;
    v_pnota_id 					INTEGER;
    v_ces_amm_dett_id			INTEGER;
begin
    numcespiti:=0;
    select elab_id into v_elab_id from siac_t_cespiti_elab_ammortamenti 
    where anno = p_anno and ente_proprietario_id = p_enteproprietarioid and data_cancellazione is null;
    
    if v_elab_id is not null then
    
      update  siac_r_cespiti_cespiti_elab_ammortamenti set data_cancellazione = now() ,validita_fine = now() ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
      update  siac_t_cespiti_elab_ammortamenti_dett    set data_cancellazione = now() ,validita_fine = now() ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
      update  siac_t_cespiti_elab_ammortamenti         set data_cancellazione = now() ,validita_fine = now() ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
	
    end if;

    insert into siac_t_cespiti_elab_ammortamenti (anno,stato_elaborazione,data_elaborazione,validita_inizio,validita_fine ,ente_proprietario_id,data_cancellazione,login_operazione) 
    values(p_anno,'AVVIATO',now(),now(),null, p_enteproprietarioid ,null,p_loginoperazione) RETURNING elab_id INTO v_elab_id;


    for rec_elab_ammortamenti in (	
         select 
        dct.pdce_conto_ammortamento_id, 
        dct.pdce_conto_ammortamento_code, 
        dct.pdce_conto_ammortamento_desc,
        dct.pdce_conto_fondo_ammortamento_id, 
        dct.pdce_conto_fondo_ammortamento_code, 
        dct.pdce_conto_fondo_ammortamento_desc,
        COALESCE(count(*),0) numero_cespiti,
        coalesce(sum(tamd.ces_amm_dett_importo), 0) importo
        from siac_t_cespiti tc
        , siac_d_cespiti_bene_tipo dct 
        , siac_t_cespiti_ammortamento tam 
        , siac_t_cespiti_ammortamento_dett tamd 
        where (tc.data_cessazione is null OR (EXTRACT(YEAR FROM tc.data_cessazione))::INTEGER = p_anno)
        and dct.ces_bene_tipo_id = tc.ces_bene_tipo_id
        and tam.ces_id = tc.ces_id and tam.data_cancellazione is null
        and tamd.ces_amm_id = tam.ces_amm_id 
        and tamd.data_cancellazione is null 
        and tamd.num_reg_def_ammortamento is null
        and dct.pdce_conto_ammortamento_id is not null 
        and dct.pdce_conto_fondo_ammortamento_id is not null
        and tamd.ces_amm_dett_anno = p_anno 
        and tamd.ente_proprietario_id = p_enteproprietarioid  
        group by 
        dct.pdce_conto_ammortamento_id, 
        dct.pdce_conto_ammortamento_code, 
        dct.pdce_conto_ammortamento_desc,
        dct.pdce_conto_fondo_ammortamento_id,
        dct.pdce_conto_fondo_ammortamento_code,
        dct.pdce_conto_fondo_ammortamento_desc
     ) loop
	
	strMessaggio :='inserimento in siac_t_cespiti_elab_ammortamenti_dett.';

    insert into siac_t_cespiti_elab_ammortamenti_dett (
    	elab_id
        ,pdce_conto_id
        ,pdce_conto_code
        ,pdce_conto_desc
        ,elab_det_importo
        ,elab_det_segno
        ,numero_cespiti
        ,pnota_id
        ,validita_inizio
        ,validita_fine
        ,ente_proprietario_id 
        ,data_cancellazione
        ,login_operazione
    )values(
         v_elab_id
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_id
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_code 
        ,rec_elab_ammortamenti.pdce_conto_ammortamento_desc
        ,rec_elab_ammortamenti.importo
        ,'Dare'        
        ,rec_elab_ammortamenti.numero_cespiti        
        ,null--TODO pnota_id  inizializzato da altro sistema,
        ,now()
        ,null
        ,p_enteproprietarioid
        ,null
        ,p_loginoperazione
    ) returning elab_dett_id into v_elab_dett_id_dare ;



   insert into siac_t_cespiti_elab_ammortamenti_dett (
    	elab_id
        ,pdce_conto_id
        ,pdce_conto_code
        ,pdce_conto_desc
        ,elab_det_importo
        ,elab_det_segno
        ,numero_cespiti
        ,pnota_id
        ,validita_inizio
        ,validita_fine
        ,ente_proprietario_id 
        ,data_cancellazione
        ,login_operazione
    )values(
         v_elab_id
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_id 
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_code 
        ,rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_desc
        ,rec_elab_ammortamenti.importo
        ,'Avere'        
        ,rec_elab_ammortamenti.numero_cespiti      
        ,null--TODO pnota_id  inizializzato da altro sistema,
        ,now()
        ,null
        ,p_enteproprietarioid
        ,null
        ,p_loginoperazione
    )returning elab_dett_id into v_elab_dett_id_avere ;

      for rec_elab_ammortamenti in (	
          select         	
              tc.ces_id   
              ,tamd.ces_amm_dett_id         
          from 
            siac_t_cespiti tc
          , siac_d_cespiti_bene_tipo dct 
          , siac_t_cespiti_ammortamento tam 
          , siac_t_cespiti_ammortamento_dett tamd 
          where tc.data_cessazione is null 
          and dct.ces_bene_tipo_id = tc.ces_bene_tipo_id
          and tam.ces_id = tc.ces_id 
          and tam.data_cancellazione is null
          and tamd.ces_amm_id = tam.ces_amm_id         
          and dct.pdce_conto_ammortamento_id       = rec_elab_ammortamenti.pdce_conto_ammortamento_id
          and dct.pdce_conto_fondo_ammortamento_id = rec_elab_ammortamenti.pdce_conto_fondo_ammortamento_id
          and tamd.data_cancellazione is null 
          and tamd.num_reg_def_ammortamento  is null
          and dct.pdce_conto_ammortamento_id is not null 
          and dct.pdce_conto_fondo_ammortamento_id is not null
          and tamd.ces_amm_dett_anno = p_anno::integer
          and tamd.ente_proprietario_id = p_enteproprietarioid
      ) loop


          insert into siac_r_cespiti_cespiti_elab_ammortamenti(
               ces_id
              ,elab_id
              ,elab_dett_id_dare
              ,elab_dett_id_avere
              ,ente_proprietario_id
              ,pnota_id
              ,validita_inizio
              ,validita_fine
              ,data_cancellazione
              ,login_operazione  
              ,ces_amm_dett_id  
          )values(
               rec_elab_ammortamenti.ces_id
              ,v_elab_id
              ,v_elab_dett_id_dare
              ,v_elab_dett_id_avere
              ,p_enteproprietarioid
              ,null--v_pnota_id,
              ,now()
              ,null
              ,null
              ,p_loginoperazione
              ,rec_elab_ammortamenti.ces_amm_dett_id
          );

			numcespiti := numcespiti + 1;
      end loop;

	end loop;	
    

	if numcespiti > 0 then
    	update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = 'CONCLUSO'  ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
	else
    	update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = 'CONCLUSO SENZA CESPITI' , data_cancellazione = now()  ,data_modifica = now() ,login_operazione = p_loginoperazione where elab_id = v_elab_id;
 	end if;

    messaggiorisultato := 'OK. Fine Elaborazione.';
    
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
    	--update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = messaggiorisultato , data_cancellazione = now() where elab_id = v_elab_id;

        return;
	when others  THEN
		raise notice ' %  % ERRORE DB: %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        --update siac_t_cespiti_elab_ammortamenti set stato_elaborazione = messaggiorisultato , data_cancellazione = now() where elab_id = v_elab_id;
        
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--Fine SIAC-6466

-- 08.01.2019 Sofia INC000002927785 - Inizio - conf. Siope+

drop index if exists idx_siac_d_accredito_tipo_oil_code;

CREATE UNIQUE INDEX idx_siac_d_accredito_tipo_oil_code ON siac.siac_d_accredito_tipo_oil
  USING btree (accredito_tipo_oil_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);
  
-- 08.01.2019 Sofia INC000002927785 - Inizio - conf. Siope+
