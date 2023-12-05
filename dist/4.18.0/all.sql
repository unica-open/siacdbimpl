/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-7149 - Maurizio - INIZIO

DROP FUNCTION if exists siac.fnc_bilr105_tab_oneri_reversali(p_ente_prop_id integer, p_id_bil integer);

CREATE OR REPLACE FUNCTION siac.fnc_bilr105_tab_oneri_reversali (
  p_ente_prop_id integer,
  p_id_bil integer
)
RETURNS TABLE (
  ord_id integer,
  tipo_split_comm varchar,
  tipo_split_istituz varchar,
  tipo_split_reverse varchar,
  cartacont_pk integer,
  cartacont varchar,
  aliquota varchar,
  num_riscoss varchar,
  importo_iva_comm numeric,
  importo_iva_istituz numeric,
  importo_iva_reverse numeric
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoOneri record;
elencoReversali record;
ciclo integer;
sql_query VARCHAR;
ord_id_corr INTEGER;
var_attr_id integer;
flgOneriExist boolean;

/*
	SIAC-7014 18/09/2019.
Funzione utilizzata dal report BILR105 per estrarre gli oneri e le reversali
per ogni ordinativo.
*/

BEGIN

ord_id:=null;
tipo_split_comm:='';
tipo_split_istituz:='';
tipo_split_reverse:='';
cartacont_pk:=null;
cartacont:='';
aliquota:='';
num_riscoss:='';
importo_iva_comm :=0;
importo_iva_istituz :=0;
importo_iva_reverse :=0;

flgOneriExist:=false;
  
select attr_id into var_attr_id 
from siac_t_attr t_attr 
where  t_attr.attr_code = 'ALIQUOTA_SOGG' 
	and t_attr.ente_proprietario_id=p_ente_prop_id
   	and t_attr.data_cancellazione IS NULL
   	and t_attr.validita_fine IS NULL;
    
ord_id_corr:=0;
for elencoOneri in 
	SELECT d_onere_tipo.onere_tipo_code, d_onere.onere_code,
          d_onere.onere_desc, d_split_iva_tipo.sriva_tipo_code,
          t_cartacont.cartac_id, t_cartacont.cartac_numero,
          t_cartacont.cartac_data_scadenza,
          r_onere_attr.percentuale, t_ordinativo_ts.ord_id, t_ord.ord_numero
        from siac_t_ordinativo t_ord,
        	siac_t_ordinativo_ts t_ordinativo_ts,
            siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
            siac_t_doc t_doc, 
            siac_t_subdoc t_subdoc
               left join siac_r_cartacont_det_subdoc r_cartacont_det_subdoc on (t_subdoc.subdoc_id=r_cartacont_det_subdoc.subdoc_id)
               left join siac_t_cartacont_det t_cartacont_det on (r_cartacont_det_subdoc.cartac_det_id=t_cartacont_det.cartac_det_id)
               left join siac_t_cartacont t_cartacont on (t_cartacont_det.cartac_id=t_cartacont.cartac_id),     
            siac_r_doc_onere r_doc_onere,
            siac_d_onere d_onere
            	left join siac_r_onere_attr r_onere_attr on 
                	(d_onere.onere_id = r_onere_attr.onere_id and r_onere_attr.data_cancellazione is null and r_onere_attr.attr_id=var_attr_id)
            ,siac_d_onere_tipo d_onere_tipo,
            siac_r_subdoc_splitreverse_iva_tipo r_subdoc_split_iva,
            siac_d_splitreverse_iva_tipo d_split_iva_tipo
        WHERE t_ord.ord_id= t_ordinativo_ts.ord_id
        	and r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
            AND t_doc.doc_id=t_subdoc.doc_id
            and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
            AND r_doc_onere.doc_id=t_doc.doc_id
            AND d_onere.onere_id=r_doc_onere.onere_id
            AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id 
            AND r_subdoc_split_iva.subdoc_id=t_subdoc.subdoc_id     
            AND d_split_iva_tipo.sriva_tipo_id=r_subdoc_split_iva.sriva_tipo_id  
            and t_ordinativo_ts.ente_proprietario_id= p_ente_prop_id
            and t_ord.bil_id = p_id_bil
            AND d_onere_tipo.onere_tipo_code='SP' --SPLIT
            AND t_doc.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL
            AND r_doc_onere.data_cancellazione IS NULL
            AND d_onere.data_cancellazione IS NULL
            AND d_onere_tipo.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_split_iva.data_cancellazione IS NULL
            AND d_split_iva_tipo.data_cancellazione IS NULL
       ORDER BY t_ordinativo_ts.ord_id, r_onere_attr.percentuale--t_cartacont.cartac_id
loop
flgOneriExist:=true; --esiste almeno un record di oneri
	if ord_id_corr <> 0 and ord_id_corr <> elencoOneri.ord_id then
    	--elaboro e restituisco i dati del record precedente 
      for elencoReversali in     
            select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                    t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                    t_ord_ts_det.ord_ts_det_importo importo_ord
            from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                  siac_d_ordinativo_tipo d_ordinativo_tipo,
                  siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo
                  where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                      AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                      AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                      AND t_ord_ts.ord_id=t_ordinativo.ord_id
                      AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                      AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code ='I'
                     AND ts_det_tipo.ord_ts_det_tipo_code='A'
                        /* 09/03/2016:  estraggo solo le reversali di tipo SPR
                            DOVREBBE ESSERE SOLO 1 */
                AND d_relaz_tipo.relaz_tipo_code='SPR' 
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                AND r_ordinativo.ord_id_da = ord_id_corr--elencoMandati.ord_id
                and t_ordinativo.ente_proprietario_id=p_ente_prop_id
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
          loop
        --raise notice 'numero mandato %, importo rev % ',elencoMandati.ord_numero, elencoReversali.importo_ord;             
              if num_riscoss = '' THEN
                  num_riscoss = elencoReversali.ord_numero ::VARCHAR;
              else
                  num_riscoss = num_riscoss||', '||elencoReversali.ord_numero ::VARCHAR;
              end if;    
          end loop;   
              /* 09/03/2016: l'importo dell'iva e' quello della reversale.
                        Il tipo di iva e' impostato in base al tipo onere del mandato
            estratto in precedenza */
          if tipo_split_comm <> '' THEN
            importo_iva_comm=elencoReversali.importo_ord;
          elsif tipo_split_istituz <> '' THEN
            importo_iva_istituz=elencoReversali.importo_ord;
          elsif tipo_split_reverse <> '' THEN
            importo_iva_reverse=elencoReversali.importo_ord;
          END IF;                 
                        
    	return next;
        
        ord_id:=null;
		tipo_split_comm:='';
        tipo_split_istituz:='';
        tipo_split_reverse:='';
        cartacont_pk:=null;
        cartacont:='';
        aliquota:='';
        num_riscoss:='';
        importo_iva_comm :=0;
        importo_iva_istituz :=0;
        importo_iva_reverse :=0;
    end if;
    
    ord_id:=elencoOneri.ord_id;
    ord_id_corr:=elencoOneri.ord_id;
    
            --SPLIT COMMERCIALE
    IF elencoOneri.sriva_tipo_code =  'SC' THEN
        tipo_split_comm=elencoOneri.sriva_tipo_code; 
        --SPLIT ISTITUZIONALE
    ELSIF elencoOneri.sriva_tipo_code = 'SI' THEN
        tipo_split_istituz=elencoOneri.sriva_tipo_code;
        --REVERSE CHANGE
    ELSIF elencoOneri.sriva_tipo_code = 'RC' THEN
        tipo_split_reverse=elencoOneri.sriva_tipo_code;
    END IF;
    if elencoOneri.cartac_id is not null and cartacont_pk != elencoOneri.cartac_id then
        cartacont_pk := elencoOneri.cartac_id;
        if cartacont = '' then
            cartacont=elencoOneri.cartac_numero||' - '||to_char(elencoOneri.cartac_data_scadenza,'dd/MM/yyyy');
        else
            cartacont=cartacont||', '||elencoOneri.cartac_numero||' - '||to_char(elencoOneri.cartac_data_scadenza,'dd/MM/yyyy');
        end if;
    end if;
    IF elencoOneri.percentuale is not null and aliquota not like '%'||elencoOneri.percentuale||'%' then
        if aliquota = '' then
            aliquota=aliquota||elencoOneri.percentuale ;
        else
            aliquota=aliquota||', '||elencoOneri.percentuale;
        end if;
    end if;
	
      
end loop;


--29/10/2019 SIAC-7149
-- l'ultimo record non veniva resituito nel resultset, devo elaborarlo.
if flgOneriExist = true then
  --devo gestire anche l'ultimo record
  for elencoReversali in     
        select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                t_ord_ts_det.ord_ts_det_importo importo_ord
        from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
              siac_d_ordinativo_tipo d_ordinativo_tipo,
              siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
              siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo
              where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                  AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                  AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                  AND t_ord_ts.ord_id=t_ordinativo.ord_id
                  AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                  AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                 AND d_ordinativo_tipo.ord_tipo_code ='I'
                 AND ts_det_tipo.ord_ts_det_tipo_code='A'
                    /* 09/03/2016:  estraggo solo le reversali di tipo SPR
                        DOVREBBE ESSERE SOLO 1 */
            AND d_relaz_tipo.relaz_tipo_code='SPR' 
              /* ord_id_da contiene l'ID del mandato
                 ord_id_a contiene l'ID della reversale */
            AND r_ordinativo.ord_id_da = ord_id_corr--elencoMandati.ord_id
            and t_ordinativo.ente_proprietario_id=p_ente_prop_id
            AND d_relaz_tipo.data_cancellazione IS NULL
            AND t_ordinativo.data_cancellazione IS NULL
            AND r_ordinativo.data_cancellazione IS NULL
            AND r_ordinativo.data_cancellazione IS NULL
            AND t_ord_ts.data_cancellazione IS NULL
            AND t_ord_ts_det.data_cancellazione IS NULL
            AND ts_det_tipo.data_cancellazione IS NULL
      loop
    --raise notice 'numero mandato %, importo rev % ',elencoMandati.ord_numero, elencoReversali.importo_ord;             
          if num_riscoss = '' THEN
              num_riscoss = elencoReversali.ord_numero ::VARCHAR;
          else
              num_riscoss = num_riscoss||', '||elencoReversali.ord_numero ::VARCHAR;
          end if;    
      end loop;   
          /* 09/03/2016: l'importo dell'iva e' quello della reversale.
                    Il tipo di iva e' impostato in base al tipo onere del mandato
        estratto in precedenza */
      if tipo_split_comm <> '' THEN
        importo_iva_comm=elencoReversali.importo_ord;
      elsif tipo_split_istituz <> '' THEN
        importo_iva_istituz=elencoReversali.importo_ord;
      elsif tipo_split_reverse <> '' THEN
        importo_iva_reverse=elencoReversali.importo_ord;
      END IF;                 
                          
    return next;
end if;
  
exception
    when no_data_found THEN
        raise notice 'nessun mandato trovato' ;
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

--SIAC-7149 - Maurizio - FINE


--SIAC-7041 - Maurizio e Haitham - INIZIO

DROP FUNCTION if exists siac."BILR238_spese_riepilogo_missione_programma"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar);

CREATE OR REPLACE FUNCTION siac."BILR238_spese_riepilogo_missione_programma" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  bil_ele_id integer,
  imp_variaz_stanz_anno numeric,
  imp_variaz_stanz_anno1 numeric,
  imp_variaz_stanz_anno2 numeric,
  imp_variaz_cassa_anno numeric,
  imp_variaz_stanz_fpv_anno numeric,
  imp_variaz_stanz_fpv_anno1 numeric,
  imp_variaz_stanz_fpv_anno2 numeric,
  imp_variaz_residui_anno numeric,
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;
ImpegniRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec VARCHAR;
annobilint integer :=0;
previsioni_anno_prec_cassa_app NUMERIC;
previsioni_anno_prec_comp_app NUMERIC;
tipo_categ_capitolo VARCHAR;
stanziamento_fpv_anno_prec_app NUMERIC;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
v_importo_imp   NUMERIC :=0;
v_importo_imp1  NUMERIC :=0;
v_importo_imp2  NUMERIC :=0;
v_conta_rec INTEGER :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
x_array VARCHAR [];

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

/*
	28/10/2019.
	Funzione creata per la richiesta SIAC-7041 usata dai report BILR238, BILR239, BILR240.
    La funzione si basa sul comportamento della funzione "BILR111_Allegato_9_bil_gest_spesa_mpt" 
    ma riceve in input, oltre all'ente ed all'anno bilancio, solo un elenco di variazioni 
    obbligatorio.
    La funzione fornisce in output solo i dati delle variazioni raggruppati per:
    - missione
    - programma
    - titolo
	- macroaggregato
    - capitolo.
    E' compito di ciascun report raggruppare ulteriormente i dati secondo le necessita'.
    Gli importi delle variazioni riguardano:
    - competenza anno bilancio, annobilancio + 1 e anno bilancio + 2;
    - cassa anno bilancio;
    - residui anno bilancio;
    - stanziamento fpv anno bilancio, annobilancio + 1 e anno bilancio + 2.
    
    Gli importi degli impegni sono impostati a 0 perche' nei report esistono i campi ma non
    devono essere valorizzati.
    
    ATTENZIONE: 
    Gli importi delle variazioni riguardano solo i capitoli di tipo ('STD','FSC','FPV','FPVC'),
    cosi' come fatto dalla procedura "BILR111_Allegato_9_bil_gest_spesa_mpt".
    Per questo modivo se si confrontano i totali delle variazioni da applicativo con i totali 
    estratti da questa procedura potrebbero esserci delle differenze, in quanto le variazioni
    potrebbero coinvolgere anche altri tipi di capitoli.    
    
*/

annobilint := p_anno::INTEGER;
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP-UG';	--- Capitolo gestione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;

-- verifico che il parametro con l'elenco delle variazioni abbia solo dei numeri oltre le virgole.
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



select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
-- raise notice 'user  %',user_table;

bil_anno='';

missione_code='';
missione_desc='';

programma_code='';
programma_desc='';

titusc_code='';
titusc_desc='';

macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
imp_variaz_stanz_anno=0;
imp_variaz_stanz_anno1=0;
imp_variaz_stanz_anno2=0;
imp_variaz_cassa_anno=0;
imp_variaz_stanz_fpv_anno=0;
imp_variaz_stanz_fpv_anno1=0;
imp_variaz_stanz_fpv_anno2=0;
   
display_error:='';

--uso una tabella di appoggio per le varizioni perche' la query e' di tipo dinamico
--in quanto il parametro con l'elenco delle variazioni e' variabile.

sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';          
       
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';    
  
    sql_query=sql_query || ' and testata_variazione.ente_proprietario_id	=  ' || p_ente_prop_id ||'     
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';

    sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
       
    sql_query=sql_query||'
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	    

raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;                
                
return query 
with struttura as (
	select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,user_table)),
capitoli as (   
    select 	programma.classif_id classif_id_programma,
            macroaggr.classif_id classif_id_macroaggregato,
            anno_eserc.anno anno_bilancio,
            capitolo.elem_code, 
            capitolo.elem_code2,
            capitolo.elem_code3,
            capitolo.elem_desc,
            capitolo.elem_id,
            capitolo.elem_desc2
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
        programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
        programma.classif_id=r_capitolo_programma.classif_id					and
        macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
        macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
        bilancio.periodo_id=anno_eserc.periodo_id 								and
        capitolo.bil_id=bilancio.bil_id 										and
        capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
        tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
        capitolo.elem_id=r_capitolo_programma.elem_id							and
        capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
        capitolo.elem_id				=	r_capitolo_stato.elem_id			and
        r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
        capitolo.elem_id				=	r_cat_capitolo.elem_id				and
        r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and                
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        anno_eserc.anno= p_anno 												and
        programma_tipo.classif_tipo_code='PROGRAMMA' 							and
        macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
        stato_capitolo.elem_stato_code	=	'VA'								and
        cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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
        and	r_cat_capitolo.data_cancellazione 	 		is null),
	variaz_stanz_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_cassa_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpCassa  --'SCA' -- cassa
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
      variaz_stanz_fpv_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_fpv_anno1 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp1
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id ),
    variaz_stanz_fpv_anno2 as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp2
                and variaz.tipologia = TipoImpComp  -- 'STA' Competenza
                and d_bil_elem_categ.elem_cat_code in ('FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )  ,
    variaz_residui_anno as (          
        	select	variaz.elem_id, 
                    sum(variaz.importo) importo_variaz                 	
            from 	siac_rep_var_spese variaz,
            		siac_r_bil_elem_categoria r_bil_elem_categ, 
                    siac_d_bil_elem_categoria d_bil_elem_categ
            where r_bil_elem_categ.elem_id	= variaz.elem_id
            	and r_bil_elem_categ.elem_cat_id=d_bil_elem_categ.elem_cat_id 
            	and variaz.ente_proprietario=p_ente_prop_id
            	and variaz.utente= user_table
                and variaz.periodo_anno = annoCapImp
                and variaz.tipologia = TipoImpRes --'STR'  residui
                and d_bil_elem_categ.elem_cat_code in ('STD','FSC','FPV','FPVC')
                and d_bil_elem_categ.validita_fine IS NULL
                and d_bil_elem_categ.data_cancellazione IS NULL
                and r_bil_elem_categ.validita_fine IS NULL
                and r_bil_elem_categ.data_cancellazione IS NULL
            group by 	variaz.elem_id )              		                                    
select 
  p_anno::varchar bil_anno,
  struttura.missione_tipo_desc::varchar missione_tipo_desc,
  struttura.missione_code::varchar missione_code,
  struttura.missione_desc:: varchar missione_desc,
  struttura.programma_tipo_desc:: varchar programma_tipo_desc,
  struttura.programma_code::varchar programma_code,
  struttura.programma_desc::varchar programma_desc,
  struttura.titusc_tipo_desc::varchar titusc_tipo_desc,
  struttura.titusc_code::varchar titusc_code,
  struttura.titusc_desc::varchar titusc_desc,
  struttura.macroag_tipo_desc::varchar macroag_tipo_desc,
  struttura.macroag_code::varchar macroag_code,
  struttura.macroag_desc::varchar macroag_desc,
  capitoli.elem_code::varchar bil_ele_code,
  capitoli.elem_desc::varchar bil_ele_desc,
  capitoli.elem_code2::varchar bil_ele_code2,
  capitoli.elem_desc2::varchar bil_ele_desc2,
  capitoli.elem_code3::varchar bil_ele_code3,
  capitoli.elem_id::integer bil_ele_id,
  COALESCE(variaz_stanz_anno.importo_variaz,0)::numeric imp_variaz_stanz_anno,
  COALESCE(variaz_stanz_anno1.importo_variaz,0)::numeric imp_variaz_stanz_anno1,
  COALESCE(variaz_stanz_anno2.importo_variaz,0)::numeric imp_variaz_stanz_anno2,
  COALESCE(variaz_cassa_anno.importo_variaz,0)::numeric imp_variaz_cassa_anno,
  COALESCE(variaz_stanz_fpv_anno.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno,
  COALESCE(variaz_stanz_fpv_anno1.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno1,
  COALESCE(variaz_stanz_fpv_anno2.importo_variaz,0)::numeric imp_variaz_stanz_fpv_anno2,
  COALESCE(variaz_residui_anno.importo_variaz,0)::numeric imp_variaz_residui_anno,  
  0::numeric impegnato_anno,
  0::numeric impegnato_anno1,
  0::numeric impegnato_anno2,
  ''::varchar display_error  
from struttura 
	left join capitoli
    	on (struttura.programma_id = capitoli.classif_id_programma    
           	and	struttura.macroag_id = capitoli.classif_id_macroaggregato)
    left join variaz_stanz_anno
      on variaz_stanz_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_anno1
      on variaz_stanz_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_anno2
      on variaz_stanz_anno2.elem_id = capitoli.elem_id 
    left join variaz_cassa_anno
      on variaz_cassa_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno
      on variaz_stanz_fpv_anno.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno1
      on variaz_stanz_fpv_anno1.elem_id = capitoli.elem_id
    left join variaz_stanz_fpv_anno2
      on variaz_stanz_fpv_anno2.elem_id = capitoli.elem_id
    left join variaz_residui_anno
      on variaz_residui_anno.elem_id = capitoli.elem_id;
                    
       
                          
delete from siac_rep_var_spese  where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'Nessun dato trovato riguardo la struttura di bilancio.';
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
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


CREATE OR REPLACE FUNCTION siac."BILR236_entrate_riepilogo_titoli_tipologie"(p_ente_prop_id integer, p_anno character varying, p_ele_variazioni character varying)
 RETURNS TABLE(bil_anno character varying, titoloe_tipo_code character varying, titoloe_tipo_desc character varying, titoloe_code character varying, titoloe_desc character varying, tipologia_tipo_code character varying, tipologia_tipo_desc character varying, tipologia_code character varying, tipologia_desc character varying, categoria_tipo_code character varying, categoria_tipo_desc character varying, categoria_code character varying, categoria_desc character varying, bil_ele_code character varying, bil_ele_desc character varying, bil_ele_code2 character varying, bil_ele_desc2 character varying, bil_ele_id integer, bil_ele_id_padre integer, stanziamento_prev_cassa_anno numeric, stanziamento_prev_anno numeric, stanziamento_prev_anno1 numeric, stanziamento_prev_anno2 numeric, residui_presunti numeric, previsioni_anno_prec numeric,  display_error character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
classifBilRec record;
elencoVarRec  record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec VARCHAR;
importo_cassa_app numeric;
importo_competenza_app numeric;
intApp INTEGER;
strApp VARCHAR;
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';
-- ALESSANDRO - SIAC-5208 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- ALESSANDRO - SIAC-5208 - FINE



BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
display_error='';

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

select fnc_siac_random_user()
into	user_table;



--06/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;

insert into siac_rep_cap_ep
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


insert into siac_rep_cap_ep             
with prec as (       
select * From siac_t_cap_e_importi_anno_prec a
where a.anno=annoPrec       
and a.ente_proprietario_id=p_ente_prop_id
)
, categ as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'CATEGORIA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)  
select categ.classif_id classif_id_categ,  p_anno,
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, user_table utente
 from prec
join categ on prec.categoria_code=categ.classif_code
and not exists (select 1 from siac_rep_cap_ep ep
                      where ep.elem_code=prec.elem_code
                        AND ep.elem_code2=prec.elem_code2
                        and ep.elem_code3=prec.elem_code3
                        and ep.classif_id = categ.classif_id
                        and ep.utente=user_table
                        and ep.ente_proprietario_id=p_ente_prop_id);                        
  
--------------



insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
            sum(capitolo_importi.elem_det_importo)   
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
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
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, 
	siac_rep_cap_ep_imp tb2, 
	siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, 
	siac_rep_cap_ep_imp tb5, 
	siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    


-------------------------------------
 
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';            
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id '; 
        
    sql_query=sql_query||' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    
      
    sql_query=sql_query || ' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
      union 
         select  tb0.elem_id,   
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
        union 
        select  tb0.elem_id,    
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);
end if;

-------------------------------------



for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_code3					BIL_ELE_CODE3,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
        
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
           --------RIGHT	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
           left	join    siac_rep_cap_ep_imp_riga tb1  
           			on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
			left	join  siac_rep_var_entrate_riga var_anno
           			on (var_anno.elem_id	=	tb.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	tb.utente=user_table
                        and var_anno.utente	=	tb.utente)         
			left	join  siac_rep_var_entrate_riga var_anno1
           			on (var_anno1.elem_id	=	tb.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	tb.utente=user_table
                        and var_anno1.utente	=	tb.utente)  
			left	join  siac_rep_var_entrate_riga var_anno2
           			on (var_anno2.elem_id	=	tb.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	tb.utente=user_table
                        and var_anno2.utente	=	tb.utente)                                                                        
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop



/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;

/* non servono piu' gli stanziamenti dei capitoli, ma non si smonta tutto  
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;
previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;
*/

--25/10/2019: sommo solo i valori delle variazioni

stanziamento_prev_anno=stanziamento_prev_anno+
                       classifBilRec.variazione_aumento_stanziato+
            		   classifBilRec.variazione_diminuzione_stanziato;
            		  
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+
                             classifBilRec.variazione_aumento_cassa+
            				 classifBilRec.variazione_diminuzione_cassa;
            				
stanziamento_prev_anno1=stanziamento_prev_anno1+
                        classifBilRec.variazione_aumento_stanziato1+
            			classifBilRec.variazione_diminuzione_stanziato1;
            		
stanziamento_prev_anno2=stanziamento_prev_anno2+
                        classifBilRec.variazione_aumento_stanziato2+
            			classifBilRec.variazione_diminuzione_stanziato2;
            		
residui_presunti=residui_presunti+
                 classifBilRec.variazione_aumento_residuo+
            	 classifBilRec.variazione_diminuzione_residuo;

    	
            	
            	
           
            	
            	
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Tipologia %', bil_ele_code, bil_ele_id, tipologia_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;    
    

raise notice 'Cap %, ID = %, Tipologia %', bil_ele_code, bil_ele_id, tipologia_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;


/*raise notice 'record';*/
return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
residui_presunti:=0;
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
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
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$function$
;


--SIAC-7041 - Maurizio e Haitham - FINE

-- SIAC-7164 - Alessandro - INIZIO
DROP FUNCTION IF EXISTS siac.fnc_siac_capitoli_from_variazioni (integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_capitoli_from_variazioni (
  p_uid_variazione integer
)
RETURNS TABLE (
  stato_variazione varchar,
  anno_capitolo varchar,
  numero_capitolo varchar,
  numero_articolo varchar,
  numero_ueb varchar,
  tipo_capitolo varchar,
  descrizione_capitolo varchar,
  descrizione_articolo varchar,
  missione varchar,
  programma varchar,
  titolo_uscita varchar,
  macroaggregato varchar,
  titolo_entrata varchar,
  tipologia varchar,
  categoria varchar,
  var_competenza numeric,
  var_residuo numeric,
  var_cassa numeric,
  var_competenza1 numeric,
  var_residuo1 numeric,
  var_cassa1 numeric,
  var_competenza2 numeric,
  var_residuo2 numeric,
  var_cassa2 numeric,
  cap_competenza numeric,
  cap_residuo numeric,
  cap_cassa numeric,
  cap_competenza1 numeric,
  cap_residuo1 numeric,
  cap_cassa1 numeric,
  cap_competenza2 numeric,
  cap_residuo2 numeric,
  cap_cassa2 numeric,
  tipologiafinanziamento varchar,
  sac varchar,
  variazione_num integer,
  variazione_anno varchar
) AS
$body$
DECLARE
	v_ente_proprietario_id INTEGER;
    v_sleep record;
BEGIN


	--select pg_sleep(90), 90  into v_sleep;
    --raise notice 'v_sleep %',v_sleep;
    
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
        tipofinanziamento AS (
        	SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc tipofinanziamento_tipo_desc,
				siac_t_class.classif_id tipofinanziamento_id,
				siac_t_class.classif_code tipofinanziamento_code,
				siac_t_class.classif_desc tipofinanziamento_desc,
				siac_t_class.validita_inizio tipofinanziamento_validita_inizio,
				siac_t_class.validita_fine tipofinanziamento_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipofinanziamento_code_desc,
				siac_r_bil_elem_class.elem_id tipofinanziamento_elem_id
			FROM 
                     siac_t_class
                JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id  AND siac_d_class_tipo.data_cancellazione IS NULL)
                JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			where 
                   siac_d_class_tipo.classif_tipo_code = 'TIPO_FINANZIAMENTO'
              AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
        ),
        sac AS (
        	SELECT DISTINCT
				siac_d_class_tipo.classif_tipo_desc sar_tipo_desc,
				siac_t_class.classif_id sac_id,
				siac_t_class.classif_code sac_code,
				siac_t_class.classif_desc sac_desc,
				siac_t_class.validita_inizio sac_validita_inizio,
				siac_t_class.validita_fine sac_validita_fine,
				siac_t_class.ente_proprietario_id,
				(siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc,
				siac_r_bil_elem_class.elem_id sac_elem_id
			FROM 
                     siac_t_class
                JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id  AND siac_d_class_tipo.data_cancellazione IS NULL)
                JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			where 
                   siac_d_class_tipo.classif_tipo_code in ('CDC','CDR')
              AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
        ),
        
		-- CTE importi variazione
		comp_variaz AS (
        SELECT
				siac_t_bil_elem_det_var.elem_id,
				siac_t_bil_elem_det_var.elem_det_var_id,
				siac_r_variazione_stato.variazione_stato_id,
				siac_t_bil_elem_det_var.elem_det_importo impSta,
				siac_t_periodo.anno::INTEGER,
                periodo_bil.anno::INTEGER anno_bil
			FROM siac_t_bil
			JOIN siac_t_variazione        			ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  			ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_t_bil_elem_det_var  			ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo 			ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           			ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_t_periodo as periodo_bil      ON (siac_t_bil.periodo_id = periodo_bil.periodo_id                                            AND periodo_bil.data_cancellazione IS NULL)

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
				siac_t_periodo.anno::integer,
                periodo_bil.anno::INTEGER anno_bil
			FROM siac_t_bil
                JOIN siac_t_variazione        			ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
                JOIN siac_r_variazione_stato  			ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
                JOIN siac_t_bil_elem_det_var  			ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione  IS NULL)
                JOIN siac_d_bil_elem_det_tipo 			ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
                JOIN siac_t_periodo           			ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
                JOIN siac_t_periodo as periodo_bil      ON (siac_t_bil.periodo_id = periodo_bil.periodo_id                                            AND periodo_bil.data_cancellazione IS NULL)
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
				siac_t_periodo.anno::INTEGER,
                periodo_bil.anno::INTEGER anno_bil
			FROM siac_t_bil
				JOIN siac_t_variazione        ON (siac_t_bil.bil_id = siac_t_variazione.bil_id                                              AND siac_t_variazione.data_cancellazione IS NULL)
				JOIN siac_r_variazione_stato  ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                   AND siac_r_variazione_stato.data_cancellazione IS NULL)
				JOIN siac_t_bil_elem_det_var  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
				JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id      AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
				JOIN siac_t_periodo           ON (siac_t_variazione.periodo_id = siac_t_periodo.periodo_id                                  AND siac_t_periodo.data_cancellazione IS NULL)
				JOIN siac_t_periodo as periodo_bil      ON (siac_t_bil.periodo_id = periodo_bil.periodo_id                                  AND periodo_bil.data_cancellazione IS NULL)
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
            ,tipofinanziamento.tipofinanziamento_code_desc tipologiaFinanziamento
            ,sac.sac_code_desc sac
            ,siac_t_variazione.variazione_num
            ,periodo_variazione.anno variazione_anno
            
		FROM siac_t_variazione
		JOIN siac_r_variazione_stato           ON (siac_t_variazione.variazione_id = siac_r_variazione_stato.variazione_id                             AND siac_r_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_d_variazione_stato           ON (siac_r_variazione_stato.variazione_stato_tipo_id = siac_d_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem_det_var           ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
		JOIN siac_t_bil_elem                   ON (siac_t_bil_elem_det_var.elem_id = siac_t_bil_elem.elem_id                                           AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                        ON (siac_t_bil_elem.bil_id = siac_t_bil.bil_id                                                          AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                    ON (siac_t_bil.periodo_id = siac_t_periodo.periodo_id                                                   AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_tipo              ON (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id                                    AND siac_d_bil_elem_tipo.data_cancellazione IS NULL)
		JOIN siac_d_bil_elem_det_tipo          ON (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
		
        --JOIN siac_t_bil     bil_variazione     ON (bil_variazione.bil_id = siac_t_variazione.bil_id                                                    AND bil_variazione.data_cancellazione IS NULL)
		--JOIN siac_t_periodo periodo_variazione ON (bil_variazione.periodo_id = periodo_variazione.periodo_id                                           AND periodo_variazione.data_cancellazione IS NULL)
		JOIN siac_t_periodo periodo_variazione ON (siac_t_variazione.periodo_id = periodo_variazione.periodo_id                                          AND periodo_variazione.data_cancellazione IS NULL)
		
        -- Importi variazione, anno 0
		LEFT OUTER JOIN comp_variaz    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz.variazione_stato_id     AND siac_t_bil_elem_det_var.elem_id = comp_variaz.elem_id   AND periodo_variazione.anno::INTEGER = comp_variaz.anno_bil   )
		LEFT OUTER JOIN residuo_variaz ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz.elem_id AND periodo_variazione.anno::INTEGER = residuo_variaz.anno_bil)		
        LEFT OUTER JOIN cassa_variaz   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz.elem_id   AND periodo_variazione.anno::INTEGER = cassa_variaz.anno_bil )
		-- Importi variazione, anno +1
		LEFT OUTER JOIN comp_variaz    comp_variaz1    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz1.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz1.elem_id    AND periodo_variazione.anno::INTEGER = comp_variaz1.anno_bil     + 1)
		LEFT OUTER JOIN residuo_variaz residuo_variaz1 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz1.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz1.elem_id AND periodo_variazione.anno::INTEGER = residuo_variaz1.anno_bil  + 1 )
		LEFT OUTER JOIN cassa_variaz   cassa_variaz1   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz1.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz1.elem_id   AND periodo_variazione.anno::INTEGER = cassa_variaz1.anno_bil    + 1 )
		-- Importi variazione, anno +2
		LEFT OUTER JOIN comp_variaz    comp_variaz2    ON (siac_r_variazione_stato.variazione_stato_id = comp_variaz2.variazione_stato_id    AND siac_t_bil_elem_det_var.elem_id = comp_variaz2.elem_id    AND periodo_variazione.anno::INTEGER = comp_variaz2.anno_bil     + 2)
		LEFT OUTER JOIN residuo_variaz residuo_variaz2 ON (siac_r_variazione_stato.variazione_stato_id = residuo_variaz2.variazione_stato_id AND siac_t_bil_elem_det_var.elem_id = residuo_variaz2.elem_id AND periodo_variazione.anno::INTEGER = residuo_variaz2.anno_bil  + 2)
		LEFT OUTER JOIN cassa_variaz   cassa_variaz2   ON (siac_r_variazione_stato.variazione_stato_id = cassa_variaz2.variazione_stato_id   AND siac_t_bil_elem_det_var.elem_id = cassa_variaz2.elem_id   AND periodo_variazione.anno::INTEGER = cassa_variaz2.anno_bil    + 2)


		-- Importi capitolo, anno 0
		LEFT OUTER JOIN comp_capitolo    ON (siac_t_bil_elem.elem_id = comp_capitolo.elem_id    AND comp_capitolo.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN residuo_capitolo ON (siac_t_bil_elem.elem_id = residuo_capitolo.elem_id AND residuo_capitolo.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN cassa_capitolo   ON (siac_t_bil_elem.elem_id = cassa_capitolo.elem_id   AND cassa_capitolo.anno = siac_t_periodo.anno::INTEGER)
		-- Importi capitolo, anno +1
		LEFT OUTER JOIN comp_capitolo    comp_capitolo1    ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id    AND siac_t_periodo.anno::INTEGER + 1 = comp_capitolo1.anno)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo1 ON (siac_t_bil_elem.elem_id = residuo_capitolo1.elem_id AND siac_t_periodo.anno::INTEGER + 1 = residuo_capitolo1.anno)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo1   ON (siac_t_bil_elem.elem_id = cassa_capitolo1.elem_id   AND siac_t_periodo.anno::INTEGER + 1 = cassa_capitolo1.anno)
		-- Importi capitolo, anno +2
		LEFT OUTER JOIN comp_capitolo    comp_capitolo2    ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id    AND siac_t_periodo.anno::INTEGER + 2 = comp_capitolo2.anno)
		LEFT OUTER JOIN residuo_capitolo residuo_capitolo2 ON (siac_t_bil_elem.elem_id = residuo_capitolo2.elem_id AND siac_t_periodo.anno::INTEGER + 2 = residuo_capitolo2.anno)
		LEFT OUTER JOIN cassa_capitolo   cassa_capitolo2   ON (siac_t_bil_elem.elem_id = cassa_capitolo2.elem_id   AND siac_t_periodo.anno::INTEGER + 2 = cassa_capitolo2.anno)
		-- Classificatori
		LEFT OUTER JOIN macroag   ON (macroag.macroag_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN programma ON (programma.programma_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN missione  ON (missione.missione_id = programma.missione_id)
		LEFT OUTER JOIN titusc    ON (titusc.titusc_id = macroag.titusc_id)
		LEFT OUTER JOIN categoria ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN tipologia ON (tipologia.tipologia_id = categoria.tipologia_id)
		LEFT OUTER JOIN titent    ON (tipologia.titent_id = titent.titent_id)
        -- SIAC-6468
        LEFT OUTER JOIN tipofinanziamento ON (tipofinanziamento.tipofinanziamento_elem_id = siac_t_bil_elem.elem_id)
        LEFT OUTER JOIN sac ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
        
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

-- SIAC-7164 - Alessandro - FINE


-- SIAC-7145 - Sofia - INIZIO
drop FUNCTION if exists fnc_fasi_bil_gest_apertura_liq_elabora_imp
(
  enteProprietarioId     integer,
  annoBilancio           integer,
  tipoElab               varchar,
  faseBilElabId          integer,
  minId                  integer,
  maxId                  integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
);

drop FUNCTION if exists siac.fnc_fasi_bil_gest_apertura_acc_elabora 
(
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);


CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_liq_elabora_imp 
(
  enteproprietarioid integer,
  annobilancio integer,
  tipoelab varchar,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;
	movgGestTsIdPadre integer:=null;

    movGestRec        record;
    aggProgressivi    record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-UG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';

    APE_GEST_IMP_RES  CONSTANT varchar:='APE_GEST_IMP_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';

	-- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;

    -- 15.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';


	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

    if tipoElab=APE_GEST_LIQ_RES then
 	 strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui per ribaltamento liquidazioni res da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    else
     strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    end if;

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_liq_imp].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_liq_imp_id) into maxId
        from fase_bil_t_gest_apertura_liq_imp fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

    -- 08.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_liq_imp per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_liq_imp fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where Fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;
    -- 08.11.2019 Sofia SIAC-7145 - fine


     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per I
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||IMP_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     -- 15.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 15.02.2017 Sofia HD-INC000001535447

     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

	 -- 15.02.2017 Sofia SIAC-4425
     strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
   	 select attr.attr_id into strict flagFrazAttrId
     from siac_t_attr attr
     where attr.ente_proprietario_id=enteProprietarioId
     and   attr.attr_code=FRAZIONABILE_ATTR
     and   attr.data_cancellazione is null
     and   attr.validita_fine is null;


     -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
     end if;

     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     strMessaggio:='Inizio ciclo per generazione impegni.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_liq_imp_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_liq_imp fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
/*      and   exists -- x test siac-6255
      (
      select 1
      from siac_r_movgest_ts_programma r
      where r.movgest_ts_id=fase.movgest_orig_ts_id
      and   r.data_cancellazione is null
      and   r.validita_fine is null
      ) */
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
 		 insert into fase_bil_t_elaborazione_log
	     (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	     )
	     values
    	 (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	     returning fase_bil_elab_log_id into codResult;

	     if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	     end if;

    	 codResult:=null;
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Impegno [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
     	  insert into siac_t_movgest
          (movgest_anno,
		   movgest_numero,
		   movgest_desc,
		   movgest_tipo_id,
		   bil_id,
		   validita_inizio,
	       ente_proprietario_id,
	       login_operazione,
	       parere_finanziario,
	       parere_finanziario_data_modifica,
	       parere_finanziario_login_operazione
		   )
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
          end if;
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo impegno.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subimpegno movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';
			strMessaggioTemp:=strMessaggio;
        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subimpegno movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
		  siope_tipo_debito_id ,
  		  siope_assenza_motivazione_id
        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di impegno padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
		  ts.siope_tipo_debito_id ,
  		  ts.siope_assenza_motivazione_id
          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                       ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO)
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

       /* select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_movgest_ts_atto_amm det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

       -- raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        -- 15.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );



 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_programma
       if codResult is null then
	   	if faseOp=G_FASE then
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
--            and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN'			-- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );

		   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );

           strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
		         siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );
        end if;
       end if;


       /*if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_programma].';

        insert into siac_r_movgest_ts_programma
        ( movgest_ts_id,
          programma_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_movgest_ts_programma det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_programma det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_programma movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_mutuo_voce_movgest
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_mutuo_voce_movgest].';

        insert into siac_r_mutuo_voce_movgest
        ( movgest_ts_id,
          mut_voce_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.mut_voce_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_mutuo_voce_movgest r,siac_t_mutuo_voce voce
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   voce.mut_voce_id=r.mut_voce_id
          and   voce.data_cancellazione is null
          and   voce.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_mutuo_voce_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_voce_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_mutuo_voce_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_giustificativo_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/


       -- siac_r_cartacont_det_movgest_ts
       /* Non si ribalta in seguito ad indicazioni di Annalina
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_cartacont_det_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_fondo_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_fondo_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_richiesta_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_richiesta_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia correzione per esclusione quote pagate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A');

        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
		and   det1.data_cancellazione is null
        and   det1.validita_fine is null;

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
      /*   spostato sotto dopo pulizia in caso di codResult null
           if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; */

       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
    	 	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
	                      ' movgest_orig_id='||movGestRec.movgest_orig_id||
                          ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                          ' elem_orig_id='||movGestRec.elem_orig_id||
                          ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_cartacont_det_movgest_ts].';
	        update siac_r_cartacont_det_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_cartacont_det_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;
       end if; */


	   -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null then
       	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_storico_imp_acc].';

        insert into siac_r_movgest_ts_storico_imp_acc
        ( movgest_ts_id,
          movgest_anno_acc,
          movgest_numero_acc,
          movgest_subnumero_acc,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_anno_acc,
           r.movgest_numero_acc,
           r.movgest_subnumero_acc,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_storico_imp_acc r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
        );


        select 1  into codResult
        from siac_r_movgest_ts_storico_imp_acc det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;
         -- siac_r_mutuo_voce_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_mutuo_voce_movgest.';
         delete from siac_r_mutuo_voce_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_giustificativo_movgest
/*         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet; */
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

	     -- 17.06.2019 Sofia siac-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;


         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;




/*        strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';

      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento impegno/subimpegno residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
            --- 12.01.2017 Sofia - sistemazione update per escludere le quote pagate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub,siac_t_doc  doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
	    	    --strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
        end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_liq_imp per fine elaborazione.';
      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;


	 -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni residui.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni residui.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atti amministrativi antecedenti.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=2017
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile

    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||tipoElab||' IN CORSO IN-2.Elabora Imp.'
    where fase_bil_elab_id=faseBilElabId;


    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_acc_elabora 
(
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;
	movgGestTsIdPadre integer:=null;

    movGestRec        record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	ACC_MOVGEST_TIPO CONSTANT varchar:='A';
  	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-EG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_ACC_RES    CONSTANT varchar:='APE_GEST_ACC_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';
    U_MOV_GEST_DET_TIPO  CONSTANT varchar:='U';

    -- 17.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';

	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento accertamenti  residui  da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;

    codResult:=null;
    strMessaggio:='Verifica esistenza in fase_bil_t_gest_apertura_acc di movimenti da generare.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_acc fase
 	where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
	and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   fase.movgest_orig_id is not null
    and   fase.movgest_orig_ts_id is not null;
    if codResult is null then
    	 raise exception ' Nessun movimento presente.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_acc].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_acc_id) into maxId
        from fase_bil_t_gest_apertura_acc fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

	-- 12.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_acc per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_acc fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_acc_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

	codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_acc dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_acc fase
 	where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
	and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   fase.movgest_orig_id is not null
    and   fase.movgest_orig_ts_id is not null;
    if codResult is null then
    	 raise exception ' Nessun movimento presente.';
    end if;

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per A
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||ACC_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;





     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     -- 17.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 17.02.2017 Sofia HD-INC000001535447

	 -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
     end if;


     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     strMessaggio:='Inizio ciclo per generazione accertamenti.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_acc_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_acc fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_acc_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
 		 insert into fase_bil_t_elaborazione_log
	     (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	     )
	     values
    	 (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	     returning fase_bil_elab_log_id into codResult;

	     if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	     end if;

    	 codResult:=null;
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Accertamento [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
     	  insert into siac_t_movgest
          (movgest_anno,
		   movgest_numero,
		   movgest_desc,
		   movgest_tipo_id,
		   bil_id,
		   validita_inizio,
	       ente_proprietario_id,
	       login_operazione,
	       parere_finanziario,
	       parere_finanziario_data_modifica,
	       parere_finanziario_login_operazione)
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
          end if;
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo accertamento.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subaccertamento movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';

        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subaccertamento movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
	      siope_tipo_debito_id,
		  siope_assenza_motivazione_id

        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di accertamento padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          ts.siope_tipo_debito_id,
		  ts.siope_assenza_motivazione_id


          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                       ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO,U_MOV_GEST_DET_TIPO)
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
--          and   atto.data_cancellazione is null 17.02.2017 Sofia HD-INC000001535447
--          and   atto.validita_fine is null
         );



		select 1  into codResult
        from siac_r_movgest_ts_atto_amm det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

		-- 17.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         	strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;
        -- 17.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        /*if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;*/

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );



 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia sistemazione gestione quote per escludere quelle incassate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
        ;
        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; **/

	   -- 03.05.2019 Sofia siac-6255
       -- siac_r_movgest_ts_programma
       if codResult is null then
	   	if faseOp=G_FASE then
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            and   stato.programma_stato_code='VA'
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );
        end if;
       end if;

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_acc per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
/*
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;*/

         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

 		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;

         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;

        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_acc per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_acc per scarto.';
      	update fase_bil_t_gest_apertura_acc fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento accertamento/subaccertamento residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_acc_id=movGestRec.fase_bil_gest_ape_acc_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;


       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
       	    -- 12.01.2017 Sofia sistemazione gestione quote per escludere quote incassate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
			and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_acc per fine elaborazione.';
      	update fase_bil_t_gest_apertura_acc fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_acc_id=movGestRec.fase_bil_gest_ape_acc_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;



     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_ACC_RES||' IN CORSO IN-2.Elabora Acc.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;



-- SIAC-7145 - Sofia - FINE 


--SIAC-7200 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);
DROP FUNCTION if exists siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_spese"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-EG'; -- tipo capitolo gestione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  
raise notice '1 - %' , clock_timestamp()::text;
/*insert into  siac_rep_tit_tip_cat_riga_anni
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
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
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
order by titolo_code, tipologia_code,categoria_code;*/

-- 30/08/2016: cambiata la query che carica la struttura di bilancio
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code
 ;
 

raise notice '2 - %' , clock_timestamp()::text;
 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  
 
 /* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
strQuery:='
	with cap as (
select 		capitolo_importi.elem_id,
              capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
              capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
              capitolo_importi.ente_proprietario_id,
              capitolo_imp_tipo.elem_det_tipo_id,
              '''||user_table||''' utente,   
              sum(capitolo_importi.elem_det_importo)    importo_cap 
  from 		siac_t_bil_elem_det capitolo_importi,
              siac_d_bil_elem_det_tipo capitolo_imp_tipo,
              siac_t_periodo capitolo_imp_periodo,
              siac_t_bil_elem capitolo,
              siac_d_bil_elem_tipo tipo_elemento,
              siac_t_bil bilancio,
              siac_t_periodo anno_eserc, 
              siac_d_bil_elem_stato stato_capitolo, 
              siac_r_bil_elem_stato r_capitolo_stato,
              siac_d_bil_elem_categoria cat_del_capitolo, 
              siac_r_bil_elem_categoria r_cat_capitolo
      where 	capitolo_importi.ente_proprietario_id = '||p_ente_prop_id ||' 
          and	anno_eserc.anno						= 	'''||p_anno ||'''												
          and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
          and	capitolo.bil_id						=	bilancio.bil_id 			 
          and	capitolo.elem_id					=	capitolo_importi.elem_id 
          and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
          and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
          and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
          and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
          and	capitolo_imp_periodo.anno = '''||annoCapImp||'''
          and	capitolo.elem_id					=	r_capitolo_stato.elem_id
          and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
          and	stato_capitolo.elem_stato_code		=	''VA''
          and	capitolo.elem_id					=	r_cat_capitolo.elem_id
          and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
          and	cat_del_capitolo.elem_cat_code		=	''STD''
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
      group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
      capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente,
      capitolo_imp_tipo.elem_det_tipo_id),
 		-- SIAC-7200 nella query che estrae le variazioni successive, aggiunto
        --  il test sull''anno (periodo_id) che lega la variazione corrente
        --  (siac_t_variazione avar) a quelle successive (siac_t_variazione avarsucc).      
      importi_variaz as (      
          select               
                dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
                sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
                from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
                siac_t_variazione avar, siac_r_variazione_stato bvar,
                siac_d_variazione_stato cvarsucc,
                siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
                siac_d_bil_elem_det_tipo tipoimp,
                siac_t_bil_elem_det_var dvar
                where avar.ente_proprietario_id=avarsucc.ente_proprietario_id
                and avarsucc.variazione_id= bvarsucc.variazione_id
                and avar.variazione_id=bvar.variazione_id
                and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
                and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
                and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
                and dvar.variazione_stato_id=bvar.variazione_stato_id
                and dvar.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
                and dvar.periodo_id = dvarsucc.periodo_id                
                and bvarsucc.validita_inizio > bvar.validita_inizio
                and cvarsucc.variazione_stato_tipo_code=''D''                
                and cvar.variazione_stato_tipo_code=''D''                
                and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
                and bvarsucc.data_cancellazione is null
                and bvar.data_cancellazione is null
                and dvar.data_cancellazione is null
                and bvar.variazione_stato_id in (';
                --raise notice 'query1: %', strQuery; 
          if p_numero_delibera IS NOT NULL THEN
             strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_atto_amm             atto,
                  siac_d_atto_amm_tipo        tipo_atto,
                  siac_r_atto_amm_stato         r_atto_stato,
                  siac_d_atto_amm_stato         stato_atto,
                  siac_r_variazione_stato     var_stato
                where
                  (var_stato.attoamm_id = atto.attoamm_id 
                     or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
                  and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
                  and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
                  and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
                  and     atto.attoamm_numero=  '||p_numero_delibera||'
                  and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                  
                  and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
                  and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') 
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
          else 
          strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
          end if;
          strQuery:=strQuery||' 
                INSERT INTO siac_rep_cap_eg_imp
                select 	cap.elem_id, 
                          cap.BIL_ELE_IMP_ANNO, 
                          cap.TIPO_IMP,
                          cap.ente_proprietario_id, 
                          '''||user_table||''' utente,        
                          (cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
                from cap LEFT  JOIN importi_variaz 
                ON (cap.elem_id = importi_variaz.elem_id_var
                  and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id)';
          
          raise notice 'query2: %', strQuery;      

			execute  strQuery;   
     

RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb4.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb4
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb4.elem_id	 								and												
        			tb1.periodo_anno 	= annoCapImp		AND	tb1.tipo_imp =	tipoImpComp		and
        			tb2.periodo_anno	= tb1.periodo_anno	AND	tb2.tipo_imp = 	tipoImpCassa	and
                    tb4.periodo_anno	= tb1.periodo_anno	AND	tb4.tipo_imp = 	tipoImpRes		and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb4.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  

--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),        
            tipo_elemento.elem_det_tipo_code, 
            user_table utente,
            atto.ente_proprietario_id	      	
    from 	siac_t_atto_amm 			atto,
            siac_d_atto_amm_tipo		tipo_atto,
            siac_r_atto_amm_stato 		r_atto_stato,
            siac_d_atto_amm_stato 		stato_atto,
            siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_bil					t_bil,
            siac_t_periodo 				anno_importi
    where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    and		r_atto_stato.attoamm_id								=	atto.attoamm_id
    and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
    and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
                r_variazione_stato.attoamm_id_varbil   				=	atto.attoamm_id )
    and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
    and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
    and 	t_bil.bil_id 										= testata_variazione.bil_id
    and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
    and 	atto.ente_proprietario_id 							= 	p_ente_prop_id 
    and		atto.attoamm_numero 								= 	p_numero_delibera
    and		atto.attoamm_anno									=	p_anno_delibera
    and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
    and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
        -- 27/04:2017 l'anno di esercizio deve essere collegato a siac_t_bil									
        --and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
    and		anno_importi.anno									= 	annoCapImp
    and		anno_eserc.anno	= 	p_anno										
     -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
    -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
    --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
    and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
    and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
    and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
    and		atto.data_cancellazione						is null
    and		tipo_atto.data_cancellazione				is null
    and		r_atto_stato.data_cancellazione				is null
    and		stato_atto.data_cancellazione				is null
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null
    and		t_bil.data_cancellazione					is null
    group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                atto.ente_proprietario_id;
else 
	strQuery:='
    insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
and 	t_bil.bil_id 										= testata_variazione.bil_id
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id		
	-- 27/04:2017 l''anno di esercizio deve essere collegato a siac_t_bil									
	--and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
and 	testata_variazione.ente_proprietario_id	=	'||p_ente_prop_id||'
and		anno_eserc.anno	= 	'''||p_anno||''' 										
and 	testata_variazione.variazione_num in('||p_ele_variazioni||')
and		anno_importi.anno									= 	'''||annoCapImp||'''
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		t_bil.data_cancellazione					is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
            utente,
        	testata_variazione.ente_proprietario_id';

raise notice 'query: %', strQuery;      

execute  strQuery;       
     
end if;                

           
RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,     
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        tb1.ente_proprietario
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	)
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	)
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0	);


/* ---- vecchia query
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		variazione_aumento_stanziato,
        coalesce (tb2.importo,0)   as 		variazione_diminuzione_stanziato,
        coalesce (tb3.importo,0)   as 		variazione_aumento_cassa,
        coalesce (tb4.importo,0)   as 		variazione_diminuzione_cassa,
        coalesce (tb5.importo,0)   as 		variazione_aumento_residuo,
        coalesce (tb6.importo,0)   as 		variazione_diminuzione_residuo,
        user_table utente,
         tb1.ente_proprietario
from   
	siac_rep_var_entrate tb1, siac_rep_var_entrate tb2, siac_rep_var_entrate tb3,
	siac_rep_var_entrate tb4,siac_rep_var_entrate tb5,siac_rep_var_entrate tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
                    tb4.elem_id	=	tb5.elem_id								and
                    tb5.elem_id	=	tb6.elem_id								and
        			tb1.tipologia  = 'STA'	AND	tb1.importo > 0				AND
                    tb2.tipologia = tb1.tipologia 	and tb2.importo < 0 	AND
                    tb3.tipologia  = 'SCA'	AND	tb3.importo > 0				AND
                    tb4.tipologia = tb3.tipologia 	and tb4.importo < 0		and
                    tb5.tipologia  = 'STR'	AND	tb5.importo > 0				AND
                    tb6.tipologia = tb5.tipologia 	and tb6.importo < 0		and
                    tb1.utente	  = user_table	AND
                    tb2.utente		=	tb1.utente	and
                    tb3.utente		=	tb1.utente	and
                    tb4.utente		=	tb1.utente	and
                    tb5.utente		=	tb1.utente	and
                    tb6.utente		=	tb1.utente;   */
        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo
from  	siac_rep_tit_tip_cat_riga_anni v1
			left  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where v1.utente = user_table
   and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id
            /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	

			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop



---titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--------tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
-------categoria_tipo_code := classifBilRec.categoria_tipo_code;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;

return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
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

CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_su_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  display_error varchar
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma  varchar;
v_fam_titolomacroaggregato varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;


raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


---------------------------------------------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;
/*
 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  
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

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;
-- 30/08/2016: cambiata la query che carica la struttura di bilancio
--da 6 secondi a 105 ms
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
    /* 30/08/2016: start filtro per mis-prog-macro*/
    , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
 /* 30/08/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;



 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
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
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
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

  

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  


/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
strQuery:='
with cap as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,           
            capitolo_imp_tipo.elem_det_tipo_id,
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo	             			            
     where 	capitolo_importi.ente_proprietario_id 	='||p_ente_prop_id ||' 
        and	anno_eserc.anno						= 	'''||p_anno ||'''												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	'''||elemTipoCode||'''
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno  ='''||annoCapImp||'''
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		=	''VA''								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in (''STD'',''FPV'',''FSC'',''FPVC'')						
 		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id,  cat_del_capitolo.elem_cat_code,
    	capitolo_imp_tipo.elem_det_tipo_id),
        -- SIAC-7200 nella query che estrae le variazioni successive, aggiunto
        --  il test sull''anno (periodo_id) che lega la variazione corrente
        --  (siac_t_variazione avar) a quelle successive (siac_t_variazione avarsucc).
    importi_variaz as (      
		select               
              dvarsucc.elem_id elem_id_var, tipoimp.elem_det_tipo_id,
              sum(COALESCE(dvarsucc.elem_det_importo,0)) totale_var_succ
              from siac_t_variazione avarsucc, siac_r_variazione_stato bvarsucc,
              siac_t_variazione avar, siac_r_variazione_stato bvar,
              siac_d_variazione_stato cvarsucc,
              siac_d_variazione_stato cvar, siac_t_bil_elem_det_var dvarsucc,
              siac_d_bil_elem_det_tipo tipoimp,
              siac_t_bil_elem_det_var dvar
              where avar.ente_proprietario_id=avarsucc.ente_proprietario_id
              and avarsucc.variazione_id= bvarsucc.variazione_id
              and avar.variazione_id=bvar.variazione_id
              and bvarsucc.variazione_stato_tipo_id=cvarsucc.variazione_stato_tipo_id
              and bvar.variazione_stato_tipo_id=cvar.variazione_stato_tipo_id
              and dvarsucc.variazione_stato_id = bvarsucc.variazione_stato_id
              and tipoimp.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
              and dvar.variazione_stato_id=bvar.variazione_stato_id
              and dvar.elem_det_tipo_id = dvarsucc.elem_det_tipo_id
              and dvar.periodo_id = dvarsucc.periodo_id
              and bvarsucc.validita_inizio > bvar.validita_inizio               
              and cvarsucc.variazione_stato_tipo_code=''D''              
              and cvar.variazione_stato_tipo_code=''D''                            
              and bvarsucc.data_cancellazione is null
              and bvar.data_cancellazione is null
              and bvar.variazione_stato_id in ( ';
                             
if p_numero_delibera IS NOT NULL THEN
	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_atto_amm             atto,
                  siac_d_atto_amm_tipo        tipo_atto,
                  siac_r_atto_amm_stato         r_atto_stato,
                  siac_d_atto_amm_stato         stato_atto,
                  siac_r_variazione_stato     var_stato
                where
                  (var_stato.attoamm_id = atto.attoamm_id 
                     or var_stato.attoamm_id_varbil = atto.attoamm_id )                  
                  and     r_atto_stato.attoamm_id   =   atto.attoamm_id 
                  and     r_atto_stato.attoamm_stato_id     =   stato_atto.attoamm_stato_id
                  and     atto.ente_proprietario_id   =   '||p_ente_prop_id||'
                  and     atto.attoamm_numero=  '||p_numero_delibera||'
                  and     atto.attoamm_anno  =  '''||p_anno_delibera||'''                  
                  and     tipo_atto.attoamm_tipo_code  = '''||p_tipo_delibera||'''
                  and     stato_atto.attoamm_stato_code   =   ''DEFINITIVO'') 
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
else 
	strQuery:=strQuery||'     
                select max(var_stato.variazione_stato_id)
                from siac_t_variazione t_var,
                  siac_r_variazione_stato     var_stato
                where
                  t_var.variazione_id = var_stato.variazione_id
                  and t_var.ente_proprietario_id = '||p_ente_prop_id||'
                  and t_var.variazione_num in('||p_ele_variazioni||')
                  and t_var.data_cancellazione IS NULL
                  and var_stato.data_cancellazione IS NULL )
                group by dvarsucc.elem_id, tipoimp.elem_det_tipo_id) ';
end if;

strQuery:=strQuery||'
              INSERT INTO siac_rep_cap_ug_imp
              select 	cap.elem_id, 
              			cap.BIL_ELE_IMP_ANNO, 
                		cap.TIPO_IMP,
              			cap.ente_proprietario_id, 
                        '''||user_table||''' utente,               
                		(cap.importo_cap  - COALESCE(importi_variaz.totale_var_succ,0)) diff
              from cap LEFT  JOIN importi_variaz 
              ON (cap.elem_id = importi_variaz.elem_id_var
              	and cap.elem_det_tipo_id= importi_variaz.elem_det_tipo_id)';
 
raise notice 'query: %', strQuery;      

execute  strQuery; 
            
RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente 
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		tb1.periodo_anno 		= annoCapImp		AND	 tb1.tipo_imp 	=	tipoImpComp		AND
        		tb2.periodo_anno		= tb1.periodo_anno	AND	tb2.tipo_imp 	= 	tipoImpCassa	and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	tb4.tipo_imp 	= 	TipoImpRes		and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  

            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.            
--Parametro specificato: atto di variazione.
if p_numero_delibera is not null THEN        
insert into siac_rep_var_spese    
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        user_table utente,
        atto.ente_proprietario_id	      	
from 	siac_t_atto_amm 			atto,
        siac_d_atto_amm_tipo		tipo_atto,
		siac_r_atto_amm_stato 		r_atto_stato,
        siac_d_atto_amm_stato 		stato_atto,
        siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
and		r_atto_stato.attoamm_id								=	atto.attoamm_id
and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
       		r_variazione_stato.attoamm_id_varbil   				=	atto.attoamm_id )
and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
and 	t_bil.bil_id 										= testata_variazione.bil_id
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
and 	atto.ente_proprietario_id 							= 	p_ente_prop_id 
and		anno_eserc.anno										= 	p_anno				 	
and		atto.attoamm_numero 								= 	p_numero_delibera
and		atto.attoamm_anno									=	p_anno_delibera
and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
	-- 27/04:2017 l'anno di esercizio deve essere collegato a siac_t_bil									
	--and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
and		anno_importi.anno									= 	annoCapImp 									
 -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
-- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
--and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
and		atto.data_cancellazione						is null
and		tipo_atto.data_cancellazione				is null
and		r_atto_stato.data_cancellazione				is null
and		stato_atto.data_cancellazione				is null
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		t_bil.data_cancellazione					is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
            utente,
        	atto.ente_proprietario_id   ;
ELSE
	strQuery:= '
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
and 	t_bil.bil_id 										= testata_variazione.bil_id
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id ||'
and		anno_eserc.anno										= 	'''||p_anno||''' 
and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
and		anno_importi.anno									= 	'''||annoCapImp||'''									
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		t_bil.data_cancellazione					is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
            utente,
        	testata_variazione.ente_proprietario_id';
            
raise notice 'Query variazioni: %', strQuery;

execute strQuery;
            
end if;            
                     

            
        
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        tb1.ente_proprietario
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	)
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	)
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0	); 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_spese_riga x, siac_rep_cap_ug y, siac_r_class_fam_tree z
*/     
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table)     
    where v1.utente = user_table 
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id
             /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento:=classifBilRec.stanziamento;
cassa:=classifBilRec.cassa;
residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;



return next;
bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
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

--SIAC-7200 - Maurizio - FINE

-- SIAC-6480 - Sofia INIZIO

-- nuove colonne x mif_d_flusso_elaborato
SELECT * from fnc_dba_add_column_params ('mif_t_ordinativo_spesa', 'mif_ord_pagopa_num_avviso', 'varchar(50)');
SELECT * from fnc_dba_add_column_params ('mif_t_ordinativo_spesa', 'mif_ord_pagopa_codfisc', 'varchar(16)');

-- inserimento nuovi tag su mif_d_flusso_elaborato
INSERT INTO mif_d_flusso_elaborato
(
      flusso_elab_mif_ordine,
      flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
      flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
      flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
      validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
      flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id
)
select 150,'avviso_pagoPA','avviso_pagoPA',true,
       'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.informazioni_aggiuntive','',NULL,NULL,true,
       'AVVISO PAGOPA','2019-01-01',ente.ente_proprietario_id,'SIAC-6840',136,NULL,true,tipo.flusso_elab_mif_tipo_id
from siac_t_ente_proprietario ente,  mif_d_flusso_elaborato_tipo tipo
where  ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and    tipo.ente_proprietario_id=ente.ente_proprietario_id
and    tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and    not exists
(
select 1 from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and mif.flusso_elab_mif_ordine=150
and mif.flusso_elab_mif_code='avviso_pagoPA'
);

INSERT INTO mif_d_flusso_elaborato
(
      flusso_elab_mif_ordine,
      flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
      flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
      flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
      validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
      flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id
)
select 151,'codice_identificativo_ente','Codice fiscale soggetto intestatario mandato',true,
       'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.informazioni_aggiuntive.avviso_pagoPA',
       'mif_t_ordinativo_spesa','mif_ord_pagopa_codfisc','',true,'','2019-01-01',
       ente.ente_proprietario_id,'SIAC-6840',137,NULL,true,tipo.flusso_elab_mif_tipo_id
from siac_t_ente_proprietario ente,  mif_d_flusso_elaborato_tipo tipo
where  ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and    tipo.ente_proprietario_id=ente.ente_proprietario_id
and    tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and    not exists
(
select 1 from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and mif.flusso_elab_mif_ordine=151
and mif.flusso_elab_mif_code='codice_identificativo_ente'
);

INSERT INTO mif_d_flusso_elaborato
(
      flusso_elab_mif_ordine,
      flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
      flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
      flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
      validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
      flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id
)
select 152,'numero_avviso','Numero avviso',true,
       'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.informazioni_aggiuntive.avviso_pagoPA',
       'mif_t_ordinativo_spesa','mif_ord_pagopa_num_avviso',NULL,true,NULL,'2019-01-01',
       ente.ente_proprietario_id,'SIAC-6840',138,NULL,true,tipo.flusso_elab_mif_tipo_id
from siac_t_ente_proprietario ente,  mif_d_flusso_elaborato_tipo tipo
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   not exists
(
select 1 from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and mif.flusso_elab_mif_ordine=152
and mif.flusso_elab_mif_code='numero_avviso'
);

-- spostamento tag
update  mif_d_flusso_elaborato mif
set     flusso_elab_mif_ordine=mif.flusso_elab_mif_ordine+3
from    siac_t_ente_proprietario ente
where  ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and    mif.ente_proprietario_id=ente.ente_proprietario_id
and    mif.flusso_elab_mif_ordine>=150
and    mif.flusso_elab_mif_code !='avviso_pagoPA'
and    mif.flusso_elab_mif_code_padre not like '%avviso_pagoPA%'
and    exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
and exists
(
select 1
from mif_d_flusso_elaborato mif1,mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif1.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif1.flusso_elab_mif_ordine=150
and   mif1.flusso_elab_mif_code !='avviso_pagoPA'
)
and not exists
(
select 1
from mif_d_flusso_elaborato mif1,mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif1.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
--and   mif1.flusso_elab_mif_ordine=150
and   mif1.flusso_elab_mif_code ='avviso_pagoPA'
);

-- inserimento nuova modalita di accredito
insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  accredito_gruppo_id,
  login_operazione,
  ente_proprietario_id,
  validita_inizio
)
select 'APA',
       'AVVISO PAGOPA',
       0,
       gruppo.accredito_gruppo_id,
       'SIAC-6840',
       gruppo.ente_proprietario_id,
       now()
from siac_t_ente_proprietario ente,siac_d_accredito_gruppo gruppo
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   gruppo.ente_proprietario_id=ente.ente_proprietario_id
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo accre
where accre.ente_proprietario_id=ente.ente_proprietario_id
and   accre.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   accre.accredito_tipo_code='APA'
and   accre.accredito_tipo_desc='AVVISO PAGOPA'
and   accre.data_cancellazione is null
and   accre.validita_fine is null
);

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  login_operazione,
  ente_proprietario_id,
  validita_inizio
)
select '22',
       'AVVISO PAGOPA',
       'SIAC-6840',
       ente.ente_proprietario_id,
       now()
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='22'
and   oil.accredito_tipo_oil_desc='AVVISO PAGOPA'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);


insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  login_operazione,
  ente_proprietario_id,
  validita_inizio
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
        'SIAC-6840',
       ente.ente_proprietario_id,
       now()
from siac_t_ente_proprietario ente,
     siac_d_accredito_tipo tipo,
     siac_d_accredito_tipo_oil oil
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.accredito_tipo_code='APA'
and   tipo.accredito_tipo_desc='AVVISO PAGOPA'
and   oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='22'
and   oil.accredito_tipo_oil_desc='AVVISO PAGOPA'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.ente_proprietario_id=ente.ente_proprietario_id
and   r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);


drop function if exists  fnc_mif_ordinativo_spesa_splus 
(
  enteproprietarioid integer,
  nomeente varchar,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  mifordritrasmelabid integer,
  out flussoelabmifdistoilid integer,
  out flussoelabmifid integer,
  out numeroordinativitrasm integer,
  out nomefilemif varchar,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_splus (
  enteproprietarioid integer,
  nomeente varchar,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  mifordritrasmelabid integer,
  out flussoelabmifdistoilid integer,
  out flussoelabmifid integer,
  out numeroordinativitrasm integer,
  out nomefilemif varchar,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 strExecSql VARCHAR(1500):='';

 mifOrdinativoIdRec record;

 mifFlussoOrdinativoRec  mif_t_ordinativo_spesa%rowtype;


 mifFlussoElabMifArr flussoElabMifRecType[];



 mifCountRec integer:=1;
 mifCountTmpRec integer:=1;
 mifAFlussoElabTypeRec  flussoElabMifRecType;
 flussoElabMifElabRec  flussoElabMifRecType;
 mifElabRec record;

 attoAmmRec record;
 enteOilRec record;
 enteProprietarioRec record;
 soggettoRec record;
 soggettoSedeRec record;
 soggettoQuietRec record;
 soggettoQuietRifRec record;
 MDPRec record;
 codAccreRec record;
 bilElemRec record;
 indirizzoRec record;
 ordSostRec record;


 tipoPagamRec record;
 ritenutaRec record;
 ricevutaRec record;
 quoteOrdinativoRec record;
 ordRec record;


 isIndirizzoBenef boolean:=false;
 isIndirizzoBenQuiet boolean:=false;

 flussoElabMifValore varchar (1000):=null;
 flussoElabMifValoreDesc varchar (1000):=null;

 ordNumero numeric:=null;
 ordAnno  integer:=null;
 attoAmmTipoSpr varchar(50):=null;
 attoAmmTipoAll varchar(50):=null;
 attoAmmTipoAllAll varchar(50):=null;

 attoAmmStrTipoRag  varchar(50):=null;
 attoAmmTipoAllRag varchar(50):=null;


 tipoMDPCbi varchar(50):=null;
 tipoMDPCsi varchar(50):=null;
 tipoMDPCo  varchar(50):=null;
 tipoMDPCCP varchar(50):=null;
 tipoMDPCB  varchar(50):=null;
 tipoPaeseCB varchar(50):=null;
 avvisoTipoMDPCo varchar(50):=null;
 codiceCge  varchar(50):=null;
 siopeDef   varchar(50):=null;
 codResult   integer:=null;

 indirizzoEnte varchar(500):=null;
 localitaEnte varchar(500):=null;
 soggettoEnteId INTEGER:=null;
 soggettoRifId integer:=null;
 soggettoSedeSecId integer:=null;
 soggettoQuietId integer:=null;
 soggettoQuietRifId integer:=null;
 accreditoGruppoCode varchar(15):=null;




 flussoElabMifLogId  integer :=null;
 flussoElabMifTipoId integer :=null;
 flussoElabMifTipoNomeFile varchar(500):=null;
 flussoElabMifTipoDec BOOLEAN:=false;
 flussoElabMifOilId integer :=null;
 flussoElabMifDistOilRetId integer:=null;
 mifOrdSpesaId integer:=null;

 dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataFineVal timestamp :=annoBilancio||'-12-31';


 ordImporto numeric :=0;


 ordTipoCodeId integer :=null;
 ordStatoCodeIId  integer :=null;
 ordStatoCodeAId  integer :=null;

 classCdrTipoId INTEGER:=null;
 classCdcTipoId INTEGER:=null;
 ordDetTsTipoId integer :=null;

 ordSedeSecRelazTipoId integer:=null;
 ordRelazCodeTipoId integer :=null;
 ordCsiRelazTipoId  integer:=null;

 noteOrdAttrId integer:=null;

 movgestTsTipoSubId integer:=null;


 famTitSpeMacroAggrCodeId integer:=null;
 titoloUscitaCodeTipoId integer :=null;
 programmaCodeTipoId integer :=null;
 programmaCodeTipo varchar(50):=null;
 famMissProgrCode VARCHAR(50):=null;
 famMissProgrCodeId integer:=null;
 programmaId integer :=null;
 titoloUscitaId integer:=null;



 isPaeseSepa integer:=null;
 ordCodiceBollo  varchar(10):=null;
 ordCodiceBolloDesc varchar(500):=null;
 ordDataScadenza timestamp:=null;

 ordCsiRelazTipo varchar(20):=null;
 ordCsiCOTipo varchar(50):=null;


 ambitoFinId integer:=null;
 anagraficaBenefCBI varchar(500):=null;

 isDefAnnoRedisuo  varchar(5):=null;


 -- ritenute
 tipoRelazRitOrd varchar(10):=null;
 tipoRelazSprOrd varchar(10):=null;
 tipoRelazSubOrd varchar(10):=null;
 tipoRitenuta varchar(10):='R';
 progrRitenuta  varchar(10):=null;
 isRitenutaAttivo boolean:=false;
 tipoOnereIrpefId integer:=null;
 tipoOnereInpsId integer:=null;
 tipoOnereIrpef varchar(10):=null;
 tipoOnereInps varchar(10):=null;

 tipoOnereIrpegId integer:=null;
 tipoOnereIrpeg varchar(10):=null;

 codiceUECodeTipo VARCHAR(50):=null;
 codiceUECodeTipoId integer:=null;
 codiceCofogCodeTipo  VARCHAR(50):=null;
 codiceCofogCodeTipoId integer:=null;
 siopeCodeTipo varchar(50):=null;
 siopeCodeTipoId integer :=null;
 eventoTipoCodeId integer:=null;
 collEventoCodeId integer:=null;

 classifTipoCodeFraz    varchar(50):=null;
 classifTipoCodeFrazVal varchar(50):=null;
 classifTipoCodeFrazId   integer:=null;

 tipoClassFruttifero varchar(100):=null;
 valFruttifero varchar(100):=null;
 valFruttiferoStr varchar(100):=null;
 valFruttiferoStrAltro varchar(100):=null;
 tipoClassFruttiferoId integer:=null;
 valFruttiferoId  integer:=null;

 classVincolatoCode   varchar(100):=null;
 classVincolatoCodeId INTEGER:=null;
 valFruttiferoClassCode   varchar(100):=null;
 valFruttiferoClassCodeId INTEGER:=null;
 valFruttiferoClassCodeSI varchar(100):=null;
 valFruttiferoCodeSI varchar(100):=null;
 valFruttiferoClassCodeNO varchar(100):=null;
 valFruttiferoCodeNO varchar(100):=null;

 cigCausAttrId INTEGER:=null;
 cupCausAttrId INTEGER:=null;
 cigCausAttr   varchar(10):=null;
 cupCausAttr   varchar(10):=null;


 codicePaeseIT varchar(50):=null;
 codiceAccreCB varchar(50):=null;
 codiceAccreCO varchar(50):=null;
 codiceAccreREG varchar(50):=null;
 codiceSepa     varchar(50):=null;
 codiceExtraSepa varchar(50):=null;
 codiceGFB  varchar(50):=null;

 sepaCreditTransfer boolean:=false;
 accreditoGruppoSepaTr varchar(10):=null;
 SepaTr varchar(10):=null;
 paeseSepaTr varchar(10):=null;


 numeroDocs varchar(10):=null;
 tipoDocs varchar(50):=null;
 tipoDocsComm varchar(50):=null;
 tipoGruppoDocs varchar(50):=null;

 tipoEsercizio varchar(50):=null;
 statoBeneficiario boolean :=false;
 bavvioFrazAttr boolean :=false;
 dataAvvioFrazAttr timestamp:=null;
 attrfrazionabile VARCHAR(50):=null;

 dataAvvioSiopeNew VARCHAR(50):=null;
 bAvvioSiopeNew   boolean:=false;


 tipoPagamPostA VARCHAR(100):=null;
 tipoPagamPostB VARCHAR(100):=null;

 cupAttrCodeId INTEGER:=null;
 cupAttrCode   varchar(10):=null;
 cigAttrCodeId INTEGER:=null;
 cigAttrCode   varchar(10):=null;
 ricorrenteCodeTipo varchar(50):=null;
 ricorrenteCodeTipoId integer:=null;

 codiceBolloPlusEsente boolean:=false;
 codiceBolloPlusDesc   varchar(100):=null;

 statoDelegatoCredEff boolean :=false;

 comPccAttrId integer:=null;
 pccOperazTipoId integer:=null;


 -- Transazione elementare
 programmaTbr varchar(50):=null;
 codiceFinVTbr varchar(50):=null;
 codiceEconPatTbr varchar(50):=null;
 cofogTbr varchar(50):=null;
 transazioneUeTbr varchar(50):=null;
 siopeTbr varchar(50):=null;
 cupTbr varchar(50):=null;
 ricorrenteTbr varchar(50):=null;
 aslTbr varchar(50):=null;
 progrRegUnitTbr varchar(50):=null;

 codiceFinVTipoTbrId integer:=null;
 cupAttrId integer:=null;
 ricorrenteTipoTbrId integer:=null;
 aslTipoTbrId integer:=null;
 progrRegUnitTipoTbrId integer:=null;

 codiceFinVCodeTbr varchar(50):=null;
 contoEconCodeTbr varchar(50):=null;
 cofogCodeTbr varchar(50):=null;
 codiceUeCodeTbr varchar(50):=null;
 siopeCodeTbr varchar(50):=null;
 cupAttrTbr varchar(50):=null;
 ricorrenteCodeTbr varchar(50):=null;
 aslCodeTbr  varchar(50):=null;
 progrRegUnitCodeTbr varchar(50):=null;



 isGestioneQuoteOK boolean:=false;
 isGestioneFatture boolean:=false;
 isRicevutaAttivo boolean:=false;
 isTransElemAttiva boolean:=false;
 isMDPCo boolean:=false;
 isOrdPiazzatura boolean:=false;

 docAnalogico    varchar(100):=null;
 titoloCorrente   varchar(100):=null;
 descriTitoloCorrente varchar(100):=null;
 titoloCapitale   varchar(100):=null;
 descriTitoloCapitale varchar(100):=null;

 -- 20.02.2018 Sofia jira siac-5849
 defNaturaPag  varchar(100):=null;

 attrCodeDataScad varchar(100):=null;
 titoloCap  varchar(100):=null;

 isOrdCommerciale boolean:=false;
 -- 20.03.2018 Sofia SIAC-5968
 tipoPdcIVA VARCHAR(100):=null;
 codePdcIVA VARCHAR(100):=null;

 -- 09.09.2019 Sofia SIAC-6840
 isPagoPA boolean:=false;

 NVL_STR               CONSTANT VARCHAR:='';


 ORD_TIPO_CODE_P  CONSTANT  varchar :='P';
 ORD_STATO_CODE_I CONSTANT  varchar :='I';
 ORD_STATO_CODE_A CONSTANT  varchar :='A';
 ORD_RELAZ_CODE_SOS  CONSTANT  varchar :='SOS_ORD';
 ORD_TIPO_A CONSTANT  varchar :='A';

 ORD_RELAZ_SEDE_SEC CONSTANT  varchar :='SEDE_SECONDARIA';
 AMBITO_FIN CONSTANT  varchar :='AMBITO_FIN';

 NOTE_ORD_ATTR CONSTANT  varchar :='NOTE_ORDINATIVO';

 CDC CONSTANT varchar:='CDC';
 CDR CONSTANT varchar:='CDR';


 PROGRAMMA               CONSTANT varchar:='PROGRAMMA';
 TITOLO_SPESA            CONSTANT varchar:='TITOLO_SPESA';
 FAM_TIT_SPE_MACROAGGREG CONSTANT varchar:='Spesa - TitoliMacroaggregati';

 FUNZIONE_CODE_I CONSTANT  varchar :='INSERIMENTO'; -- inserimenti
 FUNZIONE_CODE_S CONSTANT  varchar :='SOSTITUZIONE'; -- sostituzioni senza trasmissione
 FUNZIONE_CODE_N CONSTANT  varchar :='ANNULLO'; -- annullamenti prima di trasmissione

 FUNZIONE_CODE_A CONSTANT  varchar :='ANNULLO'; -- annullamenti dopo trasmissione
 FUNZIONE_CODE_VB CONSTANT  varchar :='VARIAZIONE'; -- spostamenti dopo trasmissione


 ORD_TS_DET_TIPO_A CONSTANT varchar:='A';
 MOVGEST_TS_TIPO_S  CONSTANT varchar:='S';

 SPACE_ASCII CONSTANT integer:=32;
 VT_ASCII CONSTANT integer:=13;
 BS_ASCII CONSTANT integer:=10;

 NUM_SETTE CONSTANT integer:=7;
 NUM_DODICI CONSTANT integer:=12;
 ZERO_PAD CONSTANT  varchar :='0';

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='MANDMIF_SPLUS';


 COM_PCC_ATTR  CONSTANT  varchar :='flagComunicaPCC';
 PCC_OPERAZ_CPAG  CONSTANT varchar:='CP';

 SEPARATORE     CONSTANT  varchar :='|';



 FLUSSO_MIF_ELAB_TEST_COD_ABI_BT      CONSTANT integer:=1;  -- codice_ABI_BT
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA    CONSTANT integer:=4;  -- codice_ente
 FLUSSO_MIF_ELAB_TEST_DESC_ENTE       CONSTANT integer:=5;  -- descrizione_ente
 FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE  CONSTANT integer:=6;  -- codice_istat_ente
 FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE    CONSTANT integer:=7;  -- codice_fiscale_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE CONSTANT integer:=8;  -- codice_tramite_ente
 FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT   CONSTANT integer:=9;  -- codice_tramite_bt
 FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT     CONSTANT integer:=10; -- codice_ente_bt
 FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE CONSTANT integer:=11; -- riferimento_ente
 FLUSSO_MIF_ELAB_TEST_ESERCIZIO       CONSTANT integer:=12; -- riferimento_ente

 FLUSSO_MIF_ELAB_INIZIO_ORD     CONSTANT integer:=13;  -- tipo_operazione

 FLUSSO_MIF_ELAB_FATTURE        CONSTANT integer:=53;  -- fattura_siope_codice_ipa_ente_siope
 FLUSSO_MIF_ELAB_FATT_CODFISC   CONSTANT integer:=58;  -- fattura_siope_codice_fiscale_emittente_siope
 FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG CONSTANT integer:=62; -- data_scadenza_pagam_siope
 FLUSSO_MIF_ELAB_FATT_NATURA_PAG CONSTANT integer:=64; -- natura_spesa_siope
 FLUSSO_MIF_ELAB_NUM_SOSPESO    CONSTANT integer:=122; -- numero_provvisorio
 FLUSSO_MIF_ELAB_RITENUTA       CONSTANT integer:=124; -- importo_ritenuta
 FLUSSO_MIF_ELAB_RITENUTA_PRG   CONSTANT integer:=126; -- progressivo_versante


 REGMOVFIN_STATO_A              CONSTANT varchar:='A';
 SEGNO_ECONOMICO				CONSTANT varchar:='Dare';



BEGIN

	numeroOrdinativiTrasm:=0;
    codiceRisultato:=0;
    messaggioRisultato:='';
	flussoElabMifId:=null;
    nomeFileMif:=null;

    flussoElabMifDistOilId:=null;

	strMessaggioFinale:='Invio ordinativi di spesa SIOPE PLUS.';


    -- enteOilRec
    strMessaggio:='Lettura dati ente OIL  per flusso MIF tipo '||MANDMIF_TIPO||'.';
    select * into strict enteOilRec
    from siac_t_ente_oil ente
    where ente.ente_proprietario_id=enteProprietarioId
    and   ente.data_cancellazione is null
    and   ente.validita_fine is null;

    if enteOilRec is null then
    	raise exception ' Errore in reperimento dati';
    end if;

    if enteOilRec.ente_oil_siope_plus=false then
    	raise exception ' SIOPE PLUS non attivo per l''ente.';
    end if;

    -- inserimento record in tabella mif_t_flusso_elaborato
    strMessaggio:='Inserimento mif_t_flusso_elaborato tipo flusso='||MANDMIF_TIPO||'.';

    insert into mif_t_flusso_elaborato
    (flusso_elab_mif_data ,
     flusso_elab_mif_esito,
     flusso_elab_mif_esito_msg,
     flusso_elab_mif_file_nome,
     flusso_elab_mif_tipo_id,
     flusso_elab_mif_id_flusso_oil, -- da calcolare su tab progressivi
     flusso_elab_mif_codice_flusso_oil, -- da calcolare su tab progressivi
     validita_inizio,
     ente_proprietario_id,
     login_operazione)
     (select dataElaborazione,
             ELAB_MIF_ESITO_IN,
             'Elaborazione in corso per tipo flusso '||MANDMIF_TIPO,
      		 tipo.flusso_elab_mif_nome_file,
     		 tipo.flusso_elab_mif_tipo_id,
     		 null,--flussoElabMifOilId, -- da calcolare su tab progressivi
             null, -- flussoElabMifDistOilId -- da calcolare su tab progressivi
    		 dataElaborazione,
     		 enteProprietarioId,
      		 loginOperazione
      from mif_d_flusso_elaborato_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null
     )
     returning flusso_elab_mif_id into flussoElabMifLogId;-- valore da restituire

      raise notice 'flussoElabMifLogId %',flussoElabMifLogId;

     if flussoElabMifLogId is null then
       RAISE EXCEPTION ' Errore generico in inserimento %.',MANDMIF_TIPO;
     end if;

    strMessaggio:='Verifica esistenza elaborazioni in corso per tipo flusso '||MANDMIF_TIPO||'.';
	codResult:=null;
    select distinct 1 into codResult
    from mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
    where  elab.flusso_elab_mif_id!=flussoElabMifLogId
    and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    and    elab.data_cancellazione is null
    and    elab.validita_fine is null
    and    tipo.flusso_elab_mif_tipo_id=elab.flusso_elab_mif_tipo_id
    and    tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
    and    tipo.ente_proprietario_id=enteProprietarioId
    and    tipo.data_cancellazione is null
    and    tipo.validita_fine is null;

    if codResult is not null then
    	RAISE EXCEPTION ' Verificare situazioni esistenti.';
    end if;

    -- verifico se la tabella degli id contiene dati in tal caso elaborazioni precedenti sono andate male
    strMessaggio:='Verifica esistenza dati in tabella temporanea id [mif_t_ordinativo_spesa_id].';
    codResult:=null;
    select distinct 1 into codResult
    from mif_t_ordinativo_spesa_id mif
    where mif.ente_proprietario_id=enteProprietarioId;

    if codResult is not null then
      RAISE EXCEPTION ' Dati presenti verificarne il contenuto ed effettuare pulizia prima di rieseguire.';
    end if;



    codResult:=null;
    -- recupero indentificativi tipi codice vari
	begin

        -- ordTipoCodeId
        strMessaggio:='Lettura ordinativo tipo Code Id '||ORD_TIPO_CODE_P||'.';
        select ord_tipo.ord_tipo_id into strict ordTipoCodeId
        from siac_d_ordinativo_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_tipo_code=ORD_TIPO_CODE_P
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
   		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));

		-- ordStatoCodeIId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeIId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordStatoCodeAId
        strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_A||'.';
        select ord_tipo.ord_stato_id into strict ordStatoCodeAId
        from siac_d_ordinativo_stato ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_stato_code=ORD_STATO_CODE_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- classCdrTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDR||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

        -- classCdcTipoId
        strMessaggio:='Lettura classif Id per tipo sac='||CDC||'.';
        select tipo.classif_tipo_id into strict classCdrTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


		-- ordDetTsTipoId
        strMessaggio:='Lettura tipo importo ordinativo  Code Id '||ORD_TS_DET_TIPO_A||'.';
        select ord_tipo.ord_ts_det_tipo_id into strict ordDetTsTipoId
        from siac_d_ordinativo_ts_det_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- ordSedeSecRelazTipoId
        strMessaggio:='Lettura relazione sede secondaria  Code Id '||ORD_RELAZ_SEDE_SEC||'.';
        select ord_tipo.relaz_tipo_id into strict ordSedeSecRelazTipoId
        from siac_d_relaz_tipo ord_tipo
        where ord_tipo.ente_proprietario_id=enteProprietarioId
        and   ord_tipo.relaz_tipo_code=ORD_RELAZ_SEDE_SEC
        and   ord_tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
 		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


		-- ordRelazCodeTipoId
        strMessaggio:='Lettura relazione   Code Id '||ORD_RELAZ_CODE_SOS||'.';
		select ord_tipo.relaz_tipo_id into strict ordRelazCodeTipoId
    	from siac_d_relaz_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.relaz_tipo_code=ORD_RELAZ_CODE_SOS
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


        -- movgestTsTipoSubId
        strMessaggio:='Lettura movgest_ts_tipo  '||MOVGEST_TS_TIPO_S||'.';
		select ord_tipo.movgest_ts_tipo_id into strict movgestTsTipoSubId
    	from siac_d_movgest_ts_tipo ord_tipo
		where ord_tipo.ente_proprietario_id=enteProprietarioId
		and   ord_tipo.movgest_ts_tipo_code=MOVGEST_TS_TIPO_S
		and   ord_tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataElaborazione));


    	-- programmaCodeTipoId
        strMessaggio:='Lettura programma_code_tipo_id  '||PROGRAMMA||'.';
		select tipo.classif_tipo_id into strict programmaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=PROGRAMMA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- famTitSpeMacroAggrCodeId
		-- FAM_TIT_SPE_MACROAGGREG='Spesa - TitoliMacroaggregati'
        strMessaggio:='Lettura fam_tit_spe_macroggregati_code_tipo_id  '||FAM_TIT_SPE_MACROAGGREG||'.';
		select fam.classif_fam_tree_id into strict famTitSpeMacroAggrCodeId
        from siac_t_class_fam_tree fam
        where fam.ente_proprietario_id=enteProprietarioId
        and   fam.class_fam_code=FAM_TIT_SPE_MACROAGGREG
        and   fam.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',fam.validita_inizio)
		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(fam.validita_fine,dataElaborazione));


    	-- titoloUscitaCodeTipoId
        strMessaggio:='Lettura titolo_spesa_code_tipo_id  '||TITOLO_SPESA||'.';
		select tipo.classif_tipo_id into strict titoloUscitaCodeTipoId
    	from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code=TITOLO_SPESA
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));

		-- noteOrdAttrId
        strMessaggio:='Lettura noteOrdAttrId per attributo='||NOTE_ORD_ATTR||'.';
		select attr.attr_id into strict  noteOrdAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_ORD_ATTR
        and   attr.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
 	 	and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));


        -- ambitoFinId
        strMessaggio:='Lettura ambito  Code Id '||AMBITO_FIN||'.';
        select a.ambito_id into strict ambitoFinId
        from siac_d_ambito a
        where a.ente_proprietario_id=enteProprietarioId
   		and   a.ambito_code=AMBITO_FIN
        and   a.data_cancellazione is null
        and   a.validita_fine is null;

        -- flussoElabMifTipoId
        strMessaggio:='Lettura tipo flusso MIF  Code Id '||MANDMIF_TIPO||'.';
        select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file, tipo.flusso_elab_mif_tipo_dec
               into strict flussoElabMifTipoId,flussoElabMifTipoNomeFile, flussoElabMifTipoDec
        from mif_d_flusso_elaborato_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
   		and   tipo.flusso_elab_mif_tipo_code=MANDMIF_TIPO
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        -- raise notice 'flussoElabMifTipoId %',flussoElabMifTipoId;
        -- mifFlussoElabTypeRec


        strMessaggio:='Lettura flusso struttura MIF  per tipo '||MANDMIF_TIPO||'.';
        for mifElabRec IN
        (select m.*
         from mif_d_flusso_elaborato m
         where m.flusso_elab_mif_tipo_id=flussoElabMifTipoId
         and   m.flusso_elab_mif_elab=true
         order by m.flusso_elab_mif_ordine_elab
        )
        loop
        	mifAFlussoElabTypeRec.flussoElabMifId :=mifElabRec.flusso_elab_mif_id;
            mifAFlussoElabTypeRec.flussoElabMifAttivo :=mifElabRec.flusso_elab_mif_attivo;
            mifAFlussoElabTypeRec.flussoElabMifDef :=mifElabRec.flusso_elab_mif_default;
            mifAFlussoElabTypeRec.flussoElabMifElab :=mifElabRec.flusso_elab_mif_elab;
            mifAFlussoElabTypeRec.flussoElabMifParam :=mifElabRec.flusso_elab_mif_param;

            mifAFlussoElabTypeRec.flusso_elab_mif_ordine_elab :=mifElabRec.flusso_elab_mif_ordine_elab;
            mifAFlussoElabTypeRec.flusso_elab_mif_ordine :=mifElabRec.flusso_elab_mif_ordine;
            mifAFlussoElabTypeRec.flusso_elab_mif_code :=mifElabRec.flusso_elab_mif_code;
            mifAFlussoElabTypeRec.flusso_elab_mif_campo :=mifElabRec.flusso_elab_mif_campo;

            mifFlussoElabMifArr[mifElabRec.flusso_elab_mif_ordine_elab]:=mifAFlussoElabTypeRec;

        end loop;



		-- Gestione registroPcc per enti che non gestiscono quitanze
        -- Nota : capire se necessario gestire PCC
		/*if enteOilRec.ente_oil_quiet_ord=false then

  			-- comPccAttrId
	        strMessaggio:='Lettura comPccAttrId per attributo='||COM_PCC_ATTR||'.';
			select attr.attr_id into strict  comPccAttrId
	        from siac_t_attr attr
	        where attr.ente_proprietario_id=enteProprietarioId
	        and   attr.attr_code=COM_PCC_ATTR
	        and   attr.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
   	 	    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attr.validita_fine,dataElaborazione));

            strMessaggio:='Lettura Id tipo operazine PCC='||PCC_OPERAZ_CPAG||'.';
			select pcc.pccop_tipo_id into strict pccOperazTipoId
		    from siac_d_pcc_operazione_tipo pcc
		    where pcc.ente_proprietario_id=enteProprietarioId
		    and   pcc.pccop_tipo_code=PCC_OPERAZ_CPAG;


        end if;*/

        -- enteProprietarioRec
        strMessaggio:='Lettura dati ente proprietario per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select * into strict enteProprietarioRec
        from siac_t_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
	    and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        -- soggettoEnteId
        strMessaggio:='Lettura indirizzo ente proprietario [siac_r_soggetto_ente_proprietario] per flusso MIF tipo '||MANDMIF_TIPO||'.';
        select ente.soggetto_id into soggettoEnteId
        from siac_r_soggetto_ente_proprietario ente
        where ente.ente_proprietario_id=enteProprietarioId
        and   ente.data_cancellazione is null
        and   ente.validita_fine is null;

        if soggettoEnteId is not null then
            strMessaggio:='Lettura indirizzo ente proprietario [siac_t_indirizzo_soggetto] per flusso MIF tipo '||MANDMIF_TIPO||'.';

        	select viaTipo.via_tipo_code||' '||indir.toponimo||' '||indir.numero_civico,
        		   com.comune_desc
                   into indirizzoEnte,localitaEnte
            from siac_t_indirizzo_soggetto indir,
                 siac_t_comune com,
                 siac_d_via_tipo viaTipo
            where indir.soggetto_id=soggettoEnteId
            and   indir.principale='S'
            and   indir.data_cancellazione is null
            and   indir.validita_fine is null
            and   com.comune_id=indir.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null
            and   viaTipo.via_tipo_id=indir.via_tipo_id
            and   viaTipo.data_cancellazione is null
	   		and   date_trunc('day',dataElaborazione)>=date_trunc('day',viaTipo.validita_inizio)
 			and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(viaTipo.validita_fine,dataElaborazione))
            order by indir.indirizzo_id;
        end if;

        -- Calcolo progressivo "distinta" per flusso MANDMIF
	    -- calcolo su progressivi di flussoElabMifDistOilId flussoOIL univoco per tipo flusso
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifDistOilRetId -- 25.05.2016 Sofia - JIRA-3619
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifDistOilRetId is null then -- 25.05.2016 Sofia - JIRA-3619
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_'||MANDMIF_TIPO||'_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifDistOilRetId:=0;
            end if;
        end if;

        if flussoElabMifDistOilRetId is not null then
	        flussoElabMifDistOilRetId:=flussoElabMifDistOilRetId+1;
        end if;

	    -- calcolo su progressivo di flussoElabMifOilId flussoOIL univoco
        strMessaggio:='Lettura progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        codResult:=null;
        select prog.prog_value into flussoElabMifOilId
        from siac_t_progressivo prog
        where prog.ente_proprietario_id=enteProprietarioId
        and   prog.prog_key='oil_out_'||annoBilancio
        and   prog.ambito_id=ambitoFinId
        and   prog.data_cancellazione is null
        and   prog.validita_fine is null;

        if flussoElabMifOilId is null then
			strMessaggio:='Inserimento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
        	insert into siac_t_progressivo
            (prog_key,
             prog_value,
			 ambito_id,
		     validita_inizio,
			 ente_proprietario_id,
			 login_operazione
            )
            values
            ('oil_out_'||annoBilancio,1,ambitoFinId,now(),enteProprietarioId,loginOperazione)
            returning prog_id into codResult;

            if codResult is null then
            	RAISE EXCEPTION ' Progressivo non inserito.';
            else
            	flussoElabMifOilId:=0;
            end if;
        end if;

        if flussoElabMifOilId is not null then
	        flussoElabMifOilId:=flussoElabMifOilId+1;
        end if;

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
        when TOO_MANY_ROWS THEN
            RAISE EXCEPTION ' Diverse righe presenti in archivio.';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;




    --- popolamento mif_t_ordinativo_spesa_id


    -- ordinativi emessi o emessi/spostati non ancora mai trasmessi codice_funzione='I' -- INSERIMENTO
    strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_I||'.';

    insert into mif_t_ordinativo_spesa_id
    (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
     mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
     mif_ord_soggetto_id, mif_ord_modpag_id,
     mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
     mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
     mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
     mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
     mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
     mif_ord_login_creazione,mif_ord_login_modifica,
     ente_proprietario_id, login_operazione)
    (
     with
     ritrasm as
     (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	  from mif_t_ordinativo_ritrasmesso r
	  where mifOrdRitrasmElabId is not null
	  and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	  and   r.ente_proprietario_id=enteProprietarioId
	  and   r.data_cancellazione is null),
     ordinativi as
     (
      select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_I mif_ord_codice_funzione,
             bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
             ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
             extract('year' from ord.ord_emissione_data)||'-'||
             lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
             lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione , 0 mif_ord_ord_anno_movg,
             0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id, elem.elem_id mif_ord_elem_id,
             0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
             ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
             ord.comm_tipo_id mif_ord_comm_tipo_id,ord.notetes_id mif_ord_notetes_id, ord.ord_desc mif_ord_desc,
             ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
             ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
             ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
             enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
      from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,siac_t_bil bil, siac_t_periodo per,siac_r_ordinativo_bil_elem elem
      where  bil.ente_proprietario_id=enteProprietarioId
        and  per.periodo_id=bil.periodo_id
        and  per.anno::integer <=annoBilancio::integer
        and  ord.bil_id=bil.bil_id
        and  ord.ord_tipo_id=ordTipoCodeId
        and  ord_stato.ord_id=ord.ord_id
        and  ord_stato.data_cancellazione is null
	    and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	    and  ord_stato.validita_fine is null
        and  ord_stato.ord_stato_id=ordStatoCodeIId
        and  ord.ord_trasm_oil_data is null
        and  ord.ord_emissione_data<=dataElaborazione
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
        and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
        and  elem.ord_id=ord.ord_id
        and  elem.data_cancellazione is null
        and  not exists (select 1 from siac_r_ordinativo rord
                          where rord.ord_id_a=ord.ord_id
                          and   rord.data_cancellazione is null
                          and   rord.validita_fine is null
			              and   rord.relaz_tipo_id=ordRelazCodeTipoId)
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
       );


      -- ordinativi emessi o emessi/spostati non ancora mai trasmessi, sostituzione di altro ordinativo codice_funzione='S' -- 'SOSPENSIONE'
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_S||'.';

      insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
 	   mif_ord_soggetto_id, mif_ord_modpag_id,
 	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id, mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_S mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id ,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,ord.notetes_id mif_ord_notetes_id,
               ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione, ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem,siac_r_ordinativo rord
  	    where  bil.ente_proprietario_id=enteProprietarioId
   		  and  per.periodo_id=bil.periodo_id
    	  and  per.anno::integer <=annoBilancio::integer
      	  and  ord.bil_id=bil.bil_id
     	  and  ord.ord_tipo_id=ordTipoCodeId
    	  and  ord_stato.ord_id=ord.ord_id
    	  and  ord_stato.data_cancellazione is null
	   	  and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	      and  ord_stato.validita_fine is null
    	  and  ord_stato.ord_stato_id=ordStatoCodeIId
	      and  ord.ord_trasm_oil_data is null
    	  and  ord.ord_emissione_data<=dataElaborazione
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
          and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
    	  and  elem.ord_id=ord.ord_id
    	  and  elem.data_cancellazione is null
          and  elem.validita_fine is null
          and  rord.ord_id_a=ord.ord_id
          and  rord.relaz_tipo_id=ordRelazCodeTipoId
          and  rord.data_cancellazione is null
          and  rord.validita_fine is null
        )
        select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id, o.login_operazione
        from ordinativi o
	    where mifOrdRitrasmElabId is null
		   or (mifOrdRitrasmElabId is not null and exists
              (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );

      -- ordinativi emessi e annullati mai trasmessi codice_funzione='N' -- ANNULLO
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_N||'.';

	  insert into mif_t_ordinativo_spesa_id
	  (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
	   mif_ord_soggetto_id, mif_ord_modpag_id,
	   mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
 	   mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
	  (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_N mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
      	 	   ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,
               ord.codbollo_id mif_ord_codbollo_id,ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
  	    from siac_t_ordinativo ord, siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord_stato.ord_id=ord.ord_id
         and  ord_stato.validita_inizio<=dataElaborazione -- questa e'' la data di annullamento
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord_stato.data_cancellazione is null
         and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	     and  ord_stato.validita_fine is null
         and  ord_stato.ord_stato_id=ordStatoCodeAId
         and  ord.ord_trasm_oil_data is null
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
         and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
       ),
       -- 23.03.2018 Sofia SIAC-5969
       ordSos as
       (
          select rord.ord_id_da, rord.ord_id_a
          from siac_r_ordinativo rOrd
          where rOrd.ente_proprietario_id=enteProprietarioId
          and   rOrd.relaz_tipo_id=ordRelazCodeTipoId
          and   rOrd.data_cancellazione is null
          and   rOrd.validita_fine is null
       ),
       -- 16.04.2018 Sofia siac-6067
       enteOil as
       (
       select false esclAnnull
       from siac_t_ente_oil oil
       where oil.ente_proprietario_id=enteProprietarioId
       and   oil.ente_oil_invio_escl_annulli=false
       )
       select  o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o, enteOil  -- 16.04.2018 Sofia siac-6067
/*	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))*/
	   where
        -- 23.03.2018 Sofia SIAC-5969
        ( mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
        )
        and  enteOil.esclAnnull=false -- 16.04.2018 Sofia siac-6067
        -- 23.03.2018 Sofia SIAC-5969 : devono essere escludi ordinativi
        -- sostituiti e sostituti
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_da=o.mif_ord_ord_id)
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_a=o.mif_ord_ord_id)
	   );

      -- ordinativi emessi tramessi e poi annullati, anche dopo spostamento  codice_funzione='A' -- ANNULLO
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_A||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id,mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_A mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_r_ordinativo_stato ord_stato,
             siac_t_bil bil, siac_t_periodo per,
             siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
          and  per.periodo_id=bil.periodo_id
          and  per.anno::integer <=annoBilancio::integer
          and  ord.bil_id=bil.bil_id
          and  ord.ord_tipo_id=ordTipoCodeId
   		  and  ord_stato.ord_id=ord.ord_id
  		  and  ord.ord_emissione_data<=dataElaborazione
          and  ord_stato.validita_inizio<=dataElaborazione  -- questa e'' la data di annullamento
  		  and  ord.ord_trasm_oil_data is not null
 		  and  ord.ord_trasm_oil_data<ord_stato.validita_inizio
          and  ord_stato.data_cancellazione is null
          and  date_trunc('day',dataElaborazione)>=date_trunc('day',ord_stato.validita_inizio)
  	      and  ord_stato.validita_fine is null
          and  ord_stato.ord_stato_id=ordStatoCodeAId
--          and  ( ord.ord_spostamento_data is null or ord.ord_spostamento_data<ord_stato.validita_inizio)
          and  ( ord.ord_spostamento_data is null or date_trunc('DAY',ord.ord_spostamento_data)<=date_trunc('DAY',ord_stato.validita_inizio)) -- 30.07.2019 Sofia siac-6950
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
          and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
          and  elem.ord_id=ord.ord_id
          and  elem.data_cancellazione is null
          and  elem.validita_fine is null
        ),
        -- 23.03.2018 Sofia SIAC-5969
        ordSos as
        (
          select rord.ord_id_da, rord.ord_id_a
          from siac_r_ordinativo rOrd
          where rOrd.ente_proprietario_id=enteProprietarioId
          and   rOrd.relaz_tipo_id=ordRelazCodeTipoId
          and   rOrd.data_cancellazione is null
          and   rOrd.validita_fine is null
        )
        select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
        from ordinativi o
        -- 23.03.2018 Sofia SIAC-5969
/*	    where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))*/
	    where
        ( mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
        )
        -- 23.03.2018 Sofia SIAC-5969 : devono essere escludi ordinativi
        -- sostituiti e sostituti
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_da=o.mif_ord_ord_id)
        and
        not exists
        (select 1 from ordSos where ordSos.ord_id_a=o.mif_ord_ord_id)
       );

      -- ordinativi emessi , trasmessi  e poi spostati codice_funzione='VB' ( mai annullati ) _--- VARIAZIONE
      strMessaggio:='Inserimento dati in tabella temporanea id [mif_t_ordinativo_spesa_id].Codice funzione='||FUNZIONE_CODE_VB||'.';

      insert into mif_t_ordinativo_spesa_id
      (mif_ord_ord_id, mif_ord_codice_funzione, mif_ord_bil_id, mif_ord_periodo_id,mif_ord_anno_bil,
       mif_ord_ord_anno,mif_ord_ord_numero,mif_ord_data_emissione,mif_ord_ord_anno_movg,
       mif_ord_soggetto_id, mif_ord_modpag_id,
       mif_ord_subord_id ,mif_ord_elem_id, mif_ord_movgest_id, mif_ord_movgest_ts_id,
       mif_ord_liq_id, mif_ord_atto_amm_id, mif_ord_contotes_id,mif_ord_dist_id,
       mif_ord_codbollo_id,mif_ord_comm_tipo_id,mif_ord_notetes_id,mif_ord_desc,
       mif_ord_cast_cassa,mif_ord_cast_competenza,mif_ord_cast_emessi,
       mif_ord_siope_tipo_debito_id,mif_ord_siope_assenza_motivazione_id,
       mif_ord_login_creazione,mif_ord_login_modifica,
       ente_proprietario_id, login_operazione)
      (
       with
       ritrasm as
       (select r.mif_ord_id, r.mif_ord_ritrasm_elab_id
	    from mif_t_ordinativo_ritrasmesso r
	    where mifOrdRitrasmElabId is not null
	    and   r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId
	    and   r.ente_proprietario_id=enteProprietarioId
	    and   r.data_cancellazione is null),
       ordinativi as
       (select ord.ord_id mif_ord_ord_id, FUNZIONE_CODE_VB mif_ord_codice_funzione,
               bil.bil_id mif_ord_bil_id,per.periodo_id mif_ord_periodo_id,per.anno::integer mif_ord_anno_bil,
               ord.ord_anno mif_ord_ord_anno,ord.ord_numero mif_ord_ord_numero,
               extract('year' from ord.ord_emissione_data)||'-'||
               lpad(extract('month' from ord.ord_emissione_data)::varchar,2,'0')||'-'||
               lpad(extract('day' from ord.ord_emissione_data)::varchar,2,'0') mif_ord_data_emissione,
               0 mif_ord_ord_anno_movg,
               0 mif_ord_soggetto_id,0 mif_ord_modpag_id,0 mif_ord_subord_id,
               elem.elem_id mif_ord_elem_id,
               0 mif_ord_movgest_id,0 mif_ord_movgest_ts_id,0 mif_ord_liq_id,0 mif_ord_atto_amm_id,
               ord.contotes_id mif_ord_contotes_id,ord.dist_id mif_ord_dist_id,ord.codbollo_id mif_ord_codbollo_id,
               ord.comm_tipo_id mif_ord_comm_tipo_id,
               ord.notetes_id mif_ord_notetes_id,ord.ord_desc mif_ord_desc,
               ord.ord_cast_cassa mif_ord_cast_cassa,ord.ord_cast_competenza mif_ord_cast_competenza,ord.ord_cast_emessi mif_ord_cast_emessi,
               ord.siope_tipo_debito_id,ord.siope_assenza_motivazione_id,
               ord.login_creazione mif_ord_login_creazione,ord.login_modifica mif_ord_login_modifica,
               enteProprietarioId ente_proprietario_id,loginOperazione login_operazione
        from siac_t_ordinativo ord,siac_t_bil bil, siac_t_periodo per, siac_r_ordinativo_bil_elem elem
        where  bil.ente_proprietario_id=enteProprietarioId
         and  per.periodo_id=bil.periodo_id
         and  per.anno::integer <=annoBilancio::integer
         and  ord.bil_id=bil.bil_id
         and  ord.ord_tipo_id=ordTipoCodeId
         and  ord.ord_emissione_data<=dataElaborazione
         and  ord.ord_trasm_oil_data is not null
         and  ord.ord_spostamento_data is not null
--         and  ord.ord_trasm_oil_data<ord.ord_spostamento_data -- 30.07.2019 Sofia siac-6950
         and  date_trunc('DAY',ord.ord_trasm_oil_data)<=date_trunc('DAY',ord.ord_spostamento_data) -- 30.07.2019 Sofia siac-6950
         and  ord.ord_spostamento_data<=dataElaborazione
--  06.07.2018 Sofia jira siac-6307
--  scommentato per siac-6175
         and  ord.ord_da_trasmettere=true -- 19.06.2017 Sofia siac-6175
         and  not exists (select 1 from siac_r_ordinativo_stato ord_stato
  				          where  ord_stato.ord_id=ord.ord_id
					        and  ord_stato.ord_stato_id=ordStatoCodeAId
                            and  ord_stato.data_cancellazione is null)
         and  elem.ord_id=ord.ord_id
         and  elem.data_cancellazione is null
         and  elem.validita_fine is null
        )
       select o.mif_ord_ord_id, o.mif_ord_codice_funzione, o.mif_ord_bil_id, o.mif_ord_periodo_id,o.mif_ord_anno_bil,
		       o.mif_ord_ord_anno,o.mif_ord_ord_numero,o.mif_ord_data_emissione,o.mif_ord_ord_anno_movg,
     		   o.mif_ord_soggetto_id, o.mif_ord_modpag_id,
               o.mif_ord_subord_id ,o.mif_ord_elem_id, o.mif_ord_movgest_id, o.mif_ord_movgest_ts_id,
               o.mif_ord_liq_id, o.mif_ord_atto_amm_id, o.mif_ord_contotes_id,o.mif_ord_dist_id,
               o.mif_ord_codbollo_id,o.mif_ord_comm_tipo_id,o.mif_ord_notetes_id,o.mif_ord_desc,
               o.mif_ord_cast_cassa,o.mif_ord_cast_competenza,o.mif_ord_cast_emessi,
               o.siope_tipo_debito_id,o.siope_assenza_motivazione_id,
               o.mif_ord_login_creazione,o.mif_ord_login_modifica,
               o.ente_proprietario_id , o.login_operazione
       from ordinativi o
	   where mifOrdRitrasmElabId is null
		  or (mifOrdRitrasmElabId is not null and exists
             (select 1 from ritrasm r where r.mif_ord_ritrasm_elab_id=mifOrdRitrasmElabId and r.mif_ord_id=o.mif_ord_ord_id))
      );
      -- aggiornamento mif_t_ordinativo_spesa_id per id


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per fase_operativa_code.';
      update mif_t_ordinativo_spesa_id m
      set mif_ord_bil_fase_ope=(select fase.fase_operativa_code from siac_r_bil_fase_operativa rFase, siac_d_fase_operativa fase
      							where rFase.bil_id=m.mif_ord_bil_id
                                and   rFase.data_cancellazione is null
                                and   rFase.validita_fine is null
                                and   fase.fase_operativa_id=rFase.fase_operativa_id
                                and   fase.data_cancellazione is null
                                and   fase.validita_fine is null);


      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per soggetto_id.';
      -- soggetto_id

      update mif_t_ordinativo_spesa_id m
      set mif_ord_soggetto_id=coalesce(s.soggetto_id,0)
      from siac_r_ordinativo_soggetto s
      where s.ord_id=m.mif_ord_ord_id
      and s.data_cancellazione is null
      and s.validita_fine is null;

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id.';

      -- modpag_id
      update mif_t_ordinativo_spesa_id m set  mif_ord_modpag_id=coalesce(s.modpag_id,0)
      from siac_r_ordinativo_modpag s
      where s.ord_id=m.mif_ord_ord_id
   	  and s.modpag_id is not null
      and s.data_cancellazione is null
      and s.validita_fine is null;

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per modpag_id [CSI].';
      update mif_t_ordinativo_spesa_id m set mif_ord_modpag_id=coalesce(rel.modpag_id,0)
      from siac_r_ordinativo_modpag s, siac_r_soggrel_modpag rel
      where s.ord_id=m.mif_ord_ord_id
      and s.soggetto_relaz_id is not null
      and rel.soggetto_relaz_id=s.soggetto_relaz_id
      and s.data_cancellazione is null
      and s.validita_fine is null
      and rel.data_cancellazione is null
      --  and rel.validita_fine is null
      -- 04.04.2018 Sofia SIAC-6064
      and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(rel.validita_fine,dataElaborazione))
      and exists  (select  1 from siac_r_soggrel_modpag rel1
                   where    rel.soggetto_relaz_id=s.soggetto_relaz_id
		           and      rel1.soggrelmpag_id=rel.soggrelmpag_id
         		   order by rel1.modpag_id
			       limit 1);

      strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per subord_id.';

      -- subord_id
      update mif_t_ordinativo_spesa_id m
      set mif_ord_subord_id =
                             (select s.ord_ts_id from siac_t_ordinativo_ts s
                               where s.ord_id=m.mif_ord_ord_id
                                 and s.data_cancellazione is null
                                 and s.validita_fine is null
                               order by s.ord_ts_id
                               limit 1);

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per liq_id.';

	 -- liq_id
	 update mif_t_ordinativo_spesa_id m
	 set mif_ord_liq_id = (select s.liq_id from siac_r_liquidazione_ord s
                            where s.sord_id = m.mif_ord_subord_id
                              and s.data_cancellazione is null
                              and s.validita_fine is null);
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_ts_id.';

     -- movgest_ts_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_ts_id = (select s.movgest_ts_id from siac_r_liquidazione_movgest s
                                   where s.liq_id = m.mif_ord_liq_id
                                     and s.data_cancellazione is null
                                     and s.validita_fine is null);
     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_id
     update mif_t_ordinativo_spesa_id m
     set mif_ord_movgest_id = (select s.movgest_id from siac_t_movgest_ts s
                               where  s.movgest_ts_id = m.mif_ord_movgest_ts_id
                               and s.data_cancellazione is null
                               and s.validita_fine is null);

     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per movgest_id.';

     -- movgest_anno
     update mif_t_ordinativo_spesa_id m
     set mif_ord_ord_anno_movg = (select s.movgest_anno from siac_t_movgest s
                              	  where  s.movgest_id = m.mif_ord_movgest_id
                             	  and s.data_cancellazione is null
                                  and s.validita_fine is null);


     strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id.';

    -- attoamm_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_id = (select s.attoamm_id from siac_r_liquidazione_atto_amm s
                                where s.liq_id = m.mif_ord_liq_id
                                  and s.data_cancellazione is null
                                  and s.validita_fine is null);

    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per attoamm_id movgest_ts.';
	-- attoamm_movgest_ts_id
    update mif_t_ordinativo_spesa_id m
    set mif_ord_atto_amm_movg_id = (select s.attoamm_id from siac_r_movgest_ts_atto_amm s
                                    where s.movgest_ts_id = m.mif_ord_movgest_ts_id
                                    and s.data_cancellazione is null
                                    and s.validita_fine is null);

	-- mif_ord_programma_id
    -- mif_ord_programma_code
    -- mif_ord_programma_desc
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_programma_id mif_ord_programma_code mif_ord_programma_desc.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_programma_id,mif_ord_programma_code,mif_ord_programma_desc) = (class.classif_id,class.classif_code,class.classif_desc) -- 11.01.2016 Sofia
    from siac_r_bil_elem_class classElem, siac_t_class class
    where classElem.elem_id=m.mif_ord_elem_id
    and   class.classif_id=classElem.classif_id
    and   class.classif_tipo_id=programmaCodeTipoId
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
    and   class.data_cancellazione is null;

	-- mif_ord_titolo_id
    -- mif_ord_titolo_code
    strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_titolo_id mif_ord_titolo_code.';
    update mif_t_ordinativo_spesa_id m
    set (mif_ord_titolo_id, mif_ord_titolo_code) = (cp.classif_id,cp.classif_code)
	from siac_r_bil_elem_class classElem, siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
	where classElem.elem_id=m.mif_ord_elem_id
    and   cf.classif_id=classElem.classif_id
    and   cf.data_cancellazione is null
    and   classElem.data_cancellazione is null
    and   classElem.validita_fine is null
	and   r.classif_id=cf.classif_id
	and   r.classif_id_padre is not null
	and   r.classif_fam_tree_id=famTitSpeMacroAggrCodeId
    and   r.data_cancellazione is null
    and   r.validita_fine is null
	and   cp.classif_id=r.classif_id_padre
    and   cp.data_cancellazione is null;






	-- mif_ord_note_attr_id
	strMessaggio:='Aggiornamento dati in tabella temporanea id [mif_t_ordinativo_spesa_id] per mif_ord_note_attr_id.';
	update mif_t_ordinativo_spesa_id m
    set mif_ord_note_attr_id= attr.ord_attr_id
    from siac_r_ordinativo_attr attr
    where attr.ord_id=m.mif_ord_ord_id
    and   attr.attr_id=noteOrdAttrId
    and   attr.data_cancellazione is null
    and   attr.validita_fine is null;


    strMessaggio:='Verifica esistenza ordinativi di spesa da trasmettere.';
    codResult:=null;
    select 1 into codResult
    from mif_t_ordinativo_spesa_id where ente_proprietario_id=enteProprietarioId;

    if codResult is null then
      codResult:=-12;
      RAISE EXCEPTION ' Nessun ordinativo di spesa da trasmettere.';
    end if;


    -- <ritenute>
    flussoElabMifElabRec:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_RITENUTA];

    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                   ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
  					tipoRelazRitOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	                tipoRelazSprOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
	                tipoRelazSubOrd:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    tipoOnereIrpef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                    tipoOnereInps:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                    tipoOnereIrpeg:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));


                    if tipoRelazRitOrd is null or tipoRelazSprOrd is null or tipoRelazSubOrd is null
                       or tipoOnereInps is null or tipoOnereIrpef is null
                       or tipoOnereIrpeg is null then
                       RAISE EXCEPTION ' Dati configurazione ritenute non completi.';
                    end if;
                    isRitenutaAttivo:=true;
            end if;
	    else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   	end if;
   end if;

   if isRitenutaAttivo=true then
     	flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_RITENUTA_PRG];
         strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   	 if flussoElabMifElabRec.flussoElabMifId is null then
  			  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   	 end if;
    	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	progrRitenuta:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
	    	else
				RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	   		end if;
	     else
    	   isRitenutaAttivo:=false;
		 end if;
   end if;

   if isRitenutaAttivo=true then
           strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereIrpef
                       ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereIrpefId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereIrpef
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
   		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

           if tipoOnereIrpefId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;

           strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereInps
                       ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereInpsId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereInps
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereInpsId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;

		   strMessaggio:='Lettura dati identificativo tipo Onere '||tipoOnereIrpeg
                        ||' sezione ritenute - tipo flusso '||MANDMIF_TIPO||'.';

           select tipo.onere_tipo_id into tipoOnereIrpegId
           from siac_d_onere_tipo tipo
           where tipo.ente_proprietario_id=enteProprietarioId
           and   tipo.onere_tipo_code=tipoOnereIrpeg
           and   tipo.data_cancellazione is null
 	  	   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));


           if tipoOnereIrpegId is null then
            	RAISE EXCEPTION ' Dato non reperito.';
           end if;
   end if;


   -- <sospesi>
   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
   flussoElabMifElabRec:=null;
   flussoElabMifElabRec:=mifFlussoElabMifArr[FLUSSO_MIF_ELAB_NUM_SOSPESO];
   mifCountRec:=FLUSSO_MIF_ELAB_NUM_SOSPESO;
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  	  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
			null;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
   		end if;
        isRicevutaAttivo:=true;
   end if;




   flussoElabMifElabRec:=null;
   mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
   strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
   end if;
   if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    numeroDocs:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            tipoGruppoDocs  :=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            if numeroDocs is not null and numeroDocs!='' and
               tipoDocs is not null and tipoDocs!='' and
               tipoGruppoDocs is not null and tipoGruppoDocs!='' then
                tipoDocs:=tipoDocs||'|'||tipoGruppoDocs;
            	isGestioneFatture:=true;
            end if;
		end if;
    else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
    end if;
   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_CODFISC;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
 		    docAnalogico:=flussoElabMifElabRec.flussoElabMifParam;
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then
    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_DATASCAD_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            attrCodeDataScad:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
		end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   if isGestioneFatture=true then

    flussoElabMifElabRec:=null;
    mifCountRec:=FLUSSO_MIF_ELAB_FATT_NATURA_PAG;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                 ||' mifCountRec='||mifCountRec
                 ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	 if flussoElabMifElabRec.flussoElabMifElab=true then
        -- 20.02.2018 Sofia JIRA siac-5849
        /*
    	if flussoElabMifElabRec.flussoElabMifParam is not null  then
            titoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            descriTitoloCorrente:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            titoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
            descriTitoloCapitale:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));

		end if;*/

        -- 20.02.2018 Sofia JIRA siac-5849
        if flussoElabMifElabRec.flussoElabMifDef is not null then
        	defNaturaPag:=flussoElabMifElabRec.flussoElabMifDef;
        end if;
     else
    	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     end if;
    end if;

   end if;

   --- lettura mif_t_ordinativo_spesa_id per popolamento mif_t_ordinativo_spesa
   codResult:=null;
   strMessaggio:='Lettura ordinativi di spesa da migrare [mif_t_ordinativo_spesa_id].Inizio ciclo.';
   for mifOrdinativoIdRec IN
   (select ms.*
     from mif_t_ordinativo_spesa_id ms
     where ms.ente_proprietario_id=enteProprietarioId
     order by ms.mif_ord_anno_bil,
              ms.mif_ord_ord_numero
   )
   loop


		mifFlussoOrdinativoRec:=null;
		MDPRec:=null;
        codAccreRec:=null;
		bilElemRec:=null;
        soggettoRec:=null;
        soggettoSedeRec:=null;
        soggettoRifId:=null;
        soggettoSedeSecId:=null;
		indirizzoRec:=null;
        mifOrdSpesaId:=null;




        isIndirizzoBenef:=true;
        isIndirizzoBenQuiet:=true;


        bavvioFrazAttr:=false;
        bAvvioSiopeNew:=false;


	    statoBeneficiario:=false;
		statoDelegatoCredEff:=false;

        -- lettura importo ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura importo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        mifFlussoOrdinativoRec.mif_ord_importo:=fnc_mif_importo_ordinativo(mifOrdinativoIdRec.mif_ord_ord_id,ordDetTsTipoId,
        													  		       flussoElabMifTipoDec);
        if flussoElabMifTipoDec=true and
           coalesce(position('.' in mifFlussoOrdinativoRec.mif_ord_importo),0)=0 then
           mifFlussoOrdinativoRec.mif_ord_importo:=mifFlussoOrdinativoRec.mif_ord_importo||'.00';
        end if;

        -- lettura MDP ti ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura MDP ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

		select * into MDPRec
        from siac_t_modpag mdp
        where mdp.modpag_id=mifOrdinativoIdRec.mif_ord_modpag_id;
        if MDPRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_modpag.';
        end if;

        -- lettura accreditoTipo ti ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura accredito tipo ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        select tipo.accredito_tipo_id, tipo.accredito_tipo_code,tipo.accredito_tipo_desc,
               gruppo.accredito_gruppo_id, gruppo.accredito_gruppo_code
               into codAccreRec
        from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
        where tipo.accredito_tipo_id=MDPRec.accredito_tipo_id
          and tipo.data_cancellazione is null
          and date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		  and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
          and gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id;
        if codAccreRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_d_accredito_tipo siac_d_accredito_gruppo.';
        end if;


        -- lettura dati soggetto ordinativo
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati soggetto [siac_r_soggetto_relaz] ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';
        select rel.soggetto_id_da into soggettoRifId
        from  siac_r_soggetto_relaz rel
        where rel.soggetto_id_a=mifOrdinativoIdRec.mif_ord_soggetto_id
        and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
        and   rel.ente_proprietario_id=enteProprietarioId
        and   rel.data_cancellazione is null
		and   rel.validita_fine is null;

        if soggettoRifId is null then
	        soggettoRifId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        else
        	soggettoSedeSecId:=mifOrdinativoIdRec.mif_ord_soggetto_id;
        end if;

        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati soggetto di riferimento ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

        select * into soggettoRec
   	    from siac_t_soggetto sogg
       	where sogg.soggetto_id=soggettoRifId;

        if soggettoRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id= %].',soggettoRifId;
        end if;

        if soggettoSedeSecId is not null then
	        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati sede sec. soggetto di riferimento ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

            select * into soggettoSedeRec
   		    from siac_t_soggetto sogg
	       	where sogg.soggetto_id=soggettoSedeSecId;

	        if soggettoSedeRec is null then
    	    	RAISE EXCEPTION ' Errore in lettura siac_t_soggetto [soggetto_id=%]',soggettoSedeSecId;
        	end if;

        end if;



        -- lettura elemento bilancio  ordinativo
 		strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura elemento bilancio ordinativo di spesa per tipo flusso '||MANDMIF_TIPO||'.';

		select * into bilElemRec
        from siac_t_bil_elem elem
        where elem.elem_id=mifOrdinativoIdRec.mif_ord_elem_id;
        if bilElemRec is null then
        	RAISE EXCEPTION ' Errore in lettura siac_t_bil_elem.';
        end if;

		-- dati testata flusso presenti come tag solo in testata
        -- valorizzati su ogni ordinativo trasmesso
        -- <testata_flusso>
		-- <codice_ABI_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ABI_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_abi is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=enteOilRec.ente_oil_abi;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_abi_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_IPA;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_ipa is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=trim(both ' ' from enteOilRec.ente_oil_codice_ipa);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <descrizione_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_DESC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.ente_denominazione is not null then
            	mifFlussoOrdinativoRec.mif_ord_desc_ente:=enteProprietarioRec.ente_denominazione;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_desc_ente:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

	    -- <codice_istat_ente>
	    flussoElabMifElabRec:=null;
		mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ISTAT_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_istat is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=enteOilRec.ente_oil_codice_istat;
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
               	mifFlussoOrdinativoRec.mif_ord_codice_ente_istat:=substring(flussoElabMifElabRec.flussoElabMifDef from 1 for 30);
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_fiscale_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODFISC_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteProprietarioRec.codice_fiscale is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=trim(both ' ' from enteProprietarioRec.codice_fiscale);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <codice_tramite_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_CODTRAMITE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice_tramite_bt is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=trim(both ' ' from enteOilRec.ente_oil_codice_tramite_bt);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <codice_ente_BT>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_COD_ENTE_BT;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_codice is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=trim(both ' ' from enteOilRec.ente_oil_codice);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_codice_ente_bt:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <riferimento_ente>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_RIFERIMENTO_ENTE;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if enteOilRec.ente_oil_riferimento is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=trim(both ' ' from enteOilRec.ente_oil_riferimento);
            elsif flussoElabMifElabRec.flussoElabMifDef is not null then
            	mifFlussoOrdinativoRec.mif_ord_riferimento_ente:=flussoElabMifElabRec.flussoElabMifDef;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_flusso>

        -- <testata_esercizio>
        -- <esercizio>
        flussoElabMifElabRec:=null;
        mifCountRec:=FLUSSO_MIF_ELAB_TEST_ESERCIZIO;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            mifFlussoOrdinativoRec.mif_ord_anno_esercizio:=mifOrdinativoIdRec.mif_ord_anno_bil;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
        -- </testata_esercizio>

        mifCountRec:=FLUSSO_MIF_ELAB_INIZIO_ORD;
        mifCountTmpRec:=FLUSSO_MIF_ELAB_INIZIO_ORD;

        -- <mandato>
		-- <tipo_operazione>
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if  flussoElabMifElabRec.flussoElabMifAttivo=true then
         if   flussoElabMifElabRec.flussoElabMifElab=true then
            if flussoElabMifElabRec.flussoElabMifParam is not null then
	            flussoElabMifValore:=fnc_mif_ordinativo_carico_bollo( mifOrdinativoIdRec.mif_ord_codice_funzione,flussoElabMifElabRec.flussoElabMifParam);
            else
            	flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_codice_funzione;
            end if;
            if flussoElabMifValore is not null then
				mifFlussoOrdinativoRec.mif_ord_codice_funzione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <numero_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
/*         	if flussoElabMifTipoDec=false then
				mifFlussoOrdinativoRec.mif_ord_numero:=lpad(mifOrdinativoIdRec.mif_ord_ord_numero,NUM_SETTE,ZERO_PAD);
            else
	            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
            end if;*/
            mifFlussoOrdinativoRec.mif_ord_numero:=mifOrdinativoIdRec.mif_ord_ord_numero;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non elaborabile.';
         end if;
        end if;


        -- <data_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true  then
         if  flussoElabMifElabRec.flussoElabMifElab=true then
			mifFlussoOrdinativoRec.mif_ord_data:=mifOrdinativoIdRec.mif_ord_data_emissione;
         else
            RAISE EXCEPTION ' Configurazione tag/campo non  elaborabile.';
         end if;
        end if;



		-- <importo_mandato>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			-- calcolato inizio ciclo
            null;
         else
         	mifFlussoOrdinativoRec.mif_ord_importo:='0';
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

        -- <conto_evidenza>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
			if mifOrdinativoIdRec.mif_ord_contotes_id is not null then
                 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura conto tesoreria.';


            	select d.contotes_code into flussoElabMifValore
                from siac_d_contotesoreria d
                where d.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id;
                if flussoElabMifValore is null then
                	RAISE EXCEPTION ' Dato non presente in archivio.';
                end if;
            end if;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_bci_conto_tes:=substring(flussoElabMifValore from 1 for 7 );
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;


        -- <estremi_provvedimento_autorizzativo>
        flussoElabMifElabRec:=null;
        mifCountRec:=mifCountRec+1;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
					   ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        flussoElabMifValore:=null;
        attoAmmRec:=null;
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
           if mifOrdinativoIdRec.mif_ord_atto_amm_id is not null then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoSpr is null then
            		attoAmmTipoSpr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmTipoAll is null then
                	attoAmmTipoAll:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
            	end if;
            end if;

            select * into attoAmmRec
            from fnc_mif_estremi_atto_amm(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                                          mifOrdinativoIdRec.mif_ord_atto_amm_movg_id,
                                          attoAmmTipoSpr,attoAmmTipoAll,
                                          dataElaborazione,dataFineVal);
           end if;

           if attoAmmRec.attoAmmEstremi is not null   then
                mifFlussoOrdinativoRec.mif_ord_estremi_attoamm:=attoAmmRec.attoAmmEstremi;
           elseif flussoElabMifElabRec.flussoElabMifDef is not null then
           		mifFlussoOrdinativoRec.mif_ord_estremi_attoamm:=flussoElabMifElabRec.flussoElabMifDef;
           end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
       end if;


       -- <responsabile_provvedimento>
	   flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   flussoElabMifValoreDesc:=null;
	   mifCountRec:=mifCountRec+1;
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_resp_attoamm:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;

     -- <ufficio_responsabile>
     mifCountRec:=mifCountRec+1;

     -- <bilancio>
     -- <codifica_bilancio>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

                mifFlussoOrdinativoRec.mif_ord_codifica_bilancio:=mifOrdinativoIdRec.mif_ord_programma_code
                												||mifOrdinativoIdRec.mif_ord_titolo_code;

                mifFlussoOrdinativoRec.mif_ord_capitolo:=bilElemRec.elem_code;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	  -- <descrizione_codifica>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_desc_codifica:=substring( bilElemRec.elem_desc from 1 for 30);
                mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil:=substring( mifOrdinativoIdRec.mif_ord_programma_desc from 1 for 30);
     	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
     	 end if;
      end if;

      -- <gestione>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifDef is not null then
            	if mifOrdinativoIdRec.mif_ord_anno_bil=mifOrdinativoIdRec.mif_ord_ord_anno_movg then
	            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                else
	                flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
            	mifFlussoOrdinativoRec.mif_ord_gestione:=flussoElabMifValore;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <anno_residuo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

            if  mifOrdinativoIdRec.mif_ord_anno_bil!=mifOrdinativoIdRec.mif_ord_ord_anno_movg  then
               	   mifFlussoOrdinativoRec.mif_ord_anno_res:=mifOrdinativoIdRec.mif_ord_ord_anno_movg;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;


      -- <numero_articolo>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
            	mifFlussoOrdinativoRec.mif_ord_articolo:=bilElemRec.elem_code2;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <voce_economica>
      mifCountRec:=mifCountRec+1;


      -- <importo_bilancio>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
           	mifFlussoOrdinativoRec.mif_ord_importo_bil:=mifFlussoOrdinativoRec.mif_ord_importo;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      -- </bilancio>

      -- <funzionario_delegato>
      -- <codice_funzionario_delegato>
      -- <importo_funzionario_delegato>
      -- <tipologia_funzionario_delegato>
      -- <numero_pagamento_funzionario_delegato>
      mifCountRec:=mifCountRec+5;

      -- <informazioni_beneficiario>

      -- <progressivo_beneficiario>
      flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
--	  raise notice 'progressivo_beneficiario mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
                if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_benef:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;

      -- <importo_beneficiario>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
     		mifFlussoOrdinativoRec.mif_ord_importo_benef:=mifFlussoOrdinativoRec.mif_ord_importo;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;


	  -- <tipo_pagamento>
      flussoElabMifElabRec:=null;
      tipoPagamRec:=null;
	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
     	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	 	if flussoElabMifElabRec.flussoElabMifElab=true then
    	   	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null then
            	if codicePaeseIT is null then
                	codicePaeseIT:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if codiceAccreCB is null then
	                codiceAccreCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if codiceAccreREG is null then
	                codiceAccreREG:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;
				if codiceSepa is null then
	                codiceSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                end if;
				if codiceExtraSepa is null then
	                codiceExtraSepa:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5));
                end if;

                if codiceGFB is null then
	                codiceGFB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6));
                end if;

                select * into tipoPagamRec
                from fnc_mif_tipo_pagamento_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											       (case when MDPRec.iban is not null and length(MDPRec.iban)>=2
                                                   then substring(MDPRec.iban from 1 for 2)
                                                   else null end), -- codicePaese
	                                               codicePaeseIT,codiceSepa,codiceExtraSepa,
                                                   codiceAccreCB,codiceAccreREG,
                                                   flussoElabMifElabRec.flussoElabMifDef, -- compensazione
												   MDPRec.accredito_tipo_id,
                                                   codAccreRec.accredito_gruppo_code,
                                                   mifFlussoOrdinativoRec.mif_ord_importo::NUMERIC, -- importo_ordinativo
                                                   (case when codAccreRec.accredito_tipo_code=codiceGFB then true else false end),
	                                               dataElaborazione,dataFineVal,
                                                   enteProprietarioId);
                if tipoPagamRec is not null then
                	if tipoPagamRec.descTipoPagamento is not null then
                    	mifFlussoOrdinativoRec.mif_ord_pagam_tipo:=tipoPagamRec.descTipoPagamento;
                        mifFlussoOrdinativoRec.mif_ord_pagam_code:=tipoPagamRec.codeTipoPagamento;
                    end if;
                end if;

	        end if;
     	else
       		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;
      end if;

      -- <impignorabili>
      mifCountRec:=mifCountRec+1;


      -- <frazionabile>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then --1
         if flussoElabMifElabRec.flussoElabMifElab=true then --2
          if flussoElabMifElabRec.flussoElabMifParam is not null and --3
             flussoElabMifElabRec.flussoElabMifDef is not null  then

             if dataAvvioFrazAttr is null then
             	dataAvvioFrazAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;

             if dataAvvioFrazAttr is not null and
                dataAvvioFrazAttr::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
                then
                bavvioFrazAttr:=true;
             end if;

             if bavvioFrazAttr=false then
              if classifTipoCodeFraz is null then
               classifTipoCodeFraz:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
              end if;

              if classifTipoCodeFrazVal is null then
               classifTipoCodeFrazVal:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
              end if;
             else
              if attrFrazionabile is null then
	             attrFrazionabile:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
              end if;
             end if;

             if  bavvioFrazAttr = false then
              if classifTipoCodeFraz is not null and
				 classifTipoCodeFrazVal is not null and
                 classifTipoCodeFrazId is null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classificatoreTipoId '||classifTipoCodeFraz||'.';
             	select tipo.classif_tipo_id into classifTipoCodeFrazId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=classifTipoCodeFraz
                and   tipo.data_cancellazione is null
                and   tipo.validita_fine is null
                order by tipo.classif_tipo_id
                limit 1;
              end if;

              if classifTipoCodeFrazVal is not null and
                 classifTipoCodeFrazId is not null then
               strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore classificatore '||classifTipoCodeFraz||' [siac_r_ordinativo_class].';
             	select c.classif_code into flussoElabMifValore
                from siac_r_ordinativo_class r, siac_t_class c
                where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                and   c.classif_id=r.classif_id
                and   c.classif_tipo_id=classifTipoCodeFrazId
                and   r.data_cancellazione is null
                and   r.validita_fine is null
                and   c.data_cancellazione is null
                order by r.ord_classif_id
                limit 1;

              end if;

              if classifTipoCodeFrazVal is not null and
                flussoElabMifValore is not null and
                flussoElabMifValore=classifTipoCodeFrazVal then
             	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
             end if;
			else
              if attrFrazionabile is not null then
               --- calcolo su attributo
               codResult:=null;
               select 1 into codResult
               from  siac_t_ordinativo_ts ts,siac_r_liquidazione_ord liqord,
                     siac_r_liquidazione_movgest rmov,
                     siac_r_movgest_ts_attr r, siac_t_attr attr
               where ts.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
               and   liqord.sord_id=ts.ord_ts_id
               and   rmov.liq_id=liqord.liq_id
               and   r.movgest_ts_id=rmov.movgest_ts_id
               and   attr.attr_id=r.attr_id
               and   attr.attr_code=attrFrazionabile
               and   r.boolean='N'
               and   r.data_cancellazione is null
               and   r.validita_fine is null
               and   rmov.data_cancellazione is null
               and   rmov.validita_fine is null
               and   liqord.data_cancellazione is null
               and   liqord.validita_fine is null
			   and   ts.data_cancellazione is null
               and   ts.validita_fine is null;

               if codResult is not null then
               	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=flussoElabMifElabRec.flussoElabMifDef;
               end if;

             end if;

            end if;

          end if; -- 3
      	 else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;  --- 2

        end if; -- 1

  	   -- <gestione_provvisoria>
       flussoElabMifElabRec:=null;
       mifCountRec:=mifCountRec+1;
        -- gestione_provvisoria da impostare solo se frazionabile=NO
       if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz is not null then
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
        end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
          if flussoElabMifElabRec.flussoElabMifParam is not null and
             flussoElabMifElabRec.flussoElabMifDef is not null and
             mifOrdinativoIdRec.mif_ord_bil_fase_ope is not null  then

             if tipoEsercizio is null then
	             tipoEsercizio:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;
          	if tipoEsercizio=mifOrdinativoIdRec.mif_ord_bil_fase_ope  then
				mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov=flussoElabMifElabRec.flussoElabMifDef;
            end if;
		   end if;


         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;

        end if;
        --- frazionabile da impostare NO solo se gestione_provvisoria=SI
        if mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov is null then
        	mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz:=null;
        end if;

      else
       	null;
      end if;

      -- <data_esecuzione_pagamento>
      flussoElabMifElabRec:=null;
      ordDataScadenza:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=flussoElabMifElabRec.flussoElabMifParam then
            	flussoElabMifElabRec.flussoElabMifElab:=false; -- se REGOLARIZZAZIONE data_esecuzione_pagamento non deve essere valorizzato
            end if;

            if flussoElabMifElabRec.flussoElabMifElab=true then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura data scadenza.';
        	 select sub.ord_ts_data_scadenza into ordDataScadenza
             from siac_t_ordinativo_ts sub
             where sub.ord_ts_id=mifOrdinativoIdRec.mif_ord_subord_id;

             if ordDataScadenza is not null and
--               date_trunc('DAY',ordDataScadenza)>= date_trunc('DAY',dataElaborazione) and
               date_trunc('DAY',ordDataScadenza)> date_trunc('DAY',dataElaborazione) and -- 13.12.2017 Sofia siac-5653
               extract('year' from ordDataScadenza)::integer<=annoBilancio::integer then
		  		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec:=
    		        extract('year' from ordDataScadenza)||'-'||
    	         	lpad(extract('month' from ordDataScadenza)::varchar,2,'0')||'-'||
            	 	lpad(extract('day' from ordDataScadenza)::varchar,2,'0');
             end if;
            end if;

	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
      end if;

      -- <data_scadenza_pagamento>
  	  mifCountRec:=mifCountRec+1;

	  -- <destinazione>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      codResult:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
  	   RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
   	   if flussoElabMifElabRec.flussoElabMifElab=true then

        if flussoElabMifElabRec.flussoElabMifParam is not null or
           flussoElabMifElabRec.flussoElabMifDef is not null then --1

           if flussoElabMifElabRec.flussoElabMifParam is not null then --2
		    if classVincolatoCode is null then
	        	classVincolatoCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if;

            if classVincolatoCode is not null and classVincolatoCodeId is null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura identificativo classVincolatoCode='||classVincolatoCode||'.';

                select tipo.classif_tipo_id into classVincolatoCodeId
                from siac_d_class_tipo tipo
                where tipo.ente_proprietario_id=enteProprietarioId
                and   tipo.classif_tipo_code=classVincolatoCode;

            end if;

            if classVincolatoCodeId is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore per classVincolatoCode='||classVincolatoCode||'.';

                         select c.classif_desc into flussoElabMifValore
                         from siac_r_ordinativo_class r, siac_t_class c
                         where r.ord_id=  mifOrdinativoIdRec.mif_ord_ord_id
                         and   c.classif_id=r.classif_id
                         and   c.classif_tipo_id=classVincolatoCodeId
                         and   r.data_cancellazione is null
                         and   r.validita_fine is null
                         and   c.data_cancellazione is null;

            end if;
  	     end if; --2


         if flussoElabMifValore is null and --3
            mifOrdinativoIdRec.mif_ord_contotes_id is not null and
        	mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
    		                   ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
        		               ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
            		           ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                		       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                    		   ||' mifCountRec='||mifCountRec
	                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_vincolato].';

			select mif.vincolato into flussoElabMifValore
    	    from mif_r_conto_tesoreria_vincolato mif
	    	where mif.ente_proprietario_id=enteProprietarioId
    	    and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
	        and   mif.validita_fine is null
		    and   mif.data_cancellazione is null;


        end if; --3
 	    if flussoElabMifValore is null and
           flussoElabMifElabRec.flussoElabMifDef is not null then
           flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
        end if;

	    if flussoElabMifValore is not null then
        	mifFlussoOrdinativoRec.mif_ord_progr_dest:=flussoElabMifValore;
        end if;

       end if; --1
      else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
      end if;
     end if;


     -- <numero_conto_banca_italia_ente_ricevente>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     codResult:=null;
     if flussoElabMifElabRec.flussoElabMifId is null then
     	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	-- non esposto se regolarizzazione (provvisori)
                if mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
-- 28.12.2017 Sofia SIAC-5665	   mifFlussoOrdinativoRec.mif_ord_pagam_tipo= trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2)) then
          		   ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                     trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                    or
                     mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                     trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
                    )  then -- 28.12.2017 Sofia SIAC-5665

                   flussoElabMifElabRec.flussoElabMifElab:=false;
                end if;

                if flussoElabMifElabRec.flussoElabMifElab=true then
	             if tipoMDPCbi is null then
                   	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
               	  end if;


                  if tipoMDPCbi is not null then
                  	if codAccreRec.accredito_gruppo_code=tipoMDPCbi then
                        	 mifFlussoOrdinativoRec.mif_ord_bci_conto:=MDPRec.contocorrente;
                    end if;
                  end if;
                 end if;


            end if;
       else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
     end if;


     -- <tipo_contabilita_ente_ricevente>
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     codResult:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
             if flussoElabMifElabRec.flussoElabMifDef is not null then

                if flussoElabMifElabRec.flussoElabMifParam is not null then
                   if tipoClassFruttifero is null then
                    	tipoClassFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                   end if;

                   if tipoClassFruttifero is not null and valFruttifero is null then
	                   valFruttifero:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                       valFruttiferoStr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                       valFruttiferoStrAltro:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
                   end if;

                   if tipoClassFruttifero is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      tipoClassFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classifTipoCodeId '||tipoClassFruttifero||'.';
                   	select tipo.classif_tipo_id into tipoClassFruttiferoId
                    from siac_d_class_tipo tipo
                    where tipo.ente_proprietario_id=enteProprietarioId
                    and   tipo.classif_tipo_code=tipoClassFruttifero
                    and   tipo.data_cancellazione is null
                    and   tipo.validita_fine is null;

                   end if;


                   if tipoClassFruttiferoId is not null and
                      valFruttifero is not null and
                      valFruttiferoStr is not null and
                      valFruttiferoStrAltro is not null and
                      valFruttiferoId is null then

                    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura classidId '||tipoClassFruttifero||' [siac_r_ordinativo_class].';


                   	select c.classif_code into flussoElabMifValore
                    from siac_r_ordinativo_class r, siac_t_class c
                    where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
	                and   c.classif_id=r.classif_id
                    and   c.classif_tipo_id=tipoClassFruttiferoId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   c.data_cancellazione is null
                    order by r.ord_classif_id limit 1;

                    if flussoElabMifValore is not null then
                    	if flussoElabMifValore=valFruttifero THEN
                        	flussoElabMifValore=valFruttiferoStr;
                        else
                          flussoElabMifValore=valFruttiferoStrAltro;
                        end if;
                    end if;

                  end if;

				end if; -- param

				if flussoElabMifValore is not null then
	                mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
                end if;

               if mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil is null and
	              mifOrdinativoIdRec.mif_ord_contotes_id is not null and
    	          mifOrdinativoIdRec.mif_ord_contotes_id!=0 then

               	  flussoElabMifValore:=null;
	              strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per conto corrente tesoreria [mif_r_conto_tesoreria_fruttifero].';
	           	  select mif.fruttifero into flussoElabMifValore
	              from mif_r_conto_tesoreria_fruttifero mif
    	          where mif.ente_proprietario_id=enteProprietarioId
        	      and   mif.contotes_id=mifOrdinativoIdRec.mif_ord_contotes_id
            	  and   mif.validita_fine is null
	              and   mif.data_cancellazione is null;

    	          if flussoElabMifValore is not null then
        	       	mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=flussoElabMifValore;
            	  end if;

              end if;

              if mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil is null then
                   	mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
              end if;
           end if; -- default
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <tipo_postalizzazione>
      flussoElabMifElabRec:=null;
      codResult:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifValore:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      raise notice 'tipo_postalizzazione mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
    	if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifParam is not null and
            flussoElabMifElabRec.flussoElabMifDef is not null then
           if tipoPagamPostA is null then
           	tipoPagamPostA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
           end if;

           if tipoPagamPostB is null then
           	tipoPagamPostB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
           end if;


           if tipoPagamPostA is not null or tipoPagamPostB is not null then
			  if tipoPagamRec is not null and tipoPagamRec.descTipoPagamento is not null then
              	if tipoPagamRec.descTipoPagamento in (tipoPagamPostA,tipoPagamPostB) then
	                mifFlussoOrdinativoRec.mif_ord_pagam_postalizza:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
              end if;
           end if;

         end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
      end if;


      -- <classificazione>
	  -- <codice_cgu>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      codiceCge:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      raise notice 'classificazione mifCountRec=%',mifCountRec;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then -- attivo
       if flussoElabMifElabRec.flussoElabMifElab=true then -- elab

        if flussoElabMifElabRec.flussoElabMifParam is not null then -- param

       	 if siopeCodeTipo is null and flussoElabMifElabRec.flussoElabMifParam is not null then
         	siopeCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
         end if;

         if siopeDef is null and flussoElabMifElabRec.flussoElabMifParam is not null then
         	siopeDef:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)=NVL_STR and
            flussoElabMifElabRec.flussoElabMifParam is not null then
           	dataAvvioSiopeNew:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR and codiceFinVTbr is null then
       	 	codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));
         end if;

         if coalesce(dataAvvioSiopeNew,NVL_STR)!=NVL_STR then
       	  if dataAvvioSiopeNew::timestamp<=date_trunc('DAY',mifOrdinativoIdRec.mif_ord_data_emissione::timestamp) -- data emissione ordinativo
             then
              bAvvioSiopeNew:=true;
           end if;
         end if;

         if bAvvioSiopeNew=true then -- avvioSiopeNew
           if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
		  	-- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

            select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
		   	from siac_r_ordinativo_class r, siac_t_class class
			where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		    and   class.classif_id=r.classif_id
		    and   class.classif_tipo_id=codiceFinVTipoTbrId
		    and   r.data_cancellazione is null
		    and   r.validita_fine is NULL
		    and   class.data_cancellazione is null;

          	if   flussoElabMifValore is null then
             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

             select replace(substring(class.classif_code,2),'.','') , class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
 		   	 from siac_r_liquidazione_class r, siac_t_class class
			 where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null;
            end if;

          end if;
         else -- avvioSiopeNew
           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||siopeCodeTipo||'.';

           if siopeCodeTipoId is null and siopeCodeTipo is not null then
           	select tipo.classif_tipo_id into siopeCodeTipoId
            from siac_d_class_tipo tipo
            where tipo.classif_tipo_code=siopeCodeTipo
            and   tipo.ente_proprietario_id=enteProprietarioId
            and   tipo.data_cancellazione is null
	 		and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
           end if;

           strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||siopeCodeTipo||'.';

           if siopeCodeTipoId is not null then
           	select class.classif_code, class.classif_desc
                   into flussoElabMifValore,flussoElabMifValoreDesc
            from siac_r_ordinativo_class cord, siac_t_class class
            where cord.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and cord.data_cancellazione is null
            and cord.validita_fine is null
            and class.classif_id=cord.classif_id
            and class.classif_code!=siopeDef
            and class.data_cancellazione is null
            and class.classif_tipo_id=siopeCodeTipoId;

            if flussoElabMifValore is null then
             select class.classif_code, class.classif_desc
                    into flussoElabMifValore,flussoElabMifValoreDesc
             from siac_r_liquidazione_class cord, siac_t_class class
             where cord.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
             and cord.data_cancellazione is null
             and cord.validita_fine is null
             and class.classif_id=cord.classif_id
             and class.classif_code!=siopeDef
             and class.data_cancellazione is null
             and class.classif_tipo_id=siopeCodeTipoId;
            end if;


           end if;
         end if; -- avvioSiopeNew


         if flussoElabMifValore is not null then
         	mifFlussoOrdinativoRec.mif_ord_class_codice_cge:=flussoElabMifValore;
            codiceCge:=flussoElabMifValore;
         end if;
        end if; -- param
       else -- elab
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if; -- elab
      end if; -- attivo

	  -- <codice_cup>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if coalesce(cupAttrCode,NVL_STR)=NVL_STR then
                	cupAttrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if coalesce(cupAttrCode,NVL_STR)!=NVL_STR and cupAttrId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cupAttrCode||'.';
                	select attr.attr_id into cupAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cupAttrCode
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
                end if;

                if cupAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cupAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                    	mifFlussoOrdinativoRec.mif_ord_class_codice_cup:=flussoElabMifValore;
                    end if;


                    if mifFlussoOrdinativoRec.mif_ord_class_codice_cup is null then
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cupAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;


                        if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
    	                	mifFlussoOrdinativoRec.mif_ord_class_codice_cup:=flussoElabMifValore;
	                    end if;
                    end if;
                end if;
            end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <codice_cpv>
      mifCountRec:=mifCountRec+1;

      -- <importo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
 	      	mifFlussoOrdinativoRec.mif_ord_class_importo:=mifFlussoOrdinativoRec.mif_ord_importo;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- </classificazione>

      -- <classificazione_dati_siope_uscite>
	  -- <tipo_debito_siope_c>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      isOrdCommerciale:=false;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        -- 21.12.2017 Sofia JIRA SIAC-5665
        if flussoElabMifElabRec.flussoElabMifParam is not null then
            flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            tipoDocsComm:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))||'|'||
                      trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))||'|'||
                      trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4));

            isOrdCommerciale:=fnc_mif_ordinativo_esiste_documenti_splus( mifOrdinativoIdRec.mif_ord_ord_id,
                                                                         tipoDocsComm,
                                                   	                     enteProprietarioId
                                                                        );


/*        	if mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id is not null then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura tipo debito [siac_d_siope_tipo_debito].';
            	select tipo.siope_tipo_debito_desc_bnkit into flussoElabMifValore
                from siac_d_siope_tipo_debito tipo
                where tipo.siope_tipo_debito_id=mifOrdinativoIdRec.mif_ord_siope_tipo_debito_id;
            end if;

            if flussoElabMifValore is not null and
               upper(flussoElabMifValore)=flussoElabMifElabRec.flussoElabMifParam then
               mifFlussoOrdinativoRec.mif_ord_class_tipo_debito:=flussoElabMifElabRec.flussoElabMifParam;
               isOrdCommerciale:=true;
            end if;*/
            -- 21.12.2017 Sofia JIRA SIAC-5665
            if isOrdCommerciale=true then
            	mifFlussoOrdinativoRec.mif_ord_class_tipo_debito:=flussoElabMifValore;
            end if;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <tipo_debito_siope_nc>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      codResult:=null;
      if isOrdCommerciale=false then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         if flussoElabMifElabRec.flussoElabMifDef is not null then
            -- 20.03.2018 Sofia SIAC-5968 - test sul pdcFin di OP per verificare se IVA
            if flussoElabMifElabRec.flussoElabMifParam is not null then
         	 if coalesce(tipoPdcIVA,'')='' then
	         	tipoPdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
             end if;
             if coalesce(codePdcIVA,'')='' then
	         	codePdcIVA:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
             end if;

             if coalesce(tipoPdcIVA,'')!=''  and coalesce(codePdcIVA,'')!='' then
                strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Verifica tipo debito IVA.';
             	select 1 into codResult
                from siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipo
                where rc.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                and   c.classif_id=rc.classif_id
                and   tipo.classif_tipo_id=c.classif_tipo_id
                and   tipo.classif_tipo_code=tipoPdcIVA
                and   c.classif_code like codePdcIVA||'%'
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null;

                if codResult is not null then
	               	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                end if;
             end if;

            end if;

            -- 21.12.2017 Sofia JIRA SIAC-5665
            --mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc:=flussoElabMifElabRec.flussoElabMifParam;

            -- 20.03.2018 Sofia SIAC-5968
            if flussoElabMifValore is null then
            	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
            end if;
            -- 20.03.2018 Sofia SIAC-5968
			mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc:=flussoElabMifValore;

         end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;




      -- <codice_cig_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      flussoElabMifValoreDesc:=null;
      mifCountRec:=mifCountRec+1;
      raise notice 'codice_cig_siope mifCountRec=%',mifCountRec;
      -- solo per COMMERCIALI
	  if isOrdCommerciale=true then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

       if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
			if flussoElabMifElabRec.flussoElabMifParam is not null then
            	if coalesce(cigAttrCode,NVL_STR)=NVL_STR then
                	cigAttrCode:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;

                if coalesce(cigAttrCode,NVL_STR)!=NVL_STR and cigAttrCodeId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cigAttrCode||'.';
                	select attr.attr_id into cigAttrCodeId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cigAttrCode
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;
                end if;

                if cigAttrCodeId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupAttrCode||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cigAttrCodeId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
                    	mifFlussoOrdinativoRec.mif_ord_class_cig:=flussoElabMifValore;
                    end if;


                    if mifFlussoOrdinativoRec.mif_ord_class_cig is null then
                    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigAttrCode||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cigAttrCodeId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;


                        if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
    	                	mifFlussoOrdinativoRec.mif_ord_class_cig:=flussoElabMifValore;
	                    end if;
                    end if;
                end if;
            end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      -- <motivo_esclusione_cig_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      -- solo per COMMERCIALI
      if isOrdCommerciale=true and
         mifFlussoOrdinativoRec.mif_ord_class_cig is null then
       flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
       strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;

	   if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
       	  if mifOrdinativoIdRec.mif_ord_siope_assenza_motivazione_id is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura motivazione [siac_d_siope_assenza_motivazione].';
            raise notice 'siope_assenza_motivazione_desc_bnkit';
		  	select upper(ass.siope_assenza_motivazione_desc_bnkit) into flussoElabMifValore
			from siac_d_siope_assenza_motivazione ass
			where ass.siope_assenza_motivazione_id=mifOrdinativoIdRec.mif_ord_siope_assenza_motivazione_id;
          end if;
		  if flussoElabMifValore is not null then
	    	  mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig:=flussoElabMifValore;
              raise notice 'siope_assenza_motivazione_desc_bnkit=%',mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig;

          end if;
        else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
       end if;
      end if;

      raise notice 'motivo_esclusione_cig_siope mifCountRec=%',mifCountRec;

      -- <fatture_siope>
      -- </fatture_siope>
      mifCountRec:=mifCountRec+12;

      -- <dati_ARCONET_siope>


      -- <codice_missione_siope>
	  flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
    	  mifFlussoOrdinativoRec.mif_ord_class_missione:=SUBSTRING(mifOrdinativoIdRec.mif_ord_programma_code from 1 for 2);
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      raise notice 'codice_missione_siope mifCountRec=%',mifCountRec;

      -- <codice_programma_siope>
	  flussoElabMifElabRec:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
    	  mifFlussoOrdinativoRec.mif_ord_class_programma:=mifOrdinativoIdRec.mif_ord_programma_code;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      -- <codice_economico_siope>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
                              raise notice 'codice_economico_siope mifCountRec=%',mifCountRec;

      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        if flussoElabMifElabRec.flussoElabMifParam is not null then

          if codiceFinVTbr is null then
				codiceFinVTbr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
          end if;

		  if codiceFinVTbr is not null and codiceFinVTipoTbrId is null then
		  	-- codiceFinVTipoTbrId
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura ID codice tipo='||codiceFinVTbr||'.';
			select tipo.classif_tipo_id into strict codiceFinVTipoTbrId
			from siac_d_class_tipo tipo
			where tipo.ente_proprietario_id=enteProprietarioId
			and   tipo.classif_tipo_code=codiceFinVTbr
			and   tipo.data_cancellazione is null
			and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
		    and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(validita_fine,dataElaborazione));
          end if;

          if codiceFinVTipoTbrId is not null then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

            select class.classif_code  into flussoElabMifValore
		   	from siac_r_ordinativo_class r, siac_t_class class
			where r.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
		    and   class.classif_id=r.classif_id
		    and   class.classif_tipo_id=codiceFinVTipoTbrId
		    and   r.data_cancellazione is null
		    and   r.validita_fine is NULL
		    and   class.data_cancellazione is null;

          	if   flussoElabMifValore is null then
             strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'.Lettura valore per codice tipo='||codiceFinVTbr||'.';

             select class.classif_code  into flussoElabMifValore
 		   	 from siac_r_liquidazione_class r, siac_t_class class
			 where r.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
		     and   class.classif_id=r.classif_id
		     and   class.classif_tipo_id=codiceFinVTipoTbrId
		     and   r.data_cancellazione is null
		     and   r.validita_fine is NULL
		     and   class.data_cancellazione is null;
            end if;
          end if;
/*
       	  if collEventoCodeId is null then
        	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura tipo coll. evento '||flussoElabMifElabRec.flussoElabMifParam||'.';


            select coll.collegamento_tipo_id into collEventoCodeId
            from siac_d_collegamento_tipo coll
            where coll.ente_proprietario_id=enteProprietarioId
            and   coll.collegamento_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))
            and   coll.data_cancellazione is null
		    and   date_trunc('day',dataElaborazione)>=date_trunc('day',coll.validita_inizio)
		    and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(coll.validita_fine,dataElaborazione));

         end if;

	     if collEventoCodeId is not null then
		  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'Lettura conto economico patrimoniale.';
                             raise notice 'QUI QUI strMessaggio=%',strMessaggio;

          select conto.pdce_conto_code into flussoElabMifValore
          from siac_t_pdce_conto conto, siac_t_reg_movfin regMovFin, siac_r_evento_reg_movfin rEvento,
               siac_d_evento evento,
               siac_t_mov_ep reg, siac_r_reg_movfin_stato regstato, siac_d_reg_movfin_stato stato,
               siac_t_prima_nota pn, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnstato,
               siac_t_mov_ep_det det
          where evento.ente_proprietario_id=enteProprietarioId
          and   evento.collegamento_tipo_id=collEventoCodeId -- OP
          and   rEvento.evento_id=evento.evento_id
          and   rEvento.campo_pk_id=mifOrdinativoIdRec.mif_ord_ord_id
          and   regMovFin.regmovfin_id=rEvento.regmovfin_id
--          and   regMovFin.ambito_id=ambitoFinId  -- AMBITO_FIN togliamo ambito
          and   regstato.regmovfin_id=regMovFin.regmovfin_id
          and   stato.regmovfin_stato_id=regstato.regmovfin_stato_id
          and   stato.regmovfin_stato_code!=REGMOVFIN_STATO_A
          and   reg.regmovfin_id=regMovFin.regmovfin_id
          and   pn.pnota_id=reg.regep_id
          and   rpnota.pnota_id=pn.pnota_id
          and   pnstato.pnota_stato_id=rpnota.pnota_stato_id
          and   pnstato.pnota_stato_code!=REGMOVFIN_STATO_A  -- forse sarebbe meglio prendere solo i D
          and   det.movep_id=reg.movep_id
          and   det.movep_det_segno=SEGNO_ECONOMICO -- Dare
		  and   conto.pdce_conto_id=det.pdce_conto_id
          and   regMovFin.data_cancellazione is null
          and   regMovFin.validita_fine is null
          and   rEvento.data_cancellazione is null
          and   rEvento.validita_fine is null
          and   evento.data_cancellazione is null
          and   evento.validita_fine is null
          and   reg.data_cancellazione is null
          and   reg.validita_fine is null
          and   regstato.data_cancellazione is null
          and   regstato.validita_fine is null
          and   pn.data_cancellazione is null
          and   pn.validita_fine is null
          and   rpnota.data_cancellazione is null
          and   rpnota.validita_fine is null
          and   conto.data_cancellazione is null
          and   conto.validita_fine is null
          order by pn.pnota_id desc
          limit 1;
         end if;
*/
       end if;


        if flussoElabMifValore is not null then
	        mifFlussoOrdinativoRec.mif_ord_class_economico:=flussoElabMifValore;
        end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

	  -- <importo_codice_economico_siope>
	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_economico is not null then
      	flussoElabMifElabRec:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

	    if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         		mifFlussoOrdinativoRec.mif_ord_class_importo_economico:=mifFlussoOrdinativoRec.mif_ord_importo;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;
      end if;

      -- <codice_UE_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
            raise notice 'codice_UE_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if codiceUECodeTipo is null then
				codiceUECodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if codiceUECodeTipo is not null and codiceUECodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceUECodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceUECodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if codiceUECodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                             raise notice 'QUI QUI codiceUECodeTipo=% strMessaggio=%',codiceUECodeTipo,strMessaggio;

        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceUECodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;

                             raise notice '222QUI QUI codiceUECodeTipo=% strMessaggio=%',codiceUECodeTipo,strMessaggio;

             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select class.classif_code into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=codiceUECodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
                raise notice 'QUI QUI flussoElabMifValore=%',flussoElabMifValore;
            	mifFlussoOrdinativoRec.mif_ord_class_transaz_ue:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;

      -- <codice_uscita_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
                  raise notice 'codice_uscita_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if ricorrenteCodeTipo is null then
				ricorrenteCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if ricorrenteCodeTipo is not null and ricorrenteCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into ricorrenteCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=ricorrenteCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if ricorrenteCodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

        	 select upper(class.classif_desc) into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=ricorrenteCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;


             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select upper(class.classif_desc) into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=ricorrenteCodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_class_ricorrente_spesa:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;


      -- <codice_cofog_siope>
      flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  codResult:=null;
	  mifCountRec:=mifCountRec+1;
                        raise notice 'codice_cofog_siope mifCountRec=%',mifCountRec;

	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	if flussoElabMifElabRec.flussoElabMifElab=true then
    	 if flussoElabMifElabRec.flussoElabMifParam is not null then
     		if codiceCofogCodeTipo is null then
				codiceCofogCodeTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
	        end if;

            if codiceCofogCodeTipo is not null and codiceCofogCodeTipoId is null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_d_class_tipo.';

        	 select tipo.classif_tipo_id into codiceCofogCodeTipoId
             from  siac_d_class_tipo tipo
             where tipo.ente_proprietario_id=enteProprietarioId
             and   tipo.classif_tipo_code=codiceCofogCodeTipo
             and   tipo.data_cancellazione is null
		     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		 	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
            end if;

	        if codiceCofogCodeTipoId is not null then
        	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_ordinativo_class.';
                                                    raise notice 'QUI QUI strMessaggio=%',strMessaggio;

        	 select class.classif_code into flussoElabMifValore
             from siac_r_ordinativo_class rclass, siac_t_class class
             where rclass.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
             and   rclass.data_cancellazione is null
             and   rclass.validita_fine is null
             and   class.classif_id=rclass.classif_id
             and   class.classif_tipo_id=codiceCofogCodeTipoId
             and   class.data_cancellazione is null
             order by rclass.ord_classif_id
             limit 1;


             if flussoElabMifValore is null then
        	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura siac_r_liquidazione_class.';
        	  select class.classif_code into flussoElabMifValore
              from siac_r_liquidazione_class rclass, siac_t_class class
              where rclass.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
              and   rclass.data_cancellazione is null
              and   rclass.validita_fine is null
              and   class.classif_id=rclass.classif_id
              and   class.classif_tipo_id=codiceCofogCodeTipoId
              and   class.data_cancellazione is null
              order by rclass.liq_classif_id
              limit 1;
             end if;
	        end if;

      	    if flussoElabMifValore is not null then
            	mifFlussoOrdinativoRec.mif_ord_class_cofog_codice:=flussoElabMifValore;
            end if;

      	 end if;
        else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		end if;
	  end if;

      -- <importo_cofog_siope>
  	  mifCountRec:=mifCountRec+1;
      if mifFlussoOrdinativoRec.mif_ord_class_cofog_codice is not null then
       flussoElabMifElabRec:=null;
	   flussoElabMifValore:=null;
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	   if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	   end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
        		mifFlussoOrdinativoRec.mif_ord_class_cofog_importo:=mifFlussoOrdinativoRec.mif_ord_importo;

         else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		 end if;
	    end if;
       end if;

      -- </dati_ARCONET_siope>

      -- </classificazione_dati_siope_uscite>

      -- <bollo>
      -- <assoggettamento_bollo>
   	  mifCountRec:=mifCountRec+1;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if mifOrdinativoIdRec.mif_ord_codbollo_id is not null then


	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then

          	if flussoElabMifElabRec.flussoElabMifParam is not null and
               flussoElabMifElabRec.flussoElabMifDef is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo in
                 (trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)), -- REGOLARIZZAZIONE
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))  -- F24EP
                 ) then

               codiceBolloPlusEsente:=true;
               -- REGOLARIZZAZIONE
               if mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) then
                  mifFlussoOrdinativoRec.mif_ord_bollo_carico:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               	  mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
               end if;
               -- F24EP
               if mifFlussoOrdinativoRec.mif_ord_pagam_tipo=
                  trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2)) then
                  mifFlussoOrdinativoRec.mif_ord_bollo_carico:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               	  mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
               end if;
            end if;

            if mifFlussoOrdinativoRec.mif_ord_bollo_carico is null then
          	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice bollo.';

             select bollo.codbollo_desc , plus.codbollo_plus_desc, plus.codbollo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
             from siac_d_codicebollo bollo, siac_d_codicebollo_plus plus, siac_r_codicebollo_plus rp
             where bollo.codbollo_id=mifOrdinativoIdRec.mif_ord_codbollo_id
             and   rp.codbollo_id=bollo.codbollo_id
             and   plus.codbollo_plus_id=rp.codbollo_plus_id
             and   rp.data_cancellazione is null
             and   rp.validita_fine is null;

             if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_bollo_carico:=codiceBolloPlusDesc;
             end if;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
       end if;

      -- <causale_esenzione_bollo>
   	  mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      if codiceBolloPlusEsente=true and coalesce(ordCodiceBolloDesc,NVL_STR)!=NVL_STR then
      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
            if mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione is null then
--              27.06.2018 Sofia siac-6272
--	          	mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=substring(ordCodiceBolloDesc from 1 for 30);
                mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione:=ordCodiceBolloDesc;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
      -- </bollo>

	  -- <spese>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      ordCodiceBolloDesc:=null;
      codiceBolloPlusDesc:=null;
      codiceBolloPlusEsente:=false;
      -- <soggetto_destinatario_delle_spese>
      if mifOrdinativoIdRec.mif_ord_comm_tipo_id is not null then
	   flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	    end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura codice commissione.';

            select tipo.comm_tipo_desc , plus.comm_tipo_plus_desc, plus.comm_tipo_plus_esente
                   into ordCodiceBolloDesc, codiceBolloPlusDesc, codiceBolloPlusEsente
            from siac_d_commissione_tipo tipo, siac_d_commissione_tipo_plus plus, siac_r_commissione_tipo_plus rp
            where tipo.comm_tipo_id=mifOrdinativoIdRec.mif_ord_comm_tipo_id
            and   rp.comm_tipo_id=tipo.comm_tipo_id
            and   plus.comm_tipo_plus_id=rp.comm_tipo_plus_id
            and   rp.data_cancellazione is null
            and   rp.validita_fine is null;

            if coalesce(codiceBolloPlusDesc,NVL_STR)!=NVL_STR  then
            	mifFlussoOrdinativoRec.mif_ord_commissioni_carico:=codiceBolloPlusDesc;
            end if;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
        end if;
      end if;
      -- <natura_pagamento>
      mifCountRec:=mifCountRec+1;

      -- <causale_esenzione_spese>
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      if codiceBolloPlusEsente=true and mifFlussoOrdinativoRec.mif_ord_commissioni_carico is not null then
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	   strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
  	   end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
	   	  if flussoElabMifElabRec.flussoElabMifElab=true then
          	mifFlussoOrdinativoRec.mif_ord_commissioni_esenzione:=ordCodiceBolloDesc;
          else
			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  		  end if;
       end if;
      end if;
      -- </spese>

	  -- <beneficiario>
      mifCountRec:=mifCountRec+1;
      -- <anagrafica_beneficiario>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      mifCountRec:=mifCountRec+1;
      anagraficaBenefCBI:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;
--       raise notice 'beneficiario mifCountRec=%',mifCountRec;
      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then
         	if soggettoSedeSecId is not null then
            	flussoElabMifValore:=soggettoRec.soggetto_desc||' '||soggettoSedeRec.soggetto_desc;
            else
            	flussoElabMifValore:=soggettoRec.soggetto_desc;
            end if;

            /*if flussoElabMifElabRec.flussoElabMifParam is not null and tipoMDPCbi is null then
	           	tipoMDPCbi:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
            end if; */

            -- se non e girofondo o se lo e ma il contocorrente_intestazione e vuoto
            -- valorizzo i tag di anagrafica_beneficiario
            -- altrimenti solo anagrafica_beneficiario=contocorrente_intestazione
            -- e anagrafica_beneficiario in dati_a_disposizione_ente
            /*if codAccreRec.accredito_gruppo_code!=tipoMDPCbi or
			   (codAccreRec.accredito_gruppo_code=tipoMDPCbi and
                 (MDPRec.contocorrente_intestazione is null or MDPRec.contocorrente_intestazione='')) then
	           	mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);
            else
	            	anagraficaBenefCBI:=flussoElabMifValore;
	                mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(MDPRec.contocorrente_intestazione from 1 for 140);
            end if;*/

            mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);

       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
     end if;



	 -- <indirizzo_beneficiario>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' indirizzo_benef mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
       if flussoElabMifElabRec.flussoElabMifElab=true then
        	if soggettoSedeSecId is not null then
                select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoSedeSecId
                and   indir.data_cancellazione is null
                and   indir.validita_fine is null;

            else
            	select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoRifId
                and   indir.principale='S'
                and   indir.data_cancellazione is null
         	    and   indir.validita_fine is null;

            end if;

            if indirizzoRec is null then
            	-- RAISE EXCEPTION ' Errore in lettura indirizzo soggetto [siac_t_indirizzo_soggetto].';
                isIndirizzoBenef:=false;
            end if;

            if isIndirizzoBenef=true then

             if indirizzoRec.via_tipo_id is not null then
            	select tipo.via_tipo_code into flussoElabMifValore
                from siac_d_via_tipo tipo
                where tipo.via_tipo_id=indirizzoRec.via_tipo_id
                and   tipo.data_cancellazione is null
         	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 		 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
                if flussoElabMifValore is not null then
                	flussoElabMifValore:=flussoElabMifValore||' ';
                end if;
             end if;

             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
                                 ||' '||coalesce(indirizzoRec.numero_civico,''));

             if flussoElabMifValore is not null and anagraficaBenefCBI is null then
	            mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
             end if;
           end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

   	  -- <cap_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then
        if indirizzoRec.zip_code is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
	            mifFlussoOrdinativoRec.mif_ord_cap_benef:=lpad(indirizzoRec.zip_code,5,'0');
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
	  end if;

      -- <localita_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select com.comune_desc into flussoElabMifValore
            from siac_t_comune com
            where com.comune_id=indirizzoRec.comune_id
            and   com.data_cancellazione is null
            and   com.validita_fine is null;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_localita_benef:=substring(flussoElabMifValore from 1 for 30);
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
      end if;


	  -- <provincia_beneficiario>
      mifCountRec:=mifCountRec+1;
      if isIndirizzoBenef=true then

        if indirizzoRec.comune_id is not null and anagraficaBenefCBI is null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	select prov.sigla_automobilistica into flussoElabMifValore
            from siac_r_comune_provincia provRel, siac_t_provincia prov
            where provRel.comune_id=indirizzoRec.comune_id
            and   provRel.data_cancellazione is null
            and   provRel.validita_fine is null
            and   prov.provincia_id=provRel.provincia_id
            and   prov.data_cancellazione is null
            and   prov.validita_fine is null
            order by provRel.data_creazione;

            if flussoElabMifValore is not null then
	            mifFlussoOrdinativoRec.mif_ord_prov_benef:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
        end if;
      end if;

      -- <stato_beneficiario>
      mifCountRec:=mifCountRec+1; -- popolare in seguito ricavato il codice_paese di piazzatura
      flussoElabMifElabRec:=null;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
          if anagraficaBenefCBI is null and
             statoBeneficiario=false then
	            statoBeneficiario:=true;
           end if;
         else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

	  -- <partita_iva_beneficiario>
      mifCountRec:=mifCountRec+1;
      if ( anagraficaBenefCBI is null and
            (soggettoRec.partita_iva is not null or
            (soggettoRec.partita_iva is null and soggettoRec.codice_fiscale is not null and length(soggettoRec.codice_fiscale)=11))
          )   then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
          	    if soggettoRec.partita_iva is not null then
		            mifFlussoOrdinativoRec.mif_ord_partiva_benef:=soggettoRec.partita_iva;
                else
                    if length(trim ( both ' ' from soggettoRec.codice_fiscale))=11 then
                        mifFlussoOrdinativoRec.mif_ord_partiva_benef:=trim ( both ' ' from soggettoRec.codice_fiscale);
                    end if;
                end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
      end if;

       -- <codice_fiscale_beneficiario>
      mifCountRec:=mifCountRec+1;
--      if mifFlussoOrdinativoRec.mif_ord_partiva_benef is null and anagraficaBenefCBI is null then
      	 flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
            -- se CASSA codice_fiscale obbligatorio
          	if flussoElabMifElabRec.flussoElabMifParam is not null then
		            if tipoMDPCo is null then
                    	tipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCo is not null and
                       tipoMDPCo=codAccreRec.accredito_gruppo_code then
                       if soggettoRec.codice_fiscale is not null then
                    	flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
                       else
	                    if mifFlussoOrdinativoRec.mif_ord_partiva_benef is not null then
     	                   flussoElabMifValore:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                        end if;
                       end if;
                    end if;
            end if;

            -- se non CASSA valorizzato se partita iva non presente e  codice_fiscale=16
            if flussoElabMifValore is null and
               mifFlussoOrdinativoRec.mif_ord_partiva_benef is null and
               soggettoRec.codice_fiscale is not null and
               length(soggettoRec.codice_fiscale)=16 then
               flussoElabMifValore:=trim ( both ' ' from soggettoRec.codice_fiscale);
            end if;

            if flussoElabMifValore is not null then
		             mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;
            end if;
          else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
         end if;
--        end if;
      -- </beneficiario>


      -- <delegato>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      isMDPCo:=false;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
        if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                    if tipoMDPCo is null then
                    	tipoMDPCo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                	end if;

                    if tipoMDPCo is not null and
                       tipoMDPCo=codAccreRec.accredito_gruppo_code then
                    	isMDPCo:=true;
                    end if;

					if isMDPCo=true and -- non esporre se REGOLARIZZAZIONE ( provvisori di cassa )
                       mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
            		   ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                         or
                         mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
                       )  then -- 20.12.2017 Sofia Jira SIAC-5665
			             isMDPCo=false;
			        end if;
            end if;
         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
      end if;

      -- <anagrafica_delegato>
      mifCountRec:=mifCountRec+1;
      if isMDPCo=true and MDPRec.quietanziante is not null then
        	flussoElabMifElabRec:=null;
      		flussoElabMifValore:=null;

     	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
		    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        	if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	    end if;
            if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                   	mifFlussoOrdinativoRec.mif_ord_anag_quiet:=MDPRec.quietanziante;
           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		         end if;
	        end if;
      end if;

      mifCountRec:=mifCountRec+7;
--      raise notice 'codfisc_quiet mifCountRec=%',mifCountRec;
      -- <codice_fiscale_delegato>
      if isMDPCo=true and mifFlussoOrdinativoRec.mif_ord_anag_quiet is not null and
         MDPRec.quietanziante_codice_fiscale is not null  and
         length(MDPRec.quietanziante_codice_fiscale)=16   then
             flussoElabMifElabRec:=null;
      		 flussoElabMifValore:=null;
             flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; -- 72
		     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        	 if flussoElabMifElabRec.flussoElabMifId is null then
	            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    	     end if;
             if flussoElabMifElabRec.flussoElabMifAttivo=true then
         		if flussoElabMifElabRec.flussoElabMifElab=true then
                   	flussoElabMifValore:=trim ( both ' ' from MDPRec.quietanziante_codice_fiscale);

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_codfisc_quiet:=flussoElabMifValore;
                    end if;

           		else
           			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		        end if;
	         end if;
      end if;
      -- </delegato>

	  -- <creditore_effettivo>
      flussoElabMifElabRec:=null;
      flussoElabMifValore:=null;
      soggettoQuietRec:=null;
      soggettoQuietRifRec:=null;
      soggettoQuietId:=null;
      soggettoQuietRifId:=null;
      mifCountRec:=mifCountRec+1;
      flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
      strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
      if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      end if;

      if flussoElabMifElabRec.flussoElabMifAttivo=true then
         if flussoElabMifElabRec.flussoElabMifElab=true then

	      /* -- 20.04.2018 Sofia JIRA SIAC-6097
          if flussoElabMifElabRec.flussoElabMifParam is not null and
             mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null and
             ( mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3))
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4))
               or -- 13.04.2018 Sofia JIRA SIAC-6097
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5))
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,6))
                 -- 13.04.2018 Sofia JIRA SIAC-6097
               or
               mifFlussoOrdinativoRec.mif_ord_pagam_tipo=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,7))
                 -- 19.04.2018 Sofia JIRA SIAC-6097
             )   then -- 20.12.2017 Sofia JIRA siac-5665

          end if;*/


          -- 20.04.2018 Sofia JIRA SIAC-6097
          if flussoElabMifElabRec.flussoElabMifParam is not null and
           mifFlussoOrdinativoRec.mif_ord_pagam_tipo is not null  then

           flussoElabMifValore:= regexp_replace(flussoElabMifElabRec.flussoElabMifParam,
                                                trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1))||'.'||
                                                trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))||'.',
							                    '');
 		   if  fnc_mif_ordinativo_esenzione_bollo(mifFlussoOrdinativoRec.mif_ord_pagam_tipo,flussoElabMifValore)=true  then
	           flussoElabMifElabRec.flussoElabMifElab=false;
               flussoElabMifValore:=null;
           end if;
          end if;

          if flussoElabMifElabRec.flussoElabMifElab=true then -- non esporre su regolarizzazione (provvisori)
           if  ordCsiRelazTipoId is null then
            if ordCsiRelazTipo is null then
            	if flussoElabMifElabRec.flussoElabMifParam is not null then
	                ordCsiRelazTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    ordCsiCOTipo:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
            end if;

            if ordCsiRelazTipo is  not null then
                select tipo.oil_relaz_tipo_id into ordCsiRelazTipoId
               	from siac_d_oil_relaz_tipo tipo
	            where tipo.ente_proprietario_id=enteProprietarioId
    	          and tipo.oil_relaz_tipo_code=ordCsiRelazTipo
        	      and tipo.data_cancellazione is null
                  and tipo.validita_fine is null;
            end if;
           end if;

           if ordCsiRelazTipoId is not null and
              ( ordCsiCOTipo is null or ordCsiCOTipo!=codAccreRec.accredito_gruppo_code ) then

                soggettoQuietId:=MDPRec.soggetto_id;

                select sogg.*
                       into  soggettoQuietRec
                from siac_t_soggetto sogg, siac_r_soggrel_modpag relmdp,siac_r_soggetto_relaz relsogg,
                     siac_r_oil_relaz_tipo roil
                where sogg.soggetto_id=MDPRec.soggetto_id
                and   sogg.data_cancellazione is null
                and   sogg.validita_fine is null
                and   relmdp.modpag_id=MDPRec.modpag_id
                and   relmdp.data_cancellazione is null
                -- and   relmdp.validita_fine is null 04.04.2018 Sofia SIAC-6064
                -- 04.04.2018 Sofia SIAC-6064
			    and date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(relmdp.validita_fine,dataElaborazione))
    			and   relmdp.soggetto_relaz_id=relsogg.soggetto_relaz_id
                and   relsogg.soggetto_id_a=MDPRec.soggetto_id
                and   relsogg.soggetto_id_da=soggettoRifId
                and   roil.relaz_tipo_id=relsogg.relaz_tipo_id
                and   roil.oil_relaz_tipo_id=ordCsiRelazTipoId
                and   relsogg.data_cancellazione is null
                and   relsogg.validita_fine is null
                and   roil.data_cancellazione is null
                and   roil.validita_fine is null;

				if soggettoQuietRec is null then
                	soggettoQuietId:=null;
                end if;

               if soggettoQuietId is not null then
                 select sogg.*
                        into soggettoQuietRifRec
		         from  siac_t_soggetto sogg, siac_r_soggetto_relaz rel
		         where rel.soggetto_id_a=soggettoQuietRec.soggetto_id
		         and   rel.relaz_tipo_id=ordSedeSecRelazTipoId
		         and   rel.ente_proprietario_id=enteProprietarioId
		         and   rel.data_cancellazione is null
                 and   rel.validita_fine is null
                 and   sogg.soggetto_id=rel.soggetto_id_da
		         and   sogg.data_cancellazione is null
                 and   sogg.validita_fine is null;


                 if soggettoQuietRifRec is null then

                 else
                 	soggettoQuietRifId:=soggettoQuietRifRec.soggetto_id;
                 end if;
               end if;
            end if;
          end if;
       else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
       end if;
      end if;

      mifCountRec:=mifCountRec+1;
  	  -- <anagrafica_creditore_effettivo>
      if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;

	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec]; --63
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
	            if soggettoQuietRifId is not null then
    	        	flussoElabMifValore:=soggettoQuietRifRec.soggetto_desc||' '||soggettoQuietRec.soggetto_desc;
        	    else
            		flussoElabMifValore:=soggettoQuietRec.soggetto_desc;
	            end if;

                if flussoElabMifValore is not null then
--                	mifFlussoOrdinativoRec.mif_ord_anag_del:=substring(flussoElabMifValore from 1 for 140);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in creditore_effettivo -- anagrafica_beneficiario
                    mifFlussoOrdinativoRec.mif_ord_anag_del:=mifFlussoOrdinativoRec.mif_ord_anag_benef;
                    mifFlussoOrdinativoRec.mif_ord_indir_del:=mifFlussoOrdinativoRec.mif_ord_indir_benef;
                    mifFlussoOrdinativoRec.mif_ord_cap_del:=mifFlussoOrdinativoRec.mif_ord_cap_benef;
                    mifFlussoOrdinativoRec.mif_ord_localita_del:=mifFlussoOrdinativoRec.mif_ord_localita_benef;
                    mifFlussoOrdinativoRec.mif_ord_prov_del:=mifFlussoOrdinativoRec.mif_ord_prov_benef;
                    mifFlussoOrdinativoRec.mif_ord_partiva_del:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                    mifFlussoOrdinativoRec.mif_ord_codfisc_del:=mifFlussoOrdinativoRec.mif_ord_codfisc_benef;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_anag_benef:=substring(flussoElabMifValore from 1 for 140);

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
	  end if;

      mifCountRec:=mifCountRec+1;
      -- <indirizzo_creditore_effettivo>
      if soggettoQuietId is not null then
         flussoElabMifElabRec:=null;
         flussoElabMifValore:=null;
         indirizzoRec:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

                select * into indirizzoRec
                from siac_t_indirizzo_soggetto indir
                where indir.soggetto_id=soggettoQuietId
                and   (case when soggettoQuietRifId is null
                            then indir.principale='S' else coalesce(indir.principale,'N')='N' end)
                and   indir.data_cancellazione is null
                and   indir.validita_fine is null;

                if indirizzoRec is null then
                    isIndirizzoBenQuiet:=false;
            	end if;

			    if isIndirizzoBenQuiet=true then

            	 if indirizzoRec.via_tipo_id is not null then
            		select tipo.via_tipo_code into flussoElabMifValore
                	from siac_d_via_tipo tipo
               		where tipo.via_tipo_id=indirizzoRec.via_tipo_id
	                and   tipo.data_cancellazione is null
    	     	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 			 		and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

                	if flussoElabMifValore is not null then
                		flussoElabMifValore:=flussoElabMifValore||' ';
               	    end if;

           		  end if;

	             flussoElabMifValore:=trim(both from coalesce(flussoElabMifValore,'')||coalesce(indirizzoRec.toponimo,'')
    	                             ||' '||coalesce(indirizzoRec.numero_civico,''));

        	     if flussoElabMifValore is not null then
--	        	    mifFlussoOrdinativoRec.mif_ord_indir_del:=substring(flussoElabMifValore from 1 for 30);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_indir_benef:=substring(flussoElabMifValore from 1 for 30);
	             end if;
                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

	 -- <cap_creditore_effettivo>
     mifCountRec:=mifCountRec+1;
     if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
--         		mifFlussoOrdinativoRec.mif_ord_cap_del:=lpad(indirizzoRec.zip_code,5,'0');

				-- 24.01.2018 Sofia jira siac-5765 - scambio tag
                -- in anagrafica_beneficiario -- creditore_effettivo
                mifFlussoOrdinativoRec.mif_ord_cap_benef:=lpad(indirizzoRec.zip_code,5,'0');
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;

         end if;
        end if;
     end if;


     -- <localita_creditore_effettivo>
     mifCountRec:=mifCountRec+1;
     if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

            	select com.comune_desc into flussoElabMifValore
           		from siac_t_comune com
	            where com.comune_id=indirizzoRec.comune_id
    	        and   com.data_cancellazione is null
                and   com.validita_fine is null;

	            if flussoElabMifValore is not null then
--		            mifFlussoOrdinativoRec.mif_ord_localita_del:=substring(flussoElabMifValore from 1 for 30);

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_localita_benef:=substring(flussoElabMifValore from 1 for 30);
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <provincia_creditore_effettivo>
	 if isIndirizzoBenQuiet=true then
        if soggettoQuietId is not null and indirizzoRec.comune_id is not null then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then

            	select prov.sigla_automobilistica into flussoElabMifValore
            	from siac_r_comune_provincia provRel, siac_t_provincia prov
           		where provRel.comune_id=indirizzoRec.comune_id
           	  	and   provRel.data_cancellazione is null
                and   provRel.validita_fine is null
        	    and   prov.provincia_id=provRel.provincia_id
            	and   prov.data_cancellazione is null
                and   prov.validita_fine is null
        	    order by provRel.data_creazione;

	            if flussoElabMifValore is not null then
--		            mifFlussoOrdinativoRec.mif_ord_prov_del:=flussoElabMifValore;
                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_prov_benef:=flussoElabMifValore;
        	    end if;
            else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
        end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <stato_creditore_effettivo>
     if soggettoQuietId is not null  then
        flussoElabMifElabRec:=null;
        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
       if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
       end if;
       if flussoElabMifElabRec.flussoElabMifAttivo=true then
          if flussoElabMifElabRec.flussoElabMifElab=true then
         	if statoDelegatoCredEff=false then
	            statoDelegatoCredEff:=true;
                -- valorizzato poi in piazzatura
            end if;
          else
           RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
          end if;
       end if;
     end if;

     mifCountRec:=mifCountRec+1;
	 -- <partita_iva_creditore_effettivo>
     if soggettoQuietId is not null THEN
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
                if  soggettoQuietRifId is not null then
	            	if soggettoQuietRifRec.partita_iva is not null  or
                       (soggettoQuietRifRec.partita_iva is null and
                        soggettoQuietRifRec.codice_fiscale is not null and length(soggettoQuietRifRec.codice_fiscale)=11)
                       then
                       	if soggettoQuietRifRec.partita_iva is not null then
	    	             flussoElabMifValore:=soggettoQuietRifRec.partita_iva;
                        else
                         flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                        end if;
                     end if;
				else
                	if soggettoQuietRec.partita_iva is not null  or
                       (soggettoQuietRec.partita_iva is null and
                        soggettoQuietRec.codice_fiscale is not null and length(soggettoQuietRec.codice_fiscale)=11)
                       then
                       	if soggettoQuietRec.partita_iva is not null then
	    	             flussoElabMifValore:=soggettoQuietRec.partita_iva;
                        else
                         flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                        end if;
                    end if;
                end if;

			    if flussoElabMifValore is not null then
--	                mifFlussoOrdinativoRec.mif_ord_partiva_del:=flussoElabMifValore;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
                    mifFlussoOrdinativoRec.mif_ord_partiva_benef:=flussoElabMifValore;

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     mifCountRec:=mifCountRec+1;
     -- <codice_fiscale_creditore_effettivo>
     if soggettoQuietId is not null  then
         flussoElabMifElabRec:=null;
		 flussoElabMifValore:=null;
         flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;

         if flussoElabMifElabRec.flussoElabMifAttivo=true then
         	if flussoElabMifElabRec.flussoElabMifElab=true then
            	if soggettoQuietRifId is not null then
                 if mifFlussoOrdinativoRec.mif_ord_partiva_del is null then
                  if soggettoQuietRifRec.codice_fiscale is not null and
                     length(soggettoQuietRifRec.codice_fiscale)= 16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRifRec.codice_fiscale);
                  end if;
                 end if;
                else
                 if soggettoQuietRec.codice_fiscale is not null and
                    length(soggettoQuietRec.codice_fiscale)=16 then
	                 flussoElabMifValore:=trim ( both ' ' from soggettoQuietRec.codice_fiscale);
                 end if;
                end if;

				if flussoElabMifValore is not null then
--	                mifFlussoOrdinativoRec.mif_ord_codfisc_del:=flussoElabMifValore;

                    -- 24.01.2018 Sofia jira siac-5765 - scambio tag
                    -- in anagrafica_beneficiario -- creditore_effettivo
  		            mifFlussoOrdinativoRec.mif_ord_codfisc_benef:=flussoElabMifValore;

                end if;
         	else
            	RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
        end if;
     end if;

     -- </creditore_effettivo>
/**/
	 -- <piazzatura>
     flussoElabMifElabRec:=null;
     isOrdPiazzatura:=false;
     accreditoGruppoCode:=null;
     isPaeseSepa:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--     raise notice 'piazzatura mifCountRec=%',mifCountRec;
     if flussoElabMifElabRec.flussoElabMifId is null then
      	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
       	 if flussoElabMifElabRec.flussoElabMifParam is not null then
            isOrdPiazzatura:=fnc_mif_ordinativo_piazzatura_splus(MDPRec.accredito_tipo_id,
                                                           		 mifOrdinativoIdRec.mif_ord_codice_funzione,
		  												         flussoElabMifElabRec.flussoElabMifParam,
                                                                 mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
			                                                     dataElaborazione,dataFineVal,enteProprietarioId);
         end if;
      	else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
        end if;
     end if;

     if isOrdPiazzatura=true then

      	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura tipo accredito MDP per popolamento  campi relativi a'||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

--        raise notice 'Ordinativo con piazzatura % codice funzione=%',mifOrdinativoIdRec.mif_ord_ord_id,mifOrdinativoIdRec.mif_ord_codice_funzione;

		accreditoGruppoCode:=codAccreRec.accredito_gruppo_code;
	    --raise notice 'accreditoGruppoCode=% ',accreditoGruppoCode;

        if MDPRec.iban is not null and length(MDPRec.iban)>2  then
        	select distinct 1 into isPaeseSepa
            from siac_t_sepa sepa
            where sepa.sepa_iso_code=substring(upper(MDPRec.iban) from 1 for 2)
            and   sepa.ente_proprietario_id=enteProprietarioId
            and   sepa.data_cancellazione is null
      	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
 			and	  date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));
        end if;
     end if;


     -- <abi_beneficiario>
 	 mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;

	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 6 for 5);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;


                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_abi_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
	 end if;

     -- <cab_beneficiario>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
         flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
 	     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
         end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 11 for 5);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cab_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <numero_conto_corrente_beneficiario>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;
                    if tipoMDPCCP is null or tipoMDPCCP='' then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 16 for 12);
                    end if;

                    if tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode and
                       coalesce(MDPRec.contocorrente,NVL_STR)!=NVL_STR then
                       flussoElabMifValore:=lpad(MDPRec.contocorrente,NUM_DODICI,ZERO_PAD);
                    end if;

                    --raise notice 'numero_conto_corrente_beneficiario';
                    --raise notice 'tipoMDPCCP=% ',tipoMDPCCP;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cc_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <caratteri_controllo>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
	    flussoElabMifElabRec:=null;
    	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;

                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 3 for 2);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_ctrl_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	end if;
     end if;


     -- <codice_cin>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;


					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 5 for 1);
                    end if;

                    -- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cin_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;

     -- <codice_paese>
	 mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true then
        flussoElabMifElabRec:=null;
     	flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	end if;
        if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;
                    if tipoPaeseCB is null then
	                    tipoPaeseCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                    end if;

					-- 15.01.2018 Sofia JIRA SIAC-5765
					if tipoMDPCCP is null then
                    	tipoMDPCCP:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.iban is not null and length(MDPRec.iban)>2 and
                       tipoPaeseCB is not null and tipoPaeseCB=substring(upper(MDPRec.iban) from 1 for 2) then -- solo IT
                       	flussoElabMifValore:=substring(upper(MDPRec.iban) from 1 for 2);
                    end if;


					-- 15.01.2018 Sofia JIRA SIAC-5765
                    if flussoElabMifValore is null and
                       flussoElabMifElabRec.flussoElabMifDef is not null and
                       tipoMDPCCP is not null and tipoMDPCCP=accreditoGruppoCode then
                       flussoElabMifValore:=flussoElabMifElabRec.flussoElabMifDef;
                    end if;

                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_cod_paese_benef:=flussoElabMifValore;
--                        raise notice 'statoBenficiario=%',statoBeneficiario;
                        if statoBeneficiario=true and statoDelegatoCredEff=false then -- se CSI IBAN non riporta dati del beneficiario quindi omettiamo codice_paese
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                        if statoDelegatoCredEff=true then
--	                        mifFlussoOrdinativoRec.mif_ord_stato_del:=flussoElabMifValore;
                            -- 24.01.2018 Sofia jira siac-5765
                            mifFlussoOrdinativoRec.mif_ord_stato_del:=mifFlussoOrdinativoRec.mif_ord_stato_benef;
                            mifFlussoOrdinativoRec.mif_ord_stato_benef:=flussoElabMifValore;
                        end if;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
       end if;
     end if;


     -- extra sepa
     -- <denominazione_banca_destinataria>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true and isPaeseSepa is null then
		 flussoElabMifElabRec:=null;
     	 flussoElabMifValore:=null;
		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
         strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifParam is not null then
                	if tipoMDPCB is null then
	                    tipoMDPCB:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                    end if;


                    if tipoMDPCB is not null and tipoMDPCB=accreditoGruppoCode and
                       MDPRec.banca_denominazione is not null  then
                       	flussoElabMifValore:=MDPRec.banca_denominazione;
                    end if;
                    if flussoElabMifValore is not null then
                    	mifFlussoOrdinativoRec.mif_ord_denom_banca_benef:=flussoElabMifValore;
                    end if;
    	        end if;
    	  	else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
     	 end if;
     end if;
     -- </piazzatura>

     -- sezione esteri sepa
     -- <sepa_credit_transfer>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and isPaeseSepa is not null then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     if flussoElabMifElabRec.flussoElabMifParam is not null then
                if paeseSepaTr is null then
	        	   	paeseSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if accreditoGruppoSepaTr is null then
	            	accreditoGruppoSepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;
                if SepaTr is null then
		            SepaTr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3));
                end if;

    	        if accreditoGruppoSepaTr is not null and SepaTr is not null and paeseSepaTr is not null then
	    	        sepaCreditTransfer:=true;
            	end if;
             end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     -- <iban>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and sepaCreditTransfer=true
        and isPaeseSepa is not null
        and accreditoGruppoSepaTr=accreditoGruppoCode then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     	if MDPRec.iban is not null and length(MDPRec.iban)>=2 and
        		   substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
		           	mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr:=MDPRec.iban;

                   -- 01.10.2018 Sofia SIAC-6421
                   if coalesce(substring(upper(MDPRec.iban) from 1 for 2),'')!='' then
--                        raise notice 'statoBenficiario=%',statoBeneficiario;
                        if statoBeneficiario=true and statoDelegatoCredEff=false then
                        	mifFlussoOrdinativoRec.mif_ord_stato_benef:=substring(upper(MDPRec.iban) from 1 for 2);
                        end if;
                        if statoDelegatoCredEff=true then
                            mifFlussoOrdinativoRec.mif_ord_stato_del:=mifFlussoOrdinativoRec.mif_ord_stato_benef;
                            mifFlussoOrdinativoRec.mif_ord_stato_benef:=substring(upper(MDPRec.iban) from 1 for 2);
                        end if;
                    end if;

        		end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;

     -- <bic>
     mifCountRec:=mifCountRec+1;
     if isOrdPiazzatura=true
        and sepaCreditTransfer=true
        and isPaeseSepa is not null
        and accreditoGruppoSepaTr=accreditoGruppoCode then
     	flussoElabMifElabRec:=null;
   	    flussoElabMifValore:=null;
	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	     if flussoElabMifElabRec.flussoElabMifId is null then
      		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;
         if flussoElabMifElabRec.flussoElabMifAttivo=true then
      		if flussoElabMifElabRec.flussoElabMifElab=true then
		     	if MDPRec.bic is not null and
                   MDPRec.iban is not null and length(MDPRec.iban)>=2 and
        		   substring(upper(MDPRec.iban) from 1 for 2)!=paeseSepaTr then
		           mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr:=MDPRec.bic;
        		end if;
            else
        	    RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
         end if;
     end if;
     mifCountRec:=mifCountRec+5;
     -- </sepa_credit_transfer>


     -- <causale> ancora informazioni_beneficiario
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifValore:=null;
     flussoElabMifValoreDesc:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
--     raise notice 'causale mifCountRec=%',mifCountRec;
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifParam is not null then
            	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Lettura CUP-CIG.';
            	if cupCausAttr is null then
	            	cupCausAttr:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if cigCausAttr is null then
	                cigCausAttr:=trim (both ' '	 from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
                end if;

                if coalesce(cupCausAttr,NVL_STR)!=NVL_STR  and cupCausAttrId is null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cupCausAttr||'.';
                	select attr.attr_id into cupCausAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cupCausAttr
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;

                end if;

                if coalesce(cigCausAttr,NVL_STR)!=NVL_STR and cigCausAttrId is null then

                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura attr_id '||cigCausAttr||'.';
                	select attr.attr_id into cigCausAttrId
                    from siac_t_attr attr
                    where attr.ente_proprietario_id=enteProprietarioId
                    and   attr.attr_code=cigCausAttr
                    and   attr.data_cancellazione is null
                    and   attr.validita_fine is null;

                end if;


                if cupCausAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupCausAttr||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValore
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cupCausAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValore,NVL_STR)=NVL_STR then
                       	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cupCausAttr||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValore
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cupCausAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;
                    end if;
                end if;

                if cigCausAttrId is not null then
                	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigCausAttr||' [siac_r_ordinativo_attr].';

                	select a.testo into flussoElabMifValoreDesc
                    from siac_r_ordinativo_attr a
                    where a.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                    and   a.attr_id=cigCausAttrId
                    and   a.data_cancellazione is null
                    and   a.validita_fine is null;

                    if coalesce(flussoElabMifValoreDesc,NVL_STR)=NVL_STR then
                       	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
	                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
    	                   ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
        	               ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
            	           ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                	       ||' mifCountRec='||mifCountRec
                    	   ||' tipo flusso '||MANDMIF_TIPO||'. Lettura valore '||cigCausAttr||' [siac_r_liquidazione_attr].';

                    	select a.testo into flussoElabMifValoreDesc
                        from siac_r_liquidazione_attr  a
                        where a.liq_id=mifOrdinativoIdRec.mif_ord_liq_id
                        and   a.attr_id=cigCausAttrId
                        and   a.data_cancellazione is null
	                    and   a.validita_fine is null;
                    end if;
                end if;

            end if;
            -- cup
			if coalesce(flussoElabMifValore,NVL_STR)!=NVL_STR then
			       	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=cupCausAttr||' '||flussoElabMifValore;

            end if;
            -- cig
			if coalesce(flussoElabMifValoreDesc,NVL_STR)!=NVL_STR  then
                	mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
                      trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||
                           ' '||cigCausAttr||' '||flussoElabMifValoreDesc);
            end if;


			mifFlussoOrdinativoRec.mif_ord_pagam_causale:=
      			replace(replace(substring(trim (both ' ' from coalesce(mifFlussoOrdinativoRec.mif_ord_pagam_causale,' ')||' '||mifOrdinativoIdRec.mif_ord_desc )
	                            from 1 for 370) , chr(VT_ASCII),chr(SPACE_ASCII)),chr(BS_ASCII),NVL_STR);

--			raise notice 'mifFlussoOrdinativoRec.mif_ord_pagam_causale %',mifFlussoOrdinativoRec.mif_ord_pagam_causale;


	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;

     -- <sospeso>
     -- <numero_provvisorio>
     -- <importo_provvisorio>
     mifCountRec:=mifCountRec+2;

	 -- <ritenuta>
     -- <importo_ritenute>
     -- <numero_reversale>
     -- <progressivo_versante>
     mifCountRec:=mifCountRec+3;

	 -- <informazioni_aggiuntive>

     -- <lingua>
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
        	if flussoElabMifElabRec.flussoElabMifDef is not null then
        		mifFlussoOrdinativoRec.mif_ord_lingua:=flussoElabMifElabRec.flussoElabMifDef;

--                raise notice 'LINGUA def % %',flussoElabMifElabRec.flusso_elab_mif_campo,flussoElabMifElabRec.flussoElabMifDef;
            end if;
	     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     end if;
     end if;


    -- <riferimento_documento_esterno>
    mifCountRec:=mifCountRec+1;
    if tipoPagamRec is not null then
    	flussoElabMifElabRec:=null;
        flussoElabMifValore:=null;
        flussoElabMifValoreDesc:=null;
        codResult:=null;

        flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
	    if flussoElabMifElabRec.flussoElabMifId is null then
  		 	RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;
    	if flussoElabMifElabRec.flussoElabMifAttivo=true then
    		if flussoElabMifElabRec.flussoElabMifElab=true then
        		if flussoElabMifElabRec.flussoElabMifDef is not null and
                   flussoElabMifElabRec.flussoElabMifParam is not null then

				    -- 30.07.2018 Sofia siac-6202
                    if coalesce(trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5)),'')!='' then

                       select 1 into codResult
                       from siac_r_ordinativo_class rc, siac_t_class c , siac_d_class_tipo tipo
                       where tipo.ente_proprietario_id=enteProprietarioId
                       and   tipo.classif_tipo_code=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,5))
                       and   c.classif_tipo_id=tipo.classif_tipo_id
                       and   rc.classif_id=c.classif_id
                       and   rc.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
                       and   rc.data_cancellazione is null
                       and   rc.validita_fine is null;

                       if codResult is not null then
		                   select * into flussoElabMifValore
                           from fnc_mif_ordinativo_splus_get_mese(mifOrdinativoIdRec.mif_ord_data_emissione);
                       end if;

                       if coalesce(flussoElabMifValore,'')!='' then
                       	flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,3))
                                             ||' '||flussoElabMifValore;
                       end if;
                    end if;
                    -- 30.07.2018 Sofia siac-6202


                    -- modalita accredito=STI - STIPENDI
                    if coalesce(flussoElabMifValore,'')='' and -- 30.07.2018 Sofia siac-6202
                       codAccreRec.accredito_tipo_code =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,3)) then
                           flussoElabMifValore:=
                             trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,2));
                    end if;

                    if  coalesce(flussoElabMifValore,'')='' and -- 30.07.2018 Sofia siac-6202
                        tipoPagamRec.descTipoPagamento in
                        (trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)),
                         trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2))
                        ) then
		                flussoElabMifValore:=tipoPagamRec.descTipoPagamento;
                    end if;

                    -- 23.01.2018 Sofia jira siac-5765
			        if coalesce(flussoElabMifValore,'')='' and -- 30.07.2018 Sofia siac-6202
                       codAccreRec.accredito_gruppo_code =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,4)) and
                           MDPRec.contocorrente is not null and MDPRec.contocorrente!=''
                            then
                           flussoElabMifValore:=MDPRec.contocorrente;
                    end if;
                    -- 23.01.2018 Sofia jira siac-5765

                    if coalesce(flussoElabMifValore,'')='' and tipoPagamRec.defRifDocEsterno=true then
                        flussoElabMifValore:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifDef,SEPARATORE,1));
                    end if;

                    if coalesce(flussoElabMifValore,'')!='' then
	                    mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno:=flussoElabMifValore;
                    end if;
		        end if;
			else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
		    end if;
    	end if;
    end if;

    -- 16.09.2019 Sofia SIAC-6840 - vedi di seguito implementazione tag
    -- <avviso_pagoPA>
    -- <codice_identificativo_ente>
    -- <numero_avviso>
    -- </avviso_pagoPA>

    -- </informazioni_aggiuntive>




    -- <sostituzione_mandato>

    flussoElabMifElabRec:=null;
    ordSostRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
    end if;
    if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	if flussoElabMifElabRec.flussoElabMifElab=true then
                	select * into ordSostRec
                    from fnc_mif_ordinativo_sostituito( mifOrdinativoIdRec.mif_ord_ord_id,
 														ordRelazCodeTipoId,
                                                        dataElaborazione,dataFineVal);
    	else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	    end if;

    end if;

   mifCountRec:=mifCountRec+3;
   if ordSostRec is not null then
   		 flussoElabMifElabRec:=null;
   		 flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-2];
	     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-2
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         -- <numero_mandato_da_sostituire>
      	 if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
      	 end if;

      	 if flussoElabMifElabRec.flussoElabMifAttivo=true then
     	   if flussoElabMifElabRec.flussoElabMifElab=true then
--        		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=lpad(ordSostRec.ordNumeroSostituto::varchar,NUM_SETTE,ZERO_PAD);
                mifFlussoOrdinativoRec.mif_ord_num_ord_colleg:=ordSostRec.ordNumeroSostituto::varchar;
	    	else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	     	end if;
         end if;

     	-- <progressivo_beneficiario_da_sostuire>
     	flussoElabMifElabRec:=null;
  	    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec-1];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec-1
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
            	if flussoElabMifElabRec.flussoElabMifDef is not null then
                	mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg:=flussoElabMifElabRec.flussoElabMifDef;
                end if;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;

        -- <esercizio_mandato_da_sostituire>
        flussoElabMifElabRec:=null;
		flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    	if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	    end if;

        if flussoElabMifElabRec.flussoElabMifAttivo=true then
     		if flussoElabMifElabRec.flussoElabMifElab=true then
               	mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg:=ordSostRec.ordAnnoSostituto;
     	    else
     			RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	        end if;
	    end if;

     end if;


     -- <dati_a_disposizione_ente_beneficiario> facoltativo non valorizzato
     -- </informazioni_beneficiario>

     -- <dati_a_disposizione_ente_mandato>
	 -- <codice_distinta>
     flussoElabMifElabRec:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifValore:=null;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	 strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	 end if;

     if flussoElabMifElabRec.flussoElabMifAttivo=true then
      if flussoElabMifElabRec.flussoElabMifElab=true then
      		if mifOrdinativoIdRec.mif_ord_dist_id is not null then
				strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'. Lettura distinta [siac_d_distinta].';
            	select  d.dist_code into flussoElabMifValore
                from siac_d_distinta d
                where d.dist_id=mifOrdinativoIdRec.mif_ord_dist_id;
            end if;

            if flussoElabMifValore is not null then
              	mifFlussoOrdinativoRec.mif_ord_codice_distinta:=flussoElabMifValore;
            end if;
      else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
	 end if;

     -- <atto_contabile>
     flussoElabMifElabRec:=null;
     flussoElabMifValore:=null;
     mifCountRec:=mifCountRec+1;
     flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
     strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
     if flussoElabMifElabRec.flussoElabMifId is null then
            RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
     end if;
     if flussoElabMifElabRec.flussoElabMifAttivo=true then
	     if flussoElabMifElabRec.flussoElabMifElab=true then
         	if flussoElabMifElabRec.flussoElabMifParam is not null then
                if attoAmmTipoAllRag is null then
            		attoAmmTipoAllRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1));
                end if;
                if attoAmmStrTipoRag is null then
                	attoAmmStrTipoRag:=trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,2));
         		end if;

                if attoAmmTipoAllRag is not null and  attoAmmStrTipoRag is not null then

                 flussoElabMifValore:=fnc_mif_estremi_attoamm_all(mifOrdinativoIdRec.mif_ord_atto_amm_id,
                 										          attoAmmTipoAllRag,attoAmmStrTipoRag,
                                                                  dataElaborazione, dataFineVal);

                end if;
          	end if;

            if flussoElabMifValore is not null then
                 	mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile:=flussoElabMifValore;
            end if;

         else
            RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
         end if;
        end if;

      -- 15.01.2018 Sofia SIAC-5765
      -- <codice_operatore>
	  flussoElabMifElabRec:=null;
	  flussoElabMifValore:=null;
	  flussoElabMifValoreDesc:=null;
	  mifCountRec:=mifCountRec+1;
	  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';

	  if flussoElabMifElabRec.flussoElabMifId is null then
  		  RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	  end if;
	  if flussoElabMifElabRec.flussoElabMifAttivo=true then
   		if flussoElabMifElabRec.flussoElabMifElab=true then


         if mifOrdinativoIdRec.mif_ord_login_creazione is not null then
			flussoElabMifValore:=mifOrdinativoIdRec.mif_ord_login_creazione;
         end if;

         if flussoElabMifValore is not null then
        	select substring(s.soggetto_desc  from 1 for 12)  into flussoElabMifValoreDesc
			from siac_t_account a, siac_r_soggetto_ruolo r, siac_t_soggetto s
			where a.ente_proprietario_id=enteProprietarioId
            and   a.account_code=flussoElabMifValore
			and   r.soggeto_ruolo_id=a.soggeto_ruolo_id
			and   s.soggetto_id=r.soggetto_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   a.data_cancellazione is null
            and   a.validita_fine is null;

            if 	flussoElabMifValoreDesc is not null then
            	flussoElabMifValore:=flussoElabMifValoreDesc;
            end if;
         end if;

         if flussoElabMifValore is not null then
            mifFlussoOrdinativoRec.mif_ord_code_operatore:=substring(flussoElabMifValore from 1 for 12);
         end if;
       else
		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
  	   end if;
     end if;

     -- </dati_a_disposizione_ente_mandato>


    -- 09.09.2019 Sofia SIAC-6840
    -- <avviso_pagoPA>
    isPagoPA:=false;
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifValore:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	end if;

    if flussoElabMifElabRec.flussoElabMifAttivo=true then
     if flussoElabMifElabRec.flussoElabMifElab=true then
            if flussoElabMifElabRec.flussoElabMifParam is not null and
               tipoPagamRec.descTipoPagamento =
                           trim (both ' ' from split_part(flussoElabMifElabRec.flussoElabMifParam,SEPARATORE,1)) then
                 isPagoPA :=true;
            end if;
     else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	 end if;
	end if;

    -- <codice_identificativo_ente>
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifValore:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	end if;

    if flussoElabMifElabRec.flussoElabMifAttivo=true then
     if flussoElabMifElabRec.flussoElabMifElab=true then

	     if isPagoPA  = true then
            if  mifFlussoOrdinativoRec.mif_ord_codfisc_benef is not null then
            	mifFlussoOrdinativoRec.mif_ord_pagopa_codfisc:=mifFlussoOrdinativoRec.mif_ord_codfisc_benef;
            else
                if  mifFlussoOrdinativoRec.mif_ord_partiva_benef is not null then
	                mifFlussoOrdinativoRec.mif_ord_pagopa_codfisc:=mifFlussoOrdinativoRec.mif_ord_partiva_benef;
                end if;
            end if;
		end if;
      else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
	end if;
    -- </codice_identificativo_ente>


    -- <numero_avviso>
    flussoElabMifElabRec:=null;
    mifCountRec:=mifCountRec+1;
    flussoElabMifValore:=null;
    flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    if flussoElabMifElabRec.flussoElabMifId is null then
  	 		RAISE EXCEPTION ' Configurazione tag/campo non presente in archivio.';
	end if;

    if flussoElabMifElabRec.flussoElabMifAttivo=true then
     if flussoElabMifElabRec.flussoElabMifElab=true then
	     if isPagoPA  = true then
            strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO
                       ||'. Lettura numero avviso PagoPA'
                       ||'.';
            select doc.cod_avviso_pago_pa into flussoElabMifValore
            from siac_t_ordinativo_ts ts ,siac_r_subdoc_ordinativo_ts r,siac_t_subdoc sub,siac_t_doc doc
            where ts.ord_id=mifOrdinativoIdRec.mif_ord_ord_id
            and   r.ord_ts_id=ts.ord_ts_id
            and   sub.subdoc_id=r.subdoc_id
            and   doc.doc_id=sub.doc_id
            and   doc.cod_avviso_pago_pa is not null
            and   doc.cod_avviso_pago_pa!=''
            and   ts.data_cancellazione is null
            and   ts.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   sub.data_cancellazione is null
            and   sub.validita_fine is null
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null
            limit 1;

            if  flussoElabMifValore is not null and flussoElabMifValore!='' then
            	mifFlussoOrdinativoRec.mif_ord_pagopa_num_avviso:=flussoElabMifValore;
            end if;
		 end if;
      else
     		RAISE EXCEPTION ' Configurazione tag/campo  non elaborabile.';
	  end if;
	end if;
    -- </numero_avviso>
    -- </avviso_pagoPA>
    -- 09.09.2019 Sofia SIAC-6840

     -- </mandato>
/**/
        /*raise notice 'codice_funzione= %',mifFlussoOrdinativoRec.mif_ord_codice_funzione;
		raise notice 'numero_mandato= %',mifFlussoOrdinativoRec.mif_ord_numero;
        raise notice 'data_mandato= %',mifFlussoOrdinativoRec.mif_ord_data;
        raise notice 'importo_mandato= %',mifFlussoOrdinativoRec.mif_ord_importo;*/

		 strMessaggio:='Inserimento mif_t_ordinativo_spesa per ord. numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
        INSERT INTO mif_t_ordinativo_spesa
        (
  		-- mif_ord_data_elab, def now
  		 mif_ord_flusso_elab_mif_id,
 		 mif_ord_bil_id,
 		 mif_ord_ord_id,
  		 mif_ord_anno,
  		 mif_ord_numero,
  		 mif_ord_codice_funzione,
  		 mif_ord_data,
  		 mif_ord_importo,
  		 mif_ord_flag_fin_loc,
  		 mif_ord_documento,
  		 mif_ord_bci_tipo_ente_pag,
  		 mif_ord_bci_dest_ente_pag,
  		 mif_ord_bci_conto_tes,
 		 mif_ord_estremi_attoamm,
         mif_ord_resp_attoamm,
         mif_ord_uff_resp_attomm,
  		 mif_ord_codice_abi_bt,
  		 mif_ord_codice_ente,
  		 mif_ord_desc_ente,
  		 mif_ord_codice_ente_bt,
  		 mif_ord_anno_esercizio,
         mif_ord_codice_flusso_oil,
  		 mif_ord_id_flusso_oil,
  		 mif_ord_data_creazione_flusso,
  		 mif_ord_anno_flusso,
 		 mif_ord_codice_struttura,
  		 mif_ord_ente_localita,
  		 mif_ord_ente_indirizzo,
 		 mif_ord_codice_raggrup,
  		 mif_ord_progr_benef,
         mif_ord_progr_dest,
  		 mif_ord_bci_conto,
  		 mif_ord_bci_tipo_contabil,
  		 mif_ord_class_codice_cge,
  		 mif_ord_class_importo,
  		 mif_ord_class_codice_cup,
  		 mif_ord_class_codice_gest_prov,
  		 mif_ord_class_codice_gest_fraz,
  		 mif_ord_codifica_bilancio,
         mif_ord_capitolo,
  		 mif_ord_articolo,
  		 mif_ord_desc_codifica,
         mif_ord_desc_codifica_bil,
  		 mif_ord_gestione,
  		 mif_ord_anno_res,
  		 mif_ord_importo_bil,
  		 mif_ord_stanz,
    	 mif_ord_mandati_stanz,
  		 mif_ord_disponibilita,
  		 mif_ord_prev,
  		 mif_ord_mandati_prev,
  		 mif_ord_disp_cassa,
  		 mif_ord_anag_benef,
  		 mif_ord_indir_benef,
  		 mif_ord_cap_benef,
  		 mif_ord_localita_benef,
  		 mif_ord_prov_benef,
         mif_ord_stato_benef,
  		 mif_ord_partiva_benef,
  		 mif_ord_codfisc_benef,
  		 mif_ord_anag_quiet,
  		 mif_ord_indir_quiet,
  		 mif_ord_cap_quiet,
  		 mif_ord_localita_quiet,
  		 mif_ord_prov_quiet,
  		 mif_ord_partiva_quiet,
  		 mif_ord_codfisc_quiet,
	     mif_ord_stato_quiet,
  		 mif_ord_anag_del,
         mif_ord_indir_del,
         mif_ord_cap_del,
         mif_ord_localita_del,
         mif_ord_prov_del,
  		 mif_ord_codfisc_del,
         mif_ord_partiva_del,
         mif_ord_stato_del,
  		 mif_ord_invio_avviso,
  		 mif_ord_abi_benef,
  		 mif_ord_cab_benef,
  		 mif_ord_cc_benef_estero,
 		 mif_ord_cc_benef,
         mif_ord_ctrl_benef,
  		 mif_ord_cin_benef,
  		 mif_ord_cod_paese_benef,
  		 mif_ord_denom_banca_benef,
  		 mif_ord_cc_postale_benef,
  		 mif_ord_swift_benef,
  		 mif_ord_iban_benef,
         mif_ord_sepa_iban_tr,
         mif_ord_sepa_bic_tr,
         mif_ord_sepa_id_end_tr,
  		 mif_ord_bollo_esenzione,
  		 mif_ord_bollo_carico,
  		 mif_ordin_bollo_caus_esenzione,
  		 mif_ord_commissioni_carico,
         mif_ord_commissioni_esenzione,
  		 mif_ord_commissioni_importo,
         mif_ord_commissioni_natura,
  		 mif_ord_pagam_tipo,
  		 mif_ord_pagam_code,
  		 mif_ord_pagam_importo,
  		 mif_ord_pagam_causale,
  		 mif_ord_pagam_data_esec,
  		 mif_ord_lingua,
  		 mif_ord_rif_doc_esterno,
  		 mif_ord_info_tesoriere,
  		 mif_ord_flag_copertura,
  		 mif_ord_num_ord_colleg,
  		 mif_ord_progr_ord_colleg,
  		 mif_ord_anno_ord_colleg,
  		 mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
  		 mif_ord_descri_estesa_cap,
  		 mif_ord_siope_codice_cge,
  		 mif_ord_siope_descri_cge,
         mif_ord_codice_ente_ipa,
         mif_ord_codice_ente_istat,
         mif_ord_codice_ente_tramite,
         mif_ord_codice_ente_tramite_bt,
	     mif_ord_riferimento_ente,
         mif_ord_importo_benef,
         mif_ord_pagam_postalizza,
         mif_ord_class_tipo_debito,
         mif_ord_class_tipo_debito_nc,
         mif_ord_class_cig,
         mif_ord_class_motivo_nocig,
         mif_ord_class_missione,
         mif_ord_class_programma,
         mif_ord_class_economico,
         mif_ord_class_importo_economico,
         mif_ord_class_transaz_ue,
         mif_ord_class_ricorrente_spesa,
         mif_ord_class_cofog_codice,
         mif_ord_class_cofog_importo,
         mif_ord_codice_distinta,
         mif_ord_codice_atto_contabile,
         -- 16.09.2019 Sofia SIAC-6840
         mif_ord_pagopa_codfisc,
         mif_ord_pagopa_num_avviso,
  		 validita_inizio,
         ente_proprietario_id,
  		 login_operazione
		)
		VALUES
        (
	  	 --:mif_ord_data_elab,
  		 flussoElabMifLogId, --idElaborazione univoco
  		 mifOrdinativoIdRec.mif_ord_bil_id,
  		 mifOrdinativoIdRec.mif_ord_ord_id,
  		 mifOrdinativoIdRec.mif_ord_ord_anno,
  		 mifFlussoOrdinativoRec.mif_ord_numero,
  		 mifFlussoOrdinativoRec.mif_ord_codice_funzione,
  		 mifFlussoOrdinativoRec.mif_ord_data,
--  	     (case when mifFlussoOrdinativoRec.mif_ord_codice_funzione in (FUNZIONE_CODE_N,FUNZIONE_CODE_A) then
--                    '0.00' else mifFlussoOrdinativoRec.mif_ord_importo end),
         mifFlussoOrdinativoRec.mif_ord_importo,
 		 mifFlussoOrdinativoRec.mif_ord_flag_fin_loc,
  	     mifFlussoOrdinativoRec.mif_ord_documento,
 		 mifFlussoOrdinativoRec.mif_ord_bci_tipo_ente_pag,
 	 	 mifFlussoOrdinativoRec.mif_ord_bci_dest_ente_pag,
 		 mifFlussoOrdinativoRec.mif_ord_bci_conto_tes,
 		 mifFlussoOrdinativoRec.mif_ord_estremi_attoamm,
         mifFlussoOrdinativoRec.mif_ord_resp_attoamm,
  		 mifFlussoOrdinativoRec.mif_ord_uff_resp_attomm,
 		 mifFlussoOrdinativoRec.mif_ord_codice_abi_bt,
 		 mifFlussoOrdinativoRec.mif_ord_codice_ente,
		 mifFlussoOrdinativoRec.mif_ord_desc_ente,
  		 mifFlussoOrdinativoRec.mif_ord_codice_ente_bt,
 		 mifFlussoOrdinativoRec.mif_ord_anno_esercizio,
  		annoBilancio||flussoElabMifDistOilRetId::varchar,
  		flussoElabMifOilId, --idflussoOil
        extract(year from now())||'-'||
        lpad(extract('month' from now())::varchar,2,'0')||'-'||
        lpad(extract('day' from now())::varchar,2,'0')||'T'||
        lpad(extract('hour' from now())::varchar,2,'0')||':'||
        lpad(extract('minute' from now())::varchar,2,'0')||':'||'00',  -- mif_ord_data_creazione_flusso
        extract(year from now())::integer,
 		mifFlussoOrdinativoRec.mif_ord_codice_struttura,
 		mifFlussoOrdinativoRec.mif_ord_ente_localita,
		mifFlussoOrdinativoRec.mif_ord_ente_indirizzo,
 		mifFlussoOrdinativoRec.mif_ord_codice_raggrup,
 		mifFlussoOrdinativoRec.mif_ord_progr_benef,
 		mifFlussoOrdinativoRec.mif_ord_progr_dest,
 		mifFlussoOrdinativoRec.mif_ord_bci_conto,
  		mifFlussoOrdinativoRec.mif_ord_bci_tipo_contabil,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_class_importo,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_cup,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_prov,
 		mifFlussoOrdinativoRec.mif_ord_class_codice_gest_fraz,
 		mifFlussoOrdinativoRec.mif_ord_codifica_bilancio,
        mifFlussoOrdinativoRec.mif_ord_capitolo,
  		mifFlussoOrdinativoRec.mif_ord_articolo,
 		mifFlussoOrdinativoRec.mif_ord_desc_codifica,
        mifFlussoOrdinativoRec.mif_ord_desc_codifica_bil,
		mifFlussoOrdinativoRec.mif_ord_gestione,
 		mifFlussoOrdinativoRec.mif_ord_anno_res,
 		mifFlussoOrdinativoRec.mif_ord_importo_bil,
        mifFlussoOrdinativoRec.mif_ord_stanz,
    	mifFlussoOrdinativoRec.mif_ord_mandati_stanz,
  		mifFlussoOrdinativoRec.mif_ord_disponibilita,
		mifFlussoOrdinativoRec.mif_ord_prev,
  		mifFlussoOrdinativoRec.mif_ord_mandati_prev,
  		mifFlussoOrdinativoRec.mif_ord_disp_cassa,
        mifFlussoOrdinativoRec.mif_ord_anag_benef,
  		mifFlussoOrdinativoRec.mif_ord_indir_benef,
		mifFlussoOrdinativoRec.mif_ord_cap_benef,
 		mifFlussoOrdinativoRec.mif_ord_localita_benef,
  		mifFlussoOrdinativoRec.mif_ord_prov_benef,
        mifFlussoOrdinativoRec.mif_ord_stato_benef,
 		mifFlussoOrdinativoRec.mif_ord_partiva_benef,
  		mifFlussoOrdinativoRec.mif_ord_codfisc_benef,
  		mifFlussoOrdinativoRec.mif_ord_anag_quiet,
        mifFlussoOrdinativoRec.mif_ord_indir_quiet,
  		mifFlussoOrdinativoRec.mif_ord_cap_quiet,
 		mifFlussoOrdinativoRec.mif_ord_localita_quiet,
  		mifFlussoOrdinativoRec.mif_ord_prov_quiet,
 		mifFlussoOrdinativoRec.mif_ord_partiva_quiet,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_quiet,
        mifFlussoOrdinativoRec.mif_ord_stato_quiet,
 		mifFlussoOrdinativoRec.mif_ord_anag_del,
        mifFlussoOrdinativoRec.mif_ord_indir_del,
        mifFlussoOrdinativoRec.mif_ord_cap_del,
 		mifFlussoOrdinativoRec.mif_ord_localita_del,
 		mifFlussoOrdinativoRec.mif_ord_prov_del,
 		mifFlussoOrdinativoRec.mif_ord_codfisc_del,
 		mifFlussoOrdinativoRec.mif_ord_partiva_del,
        mifFlussoOrdinativoRec.mif_ord_stato_del,
 		mifFlussoOrdinativoRec.mif_ord_invio_avviso,
 		mifFlussoOrdinativoRec.mif_ord_abi_benef,
 		mifFlussoOrdinativoRec.mif_ord_cab_benef,
 		mifFlussoOrdinativoRec.mif_ord_cc_benef_estero,
 		mifFlussoOrdinativoRec.mif_ord_cc_benef,
 		mifFlussoOrdinativoRec.mif_ord_ctrl_benef,
 		mifFlussoOrdinativoRec.mif_ord_cin_benef,
 		mifFlussoOrdinativoRec.mif_ord_cod_paese_benef,
  		mifFlussoOrdinativoRec.mif_ord_denom_banca_benef,
 		mifFlussoOrdinativoRec.mif_ord_cc_postale_benef,
  		mifFlussoOrdinativoRec.mif_ord_swift_benef,
  		mifFlussoOrdinativoRec.mif_ord_iban_benef,
        mifFlussoOrdinativoRec.mif_ord_sepa_iban_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_bic_tr,
        mifFlussoOrdinativoRec.mif_ord_sepa_id_end_tr,
 		mifFlussoOrdinativoRec.mif_ord_bollo_esenzione,
  		mifFlussoOrdinativoRec.mif_ord_bollo_carico,
  		mifFlussoOrdinativoRec.mif_ordin_bollo_caus_esenzione,
 		mifFlussoOrdinativoRec.mif_ord_commissioni_carico,
        mifFlussoOrdinativoRec.mif_ord_commissioni_esenzione,
		mifFlussoOrdinativoRec.mif_ord_commissioni_importo,
        mifFlussoOrdinativoRec.mif_ord_commissioni_natura,
  		mifFlussoOrdinativoRec.mif_ord_pagam_tipo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_code,
	    mifFlussoOrdinativoRec.mif_ord_pagam_importo,
 		mifFlussoOrdinativoRec.mif_ord_pagam_causale,
 		mifFlussoOrdinativoRec.mif_ord_pagam_data_esec,
 		mifFlussoOrdinativoRec.mif_ord_lingua,
		mifFlussoOrdinativoRec.mif_ord_rif_doc_esterno,
 		mifFlussoOrdinativoRec.mif_ord_info_tesoriere,
 		mifFlussoOrdinativoRec.mif_ord_flag_copertura,
		mifFlussoOrdinativoRec.mif_ord_num_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_progr_ord_colleg,
		mifFlussoOrdinativoRec.mif_ord_anno_ord_colleg,
        mifFlussoOrdinativoRec.mif_ord_code_operatore, -- 15.01.2018 Sofia SIAC-5765
        mifFlussoOrdinativoRec.mif_ord_descri_estesa_cap,
        mifFlussoOrdinativoRec.mif_ord_siope_codice_cge,
        mifFlussoOrdinativoRec.mif_ord_siope_descri_cge,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_ipa,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_istat,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite,
        mifFlussoOrdinativoRec.mif_ord_codice_ente_tramite_bt,
	    mifFlussoOrdinativoRec.mif_ord_riferimento_ente,
        mifFlussoOrdinativoRec.mif_ord_importo_benef,
        mifFlussoOrdinativoRec.mif_ord_pagam_postalizza,
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito,
        mifFlussoOrdinativoRec.mif_ord_class_tipo_debito_nc,
        mifFlussoOrdinativoRec.mif_ord_class_cig,
        mifFlussoOrdinativoRec.mif_ord_class_motivo_nocig,
        mifFlussoOrdinativoRec.mif_ord_class_missione,
        mifFlussoOrdinativoRec.mif_ord_class_programma,
        mifFlussoOrdinativoRec.mif_ord_class_economico,
        mifFlussoOrdinativoRec.mif_ord_class_importo_economico,
        mifFlussoOrdinativoRec.mif_ord_class_transaz_ue,
        mifFlussoOrdinativoRec.mif_ord_class_ricorrente_spesa,
        mifFlussoOrdinativoRec.mif_ord_class_cofog_codice,
        mifFlussoOrdinativoRec.mif_ord_class_cofog_importo,
	    mifFlussoOrdinativoRec.mif_ord_codice_distinta,
        mifFlussoOrdinativoRec.mif_ord_codice_atto_contabile,
        -- 16.09.2019 Sofia SIAC-6840
        mifFlussoOrdinativoRec.mif_ord_pagopa_codfisc,
        mifFlussoOrdinativoRec.mif_ord_pagopa_num_avviso,
        now(),
        enteProprietarioId,
        loginOperazione
   )
   returning mif_ord_id into mifOrdSpesaId;




 -- dati fatture da valorizzare se ordinativo commerciale
 -- @@@@ sicuramente da completare
 -- <fattura_siope>
 if isGestioneFatture = true and isOrdCommerciale=true then
  flussoElabMifElabRec:=null;
  mifCountRec:=FLUSSO_MIF_ELAB_FATTURE;
  titoloCap:=null;
  flussoElabMifElabRec:=mifFlussoElabMifArr[mifCountRec];
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Lettura natura spesa.';

  /*if mifOrdinativoIdRec.mif_ord_titolo_code=titoloCorrente then
	  	titoloCap:=descriTitoloCorrente;
  else
   if mifOrdinativoIdRec.mif_ord_titolo_code=titoloCapitale then
     	titoloCap:=descriTitoloCapitale;
   end if;
  end if;*/
  -- 20.02.2018 Sofia JIRA siac-5849
  select oil.oil_natura_spesa_desc into titoloCap
  from siac_d_oil_natura_spesa oil, siac_r_oil_natura_spesa_titolo r
  where r.oil_natura_spesa_titolo_id=mifOrdinativoIdRec.mif_ord_titolo_id
  and   oil.oil_natura_spesa_id=r.oil_natura_spesa_id
  and   r.data_cancellazione is null
  and   r.validita_fine is null;
  if titoloCap is null then titoloCap:=defNaturaPag; end if;
   -- 26.02.2018 Sofia JIRA siac-5849 - inclusione delle note credito  per ordinativi di pagamento
  titoloCap:=titoloCap||'|N'; -- 08.05.2018 Sofia siac-6137
  strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Lettura dati configurazione per campo '||flussoElabMifElabRec.flusso_elab_mif_campo
                       ||' mifCountRec='||mifCountRec
                       ||' tipo flusso '||MANDMIF_TIPO||'.Gestione fatture.Inizio ciclo.';
  ordRec:=null;
  for ordRec in
  (select * from fnc_mif_ordinativo_documenti_splus( mifOrdinativoIdRec.mif_ord_ord_id,
											         numeroDocs::integer,
                                                     tipoDocs,
                                                     docAnalogico,
                                                     attrCodeDataScad,
                                                     titoloCap,
                                                     enteOilRec.ente_oil_codice_pcc_uff,
		   		                        	         enteProprietarioId,
	            		                             dataElaborazione,dataFineVal)
  )
  loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento fatture '
                       ||' in mif_t_ordinativo_spesa_documenti '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
         insert into  mif_t_ordinativo_spesa_documenti
         ( mif_ord_id,
		   mif_ord_documento,
           mif_ord_doc_codice_ipa_ente,
	       mif_ord_doc_tipo,
           mif_ord_doc_tipo_a,
		   mif_ord_doc_id_lotto_sdi,
		   mif_ord_doc_tipo_analog,
		   mif_ord_doc_codfisc_emis,
		   mif_ord_doc_anno,
	       mif_ord_doc_numero,
	       mif_ord_doc_importo,
	       mif_ord_doc_data_scadenza,
	       mif_ord_doc_motivo_scadenza,
	       mif_ord_doc_natura_spesa,
		   validita_inizio,
		   ente_proprietario_id,
		   login_operazione
         )
         values
         (mifOrdSpesaId,
          --ordRec.numero_fattura_siope,
          'S', -- 07.06.2018 Sofia SIAC-6228
		  ordRec.codice_ipa_ente_siope,
		  ordRec.tipo_documento_siope,
          ordRec.tipo_documento_siope_a,
          ordRec.identificativo_lotto_sdi_siope,
          ordRec.tipo_documento_analogico_siope,
          trim ( both ' ' from ordRec.codice_fiscale_emittente_siope),
		  ordRec.anno_emissione_fattura_siope,
		  ordRec.numero_fattura_siope,
          ordRec.importo_siope,
		  ordRec.data_scadenza_pagam_siope,
		  ordRec.motivo_scadenza_siope,
    	  ordRec.natura_spesa_siope,
          now(),
          enteProprietarioId,
          loginOperazione
         );
  end loop;
 end if;




   -- <ritenuta>
   -- <importo_ritenuta>
   -- <numero_reversale>
   -- <progressivo_reversale>

   if  isRitenutaAttivo=true then
    ritenutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  ritenute'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ritenutaRec in
    (select *
     from fnc_mif_ordinativo_ritenute(mifOrdinativoIdRec.mif_ord_ord_id,
         	 					      tipoRelazRitOrd,tipoRelazSubOrd,tipoRelazSprOrd,
                                      tipoOnereIrpefId,tipoOnereInpsId,
                                      tipoOnereIrpegId,
									  ordStatoCodeAId,ordDetTsTipoId,
                                      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
        strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento ritenuta'
                       ||' in mif_t_ordinativo_spesa_ritenute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_spesa_ritenute
        (mif_ord_id,
  		 mif_ord_rit_tipo,
 		 mif_ord_rit_importo,
 		 mif_ord_rit_numero,
  		 mif_ord_rit_ord_id,
 		 mif_ord_rit_progr_rev,
  		 validita_inizio,
		 ente_proprietario_id,
		 login_operazione)
        values
        (mifOrdSpesaId,
         tipoRitenuta,
         ritenutaRec.importoRitenuta,
         ritenutaRec.numeroRitenuta,
         ritenutaRec.ordRitenutaId,
         progrRitenuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );

    end loop;
   end if;

   -- <sospeso>
   -- <numero_provvisorio>
   -- <importo_provvisorio>
  if  isRicevutaAttivo=true then
    ricevutaRec:=null;
    strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Gestione  provvisori'
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
    for ricevutaRec in
    (select *
     from fnc_mif_ordinativo_ricevute(mifOrdinativoIdRec.mif_ord_ord_id,
                                      flussoElabMifTipoDec,
    	                              enteProprietarioId,dataElaborazione,dataFineVal)
    )
    loop
    	strMessaggio:='Lettura dati ordinativo numero='||mifOrdinativoIdRec.mif_ord_ord_numero
                       ||' annoBilancio='||mifOrdinativoIdRec.mif_ord_anno_bil
                       ||' ord_id='||mifOrdinativoIdRec.mif_ord_ord_id
                       ||' mif_ord_id='||mifOrdinativoIdRec.mif_ord_id
                       ||'. Inserimento   ricevuta'
                       ||' in mif_t_ordinativo_spesa_ricevute '
                       ||' tipo flusso '||MANDMIF_TIPO||'.';
   		insert into mif_t_ordinativo_spesa_ricevute
        (mif_ord_id,
	     mif_ord_ric_anno,
	     mif_ord_ric_numero,
	     mif_ord_provc_id,
		 mif_ord_ric_importo,
	     validita_inizio,
		 ente_proprietario_id,
	     login_operazione
        )
        values
        (mifOrdSpesaId,
         ricevutaRec.annoRicevuta,
         ricevutaRec.numeroRicevuta,
         ricevutaRec.provRicevutaId,
         ricevutaRec.importoRicevuta,
         now(),
         enteProprietarioId,
         loginOperazione
        );
    end loop;
  end if;

  numeroOrdinativiTrasm:=numeroOrdinativiTrasm+1;
 end loop;

/* if comPccAttrId is not null and numeroOrdinativiTrasm>0 then
   	   strMessaggio:='Inserimento Registro PCC.';
	   insert into siac_t_registro_pcc
	   (doc_id,
    	subdoc_id,
	    pccop_tipo_id,
    	ordinativo_data_emissione,
	    ordinativo_numero,
    	rpcc_quietanza_data,
        rpcc_quietanza_importo,
	    soggetto_id,
    	validita_inizio,
	    ente_proprietario_id,
    	login_operazione
	    )
    	(
         with
         mif as
         (select m.mif_ord_ord_id ord_id, m.mif_ord_soggetto_id soggetto_id,
                 ord.ord_emissione_data , ord.ord_numero
          from mif_t_ordinativo_spesa_id m, siac_t_ordinativo ord
          where m.ente_proprietario_id=enteProprietarioId
          and   substring(m.mif_ord_codice_funzione from 1 for 1)=FUNZIONE_CODE_I
          and   ord.ord_id=m.mif_ord_ord_id
         ),
         tipodoc as
         (select tipo.doc_tipo_id
          from siac_d_doc_tipo tipo ,siac_r_doc_tipo_attr attr
          where attr.attr_id=comPccAttrId
          and   attr.boolean='S'
          and   tipo.doc_tipo_id=attr.doc_tipo_id
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
          and   tipo.data_cancellazione is null
          and   tipo.validita_fine is null
         ),
         doc as
         (select distinct m.mif_ord_ord_id ord_id, subdoc.doc_id , subdoc.subdoc_id, subdoc.subdoc_importo, doc.doc_tipo_id
	      from  mif_t_ordinativo_spesa_id m, siac_t_ordinativo_ts ts, siac_r_subdoc_ordinativo_ts rsubdoc,
                siac_t_subdoc subdoc, siac_t_doc doc
          where m.ente_proprietario_id=enteProprietarioId
          and   substring(m.mif_ord_codice_funzione from 1 for 1)=FUNZIONE_CODE_I
          and   ts.ord_id=m.mif_ord_ord_id
          and   rsubdoc.ord_ts_id=ts.ord_ts_id
          and   subdoc.subdoc_id=rsubdoc.subdoc_id
          and   doc.doc_id=subdoc.doc_id
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          and   rsubdoc.data_cancellazione is null
          and   rsubdoc.validita_fine is null
          and   subdoc.data_cancellazione is null
          and   subdoc.validita_fine is null
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )
         select
          doc.doc_id,
          doc.subdoc_id,
          pccOperazTipoId,
--          mif.ord_emissione_data,
--		  mif.ord_emissione_data+(1*interval '1 day'),
		  mif.ord_emissione_data,
          mif.ord_numero,
          dataElaborazione,
          doc.subdoc_importo,
          mif.soggetto_id,
          now(),
          enteProprietarioId,
          loginOperazione
         from mif, doc,tipodoc
         where mif.ord_id=doc.ord_id
         and   tipodoc.doc_tipo_id=doc.doc_tipo_id
        );
   end if;*/


   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_out_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifOilId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_out_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;

   strMessaggio:='Aggiornamento progressivo per identificativo flusso OIL [siac_t_progressivo prog_key=oil_'||MANDMIF_TIPO||'_'||annoBilancio||'  per flusso MIF tipo '||MANDMIF_TIPO||'.';
   update siac_t_progressivo p set prog_value=flussoElabMifDistOilRetId
   where p.ente_proprietario_id=enteProprietarioId
   and   p.prog_key='oil_'||MANDMIF_TIPO||'_'||annoBilancio
   and   p.ambito_id=ambitoFinId
   and   p.data_cancellazione is null
   and   p.validita_fine is null;


   strMessaggio:='Aggiornamento mif_t_flusso_elaborato.';

   update  mif_t_flusso_elaborato
   set (flusso_elab_mif_id_flusso_oil,flusso_elab_mif_codice_flusso_oil,flusso_elab_mif_num_ord_elab,flusso_elab_mif_file_nome,flusso_elab_mif_esito_msg)=
   	   (flussoElabMifOilId,annoBilancio||flussoElabMifDistOilRetId::varchar,numeroOrdinativiTrasm,flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice,
        'Elaborazione in corso tipo flusso '||MANDMIF_TIPO||' - Dati inseriti in mif_t_ordinativo_spesa')
   where flusso_elab_mif_id=flussoElabMifLogId;

    -- gestire aggiornamento mif_t_flusso_elaborato

	RAISE NOTICE 'numeroOrdinativiTrasm %', numeroOrdinativiTrasm;
    messaggioRisultato:=strMessaggioFinale||' Trasmessi '||numeroOrdinativiTrasm||' ordinativi di spesa.';
    messaggioRisultato:=upper(messaggioRisultato);
    flussoElabMifId:=flussoElabMifLogId;
    nomeFileMif:=flussoElabMifTipoNomeFile||'_'||enteOilRec.ente_oil_codice;


    flussoElabMifDistOilId:=(annoBilancio||flussoElabMifDistOilRetId::varchar)::integer;
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        if codResult=-12 then
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||' '||mifCountRec||'.' ;
          codiceRisultato:=0;
        else
          messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||' '||mifCountRec||'.' ;
       	  codiceRisultato:=-1;
    	end if;

        numeroOrdinativiTrasm:=0;
		messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when NO_DATA_FOUND THEN
        raise notice '% % ERRORE : % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;

        return;
     when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : % %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||' '||mifCountRec||'.';
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then


            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;
        else
        	flussoElabMifId:=null;
        end if;
        return;
	when others  THEN
		raise notice '% % Errore DB % % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100),mifCountRec;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||' '||mifCountRec||'.' ;
        numeroOrdinativiTrasm:=0;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        if flussoElabMifLogId is not null then
            flussoElabMifId:=flussoElabMifLogId;
        	update  mif_t_flusso_elaborato
   			set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
                ('KO',messaggioRisultato)
		    where flusso_elab_mif_id=flussoElabMifLogId;

        else
        	flussoElabMifId:=null;
        end if;

        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
-- SIAC-6480 - Sofia FINE

--SIAC-7211 e SIAC-7212 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR997_tipo_capitolo_dei_report_solo_variaz"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_num_provv_var_peg integer, p_anno_provv_var_peg varchar, p_tipo_provv_var_peg varchar, p_num_provv_var_bil integer, p_anno_provv_var_bil varchar, p_tipo_provv_var_bil varchar, p_code_sac_direz_peg varchar, p_code_sac_sett_peg varchar, p_code_sac_direz_bil varchar, p_code_sac_sett_bil varchar);

CREATE OR REPLACE FUNCTION siac."BILR997_tipo_capitolo_dei_report_solo_variaz" (
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
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar,
  tipo_capitolo_cod varchar
) AS
$body$
DECLARE

 /* 26/11/2019.
 	Questa funzione nasce come copia della BILR997_tipo_capitolo_dei_report_variaz
    per risolvere i problemi segnalati dalle SIAC-7211 e SIAC-7212.
	L'importo restutitito dalla funzione per ogni "codice_importo" deve contenere solo 
    gli importi delle variazioni e non tutto il contenuto dei capitoli di quel tipo
    importo.
*/         
         
classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
tipoFpv varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';
sql_query VARCHAR;
user_table	varchar;
elemTipoCode VARCHAR;
elemCatCode  VARCHAR;
variazione_aumento_stanziato NUMERIC;
variazione_diminuzione_stanziato NUMERIC;
variazione_aumento_cassa NUMERIC;
variazione_diminuzione_cassa NUMERIC;
variazione_aumento_residuo NUMERIC;
variazione_diminuzione_residuo NUMERIC;

--fase_bilancio varchar;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
contaParVarPeg integer;
contaParVarBil integer;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';
tipoFpv='FPV'; 
tipo_capitolo_cod='';


elemTipoCodeE:='CAP-EG'; -- tipo capitolo gestione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo gestione

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

contaParVarPeg:=0;
contaParVarBil:=0;

  /* 22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;
select fnc_siac_random_user()
into	user_table;

-------------------------------------
--22/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori


insert into siac_rep_cap_ep
select --cl.classif_id,
  NULL,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	--siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        --siac_d_class_tipo ct,
		--siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where-- ct.classif_tipo_code			=	'CATEGORIA'
--and ct.classif_tipo_id				=	cl.classif_tipo_id
--and cl.classif_id					=	rc.classif_id 
--and 
e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCodeE
--and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
--and	rc.data_cancellazione				is null
--and	ct.data_cancellazione 				is null
--and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
--and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
--and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
--and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


/* 05/10/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;
    sql_query=sql_query||'  where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeE|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO''
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
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
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query Var Entrate: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
      union 
         select  tb0.elem_id,   
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
        union 
        select  tb0.elem_id,    
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);



insert into siac_rep_cap_ug 
select 	NULL, --programma.classif_id,
		NULL, --macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     --siac_d_class_tipo programma_tipo,
     --siac_t_class programma,
    -- siac_d_class_tipo macroaggr_tipo,
     --siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     --siac_r_bil_elem_class r_capitolo_programma,
     --siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	--programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    --programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
   -- programma.classif_id=r_capitolo_programma.classif_id					and
    --macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    --macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    --macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCodeS						     	and 
    --capitolo.elem_id=r_capitolo_programma.elem_id							and
    --capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
	--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	--and	programma_tipo.data_cancellazione 			is null
    --and	programma.data_cancellazione 				is null
    --and	macroaggr_tipo.data_cancellazione 			is null
    --and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    --and	r_capitolo_programma.data_cancellazione 	is null
   	--and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	
    
    
sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
            anno_importo.anno	      	
    from 	siac_r_variazione_stato		r_variazione_stato,
            siac_t_variazione 			testata_variazione,
            siac_d_variazione_tipo		tipologia_variazione,
            siac_d_variazione_stato 	tipologia_stato_var,
            siac_t_bil_elem_det_var 	dettaglio_variazione,
            siac_t_bil_elem				capitolo,
            siac_d_bil_elem_tipo 		tipo_capitolo,
            siac_d_bil_elem_det_tipo	tipo_elemento,
            siac_t_periodo 				anno_eserc ,
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;                      
    
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
    and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	 
    and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
    and     anno_eserc.periodo_id                               = bilancio.periodo_id
    and     testata_variazione.bil_id                           = bilancio.bil_id 
    and     capitolo.bil_id                                     = bilancio.bil_id       
    and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
    and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
    and		dettaglio_variazione.elem_id						=	capitolo.elem_id
    and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
    and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeS|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO''  
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    
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
    
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione	is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;


   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        annocapimp2
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp2
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp2
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp2
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp2
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp2
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp2
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table    ; 
        
        
end if;

    
-------------------------------------
/*
for tipo_capitolo in
        select t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod,
                sum (t1.variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum (t1.variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum (t1.variazione_aumento_cassa) variazione_aumento_cassa,
                sum (t1.variazione_diminuzione_cassa) variazione_diminuzione_cassa,
                sum (t1.variazione_aumento_residuo) variazione_aumento_residuo,
                sum (t1.variazione_diminuzione_residuo)   variazione_diminuzione_residuo                                                                                              
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0,
            	siac_rep_var_entrate_riga t1,
                siac_d_bil_elem_categoria cat_del_capitolo,
    			siac_r_bil_elem_categoria r_cat_capitolo
        	where r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	and r_cat_capitolo.elem_id=t1.elem_id
                and cat_del_capitolo.elem_cat_code=t0.codice_importo
                and t1.periodo_anno=t0.anno_competenza
                and t1.utente=user_table
            group by t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod
                */
-- INC000001599997 Inizio
/*for tipo_capitolo in
        select t0.*               
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0
            	ORDER BY t0.anno_competenza
loop*/
for tipo_capitolo in
        select t0.*               
			from "BILR000_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno, 'G') t0
            	ORDER BY t0.anno_competenza
loop
-- INC000001599997 Fine

/* 
	SIAC-7211 e SIAC-7212.
    L'importo restituito deve contenere solo l'importo dei capitoli variati.
*/
--importo = tipo_capitolo.importo;
importo:=0;

elemCatCode= tipo_capitolo.codice_importo;

IF tipo_capitolo.tipo_capitolo_cod ='CAP-EG' THEN  
	--Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;      
	
--16/03/2017: nel caso di capitoli FPV di entrata devo sommare gli importi
--	dei capitoli FPVSC e FPVCC.
		if tipo_capitolo.codice_importo = 'FPV' then
              --raise notice 'tipo_capitolo.codice_importo=%', variazione_diminuzione_stanziato;
              select      'FPV' elem_cat_code , 
                  coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                  coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                  coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                  coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                  coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                  coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
              into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                  variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
              variazione_diminuzione_residuo 
              from siac_rep_var_entrate_riga t1,
                  siac_r_bil_elem_categoria r_cat_capitolo,
                  siac_d_bil_elem_categoria cat_del_capitolo            
              WHERE  r_cat_capitolo.elem_id=t1.elem_id
                  AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                  AND t1.utente=user_table
                  AND cat_del_capitolo.elem_cat_code in (tipoFpvcc, tipoFpvsc)
                  AND r_cat_capitolo.data_cancellazione IS NULL
                  AND cat_del_capitolo.data_cancellazione IS NULL
                  AND t1.periodo_anno = tipo_capitolo.anno_competenza
             -- 17/07/2017: commentata la group by per jira SIAC-5105
             	--group by  elem_cat_code  
             ;             
            IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
            end if;
            
            raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
            raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
              /* 
                  SIAC-7211 e SIAC-7212.
                  L'importo restituito deve contenere solo l'importo dei capitoli variati.
              */
            --importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            else 


               select      cat_del_capitolo.elem_cat_code,
                    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                    coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                    coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                    coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                    coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                    coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
                into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                    variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
                variazione_diminuzione_residuo 
                from siac_rep_var_entrate_riga t1,
                    siac_r_bil_elem_categoria r_cat_capitolo,
                    siac_d_bil_elem_categoria cat_del_capitolo            
                WHERE  r_cat_capitolo.elem_id=t1.elem_id
                    AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                    AND t1.utente=user_table
                    AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                    AND r_cat_capitolo.data_cancellazione IS NULL
                    AND cat_del_capitolo.data_cancellazione IS NULL
                    AND t1.periodo_anno = tipo_capitolo.anno_competenza
                group by cat_del_capitolo.elem_cat_code   ; 
                
                IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
                ELSE
                 -- raise notice 'elemCatCode=%', elemCatCode;
                
                  
                  /*IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                      elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc  THEN            
                          importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
                  ELSIF elemCatCode = tipoFCassaIni THEN
                      importo =importo+variazione_aumento_cassa+variazione_diminuzione_cassa;              	
                  END IF;    */ 
                  
              /* 
                  SIAC-7211 e SIAC-7212.
                  L'importo restituito deve contenere solo l'importo dei capitoli variati.
              */                   
                  IF elemCatCode = tipoFCassaIni THEN                 
                      --importo =tipo_capitolo.importo+variazione_aumento_cassa+variazione_diminuzione_cassa;  
                      importo =variazione_aumento_cassa+variazione_diminuzione_cassa;  
                  ELSE         
                      --importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                      importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                  END IF;
              
            end if;  
                  
            END IF;     
            
ELSE  --Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;
	select      cat_del_capitolo.elem_cat_code,
			    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                               
			into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
            	variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
			variazione_diminuzione_residuo 
            from siac_rep_var_spese_riga t1,
            	siac_r_bil_elem_categoria r_cat_capitolo,
                siac_d_bil_elem_categoria cat_del_capitolo            
            WHERE  r_cat_capitolo.elem_id=t1.elem_id
            	AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	AND t1.utente=user_table
                AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                AND r_cat_capitolo.data_cancellazione IS NULL
                AND cat_del_capitolo.data_cancellazione IS NULL
                AND t1.periodo_anno = tipo_capitolo.anno_competenza
            group by cat_del_capitolo.elem_cat_code   ; 
            IF NOT FOUND THEN
              variazione_aumento_stanziato=0;
              variazione_diminuzione_stanziato=0;
              variazione_aumento_cassa=0;
              variazione_diminuzione_cassa=0;
              variazione_aumento_residuo=0;
              variazione_diminuzione_residuo=0;
            ELSE
            --raise notice 'elemCatCode=%', elemCatCode;
             /* IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                  elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc OR 
                  elemCatCode= tipoFpvcc OR elemCatCode =tipoFpvsc THEN            
                      importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
              ELSIF elemCatCode = tipoFCassaIni THEN
                  importo = importo+variazione_aumento_cassa+variazione_diminuzione_cassa;
              END IF; */  
              
              /* 
                  SIAC-7211 e SIAC-7212.
                  L'importo restituito deve contenere solo l'importo dei capitoli variati.
              */                
              --importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;               
              importo = variazione_aumento_stanziato+variazione_diminuzione_stanziato;               
            END IF;                    
END IF;
            
--raise notice 'anno_competenza=%', tipo_capitolo.anno_competenza;
--raise notice 'codice_importo=%', tipo_capitolo.codice_importo;
--raise notice 'importo=%', tipo_capitolo.importo;
--raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
--raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
--raise notice 'variazione_aumento_cassa=%', variazione_aumento_cassa;
--raise notice 'variazione_diminuzione_cassa=%', variazione_diminuzione_cassa;
--raise notice 'variazione_aumento_residuo=%', variazione_aumento_residuo;
--raise notice 'variazione_diminuzione_residuo=%', variazione_diminuzione_residuo;


anno_competenza = tipo_capitolo.anno_competenza;
descrizione = tipo_capitolo.descrizione;
posizione_nel_report = tipo_capitolo.posizione_nel_report;
codice_importo = tipo_capitolo.codice_importo;
tipo_capitolo_cod = tipo_capitolo.tipo_capitolo_cod;

return next;

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_competenza = '';
descrizione = '';
posizione_nel_report = 0;
codice_importo = '';
tipo_capitolo_cod = '';
importo=0;

end loop;


delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

delete from siac_rep_var_spese where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
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

--SIAC-7211 e SIAC-7212 - Maurizio - FINE



--SIAC-7222 - Haitham - INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_provvedimento(_uid_provvedimento integer, _limit integer, _page integer)
 RETURNS TABLE(uid integer, ord_numero numeric, ord_desc character varying, ord_emissione_data timestamp without time zone, soggetto_code character varying, soggetto_desc character varying, accredito_tipo_code character varying, accredito_tipo_desc character varying, ord_stato_desc character varying, importo numeric, ord_ts_code character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, uid_capitolo integer, capitolo_numero character varying, capitolo_articolo character varying, num_ueb character varying, capitolo_desc character varying, capitolo_anno character varying, provc_anno integer, provc_numero numeric, provc_data_convalida timestamp without time zone, ord_quietanza_data timestamp without time zone, conto_tesoreria character varying, distinta_code character varying, distinta_desc character varying, ord_split character varying, ord_ritenute character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		with ord_join_outer as (
			with ord_join as (
				with ordinativo as (
					select
						a.ord_id as uid,
						a.ord_numero,
						a.ord_desc,
						a.ord_emissione_data,
						e.ord_stato_desc,
						g.ord_ts_det_importo as importo,
						f.ord_ts_code,
                        -- 13.07.2018 Sofia jira siac-6193
                        a.contotes_id,
                        a.dist_id
					from
						siac_t_ordinativo a,
						siac_r_ordinativo_stato d,
						siac_d_ordinativo_stato e,
						siac_t_ordinativo_ts f,
						siac_t_ordinativo_ts_det g,
						siac_d_ordinativo_ts_det_tipo h,
						siac_d_ordinativo_tipo i
					where d.ord_id=a.ord_id
					and d.ord_stato_id=e.ord_stato_id
					and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
					and f.ord_id=a.ord_id
					and g.ord_ts_id=f.ord_ts_id
					and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
					and h.ord_ts_det_tipo_code = 'A'
					and i.ord_tipo_id=a.ord_tipo_id
					and i.ord_tipo_code='I'
					and a.data_cancellazione is null
					and d.data_cancellazione is null
					and e.data_cancellazione is null
					and f.data_cancellazione is null
					and g.data_cancellazione is null
					and i.data_cancellazione is null
				),
				soggetto as (
					select
						b.ord_id,
						c.soggetto_code,
						c.soggetto_desc
					from
						siac_r_ordinativo_soggetto b,
						siac_t_soggetto c
					where b.soggetto_id=c.soggetto_id
					and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
					and b.data_cancellazione is null
					and c.data_cancellazione is null
				),
				attoamm as (
					select
						m.ord_id,
						n.attoamm_id,
						n.attoamm_numero,
						n.attoamm_anno,
						q.attoamm_stato_desc,
						o.attoamm_tipo_code,
						o.attoamm_tipo_desc
					from
						siac_r_ordinativo_atto_amm m,
						siac_t_atto_amm n,
						siac_d_atto_amm_tipo o,
						siac_r_atto_amm_stato p,
						siac_d_atto_amm_stato q
					where n.attoamm_id=m.attoamm_id
					and n.attoamm_id=_uid_provvedimento
					and o.attoamm_tipo_id=n.attoamm_tipo_id
					and p.attoamm_id=n.attoamm_id
					and p.attoamm_stato_id=q.attoamm_stato_id
					and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
					and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
					and q.attoamm_stato_code<>'ANNULLATO'
					and m.data_cancellazione is null
					and n.data_cancellazione is null
					and o.data_cancellazione is null
					and p.data_cancellazione is null
					and q.data_cancellazione is null
				),
				capitolo as (
					select
						r.ord_id,
						s.elem_id,
						s.elem_code,
						s.elem_code2,
						s.elem_code3,
						s.elem_desc,
						y.anno capitolo_anno
					from
						siac_r_ordinativo_bil_elem r,
						siac_t_bil_elem s,
						siac_t_bil x,
						siac_t_periodo y
					where s.elem_id=r.elem_id
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and x.bil_id=s.bil_id
					and y.periodo_id=x.periodo_id
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				),
				modpag as (
					with modpag_noncessione as (
						select
							c2.ord_id,
							e2.accredito_tipo_code,
							e2.accredito_tipo_desc
						FROM
							siac_r_ordinativo_modpag c2,
							siac_t_modpag d2,
							siac_d_accredito_tipo e2
						where c2.modpag_id=d2.modpag_id
						and e2.accredito_tipo_id=d2.accredito_tipo_id
						and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
						and c2.data_cancellazione is null
						and d2.data_cancellazione is null
						and e2.data_cancellazione is null
					),
					modpag_cessione as (
						select
							c2.ord_id,
							e2.relaz_tipo_code accredito_tipo_code,
							e2.relaz_tipo_desc accredito_tipo_desc
						from
							siac_r_ordinativo_modpag c2,
							siac_r_soggetto_relaz d2,
							siac_d_relaz_tipo e2
						where d2.soggetto_relaz_id = c2.soggetto_relaz_id
						and e2.relaz_tipo_id = d2.relaz_tipo_id
						and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
						and c2.data_cancellazione is null
						and d2.data_cancellazione is null
						and e2.data_cancellazione is null
					)
					select *
					from modpag_noncessione
					UNION ALL
					select *
					from modpag_cessione
				),
                -- 13.07.2018 Sofia siac-6193
                conto_tesoreria as
                (
                 select conto.contotes_id, conto.contotes_code
                 from siac_d_contotesoreria conto
                 where conto.data_cancellazione is null
                ),
                -- 13.07.2018 Sofia siac-6193
                distinta as
                (
                select d.dist_id, d.dist_code, d.dist_desc
                from siac_d_distinta d
                where d.data_cancellazione is null
                )
				select
					*
				from ordinativo
				join soggetto on ordinativo.uid=soggetto.ord_id
				join attoamm on ordinativo.uid=attoamm.ord_id
				join capitolo on ordinativo.uid=capitolo.ord_id
				left outer join modpag on ordinativo.uid=modpag.ord_id
                -- 13.07.2018 Sofia siac-6193
                left join conto_tesoreria on (ordinativo.contotes_id=conto_tesoreria.contotes_id)
                left join distinta on (ordinativo.dist_id=distinta.dist_id)
			),
			sac_attoamm as (
				select
					y.classif_code,
					y.classif_desc,
					z.attoamm_id
				from
					siac_r_atto_amm_class z,
					siac_t_class y,
					siac_d_class_tipo x
				where z.classif_id=y.classif_id
				and x.classif_tipo_id=y.classif_tipo_id
				and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
				and x.classif_tipo_code IN ('CDC', 'CDR')
				and z.data_cancellazione is NULL
				and x.data_cancellazione is NULL
				and y.data_cancellazione is NULL
			)
			select
				*
			from
				ord_join
				left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
		),
/*	--Haithm 27/11/2019  SIAC-7222		
		provv_cassa as (
			select
				a2.ord_id,
				b2.provc_anno,
				b2.provc_numero,
				b2.provc_data_convalida
			from
				siac_r_ordinativo_prov_cassa a2,
				siac_t_prov_cassa b2
			where b2.provc_id=a2.provc_id
			and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
			and a2.data_cancellazione is NULL
			and b2.data_cancellazione is NULL
		),*/
    	quietanza AS
        (
     --SIAC-5899
        SELECT
            siac_T_Ordinativo.ord_id,
             --SIAC-7222  siac_r_ordinativo_quietanza.ord_quietanza_data
            MAX(siac_r_ordinativo_quietanza.ord_quietanza_data) as ord_quietanza_data
        --INTO
            --ord_quietanza_data
        FROM
            siac_t_oil_ricevuta
            ,siac_T_Ordinativo
            ,siac_d_oil_ricevuta_tipo
            ,siac_r_ordinativo_quietanza
        WHERE
                siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
            AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id
            AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
            AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'
            --AND siac_T_Ordinativo.ord_Id = uid
            AND siac_t_oil_ricevuta.data_cancellazione is null
            AND siac_T_Ordinativo.data_cancellazione is null
            AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
            AND siac_r_ordinativo_quietanza.data_cancellazione is null
            group by siac_T_Ordinativo.ord_id
            ),
        split as
        (
           select distinct rord.ord_id_a ord_id
           from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
 		   where tipo.relaz_tipo_code='SPR'
            and   rord.relaz_tipo_id=tipo.relaz_tipo_id
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
        ),
        ritenute as
        (
           select distinct rord.ord_id_a ord_id
           from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
 		   where tipo.relaz_tipo_code='RIT_ORD'
            and   rord.relaz_tipo_id=tipo.relaz_tipo_id
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
        )
		select
			ord_join_outer.uid,
			ord_join_outer.ord_numero,
			ord_join_outer.ord_desc,
			ord_join_outer.ord_emissione_data,
			ord_join_outer.soggetto_code,
			ord_join_outer.soggetto_desc,
			ord_join_outer.accredito_tipo_code,
			ord_join_outer.accredito_tipo_desc,
			ord_join_outer.ord_stato_desc,
			ord_join_outer.importo,
			ord_join_outer.ord_ts_code,
			ord_join_outer.attoamm_numero,
			ord_join_outer.attoamm_anno,
			ord_join_outer.attoamm_stato_desc,
			ord_join_outer.classif_code as attoamm_sac_code,
			ord_join_outer.classif_desc as attoamm_sac_desc,
			ord_join_outer.attoamm_tipo_code,
			ord_join_outer.attoamm_tipo_desc,
			ord_join_outer.elem_id as uid_capitolo,
			ord_join_outer.elem_code as num_capitolo,
			ord_join_outer.elem_code2 as num_articolo,
			ord_join_outer.elem_code3 as num_ueb,
			ord_join_outer.elem_desc as capitolo_desc,
			ord_join_outer.capitolo_anno,
		    --SIAC-7222
		    cast(null as integer) as provc_anno, --provv_cassa.provc_anno,
	   	    cast(null as numeric) as provc_numero, --provv_cassa.provc_numero,
		    cast(null as timestamp without time zone) as provc_data_convalida, --provv_cassa.provc_data_convalida,
            quietanza.ord_quietanza_data,
            -- 13.07.2018 Sofia siac-6193
            ord_join_outer.contotes_code conto_tesoreria,
            ord_join_outer.dist_code distinta_code,
            ord_join_outer.dist_desc distinta_desc,
            (case when split.ord_id is not null then 'S' else 'N' end)::varchar ord_split,
            (case when ritenute.ord_id is not null then 'S' else 'N' end)::varchar ord_ritenute
		from ord_join_outer
			-- left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id   --SIAC-7222	
			left outer join quietanza on ord_join_outer.uid=quietanza.ord_id
            -- 13.07.2018 Sofia siac-6193
   			left outer join split on ord_join_outer.uid=split.ord_id
            left outer join ritenute on ord_join_outer.uid=ritenute.ord_id
        order by
			ord_join_outer.ord_numero,
			ord_join_outer.ord_emissione_data,
			ord_join_outer.attoamm_anno,
			ord_join_outer.attoamm_numero
 LIMIT _limit
 OFFSET _offset;

END;
$function$
;


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_provvedimento_total(_uid_provvedimento integer)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	total bigint;
BEGIN

	SELECT  coalesce(count(*),0) into total
	from (
		with ord_join_outer as (
			with ord_join as (
				with ordinativo as (
					select
						a.ord_id as uid,
						a.ord_numero,
						a.ord_desc,
						a.ord_emissione_data,
						e.ord_stato_desc,
						g.ord_ts_det_importo as importo,
						f.ord_ts_code
					from
						siac_t_ordinativo a,
						siac_r_ordinativo_stato d,
						siac_d_ordinativo_stato e,
						siac_t_ordinativo_ts f,
						siac_t_ordinativo_ts_det g,
						siac_d_ordinativo_ts_det_tipo h,
						siac_d_ordinativo_tipo i
					where d.ord_id=a.ord_id
					and d.ord_stato_id=e.ord_stato_id
					and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
					and f.ord_id=a.ord_id
					and g.ord_ts_id=f.ord_ts_id
					and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
					and h.ord_ts_det_tipo_code = 'A'
					and i.ord_tipo_id=a.ord_tipo_id
					and i.ord_tipo_code='I'
					and a.data_cancellazione is null
					and d.data_cancellazione is null
					and e.data_cancellazione is null
					and f.data_cancellazione is null
					and g.data_cancellazione is null
					and i.data_cancellazione is null
				),
				soggetto as (
					select
						b.ord_id,
						c.soggetto_code,
						c.soggetto_desc
					from
						siac_r_ordinativo_soggetto b,
						siac_t_soggetto c
					where b.soggetto_id=c.soggetto_id
					and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
					and b.data_cancellazione is null
					and c.data_cancellazione is null
				),
				attoamm as (
					select
						m.ord_id,
						n.attoamm_id,
						n.attoamm_numero,
						n.attoamm_anno,
						q.attoamm_stato_desc,
						o.attoamm_tipo_code,
						o.attoamm_tipo_desc
					from
						siac_r_ordinativo_atto_amm m,
						siac_t_atto_amm n,
						siac_d_atto_amm_tipo o,
						siac_r_atto_amm_stato p,
						siac_d_atto_amm_stato q
					where n.attoamm_id=m.attoamm_id
					and n.attoamm_id=_uid_provvedimento
					and o.attoamm_tipo_id=n.attoamm_tipo_id
					and p.attoamm_id=n.attoamm_id
					and p.attoamm_stato_id=q.attoamm_stato_id
					and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
					and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
					and q.attoamm_stato_code<>'ANNULLATO'
					and m.data_cancellazione is null
					and n.data_cancellazione is null
					and o.data_cancellazione is null
					and p.data_cancellazione is null
					and q.data_cancellazione is null
				),
				capitolo as (
					select
						r.ord_id,
						s.elem_id,
						s.elem_code,
						s.elem_code2,
						s.elem_code3,
						s.elem_desc
					from
						siac_r_ordinativo_bil_elem r,
						siac_t_bil_elem s
					where s.elem_id=r.elem_id
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				),
				modpag as (
					with modpag_noncessione as (
						select
							c2.ord_id,
							e2.accredito_tipo_code,
							e2.accredito_tipo_desc
						FROM
							siac_r_ordinativo_modpag c2,
							siac_t_modpag d2,
							siac_d_accredito_tipo e2
						where c2.modpag_id=d2.modpag_id
						and e2.accredito_tipo_id=d2.accredito_tipo_id
						and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
						and c2.data_cancellazione is null
						and d2.data_cancellazione is null
						and e2.data_cancellazione is null
					),
					modpag_cessione as (
						select
							c2.ord_id,
							e2.relaz_tipo_code accredito_tipo_code,
							e2.relaz_tipo_desc accredito_tipo_desc
						from
							siac_r_ordinativo_modpag c2,
							siac_r_soggetto_relaz d2,
							siac_d_relaz_tipo e2
						where d2.soggetto_relaz_id = c2.soggetto_relaz_id
						and e2.relaz_tipo_id = d2.relaz_tipo_id
						and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
						and c2.data_cancellazione is null
						and d2.data_cancellazione is null
						and e2.data_cancellazione is null
					)
					select *
					from modpag_noncessione
					UNION ALL
					select *
					from modpag_cessione
				)
				select
					*
				from ordinativo
				join soggetto on ordinativo.uid=soggetto.ord_id
				join attoamm on ordinativo.uid=attoamm.ord_id
				join capitolo on ordinativo.uid=capitolo.ord_id
				left outer join modpag on ordinativo.uid=modpag.ord_id
			),
			sac_attoamm as (
				select
					y.classif_code,
					y.classif_desc,
					z.attoamm_id
				from
					siac_r_atto_amm_class z,
					siac_t_class y,
					siac_d_class_tipo x
				where z.classif_id=y.classif_id
				and x.classif_tipo_id=y.classif_tipo_id
				and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
				and x.classif_tipo_code IN ('CDC', 'CDR')
				and z.data_cancellazione is NULL
				and x.data_cancellazione is NULL
				and y.data_cancellazione is NULL
			)
			select
				*
			from
				ord_join
				left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
		)
/*	--Haithm 27/11/2019  SIAC-7222		
		,
		provv_cassa as (
			select
				a2.ord_id,
				b2.provc_anno,
				b2.provc_numero,
				b2.provc_data_convalida
			from
				siac_r_ordinativo_prov_cassa a2,
				siac_t_prov_cassa b2
			where b2.provc_id=a2.provc_id
			and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
			and a2.data_cancellazione is NULL
			and b2.data_cancellazione is NULL
		)*/
		select
			ord_join_outer.uid,
			ord_join_outer.ord_numero,
			ord_join_outer.ord_desc,
			ord_join_outer.ord_emissione_data,
			ord_join_outer.soggetto_code,
			ord_join_outer.soggetto_desc,
			ord_join_outer.ord_stato_desc,
			ord_join_outer.importo,
			ord_join_outer.ord_ts_code,
			ord_join_outer.attoamm_numero,
			ord_join_outer.attoamm_anno,
			ord_join_outer.attoamm_stato_desc,
			ord_join_outer.classif_code as attoamm_sac_code,
			ord_join_outer.classif_desc as attoamm_sac_desc,
			ord_join_outer.attoamm_tipo_code,
			ord_join_outer.attoamm_tipo_desc,
			ord_join_outer.elem_id as uid_capitolo,
			ord_join_outer.elem_code as num_capitolo,
			ord_join_outer.elem_code2 as num_articolo,
			ord_join_outer.elem_code3 as num_ueb,
			ord_join_outer.elem_desc as capitolo_desc,
		--SIAC-7222
		cast(null as integer) as provc_anno, --provv_cassa.provc_anno,
		cast(null as numeric) as provc_numero, --provv_cassa.provc_numero,
		cast(null as timestamp without time zone) as provc_data_convalida --provv_cassa.provc_data_convalida,
		from ord_join_outer
		--left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	) as ord_id;
	
	return total;
END;
$function$
;



CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_soggetto(_uid_soggetto integer, _annoesercizio character varying, _limit integer, _page integer)
 RETURNS TABLE(uid integer, ord_numero numeric, ord_desc character varying, ord_emissione_data timestamp without time zone, soggetto_code character varying, soggetto_desc character varying, accredito_tipo_code character varying, accredito_tipo_desc character varying, ord_stato_desc character varying, importo numeric, ord_ts_code character varying, attoamm_numero integer, attoamm_anno character varying, attoamm_stato_desc character varying, attoamm_sac_code character varying, attoamm_sac_desc character varying, attoamm_tipo_code character varying, attoamm_tipo_desc character varying, uid_capitolo integer, capitolo_numero character varying, capitolo_articolo character varying, num_ueb character varying, capitolo_desc character varying, capitolo_anno character varying, provc_anno integer, provc_numero numeric, provc_data_convalida timestamp without time zone, ord_quietanza_data timestamp without time zone, conto_tesoreria character varying, distinta_code character varying, distinta_desc character varying, ord_split character varying, ord_ritenute character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
	_offset INTEGER := (_page) * _limit;
    v_ente_proprietario_id INTEGER;
BEGIN

	select ente_proprietario_id	into v_ente_proprietario_id from siac_t_soggetto where soggetto_id = _uid_soggetto;
	RETURN QUERY
	with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code,
                    -- 13.07.2018 Sofia jira siac-6193
                    a.contotes_id,
                    a.dist_id
				from
					 siac_t_ordinativo a
					,siac_r_ordinativo_stato d
					,siac_d_ordinativo_stato e
					,siac_t_ordinativo_ts f
					,siac_t_ordinativo_ts_det g
					,siac_d_ordinativo_ts_det_tipo h
					,siac_d_ordinativo_tipo i
                    ,siac_t_bil tbil
					,siac_t_periodo tper

				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id

                and a.bil_id = tbil.bil_id
                and tbil.periodo_id	= tper.periodo_id
                and tper.anno = _annoEsercizio
				and a.ente_proprietario_id =  v_ente_proprietario_id
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='I'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and h.data_cancellazione is null
                and tbil.data_cancellazione is null
				and tper.data_cancellazione is null

			),
			soggetto as (
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc
				from
					siac_r_ordinativo_soggetto b,
					siac_t_soggetto c
				where b.soggetto_id=c.soggetto_id
				and c.soggetto_id=_uid_soggetto
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_ordinativo_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
                and n.ente_proprietario_id =  v_ente_proprietario_id
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc,
					y.anno capitolo_anno
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s,
					siac_t_bil x,
					siac_t_periodo y
				where s.elem_id=r.elem_id
				and x.bil_id=s.bil_id
				and y.periodo_id=x.periodo_id
                and x.ente_proprietario_id =  v_ente_proprietario_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and x.data_cancellazione is null
				and y.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				select c2.ord_id,
					e2.accredito_tipo_code,
					e2.accredito_tipo_desc
				FROM
					siac_r_ordinativo_modpag c2,
					siac_t_modpag d2,
					siac_d_accredito_tipo e2
				where c2.modpag_id=d2.modpag_id
				and e2.accredito_tipo_id=d2.accredito_tipo_id
				and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
                and d2.ente_proprietario_id =  v_ente_proprietario_id
				and c2.data_cancellazione is null
				and d2.data_cancellazione is null
				and e2.data_cancellazione is null
			),
            -- 13.07.2018 Sofia siac-6193
            conto_tesoreria as
            (
            	select conto.contotes_id, conto.contotes_code
                from siac_d_contotesoreria conto
                where conto.data_cancellazione is null
            ),
            -- 13.07.2018 Sofia siac-6193
            distinta as
            (
            	select d.dist_id, d.dist_code, d.dist_desc
                from siac_d_distinta d
                where 
                    d.ente_proprietario_id =  v_ente_proprietario_id
                and d.data_cancellazione is null
            )
			select *
			from ordinativo
			join soggetto on ordinativo.uid=soggetto.ord_id
			join attoamm on ordinativo.uid=attoamm.ord_id
			join capitolo on ordinativo.uid=capitolo.ord_id
			left outer join modpag on ordinativo.uid=modpag.ord_id
            -- 13.07.2018 Sofia siac-6193
            left join conto_tesoreria on (ordinativo.contotes_id=conto_tesoreria.contotes_id)
            left join distinta on (ordinativo.dist_id=distinta.dist_id)
		),
		sac_attoamm as (
			select
				y.classif_code,
				y.classif_desc,
				z.attoamm_id
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code IN ('CDC', 'CDR')
            and y.ente_proprietario_id =  v_ente_proprietario_id
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
/*	--Haithm 27/11/2019  SIAC-7222		
   provv_cassa as(
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
        and b2.ente_proprietario_id =  v_ente_proprietario_id
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	),*/
    quietanza AS(
     --SIAC-5899
        SELECT
            siac_T_Ordinativo.ord_id,
            --SIAC-7222  siac_r_ordinativo_quietanza.ord_quietanza_data
            MAX(siac_r_ordinativo_quietanza.ord_quietanza_data) as ord_quietanza_data

        --INTO
            --ord_quietanza_data
        FROM
            siac_t_oil_ricevuta
            ,siac_T_Ordinativo
            ,siac_d_oil_ricevuta_tipo
            ,siac_r_ordinativo_quietanza
        WHERE
                siac_t_oil_ricevuta.oil_ricevuta_tipo_id =  siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_id
            AND siac_t_oil_ricevuta.oil_ord_id  = siac_T_Ordinativo.ord_id
            AND siac_T_Ordinativo.ord_id = siac_r_ordinativo_quietanza.ord_id
            and siac_t_ordinativo.ente_proprietario_id =  v_ente_proprietario_id
            AND siac_d_oil_ricevuta_tipo.oil_ricevuta_tipo_code = 'Q'            
            --AND siac_T_Ordinativo.ord_Id = uid
            AND siac_t_oil_ricevuta.data_cancellazione is null
            AND siac_T_Ordinativo.data_cancellazione is null
            AND siac_d_oil_ricevuta_tipo.data_cancellazione is null
            AND siac_r_ordinativo_quietanza.data_cancellazione is null
            group by siac_T_Ordinativo.ord_id
            ),
    split as
        (
           select distinct rord.ord_id_a ord_id
           from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
 		   where tipo.relaz_tipo_code='SPR'
            and   rord.relaz_tipo_id=tipo.relaz_tipo_id
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ord_stato_code!='A'
            and   tipo.ente_proprietario_id =  v_ente_proprietario_id
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
            and   tipo.data_cancellazione is null
            and   stato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
        ),
        ritenute as
        (
           select distinct rord.ord_id_a ord_id
           from siac_r_ordinativo rOrd, siac_d_relaz_tipo tipo,
                siac_r_ordinativo_stato rstato,siac_d_ordinativo_stato stato
 		   where tipo.relaz_tipo_code='RIT_ORD'
            and   rord.relaz_tipo_id=tipo.relaz_tipo_id
			and   rstato.ord_id=rOrd.ord_id_da
            and   stato.ord_stato_id=rstato.ord_stato_id
			and   stato.ente_proprietario_id =  v_ente_proprietario_id
			and   stato.ord_stato_code!='A'
            and   tipo.data_cancellazione is null
            and   stato.data_cancellazione is null
            and   rord.data_cancellazione is null
	        and   now() between rord.validita_inizio and coalesce(rord.validita_fine, now())
   		    and   rstato.data_cancellazione is null
			and   now() between rstato.validita_inizio and coalesce(rstato.validita_fine, now())
        )
	select 
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
		ord_join_outer.soggetto_code,
		ord_join_outer.soggetto_desc,
		ord_join_outer.accredito_tipo_code,
		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as capitolo_numero,
		ord_join_outer.elem_code2 as capitolo_articolo,
		ord_join_outer.elem_code3 as numero_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		ord_join_outer.capitolo_anno as capitolo_anno,
		--SIAC-7222
		cast(null as integer) as provc_anno, --provv_cassa.provc_anno,
		cast(null as numeric) as provc_numero, --provv_cassa.provc_numero,
		cast(null as timestamp without time zone) as provc_data_convalida, --provv_cassa.provc_data_convalida,
		quietanza.ord_quietanza_data,
        -- 13.07.2018 Sofia siac-6193
        ord_join_outer.contotes_code conto_tesoreria,
        ord_join_outer.dist_code distinta_code,
        ord_join_outer.dist_desc distinta_desc,
        (case when split.ord_id is not null then 'S' else 'N' end)::varchar ord_split,
        (case when ritenute.ord_id is not null then 'S' else 'N' end)::varchar ord_ritenute
	from ord_join_outer
		--left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id  --SIAC-7222		
    	left outer join quietanza on ord_join_outer.uid=quietanza.ord_id
        -- 13.07.2018 Sofia siac-6193
  	    left outer join split on ord_join_outer.uid=split.ord_id
        left outer join ritenute on ord_join_outer.uid=ritenute.ord_id
	order by 2,4,12,11
	LIMIT _limit
	OFFSET _offset;
END;
$function$
;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_reversale_from_soggetto_total(_uid_soggetto integer, _annoesercizio character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0)
	into total
	from (
		with ord_join_outer as (
			with ord_join as (
				with ordinativo as (
					select
						a.ord_id as uid,
						a.ord_numero,
						a.ord_desc,
						a.ord_emissione_data,
						e.ord_stato_desc,
						g.ord_ts_det_importo as importo,
						f.ord_ts_code
					from
						 siac_t_ordinativo a
						,siac_r_ordinativo_stato d
						,siac_d_ordinativo_stato e
						,siac_t_ordinativo_ts f
						,siac_t_ordinativo_ts_det g
						,siac_d_ordinativo_ts_det_tipo h
						,siac_d_ordinativo_tipo i
                        ,siac_t_bil tbil
						,siac_t_periodo tper 
					where d.ord_id=a.ord_id
					and d.ord_stato_id=e.ord_stato_id
					and f.ord_id=a.ord_id
					and g.ord_ts_id=f.ord_ts_id
					and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
                    
                    and a.bil_id = tbil.bil_id
					and tbil.periodo_id	= tper.periodo_id
                	and tper.anno = _annoEsercizio
                    
					and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
					and h.ord_ts_det_tipo_code = 'A'
					and i.ord_tipo_id=a.ord_tipo_id
					and i.ord_tipo_code='I'
					and a.data_cancellazione is null
					and d.data_cancellazione is null
					and e.data_cancellazione is null
					and f.data_cancellazione is null
					and g.data_cancellazione is null
                    and tbil.data_cancellazione is null
					and tper.data_cancellazione is null
                ),
				soggetto as (
					select
						b.ord_id,
						c.soggetto_code,
						c.soggetto_desc
					from
						siac_r_ordinativo_soggetto b,
						siac_t_soggetto c
					where b.soggetto_id=c.soggetto_id
					and c.soggetto_id=_uid_soggetto
					and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
					and b.data_cancellazione is null
					and c.data_cancellazione is null
				),
				attoamm as (
					select
						m.ord_id,
						n.attoamm_id,
						n.attoamm_numero,
						n.attoamm_anno,
						q.attoamm_stato_desc,
						o.attoamm_tipo_code,
						o.attoamm_tipo_desc
					from
						siac_r_ordinativo_atto_amm m,
						siac_t_atto_amm n,
						siac_d_atto_amm_tipo o,
						siac_r_atto_amm_stato p,
						siac_d_atto_amm_stato q
					where n.attoamm_id=m.attoamm_id
					and o.attoamm_tipo_id=n.attoamm_tipo_id
					and p.attoamm_id=n.attoamm_id
					and p.attoamm_stato_id=q.attoamm_stato_id
					and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
					and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
					and q.attoamm_stato_code<>'ANNULLATO'
					and m.data_cancellazione is null
					and n.data_cancellazione is null
					and o.data_cancellazione is null
					and p.data_cancellazione is null
					and q.data_cancellazione is null
				),
				capitolo as (
					select
						r.ord_id,
						s.elem_id,
						s.elem_code,
						s.elem_code2,
						s.elem_code3,
						s.elem_desc,
						y.anno capitolo_anno
					from
						siac_r_ordinativo_bil_elem r,
						siac_t_bil_elem s,
						siac_t_bil x,
						siac_t_periodo y
					where s.elem_id=r.elem_id
					and r.data_cancellazione is null
					and s.data_cancellazione is null
					and x.bil_id=s.bil_id
					and y.periodo_id=x.periodo_id
					and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
				),
				modpag as (
					select c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				)
				select *
				from ordinativo
				join soggetto on ordinativo.uid=soggetto.ord_id
				join attoamm on ordinativo.uid=attoamm.ord_id
				join capitolo on ordinativo.uid=capitolo.ord_id
				left outer join modpag on ordinativo.uid=modpag.ord_id
			),
			sac_attoamm as (
				select
					y.classif_code,
					y.classif_desc,
					z.attoamm_id
				from
					siac_r_atto_amm_class z,
					siac_t_class y,
					siac_d_class_tipo x
				where z.classif_id=y.classif_id
				and x.classif_tipo_id=y.classif_tipo_id
				and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
				and x.classif_tipo_code IN ('CDC', 'CDR')
				and z.data_cancellazione is NULL
				and x.data_cancellazione is NULL
				and y.data_cancellazione is NULL
			)
			select *
			from ord_join
			left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
		)
/*	--Haithm 27/11/2019  SIAC-7222		
		,
		provv_cassa as(
			select
				a2.ord_id,
				b2.provc_anno,
				b2.provc_numero,
				b2.provc_data_convalida
			from
				siac_r_ordinativo_prov_cassa a2,
				siac_t_prov_cassa b2
			where b2.provc_id=a2.provc_id
			and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
			and a2.data_cancellazione is NULL
			and b2.data_cancellazione is NULL
		)*/
		select
			ord_join_outer.uid,
			ord_join_outer.ord_numero,
			ord_join_outer.ord_desc,
			ord_join_outer.ord_emissione_data,
			ord_join_outer.soggetto_code,
			ord_join_outer.soggetto_desc,
			ord_join_outer.accredito_tipo_code,
			ord_join_outer.accredito_tipo_desc,
			ord_join_outer.ord_stato_desc,
			ord_join_outer.importo,
			ord_join_outer.ord_ts_code,
			ord_join_outer.attoamm_numero,
			ord_join_outer.attoamm_anno,
			ord_join_outer.attoamm_stato_desc,
			ord_join_outer.classif_code as attoamm_sac_code,
			ord_join_outer.classif_desc as attoamm_sac_desc,
			ord_join_outer.attoamm_tipo_code,
			ord_join_outer.attoamm_tipo_desc,
			ord_join_outer.elem_id as uid_capitolo,
			ord_join_outer.elem_code as capitolo_numero,
			ord_join_outer.elem_code2 as capitolo_articolo,
			ord_join_outer.elem_code3 as numero_ueb,
			ord_join_outer.elem_desc as capitolo_desc,
			ord_join_outer.capitolo_anno as capitolo_anno,
		--SIAC-7222
		cast(null as integer) as provc_anno, --provv_cassa.provc_anno,
		cast(null as numeric) as provc_numero, --provv_cassa.provc_numero,
		cast(null as timestamp without time zone) as provc_data_convalida --provv_cassa.provc_data_convalida,
		from ord_join_outer
		--left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id
	) as ord_id;
	
	return total;
END;
$function$
;

--SIAC-7222 - Haitham - FINE

-- ALL delle componenti (SIAC-6881) INIZIO
-- DDL
CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_tipo_stato
(
    elem_det_comp_tipo_stato_id SERIAL,
    elem_det_comp_tipo_stato_code VARCHAR(200) NOT NULL,
    elem_det_comp_tipo_stato_desc VARCHAR(500) NOT NULL,
    validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
    validita_fine TIMESTAMP,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_stato PRIMARY KEY (elem_det_comp_tipo_stato_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_stato IS 'Stato dell''anagrafica componente (VALIDO, ANNULLATO)';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_stato.elem_det_comp_tipo_stato_code IS 'V, A';

select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_stato', 'siac_d_bil_elem_det_comp_tipo_stato_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);

select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_stato', 'siac_d_bil_elem_det_comp_tipo_stato_idx_1', 'elem_det_comp_tipo_stato_code, validita_inizio, ente_proprietario_id ', 'data_cancellazione is null', true);

CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_tipo_def
(
                elem_det_comp_tipo_def_id SERIAL,
                elem_det_comp_tipo_def_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_def_desc VARCHAR(500) NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_def PRIMARY KEY (elem_det_comp_tipo_def_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_def IS 'Componente proposta come default su capitoli (Solo Previsione, Solo Gestione, Si, No)';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_def.elem_det_comp_tipo_def_code IS 'Solo Gestione, Solo Previsione, Si, No';

select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_def', 'siac_d_bil_elem_det_comp_tipo_def_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_def', 'siac_d_bil_elem_det_comp_tipo_def_idx_1', 'elem_det_comp_tipo_def_code, validita_inizio, ente_proprietario_id ', 'data_cancellazione is null', true);

CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_macro_tipo (
                elem_det_comp_macro_tipo_id SERIAL,
                elem_det_comp_macro_tipo_code VARCHAR(200) NOT NULL,
                elem_det_comp_macro_tipo_desc VARCHAR(500) NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_macro_tipo PRIMARY KEY (elem_det_comp_macro_tipo_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_macro_tipo IS 'Macrotipo componente (Fresco,FPV,Avanzo)';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_macro_tipo.elem_det_comp_macro_tipo_code IS 'Fresco, FPV, Avanzo';

select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_macro_tipo', 'siac_d_bil_elem_det_comp_macro_tipo_fk_ente_proprietario_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_macro_tipo', 'siac_d_bil_elem_det_comp_macro_tipo_code_idx_1', 'elem_det_comp_macro_tipo_code, validita_inizio, ente_proprietario_id', 'data_cancellazione is null', true);

CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_sotto_tipo (
                elem_det_comp_sotto_tipo_id SERIAL,
                elem_det_comp_sotto_tipo_code VARCHAR(200) NOT NULL,
                elem_det_comp_sotto_tipo_desc VARCHAR(500) NOT NULL,
				elem_det_comp_macro_tipo_id INTEGER NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_sotto_tipo PRIMARY KEY (elem_det_comp_sotto_tipo_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_sotto_tipo IS 'Sottotipo componente ( Programmato, Cumulato, Applicato )';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_sotto_tipo.elem_det_comp_sotto_tipo_code IS 'Programmato, Cumulato, Da definire';

select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_sotto_tipo', 'siac_d_bil_elem_det_comp_sotto_tipo_fk_macro_id_idx', 'elem_det_comp_macro_tipo_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_sotto_tipo', 'siac_d_bil_elem_det_comp_sotto_tipo_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_sotto_tipo', 'siac_d_bil_elem_det_comp_sotto_tipo_code_idx_1', ' elem_det_comp_sotto_tipo_code, elem_det_comp_macro_tipo_id,validita_inizio, ente_proprietario_id', 'data_cancellazione is null', true);

CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_tipo_ambito (
                elem_det_comp_tipo_ambito_id SERIAL,
                elem_det_comp_tipo_ambito_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_ambito_desc VARCHAR(500) NOT NULL,
				elem_det_comp_macro_tipo_id INTEGER NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_ambito PRIMARY KEY (elem_det_comp_tipo_ambito_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_ambito IS 'Ambito componente';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_ambito.elem_det_comp_tipo_ambito_code IS 'Autonomo, Vincolato,Da definire';


select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_ambito', 'siac_d_bil_elem_det_comp_tipo_ambito_fk_macro_id_idx', 'elem_det_comp_macro_tipo_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_ambito', 'siac_d_bil_elem_det_comp_tipo_ambito_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_ambito', 'siac_d_bil_elem_det_comp_tipo_ambito_idx_1', 'elem_det_comp_tipo_ambito_code,elem_det_comp_macro_tipo_id, validita_inizio, ente_proprietario_id', 'data_cancellazione is null', true);

CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_tipo_fase (
                elem_det_comp_tipo_fase_id SERIAL,
                elem_det_comp_tipo_fase_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_fase_desc VARCHAR(500) NOT NULL,
				elem_det_comp_macro_tipo_id INTEGER NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_fase PRIMARY KEY (elem_det_comp_tipo_fase_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_fase IS 'Componente utilizzabile in fase Gestione, Previsione , ROR';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_fase.elem_det_comp_tipo_fase_code IS 'Gestione, Previsione, ROR';

select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_fase', 'siac_d_bil_elem_det_comp_tipo_fase_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_fase', 'siac_d_bil_elem_det_comp_tipo_fase_fk_macro_id_idx', 'elem_det_comp_macro_tipo_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_fase', 'siac_d_bil_elem_det_comp_tipo_fase_idx_1', 'elem_det_comp_tipo_fase_code, elem_det_comp_macro_tipo_id, validita_inizio, ente_proprietario_id', 'data_cancellazione is null', true);

CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_tipo_fonte (
                elem_det_comp_tipo_fonte_id SERIAL,
                elem_det_comp_tipo_fonte_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_fonte_desc VARCHAR(500) NOT NULL,
				elem_det_comp_macro_tipo_id INTEGER NOT NULL,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo_fonte PRIMARY KEY (elem_det_comp_tipo_fonte_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo_fonte IS 'Fonte di finanziamento componente';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo_fonte.elem_det_comp_tipo_fonte_code IS 'Fresco,Avanzo';

select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_fonte', 'siac_d_bil_elem_det_comp_tipo_fonte_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_fonte', 'siac_d_bil_elem_det_comp_tipo_fonte_fk_macro_id_idx', 'elem_det_comp_macro_tipo_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo_fonte', 'siac_d_bil_elem_det_comp_tipo_fonte_idx_1', 'elem_det_comp_tipo_fonte_code, elem_det_comp_macro_tipo_id,validita_inizio, ente_proprietario_id', 'data_cancellazione is null', true);


CREATE TABLE IF NOT EXISTS siac.siac_d_bil_elem_det_comp_tipo (
                elem_det_comp_tipo_id SERIAL,
                elem_det_comp_tipo_code VARCHAR(200) NOT NULL,
                elem_det_comp_tipo_desc VARCHAR(500) NOT NULL,
                elem_det_comp_macro_tipo_id INTEGER,
                elem_det_comp_sotto_tipo_id INTEGER,
                elem_det_comp_tipo_ambito_id INTEGER,
                elem_det_comp_tipo_fonte_id INTEGER,
                elem_det_comp_tipo_fase_id INTEGER,
                elem_det_comp_tipo_def_id INTEGER,
                elem_det_comp_tipo_gest_aut BOOLEAN DEFAULT 'N' NOT NULL,
                elem_det_comp_tipo_stato_id INTEGER NOT NULL,
                periodo_id INTEGER,
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_d_bil_elem_det_comp_tipo PRIMARY KEY (elem_det_comp_tipo_id)
);
COMMENT ON TABLE siac.siac_d_bil_elem_det_comp_tipo IS 'Anagrafica tipologie componenti stanziamento';
COMMENT ON COLUMN siac.siac_d_bil_elem_det_comp_tipo.elem_det_comp_tipo_gest_aut IS 'Tipo di gestione della componente dello stanziamento manuale o solo automatica [N-manuale,S-automatica]';

select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_fonte_id_idx', 'elem_det_comp_tipo_fonte_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_macro_tipo_id_idx', 'elem_det_comp_macro_tipo_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_sotto_tipo_id_idx', 'elem_det_comp_sotto_tipo_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_ambito_id_idx', 'elem_det_comp_tipo_ambito_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_fase_id_idx', 'elem_det_comp_tipo_fase_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_def_id_idx', 'elem_det_comp_tipo_def_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_stato_id_idx', 'elem_det_comp_tipo_stato_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fk_periodo_id_idx', 'periodo_id', '', false);
select * from fnc_dba_create_index('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_idx_1', 'elem_det_comp_tipo_code, elem_det_comp_macro_tipo_id, ente_proprietario_id, validita_inizio', 'data_cancellazione is null', true);

CREATE TABLE IF NOT EXISTS siac.siac_t_bil_elem_det_comp (
                elem_det_comp_id SERIAL,
                elem_det_id INTEGER NOT NULL,
                elem_det_comp_tipo_id INTEGER NOT NULL,
                elem_det_importo NUMERIC,
                validita_inizio TIMESTAMP NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_t_bil_elem_det_comp PRIMARY KEY (elem_det_comp_id)
);
COMMENT ON TABLE siac.siac_t_bil_elem_det_comp IS 'Componente Importi Stanziamento Capitolo';
COMMENT ON COLUMN siac.siac_t_bil_elem_det_comp.elem_det_importo IS 'Importo componente stanziamento capitolo';


select * from fnc_dba_create_index('siac_t_bil_elem_det_comp', 'siac_t_bil_elem_det_comp_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_t_bil_elem_det_comp', 'siac_t_bil_elem_det_comp_fk_elem_det_id_idx', 'elem_det_id', '', false);
select * from fnc_dba_create_index('siac_t_bil_elem_det_comp', 'siac_t_bil_elem_det_comp_fk_elem_det_com_tipo_id_idx', 'elem_det_comp_tipo_id', '', false);
select * from fnc_dba_create_index('siac_t_bil_elem_det_comp', 'siac_t_bil_elem_det_comp_elem_det_idx_1', 'elem_det_id, elem_det_comp_tipo_id, validita_inizio, ente_proprietario_id', 'data_cancellazione is null', true);

CREATE TABLE IF NOT EXISTS siac.siac_t_bil_elem_det_var_comp (
                elem_det_var_comp_id SERIAL,
                elem_det_var_id INTEGER NOT NULL,
                elem_det_comp_id INTEGER NOT NULL,
                elem_det_importo NUMERIC,
                elem_det_flag CHARACTER VARYING(1),
                validita_inizio TIMESTAMP DEFAULT now() NOT NULL,
                validita_fine TIMESTAMP,
                ente_proprietario_id INTEGER NOT NULL,
                data_creazione TIMESTAMP DEFAULT now() NOT NULL,
                data_modifica TIMESTAMP DEFAULT now() NOT NULL,
                data_cancellazione TIMESTAMP,
                login_operazione VARCHAR(200) NOT NULL,
                CONSTRAINT pk_siac_t_bil_elem_det_var_comp PRIMARY KEY (elem_det_var_comp_id)
);
COMMENT ON TABLE siac.siac_t_bil_elem_det_var_comp IS 'Dettaglio di variazione della componente Importi Stanziamento Capitolo';
COMMENT ON COLUMN siac.siac_t_bil_elem_det_var_comp.elem_det_importo IS 'Importo di varaizione componente stanziamento capitolo';
COMMENT ON COLUMN siac.siac_t_bil_elem_det_var_comp.elem_det_flag IS 'Flag cancellazione (A) o inserimento (N) variazione componente stanziamento capitolo';

select * from fnc_dba_create_index('siac_t_bil_elem_det_var_comp', 'siac_t_bil_elem_det_var_comp_fk_ente_proprietario_id_idx', 'ente_proprietario_id', '', false);
select * from fnc_dba_create_index('siac_t_bil_elem_det_var_comp', 'siac_t_bil_elem_det_var_comp_fk_det_comp_id_idx', 'elem_det_comp_id', '', false);
select * from fnc_dba_create_index('siac_t_bil_elem_det_var_comp', 'siac_t_bil_elem_det_var_comp_fk_det_var_id_idx', 'elem_det_var_id', '', false);
select * from fnc_dba_create_index('siac_t_bil_elem_det_var_comp', 'siac_t_bil_elem_det_var_comp_idx_1', 'elem_det_var_id, elem_det_comp_id, ente_proprietario_id, validita_inizio', 'data_cancellazione is null', true);

select * from fnc_dba_add_fk_constraint('siac_t_bil_elem_det_var_comp', 'siac_t_ente_proprietario_siac_t_bil_elem_det_var_comp_fk', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_t_bil_elem_det_comp', 'siac_t_ente_proprietario_siac_t_bil_elem_det_comp_fk', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo_def', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_def_fk', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_fk', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo_ambito', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_ambit175', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo_fonte', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_fonte_fk', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo_fase', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_tipo_fase_fk', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_sotto_tipo', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_sotto_tipo_fk', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_macro_tipo', 'siac_t_ente_proprietario_siac_d_bil_elem_det_comp_macro_tipo_fk', 'ente_proprietario_id', 'siac_t_ente_proprietario', 'ente_proprietario_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_def_siac_d_bil_elem_det_comp_t541', 'elem_det_comp_tipo_def_id', 'siac_d_bil_elem_det_comp_tipo_def', 'elem_det_comp_tipo_def_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fase_siac_d_bil_elem_det_comp_999', 'elem_det_comp_tipo_fase_id', 'siac_d_bil_elem_det_comp_tipo_fase', 'elem_det_comp_tipo_fase_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_fonte_siac_d_bil_elem_det_comp764', 'elem_det_comp_tipo_fonte_id', 'siac_d_bil_elem_det_comp_tipo_fonte', 'elem_det_comp_tipo_fonte_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_stato_siac_d_bil_elem_det_comp_tipo_fk', 'elem_det_comp_tipo_stato_id', 'siac_d_bil_elem_det_comp_tipo_fonte', 'elem_det_comp_tipo_stato_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_tipo_ambito_siac_d_bil_elem_det_com286', 'elem_det_comp_tipo_ambito_id', 'siac_d_bil_elem_det_comp_tipo_ambito', 'elem_det_comp_tipo_ambito_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_elem_det_comp_sotto_tipo_siac_d_bil_elem_det_comp415', 'elem_det_comp_sotto_tipo_id', 'siac_d_bil_elem_det_comp_sotto_tipo', 'elem_det_comp_sotto_tipo_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_d_bil_det_comp_macro_tipo_siac_d_bil_elem_det_comp_tipo_fk', 'elem_det_comp_macro_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_macro_tipo_id');
select * from fnc_dba_add_fk_constraint('siac_d_bil_elem_det_comp_tipo', 'siac_t_periodo_siac_d_bil_elem_det_comp_tipo_fk', 'periodo_id', 'siac_t_periodo', 'periodo_id');
select * from fnc_dba_add_fk_constraint('siac_t_bil_elem_det_comp', 'siac_d_bil_elem_det_comp_siac_t_bil_elem_det_comp_fk', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');
select * from fnc_dba_add_fk_constraint('siac_t_bil_elem_det_comp', 'siac_t_bil_elem_det_siac_t_bil_elem_det_comp_fk', 'elem_det_id', 'siac_t_bil_elem_det', 'elem_det_id');
select * from fnc_dba_add_fk_constraint('siac_t_bil_elem_det_var_comp', 'siac_t_bil_elem_det_var_siac_t_bil_elem_det_var_comp_fk', 'elem_det_var_id', 'siac_t_bil_elem_det_var', 'elem_det_var_id');
select * from fnc_dba_add_fk_constraint('siac_t_bil_elem_det_var_comp', 'siac_t_bil_elem_det_comp_siac_t_bil_elem_det_var_comp_fk', 'elem_det_comp_id', 'siac_t_bil_elem_det_comp', 'elem_det_comp_id');

-- /DDL

-- AZIONI
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
select tmp.az_code, tmp.az_desc, ta.azione_tipo_id, ga.gruppo_azioni_id, tmp.az_url, to_timestamp('01/01/2017','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
from siac_d_azione_tipo ta
join siac_t_ente_proprietario e on (ta.ente_proprietario_id = e.ente_proprietario_id)
join siac_d_gruppo_azioni ga on (ga.ente_proprietario_id = e.ente_proprietario_id)
join (values
	('OP-GESC088-ricercaAnagraficaComponenti', 'Ricerca Anagrafica Componenti', 'ATTIVITA_SINGOLA', 'BIL_ALTRO', '/../siacbilapp/azioneRichiesta.do'),
	('OP-GESC089-inserisiciAnagraficaComponenti', 'Inserisci Anagrafica Componenti', 'ATTIVITA_SINGOLA', 'BIL_ALTRO', '/../siacbilapp/azioneRichiesta.do')
) as tmp (az_code, az_desc, az_tipo, az_gruppo, az_url) on (tmp.az_tipo = ta.azione_tipo_code and tmp.az_gruppo = ga.gruppo_azioni_code)
where not exists (
	select 1
	from siac_t_azione z
	where z.azione_tipo_id = ta.azione_tipo_id
	and z.azione_code = tmp.az_code
);

-- /AZIONI

-- DML
-- macro componente
-- Fresco, Avanzo, FPV, Da attribuire
insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Fresco',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='01'
and   tipo.elem_det_comp_macro_tipo_desc='Fresco'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'FPV',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='02'
and   tipo.elem_det_comp_macro_tipo_desc='FPV'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Avanzo',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='03'
and   tipo.elem_det_comp_macro_tipo_desc='Avanzo'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_macro_tipo
(
    elem_det_comp_macro_tipo_code,
    elem_det_comp_macro_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'Da attribuire',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and not exists
(
select 1
from siac_d_bil_elem_det_comp_macro_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_code='04'
and   tipo.elem_det_comp_macro_tipo_desc='Da attribuire'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- sotto componente FPV
-- Programmato non impegnato
-- Cumulato
-- Applicato
insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Programmato non impegnato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='01'
and   tipo.elem_det_comp_sotto_tipo_desc='Programmato non impegnato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Cumulato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='02'
and   tipo.elem_det_comp_sotto_tipo_desc='Cumulato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_sotto_tipo
(
	elem_det_comp_sotto_tipo_code,
    elem_det_comp_sotto_tipo_desc,
	elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Applicato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_sotto_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_sotto_tipo_code='03'
and   tipo.elem_det_comp_sotto_tipo_desc='Applicato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- ambito componente Fresco
-- Autonomo
-- Vincolato
-- Da definire
insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Autonomo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='01'
and   tipo.elem_det_comp_tipo_ambito_desc='Autonomo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Vincolato',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='02'
and   tipo.elem_det_comp_tipo_ambito_desc='Vincolato'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_ambito
(
    elem_det_comp_tipo_ambito_code,
    elem_det_comp_tipo_ambito_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Da definire',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='01'
and   macro.elem_det_comp_macro_tipo_desc='Fresco'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_ambito tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_ambito_code='03'
and   tipo.elem_det_comp_tipo_ambito_desc='Da definire'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- Fonte componente
-- FPV
--  Fresco / Avanzo
-- Avanzo
--  Avanzo/Reiscrizione Perenti
insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '01',
    'Fresco',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='01'
and   tipo.elem_det_comp_tipo_fonte_desc='Fresco'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '02',
    'Avanzo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='02'
and   tipo.elem_det_comp_tipo_fonte_desc='Avanzo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '03',
    'Avanzo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='03'
and   macro.elem_det_comp_macro_tipo_desc='Avanzo'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='03'
and   tipo.elem_det_comp_tipo_fonte_desc='Avanzo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fonte
(
      elem_det_comp_tipo_fonte_code,
      elem_det_comp_tipo_fonte_desc,
      elem_det_comp_macro_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
)
select
    '04',
    'Reiscrizione Perenti',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='03'
and   macro.elem_det_comp_macro_tipo_desc='Avanzo'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fonte tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fonte_code='04'
and   tipo.elem_det_comp_tipo_fonte_desc='Reiscrizione Perenti'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

-- Momento per FPV
-- Gestione/ROR/ Bilancio previsione
insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Bilancio previsione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='01'
and   tipo.elem_det_comp_tipo_fase_desc='Bilancio previsione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'Gestione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='02'
and   tipo.elem_det_comp_tipo_fase_desc='Gestione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'ROR effettivo',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='03'
and   tipo.elem_det_comp_tipo_fase_desc='ROR effettivo'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_fase
(
    elem_det_comp_tipo_fase_code,
    elem_det_comp_tipo_fase_desc,
    elem_det_comp_macro_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'ROR previsione',
    macro.elem_det_comp_macro_tipo_id,
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente,siac_d_bil_elem_det_comp_macro_tipo macro
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_code='02'
and   macro.elem_det_comp_macro_tipo_desc='FPV'
and not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_fase tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_fase_code='04'
and   tipo.elem_det_comp_tipo_fase_desc='ROR previsione'
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

--- Default
insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '01',
    'Si',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='01'
and   tipo.elem_det_comp_tipo_def_desc='Si'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '02',
    'No',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='02'
and   tipo.elem_det_comp_tipo_def_desc='No'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '03',
    'Solo Previsione',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='03'
and   tipo.elem_det_comp_tipo_def_desc='Solo Previsione'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_def
(
	elem_det_comp_tipo_def_code,
    elem_det_comp_tipo_def_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select
    '04',
    'Solo Gestione',
    now(),
    'SIAC-6883',
    ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo_def tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_tipo_def_code='04'
and   tipo.elem_det_comp_tipo_def_desc='Solo Gestione'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
);

insert into siac_d_bil_elem_det_comp_tipo_stato (elem_det_comp_tipo_stato_code, elem_det_comp_tipo_stato_desc, validita_inizio, login_operazione, ente_proprietario_id)
select tmp.code, tmp.descr, now(), 'SIAC-6881', ente.ente_proprietario_id
from siac_t_ente_proprietario ente
cross join (values
    ('V', 'Valido'),
    ('A', 'Annullato')
) as tmp(code, descr)
where not exists (
    select 1
    from siac_d_bil_elem_det_comp_tipo_stato stato
    where stato.ente_proprietario_id = ente.ente_proprietario_id
    and stato.elem_det_comp_tipo_stato_code = tmp.code
    and stato.data_cancellazione is null
    and stato.validita_fine is null
);

-- 25.11.2019 Sofia - inserimento componente di default - da attribuire
-- 27.11.2019 Sofia - commentato in accordo con Maspes
/*insert into siac_d_bil_elem_det_comp_tipo 
(
  elem_det_comp_tipo_code,
  elem_det_comp_tipo_desc,
  elem_det_comp_macro_tipo_id,
  elem_det_comp_tipo_def_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select '01',
       'Da attribuire',
       macro.elem_det_comp_macro_tipo_id,
       def.elem_det_comp_tipo_def_id,
       now(),
       'SIAC-6883',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente,
     siac_d_bil_elem_det_comp_macro_tipo macro,
     siac_d_bil_elem_det_comp_tipo_def def
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   macro.ente_proprietario_id=ente.ente_proprietario_id
and   macro.elem_det_comp_macro_tipo_desc ='Da attribuire'
and   def.ente_proprietario_id=ente.ente_proprietario_id
and   def.elem_det_comp_tipo_def_desc='Si'
and   not exists
(
select 1
from siac_d_bil_elem_det_comp_tipo  tipo,siac_d_bil_elem_det_comp_tipo_stato stato
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.elem_det_comp_macro_tipo_id=macro.elem_det_comp_macro_tipo_id
and   tipo.elem_det_comp_tipo_def_id=def.elem_det_comp_tipo_def_id
and   Stato.elem_det_comp_tipo_stato_id=tipo.elem_det_comp_tipo_stato_id
and   stato.elem_det_comp_tipo_stato_code='V'
and   tipo.data_cancellazione is null
);*/
-- /DML
-- ALL delle componenti (SIAC-6881) FINE

