/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--SIAC-8604 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR227_Allegato_7_delibera_variazione_variabili_bozza_Prev" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  anno_riferimento varchar,
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

annoCapImp:= p_anno; 

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFci='FCI';

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
anno_riferimento='';
display_error:='';


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

contaParametriParz:=0;
contaParametri:=0;

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

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	in (elemTipoCodeE,elemTipoCodeS)
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--28/06/2021 SIAC-8139
--Aggiunto tipoFci
and	cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
	tipoFpvcc,tipoFpvsc,tipoFci)
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
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
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            --28/06/2021 SIAC-8139
            --Aggiunto tipoFci        
  --SIAC-8305 04/08/2021.
  -- Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  -- quello stanziato.            
		--and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFci)	
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
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
   
     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
          --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
          user_table utente,
          atto.ente_proprietario_id,
          anno_importo.anno	      	
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
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno 		
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')										
  and     anno_importo.anno                                   =   p_anno_competenza					
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
  --SIAC-8305 04/08/2021.
  -- Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  -- quello stanziato.
  --and		tipo_elemento.elem_det_tipo_code					= 'STA'
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci  
 -- and		cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
  --		tipoFpvcc,tipoFpvsc,tipoFci)	
  and ((cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
  											tipoFpvcc,tipoFpvsc)
       and	tipo_elemento.elem_det_tipo_code					= 'STA') OR
        (cat_del_capitolo.elem_cat_code	in (tipoFci)
         and tipo_elemento.elem_det_tipo_code					= 'SCA'))
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
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno;
else
	strQuery:='
    	insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
          select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          '''||user_table||''' utente,
          testata_variazione.ente_proprietario_id,
          anno_importo.anno	      	
  from 	siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
  and 	testata_variazione.variazione_num 						in   ('||p_ele_variazioni||')
  and		anno_eserc.anno										= 	'''||p_anno||''' 		
  and		tipologia_stato_var.variazione_stato_tipo_code		in	(''B'',''G'', ''C'', ''P'')										
  and     anno_importo.anno                                   =   '''||p_anno_competenza||'''					
  and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
  --and		tipo_elemento.elem_det_tipo_code					= ''STA''
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci    
  --SIAC-8305 04/08/2021.
  -- Per i capitoli di tipo FCI deve essere preso l''importo di cassa e non
  -- quello stanziato.    
  --and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''','''||tipoFci||''')	
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
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, 
              utente,
              testata_variazione.ente_proprietario_id,
              anno_importo.anno'; 

raise notice 'strQuery = %', strQuery;

execute strQuery;                    
end if;                  	                          
    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =p_anno 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 1)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 1)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 2)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 2)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
     ;

     RTN_MESSAGGIO:='preparazione file output ''.';      
         
for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione,
        tb1.periodo_anno                                                anno_riferimento          
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
                    and tb1.periodo_anno=tb2.periodo_anno
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;

variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;
anno_riferimento := classifBilRec.anno_riferimento;


return next;

end loop;

--03/02/2022 SIAC-8604.
-- C'e' un return next di troppo che non deve esserci.
--return next;

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

--SIAC-8604 - Maurizio - FINE

--SIAC-8621 - Haitham - INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_capitolo_entrata(p_anno_bilancio character varying, p_ente_proprietario_id integer, p_data timestamp without time zone)
 RETURNS TABLE(esito character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE

  rec_elem_id record;
  rec_classif_id record;
  rec_attr record;
  rec_elem_dett record;
  -- Variabili per campi estratti dal cursore rec_elem_id
  v_ente_proprietario_id INTEGER := null;
  v_ente_denominazione VARCHAR := null;
  v_anno VARCHAR := null;
  v_fase_operativa_code VARCHAR := null;
  v_fase_operativa_desc VARCHAR := null;
  v_elem_code VARCHAR := null;
  v_elem_code2 VARCHAR := null;
  v_elem_code3 VARCHAR := null;
  v_elem_desc VARCHAR := null;
  v_elem_desc2 VARCHAR := null;
  v_elem_tipo_code VARCHAR := null;
  v_elem_tipo_desc VARCHAR := null;
  v_elem_stato_code VARCHAR := null;
  v_elem_stato_desc VARCHAR := null;
  v_elem_cat_code VARCHAR := null;
  v_elem_cat_desc VARCHAR := null;
  -- Variabili per classificatori in gerarchia
  v_codice_titolo_entrata VARCHAR := null;
  v_descrizione_titolo_entrata VARCHAR := null;
  v_codice_tipologia_entrata VARCHAR := null;
  v_descrizione_tipologia_entrata VARCHAR := null;
  v_codice_categoria_entrata VARCHAR := null;
  v_descrizione_categoria_entrata VARCHAR := null;
  v_codice_pdc_finanziario_I VARCHAR := null;
  v_descrizione_pdc_finanziario_I VARCHAR := null;
  v_codice_pdc_finanziario_II VARCHAR := null;
  v_descrizione_pdc_finanziario_II VARCHAR := null;
  v_codice_pdc_finanziario_III VARCHAR := null;
  v_descrizione_pdc_finanziario_III VARCHAR := null;
  v_codice_pdc_finanziario_IV VARCHAR := null;
  v_descrizione_pdc_finanziario_IV VARCHAR := null;
  v_codice_pdc_finanziario_V VARCHAR := null;
  v_descrizione_pdc_finanziario_V VARCHAR := null;
  v_codice_cofog_divisione VARCHAR := null;
  v_descrizione_cofog_divisione VARCHAR := null;
  v_codice_cofog_gruppo VARCHAR := null;
  v_descrizione_cofog_gruppo VARCHAR := null;
  v_codice_cdr VARCHAR := null;
  v_descrizione_cdr VARCHAR := null;
  v_codice_cdc VARCHAR := null;
  v_descrizione_cdc VARCHAR := null;
  v_codice_siope_I_entrata VARCHAR := null;
  v_descrizione_siope_I_entrata VARCHAR := null;
  v_codice_siope_II_entrata VARCHAR := null;
  v_descrizione_siope_II_entrata VARCHAR := null;
  v_codice_siope_III_entrata VARCHAR := null;
  v_descrizione_siope_III_entrata VARCHAR := null;
  -- Variabili per classificatori non in gerarchia
  v_codice_entrata_ricorrente VARCHAR := null;
  v_descrizione_entrata_ricorrente VARCHAR := null;
  v_codice_transazione_entrata_ue VARCHAR := null;
  v_descrizione_transazione_entrata_ue VARCHAR := null;
  v_codice_tipo_fondo VARCHAR := null;
  v_descrizione_tipo_fondo VARCHAR := null;
  v_codice_tipo_finanziamento VARCHAR := null;
  v_descrizione_tipo_finanziamento VARCHAR := null;
  v_codice_perimetro_sanitario_entrata VARCHAR := null;
  v_descrizione_perimetro_sanitario_entrata VARCHAR := null;
 v_classificatore_generico_1 VARCHAR := null;
  v_classificatore_generico_1_descrizione_valore VARCHAR := null;
  v_classificatore_generico_1_valore VARCHAR := null;
  v_classificatore_generico_2 VARCHAR := null;
  v_classificatore_generico_2_descrizione_valore VARCHAR := null;
  v_classificatore_generico_2_valore VARCHAR := null;
  v_classificatore_generico_3 VARCHAR := null;
  v_classificatore_generico_3_descrizione_valore VARCHAR := null;
  v_classificatore_generico_3_valore VARCHAR := null;
  v_classificatore_generico_4 VARCHAR := null;
  v_classificatore_generico_4_descrizione_valore VARCHAR := null;
  v_classificatore_generico_4_valore VARCHAR := null;
  v_classificatore_generico_5 VARCHAR := null;
  v_classificatore_generico_5_descrizione_valore VARCHAR := null;
  v_classificatore_generico_5_valore VARCHAR := null;
  v_classificatore_generico_6 VARCHAR := null;
  v_classificatore_generico_6_descrizione_valore VARCHAR := null;
  v_classificatore_generico_6_valore VARCHAR := null;
  v_classificatore_generico_7 VARCHAR := null;
  v_classificatore_generico_7_descrizione_valore VARCHAR := null;
  v_classificatore_generico_7_valore VARCHAR := null;
  v_classificatore_generico_8 VARCHAR := null;
  v_classificatore_generico_8_descrizione_valore VARCHAR := null;
  v_classificatore_generico_8_valore VARCHAR := null;
  v_classificatore_generico_9 VARCHAR := null;
  v_classificatore_generico_9_descrizione_valore VARCHAR := null;
  v_classificatore_generico_9_valore VARCHAR := null;
  v_classificatore_generico_10 VARCHAR := null;
  v_classificatore_generico_10_descrizione_valore VARCHAR := null;
  v_classificatore_generico_10_valore VARCHAR := null;
  v_classificatore_generico_11 VARCHAR := null;
  v_classificatore_generico_11_descrizione_valore VARCHAR := null;
  v_classificatore_generico_11_valore VARCHAR := null;
  v_classificatore_generico_12 VARCHAR := null;
  v_classificatore_generico_12_descrizione_valore VARCHAR := null;
  v_classificatore_generico_12_valore VARCHAR := null;
  v_classificatore_generico_13 VARCHAR := null;
  v_classificatore_generico_13_descrizione_valore VARCHAR := null;
  v_classificatore_generico_13_valore VARCHAR:= null;
  v_classificatore_generico_14 VARCHAR := null;
  v_classificatore_generico_14_descrizione_valore VARCHAR := null;
  v_classificatore_generico_14_valore VARCHAR := null;
  v_classificatore_generico_15 VARCHAR := null;
  v_classificatore_generico_15_descrizione_valore VARCHAR := null;
  v_classificatore_generico_15_valore VARCHAR := null;
  -- Variabili per attributi
  v_FlagEntrateRicorrenti VARCHAR := null;
  v_FlagImpegnabile VARCHAR := null;
  v_FlagPerMemoria VARCHAR := null;
  v_FlagRilevanteIva VARCHAR := null;
  v_FlagTrasferimentoOrganiComunitari VARCHAR := null;
  v_Note VARCHAR := null;
  v_FlagAccertatoPerCassa VARCHAR := null;
  -- Variabili per stipendio
  v_codice_stipendio VARCHAR := null;
  v_descrizione_stipendio VARCHAR := null;
  -- Variabili per attivita' iva
  v_codice_attivita_iva VARCHAR := null;
  v_descrizione_attivita_iva VARCHAR := null;
  -- Variabili per i campi di detaglio degli elementi
  v_massimo_impegnabile_anno1 NUMERIC := null;
  v_stanziamento_cassa_anno1 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno1  NUMERIC := null;
  v_stanziamento_anno1 NUMERIC := null;
  v_stanziamento_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_anno1  NUMERIC := null;
  v_flag_anno1 VARCHAR := null;
  v_massimo_impegnabile_anno2 NUMERIC := null;
  v_stanziamento_cassa_anno2 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno2 NUMERIC := null;
  v_stanziamento_anno2 NUMERIC := null;
  v_stanziamento_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_anno2 NUMERIC := null;
  v_flag_anno2 VARCHAR := null;
  v_massimo_impegnabile_anno3 NUMERIC := null;
  v_stanziamento_cassa_anno3 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno3 NUMERIC := null;
  v_stanziamento_anno3 NUMERIC := null;
  v_stanziamento_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_anno3 NUMERIC := null;
  v_flag_anno3 VARCHAR := null;
  -- Variabili per campi funzione
  v_disponibilita_accertare_anno1 NUMERIC := null;
  v_disponibilita_accertare_anno2 NUMERIC := null;
  v_disponibilita_accertare_anno3 NUMERIC := null;
  -- Variabili utili per il caricamento
  v_classif_code VARCHAR := null;
  v_classif_desc VARCHAR := null;
  v_classif_tipo_code VARCHAR := null;
  v_classif_tipo_desc VARCHAR :=null;
  v_elem_id INTEGER := null;
  v_classif_id INTEGER := null;
  v_classif_id_part INTEGER := null;
  v_classif_id_padre INTEGER := null;
  v_classif_tipo_id INTEGER := null;
  v_classif_fam_id INTEGER := null;
  v_conta_ciclo_classif INTEGER := null;
  v_anno_elem_dett INTEGER := null;
  v_anno_appo INTEGER := null;
  v_flag_attributo VARCHAR := null;
  v_bil_id INTEGER := null;

  v_fnc_result VARCHAR := null;
  --SIAC-5895
  v_bil_id_prec INTEGER:=null;
  v_anno_prec INTEGER:=null;
  v_elem_tipo_id INTEGER:=null;
  v_ex_anno VARCHAR:=null;
  v_ex_capitolo VARCHAR:= null;
  v_ex_articolo VARCHAR:=null;

v_user_table varchar;
params varchar;


BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

select fnc_siac_random_user()
into	v_user_table;

IF p_data IS NULL THEN
   p_data := now();
END IF;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_capitolo_entrata',
params,
clock_timestamp(),
v_user_table
);

select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

-- SIAC-5895
esito:= '  Inizio Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;
select tb.bil_id,tp.anno
into v_bil_id_prec, v_anno_prec
from siac.siac_t_periodo tp
INNER JOIN siac.siac_t_bil tb  ON tb.periodo_id = tp.periodo_id
where tp.ente_proprietario_id = p_ente_proprietario_id
and   tp.anno::integer = p_anno_bilancio::integer-1;
esito:= '  Fine Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;

-- SIAC-6007
esito:= '  Inizio Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;
select elem_tipo_id
into v_elem_tipo_id
from siac_d_bil_elem_tipo
where elem_tipo_code = 'CAP-EG'
and   ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_capitolo_entrata
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre gli elementi
FOR rec_elem_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, dbet.elem_tipo_code, dbet.elem_tipo_desc,
       dbes.elem_stato_code, dbes.elem_stato_desc, dbec.elem_cat_code, dbec.elem_cat_desc,
       tbe.elem_id,  tb.bil_id
       --, tbe.elem_tipo_id COMMENTATO PER SIAC-6007
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tb.periodo_id = tp.periodo_id
INNER JOIN siac.siac_t_ente_proprietario tep ON tb.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
LEFT JOIN  siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
                                               AND p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
                                               AND rbec.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
                                              AND p_data BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, p_data)
                                              AND dbec.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND dbet.elem_tipo_code in ('CAP-EG', 'CAP-EP')
AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
AND tbe.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, p_data)
AND dbet.data_cancellazione IS NULL
AND p_data BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, p_data)
AND rbes.data_cancellazione IS NULL
AND p_data BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, p_data)
AND dbes.data_cancellazione IS NULL

LOOP
v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_elem_code := null;
v_elem_code2 := null;
v_elem_code3 := null;
v_elem_desc := null;
v_elem_desc2 := null;
v_elem_tipo_code := null;
v_elem_tipo_desc := null;
v_elem_stato_code := null;
v_elem_stato_desc := null;
v_elem_cat_code := null;
v_elem_cat_desc := null;

v_elem_id := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_bil_id := null;

v_ente_proprietario_id := rec_elem_id.ente_proprietario_id;
v_ente_denominazione := rec_elem_id.ente_denominazione;
v_anno := rec_elem_id.anno;
v_elem_code := rec_elem_id.elem_code;
v_elem_code2 := rec_elem_id.elem_code2;
v_elem_code3 := rec_elem_id.elem_code3;

-- 17.02.2020 Sofia  Jira SIAC-7329
-- v_elem_desc := rec_elem_id.elem_desc;

v_elem_desc:=
translate( rec_elem_id.elem_desc,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);

-- 17.02.2020 Sofia  Jira SIAC-7329
-- v_elem_desc2 := rec_elem_id.elem_desc2;

v_elem_desc2 :=
translate( rec_elem_id.elem_desc2,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);



v_elem_tipo_code := rec_elem_id.elem_tipo_code;
v_elem_tipo_desc := rec_elem_id.elem_tipo_desc;
v_elem_stato_code := rec_elem_id.elem_stato_code;
v_elem_stato_desc := rec_elem_id.elem_stato_desc;
v_elem_cat_code := rec_elem_id.elem_cat_code;
v_elem_cat_desc := rec_elem_id.elem_cat_desc;

v_elem_id := rec_elem_id.elem_id;
v_anno_appo := rec_elem_id.anno::integer;
v_bil_id := rec_elem_id.bil_id;

-- Sezione per estrarre i classificatori
v_codice_titolo_entrata := null;
v_descrizione_titolo_entrata := null;
v_codice_tipologia_entrata := null;
v_descrizione_tipologia_entrata := null;
v_codice_categoria_entrata := null;
v_descrizione_categoria_entrata := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_cofog_divisione := null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;
v_codice_cdr := null;
v_descrizione_cdr := null;
v_codice_cdc := null;
v_descrizione_cdc := null;
v_codice_siope_I_entrata := null;
v_descrizione_siope_I_entrata := null;
v_codice_siope_II_entrata := null;
v_descrizione_siope_II_entrata := null;
v_codice_siope_III_entrata := null;
v_descrizione_siope_III_entrata := null;

v_codice_entrata_ricorrente := null;
v_descrizione_entrata_ricorrente := null;
v_codice_transazione_entrata_ue := null;
v_descrizione_transazione_entrata_ue := null;
v_codice_tipo_fondo := null;
v_descrizione_tipo_fondo := null;
v_codice_tipo_finanziamento := null;
v_descrizione_tipo_finanziamento := null;
v_codice_perimetro_sanitario_entrata := null;
v_descrizione_perimetro_sanitario_entrata := null;
v_classificatore_generico_1:= null;
v_classificatore_generico_1_descrizione_valore:= null;
v_classificatore_generico_1_valore:= null;
v_classificatore_generico_2:= null;
v_classificatore_generico_2_descrizione_valore:= null;
v_classificatore_generico_2_valore:= null;
v_classificatore_generico_3:= null;
v_classificatore_generico_3_descrizione_valore:= null;
v_classificatore_generico_3_valore:= null;
v_classificatore_generico_4:= null;
v_classificatore_generico_4_descrizione_valore:= null;
v_classificatore_generico_4_valore:= null;
v_classificatore_generico_5:= null;
v_classificatore_generico_5_descrizione_valore:= null;
v_classificatore_generico_5_valore:= null;
v_classificatore_generico_6:= null;
v_classificatore_generico_6_descrizione_valore:= null;
v_classificatore_generico_6_valore:= null;
v_classificatore_generico_7:= null;
v_classificatore_generico_7_descrizione_valore:= null;
v_classificatore_generico_7_valore:= null;
v_classificatore_generico_8:= null;
v_classificatore_generico_8_descrizione_valore:= null;
v_classificatore_generico_8_valore:= null;
v_classificatore_generico_9:= null;
v_classificatore_generico_9_descrizione_valore:= null;
v_classificatore_generico_9_valore:= null;
v_classificatore_generico_10:= null;
v_classificatore_generico_10_descrizione_valore:= null;
v_classificatore_generico_10_valore:= null;
v_classificatore_generico_11:= null;
v_classificatore_generico_11_descrizione_valore:= null;
v_classificatore_generico_11_valore:= null;
v_classificatore_generico_12:= null;
v_classificatore_generico_12_descrizione_valore:= null;
v_classificatore_generico_12_valore:= null;
v_classificatore_generico_13:= null;
v_classificatore_generico_13_descrizione_valore:= null;
v_classificatore_generico_13_valore:= null;
v_classificatore_generico_14:= null;
v_classificatore_generico_14_descrizione_valore:= null;
v_classificatore_generico_14_valore:= null;
v_classificatore_generico_15:= null;
v_classificatore_generico_15_descrizione_valore:= null;
v_classificatore_generico_15_valore:= null;
--SIAC-5895
--v_elem_tipo_id := rec_elem_id.elem_tipo_id; Commentato per SIAC-6007
v_ex_anno :=null;
v_ex_capitolo := null;
v_ex_articolo :=null;
esito:= '  Inizio ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
-- Sezione per estrarre la fase operativa
SELECT dfo.fase_operativa_code, dfo.fase_operativa_desc
INTO v_fase_operativa_code, v_fase_operativa_desc
FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
WHERE dfo.fase_operativa_id = rbfo.fase_operativa_id
AND   rbfo.bil_id = v_bil_id
AND   p_data BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, p_data)
AND   p_data BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, p_data)
AND   rbfo.data_cancellazione IS NULL
AND   dfo.data_cancellazione IS NULL;
-- Ciclo per estrarre i classificatori relativi ad un dato elemento
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
FROM siac.siac_r_bil_elem_class rbec, siac.siac_t_class tc
WHERE tc.classif_id = rbec.classif_id
AND   rbec.elem_id = v_elem_id
AND   rbec.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

LOOP

v_classif_id :=  rec_classif_id.classif_id;
v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
v_classif_fam_id := null;

-- Estrazione per determinare se un classificatore e' in gerarchia
SELECT rcfct.classif_fam_id
INTO v_classif_fam_id
FROM siac.siac_r_class_fam_class_tipo rcfct
WHERE rcfct.classif_tipo_id = v_classif_tipo_id
AND   rcfct.data_cancellazione IS NULL
AND   p_data BETWEEN rcfct.validita_inizio AND COALESCE(rcfct.validita_fine, p_data);

-- Se il classificatore non e' in gerarchia
IF NOT FOUND THEN
  esito:= '    Inizio step classificatori non in gerarchia - '||clock_timestamp();
  return next;
  v_classif_tipo_code := null;
  v_classif_tipo_desc :=null;
  v_classif_code := rec_classif_id.classif_code;
  v_classif_desc := rec_classif_id.classif_desc;

  SELECT dct.classif_tipo_code,dct.classif_tipo_desc
  INTO   v_classif_tipo_code,v_classif_tipo_desc
  FROM   siac.siac_d_class_tipo dct
  WHERE  dct.classif_tipo_id = v_classif_tipo_id
  AND    dct.data_cancellazione IS NULL
  AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'RICORRENTE_ENTRATA' THEN
     v_codice_entrata_ricorrente      := v_classif_code;
     v_descrizione_entrata_ricorrente := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TRANSAZIONE_UE_ENTRATA' THEN
     v_codice_transazione_entrata_ue      := v_classif_code;
     v_descrizione_transazione_entrata_ue := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FONDO' THEN
     v_codice_tipo_fondo      := v_classif_code;
     v_descrizione_tipo_fondo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FINANZIAMENTO' THEN
     v_codice_tipo_finanziamento      := v_classif_code;
     v_descrizione_tipo_finanziamento := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_ENTRATA' THEN
     v_codice_perimetro_sanitario_entrata      := v_classif_code;
     v_descrizione_perimetro_sanitario_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_36' THEN
     v_classificatore_generico_1      := v_classif_tipo_desc;
     v_classificatore_generico_1_descrizione_valore := v_classif_desc;
     v_classificatore_generico_1_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_37' THEN
     v_classificatore_generico_2     := v_classif_tipo_desc;
     v_classificatore_generico_2_descrizione_valore := v_classif_desc;
     v_classificatore_generico_2_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_38' THEN
     v_classificatore_generico_3      := v_classif_tipo_desc;
     v_classificatore_generico_3_descrizione_valore := v_classif_desc;
     v_classificatore_generico_3_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_39' THEN
     v_classificatore_generico_4     := v_classif_tipo_desc;
     v_classificatore_generico_4_descrizione_valore := v_classif_desc;
     v_classificatore_generico_4_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_40' THEN
     v_classificatore_generico_5     := v_classif_tipo_desc;
     v_classificatore_generico_5_descrizione_valore := v_classif_desc;
     v_classificatore_generico_5_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_41' THEN
     v_classificatore_generico_6      := v_classif_tipo_desc;
     v_classificatore_generico_6_descrizione_valore := v_classif_desc;
     v_classificatore_generico_6_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_42' THEN
     v_classificatore_generico_7      := v_classif_tipo_desc;
     v_classificatore_generico_7_descrizione_valore := v_classif_desc;
     v_classificatore_generico_7_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_43' THEN
     v_classificatore_generico_8      := v_classif_tipo_desc;
     v_classificatore_generico_8_descrizione_valore := v_classif_desc;
     v_classificatore_generico_8_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_44' THEN
     v_classificatore_generico_9      := v_classif_tipo_desc;
     v_classificatore_generico_9_descrizione_valore := v_classif_desc;
     v_classificatore_generico_9_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_45' THEN
     v_classificatore_generico_10      := v_classif_tipo_desc;
     v_classificatore_generico_10_descrizione_valore := v_classif_desc;
     v_classificatore_generico_10_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_46' THEN
     v_classificatore_generico_11      := v_classif_tipo_desc;
     v_classificatore_generico_11_descrizione_valore := v_classif_desc;
     v_classificatore_generico_11_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_47' THEN
     v_classificatore_generico_12     := v_classif_tipo_desc;
     v_classificatore_generico_12_descrizione_valore := v_classif_desc;
     v_classificatore_generico_12_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_48' THEN
     v_classificatore_generico_13      := v_classif_tipo_desc;
     v_classificatore_generico_13_descrizione_valore := v_classif_desc;
     v_classificatore_generico_13_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_49' THEN
     v_classificatore_generico_14     := v_classif_tipo_desc;
     v_classificatore_generico_14_descrizione_valore := v_classif_desc;
     v_classificatore_generico_14_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_50' THEN
     v_classificatore_generico_15      := v_classif_tipo_desc;
     v_classificatore_generico_15_descrizione_valore := v_classif_desc;
     v_classificatore_generico_15_valore      := v_classif_code;
  END IF;
  esito:= '    Fine step classificatori non in gerarchia - '||clock_timestamp();
  return next;
-- Se il classificatore e' in gerarchia
ELSE
 esito:= '    Inizio step classificatori in gerarchia - '||clock_timestamp();
 return next;
 v_conta_ciclo_classif :=0;
 v_classif_id_padre := null;

 -- Loop per RISALIRE la gerarchia di un dato classificatore
 LOOP

  v_classif_code := null;
  v_classif_desc := null;
  v_classif_id_part := null;
  v_classif_tipo_code := null;
  v_classif_tipo_desc := null;

  IF v_conta_ciclo_classif = 0 THEN
     v_classif_id_part := v_classif_id;
  ELSE
     v_classif_id_part := v_classif_id_padre;
  END IF;

  SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code,dct.classif_tipo_desc
  INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code,v_classif_tipo_desc
  FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
  WHERE rcft.classif_id = tc.classif_id
  AND   dct.classif_tipo_id = tc.classif_tipo_id
  AND   tc.classif_id = v_classif_id_part
  AND   rcft.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   dct.data_cancellazione IS NULL
  AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
  AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'TITOLO_ENTRATA' THEN
        v_codice_titolo_entrata := v_classif_code;
        v_descrizione_titolo_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPOLOGIA' THEN
        v_codice_tipologia_entrata := v_classif_code;
        v_descrizione_tipologia_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CATEGORIA' THEN
        v_codice_categoria_entrata := v_classif_code;
        v_descrizione_categoria_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_I' THEN
        v_codice_pdc_finanziario_I := v_classif_code;
        v_descrizione_pdc_finanziario_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_II' THEN
        v_codice_pdc_finanziario_II := v_classif_code;
        v_descrizione_pdc_finanziario_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_III' THEN
        v_codice_pdc_finanziario_III := v_classif_code;
        v_descrizione_pdc_finanziario_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_IV' THEN
        v_codice_pdc_finanziario_IV := v_classif_code;
        v_descrizione_pdc_finanziario_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_V' THEN
        v_codice_pdc_finanziario_V := v_classif_code;
        v_descrizione_pdc_finanziario_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDR' THEN
        v_codice_cdr := v_classif_code;
        v_descrizione_cdr := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDC' THEN
        v_codice_cdc := v_classif_code;
        v_descrizione_cdc := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_ENTRATA_I' THEN
        v_codice_siope_I_entrata := v_classif_code;
        v_descrizione_siope_I_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_ENTRATA_II' THEN
        v_codice_siope_II_entrata := v_classif_code;
        v_descrizione_siope_II_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_ENTRATA_III' THEN
        v_codice_siope_III_entrata := v_classif_code;
        v_descrizione_siope_III_entrata := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
 esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
 return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
esito:= '    Inizio step attributi - '||clock_timestamp();
return next;
v_FlagEntrateRicorrenti := null;
v_FlagImpegnabile := null;
v_FlagPerMemoria := null;
v_FlagRilevanteIva := null;
v_FlagTrasferimentoOrganiComunitari := null;
v_Note := null;
v_FlagAccertatoPerCassa := null;
v_flag_attributo := null;

FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rbea.tabella_id, rbea.percentuale, rbea."boolean" true_false, rbea.numerico, rbea.testo
FROM   siac.siac_r_bil_elem_attr rbea, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rbea.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rbea.elem_id = v_elem_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rbea.validita_inizio AND COALESCE(rbea.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'FlagEntrateRicorrenti' THEN
     v_FlagEntrateRicorrenti := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagImpegnabile' THEN
     v_FlagImpegnabile := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagPerMemoria' THEN
     v_FlagPerMemoria := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagRilevanteIva' THEN
     v_FlagRilevanteIva := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagTrasferimentoOrganiComunitari' THEN
     v_FlagTrasferimentoOrganiComunitari := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Note' THEN
     v_Note := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagAccertatoPerCassa' THEN
     v_FlagAccertatoPerCassa := v_flag_attributo;
  END IF;

END LOOP;
esito:= '    Fine step attributi - '||clock_timestamp();
return next;
esito:= '    Inizio step stipendi - '||clock_timestamp();
return next;
-- Sezione per i dati di stipendio
v_codice_stipendio := null;
v_descrizione_stipendio := null;

SELECT dsc.stipcode_code, dsc.stipcode_desc
INTO v_codice_stipendio, v_descrizione_stipendio
FROM  siac.siac_r_bil_elem_stipendio_codice rbesc, siac.siac_d_stipendio_codice dsc
WHERE rbesc.stipcode_id = dsc.stipcode_id
AND   rbesc.elem_id = v_elem_id
AND   rbesc.data_cancellazione IS NULL
AND   dsc.data_cancellazione IS NULL
AND   p_data between rbesc.validita_inizio and coalesce(rbesc.validita_fine, p_data)
AND   p_data between dsc.validita_inizio and coalesce(dsc.validita_fine, p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step iva - '||clock_timestamp();
return next;
-- Sezione per i dati di iva
v_codice_attivita_iva := null;
v_descrizione_attivita_iva := null;

SELECT tia.ivaatt_code, tia.ivaatt_desc
INTO v_codice_attivita_iva, v_descrizione_attivita_iva
FROM siac.siac_r_bil_elem_iva_attivita rbeia, siac.siac_t_iva_attivita tia
WHERE rbeia.ivaatt_id = tia.ivaatt_id
AND   rbeia.elem_id = v_elem_id
AND   rbeia.data_cancellazione IS NULL
AND   tia.data_cancellazione IS NULL
AND   p_data between rbeia.validita_inizio and coalesce(rbeia.validita_fine,p_data)
AND   p_data between tia.validita_inizio and coalesce(tia.validita_fine,p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step dettagli elementi - '||clock_timestamp();
return next;
-- Sezione per i dati di dettaglio degli elementi
v_massimo_impegnabile_anno1 := null;
v_stanziamento_cassa_anno1 := null;
v_stanziamento_cassa_iniziale_anno1 := null;
v_stanziamento_residuo_iniziale_anno1 := null;
v_stanziamento_anno1 := null;
v_stanziamento_iniziale_anno1 := null;
v_stanziamento_residuo_anno1 := null;
v_flag_anno1 := null;
v_massimo_impegnabile_anno2 := null;
v_stanziamento_cassa_anno2 := null;
v_stanziamento_cassa_iniziale_anno2 := null;
v_stanziamento_residuo_iniziale_anno2 := null;
v_stanziamento_anno2 := null;
v_stanziamento_iniziale_anno2 := null;
v_stanziamento_residuo_anno2 := null;
v_flag_anno2 := null;
v_massimo_impegnabile_anno3 := null;
v_stanziamento_cassa_anno3 := null;
v_stanziamento_cassa_iniziale_anno3 := null;
v_stanziamento_residuo_iniziale_anno3 := null;
v_stanziamento_anno3 := null;
v_stanziamento_iniziale_anno3 := null;
v_stanziamento_residuo_anno3 := null;
v_flag_anno3 := null;

v_anno_elem_dett := null;

FOR rec_elem_dett IN
SELECT dbedt.elem_det_tipo_code, tbed.elem_det_flag, tbed.elem_det_importo, tp.anno
FROM  siac.siac_t_bil_elem_det tbed, siac.siac_d_bil_elem_det_tipo dbedt, siac.siac_t_periodo tp
WHERE tbed.elem_det_tipo_id = dbedt.elem_det_tipo_id
AND   tbed.periodo_id = tp.periodo_id
AND   tbed.elem_id = v_elem_id
AND   tbed.data_cancellazione IS NULL
AND   dbedt.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   p_data between tbed.validita_inizio and coalesce(tbed.validita_fine,p_data)
AND   p_data between dbedt.validita_inizio and coalesce(dbedt.validita_fine,p_data)
AND   p_data between tp.validita_inizio and coalesce(tp.validita_fine,p_data)

LOOP
v_anno_elem_dett := rec_elem_dett.anno::integer;
  IF v_anno_elem_dett = v_anno_appo THEN
    v_flag_anno1 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno1 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 1) THEN
    v_flag_anno2 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno2 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 2) THEN
    v_flag_anno3 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno3 := rec_elem_dett.elem_det_importo;
    END IF;
  END IF;
END LOOP;
esito:= '    Fine step dettagli elementi - '||clock_timestamp();
return next;
esito:= '    Inizio step dati da funzione - '||clock_timestamp();
return next;
-- Sezione per valorizzazione delle variabili per i campi di funzione
v_disponibilita_accertare_anno1 := null;
v_disponibilita_accertare_anno2 := null;
v_disponibilita_accertare_anno3 := null;

IF v_elem_tipo_code = 'CAP-EG' THEN
   v_disponibilita_accertare_anno1 := siac.fnc_siac_disponibilitaaccertareeg_anno1(v_elem_id);
   v_disponibilita_accertare_anno2 := siac.fnc_siac_disponibilitaaccertareeg_anno2(v_elem_id);
   v_disponibilita_accertare_anno3 := siac.fnc_siac_disponibilitaaccertareeg_anno3(v_elem_id);
END IF;
esito:= '    Fine step dati da funzione - '||clock_timestamp();
return next;

-- SIAC-5895
esito:= '    Inizio step dati ex capitolo - '||clock_timestamp();
return next;

select per.anno,elem.elem_code,elem.elem_code2
into v_ex_anno, v_ex_capitolo, v_ex_articolo
from siac_r_bil_elem_rel_tempo r_ex
, siac_t_bil_elem elem
, siac_t_bil bil
, siac_t_periodo per
where r_ex.elem_id = v_elem_id
and   r_ex.data_cancellazione is null
and   p_data between r_ex.validita_inizio and coalesce(r_ex.validita_fine,p_data)
and   elem.elem_id = r_ex.elem_id_old
and   elem.bil_id = bil.bil_id
and   bil.periodo_id = per.periodo_id;

IF NOT FOUND then
--SIAC-6007 Indipendentemente dal tipo di capitolo, sia esso di previsione o gestione,
--il capitolo ricercato e di Gestione
  select
    v_anno_prec, elem.elem_code,elem.elem_code2
    into v_ex_anno, v_ex_capitolo, v_ex_articolo
  from siac_t_bil_elem elem
  where elem.elem_code =  v_elem_code
  and   elem.elem_code2 = v_elem_code2
  and   elem.elem_code3 = v_elem_code3
  and   elem.elem_tipo_id = v_elem_tipo_id
  and   elem.bil_id = v_bil_id_prec
  and   elem.data_cancellazione is null;  -- Haitham 10/02/2022 SIAC-8621
END IF;

esito:= '    Fine step dati ex capitolo - '||clock_timestamp();
return next;

INSERT INTO siac.siac_dwh_capitolo_entrata
(ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
cod_tipo_capitolo,
desc_tipo_capitolo,
cod_stato_capitolo,
desc_stato_capitolo,
cod_classificazione_capitolo,
desc_classificazione_capitolo,
cod_titolo_entrata,
desc_titolo_entrata,
cod_tipologia_entrata,
desc_tipologia_entrata,
cod_categoria_entrata,
desc_categoria_entrata,
cod_pdc_finanziario_i,
desc_pdc_finanziario_i,
cod_pdc_finanziario_ii,
desc_pdc_finanziario_ii,
cod_pdc_finanziario_iii,
desc_pdc_finanziario_iii,
cod_pdc_finanziario_iv,
desc_pdc_finanziario_iv,
cod_pdc_finanziario_v,
desc_pdc_finanziario_v,
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
cod_cdr,
desc_cdr,
cod_cdc,
desc_cdc,
cod_siope_i_entrata,
desc_siope_i_entrata,
cod_siope_ii_entrata,
desc_siope_ii_entrata,
cod_siope_iii_entrata,
desc_siope_iii_entrata,
cod_entrata_ricorrente,
desc_entrata_ricorrente,
cod_transazione_entrata_ue,
desc_transazione_entrata_ue,
cod_tipo_fondo,
desc_tipo_fondo,
cod_tipo_finanziamento,
desc_tipo_finanziamento,
cod_perimetro_sanita_entrata,
desc_perimetro_sanita_entrata,
classificatore_1,
classificatore_1_valore,
classificatore_1_desc_valore,
classificatore_2,
classificatore_2_valore,
classificatore_2_desc_valore,
classificatore_3,
classificatore_3_valore,
classificatore_3_desc_valore,
classificatore_4,
classificatore_4_valore,
classificatore_4_desc_valore,
classificatore_5,
classificatore_5_valore,
classificatore_5_desc_valore,
classificatore_6,
classificatore_6_valore,
classificatore_6_desc_valore,
classificatore_7,
classificatore_7_valore,
classificatore_7_desc_valore,
classificatore_8,
classificatore_8_valore,
classificatore_8_desc_valore,
classificatore_9,
classificatore_9_valore,
classificatore_9_desc_valore,
classificatore_10,
classificatore_10_valore,
classificatore_10_desc_valore,
classificatore_11,
classificatore_11_valore,
classificatore_11_desc_valore,
classificatore_12,
classificatore_12_valore,
classificatore_12_desc_valore,
classificatore_13,
classificatore_13_valore,
classificatore_13_desc_valore,
classificatore_14,
classificatore_14_valore,
classificatore_14_desc_valore,
classificatore_15,
classificatore_15_valore,
classificatore_15_desc_valore,
flagentratericorrenti,
flagimpegnabile,
flagpermemoria,
flagrilevanteiva,
flag_trasf_organi_comunitari,
note,
cod_stipendio,
desc_stipendio,
cod_attivita_iva,
desc_attivita_iva,
massimo_impegnabile_anno1,
stanz_cassa_anno1,
stanz_cassa_iniziale_anno1,
stanz_residuo_iniziale_anno1,
stanz_anno1,
stanz_iniziale_anno1,
stanz_residuo_anno1,
flag_anno1,
massimo_impegnabile_anno2,
stanz_cassa_anno2,
stanz_cassa_iniziale_anno2,
stanz_residuo_iniziale_anno2,
stanz_anno2,
stanz_iniziale_anno2,
stanz_residuo_anno2,
flag_anno2,
massimo_impegnabile_anno3,
stanz_cassa_anno3,
stanz_cassa_iniziale_anno3,
stanz_residuo_iniziale_anno3,
stanz_anno3,
stanz_iniziale_anno3,
stanz_residuo_anno3,
flag_anno3,
disponibilita_accertare_anno1,
disponibilita_accertare_anno2,
disponibilita_accertare_anno3,
flagaccertatopercassa
--SIAC-5895
,ex_anno
,ex_capitolo
,ex_articolo
)
VALUES (v_ente_proprietario_id,
        v_ente_denominazione,
        v_anno,
        v_fase_operativa_code,
        v_fase_operativa_desc,
        v_elem_code,
        v_elem_code2,
        v_elem_code3,
        v_elem_desc,
        v_elem_desc2,
        v_elem_tipo_code,
        v_elem_tipo_desc,
        v_elem_stato_code,
        v_elem_stato_desc,
        v_elem_cat_code,
        v_elem_cat_desc,
        v_codice_titolo_entrata,
        v_descrizione_titolo_entrata,
        v_codice_tipologia_entrata,
        v_descrizione_tipologia_entrata,
        v_codice_categoria_entrata,
        v_descrizione_categoria_entrata,
        v_codice_pdc_finanziario_I,
        v_descrizione_pdc_finanziario_I,
        v_codice_pdc_finanziario_II,
        v_descrizione_pdc_finanziario_II,
        v_codice_pdc_finanziario_III,
        v_descrizione_pdc_finanziario_III,
        v_codice_pdc_finanziario_IV,
        v_descrizione_pdc_finanziario_IV,
        v_codice_pdc_finanziario_V,
        v_descrizione_pdc_finanziario_V,
        v_codice_cofog_divisione,
        v_descrizione_cofog_divisione,
        v_codice_cofog_gruppo,
        v_descrizione_cofog_gruppo,
        v_codice_cdr,
        v_descrizione_cdr,
        v_codice_cdc,
        v_descrizione_cdc,
        v_codice_siope_I_entrata,
        v_descrizione_siope_I_entrata,
        v_codice_siope_II_entrata,
        v_descrizione_siope_II_entrata,
        v_codice_siope_III_entrata,
        v_descrizione_siope_III_entrata,
        v_codice_entrata_ricorrente,
        v_descrizione_entrata_ricorrente,
        v_codice_transazione_entrata_ue,
        v_descrizione_transazione_entrata_ue,
        v_codice_tipo_fondo,
        v_descrizione_tipo_fondo,
        v_codice_tipo_finanziamento,
        v_descrizione_tipo_finanziamento,
        v_codice_perimetro_sanitario_entrata,
        v_descrizione_perimetro_sanitario_entrata,
        v_classificatore_generico_1,
        v_classificatore_generico_1_valore,
        v_classificatore_generico_1_descrizione_valore,
        v_classificatore_generico_2,
        v_classificatore_generico_2_valore,
        v_classificatore_generico_2_descrizione_valore,
        v_classificatore_generico_3,
        v_classificatore_generico_3_valore,
        v_classificatore_generico_3_descrizione_valore,
        v_classificatore_generico_4,
        v_classificatore_generico_4_valore,
        v_classificatore_generico_4_descrizione_valore,
        v_classificatore_generico_5,
        v_classificatore_generico_5_valore,
        v_classificatore_generico_5_descrizione_valore,
        v_classificatore_generico_6,
        v_classificatore_generico_6_valore,
        v_classificatore_generico_6_descrizione_valore,
        v_classificatore_generico_7,
        v_classificatore_generico_7_valore,
        v_classificatore_generico_7_descrizione_valore,
        v_classificatore_generico_8,
        v_classificatore_generico_8_valore,
        v_classificatore_generico_8_descrizione_valore,
        v_classificatore_generico_9,
        v_classificatore_generico_9_valore,
        v_classificatore_generico_9_descrizione_valore,
        v_classificatore_generico_10,
        v_classificatore_generico_10_valore,
        v_classificatore_generico_10_descrizione_valore,
        v_classificatore_generico_11,
        v_classificatore_generico_11_valore,
        v_classificatore_generico_11_descrizione_valore,
        v_classificatore_generico_12,
        v_classificatore_generico_12_valore,
        v_classificatore_generico_12_descrizione_valore,
        v_classificatore_generico_13,
        v_classificatore_generico_13_valore,
        v_classificatore_generico_13_descrizione_valore,
        v_classificatore_generico_14,
        v_classificatore_generico_14_valore,
        v_classificatore_generico_14_descrizione_valore,
        v_classificatore_generico_15,
        v_classificatore_generico_15_valore,
        v_classificatore_generico_15_descrizione_valore,
        v_FlagEntrateRicorrenti,
        v_FlagImpegnabile,
        v_FlagPerMemoria,
        v_FlagRilevanteIva,
        v_FlagTrasferimentoOrganiComunitari,
        v_Note,
        v_codice_stipendio,
        v_descrizione_stipendio,
        v_codice_attivita_iva,
        v_descrizione_attivita_iva,
        v_massimo_impegnabile_anno1,
        v_stanziamento_cassa_anno1,
        v_stanziamento_cassa_iniziale_anno1,
        v_stanziamento_residuo_iniziale_anno1,
        v_stanziamento_anno1,
        v_stanziamento_iniziale_anno1,
        v_stanziamento_residuo_anno1,
        v_flag_anno1,
        v_massimo_impegnabile_anno2,
        v_stanziamento_cassa_anno2,
        v_stanziamento_cassa_iniziale_anno2,
        v_stanziamento_residuo_iniziale_anno2,
        v_stanziamento_anno2,
        v_stanziamento_iniziale_anno2,
        v_stanziamento_residuo_anno2,
        v_flag_anno2,
        v_massimo_impegnabile_anno3,
        v_stanziamento_cassa_anno3,
        v_stanziamento_cassa_iniziale_anno3,
        v_stanziamento_residuo_iniziale_anno3,
        v_stanziamento_anno3,
        v_stanziamento_iniziale_anno3,
        v_stanziamento_residuo_anno3,
        v_flag_anno3,
        v_disponibilita_accertare_anno1,
        v_disponibilita_accertare_anno2,
        v_disponibilita_accertare_anno3,
        v_FlagAccertatoPerCassa
        --SIAC-5895
        ,v_ex_anno
        ,v_ex_capitolo
        ,v_ex_articolo
       );
esito:= '  Fine ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
END LOOP;
esito:= 'Fine funzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico capitoli di entrata (FNC_SIAC_DWH_CAPITOLO_ENTRATA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$function$
;


CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_capitolo_spesa(p_anno_bilancio character varying, p_ente_proprietario_id integer, p_data timestamp without time zone)
 RETURNS TABLE(esito character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE

  rec_elem_id record;
  rec_classif_id record;
  rec_attr record;
  rec_elem_dett record;
  -- Variabili per campi estratti dal cursore rec_elem_id
  v_ente_proprietario_id INTEGER := null;
  v_ente_denominazione VARCHAR := null;
  v_anno VARCHAR := null;
  v_fase_operativa_code VARCHAR := null;
  v_fase_operativa_desc VARCHAR := null;
  v_elem_code VARCHAR := null;
  v_elem_code2 VARCHAR := null;
  v_elem_code3 VARCHAR := null;
  v_elem_desc VARCHAR := null;
  v_elem_desc2 VARCHAR := null;
  v_elem_tipo_code VARCHAR := null;
  v_elem_tipo_desc VARCHAR := null;
  v_elem_stato_code VARCHAR := null;
  v_elem_stato_desc VARCHAR := null;
  v_elem_cat_code VARCHAR := null;
  v_elem_cat_desc VARCHAR := null;
  -- Variabili per classificatori in gerarchia
  v_codice_titolo_spesa VARCHAR;
  v_descrizione_titolo_spesa VARCHAR;
  v_codice_macroaggregato_spesa VARCHAR;
  v_descrizione_macroaggregato_spesa VARCHAR;
  v_codice_missione_spesa VARCHAR;
  v_descrizione_missione_spesa VARCHAR;
  v_codice_programma_spesa VARCHAR;
  v_descrizione_programma_spesa VARCHAR;
  v_codice_pdc_finanziario_I VARCHAR := null;
  v_descrizione_pdc_finanziario_I VARCHAR := null;
  v_codice_pdc_finanziario_II VARCHAR := null;
  v_descrizione_pdc_finanziario_II VARCHAR := null;
  v_codice_pdc_finanziario_III VARCHAR := null;
  v_descrizione_pdc_finanziario_III VARCHAR := null;
  v_codice_pdc_finanziario_IV VARCHAR := null;
  v_descrizione_pdc_finanziario_IV VARCHAR := null;
  v_codice_pdc_finanziario_V VARCHAR := null;
  v_descrizione_pdc_finanziario_V VARCHAR := null;
  v_codice_cofog_divisione VARCHAR := null;
  v_descrizione_cofog_divisione VARCHAR := null;
  v_codice_cofog_gruppo VARCHAR := null;
  v_descrizione_cofog_gruppo VARCHAR := null;
  v_codice_cdr VARCHAR := null;
  v_descrizione_cdr VARCHAR := null;
  v_codice_cdc VARCHAR := null;
  v_descrizione_cdc VARCHAR := null;
  v_codice_siope_I_spesa VARCHAR := null;
  v_descrizione_siope_I_spesa VARCHAR := null;
  v_codice_siope_II_spesa VARCHAR := null;
  v_descrizione_siope_II_spesa VARCHAR := null;
  v_codice_siope_III_spesa VARCHAR := null;
  v_descrizione_siope_III_spesa VARCHAR := null;
  -- Variabili per classificatori non in gerarchia
  v_codice_spesa_ricorrente VARCHAR := null;
  v_descrizione_spesa_ricorrente VARCHAR := null;
  v_codice_transazione_spesa_ue VARCHAR := null;
  v_descrizione_transazione_spesa_ue VARCHAR := null;
  v_codice_tipo_fondo VARCHAR := null;
  v_descrizione_tipo_fondo VARCHAR := null;
  v_codice_tipo_finanziamento VARCHAR := null;
  v_descrizione_tipo_finanziamento VARCHAR := null;
  v_codice_politiche_regionali_unitarie VARCHAR := null;
  v_descrizione_politiche_regionali_unitarie VARCHAR := null;
  v_codice_perimetro_sanitario_spesa VARCHAR := null;
  v_descrizione_perimetro_sanitario_spesa VARCHAR := null;
  v_classificatore_generico_1 VARCHAR := null;
  v_classificatore_generico_1_descrizione_valore VARCHAR := null;
  v_classificatore_generico_1_valore VARCHAR := null;
  v_classificatore_generico_2 VARCHAR := null;
  v_classificatore_generico_2_descrizione_valore VARCHAR := null;
  v_classificatore_generico_2_valore VARCHAR := null;
  v_classificatore_generico_3 VARCHAR := null;
  v_classificatore_generico_3_descrizione_valore VARCHAR := null;
  v_classificatore_generico_3_valore VARCHAR := null;
  v_classificatore_generico_4 VARCHAR := null;
  v_classificatore_generico_4_descrizione_valore VARCHAR := null;
  v_classificatore_generico_4_valore VARCHAR := null;
  v_classificatore_generico_5 VARCHAR := null;
  v_classificatore_generico_5_descrizione_valore VARCHAR := null;
  v_classificatore_generico_5_valore VARCHAR := null;
  v_classificatore_generico_6 VARCHAR := null;
  v_classificatore_generico_6_descrizione_valore VARCHAR := null;
  v_classificatore_generico_6_valore VARCHAR := null;
  v_classificatore_generico_7 VARCHAR := null;
  v_classificatore_generico_7_descrizione_valore VARCHAR := null;
  v_classificatore_generico_7_valore VARCHAR := null;
  v_classificatore_generico_8 VARCHAR := null;
  v_classificatore_generico_8_descrizione_valore VARCHAR := null;
  v_classificatore_generico_8_valore VARCHAR := null;
  v_classificatore_generico_9 VARCHAR := null;
  v_classificatore_generico_9_descrizione_valore VARCHAR := null;
  v_classificatore_generico_9_valore VARCHAR := null;
  v_classificatore_generico_10 VARCHAR := null;
  v_classificatore_generico_10_descrizione_valore VARCHAR := null;
  v_classificatore_generico_10_valore VARCHAR := null;
  v_classificatore_generico_11 VARCHAR := null;
  v_classificatore_generico_11_descrizione_valore VARCHAR := null;
  v_classificatore_generico_11_valore VARCHAR := null;
  v_classificatore_generico_12 VARCHAR := null;
  v_classificatore_generico_12_descrizione_valore VARCHAR := null;
  v_classificatore_generico_12_valore VARCHAR := null;
  v_classificatore_generico_13 VARCHAR := null;
  v_classificatore_generico_13_descrizione_valore VARCHAR := null;
  v_classificatore_generico_13_valore VARCHAR:= null;
  v_classificatore_generico_14 VARCHAR := null;
  v_classificatore_generico_14_descrizione_valore VARCHAR := null;
  v_classificatore_generico_14_valore VARCHAR := null;
  v_classificatore_generico_15 VARCHAR := null;
  v_classificatore_generico_15_descrizione_valore VARCHAR := null;
  v_classificatore_generico_15_valore VARCHAR := null;
  v_codice_risorse_accantonamento VARCHAR     := null;
  v_descrizione_risorse_accantonamento VARCHAR := null;
  -- Variabili per attributi
  v_FlagEntrateRicorrenti VARCHAR := null;
  v_FlagFunzioniDelegate VARCHAR := null;
  v_FlagImpegnabile VARCHAR := null;
  v_FlagPerMemoria VARCHAR := null;
  v_FlagRilevanteIva VARCHAR := null;
  v_FlagTrasferimentoOrganiComunitari VARCHAR := null;
  v_Note VARCHAR := null;
  -- Variabili per stipendio
  v_codice_stipendio VARCHAR := null;
  v_descrizione_stipendio VARCHAR := null;
  -- Variabili per attivita' iva
  v_codice_attivita_iva VARCHAR := null;
  v_descrizione_attivita_iva VARCHAR := null;
  -- Variabili per i campi di detaglio degli elementi
  v_massimo_impegnabile_anno1 NUMERIC := null;
  v_stanziamento_cassa_anno1 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno1  NUMERIC := null;
  v_stanziamento_anno1 NUMERIC := null;
  v_stanziamento_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_anno1  NUMERIC := null;
  v_flag_anno1 VARCHAR := null;
  v_massimo_impegnabile_anno2 NUMERIC := null;
  v_stanziamento_cassa_anno2 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno2 NUMERIC := null;
  v_stanziamento_anno2 NUMERIC := null;
  v_stanziamento_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_anno2 NUMERIC := null;
  v_flag_anno2 VARCHAR := null;
  v_massimo_impegnabile_anno3 NUMERIC := null;
  v_stanziamento_cassa_anno3 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno3 NUMERIC := null;
  v_stanziamento_anno3 NUMERIC := null;
  v_stanziamento_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_anno3 NUMERIC := null;
  v_flag_anno3 VARCHAR := null;
  -- Variabili per campi funzione
  v_disponibilita_impegnare_anno1 NUMERIC := null;
  v_disponibilita_impegnare_anno2 NUMERIC := null;
  v_disponibilita_impegnare_anno3 NUMERIC := null;
  -- Variabili utili per il caricamento
  v_classif_code VARCHAR := null;
  v_classif_desc VARCHAR := null;
  v_classif_tipo_code VARCHAR := null;
  v_classif_tipo_desc VARCHAR := null;
  v_elem_id INTEGER := null;
  v_classif_id INTEGER := null;
  v_classif_id_part INTEGER := null;
  v_classif_id_padre INTEGER := null;
  v_classif_tipo_id INTEGER := null;
  v_classif_fam_id INTEGER := null;
  v_conta_ciclo_classif INTEGER := null;
  v_anno_elem_dett INTEGER := null;
  v_anno_appo INTEGER := null;
  v_flag_attributo VARCHAR := null;
  v_bil_id INTEGER := null;

  v_fnc_result VARCHAR := null;
  --SIAC-5895
  v_bil_id_prec INTEGER:=null;
  v_anno_prec INTEGER:=null;
  v_elem_tipo_id INTEGER:=null;
  v_ex_anno VARCHAR:=null;
  v_ex_capitolo VARCHAR:= null;
  v_ex_articolo VARCHAR:=null;

v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

select fnc_siac_random_user()
into	v_user_table;

IF p_data IS NULL THEN
   p_data := now();
END IF;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_capitolo_spesa',
params,
clock_timestamp(),
v_user_table
);

select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) - '||clock_timestamp();
RETURN NEXT;

-- SIAC-5895
esito:= '  Inizio Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;
select tb.bil_id,tp.anno
into v_bil_id_prec, v_anno_prec
from siac.siac_t_periodo tp
INNER JOIN siac.siac_t_bil tb  ON tb.periodo_id = tp.periodo_id
where tp.ente_proprietario_id = p_ente_proprietario_id
and   tp.anno::integer = p_anno_bilancio::integer-1;
esito:= '  Fine Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;

-- SIAC-6007
esito:= '  Inizio Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;
select elem_tipo_id
into v_elem_tipo_id
from siac_d_bil_elem_tipo
where elem_tipo_code = 'CAP-UG'
and   ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;


esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_capitolo_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id
AND bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre gli elementi
FOR rec_elem_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, dbet.elem_tipo_code, dbet.elem_tipo_desc,
       dbes.elem_stato_code, dbes.elem_stato_desc, dbec.elem_cat_code, dbec.elem_cat_desc,
       tbe.elem_id, tb.bil_id
       --, tbe.elem_tipo_id COMMENTATO PER SIAC-6007
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tb.periodo_id = tp.periodo_id
INNER JOIN siac.siac_t_ente_proprietario tep ON tb.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
LEFT JOIN  siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
                                               AND p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
                                               AND rbec.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
                                              AND p_data BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, p_data)
                                              AND dbec.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND dbet.elem_tipo_code in ('CAP-UG', 'CAP-UP')
AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
AND tbe.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, p_data)
AND dbet.data_cancellazione IS NULL
AND p_data BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, p_data)
AND rbes.data_cancellazione IS NULL
AND p_data BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, p_data)
AND dbes.data_cancellazione IS NULL

LOOP
v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_elem_code := null;
v_elem_code2 := null;
v_elem_code3 := null;
v_elem_desc := null;
v_elem_desc2 := null;
v_elem_tipo_code := null;
v_elem_tipo_desc := null;
v_elem_stato_code := null;
v_elem_stato_desc := null;
v_elem_cat_code := null;
v_elem_cat_desc := null;

v_elem_id := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_bil_id := null;

v_ente_proprietario_id := rec_elem_id.ente_proprietario_id;
v_ente_denominazione := rec_elem_id.ente_denominazione;
v_anno := rec_elem_id.anno;
v_elem_code := rec_elem_id.elem_code;
v_elem_code2 := rec_elem_id.elem_code2;
v_elem_code3 := rec_elem_id.elem_code3;

-- 14.02.2020 Sofia jira SIAC-7329
 --v_elem_desc := rec_elem_id.elem_desc;
v_elem_desc := translate( rec_elem_id.elem_desc,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);

/* sostuito con translate
  v_elem_desc := replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
     replace(
      replace(
       replace(
         replace(rec_elem_id.elem_desc::text,chr(1),' '),
          chr(2),' '),
          chr(3),' '),
          chr(4),' '),
          chr(5),' '),
          chr(6),' '),
          chr(6),' '),
          chr(7),' '),
          chr(8),' '),
          chr(9),' '),
          chr(10),' '),
          chr(11),' '),
          chr(12),' '),
          chr(13),' '),
          chr(14),' '),
          chr(15),' '),
          chr(16),' '),
          chr(17),' '),
          chr(18),' '),
          chr(19),' '),
          chr(20),' '),
          chr(21),' '),
          chr(22),' '),
          chr(23),' '),
          chr(24),' '),
          chr(25),' '),
          chr(26),' '),
          chr(27),' '),
          chr(28),' '),
          chr(29),' '),
          chr(30),' '),
          chr(31),' '),
          chr(126),' '),
          chr(127),' ');*/

-- 14.02.2020 Sofia jira SIAC-7329
--v_elem_desc2 := rec_elem_id.elem_desc2;

v_elem_desc2 :=
translate( rec_elem_id.elem_desc2,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);

/* sostituito con translate
 v_elem_desc2 := replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
     replace(
      replace(
       replace(
         replace(rec_elem_id.elem_desc2::text,chr(1),' '),
          chr(2),' '),
          chr(3),' '),
          chr(4),' '),
          chr(5),' '),
          chr(6),' '),
          chr(6),' '),
          chr(7),' '),
          chr(8),' '),
          chr(9),' '),
          chr(10),' '),
          chr(11),' '),
          chr(12),' '),
          chr(13),' '),
          chr(14),' '),
          chr(15),' '),
          chr(16),' '),
          chr(17),' '),
          chr(18),' '),
          chr(19),' '),
          chr(20),' '),
          chr(21),' '),
          chr(22),' '),
          chr(23),' '),
          chr(24),' '),
          chr(25),' '),
          chr(26),' '),
          chr(27),' '),
          chr(28),' '),
          chr(29),' '),
          chr(30),' '),
          chr(31),' '),
          chr(126),' '),
          chr(127),' ');*/

v_elem_tipo_code := rec_elem_id.elem_tipo_code;
v_elem_tipo_desc := rec_elem_id.elem_tipo_desc;
v_elem_stato_code := rec_elem_id.elem_stato_code;
v_elem_stato_desc := rec_elem_id.elem_stato_desc;
v_elem_cat_code := rec_elem_id.elem_cat_code;
v_elem_cat_desc := rec_elem_id.elem_cat_desc;

v_elem_id := rec_elem_id.elem_id;
v_anno_appo := rec_elem_id.anno::integer;
v_bil_id := rec_elem_id.bil_id;

-- Sezione per estrarre i classificatori
v_codice_titolo_spesa := null;
v_descrizione_titolo_spesa := null;
v_codice_macroaggregato_spesa := null;
v_descrizione_macroaggregato_spesa := null;
v_codice_missione_spesa := null;
v_descrizione_missione_spesa := null;
v_codice_programma_spesa := null;
v_descrizione_programma_spesa := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_cofog_divisione := null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;
v_codice_cdr := null;
v_descrizione_cdr := null;
v_codice_cdc := null;
v_descrizione_cdc := null;
v_codice_siope_I_spesa := null;
v_descrizione_siope_I_spesa := null;
v_codice_siope_II_spesa:= null;
v_descrizione_siope_II_spesa := null;
v_codice_siope_III_spesa := null;
v_descrizione_siope_III_spesa := null;

v_codice_spesa_ricorrente := null;
v_descrizione_spesa_ricorrente := null;
v_codice_transazione_spesa_ue := null;
v_descrizione_transazione_spesa_ue := null;
v_codice_tipo_fondo := null;
v_descrizione_tipo_fondo := null;
v_codice_tipo_finanziamento := null;
v_descrizione_tipo_finanziamento := null;
v_codice_politiche_regionali_unitarie := null;
v_descrizione_politiche_regionali_unitarie := null;
v_codice_perimetro_sanitario_spesa := null;
v_descrizione_perimetro_sanitario_spesa := null;
v_classificatore_generico_1:= null;
v_classificatore_generico_1_descrizione_valore:= null;
v_classificatore_generico_1_valore:= null;
v_classificatore_generico_2:= null;
v_classificatore_generico_2_descrizione_valore:= null;
v_classificatore_generico_2_valore:= null;
v_classificatore_generico_3:= null;
v_classificatore_generico_3_descrizione_valore:= null;
v_classificatore_generico_3_valore:= null;
v_classificatore_generico_4:= null;
v_classificatore_generico_4_descrizione_valore:= null;
v_classificatore_generico_4_valore:= null;
v_classificatore_generico_5:= null;
v_classificatore_generico_5_descrizione_valore:= null;
v_classificatore_generico_5_valore:= null;
v_classificatore_generico_6:= null;
v_classificatore_generico_6_descrizione_valore:= null;
v_classificatore_generico_6_valore:= null;
v_classificatore_generico_7:= null;
v_classificatore_generico_7_descrizione_valore:= null;
v_classificatore_generico_7_valore:= null;
v_classificatore_generico_8:= null;
v_classificatore_generico_8_descrizione_valore:= null;
v_classificatore_generico_8_valore:= null;
v_classificatore_generico_9:= null;
v_classificatore_generico_9_descrizione_valore:= null;
v_classificatore_generico_9_valore:= null;
v_classificatore_generico_10:= null;
v_classificatore_generico_10_descrizione_valore:= null;
v_classificatore_generico_10_valore:= null;
v_classificatore_generico_11:= null;
v_classificatore_generico_11_descrizione_valore:= null;
v_classificatore_generico_11_valore:= null;
v_classificatore_generico_12:= null;
v_classificatore_generico_12_descrizione_valore:= null;
v_classificatore_generico_12_valore:= null;
v_classificatore_generico_13:= null;
v_classificatore_generico_13_descrizione_valore:= null;
v_classificatore_generico_13_valore:= null;
v_classificatore_generico_14:= null;
v_classificatore_generico_14_descrizione_valore:= null;
v_classificatore_generico_14_valore:= null;
v_classificatore_generico_15:= null;
v_classificatore_generico_15_descrizione_valore:= null;
v_classificatore_generico_15_valore:= null;
v_codice_risorse_accantonamento      := null;
v_descrizione_risorse_accantonamento := null;
--SIAC-5895
--v_elem_tipo_id := rec_elem_id.elem_tipo_id; COMMENTATO PER SIAC-6007
v_ex_anno :=null;
v_ex_capitolo := null;
v_ex_articolo :=null;
esito:= '  Inizio ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
-- Sezione per estrarre la fase operativa
SELECT dfo.fase_operativa_code, dfo.fase_operativa_desc
INTO v_fase_operativa_code, v_fase_operativa_desc
FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
WHERE dfo.fase_operativa_id = rbfo.fase_operativa_id
AND   rbfo.bil_id = v_bil_id
AND   p_data BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, p_data)
AND   p_data BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, p_data)
AND   rbfo.data_cancellazione IS NULL
AND   dfo.data_cancellazione IS NULL;
-- Ciclo per estrarre i classificatori relativi ad un dato elemento
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
FROM siac.siac_r_bil_elem_class rbec, siac.siac_t_class tc
WHERE tc.classif_id = rbec.classif_id
AND   rbec.elem_id = v_elem_id
AND   rbec.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

LOOP

v_classif_id :=  rec_classif_id.classif_id;
v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
v_classif_fam_id := null;

-- Estrazione per determinare se un classificatore e' in gerarchia
SELECT rcfct.classif_fam_id
INTO v_classif_fam_id
FROM siac.siac_r_class_fam_class_tipo rcfct
WHERE rcfct.classif_tipo_id = v_classif_tipo_id
AND   rcfct.data_cancellazione IS NULL
AND   p_data BETWEEN rcfct.validita_inizio AND COALESCE(rcfct.validita_fine, p_data);

-- Se il classificatore non e' in gerarchia
IF NOT FOUND THEN
  esito:= '    Inizio step classificatori non in gerarchia - '||clock_timestamp();
  return next;
  v_classif_tipo_code := null;
  v_classif_code := rec_classif_id.classif_code;
  v_classif_desc := rec_classif_id.classif_desc;

  SELECT dct.classif_tipo_code , dct.classif_tipo_desc
  INTO   v_classif_tipo_code, v_classif_tipo_desc
  FROM   siac.siac_d_class_tipo dct
  WHERE  dct.classif_tipo_id = v_classif_tipo_id
  AND    dct.data_cancellazione IS NULL
  AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'RICORRENTE_SPESA' THEN
     v_codice_spesa_ricorrente      := v_classif_code;
     v_descrizione_spesa_ricorrente := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TRANSAZIONE_UE_SPESA' THEN
     v_codice_transazione_spesa_ue      := v_classif_code;
     v_descrizione_transazione_spesa_ue := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FONDO' THEN
     v_codice_tipo_fondo      := v_classif_code;
     v_descrizione_tipo_fondo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FINANZIAMENTO' THEN
     v_codice_tipo_finanziamento      := v_classif_code;
     v_descrizione_tipo_finanziamento := v_classif_desc;
  ELSIF v_classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE' THEN
     v_codice_politiche_regionali_unitarie      := v_classif_code;
     v_descrizione_politiche_regionali_unitarie := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA' THEN
     v_codice_perimetro_sanitario_spesa      := v_classif_code;
     v_descrizione_perimetro_sanitario_spesa := v_classif_desc;
 /* ELSIF v_classif_tipo_code = 'RISACC' THEN
     v_codice_risorse_accantonamento      := v_classif_code;
     v_descrizione_risorse_accantonamento := v_classif_desc;*/
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_1' THEN
     v_classificatore_generico_1      :=  v_classif_tipo_desc;
     v_classificatore_generico_1_descrizione_valore := v_classif_desc;
     v_classificatore_generico_1_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_2' THEN
     v_classificatore_generico_2      := v_classif_tipo_desc;
     v_classificatore_generico_2_descrizione_valore := v_classif_desc;
     v_classificatore_generico_2_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_3' THEN
     v_classificatore_generico_3      := v_classif_tipo_desc;
     v_classificatore_generico_3_descrizione_valore := v_classif_desc;
     v_classificatore_generico_3_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_4' THEN
     v_classificatore_generico_4      := v_classif_tipo_desc;
     v_classificatore_generico_4_descrizione_valore := v_classif_desc;
     v_classificatore_generico_4_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_5' THEN
     v_classificatore_generico_5    := v_classif_tipo_desc;
     v_classificatore_generico_5_descrizione_valore := v_classif_desc;
     v_classificatore_generico_5_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_6' THEN
     v_classificatore_generico_6      := v_classif_tipo_desc;
     v_classificatore_generico_6_descrizione_valore := v_classif_desc;
     v_classificatore_generico_6_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_7' THEN
     v_classificatore_generico_7      := v_classif_tipo_desc;
     v_classificatore_generico_7_descrizione_valore := v_classif_desc;
     v_classificatore_generico_7_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_8' THEN
     v_classificatore_generico_8      := v_classif_tipo_desc;
     v_classificatore_generico_8_descrizione_valore := v_classif_desc;
     v_classificatore_generico_8_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_9' THEN
     v_classificatore_generico_9      := v_classif_tipo_desc;
     v_classificatore_generico_9_descrizione_valore := v_classif_desc;
     v_classificatore_generico_9_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_10' THEN
     v_classificatore_generico_10     := v_classif_tipo_desc;
     v_classificatore_generico_10_descrizione_valore := v_classif_desc;
     v_classificatore_generico_10_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_31' THEN
     v_classificatore_generico_11    := v_classif_tipo_desc;
     v_classificatore_generico_11_descrizione_valore := v_classif_desc;
     v_classificatore_generico_11_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_32' THEN
     v_classificatore_generico_12     := v_classif_tipo_desc;
     v_classificatore_generico_12_descrizione_valore := v_classif_desc;
     v_classificatore_generico_12_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_33' THEN
     v_classificatore_generico_13      := v_classif_tipo_desc;
     v_classificatore_generico_13_descrizione_valore := v_classif_desc;
     v_classificatore_generico_13_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_34' THEN
     v_classificatore_generico_14      := v_classif_tipo_desc;
     v_classificatore_generico_14_descrizione_valore := v_classif_desc;
     v_classificatore_generico_14_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_35' THEN
     v_classificatore_generico_15      := v_classif_tipo_desc;
     v_classificatore_generico_15_descrizione_valore := v_classif_desc;
     v_classificatore_generico_15_valore      := v_classif_code;
  END IF;
  esito:= '    Fine step classificatori non in gerarchia - '||clock_timestamp();
  return next;
-- Se il classificatoree' in gerarchia
ELSE
 esito:= '    Inizio step classificatori in gerarchia - '||clock_timestamp();
 return next;
 v_conta_ciclo_classif :=0;
 v_classif_id_padre := null;

 -- Loop per RISALIRE la gerarchia di un dato classificatore
 LOOP

  v_classif_code := null;
  v_classif_desc := null;
  v_classif_id_part := null;
  v_classif_tipo_code := null;
  v_classif_tipo_desc:=null;

  IF v_conta_ciclo_classif = 0 THEN
     v_classif_id_part := v_classif_id;
  ELSE
     v_classif_id_part := v_classif_id_padre;
  END IF;

  SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code, dct.classif_tipo_desc
  INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code, v_classif_tipo_desc
  FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
  WHERE rcft.classif_id = tc.classif_id
  AND   dct.classif_tipo_id = tc.classif_tipo_id
  AND   tc.classif_id = v_classif_id_part
  AND   rcft.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   dct.data_cancellazione IS NULL
  AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
  AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF    v_classif_tipo_code = 'TITOLO_SPESA' THEN
        v_codice_titolo_spesa := v_classif_code;
        v_descrizione_titolo_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'MACROAGGREGATO' THEN
        v_codice_macroaggregato_spesa := v_classif_code;
        v_descrizione_macroaggregato_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'MISSIONE' THEN
        v_codice_missione_spesa := v_classif_code;
        v_descrizione_missione_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PROGRAMMA' THEN
        v_codice_programma_spesa := v_classif_code;
        v_descrizione_programma_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_I' THEN
        v_codice_pdc_finanziario_I := v_classif_code;
        v_descrizione_pdc_finanziario_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_II' THEN
        v_codice_pdc_finanziario_II := v_classif_code;
        v_descrizione_pdc_finanziario_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_III' THEN
        v_codice_pdc_finanziario_III := v_classif_code;
        v_descrizione_pdc_finanziario_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_IV' THEN
        v_codice_pdc_finanziario_IV := v_classif_code;
        v_descrizione_pdc_finanziario_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_V' THEN
        v_codice_pdc_finanziario_V := v_classif_code;
        v_descrizione_pdc_finanziario_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDR' THEN
        v_codice_cdr := v_classif_code;
        v_descrizione_cdr := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDC' THEN
        v_codice_cdc := v_classif_code;
        v_descrizione_cdc := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_I' THEN
        v_codice_siope_I_spesa := v_classif_code;
        v_descrizione_siope_I_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_II' THEN
        v_codice_siope_II_spesa := v_classif_code;
        v_descrizione_siope_II_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_III' THEN
        v_codice_siope_III_spesa := v_classif_code;
        v_descrizione_siope_III_spesa := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
 esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
 return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
 esito:= '    Inizio step attributi - '||clock_timestamp();
 return next;
v_FlagEntrateRicorrenti := null;
v_FlagFunzioniDelegate := null;
v_FlagImpegnabile := null;
v_FlagPerMemoria := null;
v_FlagRilevanteIva := null;
v_FlagTrasferimentoOrganiComunitari := null;
v_Note := null;
v_flag_attributo := null;

FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rbea.tabella_id, rbea.percentuale, rbea."boolean" true_false, rbea.numerico, rbea.testo
FROM   siac.siac_r_bil_elem_attr rbea, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rbea.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rbea.elem_id = v_elem_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rbea.validita_inizio AND COALESCE(rbea.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'FlagEntrateRicorrenti' THEN
     v_FlagEntrateRicorrenti := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagFunzioniDelegate' THEN
     v_FlagFunzioniDelegate := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagImpegnabile' THEN
     v_FlagImpegnabile := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagPerMemoria' THEN
     v_FlagPerMemoria := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagRilevanteIva' THEN
     v_FlagRilevanteIva := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagTrasferimentoOrganiComunitari' THEN
     v_FlagTrasferimentoOrganiComunitari := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Note' THEN
     v_Note := v_flag_attributo;
  END IF;

END LOOP;
esito:= '    Fine step attributi - '||clock_timestamp();
return next;
esito:= '    Inizio step stipendi - '||clock_timestamp();
return next;
-- Sezione per i dati di stipendio
v_codice_stipendio := null;
v_descrizione_stipendio := null;

SELECT dsc.stipcode_code, dsc.stipcode_desc
INTO v_codice_stipendio, v_descrizione_stipendio
FROM  siac.siac_r_bil_elem_stipendio_codice rbesc, siac.siac_d_stipendio_codice dsc
WHERE rbesc.stipcode_id = dsc.stipcode_id
AND   rbesc.elem_id = v_elem_id
AND   rbesc.data_cancellazione IS NULL
AND   dsc.data_cancellazione IS NULL
AND   p_data between rbesc.validita_inizio and coalesce(rbesc.validita_fine, p_data)
AND   p_data between dsc.validita_inizio and coalesce(dsc.validita_fine, p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step iva - '||clock_timestamp();
return next;
-- Sezione per i dati di iva
v_codice_attivita_iva := null;
v_descrizione_attivita_iva := null;

SELECT tia.ivaatt_code, tia.ivaatt_desc
INTO v_codice_attivita_iva, v_descrizione_attivita_iva
FROM siac.siac_r_bil_elem_iva_attivita rbeia, siac.siac_t_iva_attivita tia
WHERE rbeia.ivaatt_id = tia.ivaatt_id
AND   rbeia.elem_id = v_elem_id
AND   rbeia.data_cancellazione IS NULL
AND   tia.data_cancellazione IS NULL
AND   p_data between rbeia.validita_inizio and coalesce(rbeia.validita_fine,p_data)
AND   p_data between tia.validita_inizio and coalesce(tia.validita_fine,p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step dettagli elementi - '||clock_timestamp();
return next;
-- Sezione per i dati di dettaglio degli elementi
v_massimo_impegnabile_anno1 := null;
v_stanziamento_cassa_anno1 := null;
v_stanziamento_cassa_iniziale_anno1 := null;
v_stanziamento_residuo_iniziale_anno1 := null;
v_stanziamento_anno1 := null;
v_stanziamento_iniziale_anno1 := null;
v_stanziamento_residuo_anno1 := null;
v_flag_anno1 := null;
v_massimo_impegnabile_anno2 := null;
v_stanziamento_cassa_anno2 := null;
v_stanziamento_cassa_iniziale_anno2 := null;
v_stanziamento_residuo_iniziale_anno2 := null;
v_stanziamento_anno2 := null;
v_stanziamento_iniziale_anno2 := null;
v_stanziamento_residuo_anno2 := null;
v_flag_anno2 := null;
v_massimo_impegnabile_anno3 := null;
v_stanziamento_cassa_anno3 := null;
v_stanziamento_cassa_iniziale_anno3 := null;
v_stanziamento_residuo_iniziale_anno3 := null;
v_stanziamento_anno3 := null;
v_stanziamento_iniziale_anno3 := null;
v_stanziamento_residuo_anno3 := null;
v_flag_anno3 := null;

v_anno_elem_dett := null;

FOR rec_elem_dett IN
SELECT dbedt.elem_det_tipo_code, tbed.elem_det_flag, tbed.elem_det_importo, tp.anno
FROM  siac.siac_t_bil_elem_det tbed, siac.siac_d_bil_elem_det_tipo dbedt, siac.siac_t_periodo tp
WHERE tbed.elem_det_tipo_id = dbedt.elem_det_tipo_id
AND   tbed.periodo_id = tp.periodo_id
AND   tbed.elem_id = v_elem_id
AND   tbed.data_cancellazione IS NULL
AND   dbedt.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   p_data between tbed.validita_inizio and coalesce(tbed.validita_fine,p_data)
AND   p_data between dbedt.validita_inizio and coalesce(dbedt.validita_fine,p_data)
AND   p_data between tp.validita_inizio and coalesce(tp.validita_fine,p_data)

LOOP
v_anno_elem_dett := rec_elem_dett.anno::integer;
  IF v_anno_elem_dett = v_anno_appo THEN
    v_flag_anno1 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno1 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 1) THEN
    v_flag_anno2 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno2 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 2) THEN
    v_flag_anno3 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno3 := rec_elem_dett.elem_det_importo;
    END IF;
  END IF;
END LOOP;
esito:= '    Fine step dettagli elementi - '||clock_timestamp();
return next;
esito:= '    Inizio step dati da funzione - '||clock_timestamp();
return next;
-- Sezione per valorizzazione delle variabili per i campi di funzione
v_disponibilita_impegnare_anno1 := null;
v_disponibilita_impegnare_anno2 := null;
v_disponibilita_impegnare_anno3 := null;

IF v_elem_tipo_code = 'CAP-UG' THEN
   v_disponibilita_impegnare_anno1 := siac.fnc_siac_disponibilitaimpegnareug_anno1(v_elem_id);
   v_disponibilita_impegnare_anno2 := siac.fnc_siac_disponibilitaimpegnareug_anno2(v_elem_id);
   v_disponibilita_impegnare_anno3 := siac.fnc_siac_disponibilitaimpegnareug_anno3(v_elem_id);
END IF;
esito:= '    Fine step dati da funzione - '||clock_timestamp();
return next;

-- SIAC-5895
esito:= '    Inizio step dati ex capitolo - '||clock_timestamp();
return next;

select per.anno,elem.elem_code,elem.elem_code2
into v_ex_anno, v_ex_capitolo, v_ex_articolo
from siac_r_bil_elem_rel_tempo r_ex
, siac_t_bil_elem elem
, siac_t_bil bil
, siac_t_periodo per
where r_ex.elem_id = v_elem_id
and   r_ex.data_cancellazione is null
and   p_data between r_ex.validita_inizio and coalesce(r_ex.validita_fine,p_data)
and   elem.elem_id = r_ex.elem_id_old
and   elem.bil_id = bil.bil_id
and   bil.periodo_id = per.periodo_id;

IF NOT FOUND then
--SIAC-6007 Indipendentemente dal tipo di capitolo, sia esso di previsione o gestione,
--il capitolo ricercato e di Gestione
  select
    v_anno_prec, elem.elem_code,elem.elem_code2
    into v_ex_anno, v_ex_capitolo, v_ex_articolo
  from siac_t_bil_elem elem
  where elem.elem_code =  v_elem_code
  and   elem.elem_code2 = v_elem_code2
  and   elem.elem_code3 = v_elem_code3
  and   elem.elem_tipo_id = v_elem_tipo_id
  and   elem.bil_id = v_bil_id_prec
  and   elem.data_cancellazione is null;  -- Haitham 10/02/2022 SIAC-8621
END IF;

esito:= '    Fine step dati ex capitolo - '||clock_timestamp();
return next;
INSERT INTO siac.siac_dwh_capitolo_spesa
(ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
cod_tipo_capitolo,
desc_tipo_capitolo,
cod_stato_capitolo,
desc_stato_capitolo,
cod_classificazione_capitolo,
desc_classificazione_capitolo,
cod_titolo_spesa,
desc_titolo_spesa,
cod_macroaggregato_spesa,
desc_macroaggregato_spesa,
cod_missione_spesa,
desc_missione_spesa,
cod_programma_spesa,
desc_programma_spesa,
cod_pdc_finanziario_i,
desc_pdc_finanziario_i,
cod_pdc_finanziario_ii,
desc_pdc_finanziario_ii,
cod_pdc_finanziario_iii,
desc_pdc_finanziario_iii,
cod_pdc_finanziario_iv,
desc_pdc_finanziario_iv,
cod_pdc_finanziario_v,
desc_pdc_finanziario_v,
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
cod_cdr,
desc_cdr,
cod_cdc,
desc_cdc,
cod_siope_i_spesa,
desc_siope_i_spesa,
cod_siope_ii_spesa,
desc_siope_ii_spesa,
cod_siope_iii_spesa,
desc_siope_iii_spesa,
cod_spesa_ricorrente,
desc_spesa_ricorrente,
cod_transazione_spesa_ue,
desc_transazione_spesa_ue,
cod_tipo_fondo,
desc_tipo_fondo,
cod_tipo_finanziamento,
desc_tipo_finanziamento,
cod_politiche_regionali_unit,
desc_politiche_regionali_unit,
cod_perimetro_sanita_spesa,
desc_perimetro_sanita_spesa,
--codice_risorse_accantonamento,
--descrizione_risorse_accantonamento,
classificatore_1,
classificatore_1_valore,
classificatore_1_desc_valore,
classificatore_2,
classificatore_2_valore,
classificatore_2_desc_valore,
classificatore_3,
classificatore_3_valore,
classificatore_3_desc_valore,
classificatore_4,
classificatore_4_valore,
classificatore_4_desc_valore,
classificatore_5,
classificatore_5_valore,
classificatore_5_desc_valore,
classificatore_6,
classificatore_6_valore,
classificatore_6_desc_valore,
classificatore_7,
classificatore_7_valore,
classificatore_7_desc_valore,
classificatore_8,
classificatore_8_valore,
classificatore_8_desc_valore,
classificatore_9,
classificatore_9_valore,
classificatore_9_desc_valore,
classificatore_10,
classificatore_10_valore,
classificatore_10_desc_valore,
classificatore_11,
classificatore_11_valore,
classificatore_11_desc_valore,
classificatore_12,
classificatore_12_valore,
classificatore_12_desc_valore,
classificatore_13,
classificatore_13_valore,
classificatore_13_desc_valore,
classificatore_14,
classificatore_14_valore,
classificatore_14_desc_valore,
classificatore_15,
classificatore_15_valore,
classificatore_15_desc_valore,
flagentratericorrenti,
flagfunzionidelegate,
flagimpegnabile,
flagpermemoria,
flagrilevanteiva,
flag_trasf_organi_comunitari,
note,
cod_stipendio,
desc_stipendio,
cod_attivita_iva,
desc_attivita_iva,
massimo_impegnabile_anno1,
stanz_cassa_anno1,
stanz_cassa_iniziale_anno1,
stanz_residuo_iniziale_anno1,
stanz_anno1,
stanz_iniziale_anno1,
stanz_residuo_anno1,
flag_anno1,
massimo_impegnabile_anno2,
stanz_cassa_anno2,
stanz_cassa_iniziale_anno2,
stanz_residuo_iniziale_anno2,
stanz_anno2,
stanz_iniziale_anno2,
stanz_residuo_anno2,
flag_anno2,
massimo_impegnabile_anno3,
stanz_cassa_anno3,
stanz_cassa_iniziale_anno3,
stanz_residuo_iniziale_anno3,
stanz_anno3,
stanz_iniziale_anno3,
stanz_residuo_anno3,
flag_anno3,
disponibilita_impegnare_anno1,
disponibilita_impegnare_anno2,
disponibilita_impegnare_anno3
--SIAC-5895
,ex_anno
,ex_capitolo
,ex_articolo
)
VALUES (v_ente_proprietario_id,
        v_ente_denominazione,
        v_anno,
        v_fase_operativa_code,
        v_fase_operativa_desc,
        v_elem_code,
        v_elem_code2,
        v_elem_code3,
        v_elem_desc,
        v_elem_desc2,
        v_elem_tipo_code,
        v_elem_tipo_desc,
        v_elem_stato_code,
        v_elem_stato_desc,
        v_elem_cat_code,
        v_elem_cat_desc,
		v_codice_titolo_spesa,
		v_descrizione_titolo_spesa,
		v_codice_macroaggregato_spesa,
		v_descrizione_macroaggregato_spesa,
		v_codice_missione_spesa,
		v_descrizione_missione_spesa,
		v_codice_programma_spesa,
		v_descrizione_programma_spesa,
        v_codice_pdc_finanziario_I,
        v_descrizione_pdc_finanziario_I,
        v_codice_pdc_finanziario_II,
        v_descrizione_pdc_finanziario_II,
        v_codice_pdc_finanziario_III,
        v_descrizione_pdc_finanziario_III,
        v_codice_pdc_finanziario_IV,
        v_descrizione_pdc_finanziario_IV,
        v_codice_pdc_finanziario_V,
        v_descrizione_pdc_finanziario_V,
        v_codice_cofog_divisione,
        v_descrizione_cofog_divisione,
        v_codice_cofog_gruppo,
        v_descrizione_cofog_gruppo,
        v_codice_cdr,
        v_descrizione_cdr,
        v_codice_cdc,
        v_descrizione_cdc,
        v_codice_siope_I_spesa,
        v_descrizione_siope_I_spesa,
        v_codice_siope_II_spesa,
        v_descrizione_siope_II_spesa,
        v_codice_siope_III_spesa,
        v_descrizione_siope_III_spesa,
        v_codice_spesa_ricorrente,
        v_descrizione_spesa_ricorrente,
        v_codice_transazione_spesa_ue,
        v_descrizione_transazione_spesa_ue,
        v_codice_tipo_fondo,
        v_descrizione_tipo_fondo,
        v_codice_tipo_finanziamento,
        v_descrizione_tipo_finanziamento,
	    v_codice_politiche_regionali_unitarie,
	    v_descrizione_politiche_regionali_unitarie,
        v_codice_perimetro_sanitario_spesa,
        v_descrizione_perimetro_sanitario_spesa,
       -- v_codice_risorse_accantonamento,
       -- v_descrizione_risorse_accantonamento,
        v_classificatore_generico_1,
        v_classificatore_generico_1_valore,
        v_classificatore_generico_1_descrizione_valore,
        v_classificatore_generico_2,
        v_classificatore_generico_2_valore,
        v_classificatore_generico_2_descrizione_valore,
        v_classificatore_generico_3,
        v_classificatore_generico_3_valore,
        v_classificatore_generico_3_descrizione_valore,
        v_classificatore_generico_4,
        v_classificatore_generico_4_valore,
        v_classificatore_generico_4_descrizione_valore,
        v_classificatore_generico_5,
        v_classificatore_generico_5_valore,
        v_classificatore_generico_5_descrizione_valore,
        v_classificatore_generico_6,
        v_classificatore_generico_6_valore,
        v_classificatore_generico_6_descrizione_valore,
        v_classificatore_generico_7,
        v_classificatore_generico_7_valore,
        v_classificatore_generico_7_descrizione_valore,
        v_classificatore_generico_8,
        v_classificatore_generico_8_valore,
        v_classificatore_generico_8_descrizione_valore,
        v_classificatore_generico_9,
        v_classificatore_generico_9_valore,
        v_classificatore_generico_9_descrizione_valore,
        v_classificatore_generico_10,
        v_classificatore_generico_10_valore,
        v_classificatore_generico_10_descrizione_valore,
        v_classificatore_generico_11,
        v_classificatore_generico_11_valore,
        v_classificatore_generico_11_descrizione_valore,
        v_classificatore_generico_12,
        v_classificatore_generico_12_valore,
        v_classificatore_generico_12_descrizione_valore,
        v_classificatore_generico_13,
        v_classificatore_generico_13_valore,
        v_classificatore_generico_13_descrizione_valore,
        v_classificatore_generico_14,
        v_classificatore_generico_14_valore,
        v_classificatore_generico_14_descrizione_valore,
        v_classificatore_generico_15,
        v_classificatore_generico_15_valore,
        v_classificatore_generico_15_descrizione_valore,
        v_FlagEntrateRicorrenti,
		v_FlagFunzioniDelegate,
        v_FlagImpegnabile,
        v_FlagPerMemoria,
        v_FlagRilevanteIva,
        v_FlagTrasferimentoOrganiComunitari,
        v_Note,
        v_codice_stipendio,
        v_descrizione_stipendio,
        v_codice_attivita_iva,
        v_descrizione_attivita_iva,
        v_massimo_impegnabile_anno1,
        v_stanziamento_cassa_anno1,
        v_stanziamento_cassa_iniziale_anno1,
        v_stanziamento_residuo_iniziale_anno1,
        v_stanziamento_anno1,
        v_stanziamento_iniziale_anno1,
        v_stanziamento_residuo_anno1,
        v_flag_anno1,
        v_massimo_impegnabile_anno2,
        v_stanziamento_cassa_anno2,
        v_stanziamento_cassa_iniziale_anno2,
        v_stanziamento_residuo_iniziale_anno2,
        v_stanziamento_anno2,
        v_stanziamento_iniziale_anno2,
        v_stanziamento_residuo_anno2,
        v_flag_anno2,
        v_massimo_impegnabile_anno3,
        v_stanziamento_cassa_anno3,
        v_stanziamento_cassa_iniziale_anno3,
        v_stanziamento_residuo_iniziale_anno3,
        v_stanziamento_anno3,
        v_stanziamento_iniziale_anno3,
        v_stanziamento_residuo_anno3,
        v_flag_anno3,
        v_disponibilita_impegnare_anno1,
        v_disponibilita_impegnare_anno2,
        v_disponibilita_impegnare_anno3
        --SIAC-5895
        ,v_ex_anno
        ,v_ex_capitolo
        ,v_ex_articolo
       );
esito:= '  Fine ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
END LOOP;
esito:= 'Fine funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;


EXCEPTION
WHEN others THEN
  esito:='Funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$function$
;


--SIAC-8621 - Haitham - FINE

-- SIAC-8648 - 25.02.2022 - Sofia - inizio

DROP FUNCTION if exists siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying,integer,integer);

-- _filtro_crp da rinominare: e' il filtro che discrimina COMPETENZA, RESIDUO, PLURIENNALE
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(
	_uid_capitolospesa integer,
	_anno character varying,
	_filtro_crp character varying,
	_limit integer,
	_page integer)
    RETURNS TABLE(
        uid integer,
        impegno_anno integer,
        impegno_numero numeric,
        impegno_desc character varying,
        impegno_stato character varying,
        impegno_importo numeric,
        soggetto_code character varying,
        soggetto_desc character varying,
        attoamm_numero integer,
        attoamm_anno character varying,
        attoamm_desc character varying,
        attoamm_tipo_code character varying,
        attoamm_tipo_desc character varying,
        attoamm_stato_desc character varying,
        attoamm_sac_code character varying,
        attoamm_sac_desc character varying,
        pdc_code character varying,
        pdc_desc character varying,
        impegno_anno_capitolo integer,
        impegno_nro_capitolo integer,
        impegno_nro_articolo integer,
        impegno_flag_prenotazione character varying,
        impegno_cup character varying,
        impegno_cig character varying,
        impegno_tipo_debito character varying,
        impegno_motivo_assenza_cig character varying,
        --11.05.2020 SIAC-7349 SR210
        impegno_componente character varying
    )
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
    ROWS 1000
AS $BODY$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY 
		with imp_sogg_attoamm as (
			with imp_sogg as (
				select distinct
					soggall.elem_id,
					soggall.uid,
					soggall.movgest_anno,
					soggall.movgest_numero,
					soggall.movgest_desc,
					soggall.movgest_stato_desc,
					soggall.movgest_ts_id,
					soggall.movgest_ts_det_importo,
					case when soggall.zzz_soggetto_code is null then soggall.zzzz_soggetto_code else soggall.zzz_soggetto_code end soggetto_code,
					case when soggall.zzz_soggetto_desc is null then soggall.zzzz_soggetto_desc else soggall.zzz_soggetto_desc end soggetto_desc,
					soggall.pdc_code,
					soggall.pdc_desc,
                    -- 29.06.2018 Sofia jira siac-6193
					soggall.impegno_nro_capitolo,
					soggall.impegno_nro_articolo,
					soggall.impegno_anno_capitolo,
                    soggall.impegno_flag_prenotazione,
                    soggall.impegno_cig,
  					soggall.impegno_cup,
                    soggall.impegno_motivo_assenza_cig,
            		soggall.impegno_tipo_debito,
                    -- 11.05.2020 SIAC-7349 SR210
                    soggall.impegno_componente

				from (
					with za as (
						select
						    zzz.elem_id,
							zzz.uid,
							zzz.movgest_anno,
							zzz.movgest_numero,
							zzz.movgest_desc,
							zzz.movgest_stato_desc,
							zzz.movgest_ts_id,
							zzz.movgest_ts_det_importo,
							zzz.zzz_soggetto_code,
							zzz.zzz_soggetto_desc,
							zzz.pdc_code,
							zzz.pdc_desc,
                            -- 29.06.2018 Sofia jira siac-6193
                            zzz.impegno_nro_capitolo,
                            zzz.impegno_nro_articolo,
                            zzz.impegno_anno_capitolo,
                            zzz.impegno_flag_prenotazione,
                            zzz.impegno_cig,
  							zzz.impegno_cup,
                            zzz.impegno_motivo_assenza_cig,
            				zzz.impegno_tipo_debito,
                            --11/05/2020 SIAC-7349 SR210
                            zzz.impegno_componente
						from (
							with impegno as (


								select
									bilelem.elem_id, 
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo,
									q.classif_code pdc_code,
									q.classif_desc pdc_desc,
                                    -- 29.06.2018 Sofia jira siac-6193
                                    bilelem.elem_code::integer impegno_nro_capitolo,
                                    bilelem.elem_code2::integer impegno_nro_articolo,
                                    t.anno::integer impegno_anno_capitolo,
                                    c.siope_assenza_motivazione_id,
                                    c.siope_tipo_debito_id,
                                    --11.05.2020 Mr SIAC-7349 SR210 tiro fuori l'id per la join con la tabella del tipo componente
                                    b.elem_det_comp_tipo_id
                                    --
								from
									siac_t_bil_elem bilelem,
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_r_movgest_class p,
									siac_t_class q,
									siac_d_class_tipo r,
									siac_t_bil s,
									siac_t_periodo t,
									siac_t_movgest_ts c
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and p.movgest_ts_id = c.movgest_ts_id
								and q.classif_id = p.classif_id
								and r.classif_tipo_id = q.classif_tipo_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and s.bil_id = a.bil_id
								and t.periodo_id = s.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and p.data_cancellazione is null
								and q.data_cancellazione is null
								and r.data_cancellazione is null
								and s.data_cancellazione is null
								and t.data_cancellazione is null
								and bilelem.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
								and b.elem_id=bilelem.elem_id
								and bilelem.elem_id=_uid_capitolospesa
                                and t.anno = _anno
							),
							siope_assenza_motivazione as
                            (
								select
									d.siope_assenza_motivazione_id,
									d.siope_assenza_motivazione_code,
									d.siope_assenza_motivazione_desc
								from siac_d_siope_assenza_motivazione d
								where d.data_cancellazione is null
							),

							siope_tipo_debito as
                            (
								select
									d.siope_tipo_debito_id,
									d.siope_tipo_debito_code,
									d.siope_tipo_debito_desc
								from siac_d_siope_tipo_debito d
								where d.data_cancellazione is null
							),
							soggetto as
                            (
								select
									g.soggetto_code,
									g.soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sog h
								where h.soggetto_id=g.soggetto_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
							),
							impegno_flag_prenotazione as
                            (
								select
									r.movgest_ts_id,
									r.boolean
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'flagPrenotazione'
							),
							impegno_cig as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cig'
							),
							impegno_cup as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cup'
							),
                            --11.05.2020 SIAC-7349 MR SR210 lista di tutte le componenti
                            componente_desc AS
                            (
                                select * from 
                                siac_d_bil_elem_det_comp_tipo tipo
                                --where tipo.data_cancellazione is NULL --da discuterne. in questo caso prende solo le componenti non cancellate
                            )
							select
							    impegno.elem_id,
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code zzz_soggetto_code,
								soggetto.soggetto_desc zzz_soggetto_desc,
								impegno.pdc_code,
								impegno.pdc_desc,
                                -- 29.06.2018 Sofia jira siac-6193
                                impegno.impegno_nro_capitolo,
                                impegno.impegno_nro_articolo,
                                impegno.impegno_anno_capitolo,
                                siope_assenza_motivazione.siope_assenza_motivazione_desc impegno_motivo_assenza_cig,
                                siope_tipo_debito.siope_tipo_debito_desc impegno_tipo_debito,
                                coalesce(impegno_flag_prenotazione.boolean,'N') impegno_flag_prenotazione,
                                impegno_cig.testo  impegno_cig,
                                impegno_cup.testo  impegno_cup,
                                --11.05.2020 MR SIAC-7349 SR210
                                componente_desc.elem_det_comp_tipo_desc impegno_componente
							from impegno
                              left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
                              left outer join impegno_flag_prenotazione on impegno.movgest_ts_id=impegno_flag_prenotazione.movgest_ts_id
                              left outer join impegno_cig on impegno.movgest_ts_id=impegno_cig.movgest_ts_id
                              left outer join impegno_cup on impegno.movgest_ts_id=impegno_cup.movgest_ts_id
                              left outer join siope_assenza_motivazione on impegno.siope_assenza_motivazione_id=siope_assenza_motivazione.siope_assenza_motivazione_id
                              left outer join siope_tipo_debito on impegno.siope_tipo_debito_id=siope_tipo_debito.siope_tipo_debito_id
                              --11.05.2020 MR SIAC-7349 SR210
                              left outer join componente_desc on impegno.elem_det_comp_tipo_id=componente_desc.elem_det_comp_tipo_id
						) as zzz
					),
					zb as (
						select
							zzzz.elem_id,
							zzzz.uid,
							zzzz.movgest_anno,
							zzzz.movgest_numero,
							zzzz.movgest_desc,
							zzzz.movgest_stato_desc,
							zzzz.movgest_ts_id,
							zzzz.movgest_ts_det_importo,
							zzzz.soggetto_code zzzz_soggetto_code,
							zzzz.soggetto_desc zzzz_soggetto_desc
						from (
							with impegno as (
								select
									b.elem_id, 
								    a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_t_bil l,
									siac_t_periodo m
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and l.bil_id = a.bil_id
								and m.periodo_id = l.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and b.elem_id=_uid_capitolospesa
								and m.anno = _anno
							),
							soggetto as (
                                select
									l.soggetto_classe_code soggetto_code,
									l.soggetto_classe_desc soggetto_desc,
									h.movgest_ts_id
								from
									siac_r_movgest_ts_sogclasse h,
									siac_d_soggetto_classe l
								where
								    h.soggetto_classe_id=l.soggetto_classe_id
                                and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and h.data_cancellazione is null
							)
							select
								impegno.elem_id,
							    impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzzz
					)
					select
						za.*,
						zb.zzzz_soggetto_code,
						zb.zzzz_soggetto_desc
					from za
					left join zb on za.movgest_ts_id=zb.movgest_ts_id
				) soggall
			),

			attoamm as (
				select
					movgest_ts_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
                    --29.06.2018 Sofia jira siac-6193
                    n.attoamm_oggetto,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc,
					--SIAC-8188
					staa.attoal_causale
				from
					siac_r_movgest_ts_atto_amm m,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q,
					siac_t_atto_amm n
				--SIAC-8188 se ci sono corrisponsenze le ritorno
				left join siac_t_atto_allegato staa on n.attoamm_id = staa.attoamm_id 
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			)
			select
				imp_sogg.elem_id,
			    imp_sogg.uid,
				imp_sogg.movgest_anno,
				imp_sogg.movgest_numero,
				imp_sogg.movgest_desc,
				imp_sogg.movgest_stato_desc,
				imp_sogg.movgest_ts_det_importo,
				imp_sogg.soggetto_code,
				imp_sogg.soggetto_desc,
				attoamm.attoamm_id,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
                -- 29.06.2018 Sofia jira siac-6193
                attoamm.attoamm_oggetto,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				--SIAC-8188
				attoamm.attoal_causale,
				imp_sogg.pdc_code,
				imp_sogg.pdc_desc,
                -- 29.06.2018 Sofia jira siac-6193
                imp_sogg.impegno_nro_capitolo,
           		imp_sogg.impegno_nro_articolo,
           		imp_sogg.impegno_anno_capitolo,
                imp_sogg.impegno_flag_prenotazione,
                imp_sogg.impegno_cig,
                imp_sogg.impegno_cup,
                imp_sogg.impegno_motivo_assenza_cig,
                imp_sogg.impegno_tipo_debito,
                --11.05.2020 MR SIAC-7349 SR210
                imp_sogg.impegno_componente

			from imp_sogg

			 left outer join attoamm ON imp_sogg.movgest_ts_id=attoamm.movgest_ts_id
            where (case when coalesce(_filtro_crp,'X')='R' then imp_sogg.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then imp_sogg.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then imp_sogg.movgest_anno>_anno::integer
		                else true end ) -- 29.06.2018 Sofia jira siac-6193
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
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		),
      --  	SIAC-8351 Haitham 05/11/2021
		sac_capitolo as (
			select
				class_cap.classif_code,
				class_cap.classif_desc,
				r_class_cap.elem_id
			from
				siac_r_bil_elem_class r_class_cap,
				siac_t_class class_cap,
				siac_d_class_tipo tipo_class_cap
			where r_class_cap.classif_id=class_cap.classif_id
			and tipo_class_cap.classif_tipo_id=class_cap.classif_tipo_id
			and now() BETWEEN r_class_cap.validita_inizio and coalesce (r_class_cap.validita_fine,now())
			and tipo_class_cap.classif_tipo_code  IN ('CDC', 'CDR')
			and r_class_cap.data_cancellazione is NULL
			and tipo_class_cap.data_cancellazione is NULL
			and class_cap.data_cancellazione is null
		),	
      --  	SIAC-8351 Haitham 05/11/2021
        sac_impegno as (
			select
				class_imp.classif_code,
				class_imp.classif_desc,
				mov.movgest_id 
			from
				siac_r_movgest_class  r_class_imp,
				siac_t_class class_imp,
				siac_d_class_tipo tipo_class_imp,
				siac_t_movgest mov,
				siac_t_movgest_ts ts
			where r_class_imp.classif_id=class_imp.classif_id
			and tipo_class_imp.classif_tipo_id=class_imp.classif_tipo_id
			and now() BETWEEN r_class_imp.validita_inizio and coalesce (r_class_imp.validita_fine,now())
			and tipo_class_imp.classif_tipo_code  IN ('CDC', 'CDR')
			and ts.movgest_ts_id  = r_class_imp.movgest_ts_id 
			and mov.movgest_id = ts.movgest_id 
			and r_class_imp.data_cancellazione is NULL
			and tipo_class_imp.data_cancellazione is NULL
			and class_imp.data_cancellazione is null
			-- 25.02.2022 Sofia Jira SIAC-8648
			and now() BETWEEN ts.validita_inizio and COALESCE(ts.validita_fine,now())
			and ts.data_cancellazione is null 
		)
		select
			imp_sogg_attoamm.uid,
			imp_sogg_attoamm.movgest_anno as impegno_anno,
			imp_sogg_attoamm.movgest_numero as impegno_numero,
			imp_sogg_attoamm.movgest_desc as impegno_desc,
			imp_sogg_attoamm.movgest_stato_desc as impegno_stato,
			imp_sogg_attoamm.movgest_ts_det_importo as impegno_importo,
			imp_sogg_attoamm.soggetto_code,
			imp_sogg_attoamm.soggetto_desc,
			imp_sogg_attoamm.attoamm_numero,
			imp_sogg_attoamm.attoamm_anno,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.attoamm_oggetto attoamm_oggetto, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
            imp_sogg_attoamm.attoal_causale attoal_causale, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
			imp_sogg_attoamm.attoamm_tipo_code,
			imp_sogg_attoamm.attoamm_tipo_desc,
			imp_sogg_attoamm.attoamm_stato_desc,
			sac_attoamm.classif_code as attoamm_sac_code,
			sac_attoamm.classif_desc as attoamm_sac_desc,
			imp_sogg_attoamm.pdc_code,
			imp_sogg_attoamm.pdc_desc,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.impegno_anno_capitolo,
            imp_sogg_attoamm.impegno_nro_capitolo,
            imp_sogg_attoamm.impegno_nro_articolo,
            imp_sogg_attoamm.impegno_flag_prenotazione::varchar,
			imp_sogg_attoamm.impegno_cup,
            imp_sogg_attoamm.impegno_cig,
            imp_sogg_attoamm.impegno_tipo_debito,
            imp_sogg_attoamm.impegno_motivo_assenza_cig,
            --11.05.2020 SIAC-7349 MR SR210
            imp_sogg_attoamm.impegno_componente,
   			sac_capitolo.classif_code as cap_sac_code,       --  	SIAC-8351 Haitham 05/11/2021
			sac_capitolo.classif_desc as cap_sac_desc,        --  	SIAC-8351 Haitham 05/11/2021
   			sac_impegno.classif_code as imp_sac_code,       --  	SIAC-8351 Haitham 05/11/2021
			sac_impegno.classif_desc as imp_sac_desc        --  	SIAC-8351 Haitham 05/11/2021
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		left outer join sac_capitolo on imp_sogg_attoamm.elem_id=sac_capitolo.elem_id
		left outer join sac_impegno on imp_sogg_attoamm.uid=sac_impegno.movgest_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero


		LIMIT _limit
		OFFSET _offset;
END;
$BODY$;

ALTER FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying, integer, integer)
    OWNER TO siac;
-- SIAC-8648 - 25.02.2022 - Sofia - fine 