/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6090 - INIZIO

-- Inserimento azione nuova
INSERT INTO siac.siac_t_azione (
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
SELECT
  'OP-ENT-CompDefPreDoc',
  'Completa e Definisci Predisposizioni di Incasso',
  a.azione_tipo_id,
  b.gruppo_azioni_id,
  '/../siacbilapp/azioneRichiesta.do',
  FALSE,
  now(),
  a.ente_proprietario_id,
  'admin'
FROM siac_d_azione_tipo a
JOIN siac_d_gruppo_azioni b ON (b.ente_proprietario_id = a.ente_proprietario_id)
WHERE a.azione_tipo_code = 'ATTIVITA_SINGOLA'
AND b.gruppo_azioni_code = 'FIN_BASE2'
AND NOT EXISTS (
  SELECT 1
  FROM siac_t_azione z
  WHERE z.azione_code = 'OP-ENT-CompDefPreDoc'
  AND z.ente_proprietario_id = a.ente_proprietario_id
);

-- Update azione esistente
UPDATE siac_t_azione
SET azione_desc = 'Completa e Definisci Predisposizioni di Pagamento'
WHERE azione_code = 'OP-SPE-CompDefPreDoc';

-- SIAC-6090 - FINE

-- SIAC-6055 Maurizio - INIZIO

UPDATE
  siac.siac_t_report_importi
SET
  validita_fine = now(),
  data_cancellazione = now()
WHERE
  repimp_id in (
select a.repimp_id
from siac_t_report_importi a, siac_t_bil b
where
a.repimp_desc in (
'Anno Precedente - Fondo di Cassa al 1/1/esercizio di riferimento',
'Anno Precedente - Fondo pluriennale vincolato per spese in conto capitale ',
'Anno Precedente - Fondo pluriennale vincolato per spese correnti ',
'Anno Precedente - Utilizzo avanzo di amministrazione',
'Anno Precedente - Disavanzo di amministrazione',
'Spese correnti - di cui fondo pluriennale vincolato',
'Spese in conto capitale - di cui fondo pluriennale vincolato',
'fondo pluriennale vincolato'
)
and a.bil_id=b.bil_id
and b.bil_code='BIL_2018'
and a.data_cancellazione IS NULL
);


UPDATE
  siac.siac_r_report_importi
SET
  validita_fine = now(),
  data_cancellazione = now()
WHERE
  reprimp_id in (
select c.reprimp_id
from siac_t_report_importi a, siac_t_bil b,
siac_r_report_importi c
where
a.repimp_desc in (
'Anno Precedente - Fondo di Cassa al 1/1/esercizio di riferimento',
'Anno Precedente - Fondo pluriennale vincolato per spese in conto capitale ',
'Anno Precedente - Fondo pluriennale vincolato per spese correnti ',
'Anno Precedente - Utilizzo avanzo di amministrazione',
'Anno Precedente - Disavanzo di amministrazione',
'Spese correnti - di cui fondo pluriennale vincolato',
'Spese in conto capitale - di cui fondo pluriennale vincolato',
'fondo pluriennale vincolato'
)
and a.bil_id=b.bil_id
and b.bil_code='BIL_2018'
and c.repimp_id=a.repimp_id
and c.data_cancellazione IS NULL
);

-- SIAC-6055 Maurizio - FINE

-- SIAC-6143 Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR109_rendiconto_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_titolo varchar,
  p_tipo_spese varchar
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
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  spese_effettive_anno numeric
) AS
$body$
DECLARE

classifBilRec record;

annoCapImp varchar;
annoCapImp_int integer;
elemTipoCode varchar;

importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;

TipoImpstanz		varchar;
sqlQuery varchar;
idBilancio integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp_int:= p_anno::integer; 
elemTipoCode:='CAP-UG'; ------- capitolo di spesa gestione

RTN_MESSAGGIO:='lettura user table ''.';  
select fnc_siac_random_user()
into	user_table;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;

RTN_MESSAGGIO:='acquisizione struttura del bilancio ''.';  
 
raise notice 'acquisizione struttura del bilancio';
raise notice 'ora: % ',clock_timestamp()::varchar;

/*
	SIAC-6089. 13/04/2018.
    La query diventa dinamica perche' occorre parametrizzare la condizione sul titolo:
    - se il titolo che arriva in input e' 2 occorre estrarre anche il titolo 3.
    - negli altri casi funziona come prima.
*/
sqlQuery:='
insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,'''||user_table||''' from
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
WHERE missione_fam.classif_fam_desc::text = ''Spesa - MissioniProgrammi''::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = ''MISSIONE''::text 
    AND programma_tipo.classif_tipo_code::text = ''PROGRAMMA''::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = ''Spesa - TitoliMacroaggregati''::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = ''TITOLO_SPESA''::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = ''MACROAGGREGATO''::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id    
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
where v.ente_proprietario_id='||p_ente_prop_id;
if p_titolo <> '2' then
	sqlQuery:= sqlQuery || ' and  v.titusc_code ='''||p_titolo||'''
		and  v.missione_code in (select a.missione 
                         from siac_rep_titolo_missione a 
                         where a.ente_proprietario_id = '||p_ente_prop_id||'
                         and   a.titolo ='''||p_titolo||''') ';
else 
	sqlQuery:= sqlQuery || ' and  v.titusc_code in (''2'',''3'')
		and  v.missione_code in (select a.missione 
                         from siac_rep_titolo_missione a 
                         where a.ente_proprietario_id = '||p_ente_prop_id||'
                         and   a.titolo in (''2'',''3'')) ';
end if;
sqlQuery:= sqlQuery || ' and 
to_timestamp(''01/01/''||'''||p_anno||''',''dd/mm/yyyy'')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp(''31/12/''||'''||p_anno||''',''dd/mm/yyyy''))
and 
to_timestamp(''01/01/''||'''||p_anno||''',''dd/mm/yyyy'')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp(''31/12/''||'''||p_anno||''',''dd/mm/yyyy''))
and 
to_timestamp(''01/01/''||'''||p_anno||''',''dd/mm/yyyy'')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp(''31/12/''||'''||p_anno||''',''dd/mm/yyyy''))
and 
to_timestamp(''01/01/''||'''||p_anno||''',''dd/mm/yyyy'')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp(''31/12/''||'''||p_anno||''',''dd/mm/yyyy''))
order by missione_code, programma_code,titusc_code,macroag_code ';

raise notice 'Query: %', sqlQuery;

execute sqlQuery;

raise notice 'ora: % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='acquisizione capitoli di spesa gestione ''.';  

raise notice 'acquisizione capitoli di spesa gestione';
raise notice 'ora: % ',clock_timestamp()::varchar;

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
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	cat_del_capitolo.elem_cat_code	in	('STD', 'FSC', 'FPV')								
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
    and	r_cat_capitolo.data_cancellazione 			is null
    and macroaggr.classif_id in (select macroag_id from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table);

raise notice 'ora: % ',clock_timestamp()::varchar;

 select a.bil_id
 into idBilancio
 from siac_t_bil a, siac_t_periodo b
 where a.periodo_id=b.periodo_id
 and a.ente_proprietario_id =p_ente_prop_id
 and b.anno = p_anno
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;
 
-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEGLI IMPEGNI AFFERENTI L'ANNO DI ESERCIZIO ESCLUSI I RESIDUI
-----------------------------------------------------------------------------------------------------------------------------------
  RTN_MESSAGGIO:='acquisizione degli impegni ''.';   
----------------------------------------------------------------------------------------------------------
IF p_tipo_spese = 'I' THEN
  raise notice 'acquisizione degli impegni';
  raise notice 'ora: % ',clock_timestamp()::varchar;

-- SIAC-6143 10/05/2018.
-- Query resa dinamica e eliminati i collegamenti con le tabelle siac_t_bil e
-- siac_t_periodo per motivi prestazionali.

sqlQuery:='insert into siac_rep_impegni
select tb2.elem_id,
  0,
  '||p_ente_prop_id||',              
  '''||user_table||''' utente,
  tb.importo
  from (select    
  e.elem_id,
  sum (tsd.movgest_ts_det_importo) importo
      from 
          siac_t_bil_elem e,
          siac_d_bil_elem_tipo et,
          siac_r_movgest_bil_elem rm, 
          siac_t_movgest m,
          siac_d_movgest_tipo mt,
          siac_t_movgest_ts ts  ,
          siac_d_movgest_ts_tipo   tsti, 
          siac_r_movgest_ts_stato tsrs,
          siac_d_movgest_stato mst, 
          siac_t_movgest_ts_det   tsd ,
          siac_d_movgest_ts_det_tipo  tsdt
        where e.elem_tipo_id			=	et.elem_tipo_id
        and rm.elem_id      			= 	e.elem_id
        and rm.movgest_id      		=  	m.movgest_id 
        and m.movgest_tipo_id			= 	mt.movgest_tipo_id 
        and m.movgest_id				=	ts.movgest_id
        and ts.movgest_ts_id			=	tsrs.movgest_ts_id 
        and tsrs.movgest_stato_id  	= 	mst.movgest_stato_id 
        and ts.movgest_ts_tipo_id  	= 	tsti.movgest_ts_tipo_id 
        and ts.movgest_ts_id     		= 	tsd.movgest_ts_id 
        and tsd.movgest_ts_det_tipo_id  = tsdt.movgest_ts_det_tipo_id   
        and e.bil_id = '|| idBilancio || '       
        and e.ente_proprietario_id   	= 	'||p_ente_prop_id || ' 
        and et.elem_tipo_code      	=  	''' ||elemTipoCode ||'''
        and m.movgest_anno   			 = ' || annoCapImp_int ||'         
        and mt.movgest_tipo_code		=''I'' 
        and tsti.movgest_ts_tipo_code  = ''T'' 
        and mst.movgest_stato_code   in (''D'',''N'') ------ P,A,N         
        and tsdt.movgest_ts_det_tipo_code = ''A'' ----- importo attuale 
        and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
        and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
        and now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and now() between et.validita_inizio and coalesce (et.validita_fine, now())
        and now() between m.validita_inizio and coalesce (m.validita_fine, now())
        and now() between ts.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between mt.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between tsti.validita_inizio and coalesce (tsti.validita_fine, now())
        and now() between mst.validita_inizio and coalesce (mst.validita_fine, now())
        and now() between tsd.validita_inizio and coalesce (tsd.validita_fine, now())
        and now() between tsdt.validita_inizio and coalesce (tsdt.validita_fine, now())
        and e.data_cancellazione      is null     
        and et.data_cancellazione     is null 
        and rm.data_cancellazione 	is null 
        and m.data_cancellazione      is null 
        and mt.data_cancellazione     is null 
        and ts.data_cancellazione   	is null 
        and tsti.data_cancellazione   is null 
        and tsrs.data_cancellazione   is null 
        and mst.data_cancellazione    is null 
        and tsd.data_cancellazione   	is null 
        and tsdt.data_cancellazione   is null
        and e.elem_id in (select elem_id from siac_rep_cap_ug where utente='''||user_table||''')
  group by e.elem_id)
  tb 
  ,
  (select * from  siac_t_bil_elem    			capitolo_ug,
                  siac_d_bil_elem_tipo    	t_capitolo_ug
        where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
        and 	t_capitolo_ug.elem_tipo_code 	= 	''' ||elemTipoCode ||''') tb2
  where
   tb2.elem_id	=	tb.elem_id';

raise notice 'Query impegni: %', sqlQuery;

execute sqlQuery;

raise notice 'ora: % ',clock_timestamp()::varchar;
  
END IF;
-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEGI PAGAMENTI AFFERENTI L'ANNO DI ESERCIZIO COMPRESI I RESIDUI
-----------------------------------------------------------------------------------------------------------------------------------

-- SIAC-6143 10/05/2018.
-- Query resa dinamica e eliminati i collegamenti con le tabelle siac_t_bil e
-- siac_t_periodo per motivi prestazionali.

IF p_tipo_spese in ('PC','PR') THEN
  RTN_MESSAGGIO:='acquisizione dei pagamenti ''.';  
   
  raise notice 'acquisizione dei pagamenti';
  raise notice 'ora: % ',clock_timestamp()::varchar;
sqlQuery:='insert into siac_rep_impegni 
select 	  r_capitolo_ordinativo.elem_id,
              0,
              '||p_ente_prop_id||',              
              '''||user_table||''' utente,
              sum(ordinativo_imp.ord_ts_det_importo)
          from 		 
            siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
            siac_t_ordinativo				ordinativo,
            siac_d_ordinativo_tipo			tipo_ordinativo,
            siac_r_ordinativo_stato			r_stato_ordinativo,
            siac_d_ordinativo_stato			stato_ordinativo,
            siac_t_ordinativo_ts 			ordinativo_det,
			siac_t_ordinativo_ts_det 		ordinativo_imp,
        	siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
            siac_t_movgest     				movimento,
            siac_t_movgest_ts    			ts_movimento, 
            siac_r_liquidazione_movgest     r_liqmovgest,
            siac_r_liquidazione_ord         r_liqord     
    where 	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id		
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id        
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id  
        and r_liqord.sord_id                    =   ordinativo_det.ord_ts_id
        and	r_liqord.liq_id		                =	r_liqmovgest.liq_id
        and	r_liqmovgest.movgest_ts_id	        =	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id  
        and	ordinativo.bil_id					= 	' || idBilancio  || '           
        and	ordinativo.ente_proprietario_id		=	' || p_ente_prop_id || '      
        and	stato_ordinativo.ord_stato_code		<> ''A'' --ANNULLATO
        and	tipo_ordinativo.ord_tipo_code		= 	''P''		------ PAGATO    
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	''A'' 	---- importo attuale  ';
        IF p_tipo_spese = 'PC' THEN                    
	    	sqlQuery:= sqlQuery || ' 
            				and movimento.movgest_anno	= ' ||	annoCapImp_int;
        else
        	sqlQuery:= sqlQuery || ' 
            				and movimento.movgest_anno	< ' ||	annoCapImp_int;
        end if;                                        
        sqlQuery:= sqlQuery || ' and	r_capitolo_ordinativo.data_cancellazione	is null
        and	ordinativo.data_cancellazione				is null
        AND	tipo_ordinativo.data_cancellazione			is null
        and	r_stato_ordinativo.data_cancellazione		is null
        AND	stato_ordinativo.data_cancellazione			is null
        AND ordinativo_det.data_cancellazione			is null
 	  	aND ordinativo_imp.data_cancellazione			is null
        and ordinativo_imp_tipo.data_cancellazione		is null
        and	movimento.data_cancellazione				is null
        and	ts_movimento.data_cancellazione				is null
        and	r_liqord.data_cancellazione		            is null
        and	r_liqmovgest.data_cancellazione		        is null      
        and	now() between r_capitolo_ordinativo.validita_inizio and coalesce (r_capitolo_ordinativo.validita_fine, now())
        and	now() between r_stato_ordinativo.validita_inizio and coalesce (r_stato_ordinativo.validita_fine, now())
        and	now() between r_liqord.validita_inizio and coalesce (r_liqord.validita_fine, now())
        and	now() between r_liqmovgest.validita_inizio and coalesce (r_liqmovgest.validita_fine, now())          
    group by r_capitolo_ordinativo.elem_id,r_capitolo_ordinativo.ente_proprietario_id';          


raise notice 'Query pagamenti: %', sqlQuery;

execute sqlQuery;


  raise notice 'ora: % ',clock_timestamp()::varchar;
END IF;
RTN_MESSAGGIO:='preparazione dati in output ''.';  

raise notice 'preparazione dati in output';
raise notice 'ora: % ',clock_timestamp()::varchar;

/*
	SIAC-6089. 13/04/2018.
    Aggiunta una UNION per  il calcolo del totale perche' nel report e' necessario 
    introdurre un totale parziale nel caso l'utente abbia scelto i titoli 2 e 3 che
    devono essere gestiti insieme.
    Il nome della colonna macroaggregato e' restituito come 
    - 'Totale Spese in conto capitale' per il titolo 2;
    - 'Totale Spese per incremento attivita'' finanziarie' per il titolo 3;
    - 'Totale' per gli altri casi.
    
    Il codice del macroaggregato ha XX davanti per fare in modo che sia messo
    al fondo nel report.
*/
for classifBilRec in
select 	t1.missione_tipo_desc	missione_tipo_desc,
		t1.missione_code		missione_code,
		t1.missione_desc		missione_desc,
		t1.programma_tipo_desc	programma_tipo_desc,
		t1.programma_code		programma_code,
		t1.programma_desc		programma_desc,
		t1.titusc_tipo_desc		titusc_tipo_desc,
		t1.titusc_code			titusc_code,
		t1.titusc_desc			titusc_desc,
		t1.macroag_tipo_desc	macroag_tipo_desc,
		t1.macroag_code			macroag_code,
		t1.macroag_desc			macroag_desc,
    	t2.bil_anno 			BIL_ANNO,
        t2.elem_code     		BIL_ELE_CODE,
        t2.elem_code2     		BIL_ELE_CODE2,
        t2.elem_code3			BIL_ELE_CODE3,
		t2.elem_desc     		BIL_ELE_DESC,
        t2.elem_desc2     		BIL_ELE_DESC2,
        t2.elem_id      		BIL_ELE_ID,
       	t2.elem_id_padre 		BIL_ELE_ID_PADRE, 
        coalesce(t3.importo,0)				impegnato
        --coalesce(t4.pagamenti_competenza,0)	pagato
from siac_rep_mis_pro_tit_mac_riga_anni t1
        left join siac_rep_cap_ug  t2
        on (t1.programma_id = t2.programma_id    
           			and	t1.macroag_id	= t2.macroaggregato_id
           			and t1.ente_proprietario_id=p_ente_prop_id
					AND t1.utente=t1.utente
                    and t1.utente=user_table)
        left join 	siac_rep_impegni 	t3	
        				on (t3.elem_id	=	t2.elem_id 
                			and t3.utente=t2.utente)         
UNION
	select 	t1.missione_tipo_desc	missione_tipo_desc_2,
		t1.missione_code		missione_code_2,
		t1.missione_desc		missione_desc_2,
		t1.programma_tipo_desc	programma_tipo_desc_2,
		t1.programma_code		programma_code_2,
		t1.programma_desc		programma_desc_2,
		t1.titusc_tipo_desc		titusc_tipo_desc_2,
		t1.titusc_code			titusc_code_2,
		t1.titusc_desc			titusc_desc_2,
		t1.macroag_tipo_desc	macroag_tipo_desc_2,        
		'XX'||left(t1.macroag_code,1)||'000000'			macroag_code_2,
        case when t1.titusc_code = '2' then
        	'Totale Spese in conto capitale' 
            else case when t1.titusc_code = '3' then
            	'Totale Spese per incremento attivita'' finanziarie'
                else 'Totale' end
            end macroag_desc_2,					
    	t2.bil_anno 			BIL_ANNO_2,
        t2.elem_code     		BIL_ELE_CODE_2,
        t2.elem_code2     		BIL_ELE_CODE2_2,
        t2.elem_code3			BIL_ELE_CODE3_2,
		t2.elem_desc     		BIL_ELE_DESC_2,
        t2.elem_desc2     		BIL_ELE_DESC2_2,
        t2.elem_id      		BIL_ELE_ID_2,
       	t2.elem_id_padre 		BIL_ELE_ID_PADRE_2, 
        sum(coalesce(t3.importo,0))				impegnato
from siac_rep_mis_pro_tit_mac_riga_anni t1
        left join siac_rep_cap_ug  t2
        on (t1.programma_id = t2.programma_id    
           			and	t1.macroag_id	= t2.macroaggregato_id
           			and t1.ente_proprietario_id=p_ente_prop_id
					AND t1.utente=t1.utente
                    and t1.utente=user_table)
        left join 	siac_rep_impegni 	t3	
        	on (t3.elem_id	=	t2.elem_id 
                and t3.utente=t2.utente)      
        group by missione_tipo_desc_2, missione_code_2,missione_desc_2,
			programma_tipo_desc_2, programma_code_2, programma_desc_2,
			titusc_tipo_desc_2, titusc_code_2, titusc_desc_2,
			macroag_tipo_desc_2, macroag_code_2, macroag_desc_2,
    	 	BIL_ANNO_2, BIL_ELE_CODE_2, BIL_ELE_CODE2_2,
        	BIL_ELE_CODE3_2, BIL_ELE_DESC_2, BIL_ELE_DESC2_2,
            BIL_ELE_ID_2, BIL_ELE_ID_PADRE_2
        order by missione_code,programma_code,titusc_code,macroag_code       
loop
missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc:= classifBilRec.programma_tipo_desc;
programma_code:= classifBilRec.programma_code;
programma_desc:= classifBilRec.programma_desc;
titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
titusc_code:= classifBilRec.titusc_code;
titusc_desc:= classifBilRec.titusc_desc;
macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
macroag_code:= classifBilRec.macroag_code;
macroag_desc:= classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
bil_anno:=p_anno;
spese_effettive_anno:=classifBilRec.impegnato;
--pagato:=classifBilRec.pagato;
--fpv:=classifBilRec.fondo;
  		 
return next;
bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
spese_effettive_anno=0;
--pagato=0;
--fpv=0;

end loop;

raise notice 'fine preparazione dati in output';
raise notice 'ora: % ',clock_timestamp()::varchar;

delete from siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
delete from siac_rep_cap_ug 					where utente=user_table;
delete from siac_rep_impegni 					where utente=user_table;

raise notice 'fine cancellazione table';
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-6143 Maurizio - INIZIO

-- SIAC-6063 INIZIO
DROP FUNCTION IF EXISTS siac."BILR171_allegato_fpv_previsione_con_dati_gestione"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR171_allegato_fpv_previsione_con_dati_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  importi_capitoli numeric,
  spese_impegnate numeric,
  spese_impegnate_anno1 numeric,
  spese_impegnate_anno2 numeric,
  spese_impegnate_anno_succ numeric,
  importo_avanzo numeric,
  importo_avanzo_anno1 numeric,
  importo_avanzo_anno2 numeric,
  importo_avanzo_anno_succ numeric,
  elem_id integer,
  anno_esercizio varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int varchar;

BEGIN

/*Se la fase di bilancio e' Previsione allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno-1 per tutte le colonne. 

Se la fase di bilancio e' Esercizio Provvisorio allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno per tutte le colonne tranne quella relativa agli importi dei capitolo (colonna a).
In questo caso l''anno di esercizio e il bilancio id saranno quelli di p_anno-1.

L'anno relativo agli importi dei capitoli di anno_esercizio_prec
L'anno relativo agli importi degli impegni di annoImpImpegni_int*/


-- SIAC-6063
/*Aggiunto parametro p_anno_prospetto
Variabile annoImpImpegni_int sostituita da annoprospetto_int
Azzerati importi  spese_impegnate_anno1
                  spese_impegnate_anno2
                  spese_impegnate_anno_succ
                  importo_avanzo_anno1
                  importo_avanzo_anno2
                  importo_avanzo_anno_succ*/

RTN_MESSAGGIO := 'select 1'; 

bilancio_id := null;
bilancio_id_prec := null;

select bil.bil_id, fase_operativa.fase_operativa_code
into   bilancio_id, cod_fase_operativa
from  siac_d_fase_operativa fase_operativa, 
      siac_r_bil_fase_operativa bil_fase_operativa, 
      siac_t_bil bil, 
      siac_t_periodo periodo
where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
and   bil_fase_operativa.bil_id = bil.bil_id
and   periodo.periodo_id = bil.periodo_id
and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
and   bil.ente_proprietario_id = p_ente_prop_id
and   periodo.anno = p_anno
and   fase_operativa.data_cancellazione is null
and   bil_fase_operativa.data_cancellazione is null 
and   bil.data_cancellazione is null 
and   periodo.data_cancellazione is null;
 
/*if cod_fase_operativa = 'P' then
  
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer-1;
  
elsif cod_fase_operativa in ('E','G') then

  anno_esercizio := p_anno;
  annoprospetto_int := p_anno_prospetto::integer;
   
end if;*/
 
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer;
  
  annoprospetto_prec_int := ((p_anno_prospetto::integer)-1)::varchar;

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

-- annoImpImpegni_int := anno_esercizio::integer; 
-- annoImpImpegni_int := p_anno::integer; -- SIAC-6063

return query
select 
zz.*
from (
select 
tab1.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null) -- Potrebbe essere anche anno_esercizio_prec
),
capitoli_anno_prec as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 			
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id_prec													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
and	r_cat_capitolo.data_cancellazione           is null
),
capitoli_importo as ( -- Fondo pluriennale vincolato al 31 dicembre dell''esercizio N-1
select 		capitolo_importi.elem_id,
           	sum(capitolo_importi.elem_det_importo) importi_capitoli
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
where capitolo_importi.ente_proprietario_id = p_ente_prop_id  								 
and	capitolo.elem_id = capitolo_importi.elem_id 
and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
and	capitolo.elem_id = r_capitolo_stato.elem_id			
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
and	capitolo.bil_id = bilancio_id_prec							
and	tipo_elemento.elem_tipo_code = 'CAP-UG'
and	capitolo_imp_periodo.anno = annoprospetto_prec_int		  
--and	capitolo_imp_periodo.anno = anno_esercizio_prec	
and	stato_capitolo.elem_stato_code = 'VA'								
and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
and capitolo_imp_tipo.elem_det_tipo_code = 'STA'				
and	capitolo_importi.data_cancellazione 		is null
and	capitolo_imp_tipo.data_cancellazione 		is null
and	capitolo_imp_periodo.data_cancellazione 	is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
COALESCE(capitoli_importo.importi_capitoli,0)::numeric,
0::numeric spese_impegnate,
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
0::numeric importo_avanzo,
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli_anno_prec.elem_id::integer,
anno_esercizio::varchar
from struttura
left join capitoli_anno_prec on struttura.programma_id = capitoli_anno_prec.programma_id
                   and struttura.macroag_id = capitoli_anno_prec.macroaggregato_id
left join capitoli_importo on capitoli_anno_prec.elem_id = capitoli_importo.elem_id
) tab1
union all
select 
tab2.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
),
capitoli as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
-- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
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
and	r_cat_capitolo.data_cancellazione           is null
),
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
)
select impegni.movgest_ts_b_id,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,  
       case 
        when impegni.anno_impegno = annoprospetto_int+1 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno1,   
       case 
        when impegni.anno_impegno = annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno2,    
       case 
        when impegni.anno_impegno > annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+2 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno_succ,
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo,    
       case 
        when impegni.anno_impegno = annoprospetto_int+1 then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo_anno1,      
       case 
        when impegni.anno_impegno = annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno2,
       case 
        when impegni.anno_impegno > annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno_succ                      
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento
),
capitoli_impegni as (
select capitolo.elem_id, ts_movimento.movgest_ts_id
from  siac_t_bil_elem                 capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where capitolo.ente_proprietario_id = p_ente_prop_id
and   capitolo.bil_id =	bilancio_id
and   movimento.bil_id = bilancio_id
and   t_capitolo.elem_tipo_code = 'CAP-UG'
and   movimento.movgest_anno >= annoprospetto_int
-- and   movimento.movgest_anno >= annoImpImpegni_int
and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
and   capitolo.data_cancellazione is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione is null
and   movimento.data_cancellazione is null 
and   ts_movimento.data_cancellazione is null
and   ts_stato.data_cancellazione is null-- SIAC-5778
and   stato.data_cancellazione is null-- SIAC-5778 
)
select 
capitoli_impegni.elem_id,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.spese_impegnate_anno1) spese_impegnate_anno1,
sum(importo_impegni.spese_impegnate_anno2) spese_impegnate_anno2,
sum(importo_impegni.spese_impegnate_anno_succ) spese_impegnate_anno_succ,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(importo_impegni.importo_avanzo_anno1) importo_avanzo_anno1,
sum(importo_impegni.importo_avanzo_anno2) importo_avanzo_anno2,
sum(importo_impegni.importo_avanzo_anno_succ) importo_avanzo_anno_succ
from capitoli_impegni
left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
group by capitoli_impegni.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
0::numeric importi_capitoli,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
/*COALESCE(dati_impegni.spese_impegnate_anno1,0)::numeric spese_impegnate_anno1,
COALESCE(dati_impegni.spese_impegnate_anno2,0)::numeric spese_impegnate_anno2,
COALESCE(dati_impegni.spese_impegnate_anno_succ,0)::numeric spese_impegnate_anno_succ,*/
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
/*COALESCE(dati_impegni.importo_avanzo_anno1,0)::numeric importo_avanzo_anno1,
COALESCE(dati_impegni.importo_avanzo_anno2,0)::numeric importo_avanzo_anno2,
COALESCE(dati_impegni.importo_avanzo_anno_succ,0)::numeric importo_avanzo_anno_succ,*/
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli.elem_id::integer,
anno_esercizio::varchar
from struttura
left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
) tab2
) as zz;

-- raise notice 'Dati % - %',anno_esercizio::varchar,anno_esercizio_prec::varchar;
-- raise notice 'Dati % - %',bilancio_id::varchar,bilancio_id_prec::varchar;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_get_anno_prospetto (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  anno_prospetto varchar
) AS
$body$
DECLARE

anno_bilancio integer;
v_anno_prospetto integer;

BEGIN

anno_bilancio := p_anno::integer;

FOR counter IN 1..3 LOOP

  select
/*        case 
         when fase_operativa.fase_operativa_code = 'P' then
              anno_bilancio-1
         else
              anno_bilancio
        end anno_prospetto*/
        anno_bilancio as anno_prospetto
  into  v_anno_prospetto                   
  from  siac_d_fase_operativa fase_operativa, 
        siac_r_bil_fase_operativa bil_fase_operativa, 
        siac_t_bil bil, 
        siac_t_periodo periodo
  where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
  and   bil_fase_operativa.bil_id = bil.bil_id
  and   periodo.periodo_id = bil.periodo_id
  and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
  and   bil.ente_proprietario_id = p_ente_prop_id
  and   periodo.anno = p_anno
  and   fase_operativa.data_cancellazione is null
  and   bil_fase_operativa.data_cancellazione is null 
  and   bil.data_cancellazione is null 
  and   periodo.data_cancellazione is null;
 
  anno_prospetto := v_anno_prospetto::varchar;
  anno_bilancio  := anno_bilancio + 1;
  
  return next; 

END LOOP;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR171_anni_precedenti" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  imp_colonna_h numeric
) AS
$body$
DECLARE

BEGIN

if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
  select missione_code, programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR171_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code;

elsif p_anno_prospetto::integer = (p_anno::integer)+2 then

  return query
    select a.missione_code, a.programma_code,
    (a.importo_colonna_h+b.importo_colonna_h) as imp_colonna_h
  from (
  select missione_code, 
         programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR171_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  )
  group by missione_code, programma_code
  ) a, 
  (select missione_code, programma_code, 
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR171_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code;

end if;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-6063 FINE

-- SIAC-6156 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			 VARCHAR;
v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_dare_prec      NUMERIC :=0;
v_imp_avere_prec     NUMERIC :=0;
v_importo 			 NUMERIC :=0;
v_importo_prec 		 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_pdce_fam_code_prec VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;
v_anno_int integer; -- SIAC-5487
v_anno_prec_int integer; -- SIAC-5487

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

BEGIN

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer; -- SIAC-5487
v_anno_prec_int := p_anno::integer-1; -- SIAC-5487

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

WITH Importipn AS (
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_t_mov_ep		    mov_ep
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    AND pdce_fam.pdce_fam_code IN ('PP','OP')
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    AND   a.data_cancellazione is null
    AND   v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
    AND   v_anno_int BETWEEN date_part('year',a.validita_inizio) AND date_part('year',COALESCE(a.validita_fine,now())) -- SIAC-6156
    )
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine ;

END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       --case when zz.classif_code='26' then 'E.26' else zz.classif_code end codice_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       --case when zz.ordine='26' then 'E.26' else zz.ordine end codice_codifica_albero,
       case when zz.ordine='E.26' then 3 else zz.level end livello_codifica,
       --zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf, siac_t_class c
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           and c.classif_id=rt1.classif_id
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
/*           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)*/
           AND v_anno_int BETWEEN date_part('year',tt1.validita_inizio) AND 
           date_part('year',COALESCE(tt1.validita_fine,now())) --SIAC-5487
           AND v_anno_int BETWEEN date_part('year',rt1.validita_inizio) AND 
           date_part('year',COALESCE(rt1.validita_fine,now())) 
           AND v_anno_int BETWEEN date_part('year',c.validita_inizio) AND 
           date_part('year',COALESCE(c.validita_fine,now())) 
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn,siac_t_class c2
        WHERE tp.classif_id = tn.classif_id_padre 
        and c2.classif_id=tn.classif_id
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND v_anno_int BETWEEN date_part('year',tn.validita_inizio) AND 
           date_part('year',COALESCE(tn.validita_fine,now())) 
AND v_anno_int BETWEEN date_part('year',c2.validita_inizio) AND 
           date_part('year',COALESCE(c2.validita_fine,now()))            
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, 
--case when zz.ordine='26' then 'E.26' else zz.ordine end asc
zz.ordine
/*
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
FROM (
    SELECT tb.classif_classif_fam_tree_id,
           tb.classif_fam_tree_id, t1.classif_code,
           t1.classif_desc, ti1.classif_tipo_code,
           tb.classif_id, tb.classif_id_padre,
           tb.ente_proprietario_id, 
           CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
           ELSE tb.ordine
           END  ordine,
           tb.level,
           tb.arrhierarchy
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                 classif_fam_tree_id, 
                                 classif_id, 
                                 classif_id_padre, 
                                 ente_proprietario_id, 
                                 ordine, 
                                 livello, 
                                 level, arrhierarchy) AS (
           SELECT rt1.classif_classif_fam_tree_id,
                  rt1.classif_fam_tree_id,
                  rt1.classif_id,
                  rt1.classif_id_padre,
                  rt1.ente_proprietario_id,
                  rt1.ordine,
                  rt1.livello, 1,
                  ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
           AND tt1.ente_proprietario_id = p_ente_prop_id
           UNION ALL
           SELECT tn.classif_classif_fam_tree_id,
                  tn.classif_fam_tree_id,
                  tn.classif_id,
                  tn.classif_id_padre,
                  tn.ente_proprietario_id,
                  tn.ordine,
                  tn.livello,
                  tp.level + 1,
                  tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        )
        SELECT rqname.classif_classif_fam_tree_id,
               rqname.classif_fam_tree_id,
               rqname.classif_id,
               rqname.classif_id_padre,
               rqname.ente_proprietario_id,
               rqname.ordine, rqname.livello,
               rqname.level,
               rqname.arrhierarchy
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb,
        siac_t_class t1, siac_d_class_tipo ti1
    WHERE t1.classif_id = tb.classif_id 
    AND ti1.classif_tipo_id = t1.classif_tipo_id 
    AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc     */

LOOP
    
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
    END IF;
    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';
    v_pdce_fam_code_prec := '';

    FOR pdce IN
	SELECT d.pdce_fam_code, e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL
/*    AND   (v_anno_int BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487    
           OR
           v_anno_prec_int BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487 
          )*/
       AND   (i.anno::integer BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487    
           OR
           i.anno::integer BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487 
          )  
    AND  v_anno_int BETWEEN date_part('year',a.validita_inizio)::integer
    AND coalesce (date_part('year',a.validita_fine)::integer ,v_anno_int)     
    GROUP BY d.pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
    
    IF p_classificatori IN ('1','3') THEN
           
      IF pdce.movep_det_segno = 'Dare' THEN
         IF pdce.anno = p_anno THEN
            v_imp_dare := pdce.importo;
         ELSE
            v_imp_dare_prec := pdce.importo;
         END IF;   
      ELSIF pdce.movep_det_segno = 'Avere' THEN
         IF pdce.anno = p_anno THEN
            v_imp_avere := pdce.importo;
         ELSE
            v_imp_avere_prec := pdce.importo;
         END IF;                   
      END IF;               
    
      IF pdce.anno = p_anno THEN
         v_pdce_fam_code := pdce.pdce_fam_code;
      ELSE
         v_pdce_fam_code_prec := pdce.pdce_fam_code;
      END IF;    
        
    ELSIF p_classificatori = '2' THEN  
      IF pdce.pdce_fam_code = 'AP' THEN 
      
        IF pdce.movep_det_segno = 'Dare' THEN
           IF pdce.anno = p_anno THEN
              v_imp_dare := pdce.importo;
           ELSE
              v_imp_dare_prec := pdce.importo;
           END IF;   
        ELSIF pdce.movep_det_segno = 'Avere' THEN
           IF pdce.anno = p_anno THEN
              v_imp_avere := pdce.importo;
           ELSE
              v_imp_avere_prec := pdce.importo;
           END IF;                   
        END IF;       
      
        IF pdce.anno = p_anno THEN
           v_pdce_fam_code := pdce.pdce_fam_code;
        ELSE
           v_pdce_fam_code_prec := pdce.pdce_fam_code;
        END IF;      
      
      END IF;        
    END IF;  
                                                                        
    END LOOP;

    IF p_classificatori IN ('1','3') THEN

      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
         v_importo := v_imp_dare - v_imp_avere;   
      END IF; 
    
      IF v_pdce_fam_code_prec IN ('PP','OP','OA','RE') THEN
         v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
      ELSIF v_pdce_fam_code_prec IN ('AP','CE') THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;     
    
    ELSIF p_classificatori = '2' THEN
      
      IF v_pdce_fam_code = 'AP' THEN   
         v_importo := v_imp_dare - v_imp_avere;
      END IF; 
      
      IF v_pdce_fam_code_prec = 'AP' THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;       
            
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code_prec,classifGestione.classif_id,COALESCE(v_importo_prec,0),COALESCE(v_imp_dare_prec,0),COALESCE(v_imp_avere_prec,0);
    
    END IF;
    
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-6156 FINE

-- FUNZIONI MODIFICATE DA CSI - INIZIO

-- Function: fnc_siac_bko_config_report_prevind_xbrl()

-- DROP FUNCTION fnc_siac_bko_config_report_prevind_xbrl();

CREATE OR REPLACE FUNCTION fnc_siac_bko_config_report_BILR124_xbrl()
  RETURNS character varying AS
$BODY$
DECLARE
  rec_enti	record;
  sMsgReturn	varchar(1000):='';
  nIdEnte	integer;
BEGIN
    sMsgReturn:='';
    for rec_enti in
      select A.ente_proprietario_id, A.ente_denominazione, D.eptipo_code
      from siac_t_ente_proprietario A, siac_r_ente_proprietario_tipo T, siac_d_ente_proprietario_tipo D
      where A.ente_proprietario_id = T.ente_proprietario_id
        and T.eptipo_id = D.eptipo_id
      order by A.ente_proprietario_id  
    loop
      nIdEnte:=rec_enti.ente_proprietario_id;

      DELETE FROM siac.siac_t_xbrl_mapping_fatti WHERE xbrl_mapfat_rep_codice='BILR124' AND ente_proprietario_id=nIdEnte;
      DELETE FROM siac.siac_t_xbrl_report WHERE xbrl_rep_codice='BILR124' AND ente_proprietario_id=nIdEnte;

      INSERT INTO siac.siac_t_xbrl_report (xbrl_rep_codice,  xbrl_rep_fase_code,  xbrl_rep_tipologia_code,  xbrl_rep_xsd_tassonomia,  validita_inizio,  ente_proprietario_id,  login_operazione) VALUES ('BILR124','REND','SDB','bdap-sdb-rend-enti_2017-09-29.xsd',now(),nIdEnte,'admin');

      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEsePrecMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_EP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEserCompetMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_EC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotTotResPassRiportMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_TR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassiviMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_RS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCompetenzaMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_CP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCassaMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_CS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamResiduiMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_PR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotEconomieCompetMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_ECP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','ResiduiPassivi','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[= ''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_RS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','PrevDefCompetenza','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_CP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','PrevDefCassa','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_CS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','PagamResidui','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_PR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','PagamCompetenza','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_PC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotalePagamenti','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_TP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','RiaccResidui','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_R','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','Impegni','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_I','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','FondoPluriVinc','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_FPV','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','EconomieCompet','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_ECP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','ResiduiPassEserPrec','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_EP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','ResiduiPassEserCompet','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_EC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResPassRiport','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>-U.${titusc_code}.00.00.00.000_TR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassiviProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_RS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCompetenzaProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_CP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCassaProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_CS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamResiduiProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_PR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamCompetenzaProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_PC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotalePagamentiProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_TP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotRiaccResiduiProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_R','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotImpegniProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_I','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotFondoPluriVincProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_FPV','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotEconomieCompetProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_ECP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEserPrecProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_EP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEserCompetProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_EC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotTotResPassRiportProgr','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Prog<[=''${programma_code}''.replace(/(\d\d)(\d\d)/,''$1.$2'')=]>_TR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassiviMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_RS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCassaMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_CS','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamResiduiMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_PR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamCompetenzaMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_PC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotalePagamentiMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_TP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotRiaccResiduiMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_R','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotImpegniMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_I','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotFondoPluriVincMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_FPV','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPagamCompetenzaMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_PC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotalePagamentiMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_TP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotRiaccResiduiMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_R','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotImpegniMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_I','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotFondoPluriVincMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_FPV','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotEconomieCompetMissCompl2','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_ECP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEsePrecMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_EP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotResiduiPassEserCompetMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_EC','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotTotResPassRiportMissCompl','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_TotaleMissioni_TR','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR124','TotPrevDefCompetenzaMiss','SPE-<[=''${Classificatore}''.replace(/(.*)\s+-.*/,''$1'')=]>_Miss${missione_codice}_CP','d_anno/anno_bilancio*0/','eur','2',now(),nIdEnte,'admin','duration');
    end loop;

    return sMsgReturn;

exception
	when others THEN
		raise notice 'Errore di configurazione' ;
		sMsgReturn:='Errore di configurazione';
		return sMsgReturn;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fnc_siac_bko_config_report_BILR124_xbrl()
  OWNER TO siac;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR124_xbrl() TO public;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR124_xbrl() TO siac;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR124_xbrl() TO siac_rw;


CREATE OR REPLACE FUNCTION fnc_siac_bko_config_report_BILR129_xbrl()
  RETURNS character varying AS
$BODY$
DECLARE
  rec_enti	record;
  sMsgReturn	varchar(1000):='';
  nIdEnte	integer;
BEGIN
    sMsgReturn:='';
    for rec_enti in
      select A.ente_proprietario_id, A.ente_denominazione, D.eptipo_code
      from siac_t_ente_proprietario A, siac_r_ente_proprietario_tipo T, siac_d_ente_proprietario_tipo D
      where A.ente_proprietario_id = T.ente_proprietario_id
        and T.eptipo_id = D.eptipo_id
      order by A.ente_proprietario_id  
    loop
      nIdEnte:=rec_enti.ente_proprietario_id;

      DELETE FROM siac.siac_t_xbrl_mapping_fatti WHERE xbrl_mapfat_rep_codice='BILR129.tmap' AND ente_proprietario_id=nIdEnte;
      DELETE FROM siac.siac_t_xbrl_mapping_fatti WHERE xbrl_mapfat_rep_codice='BILR129' AND ente_proprietario_id=nIdEnte;
      DELETE FROM siac.siac_t_xbrl_report WHERE xbrl_rep_codice = 'BILR129' AND ente_proprietario_id=nIdEnte;

      INSERT INTO siac.siac_t_xbrl_report (xbrl_rep_codice,  xbrl_rep_fase_code,  xbrl_rep_tipologia_code,  xbrl_rep_xsd_tassonomia,  validita_inizio,  ente_proprietario_id,  login_operazione) VALUES ('BILR129','REND','SDB','bdap-sdb-rend-enti_2017-09-29.xsd',now(),nIdEnte,'admin');

      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129','ImportoCodice','${cb_xbrl_tagname}','','i_anno/anno_bilancio*0/','eur','2', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','instant');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129','ImportoCodiceAnnoPrec','${cb_xbrl_tagname}','','i_anno/anno_bilancio*-1/','eur','2', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','instant');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129','TotImpABCDE','SP_Passivo','','i_anno/anno_bilancio*0/','eur','2', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','instant');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129','TotImpABCDEAnno-1','SP_Passivo','','i_anno/anno_bilancio*-1/','eur','2', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','instant');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129','TotImpAnno','${cb_xbrl_totimp_tagname}','','i_anno/anno_bilancio*-0/','eur','2', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','instant');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129','TotImpAnno-1','${cb_xbrl_totimp_tagname}','','i_anno/anno_bilancio*-1/','eur','2', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','instant');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','0','SP_ContiOrdine','abstract','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','1','SP_ContiOrdineImpegniEserciziFuturi','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','2','SP_ContiOrdineBeniTerziInUso','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','3','SP_ContiOrdineBeniDatiUsoTerzi','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','4','SP_ContiOrdineGaranziePrestatePA','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','5','SP_ContiOrdineGaranziePrestateImpreseControllate','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','6','SP_ContiOrdineGaranziePrestateImpresePartecipate','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','7','SP_ContiOrdineGaranziePrestateAltreImprese','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A','SP_PatrimonioNetto','abstract','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A.I','SP_PatrimonioNettoFondoDotazione','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A.II','SP_PatrimonioNettoRiserve','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A.II.a','SP_PatrimonioNettoRiserveEserciziPrec','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A.II.b','SP_PatrimonioNettoRiserveCapitale','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A.II.c','SP_PatrimonioNettoRiservePermessiCostruire','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A.III','SP_PatrimonioNettoRisultatoEconomicoEsercizio','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','B','SP_FondiRischiOneri','abstract','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','B.1','SP_FondiRischiOneriTrattamentoQuiescenza','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','B.2','SP_FondiRischiOneriImposte','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','B.3','SP_FondiRischiOneriAltri','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','C','SP_TrattamentoFineRapporto','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D','SP_Debiti','abstract','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.1','SP_DebitiFinanz','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.1.a','SP_DebitiFinanzPrestitiObbligazionari','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.1.b','SP_DebitiFinanzVsAltrePA','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.1.c','SP_DebitiFinanzVsBancheTesorerie','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.1.d','SP_DebitiFinanzVsAltriFinanziatori','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.2','SP_DebitiVsFornitori','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.3','SP_DebitiAcconti','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.4','SP_DebitiTrafContr','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.4.a','SP_DebitiTrafContrEntiSSN','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.4.b','SP_DebitiTrafContrAltrePA','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.4.c','SP_DebitiTrafContrImpreseControllate','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.4.d','SP_DebitiTrafContrImpresePartecipate','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.4.e','SP_DebitiTrafContrAltriSoggetti','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.5','SP_DebitiAltriDebiti','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.5.a','SP_DebitiAltriDebitiTributari','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.5.b','SP_DebitiAltriDebitiVsIstitutiPrevidenza','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.5.c','SP_DebitiAltriDebitiAttivitaCTerzi','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','D.5.d','SP_DebitiAltriDebitiAltri','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','E','SP_RateiRiscontiPassivo','abstract','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','E.I','SP_RateiRiscontiRateiPassivi','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','E.II','SP_RateiRiscontiRiscontiPassivi','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','E.II.1','SP_RateiRiscontiContrInvest','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','E.II.1.a','SP_RateiRiscontiContrInvestAltrePA','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','E.II.1.b','SP_RateiRiscontiContrInvestAltriSoggetti','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','E.II.2','SP_RateiRiscontiConnessioniPluriennali','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','E.II.3','SP_RateiRiscontiAltriRiscontiPassivi','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A.II.d','SP_PatrimonioNettoRiserveIndBeniDemaPatriIndBeniCul','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
      INSERT INTO siac.siac_t_xbrl_mapping_fatti (xbrl_mapfat_rep_codice, xbrl_mapfat_variabile, xbrl_mapfat_fatto, xbrl_mapfat_tupla_group_key, xbrl_mapfat_periodo_code, xbrl_mapfat_unit_code, xbrl_mapfat_decimali, validita_inizio, ente_proprietario_id, login_operazione, xbrl_mapfat_periodo_tipo) VALUES ('BILR129.tmap','A.II.e','SP_PatrimonioNettoAltreRiserveIndisponibili','','unused','','0', to_timestamp('01-01-2016 00:00:00', 'DD-MM-YYYY HH24:MI:SS'),nIdEnte,'admin','duration');
    end loop;

    return sMsgReturn;

exception
	when others THEN
		raise notice 'Errore di configurazione' ;
		sMsgReturn:='Errore di configurazione';
		return sMsgReturn;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fnc_siac_bko_config_report_BILR129_xbrl()
  OWNER TO siac;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR129_xbrl() TO public;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR129_xbrl() TO siac;
GRANT EXECUTE ON FUNCTION fnc_siac_bko_config_report_BILR124_xbrl() TO siac_rw;

select * from fnc_siac_bko_config_report_BILR124_xbrl();
select * from fnc_siac_bko_config_report_BILR129_xbrl();


-- FUNZIONI MODIFICATE DA CSI - FINE

-- SIAC-6063 - Correzione procedura - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR171_anni_precedenti" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  imp_colonna_h numeric
) AS
$body$
DECLARE

BEGIN

if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
  select missione_code, programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR171_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code;

elsif p_anno_prospetto::integer = (p_anno::integer)+2 then

  return query
    select a.missione_code, a.programma_code,
    (a.importo_colonna_h-b.importo_colonna_h) as imp_colonna_h
  from (
  select missione_code, 
         programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR171_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  )
  group by missione_code, programma_code
  ) a, 
  (select missione_code, programma_code, 
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR171_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code;

end if;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-6063 - Correzione procedura - Maurizio - FINE

