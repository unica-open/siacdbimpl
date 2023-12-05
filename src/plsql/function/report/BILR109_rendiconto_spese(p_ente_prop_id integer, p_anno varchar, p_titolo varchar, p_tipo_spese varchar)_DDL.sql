/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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