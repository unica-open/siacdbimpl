/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
 --  REMEDY INC000001885831 Maurizio INIZIO
 
 CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitadodicesimi_dpm (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

dispDpm  numeric:=0;
diDpmRec record;

TIPO_DISP_DPM constant varchar:='DPM';
strMessaggio varchar(1500):=null;
---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;

BEGIN

    strMessaggio:='Calcolo DPM elem_id='||id_in||'.';

    select * into diDpmRec
    from  fnc_siac_disponibilitadodicesimi (id_in,TIPO_DISP_DPM);
    if diDpmRec.codicerisultato=-1 then
    	raise exception '%',diDpmRec.messaggiorisultato;
    end if;

    dispDpm:=diDpmRec.importodpm;


---    ANNASILVIA CMTO FORZATURA 03-07-2017 INIZIO
/*
    select a.ente_proprietario_id
    into ente_prop_in from siac_t_bil_elem a
    where a.elem_id = id_in;

    if ente_prop_in = 3 then
        	dispDpm := 99999999999999;
    end if;
*/
---    ANNASILVIA CMTO FORZATURA 03-07-2017 FINE


    return dispDpm;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        dispDpm:=0;
        return dispDpm;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        dispDpm:=0;
        return dispDpm;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1500);
        dispDpm:=0;
        return dispDpm;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitadodicesimi_dim (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

dispDim  numeric:=0;
diDimRec record;

TIPO_DISP_DIM constant varchar:='DIM';
strMessaggio varchar(1500):=null;
---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;
BEGIN

    strMessaggio:='Calcolo DIM elem_id='||id_in||'.';

    select * into diDimRec
    from  fnc_siac_disponibilitadodicesimi (id_in,TIPO_DISP_DIM);
    if diDimRec.codicerisultato=-1 then
    	raise exception '%',diDimRec.messaggiorisultato;
    end if;


    dispDim:=diDimRec.importodim;


---    ANNASILVIA CMTO FORZATURA 03-07-2017 INIZIO
/*
    select a.ente_proprietario_id
    into ente_prop_in from siac_t_bil_elem a
    where a.elem_id = id_in;

    if ente_prop_in = 3 then
        	dispDim := 99999999999999;
    end if;
*/
---    ANNASILVIA CMTO FORZATURA 03-07-2017 FINE


    return dispDim;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        dispDim:=0;
        return dispDim;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        dispDim:=0;
        return dispDim;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1500);
        dispDim:=0;
        return dispDim;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

 
  --  REMEDY INC000001885831 Maurizio FINE
  
  -- SIAC-5064 - Maurizio - INIZIO
CREATE OR REPLACE FUNCTION siac."BILR101_registro_operaz_pcc" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_utente varchar
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
  importo_quietanza numeric
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

annoCompetenza_int =p_anno ::INTEGER;

select fnc_siac_random_user()
into	user_table;



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
    --20/07/201: devo estrarre tutti i capitoli, perchè possono esserci capitoli
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
      /* 09/03/2016: nel campo account passato in input al report non c'è più
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
    t_sog_pcc.partita_iva piva_ordinativo, t_movgest.movgest_id
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
	AND t_ente.ente_proprietario_id=p_ente_prop_id   
    	/* devo estrarre solo il tipo CP */ 
    AND d_pcc_oper_tipo.pccop_tipo_code='CP'
    --AND d_pcc_oper_tipo.pccop_tipo_code='CO'
    AND t_doc.data_cancellazione IS NULL
    AND t_subdoc.data_cancellazione IS NULL
    AND t_registro_pcc.data_cancellazione IS NULL
    AND t_ente.data_cancellazione IS NULL
    AND d_pcc_codice.data_cancellazione IS NULL
    AND d_pcc_oper_tipo.data_cancellazione IS NULL
    AND t_registro_pcc.rpcc_registrazione_data IS NULL
    --AND to_char (t_registro_pcc.rpcc_registrazione_data,'dd/mm/yyyy')='05/08/2016'
ORDER BY t_doc.doc_data_emissione, t_doc.doc_numero, t_subdoc.subdoc_numero
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
	perchè estraeva tanti record invece che uno solo */
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
    	/* se il titolo è 1, la natura spesa è CO,
        	se è 2 la natura spesa è CA */
    if titolo_code= '1' THEN
    	natura_spesa='CO';
    elsif titolo_code= '2' THEN
    	natura_spesa='CA';
    else
    -- 07/07/2017: messo NA se il titolo è diverso da 1 e 2.
    	--natura_spesa='';
        natura_spesa='NA';
    end if;
    
--raise notice 'natura_spesa = %',natura_spesa;      
 
/* è eseguito l'aggiornamento della data registrazione in modo che i record
	siano estratti una volta sola */
/* 03/03/2016: modificato anche il login_operazione concatenando il nome dell'utente
	al valore contenuto 
    Sostituita clock_timestamp() con now() per avere la stessa data/ora per tuttii i 
    record. */
update siac_t_registro_pcc  set rpcc_registrazione_data = now(),
	login_operazione = login_operazione||' - '||p_utente
where rpcc_id=elencoRegistriRec.rpcc_id;
    
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
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5064 - Maurizio - FINE
-- SIAC-5069 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR092_stampa_mastrino" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
)
RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;



BEGIN

p_data_reg_a:=date_trunc('day', to_timestamp(to_char(p_data_reg_a,'dd/mm/yyyy'),'dd/mm/yyyy')) + interval '1 day';


select ente_denominazione,b.bil_id into nome_ente_in,bil_id_in
from siac_t_ente_proprietario a,siac_t_bil b,siac_t_periodo c where 
a.ente_proprietario_id=p_ente_prop_id and
a.ente_proprietario_id=b.ente_proprietario_id and b.periodo_id=c.periodo_id
and c.anno=p_anno
;
/*
raise notice 'dati input  p_ente_prop_id % - 
  p_anno % - 
  p_data_reg_da % - 
  p_data_reg_a % - 
  p_pdce_v_livello % - 
  nome_ente_in % - 
  bil_id_in %', p_ente_prop_id::varchar , p_anno::varchar ,  p_data_reg_da::varchar ,
  p_data_reg_a::varchar ,  p_pdce_v_livello::varchar ,  nome_ente_in::varchar ,
  bil_id_in::varchar ;
*/
    select fnc_siac_random_user()
	into	user_table;

raise notice '1 - % ',clock_timestamp()::varchar;
	select --a.pdce_conto_code, 
    a.pdce_conto_id --, a.livello
    into --dati_pdce
    pdce_conto_id_in
    from siac_t_pdce_conto a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.pdce_conto_code=p_pdce_v_livello;
    IF NOT FOUND THEN
    	display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') è inesistente';
        return next;
    	return;
    END IF;
--raise notice 'PDCE livello = %, conto = %, ID = %',  dati_pdce.livello, dati_pdce.pdce_conto_code, dati_pdce.pdce_conto_id;      
    
--     carico l'intera struttura PDCE 
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';

raise notice '2 - % ',clock_timestamp()::varchar;
INSERT INTO 
  siac.siac_rep_struttura_pdce
(
  pdce_liv0_id,
  pdce_liv0_id_padre,
  pdce_liv0_code,
  pdce_liv0_desc,
  pdce_liv1_id,
  pdce_liv1_id_padre,
  pdce_liv1_code,
  pdce_liv1_desc,
  pdce_liv2_id,
  pdce_liv2_id_padre,
  pdce_liv2_code,
  pdce_liv2_desc,
  pdce_liv3_id,
  pdce_liv3_id_padre,
  pdce_liv3_code,
  pdce_liv3_desc,
  pdce_liv4_id,
  pdce_liv4_id_padre,
  pdce_liv4_code,
  pdce_liv4_desc,
  pdce_liv5_id,
  pdce_liv5_id_padre,
  pdce_liv5_code,
  pdce_liv5_desc,
  pdce_liv6_id,
  pdce_liv6_id_padre,
  pdce_liv6_code,
  pdce_liv6_desc,
  pdce_liv7_id,
  pdce_liv7_id_padre,
  pdce_liv7_code,
  pdce_liv7_desc,
  utente
)
select zzz.*, user_table from(
with t_pdce_conto0 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree where pdce_conto_id=pdce_conto_id_in
),
t_pdce_conto1 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
),
t_pdce_conto2 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto3 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto4 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto5 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto6 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto7 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
select 
t_pdce_conto7.pdce_conto_id pdce_liv0_id,
t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre, 
t_pdce_conto7.pdce_conto_code pdce_liv0_code,
t_pdce_conto7.pdce_conto_desc pdce_liv0_desc,
t_pdce_conto6.pdce_conto_id pdce_liv1_id, 
t_pdce_conto6.pdce_conto_id_padre pdce_liv1_id_padre, 
t_pdce_conto6.pdce_conto_code pdce_liv1_code,
t_pdce_conto6.pdce_conto_desc pdce_liv1_desc,
t_pdce_conto5.pdce_conto_id pdce_liv2_id, 
t_pdce_conto5.pdce_conto_id_padre pdce_liv2_id_padre, 
t_pdce_conto5.pdce_conto_code pdce_liv2_code,
t_pdce_conto5.pdce_conto_desc pdce_liv2_desc,
t_pdce_conto4.pdce_conto_id pdce_liv3_id, 
t_pdce_conto4.pdce_conto_id_padre pdce_liv3_id_padre, 
t_pdce_conto4.pdce_conto_code pdce_liv3_code,
t_pdce_conto4.pdce_conto_desc pdce_liv3_desc,
t_pdce_conto3.pdce_conto_id pdce_liv4_id, 
t_pdce_conto3.pdce_conto_id_padre pdce_liv4_id_padre, 
t_pdce_conto3.pdce_conto_code pdce_liv4_code,
t_pdce_conto3.pdce_conto_desc pdce_liv4_desc,
t_pdce_conto2.pdce_conto_id pdce_liv5_id, 
t_pdce_conto2.pdce_conto_id_padre pdce_liv5_id_padre, 
t_pdce_conto2.pdce_conto_code pdce_liv5_code,
t_pdce_conto2.pdce_conto_desc pdce_liv5_desc,
t_pdce_conto1.pdce_conto_id pdce_liv6_id, 
t_pdce_conto1.pdce_conto_id_padre pdce_liv6_id_padre, 
t_pdce_conto1.pdce_conto_code pdce_liv6_code,
t_pdce_conto1.pdce_conto_desc pdce_liv6_desc,
t_pdce_conto0.pdce_conto_id pdce_liv7_id, 
t_pdce_conto0.pdce_conto_id_padre pdce_liv7_id_padre, 
t_pdce_conto0.pdce_conto_code pdce_liv7_code,
t_pdce_conto0.pdce_conto_desc pdce_liv7_desc
 from t_pdce_conto0 left join t_pdce_conto1
on t_pdce_conto0.livello-1=t_pdce_conto1.livello
left join t_pdce_conto2
on t_pdce_conto1.livello-1=t_pdce_conto2.livello
left join t_pdce_conto3
on t_pdce_conto2.livello-1=t_pdce_conto3.livello
left join t_pdce_conto4
on t_pdce_conto3.livello-1=t_pdce_conto4.livello
left join t_pdce_conto5
on t_pdce_conto4.livello-1=t_pdce_conto5.livello
left join t_pdce_conto6
on t_pdce_conto5.livello-1=t_pdce_conto6.livello
left join t_pdce_conto7
on t_pdce_conto6.livello-1=t_pdce_conto7.livello
) as zzz;

raise notice '3 - % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

return query  
select outp.* from (
with ord as (--ORD
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'ORD'::varchar tipo_pnota,
c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
s.soggetto_desc::varchar       descr_soggetto,
'ORD'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a  and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
     --   limit 1
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all       
select impacc.* from (          
--A,I 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.movgest_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest q                
WHERE d.collegamento_tipo_code in ('I','A') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_id=b.campo_pk_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL 
),
sogcla as (
select distinct c.movgest_id,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest c,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select c.movgest_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest c,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_id=sogcla.movgest_id 
left join sog on 
movgest.movgest_id=sog.movgest_id 
) as impacc
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all         
select impsubacc.* from (          
--SA,SI 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest_ts q,siac_t_movgest r               
WHERE d.collegamento_tipo_code in ('SI','SA') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_ts_id =b.campo_pk_id and
r.movgest_id=q.movgest_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL 
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubacc
--'MMGE','MMGS'
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all        
select impsubaccmod.* from (          
with movgest as (
/*SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest r,
 siac_t_movgest_ts q, siac_t_modifica s,siac_r_modifica_stato t,
 siac_t_movgest_ts_det_mod u
WHERE d.collegamento_tipo_code in ('MMGE','MMGS') and
  a.ente_proprietario_id=p_ente_prop_id
  and  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and r.movgest_id=q.movgest_id 
and s.mod_id=b.campo_pk_id
and t.mod_id=s.mod_id
and q.movgest_id=r.movgest_id
and u.mod_stato_r_id=t.mod_stato_r_id
and u.movgest_ts_id=q.movgest_ts_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL and 
s.data_cancellazione IS NULL and 
t.data_cancellazione IS NULL and 
u.data_cancellazione IS NULL  
union
select 
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
  from siac_t_prima_nota a 
,siac_r_prima_nota_stato b, siac_d_prima_nota_stato c,siac_t_mov_ep d,
siac_t_mov_ep_det e, siac_t_reg_movfin f,siac_r_evento_reg_movfin g,
siac_d_evento h,siac_d_collegamento_tipo i, siac_d_evento_tipo l,
siac_t_modifica m, siac_r_modifica_stato n, siac_d_modifica_stato o,
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where a.ente_proprietario_id=p_ente_prop_id
and b.pnota_id=a.pnota_id
and a.bil_id=bil_id_in
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between     p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and m.mod_id=g.campo_pk_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and c.pnota_stato_code='D'
and p.mod_stato_r_id=n.mod_stato_r_id
and q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and  a.data_cancellazione is null 
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null 
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null*/


with modge as (
select 
n.mod_stato_r_id,
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  from siac_t_prima_nota a 
,siac_r_prima_nota_stato b, siac_d_prima_nota_stato c,siac_t_mov_ep d,
siac_t_mov_ep_det e, siac_t_reg_movfin f,siac_r_evento_reg_movfin g,
siac_d_evento h,siac_d_collegamento_tipo i, siac_d_evento_tipo l,
siac_t_modifica m, siac_r_modifica_stato n, siac_d_modifica_stato o
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bil_id_in
and b.pnota_id=a.pnota_id
and i.collegamento_tipo_code in ('MMGS','MMGE')
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between     p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and m.mod_id=g.campo_pk_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and c.pnota_stato_code='D'
and  a.data_cancellazione is null 
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null 
) ,
modsog as (
select p.mod_stato_r_id,q.movgest_ts_id,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
 from 
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
,
modimp as (
select p.mod_stato_r_id,q.movgest_ts_id 
,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
from 
siac_t_movgest_ts_det_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
select 
modge.pnota_dataregistrazionegiornale,
modge.num_prima_nota,
modge.tipo_pnota,
modge.prov_pnota,
modge.tipo_documento ,--uguale a tipo_pnota,
modge.data_registrazione_movimento,
modge.numero_documento,
case when modsog.movgest_ts_id is null then modimp.num_det_rif else modsog.num_det_rif end num_det_rif,
modge.ente_proprietario_id,
modge.pdce_conto_id,     
modge.tipo_movimento,
modge.data_det_rif,
modge.data_registrazione,
modge.importo_dare,                    
modge.importo_avere           
, case when modsog.movgest_ts_id is null then modimp.movgest_ts_id else modsog.movgest_ts_id end movgest_ts_id
from modge left join
modsog on modge.mod_stato_r_id=modsog.mod_stato_r_id
left join
modimp on modge.mod_stato_r_id=modimp.mod_stato_r_id
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubaccmod
--LIQ
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all 
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'LIQ'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'LIQ'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.liq_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.liq_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_liquidazione q,
       siac_r_liquidazione_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('L') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.liq_id=b.campo_pk_id and
        r.liq_id=q.liq_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--DOC
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'FAT'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
t.soggetto_code::varchar cod_soggetto,
 t.soggetto_desc::varchar       descr_soggetto,
'FAT'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.doc_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
r.doc_data_emissione::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_subdoc q,
       siac_t_doc  r,
       siac_r_doc_sog s,
       siac_t_soggetto t                                       
WHERE d.collegamento_tipo_code in ('SS','SE') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.subdoc_id=b.campo_pk_id and
        r.doc_id=q.doc_id and 
        s.doc_id=r.doc_id and 
        s.soggetto_id=t.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL/*
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
'' tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'' tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
'' numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id and
  a.regmovfin_id = b.regmovfin_id AND
        c.	evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in and
        l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL*/
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--lib
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
case when dd.evento_code='AAP' then 'AAP'::varchar when dd.evento_code='APP' then 'APP'::varchar
else 'LIB'::varchar end tipo_pnota,
 dd.evento_code::varchar prov_pnota,
m.pnota_desc::varchar cod_soggetto,
 ''::varchar       descr_soggetto,
'LIB'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
''::varchar num_det_rif,
m.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
siac_t_causale_ep	aa,
siac_d_causale_ep_tipo bb,
siac_r_evento_causale cc,
siac_d_evento dd,
siac_d_evento_tipo g
where 
l.ente_proprietario_id=p_ente_prop_id
and l.regep_id=m.pnota_id
and n.pnota_id=m.pnota_id
and o.pnota_stato_id=n.pnota_stato_id
and p.movep_id=l.movep_id
and aa.causale_ep_id=l.causale_ep_id
and bb.causale_ep_tipo_id=aa.causale_ep_tipo_id
and bb.causale_ep_tipo_code='LIB'
and cc.causale_ep_id=aa.causale_ep_id
and dd.evento_id=cc.evento_id 
and g.evento_tipo_id=dd.evento_tipo_id and
 m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
aa.data_cancellazione IS NULL AND
bb.data_cancellazione IS NULL AND
cc.data_cancellazione IS NULL AND
dd.data_cancellazione IS NULL AND  
g.data_cancellazione IS NULL         
        )
        ,cc as 
        ( WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_code, my_tree.livello
from my_tree 
),
bb as (select * from siac_rep_struttura_pdce bb where bb.utente=user_table)
        /* bb as (select pdce_conto.livello, pdce_conto.pdce_conto_id,pdce_conto.pdce_conto_code codice_conto,
        pdce_conto.pdce_conto_desc descr_pdce_livello,strutt_pdce.*
    	from siac_t_pdce_conto	pdce_conto,
            siac_rep_struttura_pdce strutt_pdce
        where ((pdce_conto.livello=0 
            		AND strutt_pdce.pdce_liv0_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=1 
            		AND strutt_pdce.pdce_liv1_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=2 
            		AND strutt_pdce.pdce_liv2_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=3 
            		AND strutt_pdce.pdce_liv3_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=4 
            		AND strutt_pdce.pdce_liv4_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=5 
            		AND strutt_pdce.pdce_liv5_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=6 
            		AND strutt_pdce.pdce_liv6_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=7 
            		AND strutt_pdce.pdce_liv7_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=8 
            		AND strutt_pdce.pdce_liv8_id=pdce_conto.pdce_conto_id))
         and pdce_conto.ente_proprietario_id=p_ente_prop_id 
         and pdce_conto.pdce_conto_code=p_pdce_v_livello
        and strutt_pdce.utente=user_table
         and pdce_conto.data_cancellazione is NULL)*/
         select   
nome_ente_in,
bb.pdce_liv0_id::integer  id_pdce0 ,
bb.pdce_liv0_code::varchar codice_pdce0 ,
bb.pdce_liv0_desc  descr_pdce0 ,
bb.pdce_liv1_id id_pdce1,
bb.pdce_liv1_code::varchar  codice_pdce1 ,
bb.pdce_liv1_desc::varchar  descr_pdce1 ,
bb.pdce_liv2_id  id_pdce2 ,
bb.pdce_liv2_code::varchar codice_pdce2 ,
bb.pdce_liv2_desc::varchar  descr_pdce2 ,
bb.pdce_liv3_id  id_pdce3 ,
bb.pdce_liv3_code::varchar  codice_pdce3 ,
bb.pdce_liv3_desc::varchar  descr_pdce3 ,
bb.pdce_liv4_id   id_pdce4 ,
bb.pdce_liv4_code::varchar  codice_pdce4 ,
bb.pdce_liv4_desc::varchar  descr_pdce4 ,
bb.pdce_liv5_id   id_pdce5 ,
bb.pdce_liv5_code::varchar  codice_pdce5 ,
bb.pdce_liv5_desc::varchar  descr_pdce5 ,
bb.pdce_liv6_id   id_pdce6 ,
bb.pdce_liv6_code::varchar  codice_pdce6 ,
bb.pdce_liv6_desc::varchar  descr_pdce6 ,
bb.pdce_liv7_id   id_pdce7 ,
bb.pdce_liv7_code::varchar  codice_pdce7 ,
bb.pdce_liv7_desc::varchar  descr_pdce7 ,
coalesce(bb.pdce_liv8_id,0)::integer   id_pdce8 ,
coalesce(bb.pdce_liv8_code,'')::varchar  codice_pdce8 ,
coalesce(bb.pdce_liv8_desc,'')::varchar  descr_pdce8, 
ord.data_registrazione,
ord.num_prima_nota,
ord.tipo_pnota tipo_pnota,
ord.prov_pnota,
ord.cod_soggetto, 
ord.descr_soggetto,
ord.tipo_documento tipo_documento,--uguale a tipo_pnota,
ord.data_registrazione_movimento,
''::varchar numero_documento,
ord.num_det_rif,
ord.data_det_rif,
ord.importo_dare,                    
ord.importo_avere,             
--bb.livello::integer,
cc.livello::integer,
ord.tipo_movimento,
0::numeric  saldo_prec_dare,
0::numeric  saldo_prec_avere ,
0::numeric saldo_ini_dare ,
0::numeric saldo_ini_avere ,
--bb.codice_conto::varchar   code_pdce_livello ,
cc.pdce_conto_code::varchar   code_pdce_livello ,
''::varchar  display_error 
from ord join cc on ord.pdce_conto_id=cc.pdce_conto_id
cross join bb 
) as outp
;
  
 delete from siac_rep_struttura_pdce 	where utente=user_table;
  
exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5069 - Maurizio - FINE

-- SIAC-5072 - INIZIO
INSERT INTO siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.azione_tipo_id, dga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', FALSE, to_timestamp('01/01/2013','dd/mm/yyyy'), tep.ente_proprietario_id, 'admin'
FROM siac_d_azione_tipo dat
JOIN siac_t_ente_proprietario tep ON (dat.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac_d_gruppo_azioni dga ON (dga.ente_proprietario_id = tep.ente_proprietario_id)
CROSS JOIN (VALUES ('OP-SPE-NoDatiSospensioneDec', 'Dati sospensione documento e quote non modificabili con liquidazione definitiva', 'AZIONE_SECONDARIA', 'FIN_BASE2')) AS tmp(code, descr, tipo, gruppo)
WHERE dga.gruppo_azioni_code = tmp.gruppo
AND dat.azione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione ta
	WHERE ta.azione_tipo_id = dat.azione_tipo_id
	AND ta.azione_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;
-- SIAC-5072 - FINE


-- Sofia JIRA SIAC-5073 - INIZIO

-- inserimento accredito_tipo=SU
insert into siac_d_accredito_tipo
( accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  ente_proprietario_id,
  login_operazione,
  accredito_gruppo_id,
  validita_inizio
 )
 select 'SU',
        'SUCCESSIONE',
        12,
        gruppo.ente_proprietario_id,
        'admin',
        gruppo.accredito_gruppo_id,
        '2017-01-01'
 from siac_d_accredito_gruppo gruppo
 where gruppo.ente_proprietario_id=3
 and   gruppo.accredito_gruppo_code='CSI'
 and   not exists
 (
 select 1 from siac_d_accredito_tipo tipo1
 where tipo1.ente_proprietario_id=gruppo.ente_proprietario_id
 and   tipo1.accredito_tipo_code='SU'
 );

 -- inserimento relaz_tipo=SU
  insert into siac_d_relaz_tipo
(relaz_tipo_code,relaz_tipo_desc,validita_inizio, ente_proprietario_id,login_operazione)
select'SU','SUCCESSIONE','2017-01-01',a.ente_proprietario_id,
  'admin' from siac_t_ente_proprietario a 
  where a.ente_proprietario_id = 3 and 
  not exists
  ( select  1 from siac_d_relaz_tipo tipo
  where tipo.ente_proprietario_id=3
  and   tipo.relaz_tipo_code='SU'
  );


-- inserimento siac_r_oil_relaz_tipo
insert into siac_r_oil_relaz_tipo
(
	relaz_tipo_id,
    oil_relaz_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select relaz_tipo_id,
       oil_relaz_tipo_id,
       '2017-01-01',
       'admin',
       tipo.ente_proprietario_id
from siac_d_relaz_tipo tipo, siac_d_oil_relaz_tipo oil
where tipo.ente_proprietario_id=3
and   tipo.relaz_tipo_code='SU'
and   oil.ente_proprietario_id=3
and   oil.oil_relaz_tipo_code='CSI'
and   not exists
(
select 1
from siac_r_oil_relaz_tipo r1
where r1.ente_proprietario_id=tipo.ente_proprietario_id
and   r1.relaz_tipo_id=tipo.relaz_tipo_id
and   r1.oil_relaz_tipo_id=oil.oil_relaz_tipo_id
);

-- Sofia JIRA SIAC-5073 - INIZIO
