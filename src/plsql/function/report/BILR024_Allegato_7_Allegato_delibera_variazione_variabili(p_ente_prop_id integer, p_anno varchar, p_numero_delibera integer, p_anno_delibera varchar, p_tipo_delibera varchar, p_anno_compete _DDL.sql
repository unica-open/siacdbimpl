/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_variabili" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
tipoFci varchar;

BEGIN

--annoCapImp:= p_anno; 
annoCapImp:=p_anno_competenza;

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
--SIAC-8335 16/11/2022. Aggiunto il tipo capitolo FCI.
tipoFci='FCI';

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCodeE:='CAP-EG'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
display_error:='';

contaParametriParz:=0;
contaParametri:=0;

--SIAC-6163: 16/05/2018.
-- Introdotti i paramentri p_ele_variazioni e p_anno_variazione con l'elenco delle 
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

--SIAC-6864 09/04/2020.
--Aggiunto in input il parametro p_organo_provv.
--p_organo_provv puo' essere specificato da solo.
if  contaParametriParz = 1 
    OR contaParametriParz = 2 then
--SIAC-7767 20/10/2021
-- il parametro "organo che ha emesso il provvedimento" diventa facoltativo anche
-- se sono stati specificati i dati del provvedimento.
   -- OR (contaParametriParz = 3 and (p_organo_provv IS NULL OR
	--			p_organo_provv = ''))     then
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

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
           	--------capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
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
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	in('STA', 'SCA') 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--SIAC-8335 16/11/2022. Aggiunto il tipo capitolo FCI.
        --Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  		-- quello stanziato.
  --      and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,
  --      	tipoFpvsc)	
  		and	((cat_del_capitolo.elem_cat_code in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,
        			tipoFpvsc)  	 
               and	capitolo_imp_tipo.elem_det_tipo_code	in('STA')) OR
             (cat_del_capitolo.elem_cat_code in (tipoFci) 
              and capitolo_imp_tipo.elem_det_tipo_code	in('SCA')))         
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
        /*and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
    -----group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente

     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera is not null THEN
  insert into siac_rep_var_entrate
  select	dettaglio_variazione.elem_id,
          dettaglio_variazione.elem_det_importo,
          cat_del_capitolo.elem_cat_code,
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
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc ,
          -- 21-12 anna inizio
          siac_t_bil					t_bil,
          -- 21-12 anna fine
          siac_t_periodo 				anno_importi
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil 				= 	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  -- 21-12 anna commentato and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
  -- 21-12 anna inizio
  and		anno_eserc.periodo_id 								=   t_bil.periodo_id
  and 	t_bil.bil_id 										=	testata_variazione.bil_id								
  -- 21-12 anna fine
  and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id								
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id											
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		atto.ente_proprietario_id 							=  p_ente_prop_id	
  -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		anno_eserc.anno										= 	p_anno 
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera	
  and		stato_atto.attoamm_stato_code						=	'DEFINITIVO'	
      -- 27/04:2017 l'anno di esercizio deve essere collegato a siac_t_bil									
      --and		anno_eserc.periodo_id 								=	testata_variazione.periodo_id								
  and		anno_importi.anno									= 	annoCapImp 
  and		tipologia_stato_var.variazione_stato_tipo_code		=	'D'
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
  --SIAC-8335 16/11/2022. Aggiunto il tipo capitolo FCI.
  --L'importo per i capitoli FCI e' quello di cassa e non lo
  --stanziato.  
  --and		tipo_elemento.elem_det_tipo_code					= 'STA'
  --and		cat_del_capitolo.elem_cat_code						in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc)	
  and	((cat_del_capitolo.elem_cat_code in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,
        			tipoFpvsc)  	 
            and	tipo_elemento.elem_det_tipo_code	in('STA')) OR
          (cat_del_capitolo.elem_cat_code in (tipoFci) 
           and tipo_elemento.elem_det_tipo_code	in('SCA')))  
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
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null;
else
	strQuery:= '
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
		dettaglio_variazione.elem_det_importo,
        cat_del_capitolo.elem_cat_code,
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	      	
from 	 siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_d_bil_elem_categoria 	cat_del_capitolo, 
        siac_r_bil_elem_categoria 	r_cat_capitolo,
        siac_t_periodo 				anno_eserc ,
        siac_t_bil					t_bil,
        siac_t_periodo 				anno_importi
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_eserc.periodo_id 								=   t_bil.periodo_id
and 	t_bil.bil_id 										=	testata_variazione.bil_id								
and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id								
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id											
and		capitolo.elem_id									=	r_cat_capitolo.elem_id
and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
and		testata_variazione.ente_proprietario_id 			= '||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
and		anno_importi.anno									= 	 '''||annoCapImp||'''
and		tipologia_stato_var.variazione_stato_tipo_code		=	''D''
and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
 --SIAC-8335 16/11/2022. Aggiunto il tipo capitolo FCI.
  --L''importo per i capitoli FCI e'' quello di cassa e non lo
  --stanziato.  
--and		tipo_elemento.elem_det_tipo_code					= ''STA''
--and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''')	
and	((cat_del_capitolo.elem_cat_code in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''')
          and tipo_elemento.elem_det_tipo_code					= ''STA'') OR
         (cat_del_capitolo.elem_cat_code in ('''||tipoFci||''') 
          and tipo_elemento.elem_det_tipo_code					= ''SCA'')) 
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
and		cat_del_capitolo.data_cancellazione			is null 
and     r_cat_capitolo.data_cancellazione			is null ';

raise notice 'sqlQuery = %', strQuery;

execute strQuery;

end if;
    
RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		sum(tb1.importo)   as 		variazione_aumento_stanziato,
        sum(tb2.importo)   as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        tb1.ente_proprietario
from   
	siac_rep_cap_eg_imp tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and 	tb1.importo > 0	) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	AND	tb2.importo < 0	)
    group by 	tb0.elem_id,
    			tb0.utente,
        		tb1.ente_proprietario;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;
variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;

/*
if tipologia_capitolo ='FCI' THEN
	stanziato:=1000;
    variazione_aumento:=100;
    variazione_diminuzione:=80;
end if;
*/

return next;

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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR024_Allegato_7_Allegato_delibera_variazione_variabili" (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar, p_organo_provv varchar)
  OWNER TO siac;