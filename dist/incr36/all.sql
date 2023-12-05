/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6089 - Maurizio - INIZIO
DROP FUNCTION IF EXISTS siac."BILR109_estrai_titoli"(p_ente_prop_id integer);

CREATE OR REPLACE FUNCTION siac."BILR109_estrai_titoli" (
  p_ente_prop_id integer
)
RETURNS TABLE (
  titolo_code varchar,
  titolo_desc varchar,
  titolo_composto varchar
) AS
$body$
DECLARE

classifBilRec record;

strTempCode varchar;
strTempDesc varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


BEGIN

/*
	Funzione per estrarre i titoli configurati.
    I titoli 2 e 3 devono essere restituiti insieme per esigenze del report
    BILR109 (SIAC-6089).
*/


RTN_MESSAGGIO:='acquisizione dati ''.';  
 
raise notice 'acquisizione dati';
raise notice 'ora: % ',clock_timestamp()::varchar;
 
strTempCode:='';
strTempDesc:='';

for classifBilRec in
  SELECT distinct srtm.titolo, titusc.classif_desc
  FROM siac_d_class_fam titusc_fam, siac_t_class_fam_tree titusc_tree, 
       siac_r_class_fam_tree titusc_r_cft, siac_t_class titusc, 
       siac_d_class_tipo titusc_tipo, siac_rep_titolo_missione srtm
  WHERE titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id
    AND srtm.titolo = titusc.classif_code
    AND srtm.ente_proprietario_id = p_ente_prop_id
  ORDER BY srtm.titolo
loop
  if classifBilRec.titolo not in ('2','3') THEN
  	titolo_code := classifBilRec.titolo;
  	titolo_desc := classifBilRec.classif_desc;
    titolo_composto := titolo_code||' - '|| titolo_desc;
    return next;
  elsif classifBilRec.titolo = '2' THEN 
  	strTempCode:= classifBilRec.titolo;
    strTempDesc:= classifBilRec.classif_desc;
  else 
  	titolo_code := strTempCode ;
  	titolo_desc := strTempDesc || ' - '|| classifBilRec.classif_desc;
    titolo_composto := strTempCode|| ' - '|| strTempDesc ||
    	  ' - '|| classifBilRec.titolo||' - '|| classifBilRec.classif_desc;
    return next;
  end if;
  		 

	titolo_code:= '';
    titolo_desc:= '';
    titolo_composto:= '';

end loop;

raise notice 'fine preparazione dati in output';
raise notice 'ora: % ',clock_timestamp()::varchar;


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

DROP FUNCTION IF EXISTS siac."BILR109_rendiconto_spese"(p_ente_prop_id integer, p_anno varchar, p_titolo varchar, p_tipo_spese varchar);

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

-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEGLI IMPEGNI AFFERENTI L'ANNO DI ESERCIZIO ESCLUSI I RESIDUI
-----------------------------------------------------------------------------------------------------------------------------------
  RTN_MESSAGGIO:='acquisizione degli impegni ''.';   
----------------------------------------------------------------------------------------------------------
IF p_tipo_spese = 'I' THEN
  raise notice 'acquisizione degli impegni';
  raise notice 'ora: % ',clock_timestamp()::varchar;

  insert into siac_rep_impegni
  select tb2.elem_id,
  0,
  p_ente_prop_id,
  user_table utente,
  tb.importo
  from (select    
  e.elem_id,
  sum (tsd.movgest_ts_det_importo) importo
      from 
          siac_t_bil b, 
          siac_t_periodo p, 
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
        where 
        b.periodo_id					=	p.periodo_id 
        and p.ente_proprietario_id   	= 	p_ente_prop_id
        and p.anno          			=   p_anno 
        and b.bil_id 					= 	e.bil_id
        and e.elem_tipo_id			=	et.elem_tipo_id
        and et.elem_tipo_code      	=  	elemTipoCode
        -------and et.elem_tipo_code      =  'CAP-UG'
        ----------and m.movgest_anno    <= annoCapImp_int
        and rm.elem_id      			= 	e.elem_id
        and rm.movgest_id      		=  	m.movgest_id 
        and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
        and m.movgest_anno   			 = annoCapImp_int
        --------and m.bil_id     = b.bil_id --non serve
        and m.movgest_tipo_id			= 	mt.movgest_tipo_id 
        and mt.movgest_tipo_code		='I' 
        and m.movgest_id				=	ts.movgest_id
        and ts.movgest_ts_id			=	tsrs.movgest_ts_id 
        and tsrs.movgest_stato_id  	= 	mst.movgest_stato_id 
        and tsti.movgest_ts_tipo_code  = 'T' 
        and mst.movgest_stato_code   in ('D','N') ------ P,A,N 
        and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
        and ts.movgest_ts_tipo_id  	= 	tsti.movgest_ts_tipo_id 
        and ts.movgest_ts_id     		= 	tsd.movgest_ts_id 
        and tsd.movgest_ts_det_tipo_id  = tsdt.movgest_ts_det_tipo_id 
        and tsdt.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and now() between b.validita_inizio and coalesce (b.validita_fine, now())
        and now() between p.validita_inizio and coalesce (p.validita_fine, now())
        and now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and now() between et.validita_inizio and coalesce (et.validita_fine, now())
        and now() between m.validita_inizio and coalesce (m.validita_fine, now())
        and now() between ts.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between mt.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between tsti.validita_inizio and coalesce (tsti.validita_fine, now())
        and now() between mst.validita_inizio and coalesce (mst.validita_fine, now())
        and now() between tsd.validita_inizio and coalesce (tsd.validita_fine, now())
        and now() between tsdt.validita_inizio and coalesce (tsdt.validita_fine, now())
        and p.data_cancellazione     	is null 
        and b.data_cancellazione      is null 
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
        and e.elem_id in (select elem_id from siac_rep_cap_ug where utente=user_table)
  group by e.elem_id)
  tb 
  ,
  (select * from  siac_t_bil_elem    			capitolo_ug,
                  siac_d_bil_elem_tipo    	t_capitolo_ug
        where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
        and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
  where
   tb2.elem_id	=	tb.elem_id;

  raise notice 'ora: % ',clock_timestamp()::varchar;
END IF;
-----------------------------------------------------------------------------------------------------------------------------------
-------		ACQUISIZIONE DEGI PAGAMENTI AFFERENTI L'ANNO DI ESERCIZIO COMPRESI I RESIDUI
-----------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------
IF p_tipo_spese in ('PC','PR') THEN
  RTN_MESSAGGIO:='acquisizione dei pagamenti ''.';  
   
  raise notice 'acquisizione dei pagamenti';
  raise notice 'ora: % ',clock_timestamp()::varchar;

  insert into siac_rep_impegni
  select 	  r_capitolo_ordinativo.elem_id,
              0,
              p_ente_prop_id,              
              user_table utente,
              sum(ordinativo_imp.ord_ts_det_importo)
          from 		siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
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
    where 	anno_eserc.anno						= 	p_anno											
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id
        and	bilancio.ente_proprietario_id	=	p_ente_prop_id
        and	r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
        and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
		and	tipo_ordinativo.ord_tipo_code		= 	'P'		------ PAGATO
        and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
        and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
        ------------------------------------------------------------------------------------------		
        ----------------------    si prendono gli stati Q, F, T
        ----------------------	  da verificare se e' giusto.
        -- Q= QUIETANZATO, F= FIRMATO, T= TRASMESSO
        -- I= INSERITO, A= ANNULLATO
        and	stato_ordinativo.ord_stato_code		<> 'A' --- 
        -----------------------------------------------------------------------------------------------
        and	ordinativo.bil_id					=	bilancio.bil_id
        and	ordinativo.ord_id					=	ordinativo_det.ord_id
        and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
        and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
        and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	---- importo attuala
        ---------------------------------------------------------------------------------------------------------------------
        and r_liqord.sord_id                    =   ordinativo_det.ord_ts_id
        and	r_liqord.liq_id		                =	r_liqmovgest.liq_id
        and	r_liqmovgest.movgest_ts_id	        =	ts_movimento.movgest_ts_id
        and	ts_movimento.movgest_id				=	movimento.movgest_id                  
	    and	((movimento.movgest_anno			=	anno_eserc.anno::integer and p_tipo_spese = 'PC') or
                 (movimento.movgest_anno			<	anno_eserc.anno::integer and p_tipo_spese = 'PR'))
        and movimento.bil_id					=	bilancio.bil_id	
        --------------------------------------------------------------------------------------------------------------------		
        and	bilancio.data_cancellazione 				is null
        and	anno_eserc.data_cancellazione 				is null
        and	r_capitolo_ordinativo.data_cancellazione	is null
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
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between r_capitolo_ordinativo.validita_inizio and coalesce (r_capitolo_ordinativo.validita_fine, now())
        and	now() between r_stato_ordinativo.validita_inizio and coalesce (r_stato_ordinativo.validita_fine, now())
        and	now() between r_liqord.validita_inizio and coalesce (r_liqord.validita_fine, now())
        and	now() between r_liqmovgest.validita_inizio and coalesce (r_liqmovgest.validita_fine, now())          
          group by r_capitolo_ordinativo.elem_id,r_capitolo_ordinativo.ente_proprietario_id;

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

-- SIAC-6089 - Maurizio - FINE

-- SIAC-5427 INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_variazioni_bozza (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar,
  p_contaparvarpeg integer,
  p_contaparvarbil integer,
  p_elemtipocode varchar
)
RETURNS TABLE (
  elem_id integer,
  imp_variazioni numeric,
  tipo_capitolo varchar,
  tipo_elem_det varchar,
  anno_variazioni varchar
) AS
$body$
DECLARE

sql_query VARCHAR;
elemTipoCode varchar;
elencoVariazioni record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN

IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 p_contaParVarPeg= 3 OR p_contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
     
    elemTipoCode := p_elemTipoCode; 
     
    sql_query='
    with variazioni as (
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo) imp_variazioni,
            cat_del_capitolo.elem_cat_code,
            tipo_elemento.elem_det_tipo_code,  ';
    
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_r_bil_elem_categoria 	r_cat_capitolo,      
	 		siac_d_bil_elem_categoria	cat_del_capitolo,     		      
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';     
                   
    IF p_contaParVarPeg = 3 THEN 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    END IF;
    
    IF p_contaParVarBil = 3 THEN 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    END IF;
    
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;
    
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id    
    and	    capitolo.elem_id				                    =	r_cat_capitolo.elem_id				
	and	    r_cat_capitolo.elem_cat_id		                    =	cat_del_capitolo.elem_cat_id    
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id '; 
    
    IF p_contaParVarPeg = 3 THEN 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    END IF;
    
    IF p_contaParVarBil = 3 THEN 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    END IF;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    
    sql_query=sql_query||' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    END IF;
    
    IF p_contaParVarPeg = 3 THEN 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    END IF;
    
    IF p_contaParVarBil = 3 THEN 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    END IF;
    
    IF p_code_sac_direz_peg <> '999' THEN
    
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
        
    END IF;
    
    IF p_code_sac_direz_bil <> '999' THEN
    
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
        
    END IF;
    
    sql_query=sql_query || ' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
 
    IF p_contaParVarPeg = 3 THEN 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    END IF;
    
    IF p_contaParVarBil = 3 THEN 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    END IF;
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                cat_del_capitolo.elem_cat_code,
                tipo_elemento.elem_det_tipo_code,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno
                )
                select variazioni.elem_id::integer,
                variazioni.imp_variazioni::numeric,
                variazioni.elem_cat_code::varchar,
                variazioni.elem_det_tipo_code::varchar,
                variazioni.anno::varchar
                from variazioni';                       
     
ELSE

sql_query = ' select
              null::integer as elem_id,
              null::numeric as imp_variazioni,
              null::varchar as tipo_capitolo,
              null::varchar as tipo_elem_det,
              null::varchar as anno_variazioni';    
     
END IF;    
       
raise notice 'Query: % ',  sql_query; 

return query execute sql_query;

raise notice 'fine OK';

exception     
	when others  THEN
        RTN_MESSAGGIO:='Errore Variazioni';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR195_Allegato_12_Entrate_TitoloTipologiaCategoria_EELL_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar,
  p_pluriennale varchar = 'S'::character varying
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  elem_id integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  entrata_ricorrente_anno numeric,
  entrata_ricorrente_anno1 numeric,
  entrata_ricorrente_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

annoCapImp  := p_anno; 
annoCapImp1 := ((p_anno::integer)+1)::varchar;   
annoCapImp2 := ((p_anno::integer)+2)::varchar; 

TipoImpComp  := 'STA';  -- competenza
elemTipoCode := 'CAP-EG'; -- tipo capitolo gestione

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
zz.*
FROM (
with strut_bilancio as(
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, null)
),
capitoli as(
select cl.classif_id categoria_id,
e.elem_id,
e.elem_code,
e.elem_code2,
e.elem_code3,
e.elem_desc
from  siac_r_bil_elem_class rc,
      siac_t_bil_elem e,
      siac_d_class_tipo ct,
      siac_t_class cl,
      siac_d_bil_elem_tipo tipo_elemento, 
      siac_d_bil_elem_stato stato_capitolo,
      siac_r_bil_elem_stato r_capitolo_stato,
      siac_d_bil_elem_categoria cat_del_capitolo,
      siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id			=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and e.bil_id                        =   bilancio_id
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and	stato_capitolo.elem_stato_code	=	'VA'
and ct.classif_tipo_code			=	'CATEGORIA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
),
stanziamento as (
select 	capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale     
from 	siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria 		cat_del_capitolo, 
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  			
and capitolo.bil_id						= bilancio_id											
and	capitolo.elem_id					= capitolo_importi.elem_id
and	capitolo.elem_tipo_id				= tipo_elemento.elem_tipo_id
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	= capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		= capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)       
and	capitolo.elem_id					= r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		= stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		= 'VA'
and	capitolo.elem_id					= r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			= cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code		= 'STD'
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id
),
entrate_non_ricorrenti as (
select capitolo_importi.elem_id,
       capitolo_imp_periodo.anno 				anno_entrate_non_ricorrenti,
       capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
       sum(capitolo_importi.elem_det_importo)   imp_entrate_non_ricorrenti    
from   siac_t_bil_elem_det 			    capitolo_importi,
       siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
       siac_t_periodo 					capitolo_imp_periodo,
       siac_t_bil_elem 				    capitolo,
       siac_d_bil_elem_tipo 			tipo_elemento,
       siac_t_bil 						bilancio,
       siac_t_periodo 					anno_eserc,
       siac_d_bil_elem_stato			stato_capitolo, 
       siac_r_bil_elem_stato 			r_capitolo_stato,
       siac_d_bil_elem_categoria 		cat_del_capitolo, 
       siac_r_bil_elem_categoria 		r_cat_capitolo
where  capitolo_importi.ente_proprietario_id = p_ente_prop_id  
and	anno_eserc.anno						= p_anno 												
and	bilancio.periodo_id					=anno_eserc.periodo_id 								
and	capitolo.bil_id						=bilancio.bil_id 			 
and	capitolo.elem_id					=capitolo_importi.elem_id 
and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2) 
and	capitolo.elem_id					=r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		=stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		='VA'
and	capitolo.elem_id					=r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			=cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code		='STD'
and capitolo_importi.elem_id not in
    (select r_class.elem_id   
    from  	siac_r_bil_elem_class	r_class,
            siac_t_class 			b,
            siac_d_class_tipo 		c
    where 	b.classif_id 		 = 	r_class.classif_id
    and 	b.classif_tipo_id 	 = 	c.classif_tipo_id
    and 	c.classif_tipo_code  = 'RICORRENTE_ENTRATA'
    and		b.classif_desc	     = 'Ricorrente'
    and	r_class.data_cancellazione				is null
    and	b.data_cancellazione					is null
    and c.data_cancellazione					is null) 
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	bilancio.data_cancellazione 			is null
and	anno_eserc.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by  capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id
),
variazioni as (
select *
from "fnc_variazioni_bozza" (
  p_ente_prop_id,
  p_anno,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo = 'STD'
)
select
p_anno::varchar,
--strut_bilancio.titolo_id::integer titolo_id,
strut_bilancio.titolo_code::varchar as code_titolo, 
strut_bilancio.titolo_desc::varchar as desc_titolo, 
--strut_bilancio.tipologia_id::integer tipologia_id,
strut_bilancio.tipologia_code::varchar as code_tipologia,
strut_bilancio.tipologia_desc::varchar as desc_tipologia,
--strut_bilancio.categoria_id::integer categoria_id,
strut_bilancio.categoria_code::varchar as code_categoria,
strut_bilancio.categoria_desc::varchar as desc_categoria,
capitoli.elem_id::integer as elem_id,
--capitoli.elem_code::varchar elem_code,
--capitoli.elem_code2::varchar elem_code2,
--capitoli.elem_code3::varchar elem_code3,
--capitoli.elem_desc::varchar elem_desc,
--COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale1,
--COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale2,
--COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale3,
--COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_variazioni1,
--COALESCE(variazioni2.imp_variazioni,0)::numeric as imp_variazioni2,
--COALESCE(variazioni3.imp_variazioni,0)::numeric as imp_variazioni3,
COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_stanziamento1,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE	 
         COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric
END imp_stanziamento2,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric
END imp_stanziamento3,
COALESCE(entrate1.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_entrate_non_ricorrenti1,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(entrate2.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric
END imp_entrate_non_ricorrenti2,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(entrate3.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric
END imp_entrate_non_ricorrenti3,
display_error::varchar
from  strut_bilancio
full  join capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
left  join stanziamento stanziamento1 on stanziamento1.elem_id = capitoli.elem_id 
                                      and stanziamento1.anno_stanziamento_parziale = annoCapImp
                                      and stanziamento1.tipo_elem_det = tipoImpComp  
left  join stanziamento stanziamento2 on stanziamento2.elem_id = capitoli.elem_id 
                                      and stanziamento2.anno_stanziamento_parziale = annoCapImp1
                                      and stanziamento2.tipo_elem_det = tipoImpComp  
left  join stanziamento stanziamento3 on stanziamento3.elem_id = capitoli.elem_id 
                                      and stanziamento3.anno_stanziamento_parziale = annoCapImp2
                                      and stanziamento3.tipo_elem_det = tipoImpComp 
left join variazioni variazioni1 on variazioni1.elem_id = capitoli.elem_id 
                                 and variazioni1.anno_variazioni = annoCapImp
                                 and variazioni1.tipo_elem_det = tipoImpComp
left join variazioni variazioni2 on variazioni2.elem_id = capitoli.elem_id 
                                 and variazioni2.anno_variazioni = annoCapImp1
                                 and variazioni2.tipo_elem_det = tipoImpComp
left join variazioni variazioni3 on variazioni3.elem_id = capitoli.elem_id 
                                 and variazioni3.anno_variazioni = annoCapImp2
                                 and variazioni3.tipo_elem_det = tipoImpComp      
left join entrate_non_ricorrenti entrate1 on entrate1.elem_id = capitoli.elem_id 
                                 and entrate1.anno_entrate_non_ricorrenti = annoCapImp
                                 and entrate1.tipo_elem_det = tipoImpComp  
left join entrate_non_ricorrenti entrate2 on entrate2.elem_id = capitoli.elem_id 
                                 and entrate2.anno_entrate_non_ricorrenti = annoCapImp1
                                 and entrate2.tipo_elem_det = tipoImpComp 
left join entrate_non_ricorrenti entrate3 on entrate3.elem_id = capitoli.elem_id 
                                 and entrate3.anno_entrate_non_ricorrenti = annoCapImp2
                                 and entrate3.tipo_elem_det = tipoImpComp     
) as zz;

raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR196_Allegato_12_Spese_correnti_MPM_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  stanziamento_prev_anno numeric,
  display_error varchar
) AS
$body$
DECLARE

tipoImpComp varchar;
elemTipoCode varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

TipoImpComp='STA';      -- competenza
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione
cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
zz.*
FROM (
with strut_bilancio as (
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_titolomacroaggregato
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
and d.classif_fam_code = v_fam_titolomacroaggregato
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
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
and titusc.titusc_code ='1'
and titusc.ente_proprietario_id=missione.ente_proprietario_id
--- forzatura schemi 2017 
union 
select missione.missione_tipo_desc,
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
from missione , programma,titusc, macroag
where programma.missione_id=missione.missione_id
and titusc.titusc_id=macroag.titusc_id
and  programma.programma_code in ('9901', '9902')
and titusc.titusc_code ='1'
and titusc.ente_proprietario_id=missione.ente_proprietario_id
-- forzatura schemi 2017 
),
capitoli as (
select 	programma.classif_id as programma_id,
		macroaggr.classif_id as macroaggr_id,
        -- anno_eserc.anno anno_bilancio,
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
where programma_tipo.classif_tipo_code = 'PROGRAMMA' 									
and   programma.classif_tipo_id		   = programma_tipo.classif_tipo_id 				
and   programma.classif_id			   = r_capitolo_programma.classif_id					
and   macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and   macroaggr.classif_tipo_id		   = macroaggr_tipo.classif_tipo_id 				
and   macroaggr.classif_id			   = r_capitolo_macroaggr.classif_id					
and   capitolo.ente_proprietario_id	   = p_ente_prop_id      												
and   capitolo.bil_id				   = bilancio_id										
and   capitolo.elem_tipo_id			   = tipo_elemento.elem_tipo_id 						
and   tipo_elemento.elem_tipo_code 	   = elemTipoCode						     	 
and   capitolo.elem_id				   = r_capitolo_programma.elem_id							
and   capitolo.elem_id				   = r_capitolo_macroaggr.elem_id						    
and   capitolo.elem_id				   = r_capitolo_stato.elem_id			
and	  r_capitolo_stato.elem_stato_id   = stato_capitolo.elem_stato_id		
and	  stato_capitolo.elem_stato_code   = 'VA'								
and   capitolo.elem_id				   = r_cat_capitolo.elem_id				
and	  r_cat_capitolo.elem_cat_id	   = cat_del_capitolo.elem_cat_id		
-- 05/08/2016: aggiunto FPVC
and   cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
-- cat_del_capitolo.elem_cat_code	=	'STD'		
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
),
stanziamento as (
select 	capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale   
from 	siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria	 	cat_del_capitolo,
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id   = p_ente_prop_id  							
and	    capitolo.bil_id							= bilancio_id			 
and	    capitolo.elem_id						= capitolo_importi.elem_id 
and	    capitolo.elem_tipo_id					= tipo_elemento.elem_tipo_id 						
and	    tipo_elemento.elem_tipo_code 			= elemTipoCode
and	    capitolo_importi.elem_det_tipo_id		= capitolo_imp_tipo.elem_det_tipo_id 		
and	    capitolo_imp_periodo.periodo_id			= capitolo_importi.periodo_id 			  
and	    capitolo_imp_periodo.anno               = p_anno_competenza       
and	    capitolo.elem_id				        = r_capitolo_stato.elem_id			
and	    r_capitolo_stato.elem_stato_id			= stato_capitolo.elem_stato_id		
and	    stato_capitolo.elem_stato_code			= 'VA'								
and	    capitolo.elem_id						= r_cat_capitolo.elem_id				
and	    r_cat_capitolo.elem_cat_id				= cat_del_capitolo.elem_cat_id
-- 05/08/2016: aggiunto FPVC
and	    cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc, 'FPVC')	
-- and	cat_del_capitolo.elem_cat_code	=	'STD'								
and	    capitolo_importi.data_cancellazione 		is null
and	    capitolo_imp_tipo.data_cancellazione 		is null
and	    capitolo_imp_periodo.data_cancellazione 	is null
and	    capitolo.data_cancellazione 				is null
and	    tipo_elemento.data_cancellazione 			is null
and	    stato_capitolo.data_cancellazione 			is null 
and	    r_capitolo_stato.data_cancellazione 		is null
and     cat_del_capitolo.data_cancellazione 		is null
and	    r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
variazioni as (
select *
from fnc_variazioni_bozza (
  p_ente_prop_id,
  p_anno_competenza,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo in (cap_std, cap_fpv, cap_fsc, 'FPVC')
)
select 
p_anno::varchar,
null::varchar  missione_tipo_code,
strut_bilancio.missione_tipo_desc::varchar,
strut_bilancio.missione_code::varchar,
strut_bilancio.missione_desc::varchar,
null::varchar  programma_tipo_code,
strut_bilancio.programma_tipo_desc::varchar,
SUBSTRING(strut_bilancio.programma_code from 3)::varchar programma_code,
strut_bilancio.programma_desc::varchar,
null::varchar  titusc_tipo_code,
strut_bilancio.titusc_tipo_desc::varchar,
strut_bilancio.titusc_code::varchar,
strut_bilancio.titusc_desc::varchar,
null::varchar  macroag_tipo_code,
strut_bilancio.macroag_tipo_desc::varchar,
strut_bilancio.macroag_code::varchar,
strut_bilancio.macroag_desc::varchar,
--capitoli.elem_id::integer,
COALESCE(stanziamento.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni.imp_variazioni,0)::numeric as imp_stanziamento,     
display_error::varchar
from   strut_bilancio
left   join capitoli on  strut_bilancio.programma_id = capitoli.programma_id
                     and strut_bilancio.macroag_id = capitoli.macroaggr_id
left   join stanziamento on stanziamento.elem_id = capitoli.elem_id 
                         and stanziamento.anno_stanziamento_parziale = p_anno_competenza
                         and stanziamento.tipo_elem_det = tipoImpComp 
left join variazioni on variazioni.elem_id = capitoli.elem_id 
                     and variazioni.anno_variazioni = p_anno_competenza
                     and variazioni.tipo_elem_det = tipoImpComp                                              
) as zz; 
                    
raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR197_Allegato_12_Spese_conto_capitale_incr_attivita_fin_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  stanziamento_prev_anno numeric,
  display_error varchar
) AS
$body$
DECLARE

tipoImpComp varchar;
elemTipoCode varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

TipoImpComp='STA';      -- competenza
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione
cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
zz.*
FROM (
with strut_bilancio as (
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_titolomacroaggregato
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
and d.classif_fam_code = v_fam_titolomacroaggregato
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
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
from missione , programma,titusc, macroag
/* 07/09/2016: start filtro per mis-prog-macro*/
-- forzatura schemi 2017 , siac_r_class progmacro
/*end filtro per mis-prog-macro*/
where programma.missione_id=missione.missione_id
and titusc.titusc_id=macroag.titusc_id
/* 07/09/2016: start filtro per mis-prog-macro*/
-- forzatura schemi 2017 AND programma.programma_id = progmacro.classif_a_id
-- forzatura schemi 2017 AND titusc.titusc_id = progmacro.classif_b_id
/* end filtro per mis-prog-macro*/ 
and titusc.titusc_code in ('2','3')
and titusc.ente_proprietario_id=missione.ente_proprietario_id
 -- forzatura schemi 2017
and exists ( select 1 
             from siac_r_class x, siac_t_class y, siac_d_class_tipo z
             where programma.programma_id = x.classif_a_id
             and y.classif_id = x.classif_b_id 
             and y.classif_tipo_id=z.classif_tipo_id
             and z.classif_tipo_code ='TITOLO_SPESA'
             and y.classif_code in ('2','3')
           )
 -- forzatura schemi 2017
),
capitoli as (
select 	programma.classif_id as programma_id,
		macroaggr.classif_id as macroaggr_id,
        -- anno_eserc.anno anno_bilancio,
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
where programma_tipo.classif_tipo_code = 'PROGRAMMA' 									
and   programma.classif_tipo_id		   = programma_tipo.classif_tipo_id 				
and   programma.classif_id			   = r_capitolo_programma.classif_id					
and   macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and   macroaggr.classif_tipo_id		   = macroaggr_tipo.classif_tipo_id 				
and   macroaggr.classif_id			   = r_capitolo_macroaggr.classif_id					
and   capitolo.ente_proprietario_id	   = p_ente_prop_id      												
and   capitolo.bil_id				   = bilancio_id										
and   capitolo.elem_tipo_id			   = tipo_elemento.elem_tipo_id 						
and   tipo_elemento.elem_tipo_code 	   = elemTipoCode						     	 
and   capitolo.elem_id				   = r_capitolo_programma.elem_id							
and   capitolo.elem_id				   = r_capitolo_macroaggr.elem_id						    
and   capitolo.elem_id				   = r_capitolo_stato.elem_id			
and	  r_capitolo_stato.elem_stato_id   = stato_capitolo.elem_stato_id		
and	  stato_capitolo.elem_stato_code   = 'VA'								
and   capitolo.elem_id				   = r_cat_capitolo.elem_id				
and	  r_cat_capitolo.elem_cat_id	   = cat_del_capitolo.elem_cat_id		
-- 05/08/2016: aggiunto FPVC
and   cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
-- cat_del_capitolo.elem_cat_code	=	'STD'		
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
),
stanziamento as (
select 	capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale   
from 	siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria	 	cat_del_capitolo,
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id   = p_ente_prop_id  							
and	    capitolo.bil_id							= bilancio_id			 
and	    capitolo.elem_id						= capitolo_importi.elem_id 
and	    capitolo.elem_tipo_id					= tipo_elemento.elem_tipo_id 						
and	    tipo_elemento.elem_tipo_code 			= elemTipoCode
and	    capitolo_importi.elem_det_tipo_id		= capitolo_imp_tipo.elem_det_tipo_id 		
and	    capitolo_imp_periodo.periodo_id			= capitolo_importi.periodo_id 			  
and	    capitolo_imp_periodo.anno               = p_anno_competenza       
and	    capitolo.elem_id				        = r_capitolo_stato.elem_id			
and	    r_capitolo_stato.elem_stato_id			= stato_capitolo.elem_stato_id		
and	    stato_capitolo.elem_stato_code			= 'VA'								
and	    capitolo.elem_id						= r_cat_capitolo.elem_id				
and	    r_cat_capitolo.elem_cat_id				= cat_del_capitolo.elem_cat_id
-- 05/08/2016: aggiunto FPVC
and	    cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc, 'FPVC')	
-- and	cat_del_capitolo.elem_cat_code	=	'STD'								
and	    capitolo_importi.data_cancellazione 		is null
and	    capitolo_imp_tipo.data_cancellazione 		is null
and	    capitolo_imp_periodo.data_cancellazione 	is null
and	    capitolo.data_cancellazione 				is null
and	    tipo_elemento.data_cancellazione 			is null
and	    stato_capitolo.data_cancellazione 			is null 
and	    r_capitolo_stato.data_cancellazione 		is null
and     cat_del_capitolo.data_cancellazione 		is null
and	    r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
variazioni as (
select *
from fnc_variazioni_bozza (
  p_ente_prop_id,
  p_anno_competenza,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo in (cap_std, cap_fpv, cap_fsc, 'FPVC')
)
select 
p_anno::varchar,
null::varchar  missione_tipo_code,
strut_bilancio.missione_tipo_desc::varchar,
strut_bilancio.missione_code::varchar,
strut_bilancio.missione_desc::varchar,
null::varchar  programma_tipo_code,
strut_bilancio.programma_tipo_desc::varchar,
SUBSTRING(strut_bilancio.programma_code from 3)::varchar programma_code,
strut_bilancio.programma_desc::varchar,
null::varchar  titusc_tipo_code,
strut_bilancio.titusc_tipo_desc::varchar,
strut_bilancio.titusc_code::varchar,
strut_bilancio.titusc_desc::varchar,
null::varchar  macroag_tipo_code,
strut_bilancio.macroag_tipo_desc::varchar,
strut_bilancio.macroag_code::varchar,
strut_bilancio.macroag_desc::varchar,
--capitoli.elem_id::integer,
COALESCE(stanziamento.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni.imp_variazioni,0)::numeric as imp_stanziamento,     
display_error::varchar
from   strut_bilancio
left   join capitoli on  strut_bilancio.programma_id = capitoli.programma_id
                     and strut_bilancio.macroag_id = capitoli.macroaggr_id
left   join stanziamento on stanziamento.elem_id = capitoli.elem_id 
                         and stanziamento.anno_stanziamento_parziale = p_anno_competenza
                         and stanziamento.tipo_elem_det = tipoImpComp 
left join variazioni on variazioni.elem_id = capitoli.elem_id 
                     and variazioni.anno_variazioni = p_anno_competenza
                     and variazioni.tipo_elem_det = tipoImpComp                                              
) as zz; 
                    
raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR198_Allegato_12_Entrate_TitoloTipologiaCategoria_Reg_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  elem_id integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  entrata_ricorrente_anno numeric,
  entrata_ricorrente_anno1 numeric,
  entrata_ricorrente_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

annoCapImp  := p_anno; 
annoCapImp1 := ((p_anno::integer)+1)::varchar;   
annoCapImp2 := ((p_anno::integer)+2)::varchar; 

TipoImpComp  := 'STA';  -- competenza
elemTipoCode := 'CAP-EG'; -- tipo capitolo gestione

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
zz.*
FROM (
with strut_bilancio as(
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, null)
),
capitoli as(
select cl.classif_id categoria_id,
e.elem_id,
e.elem_code,
e.elem_code2,
e.elem_code3,
e.elem_desc
from  siac_r_bil_elem_class rc,
      siac_t_bil_elem e,
      siac_d_class_tipo ct,
      siac_t_class cl,
      siac_d_bil_elem_tipo tipo_elemento, 
      siac_d_bil_elem_stato stato_capitolo,
      siac_r_bil_elem_stato r_capitolo_stato,
      siac_d_bil_elem_categoria cat_del_capitolo,
      siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id			=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and e.bil_id                        =   bilancio_id
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and	stato_capitolo.elem_stato_code	=	'VA'
and ct.classif_tipo_code			=	'CATEGORIA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
),
stanziamento as (
select 	capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale     
from 	siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria 		cat_del_capitolo, 
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  			
and capitolo.bil_id						= bilancio_id											
and	capitolo.elem_id					= capitolo_importi.elem_id
and	capitolo.elem_tipo_id				= tipo_elemento.elem_tipo_id
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	= capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		= capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)       
and	capitolo.elem_id					= r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		= stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		= 'VA'
and	capitolo.elem_id					= r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			= cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code		= 'STD'
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id
),
entrate_non_ricorrenti as (
select capitolo_importi.elem_id,
       capitolo_imp_periodo.anno 				anno_entrate_non_ricorrenti,
       capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
       sum(capitolo_importi.elem_det_importo)   imp_entrate_non_ricorrenti    
from   siac_t_bil_elem_det 			    capitolo_importi,
       siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
       siac_t_periodo 					capitolo_imp_periodo,
       siac_t_bil_elem 				    capitolo,
       siac_d_bil_elem_tipo 			tipo_elemento,
       siac_t_bil 						bilancio,
       siac_t_periodo 					anno_eserc,
       siac_d_bil_elem_stato			stato_capitolo, 
       siac_r_bil_elem_stato 			r_capitolo_stato,
       siac_d_bil_elem_categoria 		cat_del_capitolo, 
       siac_r_bil_elem_categoria 		r_cat_capitolo
where  capitolo_importi.ente_proprietario_id = p_ente_prop_id  
and	anno_eserc.anno						= p_anno 												
and	bilancio.periodo_id					=anno_eserc.periodo_id 								
and	capitolo.bil_id						=bilancio.bil_id 			 
and	capitolo.elem_id					=capitolo_importi.elem_id 
and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2) 
and	capitolo.elem_id					=r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		=stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		='VA'
and	capitolo.elem_id					=r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			=cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code		='STD'
and capitolo_importi.elem_id not in
    (select r_class.elem_id   
    from  	siac_r_bil_elem_class	r_class,
            siac_t_class 			b,
            siac_d_class_tipo 		c
    where 	b.classif_id 		 = 	r_class.classif_id
    and 	b.classif_tipo_id 	 = 	c.classif_tipo_id
    and 	c.classif_tipo_code  = 'RICORRENTE_ENTRATA'
    and		b.classif_desc	     = 'Ricorrente'
    and	r_class.data_cancellazione				is null
    and	b.data_cancellazione					is null
    and c.data_cancellazione					is null) 
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	bilancio.data_cancellazione 			is null
and	anno_eserc.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by  capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id
),
variazioni as (
select *
from "fnc_variazioni_bozza" (
  p_ente_prop_id,
  p_anno,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo = 'STD'
)
select
p_anno::varchar,
--strut_bilancio.titolo_id::integer titolo_id,
strut_bilancio.titolo_code::varchar as code_titolo, 
strut_bilancio.titolo_desc::varchar as desc_titolo, 
--strut_bilancio.tipologia_id::integer tipologia_id,
strut_bilancio.tipologia_code::varchar as code_tipologia,
strut_bilancio.tipologia_desc::varchar as desc_tipologia,
--strut_bilancio.categoria_id::integer categoria_id,
strut_bilancio.categoria_code::varchar as code_categoria,
strut_bilancio.categoria_desc::varchar as desc_categoria,
capitoli.elem_id::integer as elem_id,
--capitoli.elem_code::varchar elem_code,
--capitoli.elem_code2::varchar elem_code2,
--capitoli.elem_code3::varchar elem_code3,
--capitoli.elem_desc::varchar elem_desc,
--COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale1,
--COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale2,
--COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale3,
--COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_variazioni1,
--COALESCE(variazioni2.imp_variazioni,0)::numeric as imp_variazioni2,
--COALESCE(variazioni3.imp_variazioni,0)::numeric as imp_variazioni3,
COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_stanziamento1,
COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric as imp_stanziamento2,
COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric as imp_stanziamento3,
COALESCE(entrate1.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_entrate_non_ricorrenti1,
COALESCE(entrate2.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric as imp_entrate_non_ricorrenti2,
COALESCE(entrate3.imp_entrate_non_ricorrenti,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric as imp_entrate_non_ricorrenti3,
display_error::varchar
from  strut_bilancio
full  join capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
left  join stanziamento stanziamento1 on stanziamento1.elem_id = capitoli.elem_id 
                                      and stanziamento1.anno_stanziamento_parziale = annoCapImp
                                      and stanziamento1.tipo_elem_det = tipoImpComp  
left  join stanziamento stanziamento2 on stanziamento2.elem_id = capitoli.elem_id 
                                      and stanziamento2.anno_stanziamento_parziale = annoCapImp1
                                      and stanziamento2.tipo_elem_det = tipoImpComp  
left  join stanziamento stanziamento3 on stanziamento3.elem_id = capitoli.elem_id 
                                      and stanziamento3.anno_stanziamento_parziale = annoCapImp2
                                      and stanziamento3.tipo_elem_det = tipoImpComp 
left join variazioni variazioni1 on variazioni1.elem_id = capitoli.elem_id 
                                 and variazioni1.anno_variazioni = annoCapImp
                                 and variazioni1.tipo_elem_det = tipoImpComp
left join variazioni variazioni2 on variazioni2.elem_id = capitoli.elem_id 
                                 and variazioni2.anno_variazioni = annoCapImp1
                                 and variazioni2.tipo_elem_det = tipoImpComp
left join variazioni variazioni3 on variazioni3.elem_id = capitoli.elem_id 
                                 and variazioni3.anno_variazioni = annoCapImp2
                                 and variazioni3.tipo_elem_det = tipoImpComp      
left join entrate_non_ricorrenti entrate1 on entrate1.elem_id = capitoli.elem_id 
                                 and entrate1.anno_entrate_non_ricorrenti = annoCapImp
                                 and entrate1.tipo_elem_det = tipoImpComp  
left join entrate_non_ricorrenti entrate2 on entrate2.elem_id = capitoli.elem_id 
                                 and entrate2.anno_entrate_non_ricorrenti = annoCapImp1
                                 and entrate2.tipo_elem_det = tipoImpComp 
left join entrate_non_ricorrenti entrate3 on entrate3.elem_id = capitoli.elem_id 
                                 and entrate3.anno_entrate_non_ricorrenti = annoCapImp2
                                 and entrate3.tipo_elem_det = tipoImpComp     
) as zz;

raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR199_Allegato_12_Spese_rimborso_prestiti_MPM_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  stanziamento_prev_anno numeric,
  display_error varchar
) AS
$body$
DECLARE

tipoImpComp varchar;
elemTipoCode varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

TipoImpComp='STA';      -- competenza
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione
cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
zz.*
FROM (
with strut_bilancio as (
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_titolomacroaggregato
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
and d.classif_fam_code = v_fam_titolomacroaggregato
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
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
from missione , programma,titusc, macroag
/* 07/09/2016: start filtro per mis-prog-macro*/
, siac_r_class progmacro
/*end filtro per mis-prog-macro*/
where programma.missione_id=missione.missione_id
and titusc.titusc_id=macroag.titusc_id
/* 07/09/2016: start filtro per mis-prog-macro*/
and programma.programma_id = progmacro.classif_a_id
and titusc.titusc_id = progmacro.classif_b_id
/* end filtro per mis-prog-macro*/ 
and titusc.titusc_code = '4'
and titusc.ente_proprietario_id=missione.ente_proprietario_id
and missione.missione_code <> '20'
),
capitoli as (
select 	programma.classif_id as programma_id,
		macroaggr.classif_id as macroaggr_id,
        -- anno_eserc.anno anno_bilancio,
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
where programma_tipo.classif_tipo_code = 'PROGRAMMA' 									
and   programma.classif_tipo_id		   = programma_tipo.classif_tipo_id 				
and   programma.classif_id			   = r_capitolo_programma.classif_id					
and   macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and   macroaggr.classif_tipo_id		   = macroaggr_tipo.classif_tipo_id 				
and   macroaggr.classif_id			   = r_capitolo_macroaggr.classif_id					
and   capitolo.ente_proprietario_id	   = p_ente_prop_id      												
and   capitolo.bil_id				   = bilancio_id										
and   capitolo.elem_tipo_id			   = tipo_elemento.elem_tipo_id 						
and   tipo_elemento.elem_tipo_code 	   = elemTipoCode						     	 
and   capitolo.elem_id				   = r_capitolo_programma.elem_id							
and   capitolo.elem_id				   = r_capitolo_macroaggr.elem_id						    
and   capitolo.elem_id				   = r_capitolo_stato.elem_id			
and	  r_capitolo_stato.elem_stato_id   = stato_capitolo.elem_stato_id		
and	  stato_capitolo.elem_stato_code   = 'VA'								
and   capitolo.elem_id				   = r_cat_capitolo.elem_id				
and	  r_cat_capitolo.elem_cat_id	   = cat_del_capitolo.elem_cat_id		
-- 05/08/2016: aggiunto FPVC
and   cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
-- cat_del_capitolo.elem_cat_code	=	'STD'		
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
),
stanziamento as (
select 	capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale   
from 	siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria	 	cat_del_capitolo,
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id   = p_ente_prop_id  							
and	    capitolo.bil_id							= bilancio_id			 
and	    capitolo.elem_id						= capitolo_importi.elem_id 
and	    capitolo.elem_tipo_id					= tipo_elemento.elem_tipo_id 						
and	    tipo_elemento.elem_tipo_code 			= elemTipoCode
and	    capitolo_importi.elem_det_tipo_id		= capitolo_imp_tipo.elem_det_tipo_id 		
and	    capitolo_imp_periodo.periodo_id			= capitolo_importi.periodo_id 			  
and	    capitolo_imp_periodo.anno               = p_anno_competenza       
and	    capitolo.elem_id				        = r_capitolo_stato.elem_id			
and	    r_capitolo_stato.elem_stato_id			= stato_capitolo.elem_stato_id		
and	    stato_capitolo.elem_stato_code			= 'VA'								
and	    capitolo.elem_id						= r_cat_capitolo.elem_id				
and	    r_cat_capitolo.elem_cat_id				= cat_del_capitolo.elem_cat_id
-- 05/08/2016: aggiunto FPVC
and	    cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc, 'FPVC')	
-- and	cat_del_capitolo.elem_cat_code	=	'STD'								
and	    capitolo_importi.data_cancellazione 		is null
and	    capitolo_imp_tipo.data_cancellazione 		is null
and	    capitolo_imp_periodo.data_cancellazione 	is null
and	    capitolo.data_cancellazione 				is null
and	    tipo_elemento.data_cancellazione 			is null
and	    stato_capitolo.data_cancellazione 			is null 
and	    r_capitolo_stato.data_cancellazione 		is null
and     cat_del_capitolo.data_cancellazione 		is null
and	    r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
variazioni as (
select *
from fnc_variazioni_bozza (
  p_ente_prop_id,
  p_anno_competenza,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo in (cap_std, cap_fpv, cap_fsc, 'FPVC')
)
select 
p_anno::varchar,
null::varchar  missione_tipo_code,
strut_bilancio.missione_tipo_desc::varchar,
strut_bilancio.missione_code::varchar,
strut_bilancio.missione_desc::varchar,
null::varchar  programma_tipo_code,
strut_bilancio.programma_tipo_desc::varchar,
SUBSTRING(strut_bilancio.programma_code from 3)::varchar programma_code,
strut_bilancio.programma_desc::varchar,
null::varchar  titusc_tipo_code,
strut_bilancio.titusc_tipo_desc::varchar,
strut_bilancio.titusc_code::varchar,
strut_bilancio.titusc_desc::varchar,
null::varchar  macroag_tipo_code,
strut_bilancio.macroag_tipo_desc::varchar,
strut_bilancio.macroag_code::varchar,
strut_bilancio.macroag_desc::varchar,
--capitoli.elem_id::integer,
COALESCE(stanziamento.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni.imp_variazioni,0)::numeric as imp_stanziamento,     
display_error::varchar
from   strut_bilancio
left   join capitoli on  strut_bilancio.programma_id = capitoli.programma_id
                     and strut_bilancio.macroag_id = capitoli.macroaggr_id
left   join stanziamento on stanziamento.elem_id = capitoli.elem_id 
                         and stanziamento.anno_stanziamento_parziale = p_anno_competenza
                         and stanziamento.tipo_elem_det = tipoImpComp 
left join variazioni on variazioni.elem_id = capitoli.elem_id 
                     and variazioni.anno_variazioni = p_anno_competenza
                     and variazioni.tipo_elem_det = tipoImpComp                                              
) as zz; 
                    
raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR200_Allegato_12_Spese_conto_terzi_partite_di_giro_MPM_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  stanziamento_prev_anno numeric,
  display_error varchar
) AS
$body$
DECLARE

tipoImpComp varchar;
elemTipoCode varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

TipoImpComp='STA';      -- competenza
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione
cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
zz.*
FROM (
with strut_bilancio as (
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_missioneprogramma
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
and d.classif_fam_code = v_fam_titolomacroaggregato
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
and d.classif_fam_code = v_fam_titolomacroaggregato
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
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
from missione , programma,titusc, macroag
/* 07/09/2016: start filtro per mis-prog-macro*/
, siac_r_class progmacro
/*end filtro per mis-prog-macro*/
where programma.missione_id=missione.missione_id
and titusc.titusc_id=macroag.titusc_id
/* 07/09/2016: start filtro per mis-prog-macro*/
and programma.programma_id = progmacro.classif_a_id
and titusc.titusc_id = progmacro.classif_b_id
/* end filtro per mis-prog-macro*/ 
and titusc.titusc_code = '7'
and titusc.ente_proprietario_id=missione.ente_proprietario_id
),
capitoli as (
select 	programma.classif_id as programma_id,
		macroaggr.classif_id as macroaggr_id,
        -- anno_eserc.anno anno_bilancio,
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
where programma_tipo.classif_tipo_code = 'PROGRAMMA' 									
and   programma.classif_tipo_id		   = programma_tipo.classif_tipo_id 				
and   programma.classif_id			   = r_capitolo_programma.classif_id					
and   macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and   macroaggr.classif_tipo_id		   = macroaggr_tipo.classif_tipo_id 				
and   macroaggr.classif_id			   = r_capitolo_macroaggr.classif_id					
and   capitolo.ente_proprietario_id	   = p_ente_prop_id      												
and   capitolo.bil_id				   = bilancio_id										
and   capitolo.elem_tipo_id			   = tipo_elemento.elem_tipo_id 						
and   tipo_elemento.elem_tipo_code 	   = elemTipoCode						     	 
and   capitolo.elem_id				   = r_capitolo_programma.elem_id							
and   capitolo.elem_id				   = r_capitolo_macroaggr.elem_id						    
and   capitolo.elem_id				   = r_capitolo_stato.elem_id			
and	  r_capitolo_stato.elem_stato_id   = stato_capitolo.elem_stato_id		
and	  stato_capitolo.elem_stato_code   = 'VA'								
and   capitolo.elem_id				   = r_cat_capitolo.elem_id				
and	  r_cat_capitolo.elem_cat_id	   = cat_del_capitolo.elem_cat_id		
-- 05/08/2016: aggiunto FPVC
and   cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
-- cat_del_capitolo.elem_cat_code	=	'STD'		
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
),
stanziamento as (
select 	capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale   
from 	siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria	 	cat_del_capitolo,
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id   = p_ente_prop_id  							
and	    capitolo.bil_id							= bilancio_id			 
and	    capitolo.elem_id						= capitolo_importi.elem_id 
and	    capitolo.elem_tipo_id					= tipo_elemento.elem_tipo_id 						
and	    tipo_elemento.elem_tipo_code 			= elemTipoCode
and	    capitolo_importi.elem_det_tipo_id		= capitolo_imp_tipo.elem_det_tipo_id 		
and	    capitolo_imp_periodo.periodo_id			= capitolo_importi.periodo_id 			  
and	    capitolo_imp_periodo.anno               = p_anno_competenza       
and	    capitolo.elem_id				        = r_capitolo_stato.elem_id			
and	    r_capitolo_stato.elem_stato_id			= stato_capitolo.elem_stato_id		
and	    stato_capitolo.elem_stato_code			= 'VA'								
and	    capitolo.elem_id						= r_cat_capitolo.elem_id				
and	    r_cat_capitolo.elem_cat_id				= cat_del_capitolo.elem_cat_id
-- 05/08/2016: aggiunto FPVC
and	    cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc, 'FPVC')	
-- and	cat_del_capitolo.elem_cat_code	=	'STD'								
and	    capitolo_importi.data_cancellazione 		is null
and	    capitolo_imp_tipo.data_cancellazione 		is null
and	    capitolo_imp_periodo.data_cancellazione 	is null
and	    capitolo.data_cancellazione 				is null
and	    tipo_elemento.data_cancellazione 			is null
and	    stato_capitolo.data_cancellazione 			is null 
and	    r_capitolo_stato.data_cancellazione 		is null
and     cat_del_capitolo.data_cancellazione 		is null
and	    r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
variazioni as (
select *
from fnc_variazioni_bozza (
  p_ente_prop_id,
  p_anno_competenza,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo in (cap_std, cap_fpv, cap_fsc, 'FPVC')
)
select 
p_anno::varchar,
null::varchar  missione_tipo_code,
strut_bilancio.missione_tipo_desc::varchar,
strut_bilancio.missione_code::varchar,
strut_bilancio.missione_desc::varchar,
null::varchar  programma_tipo_code,
strut_bilancio.programma_tipo_desc::varchar,
SUBSTRING(strut_bilancio.programma_code from 3)::varchar programma_code,
strut_bilancio.programma_desc::varchar,
null::varchar  titusc_tipo_code,
strut_bilancio.titusc_tipo_desc::varchar,
strut_bilancio.titusc_code::varchar,
strut_bilancio.titusc_desc::varchar,
null::varchar  macroag_tipo_code,
strut_bilancio.macroag_tipo_desc::varchar,
strut_bilancio.macroag_code::varchar,
strut_bilancio.macroag_desc::varchar,
--capitoli.elem_id::integer,
COALESCE(stanziamento.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni.imp_variazioni,0)::numeric as imp_stanziamento,     
display_error::varchar
from   strut_bilancio
left   join capitoli on  strut_bilancio.programma_id = capitoli.programma_id
                     and strut_bilancio.macroag_id = capitoli.macroaggr_id
left   join stanziamento on stanziamento.elem_id = capitoli.elem_id 
                         and stanziamento.anno_stanziamento_parziale = p_anno_competenza
                         and stanziamento.tipo_elem_det = tipoImpComp 
left join variazioni on variazioni.elem_id = capitoli.elem_id 
                     and variazioni.anno_variazioni = p_anno_competenza
                     and variazioni.tipo_elem_det = tipoImpComp                                              
) as zz; 
                    
raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR201_Allegato_12_Spese_titolo_macroaggregato_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar,
  p_pluriennale varchar = 'S'::character varying
)
RETURNS TABLE (
  bil_anno varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  macroag_id numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  spesa_ricorrente_anno numeric,
  spesa_ricorrente_anno1 numeric,
  spesa_ricorrente_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
bilancio_id integer;

intApp integer;
strApp varchar;
x_array varchar [];

contaParVarPeg integer;
contaParVarBil integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN

display_error :='';
contaParVarPeg:=0;
contaParVarBil:=0;

annoCapImp  := p_anno; 
annoCapImp1 := ((p_anno::integer)+1)::varchar;   
annoCapImp2 := ((p_anno::integer)+2)::varchar; 

TipoImpComp  := 'STA';  -- competenza
elemTipoCode := 'CAP-UG'; -- tipo capitolo gestione
cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/*  22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    provvedimento di variazione di PEG o di BILANCIO, siano passati anche
    gli altri 2. */
IF p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
END IF;
IF contaParVarPeg not in (0,3) THEN
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
END IF;

IF p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
END IF;
IF contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
END IF;

select a.bil_id 
into  bilancio_id 
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

RETURN query
SELECT
--zz.*
zz.bil_anno   					bil_anno,
zz.titusc_tipo_code             titusc_tipo_code,
zz.titusc_tipo_desc				titusc_tipo_desc,
zz.titusc_code					titusc_code,
zz.titusc_desc					titusc_desc,
zz.macroag_tipo_code            macroag_tipo_code, 
zz.macroag_tipo_desc			macroag_tipo_desc,
zz.macroag_code					macroag_code,
zz.macroag_desc					macroag_desc,
zz.macroag_id                   macroag_id,
COALESCE(sum(zz.imp_stanziamento1),0)		stanziamento_prev_anno,
COALESCE(sum(zz.imp_stanziamento2),0)	    stanziamento_prev_anno1,
COALESCE(sum(zz.imp_stanziamento3),0)	    stanziamento_prev_anno2,
COALESCE (sum(zz.imp_spese_non_ricorrenti1),0)	spesa_ricorrente_anno,
COALESCE (sum(zz.imp_spese_non_ricorrenti2),0)	spesa_ricorrente_anno1,
COALESCE (sum(zz.imp_spese_non_ricorrenti3),0)	spesa_ricorrente_anno2,
zz.display_error
FROM (
with strut_bilancio as (
select  a.titusc_tipo_desc, 
        a.titusc_code, 
        a.titusc_desc, 
        a.macroag_tipo_desc,
        a.macroag_code,
        a.macroag_desc,
        a.macroag_id
from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno, null) a
group by
a.titusc_tipo_desc, 
a.titusc_code, 
a.titusc_desc, 
a.macroag_tipo_desc,
a.macroag_code,
a.macroag_desc,
a.macroag_id
),
capitoli as (
select 	macroaggr.classif_id as macroaggr_id,
        -- anno_eserc.anno anno_bilancio,
        capitolo.elem_id
from    siac_d_class_tipo macroaggr_tipo,
        siac_t_class macroaggr,
        siac_t_bil_elem capitolo,
        siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_macroaggr, 
        siac_d_bil_elem_stato stato_capitolo, 
        siac_r_bil_elem_stato r_capitolo_stato,
        siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and macroaggr.classif_tipo_id          = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id               = r_capitolo_macroaggr.classif_id					
and capitolo.ente_proprietario_id      = p_ente_prop_id								
and capitolo.bil_id                    = bilancio_id										
and capitolo.elem_tipo_id              = tipo_elemento.elem_tipo_id 						
and tipo_elemento.elem_tipo_code       = elemTipoCode					     	 
and capitolo.elem_id                   = r_capitolo_macroaggr.elem_id						
and capitolo.elem_id				   =	r_capitolo_stato.elem_id			
and r_capitolo_stato.elem_stato_id	   =	stato_capitolo.elem_stato_id		
and stato_capitolo.elem_stato_code	   =	'VA'								
and capitolo.elem_id				   =	r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id		   =	cat_del_capitolo.elem_cat_id		
-- 05/08/2016: aggiunto FPVC
and cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')					
-- cat_del_capitolo.elem_cat_code	=	'STD'														
and macroaggr_tipo.data_cancellazione 			is null						
and macroaggr.data_cancellazione 				is null						
and capitolo.data_cancellazione 				is null						
and tipo_elemento.data_cancellazione 			is null						
and r_capitolo_macroaggr.data_cancellazione 	is null						 
and stato_capitolo.data_cancellazione 			is null						 
and r_capitolo_stato.data_cancellazione 		is null						
and cat_del_capitolo.data_cancellazione 		is null						
and r_cat_capitolo.data_cancellazione 			is null
),
stanziamento as (
select  capitolo_importi.elem_id,
        capitolo_imp_periodo.anno 				anno_stanziamento_parziale,
        capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
        sum(capitolo_importi.elem_det_importo)  imp_stanziamento_parziale     
from    siac_t_bil_elem_det 			capitolo_importi,
        siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
        siac_t_periodo 					capitolo_imp_periodo,
        siac_t_bil_elem 				capitolo,
        siac_d_bil_elem_tipo 			tipo_elemento,
        siac_d_bil_elem_stato 			stato_capitolo, 
        siac_r_bil_elem_stato 			r_capitolo_stato,
        siac_d_bil_elem_categoria 		cat_del_capitolo, 
        siac_r_bil_elem_categoria 		r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  						
and	capitolo.bil_id						= bilancio_id			 
and	capitolo.elem_id					= capitolo_importi.elem_id 
and	capitolo.elem_tipo_id				= tipo_elemento.elem_tipo_id 						
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	= capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		= capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)       
and	capitolo.elem_id					=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		=	'VA'
and	capitolo.elem_id					=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
-- 05/08/2016: aggiunto FPVC
and cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
-- and	cat_del_capitolo.elem_cat_code		=	'STD'
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
spese_non_ricorrenti as (
select 		capitolo_importi.elem_id,
            capitolo_imp_periodo.anno 				anno_spese_non_ricorrenti,
            capitolo_imp_tipo.elem_det_tipo_code 	tipo_elem_det,
            sum(capitolo_importi.elem_det_importo)  imp_spese_non_ricorrenti         
from siac_t_bil_elem_det 		capitolo_importi,
     siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
     siac_t_periodo 			capitolo_imp_periodo,
     siac_t_bil_elem 			capitolo,
     siac_d_bil_elem_tipo 		tipo_elemento,
     siac_d_bil_elem_stato		stato_capitolo, 
     siac_r_bil_elem_stato 		r_capitolo_stato,
     siac_d_bil_elem_categoria 	cat_del_capitolo, 
     siac_r_bil_elem_categoria 	r_cat_capitolo
where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  				
and	capitolo.bil_id						= bilancio_id		 
and	capitolo.elem_id					= capitolo_importi.elem_id 
and	capitolo.elem_tipo_id				= tipo_elemento.elem_tipo_id 						
and	tipo_elemento.elem_tipo_code 		= elemTipoCode
and	capitolo_importi.elem_det_tipo_id	= capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id		= capitolo_importi.periodo_id 			  
and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
and	capitolo.elem_id					= r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		= stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code		= 'VA'
and	capitolo.elem_id					= r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			= cat_del_capitolo.elem_cat_id		
and	cat_del_capitolo.elem_cat_code		in (cap_std, cap_fpv, cap_fsc,'FPVC')
and capitolo_imp_tipo.elem_det_tipo_code	= TipoImpComp
and capitolo_importi.elem_id    not in
(select r_class.elem_id   
 from  	siac_r_bil_elem_class	r_class,
        siac_t_class 			b,
        siac_d_class_tipo 		c
 where 	b.classif_id 		= 	r_class.classif_id
 and 	b.classif_tipo_id 	= 	c.classif_tipo_id
 and 	c.classif_tipo_code  = 'RICORRENTE_SPESA'
 and	b.classif_desc	=	'Ricorrente'
 and	r_class.data_cancellazione				is null
 and	b.data_cancellazione					is null
 and c.data_cancellazione					is null)  
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by  capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno
),
variazioni as (
select *
from "fnc_variazioni_bozza" (
  p_ente_prop_id,
  p_anno,
  p_ele_variazioni,
  p_num_provv_var_peg,
  p_anno_provv_var_peg,
  p_tipo_provv_var_peg,
  p_num_provv_var_bil,
  p_anno_provv_var_bil,
  p_tipo_provv_var_bil,
  p_code_sac_direz_peg,
  p_code_sac_sett_peg,
  p_code_sac_direz_bil,
  p_code_sac_sett_bil,
  contaParVarPeg,
  contaParVarBil,
  elemTipoCode
)
where tipo_capitolo in (cap_std, cap_fpv, cap_fsc, 'FPVC')
)
select
p_anno::varchar as bil_anno,
--strut_bilancio.titusc_id::integer titusc_id,
null::varchar as titusc_tipo_code, 
strut_bilancio.titusc_tipo_desc::varchar as titusc_tipo_desc, 
strut_bilancio.titusc_code::varchar as titusc_code, 
strut_bilancio.titusc_desc::varchar as titusc_desc, 
--strut_bilancio.macroag_id::integer macroag_id,
null::varchar as macroag_tipo_code,
strut_bilancio.macroag_tipo_desc::varchar as macroag_tipo_desc,
strut_bilancio.macroag_code::varchar as macroag_code,
strut_bilancio.macroag_desc::varchar as macroag_desc,
strut_bilancio.macroag_id::numeric as macroag_id,
--capitoli.elem_id::integer as elem_id,
--COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale1,
--COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale2,
--COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric as imp_stanziamento_parziale3,
--COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_variazioni1,
--COALESCE(variazioni2.imp_variazioni,0)::numeric as imp_variazioni2,
--COALESCE(variazioni3.imp_variazioni,0)::numeric as imp_variazioni3
COALESCE(stanziamento1.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_stanziamento1,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE	 
         COALESCE(stanziamento2.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric
END imp_stanziamento2,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(stanziamento3.imp_stanziamento_parziale,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric
END imp_stanziamento3,
COALESCE(spese1.imp_spese_non_ricorrenti,0)::numeric + COALESCE(variazioni1.imp_variazioni,0)::numeric as imp_spese_non_ricorrenti1,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(spese2.imp_spese_non_ricorrenti,0)::numeric + COALESCE(variazioni2.imp_variazioni,0)::numeric
END imp_spese_non_ricorrenti2,
CASE
	WHEN p_pluriennale = 'N' THEN
         0
    ELSE
         COALESCE(spese3.imp_spese_non_ricorrenti,0)::numeric + COALESCE(variazioni3.imp_variazioni,0)::numeric
END imp_spese_non_ricorrenti3,
display_error::varchar
from  strut_bilancio
full  join capitoli on strut_bilancio.macroag_id = capitoli.macroaggr_id
left  join stanziamento stanziamento1 on stanziamento1.elem_id = capitoli.elem_id 
                                      and stanziamento1.anno_stanziamento_parziale = annoCapImp
                                      and stanziamento1.tipo_elem_det = tipoImpComp  
left  join stanziamento stanziamento2 on stanziamento2.elem_id = capitoli.elem_id 
                                      and stanziamento2.anno_stanziamento_parziale = annoCapImp1
                                      and stanziamento2.tipo_elem_det = tipoImpComp  
left  join stanziamento stanziamento3 on stanziamento3.elem_id = capitoli.elem_id 
                                      and stanziamento3.anno_stanziamento_parziale = annoCapImp2
                                      and stanziamento3.tipo_elem_det = tipoImpComp 
left join variazioni variazioni1 on variazioni1.elem_id = capitoli.elem_id 
                                 and variazioni1.anno_variazioni = annoCapImp
                                 and variazioni1.tipo_elem_det = tipoImpComp
left join variazioni variazioni2 on variazioni2.elem_id = capitoli.elem_id 
                                 and variazioni2.anno_variazioni = annoCapImp1
                                 and variazioni2.tipo_elem_det = tipoImpComp
left join variazioni variazioni3 on variazioni3.elem_id = capitoli.elem_id 
                                 and variazioni3.anno_variazioni = annoCapImp2
                                 and variazioni3.tipo_elem_det = tipoImpComp      
left join spese_non_ricorrenti spese1 on spese1.elem_id = capitoli.elem_id 
                                 and spese1.anno_spese_non_ricorrenti = annoCapImp
                                 and spese1.tipo_elem_det = tipoImpComp  
left join spese_non_ricorrenti spese2 on spese2.elem_id = capitoli.elem_id 
                                 and spese2.anno_spese_non_ricorrenti = annoCapImp1
                                 and spese2.tipo_elem_det = tipoImpComp 
left join spese_non_ricorrenti spese3 on spese3.elem_id = capitoli.elem_id 
                                 and spese3.anno_spese_non_ricorrenti = annoCapImp2
                                 and spese3.tipo_elem_det = tipoImpComp  
) as zz
group by 
zz.bil_anno,
zz.titusc_tipo_desc,				
zz.titusc_code,				
zz.titusc_desc,					
zz.macroag_tipo_desc,
zz.macroag_id,			
zz.macroag_code,				
zz.macroag_desc,		
zz.titusc_tipo_code,
zz.macroag_tipo_code,
zz.display_error;
  
raise notice 'fine OK';

EXCEPTION    
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce record solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
        RTN_MESSAGGIO:='';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5427 FINE
--SIAC-6100 Daniela
CREATE OR REPLACE VIEW siac.siac_v_dwh_pcc (
    ente_proprietario_id,
    importo_quietanza,
    numero_ordinativo,
    data_emissione_ordinativo,
    data_scadenza,
    data_registrazione,
    cod_esito,
    desc_esito,
    data_esito,
    cod_tipo_operazione,
    desc_tipo_operazione,
    cod_ufficio,
    desc_ufficio,
    cod_debito,
    desc_debito,
    cod_causale_pcc,
    desc_causale_pcc,
    validita_inizio,
    validita_fine,
    anno_doc,
    num_doc,
    data_emissione_doc,
    cod_tipo_doc,
    cod_sogg_doc,
    num_subdoc,
    doc_id)
AS
SELECT t_registro_pcc.ente_proprietario_id,
    t_registro_pcc.rpcc_quietanza_importo AS importo_quietanza,
    t_registro_pcc.ordinativo_numero AS numero_ordinativo,
    t_registro_pcc.ordinativo_data_emissione AS data_emissione_ordinativo,
    t_registro_pcc.data_scadenza,
    t_registro_pcc.rpcc_registrazione_data AS data_registrazione,
    t_registro_pcc.rpcc_esito_code AS cod_esito,
    t_registro_pcc.rpcc_esito_desc AS desc_esito,
    t_registro_pcc.rpcc_esito_data AS data_esito,
    d_pcc_oper_tipo.pccop_tipo_code AS cod_tipo_operazione,
    d_pcc_oper_tipo.pccop_tipo_desc AS desc_tipo_operazione,
    d_pcc_codice.pcccod_code AS cod_ufficio,
    d_pcc_codice.pcccod_desc AS desc_ufficio,
    d_pcc_debito_stato.pccdeb_stato_code AS cod_debito,
    d_pcc_debito_stato.pccdeb_stato_desc AS desc_debito,
    d_pcc_causale.pcccau_code AS cod_causale_pcc,
    d_pcc_causale.pcccau_desc AS desc_causale_pcc,
    t_registro_pcc.validita_inizio, t_registro_pcc.validita_fine,
    t_doc.doc_anno AS anno_doc, t_doc.doc_numero AS num_doc,
    t_doc.doc_data_emissione AS data_emissione_doc,
    d_doc_tipo.doc_tipo_code AS cod_tipo_doc,
    t_soggetto.soggetto_code AS cod_sogg_doc,
    t_subdoc.subdoc_numero AS num_subdoc,
    t_doc.doc_id
FROM siac_t_registro_pcc t_registro_pcc
INNER JOIN siac_d_pcc_operazione_tipo d_pcc_oper_tipo ON d_pcc_oper_tipo.pccop_tipo_id = t_registro_pcc.pccop_tipo_id
INNER JOIN siac_t_doc t_doc ON t_doc.doc_id = t_registro_pcc.doc_id
INNER JOIN siac_d_pcc_codice d_pcc_codice ON d_pcc_codice.pcccod_id = t_doc.pcccod_id
INNER JOIN siac_t_subdoc t_subdoc ON t_subdoc.subdoc_id = t_registro_pcc.subdoc_id
INNER JOIN siac_d_doc_tipo d_doc_tipo ON d_doc_tipo.doc_tipo_id = t_doc.doc_tipo_id
LEFT JOIN siac_d_pcc_debito_stato d_pcc_debito_stato ON d_pcc_debito_stato.pccdeb_stato_id = t_registro_pcc.pccdeb_stato_id AND d_pcc_debito_stato.data_cancellazione IS NULL
LEFT JOIN siac_d_pcc_causale d_pcc_causale ON d_pcc_causale.pcccau_id = t_registro_pcc.pcccau_id AND d_pcc_causale.data_cancellazione IS NULL
LEFT JOIN siac_r_doc_sog r_doc_sog ON r_doc_sog.doc_id = t_doc.doc_id AND r_doc_sog.data_cancellazione IS NULL
LEFT JOIN siac_t_soggetto t_soggetto ON t_soggetto.soggetto_id = r_doc_sog.soggetto_id AND t_soggetto.data_cancellazione IS NULL
WHERE
--SIAC-6100
--d_pcc_oper_tipo.pccop_tipo_code::text = 'CP'::text AND
t_registro_pcc.data_cancellazione IS NULL
AND d_pcc_codice.data_cancellazione IS NULL
AND d_pcc_oper_tipo.data_cancellazione IS NULL
AND t_doc.data_cancellazione IS NULL
AND t_subdoc.data_cancellazione IS NULL
AND d_doc_tipo.data_cancellazione IS NULL;
--SIAC-6100 Daniela FINE