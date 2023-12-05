/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR257_modello_003_registro_operaz_pcc" (
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

/* 27/10/2021.
   Funzione nata per la SIAC-8344.
   Estrae i dati delle fatture sospese e le carica sulla tabella 
   siac_t_registro_pcc per l'estrazione del report BILR257 - modello 003.
*/

 elencoRegistriRec record;

 elencoAttrib record;
 elencoClass	record;
 annoCompetenza_int integer;
 DEF_NULL	constant varchar:=''; 
 RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
 user_table varchar;
 cod_fisc VARCHAR;
 v_fam_missioneprogramma varchar :='00001';
 v_fam_titolomacroaggregato varchar := '00002';
 sql_query VARCHAR;
 eseguiEstrOld boolean;
 contaParamDate integer;
 max_data_sosp timestamp;
 sosp_causale varchar;
 tipo_contenzioso_pcc varchar;
 
 codice_report varchar :='BILR257';
 
 TIPO_CONTESTATO constant varchar := 'debito contestato';
 TIPO_CONTENZIOSO constant varchar := 'debito in contenzioso';
 TIPO_ACCETTAZIONE constant varchar := 'in attesa di accettazione';
 TIPO_NON_DEFINITO constant varchar := 'non previsto';
 
 NATURA_SPESA_CA constant varchar := 'CA';
 NATURA_SPESA_CO constant varchar := 'CO';
 NATURA_SPESA_NA constant varchar := 'NA';
 causale_pcc varchar;
 
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
raise notice  'Inserimento dati su siac_t_registro_pcc ''.';

--Inserisco i dati delle quote di documento che hanno una sospensione non riattivata.
--Devo estrarre con distinct perche' una quota potrebbe avere diverse date di
--sospensione non riattivate.
--Nell'estrazione dei dati successiva si prendera' la data piu' recente.
insert into siac_t_registro_pcc(doc_id, subdoc_id, pccop_tipo_id,
	validita_inizio, data_modifica, ente_proprietario_id, login_operazione)
select distinct doc.doc_id, subdoc.subdoc_id, (select pccop_tipo_id
								from siac_d_pcc_operazione_tipo op
                                where op.ente_proprietario_id=p_ente_prop_id
                                	and op.pccop_tipo_code='CO'
                                    and op.data_cancellazione IS NULL),
	now(), now(), p_ente_prop_id, codice_report                                    
from siac_t_doc doc,
	siac_t_subdoc subdoc,
	siac_t_subdoc_sospensione sosp 
where doc.doc_id=subdoc.doc_id
and subdoc.subdoc_id=sosp.subdoc_id
and doc.ente_proprietario_id=p_ente_prop_id
and subdoc.data_cancellazione is null
and doc.data_cancellazione is null
and sosp.data_cancellazione is null
and sosp.subdoc_sosp_data_riattivazione is null
and subdoc.subdoc_id not in (select a.subdoc_id
							 from  siac_t_registro_pcc a);

	
    --dati dell'account.
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
     
-- i capitoli sono caricati su una tabella d'appoggio perche' se la
-- query e' lasciata in quella principale rallenta troppo la 
-- procedura.
insert into siac_rep_cap_ug 
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroagg_id,
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
where programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and			
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
    capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and               
    capitolo.ente_proprietario_id=p_ente_prop_id						and
    programma_tipo.classif_tipo_code='PROGRAMMA' 						and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'	and
    --20/07/2017: devo estrarre tutti i capitoli, perche'' possono esserci capitoli
    --   di anni di bilancio precedenti.
   	--anno_eserc.anno= p_anno 												and
    tipo_elemento.elem_tipo_code in('CAP-UG','CAP-UP')		     			and     
	stato_capitolo.elem_stato_code	=	'VA'								and    
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
        
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati Dati del Registro PCC ';
     
sql_query='
with strutt as (select * from 
		"fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||', '''||p_anno||''', '''')),
 capitoli as (select *
 			  from siac_rep_cap_ug
              where ente_proprietario_id='||p_ente_prop_id||'
              	and utente='''||user_table||'''), 
cup_doc as (SELECT a.subdoc_id, 
            COALESCE(a.testo,'''') cup_desc_doc
      from siac_r_subdoc_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.ente_proprietario_id='||p_ente_prop_id||'
          and upper(b.attr_code) in(''CUP'') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL), 
cig_doc as (SELECT a.subdoc_id, 
            COALESCE(a.testo,'''') cig_desc_doc
      from siac_r_subdoc_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.ente_proprietario_id='||p_ente_prop_id||'
          and upper(b.attr_code) in(''CIG'') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL),
cup_impegno as (SELECT a.movgest_ts_id, 
            COALESCE(a.testo,'''') cup_desc_imp
      from siac_r_movgest_ts_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.ente_proprietario_id='||p_ente_prop_id||'
          and upper(b.attr_code) in(''CUP'') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL),           
cig_impegno as (SELECT a.movgest_ts_id, 
            COALESCE(a.testo,'''') cig_desc_imp
      from siac_r_movgest_ts_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.ente_proprietario_id='||p_ente_prop_id||'
          and upper(b.attr_code) in(''CIG'') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL)                           
select t_ente.codice_fiscale cod_fisc_ente_dest, 
	t_ente.ente_denominazione,
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
    replace (replace (t_subdoc.subdoc_desc,chr(10),'' ''),chr(13),'''') desc_quota, 
    t_registro_pcc.rpcc_quietanza_importo importo_quietanza,
    t_registro_pcc.ordinativo_numero, t_registro_pcc.ordinativo_data_emissione,
    t_registro_pcc.data_scadenza,
    cap.elem_code num_capitolo, cap.elem_code2 num_articolo, 
    cap.elem_code3 ueb, cap.bil_anno,
    movimento.movgest_anno anno_impegno,    
    movimento.movgest_numero numero_impegno, movimento.movgest_ts_id,
    cap.elem_id, soggetto_doc.soggetto_code, soggetto_doc.soggetto_desc,
    soggetto_doc.codice_fiscale, soggetto_doc.partita_iva,
    t_sog_pcc.codice_fiscale cod_fisc_ordinativo, 
    t_sog_pcc.partita_iva piva_ordinativo, movimento.movgest_id,
    t_registro_pcc.rpcc_registrazione_data,
    COALESCE(strutt.titusc_code,'''') titolo_code, 
    COALESCE(strutt.titusc_desc,'''') titolo_desc,
    cig_doc.cig_desc_doc,  cup_doc.cup_desc_doc,
    cig_impegno.cig_desc_imp,  cup_impegno.cup_desc_imp    
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
    LEFT JOIN (select r_doc_sog.doc_id, t_soggetto.codice_fiscale,
    				t_soggetto.partita_iva, t_soggetto.soggetto_code,
                    t_soggetto.soggetto_desc
    			from siac_r_doc_sog r_doc_sog,
                	siac_t_soggetto t_soggetto
                where t_soggetto.soggetto_id= r_doc_sog.soggetto_id
                	AND r_doc_sog.ente_proprietario_id='||p_ente_prop_id||'
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND t_soggetto.data_cancellazione IS NULL) soggetto_doc        
    	ON soggetto_doc.doc_id=t_doc.doc_id,
    siac_t_subdoc t_subdoc    	
    LEFT JOIN cup_doc
    	on cup_doc.subdoc_id=t_subdoc.subdoc_id
    LEFT JOIN cig_doc
    	on cig_doc.subdoc_id=t_subdoc.subdoc_id
    LEFT JOIN  (select r_subdoc_movgest_ts.subdoc_id, t_movgest_ts.movgest_ts_id,
    				t_movgest.movgest_id, t_movgest.movgest_anno, t_movgest.movgest_numero,
                    r_movgest_bil_elem.elem_id
    			from siac_r_subdoc_movgest_ts r_subdoc_movgest_ts,
                	siac_t_movgest_ts t_movgest_ts,
                    siac_t_movgest t_movgest,
                    siac_r_movgest_bil_elem r_movgest_bil_elem
                where t_movgest_ts.movgest_ts_id= r_subdoc_movgest_ts.movgest_ts_id
                	AND t_movgest.movgest_id= t_movgest_ts.movgest_id
                    AND r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                    AND r_subdoc_movgest_ts.ente_proprietario_id='||p_ente_prop_id||'
                    AND r_subdoc_movgest_ts.data_cancellazione IS NULL
        			AND t_movgest_ts.data_cancellazione IS NULL
        			AND t_movgest_ts.data_cancellazione IS NULL
                    AND r_movgest_bil_elem.data_cancellazione IS NULL) movimento                    
    	ON movimento.subdoc_id=t_subdoc.subdoc_id      
    LEFT JOIN cup_impegno
    	on cup_impegno.movgest_ts_id=movimento.movgest_ts_id
    LEFT JOIN cig_impegno
    	on cig_impegno.movgest_ts_id=movimento.movgest_ts_id          
    LEFT JOIN capitoli cap
        ON cap.elem_id=movimento.elem_id
    LEFT JOIN strutt
    	ON (strutt.programma_id = cap.programma_id    
      		and	strutt.macroag_id	= cap.macroaggregato_id )        
where t_ente.ente_proprietario_id=t_registro_pcc.ente_proprietario_id
	AND t_doc.doc_id=t_registro_pcc.doc_id
    AND t_subdoc.subdoc_id=t_registro_pcc.subdoc_id
    AND d_pcc_codice.pcccod_id=t_doc.pcccod_id
    AND d_pcc_oper_tipo.pccop_tipo_id=t_registro_pcc.pccop_tipo_id
	AND t_ente.ente_proprietario_id='||p_ente_prop_id||'
    	/* devo estrarre solo il tipo CO */ 
    AND d_pcc_oper_tipo.pccop_tipo_code=''CO''
    AND t_registro_pcc.login_operazione like '''||codice_report||'%''
    AND t_doc.data_cancellazione IS NULL
    AND t_subdoc.data_cancellazione IS NULL
    AND t_registro_pcc.data_cancellazione IS NULL
    AND t_ente.data_cancellazione IS NULL
    AND d_pcc_oper_tipo.data_cancellazione IS NULL '; 
 	if eseguiEstrOld = true THEN
    	sql_query=sql_query|| ' AND date_trunc(''day'',t_registro_pcc.rpcc_registrazione_data) between '''||p_data_reg_da||''' and '''||p_data_reg_a||''' ';
    ELSE
    	sql_query=sql_query|| ' AND t_registro_pcc.rpcc_registrazione_data IS NULL ';
    end if;
    --AND to_char (t_registro_pcc.rpcc_registrazione_data,''dd/mm/yyyy'')=''05/08/2016''
sql_query=sql_query|| ' ORDER BY t_doc.doc_data_emissione, t_doc.doc_numero, t_subdoc.subdoc_numero';

      
raise notice 'sql_query = %', sql_query;

for elencoRegistriRec IN
	execute sql_query 
loop
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
    num_capitolo=COALESCE(elencoRegistriRec.num_capitolo,'');
    cod_articolo=COALESCE(elencoRegistriRec.num_articolo,'');
    ueb=COALESCE(elencoRegistriRec.ueb,'');
    --cod_stato_debito=COALESCE(elencoRegistriRec.cod_debito,'');
  --  cod_causale_mov=COALESCE(elencoRegistriRec.cod_causale_pcc,'');
    	/* 16/03/2016: la descrizione della quota non deve superare i 100 caratteri */
    --descr_quota=elencoRegistriRec.desc_quota;
    --descr_quota=substr( COALESCE(elencoRegistriRec.desc_quota,''),1,100);
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
    titolo_code:=COALESCE(elencoRegistriRec.titolo_code,'');
    titolo_desc:=COALESCE(elencoRegistriRec.titolo_desc,'');
    cig_documento:=COALESCE(elencoRegistriRec.cig_desc_doc,'');
    cup_documento:=COALESCE(elencoRegistriRec.cup_desc_doc,'');
    cig_impegno:=COALESCE(elencoRegistriRec.cig_desc_imp,'');
    cup_impegno:=COALESCE(elencoRegistriRec.cup_desc_imp,'');
    
    max_data_sosp:=NULL;
    sosp_causale:='';
    tipo_contenzioso_pcc:='';
    
    select max(sosp.subdoc_sosp_data), sosp.subdoc_sosp_causale
    	into max_data_sosp, sosp_causale
    from siac_t_subdoc_sospensione sosp
    where sosp.ente_proprietario_id = p_ente_prop_id
    	and sosp.subdoc_id=elencoRegistriRec.subdoc_id
        and sosp.data_cancellazione IS NULL
        and sosp.subdoc_sosp_data_riattivazione IS NULL
    group by sosp.subdoc_sosp_causale;

raise notice'subdoc_id = % - data % - causale = %',elencoRegistriRec.subdoc_id,
	max_data_sosp, sosp_causale;
    
    --come descrizione quota metto la data di sospensione
    descr_quota:=to_char(max_data_sosp,'dd/mm/yyyy');
--raise notice 'Titolo = %',titolo_code;     
    	/* se il titolo e' 1, la natura spesa e' CO,
        	se e' 2 la natura spesa e' CA */
    if titolo_code= '1' THEN
    	natura_spesa=NATURA_SPESA_CO;
    elsif titolo_code= '2' THEN
    	natura_spesa=NATURA_SPESA_CA;
    else
        natura_spesa=NATURA_SPESA_NA;
    end if;
    
--raise notice 'natura_spesa = %',natura_spesa;      
 
cod_stato_debito:='';
cod_causale_mov:='';

--leggo dalle tabelle di configurazione specifiche di questo report
--i dati dello stato debito.
select distinct caus_deb.codice_stato_debito_pcc,
	caus_deb.descrizione_stato_debito_pcc,
    COALESCE(caus_deb.causale_pcc,'')
into cod_stato_debito, cod_causale_mov, causale_pcc
from siac_d_causale_contenzioso_pcc caus_cont,
	siac_d_causale_stato_debito_pcc caus_deb
where caus_cont.tipo_contenzioso_pcc=caus_deb.tipo_contenzioso_pcc
and caus_cont.ente_proprietario_id=p_ente_prop_id
and position(upper(caus_cont.causale_sospensione) in upper(sosp_causale))>0
and caus_deb.natura =natura_spesa
and caus_cont.data_cancellazione IS NULL
and caus_deb.data_cancellazione IS NULL;

raise notice 'sosp_causale = % - cod_causale_mov = % - cod_causale_mov % - causale_pcc = %', 
sosp_causale, cod_stato_debito, cod_causale_mov, causale_pcc;

    --aggiorno alcune delle informazioni 
update siac_t_registro_pcc
    set rpcc_esito_code='999',
        rpcc_esito_desc='Estrazione sospensioni report BILR257',
        rpcc_esito_data=now(),
        pcccau_id=(select caus.pcccau_id
                   from siac_d_pcc_causale caus
                   where caus.ente_proprietario_id=p_ente_prop_id
                    and caus.pcccau_code=COALESCE(causale_pcc,'')
                    and caus.data_cancellazione IS NULL),
        pccdeb_stato_id=(select deb.pccdeb_stato_id
                   from siac_d_pcc_debito_stato deb
                   where deb.ente_proprietario_id=p_ente_prop_id
                    and deb.pccdeb_stato_code='SOSP' --esigibilita' importo sospesa
                    and deb.data_cancellazione IS NULL)
where rpcc_id=elencoRegistriRec.rpcc_id;
      
/* e' eseguito l'aggiornamento della data registrazione in modo che i record
	siano estratti una volta sola ma solo se non e' stata richiesta la
	riestrazione dei dati */
if eseguiEstrOld = false then
  update siac_t_registro_pcc  
  set rpcc_registrazione_data = now(),
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